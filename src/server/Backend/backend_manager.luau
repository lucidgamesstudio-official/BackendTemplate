-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local replica = require(ReplicatedStorage.Packages.replica)
local types = require(ReplicatedStorage.Shared.types)
local utility = require(ReplicatedStorage.Shared.utility)
local backend_template = require(script.Parent.backend_template)
local profilestore = require(ServerScriptService.DevPackages.profilestore)

-- The containers
local PlayerDatasManager = {} -- Module object return
local Replicas: { [Player]: types.ReplicaServer<backend_template.PlayerDatas> } = {} -- Replica container

local DataStore = profilestore.New("PlayerData", backend_template) -- DataStore Table for players datas
local Profiles: { [Player]: typeof(DataStore:StartSessionAsync()) } = {} -- The players profile container

--[[
	The function to initialize the module.
]]
function PlayerDatasManager.Init()
	--[[ Initialize the events ]]
	local playerAddedConn = replica.NewReadyPlayer:Connect(PlayerDatasManager.HandlePlayer)
	local playerRemoveConn = replica.RemovingReadyPlayer:Connect(PlayerDatasManager.HandlePlayerDisconnect)
	local playerReadyConn = replica.NewReadyPlayer:Connect(PlayerDatasManager.PlayerReady)
	local playerUnreadyConn = replica.RemovingReadyPlayer:Connect(PlayerDatasManager.PlayerUnready)

	--[[ Clean the events ]]
	game.Close:Once(function(...)
		if playerAddedConn and playerAddedConn.IsConnected then
			playerAddedConn:Disconnect()
		end
		if playerRemoveConn and playerRemoveConn.IsConnected then
			playerRemoveConn:Disconnect()
		end
		if playerReadyConn and playerReadyConn.IsConnected then
			playerReadyConn:Disconnect()
		end
		if playerUnreadyConn and playerUnreadyConn.IsConnected then
			playerUnreadyConn:Disconnect()
		end
	end)
end

--[[
	Create user profile and replica
]]
function PlayerDatasManager.HandlePlayer(player: Player)
	-- Start player's session with his ID
	local profile = DataStore:StartSessionAsync(`{player.UserId}`, {
		-- Callback when player isn't there (should never happend)
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- If profile failed to load (should never happend)
	if not profile then
		utility.Warn(`Player: {player.Name} failed to load`, script.Name)
		player:Kick("Roblox failed to load your datas, please rejoin")
		return
	end

	profile:AddUserId(player.UserId) -- Add a user to profile updating
	profile:Reconcile() -- Reconcile user profile with template (if a key missing, the key is added)

	-- If profile is shut down
	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("You're session as expired, please rejoin")
		return
	end)

	-- Last verify before replica (must do it because web things can always go wrong)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	Profiles[player] = profile -- Simply add the profile in profile container

	-- Replica
	local Token = replica.Token(`player_{player.UserId}`)
	local Replica = replica.New({
		Data = profile.Data,
		Token = Token,
	})

	-- Clear datas for player (only on studio, change true to false if you want to test the persistence of datas)
	if RunService:IsStudio() and true then
		Replica:Set({ "Inventory" }, {})
		Replica:Set({ "Money" }, 0)
		Replica:Set({ "NPC_interact" }, {})
	end

	Replicas[player] = Replica -- Add replica to replica container

	-- Subscribe the player when his ready (you need to wait the player to be ready to subscribe him)
	if replica.ReadyPlayers[player] then
		Replica:Subscribe(player)
	end
end

--[[
	End session on disconnect
]]
function PlayerDatasManager.HandlePlayerDisconnect(player: Player)
	-- Get player profile
	local profile = Profiles[player]
	if not profile then
		return
	end
	profile:EndSession()
end

--[[
	Subscribe player when ready
]]
function PlayerDatasManager.PlayerReady(player: Player)
	if Replicas[player] then
		Replicas[player]:Subscribe(player)
	end
end

--[[
	Unsubscribe on leaving
]]
function PlayerDatasManager.PlayerUnready(player: Player)
	if Replicas[player] then
		Replicas[player]:Unsubscribe(player)
	end
end

--[[
	@return Response withe player datas
	Useful for other modules server side
]]
function PlayerDatasManager.GetPlayerReplica(player: Player): types.Response<backend_template.PlayerDatas>
	local Replica = Replicas[player]
	if not Replica then
		return {
			Result = false,
			Error = `Replica not found for player: {player.Name}`,
		}
	end
	return {
		Result = true,
		Value = Replica,
		Message = "Replica found",
	}
end

return PlayerDatasManager
