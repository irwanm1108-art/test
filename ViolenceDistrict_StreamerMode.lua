-- KEY-BYPASS LOADER
local BASE = "https://raw.githubusercontent.com/lixxWW/ViolenceDistrict/refs/heads/main/"
local SCRIPTS = {
    [93978595733734] = BASE .. "violencedistrict.lua",
    -- tambahkan PlaceId lain jika perlu
}

-- 1. KEY-VALIDATION HOOKING
-- Kita mencoba mencari fungsi validasi kunci dan memaksa hasilnya jadi TRUE
local function bypassKeys()
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    
    mt.__index = function(self, key)
        -- Jika script mencari variabel bernama 'Key', 'CorrectKey', atau 'Valid'
        if key == "Key" or key == "CorrectKey" or key == "IsValid" then
            return "ANY_KEY_123" -- Memberikan nilai palsu agar script tidak crash
        end
        return oldIndex(self, key)
end
end

-- 2. REMOTE EVENT KEY SPOOFING
-- Jika kamu memasukkan key lalu klik "Submit", script akan mengirim RemoteEvent.
-- Kita coba tangkap event itu dan kirim data "True" ke server.
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, args)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        -- Jika argumen yang dikirim mengandung kata 'Key' atau 'Validate'
        for i, v in pairs(args) do
            if type(v) == "string" and (v:find("Key") or v:find("Validate")) then
                args[i] = "TRUE" -- Paksa jadi TRUE
            end
        end
    end
    return oldNamecall(self, args)
end)

-- 3. LOADER LOGIC
local placeId = game.PlaceId
local url = SCRIPTS[placeId] or BASE .. "violencedistrict.lua"

print("[Loader] Attempting Key Bypass...")

-- Eksekusi Hooking
pcall(bypassKeys)

local ok, scriptContent = pcall(function() return game:HttpGet(url .. "?t=" .. tick()) end)
if ok and scriptContent then
    local fn, err = loadstring(scriptContent)
    if fn then 
        fn() 
        print("[Loader] Script executed. Try entering any random key in the game!")
    end
end
