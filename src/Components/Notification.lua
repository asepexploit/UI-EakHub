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
