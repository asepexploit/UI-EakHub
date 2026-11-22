--[[
	Themes
	Registry of theme presets. Add a new theme by creating Themes/<Name>.lua
	with the same keys as Dark.lua and listing it here.
]]

local import = ...

return {
	Dark = import("Themes/Dark"),
	Midnight = import("Themes/Midnight"),
	Rose = import("Themes/Rose"),
	Emerald = import("Themes/Emerald"),
	Light = import("Themes/Light"),
}
