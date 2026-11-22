--[[
	Components/Paragraph

	local paragraph = Tab:Paragraph({ Title = "About", Desc = "Some text" })
	paragraph:Set({ Title = "New", Desc = "Updated" })
]]

local import = ...
local Constants = import("Core/Constants")
local Element = import("Components/Element")

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options)
	element.TitleLabel.Font = Constants.Fonts.Bold

	local content = options.Desc or options.Content
	if content then
		element:SetDesc(content)
	end

	function element:Set(newOptions)
		if newOptions.Title then
			element:SetTitle(newOptions.Title)
		end
		local text = newOptions.Desc or newOptions.Content
		if text then
			element:SetDesc(text)
		end
	end

	return element
end
