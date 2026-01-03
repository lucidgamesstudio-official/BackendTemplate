export type Item = {
	Quantity: number?,
	Price: number?,
	Name: string?,
	Description: string?,
	IsATool: boolean?,
}

export type PlayerDatas = {
	Money: number,
	Inventory: { [string]: { Item } },
	NPC_interact: {
		{
			NPC_Id: number?,
			NPC_Name: string?,
			NPC_Interactions: number?
		}
	},
}

local Template: PlayerDatas = {
	Money = 0,
	Inventory = {},
	NPC_interact = {},
}

return Template
