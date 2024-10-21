--This file contains functions that direct shuttles to stations.
local dispatch = {}

---Checks if a train is a shuttle.
---@param train LuaTrain The train to check.
---@return boolean
function dispatch.isShuttle(train)
    local id = train.id
    local force = train.carriages[1].force_index
    local surface = train.carriages[1].surface_index
    if not global.data["shuttles"] then return false end --If it doesn't exist, then this is definitely not a shuttle.
    if not global.data["shuttles"][force] then return false end
    if not global.data["shuttles"][force][surface] then return false end

    for i, shuttle in pairs(global.data["shuttles"][force][surface]) do
        if shuttle.valid == false then 
            global.data["shuttles"][force][surface][i] = nil
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
function dispatch.send(train, stop)
    local schedule = {current = 1, records = {{station=stop}}}
    train.schedule = schedule
    train.manual_mode = false
end

return dispatch