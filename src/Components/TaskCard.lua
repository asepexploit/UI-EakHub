--[[
	Components/TaskCard
	Status + progress + Start/Stop control for any long-running job
	(auto clear, auto farm, auto fish...). One card owns the whole lifecycle:

		idle ──Start──▶ running ──Stop──▶ paused ──Resume──▶ running
		  ▲                │                                    │
		  └──── Reset ─────┴──────────── progress == total ─────▶ done ──Run again──▶ running

	local job = Tab:TaskCard({
		Title       = "Auto Clear",          -- optional, also makes the card searchable
		Unit        = "tiles",               -- "86 / 180 tiles"
		StartText   = "Start Sweep",         -- also: StopText, ResumeText, AgainText
		IdleText    = "Press Start to scan the world",
		MiniStatus  = "Clearing",            -- minimized pill shows "Clearing · 45%" (false = off)
		OnStart     = function(job) end,     -- from idle/done; runs in its own thread
		OnStop      = function(job) end,     -- running -> paused
		OnResume    = function(job) end,     -- paused -> running
		OnComplete  = function(job) end,     -- progress reached total
		OnReset     = function(job) end,     -- reset button (hidden when ResetButton = false)
	})

	Typical worker:
		OnStart = function(job)
			local tiles = findTiles()
			job:SetTotal(#tiles)
			for _, tile in ipairs(tiles) do
				if not job:WaitIfPaused() then return end   -- false once reset/stopped for good
				breakTile(tile)
				job:Increment()
			end
		end

	Methods: :Start() :Stop() :Resume() :Toggle() :Reset() :Complete()
	         :SetTotal(n) :SetProgress(n) :Increment(k) :SetStatus(state, text?)
	         :SetSubtitle(text?) :GetStatus() :IsRunning() :GetElapsed() :GetProgress()
	         :WaitIfPaused() :SetTitle(text) :SetVisible(bool) :Destroy()
	States : "idle" | "preparing" | "running" | "paused" | "done"
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Assets = import("Core/Assets")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween
local RunService = game:GetService("RunService")
local TweenService = Services.TweenService

local STATES = {
	idle = { Label = "Idle", Color = "SubText" },
	preparing = { Label = "Preparing", Color = Color3.fromRGB(56, 189, 248) },
	running = { Label = "Running", Color = Constants.NotifyColors.Success },
	paused = { Label = "Paused", Color = Constants.NotifyColors.Warning },
	done = { Label = "Completed", Color = Constants.NotifyColors.Success },
}

local function stateColor(name)
	local color = STATES[name].Color
	return typeof(color) == "Color3" and color or State.Theme[color]
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor(seconds / 60) % 60
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%02d:%02d", minutes, secs)
end

return function(tab, options)
	options = options or {}
	local unit = options.Unit or "items"

	---------------------------------------------------------------- state
	local status = "idle"
	local total, progress, elapsed = 0, 0, 0
	local customSubtitle = nil
	local alive = true

	---------------------------------------------------------------- card
	local holder = Create("Frame", {
		Name = options.Title or "TaskCard",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = Constants.Glass.Element,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = tab:_NextOrder(),
		Parent = tab.Page,
	}, {
		Utility.Corner(12),
		Utility.Padding(14, 14, 14, 14),
		Utility.List(12),
	})
	Theme.Bind(holder, { BackgroundColor3 = "Element" })
	local stroke = Builders.Stroke()
	stroke.Parent = holder

	-- status tint across the card
	local tint = Create("UIGradient", {
		Rotation = 25,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.6, 0.35),
			NumberSequenceKeypoint.new(1, 0.35),
		}),
		Parent = holder,
	})

	---------------------------------------------------------------- row 1: [title] [status pill] ........ [timer]
	local topRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = holder,
	})
	local left = Create("Frame", {
		Size = UDim2.new(1, -90, 1, 0),
		BackgroundTransparency = 1,
		Parent = topRow,
	}, { Utility.List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	local titleLabel
	if options.Title then
		titleLabel = Builders.Label({
			Text = options.Title,
			Font = Constants.Fonts.Bold,
			TextSize = 14,
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 1,
			Parent = left,
		})
	end

	local pill = Create("Frame", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = left,
	}, {
		Utility.Corner(999),
		Utility.Padding(0, 0, 10, 10),
		Utility.List(7, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center),
	})
	local pillDot = Create("Frame", {
		Size = UDim2.fromOffset(7, 7),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = pill,
	}, { Utility.Corner(999) })
	local pillLabel = Create("TextLabel", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Bold,
		TextSize = 12,
		LayoutOrder = 2,
		Parent = pill,
	})

	local timerLabel = Builders.Label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 90, 1, 0),
		Font = Constants.Fonts.Mono,
		TextSize = 12,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "00:00",
		Parent = topRow,
	})

	---------------------------------------------------------------- row 2: count + subtitle ........ percent
	local countRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = holder,
	})
	local countLabel = Builders.Label({
		Size = UDim2.new(1, -70, 0, 30),
		Font = Constants.Fonts.Bold,
		TextSize = 26,
		RichText = true,
		Parent = countRow,
	})
	local subtitleLabel = Builders.Label({
		Position = UDim2.fromOffset(0, 31),
		Size = UDim2.new(1, -70, 0, 15),
		Font = Constants.Fonts.Regular,
		TextSize = 12,
		ThemeColor = "SubText",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = countRow,
	})
	local percentLabel = Builders.Label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.new(0, 70, 0, 26),
		Font = Constants.Fonts.Bold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = countRow,
	})

	---------------------------------------------------------------- row 3: progress bar (+ moving shine while running)
	local track = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 3,
		Parent = holder,
	}, { Utility.Corner(999) })
	Theme.Bind(track, { BackgroundColor3 = "ToggleOff" })

	local fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = track,
	}, { Utility.Corner(999) })

	local shine = Create("Frame", {
		Size = UDim2.fromScale(0.35, 1),
		Position = UDim2.fromScale(-0.4, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Visible = false,
		Parent = fill,
	}, {
		Create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.65),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	local shineTween = TweenService:Create(
		shine,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
		{ Position = UDim2.fromScale(1.1, 0) }
	)

	---------------------------------------------------------------- row 4: [ main action ] [reset]
	local actions = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = holder,
	})
	local showReset = options.ResetButton ~= false

	local mainButton = Create("TextButton", {
		Size = UDim2.new(1, showReset and -48 or 0, 1, 0),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Text = "",
		Parent = actions,
	}, { Utility.Corner(10) })
	local mainStroke = Create("UIStroke", {
		Thickness = 1,
		Transparency = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = mainButton,
	})
	local mainScale = Create("UIScale", { Parent = mainButton })
	local mainContent = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = mainButton,
	}, { Utility.List(8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })
	local mainIcon = Create("ImageLabel", {
		Size = UDim2.fromOffset(15, 15),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		LayoutOrder = 1,
		Parent = mainContent,
	})
	local mainLabel = Create("TextLabel", {
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Bold,
		TextSize = 13,
		LayoutOrder = 2,
		Parent = mainContent,
	})

	local resetButton
	if showReset then
		resetButton = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = Constants.Glass.Field,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = actions,
		}, { Utility.Corner(10) })
		Theme.Bind(resetButton, { BackgroundColor3 = "Field" })
		Builders.Stroke().Parent = resetButton
		local resetIcon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Parent = resetButton,
		})
		Assets.Apply(resetIcon, "refresh")
		Theme.Bind(resetIcon, { ImageColor3 = "SubText" })
		resetButton.MouseEnter:Connect(function()
			Tween(resetButton, { BackgroundColor3 = State.Theme.ElementHover }, 0.15)
		end)
		resetButton.MouseLeave:Connect(function()
			Tween(resetButton, { BackgroundColor3 = State.Theme.Field }, 0.15)
		end)
	end

	---------------------------------------------------------------- rendering
	local job = { Instance = holder, TitleLabel = titleLabel }
	local rootTab = tab
	while rootTab.Parent do
		rootTab = rootTab.Parent
	end

	local function percent()
		return total > 0 and math.floor(progress / total * 100 + 0.5) or 0
	end

	local function autoSubtitle()
		local remaining = math.max(0, total - progress)
		if status == "idle" then
			return options.IdleText or "Press Start to begin"
		elseif status == "preparing" then
			return options.PreparingText or "Preparing..."
		elseif status == "running" then
			if total <= 0 then
				return "Working..."
			end
			local rate = elapsed > 1 and progress / elapsed or 0
			local eta = rate > 0 and (" · about " .. formatTime(remaining / rate) .. " left") or ""
			return remaining .. " " .. unit .. " left" .. eta
		elseif status == "paused" then
			return "Paused · " .. remaining .. " " .. unit .. " left"
		else
			return "Finished · " .. progress .. " " .. unit .. " in " .. formatTime(elapsed)
		end
	end

	local function renderButton()
		local accent = State.Theme.Accent
		local danger = Constants.Danger
		local icon, text
		if status == "running" or status == "preparing" then
			icon, text = "pause", options.StopText or "Stop"
			Tween(mainButton, { BackgroundColor3 = danger, BackgroundTransparency = 0.86 }, 0.2)
			mainStroke.Color = danger
			mainStroke.Transparency = 0.5
			mainLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
		else
			if status == "paused" then
				icon, text = "play", options.ResumeText or "Resume"
			elseif status == "done" then
				icon, text = "refresh", options.AgainText or "Run again"
			else
				icon, text = "play", options.StartText or "Start"
			end
			Tween(mainButton, { BackgroundColor3 = accent, BackgroundTransparency = 0 }, 0.2)
			mainStroke.Transparency = 1
			mainLabel.TextColor3 = Color3.new(1, 1, 1)
		end
		mainLabel.Text = text
		mainIcon.ImageColor3 = mainLabel.TextColor3
		Assets.Apply(mainIcon, icon)
	end

	local function renderMiniStatus()
		if options.MiniStatus == false or not tab.Window or not tab.Window.SetStatus then
			return
		end
		if status == "running" then
			local label = type(options.MiniStatus) == "string" and options.MiniStatus or (options.Title or "Running")
			tab.Window:SetStatus(label .. " · " .. percent() .. "%", Constants.NotifyColors.Success)
		elseif status == "paused" then
			tab.Window:SetStatus("Paused · " .. percent() .. "%", Constants.NotifyColors.Warning)
		else
			tab.Window:SetStatus(nil)
		end
	end

	local function renderProgress(instant)
		local pct = percent()
		countLabel.Text = string.format(
			'%d<font size="15" color="#%s"> / %d %s</font>',
			progress,
			State.Theme.SubText:ToHex(),
			total,
			unit
		)
		percentLabel.Text = pct .. "%"
		percentLabel.TextColor3 = status == "done" and Constants.NotifyColors.Success or State.Theme.Text
		subtitleLabel.Text = customSubtitle or autoSubtitle()
		Tween(fill, { Size = UDim2.fromScale(total > 0 and progress / total or 0, 1) }, instant and 0 or 0.3)
		renderMiniStatus()
	end

	local function renderStatus()
		local color = stateColor(status)
		pillLabel.Text = (status == "preparing" and options.PreparingLabel) or STATES[status].Label
		pillLabel.TextColor3 = color
		pillDot.BackgroundColor3 = color
		pill.BackgroundColor3 = color
		tint.Color = ColorSequence.new(
			(status == "idle" and State.Theme.Accent or color):Lerp(State.Theme.Element, 0.82),
			State.Theme.Element
		)
		stroke.Color = (status == "running" or status == "paused") and color or State.Theme.Stroke
		stroke.Transparency = (status == "running" or status == "paused") and 0.6 or State.Theme.StrokeAlpha

		local fillColor = status == "done" and Constants.NotifyColors.Success
			or status == "paused" and Constants.NotifyColors.Warning
			or State.Theme.Accent
		Tween(fill, { BackgroundColor3 = fillColor }, 0.2)

		local active = status == "running"
		shine.Visible = active
		if active then
			shineTween:Play()
		else
			shineTween:Cancel()
			shine.Position = UDim2.fromScale(-0.4, 0)
		end

		if rootTab.SetLive then
			rootTab:SetLive(active or status == "preparing")
		end
		renderButton()
		renderProgress(true)
	end

	local function setStatus(newStatus)
		assert(STATES[newStatus], "TaskCard: unknown status " .. tostring(newStatus))
		status = newStatus
		renderStatus()
	end

	---------------------------------------------------------------- timer
	local timerAccumulator = 0
	Utility.Track(RunService.Heartbeat:Connect(function(dt)
		if status ~= "running" and status ~= "preparing" then
			return
		end
		elapsed += dt
		timerAccumulator += dt
		if timerAccumulator >= 0.25 then
			timerAccumulator = 0
			timerLabel.Text = formatTime(elapsed)
			if not customSubtitle then
				subtitleLabel.Text = autoSubtitle()
			end
		end
	end))

	---------------------------------------------------------------- lifecycle API
	function job:GetStatus()
		return status
	end

	function job:IsRunning()
		return status == "running" or status == "preparing"
	end

	function job:GetElapsed()
		return elapsed
	end

	-- progress, total, percent (0-100)
	function job:GetProgress()
		return progress, total, percent()
	end

	function job:Start()
		if job:IsRunning() then
			return
		end
		if status == "paused" then
			return job:Resume()
		end
		progress, elapsed, customSubtitle = 0, 0, nil
		timerLabel.Text = "00:00"
		setStatus("running")
		Utility.SafeCall(options.OnStart, job)
	end

	function job:Stop()
		if not job:IsRunning() then
			return
		end
		setStatus("paused")
		Utility.SafeCall(options.OnStop, job)
	end

	function job:Resume()
		if status ~= "paused" then
			return
		end
		setStatus("running")
		Utility.SafeCall(options.OnResume, job)
	end

	function job:Toggle()
		if job:IsRunning() then
			job:Stop()
		elseif status == "paused" then
			job:Resume()
		else
			job:Start()
		end
	end

	function job:Complete()
		if status == "done" then
			return
		end
		if total > 0 then
			progress = total
		end
		setStatus("done")
		Utility.SafeCall(options.OnComplete, job)
	end

	function job:Reset()
		total, progress, elapsed, customSubtitle = 0, 0, 0, nil
		timerLabel.Text = "00:00"
		setStatus("idle")
		Utility.SafeCall(options.OnReset, job)
	end

	-- "preparing" while scanning, etc.; optional custom subtitle
	function job:SetStatus(newStatus, subtitle)
		customSubtitle = subtitle
		setStatus(newStatus)
	end

	function job:SetSubtitle(text)
		customSubtitle = text
		renderProgress(true)
	end

	function job:SetTotal(n)
		total = math.max(0, math.floor(n or 0))
		progress = math.min(progress, total)
		if status == "preparing" then
			setStatus("running")
		else
			renderProgress()
		end
	end

	function job:SetProgress(n)
		progress = math.clamp(math.floor(n or 0), 0, total > 0 and total or math.huge)
		if total > 0 and progress >= total and job:IsRunning() then
			job:Complete()
		else
			renderProgress()
		end
	end

	function job:Increment(amount)
		job:SetProgress(progress + (amount or 1))
	end

	-- For worker loops: yields while paused. Returns false once the job was
	-- reset/completed/destroyed, so the loop knows to exit.
	function job:WaitIfPaused()
		while alive and status == "paused" do
			task.wait(0.1)
		end
		return alive and job:IsRunning()
	end

	function job:SetTitle(text)
		if titleLabel then
			titleLabel.Text = text
		end
	end

	function job:SetVisible(visible)
		holder.Visible = visible
	end

	function job:Destroy()
		alive = false
		shineTween:Cancel()
		holder:Destroy()
	end

	---------------------------------------------------------------- input
	Utility.Track(mainButton.InputBegan:Connect(function(input)
		if Utility.IsClick(input) then
			Builders.Ripple(mainButton, input.Position)
		end
	end))
	mainButton.MouseEnter:Connect(function()
		Tween(mainScale, { Scale = 1.01 }, 0.15)
	end)
	mainButton.MouseLeave:Connect(function()
		Tween(mainScale, { Scale = 1 }, 0.15)
	end)
	mainButton.MouseButton1Click:Connect(function()
		Builders.Press(mainScale)
		job:Toggle()
	end)
	if resetButton then
		resetButton.MouseButton1Click:Connect(function()
			job:Reset()
		end)
	end

	if titleLabel and tab._searchables then
		table.insert(tab._searchables, { Instance = holder, Label = titleLabel })
	end

	Theme.OnChange(renderStatus)
	renderStatus()
	Element.RegisterFlag(options, job)
	return job
end
