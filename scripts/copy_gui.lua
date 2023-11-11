local storage_functions = require("scripts/storage_functions")

local copy_gui = {}

function copy_gui.delete(player)
    if player.gui.relative.smart_inserters then
        player.gui.relative.smart_inserters.destroy()
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
    player.gui.screen.si_copypaste_configurator.destroy()
end

function copy_gui.add_gui(player)
    local si_copypaste_configurator = player.gui.screen.add {
        type = "frame",
        direction = "vertical",
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


function copy_gui.update_checkbox_status(event)
    local player_index = event.player_index
    storage_functions.ensure_data(player_index)
    global.SI_Storage[player_index].copy_settings[event.element.name] = event.element.state
end

function copy_gui.toggle_gui(player, event)
    if player.gui.screen.si_copypaste_configurator then
        copy_gui.remove_gui(player)
    else
        copy_gui.add_gui(player)
    end
end


return copy_gui