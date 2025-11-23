local drop_file = settings.startup["si-high-contrast-sprites"].value and "drop_hc.png" or "drop.png"
local pickup_file = settings.startup["si-high-contrast-sprites"].value and "pickup_hc.png" or "pickup.png"

--In world selector
data:extend({
	--pickup
	{
		type = "blueprint",
		name = "si-in-world-pickup-changer",
		icon = "__Smart_Inserters__/graphics/icons/"..pickup_file,
		icon_size = 128,
		flags = { "not-stackable", "only-in-cursor" },
		collision_mask = {layers = {}},
		hidden = true;
		scale = 0.2,
		stack_size = 1,
		select = {
		  border_color = {0 , 0, 0 },
		  count_button_color = { 0, 0, 0 },
		  mode = {"blueprint"},
		  cursor_box_type = "logistics",
		},
		alt_select = {
		  border_color = { 0, 0, 0 },
		  count_button_color = { 0, 0, 0 },
		  mode = {"blueprint"},
		  cursor_box_type = "logistics",
		},
	},
	{
		type = "item",
		name = "si-in-world-pickup-selector",
		icon = "__Smart_Inserters__/graphics/icons/"..pickup_file,
		scale = 0.2,
		icon_size = 128,
		order = "a-b",
		hidden = true;
		place_result = "si-in-world-pickup-entity",
		stack_size = 1
	},
	{
		type = "simple-entity-with-owner",
		name = "si-in-world-pickup-entity",
		icon = "__Smart_Inserters__/graphics/icons/"..pickup_file,
		icon_size = 128,
		scale = 0.2,
		flags = { "not-on-map", "player-creation" },
		collision_mask = {layers = {}},
		hidden = true;
		collision_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		placeable_by = {
			item = "si-in-world-pickup-selector",
			count = 1
		},
		picture = {
			filename = "__Smart_Inserters__/graphics/icons/"..pickup_file,
			size = 128,
			scale = 0.2,
		}
	},
	--drop
	{
		type = "blueprint",
		name = "si-in-world-drop-changer",
		icon = "__Smart_Inserters__/graphics/icons/"..drop_file,
		icon_size = 128,
		scale = 0.2,
		flags = { "not-stackable", "only-in-cursor" },
		hidden = true;
		stack_size = 1,
		select = {
			border_color = {0 , 0, 0 },
			count_button_color = { 0, 0, 0 },
			mode = {"blueprint"},
			cursor_box_type = "logistics",
		},
			alt_select = {
			border_color = { 0, 0, 0 },
			count_button_color = { 0, 0, 0 },
			mode = {"blueprint"},
			cursor_box_type = "logistics",
		},
	},
	{
		type = "item",
		name = "si-in-world-drop-selector",
		icon = "__Smart_Inserters__/graphics/icons/"..drop_file,
		icon_size = 128,
		scale = 0.2,
		order = "a-b",
		hidden = true;
		place_result = "si-in-world-drop-entity",
		stack_size = 1
	},
	{
		type = "simple-entity-with-owner",
		name = "si-in-world-drop-entity",
		icon = "__Smart_Inserters__/graphics/icons/"..drop_file,
		icon_size = 128,
		scale = 0.2,
		flags = { "not-on-map", "player-creation" },
		hidden = true;
		collision_mask = {layers = {}},
		collision_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		placeable_by = {
			item = "si-in-world-drop-selector",
			count = 1
		},
		picture = {
			filename = "__Smart_Inserters__/graphics/icons/"..drop_file,
			size = 128,
			scale = 0.2,
		}
	}
})