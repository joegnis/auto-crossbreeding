local Action = require "Action"
local gps = require "gps"
local posUtil = require "posUtil"
local Crossbreeder = require "farmers.Crossbreeder"
local CrossbreedFarm = require "farms.CrossbreedFarm"
local StorageFarm = require "farms.StorageFarm"

--[[
    Mainly tests two cases:
    1. Breed offspring -> Storage, when storage farm doesn't have the offspring yet
    2. Breed offspring -> Breed parent, when storage already has it and it is better
       than a parent
]]
local function testBreed()
    local breedSize = 3
    local storageSize = 3
    local action = Action:new()
    action:checkEquipment(true, true, true)
    local worker = Crossbreeder:new(action)
    local storageCrops, reverseStorageCrops, storageEmptyLands =
    action:scanFarm(posUtil.allStoragePos(storageSize), false)
    local storageFarm = StorageFarm:new(
        storageSize, storageCrops, reverseStorageCrops, storageEmptyLands,
        { "Micadia", "Titania", "God of Thunder", "Essence Berry", "Copper Oreberry" }
    )
    local breedFarm = CrossbreedFarm:new(breedSize, action:scanFarm(posUtil.allBreedParentsPos(breedSize)))
    worker:breed(breedFarm, storageFarm)
    gps.backOrigin()
end

local function testScanCrossbreedFarm()
    local size = 5
    local action = Action:new()
    local farm = CrossbreedFarm:new(size, action:scanFarm(posUtil.allBreedParentsPos(size)))
    print(farm:reportLowest())
    gps.go({ 0, 0 })
end

testBreed()
