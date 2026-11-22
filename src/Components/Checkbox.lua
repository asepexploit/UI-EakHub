--[[
	Components/Checkbox
	Compact alternative to Toggle, good for long option lists.

	local box = Tab:Checkbox({
		Title    = "Auto collect",
		Desc     = "optional",
		Value    = false,
		Flag     = "AutoCollect",
		Callback = function(value) end,
	})
	box:Set(true) / box:Get() / box:Toggle()
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local BOX = 18

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Button = true,
		Hover = true,
		Height = 38,
		RightSize = UDim.new(0, BOX + 6),
	})
	local holder = element.Instance

	if options.Value ~= nil then
		element.Value = options.Value == true
	else
		element.Value = options.Default == true
	end

	local box = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(BOX, BOX),
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(5) })
	local boxStroke = Create("UIStroke", {
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = box,
	})

	-- Checkmark: short bar + long bar, scaled in with a pop
	local mark = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(BOX, BOX),
		BackgroundTransparency = 1,
		Parent = box,
	})
	local markScale = Create("UIScale", { Scale = 0, Parent = mark })

	local short = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(6, 10),
		Size = UDim2.fromOffset(6, 2),
		Rotation = 45,
		BorderSizePixel = 0,
		Parent = mark,
	}, { Utility.Corner(1) })
	local long = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(11, 8.5),
		Size = UDim2.fromOffset(10, 2),
		Rotation = -50,
		BorderSizePixel = 0,
		Parent = mark,
	}, { Utility.Corner(1) })
	Theme.Bind(short, { BackgroundColor3 = "Knob" })
	Theme.Bind(long, { BackgroundColor3 = "Knob" })

	local function render(instant)
		local theme = State.Theme
		local on = element.Value
		local t = instant and 0 or 0.2

		Tween(box, {
			BackgroundColor3 = on and theme.Accent or theme.Field,
			BackgroundTransparency = on and 0 or 0.15,
		}, t)
		Tween(boxStroke, {
			Color = on and theme.Accent or theme.SubText,
			Transparency = on and 0 or 0.5,
		}, t)
		Tween(markScale, { Scale = on and 1 or 0 }, instant and 0 or 0.25, Enum.EasingStyle.Back)
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
	return element
end
