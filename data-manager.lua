-- This file will handle updating and reading runtime data for Shuttle Conductor.
local datamanager = {}

---Ensures the basic data structures exist.
function datamanager.initData()
    storage.data = storage.data or {}
    if not storage.data["shuttles"] then storage.data["shuttles"] = {} end --Data schema: shuttles -> force? -> surface?
    if not storage.data["depots"] then storage.data["depots"] = {} end --Also likely not needed.
    if not storage.data["players"] then storage.data["players"] = {} end
    if not storage.data["stations"] then storage.data["stations"] = {} end --Data schema: stations -> force -> surface
    if not storage.data["backernames"] then storage.data["backernames"] = {} end
end

---find all the stations that a player can access.
---@param player LuaPlayer
function datamanager.updateStations(player)
    local force = player.force_index
    local surface = player.surface_index

    if not storage.data["stations"] then storage.data["stations"] = {} end
    if not storage.data["stations"][force] then storage.data["stations"][force] = {} end
    if not storage.data["stations"][force][surface] then storage.data["stations"][force][surface] = {} end

    local s = player.surface.find_entities_filtered({name = "train-stop", force = player.force})
    storage.data["stations"][force][surface] = s
    log("Shuttle Conductor: Got stations for player " .. player.name .. " from force " .. player.force.name .. " with id " .. player.force_index .. " on surface " .. player.surface.name .. " with id " .. player.surface.index)
end

---Returns a list of the shuttles that are assigned to a particular depot.
---@param player LuaPlayer
---@param depotName string
---@return table {} A table containing shuttles assigned to the depot, or empty if none are found.
function datamanager.getShuttles(player, depotName)
    local stops = player.surface.find_entities_filtered({name = "train-stop", force=player.force})
    local depot = nil
    for _,v in pairs(stops) do 
        if v.backer_name == depotName then
            depot = v
            break
        end
    end --end for

    if depot == nil then return {} end
    return depot.get_train_stop_trains()
end

---Returns the first locomotive found in the train.
---@param train LuaTrain
function datamanager.getLocomotive(train)
    for _, locomotive in pairs(train.locomotives.front_movers) do
        if locomotive ~= nil then
            return locomotive
        end
    end

    for _, locomotive in pairs(train.locomotives.back_movers) do
        if locomotive ~= nil then
            return locomotive
        end
    end
end

---Sets the currently selected shuttle for a player.
---@param player LuaPlayer
---@param train LuaTrain
function datamanager.setShuttle(player, train)
    storage.data["players"][player.index]["shuttle"] = train
end

---Gets the currently selected shuttle for a player.
---@param player LuaPlayer
---@return LuaTrain|nil value LuaTrain if found, or nil if not found.
function datamanager.getShuttle(player)
    if storage.data["players"][player.index]["shuttle"] == nil then return nil end
    return storage.data["players"][player.index]["shuttle"]
end

---Gets a list of all the currently set names of Shuttle depots.
---@return table|nil
function datamanager.getDepots()
    if storage.data["groups"] == nil then return nil end
    return storage.data["groups"]
end

---Checks if a shuttle is still valid.
---@param train LuaTrain
---@return boolean
function datamanager.isShuttleValid(train)
    if train.valid == nil then return false end
    return train.valid
end

---Checks if a train is a shuttle.
---@param train LuaTrain
---@return boolean
function datamanager.isShuttle(train)
    local id = train.id
    local shuttles = storage.data["shuttles"]
    return true --TODO: Implement
end

---Migrates a shuttle when it is modified. (Actually just deselects it for now).
---@param train LuaTrain
function datamanager.migrateShuttle(train, oldID)
    local force = train.carriages[1].force_index
    for i, player in pairs(storage.data.players) do
        if player.shuttle ~= nil then
            if player.shuttle.valid == false then
                player.shuttle = nil
                local luaPlayer = game.get_player(i)
                if luaPlayer ~= nil then luaPlayer.print("[Shuttle Conductor] Your shuttle has been destroyed or modified and has been deselected.") end
            end
        end
    end
end

function datamanager.getTrainByID(id)
    return game.train_manager.get_train_by_id(id)
end

return datamanager