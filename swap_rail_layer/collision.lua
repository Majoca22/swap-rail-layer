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
                {x = -1.5, y = 1.5},
                {x = -0.5, y = 1.5},
                {x = -1.5, y = 2.5},
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
        tile_collisions[rail.name][rail.direction].full,
        tile_collisions[rail.name][rail.direction].partial,
    })
    positions = table.map(positions, function(v) return flib_position.add(v, rail.position) end)

    for _, position in pairs(positions) do
        if bounding_box.contains_position(box, position) then return true end
    end
    return false
end

return collision
