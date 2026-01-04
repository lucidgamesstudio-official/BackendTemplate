# BackendTemplate
*This is a template for backend architecture, actually, the best in my opinion, using new systems that are fully maintain*

## Stack use
- ![Rojo](https://img.shields.io/badge/Rojo-v7.5.1-blue?logo=roblox)
- ![Wally](https://img.shields.io/badge/Wally-enabled-green?logo=roblox)
- ![Selene](https://img.shields.io/badge/Linted%20with-Selene-purple?logo=lua)

## Description

The project is simple, it uses the `Replica` and `ProfileStore` modules which are powerful for backend/data manager

> Links to repo:
> - ![Replica](https://img.shields.io/badge/Powered%20by-Replica-blueviolet?logo=roblox)
> - ![ProfileStore](https://img.shields.io/badge/Using-ProfileStore-green?logo=roblox)

### Client side

There is only one file, just for init the Replica and make the client ready.

### Shared

There are 2 files:
- `types.luau`:
    - File with types, fix bad Replica typing and add some good types for backend
- `utility`:
    - File for useful functions, dont depend on any module, it can be use for anything

### Server

A bug part of the work is here, first, we have to initialize Backend (and also items which are use to test Backend)

- `init.server.luau`:
    - Initialize items and backend
- Backend
    - `backend_template.luau`: Just a template with types and one table which represents player Datas
    - `backend_remotes.luau`: File to create remotes to edit player Datas, like inventory, money, ...
    - `backend_manager.luau`: Create the backend by using `ProfileStore` and `Replica`
- Items
    - `init_items.luau`: Weird way to do it but initialize every items lol
    - `carrots.luau`: Item that can be take by any player and added in his inventory
    - `sell_zone.luau` Zone where any player can enter, when player enter, it sells every items in his inventory