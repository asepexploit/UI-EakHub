--[[
	Components/GroupBox
	Layout helpers. This module returns two builders:

	GroupBox: a titled, bordered box that holds any components.

		local box = Tab:GroupBox({ Title = "Aimbot" })
		box:Toggle({ Title = "Enabled" })
		box:SetTitle("Aim")

	Columns: side-by-side columns (e.g. two group boxes next to each other).

		local left, right = table.unpack(Tab:Columns({ Count = 2, Gap = 8 }))
		left:GroupBox({ Title = "Combat" }):Toggle({ Title = "Kill Aura" })
		right:GroupBox({ Title = "Visuals" }):Toggle({ Title = "ESP" })

	Register as: Tab.GroupBox = GroupBox.GroupBox, Tab.Columns = GroupBox.Columns
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create = Utility.Create

local GroupBox = {}

function GroupBox.GroupBox(tab, options)
	if type(options) == "string" then
		options = { Title = options }
	end
	options = options or {}

	local holder = Create("Frame", {
		Name = options.Title or "GroupBox",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(10),
		Utility.List(8),
		Utility.Padding(10, 10, 10, 10),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Sidebar" })
	Builders.Stroke(0.9).Parent = holder

	-- Title row: label + thin accent underline
	local titleRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})

	local title = Builders.Label({
		Text = options.Title or "Group",
		Font = Constants.Fonts.Bold,
		TextSize = 12,
		Size = UDim2.new(1, 0, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleRow,
	})

	local accentLine = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 2),
		Size = UDim2.fromOffset(18, 2),
		BorderSizePixel = 0,
		Parent = titleRow,
	}, { Utility.Corner(1) })
	Theme.Bind(accentLine, { BackgroundColor3 = "Accent" })

	local body = Create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	}, { Utility.List(6) })

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	local container = tab:_Child(body)
	container.Instance = holder
	container.Body = body

	function container:SetTitle(text)
		title.Text = text
	end

	function container:Destroy()
		holder:Destroy()
	end

	return container
end

function GroupBox.Columns(tab, options)
	options = options or {}
	local count = math.max(1, math.floor(options.Count or 2))
	local gap = options.Gap or 8

	local row = Create("Frame", {
		Name = "Columns",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.List(gap, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Top),
	})

	-- Each column takes an equal share of the width minus its part of the gaps
	local columnOffset = -math.ceil(gap * (count - 1) / count)

	local columns = {}
	for index = 1, count do
		local column = Create("Frame", {
			Name = "Column" .. index,
			Size = UDim2.new(1 / count, columnOffset, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Parent = row,
		}, { Utility.List(6) })

		local container = tab:_Child(column)
		container.Instance = column
		columns[index] = container
	end

	return columns
end

return GroupBox
