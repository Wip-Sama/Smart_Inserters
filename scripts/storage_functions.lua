local storage_functions = {}

--[[
{
    enable_circuit_control = "bool"
    circuit_check_interval = "int"
    action_loop_id = "string"
    "player_index" = {
        selected_inserter = {
            inserter = "LuaEntity"
            displayed_elements = ???
        }
    }
}
--]]
storage.SI_Storage = storage.SI_Storage or {}

---@param player_index number
function storage_functions.add_player(player_index)
    storage.SI_Storage[player_index] = {}
    ---@type SelectedInserter
    storage.SI_Storage[player_index].selected_inserter = {
        ---@type LuaEntity
        inserter = nil,
        ---@type table<table<RenderedPosition>>
        displayed_elements = {}
    }
end

function storage_functions.ensure_circuit_network_data()
    storage.SI_Storage["enable_circuit_control"] = settings.global["si-enable-circuit-control"].value
    storage.SI_Storage["circuit_check_interval"] = math.floor(tonumber(settings.global["si-circuit-check-interval"].value) or 60)
    --[[
    list of {
        inserter_position = {x, y},
        inserter_surface = "surface_id"
    }
    --]]
    storage.SI_Storage["inserter_connected_to_circuit_networks"] = storage.SI_Storage["inserter_connected_to_circuit_networks"] or {}
    storage.SI_Storage["circuit_check_interval_loop_id"] = storage.SI_Storage["circuit_check_interval_loop_id"] or nil --VERY IMPORTANT
    storage.SI_Storage["inserter_scan_loop_id"] = storage.SI_Storage["inserter_scan_loop_id"] or nil --VERY IMPORTANT
end

function storage_functions.populate_storage()
    for player_index, _ in pairs(game.players) do
        ---@diagnostic disable-next-line: param-type-mismatch
        storage_functions.add_player(player_index)
    end

    storage_functions.ensure_circuit_network_data()

    rendering.clear("Smart_Inserters")
end

---@param player_index number
---@return unknown
function storage_functions.ensure_data(player_index)
    storage.SI_Storage = storage.SI_Storage or {}

    if not storage.SI_Storage[player_index] then
        storage_functions.add_player(player_index)
    end

    storage_functions.ensure_circuit_network_data()

    return storage.SI_Storage[player_index]
end

return storage_functions