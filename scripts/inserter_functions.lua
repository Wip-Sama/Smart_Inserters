local math2d = require("scripts.extended_math2d")
local storage_functions = require("scripts.storage_functions")
local util = require("scripts.util")
local inserter_functions = {}

function inserter_functions.get_prototype(inserter)
    if inserter.type == "entity-ghost" then
        return inserter.ghost_prototype
    end
    return inserter.prototype
end

function inserter_functions.calculate_max_inserters_range()
    storage_functions.ensure_data()
    if settings.startup["si-range-adder"].value ~= "incremental" then
        global.SI_Storage["inserters_range"] = settings.startup["si-max-inserters-range"].value
        return
    end

    local max_range = 0
    for _, prototype in pairs(game.entity_prototypes) do
        if prototype.type == "inserter" and util.check_blacklist({type = prototype.type, name = prototype.name}) then
            local inserter = prototype
            local prototype = inserter.object_name == "LuaEntity" and inserter_functions.get_prototype(inserter) or inserter
            local pickup_pos = math2d.position.tilepos(math2d.position.add(prototype.inserter_pickup_position, { 0.5, 0.5 }))
            local drop_pos = math2d.position.tilepos(math2d.position.add(prototype.inserter_drop_position, { 0.5, 0.5 }))
            local inserter_range = math.max(math.abs(pickup_pos.x), math.abs(pickup_pos.y), math.abs(drop_pos.x),
                math.abs(drop_pos.y))
            max_range = math.max(inserter_range, max_range)
        end
    end
    local somma = settings.startup["si-max-inserters-range"].value+max_range
    global.SI_Storage["inserters_range"] = somma
end

function inserter_functions.get_max_inserters_range()
    return global.SI_Storage["inserters_range"]
end

function inserter_functions.get_inserter_size(inserter)
    local height = math.ceil(inserter.tile_height)
    local width = math.ceil(inserter.tile_width)
    return { x = inserter.tile_width, y = inserter.tile_height, z = math.max(width, height) }
end

function inserter_functions.is_inserter(entity)
    return entity and (entity.type == "inserter" or (entity.type == "entity-ghost" and entity.ghost_type == "inserter"))
end

function inserter_functions.is_slim(inserter)
    if inserter.tile_height == 0 or inserter.tile_width == 0 then
        return true
    end
    return false
end

function inserter_functions.get_arm_positions(inserter)
    local base_tile, base_offset = math2d.position.split(inserter.position)
    local drop_tile, drop_offset = math2d.position.split(inserter.drop_position)
    local pickup_tile, pickup_offset = math2d.position.split(inserter.pickup_position)

    local function get_offset_vector(offset)
        local offset_vec = { x = 0, y = 0 }

        if offset.x > 0.5 then
            offset_vec.x = 1
        elseif offset.x < 0.5 then
            offset_vec.x = -1
        end

        if offset.y > 0.5 then
            offset_vec.y = 1
        elseif offset.y < 0.5 then
            offset_vec.y = -1
        end

        return offset_vec
    end

    local result = {
        base = base_tile,
        base_offset = base_offset,
        drop = math2d.position.subtract(drop_tile, base_tile),
        pure_drop = drop_tile,
        drop_offset = get_offset_vector(drop_offset),
        pure_drop_offset = drop_offset,
        pickup = math2d.position.subtract(pickup_tile, base_tile),
        pickup_offset = get_offset_vector(pickup_offset),
        pure_pickup = pickup_tile,
        pure_pickup_offset = pickup_offset,
    }

    return result
end

function inserter_functions.get_max_range(inserter, force)
    local range_adder_setting = settings.startup["si-range-adder"].value

    if range_adder_setting == "equal" then
        return global.SI_Storage["inserters_range"]
    end

    local prototype = inserter.object_name == "LuaEntity" and inserter_functions.get_prototype(inserter) or inserter
    local pickup_pos = math2d.position.tilepos(math2d.position.add(prototype.inserter_pickup_position, { 0.5, 0.5 }))
    local drop_pos = math2d.position.tilepos(math2d.position.add(prototype.inserter_drop_position, { 0.5, 0.5 }))
    local inserter_range = math.max(math.abs(pickup_pos.x), math.abs(pickup_pos.y), math.abs(drop_pos.x),
        math.abs(drop_pos.y))

    if range_adder_setting == "inserter" then
        return inserter_range
    elseif range_adder_setting == "incremental" then
        local added_range = 0
        if force.technologies["si-unlock-range-4"].researched and force.technologies["si-unlock-range-4"].prototype.hidden == false then
            added_range = 4
        elseif force.technologies["si-unlock-range-3"].researched and force.technologies["si-unlock-range-3"].prototype.hidden == false then
            added_range = 3
        elseif force.technologies["si-unlock-range-2"].researched and force.technologies["si-unlock-range-2"].prototype.hidden == false then
            added_range = 2
        elseif force.technologies["si-unlock-range-1"].researched and force.technologies["si-unlock-range-1"].prototype.hidden == false then
            added_range = 1
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        return math.min(inserter_range + added_range, global.SI_Storage["inserters_range"])
    end
end

function inserter_functions.enforce_max_range(inserter, force)
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    local max_range = inserter_functions.get_max_range(inserter, force)

    local function enforce_position_limit(position)
        local abs_position = math2d.position.abs(position)
        if math.max(abs_position.x, abs_position.y) > max_range then
            local new_position = math2d.position.multiply_scalar(
                math2d.direction.to_vector(math2d.direction.from_vector(position)), max_range)
            return new_position
        end
        return position
    end

    arm_positions.drop = enforce_position_limit(arm_positions.drop)
    arm_positions.pickup = enforce_position_limit(arm_positions.pickup)

    if math2d.position.equal(arm_positions.pickup, arm_positions.drop) then
        arm_positions.pickup = { x = -arm_positions.drop.x, y = -arm_positions.drop.y }
    end

    inserter_functions.set_arm_positions(inserter, arm_positions)
end

function inserter_functions.calc_rotated_position(inserter, new_position, new_direction)
    new_direction = new_direction == 0 and 8 or new_direction
    local spostamento = (8 - inserter.direction) - (8 - new_direction)
    if spostamento < 0 then spostamento = 8 + spostamento end
    local tmp_pos = 0

    while spostamento ~= 0 do
        tmp_pos = new_position.y * -1
        new_position.y = new_position.x
        new_position.x = tmp_pos
        spostamento = spostamento - 2
    end

    return new_position
end

function inserter_functions.calc_rotated_offset(inserter, new_position, target)
    local old_positions = inserter_functions.get_arm_positions(inserter)

    if old_positions[target .. "_offset"].x == 0 and old_positions[target .. "_offset"].y == 0 then
        return old_positions[target .. "_offset"]
    end

    local range = math.max(math.abs(old_positions[target].x), math.abs(old_positions[target].y))

    local position = math2d.direction.from_vector(old_positions[target .. "_offset"])

    local old_sector = math2d.direction.vector_to_vec1_position(old_positions[target], range)
    if type(new_position) == "number" then
        new_position = inserter_functions.calc_rotated_position(inserter, old_positions[target .. "_offset"], new_position)
    end
    local new_sector = math2d.direction.vector_to_vec1_position(new_position, range)

    if old_sector ~= new_sector then
        local spostamento = (8 - old_sector) - (8 - new_sector)
        position = position + spostamento
        position = (position % 8) + 1
        return math2d.direction["vectors1"][position]
    end

    return old_positions[target .. "_offset"]
end

function util.inserter_default_range(inserter)
    local collision_box_total = 0.2

    if inserter.collision_box then
        local collision_box_1 = math2d.position.ensure_xy(inserter.collision_box.left_top)
        local collision_box_2 = math2d.position.ensure_xy(inserter.collision_box.right_bottom)
        local collision_box_1_max = math.max(math.abs(collision_box_1.x), math.abs(collision_box_1.y))
        local collision_box_2_max = math.max(math.abs(collision_box_2.x), math.abs(collision_box_2.y))
        collision_box_total = collision_box_1_max + collision_box_2_max
    end

    local biggest = { x = 0, y = 0, z = 0 }
    local pickup_position = math2d.position.ensure_xy(inserter.inserter_pickup_position)
    local insert_position = math2d.position.ensure_xy(inserter.inserter_drop_position)
    biggest.x = math.max(math.abs(pickup_position.x), math.abs(insert_position.x))
    biggest.y = math.max(math.abs(pickup_position.y), math.abs(insert_position.y))
    biggest.z = math.max(biggest.x, biggest.y) - collision_box_total

    return biggest.z
end

function inserter_functions.set_arm_positions(inserter, positions)
    local orientation = inserter_functions.get_inserter_orientation(inserter)
    local slim = inserter_functions.is_slim(inserter)
    local inserter_size = inserter_functions.get_inserter_size(inserter)
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
                if (slims or slimn) and positions.pickup.y >= 0 then -- parte bassa / lower half
                    edit.y = edit.y - 1
                elseif (slime or slimo) and positions.pickup.x >= 0 then -- parte destra / right
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

function inserter_functions.get_inserter_orientation(inserter)
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

return inserter_functions