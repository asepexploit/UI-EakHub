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
