--[[


--]]

local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

--[[
		Fake prep frames - get hidden when data on the real frames becomes available
--]]
UF.UpdateArenaPrep = function(self, event, unit, status)
	if ((event == "ARENA_OPPONENT_UPDATE" or event == "UNIT_NAME_UPDATE") and unit ~= self.unit) then return end

	local _, instanceType = IsInInstance()

	if (instanceType ~= "arena" or (UnitExists(self.unit) and status ~= "unseen")) then
		self:Hide()
		return
	end

	local id = self.unit and self.unit:sub(6)

	if (id) then
		local s = GetArenaOpponentSpec(id)

		local spec, texture, role, class
		if (s and s > 0) then
			_, spec, _, texture, _, role, class = GetSpecializationInfoByID(s)
		end

		if (class and spec) then
			local color = RAID_CLASS_COLORS[class]
			self.Health:SetStatusBarColor(color.r, color.g, color.b)

			self.Info:SetText(spec)

			if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
				self.LFDRole:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
				self.LFDRole:Show()
			else
				self.LFDRole:Hide()
			end

			self:Show()
		else
			self:Hide()
		end
	else
		self:Hide()
	end
end

-- Arena player frames - basically focus frames with castbars
local StyleDrae_ArenaPlayers = function(frame, unit, isSingle)
	UF.CommonInit(frame)

	frame.Health = UF.CreateHealthBar(frame, T.db["frames"].smallHeight - 3 - 1.5)
	frame.Power = UF.CreatePowerBar(frame, 3)

	frame.Health.value = T.CreateFontObject(frame.Health, T.db["media"].fontsize2, T.db["media"].font, "RIGHT", -4, 12)

	local info = T.CreateFontObject(frame.Health, T.db["media"].fontsize2, T.db["media"].font, "LEFT", 4, -13)
	info:SetWidth(T.db["frames"].smallWidth - 4)
	info:SetHeight(20)
	frame:Tag(info, "[level] [drae:unitcolour][name][drae:afk]")

	UF.CommonPostInit(frame, 20)

	UF.FlagIcons(frame)

	-- Auras
	UF.AddBuffs(frame, "RIGHT", frame, "LEFT", -12, 0, T.db["frames"].auras.maxArenaBuff or 4, T.db["frames"].auras.auraTny, 10, "LEFT", "DOWN", false, 4)

	-- Trinket
	do
		local trinket = CreateFrame("Frame", nil, frame)
		trinket:SetPoint("LEFT", frame, "RIGHT", 12, 0)
		trinket:SetSize(T.db["frames"].auras.auraTny, T.db["frames"].auras.auraTny)

		local border = CreateFrame("Frame", nil, trinket)
		border:SetPoint("TOPLEFT", trinket, -6, 6)
		border:SetPoint("BOTTOMRIGHT", trinket, 6, -6)
		border:SetFrameStrata("BACKGROUND")
		border:SetBackdrop {
			edgeFile = "Interface\\AddOns\\draeUI\\media\\textures\\glowtex",
			tile = false,
			edgeSize = 6
		}
		border:SetBackdropBorderColor(0, 0, 0, 0.5)
		trinket.border = border

		local icon = trinket:CreateTexture(nil, "BACKGROUND")
		icon:SetTexCoord(.07, .93, .07, .93)
		icon:SetPoint("TOPLEFT", trinket, "TOPLEFT", -0.07, 0.93)
		icon:SetPoint("BOTTOMRIGHT", trinket, "BOTTOMRIGHT", 0.07, -0.93)
		trinket.icon = icon

		local cd = CreateFrame("Cooldown", nil, trinket)
		cd:SetReverse(true)
		cd:SetAllPoints(trinket)
		trinket.cd = cd

		local borderFrame = T.CreateBorder(trinket, "small")
		trinket.borderFrame = borderFrame

		frame.Trinket = trinket
	end

	-- Castbar
	local cbf = T.db["castbar"].arena
	UF.CreateCastBar(frame, T.db["frames"].smallWidth, cbf.height, frame, "TOPLEFT", "BOTTOMLEFT", cbf.xOffset, cbf.yOffset, false, false, false, true)

	if (isSingle) then
		frame:SetSize(T.db["frames"].smallWidth, T.db["frames"].smallHeight)
	end

	-- Create fake prepFrame (taken from ElvUI and others)
	if (not frame.prepFrame) then
		frame.prepFrame = CreateFrame("Frame", frame:GetName() .. "PrepFrame", UIParent)
		frame.prepFrame:SetScript("OnEvent", UF.UpdateArenaPrep)
		frame.prepFrame:SetAllPoints(frame)
		frame.prepFrame:SetID(frame:GetID())
		frame.prepFrame.unit = frame.unit

		frame.prepFrame.Health = UF.CreateHealthBar(frame.prepFrame, T.db["frames"].smallHeight)
		frame.prepFrame.Health.value = T.CreateFontObject(frame.prepFrame.Health, T.db["media"].fontsize2, T.db["media"].font, "RIGHT", -4, 12)

		local info = T.CreateFontObject(frame.prepFrame.Health, T.db["media"].fontsize2, T.db["media"].font, "LEFT", 4, -13)
		info:SetWidth(T.db["frames"].smallWidth - 4)
		info:SetHeight(20)
		frame.prepFrame.Info = info

		UF.CommonPostInit(frame.prepFrame, 20, true)

		UF.FlagIcons(frame.prepFrame)

		frame.prepFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame.prepFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
		frame.prepFrame:RegisterEvent("UNIT_NAME_UPDATE")
		frame.prepFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	end
end

oUF:RegisterStyle("DraeArenaPlayer", StyleDrae_ArenaPlayers)
