local Farmer = require "farmers.Farmer"
local gps = require "gps"


---@class Crossbreeder: Farmer
local Crossbreeder = Farmer:newChildClass()

---@param action Action?
---@param getBreedStatScore funGetStatScore?
---@param getSpreadStatScore funGetStatScore?
function Crossbreeder:new(action, getBreedStatScore, getSpreadStatScore)
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
function Crossbreeder:handleOffspringCrop_(slot, pos, crop, breedFarm, storageFarm)
    if storageFarm:cropExists(crop.name) then
        breedFarm:tryUpgradeParentCrop(
            crop,
            function(parentPos)
                -- Saves as breed parent to get higher quality
                self.action_:transplantCrop(pos, parentPos)
                gps.go(pos)
                self.action_:placeCropSticks(true)
                print(breedFarm:reportLowest())
            end,
            function()
                self.action_:breakCrop()
                self.action_:placeCropSticks(true)
            end
        )
    else
        -- Saves to storage farm
        storageFarm:addCrop(crop, function(destPos)
            self.action_:transplantCrop(pos, destPos)
            gps.go(pos)
            self.action_:placeCropSticks(true)
        end)
        print(storageFarm:reportStatus())
    end
end

return Crossbreeder
