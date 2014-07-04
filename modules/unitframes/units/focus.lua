--[[


--]]

local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Focus is a common frame type used for most other frames inc. pet, pettarget, etc.
local StyleDrae_Focus = function(frame, unit, isSingle)
	UF.CommonInit(frame)

	frame.Health = UF.CreateHealthBar(frame, T.db["frames"].smallHeight)
	frame.Health.value = T.CreateFontObject(frame.Health, T.db["media"].fontsize2, T.db["media"].font, "RIGHT", -4, 12)

	local info = T.CreateFontObject(frame.Health, T.db["media"].fontsize2, T.db["media"].font, "LEFT", 4, -13)
	info:SetWidth(T.db["frames"].smallWidth - 4)
	info:SetHeight(20)
	frame:Tag(info, "[level] [drae:unitcolour][name][drae:afk]")

	UF.CommonPostInit(frame, 20)

	-- Auras
	UF.AddBuffs(frame, "TOPLEFT", frame, "BOTTOMLEFT", -1, -17, T.db["frames"].auras.maxOtherBuff or 2, T.db["frames"].auras.auraTny, 10, "RIGHT", "DOWN")
	UF.AddDebuffs(frame, "TOPRIGHT", frame, "BOTTOMRIGHT", 1, -17, T.db["frames"].auras.maxOtherDebuff or 2, T.db["frames"].auras.auraTny, 10, "LEFT", "DOWN")

	-- Castbar
	if (unit == "focus") then
		local cbf = T.db["castbar"].focus
		UF.CreateCastBar(frame, cbf.width, cbf.height, cbf.anchor, cbf.anchorat, cbf.anchorto, cbf.xOffset, cbf.yOffset, false, false, false)
	end

	if (isSingle) then
		frame:SetSize(T.db["frames"].smallWidth, T.db["frames"].smallHeight)
	end
end

oUF:RegisterStyle("DraeFocus", StyleDrae_Focus)
