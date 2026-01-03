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

-- Folders
local EVENT_FOLDER = utility.CreateFolder("RemoteEvents")
local FUNCTION_FOLDER = utility.CreateFolder("RemoteFunctions")
local BIND_EVENT_FOLDER = utility.CreateFolder("BindableEvents")
local BIND_FUNCTION_FOLDER = utility.CreateFolder("BindableFunctions")

local PlayerDatasManager = {}
local Replicas: { [Player]: types.ReplicaServer<backend_template.PlayerDatas> } = {}

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
		Data = profile.Data,
		Token = Token,
	})

	Replica:Set({ "Inventory" }, {})

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

--============================================================================================
-- Helpers
--============================================================================================

local function GetReplica(player: Player): types.ReplicaServer<{ backend_template.Item }>?
	local Replica = Replicas[player]
	if not Replica then
		utility.Warn(`{player.Name} have no session`, script.Name)
		player:Kick("Your session has expired, please rejoin.")
		return
	end
	return Replica
end

local function findItem(inventory: { [string]: backend_template.Item }, item_id: string): backend_template.Item?
	return inventory[item_id]
end

--============================================================================================
-- Remotes
--============================================================================================
local function AddItem(player: Player, item_id: string, _item: backend_template.Item): types.Response<any>
	local Replica = GetReplica(player)
	if not Replica then
		return {
			Result = false,
			Error = `Session expired`,
		}
	end
	local inventory = Replica.Data.Inventory
	if not inventory then
		utility.Warn(`{player.Name} have no inventory`, script.Name)
		player:Kick("Inventory is corrupt, please rejoin.")
		return {
			Result = false,
			Error = `Inventory corrupt`,
		}
	end
	local item = findItem(inventory, item_id)
	if not item then
		-- New item: store it by its item_id key instead of inserting into array part
		item = _item
		Replica:Set({ "Inventory", item_id }, item)
	else
		Replica:Set({ "Inventory", item_id, "Quantity" }, (item.Quantity or 0) + (_item.Quantity or 0))
	end
	return {
		Result = true,
		Message = `Add item {item.Name or "NA"} in inventory`,
	}
end

local function GetInventory(player: Player): types.Response<{ backend_template.Item }>
	local Replica = Replicas[player]
	if not Replica then
		utility.Warn(`{player.Name} have no session`, script.Name)
		player:Kick("Your session has expired, please rejoin.")
		return {
			Result = false,
			Error = `Session expired`,
		}
	end
	local inventory = Replica.Data.Inventory
	return {
		Result = true,
		Value = inventory,
		Message = "Inventory found",
	}
end

local function AddMoney(player: Player): types.Response<any>
	local Replica = GetReplica(player)
	if not Replica then
		return {
			Result = false,
			Error = `Session expired`,
		}
	end
	-- placeholder: amount should be provided by caller; keep function generic
	return {
		Result = true,
		Message = "AddMoney called",
	}
end

local function SellItem(player: Player, item_id: string, quantity: number, pricePerUnit: number): types.Response<any>
	local Replica = GetReplica(player)
	if not Replica then
		return {
			Result = false,
			Error = `Session expired`,
		}
	end

	local inventory = Replica.Data.Inventory
	if not inventory then
		return {
			Result = false,
			Error = `Inventory corrupt`,
		}
	end

	local item = findItem(inventory, item_id)
	if not item then
		return {
			Result = false,
			Error = `Item not found`,
		}
	end

	local sellQty = quantity or item.Quantity or 0
	sellQty = math.clamp(sellQty, 0, item.Quantity or 0)
	if sellQty <= 0 then
		return {
			Result = false,
			Error = `Nothing to sell`,
		}
	end

	local earned = sellQty * (pricePerUnit or 0)

	if (item.Quantity or 0) <= sellQty then
		-- remove the item entry
		Replica:Set({ "Inventory", item_id }, nil)
	else
		Replica:Set({ "Inventory", item_id, "Quantity" }, (item.Quantity or 0) - sellQty)
	end

	-- add money to player
	local newMoney = (Replica.Data.Money or 0) + earned
	Replica:Set({ "Money" }, newMoney)

	return {
		Result = true,
		Value = {
			Earned = earned,
			Remaining = Replica.Data.Inventory[item_id] and Replica.Data.Inventory[item_id].Quantity or 0,
			Money = newMoney,
		},
	}
end

utility.CreateRemoteFunction("AddItem", FUNCTION_FOLDER, function(player, item_id, item)
	if not player or not item or not item_id then
		return {
			Result = false,
			Error = "Arguments are invalid",
		}
	end
	return AddItem(player, item_id, item)
end)

utility.CreateBindableFunction("AddItem", BIND_FUNCTION_FOLDER, function(player, item_id, item)
	if not player or not item or not item_id then
		return {
			Result = false,
			Error = "Arguments are invalid",
		}
	end
	return AddItem(player, item_id, item)
end)

utility.CreateRemoteFunction("GetInventory", FUNCTION_FOLDER, function(player)
	if not player then
		return {
			Result = false,
			Error = "Arguments are invalid",
		}
	end
	return GetInventory(player)
end)

utility.CreateBindableFunction("GetInventory", BIND_FUNCTION_FOLDER, function(player)
	if not player then
		return {
			Result = false,
			Error = "Arguments are invalid",
		}
	end
	return GetInventory(player)
end)

utility.CreateBindableFunction("SellItem", BIND_FUNCTION_FOLDER, function(player, item_id, quantity, pricePerUnit)
	if not player or not item_id then
		return {
			Result = false,
			Error = "Arguments are invalid",
		}
	end
	return SellItem(player, item_id, quantity, pricePerUnit)
end)

utility.CreateRemoteFunction("SellItem", FUNCTION_FOLDER, function(player, item_id, quantity, pricePerUnit)
	if not player or not item_id then
		return {
			Result = false,
			Error = "Arguments are invalid",
		}
	end
	return SellItem(player, item_id, quantity, pricePerUnit)
end)

return PlayerDatasManager
