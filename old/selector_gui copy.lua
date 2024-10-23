local directional_slim_inserter = settings.startup["si-directional-slim-inserter"].value
local offset_selector = settings.startup["si-offset-selector"].value

local math2d = require("__yafla__/scripts/extended_math2d")
local gui_builder = require("__yafla__/scripts/experimental/gui_builder")
local gui_helper = require("__yafla__/scripts/experimental/gui_helper")
local events = require("scripts.events")

local tech = require("scripts.technology_functions")
local inserter_functions = require("scripts.inserter_functions")
local world_selector = require("scripts.world_selector")
local util = require("scripts.si_util")

local gui = {}

---@param vertical boolean
function gui.generate_slim_inserter_grid(vertical)
    local inserters_max_range = inserter_functions.get_max_inserters_range()
    local table_position = {}
    for y = -inserters_max_range, inserters_max_range, 1 do
        for x = -inserters_max_range, inserters_max_range, 1 do
            if x == 0 and y == 0 then
                table.insert(table_position,
                    SPRITE {
                        name = "sprite_inserter",
                        sprite = "item/inserter",
                        stretch_image_to_widget_size = true,
                        size = { 32, 32 },
                    }
                )
            else
                if (x ~= 0 and not vertical) or (y ~= 0 and vertical) then
                    if not vertical and x > 0 then
                        table.insert(table_position,
                            SPRITE_BUTTON {
                                name = tostring(x-1) .. "_" .. tostring(y),
                                style = "slot_sized_button",
                                on_click = "change_pickup_drop",
                                size = { 32, 32 }
                            }
                        )
                    elseif vertical and y > 0 then
                        table.insert(table_position,
                            SPRITE_BUTTON {
                                name = tostring(x) .. "_" .. tostring(y-1),
                                style = "slot_sized_button",
                                on_click = "change_pickup_drop",
                                size = { 32, 32 }
                            }
                        )
                    else
                        table.insert(table_position,
                            SPRITE_BUTTON {
                                name = tostring(x) .. "_" .. tostring(y),
                                style = "slot_sized_button",
                                on_click = "change_pickup_drop",
                                size = { 32, 32 }
                            }
                        )
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


---@param width number
---@param height number
---@return table
function gui.generate_x_y_inserter_grid(width, height)
    local inserters_max_range = inserter_functions.get_max_inserters_range()

    local lower_width = width%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5

    local table_position = {}
    for y = -inserters_max_range-lower_height, inserters_max_range+higher_height-1, 1 do
        for x = -inserters_max_range-lower_width, inserters_max_range+higher_width-1, 1 do
            if (-lower_width <= x and x < higher_width) and (-lower_height <= y and y < higher_height) then
                if x == higher_width-1 and y == higher_height-1 then
                    table.insert(table_position,
                        FLOW {
                            top_margin = (height-1)*-33,
                            left_margin = width/2*-33*math.min(1, width-1),
                            SPRITE {
                                name = "sprite_inserter_"..tostring(x) .. "_" .. tostring(y),
                                sprite = "item.inserter",
                                size = 32+33*(math.min(width, height)-1),
                                resize_to_sprite = false
                            }
                        }
                    )
                else
                    table.insert(table_position,
                        EMPTY_WIDGET {}
                    )
                end

            else
                table.insert(table_position,
                    SPRITE_BUTTON {
                        name = tostring(x) .. "_" .. tostring(y),
                        style = "slot_sized_button",
                        on_click = "change_pickup_drop",
                        size = { 32, 32 }
                    }
                )
            end
        end
    end
    return table_position
end

-- Also known as 3x3 table approach
---@param width number
---@param height number
---@return table
function gui.grid_generate_x_y_inserter_grid(width, height)
    local inserters_max_range = inserter_functions.get_max_inserters_range()

    local lower_width = width%2==0 and width/2 or width/2-0.5
    local higher_width = width%2==0 and width/2 or width/2+0.5

    local lower_height = height%2==0 and height/2 or height/2-0.5
    local higher_height = height%2==0 and height/2 or height/2+0.5

    local tl = {}
    local tc = {}
    local tr = {}

    local cl = {}
    local cc = {}
    local cr = {}

    local bl = {}
    local bc = {}
    local br = {}


    for y = -inserters_max_range-lower_height, -lower_height-1, 1 do
        for x = -inserters_max_range-lower_width, -lower_width-1, 1 do
            table.insert(tl,
                SPRITE_BUTTON {
                    name = tostring(x) .. "_" .. tostring(y),
                    style = "slot_sized_button",
                    on_click = "change_pickup_drop",
                    size = { 32, 32 }
                }
            )
        end
    end
    for y = -inserters_max_range-lower_height, -lower_height-1, 1 do
        for x = -lower_width, higher_width-1, 1 do
            table.insert(tc,
                SPRITE_BUTTON {
                    name = tostring(x) .. "_" .. tostring(y),
                    style = "slot_sized_button",
                    on_click = "change_pickup_drop",
                    size = { 32, 32 }
                }
            )
        end
    end
    for y = -inserters_max_range-lower_height, -lower_height-1, 1 do
        for x = higher_width, inserters_max_range+higher_width-1, 1 do
            table.insert(tr,
                SPRITE_BUTTON {
                    name = tostring(x) .. "_" .. tostring(y),
                    style = "slot_sized_button",
                    on_click = "change_pickup_drop",
                    size = { 32, 32 }
                }
            )
        end
    end


    for y = -lower_height, higher_height-1, 1 do
        for x = -inserters_max_range-lower_width, -lower_width-1, 1 do
            table.insert(cl,
                SPRITE_BUTTON {
                    name = tostring(x) .. "_" .. tostring(y),
                    style = "slot_sized_button",
                    on_click = "change_pickup_drop",
                    size = { 32, 32 }
                }
            )
        end
    end
    for y = -lower_height, higher_height-1, 1 do
        for x = -lower_width, higher_width-1, 1 do
            if x ~= 0 or y ~= 0 then
                table.insert(cc,
                    EMPTY_WIDGET {
                        name = "sprite_inserter_"..tostring(x) .. "_" .. tostring(y),
                        size = { 32, 32 },
                    }
                )
            else
                table.insert(cc,
                    FLOW {
                        top_margin = -(32+33*(math.min(width, height)-1))/2,
                        left_margin = -(32+33*(math.min(width, height)-1))/2,
                        SPRITE {
                            sprite = "item.inserter",
                            size = 32+33*(math.min(width, height)-1),
                            resize_to_sprite = false
                        }
                    }
                )
            end
        end
    end
    for y = -lower_height, higher_height-1, 1 do
        for x = higher_width, inserters_max_range+higher_width-1, 1 do
            table.insert(cr,
                SPRITE_BUTTON {
                    name = tostring(x) .. "_" .. tostring(y),
                    style = "slot_sized_button",
                    on_click = "change_pickup_drop",
                    size = { 32, 32 }
                }
            )
        end
    end


    for y = higher_height, inserters_max_range+higher_height-1, 1 do
        for x = -inserters_max_range-lower_width, -lower_width-1, 1 do
            table.insert(bl,
                SPRITE_BUTTON {
                    name = tostring(x) .. "_" .. tostring(y),
                    style = "slot_sized_button",
                    on_click = "change_pickup_drop",
                    size = { 32, 32 }
                }
            )
        end
    end
    for y = higher_height, inserters_max_range+higher_height-1, 1 do
        for x = -lower_width, higher_width-1, 1 do
            table.insert(bc,
                SPRITE_BUTTON {
                    name = tostring(x) .. "_" .. tostring(y),
                    style = "slot_sized_button",
                    on_click = "change_pickup_drop",
                    size = { 32, 32 }
                }
            )
        end
    end
    for y = higher_height, inserters_max_range+higher_height-1, 1 do
        for x = higher_width, inserters_max_range+higher_width-1, 1 do
            table.insert(br,
                SPRITE_BUTTON {
                    name = tostring(x) .. "_" .. tostring(y),
                    style = "slot_sized_button",
                    on_click = "change_pickup_drop",
                    size = { 32, 32 }
                }
            )
        end
    end

    return {
        TABLE {
            column_count = inserters_max_range,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            tl
        },
        TABLE {
            column_count = width,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            tc
        },
        TABLE {
            column_count = inserters_max_range,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            tr
        },
        TABLE {
            column_count = inserters_max_range,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            cl
        },
        TABLE {
            column_count = width,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            cc
        },
        TABLE {
            column_count = inserters_max_range,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            cr
        },
        TABLE {
            column_count = inserters_max_range,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            bl
        },
        TABLE {
            column_count = width,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            bc
        },
        TABLE {
            column_count = inserters_max_range,
            horizontal_spacing = 1,
            vertical_spacing = 1,
            br
        }
    }
end

---@param inserter LuaEntity
---@return table
function gui.create_pickup_drop_editor(inserter)
    local inserters_max_range = inserter_functions.get_max_inserters_range()

    grid = inserter_functions.is_slim(inserter) and gui.generate_slim_inserter_grid(inserter.tile_width > 0) or gui.generate_x_y_inserter_grid(math.ceil(inserter.tile_width), math.ceil(inserter.tile_height))

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
            column_count = inserters_max_range*2+width,
            --3 if I want to use the 3x3 table approach, it could be useful for slim inserter so need to keep an eye on it
            --column_count = 3,
            grid
        }
    }
end

---@param offset_name string
---@return table
function gui.create_offset_editor(offset_name)
    local inserters_max_range = inserter_functions.get_max_inserters_range()
    local table_editor = {}
    for y = 1, 3, 1 do
        for x = 1, 3, 1 do
            local button_name = "button_" .. offset_name .. "_offset_" .. tostring(x + inserters_max_range + 1) .. "_" .. tostring(y + inserters_max_range + 1)
            table.insert(table_editor,
                SPRITE_BUTTON {
                    name = button_name,
                    style = "slot_sized_button",
                    size = { 32, 32 }
                }
            )
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
                LINE {
                    name = "line",
                },
                FLOW {
                    padding = 10,
                    name = "flow_offset",
                    EMPTY_WIDGET {
                        name = "offset_pusher_left",
                        horizontally_stretchable = true
                    },
                    gui.create_offset_editor("pickup"),
                    EMPTY_WIDGET {
                        name = "offset_pusher_middle",
                        horizontally_stretchable = true
                    },
                    gui.create_offset_editor("drop"),
                    EMPTY_WIDGET {
                        name = "offset_pusher_right",
                        horizontally_stretchable = true
                    },
                }
            }
        }
    }
    gui_builder.build(player.gui.relative, selector_gui)
end

---@param event InserterArmChanged | table
function gui.update(event)
    local player = game.get_player(event.player_index)
    assert(player~=nil, "player is nil")
    local inserter = player.opened

    local res = inserter_functions.get_arm_positions(inserter)
    local d_name = res.drop.x.."_"..res.drop.y
    local p_name = res.pickup.x.."_"..res.pickup.y

    local table = gui_helper.find_element_recursive(player.gui.relative.smart_inserters, "table_position")
    assert(table~=nil, "table_position is nil")

    table[d_name].sprite = "drop"
    if table[p_name].sprite == "drop" then
        table[p_name].sprite = "combo"
    else
        table[p_name].sprite = "pickup"
    end
end


local function change_pickup_drop(event)
    ---@type LuaGuiElement
    local sprite_button = event.element

    ---@type LuaPlayer | nil
    local player = game.get_player(event.player_index)

    if player == nil then
        error("Player "..event.player_index.." is nil")
        return
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    if not (player.opened and inserter_functions.is_inserter(player.opened)) then
        -- No inserter selected
        return
    end

    --- @type LuaEntity
    --- @diagnostic disable-next-line: assign-type-mismatch
    local inserter = player.opened

    local res = inserter_functions.get_arm_positions(inserter)
    local pos = string.find(sprite_button.name, "_")
    local x = string.sub(sprite_button.name, 0, pos-1)
    local y = string.sub(sprite_button.name, pos+1, #sprite_button.name)

    print("selected"..x..", "..y)
    print("drop    "..res.drop.x..", "..res.drop.y)
    print("pickup  "..res.pickup.x..", "..res.pickup.y)
    print("base    "..res.base_offset.x..", "..res.base_offset.y)

    script.raise_event(events.on_inserter_arm_changed, {
        player_index = player.index,
        entity = inserter,
        old_pickup = res.pickup,
        old_drop = res.drop
    })
end

gui_builder.register_handler("change_pickup_drop", change_pickup_drop)

------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------Rework Separator------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------ 

--Optimized (Not cleaned up yet)
function gui.old_update(player, inserter)
    local gui_instance = player.gui.relative.smart_inserters.frame_content.flow_content
    local pickup_drop_housing = gui_instance.pickup_drop_flow.pickup_drop_housing
    local table_range = (pickup_drop_housing.table_position.column_count - 1) / 2
    local inserter_range = inserter_functions.get_max_range(inserter, player.force)
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    local inserter_size = inserter_functions.get_inserter_size(inserter)
    local slim = inserter_functions.is_slim(inserter)
    local vertical = (inserter.direction==0 or inserter.direction==4)
    local orizontal = (inserter.direction==2 or inserter.direction==6)
    local enabled_cells = util.enabled_cell_matrix(player.force, orizontal, vertical, slim)

    player.gui.relative.smart_inserters.visible = util.check_blacklist(inserter)
    pickup_drop_housing.inserter_pickup_switch_position.allow_none_state = false
    pickup_drop_housing.inserter_pickup_switch_position.visible = false
    pickup_drop_housing.inserter_drop_switch_position.allow_none_state = false
    pickup_drop_housing.inserter_drop_switch_position.visible = false

    if slim then
        if vertical and arm_positions.drop.y >= 0 then     -- parte bassa / lower half
            arm_positions.drop.y = arm_positions.drop.y + 1
        elseif orizontal and arm_positions.drop.x >= 0 then -- parte destra / right
            arm_positions.drop.x = arm_positions.drop.x + 1
        end
        if vertical and arm_positions.pickup.y >= 0 then     -- parte bassa / lower half
            arm_positions.pickup.y = arm_positions.pickup.y + 1
        elseif orizontal and arm_positions.pickup.x >= 0 then -- parte destra / right
            arm_positions.pickup.x = arm_positions.pickup.x + 1
        end
    elseif inserter_size >= 2 then
        if inserter_size == 3 then
            pickup_drop_housing.inserter_pickup_switch_position.allow_none_state = true
            pickup_drop_housing.inserter_drop_switch_position.allow_none_state = true
        end

        --pickup
        if arm_positions.pickup.x < 0 then
            arm_positions.pickup.x = arm_positions.pickup.x + (inserter_size - 1)
        end
        if arm_positions.pickup.y < 0 then
            arm_positions.pickup.y = arm_positions.pickup.y + (inserter_size - 1)
        end
        if arm_positions.pickup.y == 0 then
            pickup_drop_housing.inserter_pickup_switch_position.visible = true
            pickup_drop_housing.inserter_pickup_switch_position.right_label_caption = { "gui-smart-inserters.buttom-pickup" }
            pickup_drop_housing.inserter_pickup_switch_position.left_label_caption = { "gui-smart-inserters.top-pickup" }
            pickup_drop_housing.inserter_pickup_switch_position.switch_state = "left"
            if arm_positions.base.y == arm_positions.pure_pickup.y then
                pickup_drop_housing.inserter_pickup_switch_position.switch_state = "right"
            end
        elseif arm_positions.pickup.x == 0 then
            pickup_drop_housing.inserter_pickup_switch_position.visible = true
            pickup_drop_housing.inserter_pickup_switch_position.right_label_caption = { "gui-smart-inserters.right-pickup" }
            pickup_drop_housing.inserter_pickup_switch_position.left_label_caption = { "gui-smart-inserters.left-pickup" }
            pickup_drop_housing.inserter_pickup_switch_position.switch_state = "left"
            if arm_positions.base.x == arm_positions.pure_pickup.x then
                pickup_drop_housing.inserter_pickup_switch_position.switch_state = "right"
            end
        end

        --drop
        if arm_positions.drop.x < 0 then
            arm_positions.drop.x = arm_positions.drop.x + (inserter_size - 1)
        end
        if arm_positions.drop.y < 0 then
            arm_positions.drop.y = arm_positions.drop.y + (inserter_size - 1)
        end
        if arm_positions.drop.y == 0 then
            pickup_drop_housing.inserter_drop_switch_position.visible = true
            pickup_drop_housing.inserter_drop_switch_position.right_label_caption = { "gui-smart-inserters.buttom-drop" }
            pickup_drop_housing.inserter_drop_switch_position.left_label_caption = { "gui-smart-inserters.top-drop" }
            pickup_drop_housing.inserter_drop_switch_position.switch_state = "left"
            if arm_positions.base.y == arm_positions.pure_drop.y then
                pickup_drop_housing.inserter_drop_switch_position.switch_state = "right"
            end
        elseif arm_positions.drop.x == 0 then
            pickup_drop_housing.inserter_drop_switch_position.visible = true
            pickup_drop_housing.inserter_drop_switch_position.right_label_caption = { "gui-smart-inserters.right-drop" }
            pickup_drop_housing.inserter_drop_switch_position.left_label_caption = { "gui-smart-inserters.left-drop" }
            pickup_drop_housing.inserter_drop_switch_position.switch_state = "left"
            if arm_positions.base.x == arm_positions.pure_drop.x then
                pickup_drop_housing.inserter_drop_switch_position.switch_state = "right"
            end
        end
    end

    local idx = 0
    local button = pickup_drop_housing.table_position.children[1]
    for y = -table_range, table_range, 1 do
        for x = -table_range, table_range, 1 do
            idx = idx + 1
            button = pickup_drop_housing.table_position.children[idx]
            if button.type == "sprite-button" then
                if math.max(math.abs(x), math.abs(y)) > inserter_range then
                    button.enabled = false
                else
                    button.enabled = enabled_cells[y][x]
                end

                if math2d.position.equal(arm_positions.drop, { x, y }) then
                    button.sprite = "drop"
                    if directional_slim_inserter and slim then
                        button.sprite = "selected-drop"
                    end
                elseif math2d.position.equal(arm_positions.pickup, { x, y }) then
                    button.sprite = "pickup"
                    if directional_slim_inserter and slim then
                        button.sprite = "selected-pickup"
                    end
                elseif x ~= 0 or y ~= 0 then
                    if directional_slim_inserter and slim and button.enabled == true then
                        button.sprite = nil
                        if inserter.direction == 0 and y > 0 then
                            button.sprite = "background-drop"
                        elseif inserter.direction == 0 and y < 0 then
                            button.sprite = "background-pickup"
                        elseif inserter.direction == 4 and y < 0 then
                            button.sprite = "background-drop"
                        elseif inserter.direction == 4 and y > 0 then
                            button.sprite = "background-pickup"
                        elseif inserter.direction == 2 and x < 0 then
                            button.sprite = "background-drop"
                        elseif inserter.direction == 2 and x > 0 then
                            button.sprite = "background-pickup"
                        elseif inserter.direction == 6 and x > 0 then
                            button.sprite = "background-drop"
                        elseif inserter.direction == 6 and x < 0 then
                            button.sprite = "background-pickup"
                        end
                    else
                        button.sprite = nil
                    end
                end
            end
        end
    end

    local icon = "item/inserter"
    if slim then
        icon = "circle"
    elseif inserter.prototype.items_to_place_this then
        icon = "item/" .. inserter.prototype.items_to_place_this[1].name
    end
    gui_instance.pickup_drop_flow.pickup_drop_housing.table_position.sprite_inserter.sprite = icon

    if offset_selector == false then
        return
    end

    local offset_tech_unlocked = tech.check_offset_tech(player.force)

    local idx = 0
    for y = -1, 1, 1 do
        for x = -1, 1, 1 do
            idx = idx + 1

            gui_instance.flow_offset.flow_pickup.table_pickup.children[idx].enabled = offset_tech_unlocked
            if math2d.position.equal(arm_positions.pickup_offset, { x, y }) then
                gui_instance.flow_offset.flow_pickup.table_pickup.children[idx].sprite = "pickup"
            else
                gui_instance.flow_offset.flow_pickup.table_pickup.children[idx].sprite = nil
            end
        end
    end

    local idx = 0
    for y = -1, 1, 1 do
        for x = -1, 1, 1 do
            idx = idx + 1

            gui_instance.flow_offset.flow_drop.table_drop.children[idx].enabled = offset_tech_unlocked
            if math2d.position.equal(arm_positions.drop_offset, { x, y }) then
                gui_instance.flow_offset.flow_drop.table_drop.children[idx].sprite = "drop"
            else
                gui_instance.flow_offset.flow_drop.table_drop.children[idx].sprite = nil
            end
        end
    end
end

function gui.update_all(inserter)
    for _, player in pairs(game.players) do
        if (inserter and player.opened == inserter) or (not inserter and player.opened and player.opened.type == "inserter") then
            gui.update(player, player.opened)
        end
    end
end

function gui.get_button_pos(button)
    local idx = button.get_index_in_parent() - 1
    local len = button.parent.column_count
    local center = (len - 1) * -0.5 -- /2*-1
    return math2d.position.add({ idx % len, math.floor(idx / len) }, { center, center })
end

function gui.on_button_position(player, event)
    local inserter = player.opened
    if not inserter_functions.is_inserter(inserter) then return end
    local new_pos = gui.get_button_pos(event.element)
    local inserter_size = inserter_functions.get_inserter_size(inserter)
    local inserter_positions = inserter_functions.get_arm_positions(inserter)
    local slim = (inserter_size == 0)
    local vertical = (inserter.direction==0 or inserter.direction==4)
    local orizontal = (inserter.direction==2 or inserter.direction==6)
    local new_positions

    if event.button == defines.mouse_button_type.left and not event.control and not event.shift then
        new_positions = { drop = new_pos }

        if event.element.sprite == "drop" then
            return
        end

        if event.element.sprite == "pickup" then
            new_positions.pickup = inserter_positions.drop
            if vertical and slim and new_positions.pickup.y >= 0 then
                new_positions.pickup.y = new_positions.pickup.y + 1
            elseif orizontal and slim and new_positions.pickup.x >= 0 then
                new_positions.pickup.x = new_positions.pickup.x + 1
            end
            if (new_positions.pickup.y <= -1) and (inserter_size >= 2) then
                new_positions.pickup.y = new_positions.pickup.y + 1
            end
            if (new_positions.pickup.x <= -1) and (inserter_size >= 2) then
                new_positions.pickup.x = new_positions.pickup.x + 1
            end
        end

        new_positions.drop_offset = { x = 0, y = 0 }
        --Set the drop offset to the farthest side
        --[
        if new_pos.x < 0 and not (orizontal and slim) then
            new_positions.drop_offset.x = -1
        elseif new_pos.x > 0 and not (orizontal and slim) then
            new_positions.drop_offset.x = 1
        end

        if new_pos.y < 0 and not (vertical and slim) then
            new_positions.drop_offset.y = -1
        elseif new_pos.y > 0 and not (vertical and slim) then
            new_positions.drop_offset.y = 1
        end
        --]

        if gui.validate_button_placement(inserter, new_positions) then
            inserter_functions.set_arm_positions(inserter, new_positions)
        else
            return
        end
    elseif event.button == defines.mouse_button_type.right or (event.button == defines.mouse_button_type.left and (event.control or event.shift)) then
        new_positions = { pickup = new_pos }

        if event.element.sprite == "pickup" then
            return
        end

        if event.element.sprite == "drop" then
            new_positions.drop = inserter_positions.pickup

            if new_positions.drop.y >= 0 and vertical and slim then
                new_positions.drop.y = new_positions.drop.y + 1
            elseif new_positions.drop.x >= 0 and orizontal and slim then
                new_positions.drop.x = new_positions.drop.x + 1
            end
            if (new_positions.drop.y <= -1) and (inserter_size >= 2) then
                new_positions.drop.y = new_positions.drop.y + 1
            end
            if (new_positions.drop.x <= -1) and (inserter_size >= 2) then
                new_positions.drop.x = new_positions.drop.x + 1
            end

            new_positions.drop_offset = { x = 0, y = 0 }
            if new_positions.drop.x < 0 and not (orizontal and slim) then
                new_positions.drop_offset.x = -1
            elseif new_positions.drop.x > 0 and not (orizontal and slim) then
                new_positions.drop_offset.x = 1
            end

            if new_positions.drop.y < 0 and not (vertical and slim) then
                new_positions.drop_offset.y = -1
            elseif new_positions.drop.y > 0 and not (vertical and slim) then
                new_positions.drop_offset.y = 1
            end
        end

        new_positions.pickup_offset = { x = 0, y = 0 }
        --[[
            if new_pos.x < 0 and not (slimo or slime) then
                new_positions.pickup_offset.x = -1
            elseif new_pos.x > 0 and not (slimo or slime) then
                new_positions.pickup_offset.x = 1
            end

            if new_pos.y < 0 and not (slimn or slims) then
                new_positions.pickup_offset.y = -1
            elseif new_pos.y > 0 and not (slimn or slims) then
                new_positions.pickup_offset.y = 1
            end
        --]]

        if gui.validate_button_placement(inserter, new_positions) then
            inserter_functions.set_arm_positions(inserter, new_positions)
        else
            return
        end
    end

    gui.update_all(inserter)
    if global.SI_Storage[event.player_index].is_selected and math2d.position.equal(player.opened.position, global.SI_Storage[event.player_index].selected_inserter.position) then
        local changes = {}
        if new_positions.drop then
            changes["drop"] = {
                old = {
                    x = inserter_positions.drop.x,
                    y = inserter_positions.drop.y,
                },
                new = {
                    x = new_positions.drop.x,
                    y = new_positions.drop.y,
                }
            }
        end
        if new_positions.pickup then
            changes["pickup"] = {
                old = {
                    x = inserter_positions.pickup.x,
                    y = inserter_positions.pickup.y,
                },
                new = {
                    x = new_positions.pickup.x,
                    y = new_positions.pickup.y,
                }
            }
        end

        world_selector.update_positions(event.player_index, player.opened, changes)
    end
end

function gui.on_button_drop_offset(player, event)
    inserter_functions.set_arm_positions(player.opened, { drop_offset = gui.get_button_pos(event.element) })

    gui.update(player, player.opened)
end

function gui.on_button_pickup_offset(player, event)
    inserter_functions.set_arm_positions(player.opened, { pickup_offset = gui.get_button_pos(event.element) })

    gui.update(player, player.opened)
end

function gui.on_switch_drop_position(player, event)
    local inserter = player.opened
    local position = inserter_functions.get_arm_positions(inserter)
    local drop_position = position.drop

    local state = 0 -- "none"
    if event.element.switch_state == "right" then
        state = 1
    elseif event.element.switch_state == "left" then
        state = -1
    end

    local drop_adjust = { x = 0, y = 0 }

    if (drop_position.y >= 1) or (drop_position.y <= -2) then
        if position.base.x ~= position.pure_drop.x and event.element.switch_state == "left" then
            return
        elseif position.base.x == position.pure_drop.x and event.element.switch_state == "right" then
            return
        end
        if state == 1 then
            drop_adjust.x = 1
        else
            drop_adjust.x = -1
        end
    elseif (drop_position.x >= 1) or (drop_position.x <= -1) then
        if position.base.y ~= position.pure_drop.y and event.element.switch_state == "left" then
            return
        elseif position.base.y == position.pure_drop.y and event.element.switch_state == "right" then
            return
        end
        if state == 1 then
            drop_adjust.y = 1
        else
            drop_adjust.y = -1
        end
    end

    inserter_functions.set_arm_positions(inserter, { drop_adjust = drop_adjust })
    gui.update(player, inserter)
end

function gui.on_switch_pickup_position(player, event)
    local inserter = player.opened
    local position = inserter_functions.get_arm_positions(inserter)
    local pickup_position = position.pickup

    local state = 0 -- "none"
    if event.element.switch_state == "right" then
        state = 1
    elseif event.element.switch_state == "left" then
        state = -1
    end

    local pickup_adjust = { x = 0, y = 0 }

    if (pickup_position.y >= 1) or (pickup_position.y <= -2) then
        if position.base.x ~= position.pure_pickup.x and event.element.switch_state == "left" then
            return
        elseif position.base.x == position.pure_pickup.x and event.element.switch_state == "right" then
            return
        end
        if state == 1 then
            pickup_adjust.x = 1
        else
            pickup_adjust.x = -1
        end
    elseif (pickup_position.x >= 1) or (pickup_position.x <= -1) then
        if position.base.y ~= position.pure_pickup.y and event.element.switch_state == "left" then
            return
        elseif position.base.y == position.pure_pickup.y and event.element.switch_state == "right" then
            return
        end
        if state == 1 then
            pickup_adjust.y = 1
        else
            pickup_adjust.y = -1
        end
    end

    inserter_functions.set_arm_positions(inserter, { pickup_adjust = pickup_adjust })
    gui.update(player, inserter)
end

function gui.validate_button_placement(inserter, positions)
    if not directional_slim_inserter then
        return true
    end
    local slim = inserter_functions.is_slim(inserter)

    if positions.pickup ~= nil and slim then
        if inserter.direction == 4 and positions.pickup.y < 0 then
            return false
        end
        if inserter.direction == 0 and positions.pickup.y > 0 then
            return false
        end
        if inserter.direction == 6 and positions.pickup.x > 0 then
            return false
        end
        if inserter.direction == 2 and positions.pickup.x < 0 then
            return false
        end
    end

    if positions.drop ~= nil and slim then
        if inserter.direction == 4 and positions.drop.y > 0 then
            return false
        end
        if inserter.direction == 0 and positions.drop.y < 0 then
            return false
        end
        if inserter.direction == 6 and positions.drop.x < 0 then
            return false
        end
        if inserter.direction == 2 and positions.drop.x > 0 then
            return false
        end
    end

    return true
end

return gui