local Action = require "action"
local gps = require "gps"

local function main(args)
    if args[1] == "-h" or args[1] == "--help" or args[1] == "help" then
        print(
            "transplant [-h|--help|help] x1 y1 x2 y2\n\n" ..
            "Orders robot to transplant one crop to a position. " ..
            "Positions are relative to robot's initial position (0, 0)."
        )
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
    action:checkEquipment(true, true, true)
    action:transplantCrop({ x1, y1 }, { x2, y2 })
    gps.backOrigin()
end

main({...})
