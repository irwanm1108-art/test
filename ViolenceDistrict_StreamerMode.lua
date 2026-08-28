-- AGGRESSIVE VIP LOADER
local BASE = "https://raw.githubusercontent.com/lixxWW/ViolenceDistrict/refs/heads/main/"

local SCRIPTS = {
    [93978595733734] = BASE .. "violencedistrict.lua",
    [97598239454123] = BASE .. "growagarden.lua",
    [77085202503540] = BASE .. "growagarden.lua",
    [142823291]      = BASE .. "murdermystery2.lua",
    [66654135]       = BASE .. "murdermystery2.lua",
}

-- 1. FORCED HOOKING (Dijalankan paling awal)
local function applyHooks()
    local success, err = pcall(function()
        local mps = game:GetService("MarketplaceService")
        local old = mps.UserOwnsGamePassAsync
        mps.UserOwnsGamePassAsync = function(self, userId, gamePassId)
            print("[VIP] Bypassing GamePass Check: " .. tostring(gamePassId))
            return true
        end
    end)
    if not success then warn("[VIP] Hooking failed: " .. tostring(err)) end
end
applyHooks()

-- 2. PERSISTENT VIP VALUE (Terus menerus membuat value VIP)
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local player = game:GetService("Players").LocalPlayer
            if player then
                local v = Instance.new("BoolValue")
                v.Name = "VIP"
                v.Value = true
                v.Parent = player
                
                local v2 = Instance.new("BoolValue")
                v2.Name = "HasVIPPass"
                v2.Value = true
                v2.Parent = player
            end
        end)
    end
end)

-- 3. SCRIPT LOADER LOGIC
local placeId = game.PlaceId
local url = SCRIPTS[placeId]

if not url then
    -- Deteksi otomatis untuk MM2
    local player = game:GetService("Players").LocalPlayer
    pcall(function()
        if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("MainGUI") then
            url = BASE .. "murdermystery2.lua"
        end
    end)
end

if not url then
    warn("[Loader] No script found for this game. Trying default ViolenceDistrict...")
    url = BASE .. "violencedistrict.lua"
end

print("[Loader] Attempting to load: " .. url)

-- Download dengan retry mechanism
local function downloadScript(targetUrl)
    local success, content = pcall(function()
        return game:HttpGet(targetUrl .. "?t=" .. tick())
    end)
    if not success then
        success, content = pcall(function() return game:HttpGet(targetUrl) end)
    end
    return success, content
end

local ok, scriptContent = downloadScript(url)

if ok and scriptContent then
    local fn, err = loadstring(scriptContent)
    if fn then
        print("[Loader] Success! Executing...")
        fn()
    else
        warn("[Loader] Loadstring error: " .. tostring(err))
    end
else
    warn("[Loader] Failed to download script.")
end
