local single_line_slim_inserter = settings.startup["si-single-line-slim-inserter"].value

local tech = require("scripts.technology_functions")
local inserter_functions = require("scripts.inserter_functions")
local math2d = require("scripts.extended_math2d")

local util = {}

function util.should_cell_be_enabled(position, inserter_range, force, inserter, slimv, slimo, slim)
    --button.enabled = math.min(math.abs(x), math.abs(y)) == 0 and math.max(math.abs(x), math.abs(y)) <= inserter_range
    --button.enabled = ((math.min(math.abs(x), math.abs(y)) == 0 or math.abs(x) == math.abs(y) ) and math.max(math.abs(x), math.abs(y)) <= inserter_range)
    --button.enabled = math.max(math.abs(x), math.abs(y)) <= table_range
    position = math2d.position.ensure_xy(position)

    local default_range = 0 -- equal
    local in_inserter_range = true

    if settings.startup["si-range-adder"].value == "inserter" and inserter.prototype then
        in_inserter_range = math.max(math.abs(position.x), math.abs(position.y)) <= inserter_range
    end

    if settings.startup["si-range-adder"].value == "incremental" and inserter.prototype then
        default_range = inserter_functions.inseter_default_range(inserter.prototype)
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