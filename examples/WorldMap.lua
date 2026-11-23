--[[
	examples/WorldMap.lua
	Growblox world minimap. Needs an executor with filtergc.
]]

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/dist/EakUI.lua"))()

local gs = filtergc("table", { Keys = { "world", "hit", "invUI", "Sfx" } }, true)
if not gs then
	UI:Notify({ Title = "World map", Content = "Game state not found", Type = "Error" })
	return
end

local Window = UI:CreateWindow({ Title = "EakHub", Size = UDim2.fromOffset(640, 480) })
local Tab = Window:Tab({ Title = "World", Icon = "globe" })

local targets = {}

local map = Tab:WorldMap({
	Title = "World",
	Preset = "Growblox",
	World = function()
		return gs.world
	end,
	GetPlayer = function()
		return gs.px, gs.py
	end,
	ItemName = function(id)
		return gs.Items and gs.Items[id] and gs.Items[id].name
	end,
	Actions = {
		{
			Title = "Add target",
			Primary = true,
			Visible = function(tile)
				return tile.Fg ~= 0 and not tile.FgSkip
			end,
			Callback = function(tile)
				table.insert(targets, { Col = tile.Col, Row = tile.Row })
				UI:Notify({ Title = "Target added", Content = ("%s at %d, %d"):format(tile.FgName, tile.Col, tile.Row) })
			end,
		},
	},
})

Tab:Button({
	Title = "Show targets on map",
	Callback = function()
		map:SetMarkers(targets)
	end,
})

Tab:Button({
	Title = "Clear targets",
	Callback = function()
		table.clear(targets)
		map:SetMarkers({})
	end,
})
