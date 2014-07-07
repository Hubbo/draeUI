--[[


--]]

local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Player frame
local StyleDrae_Player = function(frame, unit, isSingle)
	UF.CommonInit(frame)

	local fbg = CreateFrame("Frame", nil, frame)
	fbg:SetFrameStrata("BACKGROUND")
	fbg:SetSize(277, 106)
	fbg:SetPoint("RIGHT", frame, "RIGHT", 34, -6)

	local tex = fbg:CreateTexture(nil, "BORDER", nil, 0)
	tex:SetTexCoord(0.0, 0.540, 0.411, 0.831)
	tex:SetAllPoints(fbg)
	tex:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\Sword")

	tex.overlay = fbg:CreateTexture(nil, "BORDER", nil, 7)
	tex.overlay:SetSize(199, 103)
	tex.overlay:SetTexCoord(0.540, 0.933, 0.411, 0.831)
	tex.overlay:SetPoint("RIGHT", fbg, "RIGHT", 0, 0)
	tex.overlay:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\Sword")
	tex.overlay:Hide()

	frame.Sword = tex

	frame.hpHeight = T.db["frames"].largeHeight - 4.25
	frame.Health = UF.CreateHealthBar(frame, frame.hpHeight)
	frame.Power = UF.CreatePowerBar(frame, 3)

	UF.CommonPostInit(frame, 30)

	frame.Health.value = T.CreateFontObject(frame.Health, T.db["media"].fontsize1, T.db["media"].font, "RIGHT", -4, 10)
	local powervalue = T.CreateFontObject(frame.Health, T.db["media"].fontsize1, T.db["media"].font, "LEFT", 4, 10)
	frame:Tag(powervalue, "[drae:power]")

	frame.DruidMana	= UF.CreateDruidManaBar(frame, 3)

	-- PvP, leader, etc.
	UF.FlagIcons(frame)

	-- Combat icon
	local combat = frame.Health:CreateTexture(nil, "OVERLAY")
	combat:SetSize(16, 16)
	combat:SetPoint("TOPLEFT", frame, -12, 10)
	combat:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
	combat:SetTexCoord(0.58, 0.90, 0.08, 0.41)
	frame.Combat = combat

	-- Resting is only of relevance for players < max level
	if (UnitLevel("player") ~= MAX_PLAYER_LEVEL) then
		-- resting icon
		local resting = frame.Health:CreateTexture(nil, "OVERLAY")
		resting:SetSize(20, 20)
		resting:SetPoint("TOPLEFT", frame, -14, 12)
		resting:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
		resting:SetTexCoord(0, 0.5, 0, 0.421875)
		frame.Resting = resting

		frame.Combat.PostUpdate = function(combat, inCombat)
			if (inCombat and combat.__owner.Resting:IsShown()) then
				combat.__owner.Resting:Hide()
				combat.__owner.showResting = true
			elseif (not inCombat and combat.__owner.showResting) then
				combat.__owner.Resting:Show()
				combat.__owner.showResting = false
			end
		end
	end

	-- PvP timer
	UF.AddPvPTimer(frame)

	-- Auras
	UF.AddBuffs(frame, "BOTTOMLEFT", frame, "TOPLEFT", -1, 20, T.db["frames"].auras.maxPlayerBuff or 20, T.db["frames"].auras.auraSml, 10, "RIGHT", "UP")
	UF.AddDebuffs(frame, "BOTTOMRIGHT", frame, "TOPRIGHT", 1, 20, T.db["frames"].auras.maxPlayerDebuff or 6, T.db["frames"].auras.auraLrg, 10, "LEFT", "UP")

	-- Castbars
	local cbp = T.db["castbar"].player
	UF.CreateCastBar(frame, cbp.width, cbp.height, cbp.anchor, cbp.anchorat, cbp.anchorto, cbp.xOffset, cbp.yOffset, T.db["castbar"].showLatency, false, T.db["castbar"].showIcon)

	UF.CreateMirrorCastbars(frame)

	-- Class specific resource bars
	local rbp = T.db["resourcebar"]

	UF.CreateHolyPowerBar(frame, "CENTER", frame, "CENTER", rbp.xOffset, rbp.yOffset)
	UF.CreateEclipseBar(frame, "CENTER", frame, "CENTER", rbp.xOffset, rbp.yOffset)
	UF.CreateRuneBar(frame, "CENTER", frame, "CENTER", rbp.xOffset, rbp.yOffset)
	UF.CreateWarlockBar(frame, "CENTER", frame, "CENTER", rbp.xOffset, rbp.yOffset)
	UF.CreateComboPointBar(frame, "CENTER", frame, "CENTER", rbp.xOffset, rbp.yOffset)
	UF.CreateMonkBar(frame, "CENTER", frame, "CENTER", rbp.xOffset, rbp.yOffset)
	UF.CreatePriestBar(frame, "CENTER", frame, "CENTER", rbp.xOffset, rbp.yOffset)
	UF.CreateArcaneChargeBar(frame, "CENTER", frame, "CENTER", rbp.xOffset, rbp.yOffset)

	-- Various classes now use the totembar
	UF.CreateTotemBar(frame, "TOPRIGHT", frame, "BOTTOMRIGHT", 0, -20)

	if (isSingle) then
		frame:SetSize(T.db["frames"].largeWidth, T.db["frames"].largeHeight)
	end
end

oUF:RegisterStyle("DraePlayer", StyleDrae_Player)
