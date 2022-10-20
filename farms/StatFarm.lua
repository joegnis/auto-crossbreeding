local BreedFarm = require "farms.BreedFarm"
local Deque = require "utils".Deque
local posUtil = require "posUtil"

--[[
    What's needed for init:
    - empty center slots
    - empty non-center slots
    - center crops
    - non-center crops
]]

---@class StatFarm: BreedFarmBase
---@field targetCropName_ string
---@field centerParents_ table<integer, ScannedInfo>
---@field emptyCenterSlots_ Deque
---@field nonCenterParents_ table<integer, ScannedInfo>
---@field emptyNonCenterParentSlots_ Deque
---@field lowestStatCenter_ integer
---@field lowestStatCenterSlot_ integer
---@field lowestStatNonCenterNonTarget_ integer
---@field lowestStatNonCenterNonTargetSlot_ integer
---@field lowestStatNonCenterTarget_ integer
---@field lowestStatNonCenterTargetSlot_ integer
local StatFarm = BreedFarm:newChildClass()

----------------------------------------
-- Inherited Class & Instance Methods --
----------------------------------------
function StatFarm:class()
    return StatFarm
end

--[[
    Creates an iterator of all parent crops' slots and positions

    e.g.
    |7| |9|d| |e|
    | |5| | |b| |
    |6| |a|c| |f|
    |2| |4|i| |j|
    | |0| | |g| |
    |1| |5|h| |k|
]]
---@param size integer? breed farm's size
---@return fun(): integer?, Position?
function StatFarm:iterParentSlotPos(size)
    size = size or self.size_
    local iterCenter = StatFarm:iterCenterParentSlotPos(size)
    local countCorner = 0
    local CORNER_OFFSETS = { { -1, -1 }, { -1, 1 }, { 1, 1 }, { 1, -1 } }
    ---@type integer?
    local centerSlot
    ---@type Position?
    local centerPos
    ---@type integer?
    local centerX
    ---@type integer?
    local centerY
    return function()
        if countCorner == 0 then
            centerSlot, centerPos = iterCenter()
            if centerPos then
                centerX, centerY = table.unpack(centerPos)
                countCorner = 1
                return centerSlot, centerPos
            else
                return nil, nil
            end
        else
            local xOff, yOff = table.unpack(CORNER_OFFSETS[countCorner])
            local pos = { centerX + xOff, centerY + yOff }

            if countCorner == 4 then
                countCorner = 0
            else
                countCorner = countCorner + 1
            end

            return self:posToSlot(pos, size), pos
        end
    end
end

---Tests if a slot is a parent slot
---@param slot integer
---@param size integer?
---@return boolean
function StatFarm:isParentSlot(slot, size)
    size = size or self.size_
    local x, y = table.unpack(self:slotToPos(slot, size))
    local offsetX = x - 1 - ((x - 1) // 3) * 3
    local offsetY = y - (y // 3) * 3
    return (offsetX == 1 and offsetY == 1) or (offsetX ~= 1 and offsetY ~= 1)
end

------------------------------
-- Class & Instance Methods --
------------------------------

--[[
    Iterator that returns all center parent crops' slots and positions.

    e.g.
    | | | | | | |
    | |2| | |3| |
    | | | | | | |
    | | | | | | |
    | |1| | |4| |
    | | | | | | |
]]
---@param size integer? breed farm's size
---@return fun(): integer?, Position? # slot and position iterator
function StatFarm:iterCenterParentSlotPos(size)
    size = size or self.size_
    local centerX = 2
    local centerY = 1
    local yDirection = 1
    return function()
        if centerX > size then
            return nil, nil
        else
            local pos = { centerX, centerY }

            centerY = centerY + 3 * yDirection
            if centerY >= size or centerY <= 0 then
                -- Changes iteration direction
                centerY = centerY - 3 * yDirection
                centerX = centerX + 3
                yDirection = -yDirection
            end

            return self:posToSlot(pos, size), pos
        end
    end
end

--[[
    Iterator that returns all non-center parent crops' slots and positions.
]]
---@param size integer? breed farm's size
---@return fun(): integer?, Position? # slot and position iterator
function StatFarm:iterNonCenterParentSlotPos(size)
    size = size or self.size_
    local iterCenter = StatFarm:iterCenterParentSlotPos(size)
    local countCorner = 0
    local CORNER_OFFSETS = { { -1, -1 }, { -1, 1 }, { 1, 1 }, { 1, -1 } }
    ---@type Position?
    local centerPos
    ---@type integer?
    local centerX
    ---@type integer?
    local centerY
    return function()
        if countCorner == 0 then
            _, centerPos = iterCenter()
            if centerPos then
                centerX, centerY = table.unpack(centerPos)
                countCorner = 1
            else
                return nil, nil
            end
        end

        local xOff, yOff = table.unpack(CORNER_OFFSETS[countCorner])
        local pos = { centerX + xOff, centerY + yOff }

        if countCorner == 4 then
            countCorner = 0
        else
            countCorner = countCorner + 1
        end

        return self:posToSlot(pos, size), pos
    end
end

---Tests if a slot is a center parent crop's slot
---@param slot integer
---@param size integer? breed farm's size
---@return boolean
function StatFarm:isCenterSlot(slot, size)
    size = size or self.size_
    local x, y = table.unpack(self:slotToPos(slot, size))
    return (x - 2) % 3 == 0 and (y - 1) % 3 == 0
end

---Tests if a slot is a non-center parent crop's slot
---@param slot integer
---@param size integer? breed farm's size
---@return boolean
function StatFarm:isNonCenterParentSlot(slot, size)
    size = size or self.size_
    local x, y = table.unpack(self:slotToPos(slot, size))
    local offsetX = x - 1 - ((x - 1) // 3) * 3
    local offsetY = y - (y // 3) * 3
    return offsetX ~= 1 and offsetY ~= 1
end

---Given a slot, returns its center slot
---@param slot integer
---@param size integer? breed farm's size
---@return integer
function StatFarm:getCenterSlotOf(slot, size)
    size = size or self.size_
    local x, y = table.unpack(self:slotToPos(slot, size))
    return self:posToSlot({ ((x - 1) // 3) * 3 + 2, (y // 3) * 3 + 1 }, size)
end

-----------------------------
-- Inherited Class Methods --
-----------------------------

---Creates a breed farm manager for auto-stat
---@param size integer
---@param targetCropName string
---@param parentCrops table<integer, ScannedInfo> parent crops' slot to their info
---@param emptyCenterSlots integer[]
---@param emptyNonCenterParentSlots integer[]
---@param getBreedStatScore funGetStatScore?
---@return StatFarm
function StatFarm:new(
    size, targetCropName, parentCrops,
    emptyCenterSlots, emptyNonCenterParentSlots,
    getBreedStatScore
)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)
    o:superClass().init_(o, size, parentCrops, getBreedStatScore)
    o.targetCropName_ = targetCropName
    o.emptyCenterSlots_ = Deque:newFromTable(emptyCenterSlots)
    o.emptyNonCenterParentSlots_ = Deque:newFromTable(emptyNonCenterParentSlots)
    o.lowestStatCenter_ = 64
    o.lowestStatCenterSlot_ = 0
    o.lowestStatNonCenterTarget_ = 64
    o.lowestStatNonCenterTargetSlot_ = 0
    o.lowestStatNonCenterNonTarget_ = 64
    o.lowestStatNonCenterNonTargetSlot_ = 0

    self:onParentSlotsChanged_()
    print(string.format(
        "Breed farm: %d parent slots in total; %d still available",
        math.ceil(o.size_ ^ 2 / 2), o.emptyCenterSlots_:size() + o.emptyNonCenterParentSlots_:size()
    ))
    print(o:reportLowest())
    return o
end

--------------------------------
-- Inherited Instance Methods --
--------------------------------

---@return string
function StatFarm:reportLowest()
    local crop = self.parentSlotsInfo_[self.lowestStatScoreSlot_]
    return string.format(
        "Breed farm: %s has the lowest stat score %d at %s.",
        self:reportCropQuality(crop),
        self.lowestStatScore_,
        posUtil.posToString(self:slotToPos(self.lowestStatScoreSlot_))
    )
end

--[[
    Given a new crop, finds the next parent slot to upgrade.

    If there is no need to upgrade, returns nil.
    If there is a slot to be upgraded, but there is no crop in it to replace,
    returns the slot only.

    Center parent crops decide offsprings' both stats and species, so
    we prioritize upgrading them.
]]
---@param newCrop ScannedInfo
---@return integer? parentSlot
---@return ScannedInfo? parentCropToUpgrade
function StatFarm:nextSlotToUpgrade(newCrop)
    local newCropScore = self.getBreedStatScore_(newCrop)
    local newCropName = newCrop.name
    if newCropName == self.targetCropName_ then
        if self.emptyCenterSlots_:size() > 0 then
            -- Priority 1: fill empty center slots
            return self.emptyCenterSlots_:peekLast()
        elseif newCropScore > self.lowestStatCenter_ then
            -- Priority 2: upgrade center crops
            local slot = self.lowestStatCenterSlot_
            return slot, self.parentSlotsInfo_[slot]
        elseif self.emptyNonCenterParentSlots_:size() > 0 then
            -- Priority 3: fill other empty parent slots
            return self.emptyNonCenterParentSlots_:peekLast()
        elseif newCropScore >= self.lowestStatNonCenterNonTarget_ then
            -- Priority 4: upgrade existing non-target parents
            -- Note it is >= instead of > because target crops priority > non-targets'
            local slot = self.lowestStatNonCenterNonTargetSlot_
            return slot, self.parentSlotsInfo_[slot]
        elseif newCropScore > self.lowestStatNonCenterTarget_ then
            -- Priority 5: upgrade existing target crops
            local slot = self.lowestStatNonCenterTargetSlot_
            return slot, self.parentSlotsInfo_[slot]
        end
    else
        if self.emptyNonCenterParentSlots_:size() > 0 then
            -- Priority 1: fill empty parent slots
            return self.emptyNonCenterParentSlots_:peekLast()
        elseif newCropScore > self.lowestStatNonCenterNonTarget_ then
            -- Priority 2: upgrade non-target parent crops
            local slot = self.lowestStatNonCenterNonTargetSlot_
            return slot, self.parentSlotsInfo_[slot]
        end
    end
end

---@param slot integer
function StatFarm:removeParentCropAt(slot)
    if not self:isParentSlot(slot) then
        error(slot .. " is not a parent slot", 2)
    end
    if self.parentSlotsInfo_[slot] then
        if self:isCenterSlot(slot) then
            self.emptyCenterSlots_:pushFirst(slot)
        else
            self.emptyNonCenterParentSlots_:pushFirst(slot)
        end
    end
    self.parentSlotsInfo_[slot] = nil
    self:onParentSlotsChanged_()
end

function StatFarm:onParentSlotsChanged_()
    local lowestStatCenter = 64
    local lowestStatCenterSlot = 0
    local lowestStatNonCenterTarget = 64
    local lowestStatNonCenterTargetSlot = 0
    local lowestStatNonCenterNonTarget = 64
    local lowestStatNonCenterNonTargetSlot = 0

    for slot, info in pairs(self.parentSlotsInfo_) do
        local score = self.getBreedStatScore_(info)
        local cropName = info.name
        if self:isCenterSlot(slot) then
            if score < lowestStatCenter then
                lowestStatCenter = score
                lowestStatCenterSlot = slot
            end
        elseif self:isParentSlot(slot) then
            if cropName == self.targetCropName_ then
                if score < lowestStatNonCenterTarget then
                    lowestStatNonCenterTarget = score
                    lowestStatNonCenterTargetSlot = slot
                end
            else
                if score < lowestStatNonCenterNonTarget then
                    lowestStatNonCenterNonTarget = score
                    lowestStatNonCenterNonTargetSlot = slot
                end
            end
        end
    end

    self.lowestStatCenter_ = lowestStatCenter
    self.lowestStatCenterSlot_ = lowestStatCenterSlot
    self.lowestStatNonCenterTarget_ = lowestStatNonCenterTarget
    self.lowestStatNonCenterTargetSlot_ = lowestStatNonCenterTargetSlot
    self.lowestStatNonCenterNonTarget_ = lowestStatNonCenterNonTarget
    self.lowestStatNonCenterNonTargetSlot_ = lowestStatNonCenterNonTargetSlot
end

--[[
    Gets called after upgrading a parent crop
]]
---@param newCrop ScannedInfo
---@param slot integer
---@param oldCrop ScannedInfo?
function StatFarm:onParentCropUpgraded_(newCrop, slot, oldCrop)
    -- If no crops were replaced, it means an empty slot was used
    if not oldCrop then
        if self:isCenterSlot(slot) then
            self.emptyCenterSlots_:popLast()
        elseif self:isParentSlot(slot) then
            self.emptyNonCenterParentSlots_:popLast()
        end
    end
end

return StatFarm
