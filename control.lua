--require("__flib__")
local modGui = require("mod-gui")


local function createGui(player)
    local screen_element = player.gui.screen
    if screen_element["shuttle-conductor-frame"] then return end
    local frame = screen_element.add{type = "frame", name = "shuttle-conductor-frame", caption = {"shuttle-conductor.name"}}
    frame.style.size = {385, 165}
    frame.auto_center = true
    frame.visible = false
end

local function isShuttle(train)
    local id = train.id
    if not global.data["shuttles"] then return false end --If it doesn't exist, then this is definitely not a shuttle.
    for _, shuttle in pairs(global.data["shuttles"]) do
        if shuttle.id == id then
            return true
        end
    end
    return false
end

local function addShuttle(train)
    if not global.data["shuttles"] then global.data["shuttles"] = {} end
    if(isShuttle(train)) then return end -- We definitely don't want to add the same shuttle twice.

    table.insert(global.data["shuttles"], train)
end

local function removeShuttle(train)
    if not global.data["shuttles"] then return end
    for i, shuttle in pairs(global.data["shuttles"]) do
        if shuttle.id == train.id then
            table.remove(global.data["shuttles"], i)
            return
        end
    end
end

---@param player LuaPlayer
local function updateStations(player)

    local playerID = player.index
    local s = player.surface.find_entities_filtered({name = "train-stop", force=player.force})

    if not global.data["players"][player.index]["stations"] then global.data["players"][player.index]["stations"] = {} end
    global.data["players"][player.index]["stations"] = s
    log("got stations")
end

---@param player LuaPlayer
local function getStationNames(player)
    local names = {}
    for _, station in pairs(global.data["players"][player.index]["stations"]) do
        table.insert(names, station.backer_name)
    end
    return names
end

---@param station LuaEntity
local function isDepot(station)
    for i, surface in pairs(game.surfaces) do
        for j, depot in pairs(global.data["depots"][surface.index]) do
            if depot.backer_name == station.backer_name then
                return true
            end
        end
    end
    return false
end

local function addDepot(depot)
    if isDepot(depot) then return end
    local surface = depot.surface_index
    if not global.data["depots"][surface] then global.data["depots"][surface] = {} end
    table.insert(global.data["depots"][surface], depot)
    log("added depot" .. depot.backer_name)
end

local function updateDepots()
    for i, surface in pairs(game.surfaces) do
        global.data["depots"][surface.index] = {}
        local stations = surface.find_entities_filtered({name = "train-stop"})
        for _, station in pairs(stations) do
            if string.find(station.backer_name:lower(), "depot") then --TODO: Make this a config option.
                addDepot(station)
            end
        end
    end
end

local function initData()
    global.data = global.data or {}

    if not global.data["shuttles"] then global.data["shuttles"] = {} end
    if not global.data["depots"] then global.data["depots"] = {} end
    if not global.data["players"] then global.data["players"] = {} end
end

script.on_init(function()
    initData()
end)

script.on_configuration_changed(function() --This will refresh the GUI whenever the mod is updated.
    log("[shuttle-conductor] configuration changed!")
    local players = game.players
    for _, player in pairs(players) do
        if player.gui.screen["shuttle-conductor-frame"] then player.gui.screen["shuttle-conductor-frame"].destroy() end
        if not global.data["players"][player.index] then global.data["players"][player.index] = {} end --This line probably only needs to exist for debugging.
        createGui(player)
    end

    initData()
end)

script.on_event(defines.events.on_player_created, function(event) --This initializes the UI for every new player.
    log("[shuttle-conductor] on_player_created run for " .. event.player_index)
    local player = game.get_player(event.player_index)
    if not player then
        log("[shuttle-conductor] player not found from index " .. event.player_index .." in on_player_created")
        return
    end

    if not global.data["players"][player.index] then global.data["players"][player.index] = {} end
    createGui(player)
end)

script.on_event(defines.events.on_train_schedule_changed, function(event) --This will handle adding or removing trains from the shuttle network.
    local train = event.train
    if event.player_index then 
    end
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event) --This code relates to when the player enters a shuttle.
    local player = game.get_player(event.player_index)
        if not player then return end
    local vehicle = player.vehicle
    local frame = player.gui.screen["shuttle-conductor-frame"]

    updateStations(player)

    if not vehicle then
        frame.visible = false
        return
    end

    if vehicle.type == "locomotive" then
        frame.visible = true
        addShuttle(vehicle.train)
        log("train added to shuttleTrains: " .. vehicle.train.id)
    end
    if vehicle.type == "cargo-wagon" then --THIS IS A DEBUG THAT SHOULD BE DISABLED IN RELEASES. IT LETS ME REFRESH THE GUI MANUALLY.
        if player.gui.screen["shuttle-conductor-frame"] then player.gui.screen["shuttle-conductor-frame"].destroy() end
        createGui(player)
        updateStations(player)
    end
end)

script.on_nth_tick(120, function() --This will track depots and shuttle destruction every two seconds.
    updateDepots()
end)