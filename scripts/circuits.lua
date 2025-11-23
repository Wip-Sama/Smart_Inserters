local inserter_functions = require("scripts.inserter_functions")
local actions            = require("__yafla__/scripts/actions")

local circuits = {}

function circuits.on_gui_opened(event)
    local player = game.players[event.player_index]
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

actions.loop_action(60, function()
    for _, surface in pairs(game.surfaces) do
        local inserters = surface.find_entities_filtered{type = "inserter"}
        for _, inserter in pairs(inserters) do
            if inserter_functions.is_inserter(inserter) then
                local circuit_connection = inserter.get_signals(
                    defines.wire_connector_id.circuit_green,
                    defines.wire_connector_id.circuit_red
                )
                if circuit_connection then
                    local dummy_signal = {
                        signal = {
                            type="virtual",
                            name="horizontal" --vertical
                        },
                        count=0
                    }

                    local arm_position = inserter_functions.get_arm_positions(inserter)

                    for _, signal in pairs(circuit_connection) do
                        if signal.signal.name == "signal-left-right-arrow" then
                            arm_position.pickup.x = signal.count
                        elseif signal.signal.name == "signal-up-down-arrow" then
                            arm_position.pickup.y = signal.count
                        end
                    end

                    inserter_functions.set_arm_positions(arm_position, inserter)

                end
            end
        end
    end
end, nil, nil)

return circuits