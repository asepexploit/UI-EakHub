--[[
	Components/RangeSlider
	Slider with two knobs selecting a min-max range. Knobs cannot cross.

	local range = Tab:RangeSlider({
		Title    = "Distance",
		Min      = 0,
		Max      = 100,
		Default  = { Min = 10, Max = 50 },
		Step     = 1,          -- supports decimals
		Suffix   = " studs",
		Flag     = "Distance",
		Callback = function(value) end, -- value = { Min = number, Max = number }
	})
	range:Set({ Min = 20, Max = 80 }) / range:Get() / range:SetMinMax(0, 200)
]]

local import = ...
local Services = import("Core/Services")
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
	})
	local holder = element.Instance

	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 124), 0, 36)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingTop = UDim.new(0, 8)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingBottom = UDim.new(0, 0)
	element.TextHolder:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top
	element.DescLabel.Visible = false
	if element.IconLabel then
		element.IconLabel.AnchorPoint = Vector2.new(0, 0)
		element.IconLabel.Position = UDim2.fromOffset(12, 9)
	end

	local valueLabel = Create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Text = "",
		Parent = holder,
	}, { Utility.Corner(6), Utility.Padding(0, 0, 8, 8) })
	Theme.Bind(valueLabel, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	Builders.Stroke().Parent = valueLabel

	local track = Create("Frame", {
		Position = UDim2.new(0, 12, 1, -16),
		Size = UDim2.new(1, -24, 0, 6),
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(999) })
	Theme.Bind(track, { BackgroundColor3 = "ToggleOff" })

	local fill = Create("Frame", {
		BorderSizePixel = 0,
		Parent = track,
	}, { Utility.Corner(999) })
	Theme.Bind(fill, { BackgroundColor3 = "Accent" })

	local function makeKnob()
		local knob = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = KNOB_SIZE,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = track,
		}, { Utility.Corner(999) })
		Theme.Bind(knob, { BackgroundColor3 = "Knob" })
		local stroke = Create("UIStroke", { Thickness = 2, Parent = knob })
		Theme.Bind(stroke, { Color = "Accent" })
		return knob
	end
	local lowKnob, highKnob = makeKnob(), makeKnob()

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

	local function percent(value)
		return (max == min) and 0 or (value - min) / (max - min)
	end

	local function render(instant)
		local a, b = percent(element.Value.Min), percent(element.Value.Max)
		local t = instant and 0 or 0.1
		Tween(fill, { Position = UDim2.fromScale(a, 0), Size = UDim2.fromScale(b - a, 1) }, t)
		Tween(lowKnob, { Position = UDim2.fromScale(a, 0.5) }, t)
		Tween(highKnob, { Position = UDim2.fromScale(b, 0.5) }, t)
		valueLabel.Text = string.format(numberFormat, element.Value.Min)
			.. " - "
			.. string.format(numberFormat, element.Value.Max)
			.. suffix
	end

	local initial = options.Default or options.Value or {}
	local low = round(initial.Min or initial[1] or min)
	local high = round(initial.Max or initial[2] or max)
	element.Value = { Min = math.min(low, high), Max = math.max(low, high) }

	function element:Set(value, silent)
		local newLow = round(tonumber(value.Min or value[1]) or element.Value.Min)
		local newHigh = round(tonumber(value.Max or value[2]) or element.Value.Max)
		if newLow > newHigh then
			newLow, newHigh = newHigh, newLow
		end
		local changed = newLow ~= element.Value.Min or newHigh ~= element.Value.Max
		element.Value = { Min = newLow, Max = newHigh }
		render(false)
		if changed and not silent then
			Utility.SafeCall(options.Callback, { Min = newLow, Max = newHigh })
		end
	end

	function element:Get()
		return { Min = element.Value.Min, Max = element.Value.Max }
	end

	function element:SetMinMax(newMin, newMax)
		min, max = newMin, newMax
		element:Set(element.Value, true)
	end

	-- Dragging: grab the nearest knob, it stops at the other knob ----------
	local active -- "Min" | "Max" | nil

	local function valueAt(x)
		local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		return round(min + p * (max - min))
	end

	local function update(x)
		local value = valueAt(x)
		if active == "Min" then
			element:Set({ Min = math.min(value, element.Value.Max), Max = element.Value.Max })
		else
			element:Set({ Min = element.Value.Min, Max = math.max(value, element.Value.Min) })
		end
	end

	Utility.Track(hitbox.InputBegan:Connect(function(input)
		if not Utility.IsClick(input) then
			return
		end
		local value = valueAt(input.Position.X)
		local toLow = math.abs(value - element.Value.Min)
		local toHigh = math.abs(value - element.Value.Max)
		if toLow == toHigh then
			active = value < element.Value.Min and "Min" or "Max"
		else
			active = toLow < toHigh and "Min" or "Max"
		end
		Tween(active == "Min" and lowKnob or highKnob, { Size = KNOB_SIZE_ACTIVE }, 0.15)
		update(input.Position.X)
	end))

	Utility.Track(UserInputService.InputChanged:Connect(function(input)
		if active and Utility.IsMove(input) then
			update(input.Position.X)
		end
	end))

	Utility.Track(UserInputService.InputEnded:Connect(function(input)
		if active and Utility.IsClick(input) then
			Tween(active == "Min" and lowKnob or highKnob, { Size = KNOB_SIZE }, 0.2, Enum.EasingStyle.Back)
			active = nil
		end
	end))

	render(true)
	Theme.OnChange(function()
		render(true)
	end)
	Element.RegisterFlag(options, element)
	return element
end
