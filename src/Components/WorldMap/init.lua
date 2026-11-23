--[[
	Components/WorldMap
	Live minimap of a tile world with a tile inspector and tile counts.

	local map = Tab:WorldMap({
		Title    = "World",
		Preset   = "Growblox",                 -- names, colors, skip set, surface row
		World    = function() return gs.world end, -- table with w, h, fg[row][col], bg[row][col]
		GetPlayer = function() return gs.px, gs.py end,
		ItemName = function(id) return gs.Items[id] and gs.Items[id].name end,
		Actions  = {
			{ Title = "Break tile", Primary = true,
			  Visible = function(tile) return tile.Fg ~= 0 and not tile.FgSkip end,
			  Callback = function(tile) print(tile.Col, tile.Row) end },
		},
	})

	Other data source: GetTile = function(col, row, layer) return id end + Width / Height.

	Options
		Title, Desc
		Preset            "Growblox" (or nil)
		World | GetTile   data source (see Scanner.lua)
		Width, Height, GetSize
		GetPlayer         function() -> px, py   (fractional col / row; floor() = tile)
		Items             { [id] = { Name, Color } }   ItemName = function(id) -> name
		Skip              { [id] = true }   tiles shown as SKIP and excluded from "clearable"
		Grass             { [id] = true }   draw a grass cap on exposed tiles
		Highlight         { ids }           quick filter chips for the fg layer
		Surface           row number | false  dashed guide line
		Background        false to hide the fg / bg layer switch
		Live = true, Interval = 2           auto rescan (only while the map is visible)
		ViewHeight = 320                    max map viewport height in pixels
		Zoom = 1                            1..4 (fit, 1.5x, 2x, 3x)
		Inspector = true, Distribution = true, DistributionLimit = 8
		Actions           inspector buttons, Callback(tile)
		OnSelect(tile), OnScan(snapshot)

	tile = { Col, Row, Fg, Bg, FgName, BgName, FgSkip, BgSkip, Distance }

	Methods
		:Refresh()                    rescan now
		:SetLive(bool) :SetInterval(seconds)
		:SetLayer("fg" | "bg") :SetFilter(id | nil) :SetZoom(1..4)
		:Select(col, row) :ClearSelection()
		:GetTile(col, row) -> tile
		:GetCounts("fg" | "bg") -> { [id] = n }
		:Find(id, layer?) -> { { Col, Row }, ... }
		:SetMarkers({ { Col, Row, Color? }, ... })   outline tiles (e.g. Auto Clear targets)
		:SetTitle(text) :SetVisible(bool) :Destroy()
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Palette = import("Components/WorldMap/Palette")
local Scanner = import("Components/WorldMap/Scanner")
local Renderer = import("Components/WorldMap/Renderer")
local Inspector = import("Components/WorldMap/Inspector")
local Distribution = import("Components/WorldMap/Distribution")
local Parts = import("Components/WorldMap/Parts")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local ZOOMS = { 1, 1.5, 2, 3 }
local PLAYER_TICK = 0.15
local SKY_TOP = Color3.fromRGB(27, 42, 68)
local SKY_LOW = Color3.fromRGB(34, 57, 90)
local GROUND = Color3.fromRGB(24, 24, 33)
local SURFACE = Color3.fromRGB(250, 204, 21)

local function isShown(instance)
	local current = instance
	while current and not current:IsA("LayerCollector") do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end
	return current ~= nil
end

local function divider(parent, order)
	local line = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.Bind(line, { BackgroundColor3 = "Stroke" })
	return line
end

return function(tab, options)
	options = options or {}
	local palette = Palette.new(options)
	local preset = palette.Preset
	local scanner = Scanner.new({
		World = options.World,
		GetTile = options.GetTile,
		GetSize = options.GetSize,
		Width = options.Width or preset.Width,
		Height = options.Height or preset.Height,
	})

	local map = {
		Snapshot = nil,
		Layer = "fg",
		Filter = nil,
		Live = options.Live ~= false,
		Interval = options.Interval or 2,
		ZoomIndex = math.clamp(options.Zoom or 1, 1, #ZOOMS),
		Selected = nil,
		Hover = nil,
		Player = nil,
		_alive = true,
		_lastScan = nil,
		_cell = 4,
		_markers = {},
	}
	local surfaceRow = options.Surface
	if surfaceRow == nil then
		surfaceRow = preset.Surface
	end

	---------------------------------------------------------------- card
	local holder = Create("Frame", {
		Name = options.Title or "WorldMap",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Corner(12), Utility.Padding(12, 12, 12, 12), Utility.List(10) })
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder
	map.Instance = holder

	-- Header ----------------------------------------------------------------
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})
	local titleLabel = Builders.Label({
		Text = options.Title or "World",
		Font = Fonts.Bold,
		TextSize = 14,
		Size = UDim2.new(1, -190, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	local scanLabel = Builders.Label({
		Text = options.Desc or "Not scanned yet",
		Font = Fonts.Regular,
		TextSize = 11,
		ThemeColor = "SubText",
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, -190, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	local headerRight = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = header,
	}, { Utility.List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })

	local liveChip = Parts.Chip(headerRight, {
		Text = "Live",
		Swatch = Parts.Colors.Success,
		Height = 26,
		LayoutOrder = 1,
		Callback = function()
			map:SetLive(not map.Live)
		end,
	})
	Parts.Button(headerRight, {
		Text = "Rescan",
		Icon = "refresh",
		Height = 26,
		LayoutOrder = 2,
		Callback = function()
			map:Refresh()
		end,
	})

	-- Toolbar: layer switch + zoom -----------------------------------------
	local toolbar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})
	local layerRow = Create("Frame", {
		Size = UDim2.new(0.6, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = toolbar,
	}, { Utility.List(5, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	local layerChips = {}
	if options.Background ~= false then
		for index, entry in ipairs({ { "fg", "Foreground" }, { "bg", "Background" } }) do
			layerChips[entry[1]] = Parts.Chip(layerRow, {
				Text = entry[2],
				Height = 26,
				LayoutOrder = index,
				Callback = function()
					map:SetLayer(entry[1])
				end,
			})
		end
	end

	local zoomRow = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = toolbar,
	}, { Utility.List(4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	Parts.Button(zoomRow, {
		Text = "-",
		Size = UDim2.fromOffset(26, 26),
		LayoutOrder = 1,
		Callback = function()
			map:SetZoom(map.ZoomIndex - 1)
		end,
	})
	local zoomLabel = Builders.Label({
		Text = "100%",
		Font = Fonts.Mono,
		TextSize = 11,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(40, 26),
		LayoutOrder = 2,
		Parent = zoomRow,
	})
	Parts.Button(zoomRow, {
		Text = "+",
		Size = UDim2.fromOffset(26, 26),
		LayoutOrder = 3,
		Callback = function()
			map:SetZoom(map.ZoomIndex + 1)
		end,
	})

	-- Highlight chips ----------------------------------------------------------
	local chipRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = holder,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})
	local filterChips = {}
	local chipKey = nil

	-- Map viewport -------------------------------------------------------------
	local viewport = Create("ScrollingFrame", {
		Name = "Viewport",
		Size = UDim2.new(1, 0, 0, 200),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		CanvasSize = UDim2.new(),
		LayoutOrder = 4,
		Parent = holder,
	}, { Corner(8) })
	Theme.Bind(viewport, { BackgroundColor3 = "Field", ScrollBarImageColor3 = "SubText" })

	local mapFrame = Create("Frame", {
		Name = "Map",
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = viewport,
	}, { Corner(4) })
	local skyGradient = Create("UIGradient", { Rotation = 90, Parent = mapFrame })

	local renderer = Renderer.new(mapFrame, palette)

	local surfaceLine = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = SURFACE,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 8,
		Visible = false,
		Parent = mapFrame,
	})

	local function outline(color, thickness, z)
		local frame = Create("Frame", {
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = z,
			Parent = mapFrame,
		})
		Create("UIStroke", { Color = color, Thickness = thickness, Parent = frame })
		return frame
	end
	local hoverBox = outline(Color3.new(1, 1, 1), 1.5, 10)
	local pinBox = outline(Theme.Get().Accent, 2, 11)
	Theme.OnChange(function()
		if pinBox.Parent then
			pinBox:FindFirstChildOfClass("UIStroke").Color = Theme.Get().Accent
		end
	end)

	local playerDot = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(9, 9),
		BorderSizePixel = 0,
		ZIndex = 12,
		Visible = false,
		Parent = mapFrame,
	}, { Corner(999), Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }) })
	Theme.Bind(playerDot, { BackgroundColor3 = "Accent" })
	local playerPulse = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = playerDot,
	}, { Corner(999) })
	Theme.Bind(playerPulse, { BackgroundColor3 = "Accent" })

	local hitLayer = Create("TextButton", {
		Name = "Hit",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 20,
		Parent = mapFrame,
	})

	-- Status line --------------------------------------------------------------
	local status = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		Parent = holder,
	})
	local sizeLabel = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.5, 1),
		Parent = status,
	})
	local cursorLabel = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 11,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.5, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = status,
	})

	-- Inspector + distribution ---------------------------------------------------
	local inspector, distribution
	if options.Inspector ~= false then
		divider(holder, 6)
		inspector = Inspector.new(holder, { Palette = palette, Actions = options.Actions, LayoutOrder = 7 })
	end
	if options.Distribution ~= false then
		divider(holder, 8)
		distribution = Distribution.new(holder, palette, {
			LayoutOrder = 9,
			Limit = options.DistributionLimit,
			Footer = "Clearable tiles",
			OnSelect = function(id)
				map:SetFilter((id == 0 or map.Filter == id) and nil or id)
			end,
		})
	end

	---------------------------------------------------------------- helpers
	local function isClearable(id)
		if options.Clearable then
			local ok, result = pcall(options.Clearable, id)
			return ok and result == true
		end
		return id ~= 0 and not palette:IsSkip(id)
	end

	local function readPlayer()
		if not options.GetPlayer then
			return nil
		end
		local ok, a, b = pcall(options.GetPlayer)
		if not ok then
			return nil
		end
		if type(a) == "table" then
			a, b = a.X or a.x or a[1], a.Y or a.y or a[2]
		end
		a, b = tonumber(a), tonumber(b)
		if a and b then
			return { X = a, Y = b }
		end
		return nil
	end

	local function cellAt(screenPosition)
		local snap = map.Snapshot
		if not snap then
			return nil
		end
		local size = mapFrame.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return nil
		end
		local relative = Vector2.new(screenPosition.X, screenPosition.Y) - mapFrame.AbsolutePosition
		local col = math.floor(relative.X / size.X * snap.W) + 1
		local row = math.floor(relative.Y / size.Y * snap.H) + 1
		if col < 1 or row < 1 or col > snap.W or row > snap.H then
			return nil
		end
		return col, row
	end

	local function place(frame, col, row, inset)
		local cell = map._cell
		frame.Position = UDim2.fromOffset((col - 1) * cell - inset, (row - 1) * cell - inset)
		frame.Size = UDim2.fromOffset(cell + inset * 2, cell + inset * 2)
	end

	local function updateInspector()
		if not inspector or not map.Snapshot then
			return
		end
		local mode, col, row
		if map.Selected then
			mode, col, row = "Pinned", map.Selected[1], map.Selected[2]
		elseif map.Hover then
			mode, col, row = "Hover", map.Hover[1], map.Hover[2]
		elseif map.Player then
			mode, col, row = "Your tile", math.floor(map.Player.X), math.floor(map.Player.Y)
		else
			mode, col, row = "Hover", 1, 1
		end
		local tile = map:GetTile(col, row)
		if tile then
			inspector:Set(tile, mode)
		end
	end

	local function updateCursor()
		local snap = map.Snapshot
		if not snap then
			return
		end
		if map.Hover then
			cursorLabel.Text = ("col %d · row %d"):format(map.Hover[1], map.Hover[2])
		elseif map.Player then
			cursorLabel.Text = ("you · col %d · row %d"):format(math.floor(map.Player.X), math.floor(map.Player.Y))
		else
			cursorLabel.Text = ""
		end
	end

	local function updatePlayer()
		map.Player = readPlayer()
		local snap = map.Snapshot
		if not map.Player or not snap then
			playerDot.Visible = false
			return
		end
		local cell = map._cell
		local size = math.max(7, math.floor(cell * 1.4))
		playerDot.Visible = true
		playerDot.Size = UDim2.fromOffset(size, size)
		playerDot.Position = UDim2.fromOffset((map.Player.X - 1) * cell, (map.Player.Y - 1) * cell)
	end

	local function rebuildChips()
		local snap = map.Snapshot
		local ids = {}
		if map.Layer == "fg" then
			ids = options.Highlight or preset.Highlight
			if not ids and snap then
				ids = {}
				for id in pairs(snap.Counts.fg) do
					if id ~= 0 then
						table.insert(ids, id)
					end
				end
				table.sort(ids, function(a, b)
					return snap.Counts.fg[a] > snap.Counts.fg[b]
				end)
			end
		elseif snap then
			for id in pairs(snap.Counts.bg) do
				if id ~= 0 then
					table.insert(ids, id)
				end
			end
			table.sort(ids, function(a, b)
				return snap.Counts.bg[a] > snap.Counts.bg[b]
			end)
		end
		ids = ids or {}

		local list = { "all" }
		for index = 1, math.min(#ids, 6) do
			table.insert(list, ids[index])
		end
		local key = map.Layer .. ":" .. table.concat(list, ",")
		if key == chipKey then
			return
		end
		chipKey = key

		for _, chip in ipairs(filterChips) do
			chip.Instance:Destroy()
		end
		table.clear(filterChips)
		for index, id in ipairs(list) do
			local chip = Parts.Chip(chipRow, {
				Text = id == "all" and "All" or palette:Name(id),
				Swatch = id ~= "all" and palette:Color(id) or nil,
				LayoutOrder = index,
				Callback = function()
					map:SetFilter(id ~= "all" and id or nil)
				end,
			})
			chip.Value = id
			table.insert(filterChips, chip)
		end
		map:_paintChips()
	end

	function map:_paintChips()
		for _, chip in ipairs(filterChips) do
			chip:SetSelected((chip.Value == "all" and self.Filter == nil) or chip.Value == self.Filter)
		end
		for layer, chip in pairs(layerChips) do
			chip:SetSelected(layer == self.Layer)
		end
		liveChip:SetSelected(self.Live)
	end

	-- Sizes the map to the available width and current zoom
	local function layout()
		local snap = map.Snapshot
		local W = snap and snap.W or scanner.Width or 100
		local H = snap and snap.H or scanner.Height or 60
		local available = viewport.AbsoluteSize.X - 8
		if available < 40 then
			return false
		end
		local fit = math.max(2, math.floor(available / W))
		local cell = math.max(2, math.floor(fit * ZOOMS[map.ZoomIndex]))
		map._cell = cell

		local mapW, mapH = W * cell, H * cell
		mapFrame.Size = UDim2.fromOffset(mapW, mapH)
		viewport.CanvasSize = UDim2.fromOffset(mapW + 8, mapH + 8)
		viewport.Size = UDim2.new(1, 0, 0, math.min(mapH + 8, options.ViewHeight or 320))
		zoomLabel.Text = math.floor(ZOOMS[map.ZoomIndex] * 100) .. "%"
		sizeLabel.Text = ("%d × %d · %d tiles"):format(W, H, W * H)

		if surfaceRow and surfaceRow >= 1 and surfaceRow <= H then
			local ratio = (surfaceRow - 1) / H
			skyGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, SKY_TOP),
				ColorSequenceKeypoint.new(math.max(0.001, ratio - 0.001), SKY_LOW),
				ColorSequenceKeypoint.new(math.min(0.999, ratio), GROUND),
				ColorSequenceKeypoint.new(1, GROUND),
			})
			surfaceLine.Visible = true
			surfaceLine.Position = UDim2.fromOffset(0, (surfaceRow - 1) * cell)
		else
			skyGradient.Color = ColorSequence.new(GROUND)
			surfaceLine.Visible = false
		end

		if map.Hover then
			place(hoverBox, map.Hover[1], map.Hover[2], 0)
		end
		if map.Selected then
			place(pinBox, map.Selected[1], map.Selected[2], 1)
		end
		for _, marker in ipairs(map._markers) do
			if marker.Frame.Visible then
				place(marker.Frame, marker.Col, marker.Row, 0)
			end
		end
		return true
	end

	local function redraw()
		if not map.Snapshot then
			return
		end
		if layout() then
			renderer:Draw(map.Snapshot, { Layer = map.Layer, Filter = map.Filter, Cell = map._cell })
			updatePlayer()
		end
	end

	---------------------------------------------------------------- input
	hitLayer.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local col, row = cellAt(input.Position)
		if not col then
			return
		end
		if not map.Hover or map.Hover[1] ~= col or map.Hover[2] ~= row then
			map.Hover = { col, row }
			hoverBox.Visible = true
			place(hoverBox, col, row, 0)
			updateCursor()
			if not map.Selected then
				updateInspector()
			end
		end
	end)
	hitLayer.MouseLeave:Connect(function()
		map.Hover = nil
		hoverBox.Visible = false
		updateCursor()
		updateInspector()
	end)
	hitLayer.InputBegan:Connect(function(input)
		if not Utility.IsClick(input) then
			return
		end
		local col, row = cellAt(input.Position)
		if col then
			map:Select(col, row)
		end
	end)

	viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		redraw()
	end)

	---------------------------------------------------------------- API
	function map:Refresh()
		local snap = scanner:Scan()
		if not snap then
			scanLabel.Text = "Scan failed (see console)"
			return false
		end
		local sizeChanged = not self.Snapshot or self.Snapshot.W ~= snap.W or self.Snapshot.H ~= snap.H
		self.Snapshot = snap
		self._lastScan = os.clock()
		if sizeChanged and self.Selected and (self.Selected[1] > snap.W or self.Selected[2] > snap.H) then
			self:ClearSelection()
		end

		rebuildChips()
		redraw()

		if distribution then
			local layer = self.Layer
			local clearable = 0
			for id, count in pairs(snap.Counts.fg) do
				if isClearable(id) then
					clearable += count
				end
			end
			distribution:Set(
				snap.Counts[layer],
				snap.W * snap.H,
				self.Filter,
				layer == "fg" and "Foreground tiles" or "Background tiles",
				clearable
			)
		end
		updateInspector()
		updateCursor()
		scanLabel.Text = "Scanned just now"
		Utility.SafeCall(options.OnScan, snap)
		return true
	end

	function map:SetLive(live)
		self.Live = live and true or false
		self:_paintChips()
	end

	function map:SetInterval(seconds)
		self.Interval = math.max(0.25, tonumber(seconds) or 2)
	end

	function map:SetLayer(layer)
		self.Layer = layer == "bg" and "bg" or "fg"
		self.Filter = nil
		rebuildChips()
		self:_paintChips()
		if self.Snapshot then
			redraw()
			if distribution then
				distribution:Set(self.Snapshot.Counts[self.Layer], self.Snapshot.W * self.Snapshot.H, nil,
					self.Layer == "fg" and "Foreground tiles" or "Background tiles")
			end
		end
	end

	function map:SetFilter(id)
		self.Filter = id
		self:_paintChips()
		if self.Snapshot then
			redraw()
			if distribution then
				distribution:Set(self.Snapshot.Counts[self.Layer], self.Snapshot.W * self.Snapshot.H, id,
					self.Layer == "fg" and "Foreground tiles" or "Background tiles")
			end
		end
	end

	function map:SetZoom(index)
		self.ZoomIndex = math.clamp(index, 1, #ZOOMS)
		redraw()
	end

	function map:GetTile(col, row)
		local snap = self.Snapshot
		if not snap or not snap.fg[row] or col < 1 or col > snap.W then
			return nil
		end
		local fg, bg = snap.fg[row][col], snap.bg[row][col]
		local distance
		if self.Player then
			-- distance to the tile center, in tiles
			distance = math.sqrt((col + 0.5 - self.Player.X) ^ 2 + (row + 0.5 - self.Player.Y) ^ 2)
		end
		return {
			Col = col,
			Row = row,
			Fg = fg,
			Bg = bg,
			FgName = palette:Name(fg),
			BgName = palette:Name(bg),
			FgSkip = palette:IsSkip(fg),
			BgSkip = palette:IsSkip(bg),
			Distance = distance,
		}
	end

	function map:Select(col, row)
		self.Selected = { col, row }
		pinBox.Visible = true
		place(pinBox, col, row, 1)
		updateInspector()
		local tile = self:GetTile(col, row)
		if tile then
			Utility.SafeCall(options.OnSelect, tile)
		end
	end

	function map:ClearSelection()
		self.Selected = nil
		pinBox.Visible = false
		updateInspector()
	end

	function map:GetCounts(layer)
		return self.Snapshot and self.Snapshot.Counts[layer or "fg"] or {}
	end

	function map:Find(id, layer)
		local found = {}
		local snap = self.Snapshot
		if not snap then
			return found
		end
		local grid = snap[layer or "fg"]
		for row = 1, snap.H do
			for col = 1, snap.W do
				if grid[row][col] == id then
					table.insert(found, { Col = col, Row = row })
				end
			end
		end
		return found
	end

	function map:SetMarkers(list)
		list = list or {}
		for index, data in ipairs(list) do
			local marker = self._markers[index]
			if not marker then
				local frame = outline(Color3.new(1, 1, 1), 1, 9)
				marker = { Frame = frame, Stroke = frame:FindFirstChildOfClass("UIStroke") }
				self._markers[index] = marker
			end
			marker.Col = data.Col or data[1]
			marker.Row = data.Row or data[2]
			marker.Stroke.Color = data.Color or Parts.Colors.Success
			marker.Frame.Visible = true
			place(marker.Frame, marker.Col, marker.Row, 0)
		end
		for index = #list + 1, #self._markers do
			self._markers[index].Frame.Visible = false
		end
	end

	function map:SetTitle(text)
		titleLabel.Text = text
	end

	function map:SetVisible(visible)
		holder.Visible = visible
	end

	function map:Destroy()
		self._alive = false
		renderer:Clear()
		holder:Destroy()
	end

	---------------------------------------------------------------- loop
	map:_paintChips()
	task.spawn(function()
		local pulse = 0
		while map._alive and holder.Parent do
			local shown = isShown(holder)
			if shown then
				if not map.Snapshot or (map.Live and os.clock() - (map._lastScan or 0) >= map.Interval) then
					map:Refresh()
				else
					updatePlayer()
					if not map.Selected and not map.Hover then
						updateInspector()
					end
				end
				if map._lastScan then
					local ago = math.floor(os.clock() - map._lastScan)
					scanLabel.Text = ago < 1 and "Scanned just now" or ("Scanned %ds ago"):format(ago)
				end
				-- soft pulse on the player marker
				pulse = (pulse + PLAYER_TICK) % 1.2
				local t = pulse / 1.2
				playerPulse.Size = UDim2.fromScale(1 + t * 1.6, 1 + t * 1.6)
				playerPulse.BackgroundTransparency = 0.55 + t * 0.45
			end
			task.wait(PLAYER_TICK)
		end
	end)

	return map
end
