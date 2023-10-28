data:extend({
    {
        type          = "int-setting",
        setting_type  = "startup",
        name          = "si-max-inserters-range",
        minimum_value = 1,
        maximum_value = 5,
        default_value = 3,
        order         = "a"
    },
    {
        type           = "string-setting",
        setting_type   = "startup",
        name           = "si-range-adder",
        default_value  = "equal",
        allowed_values = { "inserter", "incremental", "equal" },
        order          = "ba"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-offset-selector",
        default_value = true,
        order         = "bb"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-inserters-chase-belt-items",
        default_value = true,
        order         = "ca"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-range-technologies",
        default_value = false,
        order         = "cb"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-diagonal-technologies",
        default_value = false,
        order         = "cc"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-offset-technologies",
        default_value = false,
        order         = "cd"
    },
    {
        type           = "string-setting",
        setting_type   = "startup",
        name           = "si-technologies-difficulty",
        default_value  = "normal",
        allowed_values = { "normal", "hard" },
        order          = "ce"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-disable-long-inserters",
        default_value = true,
        order         = "d"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-directional-slim-inserter",
        default_value = true,
        order         = "ea"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-single-line-slim-inserter",
        default_value = true,
        order         = "eb"
    }
})
