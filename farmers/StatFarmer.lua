local Farmer = require "farmers.Farmer"
local gps = require "gps"

---@class StatFarmer: Farmer
local StatFarmer = Farmer:newChildClass()

---@param action Action?
---@param getBreedStatScore funGetStatScore?
---@param getSpreadStatScore funGetStatScore?
function StatFarmer:new(action, getBreedStatScore, getSpreadStatScore)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)
    o:super().init_(o, action, getBreedStatScore, getSpreadStatScore)
    -- Child class specific init
    return o
end

---@param slot integer
---@param pos Position
---@param crop ScannedInfo guaranteed to be a crop
---@param breedFarm BreedFarm
---@param storageFarm StorageFarm
function StatFarmer:handleOffspringCrop_(slot, pos, crop, breedFarm, storageFarm)
    storageFarm:addCrop(crop, function (newPos)
        self.action_:transplantCrop(pos, newPos)
        gps.go(pos)
        self.action_:placeCropSticks(true)
    end)
end

return StatFarmer
