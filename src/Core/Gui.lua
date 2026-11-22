--[[
	Core/Gui
	Creates (once) the protected root ScreenGui all windows live in.
]]

local import = ...
local Services = import("Core/Services")
local State = import("Core/State")
local Utility = import("Core/Utility")

local Gui = {}

local function getEnvironment()
	return (getgenv and getgenv()) or _G
end

-- gethui() > CoreGui > PlayerGui
local function resolveParent()
	local ok, hidden = pcall(function()
		return gethui and gethui()
	end)
	if ok and hidden then
		return hidden
	end

	local probe = Instance.new("ScreenGui")
	local canUseCore = pcall(function()
		probe.Parent = Services.CoreGui
	end)
	probe:Destroy()
	if canUseCore then
		return Services.CoreGui
	end

	return Services.LocalPlayer:WaitForChild("PlayerGui")
end

function Gui.Get()
	if State.Gui and State.Gui.Parent then
		return State.Gui
	end

	-- Remove the UI from a previous execution
	local env = getEnvironment()
	if env.__EakUI_Gui then
		pcall(function()
			env.__EakUI_Gui:Destroy()
		end)
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = Utility.RandomName()
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.DisplayOrder = 9999

	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(screenGui)
		end
	end)
	screenGui.Parent = resolveParent()

	State.Gui = screenGui
	env.__EakUI_Gui = screenGui
	return screenGui
end

function Gui.Destroy()
	if State.Gui then
		State.Gui:Destroy()
	end
	State.Gui = nil
	State.NotifyHolder = nil
end

return Gui
