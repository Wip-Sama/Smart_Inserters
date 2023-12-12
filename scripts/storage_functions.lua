local storage_functions = {}

local function deepcopy(object)
    if type(object) ~= 'table' then
        return object
    end

    local copy = {}
    for key, value in pairs(object) do
        copy[deepcopy(key)] = deepcopy(value)
    end

    return copy
end

function storage_functions.populate_storage()
    global.SI_Storage["inserters_range"] = settings.startup["si-max-inserters-range"].value
    for player_index, _ in pairs(game.players) do
        storage_functions.add_player(player_index)

        -- TODO 10 is a magic number, should be replaced with a variable
        local tmp = {}
        for x = -10, 10 do
            local x_string = tostring(x)
            global.SI_Storage[player_index].selected_inserter.position_grid[x_string] = {}
            tmp[x_string] = { loaded = false }
        end

        for y = -10, 10 do
            global.SI_Storage[player_index].selected_inserter.position_grid[tostring(y)] = deepcopy(tmp)
        end

        rendering.clear("Smart_Inserters")
    end
end

function storage_functions.add_player(player_index)
    local storage = global.SI_Storage[player_index] or {}
    global.SI_Storage[player_index] = storage

    storage.copy_event = {
        tick = 0,
        drop = {},
        pickup = {},
        si_direction = 0,
        relative_si_direction = 0,
        destination_behavior = {
            circuit_set_stack_size = 0,
            circuit_read_hand_contents = 0,
            circuit_mode_of_operation = 0,
            circuit_hand_read_mode = 0,
            circuit_condition = 0,
            circuit_stack_control_signal = 0
        },
        inserter_filter_mode = {},
        inserter_stack_size_override = {},
        filtered_slots = {
            { copy = true, item = "" },
            { copy = true, item = "" },
            { copy = true, item = "" },
            { copy = true, item = "" },
            { copy = true, item = "" }
        }
    }

    storage.copy_settings = {
        drop = true,
        drop_offset = true,
        pickup = true,
        pickup_offset = true,
        si_direction = true,
        relative_si_direction = true,

        inserter_filter_mode = true,
        filtered_stuff = true,
        inserter_stack_size_override = true,

        circuit_set_stack_size = true,
        circuit_read_hand_contents = true,
        circuit_mode_of_operation = true,
        circuit_hand_read_mode = true,
        circuit_condition = true,
        circuit_stack_control_signal = true
    }

    storage.is_selected = false
    storage.selected_inserter = {
        position = { x = "", y = "" },
        name = "",
        surface = "",
        drop = { x = "", y = "" },
        pickup = { x = "", y = "" },
        position_grid = {}
    }

    for x = -global.SI_Storage["inserters_range"], global.SI_Storage["inserters_range"] do
        local x_string = tostring(x)
        storage.selected_inserter.position_grid[x_string] = {}
        for y = -global.SI_Storage["inserters_range"], global.SI_Storage["inserters_range"] do
            storage.selected_inserter.position_grid[x_string][tostring(y)] = { loaded = false }
        end
    end
end

function storage_functions.purge_copy_event_data(player_index)
    storage_functions.ensure_data(player_index)
    local filtered_slots = global.SI_Storage[player_index].copy_event.filtered_slots
    global.SI_Storage[player_index].copy_event = {
        tick = 0,
        drop = {},
        pickup = {},
        si_direction = 0,
        relative_si_direction = 0,
        destination_behavior = {
            circuit_set_stack_size = 0,
            circuit_read_hand_contents = 0,
            circuit_mode_of_operation = 0,
            circuit_hand_read_mode = 0,
            circuit_condition = 0,
            circuit_stack_control_signal = 0
        },
        inserter_filter_mode = {},
        inserter_stack_size_override = {},
        filtered_slots = {
            { copy = filtered_slots[1].copy, item = "" },
            { copy = filtered_slots[2].copy, item = "" },
            { copy = filtered_slots[3].copy, item = "" },
            { copy = filtered_slots[4].copy, item = "" },
            { copy = filtered_slots[5].copy, item = "" }
        }
    }
end

function storage_functions.ensure_data(player_index)
    player_index = player_index or false

    if global.SI_Storage == nil then
        global.SI_Storage = {}
    end

    if not global.SI_Storage["inserters_range"] then
        global.SI_Storage["inserters_range"] = settings.startup["si-max-inserters-range"].value
    end

    if player_index and not global.SI_Storage[player_index] then
        storage_functions.add_player(player_index)
    end

    return global.SI_Storage[player_index]
end

return storage_functions