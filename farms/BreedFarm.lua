local posUtil = require "posUtil"


---Base class of breed farms
---@alias funGetStatScore fun(cropInfo: ScannedInfo): integer
---@class BreedFarm
---@field size_ integer
---@field parentSlotsInfo_ table<integer, ScannedInfo>
---@field reverseParentsInfo_ table<string, integer>
---@field emptyParentSlots_ Deque
---@field lowestStatScore_ integer
---@field lowestStatScoreSlot_ integer
---@field getBreedStatScore_ funGetStatScore
local BreedFarm = {}

function BreedFarm:new()
    error("should not instantiate BreedFarm")
end

function BreedFarm:newChildClass()
    local o = {}
    self.__index = self
    o = setmetatable(o, self)

    function o:super()
        return self
    end

    return o
end

---For child class constructor to call
function BreedFarm:init_(size, cropsInfo, reverseCropsInfo, emptyFarmlands, getBreedStatScore)
    self.parentSlotsInfo_ = cropsInfo
    self.reverseParentsInfo_ = reverseCropsInfo
    self.emptyParentSlots_ = emptyFarmlands
    self.size_ = size
    self.getBreedStatScore_ = getBreedStatScore or function (info)
        return info.ga + info.gr - info.re
    end
    self:updateLowest_()
end

function BreedFarm:size()
    return self.size_
end

function BreedFarm:posToSlot(pos)
    return posUtil.posToBreedSlot(pos, self.size_)
end

function BreedFarm:slotToPos(slot)
    return posUtil.breedSlotToPos(slot, self.size_)
end

function BreedFarm:isFull()
    return 0 == self.emptyParentSlots_:size()
end

function BreedFarm:reportLowest()
    local crop = self.parentSlotsInfo_[self.lowestStatScoreSlot_]
    return string.format(
        "Breed farm: %s has the lowest stat score %d at %s.",
        self:reportCropQuality(crop),
        self.lowestStatScore_,
        posUtil.posToString(self:slotToPos(self.lowestStatScoreSlot_))
    )
end

---@param crop ScannedInfo
---@return string
function BreedFarm:reportCropQuality(crop)
    return string.format(
        "{name=%s, stat=%d}",
        crop.name, self.getBreedStatScore_(crop)
    )
end

---@param crop ScannedInfo the crop to try upgrading with
---@param transplantCropTo fun(parentPos: Position)
---@param noWorseCrop fun() gets called if the provided crop is not better than the existing parent crops
function BreedFarm:tryUpgradeParentCrop(crop, transplantCropTo, noWorseCrop)
    local slot
    if self:isFull() then
        slot = self:firstParentWorseThan_(crop)
        if not slot then
            noWorseCrop()
            return
        end
        print(string.format(
            "Breed farm: transplanting offspring %s to upgrade parent %s at %s",
            self:reportCropQuality(crop),
            self:reportCropQuality(self.parentSlotsInfo_[slot]),
            posUtil.posToString(self:slotToPos(slot))
        ))
    else
        slot = self.emptyParentSlots_:popLast()
        print(string.format(
            "Breed farm: transplanting offspring %s to %s as new parent",
            self:reportCropQuality(crop), posUtil.posToString(self:slotToPos(slot))
        ))
    end
    transplantCropTo(self:slotToPos(slot))
    self.parentSlotsInfo_[slot] = crop
    self:updateLowest_()
end

function BreedFarm:removeParentCropAt(slot)
    posUtil.assertParentSlot(slot)
    self.parentSlotsInfo_[slot] = nil
    self:updateLowest_()
end

---@param crop ScannedInfo
---@return integer? slot
function BreedFarm:firstParentWorseThan_(crop)
    if crop.tier > self.lowestStatScore_ then
        return self.lowestStatScoreSlot_
    end
    return nil
end

function BreedFarm:updateLowest_()
    self:updateLowestStatScore_()
end

function BreedFarm:updateLowestStatScore_()
    local lowestStatScore = 64
    local lowestStatScoreSlot = 0

    for slot, info in pairs(self.parentSlotsInfo_) do
        local score = self.getBreedStatScore_(info)
        if score < lowestStatScore then
            lowestStatScore = score
            lowestStatScoreSlot = slot
        end
    end

    self.lowestStatScore_ = lowestStatScore
    self.lowestStatScoreSlot_ = lowestStatScoreSlot
end

return BreedFarm
