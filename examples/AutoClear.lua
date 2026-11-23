--[[
	examples/AutoClear.lua
	EakHub "Auto Clear" screen built with EakUI 1.7 components:
	TaskCard (status + progress + Start/Stop), StatTiles, GroupBox settings,
	Slider ranges, Keybind, Checkbox list, KeyValue info and Swatches.

	Only the two functions in the GAME LOGIC section are game-specific.
	Replace their bodies with your own implementation; everything else is UI.
]]

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/dist/EakUI.lua"))()

---------------------------------------------------------------- GAME LOGIC (replace these)
-- Return a list of tiles to clear. The example just pretends there are 180.
local function findDirtTiles()
	local tiles = {}
	for i = 1, 180 do
		tiles[i] = i
	end
	return tiles
end

-- Break one tile. `hits` and `delay` come from the sliders below.
local function breakTile(tile, hits, delay)
	for _ = 1, hits do
		task.wait(delay / hits) -- placeholder for one punch
	end
end

---------------------------------------------------------------- WINDOW
local Window = UI:CreateWindow({
	Title = "EakHub",
	Author = "v1.0.0",
	Logo = "zap", -- replace with your logo id / URL
	Size = UDim2.fromOffset(600, 480),
	ToggleKey = Enum.KeyCode.RightShift,
})

---------------------------------------------------------------- AUTO CLEAR
local Clear = Window:Tab({
	Title = "Auto Clear",
	Icon = "block-break",
	Desc = "Automatically break every dirt tile in the world",
})

local Settings = {
	Hits = 25,
	Delay = 0.15,
	AutoCollect = true,
	Notify = true,
}

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local sweep = Clear:TaskCard({
	Unit = "tiles",
	StartText = "Start Sweep",
	StopText = "Stop Sweep",
	ResumeText = "Resume Sweep",
	AgainText = "Sweep Again",
	IdleText = "Press Start to scan the world and begin",
	PreparingText = "Scanning world for dirt tiles...",
	MiniStatus = "Clearing", -- minimized pill shows "Clearing · 45%"

	OnStart = function(job)
		job:SetStatus("preparing")
		local tiles = findDirtTiles()
		job:SetTotal(#tiles) -- switches the card to "running"

		UI:Notify({ Title = "Sweep started", Content = #tiles .. " dirt tiles found.", Icon = "play" })

		for _, tile in ipairs(tiles) do
			if not job:WaitIfPaused() then
				return -- reset or finished
			end
			breakTile(tile, Settings.Hits, Settings.Delay)
			job:Increment()
		end
	end,

	OnComplete = function(job)
		if Settings.Notify then
			local _, total = job:GetProgress()
			UI:Notify({
				Title = "Sweep complete",
				Content = total .. " tiles cleared in " .. formatTime(job:GetElapsed()) .. ".",
				Type = "Success",
			})
		end
	end,
})

local stats = Clear:StatTiles({
	Tiles = {
		{ Title = "Speed", Value = "—", Icon = "activity" },
		{ Title = "Remaining", Value = "—", Icon = "target", Color = Color3.fromRGB(56, 189, 248) },
		{ Title = "Time left", Value = "—", Icon = "clock", Color = Color3.fromRGB(251, 191, 36) },
	},
})

-- Refresh the stat tiles twice a second from the job's own numbers
task.spawn(function()
	while task.wait(0.5) do
		if not sweep.Instance.Parent then
			break -- window destroyed
		end
		local done, total = sweep:GetProgress()
		local elapsed = sweep:GetElapsed()
		local perSecond = elapsed > 1 and done / elapsed or 0

		stats:Set("Speed", perSecond > 0 and (math.floor(perSecond * 60) .. "/min") or "—")
		stats:Set("Remaining", total > 0 and tostring(total - done) or "—")
		stats:Set("Time left", (sweep:IsRunning() and perSecond > 0) and formatTime((total - done) / perSecond) or "—")
	end
end)

Clear:Section("Settings")
local box = Clear:GroupBox({ Title = "Sweep settings" })

box:Slider({
	Title = "Hits per tile",
	Desc = "Punches before moving to the next tile",
	Icon = "punch",
	Min = 1, Max = 50, Step = 1, Default = Settings.Hits, Suffix = "x",
	ShowRange = true,
	Callback = function(value)
		Settings.Hits = value
	end,
})

box:Slider({
	Title = "Punch delay",
	Desc = "Fast and usually safe",
	Icon = "clock",
	Min = 0.05, Max = 1, Step = 0.05, Default = Settings.Delay, Suffix = "s",
	ShowRange = true, MinLabel = "fast", MaxLabel = "safe",
	Callback = function(value)
		Settings.Delay = value
	end,
})

box:Toggle({
	Title = "Auto collect drops",
	Desc = "Pick up gems and seeds while clearing",
	Icon = "package",
	Value = Settings.AutoCollect,
	Callback = function(value)
		Settings.AutoCollect = value
	end,
})

box:Toggle({
	Title = "Notify when finished",
	Desc = "Show a notification when the world is clear",
	Icon = "bell",
	Value = Settings.Notify,
	Callback = function(value)
		Settings.Notify = value
	end,
})

box:Keybind({
	Title = "Sweep hotkey",
	Desc = "Start or stop without opening the hub",
	Icon = "keyboard",
	Value = Enum.KeyCode.F6,
	Callback = function()
		sweep:Toggle()
	end,
})

---------------------------------------------------------------- RECYCLE
local Recycle = Window:Tab({ Title = "Recycle", Icon = "recycle", Desc = "Trash unwanted items automatically while clearing" })
local recycleBox = Recycle:GroupBox({ Title = "Items to trash" })
for _, item in ipairs({ "Dirt Seed", "Rock", "Cave Background", "Lava", "Wooden Platform" }) do
	recycleBox:Checkbox({ Title = item, Value = item ~= "Cave Background" and item ~= "Wooden Platform" })
end

---------------------------------------------------------------- INFO
local Info = Window:Tab({ Title = "Info", Icon = "info", Desc = "About this hub" })
Info:KeyValue({
	Rows = {
		{ "Version", "1.0.0" },
		{ "UI library", "EakUI " .. UI.Version },
		{ "Toggle window", "RightShift" },
		{ "Sweep hotkey", "F6" },
	},
})

---------------------------------------------------------------- SETTINGS
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings", Desc = "Interface preferences" })
SettingsTab:Swatches({
	Title = "Accent color",
	Callback = function(color)
		UI:SetAccent(color)
	end,
})
SettingsTab:Button({
	Title = "Close EakHub",
	Icon = "power",
	Color = Color3.fromRGB(120, 30, 40),
	Callback = function()
		Window:Destroy()
	end,
})
