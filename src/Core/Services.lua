--[[
	Core/Services
	Cached Roblox services.
]]

local Players = game:GetService("Players")

return {
	Players = Players,
	TweenService = game:GetService("TweenService"),
	UserInputService = game:GetService("UserInputService"),
	HttpService = game:GetService("HttpService"),
	RunService = game:GetService("RunService"),
	CoreGui = game:GetService("CoreGui"),
	LocalPlayer = Players.LocalPlayer,
}
