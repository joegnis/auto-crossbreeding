local Crossbreeder = require "farmers.Crossbreeder"
local defaultGlobalConfig = require "config".defaultConfig

local M = {}

---@param config GlobalConfig?
function M.createTestFarmer(config)
    return Crossbreeder:new(config or defaultGlobalConfig)
end

return M
