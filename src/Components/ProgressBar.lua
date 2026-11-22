--[[
	Components/ProgressBar
	Read-only progress indicator with an animated fill.

	local bar = Tab:ProgressBar({
		Title   = "Farming",
		Value   = 45,
		Max     = 100,
		Percent = false,                       -- true shows "45%" instead of "45 / 100"
		Color   = Color3.fromRGB(34, 197, 94), -- optional, defaults to the accent
		Flag    = "FarmProgress",
	})
	bar:Set(60) / bar:SetMax(200) / bar:Get()
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

return function(tab, options)
	options = options or {}
	local max = math.max(options.Max or 100, 1e-9)

	local element = Element.new(tab, options, {
		Height = 54,
		Auto = false,
		RightSize = UDim.new(0, 80),
	})
	local holder = element.Instance

	-- Title row at the top, bar along the bottom
	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 92), 0, 34)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingTop = UDim.new(0, 8)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingBottom = UDim.new(0, 0)
	element.TextHolder:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top
	element.DescLabel.Visible = false

	local valueLabel = Builders.Label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(80, 18),
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = holder,
	})

	local track = Create("Frame", {
		Position = UDim2.new(0, 12, 1, -16),
		Size = UDim2.new(1, -24, 0, 6),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
	}, { Utility.Corner(999) })
	Theme.Bind(track, { BackgroundColor3 = "ToggleOff" })

	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		Utility.Corner(999),
		Create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(205, 205, 205), Color3.new(1, 1, 1)) }),
	})
	if options.Color then
		fill.BackgroundColor3 = options.Color
	else
		Theme.Bind(fill, { BackgroundColor3 = "Accent" })
	end

	local function render(instant)
		local percent = math.clamp(element.Value / max, 0, 1)
		Tween(fill, { Size = UDim2.fromScale(percent, 1) }, instant and 0 or 0.35)
		if options.Percent then
			valueLabel.Text = string.format("%d%%", math.floor(percent * 100 + 0.5))
		else
			valueLabel.Text = string.format("%s / %s", tostring(element.Value), tostring(max))
		end
	end

	element.Value = math.clamp(options.Value or options.Default or 0, 0, max)

	function element:Set(value)
		element.Value = math.clamp(tonumber(value) or 0, 0, max)
		render(false)
	end

	function element:SetMax(newMax)
		max = math.max(tonumber(newMax) or max, 1e-9)
		element.Value = math.clamp(element.Value, 0, max)
		render(false)
	end

	function element:Get()
		return element.Value
	end

	render(true)
	Element.RegisterFlag(options, element)
	return element
end
