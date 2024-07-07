local math2d = require("math2d")

function math2d.position.equal(p1, p2)
    p1 = math2d.position.ensure_xy(p1)
    p2 = math2d.position.ensure_xy(p2)
    return p1.x == p2.x and p1.y == p2.y
end

function math2d.position.dot_product(p1, p2)
    p1 = math2d.position.ensure_xy(p1)
    p2 = math2d.position.ensure_xy(p2)
    return p1.x * p2.x + p1.y * p2.y
end

function math2d.position.abs(pos)
    pos = math2d.position.ensure_xy(pos)
    return { x = math.abs(pos.x), y = math.abs(pos.y) }
end

-- splits a position into tile position int(x,y) and an offset float(x,y)
-- { x = -1.5, y = 2.5 } -> {{ x = -2, y = 2 }, { x = 0.5, y = 0.5 }}
function math2d.position.split(pos)
    pos = math2d.position.ensure_xy(pos)

    local x_int, x_frac = math.modf(pos.x)
    local y_int, y_frac = math.modf(pos.y)

    if x_frac < 0 then
        x_int = x_int - 1
        x_frac = x_frac + 1
    end

    if y_frac < 0 then
        y_int = y_int - 1
        y_frac = y_frac + 1
    end

    return { x = x_int, y = y_int }, { x = x_frac, y = y_frac }
end

function math2d.position.tilepos(pos)
    pos = math2d.position.ensure_xy(pos)
    return { x = math.floor(pos.x), y = math.floor(pos.y) }
end

math2d.direction = {}

local function to_vector_table_generator(range)
    local positions = {}
    local check = range * 4
    local max = 8 * range - 1
    max = range >= 0 and max or 4

    for i = 0, max do
        table.insert(positions, i)
    end

    local status = 0.0

    for k, v in pairs(positions) do
        local mod = v % check

        if mod == 0 then
            positions[k] = 0
        elseif status < 0.25 then
            positions[k] = positions[k - 1] + 1
        elseif status >= 0.75 and status < 1.25 then
            positions[k] = positions[k - 1] - 1
        elseif status >= 1.25 and status < 1.75 then
            positions[k] = -range
        elseif status >= 1.75 then
            positions[k] = positions[k - 1] + 1
        else
            positions[k] = range
        end

        status = v / check
    end

    local merged = {}
    local max = max + 1

    for k, v in pairs(positions) do
        table.insert(merged, { x = v, y = positions[((k - (2 * range) - 1) % max) + 1] })
    end

    return merged
end

for i = 1, 48, 1 do
    math2d.direction["vectors" .. tostring(i)] = to_vector_table_generator(i)
end

function math2d.direction.from_vector(vec, range)
    range = range or 1
    vec = math2d.position.ensure_xy(vec)
    return math.floor(math.atan2(vec.x, -vec.y) * ((4 * range) / math.pi) + 0.5) % (8 * range)
end

function math2d.direction.to_vector(dir, range)
    range = range or 1
    return math2d.direction["vectors" .. tostring(range)][(dir % (8 * range)) + 1]
end

function math2d.direction.downscale_to_vec1(position, range)
    local check = range * 4
    local pos = math2d.direction.from_vector(position, range)
    local mod = pos / check

    if mod == 0 then
        return 1
    elseif mod > 0 and mod < 0.5 then
        return 2
    elseif mod == 0.5 then
        return 3
    elseif mod > 0.5 and mod < 1 then
        return 4
    elseif mod == 1 then
        return 5
    elseif mod > 1 and mod < 1.5 then
        return 6
    elseif mod == 1.5 then
        return 7
    elseif mod > 1.5 then
        return 8
    end
end

function math2d.direction.upscale_vec1(vec1_pos, range)
    return (vec1_pos - 1) * range
end

function math2d.round(vec)
    vec = math2d.position.ensure_xy(vec)
    local out = { x = vec.x, y = vec.y }
    if out.x < 0 then
        out.x = math.ceil(out.x)
    else
        out.x = math.ceil(out.x)
    end
    if out.y < 0 then
        out.y = math.ceil(out.y)
    else
        out.y = math.ceil(out.y)
    end
    return out
end

function math2d.no_minus_0(vec)
    vec = math2d.position.ensure_xy(vec)
    if vec.x == -0 then vec.x = 0 end
    if vec.y == -0 then vec.y = 0 end
    return vec
end

return math2d