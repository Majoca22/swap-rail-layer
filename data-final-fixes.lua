if settings.startup["swap_rail_layer_debug"].value then
    data.raw["rail-planner"]["rail"].stack_size = 2000
    data.raw["rail-planner"]["rail-ramp"].stack_size = 2000
    data.raw["item"]["rail-support"].stack_size = 2000
end
