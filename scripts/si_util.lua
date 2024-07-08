local single_line_slim_inserter = settings.startup["si-single-line-slim-inserter"].value

local math2d = require("__yafla__/scripts/extended_math2d")

local tech = require("scripts.technology_functions")

local cell_enabled_lookup_table = {}
local util = {
    blacklist = {
        mods = { "miniloader", "RenaiTransportation", "GhostOnWater" },
        entities = {}
    }
}

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

function util.enabled_cell_matrix(force, vertical, orizontal, slim)
    local enabled_matrix = tech.get_Tech_lookup_table(force)

    --[[
        print("\n")
        --Debug
        local out = ""
        for x = -global.SI_Storage["inserters_range"], global.SI_Storage["inserters_range"] do
            for y = -global.SI_Storage["inserters_range"], global.SI_Storage["inserters_range"] do
                out = out .. (enabled_matrix[x][y] and "■" or "□")
            end
            print(out)
            out = ""
        end
    --]]

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

    --[[
        print("\n")
        --Debug
        local out = ""
        for x = -global.SI_Storage["inserters_range"], global.SI_Storage["inserters_range"] do
            for y = -global.SI_Storage["inserters_range"], global.SI_Storage["inserters_range"] do
                out = out .. (enabled_matrix[x][y] and "■" or "□")
            end
            print(out)
            out = ""
        end
    --]]

    return enabled_matrix
end

function util.should_cell_be_enabled(position, inserter_range, force, inserter, vertical, orizontal, slim)
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
        default_range = util.inserter_default_range(inserter.prototype)
    end

    if in_inserter_range and tech.check_tech(force, position, default_range) then
        if slim then
            if single_line_slim_inserter then
                if vertical and position.x == 0 then
                    return true
                elseif orizontal and position.y == 0 then
                    return true
                end
            else
                if vertical and position.y ~= 0 then
                    return true
                elseif orizontal and position.x ~= 0 then
                    return true
                end
            end
        else
            return true
        end
    end
    return false

end

function util.check_blacklist(entity)
    --What an ugly ass piece of code... I rellay hate checking strings in this way to filter something, it's reliability is below 0...
    local prototype = script.get_prototype_history(entity.type, entity.name)

    for _, v in pairs(util.blacklist.mods) do
        if string.find(prototype.created, v) then
            return false
        end
    end

    for _, v in pairs(util.blacklist.entities) do
        if string.find(entity.name, v) then
            return false
        end
    end

    return true
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

    local biggest = { x = 0, y = 0, z = 0 }
    local pickup_position = math2d.position.ensure_xy(inserter.inserter_pickup_position)
    local insert_position = math2d.position.ensure_xy(inserter.inserter_drop_position)
    biggest.x = math.max(math.abs(pickup_position.x), math.abs(insert_position.x))
    biggest.y = math.max(math.abs(pickup_position.y), math.abs(insert_position.y))
    biggest.z = math.max(biggest.x, biggest.y) - collision_box_total

    return biggest.z
end

return util