local shell = require("shell")
local filesystem = require("filesystem")

local REPO = "https://raw.githubusercontent.com/joegnis/auto-crossbreeding"
local DEFAULT_BRANCH = "main"
local SCRIPTS = {
    "action.lua",
    "autoCrossbreed.lua",
    "autoStat.lua",
    "gps.lua",
    "posUtil.lua",
    "signal.lua",
    "transplant.lua",
    "utils.lua",
    "farmers/Farmer.lua",
    "farmers/Crossbreeder.lua",
    "farmers/StatFarmer.lua",
    "farms/BreedFarm.lua",
    "farms/StorageFarm.lua",
    "farms/CrossbreedFarm.lua",
    "farms/StatFarm.lua",
    "testsInGame/test_action.lua",
    "testsInGame/test_farmer.lua",
    "testsInGame/test_gps.lua",
    "testsInGame/test_posUtil.lua",
    "testsInGame/test_StorageFarm.lua",
    "testsInGame/utils.lua",
}
local CONFIGS = {
    "config.lua",
    "autoCrossbreedConfig.lua",
    "autoStatConfig.lua",
}
local DESCRIPTIONS = string.format([[
Usage:
./install [-b|--branch BRANCH] [-u|--update-file FILE]
./install [-b|--branch BRANCH] [-c|--update-config]
./install --help | -h

Options:
  -b --branch BRANCH     Downloads from a specific branch. Default is %s.
  -u --update-file FILE  Updates a specific file.
  -c --update-config     Updates all config files.
  -h --help              Shows this message.
]], DEFAULT_BRANCH)

---@param filename string
---@return boolean
local function exists(filename)
    return filesystem.exists(shell.getWorkingDirectory() .. "/" .. filename)
end

---Creates all missing directories along a path to a file
---@param file string
local function createDirectoriesAlongPathToFile(file)
    local relPath = filesystem.path(file)
    local absPath = filesystem.canonical(
        string.format(
            "%s/%s",
            shell.getWorkingDirectory(),
            relPath
        )
    )
    if filesystem.makeDirectory(absPath) then
        print("Created directory " .. relPath)
    end
end

---@param file string
---@param repo string
---@param branch string
local function downloadFile(file, repo, branch)
    createDirectoriesAlongPathToFile(file)
    shell.execute(string.format(
        "wget -f %s/%s/%s ./%s",
        repo, branch, file, file
    ))
end

---@param config string
---@param repo string
---@param branch string
local function downloadConfig(config, repo, branch)
    local backup = config .. ".bak"
    if exists(config) then
        if exists(backup) then
            shell.execute("rm " .. backup)
        end
        shell.execute(string.format("mv %s %s", config, backup))
        print(string.format("Backed up %s as %s", config, backup))
    end
    downloadFile(config, repo, branch)
end

local function main(args)
    local numArgs = 1
    local curArg = args[numArgs]
    if curArg == "--help" or curArg == "-h" then
        print(DESCRIPTIONS)
        return true
    end

    local branch = DEFAULT_BRANCH
    if curArg == "--branch" or curArg == "-b" then
        branch = args[numArgs + 1]
        numArgs = numArgs + 2
        if string.find(branch, "^-") then
            io.stderr:write("invalid branch name: " .. branch)
            return false
        end
    end

    local option = args[numArgs]
    if option == "-c" or option == "--update-config" then
        for _, config in ipairs(CONFIGS) do
            downloadConfig(config, REPO, branch)
        end
    elseif option == "-u" or option == "--update-file" then
        local fileArg = args[numArgs + 1]
        numArgs = numArgs + 2
        for _, config in ipairs(CONFIGS) do
            if fileArg == config then
                downloadConfig(fileArg, REPO, branch)
                return true
            end
        end
        downloadFile(fileArg, REPO, branch)
    elseif option == nil then
        for _, script in ipairs(SCRIPTS) do
            downloadFile(script, REPO, branch)
        end

        for _, config in ipairs(CONFIGS) do
            if not exists(config) then
                downloadFile(config, REPO, branch)
            else
                print("Skipped existing config file: " .. config)
            end
        end
    else
        error("unknown argument: " .. option)
    end
    return true
end

main({ ... })
