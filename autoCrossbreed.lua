local gps = require "gps"
local Action = require "action"
local posUtil = require "posUtil"
local config = require "autoCrossbreedConfig"
local StorageFarm = require "farms.StorageFarm"
local CrossbreedFarm = require "farms.CrossbreedFarm"
local Crossbreeder = require "farmers.Crossbreeder"
local utils = require "utils"

local DESCRIPTIONS = {
    "autoCrossbreed [-h|--help|help]",
    "autoCrossbreed reportStorageCrops",
    "",
    '"reportStorageCrops" reports duplicate crops and all distinct crops by scanning crops in storage farm.',
    'The "All crops" portion of the report can be used to fill out \'cropsBlacklist\' in config.',
    "Also, when 'scansSeed' is set in config, it scans seeds in the inventory at 'storagePos'.",
    "An extra storage will also be scanned for seeds if 'extraSeedsStoragePos' is set.",
}


---@param action Action
---@param storageFarmSize integer
---@param sort boolean?
---@param scansSeeds boolean?
---@param inventoryPos Position?
---@param seedInventoryPos Position?
local function reportStorageCrops(
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
    for _, pos in posUtil.allStoragePos(storageFarmSize) do
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
    if scansSeeds then
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

local function main(args, breedFarmSize, storageFarmSize)
    if args[1] then
        local arg1 = args[1]
        if arg1 == "-h" or arg1 == "--help" or arg1 == "help" then
            print(table.concat(DESCRIPTIONS, "\n"))
            return
        elseif arg1 == "reportStorageCrops" then
            local action = Action:new()
            reportStorageCrops(
                action, storageFarmSize, true,
                config.scansSeeds, action.storagePos, config.extraSeedsStoragePos
            )
            gps.backOrigin()
            return
        else
            io.stderr:write("unknown argument: " .. arg1 .. "\n")
            os.exit(false)
        end
    end

    local action = Action:new()
    action:checkEquipment(true, true, true)
    print("Working in auto-crossbreeding mode...")
    local farmer = Crossbreeder:new(action)
    local storageCrops, reverseStorageCrops, storageEmptyLands = action:scanFarm(
        posUtil.allStoragePos(storageFarmSize),
        config.checkStorageFarmland
    )
    local storageFarm = StorageFarm:new(
        storageFarmSize, storageCrops, reverseStorageCrops, storageEmptyLands,
        config.cropsBlacklist
    )
    -- ensures that robot does not wander around too far out, e.g. too far off ground
    gps.backOrigin()
    local breedFarm = CrossbreedFarm:new(
        breedFarmSize,
        action:scanFarm(posUtil.allBreedParentsPos(breedFarmSize), config.checkBreedFarmland)
    )
    farmer:breedLoop(breedFarm, storageFarm)
    gps.backOrigin()
end

local function testReportStorageCropsWithSeeds()
    local action = Action:new()
    reportStorageCrops(action, 2, true, true, action.storagePos, { 0, 7 })
    gps.backOrigin()
end

local function testReportStorageCropsWithSeedsWrongArg()
    local action = Action:new()
    reportStorageCrops(action, 2, true, true)
    gps.backOrigin()
end

local function testReportStorageCrops()
    local action = Action:new()
    reportStorageCrops(action, 2, true, false)
    gps.backOrigin()
end

main({ ... }, config.breedFarmSize, config.storageFarmSize)
