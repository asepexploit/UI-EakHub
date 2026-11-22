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
