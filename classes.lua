---@class tech_lookup_table
---@field range boolean[]
---@field diagonal boolean[]
---@field check boolean[][]


---@class InserterArmChanged
---@field player_index number
---@field entity LuaEntity
---@field old_pickup Position | nil
---@field old_drop Position | nil
---@field old_pickup_offset Position | nil
---@field old_drop_offset Position | nil
---@field do_not_popolate boolean | nil -- Do not add back new pick/drop positions


---@class ArmPosition
---@field base Position
---@field base_offset Position
---@field drop_offset Position
---@field pickup_offset Position
---@field drop Position
---@field pickup Position
---@field drop_direction number
---@field pickup_direction number


---@class ChangeArmPosition
---@field pickup Position | nil
---@field drop Position | nil
---@field pickup_offset Position | nil
---@field drop_offset Position | nil


---@class Position
---@field x number
---@field y number


---@class RenderedPosition
---@field background_render number
---@field border_render number
---@field drop_render number?
---@field pickup_render number?


---@class SelectedInserter
---@field position Position?
---@field surface LuaSurface?
---@field drop Position?
---@field pickup Position?
---@field inserter LuaEntity?
---@field displayed_elements table<table<RenderedPosition>>
---@field name string? --Not user but may become useful

