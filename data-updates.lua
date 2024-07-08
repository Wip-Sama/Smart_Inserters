if not settings.startup["si-diagonal-technologies"].value then
    data.raw.technology["si-unlock-cross"].hidden = true
    data.raw.technology["si-unlock-x-diagonals"].hidden = true
    data.raw.technology["si-unlock-all-diagonals"].hidden = true
end

if not settings.startup["si-range-technologies"].value then
    data.raw.technology["si-unlock-range-1"].hidden = true
    data.raw.technology["si-unlock-range-2"].hidden = true
    data.raw.technology["si-unlock-range-3"].hidden = true
    data.raw.technology["si-unlock-range-4"].hidden = true
    data.raw.technology["si-unlock-range-5"].hidden = true
end

if settings.startup["si-max-inserters-range"].value == 1 then
    data.raw.technology["si-unlock-all-diagonals"].hidden = true
    data.raw.technology["si-unlock-range-1"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
    data.raw.technology["si-unlock-range-2"].hidden = true
    data.raw.technology["si-unlock-range-3"].hidden = true
    data.raw.technology["si-unlock-range-4"].hidden = true
    data.raw.technology["si-unlock-range-5"].hidden = true
end

if settings.startup["si-max-inserters-range"].value == 2 then
    data.raw.technology["si-unlock-range-2"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
    data.raw.technology["si-unlock-range-3"].hidden = true
    data.raw.technology["si-unlock-range-4"].hidden = true
    data.raw.technology["si-unlock-range-5"].hidden = true

end
if settings.startup["si-max-inserters-range"].value == 3 then
    data.raw.technology["si-unlock-range-3"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
    data.raw.technology["si-unlock-range-4"].hidden = true
    data.raw.technology["si-unlock-range-5"].hidden = true
end
if settings.startup["si-max-inserters-range"].value == 4 then
    data.raw.technology["si-unlock-range-4"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
    data.raw.technology["si-unlock-range-5"].hidden = true
end
if settings.startup["si-max-inserters-range"].value == 5 then
    data.raw.technology["si-unlock-range-5"].hidden = not (settings.startup["si-range-adder"].value == "incremental")
end
if not settings.startup["si-offset-technologies"].value then
    data.raw.technology["si-unlock-offsets"].hidden = true
end
