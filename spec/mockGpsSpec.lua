local globalConfig = require "config".defaultConfig
local utils = require "utils"

local MockFarm = require "spec.mocks.MockFarm"
local mocks = require "spec.mocks.mock"


describe("mockGps", function()
  ---@module "farmers.Crossbreeder"
  local Crossbreeder
  ---@type Crossbreeder
  local farmer
  ---@type Gps
  local gps

  setup(function()
    mocks.mockCrossbreeder(
      MockFarm:new(3), MockFarm:new(3)
    )
    Crossbreeder = require "farmers.Crossbreeder"
    farmer = Crossbreeder:new(globalConfig)
    gps = farmer.gps
  end)

  describe("mocks movement", function()
    local locationLists = {
      { { 1, 0 } },
      { { 1, 0 }, { 2, 2 } },
      { { 1, 0 }, { 2, 2 }, { 3, 4 } },
    }
    local finalLocations = {
      { 1, 0 },
      { 2, 2 },
      { 3, 4 },
    }
    for i = 1, #locationLists do
      local name = string.format(
        "path %s to dest %s",
        utils.tableToString(locationLists[i]),
        utils.tableToString(finalLocations[i])
      )
      it(name, function()
        for _, loc in ipairs(locationLists[i]) do
          gps:go(loc)
        end
        assert.are.same(finalLocations[i], farmer:pos())
      end)
    end
  end)

  describe("mocks moving back to origin", function()
    local locationLists = {
      { { 1, 0 } },
      { { 1, 0 }, { 2, 2 } },
      { { 1, 0 }, { 2, 2 }, { 3, 4 } },
    }
    for i = 1, #locationLists do
      it(utils.tableToString(locationLists[i]), function()
        for _, loc in ipairs(locationLists[i]) do
          gps:go(loc)
        end
        gps:backOrigin()
        assert.are.same({ 0, 0 }, farmer:pos())
      end)
    end
  end)
end)
