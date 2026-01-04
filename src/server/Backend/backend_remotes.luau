local module = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local backend_manager = require(script.Parent.backend_manager)
local backend_template = require(script.Parent.backend_template)
local types = require(ReplicatedStorage.Shared.types)
local utility = require(ReplicatedStorage.Shared.utility)

-- Linkers Folders
local _EVENT_FOLDER = utility.CreateFolder("RemoteEvents")
local FUNCTION_FOLDER = utility.CreateFolder("RemoteFunctions")
local _BIND_EVENT_FOLDER = utility.CreateFolder("BindableEvents")
local BIND_FUNCTION_FOLDER = utility.CreateFolder("BindableFunctions")

--============================================================================================
-- Helpers
--============================================================================================

--[[
    @param player: _Player_
    @return Replica of the player
    @error Kick the player out of the game and return Replica bad Response
]]
local function GetReplica(player: Player): types.Response<backend_template.PlayerDatas>
	local Response = backend_manager.GetPlayerReplica(player)
	if not Response.Result then
		utility.Warn(`{player.Name} have no session`, script.Name)
		player:Kick("Your session has expired, please rejoin.")
		return Response
	end
	return Response
end

--[[
    @param inventory: _{ Item }_
    @param item_id: _string_
    @return The item of the player in inventory, item_id must be a _string_.
]]
local function findItem(inventory: { [string]: backend_template.Item }, item_id: string): backend_template.Item?
	return inventory[item_id]
end

--============================================================================================
-- Remotes
--============================================================================================

--[[
    @param player: *Player*
    @param item_id: *string*
    @param _item: *Item*
    @return Response with good Result
    @error No inventory, player kick and Error: Inventory corrupt
]]
local function AddItem(player: Player, item_id: string, _item: backend_template.Item): types.Response<any>
	local Response = GetReplica(player)
	if not Response.Result then
		return Response
	end
	local Replica = Response.Value :: backend_template.PlayerDatas
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

--[[
    @param player: *Player*
    @return Response with *{ Item }* in Value
    @error Replica error Response when no replica found
]]
local function GetInventory(player: Player): types.Response<{ backend_template.Item }>
	local Response = GetReplica(player)
	if not Response.Result then
		return Response
	end
	local Replica = Response.Value :: backend_template.PlayerDatas
	local inventory = Replica.Data.Inventory
	return {
		Result = true,
		Value = inventory,
		Message = "Inventory found",
	}
end

--[[
    @param player: *Player*
    @param item_id: _string_
    @param quantity: _number_
    @param pricePerUnit: _number_
    @error Inventory: Result = `false`, Error = `"Inventory corrupt"`
    @error Item: Result = `false`, Error = `"Item not found"`
    @error Quantity 0: Result = `false`, Error = `"Nothing to sell"`
    @return Result = `true`, Value = { Earned: _number_, Remaining: _number_, Money: _number_}
]]
local function SellItem(player: Player, item_id: string, quantity: number, pricePerUnit: number): types.Response<any>
	local Response = GetReplica(player)
	if not Response.Result then
		return Response
	end
	local Replica = Response.Value :: backend_template.PlayerDatas
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

return module
