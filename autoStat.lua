local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")

local args = { ... }
local nonstop = false
local docleanup = false
if #args == 1 then
    if args[1] == "docleanup" then
        docleanup = true
    elseif args[1] == "nonstop" then
        nonstop = true
    end
end

local lowestStat;
local lowestStatSlot;
local workingCrop;

local function updateLowest()
    lowestStat = 64
    lowestStatSlot = 0
    local farm = database.getFarm()
    local workingCropName = database.getFarm()[1].name
    for slot = 1, config.farmArea, 2 do
        local crop = farm[slot]
        if crop ~= nil then
            if crop.name == 'crop' then
                lowestStatSlot = slot
                break;
            else
                local stat = crop.gr + crop.ga - crop.re
                if stat < lowestStat then
                    lowestStat = stat
                    lowestStatSlot = slot
                end
            end
        end
    end
end

local function findSuitableFarmSlot(crop)
    if crop.gr + crop.ga - crop.re > lowestStat then
        return lowestStatSlot
    else
        return 0
    end
end

local function isWeed(crop)
    return crop.name == "weed" or
        crop.name == "Grass" or
        crop.gr > 21 or
        (crop.name == "venomilia" and crop.gr > 7);
end

local function checkOffspring(slot, crop)
    if crop.name == "air" then
        action.placeCropStick(2)
    elseif (not config.assumeNoBareStick) and crop.name == "crop" then
        action.placeCropStick()
    elseif crop.isCrop then
        if isWeed(crop) then
            action.deweed()
            action.placeCropStick()
        elseif crop.name == workingCrop then
            local suitableSlot = findSuitableFarmSlot(crop)
            if suitableSlot == 0 then
                action.deweed()
                action.placeCropStick()
            else
                action.transplant(posUtil.farmToGlobal(slot), posUtil.farmToGlobal(suitableSlot))
                action.placeCropStick(2)
                database.updateFarm(suitableSlot, crop)
                updateLowest()
            end
        elseif config.keepNewCropWhileMinMaxing and (not database.existInStorage(crop)) then
            action.transplant(posUtil.farmToGlobal(slot), posUtil.storageToGlobal(database.nextStorageSlot()))
            action.placeCropStick(2)
            database.addToStorage(crop)
        else
            action.deweed()
            action.placeCropStick()
        end
    end
end

local function checkParent(slot, crop)
    if crop.isCrop and isWeed(crop) then
        action.deweed();
        database.updateFarm(slot, { name = 'crop' });
        updateLowest();
    end
end

local function breedOnce()
    -- return true if all stats are maxed out
    -- 52 = 21(max gr) + 31(max ga) - 0 (min re)
    if not nonstop and lowestStat == 50 then
        return true
    end

    for slot = 1, config.farmArea, 1 do
        gps.go(posUtil.farmToGlobal(slot))
        local crop = scanner.scan()

        if (slot % 2 == 0) then
            checkOffspring(slot, crop);
        else
            checkParent(slot, crop);
        end

        if action.needCharge() then
            action.charge()
        end
    end
    return false
end

local function init()
    database.scanFarm()
    if config.keepNewCropWhileMinMaxing then
        database.scanStorage()
    end

    workingCrop = database.getFarm()[1].name;

    updateLowest()
    action.restockAll()
end

local function main()
    init()
    while not breedOnce() do
        gps.go({ 0, 0 })
        action.restockAll()
    end
    gps.go({ 0, 0 })
    if docleanup then
        action.destroyAll()
        gps.go({ 0, 0 })
    end
    if config.takeCareOfDrops then
        action.dumpInventory()
    end
    gps.turnTo(1)
    print("Done.\nAll crops are now 21/31/0")
end

main()
