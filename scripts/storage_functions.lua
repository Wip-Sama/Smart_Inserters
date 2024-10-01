local util = require("__core__/lualib/util")

local storage_functions = {}

global.SI_Storage = global.SI_Storage or {}

-- May need this copy structure for later
-- storage.copy_event = {
--     tick = 0,
--     drop = {},
--     pickup = {},
--     si_direction = 0,
--     relative_si_direction = 0,
--     destination_behavior = {
--         circuit_set_stack_size = 0,
--         circuit_read_hand_contents = 0,
--         circuit_mode_of_operation = 0,
--         circuit_hand_read_mode = 0,
--         circuit_condition = 0,
--         circuit_stack_control_signal = 0
--     },
--     inserter_filter_mode = {},
--     inserter_stack_size_override = {},
--     filtered_slots = {
--         { copy = true, item = "" },
--         { copy = true, item = "" },
--         { copy = true, item = "" },
--         { copy = true, item = "" },
--         { copy = true, item = "" }
--     }
-- }
-- purge
-- local filtered_slots = global.SI_Storage[player_index].copy_event.filtered_slots


function storage_functions.populate_storage()
    for player_index, _ in pairs(game.players) do
        ---@diagnostic disable-next-line: param-type-mismatch
        storage_functions.add_player(player_index)
    end
    rendering.clear("Smart_Inserters")
end

---@param player_index number
function storage_functions.add_player(player_index)
    local storage = global.SI_Storage[player_index] or {}

    ---@type SelectedInserter
    storage.selected_inserter = {
        inserter = nil,
        displayed_elements = {}
    }
end

---@param player_index number
---@return unknown
function storage_functions.ensure_data(player_index)
    global.SI_Storage = global.SI_Storage or {}

    if not global.SI_Storage[player_index] then
        storage_functions.add_player(player_index)
    end

    return global.SI_Storage[player_index]
end

return storage_functions