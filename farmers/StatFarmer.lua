local Farmer = require "farmers.Farmer"


---@class StatFarmer: FarmerBase
local StatFarmer = Farmer:newChildClass()

function StatFarmer:class()
    return StatFarmer
end

---@param config GlobalConfig
---@param initPos Position?
---@param initFacing Facing?
---@param getBreedStatScore funGetStatScore?
---@param getSpreadStatScore funGetStatScore?
function StatFarmer:new(config, initPos, initFacing, getBreedStatScore, getSpreadStatScore)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)
    o:superClass().init_(
        o, config, initPos, initFacing, getBreedStatScore, getSpreadStatScore
    )
    -- Child class specific init
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

return StatFarmer
