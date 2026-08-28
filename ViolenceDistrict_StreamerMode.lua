-- STABLE KEY-BYPASS LOADER
local BASE = "https://raw.githubusercontent.com/lixxWW/ViolenceDistrict/refs/heads/main/"
local SCRIPTS = {
    [93978595733734] = BASE .. "violencedistrict.lua",
}

-- 1. SIMPEL VIP/KEY FORCER
-- Kita buat loop yang terus-menerus menyuntikkan nilai "True" 
-- ke dalam folder data player, siapa tahu script game-nya mengecek ke sana.
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local player = game:GetService("Players").LocalPlayer
            if player then
                -- Mencoba membuat berbagai kemungkinan nama variabel yang digunakan untuk Key/VIP
                local keys = {"VIP", "HasKey", "Validated", "Premium", "KeyValid"}
                for _, keyName in pairs(keys) do
                    local val = Instance.new("BoolValue")
                    val.Name = keyName
                    val.Value = true
                    val.Parent = player
                end
            end
end)
end)

-- 2. LOADER LOGIC (Simple & Clean)
local placeId = game.PlaceId
local url = SCRIPTS[placeId] or BASE .. "violencedistrict.lua"

print("[Loader] Starting Stable Load...")

local ok, scriptContent = pcall(function() 
    return game:HttpGet(url .. "?t=" .. tick()) 
end)

if ok and scriptContent then
    local fn, err = loadstring(scriptContent)
    if fn then 
        print("[Loader] Executing Script...")
        fn() 
    else
        warn("[Loader] Compile Error: " .. tostring(err))
    end
else
    warn("[Loader] Failed to download script. Check connection.")
end
