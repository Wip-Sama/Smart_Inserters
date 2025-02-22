data:extend({
    {
        type          = "int-setting",
        setting_type  = "startup",
        name          = "si-max-inserters-range",
        minimum_value = 1,
        maximum_value = 6,
        default_value = 3,
        order         = "aa"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-single-line-inserters",
        default_value = false,
        order         = "ab"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-directional-inserters",
        default_value = false,
        order         = "ac"
    },
    {
        type           = "string-setting",
        setting_type   = "startup",
        name           = "si-range-adder",
        default_value  = "equal",
        allowed_values = { "inserter", "incremental", "equal", "rebase", "incremental-with-rebase", "inserter-with-rebase" },
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
        default_value = false,
        order         = "da"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-disable-inserters-consumption",
        default_value = false,
        order         = "db"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-single-line-slim-inserters",
        default_value = true,
        order         = "dc"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-directional-slim-inserters",
        default_value = true,
        order         = "dd"
    },
    {
        type          = "bool-setting",
        setting_type  = "startup",
        name          = "si-high-contrast-sprites",
        default_value = true,
        order         = "e"
    },
})
