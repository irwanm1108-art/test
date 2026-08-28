-- ULTRA-BYPASS LOADER
local BASE = "https://raw.githubusercontent.com/lixxWW/ViolenceDistrict/refs/heads/main/"
local SCRIPTS = {
    [93978595733734] = BASE .. "violencedistrict.lua",
    -- ... (PlaceID lainnya tetap sama)
}

-- 1. REMOTE EVENT SPOOFING (Mencoba memanipulasi data yang dikirim ke server)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, args)
    -- Jika script mencoba mengirim permintaan ke server untuk cek VIP
    if (self == game:GetService("RemoteFunction") or self == game:GetService("RemoteEvent")) then
        -- Kita coba selipkan data 'true' di dalam argumen yang dikirim
        for i, v in pairs(args) do
            if v == "CheckVIP" or v == "IsPremium" then
                args[i] = "True" 
            end
        end
    end
    return oldNamecall(self, args)
end)

-- 2. MARKETPLACE HOOK (Tetap kita pasang untuk jaga-jaga)
pcall(function()
    game:GetService("MarketplaceService").UserOwnsGamePassAsync = function() return true end
end)

-- 3. LOADER LOGIC
local placeId = game.PlaceId
local url = SCRIPTS[placeId] or BASE .. "violencedistrict.lua"

print("[Loader] Executing with Remote Spoofing...")

local ok, scriptContent = pcall(function() return game:HttpGet(url .. "?t=" .. tick()) end)
if ok and scriptContent then
    local fn, err = loadstring(scriptContent)
    if fn then fn() end
end
