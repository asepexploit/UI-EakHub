--[[
	Core/Badge
	Small status pill shown next to an element title.

	Badge.new(parent, "NEW")                         -- preset color
	Badge.new(parent, { Text = "x2", Color = c3 })   -- custom color
	badge:Set("ON") / badge:Set(nil) -- nil hides

	Presets: NEW / BETA (accent), ON (green), OFF (grey), PREMIUM / VIP (gold), HOT (red)
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween
local rgb = Color3.fromRGB

local PRESETS = {
	NEW = "Accent",
	BETA = "Accent",
	ON = rgb(34, 197, 94),
	OFF = "SubText",
	PREMIUM = rgb(234, 179, 8),
	VIP = rgb(234, 179, 8),
	HOT = rgb(239, 68, 68),
}

local Badge = {}

local function resolve(value)
	if value == nil then
		return nil, nil
	end
	if type(value) == "table" then
		return tostring(value.Text or ""), value.Color
	end
	local text = tostring(value)
	local preset = PRESETS[string.upper(text)]
	if type(preset) == "string" then
		return text, State.Theme[preset]
	end
	return text, preset or State.Theme.Accent
end

function Badge.new(parent, value)
	local pill = Create("Frame", {
		Name = "Badge",
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		Parent = parent,
	}, { Utility.Corner(999), Utility.Padding(0, 0, 6, 6) })

	local label = Create("TextLabel", {
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Bold,
		TextSize = 10,
		Parent = pill,
	})

	local badge = { Instance = pill, Value = value }

	function badge:Set(newValue)
		badge.Value = newValue
		local text, color = resolve(newValue)
		pill.Visible = text ~= nil and text ~= ""
		if not pill.Visible then
			return
		end
		label.Text = string.upper(text)
		Tween(pill, { BackgroundColor3 = color }, 0.15)
		Tween(label, { TextColor3 = color }, 0.15)
	end

	badge:Set(value)
	Theme.OnChange(function()
		badge:Set(badge.Value)
	end)
	return badge
end

return Badge
