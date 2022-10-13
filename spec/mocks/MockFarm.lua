---@class MockFarm
---@field size_ integer
---@field isFarmBlockSlots_ boolean[]
---@field slotsInfo_ ScannedInfo[]
local MockFarm = {}

---@param size integer
---@param slotsInfo? table<integer, ScannedInfo>
---@param nonFarmBlockSlots? integer[]
function MockFarm:new(size, slotsInfo, nonFarmBlockSlots)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)

    o.size_ = size
    o.isFarmBlockSlots_ = {}
    o.slotsInfo_ = {}
    for slot = 1, size ^ 2 do
        local info
        if slotsInfo and slotsInfo[slot] and slotsInfo[slot].name ~= "air" then
            info = slotsInfo[slot]
        end
        o.slotsInfo_[slot] = info
        table.insert(o.isFarmBlockSlots_, true)
    end
    if nonFarmBlockSlots then
        for _, slot in ipairs(nonFarmBlockSlots) do
            o.isFarmBlockSlots_[slot] = false
        end
    end

    return o
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

return MockFarm
