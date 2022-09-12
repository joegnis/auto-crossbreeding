local config = require("config")

local M = {}

local function posToSlot(size, pos)
    local lastColNum
    if pos[1] % 2 == 1 then
        lastColNum = pos[2] + 1
    else
        lastColNum = size - pos[2]
    end
    return (pos[1] - 1) * size + lastColNum
end

local function slotToPos(size, slot)
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

function M.posToString(globalPos)
    return string.format("{%d, %d}", globalPos[1], globalPos[2])
end

function M.globalToFarm(globalPos, farmSize)
    farmSize = farmSize or config.farmSize
    return posToSlot(farmSize, globalPos)
end

function M.farmToGlobal(farmSlot, farmSize)
    farmSize = farmSize or config.farmSize
    return slotToPos(farmSize, farmSlot)
end

function M.globalToStorage(globalPos, farmSize)
    farmSize = farmSize or config.storageFarmSize
    return posToSlot(farmSize, { -globalPos[1], globalPos[2] })
end

function M.storageToGlobal(storageSlot, farmSize)
    farmSize = farmSize or config.storageFarmSize
    local globalPos = slotToPos(farmSize, storageSlot)
    globalPos[1] = -globalPos[1];
    return globalPos
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
