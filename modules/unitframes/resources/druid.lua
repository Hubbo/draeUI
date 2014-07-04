--[[


--]]
local _, ns = ...
local oUF = ns.oUF or oUF

local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Localise a bunch of functions
local _G = _G
local format, unpack = string.format, unpack
local CreateFrame, UnitLevel, UnitPower, UnitPowerMax, InCombatLockdown = CreateFrame, UnitLevel, UnitPower, UnitPowerMax, InCombatLockdown
local UnitExists, GetComboPoints = UnitExists, GetComboPoints

--[[
		Druid eclipse
		Like other resources here this hijacks Blizzard existing bar
		and adds to it
		TODO: Mana bar for resto?
--]]
UF.CreateEclipseBar = function(self, point, anchor, relpoint, xOffset, yOffset)
	if (T.playerClass ~= "DRUID") then return end

	local scale = 1.3

	local rs = CreateFrame("Frame", nil, self)
	rs:SetFrameLevel(12)
	rs:EnableMouse(false)
	rs.unit = "player"

	_G["EclipseBarFrame"]:SetParent(rs)
	_G["EclipseBarFrame"]:ClearAllPoints()
	_G["EclipseBarFrame"]:SetPoint(point, anchor, relpoint, xOffset / scale, yOffset / scale)
	_G["EclipseBarFrame"]:SetScale(scale)

	_G["EclipseBarFrameBar"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")
	_G["EclipseBarFrameSun"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")
	_G["EclipseBarFrameMoon"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")
	_G["EclipseBarFrameDarkSun"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")
	_G["EclipseBarFrameDarkMoon"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")
	_G["EclipseBarFrameSunBar"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")
	_G["EclipseBarFrameMoonBar"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")
	_G["EclipseBarFrameMarker"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")
	_G["EclipseBarFrameGlow"]:SetTexture("Interface\\AddOns\\draeUI\\media\\resourcebars\\DruidEclipse")

	self.resourceBar = rs
end
