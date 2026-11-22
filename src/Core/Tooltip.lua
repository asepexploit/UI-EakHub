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
