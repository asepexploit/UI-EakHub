--[[
	KeySystem/Storage
	Remembers the last verified key in the executor workspace.
	Every call is wrapped in pcall: executors without a file system simply
	get "nothing saved" instead of an error.

	local store = Storage.new("EakHub/key.txt")
	store:Load()      --> "EAKHUB-..." | nil
	store:Save(key)
	store:Clear()
]]

local Storage = {}
Storage.__index = Storage

local function available()
	return type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function"
end

local function ensureFolder(path)
	if type(makefolder) ~= "function" or type(isfolder) ~= "function" then
		return
	end
	local current = ""
	local parts = string.split(path, "/")
	for index = 1, #parts - 1 do
		current = current == "" and parts[index] or (current .. "/" .. parts[index])
		if not isfolder(current) then
			makefolder(current)
		end
	end
end

function Storage.new(fileName)
	local self = setmetatable({}, Storage)
	self.Path = (fileName or "EakUI/key.txt"):gsub("\\", "/")
	return self
end

function Storage:Load()
	if not available() then
		return nil
	end
	local ok, content = pcall(function()
		if isfile(self.Path) then
			return readfile(self.Path)
		end
		return nil
	end)
	if not ok or type(content) ~= "string" then
		return nil
	end
	content = content:gsub("%s", "")
	return content ~= "" and content or nil
end

function Storage:Save(key)
	if not available() then
		return false
	end
	return (pcall(function()
		ensureFolder(self.Path)
		writefile(self.Path, key)
	end))
end

function Storage:Clear()
	if not available() then
		return
	end
	pcall(function()
		if type(delfile) == "function" and isfile(self.Path) then
			delfile(self.Path)
		else
			writefile(self.Path, "")
		end
	end)
end

return Storage
