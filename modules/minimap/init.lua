--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

local MM = T:NewModule("Minimap", "AceEvent-3.0")

--[[
		Load variables when addon loaded
--]]
MM.OnInitialize = function(self)
	T.dbGlobal.minimap = T.dbGlobal.minimap or {}

	self.db = T.dbGlobal["minimap"]
	self.db.dragPositions = self.db.dragPositions or {}
end
