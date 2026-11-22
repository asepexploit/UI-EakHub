--[[
	EakUI — custom UI library for Roblox script hubs
	100% Instance.new(), no external dependencies.

	Entry point. Exposes the public API only; implementation lives in
	Core/, Components/, Themes/ and Window/.

	local UI = loadstring(game:HttpGet("<raw url>/dist/EakUI.lua"))()
	local Window = UI:CreateWindow({ Title = "MyHub", Size = UDim2.fromOffset(500, 400), Theme = "Dark" })
]]

local import = ...
local State = import("Core/State")
local Theme = import("Core/Theme")
local Themes = import("Themes")
local Window = import("Window")
local Notify = import("Components/Notification")
local Assets = import("Core/Assets")

Theme.Ensure("Dark")

local EakUI = {
	Version = State.Version,
	Flags = State.Flags,
	Themes = Themes,
}

function EakUI:CreateWindow(config)
	return Window.new(config)
end

function EakUI:Notify(config)
	return Notify(config)
end

function EakUI:SetTheme(name, accent)
	Theme.Set(name, accent)
end

function EakUI:SetAccent(color)
	Theme.SetAccent(color)
end

-- Download URL images ahead of time so they appear instantly later
function EakUI:Preload(sources)
	Assets.Preload(sources)
end

-- Resolve any image source (id, URL, file) for use in your own ImageLabels
function EakUI:GetImage(source)
	return Assets.Resolve(source)
end

function EakUI:GetTheme()
	return State.ThemeName, State.Theme
end

function EakUI:Destroy()
	for _, window in ipairs(table.clone(State.Windows)) do
		pcall(function()
			window:Destroy()
		end)
	end
end

return EakUI
