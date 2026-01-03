local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local backend_template = require(ServerScriptService.Server.Backend.backend_template)
local utility = require(ReplicatedStorage.Shared.utility)
local module = {}

local BIND_FUNCTION_FOLDER = utility.CreateFolder("BindableFunctions")

local ITEM_ID = "1"
local BASE_ITEM: backend_template.Item = {
	Quantity = 1,
	Price = 2,
	Name = "Carrot",
	Description = "An orange carrot",
	IsATool = false,
}

export type Carrot = {
	Model: BasePart,

	_touchedConn: RBXScriptConnection,

	Destroy: (self: Carrot) -> (),
}

local Carrots = {}

function module.Load()
	local carrots = CollectionService:GetTagged("Carrot")
	for _, carrot in ipairs(carrots) do
		table.insert(Carrots, module.New(carrot))
	end
end

function module.New(carot: BasePart): Carrot
	local self: Carrot = {} :: Carrot

	self.Model = carot

	self._touchedConn = self.Model.Touched:Connect(function(hit: BasePart)
		local player = hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		utility.CreateBindableFunction("AddItem", BIND_FUNCTION_FOLDER):Invoke(player, ITEM_ID, BASE_ITEM)
		self.Model:Destroy()
		self._touchedConn:Disconnect()
		table.clear(self)
	end)

	return self
end

return module
