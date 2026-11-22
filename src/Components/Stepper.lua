--[[
	Components/Stepper
	Precise number input:  [-]  value  [+]
	Hold - or + to repeat (starts after 0.35s, then every 0.06s).

	local stepper = Tab:Stepper({
		Title    = "Amount",
		Min      = 0,
		Max      = 10,
		Step     = 1,       -- supports decimals
		Default  = 1,
		Suffix   = "x",
		Flag     = "Amount",
		Callback = function(value) end,
	})
	stepper:Set(5) / stepper:Get() / stepper:SetMinMax(0, 20)
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

local BUTTON = 26
local VALUE_WIDTH = 58
local REPEAT_DELAY = 0.35
local REPEAT_RATE = 0.06

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
		RightSize = UDim.new(0, BUTTON * 2 + VALUE_WIDTH + 8),
	})
	local holder = element.Instance

	local control = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(BUTTON * 2 + VALUE_WIDTH + 8, BUTTON),
		BackgroundTransparency = 1,
		Parent = holder,
	}, { Utility.List(4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	local function stepButton(order, isPlus)
		local button = Create("TextButton", {
			Size = UDim2.fromOffset(BUTTON, BUTTON),
			BackgroundTransparency = Constants.Glass.Field,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = order,
			Parent = control,
		}, { Utility.Corner(6) })
		Theme.Bind(button, { BackgroundColor3 = "Field" })
		Builders.Stroke().Parent = button

		-- "-" bar, plus a vertical bar for "+"
		local horizontal = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(10, 2),
			BorderSizePixel = 0,
			Parent = button,
		}, { Utility.Corner(1) })
		Theme.Bind(horizontal, { BackgroundColor3 = "Text" })
		if isPlus then
			local vertical = Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(2, 10),
				BorderSizePixel = 0,
				Parent = button,
			}, { Utility.Corner(1) })
			Theme.Bind(vertical, { BackgroundColor3 = "Text" })
		end

		button.MouseEnter:Connect(function()
			Tween(button, { BackgroundColor3 = State.Theme.ElementHover }, 0.12)
		end)
		button.MouseLeave:Connect(function()
			Tween(button, { BackgroundColor3 = State.Theme.Field }, 0.12)
		end)
		return button
	end

	local minus = stepButton(1, false)

	local valueBox = Create("TextBox", {
		Size = UDim2.fromOffset(VALUE_WIDTH, BUTTON),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Text = "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		Parent = control,
	}, { Utility.Corner(6) })
	Theme.Bind(valueBox, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	local boxStroke = Builders.Stroke()
	boxStroke.Parent = valueBox

	local plus = stepButton(3, true)

	local function round(value)
		local snapped = math.floor((value - min) / step + 0.5) * step + min
		snapped = tonumber(string.format(numberFormat, snapped))
		return math.clamp(snapped, min, max)
	end

	local function render()
		valueBox.Text = string.format(numberFormat, element.Value) .. suffix
		-- dim a button when its limit is reached
		Tween(minus, { BackgroundTransparency = element.Value <= min and 0.6 or Constants.Glass.Field }, 0.12)
		Tween(plus, { BackgroundTransparency = element.Value >= max and 0.6 or Constants.Glass.Field }, 0.12)
	end

	element.Value = round(options.Default or options.Value or min)

	function element:Set(value, silent)
		local new = round(tonumber(value) or element.Value)
		local changed = new ~= element.Value
		element.Value = new
		render()
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

	-- Hold-to-repeat -------------------------------------------------------
	local holdToken = 0 -- bumped on release so stale repeat loops stop

	local function startHold(direction)
		holdToken += 1
		local token = holdToken
		element:Set(element.Value + step * direction)
		task.delay(REPEAT_DELAY, function()
			while holdToken == token do
				element:Set(element.Value + step * direction)
				task.wait(REPEAT_RATE)
			end
		end)
	end

	local function bindHold(button, direction)
		Utility.Track(button.InputBegan:Connect(function(input)
			if Utility.IsClick(input) then
				Builders.Ripple(button, input.Position)
				startHold(direction)
			end
		end))
	end
	bindHold(minus, -1)
	bindHold(plus, 1)
	minus.ClipsDescendants = true
	plus.ClipsDescendants = true

	Utility.Track(UserInputService.InputEnded:Connect(function(input)
		if Utility.IsClick(input) then
			holdToken += 1
		end
	end))

	-- Manual entry ---------------------------------------------------------
	valueBox.Focused:Connect(function()
		Tween(boxStroke, { Color = State.Theme.Accent, Transparency = 0.3 }, 0.15)
		valueBox.Text = string.format(numberFormat, element.Value)
	end)

	valueBox.FocusLost:Connect(function()
		Tween(boxStroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.15)
		local number = tonumber((valueBox.Text:gsub("[^%d%.%-]", "")))
		if number then
			element:Set(number)
		end
		render()
	end)

	render()
	Element.RegisterFlag(options, element)
	return element
end
