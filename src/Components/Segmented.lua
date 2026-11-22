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
