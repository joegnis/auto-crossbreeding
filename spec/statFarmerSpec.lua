local utils = require "utils"
local globalConfig = require "config".defaultConfig
local statConfig = require "autoStatConfig".defaultConfig

local mocks = require "spec.mocks.mock"
local specUtils = require "spec.mocks.utils"


---@param breedFarmSize integer
---@param storageFarmSize integer
---@param breedFarmMap (string|nil|ScannedInfo)[]?
---@param breedFarmBlocksMap boolean[]?
---@param storageFarmMap (string|nil|ScannedInfo)[]?
---@param storageFarmBlocksMap boolean[]?
---@param globalSetting GlobalConfig?
---@param statSetting StatConfig?
---@return StatFarmer
---@return MockFarm mockBreedFarm
---@return MockFarm mockStorageFarm
local function mockAll(
  breedFarmSize, storageFarmSize,
  breedFarmMap, breedFarmBlocksMap,
  storageFarmMap, storageFarmBlocksMap,
  globalSetting, statSetting
)
  local breedFarm = specUtils.createFarmFromMaps(breedFarmSize, breedFarmMap, breedFarmBlocksMap)
  local storageFarm = specUtils.createFarmFromMaps(storageFarmSize, storageFarmMap, storageFarmBlocksMap)
  mocks.mockStatFarmer(breedFarm, storageFarm)
  local StatFarmer = require "farmers.StatFarmer"
  return StatFarmer:new(
    globalSetting or globalConfig, statSetting or statConfig
  ), breedFarm, storageFarm
end

describe("A farmer in a stat farm", function()
  describe("scans", function()
    local c1 = utils.ScannedInfoFactory.newCrop("stickreed", 1, 1, 1, 4)
    local farmSizes = { 3 }
    local farmMaps = {
      {
        nil, nil, nil,
        nil, c1, nil,
        nil, nil, nil,
      }
    }
    local expectedTargetCrops = {
      "stickreed"
    }

    for i = 1, #farmMaps do
      local farmSize = farmSizes[i]
      local farmMap = farmMaps[i]
      local expectedTargetCrop = expectedTargetCrops[i]
      local statSetting = utils.shallowCopyTable(statConfig)
      statSetting.breedFarmSize = farmSize
      statSetting.storageFarmSize = farmSize

      it("farm " .. i .. " w/ one kind of target crops", function()
        local farmer, _, _ = mockAll(
          farmSize, farmSize, farmMap, nil, nil, nil,
          nil, statSetting
        )
        local statFarm, _ = farmer:scanBreedFarm()
        if statFarm then
          assert.are.equal(expectedTargetCrop, statFarm:targetCropName())
        else
          error("statFarm is empty")
        end
      end)
    end
  end)
end)
