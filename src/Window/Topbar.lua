--[[
	Window/Topbar
	Title row with icon, title, author pill and minimize / close buttons.

	Topbar.new(parent, config) -> {
		Frame, TitleLabel, AuthorLabel, MinimizeButton, CloseButton, Divider
	}
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween
local HEIGHT = Constants.Window.TopbarHeight

local Topbar = {}

local function controlButton(parent, order, hoverColor)
	local button = Create("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = parent,
	}, { Utility.Corner(7) })

	if hoverColor then
		button.BackgroundColor3 = hoverColor
	else
		Theme.Bind(button, { BackgroundColor3 = "ElementHover" })
	end

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = hoverColor and 0.6 or 0.2 }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = 1 }, 0.15)
	end)
	return button
end

function Topbar.new(parent, config)
	local frame = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, HEIGHT),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	-- Left: icon, title, author ------------------------------------------
	local titleGroup = Create("Frame", {
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -110, 1, 0),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { Utility.List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	-- Icon (tinted with the accent) or Logo (full-color, never tinted)
	local iconSource = config.Icon or config.Logo
	if iconSource then
		local icon = Create("ImageLabel", {
			Size = UDim2.fromOffset(config.Icon and 20 or 24, config.Icon and 20 or 24),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 1,
			Parent = titleGroup,
		}, { Utility.Corner(6) })
		Assets.Apply(icon, iconSource)
		if config.Icon and config.IconColor ~= false then
			Theme.Bind(icon, { ImageColor3 = "Accent" })
		end
	end

	local titleLabel = Builders.Label({
		Text = config.Title or "EakUI",
		Font = Constants.Fonts.Bold,
		TextSize = 14,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = titleGroup,
	})

	local authorLabel
	local authorText = config.Author or config.SubTitle
	if authorText then
		local pill = Create("Frame", {
			Size = UDim2.new(0, 0, 0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
			LayoutOrder = 3,
			Parent = titleGroup,
		}, { Utility.Corner(999), Utility.Padding(0, 0, 8, 8) })
		Theme.Bind(pill, { BackgroundColor3 = "Accent" })

		authorLabel = Builders.Label({
			Text = authorText,
			TextSize = 11,
			ThemeColor = "SubText",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = pill,
		})
	end

	-- Right: window controls -----------------------------------------------
	local controls = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(70, 28),
		BackgroundTransparency = 1,
		Parent = frame,
	}, {
		Utility.List(4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center),
	})

	local minimizeButton = controlButton(controls, 1)
	local minimizeBar = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 2),
		BorderSizePixel = 0,
		Parent = minimizeButton,
	}, { Utility.Corner(1) })
	Theme.Bind(minimizeBar, { BackgroundColor3 = "SubText" })

	local closeButton = controlButton(controls, 2, Constants.Danger)
	Builders.CrossIcon(closeButton, 12, "SubText")

	local divider = Create("Frame", {
		Position = UDim2.fromOffset(0, HEIGHT),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

	return {
		Frame = frame,
		TitleLabel = titleLabel,
		AuthorLabel = authorLabel,
		MinimizeButton = minimizeButton,
		CloseButton = closeButton,
		Divider = divider,
	}
end

return Topbar
