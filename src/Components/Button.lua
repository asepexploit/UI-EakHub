--[[
	Components/Button

	Tab:Button({
		Title    = "Click Me",
		Desc     = "optional",
		Color    = Color3.fromRGB(190, 40, 60), -- optional custom background
		Callback = function() end,
	})
]]

local import = ...
local Utility = import("Core/Utility")
local Builders = import("Core/Builders")
local Element = import("Components/Element")

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		Button = true,
		Hover = true,
		RightSize = UDim.new(0, 20),
	})
	local holder = element.Instance

	local arrow = Builders.Chevron(holder, "right", options.Color and "Text" or "SubText")
	arrow.Holder.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Holder.Position = UDim2.new(1, -14, 0.5, 0)

	Utility.Track(holder.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			Builders.Ripple(holder, input.Position)
		end
	end))

	holder.MouseButton1Click:Connect(function()
		Builders.Press(element.Scale)
		Utility.SafeCall(options.Callback)
	end)

	function element:Fire()
		Utility.SafeCall(options.Callback)
	end

	function element:SetCallback(callback)
		options.Callback = callback
	end

	return element
end
