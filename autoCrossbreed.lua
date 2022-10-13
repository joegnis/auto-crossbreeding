local gps = require "gps"
local Action = require "action"
local posUtil = require "posUtil"
local config = require "autoCrossbreedConfig"
local StorageFarm = require "farms.StorageFarm"
local CrossbreedFarm = require "farms.CrossbreedFarm"
local Crossbreeder = require "farmers.Crossbreeder"
local utils = require "utils"

local DESCRIPTIONS = [[
Usage:
autoCrossbreed [-h|--help|help]

Keeps crossbreeding in breed farm and saving new breeds to storage farm until 'maxBreedRound' is reached or storage farm is full.
Higher-tier crops obtained along the process will constantly replace lower-tier parent crops to get higher-tier breeds.

Subcommands:
autoCrossbreed reportStorage [-h|--help|help]
autoCrossbreed cleanUp [-h|--help|help]
]]

local DESCRIPTIONS_REPORT_STORAGE = [[
Usage:
autoCrossbreed reportStorage [-h|--help|help]

Reports duplicate crops and all distinct kinds of crops by scanning the storage farm.
Also, when 'scansSeeds' is set in config, it scans seeds in the inventory at 'storagePos' to take those into account in report.
An extra storage will also be scanned for seeds if 'extraSeedsStoragePos' config is present.

The "All crops" portion of the report can be used to fill out 'cropsBlacklist' in config.
]]

local DESCRIPTIONS_CLEANUP = [[
Usage:
autoCrossbreed cleanUp [-h|--help|help]

Destroys weeds, crops that act like weeds, and crop sticks in storage and breed farms.
]]


---@param action Action
---@param storageFarmSize integer
---@param sort boolean?
---@param scansSeeds boolean?
---@param inventoryPos Position?
---@param seedInventoryPos Position?
local function reportStorage(
    action, storageFarmSize, sort, scansSeeds, inventoryPos, seedInventoryPos
)
    if sort == nil then
        sort = true
    end
    scansSeeds = scansSeeds or false
    if scansSeeds and not inventoryPos then
        error("inventoryPos must be provided when scansSeeds is true", 2)
    end

    -- Scans storage farm
    local breedPositions = {}
    local countFarm = 0
    for _, pos in StorageFarm:iterAllSlotPos(storageFarmSize) do
        gps.go(pos)
        local posStr = posUtil.posToString(pos)
        local scanned = action:scanBelow()
        if scanned.isCrop then
            local breed = scanned.name
            if not breedPositions[breed] then
                breedPositions[breed] = { posStr }
            else
                breedPositions[breed][#breedPositions[breed] + 1] = posStr
            end
            countFarm = countFarm + 1
        end
    end

    local dupeReports = {}
    if countFarm > 0 then
        for breed, positions in pairs(breedPositions) do
            if #positions > 1 then
                dupeReports[#dupeReports + 1] = breed .. ": " .. table.concat(positions, ", ")
            end
        end
    end
    local countDupesInFarm = #dupeReports

    local breeds = breedPositions
    local dupeInvReports = {}
    local countInv = 0
    local countCommon = 0
    -- Scans seeds in inventories
    if scansSeeds and inventoryPos then
        local breedsInv = action:getBreedsFromSeedsInInventory(inventoryPos)
        if seedInventoryPos then
            breedsInv = utils.mergeSets(
                breedsInv,
                action:getBreedsFromSeedsInInventory(seedInventoryPos)
            )
        end

        if next(breedsInv) == nil then
            print("Seeds inventory is empty.")
        else
            -- Finds dupes between farm and inventory
            for breed in pairs(breedsInv) do
                local positions = breedPositions[breed]
                if positions then
                    dupeInvReports[#dupeInvReports + 1] = (
                        breed .. ": " .. table.concat(positions, ", "))
                    countCommon = countCommon + 1
                end
                countInv = countInv + 1
            end
            breeds = utils.mergeSets(breeds, breedsInv)
        end
    end

    -- Report
    if countFarm > 0 then
        print(string.format("Found %d crops in storage farm.", countFarm))
        if countDupesInFarm > 0 then
            print("Duplicate crops in storage farm:")
            print(table.concat(dupeReports, "\n"))
        else
            print("No duplicate crops were found.")
        end
    else
        print("Storage farm is empty.")
    end

    if scansSeeds then
        print()
        if countInv > 0 then
            print(string.format("Found %d distinct seeds in inventory.", countInv))
            if #dupeInvReports > 0 then
                print()
                print(countCommon .. " crops in both storage farm and inventory:")
                print(table.concat(dupeInvReports, "\n"))
            end
        else
            print(string.format("No seeds were found in inventory."))
        end
    end

    local breedsList = utils.setToList(breeds)
    if sort then
        table.sort(breedsList)
    end
    local countDistinct = countFarm - countDupesInFarm + countInv - countCommon
    print()
    print(string.format("All %d distinct crops: {", countDistinct))
    for _, breed in ipairs(breedsList) do
        print(string.format('    "%s",', breed))
    end
    print("}")
end

---@param action Action
---@param breedFarmSize integer
---@param storageFarmSize integer
local function cleanUp(action, breedFarmSize, storageFarmSize)
    action:cleanUpFarm(CrossbreedFarm:iterAllSlotPos(breedFarmSize))
    action:cleanUpFarm(StorageFarm:iterAllSlotPos(storageFarmSize))
    action:dumpLoots()
    gps.backOrigin()
end

---@param action Action
---@param breedFarmSize integer
---@param storageFarmSize integer
local function autoCrossbreed(action, breedFarmSize, storageFarmSize)
    action:equippedOrExit(true, true, true)
    print(string.format(
        "Started auto-crossbreeding. Breed farm size: %d, storage farm size: %d.",
        breedFarmSize, storageFarmSize
    ))
    -- Scans storage farm first
    local storageFarm = action:scanStorageFarm(
        storageFarmSize, config.checkStorageFarmland, config.cropsBlacklist
    )
    -- ensures that robot does not wander around too far out, e.g. too far off ground
    gps.backOrigin()
    -- Scans breed farm
    local breedFarm = CrossbreedFarm:new(
        breedFarmSize,
        action:scanFarm(posUtil.allBreedParentsPos(breedFarmSize), config.checkBreedFarmland)
    )
    local farmer = Crossbreeder:new(action)
    utils.safeDoPrintError(
        function()
            farmer:breedLoop(breedFarm, storageFarm)
        end,
        function()
            print("Breeding completed. Cleaning up farms...")
            cleanUp(action, breedFarmSize, storageFarmSize)
        end,
        function()
            print("Something went wrong during breeding. Cleaning up farms...")
            cleanUp(action, breedFarmSize, storageFarmSize)
        end
    )
end

---@param args string[]
---@param breedFarmSize integer
---@param storageFarmSize integer
local function main(args, breedFarmSize, storageFarmSize)
    local action = Action:new()
    if args[1] then
        local arg1 = args[1]
        if arg1 == "-h" or arg1 == "--help" or arg1 == "help" then
            print(DESCRIPTIONS)
            return
        elseif arg1 == "reportStorage" then
            if args[2] == "-h" or args[2] == "--help" or args[2] == "help" then
                print(DESCRIPTIONS_REPORT_STORAGE)
                return
            end
            reportStorage(
                action, storageFarmSize, true,
                config.scansSeeds, action.storagePos, config.extraSeedsStoragePos
            )
            gps.backOrigin()
            return
        elseif arg1 == "cleanUp" then
            if args[2] == "-h" or args[2] == "--help" or args[2] == "help" then
                print(DESCRIPTIONS_CLEANUP)
                return
            end
            action:equippedOrExit(true, false, false)
            cleanUp(action, breedFarmSize, storageFarmSize)
            gps.backOrigin()
            return
        else
            io.stderr:write("unknown argument: " .. arg1 .. "\n")
            os.exit(false)
        end
    end

    autoCrossbreed(action, breedFarmSize, storageFarmSize)
end

local function testReportStorageCropsWithSeeds()
    local action = Action:new()
    reportStorage(action, 2, true, true, action.storagePos, { 0, 7 })
    gps.backOrigin()
end

local function testReportStorageCropsWithSeedsWrongArg()
    local action = Action:new()
    reportStorage(action, 2, true, true)
    gps.backOrigin()
end

local function testReportStorageCrops()
    local action = Action:new()
    reportStorage(action, 2, true, false)
    gps.backOrigin()
end

main({ ... }, config.breedFarmSize, config.storageFarmSize)
