--[[
	Components/WorldMap/Parts
	Small themed pieces shared by the WorldMap panels: tag pills, small
	buttons and toggle chips. Plain Instance.new, no assets.
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local Parts = {}

Parts.Colors = {
	Success = Color3.fromRGB(74, 222, 128),
	Danger = Color3.fromRGB(248, 113, 113),
	Violet = Color3.fromRGB(167, 139, 250),
	Muted = Color3.fromRGB(150, 150, 168),
}

-- Tag pill: { Instance, Set(text, color) }
function Parts.Tag(parent, layoutOrder)
	local pill = Create("Frame", {
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 0,
		Parent = parent,
	}, { Corner(4), Utility.Padding(0, 0, 5, 5) })
	local label = Create("TextLabel", {
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		TextSize = 9,
		Text = "",
		Parent = pill,
	})
	local api = { Instance = pill }
	function api:Set(text, color)
		label.Text = text
		label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.35)
		pill.BackgroundColor3 = color
		pill.BackgroundTransparency = 0.84
		pill.Visible = text ~= ""
	end
	return api
end

-- Small button: { Instance, SetText, SetActive }
function Parts.Button(parent, options)
	local primary = options.Primary
	local button = Create("TextButton", {
		Size = options.Size or UDim2.fromOffset(0, options.Height or 28),
		AutomaticSize = options.Size and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
		BackgroundTransparency = primary and 0 or 0.2,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = options.LayoutOrder or 0,
		ClipsDescendants = true,
		Parent = parent,
	}, {
		Corner(7),
		Utility.Padding(0, 0, 10, 10),
		Utility.List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})
	Theme.Bind(button, { BackgroundColor3 = primary and "Accent" or "Field" })
	if not primary then
		Builders.Stroke(0.9).Parent = button
	end

	local icon
	if options.Icon then
		icon = Create("ImageLabel", {
			Size = UDim2.fromOffset(13, 13),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Parent = button,
		})
		if primary then
			icon.ImageColor3 = Color3.new(1, 1, 1)
		else
			Theme.Bind(icon, { ImageColor3 = "Text" })
		end
		Assets.Apply(icon, options.Icon)
	end

	local label = Create("TextLabel", {
		Size = UDim2.fromOffset(0, options.Height or 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		TextSize = 12,
		Text = options.Text or "",
		LayoutOrder = 2,
		Parent = button,
	})
	if primary then
		label.TextColor3 = Color3.new(1, 1, 1)
	else
		Theme.Bind(label, { TextColor3 = "Text" })
	end

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = primary and 0.15 or 0 }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = primary and 0 or 0.2 }, 0.15)
	end)
	button.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			Builders.Ripple(button, input.Position)
		end
	end)
	button.MouseButton1Click:Connect(function()
		Utility.SafeCall(options.Callback)
	end)

	local api = { Instance = button, Label = label, Icon = icon }

	-- Keep the button from changing width when its text is swapped (e.g.
	-- "Copy coords" -> "Copied"). An AutoSize button that resizes re-flows the
	-- row's UIListLayout, making the buttons after it jump. On the first SetText
	-- the button is frozen to its current pixel width (fixed Size, AutomaticSize
	-- off), so later text swaps never move the row. Text that outgrows the frozen
	-- width is clipped (ClipsDescendants is already on) rather than widening it.
	function api:SetText(text)
		if not options.Size and button.AutomaticSize ~= Enum.AutomaticSize.None then
			local frozen = button.AbsoluteSize
			if frozen.X > 0 then
				button.AutomaticSize = Enum.AutomaticSize.None
				button.Size = UDim2.fromOffset(frozen.X, frozen.Y)
			end
		end
		label.Text = text
	end
	return api
end

--[[
	Toggle chip (selected state uses the accent):
	Parts.Chip(parent, { Text, Swatch = Color3?, LayoutOrder, Callback })
	-> { Instance, SetSelected(bool) }
]]
function Parts.Chip(parent, options)
	local chip = Create("TextButton", {
		Size = UDim2.fromOffset(0, options.Height or 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = options.LayoutOrder or 0,
		Parent = parent,
	}, {
		Corner(999),
		Utility.Padding(0, 0, options.Swatch and 8 or 10, 10),
		Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
	})
	local stroke = Create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = chip })

	if options.Swatch then
		Create("Frame", {
			Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = options.Swatch,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Parent = chip,
		}, { Corner(2) })
	end
	local label = Create("TextLabel", {
		Size = UDim2.fromOffset(0, options.Height or 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Fonts.Bold,
		TextSize = 11,
		Text = options.Text or "",
		LayoutOrder = 2,
		Parent = chip,
	})

	local api = { Instance = chip, Selected = false }
	local function paint()
		local theme = Theme.Get()
		chip.BackgroundColor3 = api.Selected and theme.Accent or theme.Field
		chip.BackgroundTransparency = api.Selected and 0.75 or 0.3
		stroke.Color = api.Selected and theme.Accent or theme.Stroke
		stroke.Transparency = api.Selected and 0.35 or 0.9
		label.TextColor3 = api.Selected and theme.Text or theme.SubText
	end
	function api:SetSelected(selected)
		self.Selected = selected
		paint()
	end
	paint()
	Theme.OnChange(function()
		if chip.Parent then
			paint()
		end
	end)

	chip.MouseButton1Click:Connect(function()
		Utility.SafeCall(options.Callback)
	end)
	return api
end

return Parts
