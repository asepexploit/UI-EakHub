--[[
	Window/ToggleButton
	Draggable floating button that opens / closes the window.

	ToggleButton.new(parent, config, onClick) -> { Instance, Stroke }
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Draggable = import("Core/Draggable")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local ToggleButton = {}

function ToggleButton.new(parent, config, onClick)
	local button = Create("TextButton", {
		Name = "ToggleButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.ToggleButtonPosition or UDim2.new(0, 44, 0.5, 0),
		Size = UDim2.fromOffset(48, 48),
		BackgroundTransparency = Constants.Glass.Main,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
		Parent = parent,
	}, { Utility.Corner(14) })
	Theme.Bind(button, { BackgroundColor3 = "Background" })

	local stroke = Create("UIStroke", {
		Thickness = 1.5,
		Transparency = 0.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = button,
	})
	Theme.Bind(stroke, { Color = "Accent" })

	local scale = Create("UIScale", { Parent = button })

	-- Priority: ToggleIcon > Logo (full color, fills the button) > Icon (tinted)
	local logo = config.ToggleIcon or config.Logo
	local iconId = logo or config.Icon
	if iconId then
		local image = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = logo and UDim2.new(1, -8, 1, -8) or UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 51,
			Parent = button,
		}, { Utility.Corner(10) })
		Assets.Apply(image, iconId)
		if not logo then
			Theme.Bind(image, { ImageColor3 = "Accent" })
		end
	else
		Builders.Label({
			Name = "Letter",
			Text = string.upper(string.sub(config.Title or "E", 1, 1)),
			Font = Constants.Fonts.Black,
			TextSize = 20,
			ThemeColor = "Accent",
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 51,
			Parent = button,
		})
	end

	local drag = Draggable(button, button)

	button.MouseEnter:Connect(function()
		Tween(scale, { Scale = 1.08 }, 0.2, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		Tween(scale, { Scale = 1 }, 0.2)
	end)
	button.MouseButton1Click:Connect(function()
		if drag.Moved then
			return -- it was a drag, not a click
		end
		Tween(scale, { Scale = 0.9 }, 0.08)
		task.delay(0.08, function()
			Tween(scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
		end)
		onClick()
	end)

	return { Instance = button, Stroke = stroke }
end

return ToggleButton
