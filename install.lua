local shell = require("shell")
local filesystem = require("filesystem")
local args = { ... }
local scripts = {
    "action.lua",
    "database.lua",
    "gps.lua",
    "posUtil.lua",
    "scanner.lua",
    "signal.lua",
    "autoStat.lua",
    "autoCrossbreed.lua",
    "autoSpread.lua",
    "install.lua"
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

local repo = args[3] or "https://raw.githubusercontent.com/huchenlei/auto-crossbreeding/";

for i = 1, #scripts do
    shell.execute(string.format("wget -f %s%s/%s", repo, branch, scripts[i]));
end

if not exists("config.lua") then
    shell.execute(string.format("wget %s%s/config.lua", repo, branch));
end

if option == "updateconfig" then
    if exists("config.lua") then
        if exists("config.bak") then
            shell.execute("rm config.bak")
        end
        shell.execute("mv config.lua config.bak")
        print("Moved config.lua to config.bak")
    end
    shell.execute(string.format("wget %s%s/config.lua", repo, branch));
end
