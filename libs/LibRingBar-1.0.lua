local MAJOR, MINOR = "LibRingBar", "1";
local LibRingBar = LibStub:NewLibrary(MAJOR, MINOR);

if not LibRingBar then
	return;
end

--------------------------------------------------------------------------------
local DEFAULT_SIZE = 50;
local DEFAULT_SCALE = 1;

--[[
TextureCfg = {
	name 					: texture cfg name
	bodyTexture		: ring texture string, which should be in state of degree 0 - 90 (a quarter)
	endTexture1		: end texture string (counter-clockwise)
	endTexture2		: end texture string (clockwise)
	segmentsize		: size of bodyTexture (pixel), must > 0
	outer_radius	: outer ring radius (pixel), must > 0
	inner_radius	: inner ring radius (pixel), must > 0
	blendmode			: texture blend mode, nil for DEFAULT_BLENDMODE
}
]]

--[[
SparkTexture = {
	name 				: spark cfg name
	texture 		: spark texture string, which should be in state of degree 0
	shiftRadian : spark texture shift radain
	radius			: cycle radius for spark texture center, if nil then use (TextureCfg.outer_radius + TextureCfg.inner_radius)/2
	scale				: texture scale, nil for DEFAULT_SCALE
	blendmode		:	blend mode, nil for DEFAULT_BLENDMODE
)
]]

--[[
RingCfg = {
	startDegree	: 0, 90, 180 or 270, others means default
	totalDegree	: -360 ~ +360, 0 means default
	color				: color table {r,g,b,a}
	minValue		: any number
	maxValue		: any number

	textureID		: name of using TextureCfg
	sparkID			: name of using SparkTexture
	blendmode		: master blend mode, overwrites texture blend mode
}
]]
local DEFAULT_RING = {
	startDegree = 0,
	totalDegree = -360,
	color = {r = 1, g = 1, b = 1, a = 1},
	minValue = 0,
	maxValue = 100,

	textureID,
	sparkID,
};

local RingBar = {}; --template

--------------------------------------------------------------------------------LibRingBar
local _RingTextures = {};
local _RingTextureCnt = 0;

local _SparkTextures = {};
local _SparkTextureCnt = 0;

function LibRingBar:RegisterRingTexture(textureCfg)
	_RingTextures[textureCfg.name] = textureCfg;
	_RingTextureCnt = _RingTextureCnt + 1;
end

function LibRingBar:GetTexture(textureID)
	return _RingTextures[textureID];
end

function LibRingBar:TextureIterator()
	return pairs(_RingTextures);
end

function LibRingBar:GetTextureCount()
	return _RingTextureCnt;
end

function LibRingBar:RegisterSpark(sparkcfg)
	_SparkTextures[sparkcfg.name] = sparkcfg;
	_SparkTextureCnt = _SparkTextureCnt + 1;
end

function LibRingBar:GetSpark(textureID)
	return _SparkTextures[textureID];
end

function LibRingBar:SparkIterator()
	return pairs(_SparkTextures);
end

function LibRingBar:GetSparkCount()
	return _SparkTextureCnt;
end

function LibRingBar:NewRingBar(parent, ring)
	return RingBar:_newRing(parent, ring);
end

--------------------------------------------------------------------------------RingBar
--private
function RingBar:_newRing(parent, ring)
	ring = ring or {};
	setmetatable(ring, self);
	self.__index = self;

	--check
	ring:_initCheck();
	--
	ring:_createVisual(parent);
	ring:_initFieldPercents();

	return ring;
end

function RingBar:_getFrame()
	--overwrited latter
	return nil;
end

function RingBar:_release()
	f = self:GetFrame();
	f.spark:Hide();
	f.spark = nil;
	for _, sf in ipairs(f.fields) do
		sf.texture1:Hide();
	  sf.texture2:Hide();
	  sf.fullSegment:Hide();
	  sf.slicer1:Hide();
	  sf.slicer2:Hide();
	  sf.texture1 = nil;
	  sf.texture2 = nil;
	  sf.fullSegment = nil;
	  sf.slicer1 = nil;
	  sf.slicer2 = nil;
	end
	f:ClearAllPoints();
	f:Hide();
end

function RingBar:_initCheck()
	self.startDegree = self.startDegree or DEFAULT_RING.startDegree;
	self.totalDegree = self.totalDegree or DEFAULT_RING.totalDegree;
	self.color = self.color or DEFAULT_RING.color;
	self.minValue = self.minValue or DEFAULT_RING.minValue;
	self.maxValue = self.maxValue or DEFAULT_RING.maxValue;

	self.textureID = self.textureID or DEFAULT_RING.textureID;
	self.sparkID = self.sparkID or DEFAULT_RING.sparkID;

	self.startDegree = (self.startDegree == 0 or self.startDegree == 90 or self.startDegree == 180 or self.startDegree == 270) and self.startDegree or DEFAULT_RING.startDegree;
	self.totalDegree = self.totalDegree == 0 and DEFAULT_RING.totalDegree or self.totalDegree;
	self.minValue = math.min(self.minValue, self.maxValue);
	self.maxValue = math.max(self.minValue, self.maxValue);
end

-- whenever a texture is changed
function RingBar:_createVisual(parent)
	local cfg = LibRingBar:GetTexture(self.textureID);
  local spark = LibRingBar:GetSpark(self.sparkID);

  local segSize = cfg and cfg.segmentsize or DEFAULT_SIZE;
  local blendmode = (self.blendmode) or (cfg and cfg.blendmode) or DEFAULT_BLENDMODE;

	--main frame
	local f;
	if self:_getFrame() then
		self:_release();
		f = self:_getFrame();
	else
		f = CreateFrame("Frame", nil, parent);
		f:UnregisterAllEvents();
		f:SetMovable(false);
		f:SetResizable(false);
		f:EnableMouse(false);

		f.ringValue = 0; --ensure not nil
		f.fields = {};
		for i = 1, 4 do
			local sf = CreateFrame("Frame", nil, f);
			sf:UnregisterAllEvents();
			sf:SetMovable(false);
			sf:SetResizable(false);
			sf:EnableMouse(false);
			tinsert(f.fields, sf);
		end
	end
	f:SetPoint("CENTER");
	local size = 2 * segSize;
	f:SetWidth(size);
  f:SetHeight(size);
  f:Show();

	--spark
	f.spark = f:CreateTexture(nil, "OVERLAY");
	if spark then
		f.spark:SetTexture(spark.texture);
		if cfg then
			local sparkSize = (cfg.outer_radius - cfg.inner_radius) * (spark.scale or DEFAULT_SCALE);
			f.spark:SetHeight(sparkSize);
			f.spark:SetWidth(sparkSize);
			f.spark.radius = spark.radius;
		end
		f.spark:Hide();

		f.spark.shiftRadian = spark.shiftRadian or 0;
		f.spark.radius = (f.spark.radius) or (cfg and (cfg.outer_radius + cfg.inner_radius) / 2) or segSize;
	end

	--textures
  for _, sf in ipairs(f.fields) do
    local t1 = sf:CreateTexture(nil, "BACKGROUND");
	  t1:SetVertexColor(self.color.r, self.color.g, self.color.b, self.color.a);
	  t1:Hide();
	  local t2 = sf:CreateTexture(nil, "BACKGROUND");
	  t2:SetVertexColor(self.color.r, self.color.g, self.color.b, self.color.a);
	  t2:Hide();
	  local t3 = sf:CreateTexture(nil, "BACKGROUND");
	  t3:SetVertexColor(self.color.r, self.color.g, self.color.b, self.color.a);
	  t3:SetWidth(segSize);
	  t3:SetHeight(segSize);
	  t3:Hide();
	  local s1 = sf:CreateTexture(nil, "BACKGROUND");
	  s1:SetVertexColor(self.color.r, self.color.g, self.color.b, self.color.a);
	  s1:Hide();
		local s2 = sf:CreateTexture(nil, "BACKGROUND");
	  s2:SetVertexColor(self.color.r, self.color.g, self.color.b, self.color.a);
	  s2:Hide();

		if cfg then
			t1:SetTexture(cfg.bodyTexture);
			t2:SetTexture(cfg.bodyTexture);
			t3:SetTexture(cfg.bodyTexture);
			s1:SetTexture(cfg.endTexture1);
			s2:SetTexture(cfg.endTexture2);
		end

		sf:SetWidth(segSize);
    sf:SetHeight(segSize);
		sf.texture1 = t1;
	  sf.texture2 = t2;
	  sf.fullSegment = t3;
	  sf.slicer1 = s1;
	  sf.slicer2 = s2;
  end

  --textures alignment
  f.fields[1]:SetPoint("TOPRIGHT");
  f.fields[1].fullSegment:SetPoint("TOPRIGHT");
  f.fields[1].texture1:SetPoint("BOTTOMLEFT");
  f.fields[1].texture2:SetPoint("TOPRIGHT");

  f.fields[2]:SetPoint("TOPLEFT");
  f.fields[2].fullSegment:SetPoint("TOPLEFT");
  f.fields[2].fullSegment:SetTexCoord(1,0, 0,0, 1,1, 0,1);
	f.fields[2].slicer1:SetTexCoord(1,0, 0,0, 1,1, 0,1);
  f.fields[2].slicer2:SetTexCoord(1,0, 0,0, 1,1, 0,1);
  f.fields[2].texture1:SetPoint("BOTTOMRIGHT");
  f.fields[2].texture2:SetPoint("TOPLEFT");

  f.fields[3]:SetPoint("BOTTOMLEFT");
  f.fields[3].fullSegment:SetPoint("BOTTOMLEFT");
  f.fields[3].fullSegment:SetTexCoord(1,1, 1,0, 0,1, 0,0);
  f.fields[3].slicer1:SetTexCoord(1,1, 1,0, 0,1, 0,0);
  f.fields[3].slicer2:SetTexCoord(1,1, 1,0, 0,1, 0,0);
  f.fields[3].texture1:SetPoint("TOPRIGHT");
  f.fields[3].texture2:SetPoint("BOTTOMLEFT");

	f.fields[4]:SetPoint("BOTTOMRIGHT");
  f.fields[4].fullSegment:SetPoint("BOTTOMRIGHT");
  f.fields[4].fullSegment:SetTexCoord(0,1, 1,1, 0,0, 1,0);
  f.fields[4].slicer1:SetTexCoord(0,1, 1,1, 0,0, 1,0);
  f.fields[4].slicer2:SetTexCoord(0,1, 1,1, 0,0, 1,0);
  f.fields[4].texture1:SetPoint("TOPLEFT");
  f.fields[4].texture2:SetPoint("BOTTOMRIGHT");

  self._getFrame = function()
		return f;
	end;

	return f;
end

-- whenever startDegree or totalDegree is changed
function RingBar:_initFieldPercents()
	local f = self:GetFrame();
	local absTotalDegree = math.abs(self.totalDegree);
	local percPerDegree = 1 / absTotalDegree;

	for i = 1, 4 do
		local sf = f.fields[i];
		--note the XXXDegree indicates non-directed values, that is, 0~360
		local beginDegree;
		if self.totalDegree > 0 then
			beginDegree = (i - 1) * 90 - self.startDegree;
		else
			beginDegree = (4 - i) * 90 - 360 + self.startDegree;
		end
		beginDegree = beginDegree < 0 and beginDegree + 360 or beginDegree;
		if absTotalDegree > beginDegree then
			sf.minPerc = beginDegree * percPerDegree;
			sf.maxPerc = (beginDegree + 90) * percPerDegree;
		else
			sf.minPerc = 1.0;
			sf.maxPerc = 1.1;
		end
	end

	f.startRadian = math.rad(self.startDegree);
end

function RingBar:_setPercent(perc)
	local f = self:GetFrame();
	--spark
	if not self.sparkID then
		--do nothing
	elseif perc == 0 then
		f.spark:Hide();
	else
		local radius = f.spark.radius;
		local radian = f.startRadian + math.rad(perc * self.totalDegree);
		f.spark:SetPoint("CENTER", radius * math.cos(radian), radius * math.sin(radian));
		f.spark:SetRotation(radian - f.spark.shiftRadian);
		f.spark:Show();
	end
	--textures
	if not self.textureID then
		--do nothing
	else
		for i = 1, 4 do
			local sf = f.fields[i];
			if perc <= sf.minPerc then
		  	sf.texture1:Hide();
		    sf.texture2:Hide();
		    sf.fullSegment:Hide();
		    sf.slicer1:Hide();
		    sf.slicer2:Hide();
		  elseif perc >= sf.maxPerc then
		  	sf.texture1:Hide();
		    sf.texture2:Hide();
		  	sf.fullSegment:Show();
		  	sf.slicer1:Hide();
		    sf.slicer2:Hide();
		  else
		 		self:_setFieldPercent(i, (perc - sf.minPerc) / (sf.maxPerc - sf.minPerc));
		    sf.texture1:Show();
		    sf.texture2:Show();
		    sf.fullSegment:Hide();
		    if self.totalDegree > 0 then
					sf.slicer1:Show();
					sf.slicer2:Hide();
				else
					sf.slicer1:Hide();
					sf.slicer2:Show();
				end
		  end
		end
	end
end

--fieldID : 1=TopRight 2=TopLeft 3=BottomLeft 4=BottomRight
function RingBar:_setFieldPercent(fieldID, perc)
	local f = self:GetFrame();
  local t1 = f.fields[fieldID].texture1;
  local t2 = f.fields[fieldID].texture2;
  local s1 = f.fields[fieldID].slicer1;
  local s2 = f.fields[fieldID].slicer2;

	local cfg = LibRingBar:GetTexture(self.textureID);
  local segmentsize = cfg.segmentsize;
  local outer_radius = cfg.outer_radius;
  local inner_radius = cfg.inner_radius;

  local Arad =  math.rad(perc * 90);

  if self.totalDegree < 0 then
  	local Ix = inner_radius * math.sin(Arad);
  	local Iy = segmentsize - (inner_radius * math.cos(Arad));
  	local Ox = outer_radius * math.sin(Arad);
	  local Oy = segmentsize - (outer_radius * math.cos(Arad));
	  local IxCoord = Ix / segmentsize;
	  local OyCoord = Oy / segmentsize;
  	local t1coord_1,t1coord_2, t1coord_3,t1coord_4, t1coord_5,t1coord_6 ,t1coord_7,t1coord_8 = 0,0, 0,1, IxCoord,0, IxCoord,1;
    local t2coord_1,t2coord_2, t2coord_3,t2coord_4, t2coord_5,t2coord_6, t2coord_7,t2coord_8 = IxCoord,0, IxCoord,OyCoord, 1,0, 1,OyCoord;
    if fieldID == 1 then
      t1:SetWidth(Ix);
      t1:SetHeight(segmentsize);
      t2:SetWidth(segmentsize - Ix);
      t2:SetHeight(Oy);
      s2:SetPoint("TOPLEFT", Ix, -Oy);
      s2:SetWidth(Ox - Ix);
      s2:SetHeight(Iy - Oy);
      t1:SetTexCoord(t1coord_1,t1coord_2, t1coord_3,t1coord_4, t1coord_5,t1coord_6, t1coord_7,t1coord_8);
    	t2:SetTexCoord(t2coord_1,t2coord_2, t2coord_3,t2coord_4, t2coord_5,t2coord_6, t2coord_7,t2coord_8);
		elseif fieldID == 2 then
      t1:SetWidth(segmentsize);
      t1:SetHeight(Ix);
      t2:SetWidth(Oy);
      t2:SetHeight(segmentsize - Ix);
      s2:SetPoint("BOTTOMLEFT", Oy, Ix);
      s2:SetWidth(Iy - Oy);
      s2:SetHeight(Ox - Ix);
      t1:SetTexCoord(t1coord_5,t1coord_6, t1coord_1,t1coord_2, t1coord_7,t1coord_8, t1coord_3,t1coord_4);
    	t2:SetTexCoord(t2coord_5,t2coord_6, t2coord_1,t2coord_2, t2coord_7,t2coord_8, t2coord_3,t2coord_4);
    elseif fieldID == 3 then
      t1:SetWidth(Ix);
      t1:SetHeight(segmentsize);
      t2:SetWidth(segmentsize - Ix);
      t2:SetHeight(Oy);
      s2:SetPoint("BOTTOMRIGHT", -Ix, Oy);
      s2:SetWidth(Ox - Ix);
      s2:SetHeight(Iy - Oy);
      t1:SetTexCoord(t1coord_7,t1coord_8, t1coord_5,t1coord_6, t1coord_3,t1coord_4, t1coord_1,t1coord_2);
    	t2:SetTexCoord(t2coord_7,t2coord_8, t2coord_5,t2coord_6, t2coord_3,t2coord_4, t2coord_1,t2coord_2);
    elseif fieldID == 4 then
      t1:SetWidth(segmentsize);
      t1:SetHeight(Ix);
      t2:SetWidth(Oy);
      t2:SetHeight(segmentsize - Ix);
      s2:SetPoint("TOPRIGHT", -Oy, -Ix);
      s2:SetWidth(Iy - Oy);
      s2:SetHeight(Ox - Ix);
      t1:SetTexCoord(t1coord_3,t1coord_4, t1coord_7,t1coord_8, t1coord_1,t1coord_2, t1coord_5,t1coord_6);
    	t2:SetTexCoord(t2coord_3,t2coord_4, t2coord_7,t2coord_8, t2coord_1,t2coord_2, t2coord_5,t2coord_6);
    end
  else	--self.totalDegree > 0
  	local Ix = inner_radius * math.cos(Arad);
 	  local Iy = segmentsize - (inner_radius * math.sin(Arad));
	  local Ox = outer_radius * math.cos(Arad);
	  local Oy = segmentsize - (outer_radius * math.sin(Arad));
	  local IyCoord = Iy / segmentsize;
	  local OxCoord = Ox / segmentsize;
		local t1coord_1,t1coord_2, t1coord_3,t1coord_4, t1coord_5,t1coord_6 ,t1coord_7,t1coord_8 = 0,IyCoord, 0,1, 1,IyCoord, 1,1;
    local t2coord_1,t2coord_2, t2coord_3,t2coord_4, t2coord_5,t2coord_6, t2coord_7,t2coord_8 = OxCoord,0, OxCoord,IyCoord, 1,0, 1,IyCoord;
    if fieldID == 1 then
      t1:SetWidth(segmentsize);
      t1:SetHeight(segmentsize - Iy);
      t2:SetWidth(segmentsize - Ox);
      t2:SetHeight(Iy);
      s1:SetPoint("BOTTOMRIGHT", Ox - segmentsize, segmentsize - Iy);
      s1:SetWidth(Ox - Ix);
      s1:SetHeight(Iy - Oy);
      t1:SetTexCoord(t1coord_1,t1coord_2, t1coord_3,t1coord_4, t1coord_5,t1coord_6, t1coord_7,t1coord_8);
    	t2:SetTexCoord(t2coord_1,t2coord_2, t2coord_3,t2coord_4, t2coord_5,t2coord_6, t2coord_7,t2coord_8);
		elseif fieldID == 2 then
      t1:SetWidth(segmentsize - Iy);
      t1:SetHeight(segmentsize);
      t2:SetWidth(Iy);
      t2:SetHeight(segmentsize - Ox);
      s1:SetPoint("TOPRIGHT", Iy - segmentsize, Ox - segmentsize);
      s1:SetWidth(Iy - Oy);
      s1:SetHeight(Ox - Ix);
      t1:SetTexCoord(t1coord_5,t1coord_6, t1coord_1,t1coord_2, t1coord_7,t1coord_8, t1coord_3,t1coord_4);
    	t2:SetTexCoord(t2coord_5,t2coord_6, t2coord_1,t2coord_2, t2coord_7,t2coord_8, t2coord_3,t2coord_4);
    elseif fieldID == 3 then
      t1:SetWidth(segmentsize);
      t1:SetHeight(segmentsize - Iy);
      t2:SetWidth(segmentsize - Ox);
      t2:SetHeight(Iy);
      s1:SetPoint("TOPLEFT", segmentsize - Ox, Iy - segmentsize);
      s1:SetWidth(Ox - Ix);
      s1:SetHeight(Iy - Oy);
      t1:SetTexCoord(t1coord_7,t1coord_8, t1coord_5,t1coord_6, t1coord_3,t1coord_4, t1coord_1,t1coord_2);
    	t2:SetTexCoord(t2coord_7,t2coord_8, t2coord_5,t2coord_6, t2coord_3,t2coord_4, t2coord_1,t2coord_2);
    elseif fieldID == 4 then
      t1:SetWidth(segmentsize - Iy);
      t1:SetHeight(segmentsize);
      t2:SetWidth(Iy);
      t2:SetHeight(segmentsize - Ox);
      s1:SetPoint("BOTTOMLEFT", segmentsize - Iy, segmentsize - Ox);
      s1:SetWidth(Iy - Oy);
      s1:SetHeight(Ox - Ix);
      t1:SetTexCoord(t1coord_3,t1coord_4, t1coord_7,t1coord_8, t1coord_1,t1coord_2, t1coord_5,t1coord_6);
    	t2:SetTexCoord(t2coord_3,t2coord_4, t2coord_7,t2coord_8, t2coord_1,t2coord_2, t2coord_5,t2coord_6);
    end
  end
end

--public
function RingBar:GetFrame()
	return self:_getFrame() or self:_createVisual();
end

function RingBar:GetCurrentTextureConfig()
	return LibRingBar:GetTexture(self.textureID);
end

function RingBar:SetValue(value)
	value = max(self.minValue, min(value, self.maxValue));
	if self.maxValue == self.minValue then
		self:_setPercent(1);
	else
		self:_setPercent(value / (self.maxValue - self.minValue));
	end
	self:GetFrame().ringValue = value;
end

function RingBar:SetMax()
	self:SetValue(self.maxValue);
end

function RingBar:SetMin()
	self:SetValue(self.minValue);
end

function RingBar:GetValue()
	return self:GetFrame().ringValue;
end

function RingBar:SetMinMaxValues(minValue, maxValue)
	self.minValue = math.min(minValue, maxValue);
	self.maxValue = math.max(minValue, maxValue);
end

function RingBar:GetMinMaxValues()
	return self.minValue, self.maxValue;
end

function RingBar:SetRingColor(r, g, b, a)
	self.color.r = r;
	self.color.g = g;
	self.color.b = b;
	self.color.a = a or 1;

	local f = self:GetFrame();
	for _, sf in ipairs(f.fields) do
		sf.texture1:SetVertexColor(r, g, b, a);
	  sf.texture2:SetVertexColor(r, g, b, a);
	  sf.fullSegment:SetVertexColor(r, g, b, a);
	  sf.slicer1:SetVertexColor(r, g, b, a);
	  sf.slicer2:SetVertexColor(r, g, b, a);
	 end
end

function RingBar:GetRingColor()
	return unpack(self.color);
end

function RingBar:SetMasterBlendMode(blendmode)
	self.blendmode = blendmode;
	self:Reload();
end

function RingBar:GetMasterBlendMode()
	return self.blendmode;
end

function RingBar:Refresh()
	self:_initCheck();
	self:_initFieldPercents();
	self:SetValue(self:GetValue());
end

function RingBar:Reload()
	self:_initCheck();
	self:_createVisual();
	self:SetValue(self:GetValue());
end

--------------------------------------------------------------------------------Defaults
LibRingBar:RegisterSpark({
	name = "castbar spark",
	texture = "Interface\\CastingBar\\UI-CastingBar-Spark",
	shiftRadian = math.rad(90),
	scale = 4,
	blendmode = "ADD",
});
