--[[
	Window/Tab
	A sidebar entry + its scrollable page. Component methods
	(Button, Toggle, Slider, ...) are attached from Components/.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local Components = {
	Section = import("Components/Section"),
	Button = import("Components/Button"),
	Toggle = import("Components/Toggle"),
	Slider = import("Components/Slider"),
	Input = import("Components/Input"),
	Dropdown = import("Components/Dropdown"),
	Keybind = import("Components/Keybind"),
	Grid = import("Components/Grid"),
	Paragraph = import("Components/Paragraph"),
	Divider = import("Components/Divider"),
}

local Tab = {}
Tab.__index = Tab

-- Tab.new(window, { Title, Icon, Desc }, { List = sidebarList, Content = contentFrame })
function Tab.new(window, options, containers)
	options = options or {}
	local index = #window.Tabs + 1
	local hasIcon = options.Icon ~= nil

	local button = Create("TextButton", {
		Name = options.Title or ("Tab" .. index),
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = index,
		Parent = containers.List,
	}, { Utility.Corner(8) })
	Theme.Bind(button, { BackgroundColor3 = "Accent" })

	local indicator = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BorderSizePixel = 0,
		Parent = button,
	}, { Utility.Corner(2) })
	Theme.Bind(indicator, { BackgroundColor3 = "Accent" })

	local icon
	if hasIcon then
		icon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(17, 17),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = button,
		})
		Assets.Apply(icon, options.Icon)
	end

	local textX = hasIcon and 37 or 14
	local label = Builders.Label({
		Text = options.Title or ("Tab " .. index),
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1, -(textX + 8), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeColor = "SubText",
		Parent = button,
	})

	local page = Create("ScrollingFrame", {
		Name = (options.Title or "Tab") .. "_Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = containers.Content,
	}, { Utility.List(6), Utility.Padding(8, 12, 0, 10) })
	Theme.Bind(page, { ScrollBarImageColor3 = "Accent" })

	-- Page header: tab title + optional description -----------------------
	local header = Create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = page,
	}, { Utility.List(2), Utility.Padding(2, 6, 4, 4) })

	Builders.Label({
		Text = options.Title or ("Tab " .. index),
		Font = Constants.Fonts.Bold,
		TextSize = 18,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 1,
		Parent = header,
	})

	if options.Desc then
		Builders.Label({
			Text = options.Desc,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = header,
		})
	end

	-- Shown when a search has no matches in this tab
	local emptyLabel = Builders.Label({
		Text = "No matching elements",
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 60),
		LayoutOrder = 1e6,
		Visible = false,
		Parent = page,
	})

	local self = setmetatable({
		Title = options.Title,
		Window = window,
		Page = page,
		Button = button,
		Active = false,
		_order = 0,
		_indicator = indicator,
		_label = label,
		_icon = icon,
		_iconTint = options.IconTint ~= false, -- false keeps full-color images (e.g. URL logos)
		_searchables = {},
		_sections = {},
		_empty = emptyLabel,
	}, Tab)

	button.MouseEnter:Connect(function()
		if not self.Active then
			Tween(button, { BackgroundTransparency = 0.94 }, 0.15)
		end
	end)
	button.MouseLeave:Connect(function()
		if not self.Active then
			Tween(button, { BackgroundTransparency = 1 }, 0.15)
		end
	end)
	button.MouseButton1Click:Connect(function()
		window:SelectTab(self)
	end)

	self:_SetActive(false)
	Theme.OnChange(function()
		self:_SetActive(self.Active)
	end)

	return self
end

function Tab:_NextOrder()
	self._order += 1
	return self._order
end

function Tab:_SetActive(active)
	self.Active = active
	local theme = State.Theme

	Tween(self.Button, { BackgroundTransparency = active and 0.86 or 1 }, 0.25)
	Tween(self._indicator, { Size = UDim2.fromOffset(3, active and 16 or 0) }, 0.3, Enum.EasingStyle.Back)
	Tween(self._label, { TextColor3 = active and theme.Text or theme.SubText }, 0.25)
	if self._icon and self._iconTint then
		Tween(self._icon, { ImageColor3 = active and theme.Accent or theme.SubText }, 0.25)
	elseif self._icon then
		Tween(self._icon, { ImageTransparency = active and 0 or 0.35 }, 0.25)
	end
end

function Tab:Select()
	self.Window:SelectTab(self)
end

-- Shows only elements whose title contains `query` (case-insensitive)
function Tab:Filter(query)
	query = string.lower(query or "")
	local searching = query ~= ""
	local matches = 0

	for _, item in ipairs(self._searchables) do
		if item.Instance.Parent then
			local text = string.lower(item.Label.ContentText ~= "" and item.Label.ContentText or item.Label.Text)
			local visible = not searching or string.find(text, query, 1, true) ~= nil
			item.Instance.Visible = visible
			if visible then
				matches += 1
			end
		end
	end

	for _, heading in ipairs(self._sections) do
		if heading.Parent then
			heading.Visible = not searching
		end
	end

	self._empty.Visible = searching and matches == 0
end

-- Attach component constructors as methods: Tab:Button(options), ...
for name, build in pairs(Components) do
	Tab[name] = function(self, options)
		return build(self, options)
	end
end

-- Aliases
Tab.Textbox = Tab.Input
Tab.TextBox = Tab.Input
Tab.Label = Tab.Paragraph

return Tab
