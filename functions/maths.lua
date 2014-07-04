--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

-- Localise a bunch of functions
local _G = _G
local format, gsub, floor, abs, unpack = string.format, string.gsub, math.floor, math.abs, unpack

--[[

--]]
T.ShortVal = function(value)
	if (abs(value) >= 1e6) then
		return ("%.2fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif (abs(value) >= 1e3 or value <= -1e3) then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return value
	end
end

T.Round = function(num)
	if (num >= 0) then
		return floor(num + 0.5)
	else
		return ceil(num - 0.5)
	end
end
