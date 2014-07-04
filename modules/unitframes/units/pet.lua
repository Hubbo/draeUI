--[[


--]]

local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Pet frame - this is the same as focus but we do this seperately so we can colour by happiness
local StyleDrae_Pet = function(frame, unit, isSingle)
	UF.CommonInit(frame)

	frame.Health = UF.CreateHealthBar(frame, T.db["frames"].smallHeight)
	frame.Health.value = T.CreateFontObject(frame.Health, T.db["media"].fontsize2, T.db["media"].font, "RIGHT", -4, 12)
	frame.Health.colorClassPet = true -- else colour by creature type
	frame.Health.colorReaction = false -- but don"t colour by reaction

	local info = T.CreateFontObject(frame.Health, T.db["media"].fontsize2, T.db["media"].font, "LEFT", 4, -13)
	info:SetSize(T.db["frames"].smallWidth - 4, 20)
	frame:Tag(info, "[level] [drae:unitcolour][name][drae:afk]")

	UF.CommonPostInit(frame, 20)

	-- Auras
	UF.AddBuffs(frame, "TOPLEFT", frame, "BOTTOMLEFT", -1, -17, T.db["frames"].auras.maxOtherBuff or 2, T.db["frames"].auras.auraTny, 10, "RIGHT", "DOWN")
	UF.AddDebuffs(frame, "TOPRIGHT", frame, "BOTTOMRIGHT", 1, -17, T.db["frames"].auras.maxOtherDebuff or 2, T.db["frames"].auras.auraTny, 10, "LEFT", "DOWN")

	if (isSingle) then
		frame:SetSize(T.db["frames"].smallWidth, T.db["frames"].smallHeight)
	end
end

oUF:RegisterStyle("DraePet", StyleDrae_Pet)
