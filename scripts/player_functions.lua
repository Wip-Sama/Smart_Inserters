local player_functions = {}

---@param player LuaPlayer
---@param item_stack LuaItemStack | "si-in-world-drop-changer" | "si-in-world-pickup-changer" | nil
function player_functions.safely_change_cursor(player, item_stack)
    item_stack = item_stack or nil
    local inventory = player.get_main_inventory()

    if inventory ~= nil and player.cursor_stack.valid_for_read then
        local available_space = inventory.get_insertable_count(player.cursor_stack.name)
        if not (player.cursor_stack.prototype.flags and player.cursor_stack.prototype.flags["only-in-cursor"]) then
            if available_space >= player.cursor_stack.count * 2 then
                inventory.insert({ name = player.cursor_stack.name, count = player.cursor_stack.count })
            else
                local bonus = player.force.character_inventory_slots_bonus
                player.force.character_inventory_slots_bonus = bonus + 1
                inventory.insert(player.cursor_stack)
                player.cursor_stack.clear()
                player.force.character_inventory_slots_bonus = bonus
            end
        end
    end

    player.cursor_stack.clear()

    if item_stack then
        player.cursor_stack.set_stack(item_stack)
    end
end

---@param player LuaPlayer
---@param drop_or_pickup "pickup" | "drop"
function player_functions.configure_pickup_drop_changer(player, drop_or_pickup)
    local cursor_stack = player.cursor_stack
    if cursor_stack ~= nil and cursor_stack.is_blueprint then
        cursor_stack.set_blueprint_entities({
            {
                name = "si-in-world-" .. drop_or_pickup .. "-entity",
                entity_number = 1,
                position = { 0, 0 }
            }
        })
        cursor_stack.blueprint_absolute_snapping = true
        cursor_stack.blueprint_snap_to_grid = { 1, 0 }
    end
end

return player_functions
