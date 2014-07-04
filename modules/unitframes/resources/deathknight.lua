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
		Deathknight
		This uses the libring library to create some fancy run cooldown animations
--]]
do
	local GameTooltip, RuneFrame = GameTooltip, RuneFrame

	local Rune_OnEnter = function(self)
		if (self.tooltipText) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltipText)
			GameTooltip:Show()
		end
	end

	local Rune_OnLeave = function(self)
		GameTooltip:Hide()
	end

	UF.CreateRuneBar = function(self, point, anchor, relpoint, xOffset, yOffset)
		if (T.playerClass ~= "DEATHKNIGHT") then return end

		-- Remove Blizzard runeframe
		RuneFrame.Show = RuneFrame.Hide
		RuneFrame:UnregisterAllEvents()
		RuneFrame:Hide()

		local spacing = 15
		local size = 24

		local rs = CreateFrame("Frame", nil, self)
		rs:SetFrameLevel(12)
		rs:SetSize((size * 6) + (spacing * 5), size)
		rs:SetPoint(point, anchor, relpoint, xOffset, yOffset)

		for i = 1, 6 do
			local rune = CreateFrame("Frame", nil, rs)
			rune:SetSize(size, size)

			local bg = CreateFrame("Frame", nil, rune)
			bg:SetSize(256, 256) -- Fudge to keep positioning with ringbars
			bg:SetPoint("CENTER", rune, "CENTER")
			bg:SetScale(0.16)

			local bgt = bg:CreateTexture(nil, "BACKGROUND")
			bgt:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\runebg")
			bgt:SetAllPoints(bg)
			rune.bg = bg

			rune.tex = rune:CreateTexture(nil, "ARTWORK")
			rune.tex:SetAllPoints(rune)

			if (i == 1) then
				rune:SetPoint("LEFT", rs, "LEFT", 0, 0)
			else
				rune:SetPoint("LEFT", rs[i - 1], "RIGHT", spacing, 0)
			end

			rune:SetScript("OnEnter", Rune_OnEnter)
			rune:SetScript("OnLeave", Rune_OnLeave)

			rs[i] = rune
		end

		self.Runebar 		= rs
		self.resourceBar 	= rs
	end
end
