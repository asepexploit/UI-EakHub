--[[
	Components/WorldMap/Distribution
	Count of every tile id on a layer, biggest first, with bars and SKIP tags.
	Clicking a row highlights that id on the map.

	local dist = Distribution.new(parent, palette, { Limit = 8, OnSelect = fn(id) })
	dist:Set(counts, total, selectedId, title)
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Parts = import("Components/WorldMap/Parts")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local ROW_HEIGHT = 36

local Distribution = {}
Distribution.__index = Distribution

local function format(number)
	local text = tostring(number)
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end
Distribution.FormatNumber = format

function Distribution.new(parent, palette, options)
	options = options or {}
	local self = setmetatable({ Palette = palette, _rows = {}, _onSelect = options.OnSelect }, Distribution)
	self.Limit = options.Limit or 8

	local root = Create("Frame", {
		Name = "Distribution",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = options.LayoutOrder or 0,
		Parent = parent,
	}, { Utility.List(4) })
	self.Instance = root

	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = root,
	})
	self._title = Builders.Label({
		Text = "Tiles",
		Font = Fonts.Bold,
		TextSize = 13,
		Size = UDim2.fromScale(0.6, 1),
		Parent = header,
	})
	self._total = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 11,
		ThemeColor = "SubText",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.4, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	self._list = root
	self._more = Builders.Label({
		Text = "",
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 999,
		Visible = false,
		Parent = root,
	})

	self._footer = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = 1000,
		Visible = options.Footer ~= nil,
		Parent = root,
	})
	Builders.Label({
		Text = options.Footer or "",
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.6, 1),
		Parent = self._footer,
	})
	self._footerValue = Builders.Label({
		Text = "",
		Font = Fonts.Bold,
		TextSize = 12,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.4, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = self._footer,
	})
	self._footerValue.TextColor3 = Parts.Colors.Success

	return self
end

function Distribution:_row(index)
	local row = self._rows[index]
	if row then
		return row
	end

	local button = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = index,
		Parent = self._list,
	}, { Corner(7), Utility.Padding(0, 0, 6, 6) })
	Theme.Bind(button, { BackgroundColor3 = "Accent" })

	local swatch = Create("Frame", {
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.fromOffset(10, 10),
		BorderSizePixel = 0,
		Parent = button,
	}, { Corner(3) })

	local line = Create("Frame", {
		Position = UDim2.fromOffset(16, 4),
		Size = UDim2.new(1, -16, 0, 18),
		BackgroundTransparency = 1,
		Parent = button,
	}, { Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	local name = Builders.Label({
		Text = "",
		Font = Fonts.Medium,
		TextSize = 12,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
		Parent = line,
	})
	local id = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 10,
		ThemeColor = "Placeholder",
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = line,
	})
	local tag = Parts.Tag(line, 3)

	local count = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 11,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 4),
		Size = UDim2.fromOffset(70, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = button,
	})

	local track = Create("Frame", {
		Position = UDim2.fromOffset(16, 26),
		Size = UDim2.new(1, -16, 0, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		Parent = button,
	}, { Corner(999) })
	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, { Corner(999) })

	row = { Button = button, Swatch = swatch, Name = name, Id = id, Tag = tag, Count = count, Fill = fill, Value = nil }
	button.MouseEnter:Connect(function()
		if not row.Selected then
			Tween(button, { BackgroundTransparency = 0.94 }, 0.12)
		end
	end)
	button.MouseLeave:Connect(function()
		if not row.Selected then
			Tween(button, { BackgroundTransparency = 1 }, 0.12)
		end
	end)
	button.MouseButton1Click:Connect(function()
		if self._onSelect and row.Value ~= nil then
			self._onSelect(row.Value)
		end
	end)

	self._rows[index] = row
	return row
end

-- counts: { [id] = n }, selected: id | nil
function Distribution:Set(counts, total, selected, title, clearable)
	local ids = {}
	for id in pairs(counts) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		if counts[a] == counts[b] then
			return a < b
		end
		return counts[a] > counts[b]
	end)

	local maxCount = 1
	for _, id in ipairs(ids) do
		maxCount = math.max(maxCount, counts[id])
	end

	self._title.Text = title or "Tiles"
	self._total.Text = format(total) .. " total"

	local shown = math.min(#ids, self.Limit)
	for index = 1, shown do
		local id = ids[index]
		local row = self:_row(index)
		local palette = self.Palette
		row.Value = id
		row.Selected = selected == id
		row.Button.Visible = true
		row.Button.BackgroundTransparency = row.Selected and 0.84 or 1
		row.Swatch.BackgroundColor3 = id == 0 and Color3.fromRGB(38, 54, 79) or palette:Color(id)
		row.Name.Text = palette:Name(id)
		row.Id.Text = "#" .. tostring(id)
		row.Tag:Set((id ~= 0 and palette:IsSkip(id)) and "SKIP" or "", Parts.Colors.Danger)
		row.Count.Text = format(counts[id])
		row.Count.TextColor3 = Theme.Get().Text
		row.Fill.BackgroundColor3 = id == 0 and Parts.Colors.Muted or palette:Color(id)
		row.Fill.Size = UDim2.fromScale(math.max(0.02, counts[id] / maxCount), 1)
	end
	for index = shown + 1, #self._rows do
		self._rows[index].Button.Visible = false
		self._rows[index].Value = nil
	end

	self._more.Visible = #ids > shown
	self._more.Text = ("+ %d more tile types"):format(#ids - shown)

	if clearable then
		self._footerValue.Text = format(clearable) .. " tiles"
	end
end

return Distribution
