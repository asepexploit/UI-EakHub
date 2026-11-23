--[[
	KeySystem
	License / key gate shown before the hub loads.

	local Key = UI:KeySystem({
		Title     = "EakHub",
		Logo      = "https://.../logo.png",     -- optional, any image source or icon name
		Prefix    = "EAKHUB", Groups = 3, GroupSize = 4, -- EAKHUB-XXXX-XXXX-XXXX
		Keys      = { "EAKHUB-7A4B-28C1-9F3E" },  -- simple static list, or:
		Verify    = function(key)                -- runs in its own thread, may yield (HttpGet...)
			return true, { Plan = "Premium", Expires = os.time() + 29 * 86400 }
			-- return false, "This key has expired"
		end,
		Discord   = "https://discord.gg/xxxx",
		GetKey    = "https://link-to-get-a-key", -- string (copied) or function
	})

	local ok, info = Key:Wait()   -- yields until verified (true, info) or closed (false)
	if not ok then return end

	Shortcut: UI:CreateWindow({ ..., KeySystem = { ...same options... } })
	returns nil when the key screen is closed without a valid key.

	See README for every option.
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Gui = import("Core/Gui")
local Assets = import("Core/Assets")
local Draggable = import("Core/Draggable")
local Notify = import("Components/Notification")
local Format = import("KeySystem/Format")
local Storage = import("KeySystem/Storage")
local Widgets = import("KeySystem/Widgets")
local KeyField = import("KeySystem/KeyField")
local SuccessView = import("KeySystem/SuccessView")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local WIDTH = 420
local TOPBAR = 50
local INFO = Color3.fromRGB(56, 189, 248)
local DISCORD = Color3.fromRGB(88, 101, 242)

local KeySystem = {}
KeySystem.__index = KeySystem

---------------------------------------------------------------- helpers
local function copy(text)
	local writer = setclipboard or toclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
	if type(writer) ~= "function" then
		return false
	end
	return (pcall(writer, text))
end

local function toast(enabled, title, content, kind)
	if enabled then
		Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 4 })
	end
end

-- Normalises whatever Verify returned into ok, info | ok, message
local function interpret(...)
	local first, second = ...
	if type(first) == "table" then
		return true, first
	end
	if first == true then
		return true, type(second) == "table" and second or {}
	end
	if type(first) == "string" and second == nil then
		return false, first
	end
	return false, type(second) == "string" and second or "Invalid key"
end

local function staticVerifier(keys)
	local lookup = {}
	for key, value in pairs(keys) do
		if type(key) == "number" then
			lookup[string.upper(value)] = {}
		else
			lookup[string.upper(key)] = type(value) == "table" and value or {} -- { [key] = info }
		end
	end
	return function(key)
		local info = lookup[string.upper(key)]
		if info then
			return true, info
		end
		return false, "Invalid key. Check it and try again."
	end
end

---------------------------------------------------------------- constructor
function KeySystem.new(config)
	config = config or {}
	Theme.Ensure(config.Theme or "Dark", config.Accent)

	local title = config.Title or "EakHub"
	local self = setmetatable({
		Config = config,
		Verified = false,
		Closed = false,
		Key = nil,
		Info = nil,
		_waiting = {},
		_busy = false,
		_cancelLaunch = nil,
		_toasts = config.Notify ~= false,
	}, KeySystem)

	self.Formatter = Format.new(config)
	self.Storage = config.SaveKey ~= false and Storage.new(config.FileName or (title:gsub("[^%w_%-]", "") .. "/key.txt"))
	self.Verifier = config.Verify or (config.Keys and staticVerifier(config.Keys))
	if not self.Verifier then
		warn("[EakUI] KeySystem: no Verify function or Keys list given, every key will be rejected")
		self.Verifier = function()
			return false, "Key checking is not configured"
		end
	end

	local screenGui = Gui.Get()

	---------------------------------------------------------------- backdrop + card
	local backdrop
	if config.Backdrop ~= false then
		backdrop = Create("Frame", {
			Name = "KeyBackdrop",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 50,
			Parent = screenGui,
		})
		Tween(backdrop, { BackgroundTransparency = 0.45 }, 0.3)
	end
	self._backdrop = backdrop

	local root = Create("Frame", {
		Name = "KeySystem",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, 400),
		BackgroundTransparency = 1,
		ZIndex = 51,
		Parent = screenGui,
	})
	self.Instance = root
	local rootScale = Create("UIScale", { Scale = 0.94, Parent = root })
	self._scale = rootScale

	Create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 8),
		Size = UDim2.new(1, 70, 1, 70),
		BackgroundTransparency = 1,
		Image = Constants.Shadow.Image,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.4,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Constants.Shadow.SliceCenter,
		ZIndex = 51,
		Parent = root,
	})

	local card = Create("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ZIndex = 52,
		Parent = root,
	}, {
		Corner(16),
		Utility.List(0),
		Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 215)),
		}),
	})
	Theme.Bind(card, { BackgroundColor3 = "Background" })
	Builders.Stroke(0.86).Parent = card

	-- The root keeps a fixed size that follows the card, so the shadow (sized
	-- relative to the root) never feeds back into an AutomaticSize parent.
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local scale = math.max(rootScale.Scale, 0.01)
		root.Size = UDim2.fromOffset(WIDTH, math.floor(card.AbsoluteSize.Y / scale + 0.5))
	end)
	self._card = card

	self:_buildTopbar(card, title)

	-- Pages
	local form = Create("Frame", {
		Name = "Form",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = card,
	}, {
		Utility.Padding(20, 18, 24, 24),
		Utility.List(14),
	})
	self._form = form
	self:_buildForm(form, title)

	self._success = SuccessView.new(card, {
		LayoutOrder = 3,
		Title = config.SuccessTitle,
		OnReset = config.AllowReset ~= false and function()
			self:_reset()
		end or nil,
	})

	---------------------------------------------------------------- fit + intro
	local function fit()
		local viewport = Utility.GetViewport()
		local height = math.max(root.AbsoluteSize.Y / math.max(rootScale.Scale, 0.01), 1)
		return math.clamp(math.min(1, (viewport.X - 24) / WIDTH, (viewport.Y - 24) / height), 0.55, 1)
	end
	self._fit = fit
	task.defer(function()
		Tween(rootScale, { Scale = fit() }, 0.35, Enum.EasingStyle.Back)
	end)

	-- Saved key
	local saved = self.Storage and self.Storage:Load()
	if saved then
		self._saved = saved
		self._banner.Visible = true
		toast(self._toasts, "Key found", "A saved license key was detected.", "Info")
		if config.AutoLogin then
			self._field:Set(saved)
			task.defer(function()
				self:Verify()
			end)
		end
	end

	return self
end

---------------------------------------------------------------- topbar
function KeySystem:_buildTopbar(card, title)
	local config = self.Config
	local bar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, TOPBAR),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = card,
	})

	local row = Create("Frame", {
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		BackgroundTransparency = 1,
		Parent = bar,
	}, { Utility.List(10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center) })

	local tile = Create("Frame", {
		Size = UDim2.fromOffset(26, 26),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		LayoutOrder = 1,
		Parent = row,
	}, { Corner(8) })
	Theme.Bind(tile, { BackgroundColor3 = "Accent" })
	if config.Logo then
		local logo = Create("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Parent = tile,
		}, { Corner(8) })
		Assets.Apply(logo, config.Logo)
	else
		Create("TextLabel", {
			Text = string.upper(string.sub(title, 1, 1)),
			Font = Fonts.Black,
			TextSize = 14,
			TextColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = tile,
		})
	end

	Builders.Label({
		Text = title,
		Font = Fonts.Black,
		TextSize = 15,
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Parent = row,
	})

	if config.Pill ~= false then
		local pill = Create("Frame", {
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
			LayoutOrder = 3,
			Parent = row,
		}, { Corner(999), Utility.Padding(0, 0, 9, 9) })
		Theme.Bind(pill, { BackgroundColor3 = "Accent" })
		Builders.Label({
			Text = config.Pill or "License",
			Font = Fonts.Bold,
			TextSize = 11,
			ThemeColor = "SubText",
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = pill,
		})
	end

	local close = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Parent = bar,
	}, { Corner(8) })
	Builders.CrossIcon(close, 12, "SubText")
	close.MouseEnter:Connect(function()
		Tween(close, { BackgroundTransparency = 0.92 }, 0.15)
	end)
	close.MouseLeave:Connect(function()
		Tween(close, { BackgroundTransparency = 1 }, 0.15)
	end)
	close.MouseButton1Click:Connect(function()
		self:Close()
	end)
	if config.Closable == false then
		close.Visible = false
	end

	local divider = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		Parent = bar,
	})
	divider.Name = "Divider"

	Draggable(bar, self.Instance)
end

---------------------------------------------------------------- form
function KeySystem:_buildForm(form, title)
	local config = self.Config

	-- Hero
	local hero = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = form,
	}, { Utility.List(10, nil, Enum.HorizontalAlignment.Center) })

	local lock = Create("Frame", {
		Size = UDim2.fromOffset(52, 52),
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = hero,
	}, { Corner(15) })
	Theme.Bind(lock, { BackgroundColor3 = "Accent" })
	local lockStroke = Create("UIStroke", { Transparency = 0.65, Parent = lock })
	Theme.Bind(lockStroke, { Color = "Accent" })
	Widgets.Icon(lock, config.HeroIcon or "lock", 24, "Accent", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})

	local texts = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = hero,
	}, { Utility.List(4, nil, Enum.HorizontalAlignment.Center) })
	Builders.Label({
		Text = config.Heading or ("Activate " .. title),
		Font = Fonts.Bold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = texts,
	})
	Builders.Label({
		Text = config.Subtitle or "Enter your license key to unlock the hub",
		TextSize = 13,
		ThemeColor = "SubText",
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = texts,
	})

	-- Saved-key banner
	local banner = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = INFO,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Visible = false,
		LayoutOrder = 2,
		Parent = form,
	}, { Corner(11) })
	Create("UIStroke", { Color = INFO, Transparency = 0.75, Parent = banner })
	Widgets.Icon(banner, "info", 16, INFO, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
	})
	Create("TextLabel", {
		Text = config.SavedText or "Saved key found on this device",
		Font = Fonts.Medium,
		TextSize = 12,
		TextColor3 = INFO:Lerp(Color3.new(1, 1, 1), 0.7),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Parent = banner,
	})
	local useSaved = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(60, 28),
		BackgroundColor3 = INFO,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = Fonts.Bold,
		TextSize = 12,
		TextColor3 = INFO,
		Text = "Use it",
		Parent = banner,
	}, { Corner(7) })
	useSaved.MouseEnter:Connect(function()
		Tween(useSaved, { BackgroundTransparency = 0.85 }, 0.15)
	end)
	useSaved.MouseLeave:Connect(function()
		Tween(useSaved, { BackgroundTransparency = 1 }, 0.15)
	end)
	useSaved.MouseButton1Click:Connect(function()
		if self._saved and not self._busy then
			self._field:Set(self._saved)
			banner.Visible = false
		end
	end)
	self._banner = banner

	-- Key field
	local field = KeyField.new(form, self.Formatter, { LayoutOrder = 3, Label = config.FieldLabel })
	field:Submitted(function()
		self:Verify()
	end)
	self._field = field

	-- Remember
	if self.Storage then
		self._remember = Widgets.Checkbox(form, config.RememberText or "Remember key on this device", config.Remember ~= false, nil, 4)
	end

	-- Primary
	self._primary = Widgets.Button(form, {
		Text = config.ButtonText or "Verify & Launch",
		TrailingIcon = "arrow-right",
		Height = 46,
		LayoutOrder = 5,
		Callback = function()
			self:Verify()
		end,
	})

	-- Discord
	if config.Discord then
		local discordText = config.DiscordText or "Join Discord"
		local discord
		discord = Widgets.Button(form, {
			Text = discordText,
			Icon = "message",
			Style = "Tinted",
			Color = DISCORD,
			Height = 42,
			LayoutOrder = 6,
			Callback = function()
				if type(config.Discord) == "function" then
					config.Discord()
					return
				end
				if copy(config.Discord) then
					discord:SetText("Invite copied")
					toast(self._toasts, "Discord invite copied", "Paste it in your browser to join.", "Success")
					task.delay(2, function()
						discord:SetText(discordText)
					end)
				else
					toast(self._toasts, "Join our Discord", tostring(config.Discord), "Info")
				end
			end,
		})
		self._discord = discord
	end

	-- Footer links
	local hasGetKey = config.GetKey ~= nil
	local hasHelp = config.Help ~= nil
	if hasGetKey or hasHelp then
		local footer = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			LayoutOrder = 7,
			Parent = form,
		}, {
			Utility.List(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
		})

		if hasGetKey then
			local getKeyText = config.GetKeyText or "Get a key"
			local getKey
			getKey = Widgets.Button(footer, {
				Text = getKeyText,
				Style = "Link",
				LayoutOrder = 1,
				Callback = function()
					if type(config.GetKey) == "function" then
						config.GetKey()
					elseif copy(tostring(config.GetKey)) then
						getKey:SetText("Link copied")
						toast(self._toasts, "Key link copied", "Paste it in your browser to get a key.", "Success")
						task.delay(2, function()
							getKey:SetText(getKeyText)
						end)
					else
						toast(self._toasts, "Get a key", tostring(config.GetKey), "Info")
					end
				end,
			})
		end

		if hasGetKey and hasHelp then
			local dot = Create("Frame", {
				Size = UDim2.fromOffset(3, 3),
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				Parent = footer,
			}, { Corner(2) })
			Theme.Bind(dot, { BackgroundColor3 = "SubText" })
		end

		if hasHelp then
			Widgets.Button(footer, {
				Text = config.HelpText or "Need help?",
				Style = "Link",
				LayoutOrder = 3,
				Callback = function()
					if type(config.Help) == "function" then
						config.Help()
					else
						toast(true, config.HelpText or "Need help?", tostring(config.Help), "Info")
					end
				end,
			})
		end
	end
end

---------------------------------------------------------------- flow
function KeySystem:_setBusy(busy)
	self._busy = busy
	self._field:SetEnabled(not busy)
	self._primary:SetBusy(busy, busy and (self.Config.VerifyingText or "Verifying key...") or (self.Config.ButtonText or "Verify & Launch"))
end

function KeySystem:_fail(message)
	self:_setBusy(false)
	self._field:SetError(message)
	self._field:Shake()
	toast(self._toasts, "Verification failed", message, "Error")
end

function KeySystem:Verify(key)
	if self._busy or self.Verified or self.Closed then
		return
	end
	if key then
		self._field:Set(key)
	end
	key = self._field:Get()

	if not self._field:IsComplete() then
		local message = key == "" and "Enter your license key first"
			or ("Incomplete key. It should look like " .. self.Formatter.Placeholder)
		self._field:SetError(message)
		self._field:Shake()
		return
	end

	self._field:SetError(nil)
	self:_setBusy(true)

	task.spawn(function()
		local started = os.clock()
		local results = table.pack(pcall(self.Verifier, key))
		-- Keep the spinner up briefly so instant checks do not flicker
		local elapsed = os.clock() - started
		if elapsed < 0.6 then
			task.wait(0.6 - elapsed)
		end
		if self.Closed then
			return
		end

		if not results[1] then
			warn("[EakUI] KeySystem Verify error: " .. tostring(results[2]))
			self:_fail("Could not verify the key right now. Try again.")
			return
		end

		local ok, payload = interpret(table.unpack(results, 2, results.n))
		if not ok then
			if self.Storage and self._saved == key then
				self.Storage:Clear() -- a saved key that stopped working is forgotten
				self._saved = nil
			end
			self:_fail(payload)
			return
		end

		self:_succeed(key, payload)
	end)
end

function KeySystem:_succeed(key, info)
	self:_setBusy(false)
	self.Key = key
	self.Info = info

	if self.Storage then
		if not self._remember or self._remember:Get() then
			self.Storage:Save(key)
		else
			self.Storage:Clear()
		end
	end

	local expiry = SuccessView.FormatExpiry(info.Expires)
	toast(self._toasts, "License activated", (info.Plan or "Licensed") .. (expiry and (" · " .. expiry) or ""), "Success")

	self._form.Visible = false
	self._success:Show(info, self.Formatter:Mask(key))

	local launchText = self.Config.LaunchText or ("Loading " .. (self.Config.Title or "EakHub") .. "...")
	self._cancelLaunch = self._success:Launch(self.Config.LaunchDelay or 1.6, launchText, function()
		self.Verified = true
		Utility.SafeCall(self.Config.OnSuccess, key, info)
		self:_resolve(true, info)
		self:Destroy()
	end)
end

function KeySystem:_reset()
	if self._cancelLaunch then
		self._cancelLaunch()
		self._cancelLaunch = nil
	end
	if self.Storage then
		self.Storage:Clear()
	end
	self._saved = nil
	self._banner.Visible = false
	self.Key, self.Info = nil, nil
	self._success:Hide()
	self._form.Visible = true
	self._field:Set("")
	self._field:SetError(nil)
end

function KeySystem:_resolve(ok, info)
	local waiting = self._waiting
	self._waiting = {}
	for _, thread in ipairs(waiting) do
		task.spawn(thread, ok, info)
	end
end

---------------------------------------------------------------- public
-- Yields until the key is accepted (true, info) or the screen is closed (false)
function KeySystem:Wait()
	if self.Verified then
		return true, self.Info
	end
	if self.Closed then
		return false
	end
	table.insert(self._waiting, (coroutine.running()))
	return coroutine.yield()
end

function KeySystem:IsVerified()
	return self.Verified
end

function KeySystem:GetSavedKey()
	return self.Storage and self.Storage:Load()
end

function KeySystem:ClearSavedKey()
	if self.Storage then
		self.Storage:Clear()
	end
end

function KeySystem:Close()
	if self.Closed or self.Verified then
		return
	end
	if self._cancelLaunch then
		self._cancelLaunch()
	end
	self.Closed = true
	Utility.SafeCall(self.Config.OnClose)
	self:_resolve(false)
	self:Destroy()
end

function KeySystem:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._primary:SetBusy(false)

	Tween(self._scale, { Scale = 0 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if self._backdrop then
		Tween(self._backdrop, { BackgroundTransparency = 1 }, 0.2)
	end
	task.delay(0.22, function()
		self.Instance:Destroy()
		if self._backdrop then
			self._backdrop:Destroy()
		end
	end)
end

return KeySystem
