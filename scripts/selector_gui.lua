local directional_slim_inserter = settings.startup["si-directional-slim-inserter"].value
local offset_selector = settings.startup["si-offset-selector"].value

local math2d = require("__yafla__/scripts/extended_math2d")
--local gui_builder = require("__yafla__/scripts/experimental/gui_builder")
--local gui_components = require("__yafla__/scripts/experimental/gui_builder")

local tech = require("scripts.technology_functions")
local inserter_functions = require("scripts.inserter_functions")
local world_selector = require("scripts.world_selector")
local util = require("scripts.si_util")

local gui = {}

function gui.create_pick_drop_editor(flow_content)
    local inserters_max_range = inserter_functions.get_max_inserters_range()
    -- Pickup/Drop label
    flow_content.add({
        type = "label",
        name = "label_position",
        caption = { "gui-smart-inserters.position" },
        style = "heading_2_label"
    })

    -- Pickup/Drop Grid
    local table_position = flow_content.add({
        type = "table",
        name = "table_position",
        column_count = 1 + inserters_max_range * 2
    })
    table_position.style.horizontal_spacing = 1
    table_position.style.vertical_spacing = 1

    for y = -inserters_max_range, inserters_max_range, 1 do
        for x = -inserters_max_range, inserters_max_range, 1 do
            local pos_suffix = "_" .. tostring(x + inserters_max_range + 1) .. "_" .. tostring(y + inserters_max_range + 1)

            if x == 0 and y == 0 then
                local sprite = table_position.add({ type = "sprite", name = "sprite_inserter", sprite = "item/inserter" })
                sprite.style.stretch_image_to_widget_size = true
                sprite.style.size = { 32, 32 }
            else
                local button = table_position.add({
                    type = "sprite-button",
                    name = "button_position" .. pos_suffix,
                    style = "slot_sized_button"
                })
                button.style.size = { 32, 32 }
            end
        end
    end
end

function gui.create_bigger_inserter_editor(flow_content, inserter_type)
    local bigger_switch = flow_content.add({
        type = "switch",
        name = "inserter_" .. inserter_type .. "_switch_position",
        left_label_caption = "Left " .. inserter_type .. " position",
        right_label_caption = "Right " .. inserter_type .. " position",
    })
    bigger_switch.switch_state = "right"
end

function gui.create_offset_editor(flow_offset, offset_name)
    local inserters_max_range = inserter_functions.get_max_inserters_range()
    local flow_editor = flow_offset.add({
        type = "flow",
        name = "flow_" .. offset_name,
        direction = "vertical"
    })

    flow_editor.add({
        type = "label",
        name = "label_" .. offset_name .. "_offset",
        caption = { "gui-smart-inserters." .. offset_name .. "-offset" },
        style = "heading_2_label"
    })

    local table_editor = flow_editor.add({
        type = "table",
        name = "table_" .. offset_name,
        column_count = 3
    })
    table_editor.style.horizontal_spacing = 1
    table_editor.style.vertical_spacing = 1

    for y = 1, 3, 1 do
        for x = 1, 3, 1 do
            local button_name = "button_" .. offset_name .. "_offset_" ..
                tostring(x + inserters_max_range + 1) .. "_" .. tostring(y + inserters_max_range + 1)
            local button = table_editor.add({
                type = "sprite-button",
                name = button_name,
                style = "slot_sized_button"
            })
            button.style.size = { 32, 32 }
        end
    end
end


--This could probably be revritten with YAFLA gui framework
function gui.create(player)
    local frame_main_anchor = {
        gui = defines.relative_gui_type.inserter_gui,
        position = defines.relative_gui_position.right
    }

    -- Initialization
    local frame_main = player.gui.relative.add({
        type = "frame",
        name = "smart_inserters",
        caption = { "gui-smart-inserters.configuration" },
        anchor = frame_main_anchor
    })
    local frame_content = frame_main.add({
        type = "frame",
        name = "frame_content",
        style = "inside_shallow_frame_with_padding"
    })

    -- Main vertical row
    local flow_content = frame_content.add({
        type = "flow",
        name = "flow_content",
        direction = "vertical"
    })

    -- Pickup Drop
    local pick_drop_flow = flow_content.add({
        type = "flow",
        name = "pick_drop_flow",
        direction = "horizontal"
    })

    local pusher_left = pick_drop_flow.add({
        type = "empty-widget",
        name = "pusher_left"
    })
    pusher_left.style.horizontally_stretchable = true

    local pick_drop_housing = pick_drop_flow.add({
        type = "flow",
        name = "pick_drop_housing",
        direction = "vertical"
    })

    gui.create_pick_drop_editor(pick_drop_housing)
    gui.create_bigger_inserter_editor(pick_drop_housing, "pick")
    gui.create_bigger_inserter_editor(pick_drop_housing, "drop")

    local pusher_right = pick_drop_flow.add({
        type = "empty-widget",
        name = "pusher_right"
    })
    pusher_right.style.horizontally_stretchable = true

    if offset_selector ~= false then
        -- Separator
        flow_content.add({
            type = "line",
            name = "line",
            style = "control_behavior_window_line"
        })

        -- Flow element
        local flow_offset = flow_content.add({
            type = "flow",
            name = "flow_offset",
            direction = "horizontal"
        })

        local offset_pusher_left = flow_offset.add({
            type = "empty-widget",
            name = "offset_pusher_left"
        })
        offset_pusher_left.style.horizontally_stretchable = true

        gui.create_offset_editor(flow_offset, "pick")

        local offset_pusher_middle = flow_offset.add({
            type = "empty-widget",
            name = "offset_pusher_middle"
        })
        offset_pusher_middle.style.horizontally_stretchable = true

        gui.create_offset_editor(flow_offset, "drop")

        local offset_pusher_right = flow_offset.add({
            type = "empty-widget",
            name = "offset_pusher_right"
        })
        offset_pusher_right.style.horizontally_stretchable = true
    end
end

function gui.delete(player)
    --This if could be removed probably
    if player.gui.relative.inserter_config then
        player.gui.relative.inserter_config.destroy()
    end
    if player.gui.relative.smart_inserters then
        player.gui.relative.smart_inserters.destroy()
    end
end

function gui.create_all()
    for _, player in pairs(game.players) do
        gui.delete(player)
        gui.create(player)
    end
end

--Optimized (Not cleaned up yet)
function gui.update(player, inserter)
    local gui_instance = player.gui.relative.smart_inserters.frame_content.flow_content
    local pick_drop_housing = gui_instance.pick_drop_flow.pick_drop_housing
    local table_range = (pick_drop_housing.table_position.column_count - 1) / 2
    local inserter_range = inserter_functions.get_max_range(inserter, player.force)
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    local inserter_size = inserter_functions.get_inserter_size(inserter)

    local slim = inserter_functions.is_slim(inserter)

    local vertical = (inserter.direction==0 or inserter.direction==4)
    local orizontal = (inserter.direction==2 or inserter.direction==6)
    local enabled_cells = util.enabled_cell_matrix(player.force, orizontal, vertical, slim)

    player.gui.relative.smart_inserters.visible = util.check_blacklist(inserter)
    pick_drop_housing.inserter_pick_switch_position.allow_none_state = false
    pick_drop_housing.inserter_pick_switch_position.visible = false
    pick_drop_housing.inserter_drop_switch_position.allow_none_state = false
    pick_drop_housing.inserter_drop_switch_position.visible = false

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
            pick_drop_housing.inserter_pick_switch_position.allow_none_state = true
            pick_drop_housing.inserter_drop_switch_position.allow_none_state = true
        end

        --pickup
        if arm_positions.pickup.x < 0 then
            arm_positions.pickup.x = arm_positions.pickup.x + (inserter_size - 1)
        end
        if arm_positions.pickup.y < 0 then
            arm_positions.pickup.y = arm_positions.pickup.y + (inserter_size - 1)
        end
        if arm_positions.pickup.y == 0 then
            pick_drop_housing.inserter_pick_switch_position.visible = true
            pick_drop_housing.inserter_pick_switch_position.right_label_caption = { "gui-smart-inserters.buttom-pickup" }
            pick_drop_housing.inserter_pick_switch_position.left_label_caption = { "gui-smart-inserters.top-pickup" }
            pick_drop_housing.inserter_pick_switch_position.switch_state = "left"
            if arm_positions.base.y == arm_positions.pure_pickup.y then
                pick_drop_housing.inserter_pick_switch_position.switch_state = "right"
            end
        elseif arm_positions.pickup.x == 0 then
            pick_drop_housing.inserter_pick_switch_position.visible = true
            pick_drop_housing.inserter_pick_switch_position.right_label_caption = { "gui-smart-inserters.right-pickup" }
            pick_drop_housing.inserter_pick_switch_position.left_label_caption = { "gui-smart-inserters.left-pickup" }
            pick_drop_housing.inserter_pick_switch_position.switch_state = "left"
            if arm_positions.base.x == arm_positions.pure_pickup.x then
                pick_drop_housing.inserter_pick_switch_position.switch_state = "right"
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
            pick_drop_housing.inserter_drop_switch_position.visible = true
            pick_drop_housing.inserter_drop_switch_position.right_label_caption = { "gui-smart-inserters.buttom-drop" }
            pick_drop_housing.inserter_drop_switch_position.left_label_caption = { "gui-smart-inserters.top-drop" }
            pick_drop_housing.inserter_drop_switch_position.switch_state = "left"
            if arm_positions.base.y == arm_positions.pure_drop.y then
                pick_drop_housing.inserter_drop_switch_position.switch_state = "right"
            end
        elseif arm_positions.drop.x == 0 then
            pick_drop_housing.inserter_drop_switch_position.visible = true
            pick_drop_housing.inserter_drop_switch_position.right_label_caption = { "gui-smart-inserters.right-drop" }
            pick_drop_housing.inserter_drop_switch_position.left_label_caption = { "gui-smart-inserters.left-drop" }
            pick_drop_housing.inserter_drop_switch_position.switch_state = "left"
            if arm_positions.base.x == arm_positions.pure_drop.x then
                pick_drop_housing.inserter_drop_switch_position.switch_state = "right"
            end
        end
    end

    local idx = 0
    local button = pick_drop_housing.table_position.children[1]
    for y = -table_range, table_range, 1 do
        for x = -table_range, table_range, 1 do
            idx = idx + 1
            button = pick_drop_housing.table_position.children[idx]
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
    gui_instance.pick_drop_flow.pick_drop_housing.table_position.sprite_inserter.sprite = icon

    if offset_selector == false then
        return
    end

    local offset_tech_unlocked = tech.check_offset_tech(player.force)

    local idx = 0
    for y = -1, 1, 1 do
        for x = -1, 1, 1 do
            idx = idx + 1

            gui_instance.flow_offset.flow_pick.table_pick.children[idx].enabled = offset_tech_unlocked
            if math2d.position.equal(arm_positions.pickup_offset, { x, y }) then
                gui_instance.flow_offset.flow_pick.table_pick.children[idx].sprite = "pickup"
            else
                gui_instance.flow_offset.flow_pick.table_pick.children[idx].sprite = nil
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

function gui.update_legacy(player, inserter)
    local gui_instance = player.gui.relative.smart_inserters.frame_content.flow_content
    local pick_drop_housing = gui_instance.pick_drop_flow.pick_drop_housing
    local table_range = (pick_drop_housing.table_position.column_count - 1) / 2
    local inserter_range = inserter_functions.get_max_range(inserter, player.force)
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    local inserter_size = inserter_functions.get_inserter_size(inserter)

    local slim = inserter_functions.is_slim(inserter)

    local vertical = (inserter.direction==0 or inserter.direction==4)
    local orizontal = (inserter.direction==2 or inserter.direction==6)

    player.gui.relative.smart_inserters.visible = util.check_blacklist(inserter)
    pick_drop_housing.inserter_pick_switch_position.allow_none_state = false
    pick_drop_housing.inserter_pick_switch_position.visible = false
    pick_drop_housing.inserter_drop_switch_position.allow_none_state = false
    pick_drop_housing.inserter_drop_switch_position.visible = false

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
            pick_drop_housing.inserter_pick_switch_position.allow_none_state = true
            pick_drop_housing.inserter_drop_switch_position.allow_none_state = true
        end

        --pickup
        if arm_positions.pickup.x < 0 then
            arm_positions.pickup.x = arm_positions.pickup.x + (inserter_size - 1)
        end
        if arm_positions.pickup.y < 0 then
            arm_positions.pickup.y = arm_positions.pickup.y + (inserter_size - 1)
        end
        if arm_positions.pickup.y == 0 then
            pick_drop_housing.inserter_pick_switch_position.visible = true
            pick_drop_housing.inserter_pick_switch_position.right_label_caption = { "gui-smart-inserters.buttom-pickup" }
            pick_drop_housing.inserter_pick_switch_position.left_label_caption = { "gui-smart-inserters.top-pickup" }
            pick_drop_housing.inserter_pick_switch_position.switch_state = "left"
            if arm_positions.base.y == arm_positions.pure_pickup.y then
                pick_drop_housing.inserter_pick_switch_position.switch_state = "right"
            end
        elseif arm_positions.pickup.x == 0 then
            pick_drop_housing.inserter_pick_switch_position.visible = true
            pick_drop_housing.inserter_pick_switch_position.right_label_caption = { "gui-smart-inserters.right-pickup" }
            pick_drop_housing.inserter_pick_switch_position.left_label_caption = { "gui-smart-inserters.left-pickup" }
            pick_drop_housing.inserter_pick_switch_position.switch_state = "left"
            if arm_positions.base.x == arm_positions.pure_pickup.x then
                pick_drop_housing.inserter_pick_switch_position.switch_state = "right"
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
            pick_drop_housing.inserter_drop_switch_position.visible = true
            pick_drop_housing.inserter_drop_switch_position.right_label_caption = { "gui-smart-inserters.buttom-drop" }
            pick_drop_housing.inserter_drop_switch_position.left_label_caption = { "gui-smart-inserters.top-drop" }
            pick_drop_housing.inserter_drop_switch_position.switch_state = "left"
            if arm_positions.base.y == arm_positions.pure_drop.y then
                pick_drop_housing.inserter_drop_switch_position.switch_state = "right"
            end
        elseif arm_positions.drop.x == 0 then
            pick_drop_housing.inserter_drop_switch_position.visible = true
            pick_drop_housing.inserter_drop_switch_position.right_label_caption = { "gui-smart-inserters.right-drop" }
            pick_drop_housing.inserter_drop_switch_position.left_label_caption = { "gui-smart-inserters.left-drop" }
            pick_drop_housing.inserter_drop_switch_position.switch_state = "left"
            if arm_positions.base.x == arm_positions.pure_drop.x then
                pick_drop_housing.inserter_drop_switch_position.switch_state = "right"
            end
        end
    end

    local idx = 0
    for y = -table_range, table_range, 1 do
        for x = -table_range, table_range, 1 do
            idx = idx + 1
            local button = gui_instance.pick_drop_flow.pick_drop_housing.table_position.children[idx]
            if button.type == "sprite-button" then

                if math.max(math.abs(x), math.abs(y)) > inserter_range then
                    button.enabled = false
                else
                    button.enabled = util.should_cell_be_enabled({ x = x, y = y }, inserter_range, player.force, inserter,
                        vertical, orizontal, slim
                    )
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
    gui_instance.pick_drop_flow.pick_drop_housing.table_position.sprite_inserter.sprite = icon

    if offset_selector == false then
        return
    end

    local offset_tech_unlocked = tech.check_offset_tech(player.force)

    local idx = 0
    for y = -1, 1, 1 do
        for x = -1, 1, 1 do
            idx = idx + 1

            gui_instance.flow_offset.flow_pick.table_pick.children[idx].enabled = offset_tech_unlocked
            if math2d.position.equal(arm_positions.pickup_offset, { x, y }) then
                gui_instance.flow_offset.flow_pick.table_pick.children[idx].sprite = "pickup"
            else
                gui_instance.flow_offset.flow_pick.table_pick.children[idx].sprite = nil
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
    for idx, player in pairs(game.players) do
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

function gui.on_button_pick_offset(player, event)
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

function gui.on_switch_pick_position(player, event)
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