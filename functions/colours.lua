--[[

--]]
local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))

--[[

--]]
oUF.colors.power["MANA"] 				= { 0,    0.56, 1.0  }
oUF.colors.power["RAGE"] 				= { 0.69, 0.31, 0.31 }
oUF.colors.power["FOCUS"] 				= { 0.71, 0.43, 0.27 }
oUF.colors.power["ENERGY"] 				= { 0.65, 0.63, 0.35 }
oUF.colors.power["RUNES"] 				= { 0.55, 0.57, 0.61 }
oUF.colors.power["RUNIC_POWER"] 		= { 0,    0.82, 1.0  }
oUF.colors.power["AMMOSLOT"] 			= { 0.8,  0.6,  0    }
oUF.colors.power["FUEL"] 				= { 0,    0.55, 0.5  }
oUF.colors.power["POWER_TYPE_STEAM"] 	= { 0.55, 0.57, 0.61 }
oUF.colors.power["POWER_TYPE_PYRITE"] 	= { 0.60, 0.09, 0.17 }
oUF.colors.power["ALT_POWER_BAR"] 		= { 1.0 , 0.30, 0    }

oUF.colors.reaction[2] = { 1.0, 0,   0 }
oUF.colors.reaction[4] = { 1.0, 1.0, 0 }
oUF.colors.reaction[5] = { 0,   1.0, 0 }

oUF.colors.charmed 		= { 1.0, 0,   0.4 }
oUF.colors.disconnected = { 0.9, 0.9, 0.9 }
oUF.colors.tapped 		= { 0.6, 0.6, 0.6 }

oUF.colors.runes = {
	{ 0.77, 0.12, 0.23 };
	{ 0.40, 0.80, 0.10 };
	{ 0.00, 0.40, 0.70 };
	{ 0.80, 0.10, 1.00 };
}
