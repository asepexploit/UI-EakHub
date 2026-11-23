--[[
	Components/WorldMap/Palette
	Names, colors and skip rules for tile ids.

	local palette = Palette.new(options)
	palette:Name(id)     -> "Dirt" | "Item #123"
	palette:Color(id)    -> Color3 (stable generated color for unknown ids)
	palette:IsSkip(id)   -> true for tiles your bot must never hit
	palette:HasGrass(id) -> draw a grass cap when the tile is exposed to air

	options.Preset   "Growblox" fills Items / Skip / Grass / Surface / size defaults
	options.Items    { [id] = { Name = "Dirt", Color = Color3 } }  (merged over the preset)
	options.ItemName function(id) -> string?  (e.g. read gs.Items[id].name)
	options.Skip     { [id] = true }
]]

local rgb = Color3.fromRGB

local Palette = {}
Palette.__index = Palette

-- Values verified on Growblox (placeId 112863874972771): 100 x 60 world,
-- fg[row][col], 0 = empty, surface around row 37.
Palette.Presets = {
	Growblox = {
		Width = 100,
		Height = 60,
		Surface = 37,
		Items = {
			[2] = { Name = "Dirt", Color = rgb(138, 90, 54) },
			[6] = { Name = "Main Door", Color = rgb(245, 158, 11) },
			[8] = { Name = "Bedrock", Color = rgb(58, 57, 64) },
			[10] = { Name = "Rock", Color = rgb(125, 131, 148) },
			[242] = { Name = "World Lock", Color = rgb(250, 204, 21) },
		},
		Skip = { [0] = true, [6] = true, [8] = true, [242] = true },
		Grass = { [2] = true },
		Highlight = { 2, 10, 8, 6, 242 },
	},
}

local function merge(base, extra)
	local result = {}
	for key, value in pairs(base or {}) do
		result[key] = value
	end
	for key, value in pairs(extra or {}) do
		result[key] = value
	end
	return result
end

function Palette.new(options)
	options = options or {}
	local preset = Palette.Presets[options.Preset or ""] or {}

	local self = setmetatable({}, Palette)
	self.Preset = preset
	self.Items = merge(preset.Items, options.Items)
	self.Skip = merge(preset.Skip or { [0] = true }, options.Skip)
	self.Grass = merge(preset.Grass, options.Grass)
	self.ItemName = options.ItemName
	self._generated = {}
	self._names = {}
	return self
end

function Palette:Name(id)
	if id == 0 then
		return "Empty"
	end
	local item = self.Items[id]
	if item and item.Name then
		return item.Name
	end
	local cached = self._names[id]
	if cached then
		return cached
	end
	local name
	if self.ItemName then
		local ok, result = pcall(self.ItemName, id)
		name = ok and result ~= nil and tostring(result) or nil
	end
	name = name or ("Item #" .. tostring(id))
	self._names[id] = name
	return name
end

-- Unknown ids get a stable color spread around the hue wheel (golden ratio)
function Palette:Color(id)
	local item = self.Items[id]
	if item and item.Color then
		return item.Color
	end
	local color = self._generated[id]
	if not color then
		local number = tonumber(id) or #tostring(id)
		local hue = (number * 0.6180339887) % 1
		color = Color3.fromHSV(hue, 0.45, 0.78)
		self._generated[id] = color
	end
	return color
end

function Palette:IsSkip(id)
	return self.Skip[id] == true
end

function Palette:HasGrass(id)
	return self.Grass[id] == true
end

return Palette
