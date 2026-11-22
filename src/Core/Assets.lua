--[[
	Core/Assets
	Resolves any image source to something an ImageLabel can display.

	Accepted sources:
		123456 / "123456"                 -> rbxassetid://123456
		"rbxassetid://..." "rbxasset://..." "rbxthumb://..."  (used as-is)
		"https://example.com/logo.png"    -> downloaded once, cached to
		                                     workspace/EakUI/assets/, loaded with getcustomasset
		"EakUI/my_logo.png"               -> local file in the executor workspace
		"settings" / "map-pin" / "gear"   -> built-in icon (see Core/Icons, ICONS.md)

	URL, file and named-icon images need an executor with writefile / isfile /
	getcustomasset. Without them a warning is printed and the image stays empty.

	Assets.Apply(imageLabel, source)   -- async-safe, never yields the caller
	Assets.Resolve(source) -> string?  -- may yield while downloading
]]

local import = ...
local Icons = import("Core/Icons")

local Assets = {}

local ROOT = "EakUI"
local FOLDER = ROOT .. "/assets"
local VALID_EXTENSIONS = { png = true, jpg = true, jpeg = true }

local cache = {} -- [source] = resolved asset string
local pending = {} -- [source] = true while downloading

local function getCustomAsset()
	return getcustomasset or getsynasset
end

local function hasFileSystem()
	return writefile ~= nil and isfile ~= nil and getCustomAsset() ~= nil
end

local function ensureFolders()
	if not (isfolder and makefolder) then
		return
	end
	if not isfolder(ROOT) then
		makefolder(ROOT)
	end
	if not isfolder(FOLDER) then
		makefolder(FOLDER)
	end
end

-- djb2 string hash -> stable file name per URL
local function hash(text)
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 4294967296
	end
	return string.format("%08x", h)
end

local function extensionOf(url)
	local ext = string.match(string.lower(url), "%.(%a+)[%?#]") or string.match(string.lower(url), "%.(%a+)$")
	return VALID_EXTENSIONS[ext or ""] and ext or "png"
end

local function download(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 0 then
		return body
	end

	local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
	if requestFn then
		local success, response = pcall(requestFn, { Url = url, Method = "GET" })
		if success and response and response.Body and #response.Body > 0 then
			return response.Body
		end
	end
	return nil
end

local function loadFile(path)
	local ok, asset = pcall(getCustomAsset(), path)
	if ok and asset and asset ~= "" then
		return asset
	end
	return nil
end

-- Sources that can be used directly, without yielding
local function resolveInstant(source)
	if source == nil or source == "" then
		return nil, true
	end
	if type(source) == "number" or string.match(source, "^%d+$") then
		return "rbxassetid://" .. source, true
	end
	if string.match(source, "^rbx") then
		return source, true
	end
	if cache[source] then
		return cache[source], true
	end
	return nil, false
end

function Assets.Resolve(source)
	source = Icons.ToUrl(source) or source -- named icons become their hosted PNG URL
	local instant, done = resolveInstant(source)
	if done then
		return instant
	end

	if not hasFileSystem() then
		warn("[EakUI] This executor can't load custom images (needs writefile + getcustomasset): " .. tostring(source))
		return nil
	end

	-- another caller is already downloading this source
	while pending[source] do
		task.wait()
	end
	if cache[source] then
		return cache[source]
	end

	pending[source] = true
	local result

	if string.match(source, "^https?://") then
		ensureFolders()
		local path = FOLDER .. "/" .. hash(source) .. "." .. extensionOf(source)
		if not isfile(path) then
			local body = download(source)
			if body then
				writefile(path, body)
			else
				warn("[EakUI] Failed to download image: " .. source)
			end
		end
		if isfile(path) then
			result = loadFile(path)
		end
	elseif isfile(source) then
		result = loadFile(source)
	else
		warn("[EakUI] Image file not found: " .. source)
	end

	pending[source] = nil
	cache[source] = result
	return result
end

-- Sets instance[property] to the resolved image. URLs are fetched in the background.
function Assets.Apply(instance, source, property)
	property = property or "Image"
	source = Icons.ToUrl(source) or source
	local instant, done = resolveInstant(source)
	if done then
		instance[property] = instant or ""
		return
	end

	task.spawn(function()
		local resolved = Assets.Resolve(source)
		if resolved and instance.Parent then
			instance[property] = resolved
		end
	end)
end

-- Downloads images ahead of time (e.g. call once at script start)
function Assets.Preload(sources)
	for _, source in ipairs(sources) do
		task.spawn(Assets.Resolve, source)
	end
end

return Assets
