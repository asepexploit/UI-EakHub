--[[
	Components/Element
	Shared base for every tab element: rounded glass card, stroke,
	title + optional description, hover state and common methods.

	Element.new(tab, options, config) -> element
	config:
		Button    : boolean  -- use a TextButton (clickable card)
		Hover     : boolean  -- hover highlight
		Height    : number   -- minimum height (default 42)
		Auto      : boolean  -- grow with text (default true)
		Clip      : boolean  -- ClipsDescendants
		RightSize : UDim     -- width reserved for the control on the right
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local Element = {}

function Element.new(tab, options, config)
	config = config or {}
	local rightSize = config.RightSize or UDim.new(0, 0)
	local height = config.Height or 42
	local autoSize = config.Auto ~= false and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
	local customColor = options.Color

	local holder = Create(config.Button and "TextButton" or "Frame", {
		Name = options.Title or "Element",
		Size = UDim2.new(1, 0, 0, height),
		AutomaticSize = autoSize,
		BackgroundTransparency = customColor and 0.1 or Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = config.Clip or config.Button or false,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(8) })

	if config.Button then
		holder.Text = ""
		holder.AutoButtonColor = false
	end

	if customColor then
		holder.BackgroundColor3 = customColor
	else
		Theme.Bind(holder, { BackgroundColor3 = "Element" })
	end

	local stroke = Builders.Stroke()
	stroke.Parent = holder
	local scale = Create("UIScale", { Parent = holder })

	-- Optional left icon: Icon is tinted to match text, Image keeps its colors
	local iconSource = options.Icon or options.Image
	local textX = 12
	local iconLabel
	if iconSource then
		local iconSize = options.IconSize or (options.Image and 32 or 18)
		iconLabel = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = holder,
		}, { Utility.Corner(options.Image and 6 or 0) })
		Assets.Apply(iconLabel, iconSource)
		if options.Icon and options.IconTint ~= false then
			Theme.Bind(iconLabel, { ImageColor3 = "SubText" })
		end
		textX = 12 + iconSize + 10
	end

	local textHolder = Create("Frame", {
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1 - rightSize.Scale, -(textX + 12 + rightSize.Offset), 0, height),
		AutomaticSize = autoSize,
		BackgroundTransparency = 1,
		Parent = holder,
	}, {
		Utility.List(3, nil, nil, Enum.VerticalAlignment.Center),
		Utility.Padding(10, 10, 0, 0),
	})

	local description = options.Desc or options.Description

	local title = Builders.Label({
		Text = options.Title or "Element",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = 1,
		Parent = textHolder,
	})

	local desc = Builders.Label({
		Text = description or "",
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		RichText = true,
		Visible = description ~= nil,
		LayoutOrder = 2,
		Parent = textHolder,
	})

	if config.Hover then
		holder.MouseEnter:Connect(function()
			local target = customColor and customColor:Lerp(Color3.new(1, 1, 1), 0.1) or State.Theme.ElementHover
			Tween(holder, { BackgroundColor3 = target }, 0.18)
			Tween(stroke, { Transparency = State.Theme.StrokeAlpha - 0.08 }, 0.18)
		end)
		holder.MouseLeave:Connect(function()
			Tween(holder, { BackgroundColor3 = customColor or State.Theme.Element }, 0.18)
			Tween(stroke, { Transparency = State.Theme.StrokeAlpha }, 0.18)
		end)
	end

	-- Make the element discoverable by the sidebar search
	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	local element = {
		Instance = holder,
		TitleLabel = title,
		DescLabel = desc,
		TextHolder = textHolder,
		IconLabel = iconLabel,
		Stroke = stroke,
		Scale = scale,
	}

	function element:SetTitle(text)
		title.Text = text
	end

	function element:SetDesc(text)
		desc.Text = text or ""
		desc.Visible = text ~= nil and text ~= ""
	end

	function element:SetIcon(source)
		if iconLabel then
			Assets.Apply(iconLabel, source)
		end
	end

	function element:SetVisible(visible)
		holder.Visible = visible
	end

	function element:Destroy()
		holder:Destroy()
	end

	return element
end

-- Exposes an element through UI.Flags[options.Flag]
function Element.RegisterFlag(options, element)
	if options.Flag then
		State.Flags[options.Flag] = element
	end
end

return Element
