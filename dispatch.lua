--This file contains functions that direct shuttles to stations.
local dispatch = {}
local datamanager = require("__shuttle-conductor__/data-manager")

---Checks if a train is a shuttle.
---@param train LuaTrain The train to check.
---@return boolean
function dispatch.isShuttle(train)
    local id = train.id
    local force = train.carriages[1].force_index
    local surface = train.carriages[1].surface_index
    if not storage.data["shuttles"] then return false end --If it doesn't exist, then this is definitely not a shuttle.
    if not storage.data["shuttles"][force] then return false end
    if not storage.data["shuttles"][force][surface] then return false end

    for i, shuttle in pairs(storage.data["shuttles"][force][surface]) do
        if shuttle.valid == false then 
            storage.data["shuttles"][force][surface][i] = nil
            break
        end
        if shuttle.id == id then
            return true
        end
    end
    return false
end

---Sends a train to a station.
---@param train LuaTrain The train to send.
---@param stop string The name of the station to send the train to.
function dispatch.send(train, stop, player)
    local oldSchedule = train.schedule
    local schedule = {current = 2, records = { train.schedule.records[1], {station=stop, wait_conditions={{type="inactivity", ticks=7200}}}}}
    train.schedule = schedule
    train.manual_mode = false
end

---Sends a shuttle to a rail tile.
---@param train LuaTrain The train to sennd
---@param rail LuaEntity The rail tile to send the train to.
---@param player LuaPlayer The player who summoned the train.
function dispatch.sendToRail(train, rail, player)
    if rail == nil then return end
    local oldSchedule = train.schedule
    local schedule = {current = 2, records = { train.schedule.records[1], {rail=rail, temporary=true, wait_conditions={{type="inactivity", ticks=7200}}}}}
    train.schedule = schedule
    train.manual_mode = false
end

---Sends a shuttle back to its depot.
---@param train LuaTrain
function dispatch.returnToDepot(train)
    local id = train.id
    local schedule = {current = 1, records = { train.schedule.records[1]}}
    train.schedule = schedule
    train.manual_mode = false
end

--[[

script.on_event(defines.events.on_train_changed_state, function(event)
    local train = event.train
    if train.state == defines.train_state.arrive_station then
        
    end
end)--]]

return dispatch