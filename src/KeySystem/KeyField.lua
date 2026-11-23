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
