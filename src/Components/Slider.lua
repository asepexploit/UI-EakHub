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
