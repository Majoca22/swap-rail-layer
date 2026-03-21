local const = require("swap_rail_layer.constants")
local table = require("__flib__.table")
local math = require("__flib__.math")
local util = require("__core__.lualib.util")

solver = {}
-- TODO: handle the fact that ramps can provide support

---@class ElevatedRailData
---@field name "elevated-straight-rail" | "elevated-half-diagonal-rail" | "elevated-curved-rail-a" | "elevated-curved-rail-b" The entity name of the elevated rail
---@field position MapPosition.0 The position of the elevated rail entity
---@field direction defines.direction The direction of the elevated rail entity

---@class RailSupportData
---@field name "rail-support" The entity name of the rail support
---@field position MapPosition.0 The position of the rail support entity
---@field direction defines.direction The direction of the rail support entity
---@field point SupportPointIndex The index of the support point where this rail support is
---@field supported_points SupportPointIndex[] All support points which are supported by this rail support

---@alias SupportPointIndex integer

---Abstraction layer for handling support point indices and positions.
---In general, for `n` rails, indices `1` to `n` are the top points, and indices `n + 1` to `2n` are the bottom points.
local sp = {}

---Translate a rail entity index and a rail support location into a support point index.
---@param rail_index integer
---@param location SupportPointLocation
---@param num_rails integer
---@return SupportPointIndex
sp.index_from_rail = function(rail_index, location, num_rails)
    return location == "top" and rail_index or rail_index + num_rails
end

---Translate a support point index into a rail entity index.
---@param point_index SupportPointIndex
---@param num_rails integer
---@return integer
sp.rail_index = function(point_index, num_rails)
    return ((point_index - 1) % num_rails) + 1
end

---For a given support point, get the index of the other support point on the same rail entity.
---@param point_index SupportPointIndex
---@param num_rails integer
---@return SupportPointIndex
sp.paired_index = function(point_index, num_rails)
    return ((point_index + num_rails - 1) % (2 * num_rails)) + 1
end

---Determine if two support point indices are paired.
---@param point_index1 SupportPointIndex
---@param point_index2 SupportPointIndex
---@param num_rails integer
---@return boolean
sp.indices_are_paired = function(point_index1, point_index2, num_rails)
    return math.abs(point_index1 - point_index2) == num_rails
end

---Determine the point location from a given support point index.
---@param point_index SupportPointIndex
---@param num_rails integer
---@return SupportPointLocation
sp.location_from_index = function(point_index, num_rails)
    return point_index <= num_rails and "top" or "bottom"
end

---Determine the map position for a support point on a rail.
---@param rail ElevatedRailData
---@param location SupportPointLocation
---@return MapPosition.0
sp.position = function(rail, location)
    return {
        x = rail.position.x + const.support_points[rail.name][rail.direction][location].offset.x,
        y = rail.position.y + const.support_points[rail.name][rail.direction][location].offset.y,
    }
end

---@param rails ElevatedRailData[]
---@return { [SupportPointIndex]: SupportPointIndex[] }
solver.get_support_point_connections = function(rails)
    local n = #rails

    -- first we have to get the direct connections, so then we can traverse through them

    ---Maps support point indices to all other indices that the point is directly connected to
    ---@type { [SupportPointIndex]: SupportPointIndex[] }
    local direct_connections = {}

    for i, rail in pairs(rails) do
        local index_top = sp.index_from_rail(i, "top", n)
        local index_bottom = sp.index_from_rail(i, "bottom", n)

        -- each support point on the same rail entity is always directly connected to the other one
        direct_connections[index_top] = {index_bottom}
        direct_connections[index_bottom] = {index_top}

        -- check all other support rails to see if either support point on *that* rail is connected to either support point on *this* rail
        for j, other_rail in pairs(rails) do
            if i ~= j then
                for location, support_point_def in pairs(const.support_points[rail.name][rail.direction]) do
                    -- location is the support point location on *this* rail
                    for _, connection_def in pairs(support_point_def.connects_to) do
                        -- connection_def.location is the support point location on the *other* rail
                        if
                            -- two support points on different rails "connect" if they are essentially the same support point
                            -- this means that the rails are compatible to be connected (check name and direction in connection definition), AND the support points are at the same map position (check entity position + support point offset)
                            other_rail.name == connection_def.name
                            and other_rail.direction == connection_def.direction
                            and rail.position.x + support_point_def.offset.x == sp.position(other_rail, connection_def.location).x
                            and rail.position.y + support_point_def.offset.y == sp.position(other_rail, connection_def.location).y
                        then
                            if location == "top" then
                                table.insert(direct_connections[index_top], sp.index_from_rail(j, connection_def.location, n))
                            elseif location == "bottom" then
                                table.insert(direct_connections[index_bottom], sp.index_from_rail(j, connection_def.location, n))
                            end
                        end
                    end
                end
            end
        end
    end

    -- for each support point, determine all other support points which can be traversed to while staying within rail support distance
    -- we can only traverse through direction connections
    ---@type { [SupportPointIndex]: SupportPointIndex[] }
    local connections = {}
    for i, rail in pairs(rails) do
        for _, location in pairs({"top", "bottom"}) do
            local index = sp.index_from_rail(i, location, n) -- this is the index of the support point we are considering
            -- this is the map position of the support point we are considering
            -- we need other support points to be within a certain distance of this in order to be supportable by a rail support at this position
            local pos = sp.position(rail, location)

            -- now we need to check all other support points
            connections[index] = {}
            local already_visited = {} -- don't evaluate the same other support position twice

            ---Evaluate if a support at this point could support another support point
            ---@param support_point_index SupportPointIndex The other support point we are checking
            ---@param came_from_other_end_of_same_rail boolean Whether the previous support point we checked along this path was the other support point belonging to this support point's rail
            local function traverse_recursive(support_point_index, came_from_other_end_of_same_rail)
                -- this is my current understanding of how the rail support system works:
                -- in order for a rail support at point A to provide support for point B, we need:
                -- 1. a train could traverse between A and B, without changing direction, along path P
                -- 2. every support point X along path P satisfies distance(A, X) <= 11
                -- 3. distance(A, B) <= 11
                -- 4. distance(A, the map position of the rail entity containing B) <= 11
                -- 5. distance(A, the OTHER support point of the rail entity containing B) <= 11
                -- (11 is the elevated-rails rail-support support_range value. it can be modified at startup, or different supports could be created that have different support_range values)
                -- so the strategy is to start from point A, traverse to all other points along path P, and at every step check the distance restrictions and if any of them are false, stop moving along P
                -- use recursive depth-first search to handle forks/splits
                -- we also keep track of whether or not we just came from the other support point on the same rail entity, because in that case we can traverse to ANY of the directly connected support points
                -- -- if we didn't, then we can only traverse to the other support point on this rail
                -- -- (this enforces the restriction that the train has to move along path P without changing direction)
                -- -- for example, we shouldn't be able to traverse from B to C, but we can traverse from A to B or from A to C:
                -- --       B
                -- --      /
                -- -- A ------
                -- --      \
                -- --       C
                if table.find(already_visited, support_point_index) then return end -- TODO: use points as keys so can O(1) lookup
                table.insert(already_visited, support_point_index)
                
                local other_rail = rails[sp.rail_index(support_point_index, n)]
                -- get the positions for both of the rail's support points
                local other_pos1 = sp.position(other_rail, "top")
                local other_pos2 = sp.position(other_rail, "bottom")
                if
                -- TODO: not hardcoded 11's
                    util.distance(pos, other_pos1) > 11
                    or util.distance(pos, other_rail.position) > 11
                    or util.distance(pos, other_pos2) > 11
                then return end

                table.insert(connections[index], support_point_index)
                ---@type SupportPointIndex[]
                local points_to_check
                if came_from_other_end_of_same_rail then
                    -- can check everything
                    points_to_check = direct_connections[support_point_index]
                else
                    -- can only check the other point on the rail
                    points_to_check = {sp.paired_index(support_point_index, n)}
                end
                for _, connected_index in pairs(points_to_check) do
                    traverse_recursive(connected_index, sp.indices_are_paired(support_point_index, connected_index, n))
                end
            end
            -- start with a value of true for `came_from_other_end_of_same_rail` to force it to check all direct connections
            traverse_recursive(index, true)
        end
    end

    return connections
end

---@param rails ElevatedRailData[]
---@param connections { [SupportPointIndex]: SupportPointIndex[] }
---@return RailSupportData[]
local function solve_supports(rails, connections)
    local n = #rails

    -- TODO: need to not make supports that collide with each other
    ---@type RailSupportData[]
    local supports = {}
    local original_connections = table.deep_copy(connections) -- since we will be modifying connections

    -- keep adding supports until all points are supported
    local need_to_add_support = true
    while need_to_add_support do
        -- get the most "impactful" point, which is the support point that will provide support to the largest number of other support points if we were to place a rail support there
        -- by doing this, we generally find the most efficient (fewest supports placed) solution
        local index
        local max = -1
        for i, conns in pairs(connections) do
            local _n = table_size(conns) -- not guaranteed to be a contiguous array, so can't use #
            if _n > max then
                index = i
                max = _n
            end
        end
        -- we will be removing points which have already received support, so as long as there is at least one point in one of the lists, that means we still need to place another support (because that point hasn't been supported yet)
        if max <= 0 then need_to_add_support = false end

        if need_to_add_support then
            -- add a rail support to this point
            local location = sp.location_from_index(index, n)
            local rail = rails[sp.rail_index(index, n)]
            table.insert(supports, {
                name = "rail-support",
                position = sp.position(rail, location),
                direction = const.support_points[rail.name][rail.direction][location].direction,
                point = index,
                supported_points = original_connections[index],
            })

            -- remove this point and all connected points from consideration
            -- if point A would support {1, 2, 3, 4, 5} and point B would support {2, 3, 4, 5, 6}, then after adding a support at A, we shouldn't consider B to support 5 points for the purposes of picking the next point
            -- once A is placed, then adding a support at B would only change 6 to be supported (2-5 are already supported), so in reality B is not that impactful of a support point and we should consider it a low priority
            for _, connected_support_point in pairs(connections[index]) do
                -- loop through all the lists of connections
                for i, conns in pairs(connections) do
                    if i ~= index then -- don't modify connections[index] (yet) since we are currently iterating over that
                        local index_to_remove = table.find(conns, connected_support_point)
                        if index_to_remove then table.remove(conns, index_to_remove) end
                    end
                end
            end
            -- now can modify this table safely
            connections[index] = {}
        end
    end

    -- remove redundant supports
    -- it's sometimes possible for the solver to place a support in the middle of a track, then place a support on each end of the track, such that if we removed the original middle support then the two on the ends would still be able to support the full track
    -- so we remove any supports which aren't really contributing anything in order to make the solution more efficient
    local function get_first_redundant_support()
        for i, support in pairs(supports) do
            -- assume that the support is redundant until we prove otherwise
            local redundant = true
            -- check all other points that this support is able to support - if one of those points is NOT supported by any other supports, then we know that this support is NOT redundant (since it's the only one providing support for that point)
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

---@param entities BlueprintEntity[]
---@return ElevatedRailData[]
solver.filter_entities = function(entities)
    -- TODO: probably just filter to elevated rails? still not sure how best to handle ramps
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

---@param entities BlueprintEntity[]
---@return BlueprintEntity[]
---@return boolean -- TODO: error types
solver.get_support_entities = function(entities)
    local supportable_entities = solver.filter_entities(entities)
    local connections = solver.get_support_point_connections(supportable_entities)
    local supports = solve_supports(supportable_entities, connections) --[[@as BlueprintEntity]]

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
