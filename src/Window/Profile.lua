--[[
	Window/Profile
	Sidebar footer with the local player's avatar, display name and username.

	Profile.new(parent, height) -> Frame
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Theme = import("Core/Theme")
local Builders = import("Core/Builders")
local Constants = import("Core/Constants")

local Create = Utility.Create
local Players = Services.Players

local Profile = {}

function Profile.new(parent, height)
	local player = Services.LocalPlayer

	local frame = Create("Frame", {
		Name = "Profile",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local divider = Create("Frame", {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 0, 1),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = frame,
	})
	Theme.Bind(divider, { BackgroundColor3 = "Stroke" })

	local avatar = Create("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 1),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 0.2,
		Image = "",
		Parent = frame,
	}, { Utility.Corner(999) })
	Theme.Bind(avatar, { BackgroundColor3 = "Element" })
	Builders.Stroke(0.8).Parent = avatar

	local names = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 48, 0.5, 1),
		Size = UDim2.new(1, -56, 0, 30),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { Utility.List(1, nil, nil, Enum.VerticalAlignment.Center) })

	Builders.Label({
		Text = player and player.DisplayName or "Player",
		Font = Constants.Fonts.Medium,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 14),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = names,
	})

	Builders.Label({
		Text = player and ("@" .. player.Name) or "",
		Font = Constants.Fonts.Regular,
		TextSize = 11,
		ThemeColor = "SubText",
		Size = UDim2.new(1, 0, 0, 13),
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 2,
		Parent = names,
	})

	if player then
		task.spawn(function()
			local ok, image = pcall(function()
				return Players:GetUserThumbnailAsync(
					player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				)
			end)
			if ok and avatar.Parent then
				avatar.Image = image
			end
		end)
	end

	return frame
end

return Profile
