--[[
	examples/Showcase.lua
	Every component, flags, theme switching and runtime updates.
]]

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/dist/EakUI.lua"))()
-- local UI = loadstring(readfile("EakUI.lua"))() -- local testing from the executor workspace

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = UI:CreateWindow({
	Title = "MyHub",
	Author = "v1.0",
	-- Images accept asset ids, https URLs or workspace files
	Logo = "https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/assets/logo.png",
	BrandLogo = "https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/assets/brand.png",
	BrandLogoSize = UDim2.fromOffset(110, 24),
	Size = UDim2.fromOffset(560, 400),
	MinSize = Vector2.new(420, 300),
	Theme = "Dark", -- Dark | Midnight | Rose | Emerald | Light
	ToggleKey = Enum.KeyCode.RightShift,
	ToggleButton = true,
})

---------------------------------------------------------------- Main
local Main = Window:Tab({
	Title = "Main",
	Icon = "home", -- built-in icon, see ICONS.md
	Desc = "Movement and player settings",
})

Main:Section("Player")

Main:Button({
	Title = "Click Me",
	Desc = "Fires a notification",
	Icon = "mouse-pointer",
	Callback = function()
		Window:Notify({ Title = "Clicked!", Content = "Button callback fired.", Duration = 3 })
	end,
})

Main:Button({
	Title = "Danger Button",
	Color = Color3.fromRGB(190, 40, 60),
	Callback = function()
		print("danger")
	end,
})

local enableToggle = Main:Toggle({
	Title = "Enable",
	Desc = "Turns the feature on/off",
	Value = false,
	Flag = "Enabled",
	Callback = function(value)
		print("Enabled:", value)
	end,
})

Main:Slider({
	Title = "WalkSpeed",
	Min = 16,
	Max = 200,
	Default = 16,
	Suffix = " studs",
	Flag = "WalkSpeed",
	Callback = function(value)
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end,
})

Main:Slider({ Title = "Precision", Min = 0, Max = 1, Step = 0.05, Default = 0.5, Callback = print })

Main:Divider()

Main:Keybind({
	Title = "Toggle feature",
	Desc = "Click the key, then press a new one",
	Value = Enum.KeyCode.F,
	Flag = "FeatureKey",
	Callback = function()
		enableToggle:Toggle()
	end,
	ChangedCallback = function(key)
		print("Rebound to", key and key.Name or "None")
	end,
})

---------------------------------------------------------------- Farm
local Farm = Window:Tab({ Title = "Farm", Icon = "grid", Desc = "Pick tiles around your character" })

Farm:Grid({
	Title = "ANCH Grid",
	Size = 5,
	Value = { Vector2.new(-1, -1), Vector2.new(0, -1), Vector2.new(1, -1), Vector2.new(-1, 0), Vector2.new(1, 0) },
	Modes = { "Farm", "Break", "Place" },
	ActionText = "Start {mode}",
	StopText = "Stop {mode}",
	Flag = "FarmTiles",
	Callback = function(tiles)
		print("Selected tiles:", #tiles)
	end,
	ActionCallback = function(running, tiles, mode)
		print(running and "Started" or "Stopped", mode, "on", #tiles, "tiles")
		for _, offset in ipairs(tiles) do
			-- offset.X: left(-)/right(+), offset.Y: up(-)/down(+), relative to the player tile
			print(" ", offset.X, offset.Y)
		end
	end,
})

---------------------------------------------------------------- Misc
local Misc = Window:Tab({ Title = "Misc", Icon = "package" })

Misc:Section("Input")

Misc:Input({
	Title = "Player Name",
	Placeholder = "Enter username...",
	Callback = function(text, enterPressed)
		print("Input:", text, enterPressed)
	end,
})

Misc:Input({ Title = "Amount", Placeholder = "0", Numeric = true, Live = true, Callback = print })

Misc:Section("Select")

local weaponDropdown = Misc:Dropdown({
	Title = "Weapon",
	Values = { "Sword", "Bow", "Staff", "Dagger", "Axe", "Spear", "Katana", "Crossbow", "Wand", "Scythe" }, -- >8: search box appears
	Value = "Sword",
	Flag = "Weapon",
	Callback = function(value)
		print("Weapon:", value)
	end,
})

Misc:Dropdown({
	Title = "Targets",
	Values = { "Players", "NPCs", "Bosses" },
	Multi = true,
	Value = { "NPCs" },
	Callback = function(list)
		print("Targets:", table.concat(list, ", "))
	end,
})

Misc:Paragraph({
	Title = "About",
	Desc = "EakUI is built entirely with Instance.new(). Press RightShift or the floating button to toggle.",
})

---------------------------------------------------------------- Settings
local Settings = Window:Tab({ Title = "Settings", Icon = "settings" })

Settings:Dropdown({
	Title = "Theme",
	Values = { "Dark", "Midnight", "Rose", "Emerald", "Light" },
	Value = "Dark",
	Callback = function(name)
		UI:SetTheme(name)
	end,
})

Settings:Button({
	Title = "Refresh weapon list",
	Callback = function()
		weaponDropdown:Refresh({ "Katana", "Crossbow", "Wand" })
	end,
})

Settings:Button({
	Title = "Read flags",
	Callback = function()
		enableToggle:Set(true)
		print("Enabled:", UI.Flags.Enabled.Value, "WalkSpeed:", UI.Flags.WalkSpeed.Value)
	end,
})

Settings:Button({
	Title = "Reset settings",
	Desc = "Opens a confirmation dialog",
	Callback = function()
		Window:Dialog({
			Title = "Reset all settings?",
			Content = "Toggles, sliders and keybinds go back to their defaults.",
			Buttons = {
				{ Title = "Cancel" },
				{
					Title = "Reset",
					Variant = "Primary",
					Callback = function()
						enableToggle:Set(false)
						UI:Notify({ Title = "Settings reset", Type = "Success", Duration = 3 })
					end,
				},
			},
		})
	end,
})

Settings:Button({
	Title = "Destroy UI",
	Color = Color3.fromRGB(120, 30, 40),
	Callback = function()
		Window:Destroy()
	end,
})

UI:Notify({
	Title = "MyHub loaded",
	Content = "Press RightShift to toggle the window.",
	Type = "Success",
	Duration = 5,
})
