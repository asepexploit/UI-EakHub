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
local Services = import("Core/Services")

local Create, Tween = Utility.Create, Utility.Tween
local TweenService = Services.TweenService

local Layout = import("Components/GroupBox") -- exports { GroupBox, Columns }

-- Every entry becomes a method: Tab:<Name>(options)
local Components = {
	-- Inputs
	Button = import("Components/Button"),
	ButtonGroup = import("Components/ButtonGroup"),
	Toggle = import("Components/Toggle"),
	Checkbox = import("Components/Checkbox"),
	Slider = import("Components/Slider"),
	RangeSlider = import("Components/RangeSlider"),
	Stepper = import("Components/Stepper"),
	Input = import("Components/Input"),
	TextArea = import("Components/TextArea"),
	Dropdown = import("Components/Dropdown"),
	PlayerDropdown = import("Components/PlayerDropdown"),
	Segmented = import("Components/Segmented"),
	ColorPicker = import("Components/ColorPicker"),
	Keybind = import("Components/Keybind"),
	Grid = import("Components/Grid"),
	TaskCard = import("Components/TaskCard"),
	Swatches = import("Components/Swatches"),
	List = import("Components/List"),

	-- Display
	Paragraph = import("Components/Paragraph"),
	Image = import("Components/Image"),
	CodeBlock = import("Components/CodeBlock"),
	ProgressBar = import("Components/ProgressBar"),
	StatTiles = import("Components/StatTiles"),
	KeyValue = import("Components/KeyValue"),
	WorldMap = import("Components/WorldMap"),
	Spinner = import("Components/Spinner"),

	-- Layout
	Section = import("Components/Section"),
	Divider = import("Components/Divider"),
	Collapsible = import("Components/Collapsible"),
	SubTabs = import("Components/SubTabs"),
	GroupBox = Layout.GroupBox,
	Columns = Layout.Columns,
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
		Size = UDim2.new(1, -(textX + 22), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeColor = "SubText",
		Parent = button,
	})

	-- Pulsing dot shown while something in this tab is running (Tab:SetLive)
	local liveDot = Create("Frame", {
		Name = "LiveDot",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Constants.NotifyColors.Success,
		BorderSizePixel = 0,
		Visible = false,
		Parent = button,
	}, { Utility.Corner(999) })

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
		TabButton = button, -- sidebar TextButton (NOT "Button": that would shadow Tab:Button())
		Active = false,
		_order = 0,
		_indicator = indicator,
		_label = label,
		_icon = icon,
		_iconTint = options.IconTint ~= false, -- false keeps full-color images (e.g. URL logos)
		_searchables = {},
		_sections = {},
		_empty = emptyLabel,
		_liveDot = liveDot,
		_livePulse = nil,
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

	Tween(self.TabButton, { BackgroundTransparency = active and 0.86 or 1 }, 0.25)
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

--[[
	Creates a tab-like container around `frame` so layout components
	(Collapsible, GroupBox, Columns, SubTabs) can hold any component:

		local child = tab:_Child(frame)
		child:Button({ ... })   -- parented to `frame`

	The child shares the parent tab's search index, so elements inside
	containers are still found by the sidebar search. `frame` must have
	its own UIListLayout (children are ordered by LayoutOrder).
]]
function Tab:_Child(frame)
	return setmetatable({
		Title = self.Title,
		Window = self.Window,
		Page = frame,
		TabButton = self.TabButton,
		Parent = self,
		_order = 0,
		_searchables = self._searchables,
		_sections = self._sections,
		_empty = self._empty,
	}, Tab)
end

-- Shows a pulsing green dot next to the tab name (e.g. while a task runs)
function Tab:SetLive(state)
	local root = self
	while root.Parent do -- containers forward to the real sidebar tab
		root = root.Parent
	end
	local dot = root._liveDot
	if not dot then
		return
	end
	if root._livePulse then
		root._livePulse:Cancel()
		root._livePulse = nil
	end
	dot.Visible = state and true or false
	dot.BackgroundTransparency = 0
	if state then
		root._livePulse = TweenService:Create(
			dot,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ BackgroundTransparency = 0.65 }
		)
		root._livePulse:Play()
	end
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
Tab.Radio = Tab.Segmented
Tab.Colorpicker = Tab.ColorPicker
Tab.Textarea = Tab.TextArea
Tab.Accordion = Tab.Collapsible

return Tab
