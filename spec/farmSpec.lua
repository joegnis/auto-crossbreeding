local BreedFarm = require "farms.BreedFarm"
local StorageFarm = require "farms.StorageFarm"
local posUtil = require "posUtil"


describe("Farms", function()
  describe("test if a position is in the farm", function()
    local function testName(pos, isBreed, isInFarm)
      return string.format(
        "%s %s %s", posUtil.posToString(pos),
        isInFarm and "in" or "not in",
        isBreed and "breed farm" or "storage farm"
      )
    end

    local farmSizes = { 3 }
    for _, size in ipairs(farmSizes) do
      for slot = 1, size ^ 2 do
        local breedPos = BreedFarm:slotToPos(slot, size)
        it(testName(breedPos, true, true), function()
          assert.are.equal(true, BreedFarm:isPosInFarm(breedPos, size))
        end)
        it(testName(breedPos, false, false), function()
          assert.are.equal(false, StorageFarm:isPosInFarm(breedPos, size))
        end)

        local storagePos = StorageFarm:slotToPos(slot, size)
        it(testName(storagePos, false, true), function()
          assert.are.equal(true, StorageFarm:isPosInFarm(storagePos, size))
        end)
        it(testName(storagePos, true, false), function()
          assert.are.equal(false, BreedFarm:isPosInFarm(storagePos, size))
        end)
      end
    end
  end)
end)
