local Action = require "action"
local gps = require "gps"
local posUtil = require "posUtil"
local StorageFarm = require "farms.StorageFarm"


local function testScanStorageFarm()
    local size = 5
    local action = Action:new()
    action:equippedOrExit(true, false, true)
    StorageFarm:new(size, action:scanFarm(posUtil.allStoragePos(size), true))
    gps.go({ 0, 0 })
end

local function testCropBlacklist()
    local size = 1
    local action = Action:new()
    local scannedSlots, reverseLookup, emptyLands = action:scanFarm(posUtil.allStoragePos(size), true)
    local storageFarm = StorageFarm:new(
        size, scannedSlots, reverseLookup, emptyLands,
        { "stickreed" }
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
    local action = Action:new()
    local storageCrops, reverseStorageCrops, storageEmptyLands =
        action:scanFarm(posUtil.allStoragePos(size), true)
    local storageFarm = StorageFarm:new(
        size, storageCrops, reverseStorageCrops, storageEmptyLands,
        {"stickreed"}
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

    gps.backOrigin()
end

local function testAddCrop()
    local posSrcCrop = { 1, 1 }
    local size = 3
    local action = Action:new()
    action:equippedOrExit(true, true, true)
    local storageFarm = StorageFarm:new(size, action:scanFarm(posUtil.allStoragePos(size)))
    storageFarm:addCrop({ name = "Stargatium" }, function(dest)
        action:transplantCrop(posSrcCrop, dest)
        gps.go(posSrcCrop)
        action:placeCropSticks(true)
    end)
    print(string.format("Crop exists: %s", storageFarm:cropExists("stargatium")))
    gps.backOrigin()
end

testAddCrop()
