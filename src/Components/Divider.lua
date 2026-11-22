--[[
	Components/Divider
	Thin horizontal separator between groups of elements.

	Tab:Divider()
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")

local Create = Utility.Create

return function(tab)
	local holder = Create("Frame", {
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, 9),
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	})

	local line = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.new(1, -8, 0, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Theme.Bind(line, { BackgroundColor3 = "Stroke" })

	if tab._sections then
		table.insert(tab._sections, holder)
	end

	local divider = { Instance = holder }

	function divider:Destroy()
		holder:Destroy()
	end

	return divider
end
