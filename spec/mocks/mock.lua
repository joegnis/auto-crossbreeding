local utils = require "utils"

local mockAction = require "spec.mocks.mockAction"
local mockGps = require "spec.mocks.mockGps"

local M = {}


---------------------------
-- Mocking Local Modules --
---------------------------

function M.mockGps()
    M.mockRobot()
    package.loaded["gps"] = nil
    local realGps = require "gps"
    ---@type Gps
    local gps = {}
    gps.new = realGps.new
    gps.go = mockGps.mockGo()
    gps.backOrigin = mockGps.mockBackOrigin()

    package.loaded["gps"] = gps
end

---@param mockBreedFarm MockFarm
---@param mockStorageFarm MockFarm
function M.mockAction(mockBreedFarm, mockStorageFarm)
    M.mockComponent()
    M.mockRobot()
    M.mockOs()
    M.mockSides()
    package.loaded["action"] = nil
    local realAction = require "action"
    ---@type Action
    local Action = {}
    Action.new = realAction.new
    Action.scanBelow = mockAction.mockScanBelow(mockBreedFarm, mockStorageFarm)
    Action.deweed = mockAction.mockDeweed(mockBreedFarm, mockStorageFarm)
    Action.breakCrop = mockAction.mockBreakCrop(mockBreedFarm, mockStorageFarm)
    Action.testsIfFarmlandBelow = mockAction.mockTestsIfFarmlandBelow(
        mockBreedFarm, mockStorageFarm
    )

    package.loaded["action"] = Action
end

---@param breedFarm MockFarm
---@param storageFarm MockFarm
function M.mockFarmer(breedFarm, storageFarm)
    M.mockComputer()
    M.mockRobot()
    M.mockAction(breedFarm, storageFarm)
    M.mockGps()
    package.loaded["farmers.Farmer"] = nil
    local realFarmer = require "farmers.Farmer"
    ---@type Farmer
    local Farmer = {}
    Farmer.new = realFarmer.new
    Farmer.init_ = realFarmer.init_
    Farmer.facing = realFarmer.facing
    Farmer.pos = realFarmer.pos
    Farmer.spadeSlot = realFarmer.spadeSlot
    Farmer.binderSlot = realFarmer.binderSlot
    Farmer.cropStickSlot = realFarmer.cropStickSlot
    Farmer.storageEndSlot = realFarmer.storageEndSlot
    Farmer.chargeLevel = realFarmer.chargeLevel
    Farmer.needsCharge = realFarmer.needsCharge
    Farmer.isFullyCharged = realFarmer.isFullyCharged
    Farmer.chargeIfLowEnergy = realFarmer.chargeIfLowEnergy
    Farmer.scanFarm = realFarmer.scanFarm
    package.loaded["farmers.Farmer"] = Farmer
end

---@param breedFarm MockFarm
---@param storageFarm MockFarm
function M.mockCrossbreeder(breedFarm, storageFarm)
    M.mockFarmer(breedFarm, storageFarm)
    local Farmer = require "farmers.Farmer"
    package.loaded["farmers.Crossbreeder"] = nil
    local realCrossbreeder = require "farmers.Crossbreeder"
    --[[@as Crossbreeder]]
    local Crossbreeder = utils.inheritsFrom(Farmer)
    Crossbreeder.new = realCrossbreeder.new
    package.loaded["farmers.Crossbreeder"] = Crossbreeder
end

---@param breedFarm MockFarm
---@param storageFarm MockFarm
function M.mockStatFarmer(breedFarm, storageFarm)
    M.mockFarmer(breedFarm, storageFarm)
end

------------------------
-- Mocking OC Modules --
------------------------

function M.mockRobot(o)
    package.loaded["robot"] = o or {
        inventorySize = function()
            return 16
        end
    }
end

function M.mockComponent(o)
    package.loaded["component"] = o or {
        geolyzer = {},
        inventory_controller = {},
        redstone = {},
    }
end

function M.mockComputer(o)
    package.loaded["computer"] = o or {
        energy = function()
            return 100
        end,
        maxEnergy = function()
            return 100
        end
    }
end

function M.mockOs(o)
    package.loaded["os"] = o or {}
end

function M.mockSides(o)
    package.loaded["sides"] = o or {
        bottom = 0,
        down = 0,
        negy = 0,
        top = 1,
        up = 1,
        posy = 1,
        back = 2,
        north = 2,
        negz = 2,
        front = 3,
        south = 3,
        posz = 3,
        forward = 3,
        right = 4,
        west = 4,
        negx = 4,
        left = 5,
        east = 5,
        posx = 5,
    }
end

return M
