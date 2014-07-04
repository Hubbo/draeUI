--[[


--]]
local _, ns = ...
local oUF = ns.oUF or oUF

if (select(2, UnitClass("player")) ~= "DEATHKNIGHT") then return end

--
local _G = _G
local unpack, floor = unpack, math.floor
local GetRuneType, GetRuneCooldown, GetTime = GetRuneType, GetRuneCooldown, GetTime
local RuneFrame = RuneFrame
local RUNE_MAPPING = RUNE_MAPPING

--
local LibRingBar = LibStub("LibRingBar", true) -- Used for the countdown ring around the runes

--
LibRingBar:RegisterRingTexture({
	name 			= "ring_default",
	bodyTexture 	= "Interface\\AddOns\\draeUI\\media\\resourcebars\\ring_segment",
	endTexture1 	= "Interface\\AddOns\\draeUI\\media\\resourcebars\\slicer0",
	endTexture2 	= "Interface\\AddOns\\draeUI\\media\\resourcebars\\slicer1",
	segmentsize 	= 128,
	outer_radius 	= 110,
	inner_radius 	= 60,
});

local iconTextures = {
	[1] = "Interface\\AddOns\\draeUI\\media\\resourcebars\\GlossOrbBlood",
	[2] = "Interface\\AddOns\\draeUI\\media\\resourcebars\\GlossOrbUnholy",
	[3] = "Interface\\AddOns\\draeUI\\media\\resourcebars\\GlossOrbFrost",
	[4] = "Interface\\AddOns\\draeUI\\media\\resourcebars\\GlossOrbDeath",
}

--[[

--]]
local OnUpdate = function(self, elapsed)
	local duration = self.duration + elapsed

	if (duration >= self.max) then
		return self:SetScript("OnUpdate", nil)
	else
		self.duration = duration

		return self.ring:SetValue(duration)
	end
end

local UpdateType = function(self, event, rune, alt)
	local runeType 	= GetRuneType(rune) or alt
	local rune 		= self.Runebar[rune]

	rune.tex:SetTexture(iconTextures[runeType])
	rune.runeType = runeType

	rune.ring:SetRingColor(unpack(self.colors.runes[runeType]))

	rune.tooltipText = _G["COMBAT_TEXT_RUNE_"..RUNE_MAPPING[runeType]];
	rune:Show()
end

local UpdateRune = function(self, event, rid)
	local rune = self.Runebar[rid]

	if(rune) then
		local start, duration, runeReady = GetRuneCooldown(rune:GetID())

		if (runeReady) then
			rune:SetScript("OnUpdate", nil)
			rune.ring:SetMinMaxValues(0, 1)
			rune.ring:SetMax()
		else
			rune.duration = GetTime() - start
			rune.max = duration

			rune.ring:SetMinMaxValues(0, duration)

			rune:SetScript("OnUpdate", OnUpdate)
		end
	end
end

local Update = function(self, event)
	for i = 1, 6 do
		UpdateRune(self, event, i)
	end
end

local Enable = function(self, unit)
	local runes = self.Runebar

	if (runes and unit == "player") then
		for i = 1, 6 do

			-- Instantiate the ring for this rune and set it"s frame to one below the runes
			local ringBar = LibRingBar:NewRingBar(runes[i], {textureID 	= "ring_default"})
			ringBar:GetFrame():SetFrameLevel(11)

			-- Need to shift the ring a bit ... fudge, hhmmmmmmm, nice
			local point, relativeTo, relativePoint, xOfs, yOfs = ringBar:GetFrame():GetPoint()
			ringBar:GetFrame():SetPoint(point, relativeTo, relativePoint, xOfs - 1, yOfs + 5)

			-- Scale it
			ringBar:GetFrame():SetScale(0.16)
			runes[i].ring = ringBar

			local rune = runes[i]
			rune:SetID(i)
			-- From my minor testing this is a okey solution. A full login always remove
			-- the death runes, or at least the clients knowledge about them.
			UpdateType(self, nil, i, floor((i + 1) / 2))
		end

		self:RegisterEvent("RUNE_POWER_UPDATE", UpdateRune, true)
		self:RegisterEvent("RUNE_TYPE_UPDATE", UpdateType, true)

		return true
	end
end

local Disable = function(self)
	self.Runebar:Hide()

	RuneFrame.Show = nil
	RuneFrame:Show()

	self:UnregisterEvent("RUNE_POWER_UPDATE", UpdateRune)
	self:UnregisterEvent("RUNE_TYPE_UPDATE", UpdateType)
end

oUF:AddElement("Runebar", Update, Enable, Disable)
