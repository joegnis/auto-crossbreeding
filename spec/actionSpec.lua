local CrossbreedFarm = require "farms.CrossbreedFarm"
local BreedFarm = require "farms.BreedFarm"
local StorageFarm = require "farms.StorageFarm"
local globalConfig = require "config".defaultConfig
local utils = require "utils"

local mocks = require "spec.mocks.mock"
local MockFarm = require "spec.mocks.MockFarm"
local specUtils = require "spec.mocks.utils"


---@param breedFarm MockFarm
---@param storageFarm MockFarm
---@return Farmer farmer
local function mockFarmer(breedFarm, storageFarm)
  mocks.mockCrossbreeder(breedFarm, storageFarm)
  local Crossbreeder = require "farmers.Crossbreeder"
  return Crossbreeder:new(globalConfig)
end

describe("Action", function()
  describe("deweeds", function()
    local breedFarms = {
      specUtils.createFarmFromMaps(3,
        {
          nil, "w", "w",
          nil, nil, nil,
          "w", nil, nil,
        }
      ),
      specUtils.createFarmFromMaps(3,
        {
          nil, nil, nil,
          "w", "w", nil,
          nil, nil, "w",
        }
      ),
      specUtils.createFarmFromMaps(6,
        {
          nil, nil, nil, nil, nil, nil,
          nil, nil, "w", nil, nil, nil,
          nil, nil, nil, nil, "w", nil,
          nil, "w", nil, nil, nil, nil,
          nil, nil, nil, nil, nil, nil,
          nil, nil, nil, nil, nil, "w",
        }
      )
    }

    for i = 1, #breedFarms do
      local breedFarm = breedFarms[i]
      local farmSize = breedFarm:size()
      it("breed farm no." .. i, function()
        local storageFarm = specUtils.createFarmFromMaps(breedFarm:size())
        local farmer = mockFarmer(breedFarm, storageFarm)

        for slot = 1, farmSize ^ 2 do
          farmer.gps:go(BreedFarm:slotToPos(slot, farmSize))
          farmer.action:deweed()
        end

        local isWeeds = {}
        local expected = {}
        for slot = 1, farmSize ^ 2 do
          isWeeds[#isWeeds + 1] = breedFarm:slotInfo(slot) ~= nil
          expected[#expected + 1] = false
        end
        assert.are.same(expected, isWeeds)
      end)
    end
  end)

  describe("tests if there is farm block below", function()
    local farmSizes = { 3, 3, 6 }
    local farmBlocksMaps = {
      {
        true, false, false,
        true, true, true,
        false, true, true,
      },
      {
        true, true, true,
        false, false, true,
        true, true, false,
      },
      {
        true, true, true, true, true, true,
        true, true, false, true, true, true,
        true, true, true, true, false, true,
        true, false, true, true, true, true,
        true, true, true, true, true, true,
        true, true, true, true, true, false,
      }
    }

    for i = 1, #farmSizes do
      local farmSize = farmSizes[i]
      local farmBlocksMap = farmBlocksMaps[i]
      it("in breed farm no." .. i, function()
        local breedFarm = specUtils.createFarmFromMaps(farmSize)
        local storageFarm = specUtils.createFarmFromMaps(farmSize, nil, farmBlocksMap)
        local farmer = mockFarmer(breedFarm, storageFarm)

        local actualFarmBlocks = {}
        for slot = 1, farmSize ^ 2 do
          farmer.gps:go(StorageFarm:slotToPos(slot, farmSize))
          actualFarmBlocks[#actualFarmBlocks + 1] = farmer.action:testsIfFarmlandBelow()
        end

        -- Tests
        assert.are.same(MockFarm:mapToSlotsTable(farmSize, farmBlocksMap), actualFarmBlocks)
      end)
    end
  end)

  describe("scans a breed farm", function()
    local c1 = utils.ScannedInfoFactory.newCrop("stickreed", 1, 1, 1, 4)
    local farmSizes = { 3 }
    local iterators = {
      CrossbreedFarm:iterParentSlotPos(3)
    }
    local checkFarmlandList = {
      true
    }
    local farmMaps = {
      {
        nil, nil, nil,
        c1, c1, c1,
        c1, nil, nil,
      }
    }
    local farmBlocksMaps = {
      {
        false, true, false,
        true, true, true,
        true, true, true,
      }
    }
    local expectedScannedInfosList = {
      {
        [1] = c1,
        [5] = c1,
      }
    }
    local expectedEmptySlotsList = {
      { 7 }
    }

    for i = 1, #iterators do
      local farmSize = farmSizes[i]
      local iterator = iterators[i]
      local checkFarmland = checkFarmlandList[i]
      local farmMap = farmMaps[i]
      local farmBlocksMap = farmBlocksMaps[i]
      local expectedScannedInfos = expectedScannedInfosList[i]
      local expectedEmptySlots = expectedEmptySlotsList[i]

      local testName = string.format("No. %d", i)
      it(testName, function()
        local breedFarm = specUtils.createFarmFromMaps(farmSize, farmMap, farmBlocksMap)
        local farmer = mockFarmer(breedFarm, specUtils.createFarmFromMaps(farmSize))
        local actualSlotsInfo, actualEmptySlots = farmer:scanFarm(iterator, checkFarmland)
        assert.are.same(expectedScannedInfos, actualSlotsInfo)
        assert.are.same(expectedEmptySlots, actualEmptySlots)
      end)
    end
  end)
end)
