local math2d = require("__yafla__/scripts/extended_math2d")
local storage_functions = require("scripts.storage_functions")
local util = require("scripts.si_util")

local inserter_functions = {}

--Cleaned
function inserter_functions.get_prototype(inserter)
    return inserter.type == "entity-ghost" and inserter.ghost_prototype or inserter.prototype
end

--Cleaned (? didn't really do much)
function inserter_functions.calculate_max_inserters_range()
    storage_functions.ensure_data()
    if settings.startup["si-range-adder"].value ~= "incremental" then
        global.SI_Storage["inserters_range"] = settings.startup["si-max-inserters-range"].value
        return
    end

    local max_range = 0
    for _, prototype in pairs(game.entity_prototypes) do
        if prototype.type == "inserter" and util.check_blacklist({ type = prototype.type, name = prototype.name }) then
            local prototype = prototype.object_name == "LuaEntity" and inserter_functions.get_prototype(prototype) or prototype
            local pickup_pos = math2d.position.tilepos(math2d.position.add(prototype.inserter_pickup_position, { 0.5, 0.5 }))
            local drop_pos = math2d.position.tilepos(math2d.position.add(prototype.inserter_drop_position, { 0.5, 0.5 }))
            local inserter_range = math.max(
                    math.abs(pickup_pos.x),
                    math.abs(pickup_pos.y),
                    math.abs(drop_pos.x),
                    math.abs(drop_pos.y)
                )
            if inserter_range > max_range then
                print(prototype.name, inserter_range, max_range) --Debug (the inserters that affect this calculation)
                max_range = inserter_range
            end
        end
    end

    global.SI_Storage["inserters_range"] = settings.startup["si-max-inserters-range"].value + max_range-1
end

--Cleaned (maybe just remove it)
function inserter_functions.get_max_inserters_range()
    return global.SI_Storage["inserters_range"]
end

--Cleaned
function inserter_functions.is_slim(inserter)

    return (inserter.tile_height == 0 or inserter.tile_width == 0)
end


--Cleaned
function inserter_functions.get_inserter_size(inserter)
    if inserter_functions.is_slim(inserter) then
        return 0
    end
    return math.ceil(math.max(inserter.tile_width, inserter.tile_height))
end

--Cleaned
function inserter_functions.is_inserter(entity)
    return entity and (entity.type == "inserter" or (entity.type == "entity-ghost" and entity.ghost_type == "inserter"))
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
        drop_offset = get_offset_vector(drop_offset),
        pickup = math2d.position.subtract(pickup_tile, base_tile),
        pickup_offset = get_offset_vector(pickup_offset),
        --The next 4 may not be needed
        pure_drop = drop_tile,
        pure_drop_offset = drop_offset,
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
    local inserter_range = math.max(math.abs(pickup_pos.x), math.abs(pickup_pos.y), math.abs(drop_pos.x), math.abs(drop_pos.y))

    if range_adder_setting == "inserter" then
        return inserter_range
    elseif range_adder_setting == "incremental" then
        if not settings.startup['si-range-technologies'].value then
            ---@diagnostic disable-next-line: param-type-mismatch
            return math.min(inserter_range + 5, global.SI_Storage["inserters_range"])
        end
        local added_range = 0
        if force.technologies["si-unlock-range-5"].researched and force.technologies["si-unlock-range-5"].prototype.hidden == false then
            added_range = 5
        elseif force.technologies["si-unlock-range-4"].researched and force.technologies["si-unlock-range-4"].prototype.hidden == false then
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

--ToClean
function inserter_functions.enforce_max_range(inserter, force)
    local arm_positions = inserter_functions.get_arm_positions(inserter)

    local slim = inserter_functions.is_slim(inserter)

    if slim then
        if inserter.direction == 0 then
            arm_positions.drop.y = arm_positions.drop.y + 1
        elseif inserter.direction == 4 then
            arm_positions.pickup.y = arm_positions.pickup.y + 1
        elseif inserter.direction == 2 then
            arm_positions.pickup.x = arm_positions.pickup.x + 1
        elseif inserter.direction == 6 then
            arm_positions.drop.x = arm_positions.drop.x + 1
        end
    end

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

    return arm_positions
end

--ToClean
function inserter_functions.calc_rotated_position(inserter, new_position, new_direction)
    new_direction = new_direction == 0 and 8 or new_direction
    local spostamento = (8 - inserter.direction) - (8 - new_direction)
    if spostamento < 0 then
        spostamento = 8 + spostamento
    end
    local tmp_pos = 0

    while spostamento ~= 0 do
        tmp_pos = new_position.y * -1
        new_position.y = new_position.x
        new_position.x = tmp_pos
        spostamento = spostamento - 2
    end

    return new_position
end

--ToClean
function inserter_functions.calc_rotated_offset(inserter, new_position, target)
    local old_positions = inserter_functions.get_arm_positions(inserter)

    if old_positions[target .. "_offset"].x == 0 and old_positions[target .. "_offset"].y == 0 then
        return old_positions[target .. "_offset"]
    end

    local range = math.max(math.abs(old_positions[target].x), math.abs(old_positions[target].y))

    local position = math2d.direction.from_vector(old_positions[target .. "_offset"])

    local old_sector = math2d.direction.downscale_to_vec1(old_positions[target .. "_offset"], range)
    if type(new_position) == "number" then
        new_position = inserter_functions.calc_rotated_position(inserter, old_positions[target .. "_offset"],
            new_position)
    end
    local new_sector = math2d.direction.downscale_to_vec1(new_position, range)

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

    local x, y, size
    local pickup_position = math2d.position.ensure_xy(inserter.inserter_pickup_position)
    local insert_position = math2d.position.ensure_xy(inserter.inserter_drop_position)
    x = math.max(math.abs(pickup_position.x), math.abs(insert_position.x))
    y = math.max(math.abs(pickup_position.y), math.abs(insert_position.y))
    size = math.max(x, y) - collision_box_total

    return size
end

--Experimental
--Problem there may be cases where you need to edit both pickup/drop thie mean tht I should pack position before entering this function
--but processing the data before entering here defeat the purpose
local function adjust_position(position, inserter, vertical, orizontal, slim, inserter_size, base)
    local tile, offset = math2d.position.split(inserter.pickup_position)

    if position.pickup or position.drop then
        local change = position.pickup or position.drop
        local edit = { x = 0, y = 0 }
        if slim then
            if vertical and change.y >= 0 then
                edit.y = edit.y - 1
            elseif orizontal and change.x >= 0 then
                edit.x = edit.x - 1
            end
        elseif inserter_size >= 2 then
            if change.x < 0 then
                edit.x = edit.x - (inserter_size - 1)
            end
            if change.y < 0 then
                edit.y = edit.y - (inserter_size - 1)
            end
        end
        tile = math2d.position.add(base, math2d.position.add(change, edit))
    end

    if position.drop_adjust or position.pickup_adjust then
        math2d.position.add(tile, position.drop_adjust or position.pickup_adjust)
    end

    if position.drop_offset or position.pickup_offset then
        offset = math2d.position.add(
        math2d.position.multiply_scalar(position.drop_offset or position.pickup_offset, 0.2), { 0.5, 0.5 })
    end

    return math2d.position.add(tile, offset)
end

--Cleaned
function inserter_functions.set_arm_positions(inserter, positions)
    local inserter_size = inserter_functions.get_inserter_size(inserter)
    local base, _ = math2d.position.split(inserter.position)

    local slim = inserter_functions.is_slim(inserter)

    local vertical = (inserter.direction==0 or inserter.direction==4)
    local orizontal = (inserter.direction==2 or inserter.direction==6)

    if positions.pickup or positions.pickup_offset or positions.pickup_adjust then
        local pickup_tile, pickup_offset = math2d.position.split(inserter.pickup_position)
        if positions.pickup then
            local edit = { x = 0, y = 0 }
            if slim then
                if vertical and positions.pickup.y >= 0 then
                    edit.y = edit.y - 1
                elseif orizontal and positions.pickup.x >= 0 then
                    edit.x = edit.x - 1
                end
            elseif inserter_size >= 2 then
                if positions.pickup.x < 0 then
                    edit.x = edit.x - (inserter_size - 1)
                end
                if positions.pickup.y < 0 then
                    edit.y = edit.y - (inserter_size - 1)
                end
            end
            pickup_tile = math2d.position.add(base, math2d.position.add(positions.pickup, edit))
        end

        if positions.pickup_adjust then
            pickup_tile = math2d.position.add(pickup_tile, positions.pickup_adjust)
        end

        if positions.pickup_offset then
            pickup_offset = math2d.position.add(
                math2d.position.multiply_scalar(positions.pickup_offset, 0.2), { 0.5, 0.5 }
            )
        end

        inserter.pickup_position = math2d.position.add(pickup_tile, pickup_offset)
    end

    if positions.drop or positions.drop_offset or positions.drop_adjust then
        local drop_tile, drop_offset = math2d.position.split(inserter.drop_position)

        if positions.drop then
            local edit = { x = 0, y = 0 }
            if slim then
                if vertical and positions.drop.y >= 0 then
                    edit.y = edit.y - 1
                elseif orizontal and positions.drop.x >= 0 then
                    edit.x = edit.x - 1
                end
            elseif inserter_size >= 2 then
                if positions.drop.x < 0 then
                    edit.x = edit.x - (inserter_size - 1)
                end
                if positions.drop.y < 0 then
                    edit.y = edit.y - (inserter_size - 1)
                end
            end
            drop_tile = math2d.position.add(base, math2d.position.add(positions.drop, edit))
        end

        if positions.drop_adjust then
            drop_tile = math2d.position.add(drop_tile, positions.drop_adjust)
        end

        if positions.drop_offset then
            drop_offset = math2d.position.add(math2d.position.multiply_scalar(positions.drop_offset, 0.2), { 0.5, 0.5 })
        end

        inserter.drop_position = math2d.position.add(drop_tile, drop_offset)
    end

    -- Fix stuff with rail and pickup --https://mods.factorio.com/mod/Smart_Inserters/discussion/656b192ef49ec2e9ceac7eac
    local direction = inserter.direction
    inserter.direction = (inserter.direction + 2) % 4
    inserter.direction = direction
end

return inserter_functions