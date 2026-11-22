--[[
	Components/SubTabs
	Segmented bar of sub-pages inside a tab, with a sliding accent pill.

	local sub = Tab:SubTabs({
		Tabs     = { "Aimbot", "ESP", "Misc" },
		Default  = "Aimbot",           -- optional, name or index
		Callback = function(name) end, -- fired when switching
	})
	sub:Get("ESP"):Toggle({ Title = "Boxes" })   -- or sub[2]
	sub:Select("Misc") / sub:GetActive() -> name
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create, Tween = Utility.Create, Utility.Tween

local BAR_HEIGHT = 34
local INSET = 3

return function(tab, options)
	options = options or {}
	local names = options.Tabs or options.Values or { "Tab" }
	local count = #names

	local holder = Create("Frame", {
		Name = "SubTabs",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, { Utility.List(8) })

	---------------------------------------------------------------- bar
	local bar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
		BackgroundTransparency = Constants.Glass.Field,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = holder,
	}, { Utility.Corner(9) })
	Theme.Bind(bar, { BackgroundColor3 = "Field" })
	Builders.Stroke().Parent = bar

	local track = Create("Frame", {
		Position = UDim2.fromOffset(INSET, INSET),
		Size = UDim2.new(1, -INSET * 2, 1, -INSET * 2),
		BackgroundTransparency = 1,
		Parent = bar,
	})

	local pill = Create("Frame", {
		Size = UDim2.new(1 / count, 0, 1, 0),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = track,
	}, { Utility.Corner(7) })
	Theme.Bind(pill, { BackgroundColor3 = "Accent" })

	---------------------------------------------------------------- pages
	local pagesHolder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})

	local subtabs = { Instance = holder }
	local entries = {} -- [index] = { Name, Button, Page, Container }
	local byName = {}
	local activeIndex

	local function render(instant)
		local theme = State.Theme
		for index, entry in ipairs(entries) do
			local active = index == activeIndex
			Tween(entry.Button, {
				TextColor3 = active and Color3.new(1, 1, 1) or theme.SubText,
			}, instant and 0 or 0.2)
		end
		if activeIndex then
			Tween(pill, { Position = UDim2.fromScale((activeIndex - 1) / count, 0) }, instant and 0 or 0.3)
		end
	end

	local function selectTab(target, instant)
		local index = type(target) == "number" and target or byName[target]
		if not index or not entries[index] or index == activeIndex then
			return
		end

		local previous = entries[activeIndex or 0]
		activeIndex = index
		local entry = entries[index]

		if previous then
			previous.Page.Visible = false
		end
		entry.Page.Visible = true
		if not instant then
			entry.Page.Position = UDim2.fromOffset(0, 10)
			Tween(entry.Page, { Position = UDim2.fromOffset(0, 0) }, 0.3)
		end

		render(instant)
		if not instant then
			Utility.SafeCall(options.Callback, entry.Name)
		end
	end

	for index, name in ipairs(names) do
		local button = Create("TextButton", {
			Name = tostring(name),
			Position = UDim2.fromScale((index - 1) / count, 0),
			Size = UDim2.new(1 / count, 0, 1, 0),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Font = Constants.Fonts.Medium,
			TextSize = 12,
			Text = tostring(name),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
			Parent = track,
		})
		Theme.Bind(button, { TextColor3 = "SubText" })

		local page = Create("Frame", {
			Name = tostring(name) .. "_Page",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
			Parent = pagesHolder,
		}, { Utility.List(6) })

		local container = tab:_Child(page)
		container.Instance = page

		entries[index] = { Name = name, Button = button, Page = page, Container = container }
		byName[name] = index
		subtabs[index] = container

		button.MouseEnter:Connect(function()
			if index ~= activeIndex then
				Tween(button, { TextColor3 = State.Theme.Text }, 0.15)
			end
		end)
		button.MouseLeave:Connect(function()
			if index ~= activeIndex then
				Tween(button, { TextColor3 = State.Theme.SubText }, 0.15)
			end
		end)
		button.MouseButton1Click:Connect(function()
			selectTab(index)
		end)
	end

	---------------------------------------------------------------- API
	function subtabs:Get(target)
		local index = type(target) == "number" and target or byName[target]
		return index and entries[index] and entries[index].Container or nil
	end

	function subtabs:Select(target)
		selectTab(target)
	end

	function subtabs:GetActive()
		return activeIndex and entries[activeIndex].Name or nil
	end

	function subtabs:Destroy()
		holder:Destroy()
	end

	Theme.OnChange(function()
		render(true)
	end)

	selectTab(options.Default or 1, true)
	return subtabs
end
