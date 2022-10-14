local StorageFarm = require "farms.StorageFarm"

local testUtils = require "testsInGame.utils"


local function testScanStorageFarm()
    local size = 5
    local farmer = testUtils.createTestFarmer()
    farmer.action:equippedOrExit(true, false, true)
    StorageFarm:new(size, farmer:scanFarm(StorageFarm:iterAllSlotPos(size), true))
    farmer.gps:backOrigin()
end

local function testCropBlacklist()
    local size = 1
    local farmer = testUtils.createTestFarmer()
    local scannedSlots, emptyLands = farmer:scanFarm(
        StorageFarm:iterAllSlotPos(size), true
    )
    local storageFarm = StorageFarm:new(
        size, scannedSlots, emptyLands, { "stickreed" }
    )
    local function testExists(name)
        print(string.format("%s: %s", name, storageFarm:cropExists(name)))
    end

    testExists("stickreed")
    testExists("terraWart")
    testExists("reed")
end

local function testCropExists()
    local size = 2
    local farmer = testUtils.createTestFarmer()
    local storageCrops, storageEmptyLands =
    farmer:scanFarm(StorageFarm:iterAllSlotPos(size), true)
    local storageFarm = StorageFarm:new(
        size, storageCrops, storageEmptyLands, { "stickreed" }
    )
    local function testExists(name)
        print(string.format("%s: %s", name, storageFarm:cropExists(name)))
    end

    testExists("StickReed")
    testExists("terraWart")
    testExists("Brown Mushrooms")
    testExists("Red Stonelilly")
    testExists("Saphhirum")
    testExists("reed")

    farmer.gps:backOrigin()
end

local function testAddCrop()
    local posSrcCrop = { 1, 1 }
    local size = 3
    local farmer = testUtils.createTestFarmer()
    farmer.action:equippedOrExit(true, true, true)
    local storageFarm = StorageFarm:new(
        size, farmer:scanFarm(StorageFarm:iterAllSlotPos(size))
    )
    storageFarm:addCrop({ name = "Stargatium" }, function(dest)
        farmer.action:transplantCrop(posSrcCrop, dest)
        farmer.gps:go(posSrcCrop)
        farmer.action:placeCropSticks(true)
    end)
    print(string.format("Crop exists: %s", storageFarm:cropExists("stargatium")))
    farmer.gps:backOrigin()
end

testScanStorageFarm()
