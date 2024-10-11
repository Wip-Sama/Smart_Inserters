-- ------------------------------
-- Dependencies
-- ------------------------------
local events = require("scripts.events")
local math2d = require("__yafla__/scripts/extended_math2d")

-- ------------------------------
-- Functions Group
-- ------------------------------
local technology_functions = require("scripts.technology_functions")
local selector_gui = require("scripts.selector_gui")
local inserter_functions = require("scripts.inserter_functions")
local util = require("__core__/lualib/util")
local player_functions = require("scripts.player_functions")
local world_editor = require("scripts.world_selector")
local storage_functions = require("scripts.storage_functions")
local si_util = require("scripts.si_util")

-- ------------------------------
-- Settings
-- ------------------------------
local offset_selector = settings.startup["si-offset-selector"].value
local directional_slim_inserter = settings.startup["si-directional-slim-inserter"].value

-- ------------------------------
-- Event Handlers
-- ------------------------------

local function on_init()
    global.SI_Storage = global.SI_Storage or {}
    storage_functions.populate_storage()
    technology_functions.migrate_all()
end

local function welcome()
    game.print({ "smart-inserters.welcome" })
    --game.print({ "smart-inserters.experimental" })
end

local function on_configuration_changed(event)
    global.SI_Storage = global.SI_Storage or {}
    storage_functions.populate_storage()
    technology_functions.migrate_all()
    --game.print({ "smart-inserters.experimental" })
end

local function on_player_created(event)
    storage_functions.add_player(game.get_player(event.player_index))
end

local function on_research_finished(event)
    --technology_functions.generate_Tech_lookup_table(event.research.force)
end

local function on_research_reversed(event)
    --technology_functions.generate_Tech_lookup_table(event.research.force)
end

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
    selector_gui.update_all(event.entity, event)
    world_editor.update_all(event.entity, event)
end

local function on_player_rotated_entity(event)
    local player = game.get_player(event.player_index)
    if player and event.entity and inserter_functions.is_inserter(event.entity) then
        --Note: it's easier to make factorio calculate the old positions, storing them and setting back the correct direction
        local dir = event.entity.direction
        event.entity.direction = event.previous_direction
        local old_res = inserter_functions.get_arm_positions(event.entity)
        event.entity.direction = dir

        --local res = inserter_functions.get_arm_positions(event.entity)
        --inserter_functions.set_arm_positions(res, event.entity)

        script.raise_event(events.on_inserter_arm_changed, {
            entity = event.entity,
            old_drop = old_res.drop,
            old_pickup = old_res.pickup,
            old_drop_offset = old_res.drop_offset,
            old_pickup_offset = old_res.pickup_offset,
        })
    end
end

local function on_entity_settings_pasted(event)
    local player = game.get_player(event.player_index)
    if player and inserter_functions.is_inserter(event.source) and inserter_functions.is_inserter(event.destination) then
        -- local dir = event.entity.direction
        -- event.entity.direction = event.previous_direction
        -- local old_res = inserter_functions.get_arm_positions(event.entity)
        -- event.entity.direction = dir

        --local res = inserter_functions.get_arm_positions(event.destination)
        --inserter_functions.set_arm_positions(res, event.destination)
        --Verificare che gli inserter hanno la stessa base, se no adattare x e y
        ---- x/y se in base ignora, se fuori base [[  avvicina alla base/riporta allo 0  ]]
        --Verificare se le posizioni sono valide per entrambi gli inserter
        ---- Se non sono valide: [[  resettare/  lasciare le vecchie/  adattarle  ]] (una di queste)
        script.raise_event(events.on_inserter_arm_changed, {
            entity = event.entity,
        })
    end
end

local function on_pre_entity_settings_pasted(event)
    local player = game.get_player(event.player_index)
    if player and inserter_functions.is_inserter(event.source) and inserter_functions.is_inserter(event.destination) then
        local old_res = inserter_functions.get_arm_positions(event.destination)

        --Verificare che gli inserter hanno la stessa base, se no adattare x e y
        ---- x/y se in base ignora, se fuori base [[  avvicina alla base/riporta allo 0  ]]
        --Verificare se le posizioni sono valide per entrambi gli inserter
        ---- Se non sono valide: [[  resettare/  lasciare le vecchie/  adattarle  ]] (una di queste)
        script.raise_event(events.on_inserter_arm_changed, {
            entity = event.destination,
            old_drop = old_res.drop,
            old_pickup = old_res.pickup,
            old_drop_offset = old_res.drop_offset,
            old_pickup_offset = old_res.pickup_offset,
            do_not_popolate = true
        })
    end
end

local function on_rotation_adjust(event)
    local player = game.get_player(event.player_index)
    assert(player, "[control.lua:on_rotation_adjust] Player is nil")
    local inserter = player.selected

    if inserter_functions.is_inserter(inserter) then
        assert(inserter, "[control.lua:on_rotation_adjust] Inserter is nil")
        if technology_functions.get_diagonal_increment(inserter.force) < 1 then
            ---@diagnostic disable-next-line: missing-fields
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.required-technology-missing", "technology-name.si-unlock-cross" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local width, height = inserter.tile_width, inserter.tile_height

        local lower_width = width % 2 == 0 and width / 2 or width / 2 - 0.5
        local higher_width = width % 2 == 0 and width / 2 or width / 2 + 0.5

        local lower_height = height % 2 == 0 and height / 2 or height / 2 - 0.5
        local higher_height = height % 2 == 0 and height / 2 or height / 2 + 0.5

        ---@type Position
        local move = { x = 0, y = 0 }

        local arms = inserter_functions.get_arm_positions(inserter)
        local update = string.find(event.input_name, "d", 17, true) == 17 and "drop" or "pickup"
        local direction = string.find(event.input_name, "s", #event.input_name - 1, true) == #event.input_name - 1 and -1 or
            1
        local position = util.copy(arms[update])
        local radius
        ---@type Position
        local absolute_position

        if arms[update .. "_direction"] == defines.direction.northeast then
            position.x = position.x - higher_width + 1
            position.y = position.y + lower_height
            absolute_position = math2d.position.abs(position)
            radius = math.max(absolute_position.x, absolute_position.y)
            if absolute_position.x == absolute_position.y then
                if direction == 1 then
                    move.y = 1
                else
                    move.x = -1
                end
            else
                if math.abs(position.x) < radius then
                    if direction == 1 then
                        move.x = 1
                    else
                        move.x = -1
                    end
                else
                    if direction == 1 then
                        move.y = 1
                    else
                        move.y = -1
                    end
                end
            end
        elseif arms[update .. "_direction"] == defines.direction.east then
            position.y = 0
            position.x = position.x - higher_width + 1
            if direction == 1 then
                move.y = 1
            else
                move.y = -1
            end
        elseif arms[update .. "_direction"] == defines.direction.southeast then
            position.x = position.x - higher_width + 1
            position.y = position.y - higher_height + 1
            absolute_position = math2d.position.abs(position)
            radius = math.max(absolute_position.x, absolute_position.y)
            if absolute_position.x == absolute_position.y then
                if direction == 1 then
                    move.x = -1
                else
                    move.y = -1
                end
            else
                if math.abs(position.x) < radius then
                    if direction == 1 then
                        move.x = -1
                    else
                        move.x = 1
                    end
                else
                    if direction == 1 then
                        move.y = 1
                    else
                        move.y = -1
                    end
                end
            end
        elseif arms[update .. "_direction"] == defines.direction.south then
            position.x = 0
            position.y = position.y - higher_height + 1
            if direction == 1 then
                move.x = -1
            else
                move.x = 1
            end
        elseif arms[update .. "_direction"] == defines.direction.southwest then
            position.x = position.x + lower_width
            position.y = position.y - higher_height + 1
            absolute_position = math2d.position.abs(position)
            radius = math.max(absolute_position.x, absolute_position.y)
            if absolute_position.x == absolute_position.y then
                if direction == 1 then
                    move.y = -1
                else
                    move.x = 1
                end
            else
                if math.abs(position.x) < radius then
                    if direction == 1 then
                        move.x = -1
                    else
                        move.x = 1
                    end
                else
                    if direction == 1 then
                        move.y = -1
                    else
                        move.y = 1
                    end
                end
            end
        elseif arms[update .. "_direction"] == defines.direction.west then
            position.y = 0
            position.x = position.x + lower_width
            if direction == 1 then
                move.y = -1
            else
                move.y = 1
            end
        elseif arms[update .. "_direction"] == defines.direction.northwest then
            position.x = position.x + lower_width
            position.y = position.y + lower_height
            absolute_position = math2d.position.abs(position)
            radius = math.max(absolute_position.x, absolute_position.y)
            if absolute_position.x == absolute_position.y then
                if direction == 1 then
                    move.x = 1
                else
                    move.y = 1
                end
            else
                if math.abs(position.x) < radius then
                    if direction == 1 then
                        move.x = 1
                    else
                        move.x = -1
                    end
                else
                    if direction == 1 then
                        move.y = -1
                    else
                        move.y = 1
                    end
                end
            end
        elseif arms[update .. "_direction"] == defines.direction.north then
            position.x = 0
            position.y = position.y + lower_height
            if direction == 1 then
                move.x = 1
            else
                move.x = -1
            end
        end

        absolute_position = absolute_position or math2d.position.abs(position)
        radius = radius or math.max(absolute_position.x, absolute_position.y)

        local count = 0
        local shift = { x = move.x, y = move.y }
        while not inserter_functions.should_cell_be_enabled(inserter, { x = arms[update].x + shift.x, y = arms[update].y + shift.y }) do
            shift.x = shift.x + move.x
            shift.y = shift.y + move.y
            count = count + 1

            if radius < math.max(math.abs(position.x + shift.x), math.abs(position.y + shift.y)) then
                shift.x = shift.x - move.x
                shift.y = shift.y - move.y
                move = { x = 0, y = 0 }
                if position.x + shift.x > 0 and position.y + shift.y < 0 then --northeast
                    if math.abs(position.x + shift.x) < radius then
                        if direction == 1 then
                            move.x = 1
                        else
                            move.x = -1
                        end
                    elseif math.abs(position.y + shift.y) < radius then
                        if direction == 1 then
                            move.y = 1
                        else
                            move.y = -1
                        end
                    else
                        if direction == 1 then
                            move.y = 1
                        else
                            move.x = -1
                        end
                    end
                elseif position.x + shift.x > 0 and position.y + shift.y > 0 then --southeast
                    if math.abs(position.x + shift.x) < radius then
                        if direction == 1 then
                            move.x = -1
                        else
                            move.x = 1
                        end
                    elseif math.abs(position.y + shift.y) < radius then
                        if direction == 1 then
                            move.y = 1
                        else
                            move.y = -1
                        end
                    else
                        if direction == 1 then
                            move.x = -1
                        else
                            move.y = -1
                        end
                    end
                elseif position.x + shift.x < 0 and position.y + shift.y > 0 then --southwest
                    if math.abs(position.x + shift.x) < radius then
                        if direction == 1 then
                            move.x = -1
                        else
                            move.x = 1
                        end
                    elseif math.abs(position.y + shift.y) < radius then
                        if direction == 1 then
                            move.y = -1
                        else
                            move.y = 1
                        end
                    else
                        if direction == 1 then
                            move.y = -1
                        else
                            move.x = 1
                        end
                    end
                elseif position.x + shift.x < 0 and position.y + shift.y < 0 then --northwest
                    if math.abs(position.x + shift.x) < radius then
                        if direction == 1 then
                            move.x = -1
                        else
                            move.x = 1
                        end
                    elseif math.abs(position.y + shift.y) < radius then
                        if direction == 1 then
                            move.y = 1
                        else
                            move.y = -1
                        end
                    else
                        if direction == 1 then
                            move.x = 1
                        else
                            move.y = 1
                        end
                    end
                end
            end

            if inserter.tile_height == 0 and position.y + shift.y == 0 then
                if position.y > 0 and shift.y < 0 then
                    position.y = position.y - 1
                elseif position.y < 0 and shift.y > 0 then
                    position.y = position.y + 1
                end
            elseif inserter.tile_width == 0 and position.x + shift.x == 0 then
                if position.x > 0 and shift.x < 0 then
                    position.x = position.x - 1
                elseif position.x < 0 and shift.x > 0 then
                    position.x = position.x + 1
                end
            end

            if count >= 100 then
                print("exited")
                break
            end
        end

        arms[update].x = arms[update].x + shift.x
        arms[update].y = arms[update].y + shift.y
        inserter_functions.set_arm_positions(arms, inserter)
    end
end

local function on_distance_adjust(event)
    local player = game.get_player(event.player_index)
    assert(player, "[control.lua:on_distance_adjust] Player is nil")
    local inserter = player.selected

    if inserter_functions.is_inserter(inserter) then
        assert(inserter, "[control.lua:on_offset_adjust] Inserter is nil")
        ---@diagnostic disable-next-line: param-type-mismatch
        if (technology_functions.get_actual_increment(inserter.force) < 1) or (technology_functions.get_diagonal_increment(inserter.force) < 1) then
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.required-technology-missing", "technology-name.si-unlock-range-1 / technology-name.si-unlock-cross" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end

        local width, height = inserter.tile_width, inserter.tile_height

        local lower_width = width % 2 == 0 and width / 2 or width / 2 - 0.5
        local higher_width = width % 2 == 0 and width / 2 or width / 2 + 0.5

        local lower_height = height % 2 == 0 and height / 2 or height / 2 - 0.5
        local higher_height = height % 2 == 0 and height / 2 or height / 2 + 0.5

        local arms = inserter_functions.get_arm_positions(inserter)
        local update = string.find(event.input_name, "d", 17, true) == 17 and "drop" or "pickup"
        local direction = string.find(event.input_name, "e", #event.input_name, true) == #event.input_name and -1 or 1
        local position = util.copy(arms[update])

        -- I need max range to avoid the position to be outside the range

        local x_changes, y_changes = false, false

        local max_range, min_range = inserter_functions.get_max_and_min_inserter_range(inserter)
        max_range, min_range = math.max(1, max_range), math.max(1, min_range)
        local extreme_positions = {
            min = { x = 0, y = 0 },
            max = { x = 0, y = 0 }
        }

        -- I could add the min here and remove the double check max after this code, but for now it works
        -- -1 is  because the higher height is outside the base
        if arms[update .. "_direction"] == defines.direction.north then
            position.y = position.y - direction
            extreme_positions.max.y = -max_range - lower_height
            extreme_positions.min.y = -min_range - lower_height
            y_changes = true
        elseif arms[update .. "_direction"] == defines.direction.northeast then
            position.x = position.x + direction
            position.y = position.y - direction
            extreme_positions.max.x = max_range + higher_width - 1
            extreme_positions.min.x = min_range + higher_width - 1
            extreme_positions.max.y = -max_range - lower_height
            extreme_positions.min.y = -min_range - lower_height
            x_changes = true
            y_changes = true
        elseif arms[update .. "_direction"] == defines.direction.east then
            position.x = position.x + direction
            extreme_positions.max.x = max_range + higher_width - 1
            extreme_positions.min.x = min_range + higher_width - 1
            x_changes = true
        elseif arms[update .. "_direction"] == defines.direction.southeast then
            position.x = position.x + direction
            position.y = position.y + direction
            extreme_positions.max.x = max_range + higher_width - 1
            extreme_positions.min.x = min_range + higher_width - 1

            extreme_positions.max.y = max_range + higher_height - 1
            extreme_positions.min.y = min_range + higher_height - 1
            x_changes = true
            y_changes = true
        elseif arms[update .. "_direction"] == defines.direction.south then
            position.y = position.y + direction
            extreme_positions.max.y = max_range + higher_height - 1
            extreme_positions.min.y = min_range + higher_height - 1
            y_changes = true
        elseif arms[update .. "_direction"] == defines.direction.southwest then
            position.x = position.x - direction
            position.y = position.y + direction

            extreme_positions.min.x = -min_range - lower_width
            extreme_positions.max.x = -max_range - lower_width

            extreme_positions.max.y = max_range + higher_height - 1
            extreme_positions.min.y = min_range + higher_height - 1

            x_changes = true
            y_changes = true
        elseif arms[update .. "_direction"] == defines.direction.west then
            position.x = position.x - direction
            extreme_positions.max.x = -max_range - lower_width
            extreme_positions.min.x = -min_range - lower_width
            x_changes = true
        elseif arms[update .. "_direction"] == defines.direction.northwest then
            position.x = position.x - direction
            position.y = position.y - direction
            extreme_positions.max.x = -max_range - lower_width
            extreme_positions.min.x = -min_range - lower_width

            extreme_positions.max.y = -max_range - lower_height
            extreme_positions.min.y = -min_range - lower_height
            x_changes = true
            y_changes = true
        end

        if x_changes then
            if position.x < -max_range - lower_width or position.x > max_range + higher_width - 1 then
                position.x = extreme_positions.min.x
            elseif position.x > -min_range - lower_width and position.x < min_range + higher_width - 1 then
                position.x = extreme_positions.max.x
            elseif arms[update .. "_direction"] ~= inserter_functions.calculate_arm_direction(inserter, position) then
                position.x = extreme_positions.max.x
            end
        end

        if y_changes then
            if position.y < -max_range - lower_height or position.y > max_range + higher_height - 1 then
                position.y = extreme_positions.min.y
            elseif position.y > -min_range - lower_height and position.y < min_range + higher_height - 1 then
                position.y = extreme_positions.max.y
            elseif arms[update .. "_direction"] ~= inserter_functions.calculate_arm_direction(inserter, position) then
                position.y = extreme_positions.max.y
            end
        end

        arms[update] = position
        if inserter_functions.should_cell_be_enabled(inserter, arms[update]) then
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
        if not offset_selector then
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.offset-selector-is-disabled" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        elseif not technology_functions.check_offset_tech(inserter.force) then
            player.surface.create_entity({
                name = "flying-text",
                position = inserter.position,
                text = { "flying-text-smart-inserters.required-technology-missing", "technology-name.si-unlock-offsets" },
                color = { 0.8, 0.8, 0.8 }
            })
            return
        end
        assert(inserter, "[control.lua:on_offset_adjust] Inserter is nil")
        local arms = inserter_functions.get_arm_positions(inserter)
        local update = string.find(event.input_name, "d", 17, true) == 17 and "drop" or "pickup"
        local position = util.copy(arms[update .. "_offset"])

        if arms[update .. "_direction"] == defines.direction.north then
            position.y = position.y > 0.5 and 0.25 or 0.75
            position.x = 0.5
        elseif arms[update .. "_direction"] == defines.direction.northeast then
            local x = position.x > 0.5 and 0.25 or 0.75
            local y = x == 0.75 and 0.25 or 0.75
            position.x = x
            position.y = y
        elseif arms[update .. "_direction"] == defines.direction.east then
            position.y = 0.5
            position.x = position.x > 0.5 and 0.25 or 0.75
        elseif arms[update .. "_direction"] == defines.direction.southeast then
            local new = position.x > 0.5 and 0.25 or 0.75
            position.x = new
            position.y = new
        elseif arms[update .. "_direction"] == defines.direction.south then
            position.y = position.y > 0.5 and 0.25 or 0.75
            position.x = 0.5
        elseif arms[update .. "_direction"] == defines.direction.southwest then
            local x = position.x > 0.5 and 0.25 or 0.75
            local y = x == 0.75 and 0.25 or 0.75
            position.x = x
            position.y = y
        elseif arms[update .. "_direction"] == defines.direction.west then
            position.y = 0.5
            position.x = position.x > 0.5 and 0.25 or 0.75
        elseif arms[update .. "_direction"] == defines.direction.northwest then
            local new = position.x > 0.5 and 0.25 or 0.75
            position.x = new
            position.y = new
        end

        old = arms[update .. "_offset"]
        arms[update .. "_offset"] = position
        inserter_functions.set_arm_positions(arms, inserter)
    end
end

-- To check if the player placed an in world selector blueprint
local function on_built_entity(event)
    local entity = event.created_entity and event.created_entity or event.entity
    if entity.name ~= "entity-ghost" or (entity.ghost_name ~= "si-in-world-drop-entity" and entity.ghost_name ~= "si-in-world-pickup-entity") then
        return
    end

    storage_functions.ensure_data(event.player_index)
    local inserter = global.SI_Storage[event.player_index].selected_inserter.inserter
    local update = string.find(entity.ghost_name, "d", 13) == 13 and "drop" or "pickup"
    local arm_positions = inserter_functions.get_arm_positions(inserter)
    arm_positions[update] = math2d.position.subtract(entity.position, inserter.position)
    arm_positions[update].x = arm_positions[update].x - (inserter.tile_width ~= 1 and 0.5 or 0)
    arm_positions[update].y = arm_positions[update].y - (inserter.tile_height ~= 1 and 0.5 or 0)
    local check_directional_slim = true
    if inserter_functions.is_slim(inserter) and directional_slim_inserter then
        if inserter.direction == defines.direction.north then
            if arm_positions[update].y < 0 then
                check_directional_slim = ("pickup" == update)
            else
                check_directional_slim = ("drop" == update)
            end
        elseif inserter.direction == defines.direction.south then
            if arm_positions[update].y < 0 then
                check_directional_slim = ("drop" == update)
            else
                check_directional_slim = ("pickup" == update)
            end
        elseif inserter.direction == defines.direction.east then
            if arm_positions[update].x < 0 then
                check_directional_slim = ("drop" == update)
            else
                check_directional_slim = ("pickup" == update)
            end
        elseif inserter.direction == defines.direction.west then
            if arm_positions[update].x < 0 then
                check_directional_slim = ("pickup" == update)
            else
                check_directional_slim = ("drop" == update)
            end
        end
    end
    if inserter_functions.should_cell_be_enabled(inserter, arm_positions[update]) and check_directional_slim then
        inserter_functions.set_arm_positions(arm_positions, inserter)
    else
        inserter.surface.create_entity({
            name = "flying-text",
            position = inserter.position,
            text = { "flying-text-smart-inserters.invalid-position" },
            color = { 0.8, 0.8, 0.8 }
        })
    end
    entity.destroy()
end

local function on_entity_destroyed(event)
    if not inserter_functions.is_inserter(event.entity) then
        return
    end
    for player_index, player in pairs(game.players) do
        storage_functions.ensure_data(player_index)
        if global.SI_Storage[player_index].is_selected == true and math2d.position.equal(global.SI_Storage[player_index].selected_inserter.position, event.entity.position) then
            --world_editor.clear_positions(player_index)
            player_functions.safely_change_cursor(player)
        end
    end
end

local function on_in_world_editor(event)
    local player = game.get_player(event.player_index)
    local update = string.find(event.input_name, "d", 48) == 48 and "drop" or "pickup"
    storage_functions.ensure_data(event.player_index)
    if player == nil then return end

    if player.cursor_stack.is_blueprint then
        local changing = string.find(player.cursor_stack.name, "d", 13) == 13 and "drop" or "pickup"
        if changing == update then
            player_functions.safely_change_cursor(player)
            world_editor.clear_positions(event.player_index)
            return
        else
            player_functions.safely_change_cursor(player, "si-in-world-"..update.."-changer")
            player_functions.configure_pickup_drop_changer(player, update)
            return
        end
    end

    if player.selected and inserter_functions.is_inserter(player.selected) and player.selected.position and si_util.check_blacklist(player.selected) then
        world_editor.draw_positions(event.player_index, player.selected)
        player_functions.safely_change_cursor(player, "si-in-world-" .. update .. "-changer")
        player_functions.configure_pickup_drop_changer(player, update)
    end
end

-- To check if the player destroyes out blueprint
local function on_player_cursor_stack_changed(event)
    local player = game.get_player(event.player_index)
    if player ~= nil and player.cursor_stack.is_blueprint then
        if player.cursor_stack.name == "si-in-world-drop-changer" or player.cursor_stack.name == "si-in-world-pickup-changer" then
            return
        end
    else
        world_editor.clear_positions(event.player_index)
    end
end

-- ------------------------------
-- Eventhandler registration
-- ------------------------------

-- Player and Init events
script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_player_created, on_player_created)
--[[
script.on_event(defines.events.on_research_finished, on_research_finished)
script.on_event(defines.events.on_research_reversed, on_research_reversed)
]]
script.on_event(defines.events.on_cutscene_cancelled, welcome) --[DONE]
script.on_event(defines.events.on_cutscene_finished, welcome)  --[DONE]


-- Gui events
script.on_event(defines.events.on_gui_opened, on_gui_opened)                                 --[DONE]
script.on_event(defines.events.on_gui_closed, on_gui_closed)                                 --[DONE]
script.on_event(events.on_inserter_arm_changed, on_inserter_arm_changed)                     --[DONE]
script.on_event(defines.events.on_player_rotated_entity, on_player_rotated_entity)           --[PROBABLY INCOMPLETE]
script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)         --[PROBABLY INCOMPLETE]
script.on_event(defines.events.on_pre_entity_settings_pasted, on_pre_entity_settings_pasted) --[PROBABLY INCOMPLETE]


-- Shortcut events
script.on_event("smart-inserters-drop-rotate", on_rotation_adjust)                    --[DONE] [UNTESTED: SLIM DIRECTIONAL/SINGLE LINE INSERTER]
script.on_event("smart-inserters-drop-rotate-reverse", on_rotation_adjust)            --[DONE] [UNTESTED: SLIM DIRECTIONAL/SINGLE LINE INSERTER]
script.on_event("smart-inserters-drop-distance-adjust", on_distance_adjust)           --[DONE]
script.on_event("smart-inserters-drop-distance-adjust-reverse", on_distance_adjust)   --[DONE]
script.on_event("smart-inserters-drop-offset-adjust", on_offset_adjust)               --[DONE]
script.on_event("smart-inserters-pickup-rotate", on_rotation_adjust)                  --[UNTESTED] [UNTESTED: SLIM DIRECTIONAL/SINGLE LINE INSERTER]
script.on_event("smart-inserters-pickup-rotate-reverse", on_rotation_adjust)          --[UNTESTED] [UNTESTED: SLIM DIRECTIONAL/SINGLE LINE INSERTER]
script.on_event("smart-inserters-pickup-distance-adjust", on_distance_adjust)         --[UNTESTED]
script.on_event("smart-inserters-pickup-distance-adjust-reverse", on_distance_adjust) --[UNTESTED]
script.on_event("smart-inserters-pickup-offset-adjust", on_offset_adjust)             --[UNTESTED]


-- World editor events
script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.script_raised_built, on_built_entity)
script.on_event(defines.events.script_raised_destroy, on_entity_destroyed)
script.on_event(defines.events.on_player_mined_entity, on_entity_destroyed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_destroyed)
script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)

script.on_event("smart-inserters-in-world-inserter-configurator-pickup", on_in_world_editor)
script.on_event("smart-inserters-in-world-inserter-configurator-drop", on_in_world_editor)
--[[

--]]
--script.on_event(defines.events.on_entity_died, on_entity_destroyed)
--script.on_event(defines.events.on_entity_destroyed, on_entity_destroyed)


-- TODO: optimize should cell be enabled
-- in-world selector for slim inserter
-- in world selector for 2x2 inserter
-- compatibility with renai trasportation
-- compatibility with ghost entity
