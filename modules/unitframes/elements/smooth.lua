local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "<name> was unable to locate oUF install.")

local GetFrameRate, GetValue, GetMinMaxValues, mmin, mmax = GetFrameRate, GetValue, GetMinMaxValues, math.min, math.max
local smoothing = {}

local Smooth = function(self, value)
	local _, max = self:GetMinMaxValues()

	if (value == self:GetValue() or (self._max and self._max ~= max)) then
		smoothing[self] = nil
		self:SetValue_(value)
	else
		smoothing[self] = value
	end

	self._max = max
end

-- Make global
local SmoothBar = function(self, bar)
	bar.SetValue_ = bar.SetValue
	bar.SetValue = Smooth
end

local hook = function(frame)
	frame.SmoothBar = SmoothBar

	if frame.Health and frame.Health.Smooth then
		frame:SmoothBar(frame.Health)
	end
	if frame.Power and frame.Power.Smooth then
		frame:SmoothBar(frame.Power)
	end
	if frame.ExtraPower and frame.ExtraPower.Smooth then
		frame:SmoothBar(frame.ExtraPower)
	end
end

for i, frame in ipairs(oUF.objects) do hook(frame) end
oUF:RegisterInitCallback(hook)

local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function()
	local limit = 30 / GetFramerate()

	for bar, value in pairs(smoothing) do
		local cur = bar:GetValue()
		local new = cur + mmin((value - cur) / 3, mmax(value - cur, limit))

		if (new ~= new) then
			-- Mad hax to prevent QNAN.
			new = value
		end

		bar:SetValue_(new)

		if (cur == value or abs(new - value) < 2) then
			bar:SetValue_(value)
			smoothing[bar] = nil
		end
	end
end)
