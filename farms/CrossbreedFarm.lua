local posUtil = require "posUtil"
local Deque = require "utils".Deque
local BreedFarm = require "farms.BreedFarm"


---@class CrossbreedFarm: BreedFarmBase
---@field emptyParentSlots_ Deque
---@field lowestTier_ integer
---@field lowestTierSlot_ integer
---@field lowestStatScoreInLTier_ integer
---@field lowestStatScoreInLTierSlot_ integer
local CrossbreedFarm = BreedFarm:newChildClass()

----------------------------------------
-- Inherited Class & Instance Methods --
----------------------------------------

---Creates an iterator of all parent crops' slots and positions
---@param size integer? breed farm's size
---@return fun(): integer?, Position?
function CrossbreedFarm:iterParentSlotPos(size)
    local farmArea = size ^ 2
    local slot = -1
    return function()
        slot = slot + 2
        if slot <= farmArea then
            return slot, self:slotToPos(slot, size)
        end
    end
end

---Tests if a slot is a parent slot
---@param slot integer
---@param size integer? breed farm's size
---@return boolean
function CrossbreedFarm:isParentSlot(slot, size)
    return slot % 2 == 1
end

-----------------------------
-- Inherited Class Methods --
-----------------------------

---Creates a breed farm manager for auto crossbreeding.
---In auto-crossbreeding mode, the goal is to get all IC crops stored in the storage farm.
---Parent crops should be planted every other farmland with double crop sticks in between.
---To start, plant at least two parent crops together.
---You can start with low-tier parents.
---To get high tier crops, low-tier parent crops will be replaced with their higher-tier
---offsprings.
---When an offspring has no higher tier than existing parents, its stats will be checked,
---and if stats is higher, it will replace its lowest-stats sibling.
---@param size integer
---@param parentCropsInfo table<integer, ScannedInfo>
---@param emptyParentSlots integer[]
---@param getBreedStatScore funGetStatScore?
---@return CrossbreedFarm
function CrossbreedFarm:new(
    size, parentCropsInfo, emptyParentSlots,
    getBreedStatScore
)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)
    o:superClass().init_(o, size, parentCropsInfo, getBreedStatScore)

    o.emptyParentSlots_ = Deque:newFromTable(emptyParentSlots)
    self:onParentSlotsChanged_()
    print(string.format(
        "Breed farm: %d parent slots in total; %d still available",
        math.ceil(o.size_ ^ 2 / 2), o.emptyParentSlots_:size()
    ))
    print(o:reportLowest())
    return o
end

--------------------------------
-- Inherited Instance Methods --
--------------------------------

---@return string
function CrossbreedFarm:reportLowest()
    local cropLowestTier = self.parentSlotsInfo_[self.lowestTierSlot_]
    local cropLowestScore = self.parentSlotsInfo_[self.lowestStatScoreInLTierSlot_]
    return string.format(
        "Breed farm: Lowest tier: %s at %s. Lowest stat among lowest-tiers': %s at %s",
        self:reportCropQuality(cropLowestTier),
        posUtil.posToString(self:slotToPos(self.lowestTierSlot_)),
        self:reportCropQuality(cropLowestScore),
        posUtil.posToString(self:slotToPos(self.lowestStatScoreInLTierSlot_))
    )
end

---@param crop ScannedInfo
---@return string
function CrossbreedFarm:reportCropQuality(crop)
    return string.format(
        "{name=%s, tier=%d, stat=%d}",
        crop.name,
        crop.tier,
        self.getBreedStatScore_(crop)
    )
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
function CrossbreedFarm:nextSlotToUpgrade(newCrop)
    if self.emptyParentSlots_.size_ == 0 then
        if newCrop.tier > self.lowestTier_ then
            local slot = self.lowestTierSlot_
            return slot, self.parentSlotsInfo_[slot]
        elseif newCrop.tier == self.lowestTier_ then
            if self.getBreedStatScore_(newCrop) > self.lowestStatScoreInLTier_ then
                local slot = self.lowestStatScoreInLTierSlot_
                return slot, self.parentSlotsInfo_[slot]
            end
        end
    else
        return self.emptyParentSlots_:peekLast()
    end
end

function CrossbreedFarm:onParentSlotsChanged_()
    local lowestTier = 64
    local lowestTierSlot = 0
    local lowestStatScore = 64
    local lowestStatScoreSlot = 0

    for slot, info in pairs(self.parentSlotsInfo_) do
        if info.tier < lowestTier then
            lowestTier = info.tier
            lowestTierSlot = slot
        end
    end

    for slot, info in pairs(self.parentSlotsInfo_) do
        if info.tier == lowestTier then
            local stat = self.getBreedStatScore_(info)
            if stat < lowestStatScore then
                lowestStatScore = stat
                lowestStatScoreSlot = slot
            end
        end
    end

    self.lowestTier_ = lowestTier
    self.lowestTierSlot_ = lowestTierSlot
    self.lowestStatScoreInLTier_ = lowestStatScore
    self.lowestStatScoreInLTierSlot_ = lowestStatScoreSlot
end

--[[
    Gets called after upgrading a parent crop
]]
---@param newCrop ScannedInfo
---@param slot integer
---@param oldCrop ScannedInfo?
function CrossbreedFarm:onParentCropUpgraded_(newCrop, slot, oldCrop)
    -- If no crops were replaced, it means an empty slot was used
    if not oldCrop then
        self.emptyParentSlots_:popLast()
    end
end

function CrossbreedFarm:removeParentCropAt(slot)
    if not self:isParentSlot(slot) then
        error(slot .. " is not a parent slot", 2)
    end
    if self.parentSlotsInfo_[slot] then
        self.emptyParentSlots_:pushFirst(slot)
    end
    self.parentSlotsInfo_[slot] = nil
    self:onParentSlotsChanged_()
end

----------------------
-- Instance Methods --
----------------------

function CrossbreedFarm:lowestTier()
    return self.lowestTier_
end

function CrossbreedFarm:lowestStatScoreInLowestTier()
    return self.lowestStatScoreInLTier_
end

return CrossbreedFarm
