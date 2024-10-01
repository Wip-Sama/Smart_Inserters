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
local tech = require("scripts.technology_functions")
local selector_gui = require("scripts.selector_gui")
local copy_gui = require("scripts.copy_gui")
local world_editor = require("scripts.world_selector")
local storage_functions = require("scripts.storage_functions")
local inserter_functions = require("scripts.inserter_functions")
local util = require("scripts.si_util")

-- ------------------------------
-- Settings
-- ------------------------------
local offset_selector = settings.startup["si-offset-selector"].value


















-- Mod init
local function on_init()
    global.SI_Storage = {}
    storage_functions.populate_storage()
    inserter_functions.calculate_max_inserters_range()
    copy_gui.create_all()
    gui.create_all()
    tech.migrate_all()
end

local function welcome()
    game.print({ "smart-inserters.welcome" })
    game.print({ "smart-inserters.experimental" })
end

local function on_research_finished(event)
    tech.generate_Tech_lookup_table(event.research.force)
end

local function on_research_reversed(event)
    tech.generate_Tech_lookup_table(event.research.force)
end

local function on_configuration_changed(cfg_changed_data)
    if not global.SI_Storage then
        global["SI_Storage"] = {}
    end
    storage_functions.populate_storage()
    inserter_functions.calculate_max_inserters_range()
    copy_gui.create_all()
    gui.create_all()
    gui.update_all()
    tech.migrate_all()
    game.print({ "smart-inserters.experimental" })
end

local function on_player_created(event)
    local player = game.players[event.player_index]
    gui.create(player)
    copy_gui.create(player)
    storage_functions.add_player(event.player_index)
end

-- TODO check in muliplayer when changing the in-world selector updates
local function on_entity_settings_pasted(event)
    if not (inserter_functions.is_inserter(event.destination) and inserter_functions.is_inserter(event.source)) then
        return
    end

    local player_index = event.player_index
    storage_functions.ensure_data(player_index)
    local player_storage = global.SI_Storage[player_index]
    local destination = event.destination
    local copy_event = player_storage.copy_event

    -- Basic
    destination.drop_position = copy_event.drop
    destination.pickup_position = copy_event.pickup
    destination.direction = copy_event.si_direction

    -- Filter
    if event.destination.inserter_filter_mode then
        destination.inserter_filter_mode = copy_event.inserter_filter_mode
        for i = 1, 5, 1 do
            local filtered_slot = copy_event.filtered_slots[i]
            if filtered_slot.copy and filtered_slot.item ~= "" then
                event.destination.set_filter(i, filtered_slot.item)
            end
        end
    end

    if event.destination.inserter_stack_size_override and event.source.inserter_stack_size_override then
        destination.inserter_stack_size_override = copy_event.inserter_stack_size_override
    end

    -- Circuit condition
    local destination_behavior = event.destination.get_or_create_control_behavior()
    local dest_behavior_copy = copy_event.destination_behavior

    destination_behavior.circuit_set_stack_size = dest_behavior_copy.circuit_set_stack_size
    destination_behavior.circuit_read_hand_contents = dest_behavior_copy.circuit_read_hand_contents
    destination_behavior.circuit_mode_of_operation = dest_behavior_copy.circuit_mode_of_operation
    destination_behavior.circuit_hand_read_mode = dest_behavior_copy.circuit_hand_read_mode
    destination_behavior.circuit_condition = game.json_to_table(dest_behavior_copy.circuit_condition)

    if destination_behavior.circuit_stack_control_signal then
        destination_behavior.circuit_stack_control_signal = game.json_to_table(dest_behavior_copy.circuit_stack_control_signal)
    end

    storage_functions.purge_copy_event_data(player_index)
    inserter_functions.enforce_max_range(destination, game.players[player_index].force)
    gui.update_all(destination)
end

local function on_pre_entity_settings_pasted(event)
    if not (inserter_functions.is_inserter(event.source) and inserter_functions.is_inserter(event.destination)) then
        return
    end

    local player_index = event.player_index
    local player_storage = global.SI_Storage[player_index]
    local source_arm = inserter_functions.get_arm_positions(event.source)
    local destination_arm = inserter_functions.get_arm_positions(event.destination)
    storage_functions.ensure_data(player_index)
    local copy_settings = player_storage.copy_settings
    local copy_event = player_storage.copy_event

    -- Basic
    local drop = copy_settings.drop and source_arm.drop or destination_arm.drop
    local drop_offset = copy_settings.drop_offset and source_arm.pure_drop_offset or destination_arm.pure_drop_offset
    local pickup = copy_settings.pickup and source_arm.pickup or destination_arm.pickup
    local pickup_offset = copy_settings.pickup_offset and source_arm.pure_pickup_offset or destination_arm.pure_pickup_offset

    copy_event.si_direction = copy_settings.si_direction and event.source.direction or event.destination.direction

    if copy_settings.si_direction or copy_settings.relative_si_direction then
        drop = inserter_functions.calc_rotated_position(event.source, drop, event.destination.direction)
        pickup = inserter_functions.calc_rotated_position(event.source, pickup, event.destination.direction)
        drop_offset = inserter_functions.calc_rotated_offset(event.source, event.destination.direction, "drop")
        pickup_offset = inserter_functions.calc_rotated_offset(event.source, event.destination.direction, "pickup")
        drop_offset = math2d.position.add(math2d.position.multiply_scalar(drop_offset, 0.2), { 0.5, 0.5 })
        pickup_offset = math2d.position.add(math2d.position.multiply_scalar(pickup_offset, 0.2), { 0.5, 0.5 })
    end

    local new_drop = math2d.position.add(drop, drop_offset)
    local new_pickup = math2d.position.add(pickup, pickup_offset)
    copy_event.drop = math2d.position.add(new_drop, destination_arm.base)
    copy_event.pickup = math2d.position.add(new_pickup, destination_arm.base)

    -- Filter
    if event.destination.inserter_filter_mode and event.source.inserter_filter_mode then
        copy_event.inserter_filter_mode = copy_settings.inserter_filter_mode and event.source.inserter_filter_mode or event.destination.inserter_filter_mode
    elseif event.destination.inserter_filter_mode then
        copy_event.inserter_filter_mode = event.destination.inserter_filter_mode
    end
    
    if event.destination.inserter_filter_mode then
        for i = 1, 5, 1 do
            local filtered_slot = copy_event.filtered_slots[i]
            if copy_settings.filtered_stuff and filtered_slot.copy and event.source.filter_slot_count >= i and event.destination.filter_slot_count >= i then
                filtered_slot.item = event.source.get_filter(i)
            elseif event.destination.filter_slot_count >= i then
                filtered_slot.item = event.destination.get_filter(i)
            else
                filtered_slot.item = ""
            end
        end
    end

    if event.destination.inserter_stack_size_override and event.source.inserter_stack_size_override then
        copy_event.inserter_stack_size_override = copy_settings.inserter_stack_size_override and
                                                    event.source.inserter_stack_size_override or
                                                    event.destination.inserter_stack_size_override
    end

    -- Circuit conditions
    local source_behavior = event.source.get_or_create_control_behavior()
    local destination_behavior = event.destination.get_or_create_control_behavior()

    local function copy_circuit_settings(setting)
        if copy_settings[setting] then
            destination_behavior[setting] = source_behavior[setting]
        end
    end

    copy_circuit_settings("circuit_set_stack_size")
    copy_circuit_settings("circuit_read_hand_contents")
    copy_circuit_settings("circuit_mode_of_operation")
    copy_circuit_settings("circuit_hand_read_mode")
    copy_circuit_settings("circuit_condition")

    if destination_behavior.circuit_stack_control_signal and source_behavior.circuit_stack_control_signal and copy_settings.circuit_stack_control_signal then
        destination_behavior.circuit_stack_control_signal = source_behavior.circuit_stack_control_signal
    end

    copy_event.destination_behavior.circuit_set_stack_size = destination_behavior.circuit_set_stack_size
    copy_event.destination_behavior.circuit_read_hand_contents = destination_behavior.circuit_read_hand_contents
    copy_event.destination_behavior.circuit_mode_of_operation = destination_behavior.circuit_mode_of_operation
    copy_event.destination_behavior.circuit_hand_read_mode = destination_behavior.circuit_hand_read_mode
    copy_event.destination_behavior.circuit_condition = game.table_to_json(destination_behavior.circuit_condition)

    if destination_behavior.circuit_stack_control_signal then
        copy_event.destination_behavior.circuit_stack_control_signal = game.table_to_json(destination_behavior.circuit_stack_control_signal)
    end    
end


local function on_player_rotated_entity(event)
    if event.entity.type == "inserter" then
        gui.update_all(event.entity)
        world_editor.update_all_positions(event.entity)
    end
end

-- Hotkey Events
local function on_rotation_adjust(event)
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

        while not tech.check_diagonal_tech(player.force, new_tile) do
            new_direction = (new_direction + direction) % (8 * range)
            new_tile = math2d.direction.to_vector(new_direction, range)
        end

        if math2d.position.equal(new_tile, arm_positions[check]) then
            new_direction = (new_direction + direction) % (8 * range)
            new_tile = math2d.direction.to_vector(new_direction, range)
            while not tech.check_diagonal_tech(player.force, new_tile) do
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

        local target = is_drop and "drop" or "pickup"
        local check = is_drop and "pickup" or "drop"

        local arm_positions = inserter_functions.get_arm_positions(inserter)

        local range = math.max(math.abs(arm_positions[target].x), math.abs(arm_positions[target].y))
        local max_range = inserter_functions.get_max_range(inserter, player.force)
        local dir = math2d.direction.downscale_to_vec1(arm_positions[target], range)

        local new_range = (range % max_range) + 1

        local new_positions = {}

        local pos = math2d.direction.upscale_vec1(dir, new_range)

        new_positions[target] = math2d.direction.to_vector(pos, new_range)

        if not tech.check_range_tech(player.force, new_positions[target]) then
            pos = math2d.direction.upscale_vec1(dir, 1)
            new_positions[target] = math2d.direction.to_vector(pos, 1)
        end

        if new_positions[target].x == arm_positions[check].x and new_positions[target].y == arm_positions[check].y then
            new_range = (range % max_range) + 1
            pos = math2d.direction.upscale_vec1(dir, new_range)
            new_positions[target] = math2d.direction.to_vector(pos, new_range)
        end

        inserter_functions.set_arm_positions(inserter, new_positions)
        gui.update_all(inserter)
    end
end

--Cleaned
local function on_offset_adjust(event)
    local player = game.get_player(event.player_index)
    if player and inserter_functions.is_inserter(player.selected) then
        local inserter = player.selected

        if not tech.check_offset_tech(player.force) then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.required-technology-missing" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local arm_positions = inserter_functions.get_arm_positions(inserter)
        local target = string.find(event.input_name, "drop", 17) and "drop" or "pickup"
        local offset = arm_positions[target .. "_offset"]

        -- -3 because we need to check only the last 3 character to distinguish between vertical and horizontal ("cal" / "tal")
        -- We also could check the third letter from the end but for some reason I dont trust that (IDK just me)
        if string.find(event.input_name, "cal", -3) then -- only vertical
            --[[
                -- This work but I want it to alternat only between -1 and 1
                offset.x = offset.x + 1
                if offset.x > 1 then
                    offset.x = -1
                end
            --]]
            if offset.y == 1 then
                offset.y = -1
            else
                offset.y = 1
            end
        elseif string.find(event.input_name, "tal", -3) then -- only orizontal
            if offset.x == 1 then
                offset.x = -1
            else
                offset.x = 1
            end
        else -- distance (vertical and horizontal)
            -- should move the offset in the direction of the inserter
            -- to recupe the strange behavior of slim inserter not changing line the first time you need to handle slim inserter direction
            local target_range = math.max(math.abs(arm_positions[target].x), math.abs(arm_positions[target].y))
            local arm_dir = math2d.direction.downscale_to_vec1(arm_positions[target], target_range)
            local offset_dir = math2d.direction.from_vector(offset)
            local slim = inserter_functions.is_slim(inserter)
            if not arm_dir then
                arm_dir = inserter.direction
            else
                -- because downscale_to_vec1 start at 1 while from_vector at 0
                arm_dir = arm_dir - 1
            end
            if offset_dir == arm_dir then
                if not slim then
                    offset_dir = (arm_dir + 4) % 8
                else
                    offset = { x = 0, y = 0 }
                    goto skip_offset_assignment
                end
            else
                offset_dir = arm_dir
            end
            offset = math2d.direction.to_vector(offset_dir)
            ::skip_offset_assignment::
        end

        --[[
        -- old code
        local dir = math2d.direction.from_vector(arm_positions[target])
        dir = dir % 2 == 0 and dir or 0
        local axis = (dir % 4 == 0 ~= (action == 2)) and "y" or "x"
        local new_offset = arm_positions[target .. "_offset"]
        new_offset[axis] = arm_positions[target .. "_offset"][axis] * -1

        if new_offset[axis] == 0 then new_offset[axis] = 1 end
        --]]

        inserter_functions.set_arm_positions(inserter, { [target .. "_offset"] = offset })
        gui.update_all(inserter)
    end
end

local function on_in_world_editor(event)
    local player = game.players[event.player_index]
    local is_drop = string.find(event.input_name, "drop", 31) and "drop" or "pickup"
    local storage = global.SI_Storage[event.player_index]
    storage_functions.ensure_data(event.player_index)
    if player.cursor_stack.is_blueprint then
        local is_drop_changer = (player.cursor_stack.name == "si-in-world-drop-changer")
        local is_pickup_changer = (player.cursor_stack.name == "si-in-world-pickup-changer")
        if is_drop_changer and is_drop == "pickup" then
            player_functions.safely_change_cursor(player, "si-in-world-pickup-changer")
            player_functions.configure_pickup_drop_changer(player, is_drop)
            local inserter = player.surface.find_entity(storage.selected_inserter.name, storage.selected_inserter.position)
            local inserter_ghost = player.surface.find_entity("entity-ghost", storage.selected_inserter.position)
            inserter = inserter and inserter or inserter_ghost
            if inserter_functions.is_slim(inserter) then
                world_editor.clear_positions(event.player_index)
                world_editor.draw_positions(event.player_index, inserter, is_drop)
            end
            return
        elseif is_drop_changer and is_drop == "drop" then
            storage["is_selected"] = false
            player_functions.safely_change_cursor(player)
            world_editor.clear_positions(event.player_index)
            return
        elseif is_pickup_changer and is_drop == "drop" then
            player_functions.safely_change_cursor(player, "si-in-world-drop-changer")
            player_functions.configure_pickup_drop_changer(player, is_drop)
            local inserter = player.surface.find_entity(storage.selected_inserter.name, storage.selected_inserter.position)
            local inserter_ghost = player.surface.find_entity("entity-ghost", storage.selected_inserter.position)
            inserter = inserter and inserter or inserter_ghost
            if inserter_functions.is_slim(inserter) then
                world_editor.clear_positions(event.player_index)
                world_editor.draw_positions(event.player_index, inserter, is_drop)
            end
            return
        elseif is_pickup_changer and is_drop == "pickup" then
            storage["is_selected"] = false
            player_functions.safely_change_cursor(player)
            world_editor.clear_positions(event.player_index)
            return
        end
    end
    if player.selected and inserter_functions.is_inserter(player.selected) and player.selected.position and util.check_blacklist(player.selected) then
        local size = inserter_functions.get_inserter_size(player.selected)
        --[[
            if size <= 0 then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = player.selected.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-slim-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end
        --]]
        if size >= 2 then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = player.selected.position,
                text = { "flying-text-smart-inserters.no-hotkey-on-big-inserter" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local arm_positions = inserter_functions.get_arm_positions(player.selected)
        storage.is_selected = true
        storage.selected_inserter.name = player.selected.name
        storage.selected_inserter.surface = player.selected.surface
        storage.selected_inserter.position = math2d.position.ensure_xy(player.selected.position)
        storage.selected_inserter.drop = arm_positions.drop
        storage.selected_inserter.pickup = arm_positions.pickup
        world_editor.draw_positions(event.player_index, player.selected, is_drop)
        player_functions.safely_change_cursor(player, "si-in-world-" .. is_drop .. "-changer")
        player_functions.configure_pickup_drop_changer(player, is_drop)
    end
end

-- World editor events
local function on_built_entity(event)
    local entity = event.created_entity and event.created_entity or event.entity
    if entity.name ~= "entity-ghost" then return end
    if entity.ghost_name ~= "si-in-world-drop-entity" and entity.ghost_name ~= "si-in-world-pickup-entity" then
        return
    end

    local player = game.players[event.player_index]
    local storage = storage_functions.ensure_data(event.player_index)

    local is_drop = string.find(entity.ghost_name, "drop", 11) and "drop" or "pickup"
    local is_pickup = (is_drop == "drop") and "pickup" or "drop"
    local position = entity.position
    if storage.is_selected == false then
        ---@diagnostic disable-next-line: missing-fields
        player.surface.create_entity({
            name = "flying-text",
            position = position,
            text = { "flying-text-smart-inserters.no-inserter-selected" },
            color = { 0.8, 0.8, 0.8 }
        })
        world_editor.clear_positions(event.player_index)
        entity.destroy()
        return
    end

    -- Inserter Data
    local inserter = player.surface.find_entity(storage.selected_inserter.name, storage.selected_inserter.position)
    local inserter_ghost = player.surface.find_entity("entity-ghost", storage.selected_inserter.position)
    inserter = inserter and inserter or inserter_ghost
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    local slim = inserter_functions.is_slim(inserter)
    local vertical = (inserter.direction==0 or inserter.direction==4)
    local orizontal = (inserter.direction==2 or inserter.direction==6)

    local diff = math2d.position.subtract(storage.selected_inserter.position, position)
    diff = math2d.ceil(diff)
    diff = math2d.position.multiply_scalar(diff, -1)

    if math2d.position.equal(arm_positions[is_drop], diff) then
        entity.destroy()
        return
    end

    if not slim and math2d.position.equal(diff, { 0, 0 }) then
        ---@diagnostic disable-next-line: missing-fields
        player.surface.create_entity({
            name = "flying-text",
            position = position,
            text = { "flying-text-smart-inserters.invalid-position" },
            color = { 0.8, 0.8, 0.8 }
        })
        entity.destroy()
        return
    end

    local max_range = inserter_functions.get_max_range(inserter, player.force)
    if slim then
        if vertical and diff.y >= 0 then     -- parte bassa / lower half
            max_range = max_range - 1
        elseif orizontal and diff.x >= 0 then -- parte destra / right
            max_range = max_range - 1
        end
    end
    local range = math.max(math.abs(diff.x), math.abs(diff.y))
    if range <= max_range then
        if util.should_cell_be_enabled(diff, max_range, player.force, inserter, vertical, orizontal, slim) then
            local set = {}
            local changes = {}
            if math2d.position.equal(arm_positions[is_pickup], diff) then
                arm_positions[is_drop] = math2d.position.no_minus_0(arm_positions[is_drop])
                arm_positions[is_pickup] = math2d.position.no_minus_0(arm_positions[is_pickup])
                set[is_drop] = arm_positions[is_pickup]
                changes[is_drop] = {
                    old = {
                        x = arm_positions[is_drop].x,
                        y = arm_positions[is_drop].y
                    },
                    new = {
                        x = arm_positions[is_pickup].x,
                        y = arm_positions[is_pickup].y
                    }
                }
                set[is_pickup] = arm_positions[is_drop]
                changes[is_pickup] = {
                    old = {
                        x = arm_positions[is_pickup].x,
                        y = arm_positions[is_pickup].y
                    },
                    new = {
                        x = arm_positions[is_drop].x,
                        y = arm_positions[is_drop].y
                    }
                }
            else
                diff = math2d.position.no_minus_0(diff)
                arm_positions[is_drop] = math2d.position.no_minus_0(arm_positions[is_drop])
                set[is_drop] = diff
                changes[is_drop] = {
                    old = {
                        x = arm_positions[is_drop].x,
                        y = arm_positions[is_drop].y
                    },
                    new = {
                        x = diff.x,
                        y = diff.y
                    }
                }
            end

            if set["drop"] then
                set["drop_offset"] = { x = 0, y = 0 }
                --Set the drop offset to the farthest side
                --[
                if changes["drop"].new.x < 0 then
                    set.drop_offset.x = -1
                elseif changes["drop"].new.x > 0 then
                    set.drop_offset.x = 1
                end

                if changes["drop"].new.y < 0 then
                    set.drop_offset.y = -1
                elseif changes["drop"].new.y > 0 then
                    set.drop_offset.y = 1
                end
            end

            if slim then
                if set.drop then
                    if vertical and set.drop.y >= 0 then     -- parte bassa / lower half
                        changes.drop.new.y = set.drop.y
                        set.drop.y = set.drop.y + 1
                    elseif orizontal and set.drop.x >= 0 then -- parte destra / right
                        changes.drop.new.x = set.drop.x
                        set.drop.x = set.drop.x + 1
                    end
                    if vertical and changes.drop.old.y >= 0 then     -- parte bassa / lower half
                        changes.drop.old.y = changes.drop.old.y
                    elseif orizontal and changes.drop.old.x >= 0 then -- parte destra / right
                        changes.drop.old.x = changes.drop.old.x
                    end
                end
                if set.pickup then
                    if vertical and set.pickup.y >= 0 then     -- parte bassa / lower half
                        changes.pickup.new.y = set.pickup.y
                        set.pickup.y = set.pickup.y + 1
                    elseif orizontal and set.pickup.x >= 0 then -- parte destra / right
                        changes.pickup.new.x = set.pickup.x
                        set.pickup.x = set.pickup.x + 1
                    end
                    if vertical and changes.pickup.old.y >= 0 then     -- parte bassa / lower half
                        changes.pickup.old.y = changes.pickup.old.y
                    elseif orizontal and changes.pickup.old.x >= 0 then -- parte destra / right
                        changes.pickup.old.x = changes.pickup.old.x
                    end
                end
            end
            if gui.validate_button_placement(inserter, set) then
                inserter_functions.set_arm_positions(inserter, set)
                --world_editor.update_positions(event.player_index, inserter, changes)
                world_editor.update_all_positions(inserter, is_drop)
                gui.update(player, inserter)
            else
                ---@diagnostic disable-next-line: missing-fields
                player.surface.create_entity({
                    name = "flying-text",
                    position = position,
                    text = { "flying-text-smart-inserters.invalid-position" },
                    color = { 0.8, 0.8, 0.8 }
                })
            end
        else
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = position,
                text = { "flying-text-smart-inserters.required-technology-missing" },
                color = { 0.8, 0.8, 0.8 }
            })
        end
    else
        ---@diagnostic disable-next-line: missing-fields
        player.surface.create_entity({
            name = "flying-text",
            position = position,
            text = { "flying-text-smart-inserters.out-of-range" },
            color = { 0.8, 0.8, 0.8 }
        })
    end
    entity.destroy()
end

local function on_player_cursor_stack_changed(event)
    local player = game.players[event.player_index]
    if player.cursor_stack.is_blueprint then
        local is_drop_changer = (player.cursor_stack.name == "si-in-world-drop-changer")
        local is_pickup_changer = (player.cursor_stack.name == "si-in-world-pickup-changer")
        if is_drop_changer or is_pickup_changer then
            return
        end
    else
        world_editor.clear_positions(event.player_index)
    end
end

local function on_entity_destroyed(event)
    if not inserter_functions.is_inserter(event.entity) then
        return
    end
    for player_index, player in pairs(game.players) do
        storage_functions.ensure_data(player_index)
        if global.SI_Storage[player_index].is_selected == true and math2d.position.equal(global.SI_Storage[player_index].selected_inserter.position, event.entity.position) then
            world_editor.clear_positions(player_index)
            player_functions.safely_change_cursor(player)
        end
    end
end










-- ------------------------------
-- Event Handlers
-- ------------------------------

local function on_gui_opened(event)
    local player = game.get_player(event.player_index)
    if player and event.entity and inserter_functions.is_inserter(event.entity) then
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

    if event.old_drop ~= nil then
        local button = event.old_drop.x.."_"..event.old_drop.y
        gui_helper.find_element_recursive(player.gui.relative.smart_inserters, button).sprite = ""
    end

    if event.old_pickup ~= nil then
        local button = event.old_pickup.x.."_"..event.old_pickup.y
        gui_helper.find_element_recursive(player.gui.relative.smart_inserters, button).sprite = ""
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

    selector_gui.update(event)
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

--[[
script.on_event(defines.events.on_player_rotated_entity, on_player_rotated_entity)
script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)
script.on_event(defines.events.on_pre_entity_settings_pasted, on_pre_entity_settings_pasted)
]]

-- Shortcut events
--[[
script.on_event("smart-inserters-drop-rotate", on_rotation_adjust)
script.on_event("smart-inserters-drop-rotate-reverse", on_rotation_adjust)
script.on_event("smart-inserters-pickup-rotate", on_rotation_adjust)
script.on_event("smart-inserters-pickup-rotate-reverse", on_rotation_adjust)
script.on_event("smart-inserters-pickup-distance-adjust", on_distance_adjust)
script.on_event("smart-inserters-drop-distance-adjust", on_distance_adjust)
script.on_event("smart-inserters-drop-offset-adjust-horizontal", on_offset_adjust)
script.on_event("smart-inserters-drop-offset-adjust-vertical", on_offset_adjust)
script.on_event("smart-inserters-drop-offset-adjust-distance", on_offset_adjust)
script.on_event("smart-inserters-pickup-offset-adjust-horizontal", on_offset_adjust)
script.on_event("smart-inserters-pickup-offset-adjust-vertical", on_offset_adjust)
script.on_event("smart-inserters-pickup-offset-adjust-distance", on_offset_adjust)
--]]

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

-- TODO optimize cell check (DOING) (KINDA DONE~)
-- Store technolgy instead of checking each time (TODO)
-- migarte game.players to game.get_player when possible
-- store valid cell positions (maybe)
-- in-world selector for slim inserter
-- in world selector for 2x2 inserter
-- compatibility with renai trasportation
-- compatibility with ghost entity