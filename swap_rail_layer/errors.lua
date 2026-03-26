---@class ErrorData
---@field type ErrorType The identifier of the error

local errors = {}

---@enum ErrorType
local error_types = {
    "train_stop_in_blueprint",
    "is_not_rail_blueprint",
    "cannot_write_to_blueprint",
    "blueprint_overwrite_is_disabled",
    "entity_under_elevated_rail",
    "failed_to_solve_supports",
}

for _, type in pairs(error_types) do
    errors[type] = type
end

return errors
