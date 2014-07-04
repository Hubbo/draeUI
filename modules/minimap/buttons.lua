--[[
		Basically rMinimap customied a bit!
		zoomscript taken from pminimap by p3lim - http://www.wowinterface.com/downloads/info8389-pTM.html
--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local MM = T:GetModule("Minimap")

--
local _G = _G

--
MM.buttons = {}
local BT = MM.buttons

local moving, ButtonFadeOut
local animFrames = {}

-- For the rare addons that don't use LibDBIcon for some reason :(
local addonButtons = {
	EnxMiniMapIcon = "Enchantrix",
	["FuBarPluginBig BrotherFrameMinimapButton"] = "Big Brother",
	RA_MinimapButton = "RaidAchievement",
	DBMMinimapButton = "DBM (Deadly Boss Mods)",
	XPerl_MinimapButton_Frame = "X-Perl",
	WIM3MinimapButton = "WIM (WoW Instant Messenger)",
	VuhDoMinimapButton = "VuhDo",
	AltoholicMinimapButton = "Altoholic",
	DominosMinimapButton = "Dominos",
	Gatherer_MinimapOptionsButton = "Gatherer",
	DroodFocusMinimapButton = "Drood Focus",
	["FuBarPluginElkano's BuffBarsFrameMinimapButton"] = "EBB (Elkano's Buff Bars)",
	D32MiniMapButton = "Mistra's Diablo Orbs",
	DKPBidderMapIcon = "DKP-Bidder",
	HealiumMiniMap = "Healium",
	HealBot_MMButton = "HealBot",
	IonMinimapButton = "Ion",
	OutfitterMinimapButton = "Outfitter",
	FlightMapEnhancedMinimapButton = "Flight Map Enhanced",
	NXMiniMapBut = "Carbonite",
	RaidTrackerAceMMI = "Raid Tracker",
	TellTrackAceMMI = "Tell Track",
}

--[[

--]]
local noop = function() end

local GetPosition = function(angle, radius)
	if (angle < 0) then
		angle = 360 + angle
	end

	angle = angle % 360

	local bx = cos(angle) * radius
	local by = sin(angle) * radius

	return bx, by
end

local setPosition = function(frame, angle)
	local radius = (Minimap:GetWidth() / 2) + 10 -- << Radius
	local bx, by = GetPosition(angle, radius)

	frame:ClearAllPoints()
	frame:SetPoint("CENTER", Minimap, "CENTER", bx, by)
end

do
	local OnFinished = function(anim)
		-- Minimap or Minimap icons including nil checks to compensate for other addons
		local f, focus = anim:GetParent(), GetMouseFocus()
		if focus and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			f:SetAlpha(1)
		else
			f:SetAlpha(0)
		end
	end

	local fadeStop -- Use a variable to prevent fadeout/in when moving the mouse around minimap/icons

	local OnEnter = function()
		if fadeStop or moving then return end

		for _,f in pairs(animFrames) do
			local n = f:GetName()

			local delayed = f.smAlphaAnim:IsDelaying()
			f.smAnimGroup:Stop()

			if not delayed then
				f:SetAlpha(0)
				f.smAlphaAnim:SetStartDelay(0)
				f.smAlphaAnim:SetChange(1)
				f.smAnimGroup:Play()
			end
		end
	end

	local OnLeave = function()
		if moving then return end
		local focus = GetMouseFocus() -- Minimap or Minimap icons including nil checks to compensate for other addons

		if focus and ((focus:GetName() == "Minimap") or (focus:GetParent() and focus:GetParent():GetName() and focus:GetParent():GetName():find("Mini[Mm]ap"))) then
			fadeStop = true
			return
		end
		fadeStop = nil

		for _,f in pairs(animFrames) do
			local n = f:GetName()

			f.smAnimGroup:Stop()
			f:SetAlpha(1)
			f.smAlphaAnim:SetStartDelay(0.5)
			f.smAlphaAnim:SetChange(-1)
			f.smAnimGroup:Play()
		end
	end

	function BT:NewFrame(f)
		local n = f:GetName()

		-- Only add Blizz buttons, addon buttons & LibDBIcon buttons
		if addonButtons[n] or n:find("LibDBIcon") then
			-- Create the animations
			f.smAnimGroup = f:CreateAnimationGroup()
			f.smAlphaAnim = f.smAnimGroup:CreateAnimation("Alpha")
			f.smAlphaAnim:SetOrder(1)
			f.smAlphaAnim:SetDuration(0.3)
			f.smAnimGroup:SetScript("OnFinished", OnFinished)
			tinsert(animFrames, f)

			-- Configure fading
			self:ChangeFrameVisibility(f)

			-- Some non-LibDBIcon addon buttons don't set the strata properly and can appear behind things
			-- LibDBIcon sets the strata to MEDIUM and the frame level to 8, so we do the same to other buttons
			if addonButtons[n] then
				f:SetFrameStrata("MEDIUM")
				f:SetFrameLevel(8)
			end

			self:MakeMovable(f)
		elseif (MM.db and MM.db.buttons and MM.db.buttons[n]) then
			local db = MM.db.buttons[n]

			if (db.angle) then
				setPosition(f, db.angle)
			else
				f:SetPoint(db.anchorat, Minimap, db.anchorto, db.posx, db.posy)
			end
		end

		f:HookScript("OnEnter", OnEnter)
		f:HookScript("OnLeave", OnLeave)
	end

	function BT:ChangeFrameVisibility(frame)
		if frame.oldHide then
			frame.Hide = frame.oldHide
			frame.oldHide = nil
		end

		if frame.oldShow then
			frame.Show = frame.oldShow
			frame.oldShow = nil
		end

		frame:Show()
		frame:SetAlpha(0)
	end

	ButtonFadeOut = OnLeave
end

do
	local dragFrame = CreateFrame("Frame")

	local getCurrentAngle = function(parent, bx, by)
		local mx, my = parent:GetCenter()

		if not mx or not my or not bx or not by then return 0 end

		local h, w = (by - my), (bx - mx)

		if w == 0 then
			w = 0.001
		end -- Prevent /0

		local angle = atan(h / w)

		if w < 0 then
			angle = angle + 180
		end
		return angle
	end

	local updatePosition = function()
		local x, y = GetCursorPosition()
		x, y = x / Minimap:GetEffectiveScale(), y / Minimap:GetEffectiveScale()
		local angle = getCurrentAngle(Minimap, x, y)

		MM.db.dragPositions[moving:GetName()] = angle

		setPosition(moving, angle)
	end

	local OnDragStart = function(frame)
		moving = frame
		dragFrame:SetScript("OnUpdate", updatePosition)
	end

	local OnDragStop = function()
		dragFrame:SetScript("OnUpdate", nil)
		moving = nil

		ButtonFadeOut() -- Call the fade out function
	end

	function BT:MakeMovable(frame, altFrame)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")

		if altFrame then
			frame:SetScript("OnDragStart", function()
				moving = altFrame
				dragFrame:SetScript("OnUpdate", updatePosition)
			end)
		else
			frame:SetScript("OnDragStart", OnDragStart)
		end

		frame:SetScript("OnDragStop", OnDragStop)
		self:UpdateDraggables(altFrame or frame)
	end

	function BT:UpdateDraggables(frame)
		if frame then
			local x, y = frame:GetCenter()
			local angle = MM.db.dragPositions[frame:GetName()] or getCurrentAngle(frame:GetParent(), x, y)

			if angle then
				setPosition(frame, angle)
			end
		else
			for _,f in pairs(animFrames) do
				local n = f:GetName()

				-- Don't move the Clock or Zone Text when changing shape/preset
				if n ~= "MinimapZoneTextButton" and n ~= "TimeManagerClockButton" then
					local x, y = f:GetCenter()
					local angle = MM.db.dragPositions[n] or getCurrentAngle(f:GetParent(), x, y)

					if angle then
						setPosition(f, angle)
					end
				end
			end
		end
	end
end
