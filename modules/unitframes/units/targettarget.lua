--[[


--]]

local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Target of target frame
local StyleDrae_TargetTarget = function(frame, unit, isSingle)
	UF.CommonInit(frame)

	frame.Health = UF.CreateHealthBar(frame, T.db["frames"].smallHeight)
	frame.Health.value = T.CreateFontObject(frame.Health, T.db["media"].fontsize2, T.db["media"].font, "RIGHT", -4, 12)

	local info = T.CreateFontObject(frame.Health, T.db["media"].fontsize2, T.db["media"].font, "LEFT", 4, -13)
	info:SetSize(T.db["frames"].smallWidth - 4, 20)
	frame:Tag(info, "[level] [drae:unitcolour][name][drae:afk]")

	UF.CommonPostInit(frame, 20)

	-- Auras - just debuffs for target of target
	UF.AddDebuffs(frame, "BOTTOMRIGHT", frame, "TOPRIGHT", 1, 20, T.db["frames"].auras.maxOtherDebuff or 2, T.db["frames"].auras.auraSml, 10, "LEFT", "UP")

	if (isSingle) then
		frame:SetSize(T.db["frames"].smallWidth, T.db["frames"].smallHeight)
	end
end

oUF:RegisterStyle("DraeTargetTarget", StyleDrae_TargetTarget)
