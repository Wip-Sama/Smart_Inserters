local directional_inserters = settings.startup["si-directional-inserters"].value
local directional_slim_inserters = settings.startup["si-directional-slim-inserters"].value

local inserter_functions = require("scripts/inserter_functions")
local storage_functions = require("scripts/storage_functions")
local math2d = require("__yafla__/scripts/extended_math2d")

--Removed a bunch of Tostring

local world_editor = {}
local colors       = {
    can_select  = { 30, 30, 30, 5 },
    drop        = { 154, 30, 30 },
    pickup      = { 30, 148, 26 },
    light_drop  = { 77, 15, 15, 1 },
    light_pickup= { 15, 74, 13, 1 },
}

---@param player LuaPlayer
---@param position Position
---@param directional_color "drop" | "pickup" | nil
---@return LuaRenderObject
local function draw_border(player, position, directional_color)
    return rendering.draw_rectangle {
        color = directional_color == nil and {255, 255, 255} or
                directional_color == "drop" and {255, 0, 0} or {0, 255, 0},
        -- color = {255, 255, 255},
        filled = false,
        width = 2,
        left_top = { position.x - 0.5 + 0.03125, position.y - 0.5 + 0.03125 },
        right_bottom = { position.x + 0.5 - 0.03125, position.y + 0.5 - 0.03125 },
        surface = player.surface,
        forces = { player.force },
        players = { player },
        visible = true,
        draw_on_ground = false,
        only_in_alt_mode = false
    }
end

---@param player LuaPlayer
---@param position Position
---@param directional_color "drop" | "pickup" | nil
---@return LuaRenderObject
local function draw_background(player, position, directional_color)
    return rendering.draw_rectangle {
        color = colors.can_select,
        filled = true,
        left_top = { position.x - 0.5, position.y - 0.5 },
        right_bottom = { position.x + 0.5, position.y + 0.5 },
        surface = player.surface,
        forces = { player.force },
        players = { player },
        visible = true,
        draw_on_ground = false,
        only_in_alt_mode = false
    }
end

---@param player LuaPlayer
---@param position Position
---@return LuaRenderObject
local function draw_pickup(player, position)
    return rendering.draw_rectangle {
        color = colors.pickup,
        filled = false,
        width = 8,
        left_top = { position.x - 0.5 + 0.1875, position.y - 0.5 + 0.1875 },
        right_bottom = { position.x + 0.5 - 0.1875, position.y + 0.5 - 0.1875 },
        surface = player.surface,
        forces = { player.force },
        players = { player },
        visible = true,
        draw_on_ground = false,
        only_in_alt_mode = false
    }
end

---@param player LuaPlayer
---@param position Position
---@return LuaRenderObject
local function draw_drop(player, position)
    return rendering.draw_rectangle {
        color = colors.drop,
        filled = false,
        width = 8,
        left_top = { position.x - 0.5 + 0.5625, position.y - 0.5 + 0.5625 },
        right_bottom = { position.x + 0.5 - 0.5625, position.y + 0.5 - 0.5625 },
        surface = player.surface,
        forces = { player.force },
        players = { player },
        visible = true,
        draw_on_ground = false,
        only_in_alt_mode = false
    }
end

---@param player_index number
---@param inserter LuaEntity
---@return nil
function world_editor.draw_positions(player_index, inserter)

    local player = game.get_player(player_index)
    if player == nil then return end
    
    storage_functions.ensure_data(player_index)

    local max_inserter_range, min_inserter_range = inserter_functions.get_max_and_min_inserter_range(inserter)
    local slim = inserter_functions.is_slim(inserter)

    local width, height = math.ceil(inserter.tile_width), math.ceil(inserter.tile_height)

    local lower_width = width%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5

    local x_offset, y_offset = width ~= 1 and 0.5 or 0, height ~= 1 and 0.5 or 0

    local slim = inserter_functions.is_slim(inserter)

    storage.SI_Storage[player_index].selected_inserter.inserter = inserter

    for y = -max_inserter_range-lower_height, max_inserter_range+higher_height-1, 1 do
        for x = -max_inserter_range-lower_width, max_inserter_range+higher_width-1, 1 do
            storage.SI_Storage[player_index].selected_inserter.displayed_elements[x] = storage.SI_Storage[player_index].selected_inserter.displayed_elements[x] or {}
            if (not ((-lower_width <= x and x < higher_width) and (-lower_height <= y and y < higher_height))) and inserter_functions.should_cell_be_enabled(inserter, {x = x, y = y}) then
                local directional_color
                if (directional_inserters and not slim) or (directional_slim_inserters and slim) then
                    if inserter.direction == defines.direction.north then
                        if y < 0 then
                            directional_color = "pickup"
                        else
                            directional_color = "drop"
                        end
                    elseif inserter.direction == defines.direction.south then
                        if y < 0 then
                            directional_color = "drop"
                        else
                            directional_color = "pickup"
                        end
                    elseif inserter.direction == defines.direction.east then
                        if x < 0 then
                            directional_color = "drop"
                        else
                            directional_color = "pickup"
                        end
                    elseif inserter.direction == defines.direction.west then
                        if x < 0 then
                            directional_color = "pickup"
                        else
                            directional_color = "drop"
                        end
                    end
                end

                border = draw_border(player, { x = inserter.position.x + x + x_offset, y = inserter.position.y + y + y_offset }, directional_color)
                background = draw_background(player, { x = inserter.position.x + x + x_offset, y = inserter.position.y + y + y_offset }, directional_color)
                storage.SI_Storage[player_index].selected_inserter.displayed_elements[x][y] = {
                    background_render = background,
                    border_render = border,
                    drop_render = nil,
                    pickup_render = nil,
                }
            else
                storage.SI_Storage[player_index].selected_inserter.displayed_elements[x][y] = {render = nil}
            end
        end
    end

    world_editor.update_positions(player_index, inserter)
end

---@param player_index number
---@param inserter LuaEntity
---@param event InserterArmChanged?
function world_editor.update_positions(player_index, inserter, event)
    local player = game.get_player(player_index)
    if player == nil then return end
    storage_functions.ensure_data(player_index)
    if storage.SI_Storage[player_index].selected_inserter.inserter == nil then return end
    local arm_positions = inserter_functions.get_arm_positions(inserter)

    if event == nil or (event.old_drop and not math2d.position.equal(arm_positions.drop, event.old_drop)) then
        if event and storage.SI_Storage[player_index].selected_inserter.displayed_elements[event.old_drop.x][event.old_drop.y] and storage.SI_Storage[player_index].selected_inserter.displayed_elements[event.old_drop.x][event.old_drop.y].drop_render then
            storage.SI_Storage[player_index].selected_inserter.displayed_elements[event.old_drop.x][event.old_drop.y].drop_render.destroy()
            storage.SI_Storage[player_index].selected_inserter.displayed_elements[event.old_drop.x][event.old_drop.y].drop_render = nil
        end
        if storage.SI_Storage[player_index].selected_inserter.displayed_elements[arm_positions.drop.x][arm_positions.drop.y] then
            local drop_render = draw_drop(player, { x = arm_positions.base.x + arm_positions.drop.x + 0.5, y = arm_positions.base.y + arm_positions.drop.y + 0.5 })
            storage.SI_Storage[player_index].selected_inserter.displayed_elements[arm_positions.drop.x][arm_positions.drop.y].drop_render = drop_render
        end
    end

    if event == nil or (event.old_pickup and not math2d.position.equal(arm_positions.pickup, event.old_pickup)) then
        if event and storage.SI_Storage[player_index].selected_inserter.displayed_elements[event.old_pickup.x][event.old_pickup.y] and storage.SI_Storage[player_index].selected_inserter.displayed_elements[event.old_pickup.x][event.old_pickup.y].pickup_render then
            storage.SI_Storage[player_index].selected_inserter.displayed_elements[event.old_pickup.x][event.old_pickup.y].pickup_render.destroy()
            storage.SI_Storage[player_index].selected_inserter.displayed_elements[event.old_pickup.x][event.old_pickup.y].pickup_render = nil
        end
        if storage.SI_Storage[player_index].selected_inserter.displayed_elements[arm_positions.pickup.x][arm_positions.pickup.y] then
            local pickup_render = draw_pickup(player, { x = arm_positions.base.x + arm_positions.pickup.x + 0.5, y = arm_positions.base.y + arm_positions.pickup.y + 0.5 })
            storage.SI_Storage[player_index].selected_inserter.displayed_elements[arm_positions.pickup.x][arm_positions.pickup.y].pickup_render = pickup_render
        end
    end
end

---@param inserter LuaEntity
---@param event InserterArmChanged
function world_editor.update_all(inserter, event)
    for _, player in pairs(game.players) do
        local storage = storage_functions.ensure_data(player.index)
        if storage.selected_inserter.inserter ~= nil and storage.selected_inserter.inserter == inserter then
            ---@diagnostic disable-next-line: param-type-mismatch
            world_editor.clear_positions(player.index)
            world_editor.draw_positions(player.index, inserter)
            -- world_editor.update_positions(player.index, inserter, event)
        end
    end
end

---@param inserter any
function world_editor.update_all_positions(inserter)
    local player_storage
    for _, player in pairs(game.players) do
        storage_functions.ensure_data(player.index)
        player_storage = storage.SI_Storage[player.index]
        if player_storage.is_selected == true and math2d.position.equal(player_storage.selected_inserter.position, inserter.position) then
            world_editor.clear_positions(player.index)
            world_editor.draw_positions(player.index, inserter)
        end
    end
end

---@param player_index any
function world_editor.clear_positions(player_index)
    storage_functions.ensure_data(player_index)
    storage.SI_Storage[player_index].selected_inserter.inserter = nil
    for _, x in pairs(storage.SI_Storage[player_index].selected_inserter.displayed_elements) do
        for _, y in pairs(x) do
            if y.background_render then
                y.background_render.destroy()
            end
            if y.border_render then
                y.border_render.destroy()
            end
            if y.drop_render then
                y.drop_render.destroy()
            end
            if y.pickup_render then
                y.pickup_render.destroy()
            end
        end
    end
    storage.SI_Storage[player_index].selected_inserter.displayed_elements = {}
end

return world_editor