--[[
	KeySystem/Widgets
	Small building blocks used by the key screen: tinted icons, a spinner,
	buttons (primary / tinted / link) and a remember-me checkbox.
	Everything is plain Instance.new via Utility.Create.

	Each builder returns a table with .Instance plus a few setters.
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local Widgets = {}

---------------------------------------------------------------- icon
-- Widgets.Icon(parent, "lock", 18, Color3 | "ThemeKey")
function Widgets.Icon(parent, source, size, color, properties)
	local image = Create("ImageLabel", {
		Size = UDim2.fromOffset(size or 16, size or 16),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
	for key, value in pairs(properties or {}) do
		image[key] = value
	end
	if type(color) == "string" then
		Theme.Bind(image, { ImageColor3 = color })
	elseif color then
		image.ImageColor3 = color
	end
	Assets.Apply(image, source)
	return image
end

---------------------------------------------------------------- spinner
-- A ring whose gradient rotates; returns { Instance, SetActive(bool), Destroy() }
function Widgets.Spinner(parent, size, color)
	local ring = Create("Frame", {
		Size = UDim2.fromOffset(size or 16, size or 16),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = parent,
	}, { Corner(999) })
	local stroke = Create("UIStroke", {
		Thickness = 2.5,
		Color = color or Color3.new(1, 1, 1),
		Parent = ring,
	})
	local gradient = Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.55, 0.15),
			NumberSequenceKeypoint.new(0.56, 0.8),
			NumberSequenceKeypoint.new(1, 0.8),
		}),
		Parent = stroke,
	})

	local spinner = { Instance = ring }
	local connection

	function spinner:SetActive(active)
		ring.Visible = active
		if active and not connection then
			connection = Services.RunService.Heartbeat:Connect(function(dt)
				gradient.Rotation = (gradient.Rotation + 420 * dt) % 360
			end)
		elseif not active and connection then
			connection:Disconnect()
			connection = nil
		end
	end

	function spinner:Destroy()
		self:SetActive(false)
		ring:Destroy()
	end

	return spinner
end

---------------------------------------------------------------- button
--[[
	Widgets.Button(parent, {
		Text, Icon, TrailingIcon, Height = 44,
		Style = "Primary" | "Tinted" | "Link",
		Color = Color3 (Tinted / Link accent; Primary uses theme Accent),
		LayoutOrder, Callback,
	}) -> { Instance, SetText, SetBusy, SetEnabled, Busy }
]]
function Widgets.Button(parent, options)
	local style = options.Style or "Primary"
	local isLink = style == "Link"
	local height = options.Height or (isLink and 24 or 44)

	local button = Create("TextButton", {
		Size = isLink and UDim2.fromOffset(0, height) or UDim2.new(1, 0, 0, height),
		AutomaticSize = isLink and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
		BackgroundTransparency = isLink and 1 or 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = options.LayoutOrder or 0,
		ClipsDescendants = not isLink,
		Parent = parent,
	}, {
		Corner(isLink and 6 or 11),
		Utility.Padding(0, 0, isLink and 6 or 12, isLink and 6 or 12),
		Utility.List(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})
	local scale = Create("UIScale", { Parent = button })

	local accent = options.Color
	local stroke
	if style == "Primary" then
		Theme.Bind(button, { BackgroundColor3 = "Accent" })
	elseif style == "Tinted" then
		button.BackgroundColor3 = accent
		button.BackgroundTransparency = 0.86
		stroke = Create("UIStroke", {
			Color = accent,
			Transparency = 0.55,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = button,
		})
	end

	local spinner = Widgets.Spinner(button, 16)
	spinner.Instance.LayoutOrder = 1

	local icon
	if options.Icon then
		icon = Widgets.Icon(button, options.Icon, isLink and 13 or 16, accent or Color3.new(1, 1, 1), { LayoutOrder = 2 })
	end

	local label = Create("TextLabel", {
		Size = UDim2.fromOffset(0, height),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = isLink and Fonts.Medium or Fonts.Bold,
		TextSize = isLink and 12 or (style == "Primary" and 14 or 13),
		Text = options.Text or "",
		LayoutOrder = 3,
		Parent = button,
	})
	if style == "Primary" then
		label.TextColor3 = Color3.new(1, 1, 1)
	elseif style == "Tinted" then
		label.TextColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.72)
	else
		Theme.Bind(label, { TextColor3 = "SubText" })
	end

	local trailing
	if options.TrailingIcon then
		trailing = Widgets.Icon(button, options.TrailingIcon, 15, Color3.new(1, 1, 1), { LayoutOrder = 4 })
	end

	local api = { Instance = button, Label = label, Busy = false, Enabled = true }

	button.MouseEnter:Connect(function()
		if isLink then
			Tween(label, { TextColor3 = Theme.Get().Text }, 0.15)
		elseif style == "Primary" then
			Tween(button, { BackgroundColor3 = Theme.Get().Accent:Lerp(Color3.new(1, 1, 1), 0.12) }, 0.15)
		else
			Tween(button, { BackgroundTransparency = 0.78 }, 0.15)
		end
	end)
	button.MouseLeave:Connect(function()
		if isLink then
			Tween(label, { TextColor3 = Theme.Get().SubText }, 0.15)
		elseif style == "Primary" then
			Tween(button, { BackgroundColor3 = Theme.Get().Accent }, 0.15)
		else
			Tween(button, { BackgroundTransparency = 0.86 }, 0.15)
		end
	end)

	button.InputBegan:Connect(function(input)
		if Utility.IsClick(input) and api.Enabled and not api.Busy and not isLink then
			Builders.Ripple(button, input.Position)
		end
	end)
	button.MouseButton1Click:Connect(function()
		if not api.Enabled or api.Busy then
			return
		end
		Builders.Press(scale)
		Utility.SafeCall(options.Callback)
	end)

	function api:SetText(text)
		label.Text = text
	end

	function api:SetBusy(busy, text)
		self.Busy = busy
		spinner:SetActive(busy)
		if trailing then
			trailing.Visible = not busy
		end
		if icon then
			icon.Visible = not busy
		end
		if text then
			label.Text = text
		end
		if style == "Primary" then
			Tween(button, { BackgroundTransparency = busy and 0.3 or 0 }, 0.2)
		end
	end

	function api:SetEnabled(enabled)
		self.Enabled = enabled
		label.TextTransparency = enabled and 0 or 0.5
	end

	function api:Destroy()
		spinner:Destroy()
		button:Destroy()
	end

	return api
end

---------------------------------------------------------------- checkbox
-- Widgets.Checkbox(parent, "Remember key", true, function(state) end) -> { Instance, Get, Set }
function Widgets.Checkbox(parent, text, default, callback, layoutOrder)
	local row = Create("TextButton", {
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = layoutOrder or 0,
		Parent = parent,
	}, { Utility.List(9, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	local box = Create("Frame", {
		Size = UDim2.fromOffset(17, 17),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = row,
	}, { Corner(5) })
	local boxStroke = Create("UIStroke", { Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = box })
	local mark = Widgets.Icon(box, "check", 11, Color3.new(1, 1, 1), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})

	Builders.Label({
		Text = text,
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = row,
	})

	local api = { Instance = row, Value = default ~= false }

	local function paint(instant)
		local t = instant and 0 or 0.15
		local theme = Theme.Get()
		Tween(box, {
			BackgroundColor3 = api.Value and theme.Accent or theme.Field,
			BackgroundTransparency = api.Value and 0 or 0.4,
		}, t)
		Tween(boxStroke, { Color = api.Value and theme.Accent or theme.SubText, Transparency = api.Value and 0 or 0.4 }, t)
		Tween(mark, { ImageTransparency = api.Value and 0 or 1 }, t)
	end
	paint(true)
	Theme.OnChange(function()
		if row.Parent then
			paint(true)
		end
	end)

	function api:Set(value)
		self.Value = value and true or false
		paint()
		Utility.SafeCall(callback, self.Value)
	end

	function api:Get()
		return self.Value
	end

	row.MouseButton1Click:Connect(function()
		api:Set(not api.Value)
	end)

	return api
end

return Widgets
