--[[
	Components/ButtonGroup
	One row of 2-4 equal-width buttons.

	local group = Tab:ButtonGroup({
		Buttons = {
			{ Title = "Save", Variant = "Primary", Callback = function() end },
			{ Title = "Load", Callback = function() end },          -- Secondary (default)
			{ Title = "Reset", Variant = "Danger", Callback = function() end },
		},
	})
	group:SetButtonText(1, "Saved!")
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local HEIGHT = 34
local GAP = 6

local function createButton(parent, spec, count, index)
	local variant = spec.Variant or "Secondary"
	local button = Create("TextButton", {
		Name = spec.Title or ("Button" .. index),
		Size = UDim2.new(1 / count, -(GAP * (count - 1)) / count, 1, 0),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Font = Constants.Fonts.Medium,
		TextSize = 13,
		Text = spec.Title or "Button",
		LayoutOrder = index,
		Parent = parent,
	}, { Utility.Corner(8) })

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
		baseTransparency = Constants.Glass.Element
	end
	button.BackgroundTransparency = baseTransparency

	local scale = Create("UIScale", { Parent = button })

	button.MouseEnter:Connect(function()
		Tween(button, { BackgroundTransparency = math.min(baseTransparency + 0.12, 1) }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, { BackgroundTransparency = baseTransparency }, 0.15)
	end)
	Utility.Track(button.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			Builders.Ripple(button, input.Position)
		end
	end))
	button.MouseButton1Click:Connect(function()
		Builders.Press(scale)
		Utility.SafeCall(spec.Callback)
	end)

	return button
end

return function(tab, options)
	options = options or {}
	local specs = options.Buttons or {}
	local count = math.clamp(#specs, 1, 4)

	local holder = Create("Frame", {
		Name = "ButtonGroup",
		Size = UDim2.new(1, 0, 0, HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.List(GAP, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
	})

	local buttons = {}
	for index = 1, count do
		buttons[index] = createButton(holder, specs[index], count, index)
	end

	-- Searchable by the first button's label
	if tab._searchables and buttons[1] then
		table.insert(tab._searchables, { Instance = holder, Label = buttons[1] })
	end

	local group = { Instance = holder, Buttons = buttons }

	function group:SetButtonText(index, text)
		local button = buttons[index]
		if button then
			button.Text = text
		end
	end

	function group:SetVisible(visible)
		holder.Visible = visible
	end

	function group:Destroy()
		holder:Destroy()
	end

	return group
end
