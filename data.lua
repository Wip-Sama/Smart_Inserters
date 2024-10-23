local pickup_tint = { r = 1 / 255, g = 165 / 255, b = 53 / 255 }
local drop_tint = { r = 155 / 255, g = 19 / 255, b = 7 / 255 }
require("prototypes.technology")
require("prototypes.style")

--Sprites
data:extend({
	--generic circle sprite
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
		size = 128,
		priority = "extra-high-no-scale",
	},
	{
		type = "sprite",
		name = "pickup-background",
		filename = "__Smart_Inserters__/graphics/icons/pickup_background.png",
		flags = { "gui-icon" },
		size = 128,
		priority = "extra-high-no-scale"
	},
	{
		type = "sprite",
		name = "half-pickup-background",
		filename = "__Smart_Inserters__/graphics/icons/half_pickup_background.png",
		flags = { "gui-icon" },
		size = 128,
		priority = "extra-high-no-scale"
	},
	--drop
	{
		type = "sprite",
		name = "drop",
		filename = "__Smart_Inserters__/graphics/icons/drop.png",
		flags = { "gui-icon" },
		size = 128,
		priority = "extra-high-no-scale",
	},
	{
		type = "sprite",
		name = "drop-background",
		filename = "__Smart_Inserters__/graphics/icons/drop_background.png",
		flags = { "gui-icon" },
		size = 128,
		priority = "extra-high-no-scale"
	},
	{
		type = "sprite",
		name = "half-drop-background",
		filename = "__Smart_Inserters__/graphics/icons/half_drop_background.png",
		flags = { "gui-icon" },
		size = 128,
		priority = "extra-high-no-scale"
	},
	--combo
	{
		type = "sprite",
		name = "combo",
		filename = "__Smart_Inserters__/graphics/icons/combo.png",
		flags = { "gui-icon" },
		size = 128,
		priority = "extra-high-no-scale"
	},
	{
		type = "sprite",
		name = "combo-background",
		filename = "__Smart_Inserters__/graphics/icons/combo_background.png",
		flags = { "gui-icon" },
		size = 128,
		priority = "extra-high-no-scale"
	},
})

--In world selector
data:extend({
	--pickup
	{
		type = "blueprint",
		name = "si-in-world-pickup-changer",
		icon = "__Smart_Inserters__/graphics/icons/pickup.png",
		icon_size = 128,
		flags = { "not-stackable", "only-in-cursor" },
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
		icon = "__Smart_Inserters__/graphics/icons/pickup.png",
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
		icon = "__Smart_Inserters__/graphics/icons/pickup.png",
		icon_size = 128,
		scale = 0.2,
		flags = { "not-on-map", "player-creation" },
		hidden = true;
		collision_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		placeable_by = {
			item = "si-in-world-pickup-selector",
			count = 1
		},
		picture = {
			filename = "__Smart_Inserters__/graphics/icons/pickup.png",
			size = 128,
			scale = 0.2,
		}
	},
	--drop
	{
		type = "blueprint",
		name = "si-in-world-drop-changer",
		icon = "__Smart_Inserters__/graphics/icons/drop.png",
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
		icon = "__Smart_Inserters__/graphics/icons/drop.png",
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
		icon = "__Smart_Inserters__/graphics/icons/drop.png",
		icon_size = 128,
		scale = 0.2,
		flags = { "not-on-map", "player-creation" },
		hidden = true;
		collision_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
		placeable_by = {
			item = "si-in-world-drop-selector",
			count = 1
		},
		picture = {
			filename = "__Smart_Inserters__/graphics/icons/drop.png",
			size = 128,
			scale = 0.2,
		}
	}
})

--Inputs
data:extend({
	--- DROP
	{
		type = "custom-input",
		name = "smart-inserters-drop-rotate",
		key_sequence = "",
		consuming = "none",
		order = "Aa"
	}, {
		type = "custom-input",
		name = "smart-inserters-drop-rotate-reverse",
		key_sequence = "",
		consuming = "none",
		order = "Ab"
	},{
		type = "custom-input",
		name = "smart-inserters-drop-distance-adjust",
		key_sequence = "",
		consuming = "none",
		order = "Ac"
	}, {
		type = "custom-input",
		name = "smart-inserters-drop-distance-adjust-reverse",
		key_sequence = "",
		consuming = "none",
		order = "Ad"
	}, {
		type = "custom-input",
		name = "smart-inserters-drop-offset-adjust",
		key_sequence = "",
		consuming = "none",
		order = "Ae"
	},


	--- PICKUP
	{
		type = "custom-input",
		name = "smart-inserters-pickup-rotate",
		key_sequence = "",
		consuming = "none",
		order = "Ba"
	}, {
		type = "custom-input",
		name = "smart-inserters-pickup-rotate-reverse",
		key_sequence = "",
		consuming = "none",
		order = "Bb"
	},{
		type = "custom-input",
		name = "smart-inserters-pickup-distance-adjust",
		key_sequence = "",
		consuming = "none",
		order = "Bc"
	}, {
		type = "custom-input",
		name = "smart-inserters-pickup-distance-adjust-reverse",
		key_sequence = "",
		consuming = "none",
		order = "Bd"
	}, {
		type = "custom-input",
		name = "smart-inserters-pickup-offset-adjust",
		key_sequence = "",
		consuming = "none",
		order = "Be"
	},

	--- IN WORLD SELECTOR
	{
		type = "custom-input",
		name = "smart-inserters-in-world-inserter-configurator-drop",
		key_sequence = "",
		consuming = "none",
		order = "Ca"
	}, {
		type = "custom-input",
		name = "smart-inserters-in-world-inserter-configurator-pickup",
		key_sequence = "",
		consuming = "none",
		order = "Cb"
	}
})