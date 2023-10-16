local math2d = require("math2d")
local inserter_utils = require("lib.inserter_checker")

local chases_belt_items = settings.startup["si-inserters-chase-belt-items"].value

local long_inserters = {}

for _, inserter in pairs(data.raw.inserter) do
	inserter.allow_custom_vectors = true
	inserter.extension_speed = inserter.extension_speed * 2
	inserter.chases_belt_items = chases_belt_items
end

if settings.startup["si-disable-long-inserters"].value then
	for _, item in pairs(data.raw.item) do
		if item.place_result ~= nil then
			for _, inserter in pairs(data.raw.inserter) do
				local inserter = inserter.name
				if item.place_result == inserter then
					if inserter_utils.is_inserter_long(data.raw.inserter[inserter]) then
						table.insert(long_inserters, inserter)
					end
				end
			end
		end
	end

	for _, recipe in pairs(data.raw.recipe) do
		if recipe.results ~= nil then
			if inserter_utils.inserter_in_results(recipe.results, long_inserters) then
				recipe.hidden = true
			end
		elseif recipe.result ~= nil then
			if inserter_utils.inserter_in_result(recipe.result, long_inserters) then
				recipe.hidden = true
			end
		end
	end
end
