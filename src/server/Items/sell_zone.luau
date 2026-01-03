local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local backend_template = require(ServerScriptService.Server.Backend.backend_template)
local types = require(ReplicatedStorage.Shared.types)
local utility = require(ReplicatedStorage.Shared.utility)
local module = {}

local BIND_FUNCTION_FOLDER = utility.CreateFolder("BindableFunctions")

function module.Load()
	local zone: BasePart = CollectionService:GetTagged("SellZone")[1]
	if not zone then
		utility.Error(`Wtf no zone found`, script.Name)
	end
	local event = zone.Touched:Connect(function(hit: BasePart)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		module.Sell(player)
	end)
	zone.Destroying:Once(function(...)
		if event then
			event:Disconnect()
		end
	end)
end

function module.Sell(player: Player)
	local inventory: types.Response<{ backend_template.Item }> =
		utility.CreateBindableFunction("GetInventory", BIND_FUNCTION_FOLDER):Invoke(player)
	if not inventory.Result then
		return
	end
	for id, item in pairs(inventory.Value :: { backend_template.Item }) do
		local quantity = item.Quantity or 0
		if quantity <= 0 then
			continue
		end

		local price = item.Price or 0
		local sellFn = utility.CreateBindableFunction("SellItem", BIND_FUNCTION_FOLDER)
		if not sellFn then
			warn("Sell function not available")
			continue
		end

		local result = sellFn:Invoke(player, id, quantity, price)
		if result and result.Result then
			print(
				string.format(
					"Player %s sold %d of %s for %d",
					player.Name,
					quantity,
					id,
					result.Value and result.Value.Earned or 0
				)
			)
		else
			warn("Sell failed for player", player.Name, id, result and result.Error)
		end
	end
end

return module
