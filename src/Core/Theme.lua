--[[
	Core/Theme
	Theme registry: binds instance properties to theme keys so the whole UI
	can be re-themed live with a tween.
]]

local import = ...
local State = import("Core/State")
local Utility = import("Core/Utility")
local Themes = import("Themes")

local Theme = {}

function Theme.Get()
	return State.Theme
end

-- Theme.Bind(frame, { BackgroundColor3 = "Element" })
function Theme.Bind(instance, map)
	for property, key in pairs(map) do
		instance[property] = State.Theme[key]
		table.insert(State.ThemeObjects, { instance, property, key })
	end
	return instance
end

-- Registers a function re-run after every theme change (for state-driven colors)
function Theme.OnChange(callback)
	table.insert(State.ThemeCallbacks, callback)
	return callback
end

-- Makes sure a theme is active; optionally switches preset / accent
function Theme.Ensure(name, accent)
	if State.Theme and name == nil and accent == nil then
		return State.Theme
	end

	local resolved = (name and Themes[name]) and name or State.ThemeName
	State.ThemeName = resolved
	State.Theme = Utility.CopyTable(Themes[resolved] or Themes.Dark)
	if accent then
		State.Theme.Accent = accent
	end
	return State.Theme
end

local function refresh(filterKey)
	local alive = {}
	for _, entry in ipairs(State.ThemeObjects) do
		local instance, property, key = entry[1], entry[2], entry[3]
		if instance and instance.Parent then
			if not filterKey or key == filterKey then
				Utility.Tween(instance, { [property] = State.Theme[key] }, 0.3)
			end
			table.insert(alive, entry)
		end
	end
	State.ThemeObjects = alive

	for _, callback in ipairs(State.ThemeCallbacks) do
		pcall(callback)
	end
end

function Theme.Set(name, accent)
	if not Themes[name] then
		warn("[EakUI] Unknown theme: " .. tostring(name))
		return
	end
	State.ThemeName = name
	State.Theme = Utility.CopyTable(Themes[name])
	if accent then
		State.Theme.Accent = accent
	end
	refresh()
end

function Theme.SetAccent(color)
	State.Theme.Accent = color
	refresh("Accent")
end

function Theme.Reset()
	table.clear(State.ThemeObjects)
	table.clear(State.ThemeCallbacks)
end

return Theme
