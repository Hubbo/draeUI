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
		Paladin
		This hijacks the existing Blizzard power bar and builds
		around it - includes extra power bar for Holy specs
		TODO: Mana regen for Holy?
--]]
do
	local SPELL_POWER_HOLY_POWER, PALADINPOWERBAR_SHOW_LEVEL = SPELL_POWER_HOLY_POWER, PALADINPOWERBAR_SHOW_LEVEL
	local hopo = 0

	local OnPower = function(self, event, unit, powerType)
		if (powerType ~= "HOLY_POWER" or InCombatLockdown()) then return end

		local rs = self.resourceBar
		local pp = self.ExtraPower
		local curHopo = UnitPower("player", SPELL_POWER_HOLY_POWER)

		if (curHopo == 0) then
			rs:SetAlpha(0)
			if (not pp._hide) then
				pp:Hide()
			end
		elseif (hopo == 0 and curHopo > 0) then
			rs:SetAlpha(1.0)
			if (not pp._hide) then
				pp:Show()
			end
		end

		hopo = curHopo
	end

	local OnEvent = function(self, event)
		local rs = self.resourceBar
		local pp = self.ExtraPower

		if (InCombatLockdown() or event == "PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("UNIT_POWER", OnPower)

			rs:SetAlpha(1.0)
			if (not pp._hide) then
				pp:Show()
			end
		else
			self:RegisterEvent("UNIT_POWER", OnPower)

			OnPower(self, nil, unit, "HOLY_POWER")
		end
	end

	local UpdatePaladinRegen, UpdatePaladinManaRegen, UpdateDivinePleaUseable
	do
		local manaRegenBase, manaRegenCombat, baseSpirit, divinePleaUseable
		local divinePleaTimer = CreateFrame("Frame")

		UpdatePaladinRegen = function(self, event, unit)
			manaRegenBase, manaRegenCombat = GetManaRegen()
			baseSpirit = select(2, UnitStat("player", 5))
		end

		UpdateDivinePleaUseable = function(self, event)
			local start, duration, _ = GetSpellCooldown("Divine Plea")

			-- The GCD causes issues here so check for > 1.5 duration
			local testPlea = true
			if (start and duration > 1.5) then
				testPlea = false
			end

			if (testPlea ~= divinePleaUseable) then
				divinePleaUseable = testPlea

				-- Because it's not really "possible" to obtain accurate
				-- cooldown information we're going to use a timer here
				if (not divinePleaUseable) then
					local waitFor = start - GetTime() + duration
					local refresh = 0

					divinePleaTimer:SetScript("OnUpdate", function(frame, elapsed)
						if (refresh > waitFor) then
							divinePleaTimer:SetScript("OnUpdate", nil)
							UpdateDivinePleaUseable(self)
						end
						refresh = refresh + elapsed
					end)
				end

				local pp = self.ExtraPower
				local maxMana, curMana = UnitPowerMax("player"), UnitPower("player")

				UpdatePaladinManaRegen(pp, "player", curMana, maxMana)
			end
		end

		UpdatePaladinManaRegen = function(pp, unit, curMana, maxMana)
			if (divinePleaUseable) then
				local manaReturn = baseSpirit * 1.35 * 3
				manaReturn = math.max(manaReturn, maxMana * 0.12)

				if (InCombatLockdown()) then
					manaReturn = manaReturn + manaRegenCombat * 9
				else
					manaReturn = manaReturn + manaRegenBase * 9
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

	-- Store the current spec in ExtraPower._spec so we can avoid
	-- showing the extrapower bar, etc. for non-holy specs
	local PlayerSpecChanged = function(self, event, unit)
		local pp = self.ExtraPower
		local spec = GetSpecialization()

		-- Holy? Enable mana regen and shizzle
		if (spec == 1) then
			pp.PostUpdate = UpdatePaladinManaRegen

			self:RegisterEvent("SPELL_UPDATE_USABLE", UpdateDivinePleaUseable, true)

			UpdatePaladinRegen(self)
			UpdateDivinePleaUseable(self)

			pp._hide = false
		else
			pp.PostUpdate = nil

			self:UnregisterEvent("SPELL_UPDATE_USABLE", UpdateDivinePleaUseable, true)

			pp._hide = true
		end
	end

	local EnablePaladinPowerBar = function(self)
		if (UnitLevel("player") >= PALADINPOWERBAR_SHOW_LEVEL) then
			self:RegisterEvent("PLAYER_REGEN_DISABLED", OnEvent, true)
			self:RegisterEvent("PLAYER_REGEN_ENABLED", OnEvent, true)

			PlayerSpecChanged(self)
		end
	end

	UF.CreateHolyPowerBar = function(self, point, anchor, relpoint, xOffset, yOffset)
		if (T.playerClass ~= "PALADIN") then return end

		local scale = 1.35

		local rs = CreateFrame("Frame", nil, self)
		rs:SetFrameLevel(12)
		rs.unit = "player"

		_G["PaladinPowerBar"]:SetParent(rs)
		_G["PaladinPowerBar"]:EnableMouse(false)
		_G["PaladinPowerBar"]:ClearAllPoints()
		_G["PaladinPowerBar"]:SetPoint(point, anchor, relpoint, xOffset / scale, yOffset / scale)
		_G["PaladinPowerBar"]:SetScale(scale)
		rs:SetAlpha(0)

		_G["PaladinPowerBarBG"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\PaladinHolyPower")
		_G["PaladinPowerBarGlowBGTexture"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\PaladinHolyPower")
		_G["PaladinPowerBarRune1Texture"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\PaladinHolyPower")
		_G["PaladinPowerBarRune2Texture"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\PaladinHolyPower")
		_G["PaladinPowerBarRune3Texture"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\PaladinHolyPower")
		_G["PaladinPowerBarRune4Texture"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\PaladinHolyPower")
		_G["PaladinPowerBarRune5Texture"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\PaladinHolyPower")

		-- Create power bar - only displayed for Holy
		local pp = UF.CreateExtraPowerBar(self, point, anchor, relpoint, 0, 32)

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

		self.ExtraPower = pp
		self.resourceBar = rs

		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", PlayerSpecChanged, true)
		self:RegisterEvent("FORGE_MASTER_ITEM_CHANGED", UpdatePaladinRegen, true)
		self:RegisterEvent("ITEM_UPGRADE_MASTER_UPDATE", UpdatePaladinRegen, true)
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", UpdatePaladinRegen, true)
		self:RegisterEvent("PLAYER_LEVEL_UP", EnablePaladinPowerBar, true)

		-- Run stuff that requires us to be in-game before it returns any
		-- meaningful results
		local enterWorld = CreateFrame("Frame")
		enterWorld:RegisterEvent("PLAYER_ENTERING_WORLD")
		enterWorld:SetScript("OnEvent", function()
			PlayerSpecChanged(self)
			EnablePaladinPowerBar(self)
			OnEvent(self)
		end)
	end
end
