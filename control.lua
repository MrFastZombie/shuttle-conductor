--require("__flib__")
local gui = require("__shuttle-conductor__/gui")
local dispatch = require("__shuttle-conductor__/dispatch")
local datamanager = require("__shuttle-conductor__/data-manager")

---Adds a train to the shuttle list.
---@param train LuaTrain
local function addShuttle(train)
    local force = train.carriages[1].force_index
    local surface = train.carriages[1].surface_index
    if not storage.data["shuttles"] then storage.data["shuttles"] = {} end
    if(dispatch.isShuttle(train)) then return end -- We definitely don't want to add the same shuttle twice.

    if not storage.data["shuttles"][force] then storage.data["shuttles"][force] = {} end
    if not storage.data["shuttles"][force][surface] then storage.data["shuttles"][force][surface] = {} end
    
    if not storage.data["groups"] then storage.data["groups"] = {} end
    if not storage.data["groups"]["shuttles"] then storage.data["groups"]["shuttles"] = "shuttle depot" end
    --table.insert(storage.data["shuttles"][force][surface], train)
    storage.data["shuttles"][force][surface][train.id] = train --I think it's easier if the list index matches the train id.
end

local function removeShuttle(train)
    if not storage.data["shuttles"] then return end
    for i, shuttle in pairs(storage.data["shuttles"]) do
        if shuttle.id == train.id then
            table.remove(storage.data["shuttles"], i)
            return
        end
    end
end

---@param player LuaPlayer
local function updateStations(player)

    local playerID = player.index
    local s = player.surface.find_entities_filtered({name = "train-stop", force=player.force})

    if not storage.data["players"][player.index]["stations"] then storage.data["players"][player.index]["stations"] = {} end
    storage.data["players"][player.index]["stations"] = s
    log("got stations")
end

---@param player LuaPlayer
local function getStationNames(player)
    local names = {}
    for _, station in pairs(storage.data["players"][player.index]["stations"]) do
        table.insert(names, station.backer_name)
    end
    return names
end

---@param station LuaEntity
local function isDepot(station)
    for i, surface in pairs(game.surfaces) do
        for j, depot in pairs(storage.data["depots"][surface.index]) do
            if depot.backer_name == station.backer_name then
                return true
            end
        end
    end
    return false
end

---Sets the depot name for a particular group.
---@param depot LuaEntity
---@param group string
local function addDepot(depot, group)
    if isDepot(depot) then return end
    local surface = depot.surface_index
    if not storage.data["depots"][surface] then storage.data["depots"][surface] = {} end
    if not storage.data["depots"][surface][group] then storage.data["depots"][surface][group] = "" end
    --table.insert(storage.data["depots"][surface], depot)
    storage.data["depots"][surface][group] = depot
    log("added depot " .. depot.backer_name .. " to group " .. group) --TODO: Remove this later.
end

local function updateDepots()
    for i, surface in pairs(game.surfaces) do
        storage.data["depots"][surface.index] = {}
        local stations = surface.find_entities_filtered({name = "train-stop"})
        for _, station in pairs(stations) do
            if string.find(station.backer_name:lower(), "depot") then --TODO: Make this a config option.
                addDepot(station)
            end
        end
    end
end

script.on_init(function()
    datamanager.initData()
end)

script.on_configuration_changed(function() --This will refresh the GUI whenever the mod is updated.
    log("[shuttle-conductor] configuration changed!")
    local players = game.players
    for _, player in pairs(players) do
        gui.destroy(player)
        if not storage.data["players"][player.index] then storage.data["players"][player.index] = {} end --This line probably only needs to exist for debugging.
        gui.createGui(player)
    end

    datamanager.initData()
end)

script.on_event(defines.events.on_player_created, function(event) --This initializes the UI for every new player.
    log("[shuttle-conductor] on_player_created run for " .. event.player_index)
    local player = game.get_player(event.player_index)
    if not player then
        log("[shuttle-conductor] player not found from index " .. event.player_index .." in on_player_created")
        return
    end

    if not storage.data["players"][player.index] then storage.data["players"][player.index] = {} end
    gui.createGui(player)
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

    --updateStations(player)
    datamanager.updateStations(player)

    if not vehicle then
        frame.visible = false
        return
    end

    if vehicle.type == "locomotive" then
        frame.visible = true
        addShuttle(vehicle.train)
        storage.data["players"][player.index]["shuttle"] = vehicle.train --Tracking their selected shuttle.
        log("train added to shuttleTrains: " .. vehicle.train.id)
        datamanager.getShuttles(player, "shuttle depot")
        --gui.createMinimap(vehicle.train, player)
    end
    if vehicle.type == "cargo-wagon" then --THIS IS A DEBUG THAT SHOULD BE DISABLED IN RELEASES. IT LETS ME REFRESH THE GUI MANUALLY.
        gui.destroy(player)
        gui.createGui(player)
        datamanager.updateStations(player)
    end
end)

script.on_nth_tick(120, function() --This will track depots and shuttle destruction every two seconds.
    --updateDepots()
end)

script.on_event(defines.events.on_gui_click, function(event)
    gui.onClick(event)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    if event.element.name == "shuttle-conductor-textfield" then
        gui.onSearch(event)
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function (event)
end)

script.on_event(defines.events.on_train_changed_state, function (event)
    if event.train.state == defines.train_state.wait_station then
        log("train changed state!")
    end
end)

script.on_event("shuttle-conductor-summon", function(event)
    if event.selected_prototype then
        local player = game.get_player(event.player_index)
        local trainColor = nil
        local rail = nil
        if(player == nil) then return end

        if string.find(event.selected_prototype.name, "locomotive") then
            local locomotive = player.selected
            if locomotive == nil then return end
            local train = locomotive.train
            if train == nil then return end
            if locomotive.color == nil then trainColor = "red"
            else trainColor = locomotive.color.r..","..locomotive.color.g..","..locomotive.color.b end
            if dispatch.isShuttle(train) then
                dispatch.returnToDepot(train)
                player.create_local_flying_text({text={"shuttle-conductor.summon-return", trainColor, train.id}, position={event.cursor_position.x, event.cursor_position.y}})
            else
                player.create_local_flying_text({text={"shuttle-conductor.dispatch-not-shuttle"}, position={event.cursor_position.x, event.cursor_position.y}})
            end
            return
        end
        if string.find(event.selected_prototype.name, "support") then return end
        if string.find(event.selected_prototype.name, "rail") and not string.find(event.selected_prototype.name, "railgun") and not string.find(event.selected_prototype.name, "signal") then
            rail = player.selected
        end
        if rail == nil then return end
        local train = storage.data["players"][player.index]["shuttle"]
        if(train == nil) then return end
        local locomotive = datamanager.getLocomotive(train)
        if locomotive.color == nil then trainColor = "red"
        else trainColor = locomotive.color.r..","..locomotive.color.g..","..locomotive.color.b end
        dispatch.sendToRail(train, rail, player)
        player.create_local_flying_text({text={"shuttle-conductor.summon-success", trainColor, train.id}, position={event.cursor_position.x, event.cursor_position.y}})
    end
end)