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
          iframe.style.width = 361
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

---Closes the shuttle picker menu for the player.
---@param player LuaPlayer The player to close the menu for.
function gui.destroyShuttlePicker(player)
    if player.gui.screen["shuttle-conductor-frame"]["picker-vflow"] then player.gui.screen["shuttle-conductor-frame"]["picker-vflow"].destroy() end
end

---Closes the shuttle select menu for the player so that a new one can be created.
---@param player any
function gui.destroy_shuttleSelectMenu(player)
end

---Selects which shuttle picker to use.
---@param player LuaPlayer
---@param menu any
function gui.shuttleSelectMenu(player, menu)
    gui.destroy_shuttleSelectMenu(player)
end

---Creates the shuttle picker menu for the player.
---@param player LuaPlayer The player to open the menu for.
function gui.createShuttlePicker(player)
    gui.destroyShuttlePicker(player)
    if player.gui.screen["shuttle-conductor-frame"] then
        local frame = player.gui.screen["shuttle-conductor-frame"]
        local pickerFlow = frame.add{type = "flow", name = "picker-vflow", direction = "vertical", style="shuttle-conductor-main-vflow"}
        local settingsFrame = pickerFlow.add{type = "frame", name = "settings-frame", style="inside_shallow_frame_with_padding"}
              settingsFrame.style.horizontally_stretchable = false
              settingsFrame.style.width = 360
        local settingsVFlow = settingsFrame.add{type = "flow", name = "settings-vflow", direction = "vertical"}
        local menuLabel = settingsVFlow.add{type = "label", name = "menu-label", caption = "Selection Type:"}
        local menuSelector = settingsVFlow.add{type = "drop-down", name = "menu-selector", items={{'shuttle-conductor.menu1'}, {'shuttle-conductor.menu2'}, {'shuttle-conductor.menu3'}}, selected_index = 1}
              menuSelector.style.natural_width = 100
              menuSelector.style.horizontally_stretchable = true
        local depotCheckbox = settingsVFlow.add{type = "checkbox", name = "depot-checkbox", caption = {'shuttle-conductor.return2depot'}, state = true}
        local vehicleCheckbox = settingsVFlow.add{type = "checkbox", name = "vehicle-checkbox", caption = {'shuttle-conductor.wagons'}, state = true}
        local pickerFrame = pickerFlow.add{type = "frame", name = "picker-frame", style="inside_shallow_frame"}
              pickerFrame.style.horizontally_stretchable = false
              pickerFrame.style.width = 360
              pickerFrame.style.vertically_stretchable = true
        local pickerContainer = pickerFrame.add{type = "frame", name = "pickerDeepFrame", style="shuttle-conductor-button-container"}
        local listPane = pickerContainer.add{type = "scroll-pane", name = "list-pane", style = "shuttle-conductor-scroll-frame", vertical_scroll_policy = "always", horizontal_scroll_policy = "never"}
              listPane.style.minimal_width = 360
              listPane.style.vertically_squashable = true
              listPane.style.vertically_stretchable = true
              listPane.style.maximal_height = 443
        local train = storage.data["players"][player.index]["shuttle"]
        gui.createShuttleView(player, train)
    end
end

---Creates an entry for a shuttle in the shuttle picker list.
---@param player LuaPlayer
---@param train LuaTrain
function gui.createShuttleEntry(player, train)
    if player.gui.screen["shuttle-conductor-frame"] then 
        local frame = player.gui.screen["shuttle-conductor-frame"]["picker-vflow"]["picker-frame"]["pickerDeepFrame"]["list-pane"]
        local entryFlow = frame.add{type="flow", direction="horizontal"}
        local camera = entryFlow.add{type="camera", position=train.carriages[1].position, style="shuttle-conductor-shuttle-cam"}
              camera.entity=train.carriages[1]
              camera.zoom = 0.2
    end
end

function gui.destroyShuttleView(player)
    if player.gui.screen["shuttle-conductor-frame"]["picker-vflow"]["shuttle-conductor-shuttleview-frame"] then player.gui.screen["shuttle-conductor-frame"]["picker-vflow"]["shuttle-conductor-shuttleview-frame"].destroy() end
end

---Creates a camera view of the selected shuttle under the shuttle picker.
---@param player LuaPlayer
---@param train LuaTrain
function gui.createShuttleView(player, train)
    gui.destroyShuttleView(player)
    local pickerFlow = player.gui.screen["shuttle-conductor-frame"]["picker-vflow"]
    local shuttleViewFrame = pickerFlow.add{type="frame", name="shuttle-conductor-shuttleview-frame", style="inside_shallow_frame"}
          shuttleViewFrame.style.horizontally_stretchable = true
          shuttleViewFrame.style.minimal_height = 128
    local shuttleViewFlow = shuttleViewFrame.add{type="flow", name="shuttle-conductor-shuttleview-flow", direction="vertical"}
          shuttleViewFlow.style.vertical_spacing = 0
    local subheader = shuttleViewFlow.add{type="frame", name="shuttleview-subheader", style="subheader_frame"}
          local label = subheader.add{type="label", name="shuttleview-subheader-label", caption="Selected Shuttle"}
          label.style.width = 324
          label.style.maximal_width=324
          label.style.horizontally_stretchable = true
          subheader.style.horizontally_stretchable = true
          subheader.style.width = 360
          subheader.style.bottom_padding = 0
    local camera = shuttleViewFlow.add{type="camera", name="shuttle-conductor-shuttle-camera", style="shuttle-conductor-shuttle-cam", position=train.carriages[1].position}
          camera.zoom = 0.2
          camera.entity=train.carriages[1]
end

function gui.destroyMinimap(player)
    if player.gui.screen["shuttle-conductor-frame"]["main-vflow"]["shuttle-conductor-minimap-frame"] then player.gui.screen["shuttle-conductor-frame"]["main-vflow"]["shuttle-conductor-minimap-frame"].destroy() end
end

---Creates a minimap for a shuttle on the polyer's shuttletrain GUI.
---@param train LuaTrain
---@param player LuaPlayer
function gui.createMinimap(train, player, depot)
    if depot == nil then depot = false end
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
        local label = subheader.add{type="label", name="minimap-suder-label", caption={"shuttle-conductor.dispatch-success", trainColor, train.id, stopColor, train.schedule.records[train.schedule.current].station}}
              label.style.natural_width = 296
              label.style.horizontally_squashable = true
        local buttonflow = subheader.add{type = "flow", name = "minimap-button-flow", direction="horizontal"}
            buttonflow.style.horizontal_align = "right"
            buttonflow.style.horizontally_stretchable = true
            if depot == false then buttonflow.add{type="sprite-button", name="minimap-undo", style="close_button", sprite="utility/reset_white", tooltip="Cancel & return to depot"} end
            buttonflow.add{type="sprite-button", name="minimap-close", style="close_button", sprite="utility/close", tooltip="Close minimap"}
        subheader.style.horizontally_stretchable = true
        subheader.style.bottom_padding = 0
        subheader.style.natural_width = 36
    mapframe.style.horizontally_stretchable=true
    mapframe.style.minimal_height = 128
    --local minimap = mapframe.add{type="minimap", name="shuttle-minimap", style="shuttle-conductor-minimap", position=train.carriages[1].position}
    local minimap = mapFlow.add{type="minimap", name="shuttle-minimap", style="shuttle-conductor-minimap", position=train.carriages[1].position}
    minimap.zoom=50
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

--From https://gist.github.com/akornatskyy/63100a3e6a971fd13456b6db104fb65b
local function split_with_comma(str)
    local fields = {}
    for field in str:gmatch('([^,]+)') do
      fields[#fields+1] = field
    end
    return fields
 end

local function isFiltered(name)
    local depots = settings.global["shuttle-conductor-depots"].value
    local filterStrings = settings.global["shuttle-conductor-filter"].value
    local list = split_with_comma(filterStrings)
    local filtered = false
    for i, v in ipairs(list) do
        if string.find(name, v) ~= nil then
            filtered = true
        end
    end
    return filtered
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
                if not isFiltered(string.lower(station.backer_name)) then
                    stationFlow.add{type="button", name="station-button-"..i, caption=station.backer_name, style="shuttle-conductor-station-button"}
                    --table.insert(addedStations, station.backer_name)
                    addedStations[station.backer_name] = true --The value here doesn't matter, this just lets us check without another for loop.
                end
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
        local train = storage.data["players"][player.index]["shuttle"]
        if(train == nil) then return end
        ---@diagnostic disable-next-line: param-type-mismatch
        dispatch.send(train, stationName)
        ---@diagnostic disable-next-line: param-type-mismatch
        gui.createMinimap(train, player)
        return
    end

    if(event.element.name == "minimap-close") then --Minimap close button
        gui.destroyMinimap(player)
        return
    end

    if(event.element.name == "minimap-undo") then
        local train = storage.data["players"][player.index]["shuttle"]
        dispatch.returnToDepot(train)
        gui.createMinimap(train, player, true)
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