--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

-- Localize some vars
local match = string.match

-- "Constants"
T.playerClass = select(2, UnitClass("player"))
T.playerName = UnitName("player")
T.playerRealm = GetRealmName()

T.screenRes = GetCVar("gxResolution")
T.screenHeight = tonumber(match(T.screenRes, "%d+x(%d+)"))
T.screenWidth = tonumber(match(T.screenRes, "(%d+)x+%d"))
T.uiScale = tonumber(GetCVar("uiScale"))
