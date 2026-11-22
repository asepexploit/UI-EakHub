--[[
	Core/Constants
	Static values shared across components.
]]

local rgb = Color3.fromRGB

local Constants = {}

-- Background transparency levels for the glass look
Constants.Glass = {
	Main = 0.08,
	Sidebar = 0.35,
	Element = 0.3,
	Field = 0.15,
}

Constants.NotifyColors = {
	Success = rgb(34, 197, 94),
	Warning = rgb(234, 179, 8),
	Error = rgb(239, 68, 68),
}

Constants.Danger = rgb(239, 68, 68)

-- Drop shadow (9-slice)
Constants.Shadow = {
	Image = "rbxassetid://6014261993",
	SliceCenter = Rect.new(49, 49, 450, 450),
}

Constants.Fonts = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
	Black = Enum.Font.GothamBlack,
}

Constants.Window = {
	TopbarHeight = 46,
	SidebarWidth = 156,
	SearchHeight = 30,
	ProfileHeight = 50,
	DefaultSize = UDim2.fromOffset(560, 400),
	MinSize = Vector2.new(420, 300),
	ToggleKey = Enum.KeyCode.RightShift,
}

return Constants
