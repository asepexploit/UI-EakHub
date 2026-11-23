--[[
	Components/WorldMap/Scanner
	Reads the world into a plain snapshot. Knows nothing about UI.

	Data sources (pick one):
		World   = gs.world                    -- table with w, h, fg[row][col], bg[row][col]
		World   = function() return gs.world end  -- re-read every scan (world changes)
		GetTile = function(col, row, layer) return id end  -- layer "fg" | "bg"
		          with Width / Height or GetSize = function() return w, h end

	local scanner = Scanner.new(options)
	local snap = scanner:Scan()
	snap.W, snap.H
	snap.fg[row][col], snap.bg[row][col]   (always numbers, 0 = empty)
	snap.Counts.fg[id], snap.Counts.bg[id]
	snap.RowKeys.fg[row]                   (string signature, used to skip unchanged rows)
	snap.HasBackground                     (any non-empty bg tile)
]]

local Scanner = {}
Scanner.__index = Scanner

function Scanner.new(options)
	options = options or {}
	local self = setmetatable({}, Scanner)
	self.World = options.World
	self.GetTile = options.GetTile
	self.GetSize = options.GetSize
	self.Width = options.Width
	self.Height = options.Height
	return self
end

function Scanner:_world()
	local world = self.World
	if type(world) == "function" then
		local ok, result = pcall(world)
		world = ok and result or nil
	end
	return type(world) == "table" and world or nil
end

function Scanner:Size()
	local world = self:_world()
	if world then
		return tonumber(world.w or world.W or world.Width) or self.Width or 100,
			tonumber(world.h or world.H or world.Height) or self.Height or 60
	end
	if self.GetSize then
		local ok, w, h = pcall(self.GetSize)
		if ok and w and h then
			return w, h
		end
	end
	return self.Width or 100, self.Height or 60
end

local function readLayer(world, layer, row, col)
	local grid = world[layer]
	local line = grid and grid[row]
	local value = line and line[col]
	return tonumber(value) or 0
end

function Scanner:Scan()
	local W, H = self:Size()
	local world = self:_world()
	local getTile = self.GetTile

	local snap = {
		W = W,
		H = H,
		fg = table.create(H),
		bg = table.create(H),
		Counts = { fg = {}, bg = {} },
		RowKeys = { fg = table.create(H), bg = table.create(H) },
		HasBackground = false,
		Time = os.clock(),
	}

	local ok, err = pcall(function()
		for row = 1, H do
			local fgRow, bgRow = table.create(W), table.create(W)
			for col = 1, W do
				local f, b
				if world then
					f = readLayer(world, "fg", row, col)
					b = readLayer(world, "bg", row, col)
				elseif getTile then
					f = tonumber(getTile(col, row, "fg")) or 0
					b = tonumber(getTile(col, row, "bg")) or 0
				else
					f, b = 0, 0
				end
				fgRow[col], bgRow[col] = f, b
				snap.Counts.fg[f] = (snap.Counts.fg[f] or 0) + 1
				snap.Counts.bg[b] = (snap.Counts.bg[b] or 0) + 1
				if b ~= 0 then
					snap.HasBackground = true
				end
			end
			snap.fg[row], snap.bg[row] = fgRow, bgRow
			snap.RowKeys.fg[row] = table.concat(fgRow, ",")
			snap.RowKeys.bg[row] = table.concat(bgRow, ",")
		end
	end)

	if not ok then
		warn("[EakUI] WorldMap scan failed: " .. tostring(err))
		return nil
	end
	return snap
end

return Scanner
