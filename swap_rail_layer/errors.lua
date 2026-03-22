---@class ErrorData
---@field type ErrorType The identifier of the error

local errors = {}

---@enum ErrorType
local error_types = {
    "train_stop_in_blueprint",
}

for _, type in pairs(error_types) do
    errors[type] = type
end

return errors
