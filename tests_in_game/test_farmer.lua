local posUtil = require "posUtil"
local CrossbreedFarm = require "farms.CrossbreedFarm"
local StorageFarm = require "farms.StorageFarm"

local testUtils = require "tests_in_game.utils"


--[[
    Mainly tests two cases:
    1. Breed offspring -> Storage, when storage farm doesn't have the offspring yet
    2. Breed offspring -> Breed parent, when storage already has it and it is better
       than a parent
]]
local function testBreed()
    local breedSize = 3
    local storageSize = 3
    local farmer = testUtils.createTestFarmer()
    farmer.action:equippedOrExit(true, true, true)
    local storageCrops, storageEmptyLands =
    farmer:scanFarm(StorageFarm:iterAllSlotPos(storageSize), false)
    local storageFarm = StorageFarm:new(
        storageSize, storageCrops, storageEmptyLands,
        { "Micadia", "Titania", "God of Thunder", "Essence Berry", "Copper Oreberry" }
    )
    local breedFarm = CrossbreedFarm:new(breedSize, farmer:scanFarm(posUtil.allBreedParentsPos(breedSize)))
    farmer:breed(breedFarm, storageFarm)
    farmer.gps:backOrigin()
end

local function testScanCrossbreedFarm()
    local size = 5
    local farmer = testUtils.createTestFarmer()
    local farm = CrossbreedFarm:new(size, farmer:scanFarm(posUtil.allBreedParentsPos(size)))
    print(farm:reportLowest())
    farmer.gps:backOrigin()
end

local function testBreedLoop()
    local breedSize = 4
    local storageSize = 3
    local farmer = testUtils.createTestFarmer()
    farmer.action:equippedOrExit(true, true, true)
    local storageCrops, storageEmptyLands = farmer:scanFarm(
        StorageFarm:iterAllSlotPos(storageSize), false
    )
    local storageFarm = StorageFarm:new(
        storageSize, storageCrops, storageEmptyLands,
        { "Micadia", "Titania", "God of Thunder", "Essence Berry", "Copper Oreberry" }
    )
    local breedFarm = CrossbreedFarm:new(breedSize, farmer:scanFarm(posUtil.allBreedParentsPos(breedSize)))
    farmer:breedLoop(breedFarm, storageFarm)
    farmer.gps:backOrigin()
end

testBreedLoop()
