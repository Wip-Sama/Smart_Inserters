local inserter_functions = require("scripts.inserter_functions")
local storage_functions  = require("scripts.storage_functions")
local actions            = require("__yafla__/scripts/actions")

local circuits = {}

--TODO: check what happens when I remove a a conenction from an inserter
--TODO: block player changes if a circuit network is connected to the inserter and the "enable_circuit_control" setting is enabled

function circuits.on_gui_opened(event)
    local player = game.get_player(event.player_index)
    if event.gui_type == defines.gui_type.entity and event.entity and inserter_functions.is_inserter(event.entity) then
        local circuit_connection = event.entity.get_signals(
            defines.wire_connector_id.circuit_green,
            defines.wire_connector_id.circuit_red
        )
        print("Circuit connection signals:")
        if not circuit_connection then
            print("No signals connected.")
            return
        end
        for _, signal in pairs(circuit_connection) do
            print("Name: " .. signal.signal.name .. ", count: " .. signal.count)
        end
    else
    end
end

local function update_arm_position_from_circuit(inserter)
    if inserter_functions.is_inserter(inserter) then
        local circuit_connection = inserter.get_signals(
            defines.wire_connector_id.circuit_green,
            defines.wire_connector_id.circuit_red
        )
        if circuit_connection then
            local arm_position = inserter_functions.get_arm_positions(inserter)
            local current_arm_position = table.deepcopy(arm_position)

            for _, signal in pairs(circuit_connection) do
                if signal.signal.name       == "si-vertical-pickup"             then
                    arm_position.pickup.y = signal.count
                elseif signal.signal.name   == "si-vertical-drop"               then
                    arm_position.drop.y = signal.count
                elseif signal.signal.name   == "si-horizontal-pickup"           then
                    arm_position.pickup.x = signal.count
                elseif signal.signal.name   == "si-horizontal-drop"             then
                    arm_position.drop.x = signal.count
                elseif signal.signal.name   == "si-vertical-pickup-offset"      then
                    arm_position.pickup_offset.y = signal.count
                elseif signal.signal.name   == "si-vertical-drop-offset"        then
                    arm_position.drop_offset.y = signal.count
                elseif signal.signal.name   == "si-horizontal-pickup-offset"    then
                    arm_position.pickup_offset.x = signal.count
                elseif signal.signal.name   == "si-horizontal-drop-offset"      then
                    arm_position.drop_offset.x = signal.count
                end
            end

            --if the insteter position is already correct, skip the update to prevent unnecessary arm movement
            if current_arm_position.pickup.x == arm_position.pickup.x and
               current_arm_position.pickup.y == arm_position.pickup.y and
               current_arm_position.drop.x == arm_position.drop.x and
               current_arm_position.drop.y == arm_position.drop.y and
               current_arm_position.pickup_offset.x == arm_position.pickup_offset.x and
               current_arm_position.pickup_offset.y == arm_position.pickup_offset.y and
               current_arm_position.drop_offset.x == arm_position.drop_offset.x and
               current_arm_position.drop_offset.y == arm_position.drop_offset.y then
                return
            end

            inserter_functions.set_arm_positions(arm_position, inserter)
        end
    end
end

local function update_inserters_from_circuit_network()
    for _, data in pairs(storage.SI_Storage["inserter_connected_to_circuit_networks"]) do
        local surface = game.get_surface(data["inserter_surface"])
        if surface then
            local inserter = surface.find_entity(data["inserter_name"], data["inserter_position"])
            if inserter then
                update_arm_position_from_circuit(inserter)
            else
                --Inserter not found, remove from storage
                storage.SI_Storage["inserter_connected_to_circuit_networks"][data["inserter_name"] .. serpent.line(data["inserter_position"])] = nil
            end
        else
            --Surface not found, remove from storage
            storage.SI_Storage["inserter_connected_to_circuit_networks"][data["inserter_name"] .. serpent.line(data["inserter_position"])] = nil
        end
    end
end

function circuits.update_circuit_configuration()
    storage_functions.ensure_circuit_network_data()

    actions.stop_loop_action(storage.SI_Storage["circuit_check_interval_loop_id"])
    actions.stop_loop_action(storage.SI_Storage["inserter_scan_loop_id"])
    storage.SI_Storage["circuit_check_interval_loop_id"] = nil
    storage.SI_Storage["inserter_scan_loop_id"] = nil

    if not storage.SI_Storage["enable_circuit_control"] then return end
    storage.SI_Storage["circuit_check_interval_loop_id"] = actions.loop_action(storage.SI_Storage["circuit_check_interval"], update_inserters_from_circuit_network, nil, nil)
    storage.SI_Storage["inserter_scan_loop_id"] = nil
end

return circuits