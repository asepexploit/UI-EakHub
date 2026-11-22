--[[
	Components/Spinner
	Row with a title / description and an animated loading ring.

	local loading = Tab:Spinner({
		Title    = "Loading data",
		Desc     = "Fetching server list...",
		Spinning = true,               -- start immediately (default true)
	})
	loading:Stop() / loading:Start()
	loading:SetText("Still loading...")
	loading:SetDone("Loaded 24 servers")   -- shows a check mark and stops
]]

local import = ...
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Element = import("Components/Element")

local Create, Tween = Utility.Create, Utility.Tween
local RunService = game:GetService("RunService")

local SIZE = 20
local SPEED = 360 -- degrees per second

return function(tab, options)
	options = options or {}

	local element = Element.new(tab, options, {
		RightSize = UDim.new(0, SIZE + 4),
	})
	local holder = element.Instance

	local slot = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(SIZE, SIZE),
		BackgroundTransparency = 1,
		Parent = holder,
	})

	-- Ring: a stroke whose transparency fades around the circle
	local ring = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = slot,
	}, { Utility.Corner(999) })
	local ringStroke = Create("UIStroke", { Thickness = 2.5, Parent = ring })
	Theme.Bind(ringStroke, { Color = "Accent" })
	Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.75, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = ringStroke,
	})

	-- Check mark (two bars) shown by :SetDone
	local check = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = slot,
	})
	local short = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -4, 0.5, 2),
		Size = UDim2.fromOffset(7, 2.5),
		Rotation = 45,
		BorderSizePixel = 0,
		Parent = check,
	}, { Utility.Corner(2) })
	local long = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 2, 0.5, 0),
		Size = UDim2.fromOffset(12, 2.5),
		Rotation = -50,
		BorderSizePixel = 0,
		Parent = check,
	}, { Utility.Corner(2) })
	local successColor = Color3.fromRGB(34, 197, 94)
	short.BackgroundColor3 = successColor
	long.BackgroundColor3 = successColor

	local connection

	function element:Start()
		check.Visible = false
		ring.Visible = true
		if connection then
			return
		end
		connection = Utility.Track(RunService.Heartbeat:Connect(function(dt)
			if not ring.Parent then
				connection:Disconnect()
				connection = nil
				return
			end
			ring.Rotation = (ring.Rotation + SPEED * dt) % 360
		end))
	end

	function element:Stop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end

	function element:IsSpinning()
		return connection ~= nil
	end

	function element:SetText(text)
		element:SetDesc(text)
	end

	function element:SetDone(text)
		element:Stop()
		ring.Visible = false
		check.Visible = true
		local scale = check:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = check })
		scale.Scale = 0.6
		Tween(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		if text then
			element:SetDesc(text)
		end
	end

	if options.Spinning ~= false then
		element:Start()
	end
	return element
end
