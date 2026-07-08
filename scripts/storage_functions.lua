local storage_functions = {}

storage.SI_Storage = storage.SI_Storage or {}

function storage_functions.get_default_copy_settings()
    return {
        drop = true,
        drop_offset = true,
        pickup = true,
        pickup_offset = true,
        si_direction = false,
        relative_si_direction = true,

        inserter_filter_mode = true,
        filtered_stuff = true,
        inserter_stack_size_override = true,
        inserter_target_pickup_count = true,
        inserter_spoil_priority = true,

        circuit_set_filters = true,
        circuit_read_hand_contents = true,
        circuit_hand_read_mode = true,
        circuit_set_stack_size = true,
        circuit_stack_control_signal = true,
        circuit_enable_disable = true,
        circuit_condition = true
    }
end

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

    storage.SI_Storage[player_index].copy_event = {
        tick = 0,
        drop = {},
        pickup = {},
        si_direction = 0,
        relative_si_direction = 0,
        destination_behavior = {
            circuit_set_filters = 0,
            circuit_read_hand_contents = 0,
            circuit_hand_read_mode = 0,
            circuit_set_stack_size = 0,
            circuit_stack_control_signal = 0,
            circuit_enable_disable = 0,
            circuit_condition = 0
        },
        inserter_target_pickup_count = {},
        inserter_stack_size_override = {},
        inserter_filter_mode = {},
        inserter_spoil_priority = {},

        filtered_slots = {
            { copy = true, item = "" },
            { copy = true, item = "" },
            { copy = true, item = "" },
            { copy = true, item = "" },
            { copy = true, item = "" }
        }
    }

    storage.SI_Storage[player_index].active_preset_index = 1
    storage.SI_Storage[player_index].presets = {
        {
            name = "Preset 1",
            settings = storage_functions.get_default_copy_settings()
        }
    }
end

function storage_functions.populate_storage()
    for player_index, _ in pairs(game.players) do
        ---@diagnostic disable-next-line: param-type-mismatch
        storage_functions.add_player(player_index)
    end
    rendering.clear("Smart_Inserters")
end

function storage_functions.purge_copy_event_data(player_index)
    storage_functions.ensure_data(player_index)
    local filtered_slots = storage.SI_Storage[player_index].copy_event.filtered_slots
    storage.SI_Storage[player_index].copy_event = {
        tick = 0,
        drop = {},
        pickup = {},
        si_direction = 0,
        relative_si_direction = 0,
        destination_behavior = {
            circuit_set_filters = 0,
            circuit_read_hand_contents = 0,
            circuit_hand_read_mode = 0,
            circuit_set_stack_size = 0,
            circuit_stack_control_signal = 0,
            circuit_enable_disable = 0,
            circuit_condition = 0
        },
        inserter_target_pickup_count = {},
        inserter_stack_size_override = {},
        inserter_filter_mode = {},
        inserter_spoil_priority = {},
        filtered_slots = {
            { copy = filtered_slots[1].copy, item = "" },
            { copy = filtered_slots[2].copy, item = "" },
            { copy = filtered_slots[3].copy, item = "" },
            { copy = filtered_slots[4].copy, item = "" },
            { copy = filtered_slots[5].copy, item = "" }
        }
    }
end

---@param player_index number
---@return unknown
function storage_functions.ensure_data(player_index)
    storage.SI_Storage = storage.SI_Storage or {}

    if not storage.SI_Storage[player_index] then
        storage_functions.add_player(player_index)
    end

    return storage.SI_Storage[player_index]
end

return storage_functions