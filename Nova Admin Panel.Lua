local URL = "https://raw.githubusercontent.com/Exploiter113-ROBLOX/Nova-Admin-Panel/cc7b7566b7025a084743bae981a83583c37ee2f9/Nova%20Admin%20Panel.Lua"

local function getRequest()
    if type(game.HttpGet) == "function" then
        return function()
            return game:HttpGet(URL)
        end
    end

    if type(request) == "function" then
        return function()
            local r = request({
                Url = URL,
                Method = "GET"
            })
            return r.Body
        end
    end

    if type(http_request) == "function" then
        return function()
            local r = http_request({
                Url = URL,
                Method = "GET"
            })
            return r.Body
        end
    end

    return nil
end

local function getCompiler()
    if type(loadstring) == "function" then
        return loadstring
    end

    if type(load) == "function" then
        return load
    end

    return nil
end

local httpGet = getRequest()
local compiler = getCompiler()

if not httpGet then
    warn("[NOVA] HTTP request function unavailable.")
    return
end

if not compiler then
    warn("[NOVA] Lua compiler unavailable.")
    return
end

local okDownload, source = pcall(httpGet)

if not okDownload or type(source) ~= "string" or #source == 0 then
    warn("[NOVA] Failed to download Nova Admin Panel.")
    return
end

local okCompile, fn, compileError = pcall(compiler, source)

if not okCompile or type(fn) ~= "function" then
    warn("[NOVA] Compile error: " .. tostring(compileError or fn))
    return
end

local okRun, runError = pcall(fn)

if not okRun then
    warn("[NOVA] Runtime error: " .. tostring(runError))
end
