--[[
		Inspired by various auto-loot mail apps including
		OpenAll, Postal and MailOpener
--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local OA = T:NewModule("OpenAll", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")

--
local _G = _G
local CreateFrame, format = CreateFrame, string.format

--
local btnTakeAll, btnTakeGold, goldOnly, baseInboxFrame_OnClick

--[[

--]]
local noop = function() end

do
	local pauseNext, mailIndex, attachIndex, lastNumGold, lastNumAttach, lastItem, fullBags, fullBagsNotified

	-- Reset our local vars
	local ResetVariables = function()
		pauseNext = false
		fullBags = false
		fullBagsNotified = false

		mailIndex = 0
		attachIndex = ATTACHMENTS_MAX_RECEIVE
		lastNumGold = 0
		lastNumAttach = 0
		lastItem = false
	end

	local CountItemsAndMoney = function()
		local numAttach, numGold = 0, 0

		for i = 1, GetInboxNumItems() do
			local msgMoney, _, _, msgItem = select(5, GetInboxHeaderInfo(i))

			numAttach = numAttach + (msgItem or 0)
			numGold = numGold + msgMoney
		end

		return numAttach, numGold
	end

	local BagsUpdated = function()
		-- Force a recheck of fullBags since something may have just been removed/deleted
		fullBags = false
	end

	local UIError = function(event, msg)
		if (msg == ERR_INV_FULL or msg == ERR_ITEM_MAX_COUNT) then
			if (not fullBagsNotified) then
				T.Print("Inventory full but continuing to process mail")
				fullBagsNotified = true
			end

			fullBags = true
			pauseNext = false
		elseif (msg == ERR_MAIL_DATABASE_ERROR) then
			attachIndex = attachIndex - 1
			pauseNext = false
		end
	end

	--[[

	--]]
	OA.ProcessMail = function(self)
		if (mailIndex and mailIndex > 0) then
			local sender, subject, gold, cod, _, items, _, _, _, _, isGM = select(3, GetInboxHeaderInfo(mailIndex))

			if (cod and cod > 0 or isGM) then
				mailIndex = mailIndex - 1
				attachIndex = ATTACHMENTS_MAX_RECEIVE

				self:NextMail()
			end

			-- Find next attachment index backwards
			while (not GetInboxItemLink(mailIndex, attachIndex) and attachIndex > 0) do
				attachIndex = attachIndex - 1
			end

			-- If inventory is full, check if the item to be looted can stack with an existing stack
			local lootFlag = false
			if (attachIndex > 0 and fullBags) then
				local name, itemTexture, count, quality, canUse = GetInboxItem(mailIndex, attachIndex)
				local link = GetInboxItemLink(mailIndex, attachIndex)
				local itemID = strmatch(link, "item:(%d+)")
				local stackSize = select(8, GetItemInfo(link))

				if (itemID and stackSize and GetItemCount(itemID) > 0) then
					for bag = 0, NUM_BAG_SLOTS do
						for slot = 1, GetContainerNumSlots(bag) do
							local texture2, count2, locked2, quality2, readable2, lootable2, link2 = GetContainerItemInfo(bag, slot)

							if (link2) then
								local itemID2 = strmatch(link2, "item:(%d+)")

								if (itemID == itemID2 and count + count2 <= stackSize) then
									lootFlag = true
									break
								end
							end
						end

						if (lootFlag) then break end
					end
				end
			end

			if (not goldOnly and (attachIndex > 0 and (lootFlag or not fullBags))) then
				lastNumAttach, lastNumGold = CountItemsAndMoney()

				-- If there's attachments, take the item
				TakeInboxItem(mailIndex, attachIndex)

				-- Find next attachment index backwards
				local attachIndex2 = attachIndex - 1
				while (not GetInboxItemLink(mailIndex, attachIndex2) and attachIndex2 > 0) do
					attachIndex2 = attachIndex2 - 1
				end

				if (attachIndex2 == 0 and gold == 0) then
					lastItem = true
				end

				pauseNext = true
			elseif (gold > 0) then
				lastNumAttach, lastNumGold = CountItemsAndMoney()

				-- No attachments, but there is money
				TakeInboxMoney(mailIndex)

				pauseNext = true
			else
				-- Mail has no item or money, go to next mail
				mailIndex = mailIndex - 1
				attachIndex = ATTACHMENTS_MAX_RECEIVE
			end

			self:NextMail()
		else
			self:OpenAllStop("No messages left to processs")
		end
	end

	OA.NextMail = function(self)
		if (pauseNext) then
			local attachCount, goldCount = CountItemsAndMoney()

			if (lastNumGold ~= goldCount) then
				-- Process next mail, gold has been taken
				pauseNext = false
				mailIndex = mailIndex - 1
				attachIndex = ATTACHMENTS_MAX_RECEIVE

				self:ProcessMail()
			elseif (lastNumAttach ~= attachCount) then
				-- Process next item, an attachment has been taken
				pauseNext = false
				attachIndex = attachIndex - 1

				if (lastItem) then
					-- The item taken was the last item, process next mail
					lastItem = false
					mailIndex = mailIndex - 1
					attachIndex = ATTACHMENTS_MAX_RECEIVE
				end

				self:ProcessMail()
			else
				-- Wait longer until something in the mailbox changes
				if (self.autoOpener) then
					self:CancelTimer(self.autoOpener, true)
				end
				self.autoOpener = self:ScheduleTimer("NextMail", 0.75)
			end
		else
			self:ProcessMail()
		end
	end

	--[[

	--]]
	OA.OpenAllStop = function(self, msg)
		ResetVariables()

		btnTakeAll:Enable()
		btnTakeGold:Enable()
		InboxFrame_OnClick = baseInboxFrame_OnClick

		if (self.autoOpener) then
			self:CancelTimer(self.autoOpener, true)
		end

		if (msg) then
			T.Print(msg)
		end
	end

	OA.OpenAll = function(self)
		ResetVariables()

		mailIndex = GetInboxNumItems()
		if (mailIndex == 0) then
			T.Print("No messages to processs")
			return
		end

		-- Disable further interaction till we complete, logout or the mailbox is closed
		btnTakeAll:Disable()
		btnTakeGold:Disable()
		baseInboxFrame_OnClick = InboxFrame_OnClick
		InboxFrame_OnClick = noop

		self:NextMail()
	end
end

OA.MailboxOpened = function(self)
	self:RegisterEvent("UI_ERROR_MESSAGE", UIError)
	self:RegisterEvent("BAG_UPDATE", BagsUpdated)
end

OA.MailboxClosed = function(self)
	self:OpenAllStop()

	self:UnregisterEvent("UI_ERROR_MESSAGE")
	self:UnregisterEvent("BAG_UPDATE")
end

do
	local MakeButton = function(id, text, w, h, x, y)
		local button = CreateFrame("Button", id, InboxFrame, "UIPanelButtonTemplate")
		button:SetWidth(w)
		button:SetHeight(h)
		button:SetPoint("CENTER", InboxFrame, "TOP", x, y)
		button:SetText(text)

		return button
	end

	OA.OnEnable = function(self)
		btnTakeAll = MakeButton("OpenAllTakeAll", "Take All", 75, 25, -66, -399)
		btnTakeAll:SetScript("OnClick", function()
			-- Loot everything lootable
			goldOnly = false
			OA:OpenAll()
		end)
		btnTakeAll:SetScript("OnEnter", function()
			GameTooltip:SetOwner(btnTakeAll, "ANCHOR_RIGHT")
			GameTooltip:AddLine(format("%d messages", GetInboxNumItems()), 1, 1, 1)
			GameTooltip:Show()
		end)
		btnTakeAll:SetScript("OnLeave", function() GameTooltip:Hide() end)

		btnTakeGold = MakeButton("OpenAllTakeGold", "Take Cash", 75, 25, 15, -399)
		btnTakeGold:SetScript("OnClick", function()
			-- Only loot gold
			goldOnly = true
			OA:OpenAll()
		end)
		btnTakeGold:SetScript("OnEnter", function()
			local totalCash = 0

			for index = 0, GetInboxNumItems() do
				totalCash = totalCash + select(5, GetInboxHeaderInfo(index))
			end

			GameTooltip:SetOwner(btnTakeGold, "ANCHOR_RIGHT")
			GameTooltip:AddLine(T.IntToGold(totalCash, true), 1, 1, 1)
			GameTooltip:Show()
		end)
		btnTakeGold:SetScript("OnLeave", function() GameTooltip:Hide() end)

		self:RegisterEvent("MAIL_OPEN", "MailboxOpened")
		self:RegisterEvent("MAIL_CLOSED", "MailboxClosed")
	end
end

