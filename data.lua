local pickup_tint = { r = 1 / 255, g = 165 / 255, b = 53 / 255 }
local drop_tint = { r = 155 / 255, g = 19 / 255, b = 7 / 255 }

local chr = data.raw.character.character

data:extend({
	{
		type = "blueprint",
		name = "si-in-world-pickup-changer",
		icon = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
		icon_size = 256,
		flags = { "hidden", "not-stackable", "only-in-cursor" },
		stack_size = 1,
		selection_color = { 0, 1, 0 },
		alt_selection_color = { 0, 1, 0 },
		selection_mode = { "blueprint" },
		alt_selection_mode = { "blueprint" },
		selection_cursor_box_type = "logistics",
		alt_selection_cursor_box_type = "logistics"
	},
	{
		type = "blueprint",
		name = "si-in-world-drop-changer",
		icon = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
		icon_size = 256,
		flags = { "hidden", "not-stackable", "only-in-cursor" },
		stack_size = 1,
		selection_color = { 0, 1, 0 },
		alt_selection_color = { 0, 1, 0 },
		selection_mode = { "blueprint" },
		alt_selection_mode = { "blueprint" },
		selection_cursor_box_type = "logistics",
		alt_selection_cursor_box_type = "logistics"
	},
	{
		type = "item",
		name = "si-in-world-pickup-selector",
		icon = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
		icon_size = 256,
		order = "a-b",
		flags = { "hidden" },
		place_result = "si-in-world-pickup-entity",
		stack_size = 1
	},
	{
		type = "item",
		name = "si-in-world-drop-selector",
		icon = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
		icon_size = 256,
		order = "a-b",
		flags = { "hidden" },
		place_result = "si-in-world-drop-entity",
		stack_size = 1
	},
	{
		type = "simple-entity-with-owner",
		name = "si-in-world-pickup-entity",
		icon = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
		icon_size = 256,
		flags = { "hidden", "not-on-map", "player-creation" },
		collision_mask = {},
		collision_box = { { -1, -1 }, { 0, 0 } },
		selection_box = { { -1, -1 }, { 0, 0 } },
		placeable_by = {
			item = "si-in-world-pickup-selector",
			count = 1
		},
		picture = {
			filename = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
			size = { 32, 32 }
		}
	},
	{
		type = "simple-entity-with-owner",
		name = "si-in-world-drop-entity",
		icon = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
		icon_size = 256,
		flags = { "hidden", "not-on-map", "player-creation" },
		collision_mask = {},
		collision_box = { { -1, -1 }, { 0, 0 } },
		selection_box = { { -1, -1 }, { 0, 0 } },
		placeable_by = {
			item = "si-in-world-drop-selector",
			count = 1
		},
		picture = {
			filename = "__Smart_Inserters__/graphics/technology/unlock_offsets.png",
			size = { 32, 32 }
		}
	}
})

data:extend({
	{
		type = "sprite",
		name = "circle",

		filename = "__Smart_Inserters__/graphics/icons/circle.png",
		flags = { "gui-icon" },
		width = 64,
		height = 64,
		scale = 0.5,
		priority = "extra-high-no-scale"
	},
	--pickup
	{
		type = "sprite",
		name = "pickup",

		filename = "__Smart_Inserters__/graphics/icons/pickup.png",
		flags = { "gui-icon" },
		width = 40,
		height = 40,
		scale = 0.5,
		tint = pickup_tint,
		priority = "extra-high-no-scale"
	},
	{
		type = "sprite",
		name = "background-pickup",

		filename = "__Smart_Inserters__/graphics/icons/background.png",
		flags = { "gui-icon" },
		width = 40,
		height = 40,
		scale = 0.5,
		tint = pickup_tint,
		priority = "extra-high-no-scale"
	},
	{
		type = "sprite",
		name = "selected-pickup",

		filename = "__Smart_Inserters__/graphics/icons/background-pickup.png",
		flags = { "gui-icon" },
		width = 40,
		height = 40,
		scale = 0.5,
		tint = pickup_tint,
		priority = "extra-high-no-scale"
	},
	--drop
	{
		type = "sprite",
		name = "drop",

		filename = "__Smart_Inserters__/graphics/icons/drop.png",
		flags = { "gui-icon" },
		width = 40,
		height = 40,
		scale = 0.5,
		tint = drop_tint,
		priority = "extra-high-no-scale"
	},
	{
		type = "sprite",
		name = "background-drop",

		filename = "__Smart_Inserters__/graphics/icons/background.png",
		flags = { "gui-icon" },
		width = 40,
		height = 40,
		scale = 0.5,
		tint = drop_tint,
		priority = "extra-high-no-scale"
	},
	{
		type = "sprite",
		name = "selected-drop",

		filename = "__Smart_Inserters__/graphics/icons/background-drop.png",
		flags = { "gui-icon" },
		width = 40,
		height = 40,
		scale = 0.5,
		tint = drop_tint,
		priority = "extra-high-no-scale"
	},
})

data:extend({
	{
		type = "custom-input",
		name = "inserter-config-drop-rotate",
		key_sequence = "",
		consuming = "none",
		order = "0"
	},
	{
		type = "custom-input",
		name = "inserter-config-drop-rotate-reverse",
		key_sequence = "",
		consuming = "none",
		order = "1"
	},
	{
		type = "custom-input",
		name = "inserter-config-pickup-rotate",
		key_sequence = "CONTROL + R",
		consuming = "none",
		order = "2"
	},
	{
		type = "custom-input",
		name = "inserter-config-pickup-rotate-reverse",
		key_sequence = "CONTROL + SHIFT + R",
		consuming = "none",
		order = "3"
	},
	{
		type = "custom-input",
		name = "inserter-config-drop-distance-adjust",
		key_sequence = "F",
		consuming = "none",
		order = "4"
	},
	{
		type = "custom-input",
		name = "inserter-config-pickup-distance-adjust",
		key_sequence = "CONTROL + F",
		consuming = "none",
		order = "5"
	},
	{
		type = "custom-input",
		name = "inserter-config-drop-offset-adjust-lateral",
		key_sequence = "",
		consuming = "none",
		order = "6"
	},
	{
		type = "custom-input",
		name = "inserter-config-drop-offset-adjust-distance",
		key_sequence = "",
		consuming = "none",
		order = "7"
	},
	{
		type = "custom-input",
		name = "inserter-config-pickup-offset-adjust-lateral",
		key_sequence = "",
		consuming = "none",
		order = "8"
	},
	{
		type = "custom-input",
		name = "inserter-config-pickup-offset-adjust-distance",
		key_sequence = "",
		consuming = "none",
		order = "9"
	},
	{
		type = "custom-input",
		name = "inserter-config-in-world-inserter-configurator-pickup",
		key_sequence = "CONTROL + P",
		consuming = "none",
		order = "10"
	},
	{
		type = "custom-input",
		name = "inserter-config-in-world-inserter-configurator-drop",
		key_sequence = "CONTROL + D",
		consuming = "none",
		order = "11"
	}
})

data:extend({
	{
		type = "technology",
		name = "si-unlock-offsets",
		icon_size = 256,
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
			count = 20,
			ingredients = {
				{ "automation-science-pack", 1 }
			},
			time = 30
		},
		order = "a-b-c-d"
	},
	{
		type = "technology",
		name = "si-unlock-cross",
		icon_size = 256,
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
			count = 10,
			ingredients = {
				{ "automation-science-pack", 1 }
			},
			time = 30
		},
		order = "a-b-c-d"
	},
	{
		type = "technology",
		name = "si-unlock-x-diagonals",
		icon_size = 256,
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
			count = 50,
			ingredients = {
				{ "automation-science-pack", 1 },
				{ "logistic-science-pack",   1 }
			},
			time = 30
		},
		order = "a-b-c-d"
	},
	{
		type = "technology",
		name = "si-unlock-all-diagonals",
		icon_size = 256,
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
			count = 100,
			ingredients = {
				{ "automation-science-pack", 1 },
				{ "logistic-science-pack",   1 },
				{ "chemical-science-pack",   1 }
			},
			time = 30
		},
		order = "a-b-c-d"
	},
	{
		type = "technology",
		name = "si-unlock-range-1",
		icon_size = 256,
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
			count = 10,
			ingredients = {
				{ "automation-science-pack", 1 }
			},
			time = 30
		},
		order = "a-b-c-d"
	},
	{
		type = "technology",
		name = "si-unlock-range-2",
		icon_size = 256,
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
			count = 50,
			ingredients = {
				{ "automation-science-pack", 1 },
				{ "logistic-science-pack",   1 }
			},
			time = 30
		},
		order = "a-b-c-d"
	},
	{
		type = "technology",
		name = "si-unlock-range-3",
		icon_size = 256,
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
			count = 100,
			ingredients = {
				{ "automation-science-pack", 1 },
				{ "logistic-science-pack",   1 },
				{ "chemical-science-pack",   1 }
			},
			time = 30
		},
		order = "a-b-c-d"
	},
	{
		type = "technology",
		name = "si-unlock-range-4",
		icon_size = 256,
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
			count = 500,
			ingredients = {
				{ "automation-science-pack", 1 },
				{ "logistic-science-pack",   1 },
				{ "chemical-science-pack",   1 },
				{ "utility-science-pack",    1 }
			},
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
