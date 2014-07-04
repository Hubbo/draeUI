--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local BB = T:GetModule("Buffbar")

-- init secure aura headers
local buffHeader = CreateFrame("Frame", "DraeUIBuffBar", UIParent, "SecureAuraHeaderTemplate")
local ha

--[[

--]]
local CreateAuraButton = function(btn, filter)
	-- subframe for icon and border
	btn.icon = CreateFrame("Frame", nil, btn)
	btn.icon:SetFrameStrata("BACKGROUND")
	btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
	btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)

	-- icon texture
	btn.icon.tex = btn.icon:CreateTexture(nil, "BACKGROUND")
	btn.icon.tex:SetTexCoord(.09, .91, .09, .91)
	btn.icon.tex:SetPoint("TOPLEFT", btn.icon, "TOPLEFT", -0.09, 0.91)
	btn.icon.tex:SetPoint("BOTTOMRIGHT", btn.icon, "BOTTOMRIGHT", -0.09, -0.91)

	-- duration spiral
	btn.cd = CreateFrame("Cooldown", nil, btn.icon)
	btn.cd:SetAllPoints(btn.icon)
	btn.cd:SetReverse(true)

	T.CreateBorder(btn)

	-- subframe for value texts
	btn.vFrame = CreateFrame("Frame", nil, btn)
	btn.vFrame:SetAllPoints(btn)

	-- stack count
	btn.stacks = btn.vFrame:CreateFontString(nil, "OVERLAY")
	btn.stacks:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 7, -6)
	btn.stacks:SetFont(C["media"].fontOther, 14, "OUTLINE")
	btn.stacks:SetTextColor(1.0, 1.0, 1.0, 1)

	btn.filter = filter
	btn.highlight = ha
end

local updateAuraButtonStyle = function(self, btn, filter)
	if not btn.icon then CreateAuraButton(btn, filter) end

	local name, _, icon, count, dtype, duration, expires = UnitAura(self:GetAttribute"unit", btn:GetID(), filter)

	if (name) then
		btn.icon.tex:SetTexture(icon)

		if (duration > 0) then
			btn.cd:SetCooldown(expires - duration, duration)
		else
			btn.cd:SetCooldown(0, -1)
		end
		btn.stacks:SetText((count > 1) and count or "")
	else
		btn.cd:SetCooldown(0, -1)
	end
end

local updateWeaponEnchantButtonStyle = function(btn, slot, hasEnchant, rTime)
	if (not btn.icon) then CreateAuraButton(btn) end

	if (hasEnchant) then
		btn.slotID = GetInventorySlotInfo(slot)
		local icon = GetInventoryItemTexture("player", btn.slotID)
		btn.icon.tex:SetTexture(icon)

		local r, g, b = C["media"].color_rb, C["media"].color_gb, C["media"].color_bb

		if (BB.db.colorBorderItem) then
			local c = GetInventoryItemQuality("player", slotid)
			r, g, b = GetItemQualityColor(c or 1)
		end

		T.SetBorderColor(btn, r, g, b, C["media"].color_ab or 1)

		btn.rTime = rTime / 1000

		btn.cd:SetCooldown(GetTime() + btn.rTime - 1800, 1800)
	else
		btn.cd:SetCooldown(0, -1)
	end
end

local updateStyle = function(self, event, unit)
	if (unit ~= "player" and event ~= "PLAYER_ENTERING_WORLD") then return end

	-- weapon enchant button style
	local hasMHe, MHrTime, _, hasOHe, OHrTime = GetWeaponEnchantInfo()
	local wEnch1 = buffHeader:GetAttribute("tempEnchant1")
	local wEnch2 = buffHeader:GetAttribute("tempEnchant2")

	-- buff and debuff button style
	for _, btn in buffHeader:ActiveButtons() do
		if (btn ~= wEnch1 and btn ~= wEnch2) then updateAuraButtonStyle(self, btn, "HELPFUL") end
	end

	if (wEnch1) then updateWeaponEnchantButtonStyle(wEnch1, "MainHandSlot", hasMHe, MHrTime) end
	if (wEnch2) then updateWeaponEnchantButtonStyle(wEnch2, "SecondaryHandSlot", hasOHe, OHrTime) end
end

local SetHeaderAttributes = function(header, template, isBuff)
	local bOffs = abs(BB.db.buffXoffset)

	header:SetAttribute("unit", "player")
	header:SetAttribute("filter", "HELPFUL")
	header:SetAttribute("template", template)
	header:SetAttribute("minWidth", 100)
	header:SetAttribute("minHeight", 100)

	header:SetAttribute("point", BB.db.buffAnchor[1])
	header:SetAttribute("xOffset", (BB.db.buffGrowDir == 1) and -bOffs or bOffs)
	header:SetAttribute("yOffset", 0)
	header:SetAttribute("wrapAfter", BB.db.iconsPerRow)
	header:SetAttribute("wrapXOffset", 0)
	header:SetAttribute("wrapYOffset", (BB.db.buffGrowDir == 1) and -bOffs or bOffs)
	header:SetAttribute("maxWraps", 10)

	header:SetAttribute("sortMethod", BB.db.sortMethod)
	header:SetAttribute("sortDirection", BB.db.sortReverse and "-" or "+")

	if (isBuff and BB.db.showWeaponEnch) then
		header:SetAttribute("includeWeapons", 1)
		header:SetAttribute("weaponTemplate", "DraeUIBuffButtonTemplate")
	end

	header:SetScale(BB.db.buffScale)

	header:RegisterEvent("PLAYER_ENTERING_WORLD")
	header:HookScript("OnEvent", updateStyle)
end

BB.OnEnable = function(self)
	-- The highlight (magnified) frame
	ha = CreateFrame("Frame", "DraeUIBuffsHighlight", UIParent)
	ha:SetScale(BB.db.buffScale)
	ha:SetFrameLevel(5) -- Above auras (level 3) and their cooldown overlay (4)

	ha.icon = ha:CreateTexture(nil, "ARTWORK")
	ha.icon:SetPoint("CENTER")

	ha.border = ha:CreateTexture(nil, "OVERLAY")
	ha.border:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\textureNormal")
	ha.border:SetPoint("CENTER")
	ha.border:SetVertexColor(C["media"].color_rb, C["media"].color_gb, C["media"].color_bb, C["media"].color_ab or 1)

	-- Hide stuff
	BuffFrame.Show = BuffFrame.Hide
	BuffFrame:UnregisterAllEvents()
	BuffFrame:Hide()

	ConsolidatedBuffs.Show = ConsolidatedBuffs.Hide
	ConsolidatedBuffs:UnregisterAllEvents()
	ConsolidatedBuffs:Hide()

	TemporaryEnchantFrame.Show = TemporaryEnchantFrame.Hide
	TemporaryEnchantFrame:UnregisterAllEvents()
	TemporaryEnchantFrame:Hide()

	InterfaceOptionsFrameCategoriesButton12:SetScale(0.0001)

	local btn_iterator = function(self, i)
		i = i + 1

		local child = self:GetAttribute("child" .. i)

		if (child and child:IsShown()) then
			return i, child, child:GetAttribute("index")
		end
	end

	function buffHeader:ActiveButtons()
		return btn_iterator, self, 0
	end

	SetHeaderAttributes(buffHeader, "DraeUIBuffButtonTemplate", true)

	RegisterAttributeDriver(buffHeader, "unit", "[vehicleui] vehicle; player")
	RegisterStateDriver(buffHeader, "visibility", "[petbattle] hide; show")

	buffHeader:SetPoint(unpack(BB.db.buffAnchor))
	buffHeader:Show()
end
