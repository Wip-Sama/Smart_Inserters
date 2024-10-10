local style = data.raw["gui-style"]["default"]

style.si_hotbar_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8
}

style.si_hotbar_sprite = {
  type = "image_style",
  size = 20,
  stretch_image_to_widget_size = true
}

style.si_drag_handle = {
  type = "empty_widget_style",
  parent = "draggable_space",
  horizontally_stretchable = "on",
  height = 24,
  left_margin = 4,
  right_margin = 4
}

style.slot_sized_button_drop =
{
  type = "button_style",
  parent = "slot_sized_button",
  default_graphical_set =
  {
    base = {
      position = {312, 744},
      corner_size = 8,
      tint = {r = 254, g = 90, b = 90, a = .05},
    },
  },
}

style.slot_sized_button_pickup =
{
  type = "button_style",
  parent = "slot_sized_button",
  default_graphical_set =
  {
    base = {
      position = {312, 744},
      corner_size = 8,
      tint = {r = 94, g = 182, b = 99, a = .05},
    },
  },
}