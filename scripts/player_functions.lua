local player_functions = {}

---@param player LuaPlayer
---@param item LuaItemStack | nil
function player_functions.safely_change_cursor(player, item)
    item = item or nil
    local inventory = player.get_main_inventory()
    assert(inventory, "Inventory is nil")

    if player.cursor_stack.valid_for_read then
        local available_space = inventory.get_insertable_count(player.cursor_stack.name)
        local skip = player.cursor_stack.prototype.flags and player.cursor_stack.prototype.flags["only-in-cursor"]

        if not skip then
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

    if item then
        player.cursor_stack.set_stack(item)
    end
end


---@param player LuaPlayer
---@param is_drop string
function player_functions.configure_pickup_drop_changer(player, is_drop)
    local cursor_stack = player.cursor_stack
    assert(cursor_stack, "Cursor stack is nil")

    if cursor_stack.is_blueprint then
        cursor_stack.set_blueprint_entities({
            {
                name = "si-in-world-" .. is_drop .. "-entity",
                entity_number = 1,
                position = { 0, 0 }
            }
        })

        cursor_stack.blueprint_absolute_snapping = true
        cursor_stack.blueprint_snap_to_grid = { 1, 0 }
    end
end

return player_functions