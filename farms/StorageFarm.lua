local utils = require "utils"
local posUtil = require "posUtil"


---@class StorageFarm
---@field storage_ table<integer, ScannedInfo>
---@field reverseStorage_ table<string, integer>
---@field size_ integer
---@field emptyFarmlands_ Deque
---@field cropsBlacklist_ Set<string>
---@field countBreeds_ integer
local StorageFarm = {}

---Creates a StorageFarm instance
---@param size integer
---@param cropsInfo table<integer, ScannedInfo>
---@param reverseCropsInfo table<string, integer>
---@param emptyFarmlands Deque
---@param cropsBlacklist string[]? actually a Set, with case-insensitive crop names
---@return StorageFarm
function StorageFarm:new(
    size, cropsInfo, reverseCropsInfo, emptyFarmlands,
    cropsBlacklist
)
    local o = {}
    self.__index = self
    o = setmetatable(o, self)

    o.size_ = size
    o.storage_ = cropsInfo
    o.emptyFarmlands_ = emptyFarmlands

    o.reverseStorage_ = {}
    for name, slot in pairs(reverseCropsInfo) do
        o.reverseStorage_[string.lower(name)] = slot
    end

    cropsBlacklist = cropsBlacklist or {}
    o.cropsBlacklist_ = {}
    for _, crop in ipairs(cropsBlacklist) do
        o.cropsBlacklist_[string.lower(crop)] = true
    end

    print(string.format(
        "Storage farm: %d slots in total; %d still available; black list: [%s]",
        size ^ 2, emptyFarmlands:size(), table.concat(cropsBlacklist, ", ")
    ))

    local countBreeds = 0
    for _, _ in pairs(reverseCropsInfo) do
        countBreeds = countBreeds + 1
    end
    o.countBreeds_ = countBreeds
    return o
end

function StorageFarm:size()
    return self.size_
end

function StorageFarm:posToSlot(pos)
    return posUtil.posToStorageSlot(pos, self.size_)
end

function StorageFarm:slotToPos(slot)
    return posUtil.storageSlotToPos(slot, self.size_)
end

function StorageFarm:isFull()
    return 0 == self.emptyFarmlands_:size()
end

---Adds a crop to the storage farm
---@param crop ScannedInfo the crop to add
---@param transplantCropTo fun(dest: Position)
function StorageFarm:addCrop(crop, transplantCropTo)
    if self:isFull() then
        error("Storage farm is full.")
    end
    local slot = self.emptyFarmlands_:popLast()
    transplantCropTo(posUtil.storageSlotToPos(slot, self.size_))
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
