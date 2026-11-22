--[[
	Components/ColorPicker
	Swatch chip that expands inline into a saturation/value square,
	hue bar, optional transparency bar, hex input and preset swatches.

	local picker = Tab:ColorPicker({
		Title        = "ESP Color",
		Default      = Color3.fromRGB(124, 92, 255),
		Transparency = 0,          -- optional: shows a transparency bar (0-1)
		Presets      = { Color3.fromRGB(239, 68, 68), ... }, -- optional
		Flag         = "EspColor",
		Callback     = function(color, transparency) end,
	})
	picker:Set(Color3.new(1, 0, 0), 0.5) / picker:Get() -> color, transparency
	picker:Open() / picker:Close()
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

local HEADER = 42
local SQUARE_HEIGHT = 120
local BAR_HEIGHT = 12
local ROW_HEIGHT = 26
local GAP = 8

local DEFAULT_PRESETS = {
	Color3.fromRGB(239, 68, 68),
	Color3.fromRGB(249, 115, 22),
	Color3.fromRGB(234, 179, 8),
	Color3.fromRGB(34, 197, 94),
	Color3.fromRGB(59, 130, 246),
	Color3.fromRGB(124, 92, 255),
	Color3.fromRGB(236, 72, 153),
	Color3.fromRGB(255, 255, 255),
}

local function rainbow()
	local points = {}
	for i = 0, 6 do
		table.insert(points, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((i / 6) % 1, 1, 1)))
	end
	return ColorSequence.new(points)
end

-- Small round/thin cursor with a white ring
local function cursor(parent, size, round)
	local frame = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = size,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = parent,
	}, { Utility.Corner(round and 999 or 2) })
	Create("UIStroke", {
		Thickness = 2,
		Color = Color3.new(1, 1, 1),
		Parent = frame,
	})
	return frame
end

return function(tab, options)
	options = options or {}
	local hasAlpha = options.Transparency ~= nil
	local presets = options.Presets or DEFAULT_PRESETS

	local contentHeight = SQUARE_HEIGHT + GAP + BAR_HEIGHT + GAP + (hasAlpha and (BAR_HEIGHT + GAP) or 0) + ROW_HEIGHT
	local openHeight = HEADER + contentHeight + 12

	local element = Element.new(tab, options, {
		Height = HEADER,
		Auto = false,
		Clip = true,
		RightSize = UDim.new(0, 52),
	})
	local holder = element.Instance
	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 64), 0, HEADER)
	element.DescLabel.Visible = false

	-- State (HSV is the source of truth so hue survives grey colors)
	local initial = options.Default or options.Value or Color3.fromRGB(124, 92, 255)
	local hue, sat, val = initial:ToHSV()
	local alpha = math.clamp(options.Transparency or 0, 0, 1)
	element.Value = initial
	element.Transparency = alpha

	-- Header -----------------------------------------------------------------
	local header = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, HEADER),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
		Parent = holder,
	})

	local chip = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0, HEADER / 2),
		Size = UDim2.fromOffset(40, 22),
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(6) })
	local chipStroke = Builders.Stroke(0.7)
	chipStroke.Parent = chip

	-- Content --------------------------------------------------------------
	local content = Create("Frame", {
		Position = UDim2.fromOffset(12, HEADER),
		Size = UDim2.new(1, -24, 0, contentHeight),
		BackgroundTransparency = 1,
		Parent = holder,
	}, { Utility.List(GAP) })

	-- Saturation / value square
	local square = Create("Frame", {
		Size = UDim2.new(1, 0, 0, SQUARE_HEIGHT),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = content,
	}, { Utility.Corner(6) })

	local whiteLayer = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = square,
	}, {
		Utility.Corner(6),
		Create("UIGradient", { Transparency = NumberSequence.new(0, 1) }),
	})

	Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = whiteLayer,
	}, {
		Utility.Corner(6),
		Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }),
	})

	local squareCursor = cursor(square, UDim2.fromOffset(10, 10), true)

	-- Hue bar
	local hueBar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = content,
	}, {
		Utility.Corner(999),
		Create("UIGradient", { Color = rainbow() }),
	})
	local hueCursor = cursor(hueBar, UDim2.fromOffset(4, BAR_HEIGHT + 4), false)
	hueCursor.Position = UDim2.fromScale(0, 0.5)

	-- Transparency bar (optional)
	local alphaBar, alphaCursor
	if hasAlpha then
		alphaBar = Create("Frame", {
			Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
			BorderSizePixel = 0,
			LayoutOrder = 3,
			Parent = content,
		}, {
			Utility.Corner(999),
			Create("UIGradient", { Transparency = NumberSequence.new(0, 0.9) }),
		})
		Builders.Stroke(0.85).Parent = alphaBar
		alphaCursor = cursor(alphaBar, UDim2.fromOffset(4, BAR_HEIGHT + 4), false)
	end

	-- Hex input + presets
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = content,
	}, { Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	local hexBox = Create("TextBox", {
		Size = UDim2.fromOffset(84, ROW_HEIGHT),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Text = "",
		LayoutOrder = 0,
		Parent = row,
	}, { Utility.Corner(6) })
	Theme.Bind(hexBox, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	local hexStroke = Builders.Stroke()
	hexStroke.Parent = hexBox

	-- Rendering ----------------------------------------------------------------
	local function render()
		local color = Color3.fromHSV(hue, sat, val)
		element.Value = color
		element.Transparency = alpha

		chip.BackgroundColor3 = color
		chip.BackgroundTransparency = alpha
		square.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		squareCursor.Position = UDim2.fromScale(sat, 1 - val)
		hueCursor.Position = UDim2.fromScale(hue, 0.5)
		if alphaBar then
			alphaBar.BackgroundColor3 = color
			alphaCursor.Position = UDim2.fromScale(alpha, 0.5)
		end
		if not hexBox:IsFocused() then
			hexBox.Text = "#" .. string.upper(color:ToHex())
		end
	end

	local function changed()
		render()
		Utility.SafeCall(options.Callback, element.Value, element.Transparency)
	end

	for index, preset in ipairs(presets) do
		local swatch = Create("TextButton", {
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = preset,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			Parent = row,
		}, { Utility.Corner(5) })
		Builders.Stroke(0.8).Parent = swatch
		local swatchScale = Create("UIScale", { Parent = swatch })

		swatch.MouseEnter:Connect(function()
			Tween(swatchScale, { Scale = 1.15 }, 0.12)
		end)
		swatch.MouseLeave:Connect(function()
			Tween(swatchScale, { Scale = 1 }, 0.12)
		end)
		swatch.MouseButton1Click:Connect(function()
			hue, sat, val = preset:ToHSV()
			changed()
		end)
	end

	-- Dragging -------------------------------------------------------------
	local active -- "square" | "hue" | "alpha"

	local function relative(frame, position)
		local x = math.clamp((position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1)
		local y = math.clamp((position.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y, 0, 1)
		return x, y
	end

	local function update(position)
		if active == "square" then
			local x, y = relative(square, position)
			sat, val = x, 1 - y
		elseif active == "hue" then
			hue = relative(hueBar, position)
			hue = math.min(hue, 0.999)
		elseif active == "alpha" then
			alpha = relative(alphaBar, position)
		end
		changed()
	end

	local function bindDrag(frame, name)
		Utility.Track(frame.InputBegan:Connect(function(input)
			if Utility.IsClick(input) then
				active = name
				update(input.Position)
			end
		end))
	end
	bindDrag(square, "square")
	bindDrag(hueBar, "hue")
	if alphaBar then
		bindDrag(alphaBar, "alpha")
	end

	Utility.Track(UserInputService.InputChanged:Connect(function(input)
		if active and Utility.IsMove(input) then
			update(input.Position)
		end
	end))

	Utility.Track(UserInputService.InputEnded:Connect(function(input)
		if active and Utility.IsClick(input) then
			active = nil
		end
	end))

	-- Hex input ------------------------------------------------------------
	hexBox.Focused:Connect(function()
		Tween(hexStroke, { Color = State.Theme.Accent, Transparency = 0.2 }, 0.15)
	end)

	hexBox.FocusLost:Connect(function()
		Tween(hexStroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.15)
		local hex = string.gsub(hexBox.Text, "[^%x]", "")
		if #hex == 3 then
			hex = string.gsub(hex, "%x", "%0%0")
		end
		local ok, color = pcall(Color3.fromHex, hex)
		if ok and #hex == 6 then
			hue, sat, val = color:ToHSV()
			changed()
		else
			render()
		end
	end)

	-- Open / close ----------------------------------------------------------
	local opened = false

	local function setOpen(state)
		opened = state
		Tween(holder, { Size = UDim2.new(1, 0, 0, opened and openHeight or HEADER) }, 0.3)
		Tween(chipStroke, {
			Color = opened and State.Theme.Accent or State.Theme.Stroke,
			Transparency = opened and 0.2 or 0.7,
		}, 0.2)
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not opened)
	end)
	header.MouseEnter:Connect(function()
		Tween(holder, { BackgroundColor3 = State.Theme.ElementHover }, 0.18)
	end)
	header.MouseLeave:Connect(function()
		Tween(holder, { BackgroundColor3 = State.Theme.Element }, 0.18)
	end)

	-- API ------------------------------------------------------------------
	function element:Set(color, transparency, silent)
		if typeof(color) == "Color3" then
			hue, sat, val = color:ToHSV()
		end
		if type(transparency) == "number" then
			alpha = math.clamp(transparency, 0, 1)
		end
		render()
		if not silent then
			Utility.SafeCall(options.Callback, element.Value, element.Transparency)
		end
	end

	function element:Get()
		return element.Value, element.Transparency
	end

	function element:Open()
		setOpen(true)
	end

	function element:Close()
		setOpen(false)
	end

	render()
	Element.RegisterFlag(options, element)
	return element
end
