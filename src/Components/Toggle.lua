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
