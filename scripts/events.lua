local events = {}

if script then
    events.on_inserter_arm_changed = script.generate_event_name()
end

return events