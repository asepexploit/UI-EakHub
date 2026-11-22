--[[
	Components/Section
	Small uppercase heading that groups elements.

	Tab:Section("Player")  or  Tab:Section({ Title = "Player" })
]]

local import = ...
local Utility = import("Core/Utility")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

return function(tab, options)
	if type(options) == "string" then
		options = { Title = options }
	end
	options = options or {}

	local label = Builders.Label({
		Text = string.upper(options.Title or "Section"),
		Font = Constants.Fonts.Bold,
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 26),
		TextYAlignment = Enum.TextYAlignment.Bottom,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	})
	Utility.Padding(0, 2, 4, 0).Parent = label

	-- Headings are hidden while a search filter is active
	if tab._sections then
		table.insert(tab._sections, label)
	end

	local section = { Instance = label }

	function section:SetTitle(text)
		label.Text = string.upper(text)
	end

	function section:Destroy()
		label:Destroy()
	end

	return section
end
