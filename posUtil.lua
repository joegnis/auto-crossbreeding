local config = require("config")


local M = {}

function M.posToString(globalPos)
    return string.format("(%d, %d)", globalPos[1], globalPos[2])
end

---@alias Position integer[]
---Converts a global position to breed farm's slot number
---@param pos Position
---@param size integer
---@return integer
function M.posToBreedSlot(pos, size)
    local lastColNum
    if pos[1] % 2 == 1 then
        lastColNum = pos[2] + 1
    else
        lastColNum = size - pos[2]
    end
    return (pos[1] - 1) * size + lastColNum
end

---Converts a breed farm's slot number to global position
---@param slot integer
---@param size integer breed farm's size
---@return Position
function M.breedSlotToPos(slot, size)
    local x = (slot - 1) // size + 1
    local y
    local lastColNum = (slot - 1) % size
    if x % 2 == 1 then
        y = lastColNum
    else
        y = size - lastColNum - 1
    end
    return { x, y }
end

return M
