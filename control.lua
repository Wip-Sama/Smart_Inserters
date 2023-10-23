-- ------------------------------
-- Dependencies
-- ------------------------------
local math2d = require("math2d")

-- ------------------------------
-- Utilites
-- ------------------------------
local function deepcopy(object)
    if type(object) ~= 'table' then
        return object
    end
    local res = {}
    for k, v in pairs(object) do res[deepcopy(k)] = deepcopy(v) end
    return res
end

-- ------------------------------
-- Functions Group
-- ------------------------------
local gui = {}
local tech = {}
local inserter_utils = {}
local world_editor = {}
local player_functions = {}
local storage_functions = {}

-- ------------------------------
-- Settings
-- ------------------------------
local inserters_range = settings.startup["si-max-inserters-range"].value
local directional_slim_inserter = settings.startup["si-directional-slim-inserter"].value
local diagonal_technologies = settings.startup["si-diagonal-technologies"].value
local range_technologies = settings.startup["si-range-technologies"].value
local offset_selector_technologies = settings.startup["si-offset-technologies"].value
local single_line_slim_inserter = settings.startup["si-single-line-slim-inserter"].value
local offset_selector = settings.startup["si-offset-selector"].value

-- ------------------------------
-- Blacklist
-- ------------------------------
local blacklist = {}
blacklist.mods = { "miniloader", "RenaiTransportation" }
blacklist.entities = {}

-- ------------------------------
-- Math library additions
-- ------------------------------
function math2d.position.equal(p1, p2)
    p1 = math2d.position.ensure_xy(p1)
    p2 = math2d.position.ensure_xy(p2)
    return p1.x == p2.x and p1.y == p2.y
end

function math2d.position.dot_product(p1, p2)
    p1 = math2d.position.ensure_xy(p1)
    p2 = math2d.position.ensure_xy(p2)
    return p1.x * p2.x + p1.y * p2.y
end

-- splits a position into tile position int(x,y) and an offset float(x,y)
-- { x = -1.5, y = 2.5 } -> {{ x = -2, y = 2 }, { x = 0.5, y = 0.5 }}
function math2d.position.split(pos)
    pos = math2d.position.ensure_xy(pos)

    local x_int, x_frac = math.modf(pos.x)
    local y_int, y_frac = math.modf(pos.y)

    if x_frac < 0 then
        x_int = x_int - 1
        x_frac = x_frac + 1
    end

    if y_frac < 0 then
        y_int = y_int - 1
        y_frac = y_frac + 1
    end

    return { x = x_int, y = y_int }, { x = x_frac, y = y_frac }
end

function math2d.position.tilepos(pos)
    pos = math2d.position.ensure_xy(pos)
    return { x = math.floor(pos.x), y = math.floor(pos.y) }
end

math2d.direction = {}

local function to_vector_table_generator(range)
    local posizioni = {}
    local check = range * 4

    local max = 8 * range - 1
    for i = 0, max, 1 do
        table.insert(posizioni, i)
    end

    local status = 0.0

    for k, v in pairs(posizioni) do
        local mod = v % check
        if mod == 0 then
            posizioni[k] = 0
        elseif status < 0.25 then
            posizioni[k] = posizioni[k - 1] + 1
        elseif status >= 0.75 and status < 1.25 then
            posizioni[k] = posizioni[k - 1] - 1
        elseif status >= 1.25 and status < 1.75 then
            posizioni[k] = -range
        elseif status >= 1.75 then
            posizioni[k] = posizioni[k - 1] + 1
        else
            posizioni[k] = range
        end
        status = v / check
    end

    local merged = {}
    local max = max + 1
    for k, v in pairs(posizioni) do
        table.insert(merged, { x = v, y = posizioni[((k - (2 * range) - 1) % (max)) + 1] })
    end
    return merged
end

for i = 1, 5, 1 do
    math2d.direction["vectors" .. tostring(i)] = to_vector_table_generator(i)
end

function math2d.direction.from_vector(vec, range)
    range = range or 1
    vec = math2d.position.ensure_xy(vec)
    return math.floor(math.atan2(vec.x, -vec.y) * ((4 * range) / math.pi) + 0.5) % (8 * range)
end

function math2d.direction.to_vector(dir, range)
    range = range or 1
    return math2d.direction["vectors" .. tostring(range)][(dir % (8 * range)) + 1]
end

function math2d.direction.transform_to_vector1(position, range)
    local check = range * 4
    local pos = math2d.direction.from_vector(position, range)
    local mod = pos / check

    if mod == 0 then
        return 1
    elseif mod > 0 and mod < 0.5 then
        return 2
    elseif mod == 0.5 then
        return 3
    elseif mod > 0.5 and mod < 1 then
        return 4
    elseif mod == 1 then
        return 5
    elseif mod > 1 and mod < 1.5 then
        return 6
    elseif mod == 1.5 then
        return 7
    elseif mod > 1.5 then
        return 8
    end
end

function math2d.direction.upscale_vec1(vec1_pos, range)
    return (vec1_pos - 1) * range
end

function math2d.round(vec)
    vec = math2d.position.ensure_xy(vec)
    local out = { x = vec.x, y = vec.y }
    if out.x < 0 then
        out.x = math.ceil(out.x)
    else
        out.x = math.ceil(out.x)
    end
    if out.y < 0 then
        out.y = math.ceil(out.y)
    else
        out.y = math.ceil(out.y)
    end
    return out
end

function math2d.no_minus_0(vec)
    vec = math2d.position.ensure_xy(vec)
    if vec.x == -0 then vec.x = 0 end
    if vec.y == -0 then vec.y = 0 end
    return vec
end

-- ------------------------------
-- Tech
-- ------------------------------
function tech.check_offset_tech(force)
    if not offset_selector_technologies then
        return true
    end

    if force.technologies["si-unlock-offsets"].researched then
        return true
    end

    return false
end

function tech.check_diagonal_tech(force, cell_position)
    if not diagonal_technologies then
        return true
    end

    if force.technologies["si-unlock-cross"].researched and (cell_position.x == 0 or cell_position.y == 0) then
        return true
    end

    if force.technologies["si-unlock-x-diagonals"].researched and math.abs(cell_position.x) == math.abs(cell_position.y) then
        return true
    end

    if force.technologies["si-unlock-all-diagonals"].researched then
        return true
    end

    return false
end

function tech.check_range_tech(force, cell_position)
    if not range_technologies then
        return true
    end

    cell_position = math2d.position.ensure_xy(cell_position)
    local distance = math.max(math.abs(cell_position.x), math.abs(cell_position.y))

    if distance <= 1 then
        return true
    end

    if force.technologies["si-unlock-range-1"].researched and distance <= 2 then
        return true
    elseif force.technologies["si-unlock-range-2"].researched and distance <= 3 then
        return true
    elseif force.technologies["si-unlock-range-3"].researched and distance <= 4 then
        return true
    elseif force.technologies["si-unlock-range-4"].researched and distance <= 5 then
        return true
    end

    return false
end

function tech.check_tech(force, cell_position)
    if tech.check_range_tech(force, cell_position) and tech.check_diagonal_tech(force, cell_position) then
        return true
    end
    return false
end

function tech.update_all()
    for idx, player in pairs(game.players) do
        local force = player.force
        if force.technologies["near-inserters"].researched or force.technologies["si-unlock-range-1"].researched then
            force.technologies["si-unlock-range-1"].researched = true
        end
        if force.technologies["long-inserters-1"].researched or force.technologies["si-unlock-range-2"].researched then
            force.technologies["si-unlock-range-2"].researched = true
        end
        if force.technologies["long-inserters-2"].researched or force.technologies["si-unlock-range-3"].researched then
            force.technologies["si-unlock-range-3"].researched = true
        end
        if force.technologies["more-inserters-1"].researched or force.technologies["si-unlock-cross"].researched then
            force.technologies["si-unlock-cross"].researched = true
        end
        if force.technologies["more-inserters-2"].researched or force.technologies["si-unlock-x-diagonals"].researched then
            force.technologies["si-unlock-x-diagonals"].researched = true
        end
    end
end

-- ------------------------------
-- Inserter utils
-- ------------------------------
function inserter_utils.get_prototype(inserter)
    if inserter.type == "entity-ghost" then
        return inserter.ghost_prototype
    end
    return inserter.prototype
end

function inserter_utils.is_inserter(entity)
    return entity and (entity.type == "inserter" or (entity.type == "entity-ghost" and entity.ghost_type == "inserter"))
end

function inserter_utils.is_slim(inserter)
    if inserter.tile_height == 0 or inserter.tile_width == 0 then
        return true
    end
    return false
end

function inserter_utils.get_inserter_size(inserter)
    local height = math.ceil(inserter.tile_height)
    local width = math.ceil(inserter.tile_width)
    return { x = inserter.tile_width, y = inserter.tile_height, z = math.max(width, height) }
end

function inserter_utils.get_arm_positions(inserter)
    local base_tile, base_offset = math2d.position.split(inserter.position)
    local drop_tile, drop_offset = math2d.position.split(inserter.drop_position)
    local pickup_tile, pickup_offset = math2d.position.split(inserter.pickup_position)

    local drop_offset_vec = { x = 0, y = 0 }

    if drop_offset.x > 0.5 then
        drop_offset_vec.x = 1
    elseif drop_offset.x < 0.5 then
        drop_offset_vec.x = -1
    end

    if drop_offset.y > 0.5 then
        drop_offset_vec.y = 1
    elseif drop_offset.y < 0.5 then
        drop_offset_vec.y = -1
    end

    local pickup_offset_vec = { x = 0, y = 0 }

    if pickup_offset.x > 0.5 then
        pickup_offset_vec.x = 1
    elseif pickup_offset.x < 0.5 then
        pickup_offset_vec.x = -1
    end

    if pickup_offset.y > 0.5 then
        pickup_offset_vec.y = 1
    elseif pickup_offset.y < 0.5 then
        pickup_offset_vec.y = -1
    end

    local result = {
        base = base_tile,
        base_offset = base_offset,
        drop = math2d.position.subtract(drop_tile, base_tile),
        pure_drop = drop_tile,
        drop_offset = drop_offset_vec,
        pickup = math2d.position.subtract(pickup_tile, base_tile),
        pure_pickup = pickup_tile,
        pickup_offset = pickup_offset_vec
    }

    return result
end

function inserter_utils.set_arm_positions(inserter, positions)
    local orientation = inserter_utils.get_inserter_orientation(inserter)
    local slim = inserter_utils.is_slim(inserter)
    local inserter_size = inserter_utils.get_inserter_size(inserter)
    local inserter_arm = inserter_utils.get_arm_positions(inserter)
    local slimn = slim and orientation == "N"
    local slime = slim and orientation == "E"
    local slims = slim and orientation == "S"
    local slimo = slim and orientation == "O"

    if positions.pickup or positions.pickup_offset or positions.pickup_adjust then
        local base_tile, base_offset = math2d.position.split(inserter.position)
        local old_pickup_tile, old_pickup_offset = math2d.position.split(inserter.pickup_position)
        local new_pickup_tile, new_pickup_offset

        if positions.pickup then
            local edit = { x = 0, y = 0 }
            if slim then
                if (slims or slimn) and positions.pickup.y < 0 then      -- parte alta / high half
                    --new_pickup_tile = math2d.position.add(base_tile, positions.pickup)
                elseif (slims or slimn) and positions.pickup.y >= 0 then -- parte bassa / lower half
                    --new_pickup_tile = math2d.position.add(base_tile, { positions.pickup.x, positions.pickup.y - 1 })
                    edit.y = edit.y - 1
                elseif (slime or slimo) and positions.pickup.x < 0 then  -- parte sinistra / left
                    --new_pickup_tile = math2d.position.add(base_tile, positions.pickup)
                elseif (slime or slimo) and positions.pickup.x >= 0 then -- parte destra / right
                    --new_pickup_tile = math2d.position.add(base_tile, { positions.pickup.x - 1, positions.pickup.y })
                    edit.x = edit.x - 1
                end
            elseif inserter_size.z >= 2 then
                if positions.pickup.x < 0 then
                    edit.x = edit.x - (inserter_size.z - 1)
                end
                if positions.pickup.y < 0 then
                    edit.y = edit.y - (inserter_size.z - 1)
                end
            end
            new_pickup_tile = math2d.position.add(base_tile, { positions.pickup.x + edit.x, positions.pickup.y + edit.y })
        else
            new_pickup_tile = old_pickup_tile
        end

        if positions.pickup_adjust then
            new_pickup_tile = {
                x = new_pickup_tile.x + positions.pickup_adjust.x,
                y = new_pickup_tile.y + positions.pickup_adjust.y
            }
        end

        if positions.pickup_offset then
            new_pickup_offset = math2d.position.add(
                math2d.position.multiply_scalar(positions.pickup_offset, 0.2), { 0.5, 0.5 }
            )
        else
            new_pickup_offset = old_pickup_offset
        end

        inserter.pickup_position = math2d.position.add(new_pickup_tile, new_pickup_offset)
    end

    if positions.drop or positions.drop_offset or positions.drop_adjust then
        local base_tile, base_offset = math2d.position.split(inserter.position)
        local old_drop_tile, old_drop_offset = math2d.position.split(inserter.drop_position)
        local new_drop_tile, new_drop_offset

        if positions.drop then
            local edit = { x = 0, y = 0 }
            if slim then
                if (slims or slimn) and positions.drop.y < 0 then      -- parte alta / high half
                    new_drop_tile = math2d.position.add(base_tile, positions.drop)
                elseif (slims or slimn) and positions.drop.y >= 0 then -- parte bassa / lower half
                    new_drop_tile = math2d.position.add(base_tile, { positions.drop.x, positions.drop.y - 1 })
                elseif (slime or slimo) and positions.drop.x < 0 then  -- parte sinistra / left
                    new_drop_tile = math2d.position.add(base_tile, positions.drop)
                elseif (slime or slimo) and positions.drop.x >= 0 then -- parte destra / right
                    new_drop_tile = math2d.position.add(base_tile, { positions.drop.x - 1, positions.drop.y })
                end
            elseif inserter_size.z == 2 then
                if positions.drop.x < 0 then
                    edit.x = edit.x - (inserter_size.z - 1)
                end
                if positions.drop.y < 0 then
                    edit.y = edit.y - (inserter_size.z - 1)
                end
                new_drop_tile = math2d.position.add(base_tile, { positions.drop.x + edit.x, positions.drop.y + edit.y })
            else
                new_drop_tile = math2d.position.add(base_tile, positions.drop)
            end
        else
            new_drop_tile = old_drop_tile
        end

        if positions.drop_adjust then
            new_drop_tile = {
                x = new_drop_tile.x + positions.drop_adjust.x,
                y = new_drop_tile.y + positions.drop_adjust.y
            }
        end

        if positions.drop_offset then
            new_drop_offset = math2d.position.add(
                math2d.position.multiply_scalar(positions.drop_offset, 0.2), { 0.5, 0.5 }
            )
        else
            new_drop_offset = old_drop_offset
        end

        inserter.drop_position = math2d.position.add(new_drop_tile, new_drop_offset)
    end
end

function inserter_utils.get_max_range(inserter)
    if settings.startup["si-uniform-range"].value then
        return inserters_range
    end

    local prototype = inserter
    if prototype.object_name == "LuaEntity" then
        prototype = inserter_utils.get_prototype(prototype)
    end

    local pickup_pos = math2d.position.tilepos(math2d.position.add(prototype.inserter_pickup_position, { 0.5, 0.5 }))
    local drop_pos = math2d.position.tilepos(math2d.position.add(prototype.inserter_drop_position, { 0.5, 0.5 }))
    return math.max(math.abs(pickup_pos.x), math.abs(pickup_pos.y), math.abs(drop_pos.x), math.abs(drop_pos.y))
end

function inserter_utils.enforce_max_range(inserter)
    local arm_positions = inserter_utils.get_arm_positions(inserter)
    local max_range = inserter_utils.get_max_range(inserter)

    if math.max(math.abs(arm_positions.drop.x), math.abs(arm_positions.drop.y)) > max_range then
        arm_positions.drop = math2d.position.multiply_scalar(
            math2d.direction.to_vector(math2d.direction.from_vector(arm_positions.drop)), max_range)
    end

    if math.max(math.abs(arm_positions.pickup.x), math.abs(arm_positions.pickup.y)) > max_range then
        arm_positions.pickup = math2d.position.multiply_scalar(
            math2d.direction.to_vector(math2d.direction.from_vector(arm_positions.pickup)), max_range)
    end

    if math2d.position.equal(arm_positions.pickup, arm_positions.drop) then
        arm_positions.pickup = { x = -arm_positions.drop.x, y = -arm_positions.drop.y }
    end

    inserter_utils.set_arm_positions(inserter, arm_positions)
end

function inserter_utils.calc_rotated_offset(inserter, new_position, direction, target)
    local old_positions = inserter_utils.get_arm_positions(inserter)

    if old_positions[target .. "_offset"].x == 0 and old_positions[target .. "_offset"].y == 0 then
        return old_positions[target .. "_offset"]
    end

    local range = math.max(math.abs(old_positions[target].x), math.abs(old_positions[target].y))

    local position = math2d.direction.from_vector(old_positions[target .. "_offset"])

    local old_sector = math2d.direction.transform_to_vector1(old_positions[target], range)
    local new_sector = math2d.direction.transform_to_vector1(new_position, range)

    if old_sector ~= new_sector then
        local spostamento = (8 - old_sector) - (8 - new_sector)
        position = position + spostamento
        position = (position % 8) + 1
        return math2d.direction["vectors1"][position]
    end

    return old_positions[target .. "_offset"]
end

function inserter_utils.get_inserter_orientation(inserter)
    local value = inserter.orientation
    if value > 0.875 or value <= 0.125 then
        return "N"
    elseif 0.125 < value and value <= 0.375 then
        return "E"
    elseif 0.375 < value and value <= 0.625 then
        return "S"
    else
        return "O"
    end
end

function inserter_utils.get_inserter_size_old(inserter)
    local higher = math.max(inserter.tile_height, inserter.tile_height)
    local count = 1
    while higher > 1 do
        higher = higher - 1
        count = count + 1
    end
    return count
end

-- ------------------------------
-- In world editor
-- ------------------------------
local colors       = {}
colors.can_select  = { 30, 30, 30, 5 }
colors.cant_select = { 207, 31, 60, 5 }
colors.drop        = { 77, 15, 15, 2 }
colors.pickup      = { 15, 74, 13, 2 }
-- colors.inserter    = { 15, 74, 13, 2 } I want something blueish to implement this

function world_editor.draw_positions(player_index, inserter)
    local player        = game.players[player_index]
    local range         = inserter_utils.get_max_range(inserter)
    local arm_positions = inserter_utils.get_arm_positions(inserter)
    local enabled_cell, is_drop, is_pickup
    storage_functions.ensure_data(player_index)
    global.SI_Storage[player_index].is_selected = true
    for px = -range, range, 1 do
        for py = -range, range, 1 do
            if px == py and py == 0 then goto continue end

            enabled_cell = gui.should_cell_be_enabled({ px, py }, range, player.force)
            is_drop = arm_positions.drop.x == px and arm_positions.drop.y == py
            is_pickup = arm_positions.pickup.x == px and arm_positions.pickup.y == py
            if not enabled_cell and not (is_pickup or is_pickup) then goto continue end

            local render_id = rendering.draw_rectangle {
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

            global.SI_Storage[player_index].selected_inserter.position_grid[tostring(px)][tostring(py)] = {
                loaded = true,
                render_id = render_id
            }
            ::continue::
        end
    end
end

function world_editor.update_positions(player_index, inserter, changes)
    local player = game.players[player_index]
    local arm_positions = inserter_utils.get_arm_positions(inserter)
    local render_id, enabled_cell
    storage_functions.ensure_data(player_index)

    if changes.pickup then
        if changes.pickup.old then
            render_id = global.SI_Storage[player_index].selected_inserter.position_grid[tostring(changes.pickup.old.x)]
                [tostring(changes.pickup.old.y)].render_id
            rendering.destroy(render_id)
            enabled_cell = tech.check_tech(player.force, changes.pickup.old)
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
            global.SI_Storage[player_index].selected_inserter.position_grid[tostring(changes.pickup.old.x)][tostring(changes.pickup.old.y)] = {
                loaded = true,
                render_id = render_id
            }
        end
        if changes.pickup.new then
            render_id = global.SI_Storage[player_index].selected_inserter.position_grid[tostring(changes.pickup.new.x)]
                [tostring(changes.pickup.new.y)].render_id
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
            global.SI_Storage[player_index].selected_inserter.position_grid[tostring(changes.pickup.new.x)][tostring(changes.pickup.new.y)] = {
                loaded = true,
                render_id = render_id
            }
        end
    end

    if changes.drop then
        if changes.drop.old and not changes.pickup then
            render_id = global.SI_Storage[player_index].selected_inserter.position_grid[tostring(changes.drop.old.x)]
                [tostring(changes.drop.old.y)].render_id
            rendering.destroy(render_id)
            enabled_cell = tech.check_tech(player.force, changes.drop.old)
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
            global.SI_Storage[player_index].selected_inserter.position_grid[tostring(changes.drop.old.x)][tostring(changes.drop.old.y)] = {
                loaded = true,
                render_id = render_id
            }
        end
        if changes.drop.new then
            render_id = global.SI_Storage[player_index].selected_inserter.position_grid[tostring(changes.drop.new.x)]
                [tostring(changes.drop.new.y)].render_id
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
            global.SI_Storage[player_index].selected_inserter.position_grid[tostring(changes.drop.new.x)][tostring(changes.drop.new.y)] = {
                loaded = true,
                render_id = render_id
            }
        end
    end

    if changes.tech == true then
        world_editor.draw_positions(player_index, inserter)
    end
end

function world_editor.clear_positions(player_index)
    storage_functions.ensure_data(player_index)
    global.SI_Storage[player_index].is_selected = false
    for _0, x in pairs(global.SI_Storage[player_index].selected_inserter.position_grid) do
        for _1, y in pairs(x) do
            if y.loaded then
                rendering.destroy(y.render_id)
                y.loaded = false
            end
        end
    end
end

function world_editor.update_all_positions(inserter)
    for idx, player in pairs(game.players) do
        storage_functions.ensure_data(idx)
        if global.SI_Storage[idx].is_selected == true and math2d.position.equal(global.SI_Storage[idx].selected_inserter.position, inserter.position) then
            world_editor.clear_positions(idx)
            world_editor.draw_positions(idx, inserter)
        end
    end
end

-- ------------------------------
-- Gui
-- ------------------------------
function gui.create_pick_drop_editor(flow_content)
    -- Pickup/Drop label
    flow_content.add({
        type = "label",
        name = "label_position",
        caption = { "gui-smart-inserters.position" },
        style = "heading_2_label"
    })

    local table_range = inserters_range
    local inserter_prototyes = game.get_filtered_entity_prototypes({ { filter = "type", type = "inserter" } })
    for name, prototype in pairs(inserter_prototyes) do
        local range = inserter_utils.get_max_range(prototype)
        table_range = math.max(table_range, range)
    end

    -- Pickup/Drop Grid
    local table_position = flow_content.add({
        type = "table",
        name = "table_position",
        column_count = 1 + table_range * 2
    })
    table_position.style.horizontal_spacing = 1
    table_position.style.vertical_spacing = 1

    for y = -table_range, table_range, 1 do
        for x = -table_range, table_range, 1 do
            local pos_suffix = "_" .. tostring(x + table_range + 1) .. "_" .. tostring(y + table_range + 1)

            if x == 0 and y == 0 then
                local sprite = table_position.add({ type = "sprite", name = "sprite_inserter", sprite = "item/inserter" })
                sprite.style.stretch_image_to_widget_size = true
                sprite.style.size = { 32, 32 }
            else
                local button = table_position.add({
                    type = "sprite-button",
                    name = "button_position" .. pos_suffix,
                    style = "slot_sized_button"
                })
                button.style.size = { 32, 32 }
            end
        end
    end
end

function gui.create_bigger_inserter_editor(flow_content, inserter_type)
    local bigger_switch = flow_content.add({
        type = "switch",
        name = "inserter_" .. inserter_type .. "_switch_position",
        left_label_caption = "Left " .. inserter_type .. " position",
        right_label_caption = "Right " .. inserter_type .. " position",
    })
    bigger_switch.switch_state = "right"
end

function gui.create_offset_editor(flow_offset, offset_name)
    local table_range = inserters_range
    local flow_editor = flow_offset.add({
        type = "flow",
        name = "flow_" .. offset_name,
        direction = "vertical"
    })

    flow_editor.add({
        type = "label",
        name = "label_" .. offset_name .. "_offset",
        caption = { "gui-smart-inserters." .. offset_name .. "-offset" },
        style = "heading_2_label"
    })

    local table_editor = flow_editor.add({
        type = "table",
        name = "table_" .. offset_name,
        column_count = 3
    })
    table_editor.style.horizontal_spacing = 1
    table_editor.style.vertical_spacing = 1

    for y = 1, 3, 1 do
        for x = 1, 3, 1 do
            local button_name = "button_" .. offset_name .. "_offset_" ..
                tostring(x + table_range + 1) .. "_" .. tostring(y + table_range + 1)
            local button = table_editor.add({
                type = "sprite-button",
                name = button_name,
                style = "slot_sized_button"
            })
            button.style.size = { 32, 32 }
        end
    end
end

function gui.create(player)
    local frame_main_anchor = {
        gui = defines.relative_gui_type.inserter_gui,
        position = defines.relative_gui_position.right
    }

    -- Initialization
    local frame_main = player.gui.relative.add({
        type = "frame",
        name = "inserter_config",
        caption = { "gui-smart-inserters.configuration" },
        anchor = frame_main_anchor
    })
    local frame_content = frame_main.add({
        type = "frame",
        name = "frame_content",
        style = "inside_shallow_frame_with_padding"
    })

    -- Main vertical row
    local flow_content = frame_content.add({
        type = "flow",
        name = "flow_content",
        direction = "vertical"
    })

    -- Pickup Drop
    local pick_drop_flow = flow_content.add({
        type = "flow",
        name = "pick_drop_flow",
        direction = "horizontal"
    })

    local pusher_left = pick_drop_flow.add({
        type = "empty-widget",
        name = "pusher_left"
    })
    pusher_left.style.horizontally_stretchable = true

    local pick_drop_housing = pick_drop_flow.add({
        type = "flow",
        name = "pick_drop_housing",
        direction = "vertical"
    })

    gui.create_pick_drop_editor(pick_drop_housing)
    gui.create_bigger_inserter_editor(pick_drop_housing, "pick")
    gui.create_bigger_inserter_editor(pick_drop_housing, "drop")

    local pusher_right = pick_drop_flow.add({
        type = "empty-widget",
        name = "pusher_right"
    })
    pusher_right.style.horizontally_stretchable = true

    if offset_selector ~= false then
        -- Separator
        flow_content.add({
            type = "line",
            name = "line",
            style = "control_behavior_window_line"
        })

        -- Flow element
        local flow_offset = flow_content.add({
            type = "flow",
            name = "flow_offset",
            direction = "horizontal"
        })

        local offset_pusher_left = flow_offset.add({
            type = "empty-widget",
            name = "offset_pusher_left"
        })
        offset_pusher_left.style.horizontally_stretchable = true

        gui.create_offset_editor(flow_offset, "pick")

        local offset_pusher_middle = flow_offset.add({
            type = "empty-widget",
            name = "offset_pusher_middle"
        })
        offset_pusher_middle.style.horizontally_stretchable = true

        gui.create_offset_editor(flow_offset, "drop")

        local offset_pusher_right = flow_offset.add({
            type = "empty-widget",
            name = "offset_pusher_right"
        })
        offset_pusher_right.style.horizontally_stretchable = true
    end
end

function gui.delete(player)
    if player.gui.relative.inserter_config then
        player.gui.relative.inserter_config.destroy()
    end
end

function gui.create_all()
    for idx, player in pairs(game.players) do
        gui.delete(player)
        gui.create(player)
    end
end

function gui.should_cell_be_enabled(position, inserter_range, force, slimv, slimo, slim)
    --button.enabled = math.min(math.abs(x), math.abs(y)) == 0 and math.max(math.abs(x), math.abs(y)) <= inserter_range
    --button.enabled = ((math.min(math.abs(x), math.abs(y)) == 0 or math.abs(x) == math.abs(y) ) and math.max(math.abs(x), math.abs(y)) <= inserter_range)
    --button.enabled = math.max(math.abs(x), math.abs(y)) <= table_range
    position = math2d.position.ensure_xy(position)
    if math.max(math.abs(position.x), math.abs(position.y)) <= inserter_range and tech.check_tech(force, position) then
        if slim then
            if single_line_slim_inserter then
                if slimv and position.x == 0 then
                    return true
                elseif slimo and position.y == 0 then
                    return true
                end
            else
                if slimv and position.y ~= 0 then
                    return true
                elseif slimo and position.x ~= 0 then
                    return true
                end
            end
        else
            return true
        end
    end
    return false
end

function gui.update(player, inserter)
    local gui_instance = player.gui.relative.inserter_config.frame_content.flow_content

    local table_range = (gui_instance.pick_drop_flow.pick_drop_housing.table_position.column_count - 1) / 2
    local inserter_range = inserter_utils.get_max_range(inserter)
    local arm_positions = inserter_utils.get_arm_positions(inserter)
    local orientation = inserter_utils.get_inserter_orientation(inserter)
    local slim = inserter_utils.is_slim(inserter)
    local inserter_size = inserter_utils.get_inserter_size(inserter)
    local slimn = slim and orientation == "N"
    local slime = slim and orientation == "E"
    local slims = slim and orientation == "S"
    local slimo = slim and orientation == "O"

    player.gui.relative.inserter_config.visible = gui.should_show(inserter)
    gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.allow_none_state = false
    gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.visible = false
    gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.allow_none_state = false
    gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.visible = false

    if slim then                                                   -- adjust position
        if (slims or slimn) and arm_positions.drop.y >= 0 then     -- parte bassa / lower half
            arm_positions.drop.y = arm_positions.drop.y + 1
        elseif (slime or slimo) and arm_positions.drop.x >= 0 then -- parte destra / right
            arm_positions.drop.x = arm_positions.drop.x + 1
        end
        if (slims or slimn) and arm_positions.pickup.y >= 0 then     -- parte bassa / lower half
            arm_positions.pickup.y = arm_positions.pickup.y + 1
        elseif (slime or slimo) and arm_positions.pickup.x >= 0 then -- parte destra / right
            arm_positions.pickup.x = arm_positions.pickup.x + 1
        end
    elseif inserter_size.z >= 2 then
        if inserter_size.z == 3 then
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.allow_none_state = true
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.allow_none_state = true
        end

        if arm_positions.pickup.x < 0 then
            arm_positions.pickup.x = arm_positions.pickup.x + (inserter_size.z - 1)
        end
        if arm_positions.pickup.y < 0 then
            arm_positions.pickup.y = arm_positions.pickup.y + (inserter_size.z - 1)
        end
        if arm_positions.pickup.y == 0 then
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.visible = true
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.right_label_caption =
            "Buttom pickup"
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.left_label_caption = "Top pickup"
            if arm_positions.base.y == arm_positions.pure_pickup.y then
                gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.switch_state = "right"
            else
                gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.switch_state = "left"
            end
        elseif arm_positions.pickup.x == 0 then
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.visible = true
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.right_label_caption =
            "Right pickup"
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.left_label_caption =
            "Left pickup"
            if arm_positions.base.x == arm_positions.pure_pickup.x then
                gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.switch_state = "right"
            else
                gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position.switch_state = "left"
            end
        end

        if arm_positions.drop.x < 0 then
            arm_positions.drop.x = arm_positions.drop.x + (inserter_size.z - 1)
        end
        if arm_positions.drop.y < 0 then
            arm_positions.drop.y = arm_positions.drop.y + (inserter_size.z - 1)
        end
        if arm_positions.drop.y == 0 then
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.visible = true
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.right_label_caption =
            "Buttom drop"
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.left_label_caption = "Top drop"
            if arm_positions.base.y == arm_positions.pure_drop.y then
                gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.switch_state = "right"
            else
                gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.switch_state = "left"
            end
        elseif arm_positions.drop.x == 0 then
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.visible = true
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.right_label_caption =
            "Right drop"
            gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.left_label_caption = "Left drop"
            if arm_positions.base.x == arm_positions.pure_drop.x then
                gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.switch_state = "right"
            else
                gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position.switch_state = "left"
            end
        end
    end

    local idx = 0
    for y = -table_range, table_range, 1 do
        for x = -table_range, table_range, 1 do
            idx = idx + 1
            local button = gui_instance.pick_drop_flow.pick_drop_housing.table_position.children[idx]
            if button.type == "sprite-button" then
                button.enabled = gui.should_cell_be_enabled({ x = x, y = y }, inserter_range, player.force,
                    (slimn or slims), (slimo or slime), slim)

                if math2d.position.equal(arm_positions.drop, { x, y }) then
                    if directional_slim_inserter and slim then
                        button.sprite = "selected-drop"
                    else
                        button.sprite = "drop"
                    end
                elseif math2d.position.equal(arm_positions.pickup, { x, y }) then
                    if directional_slim_inserter and slim then
                        button.sprite = "selected-pickup"
                    else
                        button.sprite = "pickup"
                    end
                elseif x ~= 0 or y ~= 0 then
                    if directional_slim_inserter and slim and button.enabled == true then
                        if slimn and y > 0 then
                            button.sprite = "background-drop"
                        elseif slimn and y < 0 then
                            button.sprite = "background-pickup"
                        elseif slims and y < 0 then
                            button.sprite = "background-drop"
                        elseif slims and y > 0 then
                            button.sprite = "background-pickup"
                        elseif slime and x < 0 then
                            button.sprite = "background-drop"
                        elseif slime and x > 0 then
                            button.sprite = "background-pickup"
                        elseif slimo and x > 0 then
                            button.sprite = "background-drop"
                        elseif slimo and x < 0 then
                            button.sprite = "background-pickup"
                        else
                            button.sprite = nil
                        end
                    else
                        button.sprite = nil
                    end
                end
            end
        end
    end

    local icon = "item/inserter"
    if slim then
        icon = "circle"
    elseif inserter.prototype.items_to_place_this then
        icon = "item/" .. inserter.prototype.items_to_place_this[1].name
    end
    gui_instance.pick_drop_flow.pick_drop_housing.table_position.sprite_inserter.sprite = icon

    if offset_selector == false then
        return
    end

    local offset_tech_unlocked = tech.check_offset_tech(player.force)

    local idx = 0
    for y = -1, 1, 1 do
        for x = -1, 1, 1 do
            idx = idx + 1

            gui_instance.flow_offset.flow_pick.table_pick.children[idx].enabled = offset_tech_unlocked
            if math2d.position.equal(arm_positions.pickup_offset, { x, y }) then
                gui_instance.flow_offset.flow_pick.table_pick.children[idx].sprite = "pickup"
            else
                gui_instance.flow_offset.flow_pick.table_pick.children[idx].sprite = nil
            end
        end
    end

    local idx = 0
    for y = -1, 1, 1 do
        for x = -1, 1, 1 do
            idx = idx + 1

            gui_instance.flow_offset.flow_drop.table_drop.children[idx].enabled = offset_tech_unlocked
            if math2d.position.equal(arm_positions.drop_offset, { x, y }) then
                gui_instance.flow_offset.flow_drop.table_drop.children[idx].sprite = "drop"
            else
                gui_instance.flow_offset.flow_drop.table_drop.children[idx].sprite = nil
            end
        end
    end
end

function gui.update_all(inserter)
    for idx, player in pairs(game.players) do
        if (inserter and player.opened == inserter) or (not inserter and player.opened and player.opened.type == "inserter") then
            gui.update(player, player.opened)
        end
    end
end

function gui.get_button_pos(button)
    local idx = button.get_index_in_parent() - 1
    local len = button.parent.column_count
    local center = (len - 1) * -0.5 -- /2*-1
    return math2d.position.add({ idx % len, math.floor(idx / len) }, { center, center })
end

function gui.on_button_position(player, event)
    local inserter = player.opened
    local new_pos = gui.get_button_pos(event.element)
    local orientation = inserter_utils.get_inserter_orientation(inserter)
    local inserter_size = inserter_utils.get_inserter_size(inserter)
    local inserter_positions = inserter_utils.get_arm_positions(inserter)
    local slim = inserter_utils.is_slim(inserter)
    local slimn = slim and orientation == "N"
    local slime = slim and orientation == "E"
    local slims = slim and orientation == "S"
    local slimo = slim and orientation == "O"
    local new_positions

    if event.button == defines.mouse_button_type.left and not event.control and not event.shift then
        new_positions = { drop = new_pos }

        if event.element.sprite == "drop" then
            return
        end

        if event.element.sprite == "pickup" then
            new_positions.pickup = inserter_positions.drop

            if new_positions.pickup.y >= 0 and (slimn or slims) then
                new_positions.pickup.y = new_positions.pickup.y + 1
            elseif new_positions.pickup.x >= 0 and (slimo or slime) then
                new_positions.pickup.x = new_positions.pickup.x + 1
            end
            if (new_positions.pickup.y <= -1) and (inserter_size.z >= 2) then
                new_positions.pickup.y = new_positions.pickup.y + 1
            end
            if (new_positions.pickup.x <= -1) and (inserter_size.z >= 2) then
                new_positions.pickup.x = new_positions.pickup.x + 1
            end
        end

        new_positions.drop_offset = { x = 0, y = 0 }
        --Set the drop offset to the farthest side
        --[
        if new_pos.x < 0 and not (slimo or slime) then
            new_positions.drop_offset.x = -1
        elseif new_pos.x > 0 and not (slimo or slime) then
            new_positions.drop_offset.x = 1
        end

        if new_pos.y < 0 and not (slimn or slims) then
            new_positions.drop_offset.y = -1
        elseif new_pos.y > 0 and not (slimn or slims) then
            new_positions.drop_offset.y = 1
        end
        --]

        if gui.validate_button_placement(inserter, new_positions) then
            inserter_utils.set_arm_positions(inserter, new_positions)
        else
            return
        end
    elseif event.button == defines.mouse_button_type.right or (event.button == defines.mouse_button_type.left and (event.control or event.shift)) then
        new_positions = { pickup = new_pos }

        if event.element.sprite == "pickup" then
            return
        end

        if event.element.sprite == "drop" then
            new_positions.drop = inserter_positions.pickup

            if new_positions.drop.y >= 0 and (slimn or slims) then
                new_positions.drop.y = new_positions.drop.y + 1
            elseif new_positions.drop.x >= 0 and (slimo or slime) then
                new_positions.drop.x = new_positions.drop.x + 1
            end
            if (new_positions.drop.y <= -1) and (inserter_size.z >= 2) then
                new_positions.drop.y = new_positions.drop.y + 1
            end
            if (new_positions.drop.x <= -1) and (inserter_size.z >= 2) then
                new_positions.drop.x = new_positions.drop.x + 1
            end

            new_positions.drop_offset = { x = 0, y = 0 }
            if new_positions.drop.x < 0 and not (slimo or slime) then
                new_positions.drop_offset.x = -1
            elseif new_positions.drop.x > 0 and not (slimo or slime) then
                new_positions.drop_offset.x = 1
            end

            if new_positions.drop.y < 0 and not (slimn or slims) then
                new_positions.drop_offset.y = -1
            elseif new_positions.drop.y > 0 and not (slimn or slims) then
                new_positions.drop_offset.y = 1
            end
        end

        new_positions.pickup_offset = { x = 0, y = 0 }
        --[[
            if new_pos.x < 0 and not (slimo or slime) then
                new_positions.pickup_offset.x = -1
            elseif new_pos.x > 0 and not (slimo or slime) then
                new_positions.pickup_offset.x = 1
            end

            if new_pos.y < 0 and not (slimn or slims) then
                new_positions.pickup_offset.y = -1
            elseif new_pos.y > 0 and not (slimn or slims) then
                new_positions.pickup_offset.y = 1
            end
        --]]

        if gui.validate_button_placement(inserter, new_positions) then
            inserter_utils.set_arm_positions(inserter, new_positions)
        else
            return
        end
    end

    gui.update_all(inserter)
    if global.SI_Storage[event.player_index].is_selected and math2d.position.equal(player.opened.position, global.SI_Storage[event.player_index].selected_inserter.position) then
        local changes = {}
        if new_positions.drop then
            changes["drop"] = {
                old = {
                    x = inserter_positions.drop.x,
                    y = inserter_positions.drop.y,
                },
                new = {
                    x = new_positions.drop.x,
                    y = new_positions.drop.y,
                }
            }
        end
        if new_positions.pickup then
            changes["pickup"] = {
                old = {
                    x = inserter_positions.pickup.x,
                    y = inserter_positions.pickup.y,
                },
                new = {
                    x = new_positions.pickup.x,
                    y = new_positions.pickup.y,
                }
            }
        end

        world_editor.update_positions(event.player_index, player.opened, changes)
    end
end

function gui.on_button_drop_offset(player, event)
    local new_drop_offset = gui.get_button_pos(event.element)
    inserter_utils.set_arm_positions(player.opened, { drop_offset = new_drop_offset })

    gui.update(player, player.opened)
end

function gui.on_button_pick_offset(player, event)
    local new_pickup_offset = gui.get_button_pos(event.element)
    inserter_utils.set_arm_positions(player.opened, { pickup_offset = new_pickup_offset })

    gui.update(player, player.opened)
end

function gui.on_switch_drop_position(player, event)
    local inserter = player.opened
    local position = inserter_utils.get_arm_positions(inserter)
    local drop_position = position.drop

    local state = 0 -- "none"
    if event.element.switch_state == "right" then
        state = 1
    elseif event.element.switch_state == "left" then
        state = -1
    end

    local drop_adjust = { x = 0, y = 0 }

    if (drop_position.y >= 1) or (drop_position.y <= -2) then
        if position.base.x ~= position.pure_drop.x and event.element.switch_state == "left" then
            return
        elseif position.base.x == position.pure_drop.x and event.element.switch_state == "right" then
            return
        end
        if state == 1 then
            drop_adjust.x = 1
        else
            drop_adjust.x = -1
        end
    elseif (drop_position.x >= 1) or (drop_position.x <= -1) then
        if position.base.y ~= position.pure_drop.y and event.element.switch_state == "left" then
            return
        elseif position.base.y == position.pure_drop.y and event.element.switch_state == "right" then
            return
        end
        if state == 1 then
            drop_adjust.y = 1
        else
            drop_adjust.y = -1
        end
    end

    inserter_utils.set_arm_positions(inserter, { drop_adjust = drop_adjust })
    gui.update(player, inserter)
end

function gui.on_switch_pick_position(player, event)
    local inserter = player.opened
    local position = inserter_utils.get_arm_positions(inserter)
    local pickup_position = position.pickup

    local state = 0 -- "none"
    if event.element.switch_state == "right" then
        state = 1
    elseif event.element.switch_state == "left" then
        state = -1
    end

    local pickup_adjust = { x = 0, y = 0 }

    if (pickup_position.y >= 1) or (pickup_position.y <= -2) then
        if position.base.x ~= position.pure_pickup.x and event.element.switch_state == "left" then
            return
        elseif position.base.x == position.pure_pickup.x and event.element.switch_state == "right" then
            return
        end
        if state == 1 then
            pickup_adjust.x = 1
        else
            pickup_adjust.x = -1
        end
    elseif (pickup_position.x >= 1) or (pickup_position.x <= -1) then
        if position.base.y ~= position.pure_pickup.y and event.element.switch_state == "left" then
            return
        elseif position.base.y == position.pure_pickup.y and event.element.switch_state == "right" then
            return
        end
        if state == 1 then
            pickup_adjust.y = 1
        else
            pickup_adjust.y = -1
        end
    end

    inserter_utils.set_arm_positions(inserter, { pickup_adjust = pickup_adjust })
    gui.update(player, inserter)
end

function gui.validate_button_placement(inserter, positions)
    if not directional_slim_inserter then
        return true
    end

    local orientation = inserter_utils.get_inserter_orientation(inserter)
    local slim = inserter_utils.is_slim(inserter)
    local slimn = slim and orientation == "N"
    local slime = slim and orientation == "E"
    local slims = slim and orientation == "S"
    local slimo = slim and orientation == "O"

    if positions.pickup ~= nil then
        if slims and positions.pickup.y < 0 then
            return false
        end
        if slimn and positions.pickup.y > 0 then
            return false
        end
        if slimo and positions.pickup.x > 0 then
            return false
        end
        if slime and positions.pickup.x < 0 then
            return false
        end
    end

    if positions.drop ~= nil then
        if slims and positions.drop.y > 0 then
            return false
        end
        if slimn and positions.drop.y < 0 then
            return false
        end
        if slimo and positions.drop.x < 0 then
            return false
        end
        if slime and positions.drop.x > 0 then
            return false
        end
    end

    return true
end

function gui.should_show(entity)
    --What an ugly ass piece of code... I rellay hate checking strings in this way to filter something, it's reliability is below 0...
    local prototype_history = script.get_prototype_history(entity.type, entity.name)

    for _, v in pairs(blacklist.mods) do
        if string.find(prototype_history.created, v) then
            return false
        end
    end

    for _, v in pairs(blacklist.entities) do
        if string.find(entity.name, v) then
            return false
        end
    end

    return true
end

-- ------------------------------
-- SI_Storage
-- ------------------------------
function storage_functions.populate_storage()
    for player_index, _ in pairs(game.players) do
        global.SI_Storage[player_index] = {}
        global.SI_Storage[player_index]["is_selected"] = false
        global.SI_Storage[player_index]["selected_inserter"] = {}

        global.SI_Storage[player_index].selected_inserter["position"] = { x = "", y = "" }
        global.SI_Storage[player_index].selected_inserter["name"] = ""
        global.SI_Storage[player_index].selected_inserter["drop"] = { x = "", y = "" }
        global.SI_Storage[player_index].selected_inserter["pickup"] = { x = "", y = "" }

        global.SI_Storage[player_index].selected_inserter["position_grid"] = {}
        local tmp = {}
        local x_string
        for x = -5, 5, 1 do
            x_string = tostring(x)
            global.SI_Storage[player_index].selected_inserter["position_grid"][x_string] = {}
            tmp[x_string] = { loaded = false }
        end
        for y = -5, 5, 1 do
            global.SI_Storage[player_index].selected_inserter["position_grid"][tostring(y)] = deepcopy(tmp)
        end
        rendering.clear("Smart_Inserters")
    end
end

function storage_functions.add_player(player_index)
    global.SI_Storage[player_index] = {}
    global.SI_Storage[player_index]["is_selected"] = false
    global.SI_Storage[player_index]["selected_inserter"] = {}

    global.SI_Storage[player_index].selected_inserter["position"] = { x = "", y = "" }
    global.SI_Storage[player_index].selected_inserter["name"] = ""
    global.SI_Storage[player_index].selected_inserter["surface"] = ""
    global.SI_Storage[player_index].selected_inserter["drop"] = { x = "", y = "" }
    global.SI_Storage[player_index].selected_inserter["pickup"] = { x = "", y = "" }

    global.SI_Storage[player_index].selected_inserter["position_grid"] = {}
    local tmp = {}
    local x_string
    for x = -5, 5, 1 do
        x_string = tostring(x)
        global.SI_Storage[player_index].selected_inserter["position_grid"][x_string] = {}
        tmp[x_string] = { loaded = false }
    end
    for y = -5, 5, 1 do
        global.SI_Storage[player_index].selected_inserter["position_grid"][tostring(y)] = deepcopy(tmp)
    end
end

function storage_functions.ensure_data(player_index)
    player_index = player_index and player_index or false
    if global.SI_Storage == nil then global.SI_Storage = {} end
    if player_index and not global.SI_Storage[player_index] then
        storage_functions.add_player(player_index)
    end
    return global.SI_Storage[player_index]
end

-- ------------------------------
-- Player functions
-- ------------------------------
function player_functions.safely_change_cursor(player, item)
    item = item or false
    player.cursor_stack.clear()
    if item == false then return end
    return player.cursor_stack.set_stack(item)
end

function player_functions.configure_pickup_drop_changher(player, is_drop)
    if player.cursor_stack.is_blueprint then --and player.cursor_stack.name == "si-in-world-pikcup-drop-changer"
        player.cursor_stack.set_blueprint_entities({ {
            name = "si-in-world-" .. is_drop .. "-entity",
            entity_number = 1,
            position = { 0, 0 }
        } })
        player.cursor_stack.blueprint_absolute_snapping = true
        player.cursor_stack.blueprint_snap_to_grid      = { 1, 0 }
    end
end

-- ------------------------------
-- Event Handlers
-- ------------------------------
-- Mod init
local function on_init()
    global.SI_Storage = {}
    storage_functions.populate_storage()
    gui.create_all()
end

local function welcome()
    game.print({ "smart-inserters.welcome" })
end

local function on_configuration_changed(cfg_changed_data)
    gui.create_all()
    gui.update_all()
    tech.update_all()
    storage_functions.ensure_data()
    storage_functions.populate_storage()
end

local function on_player_created(event)
    local player = game.players[event.player_index]
    gui.create(player)
    storage_functions.add_player(event.player_index)
end

local function on_entity_settings_pasted(event)
    if event.destination.type == "inserter" then
        event.destination.direction = event.source.direction
        inserter_utils.enforce_max_range(event.destination)
        storage_functions.populate_storage()
        gui.update_all(event.destination)
    end
end


-- Gui Events
local function on_gui_opened(event)
    local player = game.players[event.player_index]

    if event.entity and event.entity.type == "inserter" then
        gui.update(player, event.entity)
    end
end

local function on_gui_click(event)
    local player = game.players[event.player_index]
    local gui_instance = player.gui.relative.inserter_config.frame_content.flow_content

    if event.element.parent == gui_instance.pick_drop_flow.pick_drop_housing.table_position and event.element ~= gui_instance.pick_drop_flow.pick_drop_housing.table_position.sprite_inserter then
        gui.on_button_position(player, event)
    elseif offset_selector and event.element.parent == gui_instance.flow_offset.flow_drop.table_drop then
        gui.on_button_drop_offset(player, event)
    elseif offset_selector and event.element.parent == gui_instance.flow_offset.flow_pick.table_pick then
        gui.on_button_pick_offset(player, event)
    elseif event.element == gui_instance.pick_drop_flow.pick_drop_housing.inserter_drop_switch_position then
        gui.on_switch_drop_position(player, event)
    elseif event.element == gui_instance.pick_drop_flow.pick_drop_housing.inserter_pick_switch_position then
        gui.on_switch_pick_position(player, event)
    end
end

local function on_player_rotated_entity(event)
    if event.entity.type == "inserter" then
        gui.update_all(event.entity)
        world_editor.update_all_positions(event.entity)
    end
end


-- Hotkey Events
local function on_rotation_adjust(event)
    local player = game.players[event.player_index]
    if inserter_utils.is_inserter(player.selected) then
        local inserter = player.selected

        local slim = inserter_utils.is_slim(inserter)
        local size = inserter_utils.get_inserter_size(inserter)
        if slim then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-slim-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end
        if size.z > 1 then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-big-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local is_drop = string.find(event.input_name, "drop", 17) and true or false
        local direction = string.find(event.input_name, "reverse", -7) and -1 or 1

        local target = is_drop and "drop" or "pickup"
        local check = is_drop and "pickup" or "drop"

        local arm_positions = inserter_utils.get_arm_positions(inserter)

        local range = math.max(math.abs(arm_positions[target].x), math.abs(arm_positions[target].y))

        local old_direction = math2d.direction.from_vector(arm_positions[target], range)

        local new_direction = (old_direction + direction) % (8 * range)
        local new_tile = math2d.direction.to_vector(new_direction, range)

        while not tech.check_diagonal_tech(player.force, new_tile) do
            new_direction = (new_direction + direction) % (8 * range)
            new_tile = math2d.direction.to_vector(new_direction, range)
        end

        if math2d.position.equal(new_tile, arm_positions[check]) then
            new_direction = (new_direction + direction) % (8 * range)
            new_tile = math2d.direction.to_vector(new_direction, range)
            while not tech.check_diagonal_tech(player.force, new_tile) do
                new_direction = (new_direction + direction) % (8 * range)
                new_tile = math2d.direction.to_vector(new_direction, range)
            end
        end

        local new_arm_positions = {}
        new_arm_positions[target] = new_tile
        new_arm_positions[target .. "_offset"] = inserter_utils.calc_rotated_offset(inserter, new_tile, direction, target)

        new_arm_positions[target] = new_tile
        inserter_utils.set_arm_positions(inserter, new_arm_positions)

        gui.update_all(inserter)
    end
end

local function on_distance_adjust(event)
    local player = game.players[event.player_index]
    if inserter_utils.is_inserter(player.selected) then
        local inserter = player.selected

        local slim = inserter_utils.is_slim(inserter)
        local size = inserter_utils.get_inserter_size(inserter)

        if slim then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-slim-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end
        if size.z > 1 then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-big-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local is_drop = string.find(event.input_name, "drop", 17) and true or false

        local target = is_drop and "drop" or "pickup"
        local check = is_drop and "pickup" or "drop"

        local arm_positions = inserter_utils.get_arm_positions(inserter)

        local range = math.max(math.abs(arm_positions[target].x), math.abs(arm_positions[target].y))
        local max_range = inserter_utils.get_max_range(inserter)
        local dir = math2d.direction.transform_to_vector1(arm_positions[target], range)

        local new_range = (range % max_range) + 1

        local new_positions = {}

        local pos = math2d.direction.upscale_vec1(dir, new_range)

        new_positions[target] = math2d.direction.to_vector(pos, new_range)

        if not tech.check_range_tech(player.force, new_positions[target]) then
            pos = math2d.direction.upscale_vec1(dir, 1)
            new_positions[target] = math2d.direction.to_vector(pos, 1)
        end

        if new_positions[target].x == arm_positions[check].x and new_positions[target].y == arm_positions[check].y then
            new_range = (range % max_range) + 1
            pos = math2d.direction.upscale_vec1(dir, new_range)
            new_positions[target] = math2d.direction.to_vector(pos, new_range)
        end

        inserter_utils.set_arm_positions(inserter, new_positions)
        gui.update_all(inserter)
    end
end

local function on_drop_offset_adjust(event)
    local player = game.players[event.player_index]
    if inserter_utils.is_inserter(player.selected) then
        local inserter = player.selected

        if not tech.check_offset_tech(player.force) then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.required-technology-missing" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local is_drop       = string.find(event.input_name, "drop", 17) and true or false

        local target        = is_drop and "drop" or "pickup"

        local lateral       = string.find(event.input_name, "lateral", -7) ~= nil

        local arm_positions = inserter_utils.get_arm_positions(inserter)

        local dir           = math2d.direction.from_vector(arm_positions[target])

        dir                 = dir % 2 == 0 and dir or 0

        local axis          = (dir % 4 == 0 ~= lateral) and "y" or "x"

        local new_offset    = arm_positions[target .. "_offset"]
        new_offset[axis]    = ((arm_positions[target .. "_offset"][axis] + 2) % 3) - 1

        inserter_utils.set_arm_positions(inserter, { [target .. "_offset"] = new_offset })

        gui.update_all(inserter)
    end
end

local function on_in_world_editor(event)
    local player = game.players[event.player_index]
    local is_drop = string.find(event.input_name, "drop", 31) and "drop" or "pickup"
    storage_functions.ensure_data(event.player_index)
    if player.cursor_stack.is_blueprint then
        local is_drop_changer = (player.cursor_stack.name == "si-in-world-drop-changer")
        local is_pickup_changer = (player.cursor_stack.name == "si-in-world-pickup-changer")
        if is_drop_changer and is_drop == "pickup" then
            player_functions.safely_change_cursor(player, "si-in-world-pickup-changer")
            player_functions.configure_pickup_drop_changher(player, is_drop)
            return
        elseif is_drop_changer and is_drop == "drop" then
            global.SI_Storage[event.player_index]["is_selected"] = false
            player_functions.safely_change_cursor(player)
            world_editor.clear_positions(event.player_index)
            return
        elseif is_pickup_changer and is_drop == "drop" then
            player_functions.safely_change_cursor(player, "si-in-world-drop-changer")
            player_functions.configure_pickup_drop_changher(player, is_drop)
            return
        elseif is_pickup_changer and is_drop == "pickup" then
            global.SI_Storage[event.player_index]["is_selected"] = false
            player_functions.safely_change_cursor(player)
            world_editor.clear_positions(event.player_index)
            return
        end
    end
    if player.selected and inserter_utils.is_inserter(player.selected) and player.selected.position then
        local slim = inserter_utils.is_slim(player.selected)
        local size = inserter_utils.get_inserter_size(player.selected)
        if slim then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = player.selected.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-slim-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end
        if size.z > 1 then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = player.selected.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-big-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local arm_positions = inserter_utils.get_arm_positions(player.selected)
        global.SI_Storage[event.player_index].is_selected = true
        global.SI_Storage[event.player_index].selected_inserter.name = player.selected.name
        global.SI_Storage[event.player_index].selected_inserter.surface = player.selected.surface
        global.SI_Storage[event.player_index].selected_inserter.position = math2d.position.ensure_xy(player.selected
        .position)
        global.SI_Storage[event.player_index].selected_inserter.drop = arm_positions.drop
        global.SI_Storage[event.player_index].selected_inserter.pickup = arm_positions.pickup
        world_editor.draw_positions(event.player_index, player.selected)
        player_functions.safely_change_cursor(player, "si-in-world-" .. is_drop .. "-changer")
        player_functions.configure_pickup_drop_changher(player, is_drop)
    end
end


-- World editor events
local function on_built_entity(event)
    local entity = event.created_entity and event.created_entity or event.entity
    if entity.name ~= "entity-ghost" then return end
    if entity.ghost_name ~= "si-in-world-drop-entity" and entity.ghost_name ~= "si-in-world-pickup-entity" then
        return
    end

    local player = game.players[event.player_index]
    local storage = storage_functions.ensure_data(event.player_index)

    local is_drop = string.find(entity.ghost_name, "drop", 11) and "drop" or "pickup"
    local is_pickup = (is_drop == "drop") and "pickup" or "drop"
    local position = entity.position
    if storage.is_selected == false then
        ---@diagnostic disable-next-line: missing-fields
        player.surface.create_entity({
            name = "flying-text",
            position = position,
            text = { "flying-text-smart-inserters.no-inserter-selected" },
            color = { 0.8, 0.8, 0.8 }
        })
        world_editor.clear_positions(event.player_index)
        entity.destroy()
        return
    end

    -- Inserter Data
    local inserter = player.surface.find_entity(storage.selected_inserter.name, storage.selected_inserter.position)
    local inserter_ghost = player.surface.find_entity("entity-ghost", storage.selected_inserter.position)
    inserter = inserter and inserter or inserter_ghost
    local arm_positions = inserter_utils.get_arm_positions(inserter)

    local diff = math2d.position.subtract(storage.selected_inserter.position, position)
    diff = math2d.round(diff)
    diff = math2d.position.multiply_scalar(diff, -1)

    if math2d.position.equal(arm_positions[is_drop], diff) then
        entity.destroy()
        return
    end

    if math2d.position.equal(diff, { 0, 0 }) then
        ---@diagnostic disable-next-line: missing-fields
        player.surface.create_entity({
            name = "flying-text",
            position = position,
            text = { "flying-text-smart-inserters.invalid-position" },
            color = { 0.8, 0.8, 0.8 }
        })
        entity.destroy()
        return
    end

    local max_range = inserter_utils.get_max_range(inserter)
    local range = math.max(math.abs(diff.x), math.abs(diff.y))
    if range <= max_range then
        if tech.check_tech(player.force, diff) then
            math2d.direction.from_vector(diff, range)
            local set = {}
            local changes = {}
            if math2d.position.equal(arm_positions[is_pickup], diff) then
                arm_positions[is_drop] = math2d.no_minus_0(arm_positions[is_drop])
                arm_positions[is_pickup] = math2d.no_minus_0(arm_positions[is_pickup])

                set[is_drop] = arm_positions[is_pickup]
                changes[is_drop] = {
                    old = {
                        x = arm_positions[is_drop].x,
                        y = arm_positions[is_drop].y
                    },
                    new = {
                        x = arm_positions[is_pickup].x,
                        y = arm_positions[is_pickup].y
                    }
                }
                set[is_pickup] = arm_positions[is_drop]
                changes[is_pickup] = {
                    old = {
                        x = arm_positions[is_pickup].x,
                        y = arm_positions[is_pickup].y
                    },
                    new = {
                        x = arm_positions[is_drop].x,
                        y = arm_positions[is_drop].y
                    }
                }
            else
                diff = math2d.no_minus_0(diff)
                arm_positions[is_drop] = math2d.no_minus_0(arm_positions[is_drop])
                set[is_drop] = diff
                changes[is_drop] = {
                    old = {
                        x = arm_positions[is_drop].x,
                        y = arm_positions[is_drop].y
                    },
                    new = {
                        x = diff.x,
                        y = diff.y
                    }
                }
            end

            if set["drop"] then
                set["drop_offset"] = { x = 0, y = 0 }
                --Set the drop offset to the farthest side
                --[
                if changes["drop"].new.x < 0 then
                    set.drop_offset.x = -1
                elseif changes["drop"].new.x > 0 then
                    set.drop_offset.x = 1
                end

                if changes["drop"].new.y < 0 then
                    set.drop_offset.y = -1
                elseif changes["drop"].new.y > 0 then
                    set.drop_offset.y = 1
                end
            end

            inserter_utils.set_arm_positions(inserter, set)
            world_editor.update_positions(event.player_index, inserter, changes)
            gui.update(player, inserter)
        else
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = position,
                text = { "flying-text-smart-inserters.required-technology-missing" },
                color = { 0.8, 0.8, 0.8 }
            })
        end
    else
        ---@diagnostic disable-next-line: missing-fields
        player.surface.create_entity({
            name = "flying-text",
            position = position,
            text = { "flying-text-smart-inserters.out-of-range" },
            color = { 0.8, 0.8, 0.8 }
        })
    end
    entity.destroy()
end

local function on_player_cursor_stack_changed(event)
    local player = game.players[event.player_index]
    if player.cursor_stack.is_blueprint then
        local is_drop_changer = (player.cursor_stack.name == "si-in-world-drop-changer")
        local is_pickup_changer = (player.cursor_stack.name == "si-in-world-pickup-changer")
        if is_drop_changer or is_pickup_changer then
            return
        end
    else
        world_editor.clear_positions(event.player_index)
    end
end

local function on_entity_destroyed(event)
    if not inserter_utils.is_inserter(event.entity) then
        return
    end
    for player_index, player in pairs(game.players) do
        storage_functions.ensure_data(player_index)
        if global.SI_Storage[player_index].is_selected == true and math2d.position.equal(global.SI_Storage[player_index].selected_inserter.position, event.entity.position) then
            world_editor.clear_positions(player_index)
            player_functions.safely_change_cursor(player)
        end
    end
end

-- ------------------------------
-- Eventhandler registration
-- ------------------------------

-- Player and Init events
script.on_init(on_init)
script.on_event(defines.events.on_cutscene_cancelled, welcome)
script.on_event(defines.events.on_cutscene_finished, welcome)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_created, on_player_created)

-- Gui events
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_player_rotated_entity, on_player_rotated_entity)
script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

-- Shortcut events
script.on_event("smart-inserters-drop-rotate", on_rotation_adjust)
script.on_event("smart-inserters-drop-rotate-reverse", on_rotation_adjust)
script.on_event("smart-inserters-pickup-rotate", on_rotation_adjust)
script.on_event("smart-inserters-pickup-rotate-reverse", on_rotation_adjust)
script.on_event("smart-inserters-pickup-distance-adjust", on_distance_adjust)
script.on_event("smart-inserters-drop-distance-adjust", on_distance_adjust)
script.on_event("smart-inserters-drop-offset-adjust-lateral", on_drop_offset_adjust)
script.on_event("smart-inserters-drop-offset-adjust-distance", on_drop_offset_adjust)
script.on_event("smart-inserters-pickup-offset-adjust-lateral", on_drop_offset_adjust)
script.on_event("smart-inserters-pickup-offset-adjust-distance", on_drop_offset_adjust)

-- World editor events
script.on_event("smart-inserters-in-world-inserter-configurator-pickup", on_in_world_editor)
script.on_event("smart-inserters-in-world-inserter-configurator-drop", on_in_world_editor)
script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)


local function test_built(event)
    print(event.name)
    print("Event built called")
end

local function test_destroy(event)
    print(event.name)
    print("Event destroy called")
end

script.on_event(defines.events.script_raised_built, test_built)
script.on_event(defines.events.script_raised_destroy, test_destroy)

--script.on_event(defines.events.script_raised_built, on_built_entity)
--script.on_event(defines.events.script_raised_destroy, on_entity_destroyed)

script.on_event(defines.events.on_player_mined_entity, on_entity_destroyed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_destroyed)
--script.on_event(defines.events.on_entity_died, on_entity_destroyed)
--script.on_event(defines.events.on_entity_destroyed, on_entity_destroyed)

-- TODO optimize tech check (valid position checking)