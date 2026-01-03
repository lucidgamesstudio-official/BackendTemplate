local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utility = require(ReplicatedStorage.Shared.utility)
local module = {}

for _, moduleScript in ipairs(script.Parent:GetChildren()) do
	if not moduleScript:IsA("ModuleScript") or moduleScript.Name == script.Name then
		continue
	end
	local item = require(moduleScript)
	local success, value = pcall(function(...)
		item.Load()
	end)
	if not success then
		utility.Error(`Error while calling {item.Name}: `, value)
	end
end

return module
