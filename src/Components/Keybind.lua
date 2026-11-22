--[[
	Components/Keybind
	Click the key chip, press any key to rebind. Escape / Backspace clears it.

	local bind = Tab:Keybind({
		Title           = "Fly",
		Value           = Enum.KeyCode.F,       -- or nil
		Flag            = "FlyKey",
		Callback        = function(key) end,    -- fired when the key is pressed
		ChangedCallback = function(key) end,    -- fired after rebinding
	})
	bind:Set(Enum.KeyCode.G) / bind:Get()
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

local CLEAR_KEYS = {
	[Enum.KeyCode.Escape] = true,
	[Enum.KeyCode.Backspace] = true,
}

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Hover = true,
		RightSize = UDim.new(0, 96),
	})
	local holder = element.Instance
	element.Value = options.Value or options.Default

	local chip = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Text = "",
		Parent = holder,
	}, { Utility.Corner(6), Utility.Padding(0, 0, 10, 10) })
	Theme.Bind(chip, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	local chipStroke = Builders.Stroke()
	chipStroke.Parent = chip

	local listening = false

	local function render()
		if listening then
			chip.Text = "Press a key..."
		else
			chip.Text = element.Value and element.Value.Name or "None"
		end
		Tween(chipStroke, {
			Color = listening and State.Theme.Accent or State.Theme.Stroke,
			Transparency = listening and 0.2 or State.Theme.StrokeAlpha,
		}, 0.15)
	end

	function element:Set(keyCode, silent)
		element.Value = keyCode
		listening = false
		render()
		if not silent then
			Utility.SafeCall(options.ChangedCallback, keyCode)
		end
	end

	function element:Get()
		return element.Value
	end

	chip.MouseButton1Click:Connect(function()
		listening = true
		render()
	end)

	Utility.Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local key = input.KeyCode
				element:Set(not CLEAR_KEYS[key] and key or nil)
			end
			return
		end

		if not gameProcessed and element.Value and input.KeyCode == element.Value then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end))

	render()
	Theme.OnChange(render)
	Element.RegisterFlag(options, element)
	return element
end
