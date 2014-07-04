--[[


--]]
local _, ns = ...
local oUF = ns.oUF or oUF

--
local T, C, G, P, U, _ = unpack(select(2, ...))
local UF = T:GetModule("UnitFrames")

-- Localise a bunch of functions
local _G = _G
local unpack, pairs, format = unpack, pairs, string.format
local UnitChannelInfo, GetTime = UnitChannelInfo, GetTime

--
local channelingTicks = {
	-- Warlock
	[GetSpellInfo(689) or ""] 		= 1, -- Drain Life
	[GetSpellInfo(1120) or ""] 		= 2, -- Drain Soul
	[GetSpellInfo(755) or ""] 		= 1, -- Health Funnel
	[GetSpellInfo(5740) or ""] 		= 2, -- Rain of Fire
	[GetSpellInfo(1949) or ""] 		= 1, -- Hellfire
	[GetSpellInfo(103103) or ""] 	= 1, -- Malefic Grasp
	[GetSpellInfo(108371) or ""] 	= 1, -- Harvest Life
	-- Druid
	[GetSpellInfo(740) or ""] 		= 2, -- Tranquility
	[GetSpellInfo(16914) or ""] 	= 1, -- Hurricane
	[GetSpellInfo(127663) or ""] 	= 1, -- Astral Communion
	-- Priest
	[GetSpellInfo(47540) or ""] 	= 1, -- Penance
	[GetSpellInfo(15407) or ""] 	= 1, -- Mind Flay
	[GetSpellInfo(48045) or ""] 	= 1, -- Mind Sear
	[GetSpellInfo(64843) or ""] 	= 2, -- Divine Hymn
	[GetSpellInfo(64901) or ""] 	= 2, -- Hymn of Hope
	-- Mage
	[GetSpellInfo(10) or ""] 		= 1, -- Blizzard
	[GetSpellInfo(5143) or ""] 		= 0.4, -- Arcane Missiles
	[GetSpellInfo(12051) or ""] 	= 2, -- Evocation
}

--[[
		Castbar functions
--]]
local SetBarTicks
do
	local ticks = {}

	SetBarTicks = function(castBar, ticknum)
		if (ticknum and ticknum > 0) then
			local castTime = select(7, GetSpellInfo(2060))

			if (not castTime or (castTime == 0)) then
				castTime = 2500 / (1 + (GetCombatRatingBonus(CR_HASTE_SPELL) or 0) / 100)
			end

			local tickDuration = (castTime / 2500) * ticknum
			local width = castBar:GetWidth()
			local delta = (tickDuration * width / castBar.max)

			local k = 1
			while (delta * k) < width do
				if (not ticks[k]) then
					ticks[k] = castBar:CreateTexture(nil, "OVERLAY")
					ticks[k]:SetTexture(T.db["media"].texture)
					ticks[k]:SetVertexColor(0.8, 0.7, 0.7)
					ticks[k]:SetWidth(1)
					ticks[k]:SetHeight(castBar:GetHeight())
				end

				ticks[k]:ClearAllPoints()
				ticks[k]:SetPoint("CENTER", castBar, "LEFT", delta * k, 0)
				ticks[k]:Show()

				k = k + 1
			end
		else
			for _, v in pairs(ticks) do
				v:Hide()
			end
		end
	end
end

local OnCastbarUpdate = function(self, elapsed)
	local currentTime = GetTime()

	if (self.casting or self.channeling) then
		local parent = self:GetParent()
		local duration = self.casting and self.duration + elapsed or self.duration - elapsed

		if ((self.casting and duration >= self.max) or (self.channeling and duration <= 0)) then
			self.casting = nil
			self.channeling = nil
			return
		end

		if (self.Time) then
			if (parent.unit == "player") then
				if (self.delay ~= 0) then
					self.Time:SetFormattedText("%.1f | |cffff0000%.1f|r", duration, self.casting and self.max + self.delay or self.max - self.delay)
				else
					self.Time:SetFormattedText("%.1f | %.1f", duration, self.max)
					self.Lag:SetFormattedText("%d ms", self.SafeZone.timeDiff * 1000)
				end
			else
				self.Time:SetFormattedText("%.1f | %.1f", duration, self.casting and self.max + self.delay or self.max - self.delay)
			end
		end

		self.duration = duration
		self:SetValue(duration)
		self.Spark:SetPoint("CENTER", self, "LEFT", (duration / self.max) * self:GetWidth(), 0)
	else
		self.Spark:Hide()
		local alpha = self:GetAlpha() - 0.02

		if (alpha > 0) then
			self:SetAlpha(alpha)
		else
			self.fadeOut = nil
			self:Hide()
		end
	end
end

local OnCastSent = function(self, event, unit, spell, rank)
	if (self.unit ~= unit or not self.Castbar.SafeZone) then return end

	self.Castbar.SafeZone.sendTime = GetTime()
end

local PostCastStart = function(self, unit, name, rank, text)
	local pcolor = { 1, 0.5, .05 }
	local interruptcb = { 0.5, 0.5, 1.0 }

	self:SetAlpha(1.0)
	self.Spark:Show()
	self:SetStatusBarColor(unpack(self.casting and self.CastingColor or self.ChannelingColor))

	if (unit == "player") then
		local sf = self.SafeZone

		if (not sf.sendTime) then
			sf.timeDiff = 0
		else
			sf.timeDiff = GetTime() - sf.sendTime
			sf.timeDiff = sf.timeDiff > self.max and self.max or sf.timeDiff
			sf:SetWidth(self:GetWidth() * sf.timeDiff / self.max)

			sf:Show()

			if (self.casting) then
				SetBarTicks(self, 0)

				if (self.mergingTradeSkill) then
					sf:Hide()
					self.duration = self.duration + self.max * self.countCurrent
					self.max = self.max * self.countTotal
					self:SetMinMaxValues(0, self.max)
					self:SetValue(self.duration)
					self.countCurrent = self.countCurrent + 1

					if (self.countCurrent == self.countTotal) then
						self.mergingTradeSkill = nil
					end
				end
			else
				local spell = UnitChannelInfo(unit)

				self.channelingTicks = channelingTicks[spell] or 0

				SetBarTicks(self, self.channelingTicks)
			end
		end
	elseif ((unit == "target" or unit == "focus") and not self.interrupt) then
		self:SetStatusBarColor(unpack(self.casting and self.CastingColor or self.ChannelingColor))
		self.bg:SetBackdropBorderColor(0, 0, 0, 0.5)
	else
		self.bg:SetBackdropBorderColor(unpack(self.UninterruptableColor))
		self:SetStatusBarColor(unpack(self.UninterruptableColor))
	end
end

local PostCastStop = function(self, unit, name, rank, castid)
	if (self.mergingTradeSkill) then
		self.duration = self.max * self.countCurrent / self.countTotal
		self:SetValue(self.duration)
		self:SetStatusBarColor(unpack(self.CastingColor))
		self.fadeOut = nil

		local sparkPosition = (self.duration / self.max) * self:GetWidth()
		self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, 2)
		self.Spark:Show()
	else
		if (not self.fadeOut) then
			self:SetStatusBarColor(unpack(self.CompleteColor))
			self.fadeOut = true
		end

		self:SetValue(self.max)
		self:Show()
	end
end

local PostChannelStop = function(self, unit, name, rank)
	self.fadeOut = true
	self.mergingTradeSkill = nil
	self:SetValue(0)
	self:Show()
end

local PostCastFailed = function(self, event, unit, name, rank, castid)
	self:SetStatusBarColor(unpack(self.FailColor))
	self:SetValue(self.max)

	if (not self.fadeOut) then
		self.fadeOut = true
	end

	self.mergingTradeSkill = nil
	self.duration = 0
	self:Show()
end

--[[
		Create a castbar
--]]
local CastbarBackground = function(h)
	h:SetBackdrop {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\AddOns\\draeUI\\media\\textures\\glowtex",
		edgeSize = 4,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	}
	h:SetBackdropColor(0, 0, 0, 1)
	h:SetBackdropBorderColor(0, 0, 0, 0.5)
end

do
	local orgDoTradeSkill = DoTradeSkill

	UF.CreateCastBar = function(self, width, height, anchor, anchorAt, anchorTo, xOffset, yOffset, showLatency, showShield, showIcon, hideBorder)
		local s = CreateFrame("StatusBar", nil, self)
		s:SetHeight(height)
		s:SetWidth(width)
		s:SetPoint(anchorAt, anchor, anchorTo, xOffset, yOffset)
		s:SetStatusBarTexture(T.db["media"].texture)
		s:SetStatusBarColor(0.5, 0.5, 1, 1)

		--color
		s.CastingColor 			= T.db["castbar"].colorCasting or { 0.5, 0.5, 1.0 }
		s.UninterruptableColor	= T.db["castbar"].colorUninteruptable or { 0.68, 0, 0, 1.0 }
		s.CompleteColor 		= T.db["castbar"].colorComplete or { 0.5, 1.0, 0 }
		s.FailColor 			= T.db["castbar"].colorFail or { 1.0, 0.05, 0 }
		s.ChannelingColor 		= T.db["castbar"].colorChannel or { 0.5, 0.5, 1.0 }
		s.OnUpdate 				= OnCastbarUpdate
		s.PostCastStart 		= PostCastStart
		s.PostChannelStart 		= PostCastStart
		s.PostCastStop 			= PostCastStop
		s.PostChannelStop 		= PostChannelStop
		s.PostCastFailed 		= PostCastFailed
		s.PostCastInterrupted 	= PostCastFailed

		self.Castbar = s

		--helper
		local h = CreateFrame("Frame", nil, s)
		h:SetPoint("TOPLEFT", -6, 6)
		h:SetPoint("BOTTOMRIGHT", 6, -6)
		h:SetFrameStrata("BACKGROUND")
		CastbarBackground(h)
		self.Castbar.bg = h

		--backdrop
		local b = s:CreateTexture(nil, "BACKGROUND")
		b:SetTexture(T.db["media"].texture)
		b:SetAllPoints(s)
		b:SetVertexColor(.5 * 0.2, .5 * 0.2, 1 * 0.2, 0.7)

		--spark
		local sp = s:CreateTexture(nil, "OVERLAY")
		sp:SetBlendMode("ADD")
		sp:SetAlpha(0.75)
		sp:SetHeight(s:GetHeight() * 2.75)
		self.Castbar.Spark = sp

		--time
		if (not hideBorder) then
			self.Castbar.Time = T.CreateFontObject(s, T.db["media"].fontsize3, T.db["media"].fontOther, "RIGHT", -5, 0, "NONE")
		end

		--spell text
		if (hideBorder) then
			self.Castbar.Text = T.CreateFontObject(s, T.db["media"].fontsize3, T.db["media"].fontOther, "LEFT", 2, 0, "NONE")
		else
			self.Castbar.Text = T.CreateFontObject(s, T.db["media"].fontsize3, T.db["media"].fontOther, "LEFT", 5, 0, "NONE")
		end

		--icon
		if (showIcon) then
			local i = s:CreateTexture(nil, "ARTWORK")
			i:SetSize(s:GetHeight(), s:GetHeight())
			i:SetPoint("RIGHT", s, "LEFT", -4.5, 0)
			i:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			self.Castbar.Icon = i

			--helper2 for icon
			local h2 = CreateFrame("Frame", nil, s)
			h2:SetFrameLevel(0)
			h2:SetPoint("TOPLEFT", i, "TOPLEFT", -6, 6)
			h2:SetPoint("BOTTOMRIGHT", i, "BOTTOMRIGHT", 6, -6)
			CastbarBackground(h2)
		end

		local b = CreateFrame("Frame", nil, s)
		b:SetPoint("TOPLEFT")
		b:SetPoint("BOTTOMRIGHT")
		b:SetFrameLevel(s:GetFrameLevel() + 5)
		self.Castbar.bg = b

		local border
		if (not hideBorder) then
			border = T.CreateBorder(b, "small")
		end

		-- latency only for player unit same for tradeskill merging
		if (self.unit == "player") then
			local z = s:CreateTexture(nil, "OVERLAY")
			z:SetTexture(T.db["media"].texture)
			z:SetVertexColor(1, 0, 0, .6)
			z:SetPoint("TOPRIGHT")
			z:SetPoint("BOTTOMRIGHT")
			z:Hide()
			s.SafeZone = z

			--custom latency display
			local l = T.CreateFontObject(hideBorder and b or border, T.db["media"].fontsize4, T.db["media"].fontOther, "RIGHT", 6, -12, "THINOUTLINE")
			s.Lag = l

			self:RegisterEvent("UNIT_SPELLCAST_SENT", OnCastSent, true)

			DoTradeSkill = function(index, num, ...)
				orgDoTradeSkill(index, num, ...)
				s.mergingTradeSkill = true
				s.countCurrent = 0
				s.countTotal = tonumber(num) or 1
			end
		end
	end
end

-- Mirror bars
do
	local updateInterval = 1.0 -- One second
	local lastUpdate = 0

	local getFormattedNumber = function(number)
		if (strlen(number) < 2 ) then
			return "0" .. number
		else
			return number
		end
	end

	UF.CreateMirrorCastbars = function(self)
		for _, barId in pairs({"1", "2", "3",}) do
			local bar = "MirrorTimer"..barId

			for i, region in pairs({_G[bar]:GetRegions()}) do
				if (not region:GetName() or region.GetTexture and region:GetTexture() == "SolidTexture") then
					region:Hide()
				end
			end

			--glowing borders
			local h = CreateFrame("Frame", nil, _G[bar])
			h:SetFrameStrata("BACKGROUND")
			h:SetPoint("TOPLEFT", -5, 5)
			h:SetPoint("BOTTOMRIGHT", 5, -5)

			CastbarBackground(h)

			_G[bar]:SetParent(UIParent)
			_G[bar]:SetScale(1)
			_G[bar]:SetHeight(T.db["castbar"].player.height / 1.25)
			_G[bar]:SetWidth(T.db["castbar"].player.width / 2)
			if (bar == "MirrorTimer1") then
				_G[bar]:ClearAllPoints()
				_G[bar]:SetPoint("RIGHT", self.Castbar, "RIGHT", 0, 100)
			else
				_G[bar]:ClearAllPoints()
				_G[bar]:SetPoint("BOTTOM", _G["MirrorTimer"..(barId - 1)], "TOP", 0, 5)
			end

			_G[bar.."Background"] = _G[bar]:CreateTexture(bar.."Background", "BACKGROUND", _G[bar])
			_G[bar.."Background"]:SetTexture(T.db["media"].texture)
			_G[bar.."Background"]:SetAllPoints(bar)
			_G[bar.."Background"]:SetVertexColor(0, 0, 0, 0)

			_G[bar.."Border"]:Hide()

			_G[bar.."Text"]:ClearAllPoints()
			_G[bar.."Text"]:SetFont(T.db["media"].fontOther, 10)
			_G[bar.."Text"]:SetPoint("LEFT", _G[bar.."StatusBar"], 5, 1)

			_G[bar.."TextTime"] = T.CreateFontObject(_G[bar.."StatusBar"], 10, T.db["media"].fontOther, "RIGHT", -5, 1, "NONE") -- Our timer

			_G[bar.."StatusBar"]:ClearAllPoints()
			_G[bar.."StatusBar"]:SetStatusBarTexture(T.db["media"].texture)
			_G[bar.."StatusBar"]:SetAllPoints(_G[bar])

			local timeMsg = ""
			local minutes = 0
			local seconds = 0

			-- Hook scripts
			_G[bar]:HookScript("OnShow", function(self)
				local c = MirrorTimerColors[self.timer]
				_G[self:GetName().."Background"]:SetVertexColor(c.r * 0.33, c.g * 0.33, c.b * 0.33, 1)
			end)

			_G[bar]:HookScript("OnHide", function(self)
				_G[self:GetName().."Background"]:SetVertexColor(0, 0, 0, 0)
				_G[self:GetName().."TextTime"]:SetText("")
			end)

			_G[bar]:HookScript("OnUpdate", function(self, elapsed)
				if (self.paused) then
					return
				end

				if (lastUpdate <= 0) then
					if (self.value >= 60) then
						minutes = floor(self.value / 60)
						local seconds = ceil(self.value - (60 * minutes))

						if (seconds == 60) then
							minutes = minutes + 1
							seconds = 0
						end

						timeMsg = format("%s:%s", minutes, getFormattedNumber(seconds))
					else
						timeMsg = format("%d", self.value)
					end

					_G[self:GetName().."TextTime"]:SetText(timeMsg)

					lastUpdate = updateInterval
				end

				lastUpdate = lastUpdate - elapsed
			end)
		end
	end
end
