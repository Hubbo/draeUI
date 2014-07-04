--[[

--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local M = T:NewModule("Misc", "AceEvent-3.0", "AceTimer-3.0")

local UIErrorsFrame = UIErrorsFrame
local interruptMsg = INTERRUPTED .. " %s's \124cff71d5ff\124Hspell:%d\124h[%s]\124h\124r!"
local floor, format = math.floor, string.format

--[[

--]]
M.ErrorFrameToggle = function(self, event)
	if (event == "PLAYER_REGEN_DISABLED") then
		UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	else
		UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
	end
end

do
	local autoRepair = "GUILD"

	local VendorGrays = function(delete, nomsg)
		if (not MerchantFrame or not MerchantFrame:IsShown()) and not delete then
			T.Print("You must be at a vendor.")
			return
		end

		local c, count = 0, 0
		for b = 0, 4 do
			for s = 1, GetContainerNumSlots(b) do
				local l = GetContainerItemLink(b, s)
				if (l and select(11, GetItemInfo(l))) then
					local p = select(11, GetItemInfo(l)) * select(2, GetContainerItemInfo(b, s))

					if (delete) then
						if (find(l, "ff9d9d9d")) then
							PickupContainerItem(b, s)
							DeleteCursorItem()
							c = c + p
							count = count + 1
						end
					else
						if (select(3, GetItemInfo(l)) == 0 and p > 0) then
							UseContainerItem(b, s)
							PickupMerchantItem()
							c = c + p
						end
					end
				end
			end
		end

		if (c > 0 and not delete) then
			local g, s, c = floor(c / 10000) or 0, floor((c % 10000) / 100) or 0, c % 100
			T.Print("Vendored gray items for: |cffffffff"..g.."g |cffffffff"..s.."s |cffffffff"..c.."c.")
		elseif (not delete and not nomsg) then
			T.Print("No gray items to sell")
		elseif (count > 0) then
			local g, s, c = floor(c / 10000) or 0, floor((c % 10000) / 100) or 0, c % 100
			T.Print(format("Deleted %d gray items. Total Worth: %s", count, " |cffffffff"..g.."g |cffffffff"..s.."s |cffffffff"..c.."c"))
		elseif (not nomsg) then
			T.Print("No gray items to delete")
		end
	end

	M.MERCHANT_SHOW = function(self)
		VendorGrays(nil, true)

		if (IsShiftKeyDown() or not CanMerchantRepair()) then return end

		local cost, possible = GetRepairAllCost()
		local withdrawLimit = GetGuildBankWithdrawMoney()

		if (autoRepair == "GUILD" and (not CanGuildBankRepair() or cost > withdrawLimit)) then
			autoRepair = "PLAYER"
		end

		if (cost > 0) then
			if (possible) then
				RepairAllItems(autoRepair == "GUILD")
				local c, s, g = cost % 100, floor((cost % 10000) / 100), floor(cost / 10000)

				if (autoRepair == "GUILD") then
					T.Print("Your items have been repaired using guild bank funds for: "..GetCoinTextureString(cost, 13))
				else
					T.Print("Your items have been repaired using your own funds for: "..GetCoinTextureString(cost, 13))
				end
			else
				T.Print("You don't have enough money to repair!")
			end
		end
	end
end

--[[
		PLAYER_LOGIN
--]]
M.OnEnable = function(self)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "ErrorFrameToggle")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "ErrorFrameToggle")
	self:RegisterEvent("MERCHANT_SHOW")
end
