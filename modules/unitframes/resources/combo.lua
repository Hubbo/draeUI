--[[


--]]
local _, ns = ...
local oUF = ns.oUF or oUF

local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Localise a bunch of functions
local _G = _G
local format, unpack = string.format, unpack
local CreateFrame, UnitLevel, UnitPower, UnitPowerMax, InCombatLockdown = CreateFrame, UnitLevel, UnitPower, UnitPowerMax, InCombatLockdown
local UnitExists, GetComboPoints = UnitExists, GetComboPoints

--[[
		Rogue/Druid combo points
--]]
do
	MAX_COMBO_POINTS = 5
	local spacedWidth = 18

	local OnEvent = function(self, event)
		local rs = self.resourceBar

		if (event == "PLAYER_REGEN_DISABLED") then
			if (rs.animHideSelf:IsPlaying()) then rs.animHideSelf:Stop() end
			rs:SetAlpha(1.0)
		else
			if (rs.animHideSelf:IsPlaying()) then rs.animHideSelf:Stop() end
			rs:SetAlpha(1.0)
		end
	end

	UF.CreateComboPointBar = function(self, point, anchor, relpoint, xOffset, yOffset)
		if (T.playerClass ~= "ROGUE" and T.playerClass ~= "DRUID") then return end

		local rs = CreateFrame("Frame", nil, self)
		rs:SetFrameLevel(12)
		rs:SetPoint(point, anchor, relpoint, 0, 8)
		rs:SetSize((MAX_COMBO_POINTS * spacedWidth) + spacedWidth, 32)
		rs:SetScale(1.2)
		rs:SetAlpha(0)

		rs.animHideSelf = rs:CreateAnimationGroup()
		local hideBar = rs.animHideSelf:CreateAnimation("Alpha")
		hideBar:SetChange(-0.5)
		hideBar:SetDuration(0.3)
		hideBar:SetOrder(1)
		rs.animHideSelf:SetScript("OnFinished", function()
			rs:SetAlpha(0)
		end)

		rs.animShow = {}
		rs.animHide = {}

		for i = 1, MAX_COMBO_POINTS do
			rs[i] = CreateFrame("Frame", nil, rs)
			rs[i]:SetPoint("LEFT", spacedWidth * (i - 1), 0)
			rs[i]:SetSize(32, 32)

			local bg = rs[i]:CreateTexture(nil, "ARTWORK")
			bg:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\arcanecharge")
			bg:SetTexCoord(0, 0.5, 0, 0.5)
			bg:SetAllPoints()
			rs[i].bg = bg

			local glow = rs[i]:CreateTexture(nil, "OVERLAY")
			glow:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\arcanecharge")
			glow:SetTexCoord(0, 0.5, 0.5, 1.0)
			glow:SetAllPoints()
			glow:SetAlpha(0)
			rs[i].glow = glow
		end

		self.CPoints = rs
		self.resourceBar = rs

		self:RegisterEvent("PLAYER_REGEN_DISABLED", OnEvent, true)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", OnEvent, true)
	end
end
