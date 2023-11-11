local inserters_range = settings.startup["si-max-inserters-range"].value

local math2d = require("scripts.extended_math2d")
local inserter_functions = {}

function inserter_functions.get_prototype(inserter)
    if inserter.type == "entity-ghost" then
        return inserter.ghost_prototype
    end
    return inserter.prototype
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
        return inserters_range
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
        if force.technologies["si-unlock-range-4"].researched then
            added_range = 4
        elseif force.technologies["si-unlock-range-3"].researched then
            added_range = 3
        elseif force.technologies["si-unlock-range-2"].researched then
            added_range = 2
        elseif force.technologies["si-unlock-range-1"].researched then
            added_range = 1
        end
        ---@diagnostic disable-next-line: param-type-mismatch
        return math.min(inserter_range + added_range, inserters_range)
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
    new_direction = (new_direction == 0) and 8 or new_direction
    local spostamento = (8 - inserter.direction) - (8 - new_direction)
    spostamento = (spostamento < 0) and (8 + spostamento) or spostamento

    while spostamento ~= 0 do
        new_position = { y = new_position.x * -1, x = new_position.y }
        spostamento = spostamento - 2
    end

    return new_position
end

function inserter_functions.calc_rotated_offset(inserter, new_position, target)
    local old_positions = inserter_functions.get_arm_positions(inserter)
    local target_offset = old_positions[target .. "_offset"]

    if target_offset.x == 0 and target_offset.y == 0 then
        return target_offset
    end

    local range = math.max(math.abs(old_positions[target].x), math.abs(old_positions[target].y))
    local position = math2d.direction.from_vector(target_offset)
    local old_sector = math2d.direction.vector_to_vec1_position(old_positions[target], range)

    if type(new_position) == "number" then
        new_position = inserter_functions.calc_rotated_position(inserter, target_offset, new_position)
    end

    local new_sector = math2d.direction.vector_to_vec1_position(new_position, range)

    if old_sector ~= new_sector then
        local spostamento = (8 - old_sector) - (8 - new_sector)
        position = (position + spostamento) % 8 + 1
        return math2d.direction.vectors1[position]
    end

    return target_offset
end


function inserter_functions.inserter_default_range(inserter)
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

    local function calculate_new_position(base_tile, target_position, edit_condition)
        local new_tile = base_tile

        if target_position then
            local edit = { x = 0, y = 0 }
            if slim then
                if edit_condition(target_position) then
                    edit = target_position.y < 0 and { 0, -1 } or { -1, 0 }
                end
            elseif inserter_size.z >= 2 then
                if target_position.x < 0 then
                    edit.x = edit.x - (inserter_size.z - 1)
                end
                if target_position.y < 0 then
                    edit.y = edit.y - (inserter_size.z - 1)
                end
            end
            new_tile = math2d.position.add(base_tile, math2d.position.add(target_position, edit))
        end

        return new_tile
    end

    local function calculate_new_offset(target_offset, old_offset)
        return target_offset and math2d.position.add(math2d.position.multiply_scalar(target_offset, 0.2), { 0.5, 0.5 }) or old_offset
    end

    if positions.pickup or positions.pickup_offset or positions.pickup_adjust then
        local base_tile, _ = math2d.position.split(inserter.position)
        local old_pickup_tile, old_pickup_offset = math2d.position.split(inserter.pickup_position)

        local new_pickup_tile = calculate_new_position(
            base_tile, positions.pickup, function(pos) return (slims or slimn) and pos.y >= 0 or (slime or slimo) and pos.x >= 0 end
        )

        new_pickup_tile = positions.pickup_adjust and math2d.position.add(new_pickup_tile, positions.pickup_adjust) or new_pickup_tile
        local new_pickup_offset = calculate_new_offset(positions.pickup_offset, old_pickup_offset)

        inserter.pickup_position = math2d.position.add(new_pickup_tile, new_pickup_offset)
    end

    if positions.drop or positions.drop_offset or positions.drop_adjust then
        local base_tile, _ = math2d.position.split(inserter.position)
        local old_drop_tile, old_drop_offset = math2d.position.split(inserter.drop_position)

        local new_drop_tile = calculate_new_position(
            base_tile, positions.drop, function(pos) return (slims or slimn) and pos.y < 0 or (slime or slimo) and pos.x < 0 end
        )

        new_drop_tile = positions.drop_adjust and math2d.position.add(new_drop_tile, positions.drop_adjust) or new_drop_tile
        local new_drop_offset = calculate_new_offset(positions.drop_offset, old_drop_offset)

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