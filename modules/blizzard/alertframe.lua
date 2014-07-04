--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local B = T:GetModule("Blizzard")

--
local AlertFrameHolder
local POSITION, ANCHOR_POINT, YOFFSET = "TOP", "BOTTOM", -10
local FORCE_POSITION = false

--[[

--]]
B.PostAlertMove = function(self, screenQuadrant)
	AlertFrame:ClearAllPoints()
	AlertFrame:SetAllPoints(AlertFrameHolder)

	if (screenQuadrant) then
		FORCE_POSITION = true
		AlertFrame_FixAnchors()
		FORCE_POSITION = false
	end
end

B.AlertFrame_SetLootAnchors = function(self, alertAnchor)
	--This is a bit of reverse logic to get it to work properly because blizzard was a bit lazy..
	if (MissingLootFrame:IsShown()) then
		MissingLootFrame:ClearAllPoints()
		MissingLootFrame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT)

		if (GroupLootContainer:IsShown()) then
			GroupLootContainer:ClearAllPoints()
			GroupLootContainer:SetPoint(POSITION, MissingLootFrame, ANCHOR_POINT, 0, YOFFSET)
		end
	elseif (GroupLootContainer:IsShown() or FORCE_POSITION) then
		GroupLootContainer:ClearAllPoints()
		GroupLootContainer:SetPoint(POSITION, alertAnchor, ANCHOR_POINT)
	end
end

B.AlertFrame_SetLootWonAnchors = function(self, alertAnchor)
	for i=1, #LOOT_WON_ALERT_FRAMES do
		local frame = LOOT_WON_ALERT_FRAMES[i]

		if (frame:IsShown()) then
			frame:ClearAllPoints()
			frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)

			alertAnchor = frame
		end
	end
end

B.AlertFrame_SetMoneyWonAnchors = function(self, alertAnchor)
	for i=1, #MONEY_WON_ALERT_FRAMES do
		local frame = MONEY_WON_ALERT_FRAMES[i]

		if (frame:IsShown()) then
			frame:ClearAllPoints()
			frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)

			alertAnchor = frame
		end
	end
end

function B:AlertFrame_SetAchievementAnchors(alertAnchor)
	if (AchievementAlertFrame1) then
		for i = 1, MAX_ACHIEVEMENT_ALERTS do
			local frame = _G["AchievementAlertFrame"..i]
			if ( frame and frame:IsShown() ) then
				frame:ClearAllPoints()
				frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)
				alertAnchor = frame
			end
		end
	end
end

B.AlertFrame_SetCriteriaAnchors = function(self, alertAnchor)
	if (CriteriaAlertFrame1) then
		for i = 1, MAX_ACHIEVEMENT_ALERTS do
			local frame = _G["CriteriaAlertFrame"..i]

			if (frame and frame:IsShown()) then
				frame:ClearAllPoints()
				frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)

				alertAnchor = frame
			end
		end
	end
end

B.AlertFrame_SetChallengeModeAnchors = function(self, alertAnchor)
	local frame = ChallengeModeAlertFrame1

	if (frame:IsShown()) then
		frame:ClearAllPoints()
		frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)
	end
end

B.AlertFrame_SetDungeonCompletionAnchors = function(self, alertAnchor)
	local frame = DungeonCompletionAlertFrame1

	if (frame:IsShown()) then
		frame:ClearAllPoints()
		frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)
	end
end

B.AlertFrame_SetScenarioAnchors = function(self, alertAnchor)
	local frame = ScenarioAlertFrame1

	if (frame:IsShown()) then
		frame:ClearAllPoints()
		frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)
	end
end

B.AlertFrame_SetGuildChallengeAnchors = function(self, alertAnchor)
	local frame = GuildChallengeAlertFrame

	if (frame:IsShown()) then
		frame:ClearAllPoints()
		frame:SetPoint(POSITION, alertAnchor, ANCHOR_POINT, 0, YOFFSET)
	end
end

B.AlertMovers = function(self)
	AlertFrameHolder = CreateFrame("Frame", "AlertFrameHolder", UIParent)
	AlertFrameHolder:SetWidth(180)
	AlertFrameHolder:SetHeight(20)
	AlertFrameHolder:SetPoint("TOP", UIParent, "TOP", 0, -18)

	self:SecureHook("AlertFrame_FixAnchors", "PostAlertMove")
	self:SecureHook("AlertFrame_SetLootAnchors")
	self:SecureHook("AlertFrame_SetLootWonAnchors")
	self:SecureHook("AlertFrame_SetMoneyWonAnchors")
	self:SecureHook("AlertFrame_SetAchievementAnchors")
	self:SecureHook("AlertFrame_SetCriteriaAnchors")
	self:SecureHook("AlertFrame_SetChallengeModeAnchors")
	self:SecureHook("AlertFrame_SetDungeonCompletionAnchors")
	self:SecureHook("AlertFrame_SetScenarioAnchors")
	self:SecureHook("AlertFrame_SetGuildChallengeAnchors")

	UIPARENT_MANAGED_FRAME_POSITIONS["GroupLootContainer"] = nil
end
