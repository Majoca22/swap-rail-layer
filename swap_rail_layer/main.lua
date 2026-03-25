local const = require("swap_rail_layer.constants")
local solver = require("swap_rail_layer.support_solver")
local errors = require("swap_rail_layer.errors")
local collision = require("swap_rail_layer.collision")
local direction = require("__flib__.direction")
local table = require("__flib__.table")
local bounding_box = require("__flib__.bounding-box")

local main = {}

main.get_cursor_blueprint = function(player)
    if player.is_cursor_blueprint() then
        local bp
        if player.cursor_stack and player.cursor_stack.valid_for_read then
            bp = player.cursor_stack
        elseif player.cursor_record then
            if player.cursor_record.type == "blueprint" then
                bp = player.cursor_record
            elseif player.cursor_record.type == "blueprint-book" then
                bp = player.cursor_record.contents[player.cursor_record.get_active_index(player)]
            else
                return
            end
            if not bp.valid_for_write then
                return bp, {type = errors.cannot_write_to_blueprint}
            elseif not settings.get_player_settings(player).swap_rail_layer_overwrite_blueprints.value then
                return bp, {type = errors.blueprint_overwrite_is_disabled}
            end
        end
        return bp, nil
    end
end

main.swap_rail_layer = function(entities)
    local new_entities = table.deep_copy(entities)
    local is_rail_blueprint = false -- only makes sense to swap if there is at least one rail or ramp
    -- keep track of "normal" entity collision boxes, so we know if we're going to drop an elevated rail on top of them (or later, to avoid placing a support there)
    -- rails and supports have slightly different collision masks, so track them separately
    local new_rail_entities = {}
    local rail_mask_collision_boxes = {}
    local support_mask_collision_boxes = {}

    for i, entity in pairs(new_entities) do
        -- error if there are any train stops as these cannot be elevated
        if entity.name == "train-stop" then
            return entities, {type = errors.train_stop_in_blueprint}

        -- hotswap ground and elevated rails
        elseif const.hotswap_map[entity.name] then
            is_rail_blueprint = true
            entity.name = const.hotswap_map[entity.name]
            table.insert(new_rail_entities, entity)

        -- reverse ramps
        elseif entity.name == "rail-ramp" then
            is_rail_blueprint = true
            entity.direction = direction.opposite(entity.direction or defines.direction.north)

        -- change layer of signals
        elseif entity.name == "rail-signal" or entity.name == "rail-chain-signal" then
            entity.rail_layer = const.layer_map[entity.rail_layer or "ground"]

        -- remove rail supports
        -- keep them in the table so `new_entities` stays as an array, we'll fully remove them later
        elseif entity.name == "rail-support" then
            new_entities[i].to_delete = true ---@diagnostic disable-line: inject-field

        -- log non-rail-related collision box, if it would collide with a new ground rail or rail support
        else
            local bb = bounding_box.move(prototypes.entity[entity.name].collision_box, entity.position)
            if collision.mask_collides_with_rail(entity) then table.insert(rail_mask_collision_boxes, bb) end
            if collision.mask_collides_with_support(entity) then table.insert(support_mask_collision_boxes, bb) end
        end
    end

    if not is_rail_blueprint then
        return entities, {type = errors.is_not_rail_blueprint}
    end

    -- error if we would drop an elevated rail on top of another entity
    for _, rail in pairs(new_rail_entities) do
        if not rail.name:find("^elevated-") then
            for _, box in pairs(rail_mask_collision_boxes) do
                if collision.rail_collides_with_box(rail, box) then
                    return entities, {type = errors.entity_under_elevated_rail}
                end
            end
        end
    end

    -- add rail supports
    local supports, err = solver.get_support_entities(new_entities)
    if not err then
        new_entities = table.array_merge({new_entities, supports})

        for i, t in pairs(new_entities) do
            if t.to_delete then new_entities[i] = nil end
        end

        return new_entities, err
    else
        return entities, err
    end

end

return main
