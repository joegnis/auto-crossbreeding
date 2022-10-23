local BreedFarm = require "farms.BreedFarm"
local utils = require "utils"


---@class MockFarm
---@field size_ integer
---@field isFarmBlockSlots_ boolean[]
---@field slotsInfo_ table<integer, ScannedInfo>
local MockFarm = {}

---@param size integer
---@param slotsInfo? table<integer, ScannedInfo>
---@param isFarmBlocks? boolean[]
function MockFarm:new(size, slotsInfo, isFarmBlocks)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)

    o.size_ = size
    o.slotsInfo_ = slotsInfo or {}
    if not isFarmBlocks then
        o.isFarmBlockSlots_ = {}
        for i = 1, size ^ 2 do
            o.isFarmBlockSlots_[i] = true
        end
    else
        o.isFarmBlockSlots_ = isFarmBlocks
    end

    return o
end

--[[
    Creates a MockFarm instance from a slot map and a farm block map.

    Both maps mimic real in-game farm layouts.
    Their origin point is the (N - size - 1)th point, e.g. a map
    with each point's coordinate:
    {
        {3,1}, {3,2}, {3,3},
        {2,1}, {2,2}, {2,3},
        {1,1}, {1,2}, {1,3},
    }
]]
---@param size integer
---@param slotsMap (ScannedInfo|nil)[]?
---@param farmBlocksMap boolean[]?
function MockFarm:newFromMap(size, slotsMap, farmBlocksMap)
    return self:new(
        size,
        slotsMap and self:mapToSlotsTable(size, slotsMap),
        farmBlocksMap and self:mapToSlotsTable(size, farmBlocksMap)
    )
end

---@return integer
function MockFarm:size()
    return self.size_
end

---@param slot integer
---@param isFarmBlock boolean
function MockFarm:setBlockBelow(slot, isFarmBlock)
    self.isFarmBlockSlots_[slot] = isFarmBlock
end

---@param slot integer
---@return boolean
function MockFarm:isFarmBlockBelow(slot)
    return self.isFarmBlockSlots_[slot]
end

---@param slot integer
---@param scannedInfo ScannedInfo
function MockFarm:setSlot(slot, scannedInfo)
    self.slotsInfo_[slot] = scannedInfo
end

---@param slot integer
function MockFarm:clearSlot(slot)
    self.slotsInfo_[slot] = nil
end

---@param slot integer
---@return ScannedInfo
function MockFarm:slotInfo(slot)
    return self.slotsInfo_[slot]
end

---@param value1 any
---@param value2 any
function MockFarm.__eq(value1, value2)
    if utils.isInstance(value1, MockFarm) and utils.isInstance(value2, MockFarm) then
        return utils.isEqual(value1.slotsInfo_, value2.slotsInfo_)
            and utils.isEqual(value1.isFarmBlockSlots_, value2.isFarmBlockSlots_)
    end
    return false
end

---Converts a map used in newFromMap to a list in the order of slots.
---A class method.
---@generic T
---@param size integer
---@param map table<`T`>
---@return table<T>
function MockFarm:mapToSlotsTable(size, map)
    local slots = {}
    local i = 1
    for y = size - 1, 0, -1 do
        for x = 1, size do
            local slot = BreedFarm:posToSlot({ x, y }, size)
            slots[slot] = map[i]
            i = i + 1
        end
    end
    return slots
end

return MockFarm
