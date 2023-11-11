local colors       = {}
colors.can_select  = { 30, 30, 30, 5 }
colors.cant_select = { 207, 31, 60, 5 }
colors.drop        = { 77, 15, 15, 2 }
colors.pickup      = { 15, 74, 13, 2 }
-- colors.inserter    = { 15, 74, 13, 2 } I want something blueish to implement this

local inserter_functions = require("scripts/inserter_functions")
local storage_functions = require("scripts/storage_functions")
local util = require("scripts.util")
local math2d = require("scripts.extended_math2d")

local world_editor = {}

function world_editor.draw_positions(player_index, inserter)
    local player        = game.players[player_index]
    local range         = inserter_functions.get_max_range(inserter, player.force)
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    local enabled_cell, is_drop, is_pickup, render_id
    storage_functions.ensure_data(player_index)
    local player_storage = global.SI_Storage[player_index]
    player_storage.is_selected = true
    for px = -range, range, 1 do
        for py = -range, range, 1 do
            if px == py and py == 0 then goto continue end

            enabled_cell = util.should_cell_be_enabled({ px, py }, range, player.force, inserter)
            is_drop = arm_positions.drop.x == px and arm_positions.drop.y == py
            is_pickup = arm_positions.pickup.x == px and arm_positions.pickup.y == py
            if not enabled_cell and not (is_pickup or is_pickup) then goto continue end

            render_id = rendering.draw_rectangle {
                color = colors
                    [is_drop and "drop" or is_pickup and "pickup" or enabled_cell and "can_select" or "cant_select"],
                filled = true,
                left_top = { inserter.position.x + px - 0.5, inserter.position.y + py - 0.5 },
                right_bottom = { inserter.position.x + px + 0.5, inserter.position.y + py + 0.5 },
                surface = player.surface,
                forces = { player.force },
                players = { player },
                visible = true,
                draw_on_ground = false,
                only_in_alt_mode = false
            }

            player_storage.selected_inserter.position_grid[tostring(px)][tostring(py)] = {
                loaded = true,
                render_id = render_id
            }
            ::continue::
        end
    end
end

function world_editor.update_positions(player_index, inserter, changes)
    local player = game.players[player_index]
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    local range = inserter_functions.get_max_range(inserter, player.force)
    storage_functions.ensure_data(player_index)

    local function draw_rectangle_at_position(position, color_key)
        local render_id = rendering.draw_rectangle {
            color = colors[color_key],
            filled = true,
            left_top = { x = arm_positions.base.x + position.x, y = arm_positions.base.y + position.y },
            right_bottom = { x = arm_positions.base.x + position.x + 1, y = arm_positions.base.y + position.y + 1 },
            surface = player.surface,
            forces = { player.force },
            players = { player },
            visible = true,
            draw_on_ground = false,
            only_in_alt_mode = false
        }
        return render_id
    end

    local function destroy_render_id(position)
        local render_id = global.SI_Storage[player_index].selected_inserter.position_grid[tostring(position.x)][tostring(position.y)].render_id
        rendering.destroy(render_id)
    end

    if changes.pickup then
        if changes.pickup.old then
            destroy_render_id(changes.pickup.old)
            local enabled_cell = util.should_cell_be_enabled(changes.pickup.old, range, player.force, inserter)
            draw_rectangle_at_position(changes.pickup.old, enabled_cell and "can_select" or "cant_select")
        end
        if changes.pickup.new then
            destroy_render_id(changes.pickup.new)
            draw_rectangle_at_position(changes.pickup.new, "pickup")
        end
    end

    if changes.drop then
        if changes.drop.old and not changes.pickup then
            destroy_render_id(changes.drop.old)
            local enabled_cell = util.should_cell_be_enabled(changes.drop.old, range, player.force, inserter)
            draw_rectangle_at_position(changes.drop.old, enabled_cell and "can_select" or "cant_select")
        end
        if changes.drop.new then
            destroy_render_id(changes.drop.new)
            draw_rectangle_at_position(changes.drop.new, "drop")
        end
    end

    if changes.tech == true then
        world_editor.draw_positions(player_index, inserter)
    end
end

function world_editor.update_all_positions(inserter)
    local player_storage
    for _, player in pairs(game.players) do
        player_storage = global.SI_Storage[player.index]
        storage_functions.ensure_data(player.index)
        if player_storage.is_selected == true and math2d.position.equal(player_storage.selected_inserter.position, inserter.position) then
            world_editor.clear_positions(player.index)
            world_editor.draw_positions(player.index, inserter)
        end
    end
end

function world_editor.clear_positions(player_index)
    storage_functions.ensure_data(player_index)
    global.SI_Storage[player_index].is_selected = false
    for _, x in pairs(global.SI_Storage[player_index].selected_inserter.position_grid) do
        for _, y in pairs(x) do
            if y.loaded then
                rendering.destroy(y.render_id)
                y.loaded = false
            end
        end
    end
end

return world_editor