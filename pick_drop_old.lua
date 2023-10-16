function gui.create_pick_offset(flow_offset)
    local table_range = inserters_range
    -- Start pickup offset part
    local flow_pickup = flow_offset.add({
        type = "flow",
        name = "flow_pickup",
        direction = "vertical"
    })

    -- Pickup offset label
    flow_pickup.add({
        type = "label",
        name = "label_pick_offset",
        caption = { "gui-inserter-config.pick-offset" },
        style = "heading_2_label"
    })

    -- Pickup offset grid
    local table_pick = flow_pickup.add({
        type = "table",
        name = "table_pick",
        column_count = 3
    })
    table_pick.style.horizontal_spacing = 1
    table_pick.style.vertical_spacing = 1

    for y = 1, 3, 1 do
        for x = 1, 3, 1 do
            local button_name = "button_pick_offset_" ..
                tostring(x + table_range + 1) .. "_" .. tostring(y + table_range + 1)
            local button = table_pick.add({
                type = "sprite-button",
                name = button_name,
                style = "slot_sized_button"
            })
            button.style.size = { 32, 32 }
        end
    end
end

function gui.create_drop_offset(flow_offset)
    local table_range = inserters_range
    local flow_drop = flow_offset.add({
        type = "flow",
        name = "flow_drop",
        direction = "vertical"
    })

    flow_drop.add({
        type = "label",
        name = "label_offset",
        caption = { "gui-inserter-config.drop-offset" },
        style = "heading_2_label"
    })

    local table_drop = flow_drop.add({
        type = "table",
        name = "table_drop",
        column_count = 3
    })
    table_drop.style.horizontal_spacing = 1
    table_drop.style.vertical_spacing = 1

    for y = 1, 3, 1 do
        for x = 1, 3, 1 do
            local button_name = "button_drop_offset_" ..
                tostring(x + table_range + 1) .. "_" .. tostring(y + table_range + 1)
            local button = table_drop.add({
                type = "sprite-button",
                name = button_name,
                style = "slot_sized_button"
            })
            button.style.size = { 32, 32 }
        end
    end
end
