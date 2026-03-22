local main = require("swap_rail_layer.main")
local debug = require("swap_rail_layer.debug")

-- ---------------------
-- MAIN
-- ---------------------

script.on_event("swap_rail_layer_linked",
    ---@param e EventData.CustomInputEvent
    function(e)
        -- TODO: will have to error if there's something beneath an existing elevated rail
        local player = game.get_player(e.player_index)
        if not player then return end

        if player.is_cursor_blueprint() and player.cursor_stack and player.cursor_stack.valid_for_read then
            local entities = player.cursor_stack.get_blueprint_entities()
            if not entities then return end

            local new_entities, err = main.swap_rail_layer(entities)
            if not err then
                player.cursor_stack.set_blueprint_entities(new_entities)
                player.create_local_flying_text({
                    text = { "rail-layer-switched" },
                    create_at_cursor = true,
                })
            else
                player.play_sound({path = "utility/cannot_build"})
                player.create_local_flying_text({
                    text = { "swap-rail-layer-error." .. err.type },
                    create_at_cursor = true,
                })
            end
        end
    end
)

-- ---------------------
-- DEBUG
-- ---------------------

script.on_init(
    function()
        if settings.startup.swap_rail_layer_debug.value then
            debug.create_test_surface()
        end
    end
)

script.on_event(defines.events.on_player_selected_area,
    function(e)
        if e.item == "swap_rail_layer_debug_selection_tool" and settings.startup.swap_rail_layer_debug.value then
            debug.handle_debug_selection(e)
        end
    end
)

commands.add_command("srl-debug", "",
    function(c)
        local player = game.get_player(c.player_index)
        if not player then return end

        if settings.startup.swap_rail_layer_debug.value then
            debug.run_command(player, c.parameter)
        else
            player.print("Debug mode not enabled")
        end
    end
)
