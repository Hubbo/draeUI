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
		Mage
		Custom arcane charge and power bar
--]]
do
	local MANA_GEM_MANA_RETURN = 47250
	local MAX_ARCANE_CHARGES = 4

	local spacedWidth = 18
	local charges = 0

	local mageStatusColour = {
		[1] = { 0.32, 1.00, 0.00 },
		[2] = { 1.00, 0.99, 0.00 },
		[3] = { 1.00, 0.73, 0.00 },
		[4] = { 1.00, 0.32, 0.00 },
		[5] = { 1.00, 0.00, 0.00 },
	}

	local OnEvent = function(self, event, unit)
		if (event == "UNIT_AURA" and InCombatLockdown()) then return end
		local rs = self.resourceBar
		local pp = self.ExtraPower

		local name, _, _, curCharges = UnitAura("player", "Arcane Charge", nil, "HARMFUL")

		if (event == "PLAYER_REGEN_DISABLED" or (charges == 0 and (curCharges and curCharges > 0 or curCharges == nil))) then
			if (rs.animHideSelf:IsPlaying()) then rs.animHideSelf:Stop() end
			rs:SetAlpha(1.0)
			pp:Show()
		elseif ((curCharges and curCharges == 0 or curCharges == nil) and charges > 0) then
			if (rs.animHideSelf:IsPlaying()) then rs.animHideSelf:Stop() end
			rs:SetAlpha(0)
			pp:Hide()
		end

		charges = curCharges or 0
	end

	local UpdateMageManaColor = function(pp, unit, curMana, maxMana)
		local pct = curMana / maxMana

		local r, g, b, t

		if (pct >= 0.95) then
			t = mageStatusColour[1]
		elseif (pct >= 0.9) then
			t = mageStatusColour[2]
		elseif (pct >= 0.85) then
			t = mageStatusColour[3]
		elseif (pct >= 0.8) then
			t = mageStatusColour[4]
		else
			t = mageStatusColour[5]
		end

		r, g, b = unpack(t)

		pp:SetStatusBarColor(r, g, b)
		pp.bg:SetVertexColor(r * 0.33, g * 0.33, b * 0.33)
	end

	local UpdateArcaneCharges = function(self, event, unit)
		local rs = self.resourceBar

		local name, _, _, count = UnitAura("player", "Arcane Charge", nil, "HARMFUL")

		for i = 1, MAX_ARCANE_CHARGES do
			if (name) then
				if (i <= count) then
					rs[i].glow:SetAlpha(1.0)
				else
					rs[i].glow:SetAlpha(0)
				end
			else
				rs[i].glow:SetAlpha(0)
			end
		end
	end

	local PlayerSpecChanged = function(self)
		local pp = self.ExtraPower
		local rs = self.resourceBar

		local spec = GetSpecialization()

		if (spec == 1) then
			local maxMana = UnitPowerMax("player")

			-- Mark mana gem use
			local manaGemPos = T.db["frames"].largeWidth - (T.db["frames"].largeWidth * ((maxMana - MANA_GEM_MANA_RETURN) / maxMana))

			pp.gemUse = pp:CreateTexture(nil, "OVERLAY")
			pp.gemUse:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
			pp.gemUse:SetVertexColor(1.0, 1.0, 1.0)
			pp.gemUse:SetWidth(1)
			pp.gemUse:SetHeight(pp:GetHeight())
			pp.gemUse:ClearAllPoints()
			pp.gemUse:SetPoint("BOTTOMRIGHT", pp, "BOTTOMRIGHT", -manaGemPos, 0)
			pp.gemUse:Show()

			-- Mark evo use
			local evoPos = T.db["frames"].largeWidth - (T.db["frames"].largeWidth * ((maxMana * 0.4) / maxMana))

			pp.evoUse = pp:CreateTexture(nil, "OVERLAY")
			pp.evoUse:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
			pp.evoUse:SetVertexColor(1.0, 1.0, 1.0)
			pp.evoUse:SetWidth(1)
			pp.evoUse:SetHeight(pp:GetHeight())
			pp.evoUse:ClearAllPoints()
			pp.evoUse:SetPoint("BOTTOMRIGHT", pp, "BOTTOMRIGHT", -evoPos, 0)
			pp.evoUse:Show()

			pp.PostUpdate = UpdateMageManaColor

			self:RegisterEvent("PLAYER_REGEN_DISABLED", OnEvent, true)
			self:RegisterEvent("PLAYER_REGEN_ENABLED", OnEvent, true)
			self:RegisterEvent("UNIT_AURA", OnEvent)
			self:RegisterEvent("UNIT_AURA", UpdateArcaneCharges)

			rs:Show()
			UpdateArcaneCharges(self)
		else
			rs:Hide()
			pp:Hide()

			self:UnregisterEvent("PLAYER_REGEN_DISABLED", OnEvent)
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", OnEvent)
			self:UnregisterEvent("UNIT_AURA", OnEvent)
			self:UnregisterEvent("UNIT_AURA", UpdateArcaneCharges)

			pp.PostUpdate = nil
			pp.gemUse = nil
			pp.evoUse = nil
		end
	end

	UF.CreateArcaneChargeBar = function(self, point, anchor, relpoint, xOffset, yOffset)
		if (T.playerClass ~= "MAGE") then return end

		local rs = CreateFrame("Frame", nil, self)
		rs:SetFrameLevel(12)
		rs:SetPoint(point, anchor, relpoint, 0, 12)
		rs:SetSize((MAX_ARCANE_CHARGES * spacedWidth) + spacedWidth, 32)
		rs:SetScale(1.3)
		rs:Hide()

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

		for i = 1, MAX_ARCANE_CHARGES do
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

		-- Extra power bar
		local pp = UF.CreateExtraPowerBar(self, point, anchor, relpoint, 0, 32)

		self.resourceBar = rs
		self.ExtraPower = pp

		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", PlayerSpecChanged, true)

		-- Run stuff that requires us to be in-game before it returns any
		-- meaningful results
		local enterWorld = CreateFrame("Frame")
		enterWorld:RegisterEvent("PLAYER_ENTERING_WORLD")
		enterWorld:SetScript("OnEvent", function()
			PlayerSpecChanged(self)
			UpdateArcaneCharges(self)
			enterWorld:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end)
	end
end
