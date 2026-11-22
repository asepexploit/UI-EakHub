--[[
	Window
	Main hub window: shadow, glass body, topbar, sidebar, content area,
	drag, resize, minimize, show/hide, keybind and floating toggle button.

	Window.new(config) -> window
	config:
		Title, Author, Icon, IconColor
		Logo (square logo: id / rbxassetid / URL / file) -- topbar, floating button, minimized pill
		BrandLogo, BrandLogoSize                         -- wordmark shown next to the logo when minimized
		Size (UDim2), MinSize (Vector2), SidebarWidth
		Theme, Accent
		ToggleKey (Enum.KeyCode | nil), ToggleButton (bool), ToggleIcon, ToggleButtonPosition
		Search (bool), Profile (bool), ConfirmClose (bool) -- all default true
		OnClose (function)
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Gui = import("Core/Gui")
local Draggable = import("Core/Draggable")
local Notify = import("Components/Notification")
local Tab = import("Window/Tab")
local Topbar = import("Window/Topbar")
local ToggleButton = import("Window/ToggleButton")
local SearchBar = import("Window/SearchBar")
local Profile = import("Window/Profile")
local Dialog = import("Window/Dialog")
local MiniBar = import("Window/MiniBar")

local Create, Tween, Track = Utility.Create, Utility.Tween, Utility.Track
local UserInputService = Services.UserInputService
local Defaults = Constants.Window
local TOPBAR = Defaults.TopbarHeight

local Window = {}

function Window.new(config)
	config = config or {}
	Theme.Ensure(config.Theme or "Dark", config.Accent)

	local screenGui = Gui.Get()
	local sidebarWidth = config.SidebarWidth or Defaults.SidebarWidth
	local minSize = config.MinSize or Defaults.MinSize
	local size = config.Size or Defaults.DefaultSize

	local window = {
		Tabs = {},
		ActiveTab = nil,
		Minimized = false,
		Visible = true,
		Gui = screenGui,
		_query = "",
		_dialog = nil,
		ToggleKey = config.ToggleKey == nil and Defaults.ToggleKey or config.ToggleKey,
	}

	---------------------------------------------------------------- frame
	local root = Create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X.Offset, size.Y.Offset),
		BackgroundTransparency = 1,
		Parent = screenGui,
	})
	local rootScale = Create("UIScale", { Parent = root })

	Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = UDim2.new(1, 60, 1, 60),
		BackgroundTransparency = 1,
		Image = Constants.Shadow.Image,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Constants.Shadow.SliceCenter,
		ZIndex = 0,
		Parent = root,
	})

	local main = Create("Frame", {
		Name = "Main",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = Constants.Glass.Main,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = root,
	}, {
		Utility.Corner(12),
		Create("UIGradient", { -- glass sheen
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 215, 225)),
		}),
	})
	Theme.Bind(main, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.86).Parent = main

	local topbar = Topbar.new(main, config)

	---------------------------------------------------------------- body
	local body = Create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, TOPBAR + 1),
		Size = UDim2.new(1, 0, 1, -(TOPBAR + 1)),
		BackgroundTransparency = 1,
		Parent = main,
	})

	local sidebar = Create("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(0, sidebarWidth, 1, -16),
		BackgroundTransparency = Constants.Glass.Sidebar,
		BorderSizePixel = 0,
		Parent = body,
	}, { Utility.Corner(10) })
	Theme.Bind(sidebar, { BackgroundColor3 = "Sidebar" })
	Builders.Stroke(0.94).Parent = sidebar

	local searchHeight = config.Search == false and 0 or Defaults.SearchHeight
	local profileHeight = config.Profile == false and 0 or Defaults.ProfileHeight
	local listTop = searchHeight > 0 and (searchHeight + 8) or 0

	if searchHeight > 0 then
		SearchBar.new(sidebar, searchHeight, function(text)
			window._query = text
			if window.ActiveTab then
				window.ActiveTab:Filter(text)
			end
		end)
	end

	if profileHeight > 0 then
		Profile.new(sidebar, profileHeight)
	end

	local tabList = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, listTop),
		Size = UDim2.new(1, 0, 1, -(listTop + profileHeight)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	}, { Utility.List(3), Utility.Padding(6, 6, 6, 6) })

	local content = Create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(sidebarWidth + 16, 0),
		Size = UDim2.new(1, -(sidebarWidth + 16), 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = body,
	})

	---------------------------------------------------------------- resize handle
	local resizeHandle = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 10,
		Parent = main,
	})
	for _, offset in ipairs({ { 11, 5 }, { 11, 11 }, { 5, 11 } }) do
		local dot = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(offset[1], offset[2]),
			Size = UDim2.fromOffset(3, 3),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 11,
			Parent = resizeHandle,
		}, { Utility.Corner(2) })
		Theme.Bind(dot, { BackgroundColor3 = "SubText" })
	end

	---------------------------------------------------------------- responsive scale
	local baseScale = 1

	local function computeScale()
		local viewport = Utility.GetViewport()
		local fitWidth = (viewport.X - 24) / root.Size.X.Offset
		local fitHeight = (viewport.Y - 24) / math.max(root.Size.Y.Offset, TOPBAR)
		baseScale = math.clamp(math.min(1, fitWidth, fitHeight), 0.5, 1)
		return baseScale
	end

	local camera = workspace.CurrentCamera
	if camera then
		Track(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if window.Visible then
				Tween(rootScale, { Scale = computeScale() }, 0.2)
			end
		end))
	end

	---------------------------------------------------------------- drag
	Draggable(topbar.Frame, root)

	---------------------------------------------------------------- resize
	local resizing, resizeStart, startSize, startPosition = false, nil, nil, nil

	Track(resizeHandle.InputBegan:Connect(function(input)
		if Utility.IsClick(input) and not window.Minimized then
			resizing = true
			resizeStart = input.Position
			startSize = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
			startPosition = root.Position
		end
	end))

	Track(UserInputService.InputChanged:Connect(function(input)
		if not (resizing and Utility.IsMove(input)) then
			return
		end
		local scale = rootScale.Scale
		local viewport = Utility.GetViewport()
		local delta = (input.Position - resizeStart) / scale

		local width = math.clamp(startSize.X + delta.X, minSize.X, math.max(minSize.X, viewport.X / scale - 20))
		local height = math.clamp(startSize.Y + delta.Y, minSize.Y, math.max(minSize.Y, viewport.Y / scale - 20))
		root.Size = UDim2.fromOffset(width, height)

		-- anchor is centered: shift so the top-left corner stays pinned
		local dx = (width - startSize.X) * scale / 2
		local dy = (height - startSize.Y) * scale / 2
		root.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + dx,
			startPosition.Y.Scale,
			startPosition.Y.Offset + dy
		)
	end))

	Track(UserInputService.InputEnded:Connect(function(input)
		if resizing and Utility.IsClick(input) then
			resizing = false
		end
	end))

	---------------------------------------------------------------- minimize
	-- Minimizing collapses the window into a small pill: [logo] brand.
	-- The pill appears where the window's top-left corner was; restoring
	-- moves the window to wherever the pill was dragged.
	local miniBar

	function window:Minimize(state)
		if state == nil then
			state = not window.Minimized
		end
		if state == window.Minimized then
			return
		end
		window.Minimized = state

		if state then
			local corner = root.AbsolutePosition
			Tween(rootScale, { Scale = baseScale * 0.9 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.15, function()
				if window.Minimized then
					root.Visible = false
				end
			end)
			miniBar:Show(corner)
		else
			local corner = miniBar.Instance.AbsolutePosition
			local half = root.AbsoluteSize / 2
			miniBar:Hide()
			root.Position = UDim2.fromOffset(corner.X + half.X, corner.Y + half.Y)
			if window.Visible then
				root.Visible = true
				rootScale.Scale = baseScale * 0.9
				Tween(rootScale, { Scale = baseScale }, 0.3, Enum.EasingStyle.Back)
			end
		end
	end

	miniBar = MiniBar.new(screenGui, config, function()
		window:Minimize(false)
	end)

	---------------------------------------------------------------- visibility
	local animating = false

	function window:SetVisible(state)
		if state == window.Visible or animating then
			return
		end
		window.Visible = state

		-- While minimized, show/hide the pill instead of the window
		if window.Minimized then
			if state then
				miniBar:Show()
			else
				miniBar:Hide()
			end
			if window.ToggleButton then
				Tween(window.ToggleButton.Stroke, { Transparency = state and 0.2 or 0.6 }, 0.2)
			end
			return
		end

		animating = true

		if state then
			root.Visible = true
			rootScale.Scale = computeScale() * 0.9
			Tween(rootScale, { Scale = baseScale }, 0.35, Enum.EasingStyle.Back)
			task.delay(0.35, function()
				animating = false
			end)
		else
			Tween(rootScale, { Scale = baseScale * 0.9 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.18, function()
				if not window.Visible then
					root.Visible = false
				end
				animating = false
			end)
		end

		if window.ToggleButton then
			Tween(window.ToggleButton.Stroke, { Transparency = state and 0.2 or 0.6 }, 0.2)
		end
	end

	function window:Toggle()
		window:SetVisible(not window.Visible)
	end

	---------------------------------------------------------------- lifecycle
	local destroyed = false

	function window:Destroy()
		if destroyed then
			return
		end
		destroyed = true

		Tween(rootScale, { Scale = baseScale * 0.85 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.2)

		Utility.DisconnectAll()
		Theme.Reset()
		Gui.Destroy()
		table.clear(State.Windows)
		Utility.SafeCall(config.OnClose)
	end

	---------------------------------------------------------------- misc API
	function window:SetTitle(text)
		topbar.TitleLabel.Text = text
	end

	function window:SetAuthor(text)
		if topbar.AuthorLabel then
			topbar.AuthorLabel.Text = text
		end
	end

	function window:SetTheme(name, accent)
		Theme.Set(name, accent)
	end

	function window:SetToggleKey(keyCode)
		window.ToggleKey = keyCode
	end

	function window:Notify(options)
		return Notify(options)
	end

	function window:Dialog(options)
		if window._dialog then
			window._dialog:Close()
		end
		options = options or {}
		local userOnClose = options.OnClose
		options.OnClose = function()
			window._dialog = nil
			Utility.SafeCall(userOnClose)
		end
		window._dialog = Dialog.new(main, options)
		return window._dialog
	end

	---------------------------------------------------------------- tabs
	function window:SelectTab(target)
		local tab = type(target) == "number" and window.Tabs[target] or target
		if not tab or tab == window.ActiveTab then
			return
		end

		local previous = window.ActiveTab
		window.ActiveTab = tab

		if previous then
			previous.Page.Visible = false
			previous:_SetActive(false)
		end

		tab:_SetActive(true)
		tab:Filter(window._query)
		tab.Page.Visible = true
		tab.Page.Position = UDim2.fromOffset(0, 14)
		Tween(tab.Page, { Position = UDim2.fromOffset(0, 0) }, 0.35)
	end

	function window:Tab(options)
		local tab = Tab.new(window, options, { List = tabList, Content = content })
		table.insert(window.Tabs, tab)
		if #window.Tabs == 1 then
			window:SelectTab(tab)
		end
		return tab
	end
	window.AddTab = window.Tab
	window.CreateTab = window.Tab

	---------------------------------------------------------------- inputs
	topbar.MinimizeButton.MouseButton1Click:Connect(function()
		window:Minimize()
	end)

	topbar.CloseButton.MouseButton1Click:Connect(function()
		if config.ConfirmClose == false then
			task.spawn(function()
				window:Destroy()
			end)
			return
		end
		if window._dialog then
			return
		end
		window:Dialog({
			Title = "Close " .. (config.Title or "this window") .. "?",
			Content = "The interface will be removed. Run the script again to bring it back.",
			Buttons = {
				{ Title = "Cancel" },
				{
					Title = "Close",
					Variant = "Danger",
					Callback = function()
						window:Destroy()
					end,
				},
			},
		})
	end)

	Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:Toggle()
		end
	end))

	if config.ToggleButton ~= false then
		window.ToggleButton = ToggleButton.new(screenGui, config, function()
			window:Toggle()
		end)
	end

	---------------------------------------------------------------- open animation
	computeScale()
	rootScale.Scale = baseScale * 0.9
	Tween(rootScale, { Scale = baseScale }, 0.45, Enum.EasingStyle.Back)

	table.insert(State.Windows, window)
	return window
end

return Window
