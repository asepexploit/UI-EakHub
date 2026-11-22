--[[
	Window/MiniBar
	Compact pill shown while the window is minimized:
	[ logo ]  brand logo (image) or title text
	Draggable; click to restore the window.

	MiniBar.new(parent, config, onRestore) -> {
		Instance, Show(screenPosition), Hide(), IsVisible()
	}

	config.Logo          square logo (id, rbxassetid, URL or file)
	config.BrandLogo     wordmark image next to the logo (optional)
	config.BrandLogoSize UDim2, default 110x24
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")
local Draggable = import("Core/Draggable")

local Create, Tween = Utility.Create, Utility.Tween

local HEIGHT = 52
local LOGO = 38

local MiniBar = {}

function MiniBar.new(parent, config, onRestore)
	local bar = Create("TextButton", {
		Name = "MiniBar",
		Size = UDim2.fromOffset(0, HEIGHT),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = Constants.Glass.Main,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 40,
		Parent = parent,
	}, {
		Utility.Corner(14),
		Utility.Padding(0, 0, 7, 16),
		Utility.List(10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
	})
	Theme.Bind(bar, { BackgroundColor3 = "Background" })
	local stroke = Builders.Stroke(0.82)
	stroke.Parent = bar
	local scale = Create("UIScale", { Parent = bar })

	-- Logo tile ------------------------------------------------------------
	local tile = Create("Frame", {
		Size = UDim2.fromOffset(LOGO, LOGO),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 1,
		ZIndex = 41,
		Parent = bar,
	}, { Utility.Corner(10) })
	Theme.Bind(tile, { BackgroundColor3 = "Accent" })

	local logoSource = config.Logo or config.Icon
	if logoSource then
		local logo = Create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 42,
			Parent = tile,
		}, { Utility.Corner(10) })
		Assets.Apply(logo, logoSource)
	else
		Builders.Label({
			Text = string.upper(string.sub(config.Title or "E", 1, 1)),
			Font = Constants.Fonts.Black,
			TextSize = 18,
			ThemeColor = "Accent",
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 42,
			Parent = tile,
		})
	end

	-- Brand ----------------------------------------------------------------
	if config.BrandLogo then
		local brand = Create("ImageLabel", {
			Size = config.BrandLogoSize or UDim2.fromOffset(110, 24),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 2,
			ZIndex = 41,
			Parent = bar,
		})
		Assets.Apply(brand, config.BrandLogo)
	else
		local textGroup = Create("Frame", {
			Size = UDim2.fromOffset(0, LOGO),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			ZIndex = 41,
			Parent = bar,
		}, { Utility.List(1, nil, nil, Enum.VerticalAlignment.Center) })

		Builders.Label({
			Text = config.Title or "EakUI",
			Font = Constants.Fonts.Bold,
			TextSize = 14,
			Size = UDim2.fromOffset(0, 17),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 1,
			ZIndex = 41,
			Parent = textGroup,
		})
		if config.Author or config.SubTitle then
			Builders.Label({
				Text = config.Author or config.SubTitle,
				Font = Constants.Fonts.Regular,
				TextSize = 11,
				ThemeColor = "SubText",
				Size = UDim2.fromOffset(0, 13),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = 2,
				ZIndex = 41,
				Parent = textGroup,
			})
		end
	end

	-- Interaction ----------------------------------------------------------
	local drag = Draggable(bar, bar)

	bar.MouseEnter:Connect(function()
		Tween(stroke, { Transparency = 0.6 }, 0.15)
	end)
	bar.MouseLeave:Connect(function()
		Tween(stroke, { Transparency = 0.82 }, 0.15)
	end)
	bar.MouseButton1Click:Connect(function()
		if drag.Moved then
			return
		end
		onRestore()
	end)

	local api = { Instance = bar }

	function api:Show(screenPosition)
		if screenPosition then
			bar.Position = UDim2.fromOffset(screenPosition.X, screenPosition.Y)
		end
		bar.Visible = true
		scale.Scale = 0.85
		Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	end

	function api:Hide()
		Tween(scale, { Scale = 0.85 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.12, function()
			bar.Visible = false
		end)
	end

	function api:IsVisible()
		return bar.Visible
	end

	return api
end

return MiniBar
