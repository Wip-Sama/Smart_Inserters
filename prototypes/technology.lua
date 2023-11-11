local difficulty = {}
----Normal difficulty----
difficulty["offsets"] = {
    {
        count = 20,
        ingredients = {
            { "automation-science-pack", 1 }
        }
    }
}
difficulty["diagonals"] = {
    {
        count = 10,
        ingredients = {
            { "automation-science-pack", 1 }
        }
    },
    {
        count = 50,
        ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack",   1 }
        }
    },
    {
        count = 100,
        ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack",   1 },
            { "chemical-science-pack",   1 }
        }
    }
}
difficulty["range"] = {
    { --5x5
        count = 10,
        ingredients = {
            { "automation-science-pack", 1 }
        }
    },
    { --7x7
        count = 50,
        ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack",   1 }
        }
    },
    { --9x9
        count = 100,
        ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack",   1 },
            { "chemical-science-pack",   1 }
        }
    },
    { --11x11
        count = 500,
        ingredients = {
            { "automation-science-pack", 1 },
            { "logistic-science-pack",   1 },
            { "chemical-science-pack",   1 },
            { "utility-science-pack",    1 }
        }
    },
}

----Hard difficulty----
if settings.startup["si-technologies-difficulty"].value == "hard" then
    difficulty["offsets"] = {
        {
            count = 50,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 }
            }
        }
    }
    difficulty["diagonals"] = {
        {
            count = 20,
            ingredients = {
                { "automation-science-pack", 1 }
            }
        },
        {
            count = 100,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 }
            }
        },
        {
            count = 200,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 }
            }
        }
    }
    difficulty["range"] = {
        { --5x5
            count = 50,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
            }
        },
        { --7x7
            count = 200,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 }
            }
        },
        { --9x9
            count = 500,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "utility-science-pack",    1 }
            }
        },
        { --11x11
            count = 1000,
            ingredients = {
                { "automation-science-pack", 1 },
                { "logistic-science-pack",   1 },
                { "chemical-science-pack",   1 },
                { "utility-science-pack",    1 }
            }
        },
    }
end

--offsets
data:extend({
    {
        type = "technology",
        name = "si-unlock-offsets",
        icon_size = 256,
        mipmap = 1,
        icon = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
        hidden = false,
        effects = {
            {
                type = "nothing",
                effect_description = { "technology-effect-description.si-unlock-offsets" }
            }
        },
        prerequisites = {},
        unit = {
            count = difficulty.offsets[1].count,
            ingredients = difficulty.offsets[1].ingredients,
            time = 30
        },
        order = "a-b-c-d"
    }
})

--diagonals
data:extend({
    {
        type = "technology",
        name = "si-unlock-cross",
        icon_size = 256,
        mipmap = 1,
        icon = "__Smart_Inserters__/graphics/technology/unlock_cross.png",
        hidden = false,
        effects = {
            {
                type = "nothing",
                effect_description = { "technology-effect-description.si-unlock-cross" }
            }
        },
        prerequisites = {},
        unit = {
            count = difficulty.diagonals[1].count,
            ingredients = difficulty.diagonals[1].ingredients,
            time = 30
        },
        order = "a-b-c-d"
    },
    {
        type = "technology",
        name = "si-unlock-x-diagonals",
        icon_size = 256,
        mipmap = 1,
        icon = "__Smart_Inserters__/graphics/technology/unlock_x_diagonals.png",
        hidden = false,
        effects = {
            {
                type = "nothing",
                effect_description = { "technology-effect-description.si-unlock-x-diagonals" }
            }
        },
        prerequisites = { "si-unlock-cross" },
        unit = {
            count = difficulty.diagonals[2].count,
            ingredients = difficulty.diagonals[2].ingredients,
            time = 30
        },
        order = "a-b-c-d"
    },
    {
        type = "technology",
        name = "si-unlock-all-diagonals",
        icon_size = 256,
        mipmap = 1,
        icon = "__Smart_Inserters__/graphics/technology/unlock_all_diagonals.png",
        hidden = false,
        effects = {
            {
                type = "nothing",
                effect_description = { "technology-effect-description.si-unlock-all-diagonals" }
            }
        },
        prerequisites = { "si-unlock-x-diagonals" },
        unit = {
            count = difficulty.diagonals[3].count,
            ingredients = difficulty.diagonals[3].ingredients,
            time = 30
        },
        order = "a-b-c-d"
    }
})

--range
data:extend({
    {
        type = "technology",
        name = "si-unlock-range-1",
        icon_size = 256,
        mipmap = 1,
        icon = "__Smart_Inserters__/graphics/technology/unlock_range_2.png",
        hidden = false,
        effects = {
            {
                type = "nothing",
                effect_description = { "technology-effect-description.si-unlock-range-1" }
            }
        },
        prerequisites = { "automation" },
        unit = {
            count = difficulty.range[1].count,
            ingredients = difficulty.range[1].ingredients,
            time = 30
        },
        order = "a-b-c-d"
    },
    {
        type = "technology",
        name = "si-unlock-range-2",
        icon_size = 256,
        mipmap = 1,
        icon = "__Smart_Inserters__/graphics/technology/unlock_range_3.png",
        hidden = false,
        effects = {
            {
                type = "nothing",
                effect_description = { "technology-effect-description.si-unlock-range-2" }
            }
        },
        prerequisites = { "si-unlock-range-1" },
        unit = {
            count = difficulty.range[2].count,
            ingredients = difficulty.range[2].ingredients,
            time = 30
        },
        order = "a-b-c-d"
    },
    {
        type = "technology",
        name = "si-unlock-range-3",
        icon_size = 256,
        mipmap = 1,
        icon = "__Smart_Inserters__/graphics/technology/unlock_range_4.png",
        hidden = false,
        effects = {
            {
                type = "nothing",
                effect_description = { "technology-effect-description.si-unlock-range-3" }
            }
        },
        prerequisites = { "si-unlock-range-2" },
        unit = {
            count = difficulty.range[3].count,
            ingredients = difficulty.range[4].ingredients,
            time = 30
        },
        order = "a-b-c-d"
    },
    {
        type = "technology",
        name = "si-unlock-range-4",
        icon_size = 256,
        mipmap = 1,
        icon = "__Smart_Inserters__/graphics/technology/unlock_range_5.png",
        hidden = false,
        effects = {
            {
                type = "nothing",
                effect_description = { "technology-effect-description.si-unlock-range-4" }
            }
        },
        prerequisites = { "si-unlock-range-3" },
        unit = {
            count = difficulty.range[4].count,
            ingredients = difficulty.range[4].ingredients,
            time = 30
        },
        order = "a-b-c-d"
    },
})

if not mods["bobinserters"] then
	data:extend({
		{
			type = "technology",
			name = "long-inserters-1",
			icon = "__Smart_Inserters__/graphics/icons/circle.png",
			icon_size = 64,
			unit = {
				count = 1,
				ingredients = { { "automation-science-pack", 1 } },
				time = 1,
			},
			order = "a",
			hidden = true,
		},
		{
			type = "technology",
			name = "long-inserters-2",
			icon = "__Smart_Inserters__/graphics/icons/circle.png",
			icon_size = 64,
			effects = {},
			prerequisites = {},
			unit = {
				count = 1,
				ingredients = { { "automation-science-pack", 1 } },
				time = 1,
			},
			order = "a",
			hidden = true,
		},
		{
			type = "technology",
			name = "near-inserters",
			icon = "__Smart_Inserters__/graphics/icons/circle.png",
			icon_size = 64,
			effects = {},
			prerequisites = {},
			unit = {
				count = 1,
				ingredients = { { "automation-science-pack", 1 } },
				time = 1,
			},
			order = "a",
			hidden = true,
		},
		{
			type = "technology",
			name = "more-inserters-1",
			icon = "__Smart_Inserters__/graphics/icons/circle.png",
			icon_size = 64,
			effects = {},
			prerequisites = {},
			unit = {
				count = 1,
				ingredients = { { "automation-science-pack", 1 } },
				time = 1,
			},
			order = "a",
			hidden = true,
		},
		{
			type = "technology",
			name = "more-inserters-2",
			icon = "__Smart_Inserters__/graphics/icons/circle.png",
			icon_size = 64,
			effects = {},
			prerequisites = {},
			unit = {
				count = 1,
				ingredients = { { "automation-science-pack", 1 } },
				time = 1,
			},
			order = "a",
			hidden = true,
		}
	})
end
