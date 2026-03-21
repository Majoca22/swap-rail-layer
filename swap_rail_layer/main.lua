local const = require("swap_rail_layer.constants")
local solver = require("swap_rail_layer.support_solver")
local direction = require("__flib__.direction")
local table = require("__flib__.table")

local main = {}

main.swap_rail_layer = function(entities)
    entities = table.deep_copy(entities)

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
    end

    return entities, err
end

return main
