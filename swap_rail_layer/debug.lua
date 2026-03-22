local const = require("swap_rail_layer.constants")
local main = require("swap_rail_layer.main")
local solver = require("swap_rail_layer.support_solver")
local sp = solver.sp
local math = require("__flib__.math")
local table = require("__flib__.table")

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

local function get_bounds(entities)
    local bounds = {x = {}, y = {}}
    for _, entity in pairs(entities) do
        local position = entity.position

        -- x min
        if not bounds.x.min then bounds.x.min = position.x
        else bounds.x.min = math.min(bounds.x.min, position.x) end

        -- x max
        if not bounds.x.max then bounds.x.max = position.x
        else bounds.x.max = math.max(bounds.x.max, position.x) end

        -- y min
        if not bounds.y.min then bounds.y.min = position.y
        else bounds.y.min = math.min(bounds.y.min, position.y) end

        -- y max
        if not bounds.y.max then bounds.y.max = position.y
        else bounds.y.max = math.max(bounds.y.max, position.y) end
    end
    return bounds
end

local function encode_test_string(blueprint_entities)
    -- blueprint entities can be positioned basically anywhere, so adjust them so they are roughly centered around {0, 0}
    local bounds = get_bounds(blueprint_entities)
    local median = {
        x = (bounds.x.min + bounds.x.max) / 2,
        y = (bounds.y.min + bounds.y.max) / 2,
    }

    local entities = {}
    for _, bp_entity in pairs(blueprint_entities) do
        local e = table.deep_copy(bp_entity)
        e.position = {
            -- move in increments of 2 to respect rail grid
            x = e.position.x - math.round(median.x, 2),
            y = e.position.y - math.round(median.y, 2),
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
    local bounds = get_bounds(entities)
    return entities, {width = bounds.x.max - bounds.x.min, height = bounds.y.max - bounds.y.min}
end

local TEST_STRINGS = {
    "eNqN00EKwjAQBdC7zDqFpomx5ioikrZBAzaVNBVLyd0tFtwY8a9mMfD4mZkcF7I+ujif/dQ3NpDmjLzpLWkaYzDuco3FWm7E6D6MLrrBk17oSbqoGc1rEYlR54Jtt55M7MusYFPBpoBNCZsSNivY3KFmCZPqQ7ZTeNjuDRYmE5NnTZUx92hM/OU1SuILOqAkfke8zE6z+RmT/x8m56i5/SGR0ukFrjwrBQ==",
    "eNqVl8lqw0AQRP9lzjKoZ9H2KyEE2RaJIJaDLIcY43+PEy+HpI1en+YgeNSou6qkp6PrhqmfDi/DfrPsRtdI5oZ207nG7aax7V/fpsX5eHeZ+9ju+qnfDq45ui/XLCRl7nA+61Pm1v3YrS4P4yn7B/UcGjA0cKhgaMTQGjPTnbnaj5/d+pe4aBVmpTILhVlgnSXWWWImn3yFmXzwNR88ZkpOoQYm9hK/u2Ar8RkJdhLfJYl06fWdF69BExXKzSnYSYYUEWwlQ94J9pIhmaVW57R8bNByPpx8TqE6Ux2+tzdTAM1kryZCDTjyf4yiUNXXGs2NR7Qma+URqLmfCNRcUARqbigCNVcUgAbsqgdQzVVBjL1HhHoq9M7UKMHYnkRZNLYnYSZjexJmYSw6wiytRUeglbXoCLS2Fh2AxpxG8oNEVkspCvbkdVIyn/MR+0dn6koDVnp5qaopI/6su6aln4+giP+PbkgNUtDr3W43r6s0NkNShVW2GNMhtVFKqVFSbpOiQ8QopVYp3rhHlUoxVoQuJdrWr/q7Oc/fPwWsEQ==",
    "eNqdlt1uglAQhN/lXEPDnh/g8CqmaVBJS1KxQWxqjO9eUiM2kWl3uJIL82V2mJ1ldTZNN7TD6aU77tZNbypJTFfvGlOZw9DX7evbkI4/7yYxH/tDO7T7zlRn82WqtHgKiTmNDzI+XRKzbftmc/1DfkkewFYNDhM4aMBODRaZyE5D9mqy48BBC75bYUfuDCnXkn7NDlCFeto4oUQzbal/QRw48jZm87NLtsBHxFqwQlEzrqhXKOO4jvaxBKN73kaECnxfqHpI1CtjOW5Bu5iD0UveRYSKfIWpStdm9LR+XqJVr4vnFFreRSTR8Q2mugPW0y6C8rbqdck5hQsODJJY0PWlugK2pE0EzW3v27I59p/N9oeTrh9J8R+SW3BPEEq0om4bLABkWZ8QyNHDIRKdfwdAgZaESDkrKQBQQUtCpHI2AfUfJFBkjv5iKuZBPtNKuoHAgfJCu4Qk0fGOAMTHG5HoeAtYFM/nG6LogAtYFc8nHKLoDhewLD7yogAq0N84ArIZ+JRfUc/fF28KVA==",
}

local function run_test(player, test_string, map_position, surface)
    local entities, size = decode_test_string(test_string)
    if not entities or type(entities) ~= "table" or not next(entities) or not size then return end
    for _, entity in pairs(entities) do
        surface.create_entity({
            name = entity.name,
            position = {
                -- move in increments of 2 to respect rail grid
                x = entity.position.x + math.round(map_position.x - (size.width / 2 + 8), 2),
                y = entity.position.y + math.round(map_position.y, 2),
            },
            direction = entity.direction,
            force = game.forces["player"],
            create_build_effect_smoke = false,
            rail_layer = entity.rail_layer or nil,
        })
    end
    local bb = {
        -- move in increments of 2 to respect rail grid
        left_top = {
            x = map_position.x - math.round((size.width / 2 + 8), 2) - (size.width / 2) - 4,
            y = map_position.y - (size.height / 2) - 4,
        },
        right_bottom = {
            x = map_position.x - math.round((size.width / 2 + 8), 2) + (size.width / 2) + 4,
            y = map_position.y + (size.height / 2) + 4,
        },
    }
    rendering.draw_rectangle({
        color = {0, 0, 0},
        width = 4,
        left_top = bb.left_top,
        right_bottom = bb.right_bottom,
        surface = surface,
    })
    player.get_main_inventory().insert("blueprint")
    local bp = player.get_main_inventory().find_item_stack("blueprint")
    bp.create_blueprint({
        surface = surface,
        force = player.force,
        area = bb,
    })
    local new_entities, err = main.swap_rail_layer(bp.get_blueprint_entities())
    if not err then
        bp.set_blueprint_entities(new_entities)
        bp.build_blueprint({
            surface = surface,
            force = player.force,
            position = {
                -- move in increments of 2 to respect rail grid
                x = map_position.x + math.round((size.width / 2 + 8), 2),
                y = map_position.y,
            },
        })
    else
        player.print("Error when running test - see log for details", {skip = defines.print_skip.never})
        log(serpent.block(err))
    end
    return size.height
end

local function run_all_tests(player)
    player.teleport({0, 0}, test_surface_name)
    local position = {x = 0, y = 0}
    for _, s in pairs(TEST_STRINGS) do
        local height = run_test(player, s, position, game.surfaces[test_surface_name])
        position.y = position.y + height + 16
    end
    local inv = player.get_main_inventory()
    inv.insert({name = "rail", count = 2000})
    inv.insert({name = "rail-ramp", count = 2000})
    inv.insert({name = "rail-support", count = 2000})
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
        run_all_tests(player)
    end
end

return debug
