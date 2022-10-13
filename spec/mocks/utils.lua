local BreedFarm = require "farms.BreedFarm"
local StorageFarm = require "farms.StorageFarm"


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

return M
