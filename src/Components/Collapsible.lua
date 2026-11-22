--[[
	Components/Collapsible
	Card with a clickable header that expands / collapses its content.
	Returns a container: any component can be added to it.

	local combat = Tab:Collapsible({
		Title = "Combat",
		Desc  = "optional",
		Icon  = "rbxassetid://...",  -- optional (id, URL or file)
		Open  = true,                -- start expanded (default true)
		Callback = function(isOpen) end,
	})
	combat:Toggle({ Title = "Kill Aura", Callback = print })
	combat:Slider({ Title = "Range", Min = 1, Max = 20, Default = 10 })

	combat:Open() / :Close() / :SetOpen(bool) / :ToggleOpen() / :IsOpen() / :SetTitle(text)
	(:Toggle stays the normal Toggle component, like on any tab.)
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")

local Create, Tween = Utility.Create, Utility.Tween

local DURATION = 0.3

return function(tab, options)
	options = options or {}
	local description = options.Desc or options.Description
	local headerHeight = description and 54 or 42
	local opened = options.Open ~= false

	---------------------------------------------------------------- card
	local holder = Create("Frame", {
		Name = options.Title or "Collapsible",
		Size = UDim2.new(1, 0, 0, headerHeight),
		AutomaticSize = opened and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.Corner(10) })
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	Builders.Stroke().Parent = holder

	---------------------------------------------------------------- header
	local header = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, headerHeight),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = holder,
	})

	local textX = 12
	if options.Icon then
		local icon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = header,
		})
		Assets.Apply(icon, options.Icon)
		if options.IconTint ~= false then
			Theme.Bind(icon, { ImageColor3 = "Accent" })
		end
		textX = 40
	end

	local textGroup = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, textX, 0.5, 0),
		Size = UDim2.new(1, -(textX + 40), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = header,
	}, { Utility.List(3) })

	local title = Builders.Label({
		Text = options.Title or "Section",
		Font = Constants.Fonts.Bold,
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = textGroup,
	})

	if description then
		Builders.Label({
			Text = description,
			Font = Constants.Fonts.Regular,
			TextSize = 12,
			ThemeColor = "SubText",
			Size = UDim2.new(1, 0, 0, 15),
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 2,
			Parent = textGroup,
		})
	end

	local chevron = Builders.Chevron(header, opened and "up" or "down", "SubText")
	chevron.Holder.AnchorPoint = Vector2.new(1, 0.5)
	chevron.Holder.Position = UDim2.new(1, -16, 0.5, 0)

	local divider = Create("Frame", {
		Position = UDim2.new(0, 12, 0, headerHeight - 1),
		Size = UDim2.new(1, -24, 0, 1),
		BackgroundTransparency = opened and 0.93 or 1,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

	---------------------------------------------------------------- body
	local body = Create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, headerHeight),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = holder,
	}, {
		Utility.List(6),
		Utility.Padding(10, 10, 10, 10),
	})

	header.MouseEnter:Connect(function()
		Tween(holder, { BackgroundTransparency = Constants.Glass.Element - 0.1 }, 0.15)
	end)
	header.MouseLeave:Connect(function()
		Tween(holder, { BackgroundTransparency = Constants.Glass.Element }, 0.15)
	end)

	---------------------------------------------------------------- open / close
	-- Absolute sizes include the window's UIScale; convert back to offsets.
	local function scaleFactor()
		local measured = header.AbsoluteSize.Y
		return measured > 0 and measured / headerHeight or 1
	end

	local animationId = 0

	local function setOpen(state, instant)
		opened = state
		animationId += 1
		local currentAnimation = animationId
		local factor = scaleFactor()
		local current = holder.AbsoluteSize.Y / factor
		local target = state and (headerHeight + body.AbsoluteSize.Y / factor) or headerHeight
		local duration = instant and 0 or DURATION

		-- Animate with a fixed height, then hand back to AutomaticSize when open
		holder.AutomaticSize = Enum.AutomaticSize.None
		holder.Size = UDim2.new(1, 0, 0, current)
		Tween(holder, { Size = UDim2.new(1, 0, 0, target) }, duration)
		Tween(divider, { BackgroundTransparency = state and 0.93 or 1 }, duration)
		chevron:Set(state and "up" or "down", instant)

		task.delay(duration, function()
			if currentAnimation ~= animationId or not holder.Parent then
				return
			end
			if opened then
				holder.Size = UDim2.new(1, 0, 0, headerHeight)
				holder.AutomaticSize = Enum.AutomaticSize.Y -- follows children added later
			end
		end)

		Utility.SafeCall(options.Callback, opened)
	end

	header.MouseButton1Click:Connect(function()
		setOpen(not opened)
	end)

	if tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = title })
	end

	---------------------------------------------------------------- container API
	local container = tab:_Child(body)
	container.Instance = holder
	container.Body = body

	function container:Open()
		if not opened then
			setOpen(true)
		end
	end

	function container:Close()
		if opened then
			setOpen(false)
		end
	end

	function container:SetOpen(state)
		setOpen(state and true or false)
	end

	function container:ToggleOpen()
		setOpen(not opened)
	end

	function container:IsOpen()
		return opened
	end

	function container:SetTitle(text)
		title.Text = text
	end

	function container:Destroy()
		holder:Destroy()
	end

	return container
end
