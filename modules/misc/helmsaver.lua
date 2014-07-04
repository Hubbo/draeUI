--[[
	Blatantly adapted from d87's HelmSaver
	http://www.wowinterface.com/downloads/info19713-HelmSaver.html
--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local TH = T:NewModule("HelmSaver", "AceEvent-3.0", "AceHook-3.0")

--
local _G = _G
local CreateFrame = CreateFrame

--
local hcb, ccb

--[[

--]]
local Update = function()
	local helm = hcb:GetChecked()
	local cloak = ccb:GetChecked()

	ShowHelm(helm)
	ShowCloak(cloak)
end

-- Hook and handle clicking the checkboxes
local OnCheckBoxClick = function()
	Update()

	if (PaperDollEquipmentManagerPane.selectedSetName) then
		PaperDollEquipmentManagerPaneSaveSet:Enable()
		PaperDollEquipmentManagerPaneEquipSet:Enable()
	end
end

TH.EQUIPMENT_SWAP_FINISHED = function(self, event, arg1, name)
	if (self.db[name]) then
		hcb:SetChecked(self.db[name].helm)
		ccb:SetChecked(self.db[name].cloak)

		Update()
	end
end

hooksecurefunc("GearSetButton_OnClick", function(self, btn)
	PaperDollEquipmentManagerPaneEquipSet:Enable()
end)

-- Hook the equipment manager UI functions
hooksecurefunc("SaveEquipmentSet", function(name, icon)
	TH.db[name] = TH.db[name] or {}

	TH.db[name].helm = hcb:GetChecked() and true or false
	TH.db[name].cloak = ccb:GetChecked() and true or false
end)

hooksecurefunc("DeleteEquipmentSet", function(name)
	if (TH.db[name]) then TH.db[name] = nil end
end)

--[[

--]]
TH.OnEnable = function(self)
	-- Localise our appropriate database
	T.dbChar.helmsaver = T.dbChar.helmsaver or {}
	self.db = T.dbChar.helmsaver

	-- Add the select boxes to the char paperdoll equip frame
	hcb = CreateFrame("CheckButton", nil, CharacterHeadSlotPopoutButton, "UICheckButtonTemplate")
	hcb:SetSize(26, 26)
	hcb:SetPoint("RIGHT", CharacterHeadSlotPopoutButton, "LEFT", -13, 0)
	hcb:SetScript("OnClick", OnCheckBoxClick)
	hcb:SetChecked(ShowingHelm())

	ccb = CreateFrame("CheckButton", nil, CharacterBackSlotPopoutButton, "UICheckButtonTemplate")
	ccb:SetSize(26, 26)
	ccb:SetPoint("RIGHT", CharacterBackSlotPopoutButton, "LEFT", -13, 0)
	ccb:SetScript("OnClick", OnCheckBoxClick)
	ccb:SetChecked(ShowingCloak())

	self:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
end
