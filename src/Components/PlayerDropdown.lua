--[[
	Components/PlayerDropdown
	Dropdown of players in the server that updates as players join / leave.
	Built on Components/Dropdown; callbacks receive Player instances.

	local target = Tab:PlayerDropdown({
		Title        = "Target",
		ExcludeLocal = true,          -- hide yourself (default true)
		Format       = "Both",        -- "Both" = "DisplayName (@Name)", "Name", "DisplayName"
		Multi        = false,
		Placeholder  = "Select player...",
		Flag         = "Target",
		Callback     = function(player) end,  -- Player (or { Player } when Multi), nil if cleared
	})
	target:GetPlayer() -> Player? (or { Player })
	target:Set(player) / target:Refresh()
]]

local import = ...
local Services = import("Core/Services")
local Utility = import("Core/Utility")
local Element = import("Components/Element")
local Dropdown = import("Components/Dropdown")

local Players = Services.Players

return function(tab, options)
	options = options or {}
	local multi = options.Multi or false
	local labelToPlayer = {}

	local function labelOf(player)
		if options.Format == "Name" then
			return player.Name
		elseif options.Format == "DisplayName" then
			return player.DisplayName
		end
		if player.DisplayName == player.Name then
			return player.Name
		end
		return string.format("%s (@%s)", player.DisplayName, player.Name)
	end

	local function collect(leaving)
		labelToPlayer = {}
		local labels = {}
		for _, player in ipairs(Players:GetPlayers()) do
			local excluded = player == leaving
				or (options.ExcludeLocal ~= false and player == Services.LocalPlayer)
			if not excluded then
				local label = labelOf(player)
				labelToPlayer[label] = player
				table.insert(labels, label)
			end
		end
		table.sort(labels, function(a, b)
			return string.lower(a) < string.lower(b)
		end)
		return labels
	end

	local function toPlayers(value)
		if multi then
			local list = {}
			for _, label in ipairs(value or {}) do
				local player = labelToPlayer[label]
				if player then
					table.insert(list, player)
				end
			end
			return list
		end
		return value ~= nil and labelToPlayer[value] or nil
	end

	local function toLabels(value)
		if typeof(value) == "Instance" then
			return labelOf(value)
		end
		if multi and type(value) == "table" then
			local labels = {}
			for _, entry in ipairs(value) do
				table.insert(labels, typeof(entry) == "Instance" and labelOf(entry) or entry)
			end
			return labels
		end
		return value
	end

	-- Build the underlying dropdown with label values
	local dropdownOptions = table.clone(options)
	dropdownOptions.Values = collect()
	dropdownOptions.Value = toLabels(options.Value or options.Default)
	dropdownOptions.Default = nil
	dropdownOptions.Placeholder = options.Placeholder or (multi and "None" or "Select player...")
	dropdownOptions.Flag = nil -- registered below on the wrapper
	dropdownOptions.Callback = function(value)
		Utility.SafeCall(options.Callback, toPlayers(value))
	end

	local element = Dropdown(tab, dropdownOptions)
	local baseSet = element.Set
	local baseRefresh = element.Refresh

	function element:GetPlayer()
		return toPlayers(element.Value)
	end

	function element:Set(value, silent)
		baseSet(element, toLabels(value), silent)
	end

	-- Rebuilds the list; keeps the selection when those players are still here
	function element:Refresh(leaving)
		local previous = element.Value
		local labels = collect(typeof(leaving) == "Instance" and leaving or nil)
		baseRefresh(element, labels, true)

		local changed = false
		if multi then
			local kept = {}
			for _, label in ipairs(previous or {}) do
				if labelToPlayer[label] then
					table.insert(kept, label)
				else
					changed = true
				end
			end
			if changed then
				baseSet(element, kept, true)
			end
		elseif previous ~= nil and not labelToPlayer[previous] then
			changed = true
			baseSet(element, nil, true)
		end

		if changed then
			Utility.SafeCall(options.Callback, toPlayers(element.Value))
		end
	end

	Utility.Track(Players.PlayerAdded:Connect(function()
		if element.Instance.Parent then
			element:Refresh()
		end
	end))
	Utility.Track(Players.PlayerRemoving:Connect(function(player)
		if element.Instance.Parent then
			element:Refresh(player)
		end
	end))

	Element.RegisterFlag(options, element)
	return element
end
