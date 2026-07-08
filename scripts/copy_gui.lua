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
    return CHECKBOX {
        name = elem_name,
        caption = { "gui-copy-smart-inserters.si-" .. caption_key },
        tooltip = { "gui-copy-smart-inserters.si-" .. caption_key .. "-tooltip" },
        state = storage.SI_Storage[player_index].copy_settings[elem_name],
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
        style = "relative_gui_left_flow",
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
    local window = Window(player, {
        name = "si_copypaste_configurator",
        window_title = { "gui-copy-smart-inserters.si-hotbar-title" },
        window_icon = "circle",
        closable = true,
        extra_button = SPRITE_BUTTON {
            name = "si-reset-button",
            sprite = "utility/reset_white",
            hovered_sprite = "utility/reset",
            clicked_sprite = "utility/reset",
            tooltip = "Reset all checkbox",
            style = "close_button",
            on_click = "si_reset_checkbox_status"
        }
    })

    -- Add tabs natively since yafla does not fully support tabbed pane natively yet
    local copypaste_down_frame = window.add {
        type = "frame",
        name = "copypaste_down_frame",
        style = "inside_deep_frame",
    }
    local tab_pane = copypaste_down_frame.add {
        type = "tabbed-pane",
        name = "si_config_tab_pane",
    }
    
    storage_functions.ensure_data(player.index)

    -- Basic
    local basic_tab = tab_pane.add { type = "tab", name = "basic_tab", caption = { "gui-copy-smart-inserters.si-tab-basic" } }
    local basic_flow = tab_pane.add { type = "flow", name = "basic_flow" }
    tab_pane.add_tab(basic_tab, basic_flow)
    yafla_gui_builder.build(basic_flow, Tab_content("basic", player.index), player.index)

    -- Filter
    local filter_tab = tab_pane.add { type = "tab", name = "filter_tab", caption = { "gui-copy-smart-inserters.si-tab-filter" } }
    local filter_flow = tab_pane.add { type = "flow", name = "filter_flow" }
    tab_pane.add_tab(filter_tab, filter_flow)
    yafla_gui_builder.build(filter_flow, Tab_content("filter", player.index), player.index)

    -- Logic
    local logic_tab = tab_pane.add { type = "tab", name = "logic_tab", caption = { "gui-copy-smart-inserters.si-tab-circuit" } }
    local logic_flow = tab_pane.add { type = "flow", name = "logic_flow" }
    tab_pane.add_tab(logic_tab, logic_flow)
    yafla_gui_builder.build(logic_flow, Tab_content("circuit", player.index), player.index)
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
    local tab_name = string.sub(event.element.name, 8)
    local count = #elements[tab_name]
    local enabled = 0

    for _, v in pairs(elements[tab_name]) do
        enabled = enabled + (storage.SI_Storage[player_index].copy_settings[v] and 1 or 0)
    end

    return (enabled >= (count / 2) and true or false)
end

local function si_toggle_checkbox_status(event)
    local player_index = event.player_index
    local status = compute_toggle_status(event)
    local tab_name = string.sub(event.element.name, 8)
    
    local parent_flow = event.element.parent
    for _, child in pairs(parent_flow.children) do
        if child.type == "checkbox" then
            child.state = not status
            storage.SI_Storage[player_index].copy_settings[child.name] = not status
        end
    end
end

local function si_reset_checkbox_status(event)
    local player_index = event.player_index
    local player = game.get_player(player_index)
    local window = player.gui.screen.si_copypaste_configurator
    if window then
        local tab_pane = window.copypaste_down_frame.si_config_tab_pane
        for _, tab_content in pairs(tab_pane.children) do
            if tab_content.type == "flow" then
                local inner_flow = tab_content.children[1]
                for _, child in pairs(inner_flow.children) do
                    if child.type == "checkbox" then
                        child.state = true
                        storage.SI_Storage[player_index].copy_settings[child.name] = true
                    end
                end
            end
        end
    end
end

local function si_update_checkbox_status(event)
    local player_index = event.player_index
    storage_functions.ensure_data(player_index)
    storage.SI_Storage[player_index].copy_settings[event.element.name] = event.element.state
end

local function si_toggle_copy_gui(event)
    local player = game.get_player(event.player_index)
    if player.gui.screen.si_copypaste_configurator then
        copy_gui.remove_gui(player)
    else
        copy_gui.add_gui(player)
    end
end

yafla_gui_builder.register_handler("si_toggle_checkbox_status", si_toggle_checkbox_status)
yafla_gui_builder.register_handler("si_reset_checkbox_status", si_reset_checkbox_status)
yafla_gui_builder.register_handler("si_update_checkbox_status", si_update_checkbox_status)
yafla_gui_builder.register_handler("si_toggle_copy_gui", si_toggle_copy_gui)

return copy_gui
