local ReplicatedStorage = game:GetService("ReplicatedStorage")
local replica = require(ReplicatedStorage.Packages.replica)
local module = {}

export type MaidToken = {
	Destroy: (self: MaidToken) -> (),
	Cleanup: (self: MaidToken, ...any) -> (),
}

export type Maid = {
	IsActive: (self: Maid) -> boolean,
	Add: (self: Maid, object: any) -> MaidToken,
	Cleanup: (...any) -> (),
}

export type Connection = {
	Disconnect: (self: Connection) -> (),
	IsConnected: boolean,
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	FireUntil: (self: Signal<T...>, continue_callback: () -> boolean, T...) -> (),
}

export type ReplicaClient = {
	Tags: { [any]: any },
	Data: { [any]: any },
	Id: number,
	Token: string,
	Parent: ReplicaClient?,
	Children: { [ReplicaClient]: boolean? },
	BoundInstance: Instance?,
	OnClientEvent: { Connect: (self: any, listener: (...any) -> ()) -> { Disconnect: (self: any) -> () } },
	Maid: Maid,

	OnNew: (Token: string, listener: (replica: ReplicaClient) -> ()) -> Connection,
	FromId: (id: number) -> typeof(replica)?,
	OnSet: (self: any, path: {}, listener: () -> ()) -> Connection,
	OnWrite: (self: any, function_name: string, listener: (...any) -> ()) -> Connection,
	OnChange: (
		self: any,
		listener: (
			action: "Set" | "SetValues" | "TableInsert" | "TableRemove",
			path: { any },
			param1: any,
			param2: any?
		) -> ()
	) -> Connection,
	GetChild: (self: any, token: string) -> ReplicaClient?,
	FireServer: (self: any, ...any) -> (),
	UFireServer: (self: any, ...any) -> (),
	Identify: (self: any) -> string,
	IsActive: (self: any) -> boolean,

	RequestData: () -> (),
}

export type ReplicaServer<T> = {
	Tags: { [any]: any },
	Data: { [any]: T },
	Id: number,
	Token: string,
	Parent: ReplicaServer<T>?,
	Children: { [ReplicaServer<T>]: boolean? },
	BoundInstance: Instance?,
	OnServerEvent: { Connect: (self: any, listener: (Player, ...any) -> ()) -> { Disconnect: (self: any) -> () } },
	Maid: Maid,

	Set: (self: any, path: { string }, value: any) -> (),
	SetValues: (self: any, path: { string }, values: { [string]: any }) -> (),
	TableInsert: (self: any, path: { string }, value: any, index: number?) -> number,
	TableRemove: (self: any, path: { string }, index: number) -> any,
	Write: (self: any, function_name: string, ...any) -> ...any,
	FireClient: (self: any, player: Player, ...any) -> (),
	FireAllClients: (self: any, ...any) -> (),
	UFireClient: (self: any, player: Player, ...any) -> (),
	UFireAllClients: (self: any, ...any) -> (),
	SetParent: (self: any, new_parent: ReplicaServer<T>) -> (),
	BindToInstance: (self: any, instance: Instance) -> (),
	Replicate: (self: any) -> (),
	DontReplicate: (self: any) -> (),
	Subscribe: (self: any, player: Player) -> (),
	Unsubscribe: (self: any, player: Player) -> (),
	Identify: (self: any) -> string,
	IsActive: (self: any) -> boolean,
	Destroy: (self: any) -> (),
}

export type Response<T> = {
	Result: boolean,
	Value: T?,
	Message: string?,
	Error: string?,
}
 
return module
