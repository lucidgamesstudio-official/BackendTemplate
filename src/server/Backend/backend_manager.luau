-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local replica = require(ReplicatedStorage.Packages.replica)
local types = require(ReplicatedStorage.Shared.types)
local utility = require(ReplicatedStorage.Shared.utility)
local backend_template = require(script.Parent.backend_template)
local profilestore = require(ServerScriptService.DevPackages.profilestore)

local PlayerDatasManager = {}
local Replicas: { [Player]: types.ReplicaServer } = {}

local DataStore = profilestore.New("PlayerData", backend_template)

local Profiles: { [Player]: typeof(DataStore:StartSessionAsync()) } = {}

function PlayerDatasManager.Init()
	local playerAddedConn = replica.NewReadyPlayer:Connect(PlayerDatasManager.HandlePlayer)
	local playerRemoveConn = replica.RemovingReadyPlayer:Connect(PlayerDatasManager.HandlePlayerDisconnect)
	local playerReadyConn = replica.NewReadyPlayer:Connect(PlayerDatasManager.PlayerReady)
	local playerUnreadyConn = replica.RemovingReadyPlayer:Connect(PlayerDatasManager.PlayerUnready)
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

function PlayerDatasManager.HandlePlayer(player: Player)
	local profile = DataStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		utility.Warn(`Player: {player.Name} failed to load`, script.Name)
		player:Kick("Roblox failed to load your datas, please rejoin")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("You're session as expired, please rejoin")
		return
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	Profiles[player] = profile

	-- Replica
	local Token = replica.Token(`player_{player.UserId}`)
	local Replica = replica.New({
		Data = table.clone(profile.Data),
		Token = Token,
	})

	Replicas[player] = Replica

	if replica.ReadyPlayers[player] then
		Replica:Subscribe(player)
	end
end

function PlayerDatasManager.HandlePlayerDisconnect(player: Player)
	local profile = Profiles[player]
	if not profile then
		return
	end
	profile:EndSession()
end

function PlayerDatasManager.PlayerReady(player: Player)
	if Replicas[player] then
		Replicas[player]:Subscribe(player)
	end
end

function PlayerDatasManager.PlayerUnready(player: Player)
	if Replicas[player] then
		Replicas[player]:Unsubscribe(player)
	end
end

return PlayerDatasManager
