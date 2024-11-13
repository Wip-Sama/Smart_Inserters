local math2d = require("__yafla__/scripts/extended_math2d")
local technology_functions = require("scripts.technology_functions")
local events = require("scripts.events")

local single_line_inserters = settings.startup["si-single-line-inserters"].value
local single_line_slim_inserters = settings.startup["si-single-line-slim-inserters"].value
local directional_inserters = settings.startup["si-directional-inserters"].value
local directional_slim_inserters = settings.startup["si-directional-slim-inserters"].value

local inserter_functions = {}

function inserter_functions.inserter_in_result(result, long_inserters)
	for _, linserter in pairs(long_inserters) do
		if linserter == result then
			return true
		end
	end
	return false
end

function inserter_functions.inserter_in_results(results, long_inserters)
	for _, linserter in pairs(long_inserters) do
		for _, reciperecult in pairs(results) do
			if reciperecult == nil then break end
			if type(reciperecult) == "table" then
				for _, singleresult in pairs(reciperecult) do
					if type(singleresult) == "string" and singleresult == linserter then
						return true
					end
				end
			elseif reciperecult == linserter then
				return true
			end
		end
	end
	return false
end

---@param inserter LuaEntityPrototype
---@return number
function inserter_functions.inseter_default_range(inserter)
	local width, height = inserter.tile_width, inserter.tile_height
	--width, height = inserter.tile_width, inserter.tile_height

	if not width then
		width = 0
	end

	if not height then
		height = 0
	end

	local lower_width = width%2==0 and width/2 or width/2-0.5
	local higher_width = width%2==0 and width/2 or width/2+0.5

	local lower_height = height%2==0 and height/2 or height/2-0.5
	local higher_height = height%2==0 and height/2 or height/2+0.5

	local drop_int
	local pickup_int
	if not inserter.inserter_drop_position then
		drop_int, _ = math2d.position.split(inserter.insert_position)
		pickup_int, _ = math2d.position.split(inserter.pickup_position)
	else
		drop_int, _ = math2d.position.split(inserter.inserter_drop_position)
		pickup_int, _ = math2d.position.split(inserter.inserter_pickup_position)
	end

    if drop_int.x < -lower_width then
        drop_int.x = drop_int.x + lower_width
    elseif drop_int.x >= higher_width then
        drop_int.x = drop_int.x - higher_width + 1
    end
    if pickup_int.x < -lower_width then
        pickup_int.x = pickup_int.x + lower_width
    elseif pickup_int.x >= higher_width then
        pickup_int.x = pickup_int.x - higher_width +1
    end

    if drop_int.y < -lower_height then
        drop_int.y = drop_int.y + lower_height
    elseif drop_int.y >= higher_height then
        drop_int.y = drop_int.y - higher_height + 1
    end
    if pickup_int.y < -lower_height then
        pickup_int.y = pickup_int.y + lower_height
    elseif pickup_int.y >= higher_height then
        pickup_int.y = pickup_int.y - higher_height +1
    end

	local x_distance = math.max(math.abs(pickup_int.x), math.abs(drop_int.x))
	local y_distance = math.max(math.abs(pickup_int.y), math.abs(drop_int.y))

	local size = math.max(x_distance, y_distance)
	return size
end

function inserter_functions.is_inserter_long(inserter)
    if inserter_functions.is_slim(inserter) then
        if inserter_functions.inseter_default_range(inserter) > 1 then
            return true
        end
    else
        if inserter_functions.inseter_default_range(inserter) > 2 then
            return true
        end
    end
	return false
end

function inserter_functions.is_inserter_mini(inserter)
    if inserter.tile_height == 0 or inserter.tile_width == 0 then
        return true
    end
    return false
end

--- @param inserter LuaEntity
--- @return LuaEntityPrototype | LuaTilePrototype
function inserter_functions.get_prototype(inserter)
    return inserter.type == "entity-ghost" and inserter.ghost_prototype or inserter.prototype
end

--- @param entity LuaEntity?
--- @return boolean
function inserter_functions.is_inserter(entity)
    return entity ~= nil and
    (entity.type == "inserter" or (entity.type == "entity-ghost" and entity.ghost_type == "inserter"))
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

---@param inserter any
---@param tile Position
---@return defines.direction.east|defines.direction.north|defines.direction.northeast|defines.direction.northwest|defines.direction.west|defines.direction.south|defines.direction.southeast|defines.direction.southwest
function inserter_functions.calculate_arm_direction(inserter, tile)
    local width = inserter.tile_width
    local height = inserter.tile_height

    local lower_width = width % 2 == 0 and width / 2 or width / 2 - 0.5
    local higher_width = width % 2 == 0 and width / 2 or width / 2 + 0.5

    local lower_height = height % 2 == 0 and height / 2 or height / 2 - 0.5
    local higher_height = height % 2 == 0 and height / 2 or height / 2 + 0.5

    local arm_direction

    if tile.x >= higher_width then
        if tile.y < -lower_height then
            arm_direction = defines.direction.northeast
        elseif tile.y >= higher_height then
            arm_direction = defines.direction.southeast
        else
            arm_direction = defines.direction.east
        end
    elseif tile.x < -lower_width then
        if tile.y < -lower_height then
            arm_direction = defines.direction.northwest
        elseif tile.y >= higher_height then
            arm_direction = defines.direction.southwest
        else
            arm_direction = defines.direction.west
        end
    else
        if tile.y < -lower_height then
            arm_direction = defines.direction.north
        elseif tile.y >= higher_height then
            arm_direction = defines.direction.south
        end
    end

    return arm_direction
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

        if offset.x > 0.55 then
            offset_vec.x = 0.75
        elseif offset.x < 0.45 then
            offset_vec.x = 0.25
        end

        if offset.y > 0.55 then
            offset_vec.y = 0.75
        elseif offset.y < 0.45 then
            offset_vec.y = 0.25
        end

        return offset_vec
    end

    drop_tile = math2d.position.subtract(drop_tile, base_tile)
    pickup_tile = math2d.position.subtract(pickup_tile, base_tile)

    return {
        base = base_tile,
        drop = drop_tile,
        pickup = pickup_tile,
        base_offset = base_offset,
        drop_offset = convert_offset(drop_offset),
        pickup_offset = convert_offset(pickup_offset),
        drop_direction = inserter_functions.calculate_arm_direction(inserter, drop_tile),
        pickup_direction = inserter_functions.calculate_arm_direction(inserter, pickup_tile),
    }
end

---@param positions ChangeArmPosition | ArmPosition
---@param inserter LuaEntity
function inserter_functions.set_arm_positions(positions, inserter)
    local res = inserter_functions.get_arm_positions(inserter)

    if positions.pickup then
        local _, offset = math2d.position.split(inserter.pickup_position)
        inserter.pickup_position = math2d.position.adds { res.base, positions.pickup, offset }
    end

    if positions.drop then
        local _, offset = math2d.position.split(inserter.drop_position)
        inserter.drop_position = math2d.position.adds { res.base, positions.drop, offset }
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

    script.raise_event(events.on_inserter_arm_changed, {
        entity = inserter,
        old_drop = positions.drop and res.drop or nil,
        old_pickup = positions.pickup and res.pickup or nil,
        old_drop_offset = positions.drop_offset and res.drop_offset or nil,
        old_pickup_offset = positions.pickup_offset and res.pickup_offset or nil,
    })
end

---@return integer
function inserter_functions.get_max_inserters_range()
    ---@diagnostic disable-next-line: return-type-mismatch
    return settings.startup["si-max-inserters-range"].value
end

---@param inserter LuaEntity
---@param position Position
---@return boolean
function inserter_functions.should_cell_be_enabled(inserter, position)
    position = math2d.position.ensure_xy(position)

    local max_range, min_range = inserter_functions.get_max_and_min_inserter_range(inserter)
    local slim = inserter_functions.is_slim(inserter)
    --Equal
    --Tech range for everyone
    local default_range = 0

    local width, height = inserter.tile_width, inserter.tile_height

    local lower_width = width % 2 == 0 and width / 2 or width / 2 - 0.5
    local higher_width = width % 2 == 0 and width / 2 or width / 2 + 0.5

    local lower_height = height % 2 == 0 and height / 2 or height / 2 - 0.5
    local higher_height = height % 2 == 0 and height / 2 or height / 2 + 0.5

    if position.x >= -lower_width and position.x < higher_width and position.y >= -lower_height and position.y < higher_height then
        return false
    end

    if (position.y >= -lower_height and position.y < higher_height) then
        position.y = 0
    elseif (position.y < -lower_height) then
        position.y = position.y + lower_height
    elseif position.y >= higher_height then
        --This +1 is used to avoid shifting teh position into the base range
        --Example: ian base 6 inserter, higher = 3, base = -3->2, position 3-3 = 0 (in base), 3-3+1 = 1 not in base
        --Remember that base conversion goes from n*m to 1x1 so base is only 0
        position.y = position.y - higher_height + 1
    end

    if (position.x >= -lower_width and position.x < higher_width) then
        position.x = 0
    elseif (position.x < -lower_width) then
        position.x = position.x + lower_width
    elseif position.x >= higher_width then
        position.x = position.x - higher_width + 1
    end

    --Inserter
    --Tech range up to inserter range
    if settings.startup["si-range-adder"].value == "inserter" and inserter_functions.get_prototype(inserter) then
        if not (math.max(math.abs(position.x), math.abs(position.y)) <= max_range) then
            return false
        end
    end

    --Incremental
    --Inserter base range + tech range
    if settings.startup["si-range-adder"].value == "incremental" and inserter_functions.get_prototype(inserter) then
        default_range = inserter_functions.inseter_default_range(inserter_functions.get_prototype(inserter))
    end

    --Rebase
    --inserter min range up to max range
    if settings.startup["si-range-adder"].value == "rebase" then
        if math.max(math.abs(position.x), math.abs(position.y)) > max_range then
            return false
        elseif math.abs(position.x) < min_range and math.abs(position.y) < min_range then
            return false
        end
        default_range = inserter_functions.inseter_default_range(inserter_functions.get_prototype(inserter))
    end

    --inserter min range up to max range + incremet
    if settings.startup["si-range-adder"].value == "incremental-with-rebase" then
        if math.max(math.abs(position.x), math.abs(position.y)) > max_range then
            return false
        elseif math.abs(position.x) < min_range and math.abs(position.y) < min_range then
            return false
        end
        default_range = inserter_functions.inseter_default_range(inserter_functions.get_prototype(inserter))
    end

    --inserter min range up to max range + incremet
    if settings.startup["si-range-adder"].value == "inserter-with-rebase" then
        if math.max(math.abs(position.x), math.abs(position.y)) > max_range then
            return false
        elseif math.abs(position.x) < min_range and math.abs(position.y) < min_range then
            return false
        end
        default_range = inserter_functions.inseter_default_range(inserter_functions.get_prototype(inserter))
    end

    if single_line_slim_inserters and slim then
        if inserter.tile_width > 0 then
            if position.x ~= 0 then
                return false
            end
        elseif inserter.tile_height > 0 then
            if position.y ~= 0 then
                return false
            end
        end
    end

    if single_line_inserters and not slim then
        if inserter.direction == defines.direction.north or inserter.direction == defines.direction.south then
            if position.x ~= 0 then
                return false
            end
        elseif inserter.direction == defines.direction.east or inserter.direction == defines.direction.west then
            if position.y ~= 0 then
                return false
            end
        end
    end

    cell_position = math2d.position.abs(position)
    local distance = math.max(cell_position.x, cell_position.y)
    distance = math.max(math.floor(distance), 1)
    if distance > max_range or distance < min_range then
        return false
    end

    if (directional_inserters and not slim) or (directional_slim_inserters and slim) then
        if position.y == 0 and ((inserter.direction == defines.direction.north) or (inserter.direction == defines.direction.south)) then
            return false
        elseif position.x == 0 and ((inserter.direction == defines.direction.east) or (inserter.direction == defines.direction.west)) then
            return false
        end
    end

    return technology_functions.check_tech(inserter.force, position, default_range)
end

---Return max and min inserter range considering the unlocked technologies and settings
---@param inserter LuaEntity
---@return number, number
function inserter_functions.get_max_and_min_inserter_range(inserter)
    local default_range = inserter_functions.inseter_default_range(inserter_functions.get_prototype(inserter))
    local max_range = inserter_functions.get_max_inserters_range()
    local max = inserter_functions.get_max_inserters_range() -- equal
    local min = 1

    if settings.startup["si-range-adder"].value == "inserter" then
        max = default_range
    elseif settings.startup["si-range-adder"].value == "incremental" then
        max = default_range + max_range
    elseif settings.startup["si-range-adder"].value == "rebase" then
        min = default_range
    elseif settings.startup["si-range-adder"].value == "incremental-with-rebase" then
        max = default_range + max_range
        min = default_range
    elseif settings.startup["si-range-adder"].value == "inserter-with-rebase" then
        max = default_range
        min = default_range
    end

    -- clamp value based on tech with "new_max = min + tech_increment <= max"
    local increment = technology_functions.get_actual_increment(inserter.force)
    local new_max = min+increment <= max and min+increment or max

    return new_max, min
end

---Never implemented, could be useful so I leave it there only as an idea
---@param inserter LuaEntity
---@deprecated
function inserter_functions.cast_to_1x1_inserter(inserter)
    local width, height = math.ceil(inserter.tile_width), math.ceil(inserter.tile_height)

    local lower_width = width%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5
end

return inserter_functions