local const = require("swap_rail_layer.constants")
local table = require("__flib__.table")
local math = require("__flib__.math")
local bounding_box = require("__flib__.bounding-box")
local util = require("__core__.lualib.util")

solver = {}

---@class ElevatedRailData
---@field name "elevated-straight-rail" | "elevated-half-diagonal-rail" | "elevated-curved-rail-a" | "elevated-curved-rail-b" The entity name of the elevated rail
---@field position MapPosition.0 The position of the elevated rail entity
---@field direction defines.direction The direction of the elevated rail entity

---@class RailRampData
---@field name "rail-ramp" The entity name of the rail ramp
---@field position MapPosition.0 The position of the rail ramp entity
---@field direction defines.direction The direction of the rail ramp entity

---@class RailSupportData
---@field name "rail-support" The entity name of the rail support
---@field position MapPosition.0 The position of the rail support entity
---@field direction defines.direction The direction of the rail support entity
---@field point SupportPointIndex The index of the support point where this rail support is
---@field supported_points SupportPointIndex[] All support points which are supported by this rail support

---@alias SupportPointIndex integer

---Abstraction layer for handling support point indices and positions.
---In general, for `n` rails, indices `1` to `n` are the top points, and indices `n + 1` to `2n` are the bottom points.
solver.sp = {}
local sp = solver.sp

---Translate a rail entity index and a rail support location into a support point index.
---@param rail_index integer
---@param location SupportPointLocation
---@param num_rails integer
---@return SupportPointIndex
solver.sp.index_from_rail = function(rail_index, location, num_rails)
    return location == const.locations.top and rail_index or rail_index + num_rails
end

---Translate a support point index into a rail entity index.
---@param point_index SupportPointIndex
---@param num_rails integer
---@return integer
solver.sp.rail_index = function(point_index, num_rails)
    return ((point_index - 1) % num_rails) + 1
end

---For a given support point, get the index of the other support point on the same rail entity.
---@param point_index SupportPointIndex
---@param num_rails integer
---@return SupportPointIndex
solver.sp.paired_index = function(point_index, num_rails)
    return ((point_index + num_rails - 1) % (2 * num_rails)) + 1
end

---Determine if two support point indices are paired.
---@param point_index1 SupportPointIndex
---@param point_index2 SupportPointIndex
---@param num_rails integer
---@return boolean
solver.sp.indices_are_paired = function(point_index1, point_index2, num_rails)
    return math.abs(point_index1 - point_index2) == num_rails
end

---Determine the point location from a given support point index.
---@param point_index SupportPointIndex
---@param num_rails integer
---@return SupportPointLocation
solver.sp.location_from_index = function(point_index, num_rails)
    return point_index <= num_rails and const.locations.top or const.locations.bottom
end

---Determine the map position for a support point on a rail.
---@param rail ElevatedRailData
---@param location SupportPointLocation
---@return MapPosition.0
solver.sp.position = function(rail, location)
    return {
        x = rail.position.x + const.support_points[rail.name][rail.direction][location].offset.x,
        y = rail.position.y + const.support_points[rail.name][rail.direction][location].offset.y,
    }
end

---Determine the map position for a support point on a ramp.
---@param ramp RailRampData
---@return MapPosition.0
solver.sp.position_ramp = function(ramp)
    return {
        x = ramp.position.x + const.support_points[ramp.name][ramp.direction][const.locations.top].offset.x,
        y = ramp.position.y + const.support_points[ramp.name][ramp.direction][const.locations.top].offset.y,
    }
end

local function get_bounding_boxes(position, direction)
    if direction == defines.direction.north or direction == defines.direction.east then
        return {
            {
                left_top = {
                    x = position.x - 2,
                    y = position.y - 2,
                },
                right_bottom = {
                    x = position.x + 2,
                    y = position.y + 2,
                },
            },
        }
    else
        return {
            {
                left_top = {
                    x = position.x - 1,
                    y = position.y - 2,
                },
                right_bottom = {
                    x = position.x + 1,
                    y = position.y + 2,
                },
            },
            {
                left_top = {
                    x = position.x - 2,
                    y = position.y - 1,
                },
                right_bottom = {
                    x = position.x + 2,
                    y = position.y + 1,
                },
            },
        }
    end
end

local function get_bounding_boxes_ramp(position, direction)
    if direction == defines.direction.north or direction == defines.direction.south then
        return {
            {
                left_top = {
                    x = position.x - 2,
                    y = position.y - 8,
                },
                right_bottom = {
                    x = position.x + 2,
                    y = position.y + 8,
                },
            },
        }
    else
        return {
            {
                left_top = {
                    x = position.x - 8,
                    y = position.y - 2,
                },
                right_bottom = {
                    x = position.x + 8,
                    y = position.y + 2,
                },
            },
        }
    end
end

---Determine if two potential rail supports would collide with each other.
---@param position1 MapPosition.0
---@param direction1 defines.direction
---@param position2 MapPosition.0
---@param direction2 defines.direction
---@return boolean
solver.sp.will_collide = function(position1, direction1, position2, direction2)
    local bbs1 = get_bounding_boxes(position1, direction1)
    local bbs2 = get_bounding_boxes(position2, direction2)
    local collide = false
    for _, bb1 in pairs(bbs1) do
        for _, bb2 in pairs(bbs2) do
            if bounding_box.intersects_box(bb1, bb2) then collide = true end
        end
    end
    return collide
end

---Determine if a potential rail support would collide with a ramp.
---@param support_position MapPosition.0
---@param support_direction defines.direction
---@param ramp_position MapPosition.0
---@param ramp_direction defines.direction
---@return boolean
solver.sp.will_collide_with_ramp = function(support_position, support_direction, ramp_position, ramp_direction)
    local bbs1 = get_bounding_boxes(support_position, support_direction)
    local bbs2 = get_bounding_boxes_ramp(ramp_position, ramp_direction)
    local collide = false
    for _, bb1 in pairs(bbs1) do
        for _, bb2 in pairs(bbs2) do
            if bounding_box.intersects_box(bb1, bb2) then collide = true end
        end
    end
    return collide
end

---@param rails ElevatedRailData[]
---@param ramps RailRampData[]
---@return { [SupportPointIndex]: SupportPointIndex[] } connections The connection relationships among rail support points
---@return SupportPointIndex[] supported_by_ramp A list of all connection points that are already supported by ramps
solver.get_support_point_connections = function(rails, ramps)
    local n = #rails

    -- first we have to get the direct connections, so then we can traverse through them

    ---Maps support point indices to all other indices that the point is directly connected to
    ---@type { [SupportPointIndex]: SupportPointIndex[] }
    local direct_connections = {}
    ---@type { integer: SupportPointIndex[] }
    local ramp_direct_connections = {}

    for i, rail in pairs(rails) do
        local index_top = sp.index_from_rail(i, const.locations.top, n)
        local index_bottom = sp.index_from_rail(i, const.locations.bottom, n)

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
                            if location == const.locations.top then
                                table.insert(direct_connections[index_top], sp.index_from_rail(j, connection_def.location, n))
                            elseif location == const.locations.bottom then
                                table.insert(direct_connections[index_bottom], sp.index_from_rail(j, connection_def.location, n))
                            end
                        end
                    end
                end
            end
        end
    end
    for i, ramp in pairs(ramps) do
        ramp_direct_connections[i] = {}
        local support_point_def = const.support_points[ramp.name][ramp.direction][const.locations.top]
        for j, other_rail in pairs(rails) do
            for _, connection_def in pairs(support_point_def.connects_to) do
                -- connection_def.location is the support point location on the *other* rail
                if
                    -- two support points on different rails "connect" if they are essentially the same support point
                    -- this means that the rails are compatible to be connected (check name and direction in connection definition), AND the support points are at the same map position (check entity position + support point offset)
                    other_rail.name == connection_def.name
                    and other_rail.direction == connection_def.direction
                    and ramp.position.x + support_point_def.offset.x == sp.position(other_rail, connection_def.location).x
                    and ramp.position.y + support_point_def.offset.y == sp.position(other_rail, connection_def.location).y
                then
                    table.insert(ramp_direct_connections[i], sp.index_from_rail(j, connection_def.location, n))
                end
            end
        end
    end

    -- for each support point, determine all other support points which can be traversed to while staying within rail support distance
    -- we can only traverse through direction connections
    ---@type { [SupportPointIndex]: SupportPointIndex[] }
    local connections = {}
    for i, rail in pairs(rails) do
        for _, location in pairs(const.locations) do
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
                -- 2. every support point X along path P satisfies distance(A, X) <= const.support_distance
                -- 3. distance(A, B) <= const.support_distance
                -- 4. distance(A, the map position of the rail entity containing B) <= const.support_distance
                -- 5. distance(A, the OTHER support point of the rail entity containing B) <= const.support_distance
                -- (const.support_distance is the elevated-rails rail-support support_range value. it can be modified at startup, or different supports could be created that have different support_range values)
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
                if already_visited[support_point_index] then return end
                already_visited[support_point_index] = true
                
                local other_rail = rails[sp.rail_index(support_point_index, n)]
                -- get the positions for both of the rail's support points
                local other_pos1 = sp.position(other_rail, const.locations.top)
                local other_pos2 = sp.position(other_rail, const.locations.bottom)
                if
                    util.distance(pos, other_pos1) > const.support_distance
                    or util.distance(pos, other_rail.position) > const.support_distance
                    or util.distance(pos, other_pos2) > const.support_distance
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

    ---@type { integer: SupportPointIndex[] }
    local ramp_connections = {}
    for i, ramp in pairs(ramps) do
        -- this is the map position of the support point we are considering
        -- we need other support points to be within a certain distance of this in order to be supportable by this ramp
        local pos = sp.position_ramp(ramp)

        -- now we need to check all other support points
        ramp_connections[i] = {}
        local already_visited = {} -- don't evaluate the same other support position twice

        ---Evaluate if this ramp could support another support point
        ---@param support_point_index SupportPointIndex The other support point we are checking
        ---@param came_from_other_end_of_same_rail boolean Whether the previous support point we checked along this path was the other support point belonging to this support point's rail
        local function traverse_recursive(support_point_index, came_from_other_end_of_same_rail)
            -- see above for explanation
            if already_visited[support_point_index] then return end
            already_visited[support_point_index] = true

            local other_rail = rails[sp.rail_index(support_point_index, n)]
            -- get the positions for both of the rail's support points
            local other_pos1 = sp.position(other_rail, const.locations.top)
            local other_pos2 = sp.position(other_rail, const.locations.bottom)
            if
                util.distance(pos, other_pos1) > const.ramp_support_distance
                or util.distance(pos, other_rail.position) > const.ramp_support_distance
                or util.distance(pos, other_pos2) > const.ramp_support_distance
            then return end

            table.insert(ramp_connections[i], support_point_index)
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
        -- ramps aren't really part of the "support point index" structure, so just start the process from each of their direct connections
        for _, support_point_index in pairs(ramp_direct_connections[i]) do
            traverse_recursive(support_point_index, true)
        end
    end

    -- remove duplicates, condense to single array
    local supported_by_ramp_0 = {}
    for _, connected_points in pairs(ramp_connections) do
        for __, support_point_index in pairs(connected_points) do
            supported_by_ramp_0[support_point_index] = true
        end
    end
    local supported_by_ramp = {}
    for index, _ in pairs(supported_by_ramp_0) do
        table.insert(supported_by_ramp, index)
    end

    return connections, supported_by_ramp
end

---@param rails ElevatedRailData[]
---@param ramps RailRampData[]
---@param connections { [SupportPointIndex]: SupportPointIndex[] }
---@param supported_by_ramp SupportPointIndex[]
---@return RailSupportData[]
local function solve_supports(rails, ramps, connections, supported_by_ramp)
    local n = #rails

    ---@type RailSupportData[]
    local supports = {}
    local original_connections = table.deep_copy(connections) -- since we will be modifying connections

    -- remove all points that are supported by ramps from consideration, because we don't need to provide support for them with rail supports
    for _, supported_point in pairs(supported_by_ramp) do
        for __, conns in pairs(connections) do
            local index_to_remove = table.find(conns, supported_point)
            if index_to_remove then table.remove(conns, index_to_remove) end
        end
    end

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
            local location = sp.location_from_index(index, n)
            local rail = rails[sp.rail_index(index, n)]
            local position = sp.position(rail, location)
            local direction = const.support_points[rail.name][rail.direction][location].direction

            -- first make sure we aren't colliding with any existing supports. if we are, remove this support point from consideration and move on
            local no_collision = true
            for _, support in pairs(supports) do
                if sp.will_collide(position, direction, support.position, support.direction) then
                    no_collision = false
                    connections[index] = {}
                end
            end
            for _, ramp in pairs(ramps) do
                if sp.will_collide_with_ramp(position, direction, ramp.position, ramp.direction) then
                    no_collision = false
                    connections[index] = {}
                end
            end

            if no_collision then
                -- add a rail support to this point
                table.insert(supports, {
                    name = "rail-support",
                    position = position,
                    direction = direction,
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
                -- point can also be supported by a ramp
                if table.find(supported_by_ramp, supported_point) then this_point_is_supported_elsewhere = true end
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
---@return RailRampData[]
solver.filter_entities = function(entities)
    local rails = {}
    local ramps = {}
    for _, entity in pairs(entities) do
        if entity.name:find("^elevated")then
            table.insert(rails, {
                name = entity.name,
                position = entity.position,
                direction = entity.direction or defines.direction.north,
            })
        elseif entity.name == "rail-ramp"  then
            table.insert(ramps, {
                name = entity.name,
                position = entity.position,
                direction = entity.direction or defines.direction.north,
            })
        end
    end
    return rails, ramps
end

---@param entities BlueprintEntity[]
---@return BlueprintEntity[] supports The BlueprintEntities for the rail supports to be added
---@return ErrorData? err The error data, if any
solver.get_support_entities = function(entities)
    local rails, ramps = solver.filter_entities(entities)
    local connections, supported_by_ramp = solver.get_support_point_connections(rails, ramps)
    local supports = solve_supports(rails, ramps, connections, supported_by_ramp) --[[@as BlueprintEntity]]

    local max_entity_number = -1
    for _, entity in pairs(entities) do
        if entity.entity_number > max_entity_number then max_entity_number = entity.entity_number end
    end
    for i, support in pairs(supports) do
        support.entity_number = max_entity_number + i
    end

    return supports, nil -- no errors to report yet, but future-proofing in case we can detect that we simply can't solve a given configuration
end

return solver
