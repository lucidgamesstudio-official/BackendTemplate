local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local types = require(ReplicatedStorage.Shared.types)
local replica: types.ReplicaClient = require(ReplicatedStorage.Packages.replica)

replica.RequestData()

replica.OnNew(`player_{Players.LocalPlayer.UserId}`, function(replica: types.ReplicaClient)
	print(replica.Data)
	replica:OnChange(
		function(action: "Set" | "SetValues" | "TableInsert" | "TableRemove", path: { any }, param1, param2: any?) -- Called when replica is change on the server
			print(replica.Data)
		end
	)
end)
