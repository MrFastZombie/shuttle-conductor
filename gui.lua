-- all hope abandon ye who enter here --

--This file contains most of the code that pertains to creating and maintain the UI of this mod.
local gui = {}
local dispatch = require("__shuttle-conductor__/dispatch")
local datamanager = require("__shuttle-conductor__/data-manager")
local modGui = require("mod-gui")

---Creates the shuttle conductor GUI.
---@param player LuaPlayer
function gui.createGui(player)
    local screen_element = player.gui.screen
    local mButtonFlow = modGui.get_button_flow(player)

    if not mButtonFlow["shuttle-conductor-button"] then mButtonFlow.add{type="button", name="shuttle-conductor-button", style=modGui.button_style, tooltip="Shuttle Conductor", caption="SC"} end
    if screen_element["shuttle-conductor-frame"] then return end

    local frame = screen_element.add{type = "frame", name = "shuttle-conductor-frame", caption = {'shuttle-conductor.name'}, style="shuttle-conductor-main-frame"}
    local mainFlow = frame.add{type = "flow", name = "main-vflow", direction = "vertical", style="shuttle-conductor-main-vflow"}
    local iframe = mainFlow.add{type = "frame", name = "shuttle-conductor-iframe", style="inside_shallow_frame_with_padding"}
    local stationFlow = iframe.add{type = "flow", name = "station-vflow", direction = "vertical"}
    local controlFlow = stationFlow.add{type="flow", name = "control-hflow", direction="horizontal"}
    controlFlow.add{type="textfield", name="shuttle-conductor-textfield", text="", style="shuttle-conductor-search"}
    controlFlow.add{type="sprite-button", name="shuttle-button", sprite="entity/locomotive"}
    local buttoncontainer = stationFlow.add{type='frame', name="deep-button-container", style="shuttle-conductor-button-container"}
    local scrollframe = buttoncontainer.add{type="scroll-pane", name="station-scrollframe", style="shuttle-conductor-scroll-frame", vertical_scroll_policy="always", horizontal_scroll_policy="never"}
    local buttonflow = scrollframe.add{type="flow", name="buttonflow", direction="vertical"}
    --stationFlow.style.horizontally_stretchable = true
    frame.auto_center = true
    frame.visible = false
    gui.getStations(player)
end

---Destroys the shuttle conductor GUI so it can be recreated.
---@param player LuaPlayer
function gui.destroy(player)
    if player.gui.screen["shuttle-conductor-frame"] then player.gui.screen["shuttle-conductor-frame"].destroy() end
end

function gui.destroyMinimap(player)
    if player.gui.screen["shuttle-conductor-frame"]["main-vflow"]["shuttle-conductor-minimap-frame"] then player.gui.screen["shuttle-conductor-frame"]["main-vflow"]["shuttle-conductor-minimap-frame"].destroy() end
end

---Creates a minimap for a shuttle on the polyer's shuttletrain GUI.
---@param train LuaTrain
---@param player LuaPlayer
function gui.createMinimap(train, player)
    gui.destroyMinimap(player)
    local locomotive = datamanager.getLocomotive(train)
    local stopColor
    local trainColor
    local stop = train.path_end_stop
        if stop == nil or train.path_end_stop.color == nil then stopColor = "red"
        else stopColor = train.path_end_stop.color.r..","..train.path_end_stop.color.g..","..train.path_end_stop.color.b
        end
    if locomotive.color == nil then trainColor = "red"
    else trainColor = locomotive.color.r..","..locomotive.color.g..","..locomotive.color.b
    end
    if not stop then return end
    local screen_element = player.gui.screen
    local flow = screen_element["shuttle-conductor-frame"]["main-vflow"]
    local mapframe = flow.add{type="frame", name="shuttle-conductor-minimap-frame", style="inside_shallow_frame"}
    local mapFlow = mapframe.add{type="flow", name="shuttle-conductor-minimap-flow", direction="vertical"}
        mapFlow.style.vertical_spacing = 0
    local subheader = mapFlow.add{type="frame", name="minimap-subheader", style="subheader_frame"}
        local label = subheader.add{type="label", name="minimap-subheader-label", caption='[color='..trainColor..']Shuttle '..train.id..'[/color] has been dispatched to [color='..stopColor..']'..train.schedule.records[train.schedule.current].station.."[/color]"}
        label.style.width = 324
        subheader.add{type="sprite-button", name="minimap-close", style="close_button", sprite="utility/close_white"}
        subheader.style.horizontally_stretchable=true
        subheader.style.bottom_padding=0
        subheader.style.natural_width = 36
    mapframe.style.horizontally_stretchable=true
    mapframe.style.minimal_height = 128
    --local minimap = mapframe.add{type="minimap", name="shuttle-minimap", style="shuttle-conductor-minimap", position=train.carriages[1].position}
    local minimap = mapFlow.add{type="minimap", name="shuttle-minimap", style="shuttle-conductor-minimap", position=train.carriages[1].position}
    minimap.zoom=1.5
    minimap.entity = train.carriages[1]
end

---Clears the station list.
---@param player LuaPlayer
local function clearStations(player)
    local shuttleFlow = player.gui.screen["shuttle-conductor-frame"]["main-vflow"]["shuttle-conductor-iframe"]["station-vflow"]["deep-button-container"]
    --local shuttleFrame = shuttleFlow["deep-shuttle-frame"]
    local shuttleFrame = shuttleFlow["station-scrollframe"]
    if shuttleFrame then shuttleFrame.destroy() else return end
    shuttleFlow.add{type="scroll-pane", name="station-scrollframe", style="shuttle-conductor-scroll-frame"}.add{type="flow", name="buttonflow", direction="vertical"}
end

---Updates the station buttons for the player.
---@param player LuaPlayer
---@param search string Only creates buttons for stations that match the search value.
---@param filters table Hides any stations in the filter.
function gui.getStations(player, search, filters)
    local addedStations = {}
    search = search or ""
    filters = filters or {}
    datamanager.updateStations(player)
    clearStations(player)
    --local stations = storage.data["players"][player.index]["stations"]
    local stations = storage.data["stations"][player.force_index][player.surface_index]
    local stationFlow = player.gui.screen["shuttle-conductor-frame"]["main-vflow"]["shuttle-conductor-iframe"]["station-vflow"]["deep-button-container"]["station-scrollframe"]["buttonflow"]

    for i, station in pairs(stations) do
        if not addedStations[station.backer_name] then 
            if search == "" or string.find(string.lower(station.backer_name), string.lower(search)) then
                stationFlow.add{type="button", name="station-button-"..i, caption=station.backer_name, style="shuttle-conductor-station-button"}
                --table.insert(addedStations, station.backer_name)
                addedStations[station.backer_name] = true --The value here doesn't matter, this just lets us check without another for loop.
            end
        end
    end
end

function gui.update(player)
    gui.getStations(player)
end

---Handles click events for the GUI.
---@param event EventData.on_gui_click
function gui.onClick(event)
    local player = game.get_player(event.player_index) --Station button
        if player == nil then return end

    if(event.element.name:find("station%-button%-")) then
        local stationName = event.element.caption
        log("Player clicked "..event.element.name.."Which leads to "..stationName)
        if(player.vehicle ~= nil and player.vehicle.type == "locomotive") then
            local train = player.vehicle.train
            local schedule = {current = 1, records = {{station=stationName}}}
            train.schedule = schedule
            train.manual_mode = false
            ---@diagnostic disable-next-line: param-type-mismatch
            gui.createMinimap(train, player)
        end
        return
    end

    if(event.element.name == "minimap-close") then --Minimap close button
        gui.destroyMinimap(player)
        return
    end

    if(event.element.name == "shuttle-conductor-button") then --ModGUI button
        local frame = player.gui.screen["shuttle-conductor-frame"]
        if(frame == nil) then
            gui.createGui(player)
            else if (frame.visible) then frame.visible = false
            else frame.visible = true end
        end
        return
    end

    if(event.element.name == "shuttle-button") then --Shuttle settings button
        if player.gui.screen["shuttle-conductor-frame"]["picker-vflow"] then
            gui.destroyShuttlePicker(player)
        else
            gui.createShuttlePicker(player)
        end
        return
    end
end

function gui.onSearch(event)
    if(event.element.name == "shuttle-conductor-textfield") then
        local search = event.text
        gui.getStations(game.get_player(event.player_index), search)
    end
end

return gui