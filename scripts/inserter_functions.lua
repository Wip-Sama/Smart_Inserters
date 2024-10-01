local math2d = require("__yafla__/scripts/extended_math2d")

local inserter_functions = {}

--- @param inserter LuaEntity
--- @return LuaEntityPrototype | LuaTilePrototype
function inserter_functions.get_prototype(inserter)
    return inserter.type == "entity-ghost" and inserter.ghost_prototype or inserter.prototype
end

--- @param entity LuaEntity?
--- @return boolean
function inserter_functions.is_inserter(entity)
    return entity ~= nil and (entity.type == "inserter" or (entity.type == "entity-ghost" and entity.ghost_type == "inserter"))
end

--- @param inserter LuaEntity
--- @return boolean
function inserter_functions.is_slim(inserter)
    return (inserter.tile_height == 0 or inserter.tile_width == 0)
end

---@param inserter LuaEntity
---@return integer
function inserter_functions.get_inserter_size(inserter)
    if inserter_functions.is_slim(inserter) then
        return 0
    end
    return math.ceil(math.max(inserter.tile_width, inserter.tile_height))
end

---@param inserter LuaEntity
---@return ArmPosition
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

    local function convert_offset(offset)
        local offset_vec = { x = 0.5, y = 0.5 }

        if offset.x > 0.5 then
            offset_vec.x = 0.75
        elseif offset.x < 0.5 then
            offset_vec.x = 0.25
        end

        if offset.y > 0.5 then
            offset_vec.y = 0.75
        elseif offset.y < 0.5 then
            offset_vec.y = 0.25
        end

        return offset_vec
    end

    local width = inserter.tile_width
    local height = inserter.tile_height

    local lower_width = width%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5

    local arm_direction

    drop_tile = math2d.position.subtract(drop_tile, base_tile)
    pickup_tile = math2d.position.subtract(pickup_tile, base_tile)

    if drop_tile.x >= higher_width then
        if drop_tile.y < -lower_height then
            arm_direction = defines.direction.northeast
        elseif drop_tile.y >= higher_height then
            arm_direction = defines.direction.southeast
        else
            arm_direction = defines.direction.east
        end
    elseif drop_tile.x < -lower_width then
        if drop_tile.y < -lower_height then
            arm_direction = defines.direction.northwest
        elseif drop_tile.y >= higher_height then
            arm_direction = defines.direction.southwest
        else
            arm_direction = defines.direction.west
        end
    else
        if drop_tile.y < -lower_height then
            arm_direction = defines.direction.north
        elseif drop_tile.y >= higher_height then
            arm_direction = defines.direction.south
        end
    end

    return {
        base = base_tile,
        base_offset = base_offset,
        drop_offset = convert_offset(drop_offset),
        pickup_offset = convert_offset(pickup_offset),
        drop = drop_tile,
        pickup = pickup_tile,
        arm_direction = arm_direction,
    }
end

---@param positions ChangeArmPosition | ArmPosition
function inserter_functions.set_arm_positions(positions, inserter)
    local res = inserter_functions.get_arm_positions(inserter)

    if positions.pickup then
        local _, offset = math2d.position.split(inserter.pickup_position)
        inserter.pickup_position = math2d.position.adds{res.base, positions.pickup, offset}
    end

    if positions.drop then
        local _, offset = math2d.position.split(inserter.drop_position)
        inserter.drop_position = math2d.position.adds{res.base, positions.drop, offset}
    end

    if positions.pickup_offset then
        local position, _ = math2d.position.split(inserter.pickup_position)
        inserter.pickup_position = math2d.position.add(position, positions.pickup_offset)
    end

    if positions.drop_offset then
        local position, _ = math2d.position.split(inserter.drop_position)
        inserter.drop_position = math2d.position.add(position, positions.drop_offset)
    end

    -- Fix stuff with rail and pickup --https://mods.factorio.com/mod/Smart_Inserters/discussion/656b192ef49ec2e9ceac7eac
    local direction = inserter.direction
    inserter.direction = (inserter.direction + 2) % 4
    inserter.direction = direction
end

---@return integer
function inserter_functions.get_max_inserters_range()
    ---@diagnostic disable-next-line: return-type-mismatch
    return settings.startup["si-max-inserters-range"].value
end

return inserter_functions