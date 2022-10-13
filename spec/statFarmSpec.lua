local StatFarm = require "farms.StatFarm"


describe("StatFarm", function()
  describe("iterates all center parent slots", function()
    local sizes = { 6 }
    local expectedSlotsLists = { { 11, 8, 29, 26 } }
    local expectedPositionsLists = {
      { { 2, 1 }, { 2, 4 }, { 5, 4 }, { 5, 1 } }
    }

    for i = 1, #sizes do
      local size = sizes[i]
      describe("of farm size " .. size, function()
        local expectedSlots = expectedSlotsLists[i]
        local expectedPositions = expectedPositionsLists[i]
        local actualSlots = {}
        local actualPositions = {}
        for slot, pos in StatFarm:iterCenterParentSlotPos(size) do
          actualSlots[#actualSlots + 1] = slot
          actualPositions[#actualPositions + 1] = pos
        end
        assert.are.same(actualSlots, expectedSlots)
        assert.are.same(actualPositions, expectedPositions)
      end)
    end
  end)

  describe("iterates all parent slots", function()
    local sizes = { 6 }
    local expectedSlotsLists = {
      {
        11, 1, 3, 15, 13,
        8, 4, 6, 18, 16,
        29, 21, 19, 31, 33,
        26, 24, 22, 34, 36,
      }
    }
    local expectedPositionsLists = {
      {
        { 2, 1 }, { 1, 0 }, { 1, 2 }, { 3, 2 }, { 3, 0 },
        { 2, 4 }, { 1, 3 }, { 1, 5 }, { 3, 5 }, { 3, 3 },
        { 5, 4 }, { 4, 3 }, { 4, 5 }, { 6, 5 }, { 6, 3 },
        { 5, 1 }, { 4, 0 }, { 4, 2 }, { 6, 2 }, { 6, 0 },
      }
    }

    for i = 1, #sizes do
      local size = sizes[i]
      describe("of farm size " .. size, function()
        local expectedSlots = expectedSlotsLists[i]
        local expectedPositions = expectedPositionsLists[i]
        local actualSlots = {}
        local actualPositions = {}
        for slot, pos in StatFarm:iterParentSlotPos(size) do
          actualSlots[#actualSlots + 1] = slot
          actualPositions[#actualPositions + 1] = pos
        end
        assert.are.same(actualSlots, expectedSlots)
        assert.are.same(actualPositions, expectedPositions)
      end)
    end
  end)

  describe("iterates all non-center parent slots", function()
    local sizes = { 6 }
    local expectedSlotsLists = {
      {
        1, 3, 15, 13,
        4, 6, 18, 16,
        21, 19, 31, 33,
        24, 22, 34, 36,
      }
    }
    local expectedPositionsLists = {
      {
        { 1, 0 }, { 1, 2 }, { 3, 2 }, { 3, 0 },
        { 1, 3 }, { 1, 5 }, { 3, 5 }, { 3, 3 },
        { 4, 3 }, { 4, 5 }, { 6, 5 }, { 6, 3 },
        { 4, 0 }, { 4, 2 }, { 6, 2 }, { 6, 0 }
      }
    }

    for i = 1, #sizes do
      local size = sizes[i]
      describe("of farm size " .. size, function()
        local expectedSlots = expectedSlotsLists[i]
        local expectedPositions = expectedPositionsLists[i]
        local actualSlots = {}
        local actualPositions = {}
        for slot, pos in StatFarm:iterNonCenterParentSlotPos(size) do
          actualSlots[#actualSlots + 1] = slot
          actualPositions[#actualPositions + 1] = pos
        end
        assert.are.same(actualSlots, expectedSlots)
        assert.are.same(actualPositions, expectedPositions)
      end)
    end
  end)

  describe("gets center slots of all slots", function()
    local sizes = { 6 }
    local expectedCentersLists = {
      {
        11, 11, 11,
        8, 8, 8,
        8, 8, 8,
        11, 11, 11,
        11, 11, 11,
        8, 8, 8,
        29, 29, 29,
        26, 26, 26,
        26, 26, 26,
        29, 29, 29,
        29, 29, 29,
        26, 26, 26,
      }
    }

    for i = 1, #sizes do
      local size = sizes[i]
      it("of farm size " .. size, function()
        local expectedCenters = expectedCentersLists[i]
        local actualCenters = {}
        for slot = 1, size ^ 2 do
          actualCenters[#actualCenters + 1] = StatFarm:getCenterSlotOf(slot, size)
        end
        assert.are.same(actualCenters, expectedCenters)
      end)
    end

  end)

  describe("tests a slot is a certain kinda slot", function()
    local sizes = { 6 }
    local expectedIsCenterSlotLists = {
      {
        false, false, false,
        false, false, false,
        false, true, false,
        false, true, false,
        false, false, false,
        false, false, false,
        false, false, false,
        false, false, false,
        false, true, false,
        false, true, false,
        false, false, false,
        false, false, false,
      }
    }
    local expectedIsNonCenterParentSlotLists = {
      {
        true, false, true,
        true, false, true,
        false, false, false,
        false, false, false,
        true, false, true,
        true, false, true,
        true, false, true,
        true, false, true,
        false, false, false,
        false, false, false,
        true, false, true,
        true, false, true,
      }
    }
    local expectedIsParentSlotLists = {
      {
        true, false, true,
        true, false, true,
        false, true, false,
        false, true, false,
        true, false, true,
        true, false, true,
        true, false, true,
        true, false, true,
        false, true, false,
        false, true, false,
        true, false, true,
        true, false, true,
      }
    }

    for i = 1, #sizes do
      local size = sizes[i]
      it("in a farm with size " .. size, function()
        local expectedIsCenterSlot = expectedIsCenterSlotLists[i]
        local expectedIsNonCenterParentSlot = expectedIsNonCenterParentSlotLists[i]
        local expectedIsParentSlot = expectedIsParentSlotLists[i]
        local actualIsCenterSlot = {}
        local actualIsNonCenterParentSlot = {}
        local actualIsParentSlot = {}
        for slot = 1, size ^ 2 do
          actualIsCenterSlot[#actualIsCenterSlot + 1] = StatFarm:isCenterSlot(slot, size)
          actualIsNonCenterParentSlot[#actualIsNonCenterParentSlot + 1] = StatFarm:isNonCenterParentSlot(slot, size)
          actualIsParentSlot[#actualIsParentSlot + 1] = StatFarm:isParentSlot(slot, size)
        end
        assert.are.same(actualIsCenterSlot, expectedIsCenterSlot)
        assert.are.same(actualIsNonCenterParentSlot, expectedIsNonCenterParentSlot)
        assert.are.same(actualIsParentSlot, expectedIsParentSlot)
      end)
    end
  end)
end)
