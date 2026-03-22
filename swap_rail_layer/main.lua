local const = require("swap_rail_layer.constants")
local solver = require("swap_rail_layer.support_solver")
local errors = require("swap_rail_layer.errors")
local direction = require("__flib__.direction")
local table = require("__flib__.table")

local main = {}

main.swap_rail_layer = function(entities)
    local new_entities = table.deep_copy(entities)
    local is_rail_blueprint = false -- only makes sense to swap if there is at least one rail or ramp

    for i, entity in pairs(new_entities) do
        -- error if there are any train stops as these cannot be elevated
        if entity.name == "train-stop" then
            return entities, {type = errors.train_stop_in_blueprint}
        end

        -- hotswap ground and elevated rails
        local new_entity = const.hotswap_map[entity.name]
        if new_entity then
            is_rail_blueprint = true
            entity.name = new_entity
        end

        -- reverse ramps
        if entity.name == "rail-ramp" then
            is_rail_blueprint = true
            entity.direction = direction.opposite(entity.direction or defines.direction.north)
        end

        -- change layer of signals
        if entity.name == "rail-signal" or entity.name == "rail-chain-signal" then
            entity.rail_layer = const.layer_map[entity.rail_layer or "ground"]
        end

        -- remove rail supports
        -- keep them in the table so `entities` stays as an array, we'll fully remove them later
        if entity.name == "rail-support" then new_entities[i].to_delete = true end ---@diagnostic disable-line: inject-field
    end

    if not is_rail_blueprint then
        return entities, {type = errors.is_not_rail_blueprint}
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
