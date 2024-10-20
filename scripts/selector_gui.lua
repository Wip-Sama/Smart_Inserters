local directional_slim_inserter = settings.startup["si-directional-slim-inserter"].value
local offset_selector = settings.startup["si-offset-selector"].value

local gui_builder = require("__yafla__/scripts/experimental/gui_builder")
local gui_helper = require("__yafla__/scripts/experimental/gui_helper")
local inserter_functions = require("scripts.inserter_functions")
local tecnology_functions = require("scripts.technology_functions")

local gui = {}

---@param inserter LuaEntity
---@return table
function gui.generate_slim_inserter_grid(inserter)
    local max_inserter_range, min_inserter_range = inserter_functions.get_max_and_min_inserter_range(inserter)
    local table_position = {}
    local direction = inserter.direction
    local width, height = math.ceil(inserter.tile_width), math.ceil(inserter.tile_height)
    width, height = math.max(1, width), math.max(1, height)
    local vertical = inserter.tile_width > 0
    for y = -max_inserter_range, max_inserter_range, 1 do
        for x = -max_inserter_range, max_inserter_range, 1 do
            if x == 0 and y == 0 then
                table.insert(table_position,
                    SPRITE {
                        name = "sprite_inserter",
                        sprite = "item/" .. inserter_functions.get_prototype(inserter).items_to_place_this[1].name,
                        stretch_image_to_widget_size = true,
                        size = { 32, 32 },
                    }
                    -- CAMERA {
                    --     position = inserter.position,
                    --     width = 32+33*(width-1),
                    --     height = 32+33*(height-1),
                    --     zoom = 1,
                    -- }
                )
            else
                if (x ~= 0 and not vertical) or (y ~= 0 and vertical) then
                    if not vertical and x > 0 then
                        if (inserter_functions.should_cell_be_enabled(inserter, {x = x-1, y = y})) then
                            table.insert(table_position,
                                SPRITE_BUTTON {
                                    name = tostring(x-1) .. "_" .. tostring(y),
                                    style = directional_slim_inserter and (inserter.direction == 2 and "slot_sized_button_pickup" or "slot_sized_button_drop") or "slot_sized_button",
                                    on_click = directional_slim_inserter and (inserter.direction == 2 and "change_drop" or "change_pickup") or "change_pickup_drop",
                                    size = { 32, 32 }
                                }
                            )
                        else
                            table.insert(table_position,
                                EMPTY_WIDGET {
                                    size = { 32, 32 }
                                }
                            )
                        end
                    elseif vertical and y > 0 then
                        if (inserter_functions.should_cell_be_enabled(inserter, {x = x, y = y-1})) then
                            table.insert(table_position,
                                SPRITE_BUTTON {
                                    name = tostring(x) .. "_" .. tostring(y-1),
                                    style = directional_slim_inserter and (inserter.direction == 4 and "slot_sized_button_pickup" or "slot_sized_button_drop") or "slot_sized_button",
                                    on_click = directional_slim_inserter and (inserter.direction == 4 and "change_drop" or "change_pickup") or "change_pickup_drop",
                                    size = { 32, 32 }
                                }
                            )
                        else
                            table.insert(table_position,
                                EMPTY_WIDGET {
                                    size = { 32, 32 }
                                }
                            )
                        end
                    else
                        if (inserter_functions.should_cell_be_enabled(inserter, {x = x, y = y})) then
                            table.insert(table_position,
                                SPRITE_BUTTON {
                                    name = tostring(x) .. "_" .. tostring(y),
                                    style = directional_slim_inserter and ((inserter.direction == 6 or inserter.direction == 0) and "slot_sized_button_pickup" or "slot_sized_button_drop") or "slot_sized_button",
                                    on_click = directional_slim_inserter and ((inserter.direction == 6 or inserter.direction == 0) and "change_drop" or "change_pickup") or "change_pickup_drop",
                                    size = { 32, 32 }
                                }
                            )
                        else
                            table.insert(table_position,
                                EMPTY_WIDGET {
                                    size = { 32, 32 }
                                }
                            )
                        end
                    end
                else
                    table.insert(table_position,
                        EMPTY_WIDGET {
                            --name = tostring(x) .. "_" .. tostring(y),
                            size = { 32, 32 }
                        }
                    )
                end
            end
        end
    end
    return table_position
end

---@param inserter LuaEntity
---@return table
function gui.generate_x_y_inserter_grid(inserter)
    local max_inserter_range, min_inserter_range = inserter_functions.get_max_and_min_inserter_range(inserter)
    local width, height = math.ceil(inserter.tile_width), math.ceil(inserter.tile_height)

    local lower_width = width%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5

    local table_position = {}
    for y = -max_inserter_range-lower_height, max_inserter_range+higher_height-1, 1 do
        for x = -max_inserter_range-lower_width, max_inserter_range+higher_width-1, 1 do
            if (-lower_width <= x and x < higher_width) and (-lower_height <= y and y < higher_height) then
                if x == higher_width-1 and y == higher_height-1 then
                    table.insert(table_position,
                        FLOW {
                            top_margin = (height-1)*-33,
                            left_margin = width/2*-33*math.min(1, width-1), -- use with sprite
                            --left_margin = (width-1)*-33, -- use with camera
                            SPRITE {
                                name = "sprite_inserter_"..tostring(x) .. "_" .. tostring(y),
                                sprite = "item/" .. inserter_functions.get_prototype(inserter).items_to_place_this[1].name,
                                size = 32+33*(math.min(width, height)-1),
                                resize_to_sprite = false
                            }
                            -- CAMERA {
                            --     position = inserter.position,
                            --     width = 32+33*(width-1),
                            --     height = 32+33*(height-1),
                            -- }
                        }
                    )
                else
                    table.insert(table_position,
                        EMPTY_WIDGET {
                            size = { 32, 32 }
                        }
                    )
                end
            else
                if (inserter_functions.should_cell_be_enabled(inserter, {x = x, y = y})) then
                    table.insert(table_position,
                        SPRITE_BUTTON {
                            name = tostring(x) .. "_" .. tostring(y),
                            style = "slot_sized_button",
                            on_click = "change_pickup_drop",
                            size = { 32, 32 }
                        }
                    )
                else
                    table.insert(table_position,
                        EMPTY_WIDGET {
                            size = { 32, 32 }
                        }
                    )
                end
            end
        end
    end
    return table_position
end

---@param inserter LuaEntity
---@return table
function gui.create_pickup_drop_editor(inserter)
    local max_inserter_range, min_inserter_range = inserter_functions.get_max_and_min_inserter_range(inserter)

    --TODO: in an ideal world "generate_slim_inserter_grid" should not exist, the actual x_y funxion is quite good but lack some features need for slim inserters
    grid = inserter_functions.is_slim(inserter) and gui.generate_slim_inserter_grid(inserter) or gui.generate_x_y_inserter_grid(inserter)

    local width = inserter.tile_width > 0 and inserter.tile_width or 1

    return FLOW {
        name = "pickup_drop_housing",
        direction = "vertical",
        LABEL {
            name = "label_position",
            caption = { "gui-smart-inserters.position" },
            style = "heading_2_label"
        },
        TABLE {
            name = "table_position",
            horizontal_spacing = 1,
            vertical_spacing = 1,
            column_count = max_inserter_range*2+width,
            --3 if I want to use the 3x3 table approach, it could be useful for slim inserter so need to keep an eye on it
            --column_count = 3,
            grid
        }
    }
end

---@param force LuaForce
---@param offset_name string
---@return table
function gui.create_offset_editor(force, offset_name)
    local table_editor = {}
    if tecnology_functions.check_offset_tech(force) then
        for y = 1, 3, 1 do
            for x = 1, 3, 1 do
                table.insert(table_editor,
                    SPRITE_BUTTON {
                        name = tostring(x/4) .. "_" .. tostring(y/4),
                        style = "slot_sized_button",
                        size = { 32, 32 },
                        on_click = "change_" .. offset_name .. "_offset",
                    }
                )
            end
        end
    else
        for y = 1, 3, 1 do
            for x = 1, 3, 1 do
                table.insert(table_editor,
                    SPRITE_BUTTON {
                        name = tostring(x/4) .. "_" .. tostring(y/4),
                        style = "slot_sized_button",
                        size = { 32, 32 },
                        on_click = "change_" .. offset_name .. "_offset",
                        enabled = false
                    }
                )
            end
        end
    end

    return FLOW {
        name = "flow_" .. offset_name,
        direction = "vertical",
        LABEL {
            name = "label_" .. offset_name .. "_offset",
            caption = { "gui-smart-inserters." .. offset_name .. "-offset" },
            style = "heading_2_label"
        },
        TABLE {
            name = "table_" .. offset_name,
            column_count = 3,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            table_editor
        }
    }
end

---@param player LuaPlayer
function gui.delete(player)
    if player.gui.relative.inserter_config then
        player.gui.relative.inserter_config.destroy()
    end
    if player.gui.relative.smart_inserters then
        player.gui.relative.smart_inserters.destroy()
    end
end

function gui.delete_all()
    for _, player in pairs(game.players) do
        gui.delete(player)
    end
end

---@param player LuaPlayer
---@param inserter LuaEntity
function gui.create(player, inserter)
    local selector_gui = FRAME {
        name = "smart_inserters",
        caption = { "gui-smart-inserters.configuration" },
        anchor = {
            gui = defines.relative_gui_type.inserter_gui,
            position = defines.relative_gui_position.right
        },
        FRAME {
            name = "frame_content",
            style = "inside_shallow_frame",
            FLOW {
                name = "flow_content",
                direction = "vertical",
                FLOW {
                    padding = 10,
                    name = "pickup_drop_flow",
                    direction = "vertical",
                    EMPTY_WIDGET {
                        name = "pusher_left",
                        horizontally_stretchable = true
                    },
                    gui.create_pickup_drop_editor(inserter),
                    EMPTY_WIDGET {
                        name = "pusher_right",
                        horizontally_stretchable = true
                    },
                },
                offset_selector and LINE {
                    name = "line",
                } or nil,
                offset_selector and FLOW {
                    padding = 10,
                    name = "offset_flow",
                    EMPTY_WIDGET {
                        name = "offset_pusher_left",
                        horizontally_stretchable = true
                    },
                    gui.create_offset_editor(inserter.force, "pickup"),
                    EMPTY_WIDGET {
                        name = "offset_pusher_middle",
                        horizontally_stretchable = true
                    },
                    gui.create_offset_editor(inserter.force, "drop"),
                    EMPTY_WIDGET {
                        name = "offset_pusher_right",
                        horizontally_stretchable = true
                    },
                } or nil
            }
        }
    }
    gui_builder.build(player.gui.relative, selector_gui)
    gui.update(player, inserter)
end

---@param player LuaPlayer
---@param inserter LuaEntity
---@param event InserterArmChanged?
function gui.update(player, inserter, event)
    ---@diagnostic disable-next-line: param-type-mismatch
    local res = inserter_functions.get_arm_positions(inserter)
    local d_name = res.drop.x.."_"..res.drop.y
    local p_name = res.pickup.x.."_"..res.pickup.y
    local do_name = res.drop_offset.x.."_"..res.drop_offset.y
    local po_name = res.pickup_offset.x.."_"..res.pickup_offset.y

    if event then
        ----Clean up sprites
        if event.old_drop ~= nil then
            local button = event.old_drop.x.."_"..event.old_drop.y
            local old = gui_helper.find_element_recursive(player.gui.relative.smart_inserters, button)
            if old then
                old.sprite = ""
            end
        end

        if event.old_pickup ~= nil then
            local button = event.old_pickup.x.."_"..event.old_pickup.y       
            local old = gui_helper.find_element_recursive(player.gui.relative.smart_inserters, button)
            if old then
                old.sprite = ""
            end
        end

        local offset_flow = gui_helper.find_element_recursive(player.gui.relative.smart_inserters, "offset_flow")
        assert(offset_flow, "Offset flow not found")

        if event.old_drop_offset ~= nil then
            local button = event.old_drop_offset.x.."_"..event.old_drop_offset.y
            offset_flow.flow_drop.table_drop[button].sprite = ""
        end

        if event.old_pickup_offset ~= nil then
            local button = event.old_pickup_offset.x.."_"..event.old_pickup_offset.y
            offset_flow.flow_pickup.table_pickup[button].sprite = ""
        end
    end

    ----Positions
    local tp = gui_helper.find_element_recursive(player.gui.relative.smart_inserters, "table_position")
    if tp~=nil and (event == nil or event.do_not_popolate == nil or not event.do_not_popolate) then
        if tp[d_name] then
            tp[d_name].sprite = "drop"
        end
        if tp[p_name] then
            if tp[p_name].sprite == "drop" then
                tp[p_name].sprite = "combo"
            else
                tp[p_name].sprite = "pickup"
            end
        end
    end

    ----Offsets
    local offset_flow = gui_helper.find_element_recursive(player.gui.relative.smart_inserters, "offset_flow")
    if offset_flow~=nil and (event == nil or event.do_not_popolate == nil or not event.do_not_popolate) then
        offset_flow.flow_drop.table_drop[do_name].sprite = "drop"
        offset_flow.flow_pickup.table_pickup[po_name].sprite = "pickup"
    end
end

---@param inserter LuaEntity
---@param event InserterArmChanged?
function gui.update_all(inserter, event)
    for _, player in pairs(game.players) do
        if (inserter and player.opened == inserter) or (not inserter and player.opened and player.opened.type == "inserter") then
            ---@diagnostic disable-next-line: param-type-mismatch
            gui.update(player, player.opened, event)
        end
    end
end

local function change_pickup_drop(event)
    ---@type LuaPlayer | nil
    local player = game.get_player(event.player_index)

    assert(player~=nil, "Player "..event.player_index.." is nil")

    ---@diagnostic disable-next-line: param-type-mismatch
    assert(player.opened~=nil and inserter_functions.is_inserter(player.opened), "Opened is nil")

    ---@type LuaGuiElement
    local sprite_button = event.element

    --- @type LuaEntity
    --- @diagnostic disable-next-line: assign-type-mismatch
    local inserter = player.opened

    local inserter_pos = inserter_functions.get_arm_positions(inserter)
    local pos = string.find(sprite_button.name, "_")
    local x = string.sub(sprite_button.name, 0, pos-1)
    local y = string.sub(sprite_button.name, pos+1, #sprite_button.name)
    local button_pos = { x = tonumber(x), y = tonumber(y) }

    --- @type ChangeArmPosition
    local positions = {
        pickup = nil,
        drop = nil,
        pickup_offset = nil,
        drop_offset = nil
    }

    -- se è stata selezionata la stessa cella ignorare
    -- se è stata selezionata un'altra cella spostare su quella
    -- aggiornare tutte le interfacce / rilasciare l'evento di update
    if (not event.shift and event.button == defines.mouse_button_type.left) or (event.shift and event.button == defines.mouse_button_type.right) then
        --Drop
        positions.drop = button_pos

        if (event.control) then
            if (event.shift) then
                if (event.button == defines.mouse_button_type.right) then
                    positions.drop = inserter_pos.pickup
                    positions.pickup = inserter_pos.drop
                end
            else
                if (event.button == defines.mouse_button_type.left) then
                    positions.drop = inserter_pos.pickup
                    positions.pickup = inserter_pos.drop
                end
            end
        end
    elseif (not event.shift and event.button == defines.mouse_button_type.right) or (event.shift and event.button == defines.mouse_button_type.left) then
        --pickup
        positions.pickup = button_pos

        if (event.control) then
            if (event.shift) then
                if (event.button == defines.mouse_button_type.left) then
                    positions.drop = inserter_pos.pickup
                    positions.pickup = inserter_pos.drop
                end
            else
                if (event.button == defines.mouse_button_type.right) then
                    positions.drop = inserter_pos.pickup
                    positions.pickup = inserter_pos.drop
                end
            end
        end
    end


    inserter_functions.set_arm_positions(positions, inserter)
end

local function change_drop(event)
    ---@type LuaPlayer | nil
    local player = game.get_player(event.player_index)

    assert(player~=nil, "Player "..event.player_index.." is nil")

    ---@diagnostic disable-next-line: param-type-mismatch
    assert(player.opened~=nil and inserter_functions.is_inserter(player.opened), "Opened is nil")

    ---@type LuaGuiElement
    local sprite_button = event.element

    --- @type LuaEntity
    --- @diagnostic disable-next-line: assign-type-mismatch
    local inserter = player.opened

    local pos = string.find(sprite_button.name, "_")
    local x = string.sub(sprite_button.name, 0, pos-1)
    local y = string.sub(sprite_button.name, pos+1, #sprite_button.name)
    local button_pos = { x = tonumber(x), y = tonumber(y) }

    --- @type ChangeArmPosition
    local positions = {
        pickup = nil,
        drop = nil,
        pickup_offset = nil,
        drop_offset = nil
    }

    positions.drop = button_pos
    inserter_functions.set_arm_positions(positions, inserter)
end

local function change_pickup(event)
    ---@type LuaPlayer | nil
    local player = game.get_player(event.player_index)

    assert(player~=nil, "Player "..event.player_index.." is nil")

    ---@diagnostic disable-next-line: param-type-mismatch
    assert(player.opened~=nil and inserter_functions.is_inserter(player.opened), "Opened is nil")

    ---@type LuaGuiElement
    local sprite_button = event.element

    --- @type LuaEntity
    --- @diagnostic disable-next-line: assign-type-mismatch
    local inserter = player.opened

    local pos = string.find(sprite_button.name, "_")
    local x = string.sub(sprite_button.name, 0, pos-1)
    local y = string.sub(sprite_button.name, pos+1, #sprite_button.name)
    local button_pos = { x = tonumber(x), y = tonumber(y) }

    --- @type ChangeArmPosition
    local positions = {
        pickup = nil,
        drop = nil,
        pickup_offset = nil,
        drop_offset = nil
    }

    positions.pickup = button_pos
    inserter_functions.set_arm_positions(positions, inserter)
end

local function change_pickup_offset(event)
    ---@type LuaPlayer | nil
    local player = game.get_player(event.player_index)

    assert(player~=nil, "Player "..event.player_index.." is nil")

    ---@diagnostic disable-next-line: param-type-mismatch
    assert(player.opened~=nil and inserter_functions.is_inserter(player.opened), "Opened is nil")

    ---@type LuaGuiElement
    local sprite_button = event.element

    --- @type LuaEntity
    --- @diagnostic disable-next-line: assign-type-mismatch
    local inserter = player.opened

    local inserter_pos = inserter_functions.get_arm_positions(inserter)
    local pos = string.find(sprite_button.name, "_")
    local x = string.sub(sprite_button.name, 0, pos-1)
    local y = string.sub(sprite_button.name, pos+1, #sprite_button.name)
    local button_pos = { x = tonumber(x), y = tonumber(y) }

    --- @type ChangeArmPosition
    local positions = {
        pickup_offset = button_pos,
    }

    inserter_functions.set_arm_positions(positions, inserter)
end

local function change_drop_offset(event)
    ---@type LuaPlayer | nil
    local player = game.get_player(event.player_index)

    assert(player~=nil, "Player "..event.player_index.." is nil")

    ---@diagnostic disable-next-line: param-type-mismatch
    assert(player.opened~=nil and inserter_functions.is_inserter(player.opened), "Opened is nil")

    ---@type LuaGuiElement
    local sprite_button = event.element

    --- @type LuaEntity
    --- @diagnostic disable-next-line: assign-type-mismatch
    local inserter = player.opened

    local inserter_pos = inserter_functions.get_arm_positions(inserter)
    local pos = string.find(sprite_button.name, "_")
    local x = string.sub(sprite_button.name, 0, pos-1)
    local y = string.sub(sprite_button.name, pos+1, #sprite_button.name)
    local button_pos = { x = tonumber(x), y = tonumber(y) }

    --- @type ChangeArmPosition
    local positions = {
        drop_offset = button_pos,
    }

    inserter_functions.set_arm_positions(positions, inserter)
end

gui_builder.register_handler("change_pickup_drop", change_pickup_drop)
gui_builder.register_handler("change_pickup", change_drop)
gui_builder.register_handler("change_drop", change_pickup)
gui_builder.register_handler("change_pickup_offset", change_pickup_offset)
gui_builder.register_handler("change_drop_offset", change_drop_offset)

return gui