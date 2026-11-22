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
