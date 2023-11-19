local diagonal_technologies = settings.startup["si-diagonal-technologies"].value
local range_technologies = settings.startup["si-range-technologies"].value
local offset_selector_technologies = settings.startup["si-offset-technologies"].value

local math2d = require("scripts.extended_math2d")
local tech_lookup_table = {}
local tech = {}

-- Need further development
local function generate_lookup_table()
    local enabled = true
    for x = -8, 8 do
        tech_lookup_table[x] = {}
        for y = -8, 8 do
            if y == x and x == 0 then
                enabled = false
            end
            tech_lookup_table[x][y] = enabled
        end
    end
end

function tech.check_offset_tech(force)
    if not offset_selector_technologies then
        return true
    end

    return force.technologies["si-unlock-offsets"].researched
end

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
    local range_unlocked = false
    if settings.startup["si-range-adder"].value == "incremental" then
        if force.technologies["si-unlock-range-" .. math.min(4, distance)].researched and force.technologies["si-unlock-range-" .. math.min(4, distance)].prototype.hidden == false then
            range_unlocked = true
        elseif force.technologies["si-unlock-range-3"].researched and force.technologies["si-unlock-range-3"].prototype.hidden == false then
            range_unlocked = true
        elseif force.technologies["si-unlock-range-2"].researched and force.technologies["si-unlock-range-2"].prototype.hidden == false then
            range_unlocked = true
        elseif force.technologies["si-unlock-range-1"].researched and force.technologies["si-unlock-range-1"].prototype.hidden == false then
            range_unlocked = true
        end
    else
        if force.technologies["si-unlock-range-4"].researched and distance <= 5 then
            return true
        elseif force.technologies["si-unlock-range-3"].researched and distance <= 4 then
            return true
        elseif force.technologies["si-unlock-range-2"].researched and distance <= 3 then
            return true
        elseif force.technologies["si-unlock-range-1"].researched and distance <= 2 then
            return true
        end
    end

    return distance <= 1 or range_unlocked
end

function tech.check_tech(force, cell_position, distance_offset)
    return tech.check_range_tech(force, cell_position, distance_offset) and tech.check_diagonal_tech(force, cell_position)
end

function tech.migrate_all()
    for _, force in pairs(game.forces) do
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