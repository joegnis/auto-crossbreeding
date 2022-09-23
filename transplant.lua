local Action = require "action"
local gps = require "gps"

local DESCRIPTIONS = [[
Usage:
transplant [-h|--help|help] x1 y1 x2 y2

Transplants a crop at one position to another.
Positions are relative to robot's initial position (0, 0), e.g.

transplant -1 0 1 2
]]

local function main(args)
    if args[1] == "-h" or args[1] == "--help" or args[1] == "help" then
        print(DESCRIPTIONS)
        return
    end

    local x1 = tonumber(args[1])
    local y1 = tonumber(args[2])
    local x2 = tonumber(args[3])
    local y2 = tonumber(args[4])
    if not x1 or not y1 or not x2 or not y2 then
        error("Invalid arguments", 2)
    end
    local action = Action:new()
    action:equippedOrExit(true, true, true)
    action:transplantCrop({ x1, y1 }, { x2, y2 })
    gps.backOrigin()
end

main({...})
