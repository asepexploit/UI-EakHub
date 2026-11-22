--[[
	Components/List
	Selectable, searchable list card (players, items, teleport spots...).

	local list = Tab:List({
		Title     = "Teleports",
		Items     = {
			"Spawn",                                                  -- plain string
			{ Title = "Shop", Desc = "Near the fountain", Icon = "rbxassetid://..." },
			{ Title = "Boss", Image = "https://example.com/boss.png" },  -- full-color image
		},
		Multi     = false,
		Search    = nil,        -- true/false; auto-on for more than 6 items
		MaxHeight = 200,        -- list area height before scrolling
		Empty     = "No items",
		Flag      = "Teleport",
		Callback  = function(value) end,  -- title (or table of titles when Multi)
	})
	list:SetItems(items) / list:Set(value) / list:Get()
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local ROW_SIMPLE = 32
local ROW_WITH_DESC = 44
local ROW_GAP = 2
local SEARCH_THRESHOLD = 6

local function normalize(item)
	if type(item) == "table" then
		return {
			Title = tostring(item.Title or item.Name or ""),
			Desc = item.Desc or item.Description,
			Icon = item.Icon,
			Image = item.Image,
		}
	end
	return { Title = tostring(item) }
end

return function(tab, options)
	options = options or {}
	local multi = options.Multi or false
	local maxHeight = options.MaxHeight or 200
	local items = {}

	local initial = options.Value or options.Default
	local value
	if multi then
		value = type(initial) == "table" and table.clone(initial) or {}
	else
		value = initial
	end

	---------------------------------------------------------------- container
	local holder = Create("Frame", {
		Name = options.Title or "List",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(8),
		Utility.Padding(10, 10, 10, 10),
		Utility.List(8),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})

	local titleLabel = Builders.Label({
		Text = options.Title or "List",
		Position = UDim2.fromOffset(2, 0),
		Size = UDim2.new(1, -70, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	local countLabel = Builders.Label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 70, 1, 0),
		Font = Constants.Fonts.Regular,
		TextSize = 11,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	-- Search ---------------------------------------------------------------
	local searchFrame = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Visible = false,
		LayoutOrder = 2,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(searchFrame, { BackgroundColor3 = "Field" })
	local searchStroke = Builders.Stroke()
	searchStroke.Parent = searchFrame

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

	-- Rows -----------------------------------------------------------------
	local scroller = Create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		LayoutOrder = 3,
		Parent = holder,
	}, { Utility.List(ROW_GAP), Utility.Padding(0, 0, 0, 4) })
	Theme.Bind(scroller, { ScrollBarImageColor3 = "Accent" })

	local emptyLabel = Builders.Label({
		Text = options.Empty or "No items",
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 40),
		Visible = false,
		LayoutOrder = 4,
		Parent = holder,
	})

	local rows = {} -- { Instance, Label, Marker, Item }

	local function isSelected(title)
		if multi then
			return table.find(value, title) ~= nil
		end
		return value == title
	end

	local function paintRows(instant)
		local theme = State.Theme
		local duration = instant and 0 or 0.15
		for _, row in ipairs(rows) do
			local selected = isSelected(row.Item.Title)
			Tween(row.Instance, { BackgroundTransparency = selected and 0.82 or 1 }, duration)
			Tween(row.Label, { TextColor3 = selected and theme.Text or theme.SubText }, duration)
			Tween(row.Marker, { BackgroundTransparency = selected and 0 or 1 }, duration)
		end
	end

	local function layout()
		local query = string.lower(searchBox.Text)
		local visibleHeight = 0
		local visibleCount = 0
		for _, row in ipairs(rows) do
			local match = query == "" or string.find(string.lower(row.Item.Title), query, 1, true) ~= nil
			row.Instance.Visible = match
			if match then
				visibleCount += 1
				visibleHeight += row.Instance.Size.Y.Offset + ROW_GAP
			end
		end
		scroller.Size = UDim2.new(1, 0, 0, math.min(visibleHeight, maxHeight))
		scroller.Visible = visibleCount > 0
		emptyLabel.Visible = visibleCount == 0
		emptyLabel.Text = (#items > 0 and query ~= "") and "No results" or (options.Empty or "No items")

		local selectedCount = multi and #value or (value ~= nil and 1 or 0)
		countLabel.Text = multi and string.format("%d selected", selectedCount) or string.format("%d items", #items)
	end

	local element = { Instance = holder, TitleLabel = titleLabel }

	local function syncValue()
		element.Value = multi and table.clone(value) or value
	end

	local function fire()
		syncValue()
		Utility.SafeCall(options.Callback, multi and table.clone(value) or value)
	end

	local function choose(title)
		if multi then
			local index = table.find(value, title)
			if index then
				table.remove(value, index)
			else
				table.insert(value, title)
			end
		else
			value = title
		end
		paintRows(false)
		layout()
		fire()
	end

	local function createRow(index, item)
		local hasDesc = item.Desc ~= nil
		local media = item.Image or item.Icon
		local height = hasDesc and ROW_WITH_DESC or ROW_SIMPLE

		local row = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, height),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			Parent = scroller,
		}, { Utility.Corner(6) })
		Theme.Bind(row, { BackgroundColor3 = "Accent" })

		local marker = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromOffset(3, height - 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = row,
		}, { Utility.Corner(2) })
		Theme.Bind(marker, { BackgroundColor3 = "Accent" })

		local textX = 16
		if media then
			local size = item.Image and (height - 10) or 16
			local icon = Create("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Size = UDim2.fromOffset(size, size),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Parent = row,
			}, { Utility.Corner(item.Image and 6 or 0) })
			Assets.Apply(icon, media)
			if item.Icon and not item.Image then
				Theme.Bind(icon, { ImageColor3 = "SubText" })
			end
			textX = 16 + size + 8
		end

		local textGroup = Create("Frame", {
			Position = UDim2.fromOffset(textX, 0),
			Size = UDim2.new(1, -(textX + 8), 1, 0),
			BackgroundTransparency = 1,
			Parent = row,
		}, { Utility.List(1, nil, nil, Enum.VerticalAlignment.Center) })

		local label = Builders.Label({
			Text = item.Title,
			Font = Constants.Fonts.Medium,
			TextSize = 12,
			ThemeColor = "SubText",
			Size = UDim2.new(1, 0, 0, 15),
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 1,
			Parent = textGroup,
		})

		if hasDesc then
			Builders.Label({
				Text = item.Desc,
				Font = Constants.Fonts.Regular,
				TextSize = 11,
				ThemeColor = "Placeholder",
				Size = UDim2.new(1, 0, 0, 13),
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 2,
				Parent = textGroup,
			})
		end

		row.MouseEnter:Connect(function()
			if not isSelected(item.Title) then
				Tween(row, { BackgroundTransparency = 0.93 }, 0.12)
			end
		end)
		row.MouseLeave:Connect(function()
			if not isSelected(item.Title) then
				Tween(row, { BackgroundTransparency = 1 }, 0.12)
			end
		end)
		row.MouseButton1Click:Connect(function()
			choose(item.Title)
		end)

		table.insert(rows, { Instance = row, Label = label, Marker = marker, Item = item })
	end

	local function build()
		for _, row in ipairs(rows) do
			row.Instance:Destroy()
		end
		table.clear(rows)

		for index, item in ipairs(items) do
			createRow(index, item)
		end

		local searchable
		if options.Search ~= nil then
			searchable = options.Search == true
		else
			searchable = #items > SEARCH_THRESHOLD
		end
		searchFrame.Visible = searchable

		paintRows(true)
		layout()
	end

	---------------------------------------------------------------- API
	function element:SetItems(newItems, keepValue)
		items = {}
		for _, item in ipairs(newItems or {}) do
			table.insert(items, normalize(item))
		end
		if not keepValue then
			value = multi and {} or nil
		elseif multi then
			-- drop selections that no longer exist
			local kept = {}
			for _, title in ipairs(value) do
				for _, item in ipairs(items) do
					if item.Title == title then
						table.insert(kept, title)
						break
					end
				end
			end
			value = kept
		end
		syncValue()
		build()
	end

	function element:Set(newValue, silent)
		if multi then
			value = type(newValue) == "table" and table.clone(newValue) or { newValue }
		else
			value = newValue
		end
		paintRows(false)
		layout()
		if silent then
			syncValue()
		else
			fire()
		end
	end

	function element:Get()
		return multi and table.clone(value) or value
	end

	function element:SetTitle(text)
		titleLabel.Text = text
	end

	function element:SetVisible(visible)
		holder.Visible = visible
	end

	function element:Destroy()
		holder:Destroy()
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(layout)
	searchBox.Focused:Connect(function()
		Tween(searchStroke, { Color = State.Theme.Accent, Transparency = 0.3 }, 0.15)
	end)
	searchBox.FocusLost:Connect(function()
		Tween(searchStroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.15)
	end)

	Theme.OnChange(function()
		paintRows(true)
	end)

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	element:SetItems(options.Items or options.Values or {}, true)
	Element.RegisterFlag(options, element)
	return element
end
