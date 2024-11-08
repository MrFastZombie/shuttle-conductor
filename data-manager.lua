-- This file will handle updating and reading runtime data for Shuttle Conductor.
local datamanager = {}

---Ensures the basic data structures exist.
function datamanager.initData()
    storage.data = storage.data or {}
    if not storage.data["shuttles"] then storage.data["shuttles"] = {} end --Probably not needed.
    if not storage.data["depots"] then storage.data["depots"] = {} end --Also likely not needed.
    if not storage.data["players"] then storage.data["players"] = {} end
    if not storage.data["stations"] then storage.data["stations"] = {} end --Data schema: stations -> force -> surface
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

return datamanager