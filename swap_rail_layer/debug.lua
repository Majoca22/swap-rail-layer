local const = require("swap_rail_layer.constants")
local solver = require("swap_rail_layer.support_solver")

commands.add_command("srl-debug", "",
    function(c)
        if settings.startup.swap_rail_layer_debug.value then
            if c.parameter == "clear-all-rendering" then
                rendering.clear(script.mod_name)
            end
        end
    end
)

script.on_event(defines.events.on_player_selected_area,
    function(e)
        if not e.item == "swap_rail_layer_debug_selection_tool" or not settings.startup.swap_rail_layer_debug.value then return end

        local entities = {}
        for _, entity in pairs(e.entities) do
            table.insert(entities, {
                name = entity.name == "entity-ghost" and entity.ghost_name or entity.name,
                position = entity.position,
                direction = entity.direction,
            })
        end
        entities = solver.filter_entities(entities)
        local points = {top = {}, bottom = {}}
        local n = #entities

        log("----------------------------------------------------------------------------------")
        local connections = solver.get_support_point_connections(entities)
        for i, conns in pairs(connections) do
            table.sort(conns)
            log(i .. ": " .. serpent.line(conns))
        end

        for i, entity in pairs(entities) do
            for j, location in pairs({"top", "bottom"}) do
                table.insert(points[location], {
                    index = i + ((j - 1) * n),
                    position = {
                        x = entity.position.x + const.support_points[entity.name][entity.direction][location].offset.x,
                        y = entity.position.y + const.support_points[entity.name][entity.direction][location].offset.y,
                    },
                    entity_position = entity.position,
                })
            end
        end

        for _, point in pairs(points.top) do
            rendering.draw_line({
                color = {1, 1, 1},
                width = 2,
                from = {x = point.position.x, y = point.position.y - 3 - 0.5},
                to = {x = point.entity_position.x, y = point.entity_position.y - 3},
                surface = e.surface,
            })
            rendering.draw_text({
                text = point.index,
                surface = e.surface,
                target = {x = point.position.x, y = point.position.y - 3 - 0.5},
                color = {1, 1, 1},
                scale = 2,
                alignment = "center",
                vertical_alignment = "middle",
            })
        end
        for _, point in pairs(points.bottom) do
            rendering.draw_line({
                color = {0, 1, 1},
                width = 2,
                from = {x = point.position.x, y = point.position.y - 3 + 0.5},
                to = {x = point.entity_position.x, y = point.entity_position.y - 3},
                surface = e.surface,
            })
            rendering.draw_text({
                text = point.index,
                surface = e.surface,
                target = {x = point.position.x, y = point.position.y - 3 + 0.5},
                color = {0, 1, 1},
                scale = 2,
                alignment = "center",
                vertical_alignment = "middle",
            })
        end
        for _, entity in pairs(entities) do
            rendering.draw_circle({
                color = {1, 0, 0},
                radius = 0.15,
                filled = true,
                target = {x = entity.position.x, y = entity.position.y - 3},
                surface = e.surface,
            })
        end
    end
)
