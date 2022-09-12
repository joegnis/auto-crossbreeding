local component = require("component")
local robot = require("robot")
local computer = require("computer")
local os = require("os")
local sides = require("sides")
local gps = require("gps")
local config = require("config")
local signal = require("signal")
local scanner = require("scanner")
local posUtil = require("posUtil")

local inventory_controller = component.inventory_controller

local function needCharge()
    return computer.energy() / computer.maxEnergy() < config.needChargeLevel
end

local function fullyCharged()
    return computer.energy() / computer.maxEnergy() > 0.99
end

local function fullInventory()
    for i = 1, robot.inventorySize() do
        if robot.count(i) == 0 then
            return false
        end
    end
    return true
end

local function charge(resume)
    if resume ~= false then
        gps.save()
    end

    gps.go(config.chargerPos)
    repeat
        os.sleep(0.5)
    until fullyCharged()

    if resume ~= false then
        gps.resume()
    end
end

local function restockStick(resume)
    local selectedSlot = robot.select()
    if resume ~= false then
        gps.save()
    end
    gps.go(config.stickContainerPos)
    robot.select(robot.inventorySize() + config.stickSlot)
    for i = 1, inventory_controller.getInventorySize(sides.down) do
        inventory_controller.suckFromSlot(sides.down, i, 64 - robot.count())
        if robot.count() == 64 then
            break
        end
    end
    if resume ~= false then
        gps.resume()
    end
    robot.select(selectedSlot)
end

local function dumpInventory(resume)
    local selectedSlot = robot.select()
    if resume ~= false then
        gps.save()
    end
    gps.go(config.storagePos)
    for i = 1, robot.inventorySize() + config.storageStopSlot do
        if robot.count(i) > 0 then
            robot.select(i)
            for e = 1, inventory_controller.getInventorySize(sides.down) do
                if inventory_controller.getStackInSlot(sides.down, e) == nil then
                    inventory_controller.dropIntoSlot(sides.down, e)
                    break;
                end
            end
        end
    end
    if resume ~= false then
        gps.resume()
    end
    robot.select(selectedSlot)
end

local function restockAll()
    gps.save()
    if config.takeCareOfDrops then
        dumpInventory()
    end
    restockStick(false)
    charge(false)
    gps.resume()
end

--[[
    Puts number `count` of crop sticks below the robot

    Returns false if it could not place the first stick, true otherwise
    Returns false even if it has successfully place double sticks
]]
local function placeCropStick(count)
    local placed = true
    if count == nil then
        count = 1
    end
    local selectedSlot = robot.select()
    if robot.count(robot.inventorySize() + config.stickSlot) < count + 1 then
        restockStick()
    end
    robot.select(robot.inventorySize() + config.stickSlot)
    inventory_controller.equip()

    local _, interact_result = robot.useDown()
    if interact_result ~= "item_placed" then
        placed = false
    else
        for _ = 1, count - 1 do
            robot.useDown()
        end
    end

    inventory_controller.equip()
    robot.select(selectedSlot)
    return placed
end

local function deweed()
    local selectedSlot = robot.select()
    if config.takeCareOfDrops and fullInventory() then
        dumpInventory()
    end
    robot.select(robot.inventorySize() + config.spadeSlot)
    inventory_controller.equip()
    robot.useDown()
    if config.takeCareOfDrops then
        robot.suckDown()
    end
    inventory_controller.equip()
    robot.select(selectedSlot)
end

local function transplant(src, dest)
    local selectedSlot = robot.select()
    gps.save()
    robot.select(robot.inventorySize() + config.binderSlot)
    inventory_controller.equip()

    -- transfer the crop to the relay location
    gps.go(config.dislocatorPos)
    robot.useDown(sides.down)
    gps.go(src)
    robot.useDown(sides.down, true) -- sneak-right-click on crops to prevent harvesting
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- transfer the crop to the destination
    robot.useDown(sides.down)
    gps.go(dest)
    if scanner.scan().name == "air" then
        placeCropStick()
    end
    robot.useDown(sides.down, true)
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- destroy the original crop
    gps.go(config.relayFarmlandPos)
    deweed()
    robot.swingDown()
    if config.takeCareOfDrops then
        robot.suckDown()
    end

    inventory_controller.equip()
    gps.resume()
    robot.select(selectedSlot)
end

--[[
    Transfers a crop using transvector

    It tries to put crop at dest, if it could not, it tries to put crop
    at dest provided by iterator iterAltDest

    The process:
    1. With binder in hand, click transvector
    2. Click the thing you want to swap
    3. Send a redstone signal to transvector
]]
local function transplantToStorageFarm(src, dest, iterAltDest)
    iterAltDest = iterAltDest or function() return nil end
    local selectedSlot = robot.select()
    gps.save()
    robot.select(robot.inventorySize() + config.binderSlot)
    inventory_controller.equip()

    -- transfer the crop to the relay location
    gps.go(config.dislocatorPos)
    robot.useDown(sides.down)
    gps.go(src)
    robot.useDown(sides.down, true) -- sneak-right-click on crops to prevent harvesting
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- transfer the crop to the destination
    robot.useDown(sides.down)
    gps.go(dest)
    local placeSuccess = true
    -- Uses scanner to avoid harvesting crops
    if scanner.scan().name ~= 'air' or not placeCropStick() then
        local prevDest = dest
        local altDest = iterAltDest()
        print(string.format(
            "Failed to place crop at %s, looking for another...",
            posUtil.posToString(prevDest)
        ))
        while altDest do
            gps.go(altDest)
            if scanner.scan().name == 'air' and placeCropStick() then
                print(string.format(
                    "Found slot %d to place crop",
                    posUtil.globalToStorage(altDest)
                ))
                break
            end
            prevDest = altDest
            altDest = iterAltDest()
        end
        if not altDest then
            -- Fails to place crop and we have no more storage slot
            placeSuccess = false
        end
    end
    if placeSuccess then
        robot.useDown(sides.down, true)
        gps.go(config.dislocatorPos)
        signal.pulseDown()

        -- destroy the original crop
        gps.go(config.relayFarmlandPos)
        deweed()
        robot.swingDown()
        if config.takeCareOfDrops then
            robot.suckDown()
        end
    end

    inventory_controller.equip()
    gps.resume()
    robot.select(selectedSlot)
    return placeSuccess
end


local function transplantToMultifarm(src, dest)
    local globalDest = posUtil.multifarmPosToGlobalPos(dest)
    local optimalDislocatorSet = posUtil.findOptimalDislocator(dest)
    local dislocatorPos = optimalDislocatorSet[1]
    local relayFarmlandPos = optimalDislocatorSet[2]

    local selectedSlot = robot.select()
    gps.save()

    if robot.count(robot.inventorySize() + config.stickSlot) < 2 then
        restockStick()
    end

    robot.select(robot.inventorySize() + config.binderSlot)
    inventory_controller.equip()

    -- transfer the crop to the relay location
    gps.go(config.elevatorPos)
    gps.down(3)
    gps.go(dislocatorPos)
    robot.useDown(sides.down)

    gps.go(config.elevatorPos)
    gps.up(3)
    gps.go(src)
    robot.useDown(sides.down, true) -- sneak-right-click on crops to prevent harvesting

    gps.go(config.elevatorPos)
    gps.down(3)
    gps.go(dislocatorPos)
    signal.pulseDown()

    if not (relayFarmlandPos[1] == globalDest[1] and relayFarmlandPos[2] == globalDest[2]) then
        -- transfer the crop to the destination
        robot.useDown(sides.down)
        gps.go(globalDest)
        placeCropStick()
        robot.useDown(sides.down, true)
        gps.go(dislocatorPos)
        signal.pulseDown()

        -- destroy the original crop
        gps.go(relayFarmlandPos)
        robot.swingDown()
    end

    gps.go(config.elevatorPos)
    gps.up(3)

    inventory_controller.equip()
    gps.resume()
    robot.select(selectedSlot)
end

local function destroyAll()
    for slot = 2, config.farmArea, 2 do
        gps.go(posUtil.farmToGlobal(slot))
        robot.swingDown()
        if config.takeCareOfDrops then
            robot.suckDown()
        end
    end
end

return {
    needCharge = needCharge,
    charge = charge,
    restockStick = restockStick,
    restockAll = restockAll,
    placeCropStick = placeCropStick,
    deweed = deweed,
    transplant = transplant,
    transplantToMultifarm = transplantToMultifarm,
    transplantToStorageFarm = transplantToStorageFarm,
    destroyAll = destroyAll
}
