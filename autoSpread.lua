local event = require("event")
local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local action = require("action")
local config = require("config")
local robot = require("robot");

local BREED_FARM_SIZE = config.autoSpread.breedFarmSize
local STORAGE_FARM_SIZE = config.autoSpread.storageFarmSize
local BREED_FARM_AREA = BREED_FARM_SIZE ^ 2
local STORAGE_FARM_AREA = STORAGE_FARM_SIZE ^ 2

local args = { ... }

--[[
    The script aims to transfer stats from a parent crop type to the crop type
    desired but have low stats.

    [P, _, X],
    [_, T, _],
    [X, _, P],
    where P represents parent crop, T represents target crop. X represents a non-farmland
    block.

    According to IC2 breeding rule, The offspring of 2 plants have 45% chance to be either
    the parent plants, and 10% chance to be a new type of crop.
   Y-axis
   5 [6,  7, 18, ...]
   4 [5,  8, 17, ...]
   3 [4,  9, 16, ...]
   2 [3, 10, 15, ...]
   1 [2, 11, 14, ...]
   0 [1, 12, 13, ...]
      1   2   3  ...  X-axis
 ]]

local targetCrop;
local targetCropQueue;
-- Mapping from slot# to breeding cell.
local breedingCellMap = {};
local breedingCells = {};
local nextStorageSlot = 1

local BreedingCell = {};
function BreedingCell.new(center)
    local cell = {
        center = center,
        stats = nil,
    };

    function cell.slots()
        local slots = {};
        for dx = -1, 1 do
            for dy = -1, 1 do
                table.insert(slots, posUtil.globalToFarm(
                    { center[1] + dx, center[2] + dy }, BREED_FARM_SIZE));
            end
        end
        return slots;
    end

    function cell.isChildren(slot)
        local pos = posUtil.farmToGlobal(slot, BREED_FARM_SIZE);
        local c = cell.center;
        return math.abs(c[1] - pos[1]) + math.abs(c[2] - pos[2]) == 1;
    end

    function cell.isActive()
        return cell.stats == nil;
    end

    return cell;
end

local CropQueue = {};
function CropQueue.new(slotToStatMapping)
    local q = {
        stats = slotToStatMapping,
    };

    function q.updateStatsAtSlot(slot, stat)
        if q.lowestStat > stat then
            q.lowestStat = stat;
            q.lowestStatSlot = slot;
        end

        q.stats[slot] = stat;
    end

    function q.updateLowest()
        q.lowestStat = 64;
        for slot, stat in pairs(q.stats) do
            if stat < q.lowestStat then
                q.lowestStat = stat;
                q.lowestStatSlot = slot;
            end
        end
    end

    --[[ Try replace lowest stat slot in the queue with incoming pair.
    Returns true if the replacement is successful. ]]
    function q.replaceLowest(slot, stat)
        if stat > q.lowestStat then
            action.transplant(
                posUtil.farmToGlobal(slot, BREED_FARM_SIZE),
                posUtil.farmToGlobal(q.lowestStatSlot, BREED_FARM_SIZE)
            );
            q.stats[q.lowestStatSlot] = stat;
            q.updateLowest();
            return true;
        end
        return false;
    end

    q.updateLowest();
    return q;
end

local function isWeed(crop)
    return crop.name == "weed" or
        crop.name == "Grass" or
        crop.gr > 23 or
        (crop.name == "venomilia" and crop.gr > 7);
end

local function calculateBreedStats(crop)
    return crop.gr + crop.ga - crop.re;
end

local function calculateSpreadStats(crop)
    return crop.gr + crop.ga
end

local function checkChildren(slot, crop)
    if crop.name == "air" then
        action.placeCropStick(2);
        return;
    end

    if (not config.assumeNoBareStick) and crop.name == "crop" then
        action.placeCropStick();
        return;
    end

    if not crop.isCrop then
        return;
    end

    if isWeed(crop) then
        action.deweed();
        action.placeCropStick();
        return;
    end

    if crop.name == targetCrop then
        local breedStats = calculateBreedStats(crop);
        -- Populate breeding cells with high stats crop as priority.
        if targetCropQueue.lowestStat < config.autoSpread.breedTargetStats then
            print(string.format("Updating current breeding crop (lowest=%d) with crop with  gr=%d, ga=%d, re=%d",
                targetCropQueue.lowestStat, crop.gr, crop.ga, crop.re))
            if targetCropQueue.replaceLowest(slot, breedStats) then
                return;
            end
        end

        local spreadStats = calculateSpreadStats(crop)
        if spreadStats >= config.autoSpread.spreadTargetStats then
            print(string.format("Found new offspring with gr=%d, ga=%d, re=%d, to transport",
                crop.gr, crop.ga, crop.re))
            local firstFailed = false
            local transplantSuccess = action.transplantToStorageFarm(
                posUtil.farmToGlobal(slot, BREED_FARM_SIZE),
                posUtil.storageToGlobal(nextStorageSlot, STORAGE_FARM_SIZE),
                function ()
                    firstFailed = true
                    local nextSlot = nextStorageSlot
                    if nextSlot <= STORAGE_FARM_AREA then
                        nextStorageSlot = nextStorageSlot + 1
                        return posUtil.storageToGlobal(nextSlot, STORAGE_FARM_SIZE)
                    end
                end
            );
            if not firstFailed then
                nextStorageSlot = nextStorageSlot + 1
            end
            if transplantSuccess then
                print(string.format("Transported crop to storage slot %d",
                    nextStorageSlot - 1))
            else
                print(string.format("Failed transporting crop to storage slot %d",
                    nextStorageSlot - 1))
            end
            action.placeCropStick(2);
            return;
        end

        print(string.format(
            "Current crop's stats (gr=%d, ga=%d, re=%d) are lower than target (%d). Destroying...",
            crop.gr, crop.ga, crop.re, config.autoSpread.spreadTargetStats
        ))
    end

    action.deweed();
    action.placeCropStick();
end

local function spreadOnce()
    for slot = 1, BREED_FARM_AREA, 1 do
        local farmPos = posUtil.farmToGlobal(slot, BREED_FARM_SIZE);
        gps.go(farmPos);
        local crop = scanner.scan();

        local cell = breedingCellMap[slot];
        if cell.isChildren(slot) then
            checkChildren(slot, crop);
        end

        if nextStorageSlot > STORAGE_FARM_AREA then
            print(string.format("Storage farm is full (%d). Stopping.", STORAGE_FARM_AREA))
            return true;
        end

        if action.needCharge() then
            action.charge()
        end
    end

    return false
end

local function cleanup()
    for slot = 1, BREED_FARM_AREA, 1 do
        local farmPos = posUtil.farmToGlobal(slot, BREED_FARM_SIZE);
        gps.go(farmPos);
        local cell = breedingCellMap[slot];
        if cell.isChildren(slot) then
            robot.swingDown();

            if config.takeCareOfDrops then
                robot.suckDown();
            end
        end
    end
end

local function init()
    for x = 1, BREED_FARM_SIZE // 3 do
        for y = 1, BREED_FARM_SIZE // 3 do
            -- for 6x6 farm, y = 1, 4; x = 2, 5
            local centerX = 3 * (x - 1) + 2;
            local centerY = 3 * (y - 1) + 1;
            local cell = BreedingCell.new({ centerX, centerY });

            for _, slot in ipairs(cell.slots()) do
                breedingCellMap[slot] = cell;
            end
            table.insert(breedingCells, cell);
        end
    end

    gps.save();
    local breedStats = {};
    for i, cell in ipairs(breedingCells) do
        local pos = cell.center;
        local slot = posUtil.globalToFarm(pos, BREED_FARM_SIZE);

        gps.go(pos);
        local crop = scanner.scan();
        breedStats[slot] = calculateBreedStats(crop);

        if i == 1 then
            targetCrop = crop.name;
            print(string.format('Target crop recognized: %s.', targetCrop));
        end
    end

    targetCropQueue = CropQueue.new(breedStats);

    action.restockAll();
    gps.resume();
end

local function main()
    init()
    while not spreadOnce() do
        gps.go({ 0, 0 })
        action.restockAll()

        local id = event.pull(0.5, "interrupted")
        if id ~= nil then
            break
        end
    end
    gps.go({ 0, 0 })
    if #args == 1 and args[1] == "docleanup" then
        cleanup();
        gps.go({ 0, 0 });
    end
    gps.turnTo(1)
    print("Done.\nThe Farm is filled up.")
end

main()
