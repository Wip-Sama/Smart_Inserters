-- ------------------------------
-- Dependencies
-- ------------------------------
local mod_gui = require("mod-gui")
local math2d = require("__yafla__/scripts/extended_math2d")
local gui_builder = require("__yafla__/scripts/experimental/gui_builder")
local gui_helper = require("__yafla__/scripts/experimental/gui_helper")
local events = require("scripts.events")

-- ------------------------------
-- Functions Group
-- ------------------------------
local player_functions = require("scripts.player_functions")
local technology_functions = require("scripts.technology_functions")
local selector_gui = require("scripts.selector_gui")
local copy_gui = require("scripts.copy_gui")
local world_editor = require("scripts.world_selector")
local storage_functions = require("scripts.storage_functions")
local inserter_functions = require("scripts.inserter_functions")
local si_util = require("scripts.si_util")
local util = require("__core__/lualib/util")

-- ------------------------------
-- Settings
-- ------------------------------
local offset_selector = settings.startup["si-offset-selector"].value


-- ------------------------------
-- Event Handlers
-- ------------------------------

local function on_gui_opened(event)
    local player = game.get_player(event.player_index)
    if player and event.entity and inserter_functions.is_inserter(event.entity) then
        local res = inserter_functions.get_arm_positions(event.entity)
        inserter_functions.set_arm_positions(res, event.entity)
        if player.gui.relative.smart_inserters then
            selector_gui.delete(player)
        end
        selector_gui.create(player, event.entity)
    end
end

local function on_gui_closed(event)
    local player = game.get_player(event.player_index)
    if player and event.entity and inserter_functions.is_inserter(event.entity) then
        selector_gui.delete(player)
    end
end

---@param event InserterArmChanged
local function on_inserter_arm_changed(event)
    local player = game.get_player(event.player_index)
    assert(player, "Player not found")
    selector_gui.update_all(player.selected, event)
end

local function on_player_rotated_entity(event)
    local player = game.get_player(event.player_index)
    if player and event.entity and inserter_functions.is_inserter(event.entity) then
        --Note: it's easier to make factorio calculate the old positions, storing them and setting back the correct direction
        local dir = event.entity.direction
        event.entity.direction = event.previous_direction
        local old_res = inserter_functions.get_arm_positions(event.entity)
        event.entity.direction = dir
        local res = inserter_functions.get_arm_positions(event.entity)
        inserter_functions.set_arm_positions(res, event.entity)
        script.raise_event(events.on_inserter_arm_changed, {
            player_index = player.index,
            entity = event.entity,
            old_drop = old_res.drop,
            old_pickup = old_res.pickup,
            old_drop_offset = old_res.drop_offset,
            old_pickup_offset = old_res.pickup_offset
        })
    end
end

local function on_entity_settings_pasted(event)
    local player = game.get_player(event.player_index)
    if player and event.entity and inserter_functions.is_inserter(event.entity) then
        local res = inserter_functions.get_arm_positions(event.entity)
        inserter_functions.set_arm_positions(res, event.entity)
        script.raise_event(events.on_inserter_arm_changed, {
            player_index = player.index,
            entity = event.entity,
        })
        --Verificare che gli inserter hanno la stessa base, se no adattare x e y
        ---- x/y se in base ignora, se fuori base [[  avvicina alla base/riporta allo 0  ]]
        --Verificare se le posizioni sono valide per entrambi gli inserter
        ---- Se non sono valide: [[  resettare/  lasciare le vecchie/  adattarle  ]] (una di queste)
    end
end

local function on_built_entity(event)
    local player = game.get_player(event.player_index)
    if player and event.created_entity and inserter_functions.is_inserter(event.created_entity) then
        local res = inserter_functions.get_arm_positions(event.created_entity)
        inserter_functions.set_arm_positions(res, event.created_entity)
    end
end

local function on_rotation_adjust(event)
    local player = game.get_player(event.player_index)
    assert(player, "[control.lua:on_rotation_adjust] Player is nil")
    local inserter = player.selected

    if inserter_functions.is_inserter(inserter) then
        local update = string.find(event.name, "d", 17, true) == 17 and "drop" or "pickup"
        print("Dovrei fare qualcosa")
    end
end

local function on_rotation_adjust_old(event)
    local player = game.players[event.player_index]
    if inserter_functions.is_inserter(player.selected) then
        local inserter = player.selected

        local slim = inserter_functions.is_slim(inserter)
        local size = inserter_functions.get_inserter_size(inserter)
        if slim then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-slim-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end
        if size > 1 then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-big-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local is_drop = string.find(event.input_name, "drop", 17) and true or false
        local direction = string.find(event.input_name, "reverse", -7) and -1 or 1

        local target = is_drop and "drop" or "pickup"
        local check = is_drop and "pickup" or "drop"

        local arm_positions = inserter_functions.get_arm_positions(inserter)

        local range = math.max(math.abs(arm_positions[target].x), math.abs(arm_positions[target].y))

        local old_direction = math2d.direction.from_vector(arm_positions[target], range)

        local new_direction = (old_direction + direction) % (8 * range)
        local new_tile = math2d.direction.to_vector(new_direction, range)

        while not technology_functions.check_diagonal_tech(player.force, new_tile) do
            new_direction = (new_direction + direction) % (8 * range)
            new_tile = math2d.direction.to_vector(new_direction, range)
        end

        if math2d.position.equal(new_tile, arm_positions[check]) then
            new_direction = (new_direction + direction) % (8 * range)
            new_tile = math2d.direction.to_vector(new_direction, range)
            while not technology_functions.check_diagonal_tech(player.force, new_tile) do
                new_direction = (new_direction + direction) % (8 * range)
                new_tile = math2d.direction.to_vector(new_direction, range)
            end
        end

        local new_arm_positions = {}
        new_arm_positions[target] = new_tile
        new_arm_positions[target .. "_offset"] = inserter_functions.calc_rotated_offset(inserter, new_tile, target)

        new_arm_positions[target] = new_tile
        inserter_functions.set_arm_positions(inserter, new_arm_positions)

        gui.update_all(inserter)
    end
end

local function on_distance_adjust(event)
    local player = game.get_player(event.player_index)
    assert(player, "[control.lua:on_distance_adjust] Player is nil")
    local inserter = player.selected

    if inserter_functions.is_inserter(inserter) then
        assert(inserter, "[control.lua:on_offset_adjust] Inserter is nil")
        local arms = inserter_functions.get_arm_positions(inserter)
        local update = string.find(event.input_name, "d", 17, true) == 17 and "drop" or
        "pickup"                                                                                 --stands for update...drop/pickup
        local direction = string.find(event.input_name, "e", #event.input_name, true) == #event.input_name and 1 or -1
        local position = util.copy(arms[update])

        -- I need max range to avoid the position to be outside the range

        if arms.arm_direction == defines.direction.north then
            position.y = position.y + direction
        elseif arms.arm_direction == defines.direction.northeast then
            position.x = position.x + direction
            position.y = position.y + direction
        elseif arms.arm_direction == defines.direction.east then
            position.x = position.x + direction
        elseif arms.arm_direction == defines.direction.southeast then
            position.x = position.x + direction
            position.y = position.y - direction
        elseif arms.arm_direction == defines.direction.south then
            position.y = position.y - direction
        elseif arms.arm_direction == defines.direction.southwest then
            position.x = position.x - direction
            position.y = position.y - direction
        elseif arms.arm_direction == defines.direction.west then
            position.x = position.x - direction
        elseif arms.arm_direction == defines.direction.northwest then
            position.x = position.x - direction
            position.y = position.y + direction
        end

        arms[update] = position

        ---@diagnostic disable-next-line: param-type-mismatch
        if technology_functions.check_range_tech(inserter.force, position, inserter_functions.get_max_inserters_range()) then
            inserter_functions.set_arm_positions(arms, inserter)
        end
    end
end

local function on_offset_adjust(event)
    local player = game.get_player(event.player_index)
    assert(player, "[control.lua:on_offset_adjust] Player is nil")
    local inserter = player.selected

    if inserter_functions.is_inserter(inserter) then
        assert(inserter, "[control.lua:on_offset_adjust] Inserter is nil")
        ---@diagnostic disable-next-line: param-type-mismatch
        if not technology_functions.check_offset_tech(inserter.force) then
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.required-technology-missing", "mod-setting-name.si-offset-technologies" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end
        assert(inserter, "[control.lua:on_offset_adjust] Inserter is nil")
        local arms = inserter_functions.get_arm_positions(inserter)
        local update = string.find(event.input_name, "d", 17, true) == 17 and "drop" or "pickup"
        local position = util.copy(arms[update .. "_offset"])

        if arms.arm_direction == defines.direction.north then
            position.y = position.y > 0.5 and 0.25 or 0.75
            position.x = 0.5
        elseif arms.arm_direction == defines.direction.northeast then
            local x = position.x > 0.5 and 0.25 or 0.75
            local y = x == 0.75 and 0.25 or 0.75
            position.x = x
            position.y = y
        elseif arms.arm_direction == defines.direction.east then
            position.y = 0.5
            position.x = position.x > 0.5 and 0.25 or 0.75
        elseif arms.arm_direction == defines.direction.southeast then
            local new = position.x > 0.5 and 0.25 or 0.75
            position.x = new
            position.y = new
        elseif arms.arm_direction == defines.direction.south then
            position.y = position.y > 0.5 and 0.25 or 0.75
            position.x = 0.5
        elseif arms.arm_direction == defines.direction.southwest then
            local x = position.x > 0.5 and 0.25 or 0.75
            local y = x == 0.75 and 0.25 or 0.75
            position.x = x
            position.y = y
        elseif arms.arm_direction == defines.direction.west then
            position.y = 0.5
            position.x = position.x > 0.5 and 0.25 or 0.75
        elseif arms.arm_direction == defines.direction.northwest then
            local new = position.x > 0.5 and 0.25 or 0.75
            position.x = new
            position.y = new
        end

        old = arms[update .. "_offset"]
        arms[update .. "_offset"] = position
        inserter_functions.set_arm_positions(arms, inserter)
        script.raise_event(events.on_inserter_arm_changed, {
            player_index = player.index,
            entity = inserter,
            old_drop_offset = update == "drop" and old or nil,
            old_pickup_offset = update == "pickup" and old or nil
        })
    end
end

-- --------------------------
-- Eventhandler registration
-- ------------------------------

-- Player and Init events
--[[
script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_research_finished, on_research_finished)
script.on_event(defines.events.on_research_reversed, on_research_reversed)

script.on_event(defines.events.on_player_created, on_player_created)

script.on_event(defines.events.on_cutscene_cancelled, welcome)
script.on_event(defines.events.on_cutscene_finished, welcome)
]]

-- Gui events
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(events.on_inserter_arm_changed, on_inserter_arm_changed)
script.on_event(defines.events.on_player_rotated_entity, on_player_rotated_entity)
script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

--I'd like to remove this since I really do not want to check every entity built by factorio to update the positions...
--Also this may break compatibility with other mods
--TODO: find an alternative or something comparable to on_built_entity
script.on_event(defines.events.on_built_entity, on_built_entity)


--[[
script.on_event(defines.events.on_pre_entity_settings_pasted, on_pre_entity_settings_pasted)
]]

-- Shortcut events
script.on_event("smart-inserters-drop-rotate", on_rotation_adjust)
script.on_event("smart-inserters-drop-rotate-reverse", on_rotation_adjust)
script.on_event("smart-inserters-drop-distance-adjust", on_distance_adjust)
script.on_event("smart-inserters-drop-distance-adjust-reverse", on_distance_adjust)
script.on_event("smart-inserters-drop-offset-adjust", on_offset_adjust)
script.on_event("smart-inserters-pickup-rotate", on_rotation_adjust)
script.on_event("smart-inserters-pickup-rotate-reverse", on_rotation_adjust)
script.on_event("smart-inserters-pickup-distance-adjust", on_distance_adjust)
script.on_event("smart-inserters-pickup-distance-adjust-reverse", on_distance_adjust)
script.on_event("smart-inserters-pickup-offset-adjust", on_offset_adjust)

-- World editor events
--[[
script.on_event("smart-inserters-in-world-inserter-configurator-pickup", on_in_world_editor)
script.on_event("smart-inserters-in-world-inserter-configurator-drop", on_in_world_editor)
script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)
script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.script_raised_built, on_built_entity)
script.on_event(defines.events.script_raised_destroy, on_entity_destroyed)
script.on_event(defines.events.on_player_mined_entity, on_entity_destroyed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_destroyed)
--]]

--script.on_event(defines.events.on_entity_died, on_entity_destroyed)
--script.on_event(defines.events.on_entity_destroyed, on_entity_destroyed)

-- TODO: optimize should cell be enabled
-- in-world selector for slim inserter
-- in world selector for 2x2 inserter
-- compatibility with renai trasportation
-- compatibility with ghost entity
