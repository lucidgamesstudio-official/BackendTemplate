export type PlayerDatas = {
	Money: number,
	Inventory: {{
		ItemId: number?,
		Quantity: number?,
		Name: string?,
		Description: string?,
		IsATool: boolean?,
	}},
	NPC_interact: {{
		NPC_Id: number?,
		NPC_Name: string?,
		NPC_Interactions: number?,
	}},
}

local Template: PlayerDatas = {
	Money = 0,
	Inventory = {},
	NPC_interact = {},
}

return Template