--[[
	Components/Swatches
	Row of round color swatches; pick one. Great for an accent-color setting.

	Tab:Swatches({
		Title  = "Accent color",
		Colors = {
			{ "Violet", Color3.fromRGB(124, 92, 255) },
			{ "Blue", Color3.fromRGB(59, 130, 246) },
			{ "Rose", Color3.fromRGB(244, 63, 94) },
		},
		Value    = "Violet",
		Flag     = "Accent",
		Callback = function(color, name) UI:SetAccent(color) end,
	})
	:Set(name, silent) / :Get() -> name, color
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween

local SIZE = 28

local DEFAULT_COLORS = {
	{ "Violet", Color3.fromRGB(124, 92, 255) },
	{ "Blue", Color3.fromRGB(59, 130, 246) },
	{ "Rose", Color3.fromRGB(244, 63, 94) },
	{ "Emerald", Color3.fromRGB(16, 185, 129) },
	{ "Amber", Color3.fromRGB(245, 158, 11) },
}

return function(tab, options)
	options = options or {}
	local colors = options.Colors or DEFAULT_COLORS

	local element = Element.new(tab, options, { Hover = false })

	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, SIZE + 6),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = element.TextHolder,
	}, { Utility.List(10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center), Utility.Padding(4, 0, 2, 0) })

	element.Value = options.Value or options.Default or colors[1][1]
	local rings = {} -- [name] = UIStroke

	local function colorOf(name)
		for _, pair in ipairs(colors) do
			if pair[1] == name then
				return pair[2]
			end
		end
		return nil
	end

	local function render()
		for name, ring in pairs(rings) do
			local selected = name == element.Value
			Tween(ring, { Transparency = selected and 0 or 1 }, 0.15)
			ring.Color = State.Theme.Text
		end
	end

	for index, pair in ipairs(colors) do
		local name, color = pair[1], pair[2]
		local swatch = Create("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(SIZE, SIZE),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
			Parent = row,
		}, { Utility.Corner(999) })
		local ring = Create("UIStroke", {
			Thickness = 2.5,
			Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = swatch,
		})
		local scale = Create("UIScale", { Parent = swatch })
		rings[name] = ring

		swatch.MouseEnter:Connect(function()
			Tween(scale, { Scale = 1.1 }, 0.15, Enum.EasingStyle.Back)
		end)
		swatch.MouseLeave:Connect(function()
			Tween(scale, { Scale = 1 }, 0.15)
		end)
		swatch.MouseButton1Click:Connect(function()
			element:Set(name)
		end)
	end

	function element:Set(name, silent)
		if not colorOf(name) then
			return
		end
		element.Value = name
		render()
		if not silent then
			Utility.SafeCall(options.Callback, colorOf(name), name)
		end
	end

	function element:Get()
		return element.Value, colorOf(element.Value)
	end

	render()
	Theme.OnChange(render)
	Element.RegisterFlag(options, element)
	return element
end
