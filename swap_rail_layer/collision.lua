local table = require("__flib__.table")
local bounding_box = require("__flib__.bounding-box")
local flib_position = require("__flib__.position")
local dir = defines.direction

local collision = {}

local rail_collision_mask_layers = prototypes.entity["straight-rail"].collision_mask.layers
local support_collision_mask_layers = prototypes.entity["rail-support"].collision_mask.layers

---@type { [string]: { [defines.direction]: { ["full" | "partial"]: MapPosition.0[] } } }
collision.tile_collisions = {
    ["straight-rail"] = {
        [dir.north] = {
            full = {
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
            },
            partial = {},
        },
        [dir.northeast] = {
            full = {
                {x = 0.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = 1.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = -0.5, y = 1.5},
            },
            partial = {},
        },
        [dir.east] = {
            full = {
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
            },
            partial = {},
        },
        [dir.southeast] = {
            full = {
                {x = -0.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 1.5, y = 0.5},
                {x = 0.5, y = 1.5},
            },
            partial = {},
        },
    },
    ["half-diagonal-rail"] = {
        [dir.north] = {
            full = {
                {x = -1.5, y = -1.5},
                {x = -0.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 0.5, y = 1.5},
                {x = 1.5, y = 1.5},
            },
            partial = {
                {x = 0.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = 1.5, y = 0.5},
                {x = -0.5, y = 1.5},
            },
        },
        [dir.northeast] = {
            full = {
                {x = 0.5, y = -1.5},
                {x = 1.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = -1.5, y = 1.5},
                {x = -0.5, y = 1.5},
            },
            partial = {
                {x = -0.5, y = -1.5},
                {x = 1.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = 0.5, y = 1.5},
            },
        },
        [dir.east] = {
            full = {
                {x = 1.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = 1.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = -1.5, y = 1.5},
            },
            partial = {
                {x = 0.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = 1.5, y = 0.5},
                {x = -0.5, y = 1.5},
            },
        },
        [dir.southeast] = {
            full = {
                {x = -1.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 1.5, y = 0.5},
                {x = 1.5, y = 1.5},
            },
            partial = {
                {x = -0.5, y = -1.5},
                {x = 1.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = 0.5, y = 1.5},
            },
        },
    },
    ["curved-rail-a"] = {
        [dir.south] = {
            full = {
                {x = -0.5, y = -1.5},
                {x = 0.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 0.5, y = 1.5},
                {x = 0.5, y = 2.5},
                {x = 1.5, y = 2.5},
            },
            partial = {
                {x = -0.5, y = 1.5},
                {x = 1.5, y = 1.5},
            },
        },
        [dir.west] = {
            full = {
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = 1.5, y = -0.5},
                {x = -2.5, y = 0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 1.5, y = 0.5},
                {x = -2.5, y = 1.5},
            },
            partial = {
                {x = -1.5, y = -0.5},
                {x = -1.5, y = 1.5},
            },
        },
        [dir.north] = {
            full = {
                {x = -1.5, y = -2.5},
                {x = -0.5, y = -2.5},
                {x = -0.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = -0.5, y = 1.5},
                {x = 0.5, y = 1.5},
            },
            partial = {
                {x = -1.5, y = -1.5},
                {x = 0.5, y = -1.5},
            },
        },
        [dir.east] = {
            full = {
                {x = 2.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = 1.5, y = -0.5},
                {x = 2.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
            },
            partial = {
                {x = 1.5, y = -1.5},
                {x = 1.5, y = 0.5},
            },
        },
        [dir.southwest] = {
            full = {
                {x = -0.5, y = -1.5},
                {x = 0.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = -0.5, y = 1.5},
                {x = -1.5, y = 2.5},
                {x = -0.5, y = 2.5},
            },
            partial = {
                {x = -1.5, y = 1.5},
                {x = 0.5, y = 1.5},
            },
        },
        [dir.northwest] = {
            full = {
                {x = -2.5, y = -1.5},
                {x = -2.5, y = -0.5},
                {x = -1.5, y = -0.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = 1.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 1.5, y = 0.5},
            },
            partial = {
                {x = -1.5, y = -1.5},
                {x = -1.5, y = 0.5},
            },
        },
        [dir.northeast] = {
            full = {
                {x = 0.5, y = -2.5},
                {x = 1.5, y = -2.5},
                {x = 0.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = -0.5, y = 1.5},
                {x = 0.5, y = 1.5},
            },
            partial = {
                {x = -0.5, y = -1.5},
                {x = 1.5, y = -1.5},
            },
        },
        [dir.southeast] = {
            full = {
                {x = -1.5, y = -0.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 1.5, y = 0.5},
                {x = 2.5, y = 0.5},
                {x = 2.5, y = 1.5},
            },
            partial = {
                {x = 1.5, y = -0.5},
                {x = 1.5, y = 1.5},
            },
        },
    },
    ["curved-rail-b"] = {
        [dir.south] = {
            full = {
                {x = -1.5, y = -1.5},
                {x = -0.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = 0.5, y = 0.5},
                {x = 1.5, y = 0.5},
                {x = 0.5, y = 1.5},
                {x = 1.5, y = 1.5},
                {x = 2.5, y = 1.5},
                {x = 1.5, y = 2.5},
            },
            partial = {
                {x = -0.5, y = -2.5},
                {x = 0.5, y = -1.5},
                {x = 1.5, y = -0.5},
                {x = -0.5, y = 0.5},
            },
        },
        [dir.west] = {
            full = {
                {x = 1.5, y = -1.5},
                {x = 0.5, y = -0.5},
                {x = 1.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = -2.5, y = 1.5},
                {x = -1.5, y = 1.5},
                {x = -0.5, y = 1.5},
                {x = -1.5, y = 2.5},
            },
            partial = {
                {x = -0.5, y = -0.5},
                {x = 2.5, y = -0.5},
                {x = 1.5, y = 0.5},
                {x = 0.5, y = 1.5},
            },
        },
        [dir.north] = {
            full = {
                {x = -1.5, y = -2.5},
                {x = -2.5, y = -1.5},
                {x = -1.5, y = -1.5},
                {x = -0.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = -0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 0.5, y = 1.5},
                {x = 1.5, y = 1.5},
            },
            partial = {
                {x = 0.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 1.5},
                {x = 0.5, y = 2.5},
            },
        },
        [dir.east] = {
            full = {
                {x = 1.5, y = -2.5},
                {x = 0.5, y = -1.5},
                {x = 1.5, y = -1.5},
                {x = 2.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = 1.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 0.5},
                {x = -1.5, y = 1.5},
            },
            partial = {
                {x = -0.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = -2.5, y = 0.5},
                {x = 0.5, y = 0.5},
            },
        },
        [dir.southwest] = {
            full = {
                {x = 0.5, y = -1.5},
                {x = 1.5, y = -1.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 0.5},
                {x = -2.5, y = 1.5},
                {x = -1.5, y = 1.5},
                {x = -0.5, y = 1.5},
                {x = -1.5, y = 2.5},
            },
            partial = {
                {x = 0.5, y = -2.5},
                {x = -0.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = 0.5, y = 0.5},
            },
        },
        [dir.northwest] = {
            full = {
                {x = -1.5, y = -2.5},
                {x = -2.5, y = -1.5},
                {x = -1.5, y = -1.5},
                {x = -0.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = -0.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = 0.5, y = 0.5},
                {x = 1.5, y = 0.5},
                {x = 1.5, y = 1.5},
            },
            partial = {
                {x = 0.5, y = -1.5},
                {x = 1.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 2.5, y = 0.5},
            },
        },
        [dir.northeast] = {
            full = {
                {x = 1.5, y = -2.5},
                {x = 0.5, y = -1.5},
                {x = 1.5, y = -1.5},
                {x = 2.5, y = -1.5},
                {x = 0.5, y = -0.5},
                {x = 1.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = -1.5, y = 1.5},
                {x = -0.5, y = 1.5},
            },
            partial = {
                {x = -0.5, y = -0.5},
                {x = 1.5, y = 0.5},
                {x = 0.5, y = 1.5},
                {x = -0.5, y = 2.5},
            }
        },
        [dir.southeast] = {
            full = {
                {x = -1.5, y = -1.5},
                {x = -1.5, y = -0.5},
                {x = -0.5, y = -0.5},
                {x = -0.5, y = 0.5},
                {x = 0.5, y = 0.5},
                {x = 1.5, y = 0.5},
                {x = 0.5, y = 1.5},
                {x = 1.5, y = 1.5},
                {x = 2.5, y = 1.5},
                {x = 1.5, y = 2.5},
            },
            partial = {
                {x = -2.5, y = -0.5},
                {x = 0.5, y = -0.5},
                {x = -1.5, y = 0.5},
                {x = -0.5, y = 1.5},
            },
        },
    },
}

---@type { [string]: { [defines.direction]: BoundingBox.0[] } }
collision.bounding_boxes = {
    ["rail-support"] = {
        [dir.north] = {
            {left_top = {x = -2, y = -2}, right_bottom = {x = 2, y = 2}},
        },
        [dir.east] = {
            {left_top = {x = -2, y = -2}, right_bottom = {x = 2, y = 2}},
        },
        [dir.northnortheast] = {
            {left_top = {x = -1, y = -2}, right_bottom = {x = 1, y = 2}},
            {left_top = {x = -2, y = -1}, right_bottom = {x = 2, y = 1}},
        },
        [dir.northeast] = {
            {left_top = {x = -1, y = -2}, right_bottom = {x = 1, y = 2}},
            {left_top = {x = -2, y = -1}, right_bottom = {x = 2, y = 1}},
        },
        [dir.eastnortheast] = {
            {left_top = {x = -1, y = -2}, right_bottom = {x = 1, y = 2}},
            {left_top = {x = -2, y = -1}, right_bottom = {x = 2, y = 1}},
        },
        [dir.eastsoutheast] = {
            {left_top = {x = -1, y = -2}, right_bottom = {x = 1, y = 2}},
            {left_top = {x = -2, y = -1}, right_bottom = {x = 2, y = 1}},
        },
        [dir.southeast] = {
            {left_top = {x = -1, y = -2}, right_bottom = {x = 1, y = 2}},
            {left_top = {x = -2, y = -1}, right_bottom = {x = 2, y = 1}},
        },
        [dir.southsoutheast] = {
            {left_top = {x = -1, y = -2}, right_bottom = {x = 1, y = 2}},
            {left_top = {x = -2, y = -1}, right_bottom = {x = 2, y = 1}},
        },
    },
}

---@param entity LuaEntity | BlueprintEntity
---@return boolean
collision.mask_collides_with_rail = function(entity)
    for layer, _ in pairs(prototypes.entity[entity.name].collision_mask.layers) do
        if rail_collision_mask_layers[layer] then return true end
    end
    return false
end

---@param entity LuaEntity | BlueprintEntity
---@return boolean
collision.mask_collides_with_support = function(entity)
    for layer, _ in pairs(prototypes.entity[entity.name].collision_mask.layers) do
        if support_collision_mask_layers[layer] then return true end
    end
    return false
end

---@param rail LuaEntity | BlueprintEntity
---@param box BoundingBox.0
---@return boolean
collision.rail_collides_with_box = function(rail, box)
    -- for now, just ignore full/partial distinction
    -- later, can detect whether the input bounding box should check against partial tile collisions as well as full tile collisions
    local positions = table.array_merge({
        collision.tile_collisions[rail.name][rail.direction or dir.north].full,
        collision.tile_collisions[rail.name][rail.direction or dir.north].partial,
    })
    positions = table.map(positions, function(v) return flib_position.add(v, rail.position) end)

    for _, position in pairs(positions) do
        if bounding_box.contains_position(box, position) then return true end
    end
    return false
end

local function rotate_bounding_box(bb, direction)
    -- for now, assuming that all entities have rectangular collision boxes and ignoring 8/16-way rotation
    -- special cases should probably be handled by hardcoded override anyway
    if direction == dir.east or direction == dir.west then
        return bounding_box.rotate(bb)
    else
        return bb
    end
end

---Determine if a potential rail support would collide with another entity.
---@param support_position MapPosition.0
---@param support_direction defines.direction
---@param entity BlueprintEntity | RailSupportData
---@return boolean
collision.support_would_collide = function(support_position, support_direction, entity)
    local support_bbs = collision.bounding_boxes["rail-support"][support_direction]
    support_bbs = table.map(support_bbs, function(v) return bounding_box.move(v, support_position) end)

    -- special case for rails since we check tiles rather than bounding boxes
    if collision.tile_collisions[entity.name] then
        for _, bb in pairs(support_bbs) do
            if collision.rail_collides_with_box(entity --[[@as BlueprintEntity]], bb) then return true end
        end
    end

    local other_bbs
    if collision.bounding_boxes[entity.name] then
        other_bbs = collision.bounding_boxes[entity.name][entity.direction]
    else
        other_bbs = {prototypes.entity[entity.name].collision_box}
    end
    other_bbs = table.map(other_bbs, function(v) return bounding_box.move(v, entity.position) end)
    other_bbs = table.map(other_bbs, function(v) return rotate_bounding_box(v, entity.direction) end)

    for _, bb1 in pairs(support_bbs) do
        for __, bb2 in pairs(other_bbs) do
            if bounding_box.intersects_box(bb1, bb2) then return true end
        end
    end

    return false
end

return collision
