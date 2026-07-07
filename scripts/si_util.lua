local math2d = require("__yafla__/scripts/extended_math2d")
local tech = require("scripts.technology_functions")

local single_line_inserters = settings.startup["si-single-line-inserters"].value

local si_util = {
    blacklist = {
        mods = { "miniloader", "RenaiTransportation", "GhostOnWater", "miniloader-redux" },
        entities = {
            'hps__ml-', -- miniloader-redux
        }
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
                if single_line_inserters then
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
    local prototype = prototypes.get_history(entity.type, entity.name)

    for _, v in pairs(si_util.blacklist.mods) do
        if string.find(prototype.created, v) == 1 then
            return false
        end
    end

    for _, v in pairs(si_util.blacklist.entities) do
        if string.find(entity.name, v) == 1 then
            return false
        end
    end

    return true
end

function si_util.check_prototype_blacklist(name)
    if not name then return false end

    for _, v in pairs(si_util.blacklist.entities) do
        if name:find(v) == 1 then
            return false
        end
    end

    return true
end

return si_util
