local solver = require("swap_rail_layer.support_solver")
local sp = solver.sp

commands.add_command("srl-debug", "",
    function(c)
        if settings.startup.swap_rail_layer_debug.value then
            if c.parameter == "clear-all-rendering" then
                rendering.clear(script.mod_name)
            end
        end
    end
)

local function elevated_draw_position(position, offset)
    offset = offset or {x = 0, y = 0}
    -- visually, elevated rails look like they are 3 tiles higher than where their position really is
    return {
        x = position.x + offset.x,
        y = position.y + offset.y - 3,
    }
end

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
        local rails = solver.filter_entities(entities)

        log("----------------------------------------------------------------------------------")
        local connections = solver.get_support_point_connections(rails)
        for i, conns in pairs(connections) do
            table.sort(conns)
            log(i .. ": " .. serpent.line(conns))
        end

        local points = {}
        local n = #rails
        for i, rail in pairs(rails) do
            for _, location in pairs({"top", "bottom"}) do
                table.insert(points, {
                    index = sp.index_from_rail(i, location, n),
                    location = location,
                    position = sp.position(rail, location),
                    rail_position = rail.position,
                })
            end
        end

        for _, point in pairs(points) do
            local color = point.location == "top" and {1, 1, 1} or {0, 1, 1}
            local text_offset = {x = 0, y = point.location == "top" and -0.5 or 0.5}
            rendering.draw_line({
                color = color,
                width = 2,
                from = elevated_draw_position(point.position, text_offset),
                to = elevated_draw_position(point.rail_position),
                surface = e.surface,
            })
            rendering.draw_text({
                text = point.index,
                surface = e.surface,
                target = elevated_draw_position(point.position, text_offset),
                color = color,
                scale = 2,
                alignment = "center",
                vertical_alignment = "middle",
            })
        end
        for _, rail in pairs(rails) do
            rendering.draw_circle({
                color = {1, 0, 0},
                radius = 0.15,
                filled = true,
                target = elevated_draw_position(rail.position),
                surface = e.surface,
            })
        end
    end
)
