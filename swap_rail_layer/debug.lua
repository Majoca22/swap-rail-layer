local const = require("swap_rail_layer.constants")
local main = require("swap_rail_layer.main")
local solver = require("swap_rail_layer.support_solver")
local sp = solver.sp
local math = require("__flib__.math")
local table = require("__flib__.table")
local bounding_box = require("__flib__.bounding-box")

local debug = {}
local test_surface_name = "srl-tests"

debug.create_test_surface = function()
    ---@diagnostic disable-next-line missing-field
    local surface = game.create_surface(test_surface_name, {
        autoplace_controls = {},
        default_enable_all_autoplace_controls = false,
        seed = 1,
        width = 0,
        height = 0,
        peaceful_mode = true,
        no_enemies_mode = true,
    })
    surface.request_to_generate_chunks({0, 0}, 10)
    surface.force_generate_chunk_requests()
end

local function elevated_draw_position(position, offset)
    offset = offset or {x = 0, y = 0}
    -- visually, elevated rails look like they are 3 tiles higher than where their position really is
    return {
        x = position.x + offset.x,
        y = position.y + offset.y - 3,
    }
end

---@param e EventData.on_player_selected_area
debug.handle_debug_selection = function(e)
    local entities = {}
    for _, entity in pairs(e.entities) do
        table.insert(entities, {
            name = entity.name == "entity-ghost" and entity.ghost_name or entity.name,
            position = entity.position,
            direction = entity.direction,
        })
    end
    local rails, ramps = solver.filter_entities(entities)

    log("----------------------------------------------------------------------------------")
    local connections, supported_by_ramp = solver.get_support_point_connections(rails, ramps)
    for i, conns in pairs(connections) do
        table.sort(conns)
        log(i .. ": " .. serpent.line(conns))
    end
    log("supported by ramp: " .. serpent.line(supported_by_ramp))

    local points = {}
    local n = #rails
    for i, rail in pairs(rails) do
        for _, location in pairs(const.locations) do
            table.insert(points, {
                index = sp.index_from_rail(i, location, n),
                location = location,
                position = sp.position(rail, location),
                rail_position = rail.position,
            })
        end
    end

    for _, point in pairs(points) do
        local color = point.location == const.locations.top and {1, 1, 1} or {0, 1, 1}
        local text_offset = {x = 0, y = point.location == const.locations.top and -0.5 or 0.5}
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

---@param entities LuaEntity[] | BlueprintEntity[]
---@return BoundingBox
local function get_bounds(entities)
    if not entities then return {{0, 0}, {0, 0}} end
    local bounds
    for i, entity in pairs(entities) do
        local pos = entity.position
        local box
        if entity.name == "rail-ramp" then
            if entity.direction == defines.direction.north or entity.direction == defines.direction.south then
                box = {{pos.x - 2, pos.y - 8}, {pos.x + 2, pos.y + 8}}
            else
                box = {{pos.x - 8, pos.y - 2}, {pos.x + 8, pos.y + 2}}
            end
        else
            box = {{pos.x - 4, pos.y - 4}, {pos.x + 4, pos.y + 4}}
        end

        if i == 1 then
            bounds = box
        else
            bounds = bounding_box.expand_to_contain_box(bounds, box)
        end
    end
    -- add some final padding
    return bounding_box.resize(bounds, 2)
end

local function encode_test_string(blueprint_entities)
    -- blueprint entities can be positioned basically anywhere, so adjust them so they are roughly centered around {0, 0}
    local bounds = get_bounds(blueprint_entities)
    local center = {
        x = (bounds[1][1] + bounds[2][1]) / 2,
        y = (bounds[1][2] + bounds[2][2]) / 2,
    }

    local entities = {}
    for _, bp_entity in pairs(blueprint_entities) do
        local e = table.deep_copy(bp_entity)
        e.position = {
            -- move in increments of 2 to respect rail grid
            x = e.position.x - math.round(center.x, 2),
            y = e.position.y - math.round(center.y, 2),
        }
        table.insert(entities, e)
    end

    return helpers.encode_string(helpers.table_to_json(entities))
end

local function decode_test_string(str)
    local decoded = helpers.decode_string(str)
    if not decoded then return end
    local entities = helpers.json_to_table(decoded)
    if not entities then return end
    local bounds = get_bounds(entities --[[@as BlueprintEntity[] ]])
    return entities, bounds
end

local TEST_STRINGS = {
    "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",
}

local function run_test(player, test_string, map_position, surface)
    local entities, bounds = decode_test_string(test_string)
    if not entities or type(entities) ~= "table" or not next(entities) or not bounds then return end
    local horizontal_offset = (bounds[2][1] - bounds[1][1] + 4) / 2 -- get the width of the blurpint, so we know how to put the input and output side-by-side
    local vertical_offset = (bounds[2][2] - bounds[1][2] + 4) / 2 -- get the height of the blurpint, so we know how to put this test below the previous one
    -- move in increments of 2 to respect rail grid
    bounds = bounding_box.move(bounds, {math.round(map_position.x - horizontal_offset, 2), math.round(map_position.y + vertical_offset, 2)})
    for _, entity in pairs(entities) do
        surface.create_entity({
            name = entity.name,
            position = {
                -- move in increments of 2 to respect rail grid
                x = entity.position.x + math.round(map_position.x - horizontal_offset, 2),
                y = entity.position.y + math.round(map_position.y + vertical_offset, 2),
            },
            direction = entity.direction,
            force = game.forces["player"],
            create_build_effect_smoke = false,
            rail_layer = entity.rail_layer or nil,
        })
    end
    rendering.draw_rectangle({
        color = {0, 0, 0},
        width = 4,
        left_top = bounds[1],
        right_bottom = bounds[2],
        surface = surface,
    })
    player.get_main_inventory().insert("blueprint")
    local bp = player.get_main_inventory().find_item_stack("blueprint")
    bp.create_blueprint({
        surface = surface,
        force = player.force,
        area = bounds,
    })
    local new_entities, err = main.swap_rail_layer(bp.get_blueprint_entities())
    if not err then
        bp.set_blueprint_entities(new_entities)
        bp.build_blueprint({
            surface = surface,
            force = player.force,
            position = {
                -- move in increments of 2 to respect rail grid
                x = map_position.x + math.round(horizontal_offset, 2),
                y = map_position.y + math.round(vertical_offset, 2),
            },
        })
    else
        player.print("Error when running test - see log for details", {skip = defines.print_skip.never})
        log(serpent.block(err))
    end
    return bounds
end

local function run_all_tests(player)
    player.teleport({0, 0}, test_surface_name)
    local position = {x = 0, y = 0}
    for _, s in pairs(TEST_STRINGS) do
        local bounds = run_test(player, s, position, game.surfaces[test_surface_name])
        position.y = position.y + ((bounds[2][2] - bounds[1][2])) + 4
    end
    local inv = player.get_main_inventory()
    inv.insert({name = "rail", count = 2000})
    inv.insert({name = "rail-ramp", count = 2000})
    inv.insert({name = "rail-support", count = 2000})
    inv.insert({name = "rail-signal", count = 100})
    inv.insert({name = "rail-chain-signal", count = 100})
end

---@param player LuaPlayer
---@param cmd string
debug.run_command = function(player, cmd)
    if cmd == "clear-all-rendering" then
        rendering.clear(script.mod_name)

    elseif cmd == "cursor-to-test-string" then
        if player.is_cursor_blueprint() and player.cursor_stack and player.cursor_stack.valid_for_read then
            local entities = player.cursor_stack.get_blueprint_entities()
            if entities then
                log(encode_test_string(entities))
                player.print("Test string logged")
            end
        end

    elseif cmd == "run-all-tests" then
        -- building blueprints doesn't work unless the chunks are generated
        -- we can request them to be generated via script but it seems a lot slower than just having the player run around
        -- not sure what the best solution is but for now this is fine
        if not game.surfaces[test_surface_name].is_chunk_generated({0, 10}) then
            player.print("Wait until test surface chunks have been generated - run around to generate them faster", {print_skip = defines.print_skip.never})
        else
            run_all_tests(player)
        end

    elseif cmd == "clear-test-surface" then
        game.surfaces[test_surface_name].clear(true)
        for _, render_object in pairs(rendering.get_all_objects(script.mod_name)) do
            if render_object.surface.name == test_surface_name then render_object.destroy() end
        end
    end
end

return debug
