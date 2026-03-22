local data_util = require("__flib__.data-util")

data:extend({
    {
        type = "custom-input",
        name = "swap_rail_layer_linked",
        key_sequence = "",
        linked_game_control = "toggle-rail-layer",
    },
})

if settings.startup["swap_rail_layer_debug"].value then
    data:extend({
        {
            type = "selection-tool",
            name = "swap_rail_layer_debug_selection_tool",
            draw_label_for_cursor_render = true,

            select = {
                border_color = {1, 1, 1},
                cursor_box_type = "copy",
                mode = {"any-entity"},
                entity_type_filters = {
                    "elevated-straight-rail",
                    "elevated-half-diagonal-rail",
                    "elevated-curved-rail-a",
                    "elevated-curved-rail-b",
                    "rail-ramp",
                },
            },
            alt_select = {
                border_color = {1, 1, 1},
                cursor_box_type = "copy",
                mode = {"any-entity"},
                entity_type_filters = {
                    "elevated-straight-rail",
                    "elevated-half-diagonal-rail",
                    "elevated-curved-rail-a",
                    "elevated-curved-rail-b",
                    "rail-ramp",
                },
            },

            hidden = true,
            flags = {"not-stackable", "only-in-cursor", "spawnable"},
            stack_size = 1,
            icons = {
                {
                    icon = data_util.black_image,
                    icon_size = 1,
                },
            },
        },
        {
            type = "custom-input",
            name = "swap_rail_layer_spawn_debug_selection_tool",
            key_sequence = "SHIFT + G",
            action = "spawn-item",
            item_to_spawn = "swap_rail_layer_debug_selection_tool",
        },
    })
end
