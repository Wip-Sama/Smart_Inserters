if not settings.startup["si-diagonal-technologies"].value then
    data.raw.technology["si-unlock-cross"].hidden = true
    data.raw.technology["si-unlock-x-diagonals"].hidden = true
    data.raw.technology["si-unlock-all-diagonals"].hidden = true
    data.raw.technology["si-unlock-cross"].enabled = false
    data.raw.technology["si-unlock-x-diagonals"].enabled = false
    data.raw.technology["si-unlock-all-diagonals"].enabled = false
end

if not settings.startup["si-range-technologies"].value then
    data.raw.technology["si-unlock-range-1"].hidden = true
    data.raw.technology["si-unlock-range-2"].hidden = true
    data.raw.technology["si-unlock-range-3"].hidden = true
    data.raw.technology["si-unlock-range-4"].hidden = true
    data.raw.technology["si-unlock-range-5"].hidden = true
    data.raw.technology["si-unlock-range-1"].enabled = false
    data.raw.technology["si-unlock-range-2"].enabled = false
    data.raw.technology["si-unlock-range-3"].enabled = false
    data.raw.technology["si-unlock-range-4"].enabled = false
    data.raw.technology["si-unlock-range-5"].enabled = false
end

if not settings.startup["si-offset-technologies"].value then
    data.raw.technology["si-unlock-offsets"].hidden = true
    data.raw.technology["si-unlock-offsets"].enabled = false
end

if settings.startup["si-max-inserters-range"].value == 1 then
    data.raw.technology["si-unlock-all-diagonals"].hidden = true
    data.raw.technology["si-unlock-all-diagonals"].enabled = false
end

-- if settings.startup["si-max-inserters-range"].value == 1 then
--     data.raw.technology["si-unlock-all-diagonals"].hidden = true
--     data.raw.technology["si-unlock-range-1"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
--     data.raw.technology["si-unlock-range-2"].hidden = true
--     data.raw.technology["si-unlock-range-3"].hidden = true
--     data.raw.technology["si-unlock-range-4"].hidden = true
--     data.raw.technology["si-unlock-range-5"].hidden = true
--     data.raw.technology["si-unlock-all-diagonals"].enabled = false
--     data.raw.technology["si-unlock-range-1"].enabled = settings.startup["si-range-adder"].value == "incremental"
--     data.raw.technology["si-unlock-range-2"].enabled = false
--     data.raw.technology["si-unlock-range-3"].enabled = false
--     data.raw.technology["si-unlock-range-4"].enabled = false
--     data.raw.technology["si-unlock-range-5"].enabled = false
-- end

-- if settings.startup["si-max-inserters-range"].value == 2 then
--     data.raw.technology["si-unlock-range-2"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
--     data.raw.technology["si-unlock-range-3"].hidden = true
--     data.raw.technology["si-unlock-range-4"].hidden = true
--     data.raw.technology["si-unlock-range-5"].hidden = true
--     data.raw.technology["si-unlock-range-2"].enabled = settings.startup["si-range-adder"].value == "incremental"
--     data.raw.technology["si-unlock-range-3"].enabled = false
--     data.raw.technology["si-unlock-range-4"].enabled = false
--     data.raw.technology["si-unlock-range-5"].enabled = false
-- end

-- if settings.startup["si-max-inserters-range"].value == 3 then
--     data.raw.technology["si-unlock-range-3"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
--     data.raw.technology["si-unlock-range-4"].hidden = true
--     data.raw.technology["si-unlock-range-5"].hidden = true
--     data.raw.technology["si-unlock-range-3"].enabled = settings.startup["si-range-adder"].value == "incremental"
--     data.raw.technology["si-unlock-range-4"].enabled = false
--     data.raw.technology["si-unlock-range-5"].enabled = false
-- end
-- if settings.startup["si-max-inserters-range"].value == 4 then
--     data.raw.technology["si-unlock-range-4"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
--     data.raw.technology["si-unlock-range-5"].hidden = true
--     data.raw.technology["si-unlock-range-4"].enabled = settings.startup["si-range-adder"].value == "incremental"
--     data.raw.technology["si-unlock-range-5"].enabled = false
-- end

-- if settings.startup["si-max-inserters-range"].value == 5 then
--     data.raw.technology["si-unlock-range-5"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
--     data.raw.technology["si-unlock-range-5"].enabled = settings.startup["si-range-adder"].value == "incremental"
-- end



local max_inserter_range = settings.startup["si-max-inserters-range"].value

data.raw.technology["si-unlock-range-" .. max_inserter_range].hidden = not (settings.startup["si-range-adder"].value == "incremental")
data.raw.technology["si-unlock-range-" .. max_inserter_range].enabled = settings.startup["si-range-adder"].value == "incremental"

for i = max_inserter_range+1, 5 do
    data.raw.technology["si-unlock-range-" .. i].hidden = true
    data.raw.technology["si-unlock-range-" .. i].enabled = false
end