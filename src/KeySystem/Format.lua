--[[
	KeySystem/Format
	Pure helpers for license key formatting. No Instances, no side effects,
	so the rules can be reasoned about (and tested) on their own.

	local fmt = Format.new({ Prefix = "EAKHUB", Groups = 3, GroupSize = 4 })
	fmt:Apply("eakhub 7a4b28c1")  --> "EAKHUB-7A4B-28C1"
	fmt:Apply("7a4b")             --> "EAKHUB-7A4B"   (prefix is added for you)
	fmt:IsComplete("EAKHUB-7A4B-28C1-9F3E") --> true
	fmt:Count("EAKHUB-7A4B")      --> 4  (characters typed after the prefix)
	fmt.Placeholder               --> "EAKHUB-XXXX-XXXX-XXXX"

	Format = false in the KeySystem config gives a free-form formatter that
	only trims whitespace (for key providers with their own key shape).
]]

local Format = {}
Format.__index = Format

local function clean(text)
	return (string.upper(text or ""):gsub("[^A-Z0-9]", ""))
end

local function trim(text)
	return ((text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function Format.new(config)
	config = config or {}
	local self = setmetatable({}, Format)

	self.FreeForm = config.Format == false
	self.Prefix = clean(config.Prefix == nil and "EAKHUB" or config.Prefix)
	self.Groups = math.max(1, config.Groups or 3)
	self.GroupSize = math.max(1, config.GroupSize or 4)
	self.Length = self.Groups * self.GroupSize
	self.MaxLength = #self.Prefix + self.Length + self.Groups -- prefix + body + dashes

	if self.FreeForm then
		self.Placeholder = config.Placeholder or "Paste your key here"
	else
		local parts = {}
		if self.Prefix ~= "" then
			table.insert(parts, self.Prefix)
		end
		for _ = 1, self.Groups do
			table.insert(parts, string.rep("X", self.GroupSize))
		end
		self.Placeholder = config.Placeholder or table.concat(parts, "-")
	end
	return self
end

-- Characters after the prefix, without dashes
function Format:Body(text)
	local body = clean(text)
	local prefix = self.Prefix
	if prefix ~= "" and string.sub(body, 1, #prefix) == prefix then
		body = string.sub(body, #prefix + 1)
	end
	return body
end

function Format:Apply(raw)
	if self.FreeForm then
		return trim(raw)
	end

	local body = clean(raw)
	local prefix = self.Prefix

	if prefix ~= "" then
		if string.sub(body, 1, #prefix) == prefix then
			body = string.sub(body, #prefix + 1)
		elseif #body < #prefix and string.sub(prefix, 1, #body) == body then
			-- Still typing (or deleting) the prefix itself: leave it alone
			return body
		end
	end

	body = string.sub(body, 1, self.Length)
	if body == "" then
		return prefix -- no trailing dash, so backspace keeps working
	end

	local groups = {}
	for index = 1, #body, self.GroupSize do
		table.insert(groups, string.sub(body, index, index + self.GroupSize - 1))
	end

	local joined = table.concat(groups, "-")
	return prefix ~= "" and (prefix .. "-" .. joined) or joined
end

function Format:Count(text)
	if self.FreeForm then
		return #trim(text)
	end
	local cleaned = clean(text)
	local prefix = self.Prefix
	if #cleaned < #prefix and string.sub(prefix, 1, #cleaned) == cleaned then
		return 0 -- still typing the prefix
	end
	return #self:Body(text)
end

function Format:IsComplete(text)
	if self.FreeForm then
		return #trim(text) > 0
	end
	return self:Apply(text) == text and #self:Body(text) == self.Length
end

-- "EAKHUB-7A4B-••••-9F3E": safe to show on screen
function Format:Mask(text)
	text = text or ""
	if #text <= 8 then
		return text
	end
	if self.FreeForm or self.Groups < 3 then
		return string.sub(text, 1, 4) .. string.rep("•", 4) .. string.sub(text, -4)
	end
	local groups = string.split(text, "-")
	for index = 2, #groups - 1 do
		if index > (self.Prefix ~= "" and 2 or 1) then
			groups[index] = string.rep("•", #groups[index])
		end
	end
	return table.concat(groups, "-")
end

return Format
