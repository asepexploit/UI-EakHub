--[[
	Core/Icons
	Named built-in icons: Icon = "settings", "sword", "map-pin", ...

	Names map to white PNGs hosted in this repo (assets/icons/png/<name>.png),
	which Core/Assets downloads once, caches and tints at runtime.
	The list itself is generated into Core/IconList by tools/build_icons.py.

	Icons.Normalize("Map Pin")  -> "map-pin"   (case/space/underscore-insensitive, aliases applied)
	Icons.Has("gear")           -> true        (alias of "settings")
	Icons.ToUrl("settings")     -> "https://raw.githubusercontent.com/.../settings.png"
	Icons.SetBaseUrl(url)       -- host the PNGs yourself
	Icons.GetAll()              -> { { Name = "Interface", Icons = { ... } }, ... }
]]

local import = ...
local IconList = import("Core/IconList")

local DEFAULT_BASE_URL = "https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/assets/icons/png/"

local Icons = {}

local baseUrl = DEFAULT_BASE_URL
local known = {} -- [name] = true

for _, category in ipairs(IconList.Categories) do
	for _, name in ipairs(category.Icons) do
		known[name] = true
	end
end

-- Returns the canonical icon name, or nil when `source` is not an icon name.
-- Anything that looks like an id, URL or file path is never treated as an icon.
function Icons.Normalize(source)
	if type(source) ~= "string" or source == "" then
		return nil
	end
	if string.find(source, "[/:%.]") or string.match(source, "^%d+$") then
		return nil
	end

	local name = string.lower(source)
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	name = string.gsub(name, "[%s_]+", "-")

	if known[name] then
		return name
	end
	local alias = IconList.Aliases[name]
	if alias and known[alias] then
		return alias
	end
	return nil
end

function Icons.Has(source)
	return Icons.Normalize(source) ~= nil
end

function Icons.ToUrl(source)
	local name = Icons.Normalize(source)
	return name and (baseUrl .. name .. ".png") or nil
end

function Icons.SetBaseUrl(url)
	assert(type(url) == "string" and url ~= "", "SetIconBaseUrl expects a URL string")
	if string.sub(url, -1) ~= "/" then
		url = url .. "/"
	end
	baseUrl = url
end

function Icons.GetAll()
	local copy = {}
	for index, category in ipairs(IconList.Categories) do
		copy[index] = { Name = category.Name, Icons = table.clone(category.Icons) }
	end
	return copy
end

return Icons
