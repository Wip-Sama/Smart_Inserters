-- External
local yafla_gui_builder = require("__yafla__/scripts/experimental/gui_builder.lua")
require("__yafla__/scripts/experimental/gui_components.lua")

-- Internal
local storage_functions = require("scripts.storage_functions")
local mod_gui = require("mod-gui")

local copy_gui = {}

local elements = {
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
        "inserter_target_pickup_count",
        "inserter_spoil_priority"
    },
    circuit = {
        "circuit_enable_disable",
        "circuit_condition",
        "circuit_set_filters",
        "circuit_read_hand_contents",
        "circuit_hand_read_mode",
        "circuit_set_stack_size",
        "circuit_stack_control_signal"
    }
}

local function Tab_toggle_button(tab_name)
    return BUTTON {
        name = "toggle-" .. tab_name,
        caption = { "gui-copy-smart-inserters.si-toggle" },
        tooltip = { "gui-copy-smart-inserters.si-toggle-tooltip" },
        on_click = "si_toggle_checkbox_status"
    }
end

local function Config_checkbox(elem_name, player_index)
    local caption_key = string.gsub(elem_name, "_", "-")
    local active_idx = storage.SI_Storage[player_index].active_preset_index
    return CHECKBOX {
        name = elem_name,
        caption = { "gui-copy-smart-inserters.si-" .. caption_key },
        tooltip = { "gui-copy-smart-inserters.si-" .. caption_key .. "-tooltip" },
        state = storage.SI_Storage[player_index].presets[active_idx].settings[elem_name],
        actions = { on_checked_state_changed = "si_update_checkbox_status" }
    }
end

local function Tab_content(tab_name, player_index)
    local children = { Tab_toggle_button(tab_name) }
    for _, elem_name in ipairs(elements[tab_name]) do
        table.insert(children, Config_checkbox(elem_name, player_index))
    end
    
    return FLOW {
        name = tab_name .. "_flow",
        direction = "vertical",
        style = "relative_gui_right_flow",
        horizontally_stretchable = true,
        table.unpack(children)
    }
end

function copy_gui.create(player)
    local button_flow = mod_gui.get_button_flow(player)
    if button_flow.si_configurator_toggle then return end
    
    yafla_gui_builder.build(button_flow, SPRITE_BUTTON {
        name = "si_configurator_toggle",
        sprite = "circle",
        on_click = "si_toggle_copy_gui"
    }, player.index)
end

function copy_gui.delete(player)
    if player.gui.screen.si_copypaste_configurator then
        yafla_gui_builder.delete(player.gui.screen.si_copypaste_configurator)
    end
end

function copy_gui.remove_gui(player)
    copy_gui.delete(player)
end

function copy_gui.add_gui(player)
    local player_storage = storage_functions.ensure_data(player.index)
    local active_idx = player_storage.active_preset_index
    local active_name = player_storage.presets[active_idx].name

    local window = player.gui.screen.add(FRAME {
        name = "si_copypaste_configurator",
        direction = "vertical",
        ref = { "window" }
    })
    
    -- Custom Hotbar
    yafla_gui_builder.build(window, FLOW {
        direction = "horizontal",
        style = "yafla_hotbar_flow",
        drag_target = window,
        SPRITE { sprite = "circle", ignored_by_interaction = true, style = "yafla_hotbar_sprite" },
        LABEL { caption = { "gui-copy-smart-inserters.si-hotbar-title" }, ignored_by_interaction = true, style = "frame_title" },
        EMPTY_WIDGET { ignored_by_interaction = true, style = "yafla_drag_handle" },

        SPRITE_BUTTON {
            sprite = "utility/close",
            hovered_sprite = "utility/close_black",
            clicked_sprite = "utility/close_black",
            tooltip = "Close the window",
            style = "frame_action_button",
            on_click = "si_close_window"
        }
    }, player.index)

    -- Add tabs natively since yafla does not fully support tabbed pane natively yet
    -- Middle Bar: Preset selector
    local preset_names = {}
    for _, p in ipairs(player_storage.presets) do
        table.insert(preset_names, p.name)
    end

    local preset_frame = window.add(FRAME {
        type = "frame",
        name = "si_preset_frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    })
    
    yafla_gui_builder.build(preset_frame, FLOW {
        direction = "vertical",
        FLOW {
            direction = "horizontal",
            vertical_align = "center",
            TEXTFIELD {
                name = "si_preset_name",
                text = active_name,
                on_text_changed = "si_rename_preset"
            },
            SPRITE_BUTTON {
                name = "si_add_preset",
                sprite = "utility/add",
                style = "tool_button_blue",
                on_click = "si_add_preset"
            },
            SPRITE_BUTTON {
                name = "si-reset-button",
                sprite = "utility/reset",
                tooltip = "Reset all checkbox",
                style = "tool_button",
                on_click = "si_reset_checkbox_status"
            },
            SPRITE_BUTTON {
                name = "si_delete_preset",
                sprite = "utility/close",
                style = "tool_button_red",
                on_click = "si_delete_preset",
                enabled = (#preset_names > 1)
            }
        },
        DROP_DOWN {
            name = "si_preset_dropdown",
            items = preset_names,
            selected_index = active_idx,
            on_selection_changed = "si_select_preset"
        }
    }, player.index)

    -- Tabs
    local copypaste_down_frame = window.add {
        type = "frame",
        name = "copypaste_down_frame",
        style = "inside_deep_frame",
    }
    copypaste_down_frame.style.horizontally_stretchable = true
    
    yafla_gui_builder.build(copypaste_down_frame, TABBED_PANE {
        name = "si_config_tab_pane",
        horizontally_stretchable = true,
        {
            tab = TAB { name = "basic_tab", caption = { "gui-copy-smart-inserters.si-tab-basic" } },
            content = Tab_content("basic", player.index)
        },
        {
            tab = TAB { name = "filter_tab", caption = { "gui-copy-smart-inserters.si-tab-filter" } },
            content = Tab_content("filter", player.index)
        },
        {
            tab = TAB { name = "logic_tab", caption = { "gui-copy-smart-inserters.si-tab-circuit" } },
            content = Tab_content("circuit", player.index)
        }
    }, player.index)
end

function copy_gui.create_all()
    for _, player in pairs(game.players) do
        copy_gui.create(player)
    end
end

------------------------------------------
---------------GUI HANDLERS---------------
------------------------------------------

local function compute_toggle_status(event)
    local player_index = event.player_index
    local active_idx = storage.SI_Storage[player_index].active_preset_index
    local tab_name = string.sub(event.element.name, 8)
    local count = #elements[tab_name]
    local enabled = 0

    for _, v in pairs(elements[tab_name]) do
        enabled = enabled + (storage.SI_Storage[player_index].presets[active_idx].settings[v] and 1 or 0)
    end

    return (enabled >= (count / 2) and true or false)
end

local function si_toggle_checkbox_status(event)
    local player_index = event.player_index
    local active_idx = storage.SI_Storage[player_index].active_preset_index
    local status = compute_toggle_status(event)
    local tab_name = string.sub(event.element.name, 8)
    
    local parent_flow = event.element.parent
    for _, child in pairs(parent_flow.children) do
        if child.type == "checkbox" then
            child.state = not status
            storage.SI_Storage[player_index].presets[active_idx].settings[child.name] = not status
        end
    end
end

local function si_reset_checkbox_status(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    local active_idx = storage.SI_Storage[player_index].active_preset_index
    local window = player.gui.screen.si_copypaste_configurator
    if window then
        local tab_pane = window.copypaste_down_frame.si_config_tab_pane
        for _, tab_content in pairs(tab_pane.children) do
            if tab_content.type == "flow" then
                for _, child in pairs(tab_content.children) do
                    if child.type == "checkbox" then
                        child.state = true
                        storage.SI_Storage[player_index].presets[active_idx].settings[child.name] = true
                    end
                end
            end
        end
    end
end

local function si_update_checkbox_status(event)
    local player_index = event.player_index
    local active_idx = storage.SI_Storage[player_index].active_preset_index
    storage.SI_Storage[player_index].presets[active_idx].settings[event.element.name] = event.element.state
end

local function si_toggle_copy_gui(event)
    local player = game.get_player(event.player_index)
    if player.gui.screen.si_copypaste_configurator then
        copy_gui.remove_gui(player)
    else
        copy_gui.add_gui(player)
    end
end

local function si_close_window(event)
    copy_gui.remove_gui(game.get_player(event.player_index))
end

local function si_rename_preset(event)
    local player_index = event.player_index
    local player_storage = storage.SI_Storage[player_index]
    local active_idx = player_storage.active_preset_index
    
    local new_name = event.element.text
    player_storage.presets[active_idx].name = new_name
    
    local window = game.get_player(player_index).gui.screen.si_copypaste_configurator
    if window then
        local dropdown = window.si_preset_frame.children[1].si_preset_dropdown
        local items = dropdown.items
        items[active_idx] = new_name
        dropdown.items = items
    end
end

local function recreate_window_in_place(player)
    local window = player.gui.screen.si_copypaste_configurator
    local loc = window and window.location
    copy_gui.remove_gui(player)
    copy_gui.add_gui(player)
    if loc and player.gui.screen.si_copypaste_configurator then
        player.gui.screen.si_copypaste_configurator.location = loc
    end
end

local function si_add_preset(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    local player_storage = storage.SI_Storage[player_index]
    
    local new_preset = {
        name = "Preset " .. (#player_storage.presets + 1),
        settings = storage_functions.get_default_copy_settings()
    }
    table.insert(player_storage.presets, new_preset)
    player_storage.active_preset_index = #player_storage.presets
    
    recreate_window_in_place(player)
end

local function si_delete_preset(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    local player_storage = storage.SI_Storage[player_index]
    
    if #player_storage.presets <= 1 then return end
    
    table.remove(player_storage.presets, player_storage.active_preset_index)
    if player_storage.active_preset_index > #player_storage.presets then
        player_storage.active_preset_index = #player_storage.presets
    end
    
    recreate_window_in_place(player)
end

local function si_select_preset(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    storage.SI_Storage[player_index].active_preset_index = event.element.selected_index
    
    recreate_window_in_place(player)
end

yafla_gui_builder.register_handler("si_toggle_checkbox_status", si_toggle_checkbox_status)
yafla_gui_builder.register_handler("si_reset_checkbox_status", si_reset_checkbox_status)
yafla_gui_builder.register_handler("si_update_checkbox_status", si_update_checkbox_status)
yafla_gui_builder.register_handler("si_toggle_copy_gui", si_toggle_copy_gui)
yafla_gui_builder.register_handler("si_close_window", si_close_window)
yafla_gui_builder.register_handler("si_rename_preset", si_rename_preset)
yafla_gui_builder.register_handler("si_add_preset", si_add_preset)
yafla_gui_builder.register_handler("si_delete_preset", si_delete_preset)
yafla_gui_builder.register_handler("si_select_preset", si_select_preset)

return copy_gui
