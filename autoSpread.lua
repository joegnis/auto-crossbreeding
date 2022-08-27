-- Set farmSize=6, and storageFarmSize=9 in config.lua to use this script.

local database = require("database")
local gps = require("gps")
local posUtil = require("posUtil")
local scanner = require("scanner")
local action = require("action")
local config = require("config")
local robot = require("robot");

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
-- The min stats requirement for target crop to be put into storage farm.
local targetCropStatsThreshold = 45;

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
                table.insert(slots, posUtil.globalToFarm({ center[1] + dx, center[2] + dy }));
            end
        end
        return slots;
    end

    function cell.isChildren(slot)
        local pos = posUtil.farmToGlobal(slot);
        local c = cell.center;
        return math.abs(c[1] - pos[1]) + math.abs(c[2] - pos[2]) == 1;
    end

    function cell.isActive()
        return stats == nil;
    end

    return cell;
end

-- Mapping from slot# to breeding cell.
local breedingCellMap = {};
local breedingCells = {};

for x = 1, config.farmSize // 3 do
    for y = 1, config.farmSize // 3 do
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
            action.transplant(posUtil.farmToGlobal(slot), posUtil.farmToGlobal(q.lowestStatSlot));
            q.stats[q.lowestStatSlot] = stat;
            q.updateLowest();
            return true;
        end
        return false;
    end

    q.updateLowest();
    return q;
end

local targetCropQueue;

local function isWeed(crop)
    return crop.name == "weed" or
        crop.name == "Grass" or
        crop.gr > 21 or
        (crop.name == "venomilia" and crop.gr > 7);
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
        local stat = calculateStats(crop);
        -- Populate breeding cells with high stats crop as priority.
        if targetCropQueue.lowestStat < targetCropStatsThreshold then
            if targetCropQueue.replaceLowest(slot, stat) then
                return;
            end
        end

        if stat >= targetCropStatsThreshold then
            action.transplant(posUtil.farmToGlobal(slot), posUtil.storageToGlobal(database.nextStorageSlot()));
            database.addToStorage(crop);
            action.placeCropStick(2);
            return;
        end
    end

    action.deweed();
    action.placeCropStick();
end

function calculateStats(crop)
    return crop.gr + crop.ga - crop.re;
end

local function spreadOnce()
    for slot = 1, config.farmArea, 1 do
        local farmPos = posUtil.farmToGlobal(slot);
        gps.go(farmPos);
        local crop = scanner.scan();

        local cell = breedingCellMap[slot];
        if cell.isChildren(slot) then
            checkChildren(slot, crop);
        end

        if #database.getStorage() >= 81 then
            return true;
        end

        if action.needCharge() then
            action.charge()
        end
    end

    return false
end

local function cleanup()
    for slot = 1, config.farmArea, 1 do
        local farmPos = posUtil.farmToGlobal(slot);
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
    gps.save();

    local stats = {};
    for i, cell in ipairs(breedingCells) do
        local pos = cell.center;
        local slot = posUtil.globalToFarm(pos);

        gps.go(pos);
        local crop = scanner.scan();
        stats[slot] = calculateStats(crop);

        if i == 1 then
            targetCrop = crop.name;
            print(string.format('Target crop recognized: %s.', targetCrop));
        end
    end

    targetCropQueue = CropQueue.new(stats);

    action.restockAll();
    gps.resume();
end

local function main()
    init()
    while not spreadOnce() do
        gps.go({ 0, 0 })
        action.restockAll()
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
