local math2d = require("math2d")

local function inserter_in_result(result, long_inserters)
	for _, linserter in pairs(long_inserters) do
		if linserter == result then
			return true
		end
	end
	return false
end

local function inserter_in_results(results, long_inserters)
	for _, linserter in pairs(long_inserters) do
		for _, reciperecult in pairs(results) do
			if reciperecult == nil then break end
			if type(reciperecult) == "table" then
				for _, singleresult in pairs(reciperecult) do
					if type(singleresult) == "string" and singleresult == linserter then
						return true
					end
				end
			elseif reciperecult == linserter then
				return true
			end
		end
	end
	return false
end

local function is_inserter_long(inserter)
	local collision_box_toal = 0.2
	if inserter.collision_box ~= nil then
		local collision_box_1 = math2d.position.ensure_xy(inserter.collision_box[1])
		local collision_box_2 = math2d.position.ensure_xy(inserter.collision_box[2])
		local collision_box_1_max = math.max(math.abs(collision_box_1.x), math.abs(collision_box_1.y))
		local collision_box_2_max = math.max(math.abs(collision_box_2.x), math.abs(collision_box_2.y))
		collision_box_toal = collision_box_1_max+collision_box_2_max
	end

	local biggest = { x = 0, y = 0, z = 0 }
	local pickup_position = math2d.position.ensure_xy(inserter.pickup_position)
	local insert_position = math2d.position.ensure_xy(inserter.insert_position)
	biggest.x = math.max(math.abs(pickup_position.x), math.abs(insert_position.x))
	biggest.y = math.max(math.abs(pickup_position.y), math.abs(insert_position.y))
	biggest.z = math.max(biggest.x, biggest.y)-collision_box_toal

	if biggest.z > 1 then
		return true
	end
	return false
end

local function is_inserter_mini(inserter)
    if inserter.tile_height == 0 or inserter.tile_width == 0 then
        return true
    end
    return false
end

return {
    is_inserter_long = is_inserter_long;
    is_inserter_mini = is_inserter_mini;
	inserter_in_result = inserter_in_result;
	inserter_in_results = inserter_in_results;
}