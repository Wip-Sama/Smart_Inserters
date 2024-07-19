local directional_slim_inserter = settings.startup["si-directional-slim-inserter"].value

local storage_functions = require("scripts/storage_functions")
local inserter_functions = require("scripts/inserter_functions")
local util = require("scripts.si_util")
local math2d = require("__yafla__/scripts/extended_math2d")

--Removed a bunch of Tostring

local world_editor = {}
local colors       = {
    can_select  = { 30, 30, 30, 5 },
    cant_select = { 207, 31, 60, 5 },
    drop        = { 77, 15, 15, 3 },
    light_drop  = { 77, 15, 15, 1 },
    pickup      = { 15, 74, 13, 3 },
    light_pickup= { 15, 74, 13, 1 },
    -- inserter    = { 15, 74, 13, 2 } -- I want something blueish to implement this
}

function world_editor.draw_positions(player_index, inserter, hand)
    local player = game.players[player_index]
    local range = inserter_functions.get_max_range(inserter, player.force)
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    storage_functions.ensure_data(player_index)
    local player_storage = global.SI_Storage[player_index]

    local slim = inserter_functions.is_slim(inserter)

    local inserter_size = inserter_functions.get_inserter_size(inserter)
    local vertical = inserter.direction == defines.direction.north or inserter.direction == defines.direction.south
    local orizontal = inserter.direction == defines.direction.east or inserter.direction == defines.direction.west
    local enabled_matrix = util.enabled_cell_matrix(player.force, vertical, orizontal, slim)

    local is_drop, is_pickup, render_id, x_offset, y_offset

    if slim then
        if vertical and arm_positions.drop.y >= 0 then     -- parte bassa / lower half
            arm_positions.drop.y = arm_positions.drop.y + 1
        elseif orizontal and arm_positions.drop.x >= 0 then -- parte destra / right
            arm_positions.drop.x = arm_positions.drop.x + 1
        end
        if vertical and arm_positions.pickup.y >= 0 then     -- parte bassa / lower half
            arm_positions.pickup.y = arm_positions.pickup.y + 1
        elseif orizontal and arm_positions.pickup.x >= 0 then -- parte destra / right
            arm_positions.pickup.x = arm_positions.pickup.x + 1
        end
    end

    player_storage.is_selected = true
    for px = -range, range do
        for py = -range, range do
            -- Should change to allow for slim/big inserter
            if px == 0 and py == 0 then goto continue end

            is_drop = arm_positions.drop.x == px and arm_positions.drop.y == py
            is_pickup = arm_positions.pickup.x == px and arm_positions.pickup.y == py
            if not enabled_matrix[px][py] and not (is_pickup or is_drop) then
                goto continue
            end

            x_offset = 0
            y_offset = 0
            if slim then
                if directional_slim_inserter then
                    if hand == nil then goto continue end
                    if hand == "drop" then
                        if inserter.direction == 0 and py < 0 then goto continue
                        elseif inserter.direction == 2 and px > 0 then goto continue
                        elseif inserter.direction == 4 and py > 0 then goto continue
                        elseif inserter.direction == 6 and px < 0 then goto continue
                        end
                    elseif hand == "pickup" then
                        if inserter.direction == 0 and py > 0 then goto continue
                        elseif inserter.direction == 2 and px < 0 then goto continue
                        elseif inserter.direction == 4 and py < 0 then goto continue
                        elseif inserter.direction == 6 and px > 0 then goto continue
                        end
                    end
                end
                if orizontal then
                    if px < 0 then
                        x_offset = 0.5
                    elseif px > 0 then
                        x_offset = -0.5
                    end
                end
                    if vertical then
                    if py < 0 then
                        y_offset = 0.5
                    elseif py > 0 then
                        y_offset = -0.5
                    end
                end
            end

            render_id = rendering.draw_rectangle {
                color =
                    is_drop and colors.drop or
                    is_pickup and colors.pickup or
                    enabled_matrix[px][py] and colors.can_select or
                    colors.cant_select,
                filled = true,
                left_top = { inserter.position.x + px - 0.5 + x_offset, inserter.position.y + py - 0.5 + y_offset},
                right_bottom = { inserter.position.x + px + 0.5 + x_offset, inserter.position.y + py + 0.5 + y_offset},
                surface = player.surface,
                forces = { player.force },
                players = { player },
                visible = true,
                draw_on_ground = false,
                only_in_alt_mode = false
            }

            player_storage.selected_inserter.position_grid[px][py] = {
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
    local render_id, enabled_cell
    storage_functions.ensure_data(player_index)
    local size = inserter_functions.get_inserter_size(inserter)

    if changes.pickup then
        if changes.pickup.old then
            render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.pickup.old.x]
                [changes.pickup.old.y].render_id
            if type(render_id) ~= "number" then return end
            rendering.destroy(render_id)
            enabled_cell = util.should_cell_be_enabled(changes.pickup.old, range, player.force, inserter)
            render_id = rendering.draw_rectangle {
                color = colors[enabled_cell and "can_select" or "cant_select"],
                filled = true,
                left_top = { arm_positions.base.x + changes.pickup.old.x, arm_positions.base.y + changes.pickup.old.y },
                right_bottom = { arm_positions.base.x + changes.pickup.old.x + 1,
                    arm_positions.base.y + changes.pickup.old.y + 1 },
                surface = player.surface,
                forces = { player.force },
                players = { player },
                visible = true,
                draw_on_ground = false,
                only_in_alt_mode = false
            }
            global.SI_Storage[player_index].selected_inserter.position_grid[changes.pickup.old.x][changes.pickup.old.y] = {
                loaded = true,
                render_id = render_id
            }
        end
        if changes.pickup.new then
            render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.pickup.new.x]
                [changes.pickup.new.y].render_id
            if type(render_id) ~= "number" then return end
            rendering.destroy(render_id)
            render_id = rendering.draw_rectangle {
                color = colors["pickup"],
                filled = true,
                left_top = { arm_positions.base.x + changes.pickup.new.x, arm_positions.base.y + changes.pickup.new.y },
                right_bottom = { arm_positions.base.x + changes.pickup.new.x + 1,
                    arm_positions.base.y + changes.pickup.new.y + 1 },
                surface = player.surface,
                forces = { player.force },
                players = { player },
                visible = true,
                draw_on_ground = false,
                only_in_alt_mode = false
            }
            global.SI_Storage[player_index].selected_inserter.position_grid[changes.pickup.new.x][changes.pickup.new.y] = {
                loaded = true,
                render_id = render_id
            }
        end
    end

    if changes.drop then
        -- Perché ho messo and not changes.pickup??? da controllare
        if changes.drop.old and not changes.pickup then
            --[[
            
                if size == 0 then
                    local vertical = (inserter.direction==0 or inserter.direction==4)
                    local orizontal = (inserter.direction==2 or inserter.direction==6)
                    if vertical and changes.drop.old.y >= 0 then     -- parte bassa / lower half
                        render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.old.x]
                        [changes.drop.old.y-1].render_id
                    elseif orizontal and changes.drop.old.x >= 0 then -- parte destra / right
                        render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.old.x-1]
                        [changes.drop.old.y].render_id
                    end
                else
                    render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.old.x]
                        [changes.drop.old.y].render_id
                end
            ]]
            render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.old.x]
            [changes.drop.old.y].render_id
            if type(render_id) ~= "number" then return end
            rendering.destroy(render_id)
            enabled_cell = util.should_cell_be_enabled(changes.drop.old, range, player.force, inserter)
            render_id = rendering.draw_rectangle {
                color = colors[enabled_cell and "can_select" or "cant_select"],
                filled = true,
                left_top = { arm_positions.base.x + changes.drop.old.x, arm_positions.base.y + changes.drop.old.y },
                right_bottom = { arm_positions.base.x + changes.drop.old.x + 1,
                    arm_positions.base.y + changes.drop.old.y + 1 },
                surface = player.surface,
                forces = { player.force },
                players = { player },
                visible = true,
                draw_on_ground = false,
                only_in_alt_mode = false
            }
            global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.old.x][changes.drop.old.y] = {
                loaded = true,
                render_id = render_id
            }
        end
        if changes.drop.new then
            --[[

                if size == 0 then
                    local vertical = (inserter.direction==0 or inserter.direction==4)
                    local orizontal = (inserter.direction==2 or inserter.direction==6)
                    if vertical and changes.drop.new.y >= 0 then     -- parte bassa / lower half
                        render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.new.x]
                        [changes.drop.new.y-1].render_id
                    elseif orizontal and changes.drop.new.y >= 0 then -- parte destra / right
                        render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.new.x-1]
                        [changes.drop.new.y].render_id
                    end
                else
                    render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.new.x]
                        [changes.drop.new.y].render_id
                end
            ]]
            render_id = global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.new.x]
            [changes.drop.new.y].render_id
            if type(render_id) ~= "number" then return end
            rendering.destroy(render_id)
            render_id = rendering.draw_rectangle {
                color = colors["drop"],
                filled = true,
                left_top = { arm_positions.base.x + changes.drop.new.x, arm_positions.base.y + changes.drop.new.y },
                right_bottom = { arm_positions.base.x + changes.drop.new.x + 1,
                    arm_positions.base.y + changes.drop.new.y + 1 },
                surface = player.surface,
                forces = { player.force },
                players = { player },
                visible = true,
                draw_on_ground = false,
                only_in_alt_mode = false
            }
            global.SI_Storage[player_index].selected_inserter.position_grid[changes.drop.new.x][changes.drop.new.y] = {
                loaded = true,
                render_id = render_id
            }
        end
    end

    if changes.tech == true then
        world_editor.draw_positions(player_index, inserter)
    end
end

function world_editor.update_all_positions(inserter, hand)
    local player_storage
    for _, player in pairs(game.players) do
        player_storage = global.SI_Storage[player.index]
        storage_functions.ensure_data(player.index)
        if player_storage.is_selected == true and math2d.position.equal(player_storage.selected_inserter.position, inserter.position) then
            world_editor.clear_positions(player.index)
            world_editor.draw_positions(player.index, inserter, hand)
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