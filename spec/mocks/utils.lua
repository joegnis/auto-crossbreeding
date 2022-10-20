local BreedFarm = require "farms.BreedFarm"
local StorageFarm = require "farms.StorageFarm"
local utils = require "utils"

local MockFarm = require "spec.mocks.MockFarm"


local M = {}

---@param position Position
---@param breedFarm MockFarm
---@param storageFarm MockFarm
---@param doInBreed fun(size: integer, slot: integer, pos: Position)
---@param doInStorage fun(size: integer, slot: integer, pos: Position)
---@param doOther? fun(pos: Position)
---@return any
function M.doIfInFarm_(position, breedFarm, storageFarm, doInBreed, doInStorage, doOther)
    local breedFarmSize = breedFarm:size()
    local storageFarmSize = storageFarm:size()
    if BreedFarm:isPosInFarm(position, breedFarmSize) then
        return doInBreed(
            breedFarmSize, BreedFarm:posToSlot(position, breedFarmSize), position
        )
    elseif StorageFarm:isPosInFarm(position, storageFarmSize) then
        return doInStorage(
            storageFarmSize, StorageFarm:posToSlot(position, storageFarmSize), position
        )
    else
        if doOther then
            return doOther(position)
        end
    end
end

---@param position Position
---@param breedFarm MockFarm
---@param storageFarm MockFarm
---@param doInFarm fun(farm: MockFarm, slot: integer, pos: Position)
---@param doOther? fun(pos: Position)
---@return any
function M.doIfInEitherFarm_(position, breedFarm, storageFarm, doInFarm, doOther)
    local breedFarmSize = breedFarm:size()
    local storageFarmSize = storageFarm:size()
    if BreedFarm:isPosInFarm(position, breedFarmSize) then
        return doInFarm(
            breedFarm, BreedFarm:posToSlot(position, breedFarmSize), position
        )
    elseif StorageFarm:isPosInFarm(position, storageFarmSize) then
        return doInFarm(
            storageFarm, StorageFarm:posToSlot(position, storageFarmSize), position
        )
    else
        if doOther then
            return doOther(position)
        end
    end
end

--[[
    Creates a MockFarm instance from a simplified slot map and a farm block map.

    In a slot map, use single letters to represent (most) blocks for simplicity.
    Crop slot can not use a single letter since it needs to be created
    with arguments.
    - nil: air
    - "w": weed
    - "s": crop stick
    - "o": other
    - others are passed through, e.g. crops
]]
---@param size integer
---@param slotsMap string[]?
---@param farmBlocksMap boolean[]?
function M.createFarmFromMaps(size, slotsMap, farmBlocksMap)
    local slotsInfoMap
    if slotsMap then
        slotsInfoMap = {}
        for slot, block in pairs(slotsMap) do
            if block == "w" then
                slotsInfoMap[slot] = utils.ScannedInfoFactory.newWeed()
            elseif block == "s" then
                slotsInfoMap[slot] = utils.ScannedInfoFactory.newCropStick()
            elseif block == "o" then
                slotsInfoMap[slot] = utils.ScannedInfoFactory.newOther("stone")
            elseif block ~= nil then
                slotsInfoMap[slot] = block
            end
        end
    end
    return MockFarm:newFromMap(size, slotsInfoMap, farmBlocksMap)
end

return M
