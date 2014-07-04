--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local M = T:NewModule("Alreadyknown", "AceEvent-3.0", "AceHook-3.0")

--
local _G = _G
local ceil, fmod = math.ceil, math.fmod

--
local knowncolor = { r = 0.1, g = 1.0, b = 0.2 }

--[[

--]]
local IsAlreadyKnown
do
	local tooltip = CreateFrame("GameTooltip")
	tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

	local knowns = {}

	-- things we have to care. please let me know if any lack or surplus here.
	local weapon, armor, container, consumable, glyph, trade_goods, recipe, gem, miscallaneous, quest = GetAuctionItemClasses()
	local knowables = {
		[consumable] = true,
		[glyph] = true,
		[recipe] = true,
		[miscallaneous] = true,
	}

	local lines = {}
	for i = 1, 40 do
		lines[i] = tooltip:CreateFontString()
		tooltip:AddFontStrings(lines[i], tooltip:CreateFontString())
	end

	IsAlreadyKnown = function(itemLink)
		if (not itemLink) then
			return
		end

		local itemID = itemLink:match("item:(%d+):")
		if (knowns[itemID]) then
			return true
		end

		local _, _, _, _, _, itemType = GetItemInfo(itemLink)
		if (not knowables[itemType]) then
			return
		end

		tooltip:ClearLines()
		tooltip:SetHyperlink(itemLink)

		for i = 1, tooltip:NumLines() do
			if (lines[i]:GetText() == ITEM_SPELL_KNOWN) then
				knowns[itemID] = true
				return true
			end
		end
	end
end


-- Merchant frame
local MerchantFrame_UpdateMerchantInfo = function()
	local numItems = GetMerchantNumItems()

	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i

		if (index > numItems) then
			return
		end

		local button = _G["MerchantItem" .. i .. "ItemButton"]

		if (button and button:IsShown()) then
			local _, _, _, _, numAvailable, isUsable = GetMerchantItemInfo(index)

			if (isUsable and IsAlreadyKnown(GetMerchantItemLink(index))) then
				local r, g, b = knowncolor.r, knowncolor.g, knowncolor.b

				if (numAvailable == 0) then
					r, g, b = r * 0.5, g * 0.5, b * 0.5
				end

				SetItemButtonTextureVertexColor(button, r, g, b)
			end
		end
	end
end

local MerchantFrame_UpdateBuybackInfo = function()
	local numItems = GetNumBuybackItems()

	for index = 1, BUYBACK_ITEMS_PER_PAGE do
		if (index > numItems) then
			return
		end

		local button = _G["MerchantItem" .. index .. "ItemButton"]

		if (button and button:IsShown()) then
			local _, _, _, _, _, isUsable = GetBuybackItemInfo(index)

			if (isUsable and IsAlreadyKnown(GetBuybackItemLink(index))) then
				SetItemButtonTextureVertexColor(button, knowncolor.r, knowncolor.g, knowncolor.b)
			end
		end
	end
end

-- Guild bank frame
local GuildBankFrame_Update = function()
	if ( GuildBankFrame.mode ~= "bank" ) then
		return
	end

	local tab = GetCurrentGuildBankTab()

	for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
		local button = _G["GuildBankColumn" .. ceil((i - 0.5) / NUM_SLOTS_PER_GUILDBANK_GROUP) .. "Button" .. fmod(i, NUM_SLOTS_PER_GUILDBANK_GROUP)]

		if (button and button:IsShown()) then
			local texture, _, locked = GetGuildBankItemInfo(tab, i)

			if ( texture and not locked ) then
				if (IsAlreadyKnown(GetGuildBankItemLink(tab, i))) then
					SetItemButtonTextureVertexColor(button, knowncolor.r, knowncolor.g, knowncolor.b)
				else
					SetItemButtonTextureVertexColor(button, 1, 1, 1)
				end
			end
		end
	end
end

-- Auction frame
local function AuctionFrameBrowse_Update ()
	local numItems = GetNumAuctionItems("list")
	local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)

	for i = 1, NUM_BROWSE_TO_DISPLAY do
		local index = offset + i

		if (index > numItems) then
			return
		end

		local texture = _G["BrowseButton" .. i .. "ItemIconTexture"]

		if (texture and texture:IsShown()) then
			local _, _, _, _, canUse =  GetAuctionItemInfo("list", index)

			if (canUse and IsAlreadyKnown(GetAuctionItemLink("list", index))) then
				texture:SetVertexColor(knowncolor.r, knowncolor.g, knowncolor.b)
			end
		end
	end
end

local AuctionFrameBid_Update = function()
	local numItems = GetNumAuctionItems("bidder")
	local offset = FauxScrollFrame_GetOffset(BidScrollFrame)

	for i = 1, NUM_BIDS_TO_DISPLAY do
		local index = offset + i

		if (index > numItems) then
			return
		end

		local texture = _G["BidButton" .. i .. "ItemIconTexture"]

		if (texture and texture:IsShown()) then
			local _, _, _, _, canUse =  GetAuctionItemInfo("bidder", index)

			if (canUse and IsAlreadyKnown(GetAuctionItemLink("bidder", index))) then
				texture:SetVertexColor(knowncolor.r, knowncolor.g, knowncolor.b)
			end
		end
	end
end

local AuctionFrameAuctions_Update = function()
	local numItems = GetNumAuctionItems("owner")
	local offset = FauxScrollFrame_GetOffset(AuctionsScrollFrame)

	for i = 1, NUM_AUCTIONS_TO_DISPLAY do
		local index = offset + i
		if ( index > numItems ) then
			return
		end

		local texture = _G["AuctionsButton" .. i .. "ItemIconTexture"]

		if (texture and texture:IsShown()) then
			local _, _, _, _, canUse, _, _, _, _, _, _, _, saleStatus = GetAuctionItemInfo("owner", index)

			if (canUse and IsAlreadyKnown(GetAuctionItemLink("owner", index))) then
				local r, g, b = knowncolor.r, knowncolor.g, knowncolor.b

				if (saleStatus == 1) then
					r, g, b = r * 0.5, g * 0.5, b * 0.5
				end

				texture:SetVertexColor(r, g, b)
			end
		end
	end
end

local HookAuctionframe = function()
	isBlizzard_AuctionUILoaded = true

	hooksecurefunc("AuctionFrameBrowse_Update", AuctionFrameBrowse_Update)
	hooksecurefunc("AuctionFrameBid_Update", AuctionFrameBid_Update)
	hooksecurefunc("AuctionFrameAuctions_Update", AuctionFrameAuctions_Update)
end

local HookGuildBankFrame = function()
	isBlizzard_GuildBankUILoaded = true

	hooksecurefunc("GuildBankFrame_Update", GuildBankFrame_Update)
end

-- Handle LoD addons
M.HookAddons = function(self, event, addonName)
	if (addonName == "Blizzard_GuildBankUI") then
		HookGuildBankFrame()
	elseif (addonName == "Blizzard_AuctionUI") then
		HookAuctionframe()
	end

	if (isBlizzard_GuildBankUILoaded and isBlizzard_AuctionUILoaded) then
		self:UnregisterEvent("ADDON_LOADED")
	end
end

M.OnEnable = function(self)
	local guildBankLoaded = IsAddOnLoaded("Blizzard_GuildBankUI")
	local auctionLoaded = IsAddOnLoaded("Blizzard_AuctionUI")

	if (not (guildBankLoaded or auctionLoaded)) then
		self:RegisterEvent("ADDON_LOADED", "HookAddons")
	else
		if (auctionLoaded) then
			HookAuctionframe()
		end

		if (guildBankLoaded) then
			HookGuildBankFrame()
		end
	end

	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", MerchantFrame_UpdateMerchantInfo)
	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", MerchantFrame_UpdateBuybackInfo)
end
