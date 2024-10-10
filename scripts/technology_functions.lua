local diagonal_technologies = settings.startup["si-diagonal-technologies"].value
local range_technologies = settings.startup["si-range-technologies"].value
local offset_selector_technologies = settings.startup["si-offset-technologies"].value
local max_inserter_range = settings.startup["si-max-inserters-range"].value

local math2d = require("__yafla__/scripts/extended_math2d")

---@type tech_lookup_table
tech_lookup_table = tech_lookup_table or {}
local tech = {}
local util = require("__core__/lualib/util")

---@param position Position
---@param base Position
---@return boolean 
function cross_diagonals(position, base)
    local width, height = base.x, base.y
    local x, y = position.x, position.y

    local lower_width = base%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5

    if (y >=-lower_height and y <= higher_height) and (-lower_width > x or higher_width < x) then
        return true
    end
    if (x >=-lower_width and x <= higher_width) and (-lower_height > y or higher_height < y) then
        return true
    end
    return false
end

---@param position Position
---@param base Position
---@return boolean
function x_diagonals(position, base)
    --Do not use cross_diagonals here becouse all the lower / higher would be calculated twice
    local width, height = base.x, base.y
    local x, y = position.x, position.y

    local lower_width = width%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5

    if (y >=-lower_height and y <= higher_height) and (-lower_width > x or higher_width < x) then
        return true
    end
    if (x >=-lower_width and x <= higher_width) and (-lower_height > y or higher_height < y) then
        return true
    end

    if (x < -lower_width) then
        x = position.x + lower_width
    elseif (x >= higher_width) then
        -- il +1 serve perchè il quadrato si sposterebbe a sinistra di troppo
        -- l'uguale include 1 di errore
        -- nota: che anche se x > e non x >= il +1 serve lo stesso ma ci sono casi in cui va fuori range
        -- todo: verificare se il +1 funziona con gli slim, potrebbe andar bene math.min(width, height, 1)
        x = position.x - higher_width + 1
    end

    if (y < -lower_height) then
        y = position.y + lower_height
    elseif (y >= higher_height) then
        y = position.y - higher_height + 1
    end

    return (math.abs(x) == math.abs(y))

end

---@param force LuaForce
---@return boolean
function tech.check_offset_tech(force)
    if not offset_selector_technologies then
        return true
    end

    return force.technologies["si-unlock-offsets"].researched
end

---@param force LuaForce
---@param cell_position Position
---@return boolean
function tech.check_diagonal_tech(force, cell_position)
    if not diagonal_technologies then
        return true
    end

    local cross_unlocked = force.technologies["si-unlock-cross"].researched
    local x_diagonals_unlocked = force.technologies["si-unlock-x-diagonals"].researched
    local all_diagonals_unlocked = force.technologies["si-unlock-all-diagonals"].researched

    return cross_unlocked and (cell_position.x == 0 or cell_position.y == 0) or
        x_diagonals_unlocked and math.abs(cell_position.x) == math.abs(cell_position.y) or
        all_diagonals_unlocked
end

---@param force LuaForce
---@return integer
function tech.get_actual_increment(force)
    if not range_technologies then
        return 5
    end
    if force.technologies["si-unlock-range-5"].researched and force.technologies["si-unlock-range-5"].prototype.hidden == false then
        return 5
    elseif force.technologies["si-unlock-range-4"].researched and force.technologies["si-unlock-range-4"].prototype.hidden == false then
        return 4
    elseif force.technologies["si-unlock-range-3"].researched and force.technologies["si-unlock-range-3"].prototype.hidden == false then
        return 3
    elseif force.technologies["si-unlock-range-2"].researched and force.technologies["si-unlock-range-2"].prototype.hidden == false then
        return 2
    elseif force.technologies["si-unlock-range-1"].researched and force.technologies["si-unlock-range-1"].prototype.hidden == false then
        return 1
    end
    return 0
end

---@param force LuaForce
---@return integer
function tech.get_diagonal_increment(force)
    if not diagonal_technologies then
        return 3
    end
    if force.technologies["si-unlock-all-diagonals"].researched and force.technologies["si-unlock-all-diagonals"].prototype.hidden == false then
        return 3
    elseif force.technologies["si-unlock-x-diagonals"].researched and force.technologies["si-unlock-x-diagonals"].prototype.hidden == false then
        return 2
    elseif force.technologies["si-unlock-cross"].researched and force.technologies["si-unlock-cross"].prototype.hidden == false then
        return 1
    end
    return 0
end

---@param force LuaForce
---@param cell_position Position
---@param distance_offset number
---@return boolean
function tech.check_range_tech(force, cell_position, distance_offset)
    if not range_technologies then
        return true
    end

    cell_position = math2d.position.abs(cell_position)
    local distance = math.max(cell_position.x, cell_position.y)
    distance = math.max(math.floor(distance), 1)
    if distance == 1 then
        return true
    end

    if settings.startup["si-range-adder"].value == "incremental" or settings.startup["si-range-adder"].value == "incremental-with-rebase" then
        cell_position = math2d.position.abs(cell_position)
        distance_offset = distance_offset or 0
        local distance = math.max(cell_position.x, cell_position.y) - distance_offset
        distance = math.max(math.floor(distance), 1)
        if distance == 1 then
            return true
        end

        if force.technologies["si-unlock-range-" .. math.min(5, distance)].researched and force.technologies["si-unlock-range-" .. math.min(5, distance)].prototype.hidden == false then
            return true
        elseif force.technologies["si-unlock-range-4"].researched and force.technologies["si-unlock-range-4"].prototype.hidden == false then
            return true
        elseif force.technologies["si-unlock-range-3"].researched and force.technologies["si-unlock-range-3"].prototype.hidden == false then
            return true
        elseif force.technologies["si-unlock-range-2"].researched and force.technologies["si-unlock-range-2"].prototype.hidden == false then
            return true
        elseif force.technologies["si-unlock-range-1"].researched and force.technologies["si-unlock-range-1"].prototype.hidden == false then
            return true
        end
    else
        if force.technologies["si-unlock-range-5"].researched and force.technologies["si-unlock-range-5"].prototype.hidden == false and distance <= 6 then
            return true
        elseif force.technologies["si-unlock-range-4"].researched and force.technologies["si-unlock-range-4"].prototype.hidden == false and distance <= 5 then
            return true
        elseif force.technologies["si-unlock-range-3"].researched and force.technologies["si-unlock-range-3"].prototype.hidden == false and distance <= 4 then
            return true
        elseif force.technologies["si-unlock-range-2"].researched and force.technologies["si-unlock-range-2"].prototype.hidden == false and distance <= 3 then
            return true
        elseif force.technologies["si-unlock-range-1"].researched and force.technologies["si-unlock-range-1"].prototype.hidden == false and distance <= 2 then
            return true
        end
    end

    return distance <= 1
end

--Distance offset is to trick the function into ticking that incremental range is in inserter_range
---@param force LuaForce
---@param cell_position Position
---@param distance_offset number
---@return boolean
function tech.check_tech(force, cell_position, distance_offset)
    -- if validate_tech_lookup_table(force) then
    --     return util.copy(tech_lookup_table[force.index].check)
    -- else
    --     tech.generate_tech_lookup_table(force)
    --     return util.copy(tech_lookup_table[force.index].check)
    -- end
    return tech.check_range_tech(force, cell_position, distance_offset) and tech.check_diagonal_tech(force, cell_position)
end



----------------------------------------------------------
--------------------- LOOKUP TABLES ---------------------- !INCOMPLETE
----------------------------------------------------------

---@param force LuaForce
---@return boolean
local function validate_tech_lookup_table(force)
    if not tech_lookup_table[force.index] then
        return false
    end
    if tech_lookup_table[force.index].diagonal[3] ~= force.technologies["si-unlock-all-diagonals"].researched then
        return false
    elseif tech_lookup_table[force.index].diagonal[2] ~= force.technologies["si-unlock-x-diagonals"].researched then
        return false
    elseif tech_lookup_table[force.index].diagonal[1] ~= force.technologies["si-unlock-cross"].researched then
        return false
    end
    for t = 1, 5 do
        if tech_lookup_table[force.index].range[t] ~= force.technologies["si-unlock-range-" .. tostring(t)].researched then
            return false
        end
    end
    return true
end

---@param force LuaForce
---@return nil
function tech.generate_tech_lookup_table(force)
    tech_lookup_table[force.index] = {
        range = {},
        diagonal = {
            force.technologies["si-unlock-cross"].researched,
            force.technologies["si-unlock-x-diagonals"].researched,
            force.technologies["si-unlock-all-diagonals"].researched
        },
        check = {}
    }
    for t = 1, 5 do
        tech_lookup_table[force.index].range[t] = force.technologies["si-unlock-range-" .. tostring(t)].researched
    end

    if range_technologies then
        --5 is the max tech
        for t = 5, 1, -1 do
            if force.technologies["si-unlock-range-" .. math.min(5, t)].researched and force.technologies["si-unlock-range-" .. math.min(5, t)].prototype.hidden == false then
                max_inserter_range = math.min(4, t)+1
                break
            end
        end
        if settings.startup["si-range-adder"].value == "incremental" then
            max_inserter_range = max_inserter_range-5+(max_inserter_range-1) --It might need to be turned back to 4
        end
    end

    ---@return boolean
    local diagonal_function = function()
        return true
    end
    if diagonal_technologies then
        ---@return boolean
        diagonal_function = function()
            return false
        end
        if tech_lookup_table[force.index].diagonal[2] then
            diagonal_function = x_diagonals
        elseif tech_lookup_table[force.index].diagonal[1] then
            diagonal_function = cross_diagonals
        end
    end

    for x = -max_inserter_range, max_inserter_range do
        tech_lookup_table[force.index].check[x] = {}
        for y = -max_inserter_range, max_inserter_range do
            tech_lookup_table[force.index].check[x][y] = diagonal_function({x = x, y = y}, {x = max_inserter_range, y = max_inserter_range}) and tech.check_range_tech(force, {x = x, y = y}, 0)
        end
    end
end

---comment
---@param force LuaForce
---@return table|unknown
function tech.get_tech_lookup_table(force)
    if validate_tech_lookup_table(force) then
        return util.copy(tech_lookup_table[force.index].check)
    end
    return tech.generate_tech_lookup_table(force)
end

--Migrate tech from bob
function tech.migrate_all()
    for _, force in pairs(game.forces) do
        tech.generate_tech_lookup_table(force)
        for i = 1, 3 do
            local tech_name = "si-unlock-range-" .. i
            local original_tech_name = i == 1 and "near-inserters" or "long-inserters-" .. (i - 1)
            force.technologies[tech_name].researched = force.technologies[original_tech_name].researched or force.technologies[tech_name].researched
        end

        force.technologies["si-unlock-cross"].researched = force.technologies["more-inserters-1"].researched or force.technologies["si-unlock-cross"].researched
        force.technologies["si-unlock-x-diagonals"].researched = force.technologies["more-inserters-2"].researched or force.technologies["si-unlock-x-diagonals"].researched
    end
end

return tech