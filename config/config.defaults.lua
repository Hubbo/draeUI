--[[


--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

-- Register with SharedMedia
local LSM = LibStub("LibSharedMedia-3.0")

--[[
		Default configuration settings
--]]

-- Media and font sizing
C["media"] = {
	texture = LSM:Fetch("statusbar", "Striped"),

	-- Fonts
	font = LSM:Fetch("font", "Diavlo"),
	fontOther = LSM:Fetch("font", "Liberation Sans"),
	fontsize1 = 13,
	fontsize2 = 12,
	fontsize3 = 10,
	fontsize4 = 9,

	-- Unitframe border colour
	color_rb = 0.40,	-- default 0.40
	color_gb = 0.40,	-- default 0.40
	color_bb = 0.40,	-- default 0.40
	color_ab = 1.00,	-- default 1.00
}

-- Unit Frame settings
C["frames"] = {
	-- Display or hide frames
	showBoss			= true, 	-- Boss frames
	showArena			= true,

	-- Player and Target are positioned relative to center of screen,
	-- all other frames are positioned relative to those
	playerXoffset		= -420,
	playerYoffset		= -140,
	targetXoffset		= 420,
	targetYoffset		= -140,
	totXoffset			= 20, 	-- Relative to right side of target
	totYoffset			= 0,
	focusXoffset		= 0,  	-- Relative to left of target
	focusYoffset		= -40,
	focusTargetXoffset	= 0, 	-- Relative to right of target
	focusTargetYoffset	= -40,
	petXoffset			= 0, 	-- Relative to left of player
	petYoffset			= -40,
	petTargetXoffset	= 0,  	-- Relative to right of player
	petTargetYoffset	= -40,
	bossXoffset			= 20,	-- Relative to target of target
	bossYoffset			= 0,
	arenaXoffset		= 0, -- Relative to player
	arenaYoffset		= 140,

	largeScale 			= 1.0,
	mediumScale 		= 1.0,
	smallScale 			= 1.0,

	-- Dimension of frames, large applies to player/target, small everything else
	-- don't change these, change the scale
	largeWidth 			= 200,
	largeHeight 		= 20,
	mediumWidth			= 140,
	mediumHeight		= 20,
	smallWidth 			= 90,
	smallHeight 		= 20,

	-- Aura settings
	auras = {
		-- Large are debuffs on players, buffs on targets, Sml are buffs on player,
		-- debuffs on target and tiny are buffs/debuffs on other units
		auraHge = 26,
		auraLrg = 24,
		auraSml = 22,
		auraTny = 18,

		auraMag = 1.8, -- Multiplier for the magnified view of auras

		maxPlayerBuff		 	= 10,
		maxPlayerDebuff 		= 4,
		maxTargetBuff			= 4,
		maxTargetDebuff			= 10,
		maxOtherBuff			= 2, -- focus, focus target, pet, etc.
		maxOtherDebuff			= 2,
		maxBossBuff				= 1,
		maxArenaBuff			= 4,

		buffs_per_row = {
			["player"]	= 4,
			["target"]	= 2,
			["boss"]	= 2,
			["other"]	= 2, -- focus, focus target, pet, etc.
		},

		debuffs_per_row = {
			["player"]	= 2,
			["target"]	= 4,
			["other"]	= 2,
		},

		showBuffsOnMe 			= true, -- Short term buffs on myself or my pet
		showDebuffsOnMe 		= true, -- Debuffs on myself or pet
		showBuffsOnFriends		= true, -- Buffs on friends (excluding 0 duration auras)
		showDebuffsOnFriends	= true,
		showBuffsOnEnemies		= true,
		showDebuffsOnEnemies	= true,

		showStealableBuffs		= true,

		-- These auras are never displayed regardless of any other settings
		blacklistAuraFilter = {
			["Chill of the Throne"] = true,
			["Strength of Wrynn"] 	= true,
		},

		filterType = "WHITELIST", -- dictates which filter we"ll use

		-- If debuff filtering is enabled only the debuffs in the following list will appear on targets
		whiteListFilter = {
			["DEBUFF"] = {
				["Repentance"]				= true,
				["Cyclone"]					= true,
				["Polymorph"]				= true,
				["Hex"]						= true,
				["Chilled"]					= true,
				["Ice Trap"]				= true,
				["Wyvern Sting"]			= true,
				["Mortal Strike"] 			= true,
				["Unbound Plague"]			= true, -- Putricide plague
				["Plague Sickness"]			= true, -- Putricide plague
				["Necrotic Plague"]			= true, -- Lick King P1
				["Feedback"]				= true,
				["Destabilize"]				= true,
				["Scary Fog"]				= true,
				["Weakened Soul"]			= true,
			},
			["BUFF"] = {
				["Vengeance"]				= true,
				["Beacon of Light"]			= true,
				["Thorns"]					= true,
				["Hand of Protection"]		= true,
				["Hand of Freedom"]			= true,
				["Hand of Sacrifice"]		= true,
				["Hand of Salvation"]		= true,
				["Illuminated Healing"]		= true,
				["Power Word: Barrier"]		= true,
				["Aspect of the Hawk"]		= true,
				["Aspect of the Fox"]		= true,
				["Aspect of the Pack"]		= true,
				["Aspect of the Cheetah"]	= true,
				["Aspect of the Wild"]		= true,
				["Rune of Power"]			= true,
				["Light of the Ancient Kings"] = true, -- Haste buff from Holy GoAK
				["Invoker's Energy"]		= true, -- Invocation buff
				["The Light of Day"]		= true,
				["Renewing Mist"]			= true,
			}
		},
		blackListFilter = {
			["DEBUFF"] = {
			},
			["BUFF"] = {
			}
		},
	},
}

-- Player, target and focus castbar
C["castbar"] = {
	player = {
		width	 = 200,
		height	 = 18,
		xOffset  = 0,
		yOffset  = -140,
		anchor 	 = "UIParent",
		anchorat = "CENTER",
		anchorto = "CENTER",
	},
	target = {
		width	 = 200,
		height	 = 14,
		xOffset  = 0,
		yOffset  = -165,
		anchor 	 = "UIParent",
		anchorat = "CENTER",
		anchorto = "CENTER",
	},
	focus = {
		width	 = 200,
		height	 = 14,
		xOffset  = 0,
		yOffset  = -188,
		anchor 	 = "UIParent",
		anchorat = "CENTER",
		anchorto = "CENTER",
	},
	arena = {
		height	 = 8,
		xOffset  = 0,
		yOffset  = -15,
	},

	showLatency		= true,
	showIcon		= false,
}

-- Secondary resource bar
C["resourcebar"] = {
	xOffset  = -400,
	yOffset  = -45,
}

-- Equipment set mappings
C["equipSets"] = {
	["PALADIN"]	= {
		[1] = "Holy",
		[2] = "Protection",
		[3] = "Retribution",
	},
	["MAGE"]	= {
		[1] = "Arcane",
		[2] = "Fire",
		[3] = "Frost",
	},
	["MONK"]	= {
		[1]	= "Brewmaster",
		[2]	= "Mistweaver",
		[3]	= "Windwalker",
	},
}

-- Information bar (fps, mem use, etc.)
C["infobar"] = {
	showXP = true,
	showReputation = true,
}

-- Buff bar
C["buffbar"] = {
	buffAnchor 		= { "TOPRIGHT", Minimap, "TOPLEFT", -30, 10 },
	buffGrowDir 	= 1,	-- growth direction: 0 -> from left to right, 1 -> from right to left
	buffXoffset 	= 42,	-- horizontal distance between icons
	buffScale		= 0.95,

	iconsPerRow 	= 10,		-- maximum number of icons in one row before a new row starts
	sortMethod 		= "NAME",	-- how to sort the buffs/debuffs, possible values are "NAME", "INDEX" or "TIME"
	sortReverse 	= false,	-- reverse sort order
	showWeaponEnch 	= true,		-- show or hide temporary weapon enchants
	colorBorderItem = true,		-- Colour border of item enchants
}

-- Nameplates
C["nameplates"] = {
	fontsize = 10,
	fontsize2 = 8,

	hpHeight = 9,
	hpWidth = 120,
	cbHeight = 4,

	iconSize = 16, --Size of all Icons, RaidIcon/Castbar Icon

	auranum = 3,
	auraiconsize = 16,

	fadeIn = true, -- Fade plates in as they are shown
	fadeAlways = false, -- Always cause non-target frameplates to appear slightly faded

	combat = false,
	enhancethreat = true,
	enabledebuff = true,
	enablebuff = true,

	blacklist = {
		--Shaman Totems (Ones that don"t matter)
		["Earth Elemental Totem"] = true,
		["Fire Elemental Totem"] = true,
		["Fire Resistance Totem"] = true,
		["Flametongue Totem"] = true,
		["Frost Resistance Totem"] = true,
		["Healing Stream Totem"] = true,
		["Magma Totem"] = true,
		["Mana Spring Totem"] = true,
		["Nature Resistance Totem"] = true,
		["Searing Totem"] = true,
		["Stoneclaw Totem"] = true,
		["Stoneskin Totem"] = true,
		["Strength of Earth Totem"] = true,
		["Windfury Totem"] = true,
		["Totem of Wrath"] = true,
		["Wrath of Air Totem"] = true,
		["Air Totem"] = true,
		["Water Totem"] = true,
		["Fire Totem"] = true,
		["Earth Totem"] = true,

		--Army of the Dead
		["Army of the Dead Ghoul"] = true,
	},

	buffWhiteList = {
	},

	debuffWhiteList = {
	},

	debuffBlackList = {
		[15407] = true, -- Mind flay
	},
}

-- Minimap (global variable space)
G["minimap"] = {
	buttons	= {
		["MiniMapTracking"] 			= { angle = 10 },  -- The tracking button/menu
		["MiniMapMailFrame"] 			= { angle = 310 }, -- New mail alert
		["QueueStatusMinimapButton"] 	= { angle = 235 }, -- Dungeon Finder
		["GameTimeFrame"] 				= { angle = 45 },  -- The Calendar
		["MiniMapInstanceDifficulty"] 	= { angle = 126 }, -- Instance difficulty
		["GuildInstanceDifficulty"] 	= { angle = 126 }, -- As above when in guild group
		["MiniMapChallengeMode"] 		= { angle = 126 }, -- As above when in doing challenge modes
		["TimeManagerClockButton"] 		= { anchorat = "BOTTOM", anchorto = "BOTTOM", posx = 0, posy = -11 }, -- The clock
	},
}
