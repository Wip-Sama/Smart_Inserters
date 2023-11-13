local single_line_slim_inserter = settings.startup["si-single-line-slim-inserter"].value

local tech = require("scripts.technology_functions")
local inserter_functions = require("scripts.inserter_functions")
local math2d = require("scripts.extended_math2d")

local cell_enabled_lookup_table = {}
local util = {}

function util.extend_table(target, source)
    for _, value in ipairs(source) do
        table.insert(target, value)
    end
end

function util.merge_tables(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
end

-- Need further development
local function generate_lookup_table()
    local enabled = true
    for x = -8, 8 do
        cell_enabled_lookup_table[x] = {}
        for y = -8, 8 do
            if y == x and x == 0 then
                enabled = false
            end
            cell_enabled_lookup_table[x][y] = enabled
        end
    end
end

function util.should_cell_be_enabled(position, inserter_range, force, inserter, slimv, slimo, slim)
    position = math2d.position.ensure_xy(position)

    --Equal
    local default_range = 0
    local in_inserter_range = true

    --Inserter
    if settings.startup["si-range-adder"].value == "inserter" and inserter.prototype then
        in_inserter_range = math.max(math.abs(position.x), math.abs(position.y)) <= inserter_range
    end

    --Incremental
    if settings.startup["si-range-adder"].value == "incremental" and inserter.prototype then
        default_range = inserter_functions.inserter_default_range(inserter.prototype)
    end

    if in_inserter_range and tech.check_tech(force, position, default_range) then
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

return util