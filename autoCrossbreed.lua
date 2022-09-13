local gps = require("gps")
local action = require("action")
local database = require("database")
local scanner = require("scanner")
local posUtil = require("posUtil")
local config = require("config")
local robot = require("robot")

local BREED_FARM_SIZE = config.autoCrossBreed.breedFarmSize
local STORAGE_FARM_SIZE = config.autoCrossBreed.storageFarmSize
local BREED_FARM_AREA = BREED_FARM_SIZE ^ 2
local STORAGE_FARM_AREA = STORAGE_FARM_SIZE ^ 2

local lowestTier
local lowestTierSlot
local lowestStat
local lowestStatSlot

local function updateLowest(farmArea)
    lowestTier = 64
    lowestTierSlot = 0
    lowestStat = 64
    lowestStatSlot = 0
    local farm = database.getFarm()

    local hasEmptySlot = false;
    -- pairs() is slower than numeric for due to function call overhead.
    -- Find lowestest tier slot.
    for slot = 1, farmArea, 2 do
        local crop = farm[slot]
        -- Can handle the case where a slot is a machine like crop-matron
        -- Water block, etc is not supported yet
        if crop.name == "air" then
            lowestTierSlot = slot;
            lowestStatSlot = slot;
            hasEmptySlot = true;
            break;
        end

        -- If a slot is weed, this may fail
        if crop.isCrop and crop.tier < lowestTier then
            lowestTier = crop.tier
            lowestTierSlot = slot
        end
    end

    if hasEmptySlot then
        return;
    end

    -- Find lowest stats slot among the lowest tier crops.
    for slot = 1, farmArea, 2 do
        local crop = farm[slot]
        if crop.isCrop and crop.tier == lowestTier then
            local stat = crop.gr + crop.ga - crop.re
            if stat < lowestStat then
                lowestStat = stat
                lowestStatSlot = slot
            end
        end
    end
end

local function findSuitableFarmSlot(crop)
    -- if the return value > 0, then it's a valid crop slot
    -- if the return value == 0, then it's not a valid crop slot
    --     the caller may consider not to replace any crop.
    if crop.tier > lowestTier then
        return lowestTierSlot
    elseif crop.tier == lowestTier then
        if crop.gr + crop.ga - crop.re > lowestStat then
            return lowestStatSlot
        end
    end
    return 0
end

local function isWeed(crop)
    return crop.name == "weed" or
        crop.name == "Grass" or
        crop.gr > 23 or
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
        else
            if database.existInStorage(crop) then
                local suitableSlot = findSuitableFarmSlot(crop)
                if suitableSlot == 0 then
                    action.deweed()
                    action.placeCropStick()
                else
                    action.transplant(
                        posUtil.farmToGlobal(slot, BREED_FARM_SIZE),
                        posUtil.farmToGlobal(suitableSlot, BREED_FARM_SIZE)
                    )
                    action.placeCropStick(2)
                    database.updateFarm(suitableSlot, crop)
                    updateLowest(BREED_FARM_AREA)
                end
            else
                action.transplant(
                    posUtil.farmToGlobal(slot, BREED_FARM_SIZE),
                    posUtil.storageToGlobal(database.nextStorageSlot(), STORAGE_FARM_SIZE)
                )
                action.placeCropStick(2)
                database.addToStorage(crop)
            end
        end
    end
end

--[[
    Parent crop can get destroied by weed. There is a need to deweed and replant.
 ]]
local function checkParent(slot, crop)
    if crop.isCrop and isWeed(crop) then
        action.deweed();
        database.updateFarm(slot, nil);
    end
end

local function breedOnce(breedFarmSize)
    local breedFarmArea = breedFarmSize ^ 2
    for slot = 1, breedFarmArea, 1 do
        gps.go(posUtil.farmToGlobal(slot, breedFarmSize))
        local crop = scanner.scan()

        if (slot % 2 == 0) then
            checkOffspring(slot, crop);
        else
            checkParent(slot, crop);
        end

        -- breed farm may be too large to have enough crop sticks in one round
        if robot.count(robot.inventorySize() + config.stickSlot) < 2 then
            action.restockStick(true)
        end

        if action.needCharge() then
            action.charge()
        end
    end
end

local function init(breedFarmSize, storageFarmSize)
    database.scanFarm(breedFarmSize)
    database.scanStorage(storageFarmSize)
    updateLowest(breedFarmSize ^ 2)
    action.restockAll()
end

local function main()
    init(BREED_FARM_SIZE, STORAGE_FARM_SIZE)
    local breedRound = 0;
    while true do
        breedOnce(BREED_FARM_SIZE);
        gps.go({ 0, 0 });
        action.restockAll();

        breedRound = breedRound + 1;
        if (config.maxBreedRound and breedRound > config.maxBreedRound) then
            print('Max round reached, end cross-breeding.');
            break;
        end

        if #database.getStorage() >= STORAGE_FARM_AREA then
            print('Storage full, end cross-breeding.');
            break;
        end
    end
end

main()
