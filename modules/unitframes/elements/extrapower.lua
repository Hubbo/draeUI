--[[


--]]
local _, ns = ...
local oUF = ns.oUF or oUF

local Update = function(self, event, unit)
	if (unit and self.unit ~= unit) then return end
	unit = unit or self.unit

	local power = self.ExtraPower

	if (power.PreUpdate) then power:PreUpdate(unit) end

	local min, max = UnitPower(unit), UnitPowerMax(unit)
	power:SetMinMaxValues(0, max)
	power:SetValue(min)

	local r, g, b, t
	if (not power.postUpdateColor) then
		local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)

		t = self.colors.power[ptoken]
		if (not t) then
			if (altR) then
				r, g, b = altR, altG, altB
			else
				t = self.colors.power[ptype]
			end
		end
	end

	if (t) then
		r, g, b = t[1], t[2], t[3]
	end

	if (b) then
		power:SetStatusBarColor(r, g, b)

		local bg = power.bg
		if(bg) then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	if (power.PostUpdate) then
		return power:PostUpdate(unit, min, max)
	end
end

local Path = function(self, ...)
	return (self.ExtraPower.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self, unit)
	local power = self.ExtraPower
	if(power) then
		power.__owner = self
		power.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
		self:RegisterEvent('UNIT_MAXPOWER', Path)

		return true
	end
end

local Disable = function(self)
	local power = self.ExtraPower
	if (power) then
		self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
		self:UnregisterEvent('UNIT_MAXPOWER', Path)
	end
end

oUF:AddElement('Extrapower', Path, Enable, Disable)
