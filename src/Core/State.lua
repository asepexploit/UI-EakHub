--[[
	Core/State
	Shared, mutable runtime state used by every module.
	Kept in one place so modules never hold their own copies.
]]

local State = {
	Version = "1.10.0",

	-- Public
	Flags = {},

	-- Theme
	ThemeName = "Dark",
	Theme = nil, -- active theme table (copy of a preset + overrides)
	ThemeObjects = {}, -- { instance, property, themeKey }
	ThemeCallbacks = {}, -- functions re-run on theme change

	-- Runtime
	Gui = nil, -- root ScreenGui
	NotifyHolder = nil,
	Connections = {},
	Windows = {},
}

return State
