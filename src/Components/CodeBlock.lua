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
