--[[
	KeySystem/SuccessView
	Shown after a key is accepted: check mark, welcome line, license details
	(plan, expiry, masked key) and a launch progress bar.

	local view = SuccessView.new(parent, { OnReset = fn })
	view:Show(info, maskedKey)
	view:Launch(seconds, onDone) -> cancel()
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")
local Widgets = import("KeySystem/Widgets")

local Create, Tween, Corner = Utility.Create, Utility.Tween, Utility.Corner
local Fonts = Constants.Fonts

local SUCCESS = Color3.fromRGB(74, 222, 128)

local SuccessView = {}
SuccessView.__index = SuccessView

-- 1795400000 -> "22 Dec 2026 · 29 days"; true/"Lifetime" -> "Lifetime"
function SuccessView.FormatExpiry(expires)
	if expires == nil then
		return nil
	end
	if expires == true or expires == false or expires == 0 then
		return "Lifetime"
	end
	if type(expires) ~= "number" then
		return tostring(expires)
	end
	local remaining = expires - os.time()
	if remaining <= 0 then
		return "Expired"
	end
	local date = os.date("%d %b %Y", expires)
	local days = math.floor(remaining / 86400)
	if days >= 1 then
		return ("%s · %d day%s"):format(date, days, days == 1 and "" or "s")
	end
	local hours = math.max(1, math.floor(remaining / 3600))
	return ("%s · %d hour%s"):format(date, hours, hours == 1 and "" or "s")
end

function SuccessView.new(parent, options)
	options = options or {}
	local self = setmetatable({ _rows = {} }, SuccessView)

	local page = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = options.LayoutOrder or 0,
		Parent = parent,
	}, {
		Utility.Padding(26, 20, 24, 24),
		Utility.List(16, nil, Enum.HorizontalAlignment.Center),
	})
	self.Instance = page

	-- Check mark
	local badge = Create("Frame", {
		Size = UDim2.fromOffset(62, 62),
		BackgroundColor3 = SUCCESS,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = page,
	}, { Corner(999) })
	Create("UIStroke", { Color = SUCCESS, Transparency = 0.6, Parent = badge })
	self._badgeScale = Create("UIScale", { Parent = badge })
	Widgets.Icon(badge, "check", 28, SUCCESS, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})

	-- Heading
	local heading = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = page,
	}, { Utility.List(4, nil, Enum.HorizontalAlignment.Center) })
	Builders.Label({
		Text = options.Title or "License activated",
		Font = Fonts.Bold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = heading,
	})
	self._welcome = Builders.Label({
		Text = "",
		TextSize = 13,
		ThemeColor = "SubText",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 2,
		Parent = heading,
	})

	-- Details card
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Parent = page,
	}, { Corner(12), Utility.List(0) })
	Theme.Bind(card, { BackgroundColor3 = "Field" })
	Builders.Stroke(0.93).Parent = card
	self._card = card

	-- Launch progress
	local launch = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = page,
	}, { Utility.List(8) })
	local launchHeader = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Parent = launch,
	})
	self._launchLabel = Builders.Label({
		Text = "Loading...",
		TextSize = 12,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.7, 1),
		Parent = launchHeader,
	})
	self._launchPct = Builders.Label({
		Text = "",
		Font = Fonts.Mono,
		TextSize = 12,
		ThemeColor = "SubText",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.3, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = launchHeader,
	})
	local track = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundTransparency = 0.93,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = launch,
	}, { Corner(999) })
	self._fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		Corner(999),
		Create("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(170, 170, 170), Color3.new(1, 1, 1)),
		}),
	})
	Theme.Bind(self._fill, { BackgroundColor3 = "Accent" })

	if options.OnReset then
		Widgets.Button(page, {
			Text = options.ResetText or "Use a different key",
			Style = "Link",
			LayoutOrder = 5,
			Callback = options.OnReset,
		})
	end

	return self
end

function SuccessView:_row(label, value, colorKey, mono)
	local row = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = #self._rows + 1,
		Parent = self._card,
	}, { Utility.Padding(0, 0, 14, 14) })
	if #self._rows > 0 then
		local line = Create("Frame", {
			Size = UDim2.new(1, 28, 0, 1),
			Position = UDim2.fromOffset(-14, 0),
			BackgroundTransparency = 0.95,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = row,
		})
		line.Name = "Divider"
	end
	Builders.Label({
		Text = label,
		TextSize = 13,
		ThemeColor = "SubText",
		Size = UDim2.fromScale(0.4, 1),
		Parent = row,
	})
	Builders.Label({
		Text = tostring(value),
		ThemeColor = colorKey or "Text",
		Font = mono and Fonts.Mono or Fonts.Bold,
		TextSize = 13,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.6, 1),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	table.insert(self._rows, row)
end

--[[
	info = {
		Plan = "Premium", Expires = <unix> | "text" | true (lifetime),
		User = "name", Details = { { "Label", "Value" }, ... },
	}
]]
function SuccessView:Show(info, maskedKey)
	info = type(info) == "table" and info or {}
	for _, row in ipairs(self._rows) do
		row:Destroy()
	end
	table.clear(self._rows)

	local player = Services.LocalPlayer
	local name = info.User or (player and player.DisplayName) or "there"
	self._welcome.Text = "Welcome back, " .. name

	self:_row("Plan", info.Plan or "Licensed", "Accent")
	local expiry = SuccessView.FormatExpiry(info.Expires)
	if expiry then
		self:_row("Expires", expiry)
	end
	for _, pair in ipairs(info.Details or {}) do
		self:_row(tostring(pair[1]), tostring(pair[2]))
	end
	if maskedKey and maskedKey ~= "" then
		self:_row("Key", maskedKey, nil, true)
	end

	self.Instance.Visible = true
	self._fill.Size = UDim2.fromScale(0, 1)
	self._badgeScale.Scale = 0.6
	Tween(self._badgeScale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
end

function SuccessView:Hide()
	self.Instance.Visible = false
end

-- Animates the bar, then calls onDone. Returns a cancel function.
function SuccessView:Launch(seconds, label, onDone)
	seconds = math.max(0.2, seconds or 1.6)
	local cancelled = false
	self._launchLabel.Text = label or "Loading..."
	self._launchPct.Text = ""
	self._fill.Size = UDim2.fromScale(0, 1)
	Tween(self._fill, { Size = UDim2.fromScale(1, 1) }, seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	task.delay(seconds, function()
		if cancelled then
			return
		end
		self._launchLabel.Text = "Ready"
		self._launchPct.Text = "100%"
		task.wait(0.35)
		if not cancelled and onDone then
			onDone()
		end
	end)

	return function()
		cancelled = true
	end
end

return SuccessView
