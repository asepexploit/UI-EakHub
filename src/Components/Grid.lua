--[[
	Components/Grid
	Tile picker around the player (e.g. choose farm / break spots).
	Click a tile to select it, or hold and drag to paint several.
	The center tile is the player and cannot be selected.

	local grid = Tab:Grid({
		Title          = "ANCH Grid",
		Size           = 5,                         -- odd number; 5 = 5x5
		Value          = { Vector2.new(-1, 0) },    -- offsets from the center tile
		Color          = Color3.fromRGB(34, 160, 90), -- selected tile color
		CenterLabel    = "ME",
		MaxCellSize    = 48,

		Modes          = { "Farm", "Break" },       -- optional mode chip (click to cycle)
		Mode           = "Farm",
		ModeCallback   = function(mode) end,

		ActionText     = "Start {mode}",            -- "{mode}" is replaced by the current mode
		StopText       = "Stop {mode}",
		ActionCallback = function(running, tiles, mode) end,
		ClearText      = "Clear selection",

		Flag           = "FarmGrid",
		Callback       = function(tiles) end,       -- fired when the selection changes
	})

	grid:Get() -> { Vector2 }    -- X: left(-) / right(+), Y: up(-) / down(+)
	grid:Set(tiles) / grid:Clear() / grid:SetMode(name) / grid:SetRunning(bool)
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween
local UserInputService = Services.UserInputService

local GAP = 6
local DEFAULT_COLOR = Color3.fromRGB(34, 160, 90)

local function key(x, y)
	return x .. "," .. y
end

local function format(template, mode)
	return (string.gsub(template, "{mode}", mode or ""))
end

return function(tab, options)
	options = options or {}

	local size = options.Size or 5
	if size % 2 == 0 then
		size += 1 -- keep a real center tile
	end
	local radius = (size - 1) / 2
	local maxCell = options.MaxCellSize or 48
	local selectedColor = options.Color or DEFAULT_COLOR
	local modes = options.Modes
	local mode = options.Mode or (modes and modes[1]) or ""
	local running = false

	local grid = {} -- public object, filled in below
	local actionButton
	local selected = {} -- [key] = Vector2
	for _, offset in ipairs(options.Value or options.Default or {}) do
		if not (offset.X == 0 and offset.Y == 0) then
			selected[key(offset.X, offset.Y)] = offset
		end
	end

	---------------------------------------------------------------- container
	local holder = Create("Frame", {
		Name = options.Title or "Grid",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(10),
		Utility.Padding(12, 12, 12, 12),
		Utility.List(10, nil, Enum.HorizontalAlignment.Center),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	---------------------------------------------------------------- header
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})

	local title = Builders.Label({
		Text = options.Title or "Grid",
		Font = Constants.Fonts.Bold,
		TextSize = 14,
		Size = UDim2.new(1, modes and -100 or 0, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	local modeChip
	if modes then
		modeChip = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = Constants.Glass.Field,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Constants.Fonts.Bold,
			TextSize = 12,
			Text = mode,
			Parent = header,
		}, { Utility.Corner(7), Utility.Padding(0, 0, 14, 14) })
		Theme.Bind(modeChip, { BackgroundColor3 = "ElementHover", TextColor3 = "Text" })
		Builders.Stroke().Parent = modeChip
	end

	---------------------------------------------------------------- grid
	local gridFrame = Create("Frame", {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})
	local gridLayout = Create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(GAP, GAP),
		FillDirectionMaxCells = size,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = gridFrame,
	})

	local cells = {} -- [key] = TextButton

	local function paintCell(x, y, instant)
		local cell = cells[key(x, y)]
		if not cell or (x == 0 and y == 0) then
			return
		end
		local on = selected[key(x, y)] ~= nil
		Tween(cell, {
			BackgroundColor3 = on and selectedColor or State.Theme.Field,
			BackgroundTransparency = on and 0 or 0.1,
		}, instant and 0 or 0.15)
	end

	local function getTiles()
		local list = {}
		for _, offset in pairs(selected) do
			table.insert(list, offset)
		end
		table.sort(list, function(a, b)
			return a.Y == b.Y and a.X < b.X or a.Y < b.Y
		end)
		return list
	end

	local function changed()
		grid.Value = getTiles()
		Utility.SafeCall(options.Callback, grid.Value)
	end

	local function refreshAction()
		if actionButton then
			local template = running and (options.StopText or "Stop {mode}") or (options.ActionText or "Start {mode}")
			actionButton.Text = string.upper(format(template, mode))
			Tween(actionButton, { BackgroundColor3 = running and Constants.Danger or selectedColor }, 0.2)
		end
	end

	local function setTile(x, y, on)
		if x == 0 and y == 0 then
			return false
		end
		local k = key(x, y)
		local was = selected[k] ~= nil
		if was == on then
			return false
		end
		selected[k] = on and Vector2.new(x, y) or nil
		paintCell(x, y)
		return true
	end

	-- Drag painting: the first tile decides whether we select or deselect
	local painting = false
	local paintValue = true

	local order = 0
	for y = -radius, radius do
		for x = -radius, radius do
			order += 1
			local isCenter = x == 0 and y == 0
			local cell = Create("TextButton", {
				Name = key(x, y),
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = isCenter and (options.CenterLabel or "ME") or "",
				Font = Constants.Fonts.Bold,
				TextSize = 12,
				TextColor3 = Color3.new(1, 1, 1),
				LayoutOrder = order,
				Parent = gridFrame,
			}, { Utility.Corner(6) })

			if isCenter then
				Theme.Bind(cell, { BackgroundColor3 = "Accent" })
			else
				Theme.Bind(cell, { BackgroundColor3 = "Field" })
				Builders.Stroke(0.94).Parent = cell

				Utility.Track(cell.InputBegan:Connect(function(input)
					if Utility.IsClick(input) then
						painting = true
						paintValue = selected[key(x, y)] == nil
						if setTile(x, y, paintValue) then
							changed()
						end
					end
				end))

				cell.MouseEnter:Connect(function()
					if painting then
						if setTile(x, y, paintValue) then
							changed()
						end
					elseif not selected[key(x, y)] then
						Tween(cell, { BackgroundColor3 = State.Theme.ElementHover }, 0.12)
					end
				end)

				cell.MouseLeave:Connect(function()
					if not painting then
						paintCell(x, y)
					end
				end)
			end

			cells[key(x, y)] = cell
		end
	end

	Utility.Track(UserInputService.InputEnded:Connect(function(input)
		if painting and Utility.IsClick(input) then
			painting = false
		end
	end))

	-- Square cells that fit the available width (capped by MaxCellSize)
	local function layout()
		local available = holder.AbsoluteSize.X - 24
		if available <= 0 then
			return
		end
		local cell = math.floor(math.min(maxCell, (available - GAP * (size - 1)) / size))
		local total = cell * size + GAP * (size - 1)
		gridLayout.CellSize = UDim2.fromOffset(cell, cell)
		gridFrame.Size = UDim2.fromOffset(total, total)
	end
	Utility.Track(holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
	task.defer(layout)

	---------------------------------------------------------------- action + clear
	if options.ActionText or options.ActionCallback then
		actionButton = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundColor3 = selectedColor,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			ClipsDescendants = true,
			Font = Constants.Fonts.Bold,
			TextSize = 13,
			TextColor3 = Color3.new(1, 1, 1),
			Text = "",
			LayoutOrder = 3,
			Parent = holder,
		}, { Utility.Corner(8) })
		local actionScale = Create("UIScale", { Parent = actionButton })

		Utility.Track(actionButton.InputBegan:Connect(function(input)
			if Utility.IsClick(input) then
				Builders.Ripple(actionButton, input.Position)
			end
		end))
		actionButton.MouseEnter:Connect(function()
			Tween(actionButton, { BackgroundTransparency = 0.12 }, 0.15)
		end)
		actionButton.MouseLeave:Connect(function()
			Tween(actionButton, { BackgroundTransparency = 0 }, 0.15)
		end)
		actionButton.MouseButton1Click:Connect(function()
			Builders.Press(actionScale)
			running = not running
			refreshAction()
			Utility.SafeCall(options.ActionCallback, running, getTiles(), mode)
		end)
	end

	local clearButton = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		Text = options.ClearText or "Clear selection",
		LayoutOrder = 4,
		Parent = holder,
	})
	Theme.Bind(clearButton, { TextColor3 = "SubText" })
	clearButton.MouseEnter:Connect(function()
		Tween(clearButton, { TextColor3 = State.Theme.Text }, 0.12)
	end)
	clearButton.MouseLeave:Connect(function()
		Tween(clearButton, { TextColor3 = State.Theme.SubText }, 0.12)
	end)

	---------------------------------------------------------------- API
	grid.Instance = holder
	grid.TitleLabel = title
	grid.Value = getTiles()

	function grid:Get()
		return getTiles()
	end

	function grid:Set(tiles, silent)
		selected = {}
		for _, offset in ipairs(tiles or {}) do
			if not (offset.X == 0 and offset.Y == 0) and math.abs(offset.X) <= radius and math.abs(offset.Y) <= radius then
				selected[key(offset.X, offset.Y)] = offset
			end
		end
		for y = -radius, radius do
			for x = -radius, radius do
				paintCell(x, y)
			end
		end
		grid.Value = getTiles()
		if not silent then
			changed()
		end
	end

	function grid:Clear()
		grid:Set({})
	end

	function grid:GetMode()
		return mode
	end

	function grid:SetMode(newMode)
		mode = newMode
		if modeChip then
			modeChip.Text = mode
		end
		refreshAction()
		Utility.SafeCall(options.ModeCallback, mode)
	end

	function grid:IsRunning()
		return running
	end

	function grid:SetRunning(state)
		running = state and true or false
		refreshAction()
	end

	function grid:SetTitle(text)
		title.Text = text
	end

	function grid:SetVisible(visible)
		holder.Visible = visible
	end

	function grid:Destroy()
		holder:Destroy()
	end

	clearButton.MouseButton1Click:Connect(function()
		grid:Clear()
	end)

	if modeChip then
		modeChip.MouseButton1Click:Connect(function()
			local index = table.find(modes, mode) or 0
			grid:SetMode(modes[index % #modes + 1])
		end)
	end

	Theme.OnChange(function()
		for y = -radius, radius do
			for x = -radius, radius do
				paintCell(x, y, true)
			end
		end
	end)

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	refreshAction()
	for y = -radius, radius do
		for x = -radius, radius do
			paintCell(x, y, true)
		end
	end
	Element.RegisterFlag(options, grid)
	return grid
end
