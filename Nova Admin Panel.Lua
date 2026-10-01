local URL = "https://raw.githubusercontent.com/Exploiter113-ROBLOX/Nova-Admin-Panel/cc7b7566b7025a084743bae981a83583c37ee2f9/Nova%20Admin%20Panel.Lua"
local FALLBACK_URL = "https://raw.githubusercontent.com/Exploiter113-ROBLOX/Nova-Admin-Panel/main/Nova%20Admin%20Panel.Lua"

-- Try every known download method (Delta supports game:HttpGet)
local function tryDownload(url)
    -- 1) game:HttpGet (works in Delta even though type() lies)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 0 and not res:find("^<") then
        return res
    end

    -- 2) request
    if type(request) == "function" then
        ok, res = pcall(function() return request({ Url = url, Method = "GET" }).Body end)
        if ok and type(res) == "string" and #res > 0 then return res end
    end

    -- 3) http_request
    if type(http_request) == "function" then
        ok, res = pcall(function() return http_request({ Url = url, Method = "GET" }).Body end)
        if ok and type(res) == "string" and #res > 0 then return res end
    end

    -- 4) syn.request
    if type(syn) == "table" and type(syn.request) == "function" then
        ok, res = pcall(function() return syn.request({ Url = url, Method = "GET" }).Body end)
        if ok and type(res) == "string" and #res > 0 then return res end
    end

    return nil
end

local source = tryDownload(URL) or tryDownload(FALLBACK_URL)

if not source then
    warn("[NOVA] Failed to download Nova Admin Panel from both URLs.")
    return
end

local compiler = loadstring or load
if type(compiler) ~= "function" then
    warn("[NOVA] No Lua compiler available in this executor.")
    return
end

local fn, compileErr = compiler(source, "=NovaAdminPanel")
if not fn then
    warn("[NOVA] Compile error: " .. tostring(compileErr))
    return
end

local ok, runErr = pcall(fn)
if not ok then
    warn("[NOVA] Runtime error: " .. tostring(runErr))
end
