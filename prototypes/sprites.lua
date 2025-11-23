local drop_file = settings.startup["si-high-contrast-sprites"].value and "drop_hc.png" or "drop.png"
local pickup_file = settings.startup["si-high-contrast-sprites"].value and "pickup_hc.png" or "pickup.png"
local combo_file = settings.startup["si-high-contrast-sprites"].value and "combo_hc.png" or "combo.png"

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
		filename = "__Smart_Inserters__/graphics/icons/"..pickup_file,
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
		filename = "__Smart_Inserters__/graphics/icons/"..drop_file,
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
		filename = "__Smart_Inserters__/graphics/icons/"..combo_file,
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
