--[[


--]]

local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Target frame
local StyleDrae_Target = function(frame, unit, isSingle)
	UF.CommonInit(frame)

	local fbg = CreateFrame("Frame", nil, frame)
	fbg:SetFrameStrata("BACKGROUND")
	fbg:SetSize(277, 106)
	fbg:SetPoint("LEFT", frame, "LEFT", -34, -6)

	local tex = fbg:CreateTexture(nil, "BORDER", nil, 0)
	tex:SetTexCoord(0.0, 0.540, 0, 0.411)
	tex:SetAllPoints(fbg)
	tex:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\Sword")

	tex.overlay = fbg:CreateTexture(nil, "BORDER", nil, 7)
	tex.overlay:SetSize(199, 103)
	tex.overlay:SetTexCoord(0.541, 0.933, 0, 0.411)
	tex.overlay:SetPoint("LEFT", fbg, "LEFT", 0, 0)
	tex.overlay:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\Sword")
	tex.overlay:Hide()

	frame.Sword = tex

	frame.healthHeight = T.db["frames"].largeHeight - 4.25
	frame.Health = UF.CreateHealthBar(frame, frame.healthHeight)
	frame.Power = UF.CreatePowerBar(frame, 3)

	-- The number here is the size of the raid icon
	UF.CommonPostInit(frame, 30)

	-- Dragon texture on rare/elite
	frame.Classification = {}

	local cl = CreateFrame("Frame", nil, frame)
	cl:SetSize(70, 70)
	cl:SetPoint("TOPLEFT", frame.Health, "TOPRIGHT", -36, 24)

	local dragonElite = cl:CreateTexture(nil, "OVERLAY")
	dragonElite:SetAllPoints(cl)
	dragonElite:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\EliteLeft")
	dragonElite:Hide()
	frame.Classification.elite = dragonElite

	local dragonRare = cl:CreateTexture(nil, "OVERLAY")
	dragonRare:SetAllPoints(cl)
	dragonRare:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\RareLeft")
	dragonRare:Hide()
	frame.Classification.rare = dragonRare

	frame.Health.value = T.CreateFontObject(frame.Health, T.db["media"].fontsize1, T.db["media"].font, "RIGHT", -4, 10)

	local info = T.CreateFontObject(frame.Health, T.db["media"].fontsize1, T.db["media"].font, "LEFT", 4, -15)
	info:SetSize(T.db["frames"].largeWidth - 4, 20)
	frame:Tag(info, "[level][shortclassification] [drae:unitcolour][name][drae:afk]")

	local powervalue = T.CreateFontObject(frame.Health, T.db["media"].fontsize1, T.db["media"].font, "LEFT", 4, 10)
	frame:Tag(powervalue, "[drae:power]")

	-- Flags for PvP, leader, etc.
	UF.FlagIcons(frame)

	-- Auras
	UF.AddBuffs(frame, "BOTTOMLEFT", frame, "TOPLEFT", -1, 20, T.db["frames"].auras.maxTargetBuff or 4, T.db["frames"].auras.auraLrg, 10, "RIGHT", "UP")
	UF.AddDebuffs(frame, "BOTTOMRIGHT", frame, "TOPRIGHT", 1, 20, T.db["frames"].auras.maxTargetDebuff or 15, T.db["frames"].auras.auraSml, 10, "LEFT", "UP")

	-- Castbar
	local cbt = T.db["castbar"].target
	UF.CreateCastBar(frame, cbt.width, cbt.height, cbt.anchor, cbt.anchorat, cbt.anchorto, cbt.xOffset, cbt.yOffset, false, false, false)

	if (isSingle) then
		frame:SetSize(T.db["frames"].largeWidth, T.db["frames"].largeHeight)
	end
end

oUF:RegisterStyle("DraeTarget", StyleDrae_Target)
