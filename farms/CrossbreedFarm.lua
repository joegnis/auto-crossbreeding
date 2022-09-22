local posUtil = require "posUtil"
local BreedFarm = require "farms.BreedFarm"


---@class CrossbreedFarm: BreedFarm
---@field lowestTier_ integer
---@field lowestTierSlot_ integer
---@field lowestStatScoreInLTier_ integer
---@field lowestStatScoreInLTierSlot_ integer
local CrossbreedFarm = BreedFarm:newChildClass()

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
---@param cropsInfo table<integer, ScannedInfo>
---@param reverseCropsInfo table<string, integer>
---@param emptyFarmlands Deque
---@param getBreedStatScore funGetStatScore?
---@return CrossbreedFarm
function CrossbreedFarm:new(
    size, cropsInfo, reverseCropsInfo, emptyFarmlands,
    getBreedStatScore
)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)
    o:super().init_(o, size, cropsInfo, reverseCropsInfo, emptyFarmlands, getBreedStatScore)
    -- Child class specific init
    print(string.format(
        "Breed farm: %d parent slots in total; %d still available",
        math.ceil(o.size_ ^ 2 / 2), o.emptyParentSlots_:size()
    ))
    print(o:reportLowest())
    return o
end

---@return string
function CrossbreedFarm:reportLowest()
    local cropLowestTier = self.parentSlotsInfo_[self.lowestTierSlot_]
    local cropLowestScore = self.parentSlotsInfo_[self.lowestStatScoreInLTierSlot_]
    return string.format(
        "Breed farm: Lowest tier: %s at %s. Lowest stat among lowest-tiers': %s at %s",
        self:reportCropQuality(cropLowestTier), posUtil.posToString(self:slotToPos(self.lowestTierSlot_)),
        self:reportCropQuality(cropLowestScore), posUtil.posToString(self:slotToPos(self.lowestStatScoreInLTierSlot_))
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

function CrossbreedFarm:lowestTier()
    return self.lowestTier_
end

function CrossbreedFarm:lowestStatScoreInLowestTier()
    return self.lowestStatScoreInLTier_
end

---@param crop ScannedInfo
---@return integer? slot
function CrossbreedFarm:firstParentWorseThan_(crop)
    if crop.tier > self.lowestTier_ then
        return self.lowestTierSlot_
    elseif crop.tier == self.lowestTier_ then
        if self.getBreedStatScore_(crop) > self.lowestStatScoreInLTier_ then
            return self.lowestStatScoreInLTierSlot_
        end
    end
    return nil
end

function CrossbreedFarm:updateLowest_()
    self:updateLowestTierAndStatScore_()
end

function CrossbreedFarm:updateLowestTierAndStatScore_()
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

return CrossbreedFarm
