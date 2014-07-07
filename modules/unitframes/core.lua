--[[
		Common event handling, specific events are handled
		in their local functions
--]]
local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Local copies
local _G = _G
local UIParent, CreateFrame, UnitName, UnitClass = UIParent, CreateFrame, UnitName, UnitClass
local IsPVPTimerRunning, GetPVPTimer, UnitCanAttack = IsPVPTimerRunning, GetPVPTimer, UnitCanAttack
local UUnitReaction, UnitExists = UnitReaction, UnitExists
local UnitIsPlayer, GameTooltip, InCombatLockdown = UnitIsPlayer, GameTooltip, InCombatLockdown
local CancelUnitBuff, UnitIsFriend, GetShapeshiftFormID, DebuffTypeColor = CancelUnitBuff, UnitIsFriend, GetShapeshiftFormID, DebuffTypeColor
local UnitFrame_OnEnter, UnitFrame_OnLeave = UnitFrame_OnEnter, UnitFrame_OnLeave
local RAID_CLASS_COLORS, FACTION_BAR_COLORS, CAT_FORM, BEAR_FORM = RAID_CLASS_COLORS, FACTION_BAR_COLORS, CAT_FORM, BEAR_FORM
local select, upper, format, gsub, unpack, pairs, huge, insert = select, string.upper, string.format, string.gsub, unpack, pairs, math.huge, table.insert

--[[
		Local functions
--]]
local Menu = function(self)
	local cUnit = self.unit:gsub("(.)", upper, 1)

	if(_G[cUnit .. "FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cUnit .. "FrameDropDown"], "cursor", 0, 0)
	end
end

--[[
		General frame related functions
--]]
UF.CommonInit = function(self, noBg)
	self.menu = Menu -- Enable the menus

	-- Register for mouse clicks, for menu
	self:RegisterForClicks("AnyDown")
	self:SetAttribute("type2", "menu")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
end

UF.CommonPostInit = function(self, size, noRaidIcons)
	-- Framebackdrop - edging is what is coloured for debuff type/threat situation
	local fbg = CreateFrame("Frame", nil, self)
	fbg:SetFrameStrata("BACKGROUND")
	fbg:SetPoint("TOPLEFT", self.Health, -2, 2)
	fbg:SetPoint("BOTTOMRIGHT", self.Power or self.Health, "BOTTOMRIGHT", 2, -2)
	fbg:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	fbg:SetBackdropColor(0, 0, 0, 1)
	self.FrameBackdrop = fbg

	T.CreateBorder(self)

	-- raid target icons for all frames
	if (not noRaidIcons) then
		local raidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		raidIcon:SetPoint("TOP", self.Power and self.Power or self.Health, "BOTTOM", 0, size / 2)
		raidIcon:SetSize(size, size)
		self.RaidIcon = raidIcon
	end

	self.SpellRange = {
		insideAlpha = 1.00,
		outsideAlpha = 0.5
	}

	-- Magnification of buff/debuffs on mouseover
	local ha = CreateFrame("Frame", nil, self)
	ha:SetFrameLevel(5) -- Above auras (level 3) and their cooldown overlay (4)
	ha.icon = ha:CreateTexture(nil, "ARTWORK")
	ha.icon:SetPoint("CENTER")
	ha.border = ha:CreateTexture(nil, "OVERLAY")
	ha.border:SetTexture("Interface\\AddOns\\draeUI\\media\\textures\\textureNormal")
	ha.border:SetPoint("CENTER")
	self.HighlightAura = ha
end

UF.CreateHealthBar = function(self, height)
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetStatusBarTexture(T.db["media"].texture, "BORDER")
	hp:SetHeight(height)
	hp:SetPoint("TOPLEFT")
	hp:SetPoint("TOPRIGHT")

	hp.bg = hp:CreateTexture(nil, "BACKGROUND")
	hp.bg:SetAllPoints(hp)
	hp.bg:SetTexture(T.db["media"].texture)
	hp.bg.multiplier = 0.33

	hp.colorClass = true
	hp.colorDisconnected = true
	hp.colorTapping = true
	hp.colorReaction = true
	hp.Smooth = true
	hp.frequentUpdates = T.db["frames"].healthFrequentUpdates or false

	hp.PostUpdate = UF.PostUpdateHealth

	return hp
end

UF.CreatePowerBar = function(self, height)
	if (height) then
		local pp = CreateFrame("StatusBar", nil, self)
		pp:SetHeight(3)
		pp:SetWidth(T.db["frames"].largeWidth)
		pp:SetStatusBarTexture(T.db["media"].texture, "BORDER")
		pp:SetPoint("LEFT")
		pp:SetPoint("RIGHT")
		pp:SetPoint("TOP", self.Health, "BOTTOM", 0, -1.25) -- Little offset to make it pretty

		-- powerbar background
		pp.bg = pp:CreateTexture(nil, "BACKGROUND")
		pp.bg:SetAllPoints(pp)
		pp.bg:SetTexture(T.db["media"].texture)
		pp.bg.multiplier = 0.33

		pp.colorTapping = true
		pp.colorDisconnected = true
		pp.colorPower = true
		pp.Smooth = true
		pp.frequentUpdates = true

		return pp
	end
end

--[[
	 	Extra powerbar display
--]]
UF.CreateExtraPowerBar = function(self, point, anchor, relpoint, offsetX, offsetY)
	local pp = CreateFrame("StatusBar", nil, self)
	pp:SetHeight(12)
	pp:SetWidth(T.db["frames"].largeWidth)
	pp:SetStatusBarTexture(T.db["media"].texture, "BORDER")
	pp:SetPoint(point, anchor, relpoint, offsetX or 0, offsetY or 42) -- Little offset to make it pretty
	pp:Hide()

	-- powerbar background
	local ppbg = CreateFrame("Frame", nil, pp)
	ppbg:SetPoint("TOPLEFT", -6, 6)
	ppbg:SetPoint("BOTTOMRIGHT", 6, -6)
	ppbg:SetFrameStrata("BACKGROUND")
	ppbg:SetBackdrop {
		edgeFile = "Interface\\AddOns\\draeUI\\media\\textures\\glowtex", edgeSize = 6,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	}
	ppbg:SetBackdropColor(0, 0, 0, 1)
	ppbg:SetBackdropBorderColor(0, 0, 0, 1.0)

	-- powerbar background
	pp.bg = pp:CreateTexture(nil, "BACKGROUND")
	pp.bg:SetAllPoints(pp)
	pp.bg:SetTexture(T.db["media"].texture)
	pp.bg.multiplier = 0.33

	pp.animHideSelf = pp:CreateAnimationGroup()
	local hideBar = pp.animHideSelf:CreateAnimation("Alpha")
	hideBar:SetChange(-0.5)
	hideBar:SetDuration(0.3)
	hideBar:SetOrder(1)
	pp.animHideSelf:SetScript("OnFinished", function()
		pp:Hide()
	end)

	pp.Smooth = true -- Smooth power bar changes

	return pp
end

do
	local UpdateDruidMana = function(self, event, unit)
		local form = GetShapeshiftFormID()

		if (form and (form == CAT_FORM or form == BEAR_FORM)) then
			self.DruidMana:Show()
		else
			self.DruidMana:Hide()
		end
	end

	UF.CreateDruidManaBar = function(self, height)
		if (T.playerClass ~= "DRUID") then return end

		if (height) then
			local pp = CreateFrame("StatusBar", nil, self)
			pp:SetHeight(height)
			pp:SetStatusBarTexture(T.db["media"].texture, "BORDER")
			pp:SetStatusBarColor(0, 0, 1)
			pp:SetPoint("LEFT")
			pp:SetPoint("RIGHT")
			pp:SetPoint("TOP", self.Power, "BOTTOM", 0, -8) -- Place the bar below the main unit frame

			local ppbg = CreateFrame("Frame", nil, pp)
			ppbg:SetPoint("TOPLEFT", -6, 6)
			ppbg:SetPoint("BOTTOMRIGHT", 6, -6)
			ppbg:SetFrameStrata("BACKGROUND")
			ppbg:SetBackdrop {
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				edgeFile = "Interface\\AddOns\\draeUI\\media\\textures\\glowtex",
				edgeSize = 4,
				insets = { left = 4, right = 4, top = 4, bottom = 4 }
			}
			ppbg:SetBackdropColor(0, 0, 0, 1)
			ppbg:SetBackdropBorderColor(0, 0, 0, 0.5)

			-- powerbar background
			pp.bg = pp:CreateTexture(nil, "BACKGROUND")
			pp.bg:SetAllPoints(pp)
			pp.bg:SetTexture(T.db["media"].texture)
			pp.bg.multiplier = 0.33

			pp.colorTapping = true
			pp.colorDisconnected = true
			pp.colorPower = true
			pp.Smooth = true
			pp.frequentUpdates = true

			self:RegisterEvent("UNIT_DISPLAYPOWER", UpdateDruidMana, true)

			return pp
		end
	end
end

do
	local pvptimer, pvpTimerIsRunning

	local UpdateTimer = function()
		local pvpTime = GetPVPTimer()

		if (pvpTime > 0 and pvpTime < 301000) then
			pvptimer:SetFormattedText(("|cffB62220%d:%02d|r"):format((pvpTime / 1000) / 60, (pvpTime / 1000) % 60))
		else
			pvptimer:SetText("")
			UF:CancelTimer(pvpTimerIsRunning, true)

			pvpTimerIsRunning = nil
		end
	end

	local CheckPvPTimer = function(self, status)
		if (IsPVPTimerRunning() and not pvpTimerIsRunning) then
			pvpTimerIsRunning = UF:ScheduleRepeatingTimer(UpdateTimer, 1.0)
		elseif (not status and pvpTimerIsRunning) then
			pvptimer:SetText("")
			UF:CancelTimer(pvpTimerIsRunning, true)

			pvpTimerIsRunning = nil
		end
	end

	-- Adds a realtime pvp timer
	UF.AddPvPTimer = function(self)
		pvptimer = T.CreateFontObject(self.Health, T.db["media"].fontsize2, T.db["media"].font, "TOPRIGHT", 5, -6, nil, self.PvP, "TOPLEFT")

		self:RegisterEvent("PLAYER_FLAGS_CHANGED", CheckPvPTimer)
	end

	-- Leader, PvP, Role, etc.
	UF.FlagIcons = function(self)
		local hp = self.Health

		-- Leader icon
		local leader = hp:CreateTexture(nil, "OVERLAY")
		leader:SetPoint("CENTER", hp, "TOPLEFT", -1, 2)
		leader:SetSize(16, 16)
		self.Leader = leader

		-- Assistant icon
		local assistant = hp:CreateTexture(nil, "OVERLAY")
		assistant:SetPoint("CENTER", hp, "TOPLEFT", -1, 2)
		assistant:SetSize(16, 16)
		self.Assistant = assistant

		-- pvp icon
		local pvp = hp:CreateTexture(nil, "OVERLAY")
		pvp:SetPoint("CENTER", hp, "BOTTOMRIGHT", 8, -14)
		pvp:SetSize(36, 36)
		pvp.PostUpdate = CheckPvPTimer
		self.PvP = pvp

		-- Dungeon role
		local lfdRole = hp:CreateTexture(nil, "OVERLAY")
		lfdRole:SetPoint("CENTER", hp, "BOTTOMLEFT", -1, -7)
		lfdRole:SetSize(16, 16)
		lfdRole:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
		self.LFDRole = lfdRole
	end
end

-- Aura handling
do
	local AuraOnEnter = function(self)
		if (not self:IsVisible()) then return end

		-- Aura magnification
		local hilight 	= self.parent:GetParent().HighlightAura
		local auraSize 	= self:GetParent().size

		hilight:SetPoint("TOPLEFT", self, "TOPLEFT", -(auraSize * T.db["frames"].auras.auraMag - auraSize) / 2, (auraSize * T.db["frames"].auras.auraMag - auraSize) / 2)
		hilight:SetSize(auraSize * T.db["frames"].auras.auraMag, auraSize * T.db["frames"].auras.auraMag)

		hilight.border:SetSize(auraSize * T.db["frames"].auras.auraMag * 1.1, auraSize * T.db["frames"].auras.auraMag * 1.1)

		hilight.icon:SetSize(auraSize * T.db["frames"].auras.auraMag, auraSize * T.db["frames"].auras.auraMag)
		hilight.icon:SetTexture(self.icon:GetTexture())

		hilight:Show()

		-- Add aura owner to tooltip if available - colour by class/reaction because it looks nice!
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetUnitAura(self.parent:GetParent().unit, self:GetID(), self.filter)

		if (self.caster and UnitExists(self.caster)) then
			local color

			if (UnitIsPlayer(self.caster)) then
				if (RAID_CLASS_COLORS[select(2, UnitClass(self.caster))]) then
					color = RAID_CLASS_COLORS[select(2, UnitClass(self.caster))]
				end
			else
				color = FACTION_BAR_COLORS[UnitReaction(self.caster, "player")]
			end

			GameTooltip:AddLine(("Cast by %s%s|r"):format(T.Hex(color.r, color.g, color.b), UnitName(self.caster)))
		end

		GameTooltip:Show()
	end

	local AuraOnLeave = function(self)
		self.parent:GetParent().HighlightAura:Hide()
		GameTooltip:Hide()
	end

	local CreateAuraIcon = function(icons, index)
		icons.createdIcons = icons.createdIcons and icons.createdIcons + 1

		local button = CreateFrame("Button", nil, icons)

		button:EnableMouse(true)
		button:RegisterForClicks("RightButtonUp")

		button:SetWidth(icons.size or 16)
		button:SetHeight(icons.size or 16)

		local border = CreateFrame("Frame", nil, button)
		border:SetPoint("TOPLEFT", button, -6, 6)
		border:SetPoint("BOTTOMRIGHT", button, 6, -6)
		border:SetFrameStrata("BACKGROUND")
		border:SetBackdrop {
			edgeFile = "Interface\\AddOns\\draeUI\\media\\textures\\glowtex",
			tile = false,
			edgeSize = 6
		}
		border:SetBackdropBorderColor(0, 0, 0, 0.5)
		button.border = border

		local icon = button:CreateTexture(nil, "BACKGROUND")
		icon:SetTexCoord(.07, .93, .07, .93)
		icon:SetPoint("TOPLEFT", button, "TOPLEFT", -0.7, 0.93)
		icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0.7, -0.93)
		button.icon = icon

		local overlay = button:CreateTexture(nil, "OVERLAY")
		button.overlay = overlay

		local cd = CreateFrame("Cooldown", nil, button)
		cd:SetReverse(true)
		cd:SetAllPoints(button)
		button.cd = cd

		local borderFrame = T.CreateBorder(button, "small")
		button.borderFrame = borderFrame

		local count = borderFrame:CreateFontString(nil)
		count:SetFont(T.db["media"].fontOther, T.db["media"].fontsize3, "OUTLINE")
		count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 7, -6)
		button.count = count

		local stealable = borderFrame:CreateTexture(nil, "OVERLAY")
		stealable:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
		stealable:SetPoint("TOPLEFT", icon, "TOPLEFT")
		stealable:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
		stealable:SetBlendMode("ADD")
		button.stealable = stealable

		button.parent = icons

		button:SetScript("OnEnter", AuraOnEnter)
		button:SetScript("OnLeave", AuraOnLeave)

		local unit = icons:GetParent().unit

		if (unit == "player") then
			button:SetScript("OnClick", function(self)
				if (InCombatLockdown()) then return end

				CancelUnitBuff(self.parent:GetParent().unit, self:GetID(), self.filter)
			end)
		end

		insert(icons, button)

		return button
	end

	local PostUpdateIcon = function(self, unit, icon, index)
		local color = DebuffTypeColor[icon.dtype]

		if (color) then
			T.SetBorderColor(icon, "border", color.r, color.g, color.b, 1.0)
			T.SetBorderColor(icon, "shadow", color.r, color.g, color.b, 1.0)
			icon.border:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
		else
			T.SetBorderColor(icon, "border", 1.0, 1.0, 1.0, 1.0)
			T.SetBorderColor(icon, "shadow", 1.0, 1.0, 1.0, 0)
			icon.border:SetBackdropBorderColor(0, 0, 0, 0.5)
		end

		if (icon.debuff and icon.isEnemy and not icon.isPlayer) then
			icon.icon:SetDesaturated(true)
		else
			icon.icon:SetDesaturated(false)
		end
	end

	local CustomFilter = function(element, unit, button, name, _, _, _, dtype, duration, _, caster, _, _, spellid, _, isBossDebuff)
		button.isPlayer = (caster == "player" or caster == "vehicle" or caster == "pet")
		button.isFriendly = UnitCanAssist("player", unit)
		button.isEnemy = UnitCanAttack("player", unit)

		button.duration = (duration == 0) and huge or duration
		button.caster = caster
		button.dtype=  dtype

		if (T.db["frames"].auras.blacklistAuraFilter[name]) then
			return false
		end

		--local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellid, "ENEMY_TARGET")

		--[[
				* All non-zero duration buffs on friendly targets (pre-filter affects this)
				* All buffs on enemy targets (pre-filter affects this)
				* Short term buffs on player/pet
		--]]
		if (button.filter == "HELPFUL") then
			if (unit ~= "player" and unit ~= "pet" and unit ~= "vehicle") then
				if (T.db["frames"].auras.showBuffsOnFriends and button.isFriendly and duration > 0) then
					return true
				elseif (T.db["frames"].auras.showBuffsOnEnemies and button.isEnemy and (duration > 0 or isBossDebuff)) then
					return true
				end
			elseif (T.db["frames"].auras.showBuffsOnMe and duration > 0 and duration <= 600) then
				return true
			end
		end

		--[[
				* All debuffs on friendly targets (pre-filter affects this)
				* My debuffs on enemy targets
				* All debuffs on player/pet (pre-filter affects this)
		--]]
		if (button.filter == "HARMFUL") then
			if (unit ~= "player" and unit ~= "pet" and unit ~= "vehicle") then
				if (T.db["frames"].auras.showDebuffsOnFriends and button.isFriendly) then
					return true
				elseif (T.db["frames"].auras.showDebuffsOnEnemies and button.isEnemy and button.isPlayer) then
					return true
				end
			elseif (T.db["frames"].auras.showDebuffsOnMe) then
				return true
			end
		end

		-- Filtered buffs/debuffs
		if (T.db["frames"].auras.filterType == "WHITELIST") then
			if (T.db["frames"].auras.whiteListFilter[element.filter == "HELPFUL" and "BUFF" or "DEBUFF"][name]) then
				return true
			end

			return false
		else
			if (T.db["frames"].auras.blackListFilter[element.filter == "HELPFUL" and "BUFF" or "DEBUFF"][name]) then
				return false
			end

			return true
		end

		return false
	end

	local BuffPreUpdate = function(self, unit)
		self.filter = GetCVar("showCastableBuffs") == "1" and UnitCanAssist("player", unit) and "HELPFUL|RAID" or nil
	end

	local DebuffPreUpdate = function(self, unit)
		self.filter = GetCVar("showDispelDebuffs") == "1" and UnitCanAssist("player", unit) and "HARMFUL|RAID" or nil
	end

	UF.AddDebuffs = function(self, point, relativeFrame, relativePoint, ofsx, ofsy, num, size, spacing, growthx, growthy, playerOnly)
		local debuffsPerRow = T.db["frames"].auras.debuffs_per_row[self.unit] or T.db["frames"].auras.debuffs_per_row["other"]

		local width = (spacing * debuffsPerRow) + (size * debuffsPerRow)
		local height= (spacing * (num / debuffsPerRow)) + (size * (num / debuffsPerRow))

		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy)
		debuffs:SetSize(width, height)

		debuffs.num = num
		debuffs.size = size
		debuffs.spacing	= spacing
		debuffs.initialAnchor = point
		debuffs["growth-x"] = growthx
		debuffs["growth-y"] = growthy
		debuffs.filter = "HARMFUL" -- Explicitly set the filter or the first customFilter call won"t work
		debuffs.showDebuffType = true

		debuffs.PreUpdate = DebuffPreUpdate
		debuffs.CustomFilter = CustomFilter
		debuffs.CreateIcon = CreateAuraIcon
		debuffs.PostUpdateIcon = PostUpdateIcon

		self.Debuffs = debuffs
	end

	UF.AddBuffs = function(self, point, relativeFrame, relativePoint, ofsx, ofsy, num, size, spacing, growthx, growthy, filter, perrow)
		local buffsPerRow = perrow or T.db["frames"].auras.buffs_per_row[self.unit] or T.db["frames"].auras.buffs_per_row["other"]

		local width	= (spacing * buffsPerRow) + (size * buffsPerRow)
		local height = (spacing * (num / buffsPerRow)) + (size * (num / buffsPerRow))

		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint(point, relativeFrame, relativePoint, ofsx, ofsy)
		buffs:SetSize(width, height)

		buffs.num = num
		buffs.numBuffs = num
		buffs.numDebuffs = 0
		buffs.size = size
		buffs.spacing = spacing
		buffs.initialAnchor = point
		buffs["growth-x"] = growthx
		buffs["growth-y"] = growthy
		buffs.filter = "HELPFUL" -- Explicitly set the filter or the first customFilter call won"t work
		buffs.showBuffType = true
		buffs.showStealableBuffs = T.playerClass == "MAGE" and T.db["frames"].showStealableBuffs or false

		buffs.PreUpdate = BuffPreUpdate
		buffs.CreateIcon = CreateAuraIcon
		buffs.PostUpdateIcon = PostUpdateIcon
		buffs.CustomFilter = filter or CustomFilter

		self.Buffs = buffs
	end
end
