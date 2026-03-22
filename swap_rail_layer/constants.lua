local dir = defines.direction

---@alias SupportPointLocation "top" | "bottom"

---@class SupportPointDefinition Either of the two ends of an elevated rail entity
---@field offset MapPosition.0 The support point's offset from the position of the elevated rail entity
---@field direction defines.direction The direction that the rail support entity will need to face when built under this support point
---@field connects_to SupportPointConnectionDefinition[] All possible ways that this support point can connect to another elevated rail

---@class SupportPointConnectionDefinition A description of an elevated rail that is able to connect to another given elevated rail at a particular support point
---@field name string The name of the other elevated rail entity that can connect at this support point
---@field direction defines.direction The direction that the other elevated rail entity will need to face in order to make the connection valid
---@field location SupportPointLocation Which support point on the other elevated rail is able to connect to this rail's support point

return {
    ---@type { [string]: string }
    hotswap_map = {
        ["straight-rail"] = "elevated-straight-rail",
        ["elevated-straight-rail"] = "straight-rail",
        ["half-diagonal-rail"] = "elevated-half-diagonal-rail",
        ["elevated-half-diagonal-rail"] = "half-diagonal-rail",
        ["curved-rail-a"] = "elevated-curved-rail-a",
        ["elevated-curved-rail-a"] = "curved-rail-a",
        ["curved-rail-b"] = "elevated-curved-rail-b",
        ["elevated-curved-rail-b"] = "curved-rail-b",
    },

    ---@type { [string]: string }
    layer_map = {
        ["ground"] = "elevated",
        ["elevated"] = "ground",
    },

    support_distance = prototypes.entity["rail-support"].support_range,
    ramp_support_distance = prototypes.entity["rail-ramp"].support_range,

    ---@type { [string]: { [defines.direction]: { [SupportPointLocation]: SupportPointDefinition } } }
    support_points = {
        ["elevated-straight-rail"] = {
            [dir.north] = {
                top = {
                    offset = {x = 0, y = -1},
                    direction = dir.north,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.northeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 0, y = 1},
                    direction = dir.north,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.southwest, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.south, location = "top"},
                    },
                },
            },
            [dir.northeast] = {
                top = {
                    offset = {x = 1, y = -1},
                    direction = dir.northeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.northeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.southwest, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.west, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -1, y = 1},
                    direction = dir.northeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.northeast, location = "top"},
                    },
                },
            },
            [dir.east] = {
                -- calling the right point "top" and the left point "bottom" just to have consistent naming with everything else
                top = {
                    offset = {x = 1, y = 0},
                    direction = dir.east,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.east, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.east, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -1, y = 0},
                    direction = dir.east,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.west, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northwest, location = "bottom"},
                    },
                },
            },
            [dir.southeast] = {
                top = {
                    offset = {x = -1, y = -1},
                    direction = dir.southeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.south, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.southeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 1, y = 1},
                    direction = dir.southeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.northwest, location = "top"},
                    },
                },
            },
        },
        ["elevated-half-diagonal-rail"] = {
            [dir.north] = {
                top = {
                    offset = {x = -1, y = -2},
                    direction = dir.southsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.south, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.north, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 1, y = 2},
                    direction = dir.southsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.south, location = "top"},
                    },
                },
            },
            [dir.northeast] = {
                top = {
                    offset = {x = 1, y = -2},
                    direction = dir.northnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.northeast, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southwest, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.northeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -1, y = 2},
                    direction = dir.northnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.southwest, location = "top"},
                    },
                },
            },
            [dir.east] = {
                top = {
                    offset = {x = 2, y = -1},
                    direction = dir.eastnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.east, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.west, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.east, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -2, y = 1},
                    direction = dir.eastnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.west, location = "top"},
                    },
                },
            },
            [dir.southeast] = {
                top = {
                    offset = {x = -2, y = -1},
                    direction = dir.eastsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.northwest, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 2, y = 1},
                    direction = dir.eastsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northwest, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.southeast, location = "top"},
                    },
                },
            },
        },
        ["elevated-curved-rail-a"] = {
            [dir.south] = {
                top = {
                    offset = {x = 0, y = -2},
                    direction = dir.north,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.northeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 1, y = 3},
                    direction = dir.southsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.south, location = "top"},
                    },
                },
            },
            [dir.west] = {
                top = {
                    offset = {x = 2, y = 0},
                    direction = dir.east,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.east, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.east, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -3, y = 1},
                    direction = dir.eastnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.west, location = "top"},
                    },
                },
            },
            [dir.north] = {
                top = {
                    offset = {x = -1, y = -3},
                    direction = dir.southsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.south, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.north, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 0, y = 2},
                    direction = dir.north,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.southwest, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.south, location = "top"},
                    },
                },
            },
            [dir.east] = {
                top = {
                    offset = {x = 3, y = -1},
                    direction = dir.eastnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.east, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.west, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.east, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -2, y = 0},
                    direction = dir.east,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.west, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northwest, location = "bottom"},
                    },
                },
            },
            [dir.southwest] = {
                top = {
                    offset = {x = 0, y = -2},
                    direction = dir.north,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.northeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -1, y = 3},
                    direction = dir.northnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.southwest, location = "top"},
                    },
                },
            },
            [dir.northwest] = {
                top = {
                    offset = {x = -3, y = -1},
                    direction = dir.eastsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.northwest, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 2, y = 0},
                    direction = dir.east,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.east, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.east, location = "bottom"},
                    },
                },
            },
            [dir.northeast] = {
                top = {
                    offset = {x = 1, y = -3},
                    direction = dir.northnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.northeast, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southwest, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.northeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 0, y = 2},
                    direction = dir.north,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.southwest, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.south, location = "top"},
                    },
                },
            },
            [dir.southeast] = {
                top = {
                    offset = {x = -2, y = 0},
                    direction = dir.east,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.west, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northwest, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 3, y = 1},
                    direction = dir.eastsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northwest, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.southeast, location = "top"},
                    },
                },
            },
        },
        ["elevated-curved-rail-b"] = {
            [dir.south] = {
                top = {
                    offset = {x = -1, y = -2},
                    direction = dir.southsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.north, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.south, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.north, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 2, y = 2},
                    direction = dir.southeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.northwest, location = "top"},
                    },
                },
            },
            [dir.west] = {
                top = {
                    offset = {x = 2, y = -1},
                    direction = dir.eastnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.east, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.west, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.east, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -2, y = 2},
                    direction = dir.northeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.northeast, location = "top"},
                    },
                },
            },
            [dir.north] = {
                top = {
                    offset = {x = -2, y = -2},
                    direction = dir.southeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.south, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.southeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 1, y = 2},
                    direction = dir.southsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.south, location = "top"},
                    },
                },
            },
            [dir.east] = {
                top = {
                    offset = {x = 2, y = -2},
                    direction = dir.northeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.northeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.west, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.southwest, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -2, y = 1},
                    direction = dir.eastnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.west, location = "top"},
                    },
                },
            },
            [dir.southwest] = {
                top = {
                    offset = {x = 1, y = -2},
                    direction = dir.northnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.northeast, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southwest, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.northeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -2, y = 2},
                    direction = dir.northeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.east, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.northeast, location = "top"},
                    },
                },
            },
            [dir.northwest] = {
                top = {
                    offset = {x = -2, y = -2},
                    direction = dir.southeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.south, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.southeast, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 2, y = 1},
                    direction = dir.eastsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northwest, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.southeast, location = "top"},
                    },
                },
            },
            [dir.northeast] = {
                top = {
                    offset = {x = 2, y = -2},
                    direction = dir.northeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.northeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.west, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.southwest, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = -1, y = 2},
                    direction = dir.northnortheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-a", direction = dir.northeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.southwest, location = "top"},
                    },
                },
            },
            [dir.southeast] = {
                top = {
                    offset = {x = -2, y = -1},
                    direction = dir.eastsoutheast,
                    connects_to = {
                        {name = "elevated-half-diagonal-rail", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-a", direction = dir.southeast, location = "bottom"},
                        {name = "elevated-curved-rail-b", direction = dir.northwest, location = "bottom"},
                    },
                },
                bottom = {
                    offset = {x = 2, y = 2},
                    direction = dir.southeast,
                    connects_to = {
                        {name = "elevated-straight-rail", direction = dir.southeast, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.north, location = "top"},
                        {name = "elevated-curved-rail-b", direction = dir.northwest, location = "top"},
                    },
                },
            },
        },
    },
}
