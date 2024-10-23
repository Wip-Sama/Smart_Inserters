local storage_functions = require("scripts.storage_functions")
local mod_gui = require("mod-gui")

--local gui_builder = require("__yafla__/scripts/experimental/gui_builder")
--local gui_components = require("__yafla__/scripts/experimental/gui_builder")

local copy_gui = {}

copy_gui.elememts = {
    basic = {
        "drop",
        "drop_offset",
        "pickup",
        "pickup_offset",
        "si_direction",
        "relative_si_direction"
    },
    filter = {
        "inserter_filter_mode",
        "filtered_stuff",
        "inserter_stack_size_override",
    },
    circuit = {
        "circuit_set_stack_size",
        "circuit_read_hand_contents",
        "circuit_mode_of_operation",
        "circuit_hand_read_mode",
        "circuit_condition",
        "circuit_stack_control_signal",
    }
}

function copy_gui.delete(player)
    if player.gui.screen.smart_inserters then
        player.gui.screen.smart_inserters.destroy()
    end
end

function copy_gui.create(player)
    local button_flow = mod_gui.get_button_flow(player)
    if button_flow.si_configurator_toggle then return end
    button_flow.add {
        type = "sprite-button",
        name = "si_configurator_toggle",
        sprite = "circle"
    }
end

function copy_gui.create_all()
    for _, player in pairs(game.players) do
        copy_gui.delete(player)
        copy_gui.create(player)
    end
end

function copy_gui.remove_gui(player)
    if player.gui.screen.si_copypaste_configurator then
        player.gui.screen.si_copypaste_configurator.destroy()
    end
end

function copy_gui.add_gui(player)
    local si_copypaste_configurator = player.gui.screen.add {
        type = "frame",
        direction = "vertical",
        ref = { "window" },
        name = "si_copypaste_configurator",
    }

    local hotbar = si_copypaste_configurator.add {
        type = "flow",
        direction = "horizontal",
        style = "si_hotbar_flow"
    }
    hotbar.drag_target = si_copypaste_configurator

    hotbar.add {
        type = "sprite",
        sprite = "circle",
        ignored_by_interaction = true,
        style = "si_hotbar_sprite"
    }
    hotbar.add {
        type = "label",
        caption = { "gui-copy-smart-inserters.si-hotbar-title" },
        ignored_by_interaction = true,
        style = "frame_title"
    }
    hotbar.add {
        type = "empty-widget",
        ignored_by_interaction = true,
        style = "si_drag_handle"
    }
    hotbar.add {
        type = "sprite-button",
        name = "si-reset-button",
        sprite = "utility/reset_white",
        hovered_sprite = "utility/reset",
        clicked_sprite = "utility/reset",
        tooltip = "Reset all checkbox",
        style = "close_button"
    }
    hotbar.add {
        type = "sprite-button",
        name = "si-close-button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        tooltip = "Close the window",
        style = "close_button"
    }

    local copypaste_down_frame = si_copypaste_configurator.add {
        type = "frame",
        name = "copypaste_down_frame",
        style = "inside_deep_frame_for_tabs",
    }

    local tab_pane = copypaste_down_frame.add {
        type = "tabbed-pane",
        name = "si_config_tab_pane",
    }

    storage_functions.ensure_data(player.index)

    -- Basic
    local basic_tab = tab_pane.add {
        type = "tab",
        name = "basic_tab",
        caption = { "gui-copy-smart-inserters.si-tab-basic" }
    }
    local basic_flow = tab_pane.add {
        type = "flow",
        name = "basic_flow",
        direction = "vertical",
        style = "vertical_flow_with_extra_margins"
    }
    tab_pane.add_tab(basic_tab, basic_flow)
    copy_gui.add_button(basic_flow, "toggle-basic", "si-toggle", "si-toggle-tooltip")
    copy_gui.add_checkbox(basic_flow, "drop", "si-drop", "si-drop-tooltip", player.index)
    copy_gui.add_checkbox(basic_flow, "drop_offset", "si-drop-offset", "si-drop-offset-tooltip", player.index)
    copy_gui.add_checkbox(basic_flow, "pickup", "si-pickup", "si-pickup-tooltip", player.index)
    copy_gui.add_checkbox(basic_flow, "pickup_offset", "si-pickup-offset", "si-pickup-offset-tooltip", player.index)
    copy_gui.add_checkbox(basic_flow, "si_direction", "si-direction", "si-direction-tooltip", player.index)
    copy_gui.add_checkbox(basic_flow, "relative_si_direction", "si-relative-direction", "si-relative-direction-tooltip", player.index)

    -- Filter
    local filter_tab = tab_pane.add {
        type = "tab",
        name = "filter_tab",
        caption = { "gui-copy-smart-inserters.si-tab-filter" }
    }
    local filter_flow = tab_pane.add {
        type = "flow",
        name = "filter_flow",
        direction = "vertical",
        style = "vertical_flow_with_extra_margins"
    }
    tab_pane.add_tab(filter_tab, filter_flow)
    copy_gui.add_button(filter_flow, "toggle-filter", "si-toggle", "si-toggle-tooltip")
    copy_gui.add_checkbox(filter_flow, "inserter_filter_mode", "si-filter-mode", "si-filter-mode-tooltip", player.index)
    copy_gui.add_checkbox(filter_flow, "filtered_stuff", "si-filtered-stuff", "si-filtered-stuff-tooltip", player.index)
    copy_gui.add_checkbox(filter_flow, "inserter_stack_size_override", "si-stack-size-override", "si-stack-size-override-tooltip", player.index)

    -- Logic
    local logic_tab = tab_pane.add {
        type = "tab",
        name = "logic_tab",
        caption = { "gui-copy-smart-inserters.si-tab-circuit" }
    }
    local logic_flow = tab_pane.add {
        type = "flow",
        name = "logic_flow",
        direction = "vertical",
        style = "vertical_flow_with_extra_margins"
    }
    tab_pane.add_tab(logic_tab, logic_flow)
    copy_gui.add_button(logic_flow, "toggle-circuit", "si-toggle", "si-toggle-tooltip")
    copy_gui.add_checkbox(logic_flow, "circuit_set_stack_size", "si-set-stack-size", "si-set-stack-size-tooltip", player.index)
    copy_gui.add_checkbox(logic_flow, "circuit_read_hand_contents", "si-read-hand-contents", "si-read-hand-contents-tooltip", player.index)
    copy_gui.add_checkbox(logic_flow, "circuit_mode_of_operation", "si-mode-of-operation", "si-mode-of-operation-tooltip", player.index)
    copy_gui.add_checkbox(logic_flow, "circuit_hand_read_mode", "si-read-hand-mode", "si-read-hand-mode-tooltip", player.index)
    copy_gui.add_checkbox(logic_flow, "circuit_condition", "si-circuit-conditions", "si-circuit-conditions-tooltip", player.index)
    copy_gui.add_checkbox(logic_flow, "circuit_stack_control_signal", "si-control-signal", "si-control-signal-tooltip", player.index)
end

function copy_gui.add_checkbox(flow, name, caption_key, tooltip_key, player_index)
    flow.add {
        type = "checkbox",
        name = name,
        caption = { "gui-copy-smart-inserters." .. caption_key },
        tooltip = { "gui-copy-smart-inserters." .. tooltip_key },
        state = global.SI_Storage[player_index].copy_settings[name]
    }
end

function copy_gui.add_button(flow, name, caption_key, tooltip_key)
    flow.add {
        type = "button",
        name = name,
        caption = { "gui-copy-smart-inserters." .. caption_key },
        tooltip = { "gui-copy-smart-inserters." .. tooltip_key }
    }
end

local function compute_toggle_status(event)
    local player_index = event.player_index
    local count = #copy_gui.elememts[string.sub(event.element.name,8)]
    local enabled = 0

    for _, v in pairs(copy_gui.elememts[string.sub(event.element.name,8)]) do
        enabled = enabled + (global.SI_Storage[player_index].copy_settings[v] and 1 or 0)
    end

    return (enabled >= (count/2) and true or false)
end

function copy_gui.toggle_checkbox_status(event)
    local player_index = event.player_index
    local status = compute_toggle_status(event)
    local player = game.players[player_index]
    for _, vb in pairs(player.gui.screen.children) do
        if vb.name == "si_copypaste_configurator" then
            local buttons = vb.children[2].children[1].children[2]
            if string.sub(event.element.name,8) == "filter" then
                buttons = vb.children[2].children[1].children[4]
            elseif string.sub(event.element.name,8) == "circuit" then
                buttons = vb.children[2].children[1].children[6]
            end
            for k, v in pairs(copy_gui.elememts[string.sub(event.element.name,8)]) do
                buttons.children[k+1].state = not status
                global.SI_Storage[player_index].copy_settings[v] = not status
            end
            break
        end
    end
end

function copy_gui.reset_checkbox_status(event)
    local player_index = event.player_index
    local player = game.players[player_index]
    for _, vb in pairs(player.gui.screen.children) do
        if vb.name == "si_copypaste_configurator" then
            for k, v in pairs(copy_gui.elememts["basic"]) do
                vb.children[2].children[1].children[2].children[k+1].state = true
                global.SI_Storage[player_index].copy_settings[v] = true
            end
            for k, v in pairs(copy_gui.elememts["filter"]) do
                vb.children[2].children[1].children[4].children[k+1].state = true
                global.SI_Storage[player_index].copy_settings[v] = true
            end
            for k, v in pairs(copy_gui.elememts["circuit"]) do
                vb.children[2].children[1].children[6].children[k+1].state = true
                global.SI_Storage[player_index].copy_settings[v] = true
            end
            break
        end
    end
end

function copy_gui.update_checkbox_status(event)
    local player_index = event.player_index
    storage_functions.ensure_data(player_index)
    if string.sub(event.element.name,1,7) == "toggle-" then
        copy_gui.toggle_checkbox_status(event)
    else
        global.SI_Storage[player_index].copy_settings[event.element.name] = event.element.state
    end
end

function copy_gui.toggle_gui(player, event)
    if player.gui.screen.si_copypaste_configurator then
        copy_gui.remove_gui(player)
    else
        copy_gui.add_gui(player)
    end
end

return copy_gui