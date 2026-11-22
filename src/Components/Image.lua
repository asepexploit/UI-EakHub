--[[
	Components/Image
	Image / banner card. Accepts any image source (asset id, URL, workspace file).

	local banner = Tab:Image({
		Image     = "https://example.com/banner.png",
		Height    = 140,
		ScaleType = Enum.ScaleType.Crop,   -- default
		Title     = "Season 3",            -- optional overlay text
		Desc      = "New maps and items",  -- optional
	})
	banner:SetImage("rbxassetid://123")
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create = Utility.Create

return function(tab, options)
	options = options or {}
	local height = options.Height or 140

	local holder = Create("Frame", {
		Name = options.Title or "Image",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(10) })
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	local image = Create("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = options.ScaleType or Enum.ScaleType.Crop,
		Parent = holder,
	}, { Utility.Corner(10) })
	if options.Image then
		Assets.Apply(image, options.Image)
	end

	local titleLabel
	if options.Title or options.Desc then
		-- Dark gradient at the bottom so overlay text stays readable
		local shade = Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, math.min(height, 80)),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = holder,
		}, {
			Create("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0.25),
				}),
			}),
		})

		local text = Create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 12, 1, -10),
			Size = UDim2.new(1, -24, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = shade,
		}, { Utility.List(2, nil, nil, Enum.VerticalAlignment.Bottom) })

		if options.Title then
			titleLabel = Create("TextLabel", {
				Text = options.Title,
				Font = Constants.Fonts.Bold,
				TextSize = 15,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				ZIndex = 3,
				Parent = text,
			})
		end
		if options.Desc then
			Create("TextLabel", {
				Text = options.Desc,
				Font = Constants.Fonts.Regular,
				TextSize = 12,
				TextColor3 = Color3.fromRGB(225, 225, 232),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
				ZIndex = 3,
				Parent = text,
			})
		end
	end

	if tab._searchables and titleLabel then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	local element = { Instance = holder, ImageLabel = image }

	function element:SetImage(source)
		Assets.Apply(image, source)
	end

	function element:SetVisible(visible)
		holder.Visible = visible
	end

	function element:Destroy()
		holder:Destroy()
	end

	return element
end
