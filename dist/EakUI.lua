--[[
	EakUI v1.4.0
	Built 2026-11-22 06:25 UTC from 36 modules — do not edit by hand.
	Source: src/  |  Build: python tools/build.py
]]

local __modules = {}
local __cache = {}

local function import(name)
	local cached = __cache[name]
	if cached ~= nil then
		return cached
	end
	local loader = __modules[name]
	if not loader then
		error("[EakUI] module not found: " .. tostring(name), 2)
	end
	local result = loader(import)
	if result == nil then
		result = true
	end
	__cache[name] = result
	return result
end

__modules["Components/Button"] = function(...)
--[[
	Components/Button

	Tab:Button({
		Title    = "Click Me",
		Desc     = "optional",
		Color    = Color3.fromRGB(190, 40, 60), -- optional custom background
		Callback = function() end,
	})
]]

local import = ...
local Utility = import("Core/Utility")
local Builders = import("Core/Builders")
local Element = import("Components/Element")

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Button = true,
		Hover = true,
		RightSize = UDim.new(0, 20),
	})
	local holder = element.Instance

	local arrow = Builders.Chevron(holder, "right", options.Color and "Text" or "SubText")
	arrow.Holder.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Holder.Position = UDim2.new(1, -14, 0.5, 0)

	Utility.Track(holder.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			Builders.Ripple(holder, input.Position)
		end
	end))

	holder.MouseButton1Click:Connect(function()
		Builders.Press(element.Scale)
		Utility.SafeCall(options.Callback)
	end)

	function element:Fire()
		Utility.SafeCall(options.Callback)
	end

	function element:SetCallback(callback)
		options.Callback = callback
	end

	return element
end
end

__modules["Components/Divider"] = function(...)
--[[
	Components/Divider
	Thin horizontal separator between groups of elements.

	Tab:Divider()
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")

local Create = Utility.Create

return function(tab)
	local holder = Create("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, 9),
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	})

	local line = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.new(1, -8, 0, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Theme.Bind(line, { BackgroundColor3 = "Stroke" })

	if tab._sections then
		table.insert(tab._sections, holder)
	end

	local divider = { Instance = holder }

	function divider:Destroy()
		holder:Destroy()
	end

	return divider
end
end

__modules["Components/Dropdown"] = function(...)
--[[
	Components/Dropdown

	local dropdown = Tab:Dropdown({
		Title         = "Weapon",
		Values        = { "Sword", "Bow" },
		Value         = "Sword",        -- table when Multi = true
		Multi         = false,
		MaxVisible    = 5,              -- rows visible before scrolling
		Search        = nil,            -- true/false; auto-on for lists longer than 8
		Placeholder   = "Select...",
		CloseOnSelect = true,
		Flag          = "Weapon",
		Callback      = function(value) end,
	})
	dropdown:Set(v) / :Get() / :Refresh(newValues, keepValue) / :Open() / :Close()
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local HEADER_HEIGHT = 42
local OPTION_HEIGHT = 28
local OPTION_GAP = 2
local SEARCH_HEIGHT = 26
local SEARCH_THRESHOLD = 8 -- lists longer than this get a search box

return function(tab, options)
	options = options or {}
	local values = options.Values or options.Options or {}
	local multi = options.Multi or false
	local maxVisible = options.MaxVisible or 5

	local element = Element.new(tab, options, {
		Height = HEADER_HEIGHT,
		Auto = false,
		Clip = true,
		RightSize = UDim.new(0.45, 0),
	})
	local holder = element.Instance
	element.TextHolder.Size = UDim2.new(0.55, -(element.TextHolder.Position.X.Offset + 12), 0, HEADER_HEIGHT)
	element.DescLabel.Visible = false

	local initial = options.Value or options.Default
	if multi then
		element.Value = type(initial) == "table" and initial or {}
	else
		element.Value = initial
	end

	-- Header ---------------------------------------------------------------
	local header = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
		Parent = holder,
	})

	local display = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, HEADER_HEIGHT / 2),
		Size = UDim2.new(0.45, 0, 0, 28),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(display, { BackgroundColor3 = "Field" })
	local displayStroke = Builders.Stroke()
	displayStroke.Parent = display

	local displayLabel = Builders.Label({
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -34, 1, 0),
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = display,
	})

	local chevron = Builders.Chevron(display, "down", "SubText")
	chevron.Holder.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Holder.Position = UDim2.new(1, -8, 0.5, 0)

	-- Search (auto-enabled for long lists) --------------------------------
	local searchFrame = Create("Frame", {
		Position = UDim2.fromOffset(8, HEADER_HEIGHT),
		Size = UDim2.new(1, -16, 0, SEARCH_HEIGHT),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Visible = false,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(searchFrame, { BackgroundColor3 = "Field" })
	Builders.Stroke().Parent = searchFrame

	local searchBox = Create("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		PlaceholderText = "Search...",
		Text = "",
		Parent = searchFrame,
	})
	Theme.Bind(searchBox, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	-- Option list ----------------------------------------------------------
	local list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(8, HEADER_HEIGHT),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = holder,
	}, { Utility.List(OPTION_GAP), Utility.Padding(0, 0, 0, 4) })
	Theme.Bind(list, { ScrollBarImageColor3 = "Accent" })

	local opened = false
	local optionRows = {} -- [value] = { Instance, Label, Marker }

	local function isSelected(value)
		if multi then
			return table.find(element.Value, value) ~= nil
		end
		return element.Value == value
	end

	local function updateDisplay()
		if multi then
			displayLabel.Text = #element.Value > 0 and table.concat(element.Value, ", ")
				or (options.Placeholder or "None")
		else
			displayLabel.Text = element.Value ~= nil and tostring(element.Value) or (options.Placeholder or "Select...")
		end

		local theme = State.Theme
		for value, row in pairs(optionRows) do
			local selected = isSelected(value)
			Tween(row.Instance, { BackgroundTransparency = selected and 0.82 or 1 }, 0.15)
			Tween(row.Label, { TextColor3 = selected and theme.Text or theme.SubText }, 0.15)
			Tween(row.Marker, { BackgroundTransparency = selected and 0 or 1 }, 0.15)
		end
	end

	local function isSearchable()
		if options.Search ~= nil then
			return options.Search == true
		end
		return #values > SEARCH_THRESHOLD
	end

	local function searchOffset()
		return isSearchable() and (SEARCH_HEIGHT + 4) or 0
	end

	local function visibleCount()
		local count = 0
		for _, row in pairs(optionRows) do
			if row.Instance.Visible then
				count += 1
			end
		end
		return count
	end

	local function listHeight()
		return math.min(visibleCount(), maxVisible) * (OPTION_HEIGHT + OPTION_GAP)
	end

	local function applyFilter()
		local query = string.lower(searchBox.Text)
		for value, row in pairs(optionRows) do
			row.Instance.Visible = query == "" or string.find(string.lower(tostring(value)), query, 1, true) ~= nil
		end
	end

	local function setOpen(state)
		opened = state
		local height = listHeight()
		local offset = searchOffset()
		list.Position = UDim2.fromOffset(8, HEADER_HEIGHT + offset)
		list.Size = UDim2.new(1, -16, 0, height)
		local openHeight = HEADER_HEIGHT + offset + height + 8
		Tween(holder, { Size = UDim2.new(1, 0, 0, opened and openHeight or HEADER_HEIGHT) }, 0.3)
		chevron:Set(opened and "up" or "down")
		Tween(displayStroke, {
			Color = opened and State.Theme.Accent or State.Theme.Stroke,
			Transparency = opened and 0.3 or State.Theme.StrokeAlpha,
		}, 0.2)
	end

	local function choose(value)
		if multi then
			local index = table.find(element.Value, value)
			if index then
				table.remove(element.Value, index)
			else
				table.insert(element.Value, value)
			end
		else
			element.Value = value
			if options.CloseOnSelect ~= false then
				setOpen(false)
			end
		end
		updateDisplay()
		Utility.SafeCall(options.Callback, element.Value)
	end

	local function createRow(index, value)
		local row = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			Parent = list,
		}, { Utility.Corner(6) })
		Theme.Bind(row, { BackgroundColor3 = "Accent" })

		local marker = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(4, 14),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = row,
		}, { Utility.Corner(2) })
		Theme.Bind(marker, { BackgroundColor3 = "Accent" })

		local label = Builders.Label({
			Text = tostring(value),
			Position = UDim2.fromOffset(20, 0),
			Size = UDim2.new(1, -28, 1, 0),
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})

		row.MouseEnter:Connect(function()
			if not isSelected(value) then
				Tween(row, { BackgroundTransparency = 0.93 }, 0.12)
			end
		end)
		row.MouseLeave:Connect(function()
			if not isSelected(value) then
				Tween(row, { BackgroundTransparency = 1 }, 0.12)
			end
		end)
		row.MouseButton1Click:Connect(function()
			choose(value)
		end)

		optionRows[value] = { Instance = row, Label = label, Marker = marker }
	end

	local function build()
		for _, row in pairs(optionRows) do
			row.Instance:Destroy()
		end
		table.clear(optionRows)

		for index, value in ipairs(values) do
			createRow(index, value)
		end

		searchFrame.Visible = isSearchable()
		applyFilter()
		updateDisplay()
		if opened then
			setOpen(true)
		end
	end

	-- Events ---------------------------------------------------------------
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		applyFilter()
		if opened then
			setOpen(true)
		end
	end)

	header.MouseButton1Click:Connect(function()
		setOpen(not opened)
	end)
	header.MouseEnter:Connect(function()
		Tween(holder, { BackgroundColor3 = State.Theme.ElementHover }, 0.18)
	end)
	header.MouseLeave:Connect(function()
		Tween(holder, { BackgroundColor3 = State.Theme.Element }, 0.18)
	end)

	-- API ------------------------------------------------------------------
	function element:Set(value, silent)
		if multi then
			element.Value = type(value) == "table" and value or { value }
		else
			element.Value = value
		end
		updateDisplay()
		if not silent then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:Refresh(newValues, keepValue)
		values = newValues or {}
		if not keepValue then
			element.Value = multi and {} or nil
		end
		build()
	end

	function element:Open()
		setOpen(true)
	end

	function element:Close()
		setOpen(false)
	end

	Theme.OnChange(updateDisplay)
	build()
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Element"] = function(...)
--[[
	Components/Element
	Shared base for every tab element: rounded glass card, stroke,
	title + optional description, hover state and common methods.

	Element.new(tab, options, config) -> element
	config:
		Button    : boolean  -- use a TextButton (clickable card)
		Hover     : boolean  -- hover highlight
		Height    : number   -- minimum height (default 42)
		Auto      : boolean  -- grow with text (default true)
		Clip      : boolean  -- ClipsDescendants
		RightSize : UDim     -- width reserved for the control on the right
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local Element = {}

function Element.new(tab, options, config)
	config = config or {}
	local rightSize = config.RightSize or UDim.new(0, 0)
	local height = config.Height or 42
	local autoSize = config.Auto ~= false and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
	local customColor = options.Color

	local holder = Create(config.Button and "TextButton" or "Frame", {
		Name = options.Title or "Element",
		Size = UDim2.new(1, 0, 0, height),
		AutomaticSize = autoSize,
		BackgroundTransparency = customColor and 0.1 or Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = config.Clip or config.Button or false,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(8) })

	if config.Button then
		holder.Text = ""
		holder.AutoButtonColor = false
	end

	if customColor then
		holder.BackgroundColor3 = customColor
	else
		Theme.Bind(holder, { BackgroundColor3 = "Element" })
	end

	local stroke = Builders.Stroke()
	stroke.Parent = holder
	local scale = Create("UIScale", { Parent = holder })

	-- Optional left icon: Icon is tinted to match text, Image keeps its colors
	local iconSource = options.Icon or options.Image
	local textX = 12
	local iconLabel
	if iconSource then
		local iconSize = options.IconSize or (options.Image and 32 or 18)
		iconLabel = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = holder,
		}, { Utility.Corner(options.Image and 6 or 0) })
		Assets.Apply(iconLabel, iconSource)
		if options.Icon and options.IconTint ~= false then
			Theme.Bind(iconLabel, { ImageColor3 = "SubText" })
		end
		textX = 12 + iconSize + 10
	end

	local textHolder = Create("Frame", {
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1 - rightSize.Scale, -(textX + 12 + rightSize.Offset), 0, height),
		AutomaticSize = autoSize,
		BackgroundTransparency = 1,
		Parent = holder,
	}, {
		Utility.List(3, nil, nil, Enum.VerticalAlignment.Center),
		Utility.Padding(10, 10, 0, 0),
	})

	local description = options.Desc or options.Description

	local title = Builders.Label({
		Text = options.Title or "Element",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = 1,
		Parent = textHolder,
	})

	local desc = Builders.Label({
		Text = description or "",
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		RichText = true,
		Visible = description ~= nil,
		LayoutOrder = 2,
		Parent = textHolder,
	})

	if config.Hover then
		holder.MouseEnter:Connect(function()
			local target = customColor and customColor:Lerp(Color3.new(1, 1, 1), 0.1) or State.Theme.ElementHover
			Tween(holder, { BackgroundColor3 = target }, 0.18)
			Tween(stroke, { Transparency = State.Theme.StrokeAlpha - 0.08 }, 0.18)
		end)
		holder.MouseLeave:Connect(function()
			Tween(holder, { BackgroundColor3 = customColor or State.Theme.Element }, 0.18)
			Tween(stroke, { Transparency = State.Theme.StrokeAlpha }, 0.18)
		end)
	end

	-- Make the element discoverable by the sidebar search
	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	local element = {
		Instance = holder,
		TitleLabel = title,
		DescLabel = desc,
		TextHolder = textHolder,
		IconLabel = iconLabel,
		Stroke = stroke,
		Scale = scale,
	}

	function element:SetTitle(text)
		title.Text = text
	end

	function element:SetDesc(text)
		desc.Text = text or ""
		desc.Visible = text ~= nil and text ~= ""
	end

	function element:SetIcon(source)
		if iconLabel then
			Assets.Apply(iconLabel, source)
		end
	end

	function element:SetVisible(visible)
		holder.Visible = visible
	end

	function element:Destroy()
		holder:Destroy()
	end

	return element
end

-- Exposes an element through UI.Flags[options.Flag]
function Element.RegisterFlag(options, element)
	if options.Flag then
		State.Flags[options.Flag] = element
	end
end

return Element
end

__modules["Components/Grid"] = function(...)
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
end

__modules["Components/Input"] = function(...)
--[[
	Components/Input

	local input = Tab:Input({
		Title        = "Player Name",
		Placeholder  = "Enter username...",
		Default      = "",
		Numeric      = false, -- strip non-numeric characters
		MaxLength    = nil,
		Live         = false, -- true: callback on every change, false: on focus lost
		ClearOnFocus = false,
		Flag         = "PlayerName",
		Callback     = function(text, enterPressed) end,
	})
	input:Set("text") / input:Get() / input:SetPlaceholder("...")
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Hover = true,
		RightSize = UDim.new(0.42, 0),
	})
	local holder = element.Instance

	local field = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.42, 0, 0, 28),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(field, { BackgroundColor3 = "Field" })
	local fieldStroke = Builders.Stroke()
	fieldStroke.Parent = field

	local box = Create("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = options.ClearOnFocus or false,
		PlaceholderText = options.Placeholder or "Type here...",
		Text = tostring(options.Default or options.Value or ""),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = field,
	})
	Theme.Bind(box, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	local function sanitize(text)
		if options.Numeric then
			text = text:gsub("[^%d%.%-]", "")
		end
		if options.MaxLength and #text > options.MaxLength then
			text = text:sub(1, options.MaxLength)
		end
		return text
	end

	element.Value = box.Text

	box:GetPropertyChangedSignal("Text"):Connect(function()
		local clean = sanitize(box.Text)
		if clean ~= box.Text then
			box.Text = clean -- re-fires this handler with the clean value
			return
		end
		element.Value = clean
		if options.Live then
			Utility.SafeCall(options.Callback, clean)
		end
	end)

	box.Focused:Connect(function()
		Tween(fieldStroke, { Color = State.Theme.Accent, Transparency = 0.2 }, 0.18)
	end)

	box.FocusLost:Connect(function(enterPressed)
		Tween(fieldStroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.18)
		if not options.Live then
			Utility.SafeCall(options.Callback, element.Value, enterPressed)
		end
	end)

	function element:Set(text, silent)
		box.Text = sanitize(tostring(text or ""))
		element.Value = box.Text
		if not silent and not options.Live then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:SetPlaceholder(text)
		box.PlaceholderText = text
	end

	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Keybind"] = function(...)
--[[
	Components/Keybind
	Click the key chip, press any key to rebind. Escape / Backspace clears it.

	local bind = Tab:Keybind({
		Title           = "Fly",
		Value           = Enum.KeyCode.F,       -- or nil
		Flag            = "FlyKey",
		Callback        = function(key) end,    -- fired when the key is pressed
		ChangedCallback = function(key) end,    -- fired after rebinding
	})
	bind:Set(Enum.KeyCode.G) / bind:Get()
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

local CLEAR_KEYS = {
	[Enum.KeyCode.Escape] = true,
	[Enum.KeyCode.Backspace] = true,
}

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Hover = true,
		RightSize = UDim.new(0, 96),
	})
	local holder = element.Instance
	element.Value = options.Value or options.Default

	local chip = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Text = "",
		Parent = holder,
	}, { Utility.Corner(6), Utility.Padding(0, 0, 10, 10) })
	Theme.Bind(chip, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	local chipStroke = Builders.Stroke()
	chipStroke.Parent = chip

	local listening = false

	local function render()
		if listening then
			chip.Text = "Press a key..."
		else
			chip.Text = element.Value and element.Value.Name or "None"
		end
		Tween(chipStroke, {
			Color = listening and State.Theme.Accent or State.Theme.Stroke,
			Transparency = listening and 0.2 or State.Theme.StrokeAlpha,
		}, 0.15)
	end

	function element:Set(keyCode, silent)
		element.Value = keyCode
		listening = false
		render()
		if not silent then
			Utility.SafeCall(options.ChangedCallback, keyCode)
		end
	end

	function element:Get()
		return element.Value
	end

	chip.MouseButton1Click:Connect(function()
		listening = true
		render()
	end)

	Utility.Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local key = input.KeyCode
				element:Set(not CLEAR_KEYS[key] and key or nil)
			end
			return
		end

		if not gameProcessed and element.Value and input.KeyCode == element.Value then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end))

	render()
	Theme.OnChange(render)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Notification"] = function(...)
--[[
	Components/Notification
	Toast stack in the bottom-right corner with auto-dismiss.

	UI:Notify({
		Title    = "Done",
		Content  = "Something happened",
		Type     = "Info" | "Success" | "Warning" | "Error",
		Icon     = "rbxassetid://...", -- optional
		Duration = 5,
		Callback = function() end,     -- fired on close
	}) -> { Close = function }
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Gui = import("Core/Gui")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local WIDTH = 290
local MARGIN = 16
local Z = 100

local order = 0

local function getHolder()
	if State.NotifyHolder and State.NotifyHolder.Parent then
		return State.NotifyHolder
	end

	State.NotifyHolder = Create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -MARGIN, 1, -MARGIN),
		Size = UDim2.new(0, WIDTH, 1, -MARGIN * 2),
		BackgroundTransparency = 1,
		ZIndex = Z,
		Parent = Gui.Get(),
	}, {
		Utility.List(8, nil, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom),
	})
	return State.NotifyHolder
end

local function buildCloseButton(card)
	local button = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = Z + 2,
		Parent = card,
	}, { Utility.Corner(6) })
	Theme.Bind(button, { BackgroundColor3 = "ElementHover" })
	Builders.CrossIcon(button, 10, "SubText", Z + 3)

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = 0.3 }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = 1 }, 0.15)
	end)
	return button
end

return function(config)
	Theme.Ensure()
	config = config or {}

	local duration = config.Duration or 5
	local color = Constants.NotifyColors[config.Type or ""] or State.Theme.Accent
	local content = config.Content or config.Desc
	order += 1

	local outer = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		ZIndex = Z,
		Parent = getHolder(),
	})

	local card = Create("Frame", {
		Position = UDim2.new(1, 30, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = Z,
		Parent = outer,
	}, { Utility.Corner(10) })
	Theme.Bind(card, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.86).Parent = card

	-- Accent bar
	Create("Frame", {
		Position = UDim2.new(0, 8, 0, 10),
		Size = UDim2.new(0, 3, 1, -20),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = Z + 1,
		Parent = card,
	}, { Utility.Corner(2) })

	local body = Create("Frame", {
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -52, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = Z + 1,
		Parent = card,
	}, { Utility.List(3), Utility.Padding(11, 13, 0, 0) })

	local titleRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = Z + 1,
		Parent = body,
	}, { Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	if config.Icon then
		local icon = Create("ImageLabel", {
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ImageColor3 = config.IconTint == false and Color3.new(1, 1, 1) or color,
			ZIndex = Z + 1,
			Parent = titleRow,
		})
		Assets.Apply(icon, config.Icon)
	end

	Builders.Label({
		Text = config.Title or "Notification",
		Font = Constants.Fonts.Bold,
		TextSize = 13,
		Size = UDim2.new(1, config.Icon and -22 or 0, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		ZIndex = Z + 1,
		Parent = titleRow,
	})

	if content then
		Builders.Label({
			Text = content,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 3,
			ZIndex = Z + 1,
			Parent = body,
		})
	end

	local closeButton = buildCloseButton(card)

	local progress = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = Z + 2,
		Parent = card,
	})

	Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.45)
	Tween(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

	local notification = {}
	local closed = false

	function notification:Close()
		if closed then
			return
		end
		closed = true

		task.spawn(function()
			Tween(card, { Position = UDim2.new(1, 30, 0, 0) }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.wait(0.3)
			if not outer.Parent then
				return
			end
			-- collapse the slot so the stack slides down smoothly
			outer.AutomaticSize = Enum.AutomaticSize.None
			outer.Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y)
			Tween(outer, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
			task.wait(0.22)
			outer:Destroy()
		end)

		Utility.SafeCall(config.Callback)
	end

	closeButton.MouseButton1Click:Connect(function()
		notification:Close()
	end)
	task.delay(duration, function()
		notification:Close()
	end)

	return notification
end
end

__modules["Components/Paragraph"] = function(...)
--[[
	Components/Paragraph

	local paragraph = Tab:Paragraph({ Title = "About", Desc = "Some text" })
	paragraph:Set({ Title = "New", Desc = "Updated" })
]]

local import = ...
local Constants = import("Core/Constants")
local Element = import("Components/Element")

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options)
	element.TitleLabel.Font = Constants.Fonts.Bold

	local content = options.Desc or options.Content
	if content then
		element:SetDesc(content)
	end

	function element:Set(newOptions)
		if newOptions.Title then
			element:SetTitle(newOptions.Title)
		end
		local text = newOptions.Desc or newOptions.Content
		if text then
			element:SetDesc(text)
		end
	end

	return element
end
end

__modules["Components/Section"] = function(...)
--[[
	Components/Section
	Small uppercase heading that groups elements.

	Tab:Section("Player")  or  Tab:Section({ Title = "Player" })
]]

local import = ...
local Utility = import("Core/Utility")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

return function(tab, options)
	if type(options) == "string" then
		options = { Title = options }
	end
	options = options or {}

	local label = Builders.Label({
		Text = string.upper(options.Title or "Section"),
		Font = Constants.Fonts.Bold,
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 26),
		TextYAlignment = Enum.TextYAlignment.Bottom,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	})
	Utility.Padding(0, 2, 4, 0).Parent = label

	-- Headings are hidden while a search filter is active
	if tab._sections then
		table.insert(tab._sections, label)
	end

	local section = { Instance = label }

	function section:SetTitle(text)
		label.Text = string.upper(text)
	end

	function section:Destroy()
		label:Destroy()
	end

	return section
end
end

__modules["Components/Slider"] = function(...)
--[[
	Components/Slider

	local slider = Tab:Slider({
		Title    = "Speed",
		Min      = 1,
		Max      = 100,
		Default  = 50,
		Step     = 1,        -- supports decimals, e.g. 0.05
		Suffix   = " studs", -- optional
		Flag     = "Speed",
		Callback = function(value) end,
	})
	slider:Set(75) / slider:Get() / slider:SetMinMax(0, 200)
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

local KNOB_SIZE = UDim2.fromOffset(14, 14)
local KNOB_SIZE_ACTIVE = UDim2.fromOffset(18, 18)

return function(tab, options)
	options = options or {}
	local min = options.Min or 0
	local max = options.Max or 100
	local step = options.Step or options.Increment or 1
	local suffix = options.Suffix or ""
	local decimals = #(tostring(step):match("%.(%d+)$") or "")
	local numberFormat = "%." .. decimals .. "f"

	local element = Element.new(tab, options, {
		Hover = true,
		Height = 58,
		Auto = false,
		RightSize = UDim.new(0, 70),
	})
	local holder = element.Instance

	-- Compact header layout: title top-left, value box top-right
	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 84), 0, 36)
	if element.IconLabel then -- align icon with the title row, not the whole card
		element.IconLabel.AnchorPoint = Vector2.new(0, 0)
		element.IconLabel.Position = UDim2.fromOffset(12, 9)
	end
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingTop = UDim.new(0, 8)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingBottom = UDim.new(0, 0)
	element.TextHolder:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top
	element.DescLabel.Visible = false

	local valueBox = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(62, 22),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		ClearTextOnFocus = false,
		Text = "",
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(valueBox, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	local boxStroke = Builders.Stroke()
	boxStroke.Parent = valueBox

	local track = Create("Frame", {
		Position = UDim2.new(0, 12, 1, -16),
		Size = UDim2.new(1, -24, 0, 6),
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(999) })
	Theme.Bind(track, { BackgroundColor3 = "ToggleOff" })

	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		Utility.Corner(999),
		Create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(200, 200, 200), Color3.new(1, 1, 1)) }),
	})
	Theme.Bind(fill, { BackgroundColor3 = "Accent" })

	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = KNOB_SIZE,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = track,
	}, { Utility.Corner(999) })
	Theme.Bind(knob, { BackgroundColor3 = "Knob" })
	local knobStroke = Create("UIStroke", { Thickness = 2, Parent = knob })
	Theme.Bind(knobStroke, { Color = "Accent" })

	-- Larger invisible hit area over the track
	local hitbox = Create("TextButton", {
		Position = UDim2.new(0, 0, 1, -30),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = holder,
	})

	local function round(value)
		local snapped = math.floor((value - min) / step + 0.5) * step + min
		snapped = tonumber(string.format(numberFormat, snapped))
		return math.clamp(snapped, min, max)
	end

	local function render(instant)
		local percent = (max == min) and 0 or (element.Value - min) / (max - min)
		local duration = instant and 0 or 0.12
		Tween(fill, { Size = UDim2.fromScale(percent, 1) }, duration)
		Tween(knob, { Position = UDim2.fromScale(percent, 0.5) }, duration)
		valueBox.Text = string.format(numberFormat, element.Value) .. suffix
	end

	element.Value = round(options.Default or options.Value or min)

	function element:Set(value, silent)
		local new = round(tonumber(value) or element.Value)
		local changed = new ~= element.Value
		element.Value = new
		render(false)
		if changed and not silent then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:SetMinMax(newMin, newMax)
		min, max = newMin, newMax
		element:Set(element.Value, true)
	end

	-- Dragging -------------------------------------------------------------
	local dragging = false

	local function updateFromX(x)
		local percent = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		element:Set(min + percent * (max - min))
	end

	Utility.Track(hitbox.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			dragging = true
			Tween(knob, { Size = KNOB_SIZE_ACTIVE }, 0.15)
			updateFromX(input.Position.X)
		end
	end))

	Utility.Track(UserInputService.InputChanged:Connect(function(input)
		if dragging and Utility.IsMove(input) then
			updateFromX(input.Position.X)
		end
	end))

	Utility.Track(UserInputService.InputEnded:Connect(function(input)
		if dragging and Utility.IsClick(input) then
			dragging = false
			Tween(knob, { Size = KNOB_SIZE }, 0.2, Enum.EasingStyle.Back)
		end
	end))

	-- Manual entry ---------------------------------------------------------
	valueBox.Focused:Connect(function()
		Tween(boxStroke, { Transparency = 0.4 }, 0.15)
		valueBox.Text = string.format(numberFormat, element.Value)
	end)

	valueBox.FocusLost:Connect(function()
		Tween(boxStroke, { Transparency = State.Theme.StrokeAlpha }, 0.15)
		local number = tonumber((valueBox.Text:gsub("[^%d%.%-]", "")))
		if number then
			element:Set(number)
		end
		render(false)
	end)

	render(true)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Toggle"] = function(...)
--[[
	Components/Toggle

	local toggle = Tab:Toggle({
		Title      = "Enable",
		Desc       = "optional",
		Value      = false,
		Flag       = "Enabled",      -- optional, exposes UI.Flags.Enabled
		FireOnLoad = false,
		Callback   = function(value) end,
	})
	toggle:Set(true) / toggle:Get() / toggle:Toggle()
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local KNOB_OFF = UDim2.new(0, 3, 0.5, 0)
local KNOB_ON = UDim2.new(1, -19, 0.5, 0)

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Button = true,
		Hover = true,
		RightSize = UDim.new(0, 44),
	})
	local holder = element.Instance

	if options.Value ~= nil then
		element.Value = options.Value == true
	else
		element.Value = options.Default == true
	end

	local switch = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(40, 22),
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(999) })

	local switchStroke = Builders.Stroke(0.85)
	switchStroke.Parent = switch

	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = KNOB_OFF,
		Size = UDim2.fromOffset(16, 16),
		BorderSizePixel = 0,
		Parent = switch,
	}, { Utility.Corner(999) })
	Theme.Bind(knob, { BackgroundColor3 = "Knob" })

	local function render(instant)
		local duration = instant and 0 or 0.28
		local on = element.Value
		local theme = State.Theme

		Tween(switch, { BackgroundColor3 = on and theme.Accent or theme.ToggleOff }, duration)
		Tween(switchStroke, { Transparency = on and 1 or 0.85 }, duration)
		Tween(knob, { Position = on and KNOB_ON or KNOB_OFF }, duration, Enum.EasingStyle.Back)

		if not instant then -- squish while moving
			Tween(knob, { Size = UDim2.fromOffset(20, 16) }, 0.1)
			task.delay(0.12, function()
				Tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.18)
			end)
		end
	end

	function element:Set(value, silent)
		element.Value = value and true or false
		render(false)
		if not silent then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:Toggle()
		element:Set(not element.Value)
	end

	holder.MouseButton1Click:Connect(function()
		Builders.Press(element.Scale)
		element:Set(not element.Value)
	end)

	render(true)
	Theme.OnChange(function()
		render(true)
	end)
	Element.RegisterFlag(options, element)

	if element.Value and options.FireOnLoad then
		Utility.SafeCall(options.Callback, element.Value)
	end
	return element
end
end

__modules["Core/Assets"] = function(...)
--[[
	Core/Assets
	Resolves any image source to something an ImageLabel can display.

	Accepted sources:
		123456 / "123456"                 -> rbxassetid://123456
		"rbxassetid://..." "rbxasset://..." "rbxthumb://..."  (used as-is)
		"https://example.com/logo.png"    -> downloaded once, cached to
		                                     workspace/EakUI/assets/, loaded with getcustomasset
		"EakUI/my_logo.png"               -> local file in the executor workspace

	URL and file images need an executor with writefile / isfile / getcustomasset.
	Without them a warning is printed and the image stays empty.

	Assets.Apply(imageLabel, source)   -- async-safe, never yields the caller
	Assets.Resolve(source) -> string?  -- may yield while downloading
]]

local Assets = {}

local ROOT = "EakUI"
local FOLDER = ROOT .. "/assets"
local VALID_EXTENSIONS = { png = true, jpg = true, jpeg = true }

local cache = {} -- [source] = resolved asset string
local pending = {} -- [source] = true while downloading

local function getCustomAsset()
	return getcustomasset or getsynasset
end

local function hasFileSystem()
	return writefile ~= nil and isfile ~= nil and getCustomAsset() ~= nil
end

local function ensureFolders()
	if not (isfolder and makefolder) then
		return
	end
	if not isfolder(ROOT) then
		makefolder(ROOT)
	end
	if not isfolder(FOLDER) then
		makefolder(FOLDER)
	end
end

-- djb2 string hash -> stable file name per URL
local function hash(text)
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 4294967296
	end
	return string.format("%08x", h)
end

local function extensionOf(url)
	local ext = string.match(string.lower(url), "%.(%a+)[%?#]") or string.match(string.lower(url), "%.(%a+)$")
	return VALID_EXTENSIONS[ext or ""] and ext or "png"
end

local function download(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end

	local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
	if requestFn then
		local success, response = pcall(requestFn, { Url = url, Method = "GET" })
		if success and response and response.Body and #response.Body > 0 then
			return response.Body
		end
	end
	return nil
end

local function loadFile(path)
	local ok, asset = pcall(getCustomAsset(), path)
	if ok and asset and asset ~= "" then
		return asset
	end
	return nil
end

-- Sources that can be used directly, without yielding
local function resolveInstant(source)
	if source == nil or source == "" then
		return nil, true
	end
	if type(source) == "number" or string.match(source, "^%d+$") then
		return "rbxassetid://" .. source, true
	end
	if string.match(source, "^rbx") then
		return source, true
	end
	if cache[source] then
		return cache[source], true
	end
	return nil, false
end

function Assets.Resolve(source)
	local instant, done = resolveInstant(source)
	if done then
		return instant
	end

	if not hasFileSystem() then
		warn("[EakUI] This executor can't load custom images (needs writefile + getcustomasset): " .. tostring(source))
		return nil
	end

	-- another caller is already downloading this source
	while pending[source] do
		task.wait()
	end
	if cache[source] then
		return cache[source]
	end

	pending[source] = true
	local result

	if string.match(source, "^https?://") then
		ensureFolders()
		local path = FOLDER .. "/" .. hash(source) .. "." .. extensionOf(source)
		if not isfile(path) then
			local body = download(source)
			if body then
				writefile(path, body)
			else
				warn("[EakUI] Failed to download image: " .. source)
			end
		end
		if isfile(path) then
			result = loadFile(path)
		end
	elseif isfile(source) then
		result = loadFile(source)
	else
		warn("[EakUI] Image file not found: " .. source)
	end

	pending[source] = nil
	cache[source] = result
	return result
end

-- Sets instance[property] to the resolved image. URLs are fetched in the background.
function Assets.Apply(instance, source, property)
	property = property or "Image"
	local instant, done = resolveInstant(source)
	if done then
		instance[property] = instant or ""
		return
	end

	task.spawn(function()
		local resolved = Assets.Resolve(source)
		if resolved and instance.Parent then
			instance[property] = resolved
		end
	end)
end

-- Downloads images ahead of time (e.g. call once at script start)
function Assets.Preload(sources)
	for _, source in ipairs(sources) do
		task.spawn(Assets.Resolve, source)
	end
end

return Assets
end

__modules["Core/Builders"] = function(...)
--[[
	Core/Builders
	Themed building blocks shared by components: strokes, labels,
	vector chevrons / close icons and the click ripple.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Constants = import("Core/Constants")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner

local Builders = {}

function Builders.Stroke(transparency, thickness)
	local stroke = Create("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or State.Theme.StrokeAlpha,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	Theme.Bind(stroke, { Color = "Stroke" })
	return stroke
end

-- Label({ Text = "Hi", ThemeColor = "SubText", ... })
function Builders.Label(properties)
	local colorKey = properties.ThemeColor or "Text"
	properties.ThemeColor = nil

	local merged = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Medium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	}
	for key, value in pairs(properties) do
		merged[key] = value
	end

	local label = Create("TextLabel", merged)
	Theme.Bind(label, { TextColor3 = colorKey })
	return label
end

-- Two bars forming a chevron; no image assets required
function Builders.Chevron(parent, direction, colorKey)
	local holder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Parent = parent,
	})

	local function bar()
		local frame = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(8, 2),
			BorderSizePixel = 0,
			Parent = holder,
		}, { Corner(1) })
		Theme.Bind(frame, { BackgroundColor3 = colorKey or "SubText" })
		return frame
	end
	local left, right = bar(), bar()

	local chevron = { Holder = holder }

	function chevron:Set(newDirection, instant)
		local t = instant and 0 or 0.25
		if newDirection == "down" then
			Tween(left, { Position = UDim2.new(0.5, -2.5, 0.5, 0), Rotation = 45 }, t)
			Tween(right, { Position = UDim2.new(0.5, 2.5, 0.5, 0), Rotation = -45 }, t)
		elseif newDirection == "up" then
			Tween(left, { Position = UDim2.new(0.5, -2.5, 0.5, 0), Rotation = -45 }, t)
			Tween(right, { Position = UDim2.new(0.5, 2.5, 0.5, 0), Rotation = 45 }, t)
		else -- "right"
			Tween(left, { Position = UDim2.new(0.5, 0, 0.5, -2.5), Rotation = 45 }, t)
			Tween(right, { Position = UDim2.new(0.5, 0, 0.5, 2.5), Rotation = -45 }, t)
		end
	end

	chevron:Set(direction or "down", true)
	return chevron
end

-- "X" made of two rotated bars
function Builders.CrossIcon(parent, size, colorKey, zIndex)
	for _, rotation in ipairs({ 45, -45 }) do
		local frame = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(size or 12, 2),
			Rotation = rotation,
			BorderSizePixel = 0,
			ZIndex = zIndex or 1,
			Parent = parent,
		}, { Corner(1) })
		Theme.Bind(frame, { BackgroundColor3 = colorKey or "SubText" })
	end
end

function Builders.Ripple(button, screenPosition)
	local relative = Vector2.new(screenPosition.X, screenPosition.Y) - button.AbsolutePosition
	local circle = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(relative.X, relative.Y),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 5,
		Parent = button,
	}, { Corner(999) })

	local diameter = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
	Tween(circle, { Size = UDim2.fromOffset(diameter, diameter), BackgroundTransparency = 1 }, 0.55, Enum.EasingStyle.Quad)
	task.delay(0.6, function()
		circle:Destroy()
	end)
end

-- Small press-down / spring-back animation on a UIScale
function Builders.Press(scale)
	Tween(scale, { Scale = 0.975 }, 0.08, Enum.EasingStyle.Quad)
	task.delay(0.08, function()
		Tween(scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
	end)
end

return Builders
end

__modules["Core/Constants"] = function(...)
--[[
	Core/Constants
	Static values shared across components.
]]

local rgb = Color3.fromRGB

local Constants = {}

-- Background transparency levels for the glass look
Constants.Glass = {
	Main = 0.08,
	Sidebar = 0.35,
	Element = 0.3,
	Field = 0.15,
}

Constants.NotifyColors = {
	Success = rgb(34, 197, 94),
	Warning = rgb(234, 179, 8),
	Error = rgb(239, 68, 68),
}

Constants.Danger = rgb(239, 68, 68)

-- Drop shadow (9-slice)
Constants.Shadow = {
	Image = "rbxassetid://6014261993",
	SliceCenter = Rect.new(49, 49, 450, 450),
}

Constants.Fonts = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Black = Enum.Font.GothamBlack,
}

Constants.Window = {
	TopbarHeight = 46,
	SidebarWidth = 156,
	SearchHeight = 30,
	ProfileHeight = 50,
	DefaultSize = UDim2.fromOffset(560, 400),
	MinSize = Vector2.new(420, 300),
	ToggleKey = Enum.KeyCode.RightShift,
}

return Constants
end

__modules["Core/Draggable"] = function(...)
--[[
	Core/Draggable
	Mouse + touch dragging with a small threshold so clicks still register.

	local state = Draggable(handle, target)
	state.Moved -- true if the last press turned into a drag
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")

local UserInputService = Services.UserInputService
local DRAG_THRESHOLD = 4

return function(handle, target, onMove)
	local state = { Dragging = false, Moved = false }
	local dragStart, startPosition, dragInput

	Utility.Track(handle.InputBegan:Connect(function(input)
		if not Utility.IsClick(input) then
			return
		end
		state.Dragging = true
		state.Moved = false
		dragStart = input.Position
		startPosition = target.Position

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				state.Dragging = false
				connection:Disconnect()
			end
		end)
	end))

	Utility.Track(handle.InputChanged:Connect(function(input)
		if Utility.IsMove(input) then
			dragInput = input
		end
	end))

	Utility.Track(UserInputService.InputChanged:Connect(function(input)
		if not (state.Dragging and input == dragInput) then
			return
		end

		local delta = input.Position - dragStart
		if not state.Moved and Vector2.new(delta.X, delta.Y).Magnitude > DRAG_THRESHOLD then
			state.Moved = true
		end

		if state.Moved then
			local position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
			Utility.Tween(target, { Position = position }, 0.08, Enum.EasingStyle.Sine)
			if onMove then
				onMove(position)
			end
		end
	end))

	return state
end
end

__modules["Core/Gui"] = function(...)
--[[
	Core/Gui
	Creates (once) the protected root ScreenGui all windows live in.
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")

local Gui = {}

local function getEnvironment()
	return (getgenv and getgenv()) or _G
end

-- gethui() > CoreGui > PlayerGui
local function resolveParent()
	local ok, hidden = pcall(function()
		return gethui and gethui()
	end)
	if ok and hidden then
		return hidden
	end

	local probe = Instance.new("ScreenGui")
	local canUseCore = pcall(function()
		probe.Parent = Services.CoreGui
	end)
	probe:Destroy()
	if canUseCore then
		return Services.CoreGui
	end

	return Services.LocalPlayer:WaitForChild("PlayerGui")
end

function Gui.Get()
	if State.Gui and State.Gui.Parent then
		return State.Gui
	end

	-- Remove the UI from a previous execution
	local env = getEnvironment()
	if env.__EakUI_Gui then
		pcall(function()
			env.__EakUI_Gui:Destroy()
		end)
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = Utility.RandomName()
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 9999

	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(screenGui)
		end
	end)
	screenGui.Parent = resolveParent()

	State.Gui = screenGui
	env.__EakUI_Gui = screenGui
	return screenGui
end

function Gui.Destroy()
	if State.Gui then
		State.Gui:Destroy()
	end
	State.Gui = nil
	State.NotifyHolder = nil
end

return Gui
end

__modules["Core/Services"] = function(...)
--[[
	Core/Services
	Cached Roblox services.
]]

local Players = game:GetService("Players")

return {
	Players = Players,
	TweenService = game:GetService("TweenService"),
	UserInputService = game:GetService("UserInputService"),
	HttpService = game:GetService("HttpService"),
	CoreGui = game:GetService("CoreGui"),
	LocalPlayer = Players.LocalPlayer,
}
end

__modules["Core/State"] = function(...)
--[[
	Core/State
	Shared, mutable runtime state used by every module.
	Kept in one place so modules never hold their own copies.
]]

local State = {
	Version = "1.4.0",

	-- Public
	Flags = {},

	-- Theme
	ThemeName = "Dark",
	Theme = nil, -- active theme table (copy of a preset + overrides)
	ThemeObjects = {}, -- { instance, property, themeKey }
	ThemeCallbacks = {}, -- functions re-run on theme change

	-- Runtime
	Gui = nil, -- root ScreenGui
	NotifyHolder = nil,
	Connections = {},
	Windows = {},
}

return State
end

__modules["Core/Theme"] = function(...)
--[[
	Core/Theme
	Theme registry: binds instance properties to theme keys so the whole UI
	can be re-themed live with a tween.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Themes = import("Themes")

local Theme = {}

function Theme.Get()
	return State.Theme
end

-- Theme.Bind(frame, { BackgroundColor3 = "Element" })
function Theme.Bind(instance, map)
	for property, key in pairs(map) do
		instance[property] = State.Theme[key]
		table.insert(State.ThemeObjects, { instance, property, key })
	end
	return instance
end

-- Registers a function re-run after every theme change (for state-driven colors)
function Theme.OnChange(callback)
	table.insert(State.ThemeCallbacks, callback)
	return callback
end

-- Makes sure a theme is active; optionally switches preset / accent
function Theme.Ensure(name, accent)
	if State.Theme and name == nil and accent == nil then
		return State.Theme
	end

	local resolved = (name and Themes[name]) and name or State.ThemeName
	State.ThemeName = resolved
	State.Theme = Utility.CopyTable(Themes[resolved] or Themes.Dark)
	if accent then
		State.Theme.Accent = accent
	end
	return State.Theme
end

local function refresh(filterKey)
	local alive = {}
	for _, entry in ipairs(State.ThemeObjects) do
		local instance, property, key = entry[1], entry[2], entry[3]
		if instance and instance.Parent then
			if not filterKey or key == filterKey then
				Utility.Tween(instance, { [property] = State.Theme[key] }, 0.3)
			end
			table.insert(alive, entry)
		end
	end
	State.ThemeObjects = alive

	for _, callback in ipairs(State.ThemeCallbacks) do
		pcall(callback)
	end
end

function Theme.Set(name, accent)
	if not Themes[name] then
		warn("[EakUI] Unknown theme: " .. tostring(name))
		return
	end
	State.ThemeName = name
	State.Theme = Utility.CopyTable(Themes[name])
	if accent then
		State.Theme.Accent = accent
	end
	refresh()
end

function Theme.SetAccent(color)
	State.Theme.Accent = color
	refresh("Accent")
end

function Theme.Reset()
	table.clear(State.ThemeObjects)
	table.clear(State.ThemeCallbacks)
end

return Theme
end

__modules["Core/Utility"] = function(...)
--[[
	Core/Utility
	Pure helpers: instance creation, tweening, layout objects, input checks.
	Nothing here depends on the active theme.
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")

local TweenService = Services.TweenService

local Utility = {}

function Utility.CopyTable(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

-- Registers a connection so it is cleaned up when the UI is destroyed
function Utility.Track(connection)
	table.insert(State.Connections, connection)
	return connection
end

function Utility.DisconnectAll()
	for _, connection in ipairs(State.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(State.Connections)
end

-- Instance.new with properties and children; Parent is applied last
function Utility.Create(className, properties, children)
	local instance = Instance.new(className)
	local parent

	for key, value in pairs(properties or {}) do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end

	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end

	if parent then
		instance.Parent = parent
	end
	return instance
end

function Utility.Tween(instance, goal, duration, style, direction)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

function Utility.Corner(radius)
	return Utility.Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function Utility.Padding(top, bottom, left, right)
	return Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
	})
end

function Utility.List(padding, direction, horizontal, vertical)
	return Utility.Create("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

-- Runs a user callback in its own thread; errors are logged, never thrown
function Utility.SafeCall(callback, ...)
	if type(callback) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(callback, table.unpack(args, 1, args.n))
		if not ok then
			warn("[EakUI] Callback error: " .. tostring(err))
		end
	end)
end

function Utility.IsClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Utility.IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

function Utility.GetViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

function Utility.RandomName()
	return (Services.HttpService:GenerateGUID(false):gsub("-", ""))
end

return Utility
end

__modules["Themes/Dark"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(124, 92, 255),
	Background = rgb(14, 14, 20),
	Sidebar = rgb(22, 22, 31),
	Element = rgb(28, 28, 39),
	ElementHover = rgb(37, 37, 51),
	Field = rgb(18, 18, 26),
	Stroke = rgb(255, 255, 255),
	Text = rgb(240, 240, 246),
	SubText = rgb(150, 150, 168),
	Placeholder = rgb(128, 128, 146),
	ToggleOff = rgb(52, 52, 68),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.9,
}
end

__modules["Themes/Emerald"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(16, 185, 129),
	Background = rgb(10, 18, 16),
	Sidebar = rgb(16, 27, 24),
	Element = rgb(21, 34, 30),
	ElementHover = rgb(29, 45, 40),
	Field = rgb(13, 22, 19),
	Stroke = rgb(200, 255, 235),
	Text = rgb(236, 250, 245),
	SubText = rgb(140, 170, 160),
	Placeholder = rgb(116, 148, 137),
	ToggleOff = rgb(40, 60, 54),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.9,
}
end

__modules["Themes/Light"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(99, 102, 241),
	Background = rgb(246, 246, 250),
	Sidebar = rgb(234, 234, 242),
	Element = rgb(255, 255, 255),
	ElementHover = rgb(240, 240, 248),
	Field = rgb(240, 240, 246),
	Stroke = rgb(0, 0, 0),
	Text = rgb(22, 22, 30),
	SubText = rgb(100, 100, 118),
	Placeholder = rgb(104, 104, 120),
	ToggleOff = rgb(205, 205, 218),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.88,
}
end

__modules["Themes/Midnight"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(59, 130, 246),
	Background = rgb(10, 14, 26),
	Sidebar = rgb(16, 22, 38),
	Element = rgb(21, 28, 46),
	ElementHover = rgb(29, 38, 60),
	Field = rgb(13, 18, 32),
	Stroke = rgb(170, 200, 255),
	Text = rgb(236, 242, 255),
	SubText = rgb(140, 155, 185),
	Placeholder = rgb(118, 134, 166),
	ToggleOff = rgb(42, 52, 78),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.9,
}
end

__modules["Themes/Rose"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(244, 63, 94),
	Background = rgb(18, 12, 16),
	Sidebar = rgb(28, 19, 25),
	Element = rgb(34, 24, 31),
	ElementHover = rgb(45, 32, 41),
	Field = rgb(22, 15, 20),
	Stroke = rgb(255, 220, 230),
	Text = rgb(250, 238, 242),
	SubText = rgb(175, 145, 158),
	Placeholder = rgb(150, 122, 135),
	ToggleOff = rgb(62, 44, 55),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.9,
}
end

__modules["Themes"] = function(...)
--[[
	Themes
	Registry of theme presets. Add a new theme by creating Themes/<Name>.lua
	with the same keys as Dark.lua and listing it here.
]]

local import = ...

return {
	Dark = import("Themes/Dark"),
	Midnight = import("Themes/Midnight"),
	Rose = import("Themes/Rose"),
	Emerald = import("Themes/Emerald"),
	Light = import("Themes/Light"),
}
end

__modules["Window/Dialog"] = function(...)
--[[
	Window/Dialog
	Modal confirmation dialog shown over the window.

	Window:Dialog({
		Title   = "Close MyHub?",
		Content = "Optional body text",
		Buttons = {
			{ Title = "Cancel" },                                       -- Secondary (default)
			{ Title = "Close", Variant = "Danger", Callback = fn },     -- Primary | Danger | Secondary
		},
	}) -> { Close = function }
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local Z = 30
local WIDTH = 300

local Dialog = {}

local function createButton(parent, spec, order, onClick)
	local variant = spec.Variant or "Secondary"
	local button = Create("TextButton", {
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Constants.Fonts.Medium,
		TextSize = 13,
		Text = spec.Title or "OK",
		LayoutOrder = order,
		ZIndex = Z + 2,
		Parent = parent,
	}, { Utility.Corner(8), Utility.Padding(0, 0, 14, 14) })

	local baseTransparency
	if variant == "Primary" then
		Theme.Bind(button, { BackgroundColor3 = "Accent" })
		button.TextColor3 = Color3.new(1, 1, 1)
		baseTransparency = 0
	elseif variant == "Danger" then
		button.BackgroundColor3 = Constants.Danger
		button.TextColor3 = Color3.new(1, 1, 1)
		baseTransparency = 0
	else
		Theme.Bind(button, { BackgroundColor3 = "Element", TextColor3 = "Text" })
		Builders.Stroke().Parent = button
		baseTransparency = 0.2
	end
	button.BackgroundTransparency = baseTransparency

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = baseTransparency + 0.12 }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = baseTransparency }, 0.15)
	end)
	button.MouseButton1Click:Connect(function()
		onClick(spec)
	end)
end

function Dialog.new(parent, options)
	options = options or {}

	-- Full-size TextButton so clicks never reach the window underneath
	local overlay = Create("TextButton", {
		Name = "Dialog",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = Z,
		Parent = parent,
	}, { Utility.Corner(12) })

	-- TextButton (not Frame) so clicks on the card don't fall through to the backdrop
	local card = Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = Z + 1,
		Parent = overlay,
	}, { Utility.Corner(12), Utility.Padding(18, 16, 18, 18), Utility.List(8) })
	Theme.Bind(card, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.82).Parent = card
	local scale = Create("UIScale", { Scale = 0.92, Parent = card })

	Builders.Label({
		Text = options.Title or "Are you sure?",
		Font = Constants.Fonts.Bold,
		TextSize = 15,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		ZIndex = Z + 2,
		Parent = card,
	})

	if options.Content then
		Builders.Label({
			Text = options.Content,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			ZIndex = Z + 2,
			Parent = card,
		})
	end

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		ZIndex = Z + 1,
		Parent = card,
	}, {
		Utility.List(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom),
	})

	local dialog = {}
	local closed = false

	function dialog:Close()
		if closed then
			return
		end
		closed = true
		Tween(overlay, { BackgroundTransparency = 1 }, 0.18)
		Tween(scale, { Scale = 0.92 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.18, function()
			overlay:Destroy()
		end)
		Utility.SafeCall(options.OnClose)
	end

	local buttons = options.Buttons or { { Title = "OK", Variant = "Primary" } }
	for index, spec in ipairs(buttons) do
		createButton(row, spec, index, function(clicked)
			dialog:Close()
			Utility.SafeCall(clicked.Callback)
		end)
	end

	-- Clicking the dimmed backdrop dismisses the dialog
	overlay.MouseButton1Click:Connect(function()
		if options.Dismissible ~= false then
			dialog:Close()
		end
	end)

	Tween(overlay, { BackgroundTransparency = 0.45 }, 0.2)
	Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)

	dialog.Instance = overlay
	return dialog
end

return Dialog
end

__modules["Window/MiniBar"] = function(...)
--[[
	Window/MiniBar
	Compact pill shown while the window is minimized:
	[ logo ]  brand logo (image) or title text
	Draggable; click to restore the window.

	MiniBar.new(parent, config, onRestore) -> {
		Instance, Show(screenPosition), Hide(), IsVisible()
	}

	config.Logo          square logo (id, rbxassetid, URL or file)
	config.BrandLogo     wordmark image next to the logo (optional)
	config.BrandLogoSize UDim2, default 110x24
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")
local Draggable = import("Core/Draggable")

local Create, Tween = Utility.Create, Utility.Tween

local HEIGHT = 52
local LOGO = 38

local MiniBar = {}

function MiniBar.new(parent, config, onRestore)
	local bar = Create("TextButton", {
		Name = "MiniBar",
		Size = UDim2.fromOffset(0, HEIGHT),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = Constants.Glass.Main,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 40,
		Parent = parent,
	}, {
		Utility.Corner(14),
		Utility.Padding(0, 0, 7, 16),
		Utility.List(10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
	})
	Theme.Bind(bar, { BackgroundColor3 = "Background" })
	local stroke = Builders.Stroke(0.82)
	stroke.Parent = bar
	local scale = Create("UIScale", { Parent = bar })

	-- Logo tile ------------------------------------------------------------
	local tile = Create("Frame", {
		Size = UDim2.fromOffset(LOGO, LOGO),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 1,
		ZIndex = 41,
		Parent = bar,
	}, { Utility.Corner(10) })
	Theme.Bind(tile, { BackgroundColor3 = "Accent" })

	local logoSource = config.Logo or config.Icon
	if logoSource then
		local logo = Create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 42,
			Parent = tile,
		}, { Utility.Corner(10) })
		Assets.Apply(logo, logoSource)
	else
		Builders.Label({
			Text = string.upper(string.sub(config.Title or "E", 1, 1)),
			Font = Constants.Fonts.Black,
			TextSize = 18,
			ThemeColor = "Accent",
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 42,
			Parent = tile,
		})
	end

	-- Brand ----------------------------------------------------------------
	if config.BrandLogo then
		local brand = Create("ImageLabel", {
			Size = config.BrandLogoSize or UDim2.fromOffset(110, 24),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 2,
			ZIndex = 41,
			Parent = bar,
		})
		Assets.Apply(brand, config.BrandLogo)
	else
		local textGroup = Create("Frame", {
			Size = UDim2.fromOffset(0, LOGO),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			ZIndex = 41,
			Parent = bar,
		}, { Utility.List(1, nil, nil, Enum.VerticalAlignment.Center) })

		Builders.Label({
			Text = config.Title or "EakUI",
			Font = Constants.Fonts.Bold,
			TextSize = 14,
			Size = UDim2.fromOffset(0, 17),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 1,
			ZIndex = 41,
			Parent = textGroup,
		})
		if config.Author or config.SubTitle then
			Builders.Label({
				Text = config.Author or config.SubTitle,
				Font = Constants.Fonts.Regular,
				TextSize = 11,
				ThemeColor = "SubText",
				Size = UDim2.fromOffset(0, 13),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = 2,
				ZIndex = 41,
				Parent = textGroup,
			})
		end
	end

	-- Interaction ----------------------------------------------------------
	local drag = Draggable(bar, bar)

	bar.MouseEnter:Connect(function()
		Tween(stroke, { Transparency = 0.6 }, 0.15)
	end)
	bar.MouseLeave:Connect(function()
		Tween(stroke, { Transparency = 0.82 }, 0.15)
	end)
	bar.MouseButton1Click:Connect(function()
		if drag.Moved then
			return
		end
		onRestore()
	end)

	local api = { Instance = bar }

	function api:Show(screenPosition)
		if screenPosition then
			bar.Position = UDim2.fromOffset(screenPosition.X, screenPosition.Y)
		end
		bar.Visible = true
		scale.Scale = 0.85
		Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	end

	function api:Hide()
		Tween(scale, { Scale = 0.85 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.12, function()
			bar.Visible = false
		end)
	end

	function api:IsVisible()
		return bar.Visible
	end

	return api
end

return MiniBar
end

__modules["Window/Profile"] = function(...)
--[[
	Window/Profile
	Sidebar footer with the local player's avatar, display name and username.

	Profile.new(parent, height) -> Frame
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create = Utility.Create
local Players = Services.Players

local Profile = {}

function Profile.new(parent, height)
	local player = Services.LocalPlayer

	local frame = Create("Frame", {
		Name = "Profile",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local divider = Create("Frame", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 0, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = frame,
	})
	Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

	local avatar = Create("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 1),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 0.2,
		Image = "",
		Parent = frame,
	}, { Utility.Corner(999) })
	Theme.Bind(avatar, { BackgroundColor3 = "Element" })
	Builders.Stroke(0.8).Parent = avatar

	local names = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 48, 0.5, 1),
		Size = UDim2.new(1, -56, 0, 30),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { Utility.List(1, nil, nil, Enum.VerticalAlignment.Center) })

	Builders.Label({
		Text = player and player.DisplayName or "Player",
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 14),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = names,
	})

	Builders.Label({
		Text = player and ("@" .. player.Name) or "",
		Font = Constants.Fonts.Regular,
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 13),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		Parent = names,
	})

	if player then
		task.spawn(function()
			local ok, image = pcall(function()
				return Players:GetUserThumbnailAsync(
					player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				)
			end)
			if ok and avatar.Parent then
				avatar.Image = image
			end
		end)
	end

	return frame
end

return Profile
end

__modules["Window/SearchBar"] = function(...)
--[[
	Window/SearchBar
	Sidebar search field that filters elements in the active tab.

	SearchBar.new(parent, height, onChanged) -> { Frame, TextBox }
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local SearchBar = {}

-- Magnifier drawn from a ring + handle (no image asset)
local function magnifier(parent)
	local holder = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 9, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local ring = Create("Frame", {
		Size = UDim2.fromOffset(9, 9),
		BackgroundTransparency = 1,
		Parent = holder,
	}, { Utility.Corner(999) })
	local ringStroke = Create("UIStroke", { Thickness = 1.5, Parent = ring })
	Theme.Bind(ringStroke, { Color = "SubText" })

	local handle = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(5, 2),
		Rotation = 45,
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(1) })
	Theme.Bind(handle, { BackgroundColor3 = "SubText" })
end

function SearchBar.new(parent, height, onChanged)
	local frame = Create("Frame", {
		Name = "Search",
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, height),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Parent = parent,
	}, { Utility.Corner(7) })
	Theme.Bind(frame, { BackgroundColor3 = "Field" })
	local stroke = Builders.Stroke()
	stroke.Parent = frame

	magnifier(frame)

	local box = Create("TextBox", {
		Position = UDim2.fromOffset(27, 0),
		Size = UDim2.new(1, -33, 1, 0),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		PlaceholderText = "Search...",
		Text = "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	Theme.Bind(box, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	box.Focused:Connect(function()
		Tween(stroke, { Color = State.Theme.Accent, Transparency = 0.3 }, 0.18)
	end)
	box.FocusLost:Connect(function()
		Tween(stroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.18)
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		onChanged(box.Text)
	end)

	return { Frame = frame, TextBox = box }
end

return SearchBar
end

__modules["Window/Tab"] = function(...)
--[[
	Window/Tab
	A sidebar entry + its scrollable page. Component methods
	(Button, Toggle, Slider, ...) are attached from Components/.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local Components = {
	Section = import("Components/Section"),
	Button = import("Components/Button"),
	Toggle = import("Components/Toggle"),
	Slider = import("Components/Slider"),
	Input = import("Components/Input"),
	Dropdown = import("Components/Dropdown"),
	Keybind = import("Components/Keybind"),
	Grid = import("Components/Grid"),
	Paragraph = import("Components/Paragraph"),
	Divider = import("Components/Divider"),
}

local Tab = {}
Tab.__index = Tab

-- Tab.new(window, { Title, Icon, Desc }, { List = sidebarList, Content = contentFrame })
function Tab.new(window, options, containers)
	options = options or {}
	local index = #window.Tabs + 1
	local hasIcon = options.Icon ~= nil

	local button = Create("TextButton", {
		Name = options.Title or ("Tab" .. index),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		Parent = containers.List,
	}, { Utility.Corner(8) })
	Theme.Bind(button, { BackgroundColor3 = "Accent" })

	local indicator = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BorderSizePixel = 0,
		Parent = button,
	}, { Utility.Corner(2) })
	Theme.Bind(indicator, { BackgroundColor3 = "Accent" })

	local icon
	if hasIcon then
		icon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(17, 17),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = button,
		})
		Assets.Apply(icon, options.Icon)
	end

	local textX = hasIcon and 37 or 14
	local label = Builders.Label({
		Text = options.Title or ("Tab " .. index),
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1, -(textX + 8), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeColor = "SubText",
		Parent = button,
	})

	local page = Create("ScrollingFrame", {
		Name = (options.Title or "Tab") .. "_Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = containers.Content,
	}, { Utility.List(6), Utility.Padding(8, 12, 0, 10) })
	Theme.Bind(page, { ScrollBarImageColor3 = "Accent" })

	-- Page header: tab title + optional description -----------------------
	local header = Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = page,
	}, { Utility.List(2), Utility.Padding(2, 6, 4, 4) })

	Builders.Label({
		Text = options.Title or ("Tab " .. index),
		Font = Constants.Fonts.Bold,
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 1,
		Parent = header,
	})

	if options.Desc then
		Builders.Label({
			Text = options.Desc,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = header,
		})
	end

	-- Shown when a search has no matches in this tab
	local emptyLabel = Builders.Label({
		Text = "No matching elements",
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 60),
		LayoutOrder = 1e6,
		Visible = false,
		Parent = page,
	})

	local self = setmetatable({
		Title = options.Title,
		Window = window,
		Page = page,
		Button = button,
		Active = false,
		_order = 0,
		_indicator = indicator,
		_label = label,
		_icon = icon,
		_iconTint = options.IconTint ~= false, -- false keeps full-color images (e.g. URL logos)
		_searchables = {},
		_sections = {},
		_empty = emptyLabel,
	}, Tab)

	button.MouseEnter:Connect(function()
		if not self.Active then
			Tween(button, { BackgroundTransparency = 0.94 }, 0.15)
		end
	end)
	button.MouseLeave:Connect(function()
		if not self.Active then
			Tween(button, { BackgroundTransparency = 1 }, 0.15)
		end
	end)
	button.MouseButton1Click:Connect(function()
		window:SelectTab(self)
	end)

	self:_SetActive(false)
	Theme.OnChange(function()
		self:_SetActive(self.Active)
	end)

	return self
end

function Tab:_NextOrder()
	self._order += 1
	return self._order
end

function Tab:_SetActive(active)
	self.Active = active
	local theme = State.Theme

	Tween(self.Button, { BackgroundTransparency = active and 0.86 or 1 }, 0.25)
	Tween(self._indicator, { Size = UDim2.fromOffset(3, active and 16 or 0) }, 0.3, Enum.EasingStyle.Back)
	Tween(self._label, { TextColor3 = active and theme.Text or theme.SubText }, 0.25)
	if self._icon and self._iconTint then
		Tween(self._icon, { ImageColor3 = active and theme.Accent or theme.SubText }, 0.25)
	elseif self._icon then
		Tween(self._icon, { ImageTransparency = active and 0 or 0.35 }, 0.25)
	end
end

function Tab:Select()
	self.Window:SelectTab(self)
end

-- Shows only elements whose title contains `query` (case-insensitive)
function Tab:Filter(query)
	query = string.lower(query or "")
	local searching = query ~= ""
	local matches = 0

	for _, item in ipairs(self._searchables) do
		if item.Instance.Parent then
			local text = string.lower(item.Label.ContentText ~= "" and item.Label.ContentText or item.Label.Text)
			local visible = not searching or string.find(text, query, 1, true) ~= nil
			item.Instance.Visible = visible
			if visible then
				matches += 1
			end
		end
	end

	for _, heading in ipairs(self._sections) do
		if heading.Parent then
			heading.Visible = not searching
		end
	end

	self._empty.Visible = searching and matches == 0
end

-- Attach component constructors as methods: Tab:Button(options), ...
for name, build in pairs(Components) do
	Tab[name] = function(self, options)
		return build(self, options)
	end
end

-- Aliases
Tab.Textbox = Tab.Input
Tab.TextBox = Tab.Input
Tab.Label = Tab.Paragraph

return Tab
end

__modules["Window/ToggleButton"] = function(...)
--[[
	Window/ToggleButton
	Draggable floating button that opens / closes the window.

	ToggleButton.new(parent, config, onClick) -> { Instance, Stroke }
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Draggable = import("Core/Draggable")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local ToggleButton = {}

function ToggleButton.new(parent, config, onClick)
	local button = Create("TextButton", {
		Name = "ToggleButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.ToggleButtonPosition or UDim2.new(0, 44, 0.5, 0),
		Size = UDim2.fromOffset(48, 48),
		BackgroundTransparency = Constants.Glass.Main,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
		Parent = parent,
	}, { Utility.Corner(14) })
	Theme.Bind(button, { BackgroundColor3 = "Background" })

	local stroke = Create("UIStroke", {
		Thickness = 1.5,
		Transparency = 0.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = button,
	})
	Theme.Bind(stroke, { Color = "Accent" })

	local scale = Create("UIScale", { Parent = button })

	-- Priority: ToggleIcon > Logo (full color, fills the button) > Icon (tinted)
	local logo = config.ToggleIcon or config.Logo
	local iconId = logo or config.Icon
	if iconId then
		local image = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = logo and UDim2.new(1, -8, 1, -8) or UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 51,
			Parent = button,
		}, { Utility.Corner(10) })
		Assets.Apply(image, iconId)
		if not logo then
			Theme.Bind(image, { ImageColor3 = "Accent" })
		end
	else
		Builders.Label({
			Name = "Letter",
			Text = string.upper(string.sub(config.Title or "E", 1, 1)),
			Font = Constants.Fonts.Black,
			TextSize = 20,
			ThemeColor = "Accent",
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 51,
			Parent = button,
		})
	end

	local drag = Draggable(button, button)

	button.MouseEnter:Connect(function()
		Tween(scale, { Scale = 1.08 }, 0.2, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		Tween(scale, { Scale = 1 }, 0.2)
	end)
	button.MouseButton1Click:Connect(function()
		if drag.Moved then
			return -- it was a drag, not a click
		end
		Tween(scale, { Scale = 0.9 }, 0.08)
		task.delay(0.08, function()
			Tween(scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
		end)
		onClick()
	end)

	return { Instance = button, Stroke = stroke }
end

return ToggleButton
end

__modules["Window/Topbar"] = function(...)
--[[
	Window/Topbar
	Title row with icon, title, author pill and minimize / close buttons.

	Topbar.new(parent, config) -> {
		Frame, TitleLabel, AuthorLabel, MinimizeButton, CloseButton, Divider
	}
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween
local HEIGHT = Constants.Window.TopbarHeight

local Topbar = {}

local function controlButton(parent, order, hoverColor)
	local button = Create("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = parent,
	}, { Utility.Corner(7) })

	if hoverColor then
		button.BackgroundColor3 = hoverColor
	else
		Theme.Bind(button, { BackgroundColor3 = "ElementHover" })
	end

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = hoverColor and 0.6 or 0.2 }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = 1 }, 0.15)
	end)
	return button
end

function Topbar.new(parent, config)
	local frame = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, HEIGHT),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	-- Left: icon, title, author ------------------------------------------
	local titleGroup = Create("Frame", {
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { Utility.List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	-- Icon (tinted with the accent) or Logo (full-color, never tinted)
	local iconSource = config.Icon or config.Logo
	if iconSource then
		local icon = Create("ImageLabel", {
			Size = UDim2.fromOffset(config.Icon and 20 or 24, config.Icon and 20 or 24),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 1,
			Parent = titleGroup,
		}, { Utility.Corner(6) })
		Assets.Apply(icon, iconSource)
		if config.Icon and config.IconColor ~= false then
			Theme.Bind(icon, { ImageColor3 = "Accent" })
		end
	end

	local titleLabel = Builders.Label({
		Text = config.Title or "EakUI",
		Font = Constants.Fonts.Bold,
		TextSize = 14,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = titleGroup,
	})

	local authorLabel
	local authorText = config.Author or config.SubTitle
	if authorText then
		local pill = Create("Frame", {
			Size = UDim2.new(0, 0, 0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
			LayoutOrder = 3,
			Parent = titleGroup,
		}, { Utility.Corner(999), Utility.Padding(0, 0, 8, 8) })
		Theme.Bind(pill, { BackgroundColor3 = "Accent" })

		authorLabel = Builders.Label({
			Text = authorText,
			TextSize = 11,
			ThemeColor = "SubText",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = pill,
		})
	end

	-- Right: window controls -----------------------------------------------
	local controls = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(70, 28),
		BackgroundTransparency = 1,
		Parent = frame,
	}, {
		Utility.List(4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center),
	})

	local minimizeButton = controlButton(controls, 1)
	local minimizeBar = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 2),
		BorderSizePixel = 0,
		Parent = minimizeButton,
	}, { Utility.Corner(1) })
	Theme.Bind(minimizeBar, { BackgroundColor3 = "SubText" })

	local closeButton = controlButton(controls, 2, Constants.Danger)
	Builders.CrossIcon(closeButton, 12, "SubText")

	local divider = Create("Frame", {
		Position = UDim2.fromOffset(0, HEIGHT),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

	return {
		Frame = frame,
		TitleLabel = titleLabel,
		AuthorLabel = authorLabel,
		MinimizeButton = minimizeButton,
		CloseButton = closeButton,
		Divider = divider,
	}
end

return Topbar
end

__modules["Window"] = function(...)
--[[
	Window
	Main hub window: shadow, glass body, topbar, sidebar, content area,
	drag, resize, minimize, show/hide, keybind and floating toggle button.

	Window.new(config) -> window
	config:
		Title, Author, Icon, IconColor
		Logo (square logo: id / rbxassetid / URL / file) -- topbar, floating button, minimized pill
		BrandLogo, BrandLogoSize                         -- wordmark shown next to the logo when minimized
		Size (UDim2), MinSize (Vector2), SidebarWidth
		Theme, Accent
		ToggleKey (Enum.KeyCode | nil), ToggleButton (bool), ToggleIcon, ToggleButtonPosition
		Search (bool), Profile (bool), ConfirmClose (bool) -- all default true
		OnClose (function)
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Gui = import("Core/Gui")
local Draggable = import("Core/Draggable")
local Notify = import("Components/Notification")
local Tab = import("Window/Tab")
local Topbar = import("Window/Topbar")
local ToggleButton = import("Window/ToggleButton")
local SearchBar = import("Window/SearchBar")
local Profile = import("Window/Profile")
local Dialog = import("Window/Dialog")
local MiniBar = import("Window/MiniBar")

local Create, Tween, Track = Utility.Create, Utility.Tween, Utility.Track
local UserInputService = Services.UserInputService
local Defaults = Constants.Window
local TOPBAR = Defaults.TopbarHeight

local Window = {}

function Window.new(config)
	config = config or {}
	Theme.Ensure(config.Theme or "Dark", config.Accent)

	local screenGui = Gui.Get()
	local sidebarWidth = config.SidebarWidth or Defaults.SidebarWidth
	local minSize = config.MinSize or Defaults.MinSize
	local size = config.Size or Defaults.DefaultSize

	local window = {
		Tabs = {},
		ActiveTab = nil,
		Minimized = false,
		Visible = true,
		Gui = screenGui,
		_query = "",
		_dialog = nil,
		ToggleKey = config.ToggleKey == nil and Defaults.ToggleKey or config.ToggleKey,
	}

	---------------------------------------------------------------- frame
	local root = Create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X.Offset, size.Y.Offset),
		BackgroundTransparency = 1,
		Parent = screenGui,
	})
	local rootScale = Create("UIScale", { Parent = root })

	Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = UDim2.new(1, 60, 1, 60),
		BackgroundTransparency = 1,
		Image = Constants.Shadow.Image,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Constants.Shadow.SliceCenter,
		ZIndex = 0,
		Parent = root,
	})

	local main = Create("Frame", {
		Name = "Main",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = Constants.Glass.Main,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = root,
	}, {
		Utility.Corner(12),
		Create("UIGradient", { -- glass sheen
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 225)),
		}),
	})
	Theme.Bind(main, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.86).Parent = main

	local topbar = Topbar.new(main, config)

	---------------------------------------------------------------- body
	local body = Create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, TOPBAR + 1),
		Size = UDim2.new(1, 0, 1, -(TOPBAR + 1)),
		BackgroundTransparency = 1,
		Parent = main,
	})

	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(0, sidebarWidth, 1, -16),
		BackgroundTransparency = Constants.Glass.Sidebar,
		BorderSizePixel = 0,
		Parent = body,
	}, { Utility.Corner(10) })
	Theme.Bind(sidebar, { BackgroundColor3 = "Sidebar" })
	Builders.Stroke(0.94).Parent = sidebar

	local searchHeight = config.Search == false and 0 or Defaults.SearchHeight
	local profileHeight = config.Profile == false and 0 or Defaults.ProfileHeight
	local listTop = searchHeight > 0 and (searchHeight + 8) or 0

	if searchHeight > 0 then
		SearchBar.new(sidebar, searchHeight, function(text)
			window._query = text
			if window.ActiveTab then
				window.ActiveTab:Filter(text)
			end
		end)
	end

	if profileHeight > 0 then
		Profile.new(sidebar, profileHeight)
	end

	local tabList = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, listTop),
		Size = UDim2.new(1, 0, 1, -(listTop + profileHeight)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	}, { Utility.List(3), Utility.Padding(6, 6, 6, 6) })

	local content = Create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(sidebarWidth + 16, 0),
		Size = UDim2.new(1, -(sidebarWidth + 16), 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = body,
	})

	---------------------------------------------------------------- resize handle
	local resizeHandle = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 10,
		Parent = main,
	})
	for _, offset in ipairs({ { 11, 5 }, { 11, 11 }, { 5, 11 } }) do
		local dot = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(offset[1], offset[2]),
			Size = UDim2.fromOffset(3, 3),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 11,
			Parent = resizeHandle,
		}, { Utility.Corner(2) })
		Theme.Bind(dot, { BackgroundColor3 = "SubText" })
	end

	---------------------------------------------------------------- responsive scale
	local baseScale = 1

	local function computeScale()
		local viewport = Utility.GetViewport()
		local fitWidth = (viewport.X - 24) / root.Size.X.Offset
		local fitHeight = (viewport.Y - 24) / math.max(root.Size.Y.Offset, TOPBAR)
		baseScale = math.clamp(math.min(1, fitWidth, fitHeight), 0.5, 1)
		return baseScale
	end

	local camera = workspace.CurrentCamera
	if camera then
		Track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if window.Visible then
				Tween(rootScale, { Scale = computeScale() }, 0.2)
			end
		end))
	end

	---------------------------------------------------------------- drag
	Draggable(topbar.Frame, root)

	---------------------------------------------------------------- resize
	local resizing, resizeStart, startSize, startPosition = false, nil, nil, nil

	Track(resizeHandle.InputBegan:Connect(function(input)
		if Utility.IsClick(input) and not window.Minimized then
			resizing = true
			resizeStart = input.Position
			startSize = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
			startPosition = root.Position
		end
	end))

	Track(UserInputService.InputChanged:Connect(function(input)
		if not (resizing and Utility.IsMove(input)) then
			return
		end
		local scale = rootScale.Scale
		local viewport = Utility.GetViewport()
		local delta = (input.Position - resizeStart) / scale

		local width = math.clamp(startSize.X + delta.X, minSize.X, math.max(minSize.X, viewport.X / scale - 20))
		local height = math.clamp(startSize.Y + delta.Y, minSize.Y, math.max(minSize.Y, viewport.Y / scale - 20))
		root.Size = UDim2.fromOffset(width, height)

		-- anchor is centered: shift so the top-left corner stays pinned
		local dx = (width - startSize.X) * scale / 2
		local dy = (height - startSize.Y) * scale / 2
		root.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + dx,
			startPosition.Y.Scale,
			startPosition.Y.Offset + dy
		)
	end))

	Track(UserInputService.InputEnded:Connect(function(input)
		if resizing and Utility.IsClick(input) then
			resizing = false
		end
	end))

	---------------------------------------------------------------- minimize
	-- Minimizing collapses the window into a small pill: [logo] brand.
	-- The pill appears where the window's top-left corner was; restoring
	-- moves the window to wherever the pill was dragged.
	local miniBar

	function window:Minimize(state)
		if state == nil then
			state = not window.Minimized
		end
		if state == window.Minimized then
			return
		end
		window.Minimized = state

		if state then
			local corner = root.AbsolutePosition
			Tween(rootScale, { Scale = baseScale * 0.9 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.15, function()
				if window.Minimized then
					root.Visible = false
				end
			end)
			miniBar:Show(corner)
		else
			local corner = miniBar.Instance.AbsolutePosition
			local half = root.AbsoluteSize / 2
			miniBar:Hide()
			root.Position = UDim2.fromOffset(corner.X + half.X, corner.Y + half.Y)
			if window.Visible then
				root.Visible = true
				rootScale.Scale = baseScale * 0.9
				Tween(rootScale, { Scale = baseScale }, 0.3, Enum.EasingStyle.Back)
			end
		end
	end

	miniBar = MiniBar.new(screenGui, config, function()
		window:Minimize(false)
	end)

	---------------------------------------------------------------- visibility
	local animating = false

	function window:SetVisible(state)
		if state == window.Visible or animating then
			return
		end
		window.Visible = state

		-- While minimized, show/hide the pill instead of the window
		if window.Minimized then
			if state then
				miniBar:Show()
			else
				miniBar:Hide()
			end
			if window.ToggleButton then
				Tween(window.ToggleButton.Stroke, { Transparency = state and 0.2 or 0.6 }, 0.2)
			end
			return
		end

		animating = true

		if state then
			root.Visible = true
			rootScale.Scale = computeScale() * 0.9
			Tween(rootScale, { Scale = baseScale }, 0.35, Enum.EasingStyle.Back)
			task.delay(0.35, function()
				animating = false
			end)
		else
			Tween(rootScale, { Scale = baseScale * 0.9 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.18, function()
				if not window.Visible then
					root.Visible = false
				end
				animating = false
			end)
		end

		if window.ToggleButton then
			Tween(window.ToggleButton.Stroke, { Transparency = state and 0.2 or 0.6 }, 0.2)
		end
	end

	function window:Toggle()
		window:SetVisible(not window.Visible)
	end

	---------------------------------------------------------------- lifecycle
	local destroyed = false

	function window:Destroy()
		if destroyed then
			return
		end
		destroyed = true

		Tween(rootScale, { Scale = baseScale * 0.85 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.2)

		Utility.DisconnectAll()
		Theme.Reset()
		Gui.Destroy()
		table.clear(State.Windows)
		Utility.SafeCall(config.OnClose)
	end

	---------------------------------------------------------------- misc API
	function window:SetTitle(text)
		topbar.TitleLabel.Text = text
	end

	function window:SetAuthor(text)
		if topbar.AuthorLabel then
			topbar.AuthorLabel.Text = text
		end
	end

	function window:SetTheme(name, accent)
		Theme.Set(name, accent)
	end

	function window:SetToggleKey(keyCode)
		window.ToggleKey = keyCode
	end

	function window:Notify(options)
		return Notify(options)
	end

	function window:Dialog(options)
		if window._dialog then
			window._dialog:Close()
		end
		options = options or {}
		local userOnClose = options.OnClose
		options.OnClose = function()
			window._dialog = nil
			Utility.SafeCall(userOnClose)
		end
		window._dialog = Dialog.new(main, options)
		return window._dialog
	end

	---------------------------------------------------------------- tabs
	function window:SelectTab(target)
		local tab = type(target) == "number" and window.Tabs[target] or target
		if not tab or tab == window.ActiveTab then
			return
		end

		local previous = window.ActiveTab
		window.ActiveTab = tab

		if previous then
			previous.Page.Visible = false
			previous:_SetActive(false)
		end

		tab:_SetActive(true)
		tab:Filter(window._query)
		tab.Page.Visible = true
		tab.Page.Position = UDim2.fromOffset(0, 14)
		Tween(tab.Page, { Position = UDim2.fromOffset(0, 0) }, 0.35)
	end

	function window:Tab(options)
		local tab = Tab.new(window, options, { List = tabList, Content = content })
		table.insert(window.Tabs, tab)
		if #window.Tabs == 1 then
			window:SelectTab(tab)
		end
		return tab
	end
	window.AddTab = window.Tab
	window.CreateTab = window.Tab

	---------------------------------------------------------------- inputs
	topbar.MinimizeButton.MouseButton1Click:Connect(function()
		window:Minimize()
	end)

	topbar.CloseButton.MouseButton1Click:Connect(function()
		if config.ConfirmClose == false then
			task.spawn(function()
				window:Destroy()
			end)
			return
		end
		if window._dialog then
			return
		end
		window:Dialog({
			Title = "Close " .. (config.Title or "this window") .. "?",
			Content = "The interface will be removed. Run the script again to bring it back.",
			Buttons = {
				{ Title = "Cancel" },
				{
					Title = "Close",
					Variant = "Danger",
					Callback = function()
						window:Destroy()
					end,
				},
			},
		})
	end)

	Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:Toggle()
		end
	end))

	if config.ToggleButton ~= false then
		window.ToggleButton = ToggleButton.new(screenGui, config, function()
			window:Toggle()
		end)
	end

	---------------------------------------------------------------- open animation
	computeScale()
	rootScale.Scale = baseScale * 0.9
	Tween(rootScale, { Scale = baseScale }, 0.45, Enum.EasingStyle.Back)

	table.insert(State.Windows, window)
	return window
end

return Window
end

__modules["init"] = function(...)
--[[
	EakUI — custom UI library for Roblox script hubs
	100% Instance.new(), no external dependencies.

	Entry point. Exposes the public API only; implementation lives in
	Core/, Components/, Themes/ and Window/.

	local UI = loadstring(game:HttpGet("<raw url>/dist/EakUI.lua"))()
	local Window = UI:CreateWindow({ Title = "MyHub", Size = UDim2.fromOffset(500, 400), Theme = "Dark" })
]]

local import = ...
local State = import("Core/State")
local Theme = import("Core/Theme")
local Themes = import("Themes")
local Window = import("Window")
local Notify = import("Components/Notification")
local Assets = import("Core/Assets")

Theme.Ensure("Dark")

local EakUI = {
	Version = State.Version,
	Flags = State.Flags,
	Themes = Themes,
}

function EakUI:CreateWindow(config)
	return Window.new(config)
end

function EakUI:Notify(config)
	return Notify(config)
end

function EakUI:SetTheme(name, accent)
	Theme.Set(name, accent)
end

function EakUI:SetAccent(color)
	Theme.SetAccent(color)
end

-- Download URL images ahead of time so they appear instantly later
function EakUI:Preload(sources)
	Assets.Preload(sources)
end

-- Resolve any image source (id, URL, file) for use in your own ImageLabels
function EakUI:GetImage(source)
	return Assets.Resolve(source)
end

function EakUI:GetTheme()
	return State.ThemeName, State.Theme
end

function EakUI:Destroy()
	for _, window in ipairs(table.clone(State.Windows)) do
		pcall(function()
			window:Destroy()
		end)
	end
end

return EakUI
end

return import("init")
