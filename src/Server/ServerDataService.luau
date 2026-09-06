--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v1.0")

local DataService = {}
DataService.__index = DataService

export type PlayerData = {
	Coins: number,
	Gems: number,
	Inventory: { string },
	PlayTime: number,
}

local DEFAULT_DATA: PlayerData = {
	Coins = 100,
	Gems = 0,
	Inventory = { "Starter_Sword" },
	PlayTime = 0,
}

local sessionData: { [number]: PlayerData } = {}
local saveDebounce: { [number]: boolean } = {}

local MAX_RETRIES = 3
local RETRY_DELAY = 2

local function deepCopy<T>(original: T): T
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for key, value in pairs(original :: any) do
		copy[key] = deepCopy(value)
	end
	return copy :: T
end

function DataService.InitPlayer(player: Player): PlayerData
	local userId = player.UserId
	local key = `Player_{userId}`
	local tries = 0
	local success, result

	repeat
		tries += 1
		success, result = pcall(function()
			return PlayerDataStore:GetAsync(key)
		end)
		if not success then
			task.wait(RETRY_DELAY)
		end
	until success or tries >= MAX_RETRIES

	if success and result then
		for k, v in pairs(DEFAULT_DATA) do
			if result[k] == nil then
				result[k] = type(v) == "table" and deepCopy(v) or v
			end
		end
		sessionData[userId] = result
	else
		if not success then
			warn(`[DataService] Data fetch timed out for {player.Name}. Applying fallback schema.`)
		end
		sessionData[userId] = deepCopy(DEFAULT_DATA)
	end

	return sessionData[userId]
end

function DataService.SavePlayer(player: Player): boolean
	local userId = player.UserId
	if not sessionData[userId] or saveDebounce[userId] then
		return false
	end

	saveDebounce[userId] = true
	local key = `Player_{userId}`
	local tries = 0
	local success, err

	repeat
		tries += 1
		success, err = pcall(function()
			PlayerDataStore:SetAsync(key, sessionData[userId])
		end)
		if not success then
			task.wait(RETRY_DELAY)
		end
	until success or tries >= MAX_RETRIES

	saveDebounce[userId] = nil
	if not success then
		warn(`[DataService] Failed saving payload for {player.Name}: {tostring(err)}`)
	end

	return success
end

function DataService.Get(player: Player): PlayerData?
	return sessionData[player.UserId]
end

function DataService.UpdateKey(player: Player, key: string, value: any)
	local data = sessionData[player.UserId]
	if data and data[key] ~= nil then
		data[key] = value
	end
end

Players.PlayerAdded:Connect(DataService.InitPlayer)

Players.PlayerRemoving:Connect(function(player)
	DataService.SavePlayer(player)
	sessionData[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			DataService.SavePlayer(player)
		end)
	end
end)

return DataService
