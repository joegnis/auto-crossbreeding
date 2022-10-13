
local M = {}

function M.mockGo()
    ---@param gps Gps
    ---@param pos Position
    return function(gps, pos)
        gps.farmer_.position_ = pos
    end
end

function M.mockBackOrigin()
    ---@param gps Gps
    return function(gps)
        gps.farmer_.position_ = {0, 0}
    end
end

return M
