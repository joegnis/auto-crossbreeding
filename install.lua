local shell = require("shell")
local filesystem = require("filesystem")
local args = { ... }
local scripts = {
    "Action.lua",
    "autoCrossbreed.lua",
    "autoCrossbreedConfig.lua",
    "autoSpread.lua",
    "autoSpreadConfig.lua",
    "autoStat.lua",
    "autoStatConfig.lua",
    "config.lua",
    "database.lua",
    "gps.lua",
    "posUtil.lua",
    "signal.lua",
    "transplant.lua",
    "utils.lua",
    "farmers/Crossbreeder.lua",
    "farmers/Farmer.lua",
    "farms/BreedFarm.lua",
    "farms/CrossbreedFarm.lua",
    "farms/StorageFarm.lua",
    "tests_in_game/test_Action.lua",
    "tests_in_game/test_autoCrossbreed.lua",
    "tests_in_game/test_gps.lua",
    "tests_in_game/test_posUtil.lua",
    "tests_in_game/test_StorageFarm.lua",
}
local directories = {
    "farmers",
    "farms",
    "tests_in_game",
}

local function exists(filename)
    return filesystem.exists(shell.getWorkingDirectory() .. "/" .. filename)
end

local branch
local option
if #args == 0 then
    branch = "main"
else
    branch = args[1]
end

if branch == "help" then
    print("Usage:\n./install or ./install [branch] [updateconfig] [repository]")
    return
end

if args[2] ~= nil then
    option = args[2]
end

local repo = args[3] or "https://raw.githubusercontent.com/joegnis/auto-crossbreeding";
local function downloadFile(file)
    shell.execute(string.format(
        "wget -f %s/%s/%s ./%s",
        repo, branch, file, file
    ))
end

for _, dir in ipairs(directories) do
    filesystem.makeDirectory(dir)
end
for _, script in ipairs(scripts) do
    downloadFile(script)
end

if not exists("config.lua") then
    shell.execute(string.format("wget %s/%s/config.lua", repo, branch));
end

if option == "updateconfig" then
    if exists("config.lua") then
        if exists("config.bak") then
            shell.execute("rm config.bak")
        end
        shell.execute("mv config.lua config.bak")
        print("Moved config.lua to config.bak")
    end
    shell.execute(string.format("wget %s/%s/config.lua", repo, branch));
end
