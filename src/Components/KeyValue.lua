--[[
	Components/KeyValue
	Card of label / value rows, e.g. an Info or Stats summary.

	local info = Tab:KeyValue({
		Title = "Details",                     -- optional header
		Rows = {
			{ "Version", "1.0.0" },
			{ "UI library", "EakUI 1.7.0" },
			{ "Hotkey", "F6" },
		},
	})
	info:Set("Hotkey", "F7")        -- updates an existing row or appends a new one
	info:Get("Version") -> "1.0.0"
	info:SetRows({ { "A", "1" } })  -- replaces every row
	info:Remove("Hotkey")
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create = Utility.Create

local ROW_HEIGHT = 40

return function(tab, options)
	options = options or {}

	local holder = Create("Frame", {
		Name = options.Title or "KeyValue",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(12), Utility.List(0), Utility.Padding(options.Title and 4 or 0, 0, 14, 14) })
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	local titleLabel
	if options.Title then
		titleLabel = Builders.Label({
			Text = options.Title,
			Font = Constants.Fonts.Bold,
			TextSize = 13,
			Size = UDim2.new(1, 0, 0, 32),
			LayoutOrder = 0,
			Parent = holder,
		})
		if tab._searchables then
			table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
		end
	end

	local rows = {} -- array of { Key, Frame, ValueLabel }
	local order = 0

	local function findRow(key)
		for index, row in ipairs(rows) do
			if row.Key == key then
				return row, index
			end
		end
		return nil
	end

	local function refreshDividers()
		for index, row in ipairs(rows) do
			row.Divider.Visible = index < #rows
		end
	end

	local function addRow(key, value)
		order += 1
		local frame = Create("Frame", {
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Parent = holder,
		})
		Builders.Label({
			Text = tostring(key),
			Font = Constants.Fonts.Regular,
			TextSize = 13,
			ThemeColor = "SubText",
			Size = UDim2.new(0.5, 0, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = frame,
		})
		local valueLabel = Builders.Label({
			Text = tostring(value),
			Font = Constants.Fonts.Medium,
			TextSize = 13,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0.5, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			RichText = true,
			Parent = frame,
		})
		local divider = Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
			Parent = frame,
		})
		Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

		table.insert(rows, { Key = key, Frame = frame, ValueLabel = valueLabel, Divider = divider })
		refreshDividers()
	end

	local api = { Instance = holder, TitleLabel = titleLabel }

	function api:Set(key, value)
		local row = findRow(key)
		if row then
			row.ValueLabel.Text = tostring(value)
		else
			addRow(key, value)
		end
	end

	function api:Get(key)
		local row = findRow(key)
		return row and row.ValueLabel.Text
	end

	function api:Remove(key)
		local row, index = findRow(key)
		if row then
			row.Frame:Destroy()
			table.remove(rows, index)
			refreshDividers()
		end
	end

	function api:SetRows(newRows)
		for _, row in ipairs(rows) do
			row.Frame:Destroy()
		end
		table.clear(rows)
		for _, pair in ipairs(newRows or {}) do
			addRow(pair[1], pair[2])
		end
	end

	function api:SetVisible(visible)
		holder.Visible = visible
	end

	function api:Destroy()
		holder:Destroy()
	end

	api:SetRows(options.Rows)
	return api
end
