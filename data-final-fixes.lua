local si_util = require('scripts.si_util')

---@type boolean
---@diagnostic disable-next-line: assign-type-mismatch
local chases_belt_items = settings.startup["si-inserters-chase-belt-items"].value

local inserter_functions = require("scripts.inserter_functions")
local disable_inserter_consumption = settings.startup["si-disable-inserters-consumption"].value

local long_inserters = {}
for name, inserter in pairs(data.raw.inserter) do
	if si_util.check_prototype_blacklist(name) then
		inserter.allow_custom_vectors = true
		inserter.extension_speed = inserter.extension_speed * 2
		if disable_inserter_consumption then
			inserter.energy_per_movement = "0J"
			inserter.energy_per_rotation = "0J"
			inserter.energy_source = {
				type = "void"
			}
		end
		inserter.chases_belt_items = chases_belt_items
		if inserter.fast_replaceable_group == "long-handed-inserter" then
			inserter.fast_replaceable_group = "inserter"
			if inserter.name == "long-handed-inserter" then
				inserter.next_upgrade = "inserter"
			end
		end
	end
end

if settings.startup["si-disable-long-inserters"].value then
	for _, item in pairs(data.raw.item) do
		if item.place_result ~= nil then
			for _, inserter in pairs(data.raw.inserter) do
				if item.place_result == inserter.name then
					if inserter_functions.is_inserter_long(data.raw.inserter[inserter.name]) then
						table.insert(long_inserters, inserter.name)
						inserter.hidden_in_factoriopedia = true
						inserter.hidden = true
					end
				end
			end
		end
	end

	for _, recipe in pairs(data.raw.recipe) do
		if recipe.results ~= nil then
			if inserter_functions.inserter_in_results(recipe.results, long_inserters) then
				recipe.hidden = true
			end
		end
	end
end
