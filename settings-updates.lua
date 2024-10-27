local slim_inserter = true
local known_slim_inserter_mods = {
    "arrow-inserter",
    "Kux-SlimInserters"
}

for _, v in pairs(known_slim_inserter_mods) do
    if mods[v] then
        slim_inserter = false
        break
    end
end

-- data.raw["bool-setting"]["si-single-line-slim-inserter"].hidden = slim_inserter
-- data.raw["bool-setting"]["si-directional-slim-inserter"].hidden = slim_inserter