--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local BB = T:NewModule("Buffbar")

--[[
		Load variables when addon loaded
--]]
BB.OnInitialize = function(self)
	self.db = T.db["buffbar"]
end
