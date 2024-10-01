local math2d = require("__yafla__/scripts/extended_math2d")
local tech = require("scripts.technology_functions")

local single_line_slim_inserter = settings.startup["si-single-line-slim-inserter"].value

local si_util = {
    blacklist = {
        mods = { "miniloader", "RenaiTransportation", "GhostOnWater" },
        entities = {}
    }
}

function si_util.extend_table(target, source)
    for _, value in ipairs(source) do
        table.insert(target, value)
    end
end

function si_util.merge_tables(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
end

function si_util.enabled_cell_matrix(force, vertical, orizontal, slim)
    local enabled_matrix = tech.get_Tech_lookup_table(force)
    if slim then
        for kx, _ in pairs(enabled_matrix) do
            for ky, _ in pairs(enabled_matrix) do
                if single_line_slim_inserter then
                    if vertical and kx == 0 then
                        enabled_matrix[kx][ky] = true
                    elseif orizontal and ky == 0 then
                        enabled_matrix[kx][ky] = true
                    else
                        enabled_matrix[kx][ky] = false
                    end
                else
                    if vertical and ky == 0 then
                        enabled_matrix[kx][ky] = false
                    elseif orizontal and kx == 0 then
                        enabled_matrix[kx][ky] = false
                    end
                end
            end
        end
    end
    return enabled_matrix
end

function si_util.check_blacklist(entity)
    --What an ugly ass piece of code... I rellay hate checking strings in this way to filter something, it's reliability is below 0...
    local prototype = script.get_prototype_history(entity.type, entity.name)

    for _, v in pairs(si_util.blacklist.mods) do
        if string.find(prototype.created, v) then
            return false
        end
    end

    for _, v in pairs(si_util.blacklist.entities) do
        if string.find(entity.name, v) then
            return false
        end
    end

    return true
end


---@param inserter LuaEntity
---@param position Position
---@param inserter_range number
---@return boolean
function si_util.should_cell_be_enabled(inserter, position, inserter_range)
    position = math2d.position.ensure_xy(position)

    --Equal
    --Tech range for everyone
    local default_range = 0
    local in_inserter_range = true

    --Inserter
    --Tech range up to inserter range
    if settings.startup["si-range-adder"].value == "inserter" and inserter.prototype then
        in_inserter_range = math.max(math.abs(position.x), math.abs(position.y)) <= inserter_range
    end

    --Incremental
    --Inserter base range + tech range
    if settings.startup["si-range-adder"].value == "incremental" and inserter.prototype then
        default_range = si_util.inserter_default_range(inserter.prototype)
    end

    local width, height = inserter.tile_width, inserter.tile_height

    local lower_width = width%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5

    if position.y == 2 and position.x == 1 then
        print()
    end

    if (position.y >= -lower_height and position.y < higher_height) then
        position.y = 0
    elseif (position.y < -lower_height) then
        position.y = position.y+lower_height
    elseif position.y >= higher_height then
        --This +1 is used to avoid shifting teh position into the base range
        --Example: ian base 6 inserter, higher = 3, base = -3->2, position 3-3 = 0 (in base), 3-3+1 = 1 not in base
        --Remember taht base conversion goes from n*m to 1x1 so base is only 0
        position.y = position.y-higher_height+1
    end

    if (position.x >= -lower_width and position.x < higher_width) then
        position.x = 0
    elseif (position.x < -lower_width) then
        position.x = position.x+lower_width
    elseif position.x >= higher_width then
        position.x = position.x-higher_width+1
    end

    return in_inserter_range and tech.check_tech(inserter.force, position, default_range)
end

return si_util
