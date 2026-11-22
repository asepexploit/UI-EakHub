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
