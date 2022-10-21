local Farmer = require "farmers.Farmer"
local StatFarm = require "farms.StatFarm"
local utils = require "utils"


---@class StatFarmer: FarmerBase
---@field statConfig_ StatConfig
local StatFarmer = Farmer:newChildClass()

function StatFarmer:class()
    return StatFarmer
end

---@param globalConfig GlobalConfig
---@param statConfig StatConfig
---@param initPos Position?
---@param initFacing Facing?
---@param getBreedStatScore funGetStatScore?
---@param getSpreadStatScore funGetStatScore?
function StatFarmer:new(
    globalConfig, statConfig,
    initPos, initFacing,
    getBreedStatScore, getSpreadStatScore
)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)
    o:superClass().init_(
        o, globalConfig, initPos, initFacing, getBreedStatScore, getSpreadStatScore
    )
    -- Child class specific init
    self.statConfig_ = statConfig
    return o
end

---@param slot integer
---@param pos Position
---@param crop ScannedInfo guaranteed to be a crop
---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
function StatFarmer:handleOffspringCrop_(slot, pos, crop, breedFarm, storageFarm)
    storageFarm:addCrop(crop, function(newPos)
        self.action:transplantCrop(pos, newPos)
        self.gps:go(pos)
        self.action:placeCropSticks(true)
    end)
end

---Scans breed farm and creates a StatFarm instance
---@return StatFarm?
---@return string? errMsg
function StatFarmer:scanBreedFarm()
    local checkFarmland = self.statConfig_.checkBreedFarmland
    local farmSize = self.statConfig_.breedFarmSize
    local centerCrops, emptyCenterSlots = self:scanFarm(
        StatFarm:iterCenterParentSlotPos(farmSize), checkFarmland
    )
    ---@type string[]
    local targetCrops = {}
    for _, scannedInfo in pairs(centerCrops) do
        if scannedInfo.isCrop then
            targetCrops[#targetCrops + 1] = scannedInfo.name
        end
    end
    local targetCropsSet = utils.listToSet(targetCrops)
    if utils.sizeOfTable(targetCropsSet) > 1 then
        return nil, "More than one crops are found on center slots: " .. utils.setToString(targetCropsSet)
    end

    local nonCenterParentCrops, emptyNonCenterParentSlots = self:scanFarm(
        StatFarm:iterNonCenterParentSlotPos(farmSize),
        checkFarmland
    )

    -- Merging two pairs of dictionaries
    local parentCrops = centerCrops
    for slot, crop in nonCenterParentCrops do
        parentCrops[slot] = crop
    end
    return StatFarm:new(
        farmSize, targetCrops[1], parentCrops,
        emptyCenterSlots, emptyNonCenterParentSlots
    )
end

return StatFarmer
