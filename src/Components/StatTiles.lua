--[[
	Components/StatTiles
	A row of 2-4 compact stat tiles: [icon] Label / big Value.

	local stats = Tab:StatTiles({
		Tiles = {
			{ Title = "Speed",     Value = "0/min", Icon = "activity" },
			{ Title = "Remaining", Value = "—",     Icon = "target", Color = Color3.fromRGB(56, 189, 248) },
			{ Title = "Time left", Value = "—",     Icon = "clock",  Color = Color3.fromRGB(251, 191, 36) },
		},
	})
	stats:Set("Speed", "120/min")      -- by title (case-insensitive) or index
	stats:Set(2, 86)
	stats:SetColor("Time left", Color3.fromRGB(239, 68, 68))
	stats:Get("Speed") -> "120/min"
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create = Utility.Create

local GAP = 8
local HEIGHT = 60

return function(tab, options)
	options = options or {}
	local specs = options.Tiles or {}
	local count = math.clamp(#specs, 1, 4)

	local row = Create("Frame", {
		Name = "StatTiles",
		Size = UDim2.new(1, 0, 0, HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.List(GAP, Enum.FillDirection.Horizontal) })

	local tiles = {} -- array of { Spec, Value, Icon, ValueLabel, TitleLabel, Color }

	local function tileColor(tile)
		return tile.Color or State.Theme.Accent
	end

	for index = 1, count do
		local spec = specs[index]
		local tile = Create("Frame", {
			Size = UDim2.new(1 / count, -GAP * (count - 1) / count, 1, 0),
			BackgroundTransparency = Constants.Glass.Element,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Parent = row,
		}, { Utility.Corner(11), Utility.Padding(10, 10, 12, 12) })
		Theme.Bind(tile, { BackgroundColor3 = "Element" })
		Builders.Stroke().Parent = tile

		local header = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Parent = tile,
		}, { Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

		local icon
		if spec.Icon then
			icon = Create("ImageLabel", {
				Size = UDim2.fromOffset(13, 13),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
				Parent = header,
			})
			Assets.Apply(icon, spec.Icon)
		end

		local titleLabel = Builders.Label({
			Text = spec.Title or ("Stat " .. index),
			Font = Constants.Fonts.Medium,
			TextSize = 11,
			ThemeColor = "SubText",
			Size = UDim2.new(1, icon and -19 or 0, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 2,
			Parent = header,
		})

		local valueLabel = Builders.Label({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 22),
			Font = Constants.Fonts.Bold,
			TextSize = 18,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = tostring(spec.Value or "—"),
			Parent = tile,
		})

		tiles[index] = {
			Title = spec.Title or "",
			Value = spec.Value,
			Color = spec.Color,
			Icon = icon,
			TitleLabel = titleLabel,
			ValueLabel = valueLabel,
		}
		if icon then
			icon.ImageColor3 = tileColor(tiles[index])
		end

	end

	-- One search entry for the whole row: matches any tile title
	if tab._searchables then
		local titles = {}
		for _, tile in ipairs(tiles) do
			table.insert(titles, tile.Title)
		end
		local searchLabel = Create("TextLabel", {
			Name = "SearchIndex",
			Text = table.concat(titles, " "),
			Visible = false,
			Parent = row,
		})
		table.insert(tab._searchables, { Instance = row, Label = searchLabel })
	end

	local function find(key)
		if type(key) == "number" then
			return tiles[key]
		end
		local wanted = string.lower(tostring(key))
		for _, tile in ipairs(tiles) do
			if string.lower(tile.Title) == wanted then
				return tile
			end
		end
		return nil
	end

	local api = { Instance = row, Tiles = tiles }

	function api:Set(key, value)
		local tile = find(key)
		if tile then
			tile.Value = value
			tile.ValueLabel.Text = tostring(value)
		end
	end

	function api:Get(key)
		local tile = find(key)
		return tile and tile.Value
	end

	function api:SetColor(key, color)
		local tile = find(key)
		if tile then
			tile.Color = color
			if tile.Icon then
				tile.Icon.ImageColor3 = tileColor(tile)
			end
		end
	end

	function api:SetVisible(visible)
		row.Visible = visible
	end

	function api:Destroy()
		row:Destroy()
	end

	Theme.OnChange(function()
		for _, tile in ipairs(tiles) do
			if tile.Icon then
				tile.Icon.ImageColor3 = tileColor(tile)
			end
		end
	end)

	return api
end
