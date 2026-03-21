local const = require("swap_rail_layer.constants")
local table = require("__flib__.table")
local math = require("__flib__.math")
local util = require("__core__.lualib.util")

solver = {}
-- TODO: explain what is going on here
-- TODO: handle the fact that ramps can provide support

solver.get_support_point_connections = function(entities)

    -- first we have to get the direct connections, so then we can traverse through them
    local direct_connections = {}
    local n = #entities
    for i, entity in pairs(entities) do
        -- each connection on the same rail entity is always directly connected to the other one
        direct_connections[i] = {i + n}
        direct_connections[i + n] = {i}
        for j, other_entity in pairs(entities) do
            if i ~= j then
                for k, support_point_def in pairs(const.support_points[entity.name][entity.direction]) do
                    for _, connection_def in pairs(support_point_def.connects_to) do
                        if
                            other_entity.name == connection_def.name
                            and other_entity.direction == connection_def.direction
                            and entity.position.x + support_point_def.offset.x == other_entity.position.x + const.support_points[connection_def.name][connection_def.direction][connection_def.location].offset.x
                            and entity.position.y + support_point_def.offset.y == other_entity.position.y + const.support_points[connection_def.name][connection_def.direction][connection_def.location].offset.y
                        then
                            if k == "top" then
                                if connection_def.location == "top" then table.insert(direct_connections[i], j)
                                elseif connection_def.location == "bottom" then table.insert(direct_connections[i], j + n)
                                end
                            elseif k == "bottom" then
                                if connection_def.location == "top" then table.insert(direct_connections[i + n], j)
                                elseif connection_def.location == "bottom" then table.insert(direct_connections[i + n], j + n)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- now get all connections that can be traversed to from each connection within rail support distance
    local connections = {}
    for i, entity in pairs(entities) do
        for j, location in pairs({"top", "bottom"}) do
            local index = i + ((j - 1) * n)
            connections[index] = {}
            local pos = {x = entity.position.x + const.support_points[entity.name][entity.direction][location].offset.x, y = entity.position.y + const.support_points[entity.name][entity.direction][location].offset.y}
            
            local already_visited = {}
            local function traverse_recursive(connection_point_index, came_from_other_end_of_same_rail)
                if table.find(already_visited, connection_point_index) then return end -- TODO: use points as keys so can O(1) lookup
                table.insert(already_visited, connection_point_index)
                
                local other_entity = entities[((connection_point_index - 1) % n) + 1]
                local other_pos1 = {x = other_entity.position.x + const.support_points[other_entity.name][other_entity.direction].top.offset.x, y = other_entity.position.y + const.support_points[other_entity.name][other_entity.direction].top.offset.y}
                local other_pos2 = {x = other_entity.position.x + const.support_points[other_entity.name][other_entity.direction].bottom.offset.x, y = other_entity.position.y + const.support_points[other_entity.name][other_entity.direction].bottom.offset.y}
                if
                -- kinda just guessing (based on trial and error) that the support has to be within distance of *both* support points *and* the entity position
                -- TODO: not hardcoded 11's
                    util.distance(pos, other_pos1) > 11
                    or util.distance(pos, other_entity.position) > 11
                    or util.distance(pos, other_pos2) > 11
                then return end

                table.insert(connections[index], connection_point_index)
                local points_to_check
                if came_from_other_end_of_same_rail then 
                    -- can check everything
                    points_to_check = direct_connections[connection_point_index]
                else
                    -- can only check the other point on the rail
                    points_to_check = {((connection_point_index + n - 1) % (2 * n)) + 1}
                end
                for _, connected_index in pairs(points_to_check) do
                    traverse_recursive(connected_index, math.abs(connection_point_index - connected_index) == n)
                end
            end
            traverse_recursive(index, true)
        end
    end

    return connections
end

local function solve_supports(entities, connections)
    -- TODO: need to not make supports that collide with each other
    local supports = {}
    local n = #entities
    local original_connections = table.deep_copy(connections) -- since we will be modifying connections

    local need_to_add_support = true
    while need_to_add_support do
        -- get most impactful point
        local index
        local max = -1
        for i, conns in pairs(connections) do
            local _n = table_size(conns) -- not guaranteed to be a contiguous array, so can't use #
            if _n > max then
                index = i
                max = _n
            end
        end
        if max <= 0 then need_to_add_support = false end

        if need_to_add_support then
            -- add a rail support to this point
            local location = index <= n and "top" or "bottom"
            local entity = entities[((index - 1) % n) + 1]
            table.insert(supports, {
                name = "rail-support",
                position = {
                    x = entity.position.x + const.support_points[entity.name][entity.direction][location].offset.x,
                    y = entity.position.y + const.support_points[entity.name][entity.direction][location].offset.y,
                },
                direction = const.support_points[entity.name][entity.direction][location].direction,

                point = index,
                supported_points = original_connections[index],
            })

            -- remove this point and all connected points from consideration
            for _, connected_point in pairs(connections[index]) do
                for i, conns in pairs(connections) do
                    if i ~= index then -- don't modify connections[index] since we are iterating over that
                        local index_to_remove = table.find(conns, connected_point)
                        if index_to_remove then table.remove(conns, index_to_remove) end
                    end
                end
            end
            connections[index] = {}
        end
    end

    -- remove redundant supports
    local function get_first_redundant_support()
        for i, support in pairs(supports) do
            local redundant = true
            for _, supported_point in pairs(support.supported_points) do
                local this_point_is_supported_elsewhere = false
                for j, other_support in pairs(supports) do
                    if i ~= j and table.find(other_support.supported_points, supported_point) then
                        this_point_is_supported_elsewhere = true
                    end
                end
                if not this_point_is_supported_elsewhere then redundant = false end
            end
            if redundant then return i end
        end
    end
    repeat
        local redundant_index = get_first_redundant_support()
        if redundant_index then table.remove(supports, redundant_index) end
    until not redundant_index

    return supports
end

solver.filter_entities = function(entities)
    local supportable_entities = {}
    for _, entity in pairs(entities) do
        if entity.name:find("^elevated") or entity.name == "rail-ramp" then
            table.insert(supportable_entities, {
                name = entity.name,
                position = entity.position,
                direction = entity.direction or defines.direction.north,
            })
        end
    end
    return supportable_entities
end

solver.get_support_entities = function(entities)
    local supportable_entities = solver.filter_entities(entities)
    local connections = solver.get_support_point_connections(supportable_entities)
    local supports = solve_supports(supportable_entities, connections)

    local max_entity_number = -1
    for _, entity in pairs(entities) do
        if entity.entity_number > max_entity_number then max_entity_number = entity.entity_number end
    end
    for i, support in pairs(supports) do
        support.entity_number = max_entity_number + i
    end

    return supports, false -- TODO: report error
end

return solver
