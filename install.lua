local shell = require("shell")
local filesystem = require("filesystem")

local repo = "https://raw.githubusercontent.com/joegnis/auto-crossbreeding";
local scripts = {
    "action.lua",
    "autoCrossbreed.lua",
    "autoSpread.lua",
    "autoStat.lua",
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
    "tests_in_game/test_action.lua",
    "tests_in_game/test_autocrossbreed.lua",
    "tests_in_game/test_gps.lua",
    "tests_in_game/test_posUtil.lua",
    "tests_in_game/test_StorageFarm.lua",
}
local configs = {
    "config.lua",
    "autoCrossbreedConfig.lua"
}
local directories = {
    "farmers",
    "farms",
    "tests_in_game",
}
local DESCRIPTIONS = {
    "Usage:",
    "./install [--help|-h]",
    "./install branch",
    "./install branch --update-config",
    "./install branch -u [file]",
}

---@param filename string
---@return boolean
local function exists(filename)
    return filesystem.exists(shell.getWorkingDirectory() .. "/" .. filename)
end

---@param file string
---@param repoURL string
---@param branch string
local function downloadFile(file, repoURL, branch)
    shell.execute(string.format(
        "wget -f %s/%s/%s ./%s",
        repoURL, branch, file, file
    ))
end

---@param config string
---@param repoURL string
---@param branch string
local function downloadConfig(config, repoURL, branch)
    local backup = config .. ".bak"
    if exists(config) then
        if exists(backup) then
            shell.execute("rm " .. backup)
        end
        shell.execute(string.format("mv %s %s", config, backup))
        print(string.format("Backed up %s as %s", config, backup))
    end
    downloadFile(config, repoURL, branch)
end

local function main(args)
    local branch
    local option
    if #args == 0 then
        branch = "main"
    else
        branch = args[1]
    end

    if branch == "--help" or branch == "-h" then
        print(table.concat(DESCRIPTIONS, "\n"))
        return true
    elseif string.find(branch, "^-") then
        io.stderr:write("invalid branch name: " .. branch)
        return false
    end

    if args[2] ~= nil then
        option = args[2]
    end

    if option == "--update-config" then
        for _, config in ipairs(configs) do
            downloadConfig(config, repo, branch)
        end
    elseif option == "-u" then
        local fileArg = args[3]
        for _, config in ipairs(configs) do
            if fileArg == config then
                downloadConfig(fileArg, repo, branch)
                return true
            end
        end
        downloadFile(fileArg, repo, branch)
    elseif option == nil then
        for _, dir in ipairs(directories) do
            if not exists(dir) then
                shell.execute("mkdir " .. dir)
            else
                print("Skipped creating existing directory: " .. dir)
            end
        end

        for _, script in ipairs(scripts) do
            downloadFile(script, repo, branch)
        end

        for _, config in ipairs(configs) do
            if not exists(config) then
                downloadFile(config, repo, branch)
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
