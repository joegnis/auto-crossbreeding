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

---Converts a global position to storage farm's slot number
---@param pos Position
---@param size integer
---@return integer
function M.posToStorageSlot(pos, size)
    return M.posToBreedSlot({-pos[1], pos[2]}, size)
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

---Converts a storage farm's slot number to global position
---@param slot integer
---@param size integer storage farm's size
---@return Position
function M.storageSlotToPos(slot, size)
    local pos = M.breedSlotToPos(slot, size)
    pos[1] = -pos[1]
    return pos
end

---Creates an iterator of all slots and their positions in a storage farm
---@param size integer storage farm's size
---@return fun(): integer, Position
function M.allStoragePos(size)
    local farmArea = size ^ 2
    local slot = 0
    return function ()
        slot = slot + 1
        if slot <= farmArea then
            return slot, M.storageSlotToPos(slot, size)
        end
    end
end

---Creates an iterator of parent breeding crops' slots and positions in a breed farm
---@param size integer breed farm's size
---@return fun(): integer, Position
function M.allBreedParentsPos(size)
    local farmArea = size ^ 2
    local slot = -1
    return function ()
        slot = slot + 2
        if slot <= farmArea then
            return slot, M.breedSlotToPos(slot, size)
        end
    end
end

function M.assertParentSlot(slot)
    if slot % 2 == 1 then
        error(string.format("%d is not a parent slot", slot), 2)
    end
end

---Creates an iterator of all slots and their positions in a breed farm
---@param size integer breed farm's size
---@return fun(): integer, Position
function M.allBreedPos(size)
    local farmArea = size ^ 2
    local slot = 0
    return function ()
        slot = slot + 1
        if slot <= farmArea then
            return slot, M.breedSlotToPos(slot, size)
        end
    end
end

function M.multifarmPosInFarm(pos)
    local absX = math.abs(pos[1])
    local absY = math.abs(pos[2])
    return (absX + absY) <= config.multifarmSize and (absX > 2 or absY > 2) and absX < config.multifarmSize - 1 and
        absY < config.multifarmSize - 1
end

function M.globalPosToMultifarmPos(pos)
    return { pos[1] - config.multifarmCentorOffset[1], pos[2] - config.multifarmCentorOffset[2] }
end

function M.multifarmPosToGlobalPos(pos)
    return { pos[1] + config.multifarmCentorOffset[1], pos[2] + config.multifarmCentorOffset[2] }
end

function M.multifarmPosIsRelayFarmland(pos)
    for i = 1, #config.multifarmRelayFarmlandPoses do
        local rPos = config.multifarmRelayFarmlandPoses[i]
        if rPos[1] == pos[1] and rPos[2] == pos[2] then
            return true
        end
    end
    return false
end

function M.nextRelayFarmland(pos)
    if pos == nil then
        return config.multifarmRelayFarmlandPoses[1]
    end
    for i = 1, #config.multifarmRelayFarmlandPoses do
        local rPos = config.multifarmRelayFarmlandPoses[i]
        if rPos[1] == pos[1] and rPos[2] == pos[2] and i < #config.multifarmRelayFarmlandPoses then
            return config.multifarmRelayFarmlandPoses[i + 1]
        end
    end
end

function M.findOptimalDislocator(pos)
    -- return: {dislocatorGlobalPos, relayFarmlandGlobalPos}
    local minDistance = 100
    local minPosI
    for i = 1, #config.multifarmDislocatorPoses do
        local rPos = config.multifarmDislocatorPoses[i]
        local distance = math.max(math.abs(pos[1] - rPos[1]), math.abs(pos[2] - rPos[2]))
        if distance < minDistance then
            minDistance = distance
            minPosI = i
        end
    end
    return { M.multifarmPosToGlobalPos(config.multifarmDislocatorPoses[minPosI]),
        M.multifarmPosToGlobalPos(config.multifarmRelayFarmlandPoses[minPosI]) }
end

return M
