--[[
	Basically rMinimap customied a bit!
	zoomscript taken from pminimap by p3lim - http://www.wowinterface.com/downloads/info8389-pT.html
--]]

--
local T, C, G, P, U, _ = unpack(select(2, ...))

local MM = T:GetModule("Minimap")

--
local _G = _G
local Minimap, MinimapCluster, MinimapBackdrop, MinimapPing = _G["Minimap"], _G["MinimapCluster"], _G["MinimapBackdrop"], _G["MinimapPing"]

--
MM.frame = CreateFrame("Frame") -- Animation frame
local pingFrame

--[[
		This is the right click menu
--]]
local menuFrame = CreateFrame("Frame", "MinimapRightClickMenu", UIParent, "UIDropDownMenuTemplate")
local menuList = {
	{text = CHARACTER_BUTTON,
		func = function() ToggleCharacter("PaperDollFrame") end},
	{text = SPELLBOOK_ABILITIES_BUTTON,
		func = function() ToggleFrame(SpellBookFrame) end},
	{text = TALENTS_BUTTON,
		func = function() if not PlayerTalentFrame then LoadAddOn("Blizzard_TalentUI") end PlayerTalentFrame_Toggle() end},
	{text = ACHIEVEMENT_BUTTON,
		func = function() ToggleAchievementFrame() end},
	{text = QUESTLOG_BUTTON,
		func = function() ToggleFrame(QuestLogFrame) end},
	{text = SOCIAL_BUTTON,
		func = function() ToggleFriendsFrame(1) end},
	{text = PLAYER_V_PLAYER,
		func = function() ToggleFrame(PVPFrame) end},
	{text = ACHIEVEMENTS_GUILD_TAB,
		func = function() if IsInGuild() then if not GuildFrame then LoadAddOn("Blizzard_GuildUI") end GuildFrame_Toggle() end end},
	{text = LFG_TITLE,
		func = function() ToggleFrame(LFDParentFrame) end},
	{text = L_LFRAID,
		func = function() ToggleFrame(LFRParentFrame) end},
	{text = HELP_BUTTON,
		func = function() ToggleHelpFrame() end},
	{text = L_CALENDAR,
		func = function()
	if (not CalendarFrame) then LoadAddOn("Blizzard_Calendar") end
		Calendar_Toggle()
	end},
}

local minimapRotate	= {
	[1] = {
		texture 	= "Interface\\AddOns\\draeUI\\media\\textures\\zahnrad", --texturename under media folder --"SPELLS\\AURARUNE256.BLP"
		width 		= 210,
		height 		= 210,
		scale 		= 0.82, --0.95,
		framelevel 	= "0",
		duration 	= 60, --how long should the rotation need to finish 360�
		direction 	= 1, --0 = counter-clockwise, 1 = clockwise
		color_red 	= 48/255, --0.3098039215686275,
		color_green = 44/255, --0.4784313725490196
		color_blue 	= 35/255, --1.0
		alpha 		= 1,
		blendmode 	= "BLEND", --"BLEND", --ADD or BLEND
	},
	[2] = {
		texture 	= "Interface\\AddOns\\draeUI\\media\\textures\\ring", --texturename under media folder
		width 		= 190,
		height 		= 190,
		scale 		= 0.82,
		framelevel 	= "3", --defines the framelevel to overlay or underlay other stuff
		duration 	= 60, --how long should the rotation need to finish 360�
		direction 	= 1, --0 = counter-clockwise, 1 = clockwise
		color_red 	= 0/255,
		color_green = 0/255,
		color_blue 	= 0/255,
		alpha 		= 0.4,
		blendmode 	= "BLEND", --ADD or BLEND
	},
}

--[[

--]]
local noop = function() end

-- Animate the minimap frame
local CreateRotateTextures = function(texture, width, height, scale, framelevel, texr, texg, texb, alpha, duration, side, blendmode)
	local h = CreateFrame("Frame", nil, Minimap)
	h:SetHeight(height)
	h:SetWidth(width)
	h:SetPoint("CENTER", 0, 0)
	h:SetScale(scale)
	h:SetFrameLevel(framelevel)

	local t = h:CreateTexture()
	t:SetAllPoints(h)
	t:SetTexture(texture)
	t:SetBlendMode(blendmode)
	t:SetVertexColor(texr, texg, texb, alpha)

	local ag = h:CreateAnimationGroup()
	local a1 = ag:CreateAnimation("Rotation")

	if (side == 0) then
		a1:SetDegrees(360)
	else
		a1:SetDegrees(-360)
	end
	a1:SetDuration(duration)

	ag:Play()
	ag:SetLooping("REPEAT")
end

do
	local alreadyGrabbed = {}

	local grabFrames = function(...)
		for i=1, select("#", ...) do
			local f = select(i, ...)
			local n = f:GetName()

			if n and not alreadyGrabbed[n] then
				alreadyGrabbed[n] = true
				MM.buttons:NewFrame(f)
			end
		end
	end

	MM.StartFrameGrab = function(self)
		-- Try to capture new frames periodically
		-- We"d use ADDON_LOADED but it"s too early, some addons load a minimap icon afterwards
		local updateTimer = MM.frame:CreateAnimationGroup()
		local anim = updateTimer:CreateAnimation()
		updateTimer:SetScript("OnLoop", function() grabFrames(Minimap:GetChildren()) end)
		anim:SetOrder(1)
		anim:SetDuration(1)
		updateTimer:SetLooping("REPEAT")
		updateTimer:Play()

		-- Grab Icons
		grabFrames(MinimapZoneTextButton, Minimap, MiniMapTrackingButton, TimeManagerClockButton, MinimapBackdrop:GetChildren())
		grabFrames(MinimapCluster:GetChildren())

		self.StartFrameGrab = nil
	end
end

MM.OnEnable = function(self)
	MinimapBackdrop:ClearAllPoints()
	MinimapBackdrop:SetParent(Minimap)
	MinimapBackdrop:SetPoint("CENTER", Minimap, "CENTER", -8, -23)

	Minimap:SetScale(1.1)
	Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -30)

	-- Move the minibackdrop and border
	MinimapBackdrop:SetPoint("CENTER", Minimap, "CENTER", -8, -24)

	-- Change some basic textures
	MinimapBorder:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\UI-Minimap-Border")
	MinimapNorthTag:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\CompassNorthTag")
	MinimapCompassTexture:SetTexture("Interface\\AddOns\\draeUI\\media\textures\\CompassRing")
	MiniMapTrackingButtonBorder:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\MiniMap-TrackingBorder")
	QueueStatusMinimapButtonBorder:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\MiniMap-TrackingBorder")
	MiniMapMailBorder:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\MiniMap-TrackingBorder")

	-- The Pinger
	pingFrame = CreateFrame("Frame", nil, Minimap)
	pingFrame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		insets = {left = 2, top = 2, right = 2, bottom = 2},
		edgeSize = 12,
		tile = true
	})
	pingFrame:SetBackdropColor(0, 0, 0, 0.8)
	pingFrame:SetBackdropBorderColor(0, 0, 0, 0.6)
	pingFrame:SetHeight(20)
	pingFrame:SetWidth(100)
	pingFrame:SetPoint("TOP", Minimap, "TOP", 0, 15)
	pingFrame:SetFrameStrata("HIGH")
	pingFrame.name = pingFrame:CreateFontString(nil, nil, "GameFontNormalSmall")
	pingFrame.name:SetAllPoints()
	pingFrame:Hide()

	local animGroup = pingFrame:CreateAnimationGroup()
	local anim = animGroup:CreateAnimation("Alpha")
	animGroup:SetScript("OnFinished", function() pingFrame:Hide() end)
	anim:SetChange(-1)
	anim:SetOrder(1)
	anim:SetDuration(3)
	anim:SetStartDelay(3)

	pingFrame:SetScript("OnEvent", function(_, _, unit)
		local class = select(2, UnitClass(unit))
		local color = class and RAID_CLASS_COLORS[class] or GRAY_FONT_COLOR

		pingFrame.name:SetFormattedText("|cFF%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, UnitName(unit))
		pingFrame:SetWidth(pingFrame.name:GetStringWidth() + 14)
		pingFrame:SetHeight(pingFrame.name:GetStringHeight() + 10)
		animGroup:Stop()
		pingFrame:Show()
		animGroup:Play()
	end)
	pingFrame:RegisterEvent("MINIMAP_PING")

	-- Clock
	if (TimeManagerClockButton) then
		local timerframe = _G["TimeManagerClockButton"]
		TimeManagerClockTicker:SetFont(NAMEPLATE_FONT, 12, "THINOUTLINE")
		local region1 = timerframe:GetRegions()
		region1:Hide()
	end

	-- Hide other buttons
	MinimapZoomOut:Hide()
	MinimapZoomIn:Hide()
	MinimapZoneTextButton:Hide()
	MinimapBorderTop:Hide()
	MiniMapWorldMapButton:Hide()

	Minimap:EnableMouseWheel()
	Minimap:SetScript("OnMouseWheel", function(self, direction)
		if (direction > 0) then
			Minimap_ZoomIn()
		else
			Minimap_ZoomOut()
		end
	end)

	Minimap:SetScript("OnMouseUp", function(self, btn)
		if (btn == "RightButton") then
			EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
		else
			Minimap_OnClick(self)
		end
	end)

	-- Create  the rotating textures
	for k, _ in ipairs(minimapRotate) do
		local v = minimapRotate[k]
		CreateRotateTextures(v.texture, v.width, v.height, v.scale, v.framelevel, v.color_red, v.color_green, v.color_blue, v.alpha, v.duration, v.direction, v.blendmode)
	end

	-- Grab all the buttons and stuffs
	self:StartFrameGrab()
end

