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

function Builders.Ripple(button, screenPosition)
	local relative = Vector2.new(screenPosition.X, screenPosition.Y) - button.AbsolutePosition
	local circle = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(relative.X, relative.Y),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 5,
		Parent = button,
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
