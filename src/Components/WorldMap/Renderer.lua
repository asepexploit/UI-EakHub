--[[
	Components/WorldMap/Renderer
	Draws a snapshot into a Frame using as few Instances as possible:
	each row's equal neighbouring tiles are merged into one Frame ("run"),
	frames are pooled per row, and rows whose content did not change since
	the last draw are left alone.

	local renderer = Renderer.new(canvas, palette)
	renderer:Draw(snap, { Layer = "fg" | "bg", Filter = id | nil, Cell = 5 })
	renderer:Clear()
]]

local Renderer = {}
Renderer.__index = Renderer

local GRASS = Color3.fromRGB(76, 175, 80)
local DIM = 0.82 -- transparency of tiles outside the highlight filter
local GHOST = 0.84 -- transparency of fg while viewing the bg layer

local Z = { fg = 2, cap = 3, bg = 4 }

function Renderer.new(canvas, palette)
	local self = setmetatable({}, Renderer)
	self.Canvas = canvas
	self.Palette = palette
	self._pools = {} -- [kind .. row] = { frames }
	self._sigs = {} -- [kind .. row] = signature of what is drawn
	self._mode = nil
	return self
end

function Renderer:_pool(key)
	local pool = self._pools[key]
	if not pool then
		pool = {}
		self._pools[key] = pool
	end
	return pool
end

function Renderer:_frame(pool, index, zIndex)
	local frame = pool[index]
	if not frame then
		frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Active = false
		frame.ZIndex = zIndex
		frame.Parent = self.Canvas
		pool[index] = frame
	end
	frame.Visible = true
	return frame
end

-- runs: array of { c0, c1, id }; drawn at row with height h (cap rows are thinner)
function Renderer:_drawRow(kind, row, runs, cell, opts)
	local key = kind .. row
	local pool = self:_pool(key)
	local filter = opts.Filter
	local base = opts.Base or 0
	local height = opts.Height or cell

	for index, run in ipairs(runs) do
		local frame = self:_frame(pool, index, Z[kind])
		local c0, c1, id = run[1], run[2], run[3]
		frame.Position = UDim2.fromOffset((c0 - 1) * cell, (row - 1) * cell)
		frame.Size = UDim2.fromOffset((c1 - c0 + 1) * cell, height)
		frame.BackgroundColor3 = kind == "cap" and GRASS or self.Palette:Color(id)
		local dimmed = filter ~= nil and id ~= filter
		local transparency = base
		if dimmed then
			transparency = math.max(transparency, DIM)
		end
		frame.BackgroundTransparency = transparency
	end
	for index = #runs + 1, #pool do
		pool[index].Visible = false
	end
end

local function rowRuns(line, W)
	local runs = {}
	local col = 1
	while col <= W do
		local id = line[col] or 0
		local stop = col
		while stop < W and (line[stop + 1] or 0) == id do
			stop += 1
		end
		if id ~= 0 then
			table.insert(runs, { col, stop, id })
		end
		col = stop + 1
	end
	return runs
end

-- Exposed grass tiles (air above) merged into thin strips
function Renderer:_capRuns(snap, row)
	local runs = {}
	if row < 2 then
		return runs
	end
	local line, above = snap.fg[row], snap.fg[row - 1]
	local col = 1
	while col <= snap.W do
		if self.Palette:HasGrass(line[col]) and above[col] == 0 then
			local stop = col
			while stop < snap.W and self.Palette:HasGrass(line[stop + 1]) and above[stop + 1] == 0 do
				stop += 1
			end
			table.insert(runs, { col, stop, line[col] })
			col = stop + 1
		else
			col += 1
		end
	end
	return runs
end

function Renderer:Draw(snap, opts)
	if not snap then
		return
	end
	local cell = opts.Cell
	local layer = opts.Layer == "bg" and "bg" or "fg"
	local filter = opts.Filter
	local mode = table.concat({ layer, tostring(filter), cell, snap.W, snap.H }, "|")
	local force = mode ~= self._mode
	self._mode = mode

	local fgBase = layer == "bg" and GHOST or 0
	local fgFilter = layer == "fg" and filter or nil
	local capHeight = math.max(1, math.floor(cell * 0.32 + 0.5))

	for row = 1, snap.H do
		local fgKey = snap.RowKeys.fg[row]
		if force or self._sigs["fg" .. row] ~= fgKey then
			self._sigs["fg" .. row] = fgKey
			self:_drawRow("fg", row, rowRuns(snap.fg[row], snap.W), cell, { Filter = fgFilter, Base = fgBase })
		end

		local capKey = fgKey .. "|" .. (snap.RowKeys.fg[row - 1] or "")
		if force or self._sigs["cap" .. row] ~= capKey then
			self._sigs["cap" .. row] = capKey
			local runs = layer == "fg" and self:_capRuns(snap, row) or {}
			self:_drawRow("cap", row, runs, cell, { Filter = fgFilter, Height = capHeight })
		end

		local bgKey = layer == "bg" and snap.RowKeys.bg[row] or ""
		if force or self._sigs["bg" .. row] ~= bgKey then
			self._sigs["bg" .. row] = bgKey
			local runs = layer == "bg" and rowRuns(snap.bg[row], snap.W) or {}
			self:_drawRow("bg", row, runs, cell, { Filter = filter })
		end
	end

	-- Rows beyond a smaller new world
	for key, pool in pairs(self._pools) do
		local row = tonumber(string.match(key, "%d+$"))
		if row and row > snap.H then
			for _, frame in ipairs(pool) do
				frame.Visible = false
			end
			self._sigs[key] = nil
		end
	end
end

function Renderer:Clear()
	for _, pool in pairs(self._pools) do
		for _, frame in ipairs(pool) do
			frame:Destroy()
		end
	end
	table.clear(self._pools)
	table.clear(self._sigs)
	self._mode = nil
end

return Renderer
