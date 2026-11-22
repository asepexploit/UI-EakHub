--[[
	Core/Draggable
	Mouse + touch dragging with a small threshold so clicks still register.

	local state = Draggable(handle, target)
	state.Moved -- true if the last press turned into a drag
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")

local UserInputService = Services.UserInputService
local DRAG_THRESHOLD = 4

return function(handle, target, onMove)
	local state = { Dragging = false, Moved = false }
	local dragStart, startPosition, dragInput

	Utility.Track(handle.InputBegan:Connect(function(input)
		if not Utility.IsClick(input) then
			return
		end
		state.Dragging = true
		state.Moved = false
		dragStart = input.Position
		startPosition = target.Position

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				state.Dragging = false
				connection:Disconnect()
			end
		end)
	end))

	Utility.Track(handle.InputChanged:Connect(function(input)
		if Utility.IsMove(input) then
			dragInput = input
		end
	end))

	Utility.Track(UserInputService.InputChanged:Connect(function(input)
		if not (state.Dragging and input == dragInput) then
			return
		end

		local delta = input.Position - dragStart
		if not state.Moved and Vector2.new(delta.X, delta.Y).Magnitude > DRAG_THRESHOLD then
			state.Moved = true
		end

		if state.Moved then
			local position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
			Utility.Tween(target, { Position = position }, 0.08, Enum.EasingStyle.Sine)
			if onMove then
				onMove(position)
			end
		end
	end))

	return state
end
