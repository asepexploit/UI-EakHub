--[[
	examples/Components.lua
	Tour of the v1.5 components: inputs, display, layout, badges and tooltips.
]]

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/dist/EakUI.lua"))()

local Window = UI:CreateWindow({
	Title = "MyHub",
	Author = "v1.5",
	Size = UDim2.fromOffset(600, 440),
})

---------------------------------------------------------------- Inputs
local Inputs = Window:Tab({ Title = "Inputs", Desc = "Every input component" })

Inputs:Checkbox({ Title = "Auto collect", Badge = "NEW", Tooltip = "Picks up drops automatically", Callback = print })
Inputs:Segmented({ Title = "Mode", Values = { "Farm", "Break", "Place" }, Value = "Farm", Callback = print })
Inputs:ColorPicker({ Title = "ESP color", Default = Color3.fromRGB(124, 92, 255), Transparency = 0, Callback = print })
Inputs:RangeSlider({ Title = "Distance", Min = 0, Max = 500, Default = { Min = 25, Max = 150 }, Suffix = "m", Callback = print })
Inputs:Stepper({ Title = "Amount", Min = 1, Max = 99, Default = 5, Callback = print })
Inputs:TextArea({ Title = "Whitelist", Placeholder = "One name per line", Lines = 4, MaxLength = 200, Callback = print })
Inputs:ButtonGroup({
	Buttons = {
		{ Title = "Save", Variant = "Primary", Callback = function() print("save") end },
		{ Title = "Load", Callback = function() print("load") end },
		{ Title = "Reset", Variant = "Danger", Callback = function() print("reset") end },
	},
})
Inputs:PlayerDropdown({
	Title = "Target",
	Callback = function(player)
		print("Target:", player and player.Name)
	end,
})
Inputs:List({
	Title = "Teleports",
	Items = {
		{ Title = "Spawn", Desc = "Starting area" },
		{ Title = "Shop", Desc = "Buy upgrades" },
		{ Title = "Boss Arena", Desc = "Level 50+" },
		"Secret Cave",
	},
	Callback = function(name)
		print("Teleport to", name)
	end,
})

---------------------------------------------------------------- Display
local Display = Window:Tab({ Title = "Display", Desc = "Read-only components" })

Display:Image({ Image = "rbxassetid://10723407389", Height = 120, Title = "Season 2", Desc = "New maps and bosses" })

local progress = Display:ProgressBar({ Title = "Farming", Value = 0, Max = 100 })
task.spawn(function()
	for i = 1, 100 do
		progress:Set(i)
		task.wait(0.05)
	end
end)

local spinner = Display:Spinner({ Title = "Loading data", Desc = "Fetching server info" })
task.delay(3, function()
	spinner:SetDone("Data loaded")
end)

Display:CodeBlock({ Title = "Discord", Code = "discord.gg/your-invite" })
Display:Paragraph({ Title = "Status", Desc = "All systems running", Badge = "ON" })

---------------------------------------------------------------- Layout
local Layout = Window:Tab({ Title = "Layout", Desc = "Containers hold any component" })

local combat = Layout:Collapsible({ Title = "Combat", Desc = "Click to collapse", Open = true })
combat:Toggle({ Title = "Kill Aura", Badge = "PREMIUM" })
combat:Slider({ Title = "Range", Min = 1, Max = 20, Default = 10 })

local columns = Layout:Columns({ Count = 2, Gap = 8 })
local movement = columns[1]:GroupBox({ Title = "Movement" })
movement:Toggle({ Title = "Fly" })
movement:Stepper({ Title = "Speed", Min = 1, Max = 10, Default = 3 })
local visuals = columns[2]:GroupBox({ Title = "Visuals" })
visuals:Checkbox({ Title = "Boxes" })
visuals:Checkbox({ Title = "Names", Value = true })

local sub = Layout:SubTabs({ Tabs = { "Aimbot", "ESP", "Misc" } })
sub:Get("Aimbot"):Toggle({ Title = "Enabled" })
sub:Get("ESP"):ColorPicker({ Title = "Color", Default = Color3.fromRGB(239, 68, 68) })
sub:Get("Misc"):Button({ Title = "Rejoin", Tooltip = "Reconnects to this server" })
