local gps = require "gps"
local Action = require "Action"
local posUtil = require "posUtil"
local config = require "autoCrossbreedConfig"
local StorageFarm = require "farms.StorageFarm"
local CrossbreedFarm = require "farms.CrossbreedFarm"
local Crossbreeder = require "farmers.Crossbreeder"


local function reportStorageCrops(storageFarmSize)
    local action = Action:new()
    local breeds = {}
    local numBreeds = 0
    local positions = {}
    for _, pos in posUtil.allStoragePos(storageFarmSize) do
        gps.go(pos)
        local posStr = posUtil.posToString(pos)
        local scanned = action:scanBelow()
        if scanned.isCrop then
            local cropName = scanned.name
            breeds[cropName] = true
            if not positions[cropName] then
                positions[cropName] = { posStr }
                numBreeds = numBreeds + 1
            else
                positions[cropName][#positions[cropName] + 1] = posStr
            end
        end
    end

    local dupeReports = {}
    for name, pos in pairs(positions) do
        if #pos > 1 then
            dupeReports[#dupeReports+1] = name .. ": " .. table.concat(pos, ", ")
        end
    end

    if numBreeds == 0 then
        print("Storage farm is empty.")
        return
    end

    if #dupeReports > 0 then
        print("Duplicate crops in storage farm: ")
        print(table.concat(dupeReports, "\n"))
    else
        print("No duplicate crops in storage farm")
    end

    print()
    print(string.format("All %d breeds in storage farm:", numBreeds))
    for name, _ in pairs(breeds) do
        print(string.format('"%s",', name))
    end
    gps.backOrigin()
end

local function main(args, breedFarmSize, storageFarmSize)
    if args[1] then
        local arg1 = args[1]
        if arg1 == "-h" or arg1 == "--help" or arg1 == "help" then
            print("autoCrossbreed [-h|--help|help]")
            print("autoCrossbreed reportStorageCrops")
            print()
            print("reportStorageCrops: scans storage farm and prints duplicate crops and all breeds")
            return
        elseif arg1 == "reportStorageCrops" then
            reportStorageCrops(storageFarmSize)
            return
        else
            io.stderr:write("unknown argument: " .. arg1)
            os.exit(false)
        end
    end

    local action = Action:new()
    action:checkEquipment(true, true, true)
    print("Working in auto-crossbreeding mode...")
    local farmer = Crossbreeder:new(action)
    local storageCrops, reverseStorageCrops, storageEmptyLands =
        action:scanFarm(
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
end

local function testReportStorage()
    local size = 2
    reportStorageCrops(size)
end

main({ ... }, config.breedFarmSize, config.storageFarmSize)
