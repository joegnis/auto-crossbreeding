local Farmer = require "farmers.Farmer"


---@class Crossbreeder: FarmerBase
local Crossbreeder = Farmer:newChildClass()

---@param config GlobalConfig
---@param initPos Position?
---@param initFacing Facing?
---@param getBreedStatScore funGetStatScore?
---@param getSpreadStatScore funGetStatScore?
function Crossbreeder:new(
    config, initPos, initFacing, getBreedStatScore, getSpreadStatScore
)
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
---@param breedFarm CrossbreedFarm
---@param storageFarm StorageFarm
function Crossbreeder:handleOffspringCrop_(slot, pos, crop, breedFarm, storageFarm)
    if storageFarm:cropExists(crop.name) then
        breedFarm:upgradeParentCrop_(
            crop,
            function(parentPos)
                -- Saves as breed parent to get higher quality
                self.action:transplantCrop(pos, parentPos)
                self.gps:go(pos)
                self.action:placeCropSticks(true)
                print(breedFarm:reportLowest())
            end,
            function()
                self.action:breakCrop()
                self.action:placeCropSticks(true)
            end
        )
    else
        -- Saves to storage farm
        storageFarm:addCrop(crop, function(destPos)
            self.action:transplantCrop(pos, destPos)
            self.gps:go(pos)
            self.action:placeCropSticks(true)
        end)
        print(storageFarm:reportStatus())
    end
end

return Crossbreeder
