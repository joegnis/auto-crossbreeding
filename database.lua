local gps = require("gps")
local posUtil = require("posUtil")
local config = require("config")
local utils = require("utils")

--[[
If you are reading the source code and got confused by the whole "slot" thing,
here is some explanation:
So we have two farmlands:
A storage farm land for storing unseen crops.
Only one crop per type can exist in the storage farmland.
A farmland for main crossbreeding things, the crop used for crossbreeding
and the space for new crops to grow form a checkerboard pattern.
the slot number for storage farmland start with 1 and from the bottom-right corner of the land,
and the number increases in a zigzag pattern from right to left. Like this:
-------
|9|4|3|
|8|5|2|
|7|6|1|
-------
And the slot number for the main farmland follow the same rule as the storage farmland,
but the number increases from left to right. Like this:
-------
|3|4|9|
|2|5|8|
|1|6|7|
-------
]]
local M = {}

local farm = {} -- odd slots only
-- the center of this pos is the center of the multifarm.
-- you can find functions in posUtil to translate it to global pos.
local lastMultifarmPos = { 0, 0 }

function M.getFarm()
    return farm
end

function M.getLastMultifarmPos()
    return lastMultifarmPos
end

function M.setLastMultifarmPos(pos)
    lastMultifarmPos = pos
end

function M.scanFarm(farmSize)
    local farmArea = farmSize ^ 2

    gps.save()
    local countCrop = 0
    local countAir = 0
    -- Every other slot so this function scans like a chessboard
    for slot = 1, farmArea, 2 do
        gps.go(posUtil.farmToGlobal(slot, farmSize))
        local cropInfo = scanner.scan()
        farm[slot] = cropInfo
        if cropInfo.name == "air" then
            cropInfo.tier = 0
            cropInfo.gr = 0
            cropInfo.ga = 0
            cropInfo.re = 100
            countAir = countAir + 1
        elseif cropInfo.isCrop then
            countCrop = countCrop + 1
        end
    end
    print(string.format("Scanned breed farm's crossbreeding parents' locations: %d crops, %d air, %d other",
        countCrop, countAir, farmArea // 2 + 1 - countCrop - countAir))
    gps.resume()
end

function M.updateFarm(slot, crop)
    farm[slot] = crop
end

function M.nextMultifarmPos()
    local x = lastMultifarmPos[1]
    local y = lastMultifarmPos[2]

    if posUtil.multifarmPosIsRelayFarmland(lastMultifarmPos) then
        return posUtil.nextRelayFarmland(lastMultifarmPos)
    end

    local d = math.abs(x) + math.abs(y)
    local nextPossiblePos

    if x == 0 and y == 0 then
        nextPossiblePos = { 0, 4 }
    elseif x == -1 and y == d - 1 then
        if d == config.multifarmSize then
            return posUtil.nextRelayFarmland()
        else
            nextPossiblePos = { 0, d + 1 }
        end
    elseif x >= 0 and y > 0 then
        nextPossiblePos = { x + 1, y - 1 }
    elseif x > 0 and y <= 0 then
        nextPossiblePos = { x - 1, y - 1 }
    elseif x <= 0 and y < 0 then
        nextPossiblePos = { x - 1, y + 1 }
    elseif x < 0 and y >= 0 then
        nextPossiblePos = { x + 1, y + 1 }
    end

    if posUtil.multifarmPosIsRelayFarmland(nextPossiblePos) or not posUtil.multifarmPosInFarm(nextPossiblePos) then
        lastMultifarmPos = nextPossiblePos
        return M.nextMultifarmPos()
    else
        return nextPossiblePos
    end
end

function M.updateMultifarm(pos)
    lastMultifarmPos = pos
end

function M.scanMultifarm()
    gps.save()
    gps.go(config.elevatorPos)
    gps.down(3)
    while true do
        local nextPos = M.nextMultifarmPos()
        local nextGlobalPos = posUtil.multifarmPosToGlobalPos(nextPos)
        gps.go(nextGlobalPos)
        local cropInfo = scanner.scan()
        if cropInfo.name == "air" then
            break
        else
            M.updateMultifarm(nextPos)
        end
    end
    gps.go(config.elevatorPos)
    gps.up(3)
    gps.resume()
end

return M
