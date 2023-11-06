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