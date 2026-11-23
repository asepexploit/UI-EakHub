--[[
	examples/KeySystem.lua
	License screen before the hub. Try EAKHUB-7A4B-28C1-9F3E (valid)
	or EAKHUB-0000-0000-0000 (expired).
]]

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/dist/EakUI.lua"))()

local Key = UI:KeySystem({
	Title = "EakHub",
	Prefix = "EAKHUB",

	Verify = function(key)
		-- Replace with your own backend, e.g.
		-- local response = game:HttpGet("https://api.example.com/check?key=" .. key)
		task.wait(0.5)
		if key == "EAKHUB-0000-0000-0000" then
			return false, "This key expired on 01 Nov 2026. Renew it to continue."
		end
		if key == "EAKHUB-7A4B-28C1-9F3E" then
			return true, { Plan = "Premium", Expires = os.time() + 29 * 86400 }
		end
		return false, "Invalid key. Check it and try again."
	end,

	Discord = "https://discord.gg/your-invite",
	GetKey = "https://your-key-site.example",
	Help = "Open a ticket in the EakHub Discord.",
})

local ok, info = Key:Wait()
if not ok then
	return -- closed without a valid key
end

local Window = UI:CreateWindow({ Title = "EakHub", Author = info.Plan })
local Tab = Window:Tab({ Title = "Main", Icon = "home" })
Tab:Paragraph({ Title = "Welcome", Content = "Your license is active." })
