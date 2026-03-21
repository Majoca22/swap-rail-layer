local const = require("swap_rail_layer.constants")
local solver = require("swap_rail_layer.support_solver")
local direction = require("__flib__.direction")
local table = require("__flib__.table")

script.on_event("swap_rail_layer_linked",
    ---@param e EventData.CustomInputEvent
    function(e)
        -- TODO: can't work with stations in the blueprint
        -- TODO: will have to error if there's something beneath an existing elevated rail
        local player = game.get_player(e.player_index)
        if not player then return end

        if player.is_cursor_blueprint() and player.cursor_stack and player.cursor_stack.valid_for_read then
            local entities = player.cursor_stack.get_blueprint_entities()
            if not entities then return end

            for i, entity in pairs(entities) do
                -- hotswap ground and elevated rails
                local new_entity = const.hotswap_map[entity.name]
                if new_entity then entity.name = new_entity end

                -- reverse ramps
                if entity.name == "rail-ramp" then
                    entity.direction = direction.opposite(entity.direction or defines.direction.north)
                end

                -- change layer of signals
                if entity.name == "rail-signal" or entity.name == "rail-chain-signal" then
                    entity.rail_layer = const.layer_map[entity.rail_layer or "ground"]
                end

                -- remove rail supports
                -- keep them in the table so `entities` stays as an array, we'll fully remove them later
                if entity.name == "rail-support" then entities[i].to_delete = true end ---@diagnostic disable-line: inject-field
            end

            -- add rail supports
            local supports, err = solver.get_support_entities(entities)
            if not err then
                entities = table.array_merge({entities, supports})

                for i, t in pairs(entities) do
                    if t.to_delete then entities[i] = nil end
                end

                player.cursor_stack.set_blueprint_entities(entities)
                player.create_local_flying_text({
                    text = { "rail-layer-switched" },
                    create_at_cursor = true,
                })
            else
                -- TODO: do something with the error
            end
        end
    end
)
