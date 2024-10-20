local events = {}

if script then
    events.on_inserter_arm_changed = script.generate_event_name()
    remote.add_interface("Smart_Inserters", {
        on_inserter_arm_changed = function()
            return events.on_inserter_arm_changed
        end
    })
end

return events