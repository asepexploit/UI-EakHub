--[[
	examples/Basic.lua
	Minimal setup — one window, one tab, three components.
]]

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/dist/EakUI.lua"))()

local Window = UI:CreateWindow({
	Title = "MyHub",
	Size = UDim2.fromOffset(500, 400),
	Theme = "Dark",
})

local Tab = Window:Tab({ Title = "Main", Icon = "rbxassetid://10723407389" })

Tab:Button({
	Title = "Click Me",
	Callback = function()
		UI:Notify({ Title = "Hello", Content = "Button clicked", Duration = 3 })
	end,
})

Tab:Toggle({
	Title = "Enable",
	Value = false,
	Callback = function(value)
		print("Enabled:", value)
	end,
})

Tab:Slider({
	Title = "Speed",
	Min = 1,
	Max = 100,
	Default = 50,
	Callback = function(value)
		print("Speed:", value)
	end,
})
