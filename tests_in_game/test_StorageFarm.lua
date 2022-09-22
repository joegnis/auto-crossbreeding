local Action = require "Action"
local gps = require "gps"
local posUtil = require "posUtil"
local StorageFarm = require "storageFarm"


local function testScanStorageFarm()
    local size = 5
    local action = Action:new()
    action:checkEquipment(true, false, true)
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
    local storageFarm = StorageFarm:new(
        size, action:scanFarm(posUtil.allStoragePos(size), true)
    )
    local function testExists(name)
        print(string.format("%s: %s", name, storageFarm:cropExists(name)))
    end

    testExists("stickreed")
    testExists("terraWart")
    testExists("Brown Mushrooms")
    testExists("Red Stonelilly")
    testExists("Saphhirum")
    testExists("reed")
end

local function testAddCrop()
    local posSrcCrop = { 2, 0 }
    local size = 3
    local action = Action:new()
    action:checkEquipment(true, true, true)
    local storageFarm = StorageFarm:new(size, action:scanFarm(posUtil.allStoragePos(size)))
    storageFarm:addCrop({ name = "Stargatium" }, function(dest)
        action:transplantCrop(posSrcCrop, dest)
        gps.go(posSrcCrop)
        action:placeCropSticks(true)
    end)
    gps.backOrigin()
end

testAddCrop()
