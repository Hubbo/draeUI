--[[

--]]
local T, C, G, P, U, _ = unpack(select(2, ...))

-- Register with SharedMedia
local LSM = LibStub("LibSharedMedia-3.0")

local ChangeFont = function(obj, font, size, style, r, g, b, sr, sg, sb, sox, soy)
	obj:SetFont(font, size, style)

	if (sr and sg and sb) then obj:SetShadowColor(sr, sg, sb) end

	if (sox and soy) then obj:SetShadowOffset(sox, soy) end

	if (r and g and b) then
		obj:SetTextColor(r, g, b)
	elseif (r) then
		obj:SetAlpha(r)
	end
end

T.UpdateBlizzardFonts = function(self)
	-- Change fonts
	local FontStandard = LSM:Fetch("font", "Liberation Sans")
	local FontFancy = LSM:Fetch("font", "Liberation Sans")
	local FontCombat = LSM:Fetch("font", "Bignoodle")
	local FontSmall = FontStandard

	local SizeSmall    = 10
	local SizeMedium   = 12
	local SizeLarge    = 16
	local SizeHuge     = 18
	local SizeInsane   = 26

	-- Base fonts
	ChangeFont(SystemFont_Tiny                   , FontSmall   , SizeSmall , nil)
	ChangeFont(SystemFont_Small                  , FontSmall   , SizeSmall , nil)
	ChangeFont(SystemFont_Outline_Small          , FontSmall   , SizeSmall , "OUTLINE")
	ChangeFont(SystemFont_Shadow_Small           , FontSmall   , SizeSmall , nil)
	ChangeFont(SystemFont_InverseShadow_Small    , FontSmall   , SizeSmall , nil)
	ChangeFont(SystemFont_Med1                   , FontStandard, SizeMedium, nil)
	ChangeFont(SystemFont_Shadow_Med1            , FontStandard, SizeMedium, nil)
	ChangeFont(SystemFont_Med2                   , FontStandard, SizeMedium, nil)
	ChangeFont(SystemFont_Med3                   , FontStandard, SizeMedium, nil)
	ChangeFont(SystemFont_Shadow_Med3            , FontStandard, SizeMedium, nil)
	ChangeFont(SystemFont_Large                  , FontStandard, SizeLarge , nil)
	ChangeFont(SystemFont_Shadow_Large           , FontStandard, SizeLarge , nil)
	ChangeFont(SystemFont_Shadow_Huge1           , FontStandard, SizeHuge  , nil)
	ChangeFont(SystemFont_OutlineThick_Huge2     , FontStandard, SizeHuge  , "THICKOUTLINE")
	ChangeFont(SystemFont_Shadow_Outline_Huge2   , FontStandard, SizeHuge  , "THICKOUTLINE")
	ChangeFont(SystemFont_Shadow_Huge3           , FontStandard, SizeHuge  , nil)
	ChangeFont(SystemFont_OutlineThick_Huge4     , FontStandard, SizeHuge  , "THICKOUTLINE")
	ChangeFont(SystemFont_OutlineThick_WTF       , FontStandard, SizeInsane, "THICKOUTLINE")

	ChangeFont(NumberFont_Shadow_Small           , FontSmall   , SizeSmall , nil)
	ChangeFont(NumberFont_OutlineThick_Mono_Small, FontStandard, SizeMedium, "OUTLINE")
	ChangeFont(NumberFont_Shadow_Med             , FontStandard, SizeMedium, nil)
	ChangeFont(NumberFont_Outline_Med            , FontStandard, SizeMedium, "OUTLINE")
	ChangeFont(NumberFont_Outline_Large          , FontStandard, SizeLarge , "OUTLINE")
	ChangeFont(NumberFont_Outline_Huge           , FontStandard, SizeHuge  , "OUTLINE")

	ChangeFont(QuestFont_Large                   , FontFancy   , SizeMedium, nil)
	ChangeFont(QuestFont_Shadow_Huge             , FontFancy   , SizeHuge  , nil)
	ChangeFont(GameTooltipHeader                 , FontStandard, SizeMedium, nil)
	ChangeFont(MailFont_Large                    , FontFancy   , SizeMedium, nil)
	ChangeFont(SpellFont_Small                   , FontSmall   , SizeSmall , nil)
	ChangeFont(InvoiceFont_Med                   , FontStandard, SizeMedium, nil)
	ChangeFont(InvoiceFont_Small                 , FontSmall   , SizeSmall , nil)
	ChangeFont(Tooltip_Med                       , FontStandard, SizeMedium, nil)
	ChangeFont(Tooltip_Small                     , FontSmall   , SizeSmall , nil)
	ChangeFont(AchievementFont_Small             , FontSmall   , SizeSmall , nil)
	ChangeFont(ReputationDetailFont              , FontSmall   , SizeSmall , nil)
	ChangeFont(FriendsFont_UserText              , FontSmall   , SizeSmall , nil)
	ChangeFont(FriendsFont_Normal                , FontStandard, SizeMedium, nil)
	ChangeFont(FriendsFont_Small                 , FontSmall   , SizeSmall , nil)
	ChangeFont(FriendsFont_Large                 , FontStandard, SizeLarge , nil)
	ChangeFont(CombatTextFont					 , FontCombat  , 100       , "THINOUTLINE", nil, nil, nil, nil, nil, nil, 1, -1)

	-- Game engine fonts
	STANDARD_TEXT_FONT = FontStandard
	NAMEPLATE_FONT = FontStandard
	UNIT_NAME_FONT = FontStandard
	DAMAGE_TEXT_FONT = FontCombat

	-- Combat text
	local UpdateBlizzardCombatText = function()
		COMBAT_TEXT_HEIGHT = 100
		COMBAT_TEXT_CRIT_MAXHEIGHT = 100
		COMBAT_TEXT_CRIT_MINHEIGHT = 100
		COMBAT_TEXT_MAX_OFFSET = 100
		COMBAT_TEXT_X_ADJUSTMENT = 100
		COMBAT_TEXT_Y_SCALE = 0.2
		COMBAT_TEXT_X_SCALE = 0.2
		COMBAT_TEXT_SPACING = 10
		COMBAT_TEXT_FADEOUT_TIME = 1.5
		COMBAT_TEXT_SCROLLSPEED = 3.5

		COMBAT_TEXT_TYPE_INFO["COMBO_POINTS"] = {r = 1.0, g = 1.0, b = 0.0, var = "COMBAT_TEXT_SHOW_COMBO_POINTS"}
		COMBAT_TEXT_TYPE_INFO["MANA_LOW"] = {r = 0, g = 144/255, b = 1, var = "COMBAT_TEXT_SHOW_LOW_HEALTH_MANA"}

		if (C.combatText.showHealing) then
			COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL"] = {r = 0.1, g = 1, b = 0.1, show = 1}
			COMBAT_TEXT_TYPE_INFO["HEAL_CRIT"] = {r = 0.1, g = 1, b = 0.1, show = 1}
			COMBAT_TEXT_TYPE_INFO["HEAL"] = {r = 0.1, g = 1, b = 0.1, show = 1}
			COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_ABSORB"] = {r = 0.1, g = 1, b = 0.1, show = 1}
			COMBAT_TEXT_TYPE_INFO["HEAL_CRIT_ABSORB"] = {r = 0.1, g = 1, b = 0.1, show = 1}
			COMBAT_TEXT_TYPE_INFO["HEAL_ABSORB"] = {r = 0.1, g = 1, b = 0.1, show = 1}
		else
			COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL"] = {r = 0.1, g = 1, b = 0.1}
			COMBAT_TEXT_TYPE_INFO["HEAL_CRIT"] = {r = 0.1, g = 1, b = 0.1}
			COMBAT_TEXT_TYPE_INFO["HEAL"] = {r = 0.1, g = 1, b = 0.1}
			COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_ABSORB"] = {r = 0.1, g = 1, b = 0.1}
			COMBAT_TEXT_TYPE_INFO["HEAL_CRIT_ABSORB"] = {r = 0.1, g = 1, b = 0.1}
			COMBAT_TEXT_TYPE_INFO["HEAL_ABSORB"] = {r = 0.1, g = 1, b = 0.1}
		end

		if (C.combatText.hideDebuffs) then
			COMBAT_TEXT_TYPE_INFO["SPELL_AURA_START_HARMFUL"] = {r = 1.0, g = 0.0, b = 0.0, var = "COMBAT_TEXT_SHOW_AURAS"}
			COMBAT_TEXT_TYPE_INFO["SPELL_AURA_END_HARMFUL"] = {r = 1.0, g = 0.0, b = 0.0, var = "COMBAT_TEXT_SHOW_AURAS"}
		else
			COMBAT_TEXT_TYPE_INFO["SPELL_AURA_START_HARMFUL"] = {r = 1.0, g = 0.0, b = 0.0}
			COMBAT_TEXT_TYPE_INFO["SPELL_AURA_END_HARMFUL"] = {r = 1.0, g = 0.0, b = 0.0}
		end

		-- lets class color the auras that we get, makes easier to spot them!
		local playerColor = RAID_CLASS_COLORS[T.playerClass]
		COMBAT_TEXT_TYPE_INFO["SPELL_CAST"] = {r = playerColor.r, g = playerColor.g, b = playerColor.b, show = 1}
		COMBAT_TEXT_TYPE_INFO["SPELL_AURA_END"] = {r = playerColor.r, g = playerColor.g, b = playerColor.b, var = "COMBAT_TEXT_SHOW_AURAS"}
		COMBAT_TEXT_TYPE_INFO["SPELL_AURA_START"] = {r = playerColor.r, g = playerColor.g, b = playerColor.b, var = "COMBAT_TEXT_SHOW_AURAS"}
		COMBAT_TEXT_TYPE_INFO["SPELL_ACTIVE"] = {r = playerColor.r, g = playerColor.g, b = playerColor.b, var = "COMBAT_TEXT_SHOW_REACTIVES"}
	end

	if (IsAddOnLoaded("Blizzard_CombatText")) then
		UpdateBlizzardCombatText()
	else
		local combatText = CreateFrame("Frame")
		combatText:RegisterEvent("ADDON_LOADED")
		combatText:SetScript("OnEvent", function(self, event, addon)
			if (addon == "Blizzard_CombatText") then
				UpdateBlizzardCombatText()
				self:UnregisterEvent("ADDON_LOADED")
			end
		end)
	end
end
