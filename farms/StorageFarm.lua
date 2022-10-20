local Deque = require "utils".Deque
local Farm = require "farms.Farm"
local posUtil = require "posUtil"
local utils = require "utils"


---@class StorageFarm: FarmBase
---@field storage_ table<integer, ScannedInfo>
---@field reverseStorage_ table<string, integer>
---@field size_ integer
---@field emptyFarmlands_ Deque
---@field cropsBlacklist_ Set<string>
---@field countBreeds_ integer
local StorageFarm = Farm:newChildClass()

----------------------------------------
-- Inherited Class & Instance Methods --
----------------------------------------
function StorageFarm:class()
    return StorageFarm
end

---Given a slot in the farm, returns its position
---@param slot integer
---@param size integer? farm's size
---@return Position
function StorageFarm:slotToPos(slot, size)
    size = size or self.size_
    local pos = posUtil.breedSlotToPos(slot, size)
    pos[1] = -pos[1]
    return pos
end

---Given a position, returns its corresponding slot in the farm
---@param pos Position
---@param size integer? farm's size
---@return integer
function StorageFarm:posToSlot(pos, size)
    size = size or self.size_
    return posUtil.posToBreedSlot({ -pos[1], pos[2] }, size)
end

---@param pos Position
---@param size integer?
function StorageFarm:isPosInFarm(pos, size)
    size = size or self.size_
    local x, y = table.unpack(pos)
    return x < 0 and x >= -size and y >= 0 and y < size
end

-----------------------------
-- Inherited Class Methods --
-----------------------------

---Creates a StorageFarm instance.
---When "cropsBlacklist" is present, "cropExists" check will always return
---true for those crops in the list.
---@param size integer
---@param cropsInfo table<integer, ScannedInfo>
---@param emptyFarmlands integer[]
---@param cropsBlacklist string[]? an array of case-insensitive crop names
---@return StorageFarm
function StorageFarm:new(
    size, cropsInfo, emptyFarmlands,
    cropsBlacklist
)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)
    o:superClass().init_(o, size)

    o.storage_ = cropsInfo
    o.emptyFarmlands_ = Deque:newFromTable(emptyFarmlands)

    o.reverseStorage_ = {}
    for slot, info in pairs(cropsInfo) do
        o.reverseStorage_[string.lower(info.name)] = slot
    end
    o.countBreeds_ = utils.sizeOfTable(o.reverseStorage_)

    cropsBlacklist = cropsBlacklist or {}
    o.cropsBlacklist_ = {}
    for _, crop in ipairs(cropsBlacklist) do
        o.cropsBlacklist_[string.lower(crop)] = true
    end

    print(string.format(
        "Storage farm: %d slots in total; %d still available; black list: [%s]",
        size ^ 2, #emptyFarmlands, table.concat(cropsBlacklist, ", ")
    ))
    return o
end

----------------------
-- Instance Methods --
----------------------

function StorageFarm:isFull()
    return 0 == self.emptyFarmlands_:size()
end

---Adds a crop to the storage farm
---@param crop ScannedInfo the crop to add
---@param transplantCropTo fun(dest: Position)
function StorageFarm:addCrop(crop, transplantCropTo)
    if self:isFull() then
        error("Storage farm is full.", 2)
    end
    local slot = self.emptyFarmlands_:popLast()
    transplantCropTo(self.slotToPos(slot, self.size_))
    self.storage_[slot] = crop
    -- case insensitive
    local cropName = string.lower(crop.name)
    if self.reverseStorage_[cropName] ~= nil then
        self.countBreeds_ = self.countBreeds_ + 1
    end
    self.reverseStorage_[cropName] = slot
    print(string.format("Added '%s' to storage farm.", crop.name))
end

---Tests if a crop exists in the storage farm.
---Taking into account of the black list.
---Case insensitive when comparing crop's names
---@param cropName string
---@return boolean
function StorageFarm:cropExists(cropName)
    cropName = string.lower(cropName)
    return self.cropsBlacklist_[cropName] ~= nil or
        self.reverseStorage_[cropName] ~= nil
end

---@return string
function StorageFarm:reportStatus()
    return string.format(
        "Storage farm: %d breeds, %d slots left, %d slots occupied.",
        self.countBreeds_, self.emptyFarmlands_:size(),
        self.size_ ^ 2 - self.emptyFarmlands_:size()
    )
end

return StorageFarm
