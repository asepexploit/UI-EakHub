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
