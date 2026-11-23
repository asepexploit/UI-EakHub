--[[
	EakUI v1.10.0
	Built 2026-11-23 07:46 UTC from 73 modules — do not edit by hand.
	Source: src/  |  Build: python tools/build.py
]]

local __modules = {}
local __cache = {}

local function import(name)
	local cached = __cache[name]
	if cached ~= nil then
		return cached
	end
	local loader = __modules[name]
	if not loader then
		error("[EakUI] module not found: " .. tostring(name), 2)
	end
	local result = loader(import)
	if result == nil then
		result = true
	end
	__cache[name] = result
	return result
end

__modules["Components/Button"] = function(...)
--[[
	Components/Button

	Tab:Button({
		Title    = "Click Me",
		Desc     = "optional",
		Color    = Color3.fromRGB(190, 40, 60), -- optional custom background
		Callback = function() end,
	})
]]

local import = ...
local Utility = import("Core/Utility")
local Builders = import("Core/Builders")
local Element = import("Components/Element")

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Button = true,
		Hover = true,
		Auto = false,
		RightSize = UDim.new(0, 20),
	})
	local holder = element.Instance

	local arrow = Builders.Chevron(holder, "right", options.Color and "Text" or "SubText")
	arrow.Holder.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Holder.Position = UDim2.new(1, -14, 0.5, 0)

	Utility.Track(holder.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			Builders.Ripple(holder, input.Position)
		end
	end))

	holder.MouseButton1Click:Connect(function()
		Builders.Press(element.Scale)
		Utility.SafeCall(options.Callback)
	end)

	function element:Fire()
		Utility.SafeCall(options.Callback)
	end

	function element:SetCallback(callback)
		options.Callback = callback
	end

	return element
end
end

__modules["Components/ButtonGroup"] = function(...)
--[[
	Components/ButtonGroup
	One row of 2-4 equal-width buttons.

	local group = Tab:ButtonGroup({
		Buttons = {
			{ Title = "Save", Variant = "Primary", Callback = function() end },
			{ Title = "Load", Callback = function() end },          -- Secondary (default)
			{ Title = "Reset", Variant = "Danger", Callback = function() end },
		},
	})
	group:SetButtonText(1, "Saved!")
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local HEIGHT = 34
local GAP = 6

local function createButton(parent, spec, count, index)
	local variant = spec.Variant or "Secondary"
	local button = Create("TextButton", {
		Name = spec.Title or ("Button" .. index),
		Size = UDim2.new(1 / count, -(GAP * (count - 1)) / count, 1, 0),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Font = Constants.Fonts.Medium,
		TextSize = 13,
		Text = spec.Title or "Button",
		LayoutOrder = index,
		Parent = parent,
	}, { Utility.Corner(8) })

	local baseTransparency
	if variant == "Primary" then
		Theme.Bind(button, { BackgroundColor3 = "Accent" })
		button.TextColor3 = Color3.new(1, 1, 1)
		baseTransparency = 0
	elseif variant == "Danger" then
		button.BackgroundColor3 = Constants.Danger
		button.TextColor3 = Color3.new(1, 1, 1)
		baseTransparency = 0
	else
		Theme.Bind(button, { BackgroundColor3 = "Element", TextColor3 = "Text" })
		Builders.Stroke().Parent = button
		baseTransparency = Constants.Glass.Element
	end
	button.BackgroundTransparency = baseTransparency

	local scale = Create("UIScale", { Parent = button })

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = math.min(baseTransparency + 0.12, 1) }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = baseTransparency }, 0.15)
	end)
	Utility.Track(button.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			Builders.Ripple(button, input.Position)
		end
	end))
	button.MouseButton1Click:Connect(function()
		Builders.Press(scale)
		Utility.SafeCall(spec.Callback)
	end)

	return button
end

return function(tab, options)
	options = options or {}
	local specs = options.Buttons or {}
	local count = math.clamp(#specs, 1, 4)

	local holder = Create("Frame", {
		Name = "ButtonGroup",
		Size = UDim2.new(1, 0, 0, HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.List(GAP, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
	})

	local buttons = {}
	for index = 1, count do
		buttons[index] = createButton(holder, specs[index], count, index)
	end

	-- Searchable by the first button's label
	if tab._searchables and buttons[1] then
		table.insert(tab._searchables, { Instance = holder, Label = buttons[1] })
	end

	local group = { Instance = holder, Buttons = buttons }

	function group:SetButtonText(index, text)
		local button = buttons[index]
		if button then
			button.Text = text
		end
	end

	function group:SetVisible(visible)
		holder.Visible = visible
	end

	function group:Destroy()
		holder:Destroy()
	end

	return group
end
end

__modules["Components/Checkbox"] = function(...)
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
end

__modules["Components/CodeBlock"] = function(...)
--[[
	Components/CodeBlock
	Monospace, read-only text with a Copy button.

	local code = Tab:CodeBlock({
		Title = "Discord",
		Code  = "discord.gg/yourserver",
	})
	code:SetCode("new text")

	Copy uses setclipboard / toclipboard when the executor has it;
	otherwise the text is focused and selected so the user can copy it.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local function copyToClipboard(text)
	local copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
	if copy then
		return pcall(copy, text)
	end
	return false
end

return function(tab, options)
	options = options or {}

	local holder = Create("Frame", {
		Name = options.Title or "CodeBlock",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(8),
		Utility.Padding(10, 10, 12, 12),
		Utility.List(8),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	-- Header ---------------------------------------------------------------
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})

	local titleLabel = Builders.Label({
		Text = options.Title or "Code",
		Size = UDim2.new(1, -80, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	local copyButton = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Text = "Copy",
		Parent = header,
	}, { Utility.Corner(6), Utility.Padding(0, 0, 10, 10) })
	Theme.Bind(copyButton, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	local copyStroke = Builders.Stroke()
	copyStroke.Parent = copyButton

	-- Code box -------------------------------------------------------------
	local codeFrame = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = holder,
	}, { Utility.Corner(6), Utility.Padding(8, 8, 10, 10) })
	Theme.Bind(codeFrame, { BackgroundColor3 = "Field" })

	local codeBox = Create("TextBox", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		MultiLine = true,
		ClearTextOnFocus = false,
		TextEditable = false,
		Text = options.Code or "",
		Parent = codeFrame,
	})
	Theme.Bind(codeBox, { TextColor3 = "Text" })

	-- Copy -----------------------------------------------------------------
	local resetToken = 0

	copyButton.MouseEnter:Connect(function()
		Tween(copyStroke, { Transparency = 0.6 }, 0.15)
	end)
	copyButton.MouseLeave:Connect(function()
		Tween(copyStroke, { Transparency = State.Theme.StrokeAlpha }, 0.15)
	end)

	copyButton.MouseButton1Click:Connect(function()
		local copied = copyToClipboard(codeBox.Text)
		if not copied then
			-- Fallback: select everything so the user can press Ctrl+C
			codeBox:CaptureFocus()
			codeBox.SelectionStart = 1
			codeBox.CursorPosition = #codeBox.Text + 1
		end

		resetToken += 1
		local token = resetToken
		copyButton.Text = copied and "Copied!" or "Selected"
		Tween(copyButton, { TextColor3 = State.Theme.Accent }, 0.15)
		task.delay(1.5, function()
			if token == resetToken and copyButton.Parent then
				copyButton.Text = "Copy"
				Tween(copyButton, { TextColor3 = State.Theme.Text }, 0.15)
			end
		end)
	end)

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	local element = { Instance = holder, TitleLabel = titleLabel, Value = codeBox.Text }

	function element:SetCode(text)
		codeBox.Text = tostring(text or "")
		element.Value = codeBox.Text
	end

	function element:SetTitle(text)
		titleLabel.Text = text
	end

	function element:SetVisible(visible)
		holder.Visible = visible
	end

	function element:Destroy()
		holder:Destroy()
	end

	return element
end
end

__modules["Components/Collapsible"] = function(...)
--[[
	Components/Collapsible
	Card with a clickable header that expands / collapses its content.
	Returns a container: any component can be added to it.

	local combat = Tab:Collapsible({
		Title = "Combat",
		Desc  = "optional",
		Icon  = "rbxassetid://...",  -- optional (id, URL or file)
		Open  = true,                -- start expanded (default true)
		Callback = function(isOpen) end,
	})
	combat:Toggle({ Title = "Kill Aura", Callback = print })
	combat:Slider({ Title = "Range", Min = 1, Max = 20, Default = 10 })

	combat:Open() / :Close() / :SetOpen(bool) / :ToggleOpen() / :IsOpen() / :SetTitle(text)
	(:Toggle stays the normal Toggle component, like on any tab.)
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local DURATION = 0.3

return function(tab, options)
	options = options or {}
	local description = options.Desc or options.Description
	local headerHeight = description and 54 or 42
	local opened = options.Open ~= false

	---------------------------------------------------------------- card
	local holder = Create("Frame", {
		Name = options.Title or "Collapsible",
		Size = UDim2.new(1, 0, 0, headerHeight),
		AutomaticSize = opened and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(10) })
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	---------------------------------------------------------------- header
	local header = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, headerHeight),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	})

	local textX = 12
	if options.Icon then
		local icon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = header,
		})
		Assets.Apply(icon, options.Icon)
		if options.IconTint ~= false then
			Theme.Bind(icon, { ImageColor3 = "Accent" })
		end
		textX = 40
	end

	local textGroup = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, textX, 0.5, 0),
		Size = UDim2.new(1, -(textX + 40), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = header,
	}, { Utility.List(3) })

	local title = Builders.Label({
		Text = options.Title or "Section",
		Font = Constants.Fonts.Bold,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = textGroup,
	})

	if description then
		Builders.Label({
			Text = description,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			Size = UDim2.new(1, 0, 0, 15),
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 2,
			Parent = textGroup,
		})
	end

	local chevron = Builders.Chevron(header, opened and "up" or "down", "SubText")
	chevron.Holder.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Holder.Position = UDim2.new(1, -16, 0.5, 0)

	local divider = Create("Frame", {
		Position = UDim2.new(0, 12, 0, headerHeight - 1),
		Size = UDim2.new(1, -24, 0, 1),
		BackgroundTransparency = opened and 0.93 or 1,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

	---------------------------------------------------------------- body
	local body = Create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, headerHeight),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = holder,
	}, {
		Utility.List(6),
		Utility.Padding(10, 10, 10, 10),
	})

	header.MouseEnter:Connect(function()
		Tween(holder, { BackgroundTransparency = Constants.Glass.Element - 0.1 }, 0.15)
	end)
	header.MouseLeave:Connect(function()
		Tween(holder, { BackgroundTransparency = Constants.Glass.Element }, 0.15)
	end)

	---------------------------------------------------------------- open / close
	-- Absolute sizes include the window's UIScale; convert back to offsets.
	local function scaleFactor()
		local measured = header.AbsoluteSize.Y
		return measured > 0 and measured / headerHeight or 1
	end

	local animationId = 0

	local function setOpen(state, instant)
		opened = state
		animationId += 1
		local currentAnimation = animationId
		local factor = scaleFactor()
		local current = holder.AbsoluteSize.Y / factor
		local target = state and (headerHeight + body.AbsoluteSize.Y / factor) or headerHeight
		local duration = instant and 0 or DURATION

		-- Animate with a fixed height, then hand back to AutomaticSize when open
		holder.AutomaticSize = Enum.AutomaticSize.None
		holder.Size = UDim2.new(1, 0, 0, current)
		Tween(holder, { Size = UDim2.new(1, 0, 0, target) }, duration)
		Tween(divider, { BackgroundTransparency = state and 0.93 or 1 }, duration)
		chevron:Set(state and "up" or "down", instant)

		task.delay(duration, function()
			if currentAnimation ~= animationId or not holder.Parent then
				return
			end
			if opened then
				holder.Size = UDim2.new(1, 0, 0, headerHeight)
				holder.AutomaticSize = Enum.AutomaticSize.Y -- follows children added later
			end
		end)

		Utility.SafeCall(options.Callback, opened)
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not opened)
	end)

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	---------------------------------------------------------------- container API
	local container = tab:_Child(body)
	container.Instance = holder
	container.Body = body

	function container:Open()
		if not opened then
			setOpen(true)
		end
	end

	function container:Close()
		if opened then
			setOpen(false)
		end
	end

	function container:SetOpen(state)
		setOpen(state and true or false)
	end

	function container:ToggleOpen()
		setOpen(not opened)
	end

	function container:IsOpen()
		return opened
	end

	function container:SetTitle(text)
		title.Text = text
	end

	function container:Destroy()
		holder:Destroy()
	end

	return container
end
end

__modules["Components/ColorPicker"] = function(...)
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
end

__modules["Components/Divider"] = function(...)
--[[
	Components/Divider
	Thin horizontal separator between groups of elements.

	Tab:Divider()
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")

local Create = Utility.Create

return function(tab)
	local holder = Create("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, 9),
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	})

	local line = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.new(1, -8, 0, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Theme.Bind(line, { BackgroundColor3 = "Stroke" })

	if tab._sections then
		table.insert(tab._sections, holder)
	end

	local divider = { Instance = holder }

	function divider:Destroy()
		holder:Destroy()
	end

	return divider
end
end

__modules["Components/Dropdown"] = function(...)
--[[
	Components/Dropdown

	local dropdown = Tab:Dropdown({
		Title         = "Weapon",
		Values        = { "Sword", "Bow" },
		Value         = "Sword",        -- table when Multi = true
		Multi         = false,
		MaxVisible    = 5,              -- rows visible before scrolling
		Search        = nil,            -- true/false; auto-on for lists longer than 8
		Placeholder   = "Select...",
		CloseOnSelect = true,
		Flag          = "Weapon",
		Callback      = function(value) end,
	})
	dropdown:Set(v) / :Get() / :Refresh(newValues, keepValue) / :Open() / :Close()
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local HEADER_HEIGHT = 42
local OPTION_HEIGHT = 28
local OPTION_GAP = 2
local SEARCH_HEIGHT = 26
local SEARCH_THRESHOLD = 8 -- lists longer than this get a search box

return function(tab, options)
	options = options or {}
	local values = options.Values or options.Options or {}
	local multi = options.Multi or false
	local maxVisible = options.MaxVisible or 5

	local element = Element.new(tab, options, {
		Height = HEADER_HEIGHT,
		Auto = false,
		Clip = true,
		RightSize = UDim.new(0.45, 0),
	})
	local holder = element.Instance
	element.TextHolder.Size = UDim2.new(0.55, -(element.TextHolder.Position.X.Offset + 12), 0, HEADER_HEIGHT)
	element.DescLabel.Visible = false

	local initial = options.Value or options.Default
	if multi then
		element.Value = type(initial) == "table" and initial or {}
	else
		element.Value = initial
	end

	-- Header ---------------------------------------------------------------
	local header = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
		Parent = holder,
	})

	local display = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, HEADER_HEIGHT / 2),
		Size = UDim2.new(0.45, 0, 0, 28),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(display, { BackgroundColor3 = "Field" })
	local displayStroke = Builders.Stroke()
	displayStroke.Parent = display

	local displayLabel = Builders.Label({
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -34, 1, 0),
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = display,
	})

	local chevron = Builders.Chevron(display, "down", "SubText")
	chevron.Holder.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Holder.Position = UDim2.new(1, -8, 0.5, 0)

	-- Search (auto-enabled for long lists) --------------------------------
	local searchFrame = Create("Frame", {
		Position = UDim2.fromOffset(8, HEADER_HEIGHT),
		Size = UDim2.new(1, -16, 0, SEARCH_HEIGHT),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Visible = false,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(searchFrame, { BackgroundColor3 = "Field" })
	Builders.Stroke().Parent = searchFrame

	local searchBox = Create("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		PlaceholderText = "Search...",
		Text = "",
		Parent = searchFrame,
	})
	Theme.Bind(searchBox, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	-- Option list ----------------------------------------------------------
	local list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(8, HEADER_HEIGHT),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = holder,
	}, { Utility.List(OPTION_GAP), Utility.Padding(0, 0, 0, 4) })
	Theme.Bind(list, { ScrollBarImageColor3 = "Accent" })

	local opened = false
	local optionRows = {} -- [value] = { Instance, Label, Marker }

	local function isSelected(value)
		if multi then
			return table.find(element.Value, value) ~= nil
		end
		return element.Value == value
	end

	local function updateDisplay()
		if multi then
			displayLabel.Text = #element.Value > 0 and table.concat(element.Value, ", ")
				or (options.Placeholder or "None")
		else
			displayLabel.Text = element.Value ~= nil and tostring(element.Value) or (options.Placeholder or "Select...")
		end

		local theme = State.Theme
		for value, row in pairs(optionRows) do
			local selected = isSelected(value)
			Tween(row.Instance, { BackgroundTransparency = selected and 0.82 or 1 }, 0.15)
			Tween(row.Label, { TextColor3 = selected and theme.Text or theme.SubText }, 0.15)
			Tween(row.Marker, { BackgroundTransparency = selected and 0 or 1 }, 0.15)
		end
	end

	local function isSearchable()
		if options.Search ~= nil then
			return options.Search == true
		end
		return #values > SEARCH_THRESHOLD
	end

	local function searchOffset()
		return isSearchable() and (SEARCH_HEIGHT + 4) or 0
	end

	local function visibleCount()
		local count = 0
		for _, row in pairs(optionRows) do
			if row.Instance.Visible then
				count += 1
			end
		end
		return count
	end

	local function listHeight()
		return math.min(visibleCount(), maxVisible) * (OPTION_HEIGHT + OPTION_GAP)
	end

	local function applyFilter()
		local query = string.lower(searchBox.Text)
		for value, row in pairs(optionRows) do
			row.Instance.Visible = query == "" or string.find(string.lower(tostring(value)), query, 1, true) ~= nil
		end
	end

	local function setOpen(state)
		opened = state
		local height = listHeight()
		local offset = searchOffset()
		list.Position = UDim2.fromOffset(8, HEADER_HEIGHT + offset)
		list.Size = UDim2.new(1, -16, 0, height)
		local openHeight = HEADER_HEIGHT + offset + height + 8
		Tween(holder, { Size = UDim2.new(1, 0, 0, opened and openHeight or HEADER_HEIGHT) }, 0.3)
		chevron:Set(opened and "up" or "down")
		Tween(displayStroke, {
			Color = opened and State.Theme.Accent or State.Theme.Stroke,
			Transparency = opened and 0.3 or State.Theme.StrokeAlpha,
		}, 0.2)
	end

	local function choose(value)
		if multi then
			local index = table.find(element.Value, value)
			if index then
				table.remove(element.Value, index)
			else
				table.insert(element.Value, value)
			end
		else
			element.Value = value
			if options.CloseOnSelect ~= false then
				setOpen(false)
			end
		end
		updateDisplay()
		Utility.SafeCall(options.Callback, element.Value)
	end

	local function createRow(index, value)
		local row = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			Parent = list,
		}, { Utility.Corner(6) })
		Theme.Bind(row, { BackgroundColor3 = "Accent" })

		local marker = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(4, 14),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = row,
		}, { Utility.Corner(2) })
		Theme.Bind(marker, { BackgroundColor3 = "Accent" })

		local label = Builders.Label({
			Text = tostring(value),
			Position = UDim2.fromOffset(20, 0),
			Size = UDim2.new(1, -28, 1, 0),
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})

		row.MouseEnter:Connect(function()
			if not isSelected(value) then
				Tween(row, { BackgroundTransparency = 0.93 }, 0.12)
			end
		end)
		row.MouseLeave:Connect(function()
			if not isSelected(value) then
				Tween(row, { BackgroundTransparency = 1 }, 0.12)
			end
		end)
		row.MouseButton1Click:Connect(function()
			choose(value)
		end)

		optionRows[value] = { Instance = row, Label = label, Marker = marker }
	end

	local function build()
		for _, row in pairs(optionRows) do
			row.Instance:Destroy()
		end
		table.clear(optionRows)

		for index, value in ipairs(values) do
			createRow(index, value)
		end

		searchFrame.Visible = isSearchable()
		applyFilter()
		updateDisplay()
		if opened then
			setOpen(true)
		end
	end

	-- Events ---------------------------------------------------------------
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		applyFilter()
		if opened then
			setOpen(true)
		end
	end)

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
	function element:Set(value, silent)
		if multi then
			element.Value = type(value) == "table" and value or { value }
		else
			element.Value = value
		end
		updateDisplay()
		if not silent then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:Refresh(newValues, keepValue)
		values = newValues or {}
		if not keepValue then
			element.Value = multi and {} or nil
		end
		build()
	end

	function element:Open()
		setOpen(true)
	end

	function element:Close()
		setOpen(false)
	end

	Theme.OnChange(updateDisplay)
	build()
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Element"] = function(...)
--[[
	Components/Element
	Shared base for every tab element: rounded glass card, stroke,
	title + optional description, hover state and common methods.

	Element.new(tab, options, config) -> element
	config:
		Button    : boolean  -- use a TextButton (clickable card)
		Hover     : boolean  -- hover highlight
		Height    : number   -- minimum height (default 42)
		Auto      : boolean  -- grow with text (default true)
		Clip      : boolean  -- ClipsDescendants
		RightSize : UDim     -- width reserved for the control on the right
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")
local Tooltip = import("Core/Tooltip")
local Badge = import("Core/Badge")

local Create, Tween = Utility.Create, Utility.Tween

local Element = {}

function Element.new(tab, options, config)
	config = config or {}
	local rightSize = config.RightSize or UDim.new(0, 0)
	local height = config.Height or 42
	local autoSize = config.Auto ~= false and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
	local customColor = options.Color

	local holder = Create(config.Button and "TextButton" or "Frame", {
		Name = options.Title or "Element",
		Size = UDim2.new(1, 0, 0, height),
		AutomaticSize = autoSize,
		BackgroundTransparency = customColor and 0.1 or Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = config.Clip or config.Button or false,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(8) })

	if config.Button then
		holder.Text = ""
		holder.AutoButtonColor = false
	end

	if customColor then
		holder.BackgroundColor3 = customColor
	else
		Theme.Bind(holder, { BackgroundColor3 = "Element" })
	end

	local stroke = Builders.Stroke()
	stroke.Parent = holder
	local scale = Create("UIScale", { Parent = holder })

	-- Optional left icon: Icon is tinted to match text, Image keeps its colors
	local iconSource = options.Icon or options.Image
	local textX = 12
	local iconLabel
	if iconSource then
		local iconSize = options.IconSize or (options.Image and 32 or 18)
		iconLabel = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = holder,
		}, { Utility.Corner(options.Image and 6 or 0) })
		Assets.Apply(iconLabel, iconSource)
		if options.Icon and options.IconTint ~= false then
			Theme.Bind(iconLabel, { ImageColor3 = "SubText" })
		end
		textX = 12 + iconSize + 10
	end

	local textHolder = Create("Frame", {
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1 - rightSize.Scale, -(textX + 12 + rightSize.Offset), 0, height),
		AutomaticSize = autoSize,
		BackgroundTransparency = 1,
		Parent = holder,
	}, {
		Utility.List(3, nil, nil, Enum.VerticalAlignment.Center),
		Utility.Padding(10, 10, 0, 0),
	})

	local description = options.Desc or options.Description

	-- With a Badge the title sits in a row next to the pill (single line);
	-- without one it wraps freely.
	local titleParent = textHolder
	if options.Badge then
		titleParent = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Parent = textHolder,
		}, { Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	end

	local title = Builders.Label({
		Text = options.Title or "Element",
		Size = options.Badge and UDim2.fromOffset(0, 16) or UDim2.new(1, 0, 0, 0),
		AutomaticSize = options.Badge and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
		TextWrapped = not options.Badge,
		RichText = true,
		LayoutOrder = 1,
		Parent = titleParent,
	})

	local badge
	if options.Badge then
		badge = Badge.new(titleParent, options.Badge)
		badge.Instance.LayoutOrder = 2
	end

	local desc = Builders.Label({
		Text = description or "",
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		RichText = true,
		Visible = description ~= nil,
		LayoutOrder = 2,
		Parent = textHolder,
	})

	if config.Hover then
		holder.MouseEnter:Connect(function()
			local target = customColor and customColor:Lerp(Color3.new(1, 1, 1), 0.1) or State.Theme.ElementHover
			Tween(holder, { BackgroundColor3 = target }, 0.18)
			Tween(stroke, { Transparency = State.Theme.StrokeAlpha - 0.08 }, 0.18)
		end)
		holder.MouseLeave:Connect(function()
			Tween(holder, { BackgroundColor3 = customColor or State.Theme.Element }, 0.18)
			Tween(stroke, { Transparency = State.Theme.StrokeAlpha }, 0.18)
		end)
	end

	-- Make the element discoverable by the sidebar search
	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	local tooltip = options.Tooltip and Tooltip.Attach(holder, options.Tooltip)

	local element = {
		Instance = holder,
		TitleLabel = title,
		DescLabel = desc,
		TextHolder = textHolder,
		IconLabel = iconLabel,
		Stroke = stroke,
		Scale = scale,
	}

	function element:SetTitle(text)
		title.Text = text
	end

	function element:SetDesc(text)
		desc.Text = text or ""
		desc.Visible = text ~= nil and text ~= ""
	end

	-- Badge = "NEW" | "ON" | "OFF" | "BETA" | "PREMIUM" | { Text, Color }
	-- Only available when the element was created with a Badge; nil hides it.
	function element:SetBadge(value)
		if badge then
			badge:Set(value)
		end
	end

	function element:SetTooltip(text)
		if tooltip then
			tooltip:SetText(text)
		elseif text then
			tooltip = Tooltip.Attach(holder, text)
		end
	end

	function element:SetIcon(source)
		if iconLabel then
			Assets.Apply(iconLabel, source)
		end
	end

	function element:SetVisible(visible)
		holder.Visible = visible
	end

	function element:Destroy()
		holder:Destroy()
	end

	return element
end

-- Exposes an element through UI.Flags[options.Flag]
function Element.RegisterFlag(options, element)
	if options.Flag then
		State.Flags[options.Flag] = element
	end
end

return Element
end

__modules["Components/Grid"] = function(...)
--[[
	Components/Grid
	Tile picker around the player (e.g. choose farm / break spots).
	Click a tile to select it, or hold and drag to paint several.
	The center tile is the player and cannot be selected.

	local grid = Tab:Grid({
		Title          = "ANCH Grid",
		Size           = 5,                         -- odd number; 5 = 5x5
		Value          = { Vector2.new(-1, 0) },    -- offsets from the center tile
		Color          = Color3.fromRGB(34, 160, 90), -- selected tile color
		CenterLabel    = "ME",
		MaxCellSize    = 48,

		Modes          = { "Farm", "Break" },       -- optional mode chip (click to cycle)
		Mode           = "Farm",
		ModeCallback   = function(mode) end,

		ActionText     = "Start {mode}",            -- "{mode}" is replaced by the current mode
		StopText       = "Stop {mode}",
		ActionCallback = function(running, tiles, mode) end,
		ClearText      = "Clear selection",

		Flag           = "FarmGrid",
		Callback       = function(tiles) end,       -- fired when the selection changes
	})

	grid:Get() -> { Vector2 }    -- X: left(-) / right(+), Y: up(-) / down(+)
	grid:Set(tiles) / grid:Clear() / grid:SetMode(name) / grid:SetRunning(bool)
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

local GAP = 6
local DEFAULT_COLOR = Color3.fromRGB(34, 160, 90)

local function key(x, y)
	return x .. "," .. y
end

local function format(template, mode)
	return (string.gsub(template, "{mode}", mode or ""))
end

return function(tab, options)
	options = options or {}

	local size = options.Size or 5
	if size % 2 == 0 then
		size += 1 -- keep a real center tile
	end
	local radius = (size - 1) / 2
	local maxCell = options.MaxCellSize or 48
	local selectedColor = options.Color or DEFAULT_COLOR
	local modes = options.Modes
	local mode = options.Mode or (modes and modes[1]) or ""
	local running = false

	local grid = {} -- public object, filled in below
	local actionButton
	local selected = {} -- [key] = Vector2
	for _, offset in ipairs(options.Value or options.Default or {}) do
		if not (offset.X == 0 and offset.Y == 0) then
			selected[key(offset.X, offset.Y)] = offset
		end
	end

	---------------------------------------------------------------- container
	local holder = Create("Frame", {
		Name = options.Title or "Grid",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(10),
		Utility.Padding(12, 12, 12, 12),
		Utility.List(10, nil, Enum.HorizontalAlignment.Center),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	---------------------------------------------------------------- header
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})

	local title = Builders.Label({
		Text = options.Title or "Grid",
		Font = Constants.Fonts.Bold,
		TextSize = 14,
		Size = UDim2.new(1, modes and -100 or 0, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	local modeChip
	if modes then
		modeChip = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = Constants.Glass.Field,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Constants.Fonts.Bold,
			TextSize = 12,
			Text = mode,
			Parent = header,
		}, { Utility.Corner(7), Utility.Padding(0, 0, 14, 14) })
		Theme.Bind(modeChip, { BackgroundColor3 = "ElementHover", TextColor3 = "Text" })
		Builders.Stroke().Parent = modeChip
	end

	---------------------------------------------------------------- grid
	local gridFrame = Create("Frame", {
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})
	local gridLayout = Create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(GAP, GAP),
		FillDirectionMaxCells = size,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = gridFrame,
	})

	local cells = {} -- [key] = TextButton

	local function paintCell(x, y, instant)
		local cell = cells[key(x, y)]
		if not cell or (x == 0 and y == 0) then
			return
		end
		local on = selected[key(x, y)] ~= nil
		Tween(cell, {
			BackgroundColor3 = on and selectedColor or State.Theme.Field,
			BackgroundTransparency = on and 0 or 0.1,
		}, instant and 0 or 0.15)
	end

	local function getTiles()
		local list = {}
		for _, offset in pairs(selected) do
			table.insert(list, offset)
		end
		table.sort(list, function(a, b)
			return a.Y == b.Y and a.X < b.X or a.Y < b.Y
		end)
		return list
	end

	local function changed()
		grid.Value = getTiles()
		Utility.SafeCall(options.Callback, grid.Value)
	end

	local function refreshAction()
		if actionButton then
			local template = running and (options.StopText or "Stop {mode}") or (options.ActionText or "Start {mode}")
			actionButton.Text = string.upper(format(template, mode))
			Tween(actionButton, { BackgroundColor3 = running and Constants.Danger or selectedColor }, 0.2)
		end
	end

	local function setTile(x, y, on)
		if x == 0 and y == 0 then
			return false
		end
		local k = key(x, y)
		local was = selected[k] ~= nil
		if was == on then
			return false
		end
		selected[k] = on and Vector2.new(x, y) or nil
		paintCell(x, y)
		return true
	end

	-- Drag painting: the first tile decides whether we select or deselect
	local painting = false
	local paintValue = true

	local order = 0
	for y = -radius, radius do
		for x = -radius, radius do
			order += 1
			local isCenter = x == 0 and y == 0
			local cell = Create("TextButton", {
				Name = key(x, y),
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = isCenter and (options.CenterLabel or "ME") or "",
				Font = Constants.Fonts.Bold,
				TextSize = 12,
				TextColor3 = Color3.new(1, 1, 1),
				LayoutOrder = order,
				Parent = gridFrame,
			}, { Utility.Corner(6) })

			if isCenter then
				Theme.Bind(cell, { BackgroundColor3 = "Accent" })
			else
				Theme.Bind(cell, { BackgroundColor3 = "Field" })
				Builders.Stroke(0.94).Parent = cell

				Utility.Track(cell.InputBegan:Connect(function(input)
					if Utility.IsClick(input) then
						painting = true
						paintValue = selected[key(x, y)] == nil
						if setTile(x, y, paintValue) then
							changed()
						end
					end
				end))

				cell.MouseEnter:Connect(function()
					if painting then
						if setTile(x, y, paintValue) then
							changed()
						end
					elseif not selected[key(x, y)] then
						Tween(cell, { BackgroundColor3 = State.Theme.ElementHover }, 0.12)
					end
				end)

				cell.MouseLeave:Connect(function()
					if not painting then
						paintCell(x, y)
					end
				end)
			end

			cells[key(x, y)] = cell
		end
	end

	Utility.Track(UserInputService.InputEnded:Connect(function(input)
		if painting and Utility.IsClick(input) then
			painting = false
		end
	end))

	-- Square cells that fit the available width (capped by MaxCellSize)
	local function layout()
		local available = holder.AbsoluteSize.X - 24
		if available <= 0 then
			return
		end
		local cell = math.floor(math.min(maxCell, (available - GAP * (size - 1)) / size))
		local total = cell * size + GAP * (size - 1)
		gridLayout.CellSize = UDim2.fromOffset(cell, cell)
		gridFrame.Size = UDim2.fromOffset(total, total)
	end
	Utility.Track(holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
	task.defer(layout)

	---------------------------------------------------------------- action + clear
	if options.ActionText or options.ActionCallback then
		actionButton = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundColor3 = selectedColor,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			ClipsDescendants = true,
			Font = Constants.Fonts.Bold,
			TextSize = 13,
			TextColor3 = Color3.new(1, 1, 1),
			Text = "",
			LayoutOrder = 3,
			Parent = holder,
		}, { Utility.Corner(8) })
		local actionScale = Create("UIScale", { Parent = actionButton })

		Utility.Track(actionButton.InputBegan:Connect(function(input)
			if Utility.IsClick(input) then
				Builders.Ripple(actionButton, input.Position)
			end
		end))
		actionButton.MouseEnter:Connect(function()
			Tween(actionButton, { BackgroundTransparency = 0.12 }, 0.15)
		end)
		actionButton.MouseLeave:Connect(function()
			Tween(actionButton, { BackgroundTransparency = 0 }, 0.15)
		end)
		actionButton.MouseButton1Click:Connect(function()
			Builders.Press(actionScale)
			running = not running
			refreshAction()
			Utility.SafeCall(options.ActionCallback, running, getTiles(), mode)
		end)
	end

	local clearButton = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		Text = options.ClearText or "Clear selection",
		LayoutOrder = 4,
		Parent = holder,
	})
	Theme.Bind(clearButton, { TextColor3 = "SubText" })
	clearButton.MouseEnter:Connect(function()
		Tween(clearButton, { TextColor3 = State.Theme.Text }, 0.12)
	end)
	clearButton.MouseLeave:Connect(function()
		Tween(clearButton, { TextColor3 = State.Theme.SubText }, 0.12)
	end)

	---------------------------------------------------------------- API
	grid.Instance = holder
	grid.TitleLabel = title
	grid.Value = getTiles()

	function grid:Get()
		return getTiles()
	end

	function grid:Set(tiles, silent)
		selected = {}
		for _, offset in ipairs(tiles or {}) do
			if not (offset.X == 0 and offset.Y == 0) and math.abs(offset.X) <= radius and math.abs(offset.Y) <= radius then
				selected[key(offset.X, offset.Y)] = offset
			end
		end
		for y = -radius, radius do
			for x = -radius, radius do
				paintCell(x, y)
			end
		end
		grid.Value = getTiles()
		if not silent then
			changed()
		end
	end

	function grid:Clear()
		grid:Set({})
	end

	function grid:GetMode()
		return mode
	end

	function grid:SetMode(newMode)
		mode = newMode
		if modeChip then
			modeChip.Text = mode
		end
		refreshAction()
		Utility.SafeCall(options.ModeCallback, mode)
	end

	function grid:IsRunning()
		return running
	end

	function grid:SetRunning(state)
		running = state and true or false
		refreshAction()
	end

	function grid:SetTitle(text)
		title.Text = text
	end

	function grid:SetVisible(visible)
		holder.Visible = visible
	end

	function grid:Destroy()
		holder:Destroy()
	end

	clearButton.MouseButton1Click:Connect(function()
		grid:Clear()
	end)

	if modeChip then
		modeChip.MouseButton1Click:Connect(function()
			local index = table.find(modes, mode) or 0
			grid:SetMode(modes[index % #modes + 1])
		end)
	end

	Theme.OnChange(function()
		for y = -radius, radius do
			for x = -radius, radius do
				paintCell(x, y, true)
			end
		end
	end)

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	refreshAction()
	for y = -radius, radius do
		for x = -radius, radius do
			paintCell(x, y, true)
		end
	end
	Element.RegisterFlag(options, grid)
	return grid
end
end

__modules["Components/GroupBox"] = function(...)
--[[
	Components/GroupBox
	Layout helpers. This module returns two builders:

	GroupBox: a titled, bordered box that holds any components.

		local box = Tab:GroupBox({ Title = "Aimbot" })
		box:Toggle({ Title = "Enabled" })
		box:SetTitle("Aim")

	Columns: side-by-side columns (e.g. two group boxes next to each other).

		local left, right = table.unpack(Tab:Columns({ Count = 2, Gap = 8 }))
		left:GroupBox({ Title = "Combat" }):Toggle({ Title = "Kill Aura" })
		right:GroupBox({ Title = "Visuals" }):Toggle({ Title = "ESP" })

	Register as: Tab.GroupBox = GroupBox.GroupBox, Tab.Columns = GroupBox.Columns
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create = Utility.Create

local GroupBox = {}

function GroupBox.GroupBox(tab, options)
	if type(options) == "string" then
		options = { Title = options }
	end
	options = options or {}

	local holder = Create("Frame", {
		Name = options.Title or "GroupBox",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(10),
		Utility.List(8),
		Utility.Padding(10, 10, 10, 10),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Sidebar" })
	Builders.Stroke(0.9).Parent = holder

	-- Title row: label + thin accent underline
	local titleRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})

	local title = Builders.Label({
		Text = options.Title or "Group",
		Font = Constants.Fonts.Bold,
		TextSize = 12,
		Size = UDim2.new(1, 0, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleRow,
	})

	local accentLine = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 2),
		Size = UDim2.fromOffset(18, 2),
		BorderSizePixel = 0,
		Parent = titleRow,
	}, { Utility.Corner(1) })
	Theme.Bind(accentLine, { BackgroundColor3 = "Accent" })

	local body = Create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	}, { Utility.List(6) })

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	local container = tab:_Child(body)
	container.Instance = holder
	container.Body = body

	function container:SetTitle(text)
		title.Text = text
	end

	function container:Destroy()
		holder:Destroy()
	end

	return container
end

function GroupBox.Columns(tab, options)
	options = options or {}
	local count = math.max(1, math.floor(options.Count or 2))
	local gap = options.Gap or 8

	local row = Create("Frame", {
		Name = "Columns",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.List(gap, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Top),
	})

	-- Each column takes an equal share of the width minus its part of the gaps
	local columnOffset = -math.ceil(gap * (count - 1) / count)

	local columns = {}
	for index = 1, count do
		local column = Create("Frame", {
			Name = "Column" .. index,
			Size = UDim2.new(1 / count, columnOffset, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Parent = row,
		}, { Utility.List(6) })

		local container = tab:_Child(column)
		container.Instance = column
		columns[index] = container
	end

	return columns
end

return GroupBox
end

__modules["Components/Image"] = function(...)
--[[
	Components/Image
	Image / banner card. Accepts any image source (asset id, URL, workspace file).

	local banner = Tab:Image({
		Image     = "https://example.com/banner.png",
		Height    = 140,
		ScaleType = Enum.ScaleType.Crop,   -- default
		Title     = "Season 3",            -- optional overlay text
		Desc      = "New maps and items",  -- optional
	})
	banner:SetImage("rbxassetid://123")
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create = Utility.Create

return function(tab, options)
	options = options or {}
	local height = options.Height or 140

	local holder = Create("Frame", {
		Name = options.Title or "Image",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(10) })
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	local image = Create("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = options.ScaleType or Enum.ScaleType.Crop,
		Parent = holder,
	}, { Utility.Corner(10) })
	if options.Image then
		Assets.Apply(image, options.Image)
	end

	local titleLabel
	if options.Title or options.Desc then
		-- Dark gradient at the bottom so overlay text stays readable
		local shade = Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, math.min(height, 80)),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = holder,
		}, {
			Create("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0.25),
				}),
			}),
		})

		local text = Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 12, 1, -10),
			Size = UDim2.new(1, -24, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = shade,
		}, { Utility.List(2, nil, nil, Enum.VerticalAlignment.Bottom) })

		if options.Title then
			titleLabel = Create("TextLabel", {
				Text = options.Title,
				Font = Constants.Fonts.Bold,
				TextSize = 15,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				ZIndex = 3,
				Parent = text,
			})
		end
		if options.Desc then
			Create("TextLabel", {
				Text = options.Desc,
				Font = Constants.Fonts.Regular,
				TextSize = 12,
				TextColor3 = Color3.fromRGB(225, 225, 232),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
				ZIndex = 3,
				Parent = text,
			})
		end
	end

	if tab._searchables and titleLabel then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	local element = { Instance = holder, ImageLabel = image }

	function element:SetImage(source)
		Assets.Apply(image, source)
	end

	function element:SetVisible(visible)
		holder.Visible = visible
	end

	function element:Destroy()
		holder:Destroy()
	end

	return element
end
end

__modules["Components/Input"] = function(...)
--[[
	Components/Input

	local input = Tab:Input({
		Title        = "Player Name",
		Placeholder  = "Enter username...",
		Default      = "",
		Numeric      = false, -- strip non-numeric characters
		MaxLength    = nil,
		Live         = false, -- true: callback on every change, false: on focus lost
		ClearOnFocus = false,
		Flag         = "PlayerName",
		Callback     = function(text, enterPressed) end,
	})
	input:Set("text") / input:Get() / input:SetPlaceholder("...")
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Hover = true,
		RightSize = UDim.new(0.42, 0),
	})
	local holder = element.Instance

	local field = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.42, 0, 0, 28),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(field, { BackgroundColor3 = "Field" })
	local fieldStroke = Builders.Stroke()
	fieldStroke.Parent = field

	local box = Create("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = options.ClearOnFocus or false,
		PlaceholderText = options.Placeholder or "Type here...",
		Text = tostring(options.Default or options.Value or ""),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = field,
	})
	Theme.Bind(box, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	local function sanitize(text)
		if options.Numeric then
			text = text:gsub("[^%d%.%-]", "")
		end
		if options.MaxLength and #text > options.MaxLength then
			text = text:sub(1, options.MaxLength)
		end
		return text
	end

	element.Value = box.Text

	box:GetPropertyChangedSignal("Text"):Connect(function()
		local clean = sanitize(box.Text)
		if clean ~= box.Text then
			box.Text = clean -- re-fires this handler with the clean value
			return
		end
		element.Value = clean
		if options.Live then
			Utility.SafeCall(options.Callback, clean)
		end
	end)

	box.Focused:Connect(function()
		Tween(fieldStroke, { Color = State.Theme.Accent, Transparency = 0.2 }, 0.18)
	end)

	box.FocusLost:Connect(function(enterPressed)
		Tween(fieldStroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.18)
		if not options.Live then
			Utility.SafeCall(options.Callback, element.Value, enterPressed)
		end
	end)

	function element:Set(text, silent)
		box.Text = sanitize(tostring(text or ""))
		element.Value = box.Text
		if not silent and not options.Live then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:SetPlaceholder(text)
		box.PlaceholderText = text
	end

	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Keybind"] = function(...)
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
end

__modules["Components/KeyValue"] = function(...)
--[[
	Components/KeyValue
	Card of label / value rows, e.g. an Info or Stats summary.

	local info = Tab:KeyValue({
		Title = "Details",                     -- optional header
		Rows = {
			{ "Version", "1.0.0" },
			{ "UI library", "EakUI 1.7.0" },
			{ "Hotkey", "F6" },
		},
	})
	info:Set("Hotkey", "F7")        -- updates an existing row or appends a new one
	info:Get("Version") -> "1.0.0"
	info:SetRows({ { "A", "1" } })  -- replaces every row
	info:Remove("Hotkey")
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create = Utility.Create

local ROW_HEIGHT = 40

return function(tab, options)
	options = options or {}

	local holder = Create("Frame", {
		Name = options.Title or "KeyValue",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(12), Utility.List(0), Utility.Padding(options.Title and 4 or 0, 0, 14, 14) })
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	local titleLabel
	if options.Title then
		titleLabel = Builders.Label({
			Text = options.Title,
			Font = Constants.Fonts.Bold,
			TextSize = 13,
			Size = UDim2.new(1, 0, 0, 32),
			LayoutOrder = 0,
			Parent = holder,
		})
		if tab._searchables then
			table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
		end
	end

	local rows = {} -- array of { Key, Frame, ValueLabel }
	local order = 0

	local function findRow(key)
		for index, row in ipairs(rows) do
			if row.Key == key then
				return row, index
			end
		end
		return nil
	end

	local function refreshDividers()
		for index, row in ipairs(rows) do
			row.Divider.Visible = index < #rows
		end
	end

	local function addRow(key, value)
		order += 1
		local frame = Create("Frame", {
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Parent = holder,
		})
		Builders.Label({
			Text = tostring(key),
			Font = Constants.Fonts.Regular,
			TextSize = 13,
			ThemeColor = "SubText",
			Size = UDim2.new(0.5, 0, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = frame,
		})
		local valueLabel = Builders.Label({
			Text = tostring(value),
			Font = Constants.Fonts.Medium,
			TextSize = 13,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0.5, 0, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			RichText = true,
			Parent = frame,
		})
		local divider = Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
			Parent = frame,
		})
		Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

		table.insert(rows, { Key = key, Frame = frame, ValueLabel = valueLabel, Divider = divider })
		refreshDividers()
	end

	local api = { Instance = holder, TitleLabel = titleLabel }

	function api:Set(key, value)
		local row = findRow(key)
		if row then
			row.ValueLabel.Text = tostring(value)
		else
			addRow(key, value)
		end
	end

	function api:Get(key)
		local row = findRow(key)
		return row and row.ValueLabel.Text
	end

	function api:Remove(key)
		local row, index = findRow(key)
		if row then
			row.Frame:Destroy()
			table.remove(rows, index)
			refreshDividers()
		end
	end

	function api:SetRows(newRows)
		for _, row in ipairs(rows) do
			row.Frame:Destroy()
		end
		table.clear(rows)
		for _, pair in ipairs(newRows or {}) do
			addRow(pair[1], pair[2])
		end
	end

	function api:SetVisible(visible)
		holder.Visible = visible
	end

	function api:Destroy()
		holder:Destroy()
	end

	api:SetRows(options.Rows)
	return api
end
end

__modules["Components/List"] = function(...)
--[[
	Components/List
	Selectable, searchable list card (players, items, teleport spots...).

	local list = Tab:List({
		Title     = "Teleports",
		Items     = {
			"Spawn",                                                  -- plain string
			{ Title = "Shop", Desc = "Near the fountain", Icon = "rbxassetid://..." },
			{ Title = "Boss", Image = "https://example.com/boss.png" },  -- full-color image
		},
		Multi     = false,
		Search    = nil,        -- true/false; auto-on for more than 6 items
		MaxHeight = 200,        -- list area height before scrolling
		Empty     = "No items",
		Flag      = "Teleport",
		Callback  = function(value) end,  -- title (or table of titles when Multi)
	})
	list:SetItems(items) / list:Set(value) / list:Get()
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local ROW_SIMPLE = 32
local ROW_WITH_DESC = 44
local ROW_GAP = 2
local SEARCH_THRESHOLD = 6

local function normalize(item)
	if type(item) == "table" then
		return {
			Title = tostring(item.Title or item.Name or ""),
			Desc = item.Desc or item.Description,
			Icon = item.Icon,
			Image = item.Image,
		}
	end
	return { Title = tostring(item) }
end

return function(tab, options)
	options = options or {}
	local multi = options.Multi or false
	local maxHeight = options.MaxHeight or 200
	local items = {}

	local initial = options.Value or options.Default
	local value
	if multi then
		value = type(initial) == "table" and table.clone(initial) or {}
	else
		value = initial
	end

	---------------------------------------------------------------- container
	local holder = Create("Frame", {
		Name = options.Title or "List",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(8),
		Utility.Padding(10, 10, 10, 10),
		Utility.List(8),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})

	local titleLabel = Builders.Label({
		Text = options.Title or "List",
		Position = UDim2.fromOffset(2, 0),
		Size = UDim2.new(1, -70, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})

	local countLabel = Builders.Label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 70, 1, 0),
		Font = Constants.Fonts.Regular,
		TextSize = 11,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	-- Search ---------------------------------------------------------------
	local searchFrame = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Visible = false,
		LayoutOrder = 2,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(searchFrame, { BackgroundColor3 = "Field" })
	local searchStroke = Builders.Stroke()
	searchStroke.Parent = searchFrame

	local searchBox = Create("TextBox", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		PlaceholderText = "Search...",
		Text = "",
		Parent = searchFrame,
	})
	Theme.Bind(searchBox, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	-- Rows -----------------------------------------------------------------
	local scroller = Create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		LayoutOrder = 3,
		Parent = holder,
	}, { Utility.List(ROW_GAP), Utility.Padding(0, 0, 0, 4) })
	Theme.Bind(scroller, { ScrollBarImageColor3 = "Accent" })

	local emptyLabel = Builders.Label({
		Text = options.Empty or "No items",
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 40),
		Visible = false,
		LayoutOrder = 4,
		Parent = holder,
	})

	local rows = {} -- { Instance, Label, Marker, Item }

	local function isSelected(title)
		if multi then
			return table.find(value, title) ~= nil
		end
		return value == title
	end

	local function paintRows(instant)
		local theme = State.Theme
		local duration = instant and 0 or 0.15
		for _, row in ipairs(rows) do
			local selected = isSelected(row.Item.Title)
			Tween(row.Instance, { BackgroundTransparency = selected and 0.82 or 1 }, duration)
			Tween(row.Label, { TextColor3 = selected and theme.Text or theme.SubText }, duration)
			Tween(row.Marker, { BackgroundTransparency = selected and 0 or 1 }, duration)
		end
	end

	local function layout()
		local query = string.lower(searchBox.Text)
		local visibleHeight = 0
		local visibleCount = 0
		for _, row in ipairs(rows) do
			local match = query == "" or string.find(string.lower(row.Item.Title), query, 1, true) ~= nil
			row.Instance.Visible = match
			if match then
				visibleCount += 1
				visibleHeight += row.Instance.Size.Y.Offset + ROW_GAP
			end
		end
		scroller.Size = UDim2.new(1, 0, 0, math.min(visibleHeight, maxHeight))
		scroller.Visible = visibleCount > 0
		emptyLabel.Visible = visibleCount == 0
		emptyLabel.Text = (#items > 0 and query ~= "") and "No results" or (options.Empty or "No items")

		local selectedCount = multi and #value or (value ~= nil and 1 or 0)
		countLabel.Text = multi and string.format("%d selected", selectedCount) or string.format("%d items", #items)
	end

	local element = { Instance = holder, TitleLabel = titleLabel }

	local function syncValue()
		element.Value = multi and table.clone(value) or value
	end

	local function fire()
		syncValue()
		Utility.SafeCall(options.Callback, multi and table.clone(value) or value)
	end

	local function choose(title)
		if multi then
			local index = table.find(value, title)
			if index then
				table.remove(value, index)
			else
				table.insert(value, title)
			end
		else
			value = title
		end
		paintRows(false)
		layout()
		fire()
	end

	local function createRow(index, item)
		local hasDesc = item.Desc ~= nil
		local media = item.Image or item.Icon
		local height = hasDesc and ROW_WITH_DESC or ROW_SIMPLE

		local row = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, height),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			Parent = scroller,
		}, { Utility.Corner(6) })
		Theme.Bind(row, { BackgroundColor3 = "Accent" })

		local marker = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromOffset(3, height - 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = row,
		}, { Utility.Corner(2) })
		Theme.Bind(marker, { BackgroundColor3 = "Accent" })

		local textX = 16
		if media then
			local size = item.Image and (height - 10) or 16
			local icon = Create("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Size = UDim2.fromOffset(size, size),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Parent = row,
			}, { Utility.Corner(item.Image and 6 or 0) })
			Assets.Apply(icon, media)
			if item.Icon and not item.Image then
				Theme.Bind(icon, { ImageColor3 = "SubText" })
			end
			textX = 16 + size + 8
		end

		local textGroup = Create("Frame", {
			Position = UDim2.fromOffset(textX, 0),
			Size = UDim2.new(1, -(textX + 8), 1, 0),
			BackgroundTransparency = 1,
			Parent = row,
		}, { Utility.List(1, nil, nil, Enum.VerticalAlignment.Center) })

		local label = Builders.Label({
			Text = item.Title,
			Font = Constants.Fonts.Medium,
			TextSize = 12,
			ThemeColor = "SubText",
			Size = UDim2.new(1, 0, 0, 15),
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 1,
			Parent = textGroup,
		})

		if hasDesc then
			Builders.Label({
				Text = item.Desc,
				Font = Constants.Fonts.Regular,
				TextSize = 11,
				ThemeColor = "Placeholder",
				Size = UDim2.new(1, 0, 0, 13),
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 2,
				Parent = textGroup,
			})
		end

		row.MouseEnter:Connect(function()
			if not isSelected(item.Title) then
				Tween(row, { BackgroundTransparency = 0.93 }, 0.12)
			end
		end)
		row.MouseLeave:Connect(function()
			if not isSelected(item.Title) then
				Tween(row, { BackgroundTransparency = 1 }, 0.12)
			end
		end)
		row.MouseButton1Click:Connect(function()
			choose(item.Title)
		end)

		table.insert(rows, { Instance = row, Label = label, Marker = marker, Item = item })
	end

	local function build()
		for _, row in ipairs(rows) do
			row.Instance:Destroy()
		end
		table.clear(rows)

		for index, item in ipairs(items) do
			createRow(index, item)
		end

		local searchable
		if options.Search ~= nil then
			searchable = options.Search == true
		else
			searchable = #items > SEARCH_THRESHOLD
		end
		searchFrame.Visible = searchable

		paintRows(true)
		layout()
	end

	---------------------------------------------------------------- API
	function element:SetItems(newItems, keepValue)
		items = {}
		for _, item in ipairs(newItems or {}) do
			table.insert(items, normalize(item))
		end
		if not keepValue then
			value = multi and {} or nil
		elseif multi then
			-- drop selections that no longer exist
			local kept = {}
			for _, title in ipairs(value) do
				for _, item in ipairs(items) do
					if item.Title == title then
						table.insert(kept, title)
						break
					end
				end
			end
			value = kept
		end
		syncValue()
		build()
	end

	function element:Set(newValue, silent)
		if multi then
			value = type(newValue) == "table" and table.clone(newValue) or { newValue }
		else
			value = newValue
		end
		paintRows(false)
		layout()
		if silent then
			syncValue()
		else
			fire()
		end
	end

	function element:Get()
		return multi and table.clone(value) or value
	end

	function element:SetTitle(text)
		titleLabel.Text = text
	end

	function element:SetVisible(visible)
		holder.Visible = visible
	end

	function element:Destroy()
		holder:Destroy()
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(layout)
	searchBox.Focused:Connect(function()
		Tween(searchStroke, { Color = State.Theme.Accent, Transparency = 0.3 }, 0.15)
	end)
	searchBox.FocusLost:Connect(function()
		Tween(searchStroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.15)
	end)

	Theme.OnChange(function()
		paintRows(true)
	end)

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	element:SetItems(options.Items or options.Values or {}, true)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Notification"] = function(...)
--[[
	Components/Notification
	Toast stack in the bottom-right corner with auto-dismiss.

	UI:Notify({
		Title    = "Done",
		Content  = "Something happened",
		Type     = "Info" | "Success" | "Warning" | "Error", -- also sets a default icon
		Icon     = "rbxassetid://...", -- optional
		Duration = 5,
		Callback = function() end,     -- fired on close
	}) -> { Close = function }
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Gui = import("Core/Gui")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local WIDTH = 290
local MARGIN = 16
local Z = 100

local order = 0

-- Built-in icon shown for each Type when no Icon is given
local TYPE_ICONS = {
	Info = "info",
	Success = "check-circle",
	Warning = "alert",
	Error = "x-circle",
}

local function getHolder()
	if State.NotifyHolder and State.NotifyHolder.Parent then
		return State.NotifyHolder
	end

	State.NotifyHolder = Create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -MARGIN, 1, -MARGIN),
		Size = UDim2.new(0, WIDTH, 1, -MARGIN * 2),
		BackgroundTransparency = 1,
		ZIndex = Z,
		Parent = Gui.Get(),
	}, {
		Utility.List(8, nil, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom),
	})
	return State.NotifyHolder
end

local function buildCloseButton(card)
	local button = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = Z + 2,
		Parent = card,
	}, { Utility.Corner(6) })
	Theme.Bind(button, { BackgroundColor3 = "ElementHover" })
	Builders.CrossIcon(button, 10, "SubText", Z + 3)

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = 0.3 }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = 1 }, 0.15)
	end)
	return button
end

return function(config)
	Theme.Ensure()
	config = config or {}

	local duration = config.Duration or 5
	local color = Constants.NotifyColors[config.Type or ""] or State.Theme.Accent
	local content = config.Content or config.Desc
	local iconSource = config.Icon or TYPE_ICONS[config.Type or ""] -- default icon per Type
	order += 1

	local outer = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		ZIndex = Z,
		Parent = getHolder(),
	})

	local card = Create("Frame", {
		Position = UDim2.new(1, 30, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = Z,
		Parent = outer,
	}, { Utility.Corner(10) })
	Theme.Bind(card, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.86).Parent = card

	-- Accent bar
	Create("Frame", {
		Position = UDim2.new(0, 8, 0, 10),
		Size = UDim2.new(0, 3, 1, -20),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = Z + 1,
		Parent = card,
	}, { Utility.Corner(2) })

	local body = Create("Frame", {
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -52, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = Z + 1,
		Parent = card,
	}, { Utility.List(3), Utility.Padding(11, 13, 0, 0) })

	local titleRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		ZIndex = Z + 1,
		Parent = body,
	}, { Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	if iconSource then
		local icon = Create("ImageLabel", {
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ImageColor3 = config.IconTint == false and Color3.new(1, 1, 1) or color,
			ZIndex = Z + 1,
			Parent = titleRow,
		})
		Assets.Apply(icon, iconSource)
	end

	Builders.Label({
		Text = config.Title or "Notification",
		Font = Constants.Fonts.Bold,
		TextSize = 13,
		Size = UDim2.new(1, iconSource and -22 or 0, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		ZIndex = Z + 1,
		Parent = titleRow,
	})

	if content then
		Builders.Label({
			Text = content,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 3,
			ZIndex = Z + 1,
			Parent = body,
		})
	end

	local closeButton = buildCloseButton(card)

	local progress = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = Z + 2,
		Parent = card,
	})

	Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.45)
	Tween(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

	local notification = {}
	local closed = false

	function notification:Close()
		if closed then
			return
		end
		closed = true

		task.spawn(function()
			Tween(card, { Position = UDim2.new(1, 30, 0, 0) }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.wait(0.3)
			if not outer.Parent then
				return
			end
			-- collapse the slot so the stack slides down smoothly
			outer.AutomaticSize = Enum.AutomaticSize.None
			outer.Size = UDim2.new(1, 0, 0, card.AbsoluteSize.Y)
			Tween(outer, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
			task.wait(0.22)
			outer:Destroy()
		end)

		Utility.SafeCall(config.Callback)
	end

	closeButton.MouseButton1Click:Connect(function()
		notification:Close()
	end)
	task.delay(duration, function()
		notification:Close()
	end)

	return notification
end
end

__modules["Components/Paragraph"] = function(...)
--[[
	Components/Paragraph

	local paragraph = Tab:Paragraph({ Title = "About", Desc = "Some text" })
	paragraph:Set({ Title = "New", Desc = "Updated" })
]]

local import = ...
local Constants = import("Core/Constants")
local Element = import("Components/Element")

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options)
	element.TitleLabel.Font = Constants.Fonts.Bold

	local content = options.Desc or options.Content
	if content then
		element:SetDesc(content)
	end

	function element:Set(newOptions)
		if newOptions.Title then
			element:SetTitle(newOptions.Title)
		end
		local text = newOptions.Desc or newOptions.Content
		if text then
			element:SetDesc(text)
		end
	end

	return element
end
end

__modules["Components/PlayerDropdown"] = function(...)
--[[
	Components/PlayerDropdown
	Dropdown of players in the server that updates as players join / leave.
	Built on Components/Dropdown; callbacks receive Player instances.

	local target = Tab:PlayerDropdown({
		Title        = "Target",
		ExcludeLocal = true,          -- hide yourself (default true)
		Format       = "Both",        -- "Both" = "DisplayName (@Name)", "Name", "DisplayName"
		Multi        = false,
		Placeholder  = "Select player...",
		Flag         = "Target",
		Callback     = function(player) end,  -- Player (or { Player } when Multi), nil if cleared
	})
	target:GetPlayer() -> Player? (or { Player })
	target:Set(player) / target:Refresh()
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Element = import("Components/Element")
local Dropdown = import("Components/Dropdown")

local Players = Services.Players

return function(tab, options)
	options = options or {}
	local multi = options.Multi or false
	local labelToPlayer = {}

	local function labelOf(player)
		if options.Format == "Name" then
			return player.Name
		elseif options.Format == "DisplayName" then
			return player.DisplayName
		end
		if player.DisplayName == player.Name then
			return player.Name
		end
		return string.format("%s (@%s)", player.DisplayName, player.Name)
	end

	local function collect(leaving)
		labelToPlayer = {}
		local labels = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local excluded = player == leaving
				or (options.ExcludeLocal ~= false and player == Services.LocalPlayer)
			if not excluded then
				local label = labelOf(player)
				labelToPlayer[label] = player
				table.insert(labels, label)
			end
		end
		table.sort(labels, function(a, b)
			return string.lower(a) < string.lower(b)
		end)
		return labels
	end

	local function toPlayers(value)
		if multi then
			local list = {}
			for _, label in ipairs(value or {}) do
				local player = labelToPlayer[label]
				if player then
					table.insert(list, player)
				end
			end
			return list
		end
		return value ~= nil and labelToPlayer[value] or nil
	end

	local function toLabels(value)
		if typeof(value) == "Instance" then
			return labelOf(value)
		end
		if multi and type(value) == "table" then
			local labels = {}
			for _, entry in ipairs(value) do
				table.insert(labels, typeof(entry) == "Instance" and labelOf(entry) or entry)
			end
			return labels
		end
		return value
	end

	-- Build the underlying dropdown with label values
	local dropdownOptions = table.clone(options)
	dropdownOptions.Values = collect()
	dropdownOptions.Value = toLabels(options.Value or options.Default)
	dropdownOptions.Default = nil
	dropdownOptions.Placeholder = options.Placeholder or (multi and "None" or "Select player...")
	dropdownOptions.Flag = nil -- registered below on the wrapper
	dropdownOptions.Callback = function(value)
		Utility.SafeCall(options.Callback, toPlayers(value))
	end

	local element = Dropdown(tab, dropdownOptions)
	local baseSet = element.Set
	local baseRefresh = element.Refresh

	function element:GetPlayer()
		return toPlayers(element.Value)
	end

	function element:Set(value, silent)
		baseSet(element, toLabels(value), silent)
	end

	-- Rebuilds the list; keeps the selection when those players are still here
	function element:Refresh(leaving)
		local previous = element.Value
		local labels = collect(typeof(leaving) == "Instance" and leaving or nil)
		baseRefresh(element, labels, true)

		local changed = false
		if multi then
			local kept = {}
			for _, label in ipairs(previous or {}) do
				if labelToPlayer[label] then
					table.insert(kept, label)
				else
					changed = true
				end
			end
			if changed then
				baseSet(element, kept, true)
			end
		elseif previous ~= nil and not labelToPlayer[previous] then
			changed = true
			baseSet(element, nil, true)
		end

		if changed then
			Utility.SafeCall(options.Callback, toPlayers(element.Value))
		end
	end

	Utility.Track(Players.PlayerAdded:Connect(function()
		if element.Instance.Parent then
			element:Refresh()
		end
	end))
	Utility.Track(Players.PlayerRemoving:Connect(function(player)
		if element.Instance.Parent then
			element:Refresh(player)
		end
	end))

	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/ProgressBar"] = function(...)
--[[
	Components/ProgressBar
	Read-only progress indicator with an animated fill.

	local bar = Tab:ProgressBar({
		Title   = "Farming",
		Value   = 45,
		Max     = 100,
		Percent = false,                       -- true shows "45%" instead of "45 / 100"
		Color   = Color3.fromRGB(34, 197, 94), -- optional, defaults to the accent
		Flag    = "FarmProgress",
	})
	bar:Set(60) / bar:SetMax(200) / bar:Get()
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

return function(tab, options)
	options = options or {}
	local max = math.max(options.Max or 100, 1e-9)

	local element = Element.new(tab, options, {
		Height = 54,
		Auto = false,
		RightSize = UDim.new(0, 80),
	})
	local holder = element.Instance

	-- Title row at the top, bar along the bottom
	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 92), 0, 34)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingTop = UDim.new(0, 8)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingBottom = UDim.new(0, 0)
	element.TextHolder:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top
	element.DescLabel.Visible = false

	local valueLabel = Builders.Label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(80, 18),
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = holder,
	})

	local track = Create("Frame", {
		Position = UDim2.new(0, 12, 1, -16),
		Size = UDim2.new(1, -24, 0, 6),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
	}, { Utility.Corner(999) })
	Theme.Bind(track, { BackgroundColor3 = "ToggleOff" })

	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		Utility.Corner(999),
		Create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(205, 205, 205), Color3.new(1, 1, 1)) }),
	})
	if options.Color then
		fill.BackgroundColor3 = options.Color
	else
		Theme.Bind(fill, { BackgroundColor3 = "Accent" })
	end

	local function render(instant)
		local percent = math.clamp(element.Value / max, 0, 1)
		Tween(fill, { Size = UDim2.fromScale(percent, 1) }, instant and 0 or 0.35)
		if options.Percent then
			valueLabel.Text = string.format("%d%%", math.floor(percent * 100 + 0.5))
		else
			valueLabel.Text = string.format("%s / %s", tostring(element.Value), tostring(max))
		end
	end

	element.Value = math.clamp(options.Value or options.Default or 0, 0, max)

	function element:Set(value)
		element.Value = math.clamp(tonumber(value) or 0, 0, max)
		render(false)
	end

	function element:SetMax(newMax)
		max = math.max(tonumber(newMax) or max, 1e-9)
		element.Value = math.clamp(element.Value, 0, max)
		render(false)
	end

	function element:Get()
		return element.Value
	end

	render(true)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/RangeSlider"] = function(...)
--[[
	Components/RangeSlider
	Slider with two knobs selecting a min-max range. Knobs cannot cross.

	local range = Tab:RangeSlider({
		Title    = "Distance",
		Min      = 0,
		Max      = 100,
		Default  = { Min = 10, Max = 50 },
		Step     = 1,          -- supports decimals
		Suffix   = " studs",
		Flag     = "Distance",
		Callback = function(value) end, -- value = { Min = number, Max = number }
	})
	range:Set({ Min = 20, Max = 80 }) / range:Get() / range:SetMinMax(0, 200)
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween
local UserInputService = Services.UserInputService

local KNOB_SIZE = UDim2.fromOffset(14, 14)
local KNOB_SIZE_ACTIVE = UDim2.fromOffset(18, 18)

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
		Height = 58,
		Auto = false,
	})
	local holder = element.Instance

	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 124), 0, 36)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingTop = UDim.new(0, 8)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingBottom = UDim.new(0, 0)
	element.TextHolder:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top
	element.DescLabel.Visible = false
	if element.IconLabel then
		element.IconLabel.AnchorPoint = Vector2.new(0, 0)
		element.IconLabel.Position = UDim2.fromOffset(12, 9)
	end

	local valueLabel = Create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Text = "",
		Parent = holder,
	}, { Utility.Corner(6), Utility.Padding(0, 0, 8, 8) })
	Theme.Bind(valueLabel, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	Builders.Stroke().Parent = valueLabel

	local track = Create("Frame", {
		Position = UDim2.new(0, 12, 1, -16),
		Size = UDim2.new(1, -24, 0, 6),
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(999) })
	Theme.Bind(track, { BackgroundColor3 = "ToggleOff" })

	local fill = Create("Frame", {
		BorderSizePixel = 0,
		Parent = track,
	}, { Utility.Corner(999) })
	Theme.Bind(fill, { BackgroundColor3 = "Accent" })

	local function makeKnob()
		local knob = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = KNOB_SIZE,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = track,
		}, { Utility.Corner(999) })
		Theme.Bind(knob, { BackgroundColor3 = "Knob" })
		local stroke = Create("UIStroke", { Thickness = 2, Parent = knob })
		Theme.Bind(stroke, { Color = "Accent" })
		return knob
	end
	local lowKnob, highKnob = makeKnob(), makeKnob()

	local hitbox = Create("TextButton", {
		Position = UDim2.new(0, 0, 1, -30),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = holder,
	})

	local function round(value)
		local snapped = math.floor((value - min) / step + 0.5) * step + min
		snapped = tonumber(string.format(numberFormat, snapped))
		return math.clamp(snapped, min, max)
	end

	local function percent(value)
		return (max == min) and 0 or (value - min) / (max - min)
	end

	local function render(instant)
		local a, b = percent(element.Value.Min), percent(element.Value.Max)
		local t = instant and 0 or 0.1
		Tween(fill, { Position = UDim2.fromScale(a, 0), Size = UDim2.fromScale(b - a, 1) }, t)
		Tween(lowKnob, { Position = UDim2.fromScale(a, 0.5) }, t)
		Tween(highKnob, { Position = UDim2.fromScale(b, 0.5) }, t)
		valueLabel.Text = string.format(numberFormat, element.Value.Min)
			.. " - "
			.. string.format(numberFormat, element.Value.Max)
			.. suffix
	end

	local initial = options.Default or options.Value or {}
	local low = round(initial.Min or initial[1] or min)
	local high = round(initial.Max or initial[2] or max)
	element.Value = { Min = math.min(low, high), Max = math.max(low, high) }

	function element:Set(value, silent)
		local newLow = round(tonumber(value.Min or value[1]) or element.Value.Min)
		local newHigh = round(tonumber(value.Max or value[2]) or element.Value.Max)
		if newLow > newHigh then
			newLow, newHigh = newHigh, newLow
		end
		local changed = newLow ~= element.Value.Min or newHigh ~= element.Value.Max
		element.Value = { Min = newLow, Max = newHigh }
		render(false)
		if changed and not silent then
			Utility.SafeCall(options.Callback, { Min = newLow, Max = newHigh })
		end
	end

	function element:Get()
		return { Min = element.Value.Min, Max = element.Value.Max }
	end

	function element:SetMinMax(newMin, newMax)
		min, max = newMin, newMax
		element:Set(element.Value, true)
	end

	-- Dragging: grab the nearest knob, it stops at the other knob ----------
	local active -- "Min" | "Max" | nil

	local function valueAt(x)
		local p = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		return round(min + p * (max - min))
	end

	local function update(x)
		local value = valueAt(x)
		if active == "Min" then
			element:Set({ Min = math.min(value, element.Value.Max), Max = element.Value.Max })
		else
			element:Set({ Min = element.Value.Min, Max = math.max(value, element.Value.Min) })
		end
	end

	Utility.Track(hitbox.InputBegan:Connect(function(input)
		if not Utility.IsClick(input) then
			return
		end
		local value = valueAt(input.Position.X)
		local toLow = math.abs(value - element.Value.Min)
		local toHigh = math.abs(value - element.Value.Max)
		if toLow == toHigh then
			active = value < element.Value.Min and "Min" or "Max"
		else
			active = toLow < toHigh and "Min" or "Max"
		end
		Tween(active == "Min" and lowKnob or highKnob, { Size = KNOB_SIZE_ACTIVE }, 0.15)
		update(input.Position.X)
	end))

	Utility.Track(UserInputService.InputChanged:Connect(function(input)
		if active and Utility.IsMove(input) then
			update(input.Position.X)
		end
	end))

	Utility.Track(UserInputService.InputEnded:Connect(function(input)
		if active and Utility.IsClick(input) then
			Tween(active == "Min" and lowKnob or highKnob, { Size = KNOB_SIZE }, 0.2, Enum.EasingStyle.Back)
			active = nil
		end
	end))

	render(true)
	Theme.OnChange(function()
		render(true)
	end)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Section"] = function(...)
--[[
	Components/Section
	Small uppercase heading that groups elements.

	Tab:Section("Player")  or  Tab:Section({ Title = "Player" })
]]

local import = ...
local Utility = import("Core/Utility")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

return function(tab, options)
	if type(options) == "string" then
		options = { Title = options }
	end
	options = options or {}

	local label = Builders.Label({
		Text = string.upper(options.Title or "Section"),
		Font = Constants.Fonts.Bold,
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 26),
		TextYAlignment = Enum.TextYAlignment.Bottom,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	})
	Utility.Padding(0, 2, 4, 0).Parent = label

	-- Headings are hidden while a search filter is active
	if tab._sections then
		table.insert(tab._sections, label)
	end

	local section = { Instance = label }

	function section:SetTitle(text)
		label.Text = string.upper(text)
	end

	function section:Destroy()
		label:Destroy()
	end

	return section
end
end

__modules["Components/Segmented"] = function(...)
--[[
	Components/Segmented
	Pick one of 2-5 visible options; an accent pill slides behind the choice.

	local mode = Tab:Segmented({
		Title    = "Mode",
		Values   = { "Farm", "Break", "Place" },
		Value    = "Farm",
		Flag     = "Mode",
		Callback = function(value) end,
	})
	mode:Set("Break") / mode:Get() / mode:SetValues({ "A", "B" })
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local TRACK_HEIGHT = 30
local INSET = 3

return function(tab, options)
	options = options or {}
	local values = options.Values or options.Options or {}

	local element = Element.new(tab, options, {
		Height = 42 + TRACK_HEIGHT + 4,
		Auto = false,
	})
	local holder = element.Instance

	-- Title row on top, control below
	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 12), 0, 36)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingBottom = UDim.new(0, 0)
	element.DescLabel.Visible = false
	if element.IconLabel then
		element.IconLabel.AnchorPoint = Vector2.new(0, 0)
		element.IconLabel.Position = UDim2.fromOffset(12, 9)
	end

	local track = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -10),
		Size = UDim2.new(1, -20, 0, TRACK_HEIGHT),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(8) })
	Theme.Bind(track, { BackgroundColor3 = "Field" })
	Builders.Stroke().Parent = track

	local pill = Create("Frame", {
		Position = UDim2.fromOffset(INSET, INSET),
		Size = UDim2.new(0, 0, 1, -INSET * 2),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = track,
	}, { Utility.Corner(6) })
	Theme.Bind(pill, { BackgroundColor3 = "Accent" })

	local segmentHolder = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = track,
	}, { Utility.List(0, Enum.FillDirection.Horizontal) })

	local segments = {} -- [index] = TextButton

	element.Value = options.Value or options.Default or values[1]

	local function indexOf(value)
		return table.find(values, value)
	end

	local function render(instant)
		local index = indexOf(element.Value)
		local count = #values
		local t = instant and 0 or 0.3

		if index and count > 0 then
			pill.Visible = true
			Tween(pill, {
				Position = UDim2.new((index - 1) / count, INSET, 0, INSET),
				Size = UDim2.new(1 / count, -INSET * 2, 1, -INSET * 2),
			}, t)
		else
			pill.Visible = false
		end

		local theme = State.Theme
		for i, button in ipairs(segments) do
			Tween(button, { TextColor3 = i == index and Color3.new(1, 1, 1) or theme.SubText }, t)
		end
	end

	local function build()
		for _, button in ipairs(segments) do
			button:Destroy()
		end
		table.clear(segments)

		local count = math.max(#values, 1)
		for i, value in ipairs(values) do
			local button = Create("TextButton", {
				Size = UDim2.new(1 / count, 0, 1, 0),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Font = Constants.Fonts.Medium,
				TextSize = 12,
				Text = tostring(value),
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = i,
				ZIndex = 3,
				Parent = segmentHolder,
			})
			Theme.Bind(button, { TextColor3 = "SubText" })

			button.MouseEnter:Connect(function()
				if element.Value ~= value then
					Tween(button, { TextColor3 = State.Theme.Text }, 0.12)
				end
			end)
			button.MouseLeave:Connect(function()
				if element.Value ~= value then
					Tween(button, { TextColor3 = State.Theme.SubText }, 0.12)
				end
			end)
			button.MouseButton1Click:Connect(function()
				if element.Value ~= value then
					element:Set(value)
				end
			end)

			segments[i] = button
		end
		render(true)
	end

	function element:Set(value, silent)
		element.Value = value
		render(false)
		if not silent then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:SetValues(newValues, keepValue)
		values = newValues or {}
		if not keepValue or not indexOf(element.Value) then
			element.Value = values[1]
		end
		build()
	end

	build()
	Theme.OnChange(function()
		render(true)
	end)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Slider"] = function(...)
--[[
	Components/Slider

	local slider = Tab:Slider({
		Title    = "Speed",
		Min      = 1,
		Max      = 100,
		Default  = 50,
		Step     = 1,        -- supports decimals, e.g. 0.05
		Suffix   = " studs", -- optional
		Desc     = "optional description under the title",
		ShowRange = true,    -- min / max captions under the track
		MinLabel = "fast", MaxLabel = "safe", -- optional words after the captions
		Flag     = "Speed",
		Callback = function(value) end,
	})
	slider:Set(75) / slider:Get() / slider:SetMinMax(0, 200)
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

local KNOB_SIZE = UDim2.fromOffset(14, 14)
local KNOB_SIZE_ACTIVE = UDim2.fromOffset(18, 18)

return function(tab, options)
	options = options or {}
	local min = options.Min or 0
	local max = options.Max or 100
	local step = options.Step or options.Increment or 1
	local suffix = options.Suffix or ""
	local decimals = #(tostring(step):match("%.(%d+)$") or "")
	local numberFormat = "%." .. decimals .. "f"

	local hasDesc = (options.Desc or options.Description) ~= nil
	local rangeHeight = options.ShowRange and 14 or 0
	local descHeight = hasDesc and 16 or 0

	local element = Element.new(tab, options, {
		Hover = true,
		Height = 58 + descHeight + rangeHeight,
		Auto = false,
		RightSize = UDim.new(0, 70),
	})
	local holder = element.Instance

	-- Compact header layout: title top-left, value box top-right
	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 84), 0, 36 + descHeight)
	if element.IconLabel then -- align icon with the title row, not the whole card
		element.IconLabel.AnchorPoint = Vector2.new(0, 0)
		element.IconLabel.Position = UDim2.fromOffset(12, 9)
	end
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingTop = UDim.new(0, 8)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingBottom = UDim.new(0, 0)
	element.TextHolder:FindFirstChildOfClass("UIListLayout").VerticalAlignment = Enum.VerticalAlignment.Top
	element.DescLabel.Visible = hasDesc

	local valueBox = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(62, 22),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		ClearTextOnFocus = false,
		Text = "",
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(valueBox, { BackgroundColor3 = "Field", TextColor3 = "Text" })
	local boxStroke = Builders.Stroke()
	boxStroke.Parent = valueBox

	local track = Create("Frame", {
		Position = UDim2.new(0, 12, 1, -(16 + rangeHeight)),
		Size = UDim2.new(1, -24, 0, 6),
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(999) })
	Theme.Bind(track, { BackgroundColor3 = "ToggleOff" })

	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		Utility.Corner(999),
		Create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(200, 200, 200), Color3.new(1, 1, 1)) }),
	})
	Theme.Bind(fill, { BackgroundColor3 = "Accent" })

	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = KNOB_SIZE,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = track,
	}, { Utility.Corner(999) })
	Theme.Bind(knob, { BackgroundColor3 = "Knob" })
	local knobStroke = Create("UIStroke", { Thickness = 2, Parent = knob })
	Theme.Bind(knobStroke, { Color = "Accent" })

	-- Larger invisible hit area over the track
	local hitbox = Create("TextButton", {
		Position = UDim2.new(0, 0, 1, -(30 + rangeHeight)),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 4,
		Parent = holder,
	})

	-- Min / max captions under the track (ShowRange = true)
	local rangeLabels = {}
	if options.ShowRange then
		for index, align in ipairs({ Enum.TextXAlignment.Left, Enum.TextXAlignment.Right }) do
			rangeLabels[index] = Builders.Label({
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 12, 1, -5),
				Size = UDim2.new(1, -24, 0, 12),
				Font = Constants.Fonts.Mono,
				TextSize = 10,
				ThemeColor = "Placeholder",
				TextXAlignment = align,
				Parent = holder,
			})
		end
	end
	local function renderRange()
		if rangeLabels[1] then
			rangeLabels[1].Text = string.format(numberFormat, min) .. suffix .. (options.MinLabel and (" · " .. options.MinLabel) or "")
			rangeLabels[2].Text = string.format(numberFormat, max) .. suffix .. (options.MaxLabel and (" · " .. options.MaxLabel) or "")
		end
	end
	renderRange()

	local function round(value)
		local snapped = math.floor((value - min) / step + 0.5) * step + min
		snapped = tonumber(string.format(numberFormat, snapped))
		return math.clamp(snapped, min, max)
	end

	local function render(instant)
		local percent = (max == min) and 0 or (element.Value - min) / (max - min)
		local duration = instant and 0 or 0.12
		Tween(fill, { Size = UDim2.fromScale(percent, 1) }, duration)
		Tween(knob, { Position = UDim2.fromScale(percent, 0.5) }, duration)
		valueBox.Text = string.format(numberFormat, element.Value) .. suffix
	end

	element.Value = round(options.Default or options.Value or min)

	function element:Set(value, silent)
		local new = round(tonumber(value) or element.Value)
		local changed = new ~= element.Value
		element.Value = new
		render(false)
		if changed and not silent then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:SetMinMax(newMin, newMax)
		min, max = newMin, newMax
		renderRange()
		element:Set(element.Value, true)
	end

	-- Dragging -------------------------------------------------------------
	local dragging = false

	local function updateFromX(x)
		local percent = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		element:Set(min + percent * (max - min))
	end

	Utility.Track(hitbox.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			dragging = true
			Tween(knob, { Size = KNOB_SIZE_ACTIVE }, 0.15)
			updateFromX(input.Position.X)
		end
	end))

	Utility.Track(UserInputService.InputChanged:Connect(function(input)
		if dragging and Utility.IsMove(input) then
			updateFromX(input.Position.X)
		end
	end))

	Utility.Track(UserInputService.InputEnded:Connect(function(input)
		if dragging and Utility.IsClick(input) then
			dragging = false
			Tween(knob, { Size = KNOB_SIZE }, 0.2, Enum.EasingStyle.Back)
		end
	end))

	-- Manual entry ---------------------------------------------------------
	valueBox.Focused:Connect(function()
		Tween(boxStroke, { Transparency = 0.4 }, 0.15)
		valueBox.Text = string.format(numberFormat, element.Value)
	end)

	valueBox.FocusLost:Connect(function()
		Tween(boxStroke, { Transparency = State.Theme.StrokeAlpha }, 0.15)
		local number = tonumber((valueBox.Text:gsub("[^%d%.%-]", "")))
		if number then
			element:Set(number)
		end
		render(false)
	end)

	render(true)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Spinner"] = function(...)
--[[
	Components/Spinner
	Row with a title / description and an animated loading ring.

	local loading = Tab:Spinner({
		Title    = "Loading data",
		Desc     = "Fetching server list...",
		Spinning = true,               -- start immediately (default true)
	})
	loading:Stop() / loading:Start()
	loading:SetText("Still loading...")
	loading:SetDone("Loaded 24 servers")   -- shows a check mark and stops
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween
local RunService = game:GetService("RunService")

local SIZE = 20
local SPEED = 360 -- degrees per second

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		RightSize = UDim.new(0, SIZE + 4),
	})
	local holder = element.Instance

	local slot = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(SIZE, SIZE),
		BackgroundTransparency = 1,
		Parent = holder,
	})

	-- Ring: a stroke whose transparency fades around the circle
	local ring = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = slot,
	}, { Utility.Corner(999) })
	local ringStroke = Create("UIStroke", { Thickness = 2.5, Parent = ring })
	Theme.Bind(ringStroke, { Color = "Accent" })
	Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.75, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = ringStroke,
	})

	-- Check mark (two bars) shown by :SetDone
	local check = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = slot,
	})
	local short = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -4, 0.5, 2),
		Size = UDim2.fromOffset(7, 2.5),
		Rotation = 45,
		BorderSizePixel = 0,
		Parent = check,
	}, { Utility.Corner(2) })
	local long = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 2, 0.5, 0),
		Size = UDim2.fromOffset(12, 2.5),
		Rotation = -50,
		BorderSizePixel = 0,
		Parent = check,
	}, { Utility.Corner(2) })
	local successColor = Color3.fromRGB(34, 197, 94)
	short.BackgroundColor3 = successColor
	long.BackgroundColor3 = successColor

	local connection

	function element:Start()
		check.Visible = false
		ring.Visible = true
		if connection then
			return
		end
		connection = Utility.Track(RunService.Heartbeat:Connect(function(dt)
			if not ring.Parent then
				connection:Disconnect()
				connection = nil
				return
			end
			ring.Rotation = (ring.Rotation + SPEED * dt) % 360
		end))
	end

	function element:Stop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end

	function element:IsSpinning()
		return connection ~= nil
	end

	function element:SetText(text)
		element:SetDesc(text)
	end

	function element:SetDone(text)
		element:Stop()
		ring.Visible = false
		check.Visible = true
		local scale = check:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = check })
		scale.Scale = 0.6
		Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		if text then
			element:SetDesc(text)
		end
	end

	if options.Spinning ~= false then
		element:Start()
	end
	return element
end
end

__modules["Components/StatTiles"] = function(...)
--[[
	Components/StatTiles
	A row of 2-4 compact stat tiles: [icon] Label / big Value.

	local stats = Tab:StatTiles({
		Tiles = {
			{ Title = "Speed",     Value = "0/min", Icon = "activity" },
			{ Title = "Remaining", Value = "—",     Icon = "target", Color = Color3.fromRGB(56, 189, 248) },
			{ Title = "Time left", Value = "—",     Icon = "clock",  Color = Color3.fromRGB(251, 191, 36) },
		},
	})
	stats:Set("Speed", "120/min")      -- by title (case-insensitive) or index
	stats:Set(2, 86)
	stats:SetColor("Time left", Color3.fromRGB(239, 68, 68))
	stats:Get("Speed") -> "120/min"
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create = Utility.Create

local GAP = 8
local HEIGHT = 60

return function(tab, options)
	options = options or {}
	local specs = options.Tiles or {}
	local count = math.clamp(#specs, 1, 4)

	local row = Create("Frame", {
		Name = "StatTiles",
		Size = UDim2.new(1, 0, 0, HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.List(GAP, Enum.FillDirection.Horizontal) })

	local tiles = {} -- array of { Spec, Value, Icon, ValueLabel, TitleLabel, Color }

	local function tileColor(tile)
		return tile.Color or State.Theme.Accent
	end

	for index = 1, count do
		local spec = specs[index]
		local tile = Create("Frame", {
			Size = UDim2.new(1 / count, -GAP * (count - 1) / count, 1, 0),
			BackgroundTransparency = Constants.Glass.Element,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Parent = row,
		}, { Utility.Corner(11), Utility.Padding(10, 10, 12, 12) })
		Theme.Bind(tile, { BackgroundColor3 = "Element" })
		Builders.Stroke().Parent = tile

		local header = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Parent = tile,
		}, { Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

		local icon
		if spec.Icon then
			icon = Create("ImageLabel", {
				Size = UDim2.fromOffset(13, 13),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
				Parent = header,
			})
			Assets.Apply(icon, spec.Icon)
		end

		local titleLabel = Builders.Label({
			Text = spec.Title or ("Stat " .. index),
			Font = Constants.Fonts.Medium,
			TextSize = 11,
			ThemeColor = "SubText",
			Size = UDim2.new(1, icon and -19 or 0, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 2,
			Parent = header,
		})

		local valueLabel = Builders.Label({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 22),
			Font = Constants.Fonts.Bold,
			TextSize = 18,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = tostring(spec.Value or "—"),
			Parent = tile,
		})

		tiles[index] = {
			Title = spec.Title or "",
			Value = spec.Value,
			Color = spec.Color,
			Icon = icon,
			TitleLabel = titleLabel,
			ValueLabel = valueLabel,
		}
		if icon then
			icon.ImageColor3 = tileColor(tiles[index])
		end

	end

	-- One search entry for the whole row: matches any tile title
	if tab._searchables then
		local titles = {}
		for _, tile in ipairs(tiles) do
			table.insert(titles, tile.Title)
		end
		local searchLabel = Create("TextLabel", {
			Name = "SearchIndex",
			Text = table.concat(titles, " "),
			Visible = false,
			Parent = row,
		})
		table.insert(tab._searchables, { Instance = row, Label = searchLabel })
	end

	local function find(key)
		if type(key) == "number" then
			return tiles[key]
		end
		local wanted = string.lower(tostring(key))
		for _, tile in ipairs(tiles) do
			if string.lower(tile.Title) == wanted then
				return tile
			end
		end
		return nil
	end

	local api = { Instance = row, Tiles = tiles }

	function api:Set(key, value)
		local tile = find(key)
		if tile then
			tile.Value = value
			tile.ValueLabel.Text = tostring(value)
		end
	end

	function api:Get(key)
		local tile = find(key)
		return tile and tile.Value
	end

	function api:SetColor(key, color)
		local tile = find(key)
		if tile then
			tile.Color = color
			if tile.Icon then
				tile.Icon.ImageColor3 = tileColor(tile)
			end
		end
	end

	function api:SetVisible(visible)
		row.Visible = visible
	end

	function api:Destroy()
		row:Destroy()
	end

	Theme.OnChange(function()
		for _, tile in ipairs(tiles) do
			if tile.Icon then
				tile.Icon.ImageColor3 = tileColor(tile)
			end
		end
	end)

	return api
end
end

__modules["Components/Stepper"] = function(...)
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
end

__modules["Components/SubTabs"] = function(...)
--[[
	Components/SubTabs
	Segmented bar of sub-pages inside a tab, with a sliding accent pill.

	local sub = Tab:SubTabs({
		Tabs     = { "Aimbot", "ESP", "Misc" },
		Default  = "Aimbot",           -- optional, name or index
		Callback = function(name) end, -- fired when switching
	})
	sub:Get("ESP"):Toggle({ Title = "Boxes" })   -- or sub[2]
	sub:Select("Misc") / sub:GetActive() -> name
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local BAR_HEIGHT = 34
local INSET = 3

return function(tab, options)
	options = options or {}
	local names = options.Tabs or options.Values or { "Tab" }
	local count = #names

	local holder = Create("Frame", {
		Name = "SubTabs",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.List(8) })

	---------------------------------------------------------------- bar
	local bar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = holder,
	}, { Utility.Corner(9) })
	Theme.Bind(bar, { BackgroundColor3 = "Field" })
	Builders.Stroke().Parent = bar

	local track = Create("Frame", {
		Position = UDim2.fromOffset(INSET, INSET),
		Size = UDim2.new(1, -INSET * 2, 1, -INSET * 2),
		BackgroundTransparency = 1,
		Parent = bar,
	})

	local pill = Create("Frame", {
		Size = UDim2.new(1 / count, 0, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = track,
	}, { Utility.Corner(7) })
	Theme.Bind(pill, { BackgroundColor3 = "Accent" })

	---------------------------------------------------------------- pages
	local pagesHolder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})

	local subtabs = { Instance = holder }
	local entries = {} -- [index] = { Name, Button, Page, Container }
	local byName = {}
	local activeIndex

	local function render(instant)
		local theme = State.Theme
		for index, entry in ipairs(entries) do
			local active = index == activeIndex
			Tween(entry.Button, {
				TextColor3 = active and Color3.new(1, 1, 1) or theme.SubText,
			}, instant and 0 or 0.2)
		end
		if activeIndex then
			Tween(pill, { Position = UDim2.fromScale((activeIndex - 1) / count, 0) }, instant and 0 or 0.3)
		end
	end

	local function selectTab(target, instant)
		local index = type(target) == "number" and target or byName[target]
		if not index or not entries[index] or index == activeIndex then
			return
		end

		local previous = entries[activeIndex or 0]
		activeIndex = index
		local entry = entries[index]

		if previous then
			previous.Page.Visible = false
		end
		entry.Page.Visible = true
		if not instant then
			entry.Page.Position = UDim2.fromOffset(0, 10)
			Tween(entry.Page, { Position = UDim2.fromOffset(0, 0) }, 0.3)
		end

		render(instant)
		if not instant then
			Utility.SafeCall(options.Callback, entry.Name)
		end
	end

	for index, name in ipairs(names) do
		local button = Create("TextButton", {
			Name = tostring(name),
			Position = UDim2.fromScale((index - 1) / count, 0),
			Size = UDim2.new(1 / count, 0, 1, 0),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Font = Constants.Fonts.Medium,
			TextSize = 12,
			Text = tostring(name),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
			Parent = track,
		})
		Theme.Bind(button, { TextColor3 = "SubText" })

		local page = Create("Frame", {
			Name = tostring(name) .. "_Page",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
			Parent = pagesHolder,
		}, { Utility.List(6) })

		local container = tab:_Child(page)
		container.Instance = page

		entries[index] = { Name = name, Button = button, Page = page, Container = container }
		byName[name] = index
		subtabs[index] = container

		button.MouseEnter:Connect(function()
			if index ~= activeIndex then
				Tween(button, { TextColor3 = State.Theme.Text }, 0.15)
			end
		end)
		button.MouseLeave:Connect(function()
			if index ~= activeIndex then
				Tween(button, { TextColor3 = State.Theme.SubText }, 0.15)
			end
		end)
		button.MouseButton1Click:Connect(function()
			selectTab(index)
		end)
	end

	---------------------------------------------------------------- API
	function subtabs:Get(target)
		local index = type(target) == "number" and target or byName[target]
		return index and entries[index] and entries[index].Container or nil
	end

	function subtabs:Select(target)
		selectTab(target)
	end

	function subtabs:GetActive()
		return activeIndex and entries[activeIndex].Name or nil
	end

	function subtabs:Destroy()
		holder:Destroy()
	end

	Theme.OnChange(function()
		render(true)
	end)

	selectTab(options.Default or 1, true)
	return subtabs
end
end

__modules["Components/Swatches"] = function(...)
--[[
	Components/Swatches
	Row of round color swatches; pick one. Great for an accent-color setting.

	Tab:Swatches({
		Title  = "Accent color",
		Colors = {
			{ "Violet", Color3.fromRGB(124, 92, 255) },
			{ "Blue", Color3.fromRGB(59, 130, 246) },
			{ "Rose", Color3.fromRGB(244, 63, 94) },
		},
		Value    = "Violet",
		Flag     = "Accent",
		Callback = function(color, name) UI:SetAccent(color) end,
	})
	:Set(name, silent) / :Get() -> name, color
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local SIZE = 28

local DEFAULT_COLORS = {
	{ "Violet", Color3.fromRGB(124, 92, 255) },
	{ "Blue", Color3.fromRGB(59, 130, 246) },
	{ "Rose", Color3.fromRGB(244, 63, 94) },
	{ "Emerald", Color3.fromRGB(16, 185, 129) },
	{ "Amber", Color3.fromRGB(245, 158, 11) },
}

return function(tab, options)
	options = options or {}
	local colors = options.Colors or DEFAULT_COLORS

	local element = Element.new(tab, options, { Hover = false })

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, SIZE + 6),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = element.TextHolder,
	}, { Utility.List(10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center), Utility.Padding(4, 0, 2, 0) })

	element.Value = options.Value or options.Default or colors[1][1]
	local rings = {} -- [name] = UIStroke

	local function colorOf(name)
		for _, pair in ipairs(colors) do
			if pair[1] == name then
				return pair[2]
			end
		end
		return nil
	end

	local function render()
		for name, ring in pairs(rings) do
			local selected = name == element.Value
			Tween(ring, { Transparency = selected and 0 or 1 }, 0.15)
			ring.Color = State.Theme.Text
		end
	end

	for index, pair in ipairs(colors) do
		local name, color = pair[1], pair[2]
		local swatch = Create("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(SIZE, SIZE),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			Parent = row,
		}, { Utility.Corner(999) })
		local ring = Create("UIStroke", {
			Thickness = 2.5,
			Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = swatch,
		})
		local scale = Create("UIScale", { Parent = swatch })
		rings[name] = ring

		swatch.MouseEnter:Connect(function()
			Tween(scale, { Scale = 1.1 }, 0.15, Enum.EasingStyle.Back)
		end)
		swatch.MouseLeave:Connect(function()
			Tween(scale, { Scale = 1 }, 0.15)
		end)
		swatch.MouseButton1Click:Connect(function()
			element:Set(name)
		end)
	end

	function element:Set(name, silent)
		if not colorOf(name) then
			return
		end
		element.Value = name
		render()
		if not silent then
			Utility.SafeCall(options.Callback, colorOf(name), name)
		end
	end

	function element:Get()
		return element.Value, colorOf(element.Value)
	end

	render()
	Theme.OnChange(render)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/TaskCard"] = function(...)
--[[
	Components/TaskCard
	Status + progress + Start/Stop control for any long-running job
	(auto clear, auto farm, auto fish...). One card owns the whole lifecycle:

		idle ──Start──▶ running ──Stop──▶ paused ──Resume──▶ running
		  ▲                │                                    │
		  └──── Reset ─────┴──────────── progress == total ─────▶ done ──Run again──▶ running

	local job = Tab:TaskCard({
		Title       = "Auto Clear",          -- optional, also makes the card searchable
		Unit        = "tiles",               -- "86 / 180 tiles"
		StartText   = "Start Sweep",         -- also: StopText, ResumeText, AgainText
		IdleText    = "Press Start to scan the world",
		MiniStatus  = "Clearing",            -- minimized pill shows "Clearing · 45%" (false = off)
		OnStart     = function(job) end,     -- from idle/done; runs in its own thread
		OnStop      = function(job) end,     -- running -> paused
		OnResume    = function(job) end,     -- paused -> running
		OnComplete  = function(job) end,     -- progress reached total
		OnReset     = function(job) end,     -- reset button (hidden when ResetButton = false)
	})

	Typical worker:
		OnStart = function(job)
			local tiles = findTiles()
			job:SetTotal(#tiles)
			for _, tile in ipairs(tiles) do
				if not job:WaitIfPaused() then return end   -- false once reset/stopped for good
				breakTile(tile)
				job:Increment()
			end
		end

	Methods: :Start() :Stop() :Resume() :Toggle() :Reset() :Complete()
	         :SetTotal(n) :SetProgress(n) :Increment(k) :SetStatus(state, text?)
	         :SetSubtitle(text?) :GetStatus() :IsRunning() :GetElapsed() :GetProgress()
	         :WaitIfPaused() :SetTitle(text) :SetVisible(bool) :Destroy()
	States : "idle" | "preparing" | "running" | "paused" | "done"
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween
local RunService = game:GetService("RunService")
local TweenService = Services.TweenService

local STATES = {
	idle = { Label = "Idle", Color = "SubText" },
	preparing = { Label = "Preparing", Color = Color3.fromRGB(56, 189, 248) },
	running = { Label = "Running", Color = Constants.NotifyColors.Success },
	paused = { Label = "Paused", Color = Constants.NotifyColors.Warning },
	done = { Label = "Completed", Color = Constants.NotifyColors.Success },
}

local function stateColor(name)
	local color = STATES[name].Color
	return typeof(color) == "Color3" and color or State.Theme[color]
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor(seconds / 60) % 60
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%02d:%02d", minutes, secs)
end

return function(tab, options)
	options = options or {}
	local unit = options.Unit or "items"

	---------------------------------------------------------------- state
	local status = "idle"
	local total, progress, elapsed = 0, 0, 0
	local customSubtitle = nil
	local alive = true

	---------------------------------------------------------------- card
	local holder = Create("Frame", {
		Name = options.Title or "TaskCard",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(12),
		Utility.Padding(14, 14, 14, 14),
		Utility.List(12),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	local stroke = Builders.Stroke()
	stroke.Parent = holder

	-- status tint across the card
	local tint = Create("UIGradient", {
		Rotation = 25,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.6, 0.35),
			NumberSequenceKeypoint.new(1, 0.35),
		}),
		Parent = holder,
	})

	---------------------------------------------------------------- row 1: [title] [status pill] ........ [timer]
	local topRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})
	local left = Create("Frame", {
		Size = UDim2.new(1, -90, 1, 0),
		BackgroundTransparency = 1,
		Parent = topRow,
	}, { Utility.List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	local titleLabel
	if options.Title then
		titleLabel = Builders.Label({
			Text = options.Title,
			Font = Constants.Fonts.Bold,
			TextSize = 14,
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 1,
			Parent = left,
		})
	end

	local pill = Create("Frame", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = left,
	}, {
		Utility.Corner(999),
		Utility.Padding(0, 0, 10, 10),
		Utility.List(7, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
	})
	local pillDot = Create("Frame", {
		Size = UDim2.fromOffset(7, 7),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = pill,
	}, { Utility.Corner(999) })
	local pillLabel = Create("TextLabel", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Bold,
		TextSize = 12,
		LayoutOrder = 2,
		Parent = pill,
	})

	local timerLabel = Builders.Label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 90, 1, 0),
		Font = Constants.Fonts.Mono,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "00:00",
		Parent = topRow,
	})

	---------------------------------------------------------------- row 2: count + subtitle ........ percent
	local countRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})
	local countLabel = Builders.Label({
		Size = UDim2.new(1, -70, 0, 30),
		Font = Constants.Fonts.Bold,
		TextSize = 26,
		RichText = true,
		Parent = countRow,
	})
	local subtitleLabel = Builders.Label({
		Position = UDim2.fromOffset(0, 31),
		Size = UDim2.new(1, -70, 0, 15),
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = countRow,
	})
	local percentLabel = Builders.Label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.new(0, 70, 0, 26),
		Font = Constants.Fonts.Bold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = countRow,
	})

	---------------------------------------------------------------- row 3: progress bar (+ moving shine while running)
	local track = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 3,
		Parent = holder,
	}, { Utility.Corner(999) })
	Theme.Bind(track, { BackgroundColor3 = "ToggleOff" })

	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = track,
	}, { Utility.Corner(999) })

	local shine = Create("Frame", {
		Size = UDim2.fromScale(0.35, 1),
		Position = UDim2.fromScale(-0.4, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Visible = false,
		Parent = fill,
	}, {
		Create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.65),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	local shineTween = TweenService:Create(
		shine,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
		{ Position = UDim2.fromScale(1.1, 0) }
	)

	---------------------------------------------------------------- row 4: [ main action ] [reset]
	local actions = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = holder,
	})
	local showReset = options.ResetButton ~= false

	local mainButton = Create("TextButton", {
		Size = UDim2.new(1, showReset and -48 or 0, 1, 0),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Text = "",
		Parent = actions,
	}, { Utility.Corner(10) })
	local mainStroke = Create("UIStroke", {
		Thickness = 1,
		Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = mainButton,
	})
	local mainScale = Create("UIScale", { Parent = mainButton })
	local mainContent = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = mainButton,
	}, { Utility.List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	local mainIcon = Create("ImageLabel", {
		Size = UDim2.fromOffset(15, 15),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		LayoutOrder = 1,
		Parent = mainContent,
	})
	local mainLabel = Create("TextLabel", {
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Bold,
		TextSize = 13,
		LayoutOrder = 2,
		Parent = mainContent,
	})

	local resetButton
	if showReset then
		resetButton = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = Constants.Glass.Field,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = actions,
		}, { Utility.Corner(10) })
		Theme.Bind(resetButton, { BackgroundColor3 = "Field" })
		Builders.Stroke().Parent = resetButton
		local resetIcon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Parent = resetButton,
		})
		Assets.Apply(resetIcon, "refresh")
		Theme.Bind(resetIcon, { ImageColor3 = "SubText" })
		resetButton.MouseEnter:Connect(function()
			Tween(resetButton, { BackgroundColor3 = State.Theme.ElementHover }, 0.15)
		end)
		resetButton.MouseLeave:Connect(function()
			Tween(resetButton, { BackgroundColor3 = State.Theme.Field }, 0.15)
		end)
	end

	---------------------------------------------------------------- rendering
	local job = { Instance = holder, TitleLabel = titleLabel }
	local rootTab = tab
	while rootTab.Parent do
		rootTab = rootTab.Parent
	end

	local function percent()
		return total > 0 and math.floor(progress / total * 100 + 0.5) or 0
	end

	local function autoSubtitle()
		local remaining = math.max(0, total - progress)
		if status == "idle" then
			return options.IdleText or "Press Start to begin"
		elseif status == "preparing" then
			return options.PreparingText or "Preparing..."
		elseif status == "running" then
			if total <= 0 then
				return "Working..."
			end
			local rate = elapsed > 1 and progress / elapsed or 0
			local eta = rate > 0 and (" · about " .. formatTime(remaining / rate) .. " left") or ""
			return remaining .. " " .. unit .. " left" .. eta
		elseif status == "paused" then
			return "Paused · " .. remaining .. " " .. unit .. " left"
		else
			return "Finished · " .. progress .. " " .. unit .. " in " .. formatTime(elapsed)
		end
	end

	local function renderButton()
		local accent = State.Theme.Accent
		local danger = Constants.Danger
		local icon, text
		if status == "running" or status == "preparing" then
			icon, text = "pause", options.StopText or "Stop"
			Tween(mainButton, { BackgroundColor3 = danger, BackgroundTransparency = 0.86 }, 0.2)
			mainStroke.Color = danger
			mainStroke.Transparency = 0.5
			mainLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
		else
			if status == "paused" then
				icon, text = "play", options.ResumeText or "Resume"
			elseif status == "done" then
				icon, text = "refresh", options.AgainText or "Run again"
			else
				icon, text = "play", options.StartText or "Start"
			end
			Tween(mainButton, { BackgroundColor3 = accent, BackgroundTransparency = 0 }, 0.2)
			mainStroke.Transparency = 1
			mainLabel.TextColor3 = Color3.new(1, 1, 1)
		end
		mainLabel.Text = text
		mainIcon.ImageColor3 = mainLabel.TextColor3
		Assets.Apply(mainIcon, icon)
	end

	local function renderMiniStatus()
		if options.MiniStatus == false or not tab.Window or not tab.Window.SetStatus then
			return
		end
		if status == "running" then
			local label = type(options.MiniStatus) == "string" and options.MiniStatus or (options.Title or "Running")
			tab.Window:SetStatus(label .. " · " .. percent() .. "%", Constants.NotifyColors.Success)
		elseif status == "paused" then
			tab.Window:SetStatus("Paused · " .. percent() .. "%", Constants.NotifyColors.Warning)
		else
			tab.Window:SetStatus(nil)
		end
	end

	local function renderProgress(instant)
		local pct = percent()
		countLabel.Text = string.format(
			'%d<font size="15" color="#%s"> / %d %s</font>',
			progress,
			State.Theme.SubText:ToHex(),
			total,
			unit
		)
		percentLabel.Text = pct .. "%"
		percentLabel.TextColor3 = status == "done" and Constants.NotifyColors.Success or State.Theme.Text
		subtitleLabel.Text = customSubtitle or autoSubtitle()
		Tween(fill, { Size = UDim2.fromScale(total > 0 and progress / total or 0, 1) }, instant and 0 or 0.3)
		renderMiniStatus()
	end

	local function renderStatus()
		local color = stateColor(status)
		pillLabel.Text = (status == "preparing" and options.PreparingLabel) or STATES[status].Label
		pillLabel.TextColor3 = color
		pillDot.BackgroundColor3 = color
		pill.BackgroundColor3 = color
		tint.Color = ColorSequence.new(
			(status == "idle" and State.Theme.Accent or color):Lerp(State.Theme.Element, 0.82),
			State.Theme.Element
		)
		stroke.Color = (status == "running" or status == "paused") and color or State.Theme.Stroke
		stroke.Transparency = (status == "running" or status == "paused") and 0.6 or State.Theme.StrokeAlpha

		local fillColor = status == "done" and Constants.NotifyColors.Success
			or status == "paused" and Constants.NotifyColors.Warning
			or State.Theme.Accent
		Tween(fill, { BackgroundColor3 = fillColor }, 0.2)

		local active = status == "running"
		shine.Visible = active
		if active then
			shineTween:Play()
		else
			shineTween:Cancel()
			shine.Position = UDim2.fromScale(-0.4, 0)
		end

		if rootTab.SetLive then
			rootTab:SetLive(active or status == "preparing")
		end
		renderButton()
		renderProgress(true)
	end

	local function setStatus(newStatus)
		assert(STATES[newStatus], "TaskCard: unknown status " .. tostring(newStatus))
		status = newStatus
		renderStatus()
	end

	---------------------------------------------------------------- timer
	local timerAccumulator = 0
	Utility.Track(RunService.Heartbeat:Connect(function(dt)
		if status ~= "running" and status ~= "preparing" then
			return
		end
		elapsed += dt
		timerAccumulator += dt
		if timerAccumulator >= 0.25 then
			timerAccumulator = 0
			timerLabel.Text = formatTime(elapsed)
			if not customSubtitle then
				subtitleLabel.Text = autoSubtitle()
			end
		end
	end))

	---------------------------------------------------------------- lifecycle API
	function job:GetStatus()
		return status
	end

	function job:IsRunning()
		return status == "running" or status == "preparing"
	end

	function job:GetElapsed()
		return elapsed
	end

	-- progress, total, percent (0-100)
	function job:GetProgress()
		return progress, total, percent()
	end

	function job:Start()
		if job:IsRunning() then
			return
		end
		if status == "paused" then
			return job:Resume()
		end
		progress, elapsed, customSubtitle = 0, 0, nil
		timerLabel.Text = "00:00"
		setStatus("running")
		Utility.SafeCall(options.OnStart, job)
	end

	function job:Stop()
		if not job:IsRunning() then
			return
		end
		setStatus("paused")
		Utility.SafeCall(options.OnStop, job)
	end

	function job:Resume()
		if status ~= "paused" then
			return
		end
		setStatus("running")
		Utility.SafeCall(options.OnResume, job)
	end

	function job:Toggle()
		if job:IsRunning() then
			job:Stop()
		elseif status == "paused" then
			job:Resume()
		else
			job:Start()
		end
	end

	function job:Complete()
		if status == "done" then
			return
		end
		if total > 0 then
			progress = total
		end
		setStatus("done")
		Utility.SafeCall(options.OnComplete, job)
	end

	function job:Reset()
		total, progress, elapsed, customSubtitle = 0, 0, 0, nil
		timerLabel.Text = "00:00"
		setStatus("idle")
		Utility.SafeCall(options.OnReset, job)
	end

	-- "preparing" while scanning, etc.; optional custom subtitle
	function job:SetStatus(newStatus, subtitle)
		customSubtitle = subtitle
		setStatus(newStatus)
	end

	function job:SetSubtitle(text)
		customSubtitle = text
		renderProgress(true)
	end

	function job:SetTotal(n)
		total = math.max(0, math.floor(n or 0))
		progress = math.min(progress, total)
		if status == "preparing" then
			setStatus("running")
		else
			renderProgress()
		end
	end

	function job:SetProgress(n)
		progress = math.clamp(math.floor(n or 0), 0, total > 0 and total or math.huge)
		if total > 0 and progress >= total and job:IsRunning() then
			job:Complete()
		else
			renderProgress()
		end
	end

	function job:Increment(amount)
		job:SetProgress(progress + (amount or 1))
	end

	-- For worker loops: yields while paused. Returns false once the job was
	-- reset/completed/destroyed, so the loop knows to exit.
	function job:WaitIfPaused()
		while alive and status == "paused" do
			task.wait(0.1)
		end
		return alive and job:IsRunning()
	end

	function job:SetTitle(text)
		if titleLabel then
			titleLabel.Text = text
		end
	end

	function job:SetVisible(visible)
		holder.Visible = visible
	end

	function job:Destroy()
		alive = false
		shineTween:Cancel()
		holder:Destroy()
	end

	---------------------------------------------------------------- input
	Utility.Track(mainButton.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			Builders.Ripple(mainButton, input.Position)
		end
	end))
	mainButton.MouseEnter:Connect(function()
		Tween(mainScale, { Scale = 1.01 }, 0.15)
	end)
	mainButton.MouseLeave:Connect(function()
		Tween(mainScale, { Scale = 1 }, 0.15)
	end)
	mainButton.MouseButton1Click:Connect(function()
		Builders.Press(mainScale)
		job:Toggle()
	end)
	if resetButton then
		resetButton.MouseButton1Click:Connect(function()
			job:Reset()
		end)
	end

	if titleLabel and tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	Theme.OnChange(renderStatus)
	renderStatus()
	Element.RegisterFlag(options, job)
	return job
end
end

__modules["Components/TextArea"] = function(...)
--[[
	Components/TextArea
	Multi-line text input with an optional character counter.

	local notes = Tab:TextArea({
		Title       = "Notes",
		Placeholder = "Write something...",
		Default     = "",
		Lines       = 4,        -- visible lines
		MaxLength   = 200,      -- optional, shows "12/200"
		Live        = false,    -- true: callback on every change, false: on focus lost
		Flag        = "Notes",
		Callback    = function(text) end,
	})
	notes:Set("text") / notes:Get() / notes:SetPlaceholder("...")
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local LINE_HEIGHT = 16
local HEADER = 36
local COUNTER = 16

return function(tab, options)
	options = options or {}
	local lines = options.Lines or 4
	local maxLength = options.MaxLength
	local fieldHeight = lines * LINE_HEIGHT + 16
	local totalHeight = HEADER + fieldHeight + (maxLength and COUNTER or 0) + 12

	local element = Element.new(tab, options, {
		Hover = true,
		Height = totalHeight,
		Auto = false,
	})
	local holder = element.Instance

	element.TextHolder.Size = UDim2.new(1, -(element.TextHolder.Position.X.Offset + 12), 0, HEADER)
	element.TextHolder:FindFirstChildOfClass("UIPadding").PaddingBottom = UDim.new(0, 0)
	element.DescLabel.Visible = false
	if element.IconLabel then
		element.IconLabel.AnchorPoint = Vector2.new(0, 0)
		element.IconLabel.Position = UDim2.fromOffset(12, 9)
	end

	local field = Create("Frame", {
		Position = UDim2.fromOffset(10, HEADER),
		Size = UDim2.new(1, -20, 0, fieldHeight),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
	}, { Utility.Corner(6) })
	Theme.Bind(field, { BackgroundColor3 = "Field" })
	local fieldStroke = Builders.Stroke()
	fieldStroke.Parent = field

	local box = Create("TextBox", {
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 1, -16),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		LineHeight = 1.15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		MultiLine = true,
		ClearTextOnFocus = false,
		PlaceholderText = options.Placeholder or "Type here...",
		Text = tostring(options.Default or options.Value or ""),
		Parent = field,
	})
	Theme.Bind(box, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	local counter
	if maxLength then
		counter = Builders.Label({
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -12, 1, -8),
			Size = UDim2.fromOffset(80, COUNTER),
			Font = Constants.Fonts.Regular,
			TextSize = 11,
			ThemeColor = "SubText",
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = holder,
		})
	end

	local function updateCounter()
		if counter then
			local full = #box.Text >= maxLength
			counter.Text = #box.Text .. "/" .. maxLength
			counter.TextColor3 = full and Constants.Danger or State.Theme.SubText
		end
	end

	local function sanitize(text)
		if maxLength and #text > maxLength then
			return text:sub(1, maxLength)
		end
		return text
	end

	element.Value = sanitize(box.Text)

	box:GetPropertyChangedSignal("Text"):Connect(function()
		local clean = sanitize(box.Text)
		if clean ~= box.Text then
			box.Text = clean -- re-fires with the trimmed value
			return
		end
		element.Value = clean
		updateCounter()
		if options.Live then
			Utility.SafeCall(options.Callback, clean)
		end
	end)

	box.Focused:Connect(function()
		Tween(fieldStroke, { Color = State.Theme.Accent, Transparency = 0.2 }, 0.18)
	end)

	box.FocusLost:Connect(function()
		Tween(fieldStroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.18)
		if not options.Live then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end)

	function element:Set(text, silent)
		box.Text = sanitize(tostring(text or ""))
		element.Value = box.Text
		updateCounter()
		if not silent and not options.Live then
			Utility.SafeCall(options.Callback, element.Value)
		end
	end

	function element:Get()
		return element.Value
	end

	function element:SetPlaceholder(text)
		box.PlaceholderText = text
	end

	updateCounter()
	Theme.OnChange(updateCounter)
	Element.RegisterFlag(options, element)
	return element
end
end

__modules["Components/Toggle"] = function(...)
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
end

__modules["Components/WorldMap/Distribution"] = function(...)
--[[
	Components/WorldMap/Distribution
	Count of every tile id on a layer, biggest first, with bars and SKIP tags.
	Clicking a row highlights that id on the map.

	local dist = Distribution.new(parent, palette, { Limit = 8, OnSelect = fn(id) })
	dist:Set(counts, total, selectedId, title)
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Parts = import("Components/WorldMap/Parts")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local ROW_HEIGHT = 36

local Distribution = {}
Distribution.__index = Distribution

local function format(number)
	local text = tostring(number)
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end
Distribution.FormatNumber = format

function Distribution.new(parent, palette, options)
	options = options or {}
	local self = setmetatable({ Palette = palette, _rows = {}, _onSelect = options.OnSelect }, Distribution)
	self.Limit = options.Limit or 8

	local root = Create("Frame", {
		Name = "Distribution",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = options.LayoutOrder or 0,
		Parent = parent,
	}, { Utility.List(4) })
	self.Instance = root

	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = root,
	})
	self._title = Builders.Label({
		Text = "Tiles",
		Font = Fonts.Bold,
		TextSize = 13,
		Size = UDim2.fromScale(0.6, 1),
		Parent = header,
	})
	self._total = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 11,
		ThemeColor = "SubText",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.4, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	self._list = root
	self._more = Builders.Label({
		Text = "",
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 999,
		Visible = false,
		Parent = root,
	})

	self._footer = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = 1000,
		Visible = options.Footer ~= nil,
		Parent = root,
	})
	Builders.Label({
		Text = options.Footer or "",
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.6, 1),
		Parent = self._footer,
	})
	self._footerValue = Builders.Label({
		Text = "",
		Font = Fonts.Bold,
		TextSize = 12,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.4, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = self._footer,
	})
	self._footerValue.TextColor3 = Parts.Colors.Success

	return self
end

function Distribution:_row(index)
	local row = self._rows[index]
	if row then
		return row
	end

	local button = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = index,
		Parent = self._list,
	}, { Corner(7), Utility.Padding(0, 0, 6, 6) })
	Theme.Bind(button, { BackgroundColor3 = "Accent" })

	local swatch = Create("Frame", {
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.fromOffset(10, 10),
		BorderSizePixel = 0,
		Parent = button,
	}, { Corner(3) })

	local line = Create("Frame", {
		Position = UDim2.fromOffset(16, 4),
		Size = UDim2.new(1, -16, 0, 18),
		BackgroundTransparency = 1,
		Parent = button,
	}, { Utility.List(6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	local name = Builders.Label({
		Text = "",
		Font = Fonts.Medium,
		TextSize = 12,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
		Parent = line,
	})
	local id = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 10,
		ThemeColor = "Placeholder",
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = line,
	})
	local tag = Parts.Tag(line, 3)

	local count = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 11,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 4),
		Size = UDim2.fromOffset(70, 18),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = button,
	})

	local track = Create("Frame", {
		Position = UDim2.fromOffset(16, 26),
		Size = UDim2.new(1, -16, 0, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		Parent = button,
	}, { Corner(999) })
	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, { Corner(999) })

	row = { Button = button, Swatch = swatch, Name = name, Id = id, Tag = tag, Count = count, Fill = fill, Value = nil }
	button.MouseEnter:Connect(function()
		if not row.Selected then
			Tween(button, { BackgroundTransparency = 0.94 }, 0.12)
		end
	end)
	button.MouseLeave:Connect(function()
		if not row.Selected then
			Tween(button, { BackgroundTransparency = 1 }, 0.12)
		end
	end)
	button.MouseButton1Click:Connect(function()
		if self._onSelect and row.Value ~= nil then
			self._onSelect(row.Value)
		end
	end)

	self._rows[index] = row
	return row
end

-- counts: { [id] = n }, selected: id | nil
function Distribution:Set(counts, total, selected, title, clearable)
	local ids = {}
	for id in pairs(counts) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		if counts[a] == counts[b] then
			return a < b
		end
		return counts[a] > counts[b]
	end)

	local maxCount = 1
	for _, id in ipairs(ids) do
		maxCount = math.max(maxCount, counts[id])
	end

	self._title.Text = title or "Tiles"
	self._total.Text = format(total) .. " total"

	local shown = math.min(#ids, self.Limit)
	for index = 1, shown do
		local id = ids[index]
		local row = self:_row(index)
		local palette = self.Palette
		row.Value = id
		row.Selected = selected == id
		row.Button.Visible = true
		row.Button.BackgroundTransparency = row.Selected and 0.84 or 1
		row.Swatch.BackgroundColor3 = id == 0 and Color3.fromRGB(38, 54, 79) or palette:Color(id)
		row.Name.Text = palette:Name(id)
		row.Id.Text = "#" .. tostring(id)
		row.Tag:Set((id ~= 0 and palette:IsSkip(id)) and "SKIP" or "", Parts.Colors.Danger)
		row.Count.Text = format(counts[id])
		row.Count.TextColor3 = Theme.Get().Text
		row.Fill.BackgroundColor3 = id == 0 and Parts.Colors.Muted or palette:Color(id)
		row.Fill.Size = UDim2.fromScale(math.max(0.02, counts[id] / maxCount), 1)
	end
	for index = shown + 1, #self._rows do
		self._rows[index].Button.Visible = false
		self._rows[index].Value = nil
	end

	self._more.Visible = #ids > shown
	self._more.Text = ("+ %d more tile types"):format(#ids - shown)

	if clearable then
		self._footerValue.Text = format(clearable) .. " tiles"
	end
end

return Distribution
end

__modules["Components/WorldMap"] = function(...)
--[[
	Components/WorldMap
	Live minimap of a tile world with a tile inspector and tile counts.

	local map = Tab:WorldMap({
		Title    = "World",
		Preset   = "Growblox",                 -- names, colors, skip set, surface row
		World    = function() return gs.world end, -- table with w, h, fg[row][col], bg[row][col]
		GetPlayer = function() return gs.px, gs.py end,
		ItemName = function(id) return gs.Items[id] and gs.Items[id].name end,
		Actions  = {
			{ Title = "Break tile", Primary = true,
			  Visible = function(tile) return tile.Fg ~= 0 and not tile.FgSkip end,
			  Callback = function(tile) print(tile.Col, tile.Row) end },
		},
	})

	Other data source: GetTile = function(col, row, layer) return id end + Width / Height.

	Options
		Title, Desc
		Preset            "Growblox" (or nil)
		World | GetTile   data source (see Scanner.lua)
		Width, Height, GetSize
		GetPlayer         function() -> px, py   (fractional col / row; floor() = tile)
		Items             { [id] = { Name, Color } }   ItemName = function(id) -> name
		Skip              { [id] = true }   tiles shown as SKIP and excluded from "clearable"
		Grass             { [id] = true }   draw a grass cap on exposed tiles
		Highlight         { ids }           quick filter chips for the fg layer
		Surface           row number | false  dashed guide line
		Background        false to hide the fg / bg layer switch
		Live = true, Interval = 2           auto rescan (only while the map is visible)
		ViewHeight = 320                    max map viewport height in pixels
		Zoom = 1                            1..4 (fit, 1.5x, 2x, 3x)
		Inspector = true, Distribution = true, DistributionLimit = 8
		Actions           inspector buttons, Callback(tile)
		OnSelect(tile), OnScan(snapshot)

	tile = { Col, Row, Fg, Bg, FgName, BgName, FgSkip, BgSkip, Distance }

	Methods
		:Refresh()                    rescan now
		:SetLive(bool) :SetInterval(seconds)
		:SetLayer("fg" | "bg") :SetFilter(id | nil) :SetZoom(1..4)
		:Select(col, row) :ClearSelection()
		:GetTile(col, row) -> tile
		:GetCounts("fg" | "bg") -> { [id] = n }
		:Find(id, layer?) -> { { Col, Row }, ... }
		:SetMarkers({ { Col, Row, Color? }, ... })   outline tiles (e.g. Auto Clear targets)
		:SetTitle(text) :SetVisible(bool) :Destroy()
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Palette = import("Components/WorldMap/Palette")
local Scanner = import("Components/WorldMap/Scanner")
local Renderer = import("Components/WorldMap/Renderer")
local Inspector = import("Components/WorldMap/Inspector")
local Distribution = import("Components/WorldMap/Distribution")
local Parts = import("Components/WorldMap/Parts")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local ZOOMS = { 1, 1.5, 2, 3 }
local PLAYER_TICK = 0.15
local SKY_TOP = Color3.fromRGB(27, 42, 68)
local SKY_LOW = Color3.fromRGB(34, 57, 90)
local GROUND = Color3.fromRGB(24, 24, 33)
local SURFACE = Color3.fromRGB(250, 204, 21)

local function isShown(instance)
	local current = instance
	while current and not current:IsA("LayerCollector") do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end
	return current ~= nil
end

local function divider(parent, order)
	local line = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.Bind(line, { BackgroundColor3 = "Stroke" })
	return line
end

return function(tab, options)
	options = options or {}
	local palette = Palette.new(options)
	local preset = palette.Preset
	local scanner = Scanner.new({
		World = options.World,
		GetTile = options.GetTile,
		GetSize = options.GetSize,
		Width = options.Width or preset.Width,
		Height = options.Height or preset.Height,
	})

	local map = {
		Snapshot = nil,
		Layer = "fg",
		Filter = nil,
		Live = options.Live ~= false,
		Interval = options.Interval or 2,
		ZoomIndex = math.clamp(options.Zoom or 1, 1, #ZOOMS),
		Selected = nil,
		Hover = nil,
		Player = nil,
		_alive = true,
		_lastScan = nil,
		_cell = 4,
		_markers = {},
	}
	local surfaceRow = options.Surface
	if surfaceRow == nil then
		surfaceRow = preset.Surface
	end

	---------------------------------------------------------------- card
	local holder = Create("Frame", {
		Name = options.Title or "WorldMap",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Corner(12), Utility.Padding(12, 12, 12, 12), Utility.List(10) })
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder
	map.Instance = holder

	-- Header ----------------------------------------------------------------
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})
	local titleLabel = Builders.Label({
		Text = options.Title or "World",
		Font = Fonts.Bold,
		TextSize = 14,
		Size = UDim2.new(1, -190, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	local scanLabel = Builders.Label({
		Text = options.Desc or "Not scanned yet",
		Font = Fonts.Regular,
		TextSize = 11,
		ThemeColor = "SubText",
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, -190, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	local headerRight = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = header,
	}, { Utility.List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })

	local liveChip = Parts.Chip(headerRight, {
		Text = "Live",
		Swatch = Parts.Colors.Success,
		Height = 26,
		LayoutOrder = 1,
		Callback = function()
			map:SetLive(not map.Live)
		end,
	})
	Parts.Button(headerRight, {
		Text = "Rescan",
		Icon = "refresh",
		Height = 26,
		LayoutOrder = 2,
		Callback = function()
			map:Refresh()
		end,
	})

	-- Toolbar: layer switch + zoom -----------------------------------------
	local toolbar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})
	local layerRow = Create("Frame", {
		Size = UDim2.new(0.6, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = toolbar,
	}, { Utility.List(5, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	local layerChips = {}
	if options.Background ~= false then
		for index, entry in ipairs({ { "fg", "Foreground" }, { "bg", "Background" } }) do
			layerChips[entry[1]] = Parts.Chip(layerRow, {
				Text = entry[2],
				Height = 26,
				LayoutOrder = index,
				Callback = function()
					map:SetLayer(entry[1])
				end,
			})
		end
	end

	local zoomRow = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = toolbar,
	}, { Utility.List(4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	Parts.Button(zoomRow, {
		Text = "-",
		Size = UDim2.fromOffset(26, 26),
		LayoutOrder = 1,
		Callback = function()
			map:SetZoom(map.ZoomIndex - 1)
		end,
	})
	local zoomLabel = Builders.Label({
		Text = "100%",
		Font = Fonts.Mono,
		TextSize = 11,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(40, 26),
		LayoutOrder = 2,
		Parent = zoomRow,
	})
	Parts.Button(zoomRow, {
		Text = "+",
		Size = UDim2.fromOffset(26, 26),
		LayoutOrder = 3,
		Callback = function()
			map:SetZoom(map.ZoomIndex + 1)
		end,
	})

	-- Highlight chips ----------------------------------------------------------
	local chipRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = holder,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})
	local filterChips = {}
	local chipKey = nil

	-- Map viewport -------------------------------------------------------------
	local viewport = Create("ScrollingFrame", {
		Name = "Viewport",
		Size = UDim2.new(1, 0, 0, 200),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		CanvasSize = UDim2.new(),
		LayoutOrder = 4,
		Parent = holder,
	}, { Corner(8) })
	Theme.Bind(viewport, { BackgroundColor3 = "Field", ScrollBarImageColor3 = "SubText" })

	local mapFrame = Create("Frame", {
		Name = "Map",
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = viewport,
	}, { Corner(4) })
	local skyGradient = Create("UIGradient", { Rotation = 90, Parent = mapFrame })

	local renderer = Renderer.new(mapFrame, palette)

	local surfaceLine = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = SURFACE,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 8,
		Visible = false,
		Parent = mapFrame,
	})

	local function outline(color, thickness, z)
		local frame = Create("Frame", {
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = z,
			Parent = mapFrame,
		})
		Create("UIStroke", { Color = color, Thickness = thickness, Parent = frame })
		return frame
	end
	local hoverBox = outline(Color3.new(1, 1, 1), 1.5, 10)
	local pinBox = outline(Theme.Get().Accent, 2, 11)
	Theme.OnChange(function()
		if pinBox.Parent then
			pinBox:FindFirstChildOfClass("UIStroke").Color = Theme.Get().Accent
		end
	end)

	local playerDot = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(9, 9),
		BorderSizePixel = 0,
		ZIndex = 12,
		Visible = false,
		Parent = mapFrame,
	}, { Corner(999), Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5 }) })
	Theme.Bind(playerDot, { BackgroundColor3 = "Accent" })
	local playerPulse = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = playerDot,
	}, { Corner(999) })
	Theme.Bind(playerPulse, { BackgroundColor3 = "Accent" })

	local hitLayer = Create("TextButton", {
		Name = "Hit",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 20,
		Parent = mapFrame,
	})

	-- Status line --------------------------------------------------------------
	local status = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		Parent = holder,
	})
	local sizeLabel = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.5, 1),
		Parent = status,
	})
	local cursorLabel = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 11,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.5, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = status,
	})

	-- Inspector + distribution ---------------------------------------------------
	local inspector, distribution
	if options.Inspector ~= false then
		divider(holder, 6)
		inspector = Inspector.new(holder, { Palette = palette, Actions = options.Actions, LayoutOrder = 7 })
	end
	if options.Distribution ~= false then
		divider(holder, 8)
		distribution = Distribution.new(holder, palette, {
			LayoutOrder = 9,
			Limit = options.DistributionLimit,
			Footer = "Clearable tiles",
			OnSelect = function(id)
				map:SetFilter((id == 0 or map.Filter == id) and nil or id)
			end,
		})
	end

	---------------------------------------------------------------- helpers
	local function isClearable(id)
		if options.Clearable then
			local ok, result = pcall(options.Clearable, id)
			return ok and result == true
		end
		return id ~= 0 and not palette:IsSkip(id)
	end

	local function readPlayer()
		if not options.GetPlayer then
			return nil
		end
		local ok, a, b = pcall(options.GetPlayer)
		if not ok then
			return nil
		end
		if type(a) == "table" then
			a, b = a.X or a.x or a[1], a.Y or a.y or a[2]
		end
		a, b = tonumber(a), tonumber(b)
		if a and b then
			return { X = a, Y = b }
		end
		return nil
	end

	local function cellAt(screenPosition)
		local snap = map.Snapshot
		if not snap then
			return nil
		end
		local size = mapFrame.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return nil
		end
		local relative = Vector2.new(screenPosition.X, screenPosition.Y) - mapFrame.AbsolutePosition
		local col = math.floor(relative.X / size.X * snap.W) + 1
		local row = math.floor(relative.Y / size.Y * snap.H) + 1
		if col < 1 or row < 1 or col > snap.W or row > snap.H then
			return nil
		end
		return col, row
	end

	local function place(frame, col, row, inset)
		local cell = map._cell
		frame.Position = UDim2.fromOffset((col - 1) * cell - inset, (row - 1) * cell - inset)
		frame.Size = UDim2.fromOffset(cell + inset * 2, cell + inset * 2)
	end

	local function updateInspector()
		if not inspector or not map.Snapshot then
			return
		end
		local mode, col, row
		if map.Selected then
			mode, col, row = "Pinned", map.Selected[1], map.Selected[2]
		elseif map.Hover then
			mode, col, row = "Hover", map.Hover[1], map.Hover[2]
		elseif map.Player then
			mode, col, row = "Your tile", math.floor(map.Player.X), math.floor(map.Player.Y)
		else
			mode, col, row = "Hover", 1, 1
		end
		local tile = map:GetTile(col, row)
		if tile then
			inspector:Set(tile, mode)
		end
	end

	local function updateCursor()
		local snap = map.Snapshot
		if not snap then
			return
		end
		if map.Hover then
			cursorLabel.Text = ("col %d · row %d"):format(map.Hover[1], map.Hover[2])
		elseif map.Player then
			cursorLabel.Text = ("you · col %d · row %d"):format(math.floor(map.Player.X), math.floor(map.Player.Y))
		else
			cursorLabel.Text = ""
		end
	end

	local function updatePlayer()
		map.Player = readPlayer()
		local snap = map.Snapshot
		if not map.Player or not snap then
			playerDot.Visible = false
			return
		end
		local cell = map._cell
		local size = math.max(7, math.floor(cell * 1.4))
		playerDot.Visible = true
		playerDot.Size = UDim2.fromOffset(size, size)
		playerDot.Position = UDim2.fromOffset((map.Player.X - 1) * cell, (map.Player.Y - 1) * cell)
	end

	local function rebuildChips()
		local snap = map.Snapshot
		local ids = {}
		if map.Layer == "fg" then
			ids = options.Highlight or preset.Highlight
			if not ids and snap then
				ids = {}
				for id in pairs(snap.Counts.fg) do
					if id ~= 0 then
						table.insert(ids, id)
					end
				end
				table.sort(ids, function(a, b)
					return snap.Counts.fg[a] > snap.Counts.fg[b]
				end)
			end
		elseif snap then
			for id in pairs(snap.Counts.bg) do
				if id ~= 0 then
					table.insert(ids, id)
				end
			end
			table.sort(ids, function(a, b)
				return snap.Counts.bg[a] > snap.Counts.bg[b]
			end)
		end
		ids = ids or {}

		local list = { "all" }
		for index = 1, math.min(#ids, 6) do
			table.insert(list, ids[index])
		end
		local key = map.Layer .. ":" .. table.concat(list, ",")
		if key == chipKey then
			return
		end
		chipKey = key

		for _, chip in ipairs(filterChips) do
			chip.Instance:Destroy()
		end
		table.clear(filterChips)
		for index, id in ipairs(list) do
			local chip = Parts.Chip(chipRow, {
				Text = id == "all" and "All" or palette:Name(id),
				Swatch = id ~= "all" and palette:Color(id) or nil,
				LayoutOrder = index,
				Callback = function()
					map:SetFilter(id ~= "all" and id or nil)
				end,
			})
			chip.Value = id
			table.insert(filterChips, chip)
		end
		map:_paintChips()
	end

	function map:_paintChips()
		for _, chip in ipairs(filterChips) do
			chip:SetSelected((chip.Value == "all" and self.Filter == nil) or chip.Value == self.Filter)
		end
		for layer, chip in pairs(layerChips) do
			chip:SetSelected(layer == self.Layer)
		end
		liveChip:SetSelected(self.Live)
	end

	-- Sizes the map to the available width and current zoom
	local function layout()
		local snap = map.Snapshot
		local W = snap and snap.W or scanner.Width or 100
		local H = snap and snap.H or scanner.Height or 60
		local available = viewport.AbsoluteSize.X - 8
		if available < 40 then
			return false
		end
		local fit = math.max(2, math.floor(available / W))
		local cell = math.max(2, math.floor(fit * ZOOMS[map.ZoomIndex]))
		map._cell = cell

		local mapW, mapH = W * cell, H * cell
		mapFrame.Size = UDim2.fromOffset(mapW, mapH)
		viewport.CanvasSize = UDim2.fromOffset(mapW + 8, mapH + 8)
		viewport.Size = UDim2.new(1, 0, 0, math.min(mapH + 8, options.ViewHeight or 320))
		zoomLabel.Text = math.floor(ZOOMS[map.ZoomIndex] * 100) .. "%"
		sizeLabel.Text = ("%d × %d · %d tiles"):format(W, H, W * H)

		if surfaceRow and surfaceRow >= 1 and surfaceRow <= H then
			local ratio = (surfaceRow - 1) / H
			skyGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, SKY_TOP),
				ColorSequenceKeypoint.new(math.max(0.001, ratio - 0.001), SKY_LOW),
				ColorSequenceKeypoint.new(math.min(0.999, ratio), GROUND),
				ColorSequenceKeypoint.new(1, GROUND),
			})
			surfaceLine.Visible = true
			surfaceLine.Position = UDim2.fromOffset(0, (surfaceRow - 1) * cell)
		else
			skyGradient.Color = ColorSequence.new(GROUND)
			surfaceLine.Visible = false
		end

		if map.Hover then
			place(hoverBox, map.Hover[1], map.Hover[2], 0)
		end
		if map.Selected then
			place(pinBox, map.Selected[1], map.Selected[2], 1)
		end
		for _, marker in ipairs(map._markers) do
			if marker.Frame.Visible then
				place(marker.Frame, marker.Col, marker.Row, 0)
			end
		end
		return true
	end

	local function redraw()
		if not map.Snapshot then
			return
		end
		if layout() then
			renderer:Draw(map.Snapshot, { Layer = map.Layer, Filter = map.Filter, Cell = map._cell })
			updatePlayer()
		end
	end

	---------------------------------------------------------------- input
	hitLayer.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local col, row = cellAt(input.Position)
		if not col then
			return
		end
		if not map.Hover or map.Hover[1] ~= col or map.Hover[2] ~= row then
			map.Hover = { col, row }
			hoverBox.Visible = true
			place(hoverBox, col, row, 0)
			updateCursor()
			if not map.Selected then
				updateInspector()
			end
		end
	end)
	hitLayer.MouseLeave:Connect(function()
		map.Hover = nil
		hoverBox.Visible = false
		updateCursor()
		updateInspector()
	end)
	hitLayer.InputBegan:Connect(function(input)
		if not Utility.IsClick(input) then
			return
		end
		local col, row = cellAt(input.Position)
		if col then
			map:Select(col, row)
		end
	end)

	viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		redraw()
	end)

	---------------------------------------------------------------- API
	function map:Refresh()
		local snap = scanner:Scan()
		if not snap then
			scanLabel.Text = "Scan failed (see console)"
			return false
		end
		local sizeChanged = not self.Snapshot or self.Snapshot.W ~= snap.W or self.Snapshot.H ~= snap.H
		self.Snapshot = snap
		self._lastScan = os.clock()
		if sizeChanged and self.Selected and (self.Selected[1] > snap.W or self.Selected[2] > snap.H) then
			self:ClearSelection()
		end

		rebuildChips()
		redraw()

		if distribution then
			local layer = self.Layer
			local clearable = 0
			for id, count in pairs(snap.Counts.fg) do
				if isClearable(id) then
					clearable += count
				end
			end
			distribution:Set(
				snap.Counts[layer],
				snap.W * snap.H,
				self.Filter,
				layer == "fg" and "Foreground tiles" or "Background tiles",
				clearable
			)
		end
		updateInspector()
		updateCursor()
		scanLabel.Text = "Scanned just now"
		Utility.SafeCall(options.OnScan, snap)
		return true
	end

	function map:SetLive(live)
		self.Live = live and true or false
		self:_paintChips()
	end

	function map:SetInterval(seconds)
		self.Interval = math.max(0.25, tonumber(seconds) or 2)
	end

	function map:SetLayer(layer)
		self.Layer = layer == "bg" and "bg" or "fg"
		self.Filter = nil
		rebuildChips()
		self:_paintChips()
		if self.Snapshot then
			redraw()
			if distribution then
				distribution:Set(self.Snapshot.Counts[self.Layer], self.Snapshot.W * self.Snapshot.H, nil,
					self.Layer == "fg" and "Foreground tiles" or "Background tiles")
			end
		end
	end

	function map:SetFilter(id)
		self.Filter = id
		self:_paintChips()
		if self.Snapshot then
			redraw()
			if distribution then
				distribution:Set(self.Snapshot.Counts[self.Layer], self.Snapshot.W * self.Snapshot.H, id,
					self.Layer == "fg" and "Foreground tiles" or "Background tiles")
			end
		end
	end

	function map:SetZoom(index)
		self.ZoomIndex = math.clamp(index, 1, #ZOOMS)
		redraw()
	end

	function map:GetTile(col, row)
		local snap = self.Snapshot
		if not snap or not snap.fg[row] or col < 1 or col > snap.W then
			return nil
		end
		local fg, bg = snap.fg[row][col], snap.bg[row][col]
		local distance
		if self.Player then
			-- distance to the tile center, in tiles
			distance = math.sqrt((col + 0.5 - self.Player.X) ^ 2 + (row + 0.5 - self.Player.Y) ^ 2)
		end
		return {
			Col = col,
			Row = row,
			Fg = fg,
			Bg = bg,
			FgName = palette:Name(fg),
			BgName = palette:Name(bg),
			FgSkip = palette:IsSkip(fg),
			BgSkip = palette:IsSkip(bg),
			Distance = distance,
		}
	end

	function map:Select(col, row)
		self.Selected = { col, row }
		pinBox.Visible = true
		place(pinBox, col, row, 1)
		updateInspector()
		local tile = self:GetTile(col, row)
		if tile then
			Utility.SafeCall(options.OnSelect, tile)
		end
	end

	function map:ClearSelection()
		self.Selected = nil
		pinBox.Visible = false
		updateInspector()
	end

	function map:GetCounts(layer)
		return self.Snapshot and self.Snapshot.Counts[layer or "fg"] or {}
	end

	function map:Find(id, layer)
		local found = {}
		local snap = self.Snapshot
		if not snap then
			return found
		end
		local grid = snap[layer or "fg"]
		for row = 1, snap.H do
			for col = 1, snap.W do
				if grid[row][col] == id then
					table.insert(found, { Col = col, Row = row })
				end
			end
		end
		return found
	end

	function map:SetMarkers(list)
		list = list or {}
		for index, data in ipairs(list) do
			local marker = self._markers[index]
			if not marker then
				local frame = outline(Color3.new(1, 1, 1), 1, 9)
				marker = { Frame = frame, Stroke = frame:FindFirstChildOfClass("UIStroke") }
				self._markers[index] = marker
			end
			marker.Col = data.Col or data[1]
			marker.Row = data.Row or data[2]
			marker.Stroke.Color = data.Color or Parts.Colors.Success
			marker.Frame.Visible = true
			place(marker.Frame, marker.Col, marker.Row, 0)
		end
		for index = #list + 1, #self._markers do
			self._markers[index].Frame.Visible = false
		end
	end

	function map:SetTitle(text)
		titleLabel.Text = text
	end

	function map:SetVisible(visible)
		holder.Visible = visible
	end

	function map:Destroy()
		self._alive = false
		renderer:Clear()
		holder:Destroy()
	end

	---------------------------------------------------------------- loop
	map:_paintChips()
	task.spawn(function()
		local pulse = 0
		while map._alive and holder.Parent do
			local shown = isShown(holder)
			if shown then
				if not map.Snapshot or (map.Live and os.clock() - (map._lastScan or 0) >= map.Interval) then
					map:Refresh()
				else
					updatePlayer()
					if not map.Selected and not map.Hover then
						updateInspector()
					end
				end
				if map._lastScan then
					local ago = math.floor(os.clock() - map._lastScan)
					scanLabel.Text = ago < 1 and "Scanned just now" or ("Scanned %ds ago"):format(ago)
				end
				-- soft pulse on the player marker
				pulse = (pulse + PLAYER_TICK) % 1.2
				local t = pulse / 1.2
				playerPulse.Size = UDim2.fromScale(1 + t * 1.6, 1 + t * 1.6)
				playerPulse.BackgroundTransparency = 0.55 + t * 0.45
			end
			task.wait(PLAYER_TICK)
		end
	end)

	return map
end
end

__modules["Components/WorldMap/Inspector"] = function(...)
--[[
	Components/WorldMap/Inspector
	Details of one tile: coordinates, fg / bg contents with tags, distance
	from the player, and action buttons.

	local inspector = Inspector.new(parent, { Actions = {...}, LayoutOrder })
	inspector:Set(tile, "Pinned" | "Hover" | "Your tile")

	tile = { Col, Row, Fg, Bg, FgName, BgName, FgSkip, BgSkip, Distance }

	Actions = {
		{ Title = "Walk here", Primary = true,
		  Visible = function(tile) return tile.Fg == 0 end,   -- optional
		  Callback = function(tile) end },
	}
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Parts = import("Components/WorldMap/Parts")

local Create, Corner = Utility.Create, Utility.Corner
local Fonts = Constants.Fonts
local Colors = Parts.Colors

local Inspector = {}
Inspector.__index = Inspector

local function copy(text)
	local writer = setclipboard or toclipboard or (syn and syn.write_clipboard)
	if type(writer) == "function" then
		return (pcall(writer, text))
	end
	return false
end

function Inspector.new(parent, options)
	options = options or {}
	local self = setmetatable({ Tile = nil, _actions = {} }, Inspector)
	self.Palette = options.Palette

	local root = Create("Frame", {
		Name = "Inspector",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = options.LayoutOrder or 0,
		Parent = parent,
	}, { Utility.List(8) })
	self.Instance = root

	-- Header: title + mode pill
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = root,
	})
	Builders.Label({
		Text = "Tile inspector",
		Font = Fonts.Bold,
		TextSize = 13,
		Size = UDim2.fromScale(0.6, 1),
		Parent = header,
	})
	local modeHolder = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = header,
	}, { Utility.List(0, Enum.FillDirection.Horizontal) })
	self._mode = Parts.Tag(modeHolder)

	-- Coordinates
	local coords = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = root,
	}, { Utility.List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Bottom) })
	self._coord = Builders.Label({
		Text = "-",
		Font = Fonts.Mono,
		TextSize = 20,
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = coords,
	})
	Builders.Label({
		Text = "col, row",
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = coords,
	})

	-- Layer rows
	self._layers = {}
	for index, caption in ipairs({ "FOREGROUND", "BACKGROUND" }) do
		local row = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			LayoutOrder = 2 + index,
			Parent = root,
		}, { Corner(9) })
		Theme.Bind(row, { BackgroundColor3 = "Field" })
		Builders.Stroke(0.94).Parent = row

		local swatch = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BorderSizePixel = 0,
			Parent = row,
		}, { Corner(6) })
		Create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.85, Parent = swatch })

		Builders.Label({
			Text = caption,
			Font = Fonts.Bold,
			TextSize = 9,
			ThemeColor = "SubText",
			Position = UDim2.fromOffset(44, 7),
			Size = UDim2.new(1, -120, 0, 12),
			Parent = row,
		})
		local name = Builders.Label({
			Text = "",
			Font = Fonts.Bold,
			TextSize = 13,
			Position = UDim2.fromOffset(44, 20),
			Size = UDim2.new(1, -120, 0, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local right = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(70, 34),
			BackgroundTransparency = 1,
			Parent = row,
		}, { Utility.List(3, nil, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
		local id = Builders.Label({
			Text = "",
			Font = Fonts.Mono,
			TextSize = 11,
			ThemeColor = "SubText",
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.new(1, 0, 0, 14),
			Parent = right,
		})
		local tag = Parts.Tag(right, 2)
		self._layers[index] = { Swatch = swatch, Name = name, Id = id, Tag = tag }
	end

	-- Distance
	local distanceRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		Parent = root,
	})
	Builders.Label({
		Text = "Distance from you",
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.6, 1),
		Parent = distanceRow,
	})
	self._distance = Builders.Label({
		Text = "-",
		Font = Fonts.Bold,
		TextSize = 12,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.4, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = distanceRow,
	})

	-- Actions
	local actions = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 6,
		Parent = root,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local copyButton
	copyButton = Parts.Button(actions, {
		Text = "Copy coords",
		Icon = "copy",
		LayoutOrder = 1,
		Callback = function()
			local tile = self.Tile
			if not tile then
				return
			end
			copy(("%d, %d"):format(tile.Col, tile.Row))
			copyButton:SetText("Copied")
			task.delay(1.2, function()
				copyButton:SetText("Copy coords")
			end)
		end,
	})

	for index, action in ipairs(options.Actions or {}) do
		local button = Parts.Button(actions, {
			Text = action.Title or action.Text or "Action",
			Icon = action.Icon,
			Primary = action.Primary,
			LayoutOrder = index + 1,
			Callback = function()
				if self.Tile then
					Utility.SafeCall(action.Callback, self.Tile)
				end
			end,
		})
		table.insert(self._actions, { Button = button, Action = action })
	end

	return self
end

function Inspector:_tag(id, skip, layer)
	if id == 0 then
		return "EMPTY", Colors.Muted
	elseif skip then
		return "SKIP", Colors.Danger
	elseif layer == "bg" then
		return "BG ITEM", Colors.Violet
	end
	return "CLEARABLE", Colors.Success
end

function Inspector:Set(tile, mode)
	self.Tile = tile
	if not tile then
		return
	end
	local theme = Theme.Get()
	self._mode:Set(string.upper(mode or ""), mode == "Pinned" and theme.Accent or Colors.Muted)
	self._coord.Text = ("%d, %d"):format(tile.Col, tile.Row)

	local data = {
		{ tile.Fg, tile.FgName, tile.FgSkip, "fg" },
		{ tile.Bg, tile.BgName, tile.BgSkip, "bg" },
	}
	for index, entry in ipairs(data) do
		local view = self._layers[index]
		local id, name, skip, layer = entry[1], entry[2], entry[3], entry[4]
		view.Name.Text = name
		view.Id.Text = "#" .. tostring(id)
		view.Swatch.BackgroundColor3 = id == 0 and theme.Field or self.Palette:Color(id)
		view.Swatch.BackgroundTransparency = id == 0 and 0.5 or 0
		view.Tag:Set(self:_tag(id, skip, layer))
	end

	local distance = tile.Distance
	self._distance.Text = distance == nil and "-" or (distance < 1 and "here" or ("%.1f tiles"):format(distance))

	for _, entry in ipairs(self._actions) do
		local visible = true
		if type(entry.Action.Visible) == "function" then
			local ok, result = pcall(entry.Action.Visible, tile)
			visible = ok and result ~= false
		end
		entry.Button.Instance.Visible = visible
	end
end

return Inspector
end

__modules["Components/WorldMap/Palette"] = function(...)
--[[
	Components/WorldMap/Palette
	Names, colors and skip rules for tile ids.

	local palette = Palette.new(options)
	palette:Name(id)     -> "Dirt" | "Item #123"
	palette:Color(id)    -> Color3 (stable generated color for unknown ids)
	palette:IsSkip(id)   -> true for tiles your bot must never hit
	palette:HasGrass(id) -> draw a grass cap when the tile is exposed to air

	options.Preset   "Growblox" fills Items / Skip / Grass / Surface / size defaults
	options.Items    { [id] = { Name = "Dirt", Color = Color3 } }  (merged over the preset)
	options.ItemName function(id) -> string?  (e.g. read gs.Items[id].name)
	options.Skip     { [id] = true }
]]

local rgb = Color3.fromRGB

local Palette = {}
Palette.__index = Palette

-- Values verified on Growblox (placeId 112863874972771): 100 x 60 world,
-- fg[row][col], 0 = empty, surface around row 37.
Palette.Presets = {
	Growblox = {
		Width = 100,
		Height = 60,
		Surface = 37,
		Items = {
			[2] = { Name = "Dirt", Color = rgb(138, 90, 54) },
			[6] = { Name = "Main Door", Color = rgb(245, 158, 11) },
			[8] = { Name = "Bedrock", Color = rgb(58, 57, 64) },
			[10] = { Name = "Rock", Color = rgb(125, 131, 148) },
			[242] = { Name = "World Lock", Color = rgb(250, 204, 21) },
		},
		Skip = { [0] = true, [6] = true, [8] = true, [242] = true },
		Grass = { [2] = true },
		Highlight = { 2, 10, 8, 6, 242 },
	},
}

local function merge(base, extra)
	local result = {}
	for key, value in pairs(base or {}) do
		result[key] = value
	end
	for key, value in pairs(extra or {}) do
		result[key] = value
	end
	return result
end

function Palette.new(options)
	options = options or {}
	local preset = Palette.Presets[options.Preset or ""] or {}

	local self = setmetatable({}, Palette)
	self.Preset = preset
	self.Items = merge(preset.Items, options.Items)
	self.Skip = merge(preset.Skip or { [0] = true }, options.Skip)
	self.Grass = merge(preset.Grass, options.Grass)
	self.ItemName = options.ItemName
	self._generated = {}
	self._names = {}
	return self
end

function Palette:Name(id)
	if id == 0 then
		return "Empty"
	end
	local item = self.Items[id]
	if item and item.Name then
		return item.Name
	end
	local cached = self._names[id]
	if cached then
		return cached
	end
	local name
	if self.ItemName then
		local ok, result = pcall(self.ItemName, id)
		name = ok and result ~= nil and tostring(result) or nil
	end
	name = name or ("Item #" .. tostring(id))
	self._names[id] = name
	return name
end

-- Unknown ids get a stable color spread around the hue wheel (golden ratio)
function Palette:Color(id)
	local item = self.Items[id]
	if item and item.Color then
		return item.Color
	end
	local color = self._generated[id]
	if not color then
		local number = tonumber(id) or #tostring(id)
		local hue = (number * 0.6180339887) % 1
		color = Color3.fromHSV(hue, 0.45, 0.78)
		self._generated[id] = color
	end
	return color
end

function Palette:IsSkip(id)
	return self.Skip[id] == true
end

function Palette:HasGrass(id)
	return self.Grass[id] == true
end

return Palette
end

__modules["Components/WorldMap/Parts"] = function(...)
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
	function api:SetText(text)
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
end

__modules["Components/WorldMap/Renderer"] = function(...)
--[[
	Components/WorldMap/Renderer
	Draws a snapshot into a Frame using as few Instances as possible:
	each row's equal neighbouring tiles are merged into one Frame ("run"),
	frames are pooled per row, and rows whose content did not change since
	the last draw are left alone.

	local renderer = Renderer.new(canvas, palette)
	renderer:Draw(snap, { Layer = "fg" | "bg", Filter = id | nil, Cell = 5 })
	renderer:Clear()
]]

local Renderer = {}
Renderer.__index = Renderer

local GRASS = Color3.fromRGB(76, 175, 80)
local DIM = 0.82 -- transparency of tiles outside the highlight filter
local GHOST = 0.84 -- transparency of fg while viewing the bg layer

local Z = { fg = 2, cap = 3, bg = 4 }

function Renderer.new(canvas, palette)
	local self = setmetatable({}, Renderer)
	self.Canvas = canvas
	self.Palette = palette
	self._pools = {} -- [kind .. row] = { frames }
	self._sigs = {} -- [kind .. row] = signature of what is drawn
	self._mode = nil
	return self
end

function Renderer:_pool(key)
	local pool = self._pools[key]
	if not pool then
		pool = {}
		self._pools[key] = pool
	end
	return pool
end

function Renderer:_frame(pool, index, zIndex)
	local frame = pool[index]
	if not frame then
		frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Active = false
		frame.ZIndex = zIndex
		frame.Parent = self.Canvas
		pool[index] = frame
	end
	frame.Visible = true
	return frame
end

-- runs: array of { c0, c1, id }; drawn at row with height h (cap rows are thinner)
function Renderer:_drawRow(kind, row, runs, cell, opts)
	local key = kind .. row
	local pool = self:_pool(key)
	local filter = opts.Filter
	local base = opts.Base or 0
	local height = opts.Height or cell

	for index, run in ipairs(runs) do
		local frame = self:_frame(pool, index, Z[kind])
		local c0, c1, id = run[1], run[2], run[3]
		frame.Position = UDim2.fromOffset((c0 - 1) * cell, (row - 1) * cell)
		frame.Size = UDim2.fromOffset((c1 - c0 + 1) * cell, height)
		frame.BackgroundColor3 = kind == "cap" and GRASS or self.Palette:Color(id)
		local dimmed = filter ~= nil and id ~= filter
		local transparency = base
		if dimmed then
			transparency = math.max(transparency, DIM)
		end
		frame.BackgroundTransparency = transparency
	end
	for index = #runs + 1, #pool do
		pool[index].Visible = false
	end
end

local function rowRuns(line, W)
	local runs = {}
	local col = 1
	while col <= W do
		local id = line[col] or 0
		local stop = col
		while stop < W and (line[stop + 1] or 0) == id do
			stop += 1
		end
		if id ~= 0 then
			table.insert(runs, { col, stop, id })
		end
		col = stop + 1
	end
	return runs
end

-- Exposed grass tiles (air above) merged into thin strips
function Renderer:_capRuns(snap, row)
	local runs = {}
	if row < 2 then
		return runs
	end
	local line, above = snap.fg[row], snap.fg[row - 1]
	local col = 1
	while col <= snap.W do
		if self.Palette:HasGrass(line[col]) and above[col] == 0 then
			local stop = col
			while stop < snap.W and self.Palette:HasGrass(line[stop + 1]) and above[stop + 1] == 0 do
				stop += 1
			end
			table.insert(runs, { col, stop, line[col] })
			col = stop + 1
		else
			col += 1
		end
	end
	return runs
end

function Renderer:Draw(snap, opts)
	if not snap then
		return
	end
	local cell = opts.Cell
	local layer = opts.Layer == "bg" and "bg" or "fg"
	local filter = opts.Filter
	local mode = table.concat({ layer, tostring(filter), cell, snap.W, snap.H }, "|")
	local force = mode ~= self._mode
	self._mode = mode

	local fgBase = layer == "bg" and GHOST or 0
	local fgFilter = layer == "fg" and filter or nil
	local capHeight = math.max(1, math.floor(cell * 0.32 + 0.5))

	for row = 1, snap.H do
		local fgKey = snap.RowKeys.fg[row]
		if force or self._sigs["fg" .. row] ~= fgKey then
			self._sigs["fg" .. row] = fgKey
			self:_drawRow("fg", row, rowRuns(snap.fg[row], snap.W), cell, { Filter = fgFilter, Base = fgBase })
		end

		local capKey = fgKey .. "|" .. (snap.RowKeys.fg[row - 1] or "")
		if force or self._sigs["cap" .. row] ~= capKey then
			self._sigs["cap" .. row] = capKey
			local runs = layer == "fg" and self:_capRuns(snap, row) or {}
			self:_drawRow("cap", row, runs, cell, { Filter = fgFilter, Height = capHeight })
		end

		local bgKey = layer == "bg" and snap.RowKeys.bg[row] or ""
		if force or self._sigs["bg" .. row] ~= bgKey then
			self._sigs["bg" .. row] = bgKey
			local runs = layer == "bg" and rowRuns(snap.bg[row], snap.W) or {}
			self:_drawRow("bg", row, runs, cell, { Filter = filter })
		end
	end

	-- Rows beyond a smaller new world
	for key, pool in pairs(self._pools) do
		local row = tonumber(string.match(key, "%d+$"))
		if row and row > snap.H then
			for _, frame in ipairs(pool) do
				frame.Visible = false
			end
			self._sigs[key] = nil
		end
	end
end

function Renderer:Clear()
	for _, pool in pairs(self._pools) do
		for _, frame in ipairs(pool) do
			frame:Destroy()
		end
	end
	table.clear(self._pools)
	table.clear(self._sigs)
	self._mode = nil
end

return Renderer
end

__modules["Components/WorldMap/Scanner"] = function(...)
--[[
	Components/WorldMap/Scanner
	Reads the world into a plain snapshot. Knows nothing about UI.

	Data sources (pick one):
		World   = gs.world                    -- table with w, h, fg[row][col], bg[row][col]
		World   = function() return gs.world end  -- re-read every scan (world changes)
		GetTile = function(col, row, layer) return id end  -- layer "fg" | "bg"
		          with Width / Height or GetSize = function() return w, h end

	local scanner = Scanner.new(options)
	local snap = scanner:Scan()
	snap.W, snap.H
	snap.fg[row][col], snap.bg[row][col]   (always numbers, 0 = empty)
	snap.Counts.fg[id], snap.Counts.bg[id]
	snap.RowKeys.fg[row]                   (string signature, used to skip unchanged rows)
	snap.HasBackground                     (any non-empty bg tile)
]]

local Scanner = {}
Scanner.__index = Scanner

function Scanner.new(options)
	options = options or {}
	local self = setmetatable({}, Scanner)
	self.World = options.World
	self.GetTile = options.GetTile
	self.GetSize = options.GetSize
	self.Width = options.Width
	self.Height = options.Height
	return self
end

function Scanner:_world()
	local world = self.World
	if type(world) == "function" then
		local ok, result = pcall(world)
		world = ok and result or nil
	end
	return type(world) == "table" and world or nil
end

function Scanner:Size()
	local world = self:_world()
	if world then
		return tonumber(world.w or world.W or world.Width) or self.Width or 100,
			tonumber(world.h or world.H or world.Height) or self.Height or 60
	end
	if self.GetSize then
		local ok, w, h = pcall(self.GetSize)
		if ok and w and h then
			return w, h
		end
	end
	return self.Width or 100, self.Height or 60
end

local function readLayer(world, layer, row, col)
	local grid = world[layer]
	local line = grid and grid[row]
	local value = line and line[col]
	return tonumber(value) or 0
end

function Scanner:Scan()
	local W, H = self:Size()
	local world = self:_world()
	local getTile = self.GetTile

	local snap = {
		W = W,
		H = H,
		fg = table.create(H),
		bg = table.create(H),
		Counts = { fg = {}, bg = {} },
		RowKeys = { fg = table.create(H), bg = table.create(H) },
		HasBackground = false,
		Time = os.clock(),
	}

	local ok, err = pcall(function()
		for row = 1, H do
			local fgRow, bgRow = table.create(W), table.create(W)
			for col = 1, W do
				local f, b
				if world then
					f = readLayer(world, "fg", row, col)
					b = readLayer(world, "bg", row, col)
				elseif getTile then
					f = tonumber(getTile(col, row, "fg")) or 0
					b = tonumber(getTile(col, row, "bg")) or 0
				else
					f, b = 0, 0
				end
				fgRow[col], bgRow[col] = f, b
				snap.Counts.fg[f] = (snap.Counts.fg[f] or 0) + 1
				snap.Counts.bg[b] = (snap.Counts.bg[b] or 0) + 1
				if b ~= 0 then
					snap.HasBackground = true
				end
			end
			snap.fg[row], snap.bg[row] = fgRow, bgRow
			snap.RowKeys.fg[row] = table.concat(fgRow, ",")
			snap.RowKeys.bg[row] = table.concat(bgRow, ",")
		end
	end)

	if not ok then
		warn("[EakUI] WorldMap scan failed: " .. tostring(err))
		return nil
	end
	return snap
end

return Scanner
end

__modules["Core/Assets"] = function(...)
--[[
	Core/Assets
	Resolves any image source to something an ImageLabel can display.

	Accepted sources:
		123456 / "123456"                 -> rbxassetid://123456
		"rbxassetid://..." "rbxasset://..." "rbxthumb://..."  (used as-is)
		"https://example.com/logo.png"    -> downloaded once, cached to
		                                     workspace/EakUI/assets/, loaded with getcustomasset
		"EakUI/my_logo.png"               -> local file in the executor workspace
		"settings" / "map-pin" / "gear"   -> built-in icon (see Core/Icons, ICONS.md)

	URL, file and named-icon images need an executor with writefile / isfile /
	getcustomasset. Without them a warning is printed and the image stays empty.

	Assets.Apply(imageLabel, source)   -- async-safe, never yields the caller
	Assets.Resolve(source) -> string?  -- may yield while downloading
]]

local import = ...
local Icons = import("Core/Icons")

local Assets = {}

local ROOT = "EakUI"
local FOLDER = ROOT .. "/assets"
local VALID_EXTENSIONS = { png = true, jpg = true, jpeg = true }

local cache = {} -- [source] = resolved asset string
local pending = {} -- [source] = true while downloading

local function getCustomAsset()
	return getcustomasset or getsynasset
end

local function hasFileSystem()
	return writefile ~= nil and isfile ~= nil and getCustomAsset() ~= nil
end

local function ensureFolders()
	if not (isfolder and makefolder) then
		return
	end
	if not isfolder(ROOT) then
		makefolder(ROOT)
	end
	if not isfolder(FOLDER) then
		makefolder(FOLDER)
	end
end

-- djb2 string hash -> stable file name per URL
local function hash(text)
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 4294967296
	end
	return string.format("%08x", h)
end

local function extensionOf(url)
	local ext = string.match(string.lower(url), "%.(%a+)[%?#]") or string.match(string.lower(url), "%.(%a+)$")
	return VALID_EXTENSIONS[ext or ""] and ext or "png"
end

local function download(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end

	local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
	if requestFn then
		local success, response = pcall(requestFn, { Url = url, Method = "GET" })
		if success and response and response.Body and #response.Body > 0 then
			return response.Body
		end
	end
	return nil
end

local function loadFile(path)
	local ok, asset = pcall(getCustomAsset(), path)
	if ok and asset and asset ~= "" then
		return asset
	end
	return nil
end

-- Sources that can be used directly, without yielding
local function resolveInstant(source)
	if source == nil or source == "" then
		return nil, true
	end
	if type(source) == "number" or string.match(source, "^%d+$") then
		return "rbxassetid://" .. source, true
	end
	if string.match(source, "^rbx") then
		return source, true
	end
	if cache[source] then
		return cache[source], true
	end
	return nil, false
end

function Assets.Resolve(source)
	source = Icons.ToUrl(source) or source -- named icons become their hosted PNG URL
	local instant, done = resolveInstant(source)
	if done then
		return instant
	end

	if not hasFileSystem() then
		warn("[EakUI] This executor can't load custom images (needs writefile + getcustomasset): " .. tostring(source))
		return nil
	end

	-- another caller is already downloading this source
	while pending[source] do
		task.wait()
	end
	if cache[source] then
		return cache[source]
	end

	pending[source] = true
	local result

	if string.match(source, "^https?://") then
		ensureFolders()
		local path = FOLDER .. "/" .. hash(source) .. "." .. extensionOf(source)
		if not isfile(path) then
			local body = download(source)
			if body then
				writefile(path, body)
			else
				warn("[EakUI] Failed to download image: " .. source)
			end
		end
		if isfile(path) then
			result = loadFile(path)
		end
	elseif isfile(source) then
		result = loadFile(source)
	else
		warn("[EakUI] Image file not found: " .. source)
	end

	pending[source] = nil
	cache[source] = result
	return result
end

-- Sets instance[property] to the resolved image. URLs are fetched in the background.
function Assets.Apply(instance, source, property)
	property = property or "Image"
	source = Icons.ToUrl(source) or source
	local instant, done = resolveInstant(source)
	if done then
		instance[property] = instant or ""
		return
	end

	task.spawn(function()
		local resolved = Assets.Resolve(source)
		if resolved and instance.Parent then
			instance[property] = resolved
		end
	end)
end

-- Downloads images ahead of time (e.g. call once at script start)
function Assets.Preload(sources)
	for _, source in ipairs(sources) do
		task.spawn(Assets.Resolve, source)
	end
end

return Assets
end

__modules["Core/Badge"] = function(...)
--[[
	Core/Badge
	Small status pill shown next to an element title.

	Badge.new(parent, "NEW")                         -- preset color
	Badge.new(parent, { Text = "x2", Color = c3 })   -- custom color
	badge:Set("ON") / badge:Set(nil) -- nil hides

	Presets: NEW / BETA (accent), ON (green), OFF (grey), PREMIUM / VIP (gold), HOT (red)
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween
local rgb = Color3.fromRGB

local PRESETS = {
	NEW = "Accent",
	BETA = "Accent",
	ON = rgb(34, 197, 94),
	OFF = "SubText",
	PREMIUM = rgb(234, 179, 8),
	VIP = rgb(234, 179, 8),
	HOT = rgb(239, 68, 68),
}

local Badge = {}

local function resolve(value)
	if value == nil then
		return nil, nil
	end
	if type(value) == "table" then
		return tostring(value.Text or ""), value.Color
	end
	local text = tostring(value)
	local preset = PRESETS[string.upper(text)]
	if type(preset) == "string" then
		return text, State.Theme[preset]
	end
	return text, preset or State.Theme.Accent
end

function Badge.new(parent, value)
	local pill = Create("Frame", {
		Name = "Badge",
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		Parent = parent,
	}, { Utility.Corner(999), Utility.Padding(0, 0, 6, 6) })

	local label = Create("TextLabel", {
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Bold,
		TextSize = 10,
		Parent = pill,
	})

	local badge = { Instance = pill, Value = value }

	function badge:Set(newValue)
		badge.Value = newValue
		local text, color = resolve(newValue)
		pill.Visible = text ~= nil and text ~= ""
		if not pill.Visible then
			return
		end
		label.Text = string.upper(text)
		Tween(pill, { BackgroundColor3 = color }, 0.15)
		Tween(label, { TextColor3 = color }, 0.15)
	end

	badge:Set(value)
	Theme.OnChange(function()
		badge:Set(badge.Value)
	end)
	return badge
end

return Badge
end

__modules["Core/Builders"] = function(...)
--[[
	Core/Builders
	Themed building blocks shared by components: strokes, labels,
	vector chevrons / close icons and the click ripple.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Constants = import("Core/Constants")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner

local Builders = {}

function Builders.Stroke(transparency, thickness)
	local stroke = Create("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or State.Theme.StrokeAlpha,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	Theme.Bind(stroke, { Color = "Stroke" })
	return stroke
end

-- Label({ Text = "Hi", ThemeColor = "SubText", ... })
function Builders.Label(properties)
	local colorKey = properties.ThemeColor or "Text"
	properties.ThemeColor = nil

	local merged = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Medium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	}
	for key, value in pairs(properties) do
		merged[key] = value
	end

	local label = Create("TextLabel", merged)
	Theme.Bind(label, { TextColor3 = colorKey })
	return label
end

-- Two bars forming a chevron; no image assets required
function Builders.Chevron(parent, direction, colorKey)
	local holder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Parent = parent,
	})

	local function bar()
		local frame = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(8, 2),
			BorderSizePixel = 0,
			Parent = holder,
		}, { Corner(1) })
		Theme.Bind(frame, { BackgroundColor3 = colorKey or "SubText" })
		return frame
	end
	local left, right = bar(), bar()

	local chevron = { Holder = holder }

	function chevron:Set(newDirection, instant)
		local t = instant and 0 or 0.25
		if newDirection == "down" then
			Tween(left, { Position = UDim2.new(0.5, -2.5, 0.5, 0), Rotation = 45 }, t)
			Tween(right, { Position = UDim2.new(0.5, 2.5, 0.5, 0), Rotation = -45 }, t)
		elseif newDirection == "up" then
			Tween(left, { Position = UDim2.new(0.5, -2.5, 0.5, 0), Rotation = -45 }, t)
			Tween(right, { Position = UDim2.new(0.5, 2.5, 0.5, 0), Rotation = 45 }, t)
		else -- "right"
			Tween(left, { Position = UDim2.new(0.5, 0, 0.5, -2.5), Rotation = 45 }, t)
			Tween(right, { Position = UDim2.new(0.5, 0, 0.5, 2.5), Rotation = -45 }, t)
		end
	end

	chevron:Set(direction or "down", true)
	return chevron
end

-- "X" made of two rotated bars
function Builders.CrossIcon(parent, size, colorKey, zIndex)
	for _, rotation in ipairs({ 45, -45 }) do
		local frame = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(size or 12, 2),
			Rotation = rotation,
			BorderSizePixel = 0,
			ZIndex = zIndex or 1,
			Parent = parent,
		}, { Corner(1) })
		Theme.Bind(frame, { BackgroundColor3 = colorKey or "SubText" })
	end
end

--[[
	Ripples are drawn inside a clipped "RippleLayer" frame. CRITICAL: on a button
	with AutomaticSize the growing circle must not feed back into the button's
	measured size. A RippleLayer parented INSIDE the button fails — AutomaticSize
	measures the oversized circle descendant (clipping and UISizeConstraint do not
	change what it measures), the button widens, and it loops until the button
	fills its container (the "button becomes a full-width bar" bug). The fix: the
	layer is a SIBLING of the button (parented to button.Parent), not a child, and
	tracks the button's position/size. Then the circle can grow and clip without
	ever being measured by the button's AutomaticSize.
]]
local function getRippleLayer(button)
	local host = button.Parent
	if not host then
		return nil
	end
	local layer = button:FindFirstChild("RippleLayer")
		or host:FindFirstChild("RippleLayer_" .. tostring(button:GetDebugId()))
	if not layer then
		layer = Create("Frame", {
			Name = "RippleLayer_" .. tostring(button:GetDebugId()),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = button.ZIndex + 5,
			Parent = host,
		}, { Corner(8) })
	end
	-- track the button's current pixel position and size (as a sibling)
	local size = button.AbsoluteSize
	local hostPos = host.AbsolutePosition
	local btnPos = button.AbsolutePosition
	layer.Size = UDim2.fromOffset(size.X, size.Y)
	layer.Position = UDim2.fromOffset(btnPos.X - hostPos.X, btnPos.Y - hostPos.Y)
	return layer
end

function Builders.Ripple(button, screenPosition)
	local layer = getRippleLayer(button)
	if not layer then
		return
	end
	local relative = Vector2.new(screenPosition.X, screenPosition.Y) - layer.AbsolutePosition
	local circle = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(relative.X, relative.Y),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = layer.ZIndex,
		Parent = layer,
	}, { Corner(999) })

	local diameter = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
	Tween(circle, { Size = UDim2.fromOffset(diameter, diameter), BackgroundTransparency = 1 }, 0.55, Enum.EasingStyle.Quad)
	task.delay(0.6, function()
		circle:Destroy()
	end)
end

-- Small press-down / spring-back animation on a UIScale
function Builders.Press(scale)
	Tween(scale, { Scale = 0.975 }, 0.08, Enum.EasingStyle.Quad)
	task.delay(0.08, function()
		Tween(scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
	end)
end

return Builders
end

__modules["Core/Constants"] = function(...)
--[[
	Core/Constants
	Static values shared across components.
]]

local rgb = Color3.fromRGB

local Constants = {}

-- Background transparency levels for the glass look
Constants.Glass = {
	Main = 0.08,
	Sidebar = 0.35,
	Element = 0.3,
	Field = 0.15,
}

Constants.NotifyColors = {
	Success = rgb(34, 197, 94),
	Warning = rgb(234, 179, 8),
	Error = rgb(239, 68, 68),
}

Constants.Danger = rgb(239, 68, 68)

-- Drop shadow (9-slice)
Constants.Shadow = {
	Image = "rbxassetid://6014261993",
	SliceCenter = Rect.new(49, 49, 450, 450),
}

Constants.Fonts = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Black = Enum.Font.GothamBlack,
	Mono = Enum.Font.RobotoMono,
}

Constants.Window = {
	TopbarHeight = 46,
	SidebarWidth = 156,
	SearchHeight = 30,
	ProfileHeight = 50,
	DefaultSize = UDim2.fromOffset(560, 400),
	MinSize = Vector2.new(420, 300),
	ToggleKey = Enum.KeyCode.RightShift,
}

return Constants
end

__modules["Core/Draggable"] = function(...)
--[[
	Core/Draggable
	Mouse + touch dragging with a small threshold so clicks still register.

	local state = Draggable(handle, target)
	state.Moved -- true if the last press turned into a drag
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")

local UserInputService = Services.UserInputService
local DRAG_THRESHOLD = 4

return function(handle, target, onMove)
	local state = { Dragging = false, Moved = false }
	local dragStart, startPosition, dragInput

	Utility.Track(handle.InputBegan:Connect(function(input)
		if not Utility.IsClick(input) then
			return
		end
		state.Dragging = true
		state.Moved = false
		dragStart = input.Position
		startPosition = target.Position

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				state.Dragging = false
				connection:Disconnect()
			end
		end)
	end))

	Utility.Track(handle.InputChanged:Connect(function(input)
		if Utility.IsMove(input) then
			dragInput = input
		end
	end))

	Utility.Track(UserInputService.InputChanged:Connect(function(input)
		if not (state.Dragging and input == dragInput) then
			return
		end

		local delta = input.Position - dragStart
		if not state.Moved and Vector2.new(delta.X, delta.Y).Magnitude > DRAG_THRESHOLD then
			state.Moved = true
		end

		if state.Moved then
			local position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
			Utility.Tween(target, { Position = position }, 0.08, Enum.EasingStyle.Sine)
			if onMove then
				onMove(position)
			end
		end
	end))

	return state
end
end

__modules["Core/Gui"] = function(...)
--[[
	Core/Gui
	Creates (once) the protected root ScreenGui all windows live in.
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")

local Gui = {}

local function getEnvironment()
	return (getgenv and getgenv()) or _G
end

-- gethui() > CoreGui > PlayerGui
local function resolveParent()
	local ok, hidden = pcall(function()
		return gethui and gethui()
	end)
	if ok and hidden then
		return hidden
	end

	local probe = Instance.new("ScreenGui")
	local canUseCore = pcall(function()
		probe.Parent = Services.CoreGui
	end)
	probe:Destroy()
	if canUseCore then
		return Services.CoreGui
	end

	return Services.LocalPlayer:WaitForChild("PlayerGui")
end

function Gui.Get()
	if State.Gui and State.Gui.Parent then
		return State.Gui
	end

	-- Remove the UI from a previous execution
	local env = getEnvironment()
	if env.__EakUI_Gui then
		pcall(function()
			env.__EakUI_Gui:Destroy()
		end)
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = Utility.RandomName()
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 9999

	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(screenGui)
		end
	end)
	screenGui.Parent = resolveParent()

	State.Gui = screenGui
	env.__EakUI_Gui = screenGui
	return screenGui
end

function Gui.Destroy()
	if State.Gui then
		State.Gui:Destroy()
	end
	State.Gui = nil
	State.NotifyHolder = nil
end

return Gui
end

__modules["Core/IconList"] = function(...)
--[[
	Core/IconList
	GENERATED by tools/build_icons.py from tools/icons/icons.json - do not edit by hand.
]]

return {
	Categories = {
		{ Name = "Interface", Icons = { "home", "settings", "sliders", "menu", "search", "x", "check", "plus", "minus", "chevron-right", "chevron-down", "arrow-left", "arrow-right", "external-link", "refresh", "filter", "grid", "list", "more" } },
		{ Name = "User & Security", Icons = { "user", "users", "user-plus", "crown", "shield", "shield-check", "lock", "unlock", "key", "eye", "eye-off", "bell", "star", "heart" } },
		{ Name = "Combat & Game", Icons = { "sword", "crosshair", "target", "zap", "flame", "skull", "bomb", "trophy", "gem", "coins", "gift", "package", "rocket" } },
		{ Name = "World & Movement", Icons = { "map", "map-pin", "compass", "navigation", "globe", "mountain", "sun", "moon", "cloud" } },
		{ Name = "Actions", Icons = { "play", "pause", "stop", "save", "download", "upload", "trash", "copy", "edit", "send", "link", "log-out", "power", "undo" } },
		{ Name = "Info & System", Icons = { "info", "alert", "help", "check-circle", "x-circle", "clock", "calendar", "bar-chart", "activity", "terminal", "code", "cpu", "wifi", "monitor", "smartphone", "keyboard", "mouse-pointer", "camera", "image", "music", "volume", "message" } },
		{ Name = "Farming & Harvest", Icons = { "sprout", "leaf", "wheat", "tree", "tree-round", "flower", "seed", "shovel", "watering-can", "droplet", "apple", "carrot", "grape", "cherry", "egg", "fish", "fishing-rod", "bug", "paw", "barn", "tractor", "basket" } },
		{ Name = "Tools & Gathering", Icons = { "axe", "pickaxe", "hammer", "wrench", "magnet", "hand", "recycle", "bag", "backpack" } },
		{ Name = "Automation", Icons = { "bot", "repeat", "timer", "hourglass", "workflow", "infinity", "route", "radar", "scan", "fast-forward", "skip-forward", "toggle", "trending-up", "layers" } },
		{ Name = "Economy & Items", Icons = { "cart", "store", "wallet", "dollar", "archive", "diamond", "potion", "scroll", "flag", "anchor" } },
		{ Name = "Blocks & Building", Icons = { "block", "blocks", "brick", "block-break", "block-place", "block-remove", "door", "ladder", "chest", "sign", "portal", "fence", "platform", "seed-pack" } },
		{ Name = "Player & Movement", Icons = { "player", "player-run", "jump", "move", "move-vertical", "move-horizontal", "rotate", "teleport", "fly", "footprints", "spawn", "punch", "swim", "ghost", "speed", "health" } },
	},
	Aliases = {
		["aim"] = "crosshair",
		["alert-triangle"] = "alert",
		["auto"] = "bot",
		["break"] = "block-break",
		["build"] = "block-place",
		["cash"] = "dollar",
		["character"] = "player",
		["chart"] = "bar-chart",
		["chat"] = "message",
		["chop"] = "axe",
		["close"] = "x",
		["cog"] = "settings",
		["crop"] = "wheat",
		["cube"] = "block",
		["ellipsis"] = "more",
		["exit"] = "log-out",
		["farm"] = "sprout",
		["fire"] = "flame",
		["flash"] = "zap",
		["gear"] = "settings",
		["hamburger"] = "menu",
		["harvest"] = "wheat",
		["help-circle"] = "help",
		["home-2"] = "home",
		["house"] = "home",
		["inventory"] = "backpack",
		["lightning"] = "zap",
		["location"] = "map-pin",
		["loop"] = "repeat",
		["mine"] = "pickaxe",
		["money"] = "dollar",
		["pc"] = "monitor",
		["pencil"] = "edit",
		["phone"] = "smartphone",
		["pin"] = "map-pin",
		["plant"] = "sprout",
		["players"] = "users",
		["question"] = "help",
		["reset"] = "undo",
		["run"] = "player-run",
		["shop"] = "store",
		["sound"] = "volume",
		["star-filled"] = "star",
		["tp"] = "teleport",
		["trash-2"] = "trash",
		["walk"] = "footprints",
		["wall"] = "brick",
		["warning"] = "alert",
		["water"] = "droplet",
	},
}
end

__modules["Core/Icons"] = function(...)
--[[
	Core/Icons
	Named built-in icons: Icon = "settings", "sword", "map-pin", ...

	Names map to white PNGs hosted in this repo (assets/icons/png/<name>.png),
	which Core/Assets downloads once, caches and tints at runtime.
	The list itself is generated into Core/IconList by tools/build_icons.py.

	Icons.Normalize("Map Pin")  -> "map-pin"   (case/space/underscore-insensitive, aliases applied)
	Icons.Has("gear")           -> true        (alias of "settings")
	Icons.ToUrl("settings")     -> "https://raw.githubusercontent.com/.../settings.png"
	Icons.SetBaseUrl(url)       -- host the PNGs yourself
	Icons.GetAll()              -> { { Name = "Interface", Icons = { ... } }, ... }
]]

local import = ...
local IconList = import("Core/IconList")

local DEFAULT_BASE_URL = "https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/assets/icons/png/"

local Icons = {}

local baseUrl = DEFAULT_BASE_URL
local known = {} -- [name] = true

for _, category in ipairs(IconList.Categories) do
	for _, name in ipairs(category.Icons) do
		known[name] = true
	end
end

-- Returns the canonical icon name, or nil when `source` is not an icon name.
-- Anything that looks like an id, URL or file path is never treated as an icon.
function Icons.Normalize(source)
	if type(source) ~= "string" or source == "" then
		return nil
	end
	if string.find(source, "[/:%.]") or string.match(source, "^%d+$") then
		return nil
	end

	local name = string.lower(source)
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	name = string.gsub(name, "[%s_]+", "-")

	if known[name] then
		return name
	end
	local alias = IconList.Aliases[name]
	if alias and known[alias] then
		return alias
	end
	return nil
end

function Icons.Has(source)
	return Icons.Normalize(source) ~= nil
end

function Icons.ToUrl(source)
	local name = Icons.Normalize(source)
	return name and (baseUrl .. name .. ".png") or nil
end

function Icons.SetBaseUrl(url)
	assert(type(url) == "string" and url ~= "", "SetIconBaseUrl expects a URL string")
	if string.sub(url, -1) ~= "/" then
		url = url .. "/"
	end
	baseUrl = url
end

function Icons.GetAll()
	local copy = {}
	for index, category in ipairs(IconList.Categories) do
		copy[index] = { Name = category.Name, Icons = table.clone(category.Icons) }
	end
	return copy
end

return Icons
end

__modules["Core/Services"] = function(...)
--[[
	Core/Services
	Cached Roblox services.
]]

local Players = game:GetService("Players")

return {
	Players = Players,
	TweenService = game:GetService("TweenService"),
	UserInputService = game:GetService("UserInputService"),
	HttpService = game:GetService("HttpService"),
	RunService = game:GetService("RunService"),
	CoreGui = game:GetService("CoreGui"),
	LocalPlayer = Players.LocalPlayer,
}
end

__modules["Core/State"] = function(...)
--[[
	Core/State
	Shared, mutable runtime state used by every module.
	Kept in one place so modules never hold their own copies.
]]

local State = {
	Version = "1.10.0",

	-- Public
	Flags = {},

	-- Theme
	ThemeName = "Dark",
	Theme = nil, -- active theme table (copy of a preset + overrides)
	ThemeObjects = {}, -- { instance, property, themeKey }
	ThemeCallbacks = {}, -- functions re-run on theme change

	-- Runtime
	Gui = nil, -- root ScreenGui
	NotifyHolder = nil,
	Connections = {},
	Windows = {},
}

return State
end

__modules["Core/Theme"] = function(...)
--[[
	Core/Theme
	Theme registry: binds instance properties to theme keys so the whole UI
	can be re-themed live with a tween.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Themes = import("Themes")

local Theme = {}

function Theme.Get()
	return State.Theme
end

-- Theme.Bind(frame, { BackgroundColor3 = "Element" })
function Theme.Bind(instance, map)
	for property, key in pairs(map) do
		instance[property] = State.Theme[key]
		table.insert(State.ThemeObjects, { instance, property, key })
	end
	return instance
end

-- Registers a function re-run after every theme change (for state-driven colors)
function Theme.OnChange(callback)
	table.insert(State.ThemeCallbacks, callback)
	return callback
end

-- Makes sure a theme is active; optionally switches preset / accent
function Theme.Ensure(name, accent)
	if State.Theme and name == nil and accent == nil then
		return State.Theme
	end

	local resolved = (name and Themes[name]) and name or State.ThemeName
	State.ThemeName = resolved
	State.Theme = Utility.CopyTable(Themes[resolved] or Themes.Dark)
	if accent then
		State.Theme.Accent = accent
	end
	return State.Theme
end

local function refresh(filterKey)
	local alive = {}
	for _, entry in ipairs(State.ThemeObjects) do
		local instance, property, key = entry[1], entry[2], entry[3]
		if instance and instance.Parent then
			if not filterKey or key == filterKey then
				Utility.Tween(instance, { [property] = State.Theme[key] }, 0.3)
			end
			table.insert(alive, entry)
		end
	end
	State.ThemeObjects = alive

	for _, callback in ipairs(State.ThemeCallbacks) do
		pcall(callback)
	end
end

function Theme.Set(name, accent)
	if not Themes[name] then
		warn("[EakUI] Unknown theme: " .. tostring(name))
		return
	end
	State.ThemeName = name
	State.Theme = Utility.CopyTable(Themes[name])
	if accent then
		State.Theme.Accent = accent
	end
	refresh()
end

function Theme.SetAccent(color)
	State.Theme.Accent = color
	refresh("Accent")
end

function Theme.Reset()
	table.clear(State.ThemeObjects)
	table.clear(State.ThemeCallbacks)
end

return Theme
end

__modules["Core/Tooltip"] = function(...)
--[[
	Core/Tooltip
	One shared tooltip bubble that follows the cursor.

	Tooltip.Attach(guiObject, "Text")  -> handle { SetText(text), Detach() }

	Shows after a short hover delay, hides on leave or click. Any element
	accepts `Tooltip = "..."` through Element.new, so users rarely call this.
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Gui = import("Core/Gui")

local Create, Tween = Utility.Create, Utility.Tween

local DELAY = 0.35
local OFFSET = Vector2.new(14, 18)
local MAX_WIDTH = 240

local Tooltip = {}

local bubble, label
local owner -- object currently showing the tooltip
local token = 0 -- invalidates pending show timers

local function ensureBubble()
	if bubble and bubble.Parent then
		return
	end
	bubble = Create("Frame", {
		Name = "Tooltip",
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 200,
		Parent = Gui.Get(),
	}, {
		Utility.Corner(7),
		Utility.Padding(6, 7, 9, 9),
		Create("UISizeConstraint", { MaxSize = Vector2.new(MAX_WIDTH, math.huge) }),
	})
	Theme.Bind(bubble, { BackgroundColor3 = "ElementHover" })
	Builders.Stroke(0.8).Parent = bubble

	label = Builders.Label({
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextWrapped = true,
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 201,
		Parent = bubble,
	})
	Create("UISizeConstraint", { MaxSize = Vector2.new(MAX_WIDTH - 18, math.huge), Parent = label })
end

local function place(position)
	if not bubble then
		return
	end
	local viewport = Utility.GetViewport()
	local size = bubble.AbsoluteSize
	local x = math.min(position.X + OFFSET.X, viewport.X - size.X - 8)
	local y = position.Y + OFFSET.Y
	if y + size.Y > viewport.Y - 8 then
		y = position.Y - size.Y - 8
	end
	bubble.Position = UDim2.fromOffset(x, y)
end

local function hide(target)
	if target and owner ~= target then
		return
	end
	token += 1
	owner = nil
	if bubble then
		bubble.Visible = false
	end
end

function Tooltip.Attach(target, text)
	local handle = { Text = text }
	local lastPosition = Vector2.zero
	local connections = {}

	local function connect(signal, fn)
		local connection = signal:Connect(fn)
		table.insert(connections, connection)
		Utility.Track(connection)
	end

	connect(target.MouseEnter, function()
		if not handle.Text or handle.Text == "" then
			return
		end
		token += 1
		local myToken = token
		task.delay(DELAY, function()
			if myToken ~= token or not target.Parent then
				return
			end
			ensureBubble()
			owner = target
			label.Text = handle.Text
			bubble.Visible = true
			place(lastPosition)
			bubble.BackgroundTransparency = 0.3
			Tween(bubble, { BackgroundTransparency = 0.04 }, 0.15)
		end)
	end)

	connect(target.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			lastPosition = Vector2.new(input.Position.X, input.Position.Y)
			if owner == target then
				place(lastPosition)
			end
		end
	end)

	connect(target.MouseLeave, function()
		hide(target)
		token += 1
	end)

	connect(target.InputBegan, function(input)
		if Utility.IsClick(input) then
			hide(target)
		end
	end)

	function handle:SetText(newText)
		handle.Text = newText
		if owner == target and label then
			label.Text = newText or ""
		end
	end

	function handle:Detach()
		hide(target)
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	return handle
end

return Tooltip
end

__modules["Core/Utility"] = function(...)
--[[
	Core/Utility
	Pure helpers: instance creation, tweening, layout objects, input checks.
	Nothing here depends on the active theme.
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")

local TweenService = Services.TweenService

local Utility = {}

function Utility.CopyTable(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

-- Registers a connection so it is cleaned up when the UI is destroyed
function Utility.Track(connection)
	table.insert(State.Connections, connection)
	return connection
end

function Utility.DisconnectAll()
	for _, connection in ipairs(State.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(State.Connections)
end

-- Instance.new with properties and children; Parent is applied last
function Utility.Create(className, properties, children)
	local instance = Instance.new(className)
	local parent

	for key, value in pairs(properties or {}) do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end

	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end

	if parent then
		instance.Parent = parent
	end
	return instance
end

function Utility.Tween(instance, goal, duration, style, direction)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

function Utility.Corner(radius)
	return Utility.Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function Utility.Padding(top, bottom, left, right)
	return Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
	})
end

function Utility.List(padding, direction, horizontal, vertical)
	return Utility.Create("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

-- Runs a user callback in its own thread; errors are logged, never thrown
function Utility.SafeCall(callback, ...)
	if type(callback) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(callback, table.unpack(args, 1, args.n))
		if not ok then
			warn("[EakUI] Callback error: " .. tostring(err))
		end
	end)
end

function Utility.IsClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Utility.IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

function Utility.GetViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

function Utility.RandomName()
	return (Services.HttpService:GenerateGUID(false):gsub("-", ""))
end

return Utility
end

__modules["init"] = function(...)
--[[
	EakUI — custom UI library for Roblox script hubs
	100% Instance.new(), no external dependencies.

	Entry point. Exposes the public API only; implementation lives in
	Core/, Components/, Themes/ and Window/.

	local UI = loadstring(game:HttpGet("<raw url>/dist/EakUI.lua"))()
	local Window = UI:CreateWindow({ Title = "MyHub", Size = UDim2.fromOffset(500, 400), Theme = "Dark" })
]]

local import = ...
local State = import("Core/State")
local Theme = import("Core/Theme")
local Themes = import("Themes")
local Window = import("Window")
local Notify = import("Components/Notification")
local Assets = import("Core/Assets")
local Icons = import("Core/Icons")
local KeySystem = import("KeySystem")

Theme.Ensure("Dark")

local EakUI = {
	Version = State.Version,
	Flags = State.Flags,
	Themes = Themes,
}

--[[
	CreateWindow(config). With config.KeySystem = { ... } the key screen is
	shown first; this call then yields and returns nil if no valid key was
	entered (the user closed the key screen).
]]
function EakUI:CreateWindow(config)
	config = config or {}
	if type(config.KeySystem) == "table" then
		local options = table.clone(config.KeySystem)
		options.Title = options.Title or config.Title
		options.Logo = options.Logo or config.Logo
		options.Theme = options.Theme or config.Theme
		options.Accent = options.Accent or config.Accent
		local ok = KeySystem.new(options):Wait()
		if not ok then
			return nil
		end
	end
	return Window.new(config)
end

-- License key screen. :Wait() yields until verified (true, info) or closed (false).
function EakUI:KeySystem(config)
	return KeySystem.new(config)
end

function EakUI:Notify(config)
	return Notify(config)
end

function EakUI:SetTheme(name, accent)
	Theme.Set(name, accent)
end

function EakUI:SetAccent(color)
	Theme.SetAccent(color)
end

-- Download URL images ahead of time so they appear instantly later
function EakUI:Preload(sources)
	Assets.Preload(sources)
end

-- Resolve any image source (id, URL, file or icon name) for use in your own ImageLabels
function EakUI:GetImage(source)
	return Assets.Resolve(source)
end

-- Built-in named icons (see ICONS.md)
function EakUI:GetIcons()
	return Icons.GetAll()
end

function EakUI:HasIcon(name)
	return Icons.Has(name)
end

-- Load icon PNGs from your own host (folder URL containing <name>.png files)
function EakUI:SetIconBaseUrl(url)
	Icons.SetBaseUrl(url)
end

function EakUI:GetTheme()
	return State.ThemeName, State.Theme
end

function EakUI:Destroy()
	for _, window in ipairs(table.clone(State.Windows)) do
		pcall(function()
			window:Destroy()
		end)
	end
end

return EakUI
end

__modules["KeySystem/Format"] = function(...)
--[[
	KeySystem/Format
	Pure helpers for license key formatting. No Instances, no side effects,
	so the rules can be reasoned about (and tested) on their own.

	local fmt = Format.new({ Prefix = "EAKHUB", Groups = 3, GroupSize = 4 })
	fmt:Apply("eakhub 7a4b28c1")  --> "EAKHUB-7A4B-28C1"
	fmt:Apply("7a4b")             --> "EAKHUB-7A4B"   (prefix is added for you)
	fmt:IsComplete("EAKHUB-7A4B-28C1-9F3E") --> true
	fmt:Count("EAKHUB-7A4B")      --> 4  (characters typed after the prefix)
	fmt.Placeholder               --> "EAKHUB-XXXX-XXXX-XXXX"

	Format = false in the KeySystem config gives a free-form formatter that
	only trims whitespace (for key providers with their own key shape).
]]

local Format = {}
Format.__index = Format

local function clean(text)
	return (string.upper(text or ""):gsub("[^A-Z0-9]", ""))
end

local function trim(text)
	return ((text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function Format.new(config)
	config = config or {}
	local self = setmetatable({}, Format)

	self.FreeForm = config.Format == false
	self.Prefix = clean(config.Prefix == nil and "EAKHUB" or config.Prefix)
	self.Groups = math.max(1, config.Groups or 3)
	self.GroupSize = math.max(1, config.GroupSize or 4)
	self.Length = self.Groups * self.GroupSize
	self.MaxLength = #self.Prefix + self.Length + self.Groups -- prefix + body + dashes

	if self.FreeForm then
		self.Placeholder = config.Placeholder or "Paste your key here"
	else
		local parts = {}
		if self.Prefix ~= "" then
			table.insert(parts, self.Prefix)
		end
		for _ = 1, self.Groups do
			table.insert(parts, string.rep("X", self.GroupSize))
		end
		self.Placeholder = config.Placeholder or table.concat(parts, "-")
	end
	return self
end

-- Characters after the prefix, without dashes
function Format:Body(text)
	local body = clean(text)
	local prefix = self.Prefix
	if prefix ~= "" and string.sub(body, 1, #prefix) == prefix then
		body = string.sub(body, #prefix + 1)
	end
	return body
end

function Format:Apply(raw)
	if self.FreeForm then
		return trim(raw)
	end

	local body = clean(raw)
	local prefix = self.Prefix

	if prefix ~= "" then
		if string.sub(body, 1, #prefix) == prefix then
			body = string.sub(body, #prefix + 1)
		elseif #body < #prefix and string.sub(prefix, 1, #body) == body then
			-- Still typing (or deleting) the prefix itself: leave it alone
			return body
		end
	end

	body = string.sub(body, 1, self.Length)
	if body == "" then
		return prefix -- no trailing dash, so backspace keeps working
	end

	local groups = {}
	for index = 1, #body, self.GroupSize do
		table.insert(groups, string.sub(body, index, index + self.GroupSize - 1))
	end

	local joined = table.concat(groups, "-")
	return prefix ~= "" and (prefix .. "-" .. joined) or joined
end

function Format:Count(text)
	if self.FreeForm then
		return #trim(text)
	end
	local cleaned = clean(text)
	local prefix = self.Prefix
	if #cleaned < #prefix and string.sub(prefix, 1, #cleaned) == cleaned then
		return 0 -- still typing the prefix
	end
	return #self:Body(text)
end

function Format:IsComplete(text)
	if self.FreeForm then
		return #trim(text) > 0
	end
	return self:Apply(text) == text and #self:Body(text) == self.Length
end

-- "EAKHUB-7A4B-••••-9F3E": safe to show on screen
function Format:Mask(text)
	text = text or ""
	if #text <= 8 then
		return text
	end
	if self.FreeForm or self.Groups < 3 then
		return string.sub(text, 1, 4) .. string.rep("•", 4) .. string.sub(text, -4)
	end
	local groups = string.split(text, "-")
	for index = 2, #groups - 1 do
		if index > (self.Prefix ~= "" and 2 or 1) then
			groups[index] = string.rep("•", #groups[index])
		end
	end
	return table.concat(groups, "-")
end

return Format
end

__modules["KeySystem"] = function(...)
--[[
	KeySystem
	License / key gate shown before the hub loads.

	local Key = UI:KeySystem({
		Title     = "EakHub",
		Logo      = "https://.../logo.png",     -- optional, any image source or icon name
		Prefix    = "EAKHUB", Groups = 3, GroupSize = 4, -- EAKHUB-XXXX-XXXX-XXXX
		Keys      = { "EAKHUB-7A4B-28C1-9F3E" },  -- simple static list, or:
		Verify    = function(key)                -- runs in its own thread, may yield (HttpGet...)
			return true, { Plan = "Premium", Expires = os.time() + 29 * 86400 }
			-- return false, "This key has expired"
		end,
		Discord   = "https://discord.gg/xxxx",
		GetKey    = "https://link-to-get-a-key", -- string (copied) or function
	})

	local ok, info = Key:Wait()   -- yields until verified (true, info) or closed (false)
	if not ok then return end

	Shortcut: UI:CreateWindow({ ..., KeySystem = { ...same options... } })
	returns nil when the key screen is closed without a valid key.

	See README for every option.
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Gui = import("Core/Gui")
local Assets = import("Core/Assets")
local Draggable = import("Core/Draggable")
local Notify = import("Components/Notification")
local Format = import("KeySystem/Format")
local Storage = import("KeySystem/Storage")
local Widgets = import("KeySystem/Widgets")
local KeyField = import("KeySystem/KeyField")
local SuccessView = import("KeySystem/SuccessView")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local WIDTH = 420
local TOPBAR = 50
local INFO = Color3.fromRGB(56, 189, 248)
local DISCORD = Color3.fromRGB(88, 101, 242)

local KeySystem = {}
KeySystem.__index = KeySystem

---------------------------------------------------------------- helpers
local function copy(text)
	local writer = setclipboard or toclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
	if type(writer) ~= "function" then
		return false
	end
	return (pcall(writer, text))
end

local function toast(enabled, title, content, kind)
	if enabled then
		Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 4 })
	end
end

-- Normalises whatever Verify returned into ok, info | ok, message
local function interpret(...)
	local first, second = ...
	if type(first) == "table" then
		return true, first
	end
	if first == true then
		return true, type(second) == "table" and second or {}
	end
	if type(first) == "string" and second == nil then
		return false, first
	end
	return false, type(second) == "string" and second or "Invalid key"
end

local function staticVerifier(keys)
	local lookup = {}
	for key, value in pairs(keys) do
		if type(key) == "number" then
			lookup[string.upper(value)] = {}
		else
			lookup[string.upper(key)] = type(value) == "table" and value or {} -- { [key] = info }
		end
	end
	return function(key)
		local info = lookup[string.upper(key)]
		if info then
			return true, info
		end
		return false, "Invalid key. Check it and try again."
	end
end

---------------------------------------------------------------- constructor
function KeySystem.new(config)
	config = config or {}
	Theme.Ensure(config.Theme or "Dark", config.Accent)

	local title = config.Title or "EakHub"
	local self = setmetatable({
		Config = config,
		Verified = false,
		Closed = false,
		Key = nil,
		Info = nil,
		_waiting = {},
		_busy = false,
		_cancelLaunch = nil,
		_toasts = config.Notify ~= false,
	}, KeySystem)

	self.Formatter = Format.new(config)
	self.Storage = config.SaveKey ~= false and Storage.new(config.FileName or (title:gsub("[^%w_%-]", "") .. "/key.txt"))
	self.Verifier = config.Verify or (config.Keys and staticVerifier(config.Keys))
	if not self.Verifier then
		warn("[EakUI] KeySystem: no Verify function or Keys list given, every key will be rejected")
		self.Verifier = function()
			return false, "Key checking is not configured"
		end
	end

	local screenGui = Gui.Get()

	---------------------------------------------------------------- backdrop + card
	local backdrop
	if config.Backdrop ~= false then
		backdrop = Create("Frame", {
			Name = "KeyBackdrop",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 50,
			Parent = screenGui,
		})
		Tween(backdrop, { BackgroundTransparency = 0.45 }, 0.3)
	end
	self._backdrop = backdrop

	local root = Create("Frame", {
		Name = "KeySystem",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, 400),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = screenGui,
	})
	self.Instance = root
	local rootScale = Create("UIScale", { Scale = 0.94, Parent = root })
	self._scale = rootScale

	Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 8),
		Size = UDim2.new(1, 70, 1, 70),
		BackgroundTransparency = 1,
		Image = Constants.Shadow.Image,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.4,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Constants.Shadow.SliceCenter,
		ZIndex = 51,
		Parent = root,
	})

	local card = Create("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ZIndex = 52,
		Parent = root,
	}, {
		Corner(16),
		Utility.List(0),
		Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 215)),
		}),
	})
	Theme.Bind(card, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.86).Parent = card

	-- The root keeps a fixed size that follows the card, so the shadow (sized
	-- relative to the root) never feeds back into an AutomaticSize parent.
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local scale = math.max(rootScale.Scale, 0.01)
		root.Size = UDim2.fromOffset(WIDTH, math.floor(card.AbsoluteSize.Y / scale + 0.5))
	end)
	self._card = card

	self:_buildTopbar(card, title)

	-- Pages
	local form = Create("Frame", {
		Name = "Form",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = card,
	}, {
		Utility.Padding(20, 18, 24, 24),
		Utility.List(14),
	})
	self._form = form
	self:_buildForm(form, title)

	self._success = SuccessView.new(card, {
		LayoutOrder = 3,
		Title = config.SuccessTitle,
		OnReset = config.AllowReset ~= false and function()
			self:_reset()
		end or nil,
	})

	---------------------------------------------------------------- fit + intro
	local function fit()
		local viewport = Utility.GetViewport()
		local height = math.max(root.AbsoluteSize.Y / math.max(rootScale.Scale, 0.01), 1)
		return math.clamp(math.min(1, (viewport.X - 24) / WIDTH, (viewport.Y - 24) / height), 0.55, 1)
	end
	self._fit = fit
	task.defer(function()
		Tween(rootScale, { Scale = fit() }, 0.35, Enum.EasingStyle.Back)
	end)

	-- Saved key
	local saved = self.Storage and self.Storage:Load()
	if saved then
		self._saved = saved
		self._banner.Visible = true
		toast(self._toasts, "Key found", "A saved license key was detected.", "Info")
		if config.AutoLogin then
			self._field:Set(saved)
			task.defer(function()
				self:Verify()
			end)
		end
	end

	return self
end

---------------------------------------------------------------- topbar
function KeySystem:_buildTopbar(card, title)
	local config = self.Config
	local bar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, TOPBAR),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = card,
	})

	local row = Create("Frame", {
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		BackgroundTransparency = 1,
		Parent = bar,
	}, { Utility.List(10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	local tile = Create("Frame", {
		Size = UDim2.fromOffset(26, 26),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 1,
		Parent = row,
	}, { Corner(8) })
	Theme.Bind(tile, { BackgroundColor3 = "Accent" })
	if config.Logo then
		local logo = Create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = tile,
		}, { Corner(8) })
		Assets.Apply(logo, config.Logo)
	else
		Create("TextLabel", {
			Text = string.upper(string.sub(title, 1, 1)),
			Font = Fonts.Black,
			TextSize = 14,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = tile,
		})
	end

	Builders.Label({
		Text = title,
		Font = Fonts.Black,
		TextSize = 15,
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = row,
	})

	if config.Pill ~= false then
		local pill = Create("Frame", {
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
			LayoutOrder = 3,
			Parent = row,
		}, { Corner(999), Utility.Padding(0, 0, 9, 9) })
		Theme.Bind(pill, { BackgroundColor3 = "Accent" })
		Builders.Label({
			Text = config.Pill or "License",
			Font = Fonts.Bold,
			TextSize = 11,
			ThemeColor = "SubText",
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = pill,
		})
	end

	local close = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Parent = bar,
	}, { Corner(8) })
	Builders.CrossIcon(close, 12, "SubText")
	close.MouseEnter:Connect(function()
		Tween(close, { BackgroundTransparency = 0.92 }, 0.15)
	end)
	close.MouseLeave:Connect(function()
		Tween(close, { BackgroundTransparency = 1 }, 0.15)
	end)
	close.MouseButton1Click:Connect(function()
		self:Close()
	end)
	if config.Closable == false then
		close.Visible = false
	end

	local divider = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		Parent = bar,
	})
	divider.Name = "Divider"

	Draggable(bar, self.Instance)
end

---------------------------------------------------------------- form
function KeySystem:_buildForm(form, title)
	local config = self.Config

	-- Hero
	local hero = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = form,
	}, { Utility.List(10, nil, Enum.HorizontalAlignment.Center) })

	local lock = Create("Frame", {
		Size = UDim2.fromOffset(52, 52),
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = hero,
	}, { Corner(15) })
	Theme.Bind(lock, { BackgroundColor3 = "Accent" })
	local lockStroke = Create("UIStroke", { Transparency = 0.65, Parent = lock })
	Theme.Bind(lockStroke, { Color = "Accent" })
	Widgets.Icon(lock, config.HeroIcon or "lock", 24, "Accent", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})

	local texts = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = hero,
	}, { Utility.List(4, nil, Enum.HorizontalAlignment.Center) })
	Builders.Label({
		Text = config.Heading or ("Activate " .. title),
		Font = Fonts.Bold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = texts,
	})
	Builders.Label({
		Text = config.Subtitle or "Enter your license key to unlock the hub",
		TextSize = 13,
		ThemeColor = "SubText",
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = texts,
	})

	-- Saved-key banner
	local banner = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = INFO,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Visible = false,
		LayoutOrder = 2,
		Parent = form,
	}, { Corner(11) })
	Create("UIStroke", { Color = INFO, Transparency = 0.75, Parent = banner })
	Widgets.Icon(banner, "info", 16, INFO, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
	})
	Create("TextLabel", {
		Text = config.SavedText or "Saved key found on this device",
		Font = Fonts.Medium,
		TextSize = 12,
		TextColor3 = INFO:Lerp(Color3.new(1, 1, 1), 0.7),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Parent = banner,
	})
	local useSaved = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(60, 28),
		BackgroundColor3 = INFO,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Fonts.Bold,
		TextSize = 12,
		TextColor3 = INFO,
		Text = "Use it",
		Parent = banner,
	}, { Corner(7) })
	useSaved.MouseEnter:Connect(function()
		Tween(useSaved, { BackgroundTransparency = 0.85 }, 0.15)
	end)
	useSaved.MouseLeave:Connect(function()
		Tween(useSaved, { BackgroundTransparency = 1 }, 0.15)
	end)
	useSaved.MouseButton1Click:Connect(function()
		if self._saved and not self._busy then
			self._field:Set(self._saved)
			banner.Visible = false
		end
	end)
	self._banner = banner

	-- Key field
	local field = KeyField.new(form, self.Formatter, { LayoutOrder = 3, Label = config.FieldLabel })
	field:Submitted(function()
		self:Verify()
	end)
	self._field = field

	-- Remember
	if self.Storage then
		self._remember = Widgets.Checkbox(form, config.RememberText or "Remember key on this device", config.Remember ~= false, nil, 4)
	end

	-- Primary
	self._primary = Widgets.Button(form, {
		Text = config.ButtonText or "Verify & Launch",
		TrailingIcon = "arrow-right",
		Height = 46,
		LayoutOrder = 5,
		Callback = function()
			self:Verify()
		end,
	})

	-- Discord
	if config.Discord then
		local discordText = config.DiscordText or "Join Discord"
		local discord
		discord = Widgets.Button(form, {
			Text = discordText,
			Icon = "message",
			Style = "Tinted",
			Color = DISCORD,
			Height = 42,
			LayoutOrder = 6,
			Callback = function()
				if type(config.Discord) == "function" then
					config.Discord()
					return
				end
				if copy(config.Discord) then
					discord:SetText("Invite copied")
					toast(self._toasts, "Discord invite copied", "Paste it in your browser to join.", "Success")
					task.delay(2, function()
						discord:SetText(discordText)
					end)
				else
					toast(self._toasts, "Join our Discord", tostring(config.Discord), "Info")
				end
			end,
		})
		self._discord = discord
	end

	-- Footer links
	local hasGetKey = config.GetKey ~= nil
	local hasHelp = config.Help ~= nil
	if hasGetKey or hasHelp then
		local footer = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			LayoutOrder = 7,
			Parent = form,
		}, {
			Utility.List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
		})

		if hasGetKey then
			local getKeyText = config.GetKeyText or "Get a key"
			local getKey
			getKey = Widgets.Button(footer, {
				Text = getKeyText,
				Style = "Link",
				LayoutOrder = 1,
				Callback = function()
					if type(config.GetKey) == "function" then
						config.GetKey()
					elseif copy(tostring(config.GetKey)) then
						getKey:SetText("Link copied")
						toast(self._toasts, "Key link copied", "Paste it in your browser to get a key.", "Success")
						task.delay(2, function()
							getKey:SetText(getKeyText)
						end)
					else
						toast(self._toasts, "Get a key", tostring(config.GetKey), "Info")
					end
				end,
			})
		end

		if hasGetKey and hasHelp then
			local dot = Create("Frame", {
				Size = UDim2.fromOffset(3, 3),
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				Parent = footer,
			}, { Corner(2) })
			Theme.Bind(dot, { BackgroundColor3 = "SubText" })
		end

		if hasHelp then
			Widgets.Button(footer, {
				Text = config.HelpText or "Need help?",
				Style = "Link",
				LayoutOrder = 3,
				Callback = function()
					if type(config.Help) == "function" then
						config.Help()
					else
						toast(true, config.HelpText or "Need help?", tostring(config.Help), "Info")
					end
				end,
			})
		end
	end
end

---------------------------------------------------------------- flow
function KeySystem:_setBusy(busy)
	self._busy = busy
	self._field:SetEnabled(not busy)
	self._primary:SetBusy(busy, busy and (self.Config.VerifyingText or "Verifying key...") or (self.Config.ButtonText or "Verify & Launch"))
end

function KeySystem:_fail(message)
	self:_setBusy(false)
	self._field:SetError(message)
	self._field:Shake()
	toast(self._toasts, "Verification failed", message, "Error")
end

function KeySystem:Verify(key)
	if self._busy or self.Verified or self.Closed then
		return
	end
	if key then
		self._field:Set(key)
	end
	key = self._field:Get()

	if not self._field:IsComplete() then
		local message = key == "" and "Enter your license key first"
			or ("Incomplete key. It should look like " .. self.Formatter.Placeholder)
		self._field:SetError(message)
		self._field:Shake()
		return
	end

	self._field:SetError(nil)
	self:_setBusy(true)

	task.spawn(function()
		local started = os.clock()
		local results = table.pack(pcall(self.Verifier, key))
		-- Keep the spinner up briefly so instant checks do not flicker
		local elapsed = os.clock() - started
		if elapsed < 0.6 then
			task.wait(0.6 - elapsed)
		end
		if self.Closed then
			return
		end

		if not results[1] then
			warn("[EakUI] KeySystem Verify error: " .. tostring(results[2]))
			self:_fail("Could not verify the key right now. Try again.")
			return
		end

		local ok, payload = interpret(table.unpack(results, 2, results.n))
		if not ok then
			if self.Storage and self._saved == key then
				self.Storage:Clear() -- a saved key that stopped working is forgotten
				self._saved = nil
			end
			self:_fail(payload)
			return
		end

		self:_succeed(key, payload)
	end)
end

function KeySystem:_succeed(key, info)
	self:_setBusy(false)
	self.Key = key
	self.Info = info

	if self.Storage then
		if not self._remember or self._remember:Get() then
			self.Storage:Save(key)
		else
			self.Storage:Clear()
		end
	end

	local expiry = SuccessView.FormatExpiry(info.Expires)
	toast(self._toasts, "License activated", (info.Plan or "Licensed") .. (expiry and (" · " .. expiry) or ""), "Success")

	self._form.Visible = false
	self._success:Show(info, self.Formatter:Mask(key))

	local launchText = self.Config.LaunchText or ("Loading " .. (self.Config.Title or "EakHub") .. "...")
	self._cancelLaunch = self._success:Launch(self.Config.LaunchDelay or 1.6, launchText, function()
		self.Verified = true
		Utility.SafeCall(self.Config.OnSuccess, key, info)
		self:_resolve(true, info)
		self:Destroy()
	end)
end

function KeySystem:_reset()
	if self._cancelLaunch then
		self._cancelLaunch()
		self._cancelLaunch = nil
	end
	if self.Storage then
		self.Storage:Clear()
	end
	self._saved = nil
	self._banner.Visible = false
	self.Key, self.Info = nil, nil
	self._success:Hide()
	self._form.Visible = true
	self._field:Set("")
	self._field:SetError(nil)
end

function KeySystem:_resolve(ok, info)
	local waiting = self._waiting
	self._waiting = {}
	for _, thread in ipairs(waiting) do
		task.spawn(thread, ok, info)
	end
end

---------------------------------------------------------------- public
-- Yields until the key is accepted (true, info) or the screen is closed (false)
function KeySystem:Wait()
	if self.Verified then
		return true, self.Info
	end
	if self.Closed then
		return false
	end
	table.insert(self._waiting, (coroutine.running()))
	return coroutine.yield()
end

function KeySystem:IsVerified()
	return self.Verified
end

function KeySystem:GetSavedKey()
	return self.Storage and self.Storage:Load()
end

function KeySystem:ClearSavedKey()
	if self.Storage then
		self.Storage:Clear()
	end
end

function KeySystem:Close()
	if self.Closed or self.Verified then
		return
	end
	if self._cancelLaunch then
		self._cancelLaunch()
	end
	self.Closed = true
	Utility.SafeCall(self.Config.OnClose)
	self:_resolve(false)
	self:Destroy()
end

function KeySystem:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._primary:SetBusy(false)

	Tween(self._scale, { Scale = 0 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if self._backdrop then
		Tween(self._backdrop, { BackgroundTransparency = 1 }, 0.2)
	end
	task.delay(0.22, function()
		self.Instance:Destroy()
		if self._backdrop then
			self._backdrop:Destroy()
		end
	end)
end

return KeySystem
end

__modules["KeySystem/KeyField"] = function(...)
--[[
	KeySystem/KeyField
	License key input: label + live hint, auto-formatting monospace TextBox,
	valid-format check mark, Paste button and an inline error line.

	local field = KeyField.new(parent, formatter, { LayoutOrder = 3 })
	field:Get() / field:Set(text)
	field:IsComplete()
	field:SetError("Key expired") / field:SetError(nil)
	field:Shake(), field:Focus(), field:SetEnabled(bool)
	field:Changed(fn)   -- fn(text)
	field:Submitted(fn) -- Enter pressed
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Widgets = import("KeySystem/Widgets")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local SUCCESS = Color3.fromRGB(74, 222, 128)
local DANGER = Color3.fromRGB(248, 113, 113)
local HEIGHT = 48
local PASTE_WIDTH = 74

local KeyField = {}
KeyField.__index = KeyField

local function readClipboard()
	local reader = getclipboard or (syn and syn.read_clipboard) or (Clipboard and Clipboard.get)
	if type(reader) ~= "function" then
		return nil
	end
	local ok, text = pcall(reader)
	return ok and type(text) == "string" and text or nil
end

function KeyField.new(parent, formatter, options)
	options = options or {}
	local self = setmetatable({
		Formatter = formatter,
		Error = nil,
		Enabled = true,
		_focused = false,
		_changed = {},
		_submitted = {},
	}, KeyField)

	local holder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = options.LayoutOrder or 0,
		Parent = parent,
	}, { Utility.List(7) })
	self.Instance = holder

	-- Header: "License key" ............ hint
	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})
	Builders.Label({
		Text = options.Label or "License key",
		Font = Fonts.Bold,
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.5, 1),
		Parent = header,
	})
	self._hint = Create("TextLabel", { -- colored by _paint, not bound to the theme
		Text = "",
		Font = Fonts.Medium,
		TextSize = 12,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.6, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	-- Box (inside a fixed slot so it can shake without moving the layout)
	local slot = Create("Frame", {
		Size = UDim2.new(1, 0, 0, HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})
	local box = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = slot,
	}, { Corner(11) })
	Theme.Bind(box, { BackgroundColor3 = "Field" })
	self._box = box
	self._stroke = Create("UIStroke", {
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = box,
	})

	Widgets.Icon(box, "key", 16, "SubText", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
	})

	local textBox = Create("TextBox", {
		Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -(40 + PASTE_WIDTH + 34), 1, 0),
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Fonts.Mono,
		TextSize = 14,
		Text = "",
		PlaceholderText = formatter.Placeholder,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = box,
	})
	Theme.Bind(textBox, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })
	self._textBox = textBox

	self._check = Widgets.Icon(box, "check", 18, SUCCESS, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(PASTE_WIDTH + 12), 0.5, 0),
		ImageTransparency = 1,
	})

	local paste = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -7, 0.5, 0),
		Size = UDim2.fromOffset(PASTE_WIDTH, 34),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = box,
	}, {
		Corner(8),
		Utility.List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})
	Theme.Bind(paste, { BackgroundColor3 = "Element" })
	Builders.Stroke(0.9).Parent = paste
	Widgets.Icon(paste, "copy", 13, "Text", { LayoutOrder = 1 })
	Builders.Label({
		Text = "Paste",
		Font = Fonts.Bold,
		TextSize = 12,
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = paste,
	})
	self._paste = paste

	-- Error line
	local errorRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 3,
		Parent = holder,
	})
	Widgets.Icon(errorRow, "x-circle", 13, DANGER, { Position = UDim2.fromOffset(0, 1) })
	self._errorLabel = Create("TextLabel", {
		Position = UDim2.fromOffset(19, 0),
		Size = UDim2.new(1, -19, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Fonts.Medium,
		TextSize = 12,
		TextColor3 = DANGER,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		Parent = errorRow,
	})
	self._errorRow = errorRow

	---------------------------------------------------------------- behaviour
	local formatting = false
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		if formatting then
			return
		end
		local formatted = formatter:Apply(textBox.Text)
		if formatted ~= textBox.Text then
			formatting = true
			textBox.Text = formatted
			textBox.CursorPosition = #formatted + 1
			formatting = false
		end
		if self.Error then
			self:SetError(nil)
		end
		self:_paint()
		for _, callback in ipairs(self._changed) do
			Utility.SafeCall(callback, formatted)
		end
	end)

	textBox.Focused:Connect(function()
		self._focused = true
		self:_paint()
	end)
	textBox.FocusLost:Connect(function(enterPressed)
		self._focused = false
		self:_paint()
		if enterPressed then
			for _, callback in ipairs(self._submitted) do
				Utility.SafeCall(callback, textBox.Text)
			end
		end
	end)

	paste.MouseButton1Click:Connect(function()
		if not self.Enabled then
			return
		end
		local text = readClipboard()
		if text and text ~= "" then
			self:Set(text)
		else
			-- No clipboard read API on this executor: focus so Ctrl+V works
			textBox:CaptureFocus()
			self:_setHint("Press Ctrl+V to paste", Theme.Get().Text)
			task.delay(2, function()
				self:_paint()
			end)
		end
	end)

	Theme.OnChange(function()
		if holder.Parent then
			self:_paint(true)
		end
	end)

	self:_paint(true)
	return self
end

function KeyField:_setHint(text, color)
	self._hint.Text = text
	self._hint.TextColor3 = color
end

function KeyField:_paint(instant)
	local theme = Theme.Get()
	local text = self._textBox.Text
	local complete = self.Formatter:IsComplete(text)
	local t = instant and 0 or 0.18

	-- Hint
	if complete then
		self:_setHint("Looks good", SUCCESS)
	elseif text ~= "" and not self.Formatter.FreeForm then
		self:_setHint(("%d / %d characters"):format(self.Formatter:Count(text), self.Formatter.Length), theme.SubText)
	elseif self.Formatter.FreeForm then
		self:_setHint("", theme.Placeholder)
	else
		self:_setHint("Format: " .. self.Formatter.Placeholder, theme.Placeholder)
	end

	-- Border
	local color, transparency = theme.Stroke, 0.9
	if self.Error then
		color, transparency = DANGER, 0.3
	elseif complete then
		color, transparency = SUCCESS, 0.45
	elseif self._focused then
		color, transparency = theme.Accent, 0.35
	end
	Tween(self._stroke, { Color = color, Transparency = transparency }, t)
	Tween(self._check, { ImageTransparency = (complete and not self.Error) and 0 or 1 }, t)
end

function KeyField:Get()
	return self._textBox.Text
end

function KeyField:Set(text)
	self._textBox.Text = self.Formatter:Apply(text or "")
end

function KeyField:IsComplete()
	return self.Formatter:IsComplete(self:Get())
end

function KeyField:SetError(message)
	self.Error = message
	self._errorRow.Visible = message ~= nil
	self._errorLabel.Text = message or ""
	self:_paint()
end

function KeyField:Shake()
	local box = self._box
	task.spawn(function()
		for _, offset in ipairs({ -7, 7, -5, 5, -2, 0 }) do
			Tween(box, { Position = UDim2.fromOffset(offset, 0) }, 0.05, Enum.EasingStyle.Sine)
			task.wait(0.05)
		end
	end)
end

function KeyField:Focus()
	self._textBox:CaptureFocus()
end

function KeyField:SetEnabled(enabled)
	self.Enabled = enabled
	self._textBox.TextEditable = enabled
	self._textBox.TextTransparency = enabled and 0 or 0.4
	self._paste.Active = enabled
end

function KeyField:Changed(callback)
	table.insert(self._changed, callback)
end

function KeyField:Submitted(callback)
	table.insert(self._submitted, callback)
end

return KeyField
end

__modules["KeySystem/Storage"] = function(...)
--[[
	KeySystem/Storage
	Remembers the last verified key in the executor workspace.
	Every call is wrapped in pcall: executors without a file system simply
	get "nothing saved" instead of an error.

	local store = Storage.new("EakHub/key.txt")
	store:Load()      --> "EAKHUB-..." | nil
	store:Save(key)
	store:Clear()
]]

local Storage = {}
Storage.__index = Storage

local function available()
	return type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function"
end

local function ensureFolder(path)
	if type(makefolder) ~= "function" or type(isfolder) ~= "function" then
		return
	end
	local current = ""
	local parts = string.split(path, "/")
	for index = 1, #parts - 1 do
		current = current == "" and parts[index] or (current .. "/" .. parts[index])
		if not isfolder(current) then
			makefolder(current)
		end
	end
end

function Storage.new(fileName)
	local self = setmetatable({}, Storage)
	self.Path = (fileName or "EakUI/key.txt"):gsub("\\", "/")
	return self
end

function Storage:Load()
	if not available() then
		return nil
	end
	local ok, content = pcall(function()
		if isfile(self.Path) then
			return readfile(self.Path)
		end
		return nil
	end)
	if not ok or type(content) ~= "string" then
		return nil
	end
	content = content:gsub("%s", "")
	return content ~= "" and content or nil
end

function Storage:Save(key)
	if not available() then
		return false
	end
	return (pcall(function()
		ensureFolder(self.Path)
		writefile(self.Path, key)
	end))
end

function Storage:Clear()
	if not available() then
		return
	end
	pcall(function()
		if type(delfile) == "function" and isfile(self.Path) then
			delfile(self.Path)
		else
			writefile(self.Path, "")
		end
	end)
end

return Storage
end

__modules["KeySystem/SuccessView"] = function(...)
--[[
	KeySystem/SuccessView
	Shown after a key is accepted: check mark, welcome line, license details
	(plan, expiry, masked key) and a launch progress bar.

	local view = SuccessView.new(parent, { OnReset = fn })
	view:Show(info, maskedKey)
	view:Launch(seconds, onDone) -> cancel()
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Widgets = import("KeySystem/Widgets")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local SUCCESS = Color3.fromRGB(74, 222, 128)

local SuccessView = {}
SuccessView.__index = SuccessView

-- 1795400000 -> "22 Dec 2026 · 29 days"; true/"Lifetime" -> "Lifetime"
function SuccessView.FormatExpiry(expires)
	if expires == nil then
		return nil
	end
	if expires == true or expires == false or expires == 0 then
		return "Lifetime"
	end
	if type(expires) ~= "number" then
		return tostring(expires)
	end
	local remaining = expires - os.time()
	if remaining <= 0 then
		return "Expired"
	end
	local date = os.date("%d %b %Y", expires)
	local days = math.floor(remaining / 86400)
	if days >= 1 then
		return ("%s · %d day%s"):format(date, days, days == 1 and "" or "s")
	end
	local hours = math.max(1, math.floor(remaining / 3600))
	return ("%s · %d hour%s"):format(date, hours, hours == 1 and "" or "s")
end

function SuccessView.new(parent, options)
	options = options or {}
	local self = setmetatable({ _rows = {} }, SuccessView)

	local page = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = options.LayoutOrder or 0,
		Parent = parent,
	}, {
		Utility.Padding(26, 20, 24, 24),
		Utility.List(16, nil, Enum.HorizontalAlignment.Center),
	})
	self.Instance = page

	-- Check mark
	local badge = Create("Frame", {
		Size = UDim2.fromOffset(62, 62),
		BackgroundColor3 = SUCCESS,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = page,
	}, { Corner(999) })
	Create("UIStroke", { Color = SUCCESS, Transparency = 0.6, Parent = badge })
	self._badgeScale = Create("UIScale", { Parent = badge })
	Widgets.Icon(badge, "check", 28, SUCCESS, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})

	-- Heading
	local heading = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = page,
	}, { Utility.List(4, nil, Enum.HorizontalAlignment.Center) })
	Builders.Label({
		Text = options.Title or "License activated",
		Font = Fonts.Bold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = heading,
	})
	self._welcome = Builders.Label({
		Text = "",
		TextSize = 13,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 2,
		Parent = heading,
	})

	-- Details card
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Parent = page,
	}, { Corner(12), Utility.List(0) })
	Theme.Bind(card, { BackgroundColor3 = "Field" })
	Builders.Stroke(0.93).Parent = card
	self._card = card

	-- Launch progress
	local launch = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = page,
	}, { Utility.List(8) })
	local launchHeader = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Parent = launch,
	})
	self._launchLabel = Builders.Label({
		Text = "Loading...",
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.7, 1),
		Parent = launchHeader,
	})
	self._launchPct = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 12,
		ThemeColor = "SubText",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.3, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = launchHeader,
	})
	local track = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundTransparency = 0.93,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = launch,
	}, { Corner(999) })
	self._fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		Corner(999),
		Create("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(170, 170, 170), Color3.new(1, 1, 1)),
		}),
	})
	Theme.Bind(self._fill, { BackgroundColor3 = "Accent" })

	if options.OnReset then
		Widgets.Button(page, {
			Text = options.ResetText or "Use a different key",
			Style = "Link",
			LayoutOrder = 5,
			Callback = options.OnReset,
		})
	end

	return self
end

function SuccessView:_row(label, value, colorKey, mono)
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = #self._rows + 1,
		Parent = self._card,
	}, { Utility.Padding(0, 0, 14, 14) })
	if #self._rows > 0 then
		local line = Create("Frame", {
			Size = UDim2.new(1, 28, 0, 1),
			Position = UDim2.fromOffset(-14, 0),
			BackgroundTransparency = 0.95,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = row,
		})
		line.Name = "Divider"
	end
	Builders.Label({
		Text = label,
		TextSize = 13,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.4, 1),
		Parent = row,
	})
	Builders.Label({
		Text = tostring(value),
		ThemeColor = colorKey or "Text",
		Font = mono and Fonts.Mono or Fonts.Bold,
		TextSize = 13,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.6, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	table.insert(self._rows, row)
end

--[[
	info = {
		Plan = "Premium", Expires = <unix> | "text" | true (lifetime),
		User = "name", Details = { { "Label", "Value" }, ... },
	}
]]
function SuccessView:Show(info, maskedKey)
	info = type(info) == "table" and info or {}
	for _, row in ipairs(self._rows) do
		row:Destroy()
	end
	table.clear(self._rows)

	local player = Services.LocalPlayer
	local name = info.User or (player and player.DisplayName) or "there"
	self._welcome.Text = "Welcome back, " .. name

	self:_row("Plan", info.Plan or "Licensed", "Accent")
	local expiry = SuccessView.FormatExpiry(info.Expires)
	if expiry then
		self:_row("Expires", expiry)
	end
	for _, pair in ipairs(info.Details or {}) do
		self:_row(tostring(pair[1]), tostring(pair[2]))
	end
	if maskedKey and maskedKey ~= "" then
		self:_row("Key", maskedKey, nil, true)
	end

	self.Instance.Visible = true
	self._fill.Size = UDim2.fromScale(0, 1)
	self._badgeScale.Scale = 0.6
	Tween(self._badgeScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
end

function SuccessView:Hide()
	self.Instance.Visible = false
end

-- Animates the bar, then calls onDone. Returns a cancel function.
function SuccessView:Launch(seconds, label, onDone)
	seconds = math.max(0.2, seconds or 1.6)
	local cancelled = false
	self._launchLabel.Text = label or "Loading..."
	self._launchPct.Text = ""
	self._fill.Size = UDim2.fromScale(0, 1)
	Tween(self._fill, { Size = UDim2.fromScale(1, 1) }, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	task.delay(seconds, function()
		if cancelled then
			return
		end
		self._launchLabel.Text = "Ready"
		self._launchPct.Text = "100%"
		task.wait(0.35)
		if not cancelled and onDone then
			onDone()
		end
	end)

	return function()
		cancelled = true
	end
end

return SuccessView
end

__modules["KeySystem/Widgets"] = function(...)
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
end

__modules["Themes/Dark"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(124, 92, 255),
	Background = rgb(14, 14, 20),
	Sidebar = rgb(22, 22, 31),
	Element = rgb(28, 28, 39),
	ElementHover = rgb(37, 37, 51),
	Field = rgb(18, 18, 26),
	Stroke = rgb(255, 255, 255),
	Text = rgb(240, 240, 246),
	SubText = rgb(150, 150, 168),
	Placeholder = rgb(128, 128, 146),
	ToggleOff = rgb(52, 52, 68),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.9,
}
end

__modules["Themes/Emerald"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(16, 185, 129),
	Background = rgb(10, 18, 16),
	Sidebar = rgb(16, 27, 24),
	Element = rgb(21, 34, 30),
	ElementHover = rgb(29, 45, 40),
	Field = rgb(13, 22, 19),
	Stroke = rgb(200, 255, 235),
	Text = rgb(236, 250, 245),
	SubText = rgb(140, 170, 160),
	Placeholder = rgb(116, 148, 137),
	ToggleOff = rgb(40, 60, 54),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.9,
}
end

__modules["Themes"] = function(...)
--[[
	Themes
	Registry of theme presets. Add a new theme by creating Themes/<Name>.lua
	with the same keys as Dark.lua and listing it here.
]]

local import = ...

return {
	Dark = import("Themes/Dark"),
	Midnight = import("Themes/Midnight"),
	Rose = import("Themes/Rose"),
	Emerald = import("Themes/Emerald"),
	Light = import("Themes/Light"),
}
end

__modules["Themes/Light"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(99, 102, 241),
	Background = rgb(246, 246, 250),
	Sidebar = rgb(234, 234, 242),
	Element = rgb(255, 255, 255),
	ElementHover = rgb(240, 240, 248),
	Field = rgb(240, 240, 246),
	Stroke = rgb(0, 0, 0),
	Text = rgb(22, 22, 30),
	SubText = rgb(100, 100, 118),
	Placeholder = rgb(104, 104, 120),
	ToggleOff = rgb(205, 205, 218),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.88,
}
end

__modules["Themes/Midnight"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(59, 130, 246),
	Background = rgb(10, 14, 26),
	Sidebar = rgb(16, 22, 38),
	Element = rgb(21, 28, 46),
	ElementHover = rgb(29, 38, 60),
	Field = rgb(13, 18, 32),
	Stroke = rgb(170, 200, 255),
	Text = rgb(236, 242, 255),
	SubText = rgb(140, 155, 185),
	Placeholder = rgb(118, 134, 166),
	ToggleOff = rgb(42, 52, 78),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.9,
}
end

__modules["Themes/Rose"] = function(...)
local rgb = Color3.fromRGB

return {
	Accent = rgb(244, 63, 94),
	Background = rgb(18, 12, 16),
	Sidebar = rgb(28, 19, 25),
	Element = rgb(34, 24, 31),
	ElementHover = rgb(45, 32, 41),
	Field = rgb(22, 15, 20),
	Stroke = rgb(255, 220, 230),
	Text = rgb(250, 238, 242),
	SubText = rgb(175, 145, 158),
	Placeholder = rgb(150, 122, 135),
	ToggleOff = rgb(62, 44, 55),
	Knob = rgb(255, 255, 255),
	StrokeAlpha = 0.9,
}
end

__modules["Window/Dialog"] = function(...)
--[[
	Window/Dialog
	Modal confirmation dialog shown over the window.

	Window:Dialog({
		Title   = "Close MyHub?",
		Content = "Optional body text",
		Buttons = {
			{ Title = "Cancel" },                                       -- Secondary (default)
			{ Title = "Close", Variant = "Danger", Callback = fn },     -- Primary | Danger | Secondary
		},
	}) -> { Close = function }
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local Z = 30
local WIDTH = 300

local Dialog = {}

local function createButton(parent, spec, order, onClick)
	local variant = spec.Variant or "Secondary"
	local button = Create("TextButton", {
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Constants.Fonts.Medium,
		TextSize = 13,
		Text = spec.Title or "OK",
		LayoutOrder = order,
		ZIndex = Z + 2,
		Parent = parent,
	}, { Utility.Corner(8), Utility.Padding(0, 0, 14, 14) })

	local baseTransparency
	if variant == "Primary" then
		Theme.Bind(button, { BackgroundColor3 = "Accent" })
		button.TextColor3 = Color3.new(1, 1, 1)
		baseTransparency = 0
	elseif variant == "Danger" then
		button.BackgroundColor3 = Constants.Danger
		button.TextColor3 = Color3.new(1, 1, 1)
		baseTransparency = 0
	else
		Theme.Bind(button, { BackgroundColor3 = "Element", TextColor3 = "Text" })
		Builders.Stroke().Parent = button
		baseTransparency = 0.2
	end
	button.BackgroundTransparency = baseTransparency

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = baseTransparency + 0.12 }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = baseTransparency }, 0.15)
	end)
	button.MouseButton1Click:Connect(function()
		onClick(spec)
	end)
end

function Dialog.new(parent, options)
	options = options or {}

	-- Full-size TextButton so clicks never reach the window underneath
	local overlay = Create("TextButton", {
		Name = "Dialog",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = Z,
		Parent = parent,
	}, { Utility.Corner(12) })

	-- TextButton (not Frame) so clicks on the card don't fall through to the backdrop
	local card = Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = Z + 1,
		Parent = overlay,
	}, { Utility.Corner(12), Utility.Padding(18, 16, 18, 18), Utility.List(8) })
	Theme.Bind(card, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.82).Parent = card
	local scale = Create("UIScale", { Scale = 0.92, Parent = card })

	Builders.Label({
		Text = options.Title or "Are you sure?",
		Font = Constants.Fonts.Bold,
		TextSize = 15,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		ZIndex = Z + 2,
		Parent = card,
	})

	if options.Content then
		Builders.Label({
			Text = options.Content,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			ZIndex = Z + 2,
			Parent = card,
		})
	end

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		ZIndex = Z + 1,
		Parent = card,
	}, {
		Utility.List(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom),
	})

	local dialog = {}
	local closed = false

	function dialog:Close()
		if closed then
			return
		end
		closed = true
		Tween(overlay, { BackgroundTransparency = 1 }, 0.18)
		Tween(scale, { Scale = 0.92 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.18, function()
			overlay:Destroy()
		end)
		Utility.SafeCall(options.OnClose)
	end

	local buttons = options.Buttons or { { Title = "OK", Variant = "Primary" } }
	for index, spec in ipairs(buttons) do
		createButton(row, spec, index, function(clicked)
			dialog:Close()
			Utility.SafeCall(clicked.Callback)
		end)
	end

	-- Clicking the dimmed backdrop dismisses the dialog
	overlay.MouseButton1Click:Connect(function()
		if options.Dismissible ~= false then
			dialog:Close()
		end
	end)

	Tween(overlay, { BackgroundTransparency = 0.45 }, 0.2)
	Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)

	dialog.Instance = overlay
	return dialog
end

return Dialog
end

__modules["Window"] = function(...)
--[[
	Window
	Main hub window: shadow, glass body, topbar, sidebar, content area,
	drag, resize, minimize, show/hide, keybind and floating toggle button.

	Window.new(config) -> window
	config:
		Title, Author, Icon, IconColor
		Logo (square logo: id / rbxassetid / URL / file) -- topbar, floating button, minimized pill
		BrandLogo, BrandLogoSize                         -- wordmark shown next to the logo when minimized
		Size (UDim2), MinSize (Vector2), SidebarWidth
		Theme, Accent
		ToggleKey (Enum.KeyCode | nil), ToggleButton (bool), ToggleIcon, ToggleButtonPosition
		Search (bool), Profile (bool), ConfirmClose (bool) -- all default true
		OnClose (function)
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Gui = import("Core/Gui")
local Draggable = import("Core/Draggable")
local Notify = import("Components/Notification")
local Tab = import("Window/Tab")
local Topbar = import("Window/Topbar")
local ToggleButton = import("Window/ToggleButton")
local SearchBar = import("Window/SearchBar")
local Profile = import("Window/Profile")
local Dialog = import("Window/Dialog")
local MiniBar = import("Window/MiniBar")

local Create, Tween, Track = Utility.Create, Utility.Tween, Utility.Track
local UserInputService = Services.UserInputService
local Defaults = Constants.Window
local TOPBAR = Defaults.TopbarHeight

local Window = {}

function Window.new(config)
	config = config or {}
	Theme.Ensure(config.Theme or "Dark", config.Accent)

	local screenGui = Gui.Get()
	local sidebarWidth = config.SidebarWidth or Defaults.SidebarWidth
	local minSize = config.MinSize or Defaults.MinSize
	local size = config.Size or Defaults.DefaultSize

	local window = {
		Tabs = {},
		ActiveTab = nil,
		Minimized = false,
		Visible = true,
		Gui = screenGui,
		_query = "",
		_dialog = nil,
		ToggleKey = config.ToggleKey == nil and Defaults.ToggleKey or config.ToggleKey,
	}

	---------------------------------------------------------------- frame
	local root = Create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X.Offset, size.Y.Offset),
		BackgroundTransparency = 1,
		Parent = screenGui,
	})
	local rootScale = Create("UIScale", { Parent = root })

	Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = UDim2.new(1, 60, 1, 60),
		BackgroundTransparency = 1,
		Image = Constants.Shadow.Image,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Constants.Shadow.SliceCenter,
		ZIndex = 0,
		Parent = root,
	})

	local main = Create("Frame", {
		Name = "Main",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = Constants.Glass.Main,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = root,
	}, {
		Utility.Corner(12),
		Create("UIGradient", { -- glass sheen
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 225)),
		}),
	})
	Theme.Bind(main, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.86).Parent = main

	local topbar = Topbar.new(main, config)

	---------------------------------------------------------------- body
	local body = Create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, TOPBAR + 1),
		Size = UDim2.new(1, 0, 1, -(TOPBAR + 1)),
		BackgroundTransparency = 1,
		Parent = main,
	})

	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(0, sidebarWidth, 1, -16),
		BackgroundTransparency = Constants.Glass.Sidebar,
		BorderSizePixel = 0,
		Parent = body,
	}, { Utility.Corner(10) })
	Theme.Bind(sidebar, { BackgroundColor3 = "Sidebar" })
	Builders.Stroke(0.94).Parent = sidebar

	local searchHeight = config.Search == false and 0 or Defaults.SearchHeight
	local profileHeight = config.Profile == false and 0 or Defaults.ProfileHeight
	local listTop = searchHeight > 0 and (searchHeight + 8) or 0

	if searchHeight > 0 then
		SearchBar.new(sidebar, searchHeight, function(text)
			window._query = text
			if window.ActiveTab then
				window.ActiveTab:Filter(text)
			end
		end)
	end

	if profileHeight > 0 then
		Profile.new(sidebar, profileHeight)
	end

	local tabList = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, listTop),
		Size = UDim2.new(1, 0, 1, -(listTop + profileHeight)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	}, { Utility.List(3), Utility.Padding(6, 6, 6, 6) })

	local content = Create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(sidebarWidth + 16, 0),
		Size = UDim2.new(1, -(sidebarWidth + 16), 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = body,
	})

	---------------------------------------------------------------- resize handle
	local resizeHandle = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 10,
		Parent = main,
	})
	for _, offset in ipairs({ { 11, 5 }, { 11, 11 }, { 5, 11 } }) do
		local dot = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(offset[1], offset[2]),
			Size = UDim2.fromOffset(3, 3),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 11,
			Parent = resizeHandle,
		}, { Utility.Corner(2) })
		Theme.Bind(dot, { BackgroundColor3 = "SubText" })
	end

	---------------------------------------------------------------- responsive scale
	local baseScale = 1

	local function computeScale()
		local viewport = Utility.GetViewport()
		local fitWidth = (viewport.X - 24) / root.Size.X.Offset
		local fitHeight = (viewport.Y - 24) / math.max(root.Size.Y.Offset, TOPBAR)
		baseScale = math.clamp(math.min(1, fitWidth, fitHeight), 0.5, 1)
		return baseScale
	end

	local camera = workspace.CurrentCamera
	if camera then
		Track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if window.Visible then
				Tween(rootScale, { Scale = computeScale() }, 0.2)
			end
		end))
	end

	---------------------------------------------------------------- drag
	Draggable(topbar.Frame, root)

	---------------------------------------------------------------- resize
	local resizing, resizeStart, startSize, startPosition = false, nil, nil, nil

	Track(resizeHandle.InputBegan:Connect(function(input)
		if Utility.IsClick(input) and not window.Minimized then
			resizing = true
			resizeStart = input.Position
			startSize = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
			startPosition = root.Position
		end
	end))

	Track(UserInputService.InputChanged:Connect(function(input)
		if not (resizing and Utility.IsMove(input)) then
			return
		end
		local scale = rootScale.Scale
		local viewport = Utility.GetViewport()
		local delta = (input.Position - resizeStart) / scale

		local width = math.clamp(startSize.X + delta.X, minSize.X, math.max(minSize.X, viewport.X / scale - 20))
		local height = math.clamp(startSize.Y + delta.Y, minSize.Y, math.max(minSize.Y, viewport.Y / scale - 20))
		root.Size = UDim2.fromOffset(width, height)

		-- anchor is centered: shift so the top-left corner stays pinned
		local dx = (width - startSize.X) * scale / 2
		local dy = (height - startSize.Y) * scale / 2
		root.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + dx,
			startPosition.Y.Scale,
			startPosition.Y.Offset + dy
		)
	end))

	Track(UserInputService.InputEnded:Connect(function(input)
		if resizing and Utility.IsClick(input) then
			resizing = false
		end
	end))

	---------------------------------------------------------------- minimize
	-- Minimizing collapses the window into a small pill: [logo] brand.
	-- The pill appears where the window's top-left corner was; restoring
	-- moves the window to wherever the pill was dragged.
	local miniBar

	function window:Minimize(state)
		if state == nil then
			state = not window.Minimized
		end
		if state == window.Minimized then
			return
		end
		window.Minimized = state

		if state then
			local corner = root.AbsolutePosition
			Tween(rootScale, { Scale = baseScale * 0.9 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.15, function()
				if window.Minimized then
					root.Visible = false
				end
			end)
			miniBar:Show(corner)
		else
			local corner = miniBar.Instance.AbsolutePosition
			local half = root.AbsoluteSize / 2
			miniBar:Hide()
			root.Position = UDim2.fromOffset(corner.X + half.X, corner.Y + half.Y)
			if window.Visible then
				root.Visible = true
				rootScale.Scale = baseScale * 0.9
				Tween(rootScale, { Scale = baseScale }, 0.3, Enum.EasingStyle.Back)
			end
		end
	end

	miniBar = MiniBar.new(screenGui, config, function()
		window:Minimize(false)
	end)

	---------------------------------------------------------------- visibility
	local animating = false

	function window:SetVisible(state)
		if state == window.Visible or animating then
			return
		end
		window.Visible = state

		-- While minimized, show/hide the pill instead of the window
		if window.Minimized then
			if state then
				miniBar:Show()
			else
				miniBar:Hide()
			end
			if window.ToggleButton then
				Tween(window.ToggleButton.Stroke, { Transparency = state and 0.2 or 0.6 }, 0.2)
			end
			return
		end

		animating = true

		if state then
			root.Visible = true
			rootScale.Scale = computeScale() * 0.9
			Tween(rootScale, { Scale = baseScale }, 0.35, Enum.EasingStyle.Back)
			task.delay(0.35, function()
				animating = false
			end)
		else
			Tween(rootScale, { Scale = baseScale * 0.9 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.18, function()
				if not window.Visible then
					root.Visible = false
				end
				animating = false
			end)
		end

		if window.ToggleButton then
			Tween(window.ToggleButton.Stroke, { Transparency = state and 0.2 or 0.6 }, 0.2)
		end
	end

	function window:Toggle()
		window:SetVisible(not window.Visible)
	end

	---------------------------------------------------------------- lifecycle
	local destroyed = false

	function window:Destroy()
		if destroyed then
			return
		end
		destroyed = true

		Tween(rootScale, { Scale = baseScale * 0.85 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.2)

		Utility.DisconnectAll()
		Theme.Reset()
		Gui.Destroy()
		table.clear(State.Windows)
		Utility.SafeCall(config.OnClose)
	end

	---------------------------------------------------------------- misc API
	function window:SetTitle(text)
		topbar.TitleLabel.Text = text
	end

	function window:SetAuthor(text)
		if topbar.AuthorLabel then
			topbar.AuthorLabel.Text = text
		end
	end

	function window:SetTheme(name, accent)
		Theme.Set(name, accent)
	end

	-- Status line shown in the minimized pill, e.g. "Clearing · 45%"; nil resets it
	function window:SetStatus(text, color)
		miniBar:SetStatus(text, color)
	end

	function window:SetToggleKey(keyCode)
		window.ToggleKey = keyCode
	end

	function window:Notify(options)
		return Notify(options)
	end

	function window:Dialog(options)
		if window._dialog then
			window._dialog:Close()
		end
		options = options or {}
		local userOnClose = options.OnClose
		options.OnClose = function()
			window._dialog = nil
			Utility.SafeCall(userOnClose)
		end
		window._dialog = Dialog.new(main, options)
		return window._dialog
	end

	---------------------------------------------------------------- tabs
	function window:SelectTab(target)
		local tab = type(target) == "number" and window.Tabs[target] or target
		if not tab or tab == window.ActiveTab then
			return
		end

		local previous = window.ActiveTab
		window.ActiveTab = tab

		if previous then
			previous.Page.Visible = false
			previous:_SetActive(false)
		end

		tab:_SetActive(true)
		tab:Filter(window._query)
		tab.Page.Visible = true
		tab.Page.Position = UDim2.fromOffset(0, 14)
		Tween(tab.Page, { Position = UDim2.fromOffset(0, 0) }, 0.35)
	end

	function window:Tab(options)
		local tab = Tab.new(window, options, { List = tabList, Content = content })
		table.insert(window.Tabs, tab)
		if #window.Tabs == 1 then
			window:SelectTab(tab)
		end
		return tab
	end
	window.AddTab = window.Tab
	window.CreateTab = window.Tab

	---------------------------------------------------------------- inputs
	topbar.MinimizeButton.MouseButton1Click:Connect(function()
		window:Minimize()
	end)

	topbar.CloseButton.MouseButton1Click:Connect(function()
		if config.ConfirmClose == false then
			task.spawn(function()
				window:Destroy()
			end)
			return
		end
		if window._dialog then
			return
		end
		window:Dialog({
			Title = "Close " .. (config.Title or "this window") .. "?",
			Content = "The interface will be removed. Run the script again to bring it back.",
			Buttons = {
				{ Title = "Cancel" },
				{
					Title = "Close",
					Variant = "Danger",
					Callback = function()
						window:Destroy()
					end,
				},
			},
		})
	end)

	Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:Toggle()
		end
	end))

	if config.ToggleButton ~= false then
		window.ToggleButton = ToggleButton.new(screenGui, config, function()
			window:Toggle()
		end)
	end

	---------------------------------------------------------------- open animation
	computeScale()
	rootScale.Scale = baseScale * 0.9
	Tween(rootScale, { Scale = baseScale }, 0.45, Enum.EasingStyle.Back)

	table.insert(State.Windows, window)
	return window
end

return Window
end

__modules["Window/MiniBar"] = function(...)
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
	config.BrandLogoSize UDim2, default 110x22

	api:SetStatus(text, color?) shows a live line under the brand (Window:SetStatus).
]]

local import = ...
local State = import("Core/State")
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

	-- Brand + status line --------------------------------------------------
	-- [logo]  Brand (image or title)
	--         status line (Author by default, or live text from :SetStatus)
	local textGroup = Create("Frame", {
		Size = UDim2.fromOffset(0, LOGO),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		ZIndex = 41,
		Parent = bar,
	}, { Utility.List(2, nil, nil, Enum.VerticalAlignment.Center) })

	if config.BrandLogo then
		local brand = Create("ImageLabel", {
			Size = config.BrandLogoSize or UDim2.fromOffset(110, 22),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 1,
			ZIndex = 41,
			Parent = textGroup,
		})
		Assets.Apply(brand, config.BrandLogo)
	else
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
	end

	local defaultStatus = config.Author or config.SubTitle
	local statusLabel = Create("TextLabel", {
		Text = defaultStatus or "",
		Font = Constants.Fonts.Medium,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 13),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = defaultStatus ~= nil,
		LayoutOrder = 2,
		ZIndex = 41,
		Parent = textGroup,
	})
	local statusColor = nil -- nil = theme SubText
	local function paintStatus()
		statusLabel.TextColor3 = statusColor or State.Theme.SubText
	end
	paintStatus()
	Theme.OnChange(paintStatus)

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

	-- Live status under the brand, e.g. "Clearing · 45%". nil restores the default.
	function api:SetStatus(text, color)
		if text == nil or text == "" then
			statusLabel.Text = defaultStatus or ""
			statusLabel.Visible = defaultStatus ~= nil
			statusColor = nil
		else
			statusLabel.Text = text
			statusLabel.Visible = true
			statusColor = color
		end
		paintStatus()
	end

	function api:IsVisible()
		return bar.Visible
	end

	return api
end

return MiniBar
end

__modules["Window/Profile"] = function(...)
--[[
	Window/Profile
	Sidebar footer with the local player's avatar, display name and username.

	Profile.new(parent, height) -> Frame
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create = Utility.Create
local Players = Services.Players

local Profile = {}

function Profile.new(parent, height)
	local player = Services.LocalPlayer

	local frame = Create("Frame", {
		Name = "Profile",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local divider = Create("Frame", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 0, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = frame,
	})
	Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

	local avatar = Create("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 1),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 0.2,
		Image = "",
		Parent = frame,
	}, { Utility.Corner(999) })
	Theme.Bind(avatar, { BackgroundColor3 = "Element" })
	Builders.Stroke(0.8).Parent = avatar

	local names = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 48, 0.5, 1),
		Size = UDim2.new(1, -56, 0, 30),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { Utility.List(1, nil, nil, Enum.VerticalAlignment.Center) })

	Builders.Label({
		Text = player and player.DisplayName or "Player",
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 14),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = names,
	})

	Builders.Label({
		Text = player and ("@" .. player.Name) or "",
		Font = Constants.Fonts.Regular,
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 13),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		Parent = names,
	})

	if player then
		task.spawn(function()
			local ok, image = pcall(function()
				return Players:GetUserThumbnailAsync(
					player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				)
			end)
			if ok and avatar.Parent then
				avatar.Image = image
			end
		end)
	end

	return frame
end

return Profile
end

__modules["Window/SearchBar"] = function(...)
--[[
	Window/SearchBar
	Sidebar search field that filters elements in the active tab.

	SearchBar.new(parent, height, onChanged) -> { Frame, TextBox }
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local SearchBar = {}

-- Magnifier drawn from a ring + handle (no image asset)
local function magnifier(parent)
	local holder = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 9, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local ring = Create("Frame", {
		Size = UDim2.fromOffset(9, 9),
		BackgroundTransparency = 1,
		Parent = holder,
	}, { Utility.Corner(999) })
	local ringStroke = Create("UIStroke", { Thickness = 1.5, Parent = ring })
	Theme.Bind(ringStroke, { Color = "SubText" })

	local handle = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(5, 2),
		Rotation = 45,
		BorderSizePixel = 0,
		Parent = holder,
	}, { Utility.Corner(1) })
	Theme.Bind(handle, { BackgroundColor3 = "SubText" })
end

function SearchBar.new(parent, height, onChanged)
	local frame = Create("Frame", {
		Name = "Search",
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, height),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		Parent = parent,
	}, { Utility.Corner(7) })
	Theme.Bind(frame, { BackgroundColor3 = "Field" })
	local stroke = Builders.Stroke()
	stroke.Parent = frame

	magnifier(frame)

	local box = Create("TextBox", {
		Position = UDim2.fromOffset(27, 0),
		Size = UDim2.new(1, -33, 1, 0),
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		PlaceholderText = "Search...",
		Text = "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	Theme.Bind(box, { TextColor3 = "Text", PlaceholderColor3 = "Placeholder" })

	box.Focused:Connect(function()
		Tween(stroke, { Color = State.Theme.Accent, Transparency = 0.3 }, 0.18)
	end)
	box.FocusLost:Connect(function()
		Tween(stroke, { Color = State.Theme.Stroke, Transparency = State.Theme.StrokeAlpha }, 0.18)
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		onChanged(box.Text)
	end)

	return { Frame = frame, TextBox = box }
end

return SearchBar
end

__modules["Window/Tab"] = function(...)
--[[
	Window/Tab
	A sidebar entry + its scrollable page. Component methods
	(Button, Toggle, Slider, ...) are attached from Components/.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")
local Services = import("Core/Services")

local Create, Tween = Utility.Create, Utility.Tween
local TweenService = Services.TweenService

local Layout = import("Components/GroupBox") -- exports { GroupBox, Columns }

-- Every entry becomes a method: Tab:<Name>(options)
local Components = {
	-- Inputs
	Button = import("Components/Button"),
	ButtonGroup = import("Components/ButtonGroup"),
	Toggle = import("Components/Toggle"),
	Checkbox = import("Components/Checkbox"),
	Slider = import("Components/Slider"),
	RangeSlider = import("Components/RangeSlider"),
	Stepper = import("Components/Stepper"),
	Input = import("Components/Input"),
	TextArea = import("Components/TextArea"),
	Dropdown = import("Components/Dropdown"),
	PlayerDropdown = import("Components/PlayerDropdown"),
	Segmented = import("Components/Segmented"),
	ColorPicker = import("Components/ColorPicker"),
	Keybind = import("Components/Keybind"),
	Grid = import("Components/Grid"),
	TaskCard = import("Components/TaskCard"),
	Swatches = import("Components/Swatches"),
	List = import("Components/List"),

	-- Display
	Paragraph = import("Components/Paragraph"),
	Image = import("Components/Image"),
	CodeBlock = import("Components/CodeBlock"),
	ProgressBar = import("Components/ProgressBar"),
	StatTiles = import("Components/StatTiles"),
	KeyValue = import("Components/KeyValue"),
	WorldMap = import("Components/WorldMap"),
	Spinner = import("Components/Spinner"),

	-- Layout
	Section = import("Components/Section"),
	Divider = import("Components/Divider"),
	Collapsible = import("Components/Collapsible"),
	SubTabs = import("Components/SubTabs"),
	GroupBox = Layout.GroupBox,
	Columns = Layout.Columns,
}

local Tab = {}
Tab.__index = Tab

-- Tab.new(window, { Title, Icon, Desc }, { List = sidebarList, Content = contentFrame })
function Tab.new(window, options, containers)
	options = options or {}
	local index = #window.Tabs + 1
	local hasIcon = options.Icon ~= nil

	local button = Create("TextButton", {
		Name = options.Title or ("Tab" .. index),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		Parent = containers.List,
	}, { Utility.Corner(8) })
	Theme.Bind(button, { BackgroundColor3 = "Accent" })

	local indicator = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BorderSizePixel = 0,
		Parent = button,
	}, { Utility.Corner(2) })
	Theme.Bind(indicator, { BackgroundColor3 = "Accent" })

	local icon
	if hasIcon then
		icon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(17, 17),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = button,
		})
		Assets.Apply(icon, options.Icon)
	end

	local textX = hasIcon and 37 or 14
	local label = Builders.Label({
		Text = options.Title or ("Tab " .. index),
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1, -(textX + 22), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeColor = "SubText",
		Parent = button,
	})

	-- Pulsing dot shown while something in this tab is running (Tab:SetLive)
	local liveDot = Create("Frame", {
		Name = "LiveDot",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Constants.NotifyColors.Success,
		BorderSizePixel = 0,
		Visible = false,
		Parent = button,
	}, { Utility.Corner(999) })

	local page = Create("ScrollingFrame", {
		Name = (options.Title or "Tab") .. "_Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = containers.Content,
	}, { Utility.List(6), Utility.Padding(8, 12, 0, 10) })
	Theme.Bind(page, { ScrollBarImageColor3 = "Accent" })

	-- Page header: tab title + optional description -----------------------
	local header = Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = page,
	}, { Utility.List(2), Utility.Padding(2, 6, 4, 4) })

	Builders.Label({
		Text = options.Title or ("Tab " .. index),
		Font = Constants.Fonts.Bold,
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 1,
		Parent = header,
	})

	if options.Desc then
		Builders.Label({
			Text = options.Desc,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = header,
		})
	end

	-- Shown when a search has no matches in this tab
	local emptyLabel = Builders.Label({
		Text = "No matching elements",
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 60),
		LayoutOrder = 1e6,
		Visible = false,
		Parent = page,
	})

	local self = setmetatable({
		Title = options.Title,
		Window = window,
		Page = page,
		TabButton = button, -- sidebar TextButton (NOT "Button": that would shadow Tab:Button())
		Active = false,
		_order = 0,
		_indicator = indicator,
		_label = label,
		_icon = icon,
		_iconTint = options.IconTint ~= false, -- false keeps full-color images (e.g. URL logos)
		_searchables = {},
		_sections = {},
		_empty = emptyLabel,
		_liveDot = liveDot,
		_livePulse = nil,
	}, Tab)

	button.MouseEnter:Connect(function()
		if not self.Active then
			Tween(button, { BackgroundTransparency = 0.94 }, 0.15)
		end
	end)
	button.MouseLeave:Connect(function()
		if not self.Active then
			Tween(button, { BackgroundTransparency = 1 }, 0.15)
		end
	end)
	button.MouseButton1Click:Connect(function()
		window:SelectTab(self)
	end)

	self:_SetActive(false)
	Theme.OnChange(function()
		self:_SetActive(self.Active)
	end)

	return self
end

function Tab:_NextOrder()
	self._order += 1
	return self._order
end

function Tab:_SetActive(active)
	self.Active = active
	local theme = State.Theme

	Tween(self.TabButton, { BackgroundTransparency = active and 0.86 or 1 }, 0.25)
	Tween(self._indicator, { Size = UDim2.fromOffset(3, active and 16 or 0) }, 0.3, Enum.EasingStyle.Back)
	Tween(self._label, { TextColor3 = active and theme.Text or theme.SubText }, 0.25)
	if self._icon and self._iconTint then
		Tween(self._icon, { ImageColor3 = active and theme.Accent or theme.SubText }, 0.25)
	elseif self._icon then
		Tween(self._icon, { ImageTransparency = active and 0 or 0.35 }, 0.25)
	end
end

function Tab:Select()
	self.Window:SelectTab(self)
end

--[[
	Creates a tab-like container around `frame` so layout components
	(Collapsible, GroupBox, Columns, SubTabs) can hold any component:

		local child = tab:_Child(frame)
		child:Button({ ... })   -- parented to `frame`

	The child shares the parent tab's search index, so elements inside
	containers are still found by the sidebar search. `frame` must have
	its own UIListLayout (children are ordered by LayoutOrder).
]]
function Tab:_Child(frame)
	return setmetatable({
		Title = self.Title,
		Window = self.Window,
		Page = frame,
		TabButton = self.TabButton,
		Parent = self,
		_order = 0,
		_searchables = self._searchables,
		_sections = self._sections,
		_empty = self._empty,
	}, Tab)
end

-- Shows a pulsing green dot next to the tab name (e.g. while a task runs)
function Tab:SetLive(state)
	local root = self
	while root.Parent do -- containers forward to the real sidebar tab
		root = root.Parent
	end
	local dot = root._liveDot
	if not dot then
		return
	end
	if root._livePulse then
		root._livePulse:Cancel()
		root._livePulse = nil
	end
	dot.Visible = state and true or false
	dot.BackgroundTransparency = 0
	if state then
		root._livePulse = TweenService:Create(
			dot,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundTransparency = 0.65 }
		)
		root._livePulse:Play()
	end
end

-- Shows only elements whose title contains `query` (case-insensitive)
function Tab:Filter(query)
	query = string.lower(query or "")
	local searching = query ~= ""
	local matches = 0

	for _, item in ipairs(self._searchables) do
		if item.Instance.Parent then
			local text = string.lower(item.Label.ContentText ~= "" and item.Label.ContentText or item.Label.Text)
			local visible = not searching or string.find(text, query, 1, true) ~= nil
			item.Instance.Visible = visible
			if visible then
				matches += 1
			end
		end
	end

	for _, heading in ipairs(self._sections) do
		if heading.Parent then
			heading.Visible = not searching
		end
	end

	self._empty.Visible = searching and matches == 0
end

-- Attach component constructors as methods: Tab:Button(options), ...
for name, build in pairs(Components) do
	Tab[name] = function(self, options)
		return build(self, options)
	end
end

-- Aliases
Tab.Textbox = Tab.Input
Tab.TextBox = Tab.Input
Tab.Label = Tab.Paragraph
Tab.Radio = Tab.Segmented
Tab.Colorpicker = Tab.ColorPicker
Tab.Textarea = Tab.TextArea
Tab.Accordion = Tab.Collapsible

return Tab
end

__modules["Window/ToggleButton"] = function(...)
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
end

__modules["Window/Topbar"] = function(...)
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
end

return import("init")
