--This file contains most of the code that pertains to creating and maintain the UI of this mod.
local gui = {}
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
    controlFlow.add{type="textfield", name="textfield", text="fuck", style="shuttle-conductor-search"}
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
    local screen_element = player.gui.screen
    local flow = screen_element["shuttle-conductor-frame"]["main-vflow"]
    local mapframe = flow.add{type="frame", name="shuttle-conductor-minimap-frame", style="inside_shallow_frame"}
    local mapFlow = mapframe.add{type="flow", name="shuttle-conductor-minimap-flow", direction="vertical"}
        mapFlow.style.vertical_spacing = 0
    local subheader = mapFlow.add{type="frame", name="minimap-subheader", style="subheader_frame"}
        subheader.add{type="label", name="minimap-subheader-label", caption='Shuttle '..train.id..train.carriages[1].gps_tag..' has been dispatched to placeholder...sdl;kjhflijkrwhjwrehgerowg'}.style.horizontally_stretchable=true
        subheader.add{type="sprite-button", name="minimap-close", style="close_button", sprite="utility/close_white"} --TODO: Get this to align correctly >:(
        subheader.style.horizontally_stretchable=true
        subheader.style.bottom_padding=0
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

--Updates the station data for the player.
---@param player LuaPlayer
local function updateStations(player)

    local playerID = player.index
    local s = player.surface.find_entities_filtered({name = "train-stop", force=player.force})

    if not global.data["players"][player.index]["stations"] then global.data["players"][player.index]["stations"] = {} end
    global.data["players"][player.index]["stations"] = s
end

---Updates the station buttons for the player.
---@param player LuaPlayer
function gui.getStations(player)
    updateStations(player)
    clearStations(player)
    local stations = global.data["players"][player.index]["stations"]
    local stationFlow = player.gui.screen["shuttle-conductor-frame"]["main-vflow"]["shuttle-conductor-iframe"]["station-vflow"]["deep-button-container"]["station-scrollframe"]["buttonflow"]

    for i, station in pairs(stations) do
        stationFlow.add{type="button", name="station-button-"..i, caption=station.backer_name, style="shuttle-conductor-station-button"}
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
    end

    if(event.element.name == "minimap-close") then --Minimap close button
        gui.destroyMinimap(player)
    end

    if(event.element.name == "shuttle-conductor-button") then --ModGUI button
        local frame = player.gui.screen["shuttle-conductor-frame"]
        if(frame == nil) then
            gui.createGui(player)
            else if (frame.visible) then frame.visible = false
            else frame.visible = true end
        end
    end
end

return gui