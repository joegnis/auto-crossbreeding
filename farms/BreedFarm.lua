local Farm = require "farms.Farm"
local posUtil = require "posUtil"
local utils = require "utils"


---Base class of breed farms
---@alias funGetStatScore fun(cropInfo: ScannedInfo): integer
---@class BreedFarm: Farm
---@field size_ integer
---@field parentSlotsInfo_ table<integer, ScannedInfo>
---@field getBreedStatScore_ funGetStatScore
local BreedFarm = utils.inheritsFrom(Farm)

----------------------------------------
-- Inherited Class & Instance Methods --
----------------------------------------
---Given a slot in the farm, returns its position
---@param slot integer
---@param size integer? farm's size
---@return Position
function BreedFarm:slotToPos(slot, size)
    size = size or self.size_
    return posUtil.breedSlotToPos(slot, size)
end

---Given a position, returns its corresponding slot in the farm
---@param pos Position
---@param size integer? farm's size
---@return integer
function BreedFarm:posToSlot(pos, size)
    size = size or self.size_
    return posUtil.posToBreedSlot(pos, size)
end

---@param pos Position
---@param size integer?
function BreedFarm:isPosInFarm(pos, size)
    size = size or self.size_
    local x, y = table.unpack(pos)
    return x > 0 and x <= size and y >= 0 and y < size
end

------------------------------
-- Class & Instance Methods --
------------------------------

---Creates an iterator of all parent crops' slots and positions
---@param size integer? breed farm's size
---@return fun(): integer?, Position?
function BreedFarm:iterParentSlotPos(size)
    error("not implemented")
end

---Tests if a slot is a parent slot
---@param slot integer
---@param size integer?
---@return boolean
function BreedFarm:isParentSlot(slot, size)
    error("not implemented")
end

-----------------------------
-- Inherited Class Methods --
-----------------------------

function BreedFarm:new()
    error("should not instantiate BreedFarm", 2)
end

----------------------
-- Instance Methods --
----------------------

---For child class constructor to call
---@param size integer
---@param parentCropsInfo table<integer, ScannedInfo> slot-to-ScannedInfo mapping
---@param getBreedStatScore funGetStatScore?
function BreedFarm:init_(size, parentCropsInfo, getBreedStatScore)
    Farm.init_(self, size)
    self.parentSlotsInfo_ = parentCropsInfo
    self.getBreedStatScore_ = getBreedStatScore or function(info)
        return info.ga + info.gr - info.re
    end
end

function BreedFarm:reportLowest()
    error("not implemented")
end

---@param crop ScannedInfo
---@return string
function BreedFarm:reportCropQuality(crop)
    return string.format(
        "{name=%s, stat=%d}",
        crop.name, self.getBreedStatScore_(crop)
    )
end

---@param newCrop ScannedInfo the crop to try upgrading with
---@param funcTransplant fun(parentPos: Position)
---@param onFail fun() gets called if the provided crop is not better than the existing parent crops
---@return ScannedInfo? oldCrop
function BreedFarm:upgradeParentCrop_(newCrop, funcTransplant, onFail)
    local upgradeSlot, cropToUpgrade = self:nextSlotToUpgrade(newCrop)
    if upgradeSlot then
        if cropToUpgrade then
            print(string.format(
                "Breed farm: transplanting offspring %s to upgrade parent %s at %s",
                self:reportCropQuality(newCrop),
                self:reportCropQuality(cropToUpgrade),
                posUtil.posToString(self:slotToPos(upgradeSlot))
            ))
        else
            print(string.format(
                "Breed farm: transplanting offspring %s to %s as new parent",
                self:reportCropQuality(newCrop), posUtil.posToString(self:slotToPos(upgradeSlot))
            ))
        end
        funcTransplant(self:slotToPos(upgradeSlot))
        self.parentSlotsInfo_[upgradeSlot] = newCrop
        self:onParentSlotsChanged_()
        self:onParentCropUpgraded_(newCrop, upgradeSlot, cropToUpgrade)
    else
        onFail()
    end
end

---@param slot integer
function BreedFarm:removeParentCropAt(slot)
    if not self:isParentSlot(slot) then
        error(slot .. " is not a parent slot", 2)
    end
    error("not implemented")
end

--[[
    Given a new crop, finds the next parent slot to upgrade.

    If there is no need to upgrade, returns nil.
    If there is a slot to be upgraded, but there is no crop in it to replace,
    returns the slot only.
]]
---@param newCrop ScannedInfo
---@return integer? parentSlot
---@return ScannedInfo? parentCropToUpgrade
function BreedFarm:nextSlotToUpgrade(newCrop)
    error("not implemented")
end

--[[
    Gets called after any parent slot has been changed, e.g.
    after adding/upgrading/removing a parent.
]]
function BreedFarm:onParentSlotsChanged_()
    -- do nothing
end

--[[
    Gets called after upgrading a parent crop
]]
---@param newCrop ScannedInfo
---@param slot integer
---@param oldCrop ScannedInfo?
function BreedFarm:onParentCropUpgraded_(newCrop, slot, oldCrop)
    -- do nothing
end

return BreedFarm
