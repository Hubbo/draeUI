--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

-- Localise a bunch of functions
local _G = _G
local pairs, ipairs, format, match, gupper, gsub, floor, abs, type, unpack, mmax, mmin, floor = pairs, ipairs, string.format, string.match, string.upper, string.gsub, math.floor, math.abs, type, unpack, math.max, math.min, math.floor
local UIParent, CreateFrame, ToggleDropDownMenu = UIParent, CreateFrame, ToggleDropDownMenu

--[[
		General functions
--]]
T.Print = function(...)
	print("|cff33ff99draeUI:|r ", ...)
end

-- Output an rgb hex string
T.Hex = function (r, g, b, a)
	if (type(r) == "table") then
		if (r.r) then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end

	return ("|c%02x%02x%02x%02x"):format((a or 1) * 255, r * 255, g * 255, b * 255)
end

-- MB or KB
T.MemFormat = function(num)
	if (num > 1024) then
		return format("%.2f MB", (num / 1024))
	else
		return format("%.1f KB", floor(num))
	end
end

-- UTF-8 encoding
T.UTF8 = function(str, i, dots)
	local bytes = str and str:len() or 0

	if (bytes <= i) then
		return str
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = str:byte(pos)
			if (c > 0 and c <= 127) then
				pos = pos + 1
			elseif (c >= 192 and c <= 223) then
				pos = pos + 2
			elseif (c >= 224 and c <= 239) then
				pos = pos + 3
			elseif (c >= 240 and c <= 247) then
				pos = pos + 4
			end
			if (len == i) then break end
		end

		if (len == i and pos <= bytes) then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

-- Configuration/Alignment grid (stolen from Align!)
do
	local grid

	T.AlignGridShow = function(self, gridSize)
		if (not grid or (gridSize and grid.gridSize ~= gridSize)) then
			self:AlignGridCreate(gridSize)
		end

		grid:Show()
	end

	T.AlignGridHide = function(self, gridSize)
		if (not grid) then return end

		grid:Hide()

		if (gridSize and grid.gridSize ~= gridSize) then
			self:AlignGridCreate(gridSize)
		end
	end

	T.AlignGridToggle = function(self, gridSize)
		if (grid and grid:IsVisible()) then
			self:AlignGridHide(gridSize)
		else
			self:AlignGridShow(gridSize)
		end
	end

	T.AlignGridCreate = function(self, gridSize)
		if (not grid or (gridSize and grid.gridSize ~= gridSize)) then
			grid = nil

			grid = CreateFrame("Frame", nil, UIParent)
			grid:SetAllPoints(UIParent)
		end

		gridSize = gridSize or 128
		grid.gridSize = gridSize

		local size = 2
		local width = T.screenWidth
		local ratio = width / T.screenHeight
		local height = T.screenHeight * ratio

		local wStep = width / gridSize
		local hStep = height / gridSize

		for i = 0, gridSize do
			local tx = grid:CreateTexture(nil, "BACKGROUND")

			if (i == gridSize / 2 ) then
				tx:SetTexture(1, 0, 0, 0.5)
			else
				tx:SetTexture(0, 0, 0, 0.5)
			end

			tx:SetPoint("TOPLEFT", grid, "TOPLEFT", i * wStep - (size / 2), 0)
			tx:SetPoint("BOTTOMRIGHT", grid, "BOTTOMLEFT", i * wStep + (size / 2), 0)
		end

		height = T.screenHeight

		do
			local tx = grid:CreateTexture(nil, "BACKGROUND")
			tx:SetTexture(1, 0, 0, 0.5)
			tx:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(height / 2) + (size / 2))
			tx:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height / 2 + size / 2))
		end

		for i = 1, floor((height / 2) / hStep) do
			local tx = grid:CreateTexture(nil, "BACKGROUND")
			tx:SetTexture(0, 0, 0, 0.5)

			tx:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(height / 2 + i * hStep) + (size / 2))
			tx:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height / 2 + i * hStep + size / 2))

			tx = grid:CreateTexture(nil, "BACKGROUND")
			tx:SetTexture(0, 0, 0, 0.5)

			tx:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -(height / 2 - i * hStep) + (size / 2))
			tx:SetPoint("BOTTOMRIGHT", grid, "TOPRIGHT", 0, -(height / 2 - i * hStep + size / 2))
		end
	end
end

-- Smooth colour gradient between two r, g, b value
T.ColorGradient = function(perc, ...)
	if (perc > 1) then
		local r, g, b = select(select("#", ...) - 2, ...)
		return r, g, b
	elseif (perc < 0) then
		local r, g, b = ... return r, g, b
	end

	local num = select("#", ...) / 3

	local segment, relperc = math.modf(perc * (num - 1))
	local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...)

	return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
end

-- Border setup
T.SetBorderColor = function(self, which, r, g, b, a)
	if (not self or type(self)) ~= "table" then return end

	if (self.borderTextureShadow and which == "shadow") then
		for _, tex in ipairs(self.borderTextureShadow) do
			tex:SetVertexColor(r or 0, g or 0, b or 0, a or 0)
		end
	elseif (self.borderTexture and which == "border") then
		for _, tex in ipairs(self.borderTexture) do
			tex:SetVertexColor(r or 0, g or 0, b or 0, a or 0)
		end
	end
end

T.CreateBorder = function(self, sizing)
	if (not self or type(self) ~= "table" or self.borderTexture) then return end

	if (not size) then
		size = 12
	end

	self.borderTexture = {}
	self.borderTextureShadow = {}

	local border = CreateFrame("Frame", nil, self)
	border:SetAllPoints(self)

	size = sizing == "smaller" and 8 or sizing == "small" and 12 or 16

	for k, tex in pairs({["normal"] = self.borderTexture, ["shadow"] = self.borderTextureShadow}) do
		-- creating the textures
		local i
		for i = 1, 8 do
			tex[i] = border:CreateTexture(nil, "BORDER", nil, k == "shadow" and 7 or 5)
			tex[i]:SetTexture(k == "normal" and "Interface\\AddOns\\draeUI\\media\\textures\\textureNormal" or "Interface\\AddOns\\draeUI\\media\\textures\\textureShadow")

			if (k == "shadow") then
				tex[i]:SetVertexColor(0, 0, 0, 0)
			end

			local width = (i == 3 or i == 6) and size * 2 or size
			local height = (i == 7 or i == 8) and size * 2 or size
			tex[i]:SetSize(k == "shadow" and width * 1.25 or width, k == "shadow" and height * 1.25 or height)
		end

		local x = size / 2 - 5
		local space = (k == "shadow") and size / 3 or 0

		tex[1].id = "TOPLEFT"
		tex[1]:SetTexCoord(0, 1/4, 0, 1/4)-- 0, 1/4, 0, 1/4
		tex[1]:SetPoint("TOPLEFT", border, -4 - x - space, 4 + x + space)

		tex[2].id = "TOPRIGHT"
		tex[2]:SetTexCoord(3/4, 1, 0, 1/4) -- 3/4, 1, 0, 1/4
		tex[2]:SetPoint("TOPRIGHT", border, 4 + x + space, 4 + x + space)

		tex[4].id = "BOTTOMLEFT"
		tex[4]:SetTexCoord(0, 1/4, 3/4, 1) -- 0, 1/4, 3/4, 1
		tex[4]:SetPoint("BOTTOMLEFT", border, -4 - x - space, -4 - x - space)

		tex[5].id = "BOTTOMRIGHT"
		tex[5]:SetTexCoord(3/4, 1, 3/4, 1) -- 3/4, 1, 3/4, 1
		tex[5]:SetPoint("BOTTOMRIGHT", border, 4 + x + space, -4 - x - space)

		-- width = 2 * nornal width
		tex[3].id = "TOP"
		tex[3]:SetTexCoord(1/4, 3/4, 0, 1/4) -- 1/4, 3/4, 0, 1/4
		tex[3]:SetPoint("TOPLEFT", tex[1], "TOPRIGHT")
		tex[3]:SetPoint("TOPRIGHT", tex[2], "TOPLEFT")

		-- width = 2 * nornal width
		tex[6].id = "BOTTOM"
		tex[6]:SetTexCoord(1/4, 3/4, 3/4, 1) -- 1/4, 3/4, 3/4, 1
		tex[6]:SetPoint("BOTTOMLEFT", tex[4], "BOTTOMRIGHT")
		tex[6]:SetPoint("BOTTOMRIGHT", tex[5], "BOTTOMLEFT")

		tex[7].id = "LEFT"
		tex[7]:SetTexCoord(0, 1/4, 1/4, 3/4) -- 0, 1/4, 1/4, 3/4
		tex[7]:SetPoint("TOPLEFT", tex[1], "BOTTOMLEFT")
		tex[7]:SetPoint("BOTTOMLEFT", tex[4], "TOPLEFT")

		-- width = 2 * nornal height
		tex[8].id = "RIGHT"
		tex[8]:SetTexCoord(3/4, 1, 1/4, 3/4) -- 3/4, 1, 1/4, 3/4
		tex[8]:SetPoint("TOPRIGHT", tex[2], "BOTTOMRIGHT")
		tex[8]:SetPoint("BOTTOMRIGHT", tex[5], "TOPRIGHT")
	end

	return border
end

-- Create and set font
T.CreateFontObject = function(parent, size, font, anchorAt, oX, oY, type, anchor, anchorTo)
	local fo = parent:IsObjectType("FontString") and parent or parent:CreateFontString(nil, "OVERLAY")

	fo:SetFont(font, size, type or "OUTLINE")

	if (anchor) then
		fo:SetPoint(anchorAt, anchor, anchorTo, oX, oY)
	else
		fo:SetJustifyH(anchorAt or "LEFT")

		if (oX or oY) then
			fo:SetPoint(anchorAt or "LEFT", oX or 0, oY or 0)
		end
	end

	fo:SetShadowOffset(1, -1)

	return fo
end

-- Print out money in a nicely formatted way
T.IntToGold = function(i, showIcons)
	local g = i > 10000 and i / 10000 or 0
	local s = i > 100 and (i / 100) % 100 or 0
	local c = i % 100

	local gText = showIcons and format("\124TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:1:0\124t", 12, 12) or "|cffffd700g|r"
	local sText = showIcons and format("\124TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:1:0\124t", 12, 12) or "|cffc7c7cfs|r"
	local cText = showIcons and format("\124TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:1:0\124t", 12, 12) or "|cffeda55fc|r"

	if (g) then
		return ("%d%s %d%s %d%s"):format(g, gText, s, sText, c, cText)
	elseif (s) then
		return ("%d%s %d%s"):format(s, sText, c, cText)
	else
		return ("%d%s"):format(c, cText)
	end
end
