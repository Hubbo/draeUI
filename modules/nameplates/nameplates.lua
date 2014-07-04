--[[

--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

--
local PL = T:GetModule("Nameplates")
local LSM = LibStub("LibSharedMedia-3.0")

--
local floor, ceil, select = math.floor, math.ceil, select

--[[

--]]
local stdUpdateTime, ImpUpdateTime = 1, .1
local targetExists = false

--[[
		Creation functions
--]]
local noop = function() end

PL.CreateBackground = function(self, f, a, offset)
	-- Try and use the parent of the passed object if it's just a texture
	local f = (f:GetObjectType() == "Texture") and f:GetParent() or f

	offset = offset or 5

	f.bg = CreateFrame("Frame", nil, f)
	f.bg:SetFrameLevel(1)
	f.bg:SetPoint("TOPLEFT", f, -(offset + 1), offset + 1)
	f.bg:SetPoint("BOTTOMRIGHT", f, offset + 1, -(offset + 1))
	f.bg:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\AddOns\\draeUI\\media\\textures\\glowtex",
		edgeSize = offset,
		insets = { left = offset, right = offset, top = offset, bottom = offset }
	})
	f.bg:SetBackdropColor(0, 0, 0, 1)
	f.bg:SetBackdropBorderColor(0, 0, 0, a or 0.7)
end

-- Frame fading functions
-- (without the taint of UIFrameFade & the lag of AnimationGroups)
PL.frameFadeFrame = CreateFrame('Frame')
PL.FADEFRAMES = {}

PL.frameIsFading = function(frame)
	for index, value in pairs(PL.FADEFRAMES) do
		if value == frame then
			return true
		end
	end
end

PL.frameFadeRemoveFrame = function(frame)
	tDeleteItem(PL.FADEFRAMES, frame)
end

PL.frameFadeOnUpdate = function(self, elapsed)
	local frame, info
	for index, value in pairs(PL.FADEFRAMES) do
		frame, info = value, value.fadeInfo

		if info.startDelay and info.startDelay > 0 then
			info.startDelay = info.startDelay - elapsed
		else
			info.fadeTimer = (info.fadeTimer and info.fadeTimer + elapsed) or 0

			if info.fadeTimer < info.timeToFade then
				-- perform animation in either direction
				if info.mode == 'IN' then
					frame:SetAlpha(
						(info.fadeTimer / info.timeToFade) *
						(info.endAlpha - info.startAlpha) +
						info.startAlpha
					)
				elseif info.mode == 'OUT' then
					frame:SetAlpha(
						((info.timeToFade - info.fadeTimer) / info.timeToFade) *
						(info.startAlpha - info.endAlpha) + info.endAlpha
					)
				end
			else
				-- animation has ended
				frame:SetAlpha(info.endAlpha)

				if info.fadeHoldTime and info.fadeHoldTime > 0 then
					info.fadeHoldTime = info.fadeHoldTime - elapsed
				else
					PL.frameFadeRemoveFrame(frame)

					if info.finishedFunc then
						info.finishedFunc(frame)
						info.finishedFunc = nil
					end
				end
			end
		end
	end

	if #PL.FADEFRAMES == 0 then
		self:SetScript('OnUpdate', nil)
	end
end

--[[
	info = {
		mode			= "IN" (nil) or "OUT",
		startAlpha		= alpha value to start at,
		endAlpha		= alpha value to end at,
		timeToFade		= duration of animation,
		startDelay		= seconds to wait before starting animation,
		fadeHoldTime 	= seconds to wait after ending animation before calling finishedFunc,
		finishedFunc	= function to call after animation has ended,
	}

	If you plan to reuse `info`, it should be passed as a single table,
	NOT a reference, as the table will be directly edited.
]]
PL.frameFade = function(frame, info)
	if not frame then return end

	if PL.frameIsFading(frame) then
		-- cancel the current operation
		-- the code calling this should make sure not to interrupt a
		-- necessary finishedFunc. This will entirely skip iPL.
		tDeleteItem(PL.FADEFRAMES, frame)
	end

	info		= info or {}
	info.mode	= info.mode or 'IN'

	if info.mode == 'IN' then
		info.startAlpha	= info.startAlpha or 0
		info.endAlpha	= info.endAlpha or 1
	elseif info.mode == 'OUT' then
		info.startAlpha	= info.startAlpha or 1
		info.endAlpha	= info.endAlpha or 0
	end

	frame:SetAlpha(info.startAlpha)
	frame.fadeInfo = info

	tinsert(PL.FADEFRAMES, frame)
	PL.frameFadeFrame:SetScript('OnUpdate', PL.frameFadeOnUpdate)
end

--[[
		Castbar functions
--]]

-- Color the castbar depending on if we can interrupt or not,
-- also resize it as nameplates somehow manage to resize some frames when they reappear after being hidden
local UpdateCastbar = function(frame)
	frame:ClearAllPoints()
	frame:SetSize(PL.db.hpWidth, PL.db.cbHeight)
	frame:SetPoint("TOP", frame.parent.hp, "BOTTOM", 0, -4)

	if (frame.shield:IsShown()) then
		frame.shield:ClearAllPoints()
		frame.shield:SetPoint("RIGHT", frame, "LEFT", -2, 0)
		frame.shield:SetSize(PL.db.cbHeight * 5, PL.db.cbHeight * 5)

		frame:SetStatusBarColor(0.78, 0.25, 0.25, 1)
	end
end

-- Determine whether or not the cast is Channelled or a Regular cast so we can grab the proper Cast Name
local UpdateCastText = function(frame, curValue)
	local minValue, maxValue = frame:GetMinMaxValues()

	if (UnitChannelInfo("target")) then
		frame.time:SetFormattedText("%.1f ", curValue)
	elseif (UnitCastingInfo("target")) then
		frame.time:SetFormattedText("%.1f ", maxValue - curValue)
	end
end

-- Sometimes castbar likes to randomly resize
local OnValueChanged = function(self, curValue)
	UpdateCastText(self, curValue)

	if (self.needFix) then
		UpdateCastbar(self)
		self.needFix = nil
	end
end

--Sometimes castbar likes to randomly resize
local OnSizeChanged = function(self)
	self.needFix = true
end

--[[

--]]
local SetGlowColour = function(frame, r, g, b, a)
	frame.hp.bg:SetBackdropBorderColor(r or 0, g or 0, b or 0, a or 0.7)
end

--Color Nameplate
local SetHealthBarColour = function(frame)
	local r, g, b = frame.hp:GetStatusBarColor()

	local mu = frame.hp.hpbg.multiplier or 1
	frame.hp.hpbg:SetVertexColor(r * mu, g * mu, b * mu, 1)
end

--Create our blacklist for nameplates, so prevent a certain nameplate from ever showing
local CheckBlacklist = function(frame)
	if (PL.db.blacklist[frame.overlay.name:GetText()]) then
		frame:Hide()
		frame.castBar:Hide()
		frame.level:Hide()

		frame:SetScript("OnUpdate", function() end)

		return true
	end
end

--[[

--]]
PL.PLAYER_TARGET_CHANGED = function(self)
	targetExists = UnitExists('target')
end

local OnFrameEnter = function(frame)
	frame.highlighted = true

	if (frame.overlay.highlight) then
		frame.overlay.highlight:Show()
	end
end

local OnFrameLeave = function(frame)
	frame.highlighted = false

	if (frame.overlay.highlight) then
		frame.overlay.highlight:Hide()
	end
end

--We need to reset everything when a nameplate it hidden, this is so theres no left over data when a nameplate gets reshown for a differant mob.
local OnFrameHide = function(f)
	local frame = f.draePlate

	frame:Hide()

	if (frame.targetGlow) then
		frame.targetGlow:Hide()
	end

	frame.unit = nil
	frame.guid = nil
	frame.target = nil

	frame.lastAlpha = nil
	frame.fadingTo  = nil
	frame.hasThreat = nil

	frame.StdElapsed = 0
	frame.ImpElapsed = 0

	frame:SetScript("OnUpdate", nil)
end

-- OnShow,
-- Use this to set variables for the nameplate, also size the healthbar here because it likes to lose it"s
-- size settings when it gets reshown
local OnFrameShow = function(f)
	local frame = f.draePlate

	frame:SetAlpha(0)

	while frame.hp:GetEffectiveScale() < 1 do
		frame.hp:SetScale(frame.hp:GetScale() + 0.01)
	end

	if (frame.targetGlow) then
		frame.targetGlow:Hide()
	end

	--Have to reposition this here so it doesnt resize after being hidden
	frame.hp:ClearAllPoints()
	frame.hp:SetSize(PL.db.hpWidth, PL.db.hpHeight)
	frame.hp:SetPoint("TOP", frame, "TOP", 0, -15)

	--Set the name text
	frame.overlay.name:SetText(frame.oldName:GetText())

	if (frame.boss:IsShown()) then
		frame.level:SetText("??")
		frame.level:Show()
	elseif (frame.state:IsShown()) then
		frame.level:SetText(frame.level:GetText() .. "+")
		frame.level:Show()
	end

	-- reset glow colour
	frame:SetGlowColour()

	frame.toShow = true
	frame.PostOnFrameShow = true
end

local OnHealthValueChanged = function(f, cur)
	if f.hp then
		f = f.hp
		cur = f:GetValue()
	end

	local frame = f.parent.draePlate

	-- show current health value
	local minHealth, maxHealth = f:GetMinMaxValues()
	local pct = (cur / maxHealth) * 100

	if (cur ~= maxHealth) then
		frame.overlay.value:SetText(format("|cffa0a0a0%s|r - %d%%", T.ShortVal(cur), floor(pct)))
	else
		frame.overlay.value:SetText("")
	end
end

local OnFrameUpdate = function(f, elapsed)
	local frame = f.draePlate

	if (CheckBlacklist(frame)) then return end

	frame.defaultAlpha = f:GetAlpha()

	if ((frame.defaultAlpha == 1 and targetExists)) then
		frame.currentAlpha = 1
	elseif (targetExists or PL.db.fadeAlways) then
		frame.currentAlpha = PL.db.fadeAlways or .5
	else
		frame.currentAlpha = 1
	end

	if (frame.toShow) then
		frame:Show()
		frame.toShow = nil
	end

	if (PL.db.fadeIn) then
		if (not frame.lastAlpha or frame.currentAlpha ~= frame.lastAlpha) then
			if (not frame.fadingTo or frame.fadingTo ~= frame.currentAlpha) then
				if (PL.frameIsFading(frame)) then
					PL.frameFadeRemoveFrame(frame)
				end

				-- fade to the new value
				frame.fadingTo = frame.currentAlpha
				local alphaChange = (frame.fadingTo - (frame.lastAlpha or 0))

				PL.frameFade(frame, {
					mode = alphaChange < 0 and "OUT" or "IN",
					timeToFade = abs(alphaChange) * .5,
					startAlpha = frame.lastAlpha or 0,
					endAlpha = frame.fadingTo,
					finishedFunc = function()
						frame.fadingTo = nil
					end,
				})
			end

			frame.lastAlpha = frame.currentAlpha
		end
	else
		frame:SetAlpha(frame.currentAlpha)
	end

	frame.StdElapsed = frame.StdElapsed - elapsed
	frame.ImpElapsed = frame.ImpElapsed - elapsed

	-- call delayed updates
	if (frame.StdElapsed <= 0) then
		frame.StdElapsed = stdUpdateTime
		frame:UpdateFrameStd()
	end

	if (frame.ImpElapsed <= 0) then
		frame.ImpElapsed = ImpUpdateTime
		frame:UpdateFrameImp()
	end
end

-- This is called per frame every StdElapsed seconds - so every half second
local UpdateFrameStd = function(frame)
	SetHealthBarColour(frame)

	if (frame.PostOnFrameShow) then
		frame:OnHealthValueChanged()

		frame.PostOnFrameShow = nil
	end
end

-- This is called per frame every ImpElapsed seconds - so every 0.2 seconds
local UpdateFrameImp = function(frame)
	-- set glow to the current default ui's colour
	if (frame.glow:IsVisible()) then
		frame.glow.wasVisible = true

		frame.glow.r, frame.glow.g, frame.glow.b = frame.glow:GetVertexColor()
		frame:SetGlowColour(frame.glow.r, frame.glow.g, frame.glow.b)
	elseif (frame.glow.wasVisible) then
		frame.glow.wasVisible = nil
		frame:SetGlowColour()
	end

	if (frame.oldHighlight:IsShown()) then
		if (not frame.highlighted) then
			OnFrameEnter(frame)
		end
	elseif (frame.highlighted) then
		OnFrameLeave(frame)
	end

	if (targetExists and frame.defaultAlpha == 1) then
		if (not frame.target) then
			-- this frame just became targeted
			frame.target = true

			frame:SetFrameLevel(10)

			if (frame.targetGlow) then
				frame.targetGlow:Show()
			end
		end
	elseif (frame.target) then
		frame.target = nil

		frame:SetFrameLevel(0)

		if (frame.targetGlow) then
			frame.targetGlow:Hide()
		end
	end

end

--[[
		This is where we create most "Static" objects for the nameplate, it gets fired when a nameplate is first seen.
--]]
PL.StyleNameplate = function(self, frame)
	-- fetch default ui's objects
	local barFrame, nameFrame = frame:GetChildren()

	local nameText = nameFrame:GetRegions()
	local glowRegion, overlayRegion, highlightRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = barFrame:GetRegions()
	local healthBar, castBar = barFrame:GetChildren()
	local _, castbarOverlay, shieldedRegion, spellIconRegion, spellNameRegion, spellNameShadow = castBar:GetRegions()

	-- Hide unwanted elements
	overlayRegion:SetTexture(nil)
	bossIconRegion:SetTexture(nil)
	stateIconRegion:SetTexture(nil)
	castbarOverlay:SetTexture(nil)
	glowRegion:SetTexture(nil)
	spellIconRegion:SetTexCoord(0, 0, 0, 0)
	nameText:Hide()

	-- Create our plate frame
	local plate = CreateFrame("Frame", nil, WorldFrame)
	frame.draePlate = plate

	-- Keep track of existing elements
	plate.glow = glowRegion
	plate.boss = bossIconRegion
	plate.state = stateIconRegion
	plate.raidIcon = raidIconRegion
	plate.level = levelTextRegion

	-- We need data from these elements so save them too
	plate.oldHighlight = highlightRegion
	plate.oldName = nameText
	plate.barFrame = barFrame

	--
	plate.StdElapsed = 0
	plate.ImpElapsed = 0

	-- Same for castbar
	castBar.spellName = spellNameRegion
	castBar.spellIcon = spellIconRegion
	castBar.shield = shieldedRegion
	castBar.spellNameShadow = spellNameShadow

	-- Functions
	plate.UpdateFrameStd = UpdateFrameStd
	plate.UpdateFrameImp = UpdateFrameImp
	plate.SetGlowColour = SetGlowColour
	plate.SetCentre = SetFrameCentre
	plate.OnHealthValueChanged = OnHealthValueChanged

	-- Initial setup of our plate
	plate:SetAllPoints(frame)
	plate:SetFrameStrata("BACKGROUND")
	plate:SetFrameLevel(0)

	--[[
			Create or re-purpose and update elements
	--]]

	--Health Bar
	healthBar:SetParent(plate)
	healthBar:SetFrameLevel(2)
	healthBar:SetStatusBarTexture(T.db["media"].texture)
	healthBar:SetSize(PL.db.hpWidth, PL.db.hpHeight)
	healthBar:SetPoint('BOTTOM', plate, 'BOTTOM', 0, 5)
	healthBar.percent = 100

	healthBar.hpbg = healthBar:CreateTexture(nil, "BACKGROUND")
	healthBar.hpbg:SetAllPoints(healthBar)
	healthBar.hpbg:SetTexture(T.db["media"].texture)
	healthBar.hpbg.multiplier = 0.33

	self:CreateBackground(healthBar)

	healthBar.parent = frame
	plate.hp = healthBar

	-- Container for text and other elements
	local overlay = CreateFrame("Frame", nil, plate)
	overlay:SetAllPoints(healthBar)
	overlay:SetFrameLevel(3)

	--Create Level
	plate.level:SetParent(overlay)
	plate.level = T.CreateFontObject(plate.level, C["nameplates"].fontsize - 2, T.db["media"].fontOther, "RIGHT")
	plate.level:ClearAllPoints()
	plate.level:SetPoint("BOTTOMRIGHT", overlay, "TOPLEFT", 20, (-C["nameplates"].fontsize / 3) + 1)

	--Create Name Text
	overlay.name = T.CreateFontObject(overlay, C["nameplates"].fontsize - 2, T.db["media"].fontOther, "LEFT")
	overlay.name:SetPoint("BOTTOMRIGHT", overlay, "TOPRIGHT", -5, (-C["nameplates"].fontsize / 3) + 1)
	overlay.name:SetPoint("BOTTOMLEFT", overlay, "TOPLEFT", 20, (-C["nameplates"].fontsize / 3) + 1)
	overlay.name:SetTextColor(1, 1, 1)

	--Create Health Text
	overlay.value = T.CreateFontObject(overlay, C["nameplates"].fontsize / 2 + 3, T.db["media"].fontOther, "RIGHT")
	overlay.value:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, (-PL.db.fontsize/3) - 1)
	overlay.value:SetTextColor(1, 1, 1)

	-- Highlight
	overlay.highlight = overlay:CreateTexture(nil, 'ARTWORK')
	overlay.highlight:SetTexture(T.db["media"].texture)
	overlay.highlight:SetAllPoints(healthBar)
	overlay.highlight:SetVertexColor(1, 1, 1)
	overlay.highlight:SetBlendMode('ADD')
	overlay.highlight:SetAlpha(.4)
	overlay.highlight:Hide()

	plate.overlay = overlay

	--Reposition and resize raid icon
	plate.raidIcon:ClearAllPoints()
	plate.raidIcon:SetDrawLayer("OVERLAY", 7)
	plate.raidIcon:SetPoint("RIGHT", overlay, "LEFT", -5, 0)
	plate.raidIcon:SetSize(PL.db.iconSize, PL.db.iconSize)

	-- Glow for target/threat
	local targetGlow = healthBar:CreateTexture(nil, "BACKGROUND")
	targetGlow:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\target-glow")
	targetGlow:SetTexCoord(0, .593, 0, .875)
	targetGlow:SetPoint('TOP', healthBar, 'BOTTOM', 0, 2)
	targetGlow:SetWidth(PL.db.hpWidth)
	targetGlow:SetVertexColor(1, 1, 1)

	plate.targetGlow = targetGlow

	--[[
			Castbar
	--]]
	castBar:SetFrameLevel(2)
	castBar:SetStatusBarTexture(T.db["media"].texture)

	self:CreateBackground(castBar, nil, 3)

	-- Spell name shadow
	castBar.spellNameShadow:SetParent(castBar)
	castBar.spellNameShadow:SetDrawLayer("BACKGROUND")
	castBar.spellNameShadow:SetPoint("TOP", castBar, "BOTTOM", 0, -1)

	--Create castbar spell cast time text
	castBar.time = T.CreateFontObject(castBar, C["nameplates"].fontsize2, T.db["media"].fontOther, "RIGHT")
	castBar.time:SetPoint("RIGHT", castBar, "LEFT", -1, 0)
	castBar.time:SetTextColor(1, 1, 1)

	-- Re-purpose castbar spell name text
	castBar.spellName:SetParent(castBar)
	castBar.spellName:ClearAllPoints()
	castBar.spellName = T.CreateFontObject(castBar.spellName, C["nameplates"].fontsize2, T.db["media"].fontOther, "CENTER")
	castBar.spellName:SetPoint("TOP", castBar, "BOTTOM", 0, -1)
	castBar.spellName:SetTextColor(1, 1, 1)

	-- Uninterruptable shield icon
	castBar.shield:SetParent(castBar)
	castBar.shield:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\Shield")
	castBar.shield:SetTexCoord(0, 0.53125, 0, 0.625)
	castBar.shield:SetDrawLayer("ARTWORK")

	castBar.parent = plate
	plate.castBar = castBar

	--[[
			Hook existing frames
	--]]
	castBar:HookScript("OnShow", UpdateCastbar)
	castBar:HookScript("OnSizeChanged", OnSizeChanged)
	castBar:HookScript("OnValueChanged", OnValueChanged)

	frame:HookScript("OnShow", OnFrameShow)
	frame:HookScript("OnHide", OnFrameHide)
	frame:HookScript("OnUpdate", OnFrameUpdate)
	healthBar:HookScript("OnValueChanged", OnHealthValueChanged)

	if (frame:IsShown()) then
		OnFrameShow(frame)
		UpdateCastbar(castBar)
	else
		plate:Hide()
	end
end

--[[

--]]
local IsNameplate = function(frame)
	local name = frame:GetName()

	if (name and name:find("NamePlate%d")) then
		local nameTextChild = select(2, frame:GetChildren())

		if (nameTextChild) then
			local nameTextRegion = nameTextChild:GetRegions()
			return (nameTextRegion and nameTextRegion:GetObjectType() == "FontString")
		end
	end
end

--
do
	local WorldFrame = WorldFrame

	-- Look for new nameplate frames
	PL.OnUpdate = function(self)
		local frames = select("#", WorldFrame:GetChildren())

		if (frames ~= self.numFrames) then
			local i, f

			for i = 1, frames do
				f = select(i, WorldFrame:GetChildren())

				if (IsNameplate(f) and not f.draePlate) then
					self:StyleNameplate(f)
				end
			end

			self.numFrames = frames
		end
	end
end

--
PL.OnEnable = function(self)
	SetCVar("threatWarning", (PL.db.enhancethreat) and 3 or 0)

	self:ScheduleRepeatingTimer("OnUpdate", .1)

	self:RegisterEvent("PLAYER_TARGET_CHANGED")
end
