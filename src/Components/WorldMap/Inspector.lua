--[[
	Components/WorldMap/Inspector
	Details of one tile: coordinates, fg / bg contents with tags, distance
	from the player, and action buttons.

	local inspector = Inspector.new(parent, { Actions = {...}, LayoutOrder })
	inspector:Set(tile, "Pinned" | "Hover" | "Your tile")

	tile = { Col, Row, Fg, Bg, FgName, BgName, FgSkip, BgSkip, Distance }

	Actions = {
		{ Title = "Walk here", Primary = true,
		  Visible = function(tile) return tile.Fg == 0 end,   -- optional
		  Callback = function(tile) end },
	}
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Parts = import("Components/WorldMap/Parts")

local Create, Corner = Utility.Create, Utility.Corner
local Fonts = Constants.Fonts
local Colors = Parts.Colors

local Inspector = {}
Inspector.__index = Inspector

local function copy(text)
	local writer = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if type(writer) == "function" then
		return (pcall(writer, text))
	end
	return false
end

function Inspector.new(parent, options)
	options = options or {}
	local self = setmetatable({ Tile = nil, _actions = {} }, Inspector)
	self.Palette = options.Palette

	local root = Create("Frame", {
		Name = "Inspector",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = options.LayoutOrder or 0,
		Parent = parent,
	}, { Utility.List(8) })
	self.Instance = root

	-- Header: title + mode pill
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = root,
	})
	Builders.Label({
		Text = "Tile inspector",
		Font = Fonts.Bold,
		TextSize = 13,
		Size = UDim2.fromScale(0.6, 1),
		Parent = header,
	})
	local modeHolder = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = header,
	}, { Utility.List(0, Enum.FillDirection.Horizontal) })
	self._mode = Parts.Tag(modeHolder)

	-- Coordinates
	local coords = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = root,
	}, { Utility.List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Bottom) })
	self._coord = Builders.Label({
		Text = "-",
		Font = Fonts.Mono,
		TextSize = 20,
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = coords,
	})
	Builders.Label({
		Text = "col, row",
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = coords,
	})

	-- Layer rows
	self._layers = {}
	for index, caption in ipairs({ "FOREGROUND", "BACKGROUND" }) do
		local row = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			LayoutOrder = 2 + index,
			Parent = root,
		}, { Corner(9) })
		Theme.Bind(row, { BackgroundColor3 = "Field" })
		Builders.Stroke(0.94).Parent = row

		local swatch = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BorderSizePixel = 0,
			Parent = row,
		}, { Corner(6) })
		Create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.85, Parent = swatch })

		Builders.Label({
			Text = caption,
			Font = Fonts.Bold,
			TextSize = 9,
			ThemeColor = "SubText",
			Position = UDim2.fromOffset(44, 7),
			Size = UDim2.new(1, -120, 0, 12),
			Parent = row,
		})
		local name = Builders.Label({
			Text = "",
			Font = Fonts.Bold,
			TextSize = 13,
			Position = UDim2.fromOffset(44, 20),
			Size = UDim2.new(1, -120, 0, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local right = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(70, 34),
			BackgroundTransparency = 1,
			Parent = row,
		}, { Utility.List(3, nil, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
		local id = Builders.Label({
			Text = "",
			Font = Fonts.Mono,
			TextSize = 11,
			ThemeColor = "SubText",
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.new(1, 0, 0, 14),
			Parent = right,
		})
		local tag = Parts.Tag(right, 2)
		self._layers[index] = { Swatch = swatch, Name = name, Id = id, Tag = tag }
	end

	-- Distance
	local distanceRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		Parent = root,
	})
	Builders.Label({
		Text = "Distance from you",
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.6, 1),
		Parent = distanceRow,
	})
	self._distance = Builders.Label({
		Text = "-",
		Font = Fonts.Bold,
		TextSize = 12,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.4, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = distanceRow,
	})

	-- Actions
	local actions = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 6,
		Parent = root,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local copyButton
	copyButton = Parts.Button(actions, {
		Text = "Copy coords",
		Icon = "copy",
		LayoutOrder = 1,
		Callback = function()
			local tile = self.Tile
			if not tile then
				return
			end
			copy(("%d, %d"):format(tile.Col, tile.Row))
			copyButton:SetText("Copied")
			task.delay(1.2, function()
				copyButton:SetText("Copy coords")
			end)
		end,
	})

	for index, action in ipairs(options.Actions or {}) do
		local button = Parts.Button(actions, {
			Text = action.Title or action.Text or "Action",
			Icon = action.Icon,
			Primary = action.Primary,
			LayoutOrder = index + 1,
			Callback = function()
				if self.Tile then
					Utility.SafeCall(action.Callback, self.Tile)
				end
			end,
		})
		table.insert(self._actions, { Button = button, Action = action })
	end

	return self
end

function Inspector:_tag(id, skip, layer)
	if id == 0 then
		return "EMPTY", Colors.Muted
	elseif skip then
		return "SKIP", Colors.Danger
	elseif layer == "bg" then
		return "BG ITEM", Colors.Violet
	end
	return "CLEARABLE", Colors.Success
end

function Inspector:Set(tile, mode)
	self.Tile = tile
	if not tile then
		return
	end
	local theme = Theme.Get()
	self._mode:Set(string.upper(mode or ""), mode == "Pinned" and theme.Accent or Colors.Muted)
	self._coord.Text = ("%d, %d"):format(tile.Col, tile.Row)

	local data = {
		{ tile.Fg, tile.FgName, tile.FgSkip, "fg" },
		{ tile.Bg, tile.BgName, tile.BgSkip, "bg" },
	}
	for index, entry in ipairs(data) do
		local view = self._layers[index]
		local id, name, skip, layer = entry[1], entry[2], entry[3], entry[4]
		view.Name.Text = name
		view.Id.Text = "#" .. tostring(id)
		view.Swatch.BackgroundColor3 = id == 0 and theme.Field or self.Palette:Color(id)
		view.Swatch.BackgroundTransparency = id == 0 and 0.5 or 0
		view.Tag:Set(self:_tag(id, skip, layer))
	end

	local distance = tile.Distance
	self._distance.Text = distance == nil and "-" or (distance < 1 and "here" or ("%.1f tiles"):format(distance))

	for _, entry in ipairs(self._actions) do
		local visible = true
		if type(entry.Action.Visible) == "function" then
			local ok, result = pcall(entry.Action.Visible, tile)
			visible = ok and result ~= false
		end
		entry.Button.Instance.Visible = visible
	end
end

return Inspector
