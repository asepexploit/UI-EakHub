--[[
	Core/Utility
	Pure helpers: instance creation, tweening, layout objects, input checks.
	Nothing here depends on the active theme.
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")

local TweenService = Services.TweenService

local Utility = {}

function Utility.CopyTable(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

-- Registers a connection so it is cleaned up when the UI is destroyed
function Utility.Track(connection)
	table.insert(State.Connections, connection)
	return connection
end

function Utility.DisconnectAll()
	for _, connection in ipairs(State.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(State.Connections)
end

-- Instance.new with properties and children; Parent is applied last
function Utility.Create(className, properties, children)
	local instance = Instance.new(className)
	local parent

	for key, value in pairs(properties or {}) do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end

	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end

	if parent then
		instance.Parent = parent
	end
	return instance
end

function Utility.Tween(instance, goal, duration, style, direction)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

function Utility.Corner(radius)
	return Utility.Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function Utility.Padding(top, bottom, left, right)
	return Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
	})
end

function Utility.List(padding, direction, horizontal, vertical)
	return Utility.Create("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

-- Runs a user callback in its own thread; errors are logged, never thrown
function Utility.SafeCall(callback, ...)
	if type(callback) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(callback, table.unpack(args, 1, args.n))
		if not ok then
			warn("[EakUI] Callback error: " .. tostring(err))
		end
	end)
end

function Utility.IsClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Utility.IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

function Utility.GetViewport()
	local camera = workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

function Utility.RandomName()
	return (Services.HttpService:GenerateGUID(false):gsub("-", ""))
end

return Utility
