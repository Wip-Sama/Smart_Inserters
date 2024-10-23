local diagonal_technologies = settings.startup["si-diagonal-technologies"].value
local range_technologies = settings.startup["si-range-technologies"].value
local offset_selector_technologies = settings.startup["si-offset-technologies"].value
local max_inserter_range = settings.startup["si-max-inserters-range"].value

local inserter_functions = require("__Smart_Inserters__/scripts/inserter_functions")
local math2d = require("__yafla__/scripts/extended_math2d")

---@type tech_lookup_table
tech_lookup_table = tech_lookup_table or {}
local tech = {}
local util = require("__core__/lualib/util")

function tech.check_offset_tech(force)
    if not offset_selector_technologies then
        return true
    end

    return force.technologies["si-unlock-offsets"].researched
end

--Legacy
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

--Legacy
function tech.check_range_tech(force, cell_position, distance_offset)
    if not range_technologies then
        return true
    end

    cell_position = math2d.position.ensure_xy(cell_position)
    distance_offset = distance_offset or 0
    local distance = math.max(math.abs(cell_position.x), math.abs(cell_position.y)) - distance_offset
    distance = math.max(math.floor(distance), 1)
    if distance == 1 then
        return true
    end

    if settings.startup["si-range-adder"].value == "incremental" then
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
        range = {false, false, false, false},
        diagonal = {
            force.technologies["si-unlock-cross"].researched,
            force.technologies["si-unlock-x-diagonals"].researched,
            force.technologies["si-unlock-all-diagonals"].researched
        },
        check = {}
    }

    tech_lookup_table[force.index].diagonal = {
        force.technologies["si-unlock-cross"].researched,
        force.technologies["si-unlock-x-diagonals"].researched,
        force.technologies["si-unlock-all-diagonals"].researched,
    }
    for t = 1, 5 do
        tech_lookup_table[force.index].range[t] = force.technologies["si-unlock-range-" .. tostring(t)].researched
    end

    local valid_distance = 1

    if not range_technologies then
        valid_distance = inserter_functions.get_max_inserters_range()
    else
        --5 is the max tech
        for t = 5, 1, -1 do
            if force.technologies["si-unlock-range-" .. math.min(5, t)].researched and force.technologies["si-unlock-range-" .. math.min(5, t)].prototype.hidden == false then
                valid_distance = math.min(4, t)+1
                break
            end
        end
        if settings.startup["si-range-adder"].value == "incremental" then
            valid_distance = inserter_functions.get_max_inserters_range()-5+(valid_distance-1) --It might need to be turned back to 4
        end
    end

    local diagonal_function
    if not diagonal_technologies then
        ---@return boolean
        diagonal_function = function()
            return true
        end
    else
        local cross_unlocked = tech_lookup_table[force.index].diagonal[1]
        local x_diagonals_unlocked = tech_lookup_table[force.index].diagonal[2]
        local all_diagonals_unlocked = tech_lookup_table[force.index].diagonal[3]
        ---@return boolean
        diagonal_function = function()
            return false
        end
        if all_diagonals_unlocked then
            ---@return boolean
            diagonal_function = function()
                return true
            end
        elseif x_diagonals_unlocked then
            diagonal_function = x_diagonals
        elseif cross_unlocked then
            diagonal_function = cross_diagonals
        end
    end
end

function tech.get_tech_lookup_table(force)
    if validate_tech_lookup_table(force) then
        return util.copy(tech_lookup_table[force.index].check)
    end
    return tech.generate_tech_lookup_table(force)
end

--Distance offset is to trick the function into ticking that incremental range is in inserter_range
function tech.check_tech(force, cell_position, distance_offset)
    if validate_tech_lookup_table(force) then
        return tech_lookup_table[force.index].check[cell_position.x][cell_position.y]
    end
    return tech.check_range_tech(force, cell_position, distance_offset) and tech.check_diagonal_tech(force, cell_position)
end

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