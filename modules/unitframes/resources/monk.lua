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
		Monk
		This handles Chi, ExtraPower and mana regen via stacks of mana tea
--]]
do
	local SPELL_POWER_CHI = SPELL_POWER_CHI
	local chi = 0

	local OnPower = function(self, event, unit, powerType)
		if (powerType ~= "CHI" or InCombatLockdown()) then return end

		local rs = self.resourceBar
		local pp = self.ExtraPower
		local curChi = UnitPower("player", SPELL_POWER_CHI)

		if (curChi == 0) then
			rs:SetAlpha(0)
			pp:Hide()
		elseif (chi == 0 and curChi > 0) then
			rs:SetAlpha(1.0)
			pp:Show()
		end

		chi = curChi
	end

	local OnEvent = function(self, event, arg1, arg2)
		local rs = self.resourceBar
		local pp = self.ExtraPower

		if (InCombatLockdown() or event == "PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("UNIT_POWER", OnPower)

			rs:SetAlpha(1.0)
			pp:Show()
		else
			self:RegisterEvent("UNIT_POWER", OnPower)

			OnPower(self, nil, unit, "CHI")
		end
	end

	local UpdateChi = function(self, event, unit, powerType)
		if (unit ~= "player" ) then return end

		local chi = self.resourceBar
		local curChi = UnitPower(unit, SPELL_POWER_CHI)

		for i = 1, UnitPowerMax(unit, SPELL_POWER_CHI) do
			local isShown = ((chi[i].lit:GetAlpha() > 0 and not chi[i].animHide:IsPlaying()) or chi[i].animShow:IsPlaying()) and true or false
			local shouldShow = i <= curChi and true or false

			if (isShown ~= shouldShow) then
				if (isShown) then
					chi[i].animHide:Play()
				else
					chi[i].animShow:Play()
				end
			end
		end
	end

	local UpdateMonkRegen, UpdateMonkManaRegen, UpdateMonkManaTea
	do
		local manaRegenBase, manaRegenCombat, manaTeaStacks

		UpdateMonkRegen = function(self, event, unit)
			manaRegenBase, manaRegenCombat = GetManaRegen()
		end

		UpdateMonkManaTea = function(self, event, unit)
			local name, _, _, stacks = UnitAura("player", "Mana Tea")

			if (stacks ~= manaTeaStacks) then
				local pp = self.ExtraPower
				local maxMana, curMana = UnitPowerMax("player"), UnitPower("player")

				manaTeaStacks = stacks
				UpdateMonkManaRegen(pp, unit, curMana, maxMana)
			end
		end

		UpdateMonkManaRegen = function(pp, unit, curMana, maxMana)
			if (manaTeaStacks) then
				local manaReturn = 0.04 * maxMana * manaTeaStacks

				if (InCombatLockdown()) then
					manaReturn = manaReturn + (manaRegenCombat * manaTeaStacks * 0.5)
				else
					manaReturn = manaReturn + (manaRegenBase * manaTeaStacks * 0.5)
				end

				if (curMana + manaReturn >= maxMana) then
					manaReturn = maxMana - curMana
					pp.manaExcess:Show()
				else
					pp.manaExcess:Hide()
				end

				pp.mana:SetMinMaxValues(0, maxMana)
				pp.mana:SetValue(manaReturn)

				if (pp._manaRegen ~= true) then
					pp.mana:Show()
					pp._manaRegen = true
				end
			elseif (pp._manaRegen) then
				pp.mana:Hide()
				pp.manaExcess:Hide()

				pp._manaRegen = nil
			end
		end
	end

	local UpdateChiPositions = function(self)
		local rs = self.resourceBar

		local maxChi = UnitPowerMax("player", SPELL_POWER_CHI)

		if (rs.maxChi ~= maxChi) then
			for i = 1, maxChi do
				if (i == 1) then
					rs[i]:SetPoint("LEFT", maxChi == 5 and 8 or 28, -2)
				else
					rs[i]:SetPoint("LEFT", rs[i - 1], "RIGHT", 10, 0)
				end
				rs[i]:SetAlpha(1.0)
			end

			if (rs.maxChi == 5) then
				rs[5]:SetAlpha(0)
			end

			rs.maxChi = maxChi
		end
	end

	local PlayerSpecChanged = function(self)
		local pp = self.ExtraPower
		local spec = GetSpecialization()

		-- Mistweaver? Enable mana feedback
		if (spec == 2) then
			pp.PostUpdate = UpdateMonkManaRegen
			self:RegisterEvent("UNIT_AURA", UpdateMonkManaTea)

			UpdateMonkManaTea(self)
		else
			self:UnregisterEvent("UNIT_AURA", UpdateMonkManaTea)
			pp.PostUpdate = nil
		end
	end

	UF.CreateMonkBar = function(self, point, anchor, relpoint, xOffset, yOffset)
		if (T.playerClass ~= "MONK") then return end

		MonkHarmonyBar.Show = MonkHarmonyBar.Hide
		MonkHarmonyBar:UnregisterAllEvents()
		MonkHarmonyBar:Hide()

		local rs = CreateFrame("Frame", nil, self)
		rs:SetFrameLevel(12)
		rs:SetPoint(point, anchor, relpoint, xOffset, yOffset)
		rs:SetSize(256 * 0.8, 128 * 0.8)
		rs:SetAlpha(0)

		local t = rs:CreateTexture(nil, "ARTWORK", self, -5)
		t:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\MonkDragonBar")
		t:SetAllPoints()

		rs.maxLight 	= 0
		rs.animShow 	= {}
		rs.animHide 	= {}

		for i = 1, 5 do
			rs[i] = CreateFrame("Frame", nil, rs)
			rs[i]:SetSize(30, 30)
			rs[i]:SetAlpha(0)

			local r = rs[i]:CreateTexture(nil, "ARTWORK")
			r:SetTexture("Interface\\PlayerFrame\\MonkUI")
			r:SetTexCoord(0.09375000, 0.17578125, 0.71093750, 0.87500000)
			r:SetAllPoints(rs[i])

			local r2 = rs[i]:CreateTexture(nil, "OVERLAY")
			r2:SetTexture("Interface\\PlayerFrame\\MonkUI")
			r2:SetTexCoord(0.00390625, 0.08593750, 0.71093750, 0.87500000)
			r2:SetAllPoints(rs[i])
			r2:SetAlpha(0)
			rs[i].lit = r2

			rs[i].animShow = rs[i].lit:CreateAnimationGroup()
			local showPoint = rs[i].animShow:CreateAnimation("Alpha")
			showPoint:SetChange(1)
			showPoint:SetDuration(0.2)
			showPoint:SetOrder(1)
			rs[i].animShow:SetScript("OnFinished", function()
				rs[i].lit:SetAlpha(1.0)
			end)

			rs[i].animHide = rs[i].lit:CreateAnimationGroup()
			local hidePoint = rs[i].animHide:CreateAnimation("Alpha")
			hidePoint:SetChange(-1.0)
			hidePoint:SetDuration(0.2)
			hidePoint:SetOrder(1)
			rs[i].animHide:SetScript("OnFinished", function()
				rs[i].lit:SetAlpha(0)
			end)
		end

		local pp = UF.CreateExtraPowerBar(self, point, anchor, relpoint)

		-- Mana feedback
		local ppmana = CreateFrame("StatusBar", nil, pp)
		ppmana:SetHeight(12)
		ppmana:SetWidth(T.db["frames"].largeWidth)
		ppmana:SetStatusBarTexture(T.db["media"].texture, "BORDER")
		ppmana:SetPoint("TOPLEFT", pp:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		ppmana:SetPoint("BOTTOMLEFT", pp:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
		ppmana:SetStatusBarColor(0.8, 0.8, 0.8, 0.75)
		ppmana:Hide()
		pp.mana = ppmana

		local excessMana = pp:CreateTexture(nil, "OVERLAY")
		excessMana:SetTexture(1.0, 1.0, 1.0, 0.75) -- Always white
		excessMana:SetBlendMode("ADD")
		excessMana:SetPoint("TOP")
		excessMana:SetPoint("BOTTOM")
		excessMana:SetPoint("RIGHT")
		excessMana:SetWidth(2)
		excessMana:Hide()
		pp.manaExcess = excessMana

		self.resourceBar 				= rs
		self.ClassIcons					= rs
		self.ClassIcons.Override 		= UpdateChi
		self.ClassIcons.UpdateTexture 	= function() end
		self.ExtraPower 				= pp

		self:RegisterEvent("PLAYER_TALENT_UPDATE", UpdateChiPositions, true)

		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", PlayerSpecChanged, true)

		self:RegisterEvent("FORGE_MASTER_ITEM_CHANGED", UpdateMonkRegen, true)
		self:RegisterEvent("ITEM_UPGRADE_MASTER_UPDATE", UpdateMonkRegen, true)
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", UpdateMonkRegen, true)

		self:RegisterEvent("PLAYER_REGEN_DISABLED", OnEvent, true)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", OnEvent, true)

		-- Run stuff that requires us to be in-game before it returns any
		-- meaningful results
		local enterWorld = CreateFrame("Frame")
		enterWorld:RegisterEvent("PLAYER_ENTERING_WORLD")
		enterWorld:SetScript("OnEvent", function()
			UpdateMonkRegen(self)
			UpdateChiPositions(self)
			PlayerSpecChanged(self)
			OnEvent(self)
		end)
	end
end
