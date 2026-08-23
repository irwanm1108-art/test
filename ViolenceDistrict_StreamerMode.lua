--[[
    ============================================================
      VIOLENCE DISTRICT — REBUILT LOADER
      Dirombak oleh: Ghost
      Tambahan baru:
        [x] STREAMER MODE / OBS MODE (toggle on/off)
        [x] Sembunyikan ESP (Drawing box/text/line)
        [x] Sembunyikan nametag player lain + nametag sendiri
        [x] Sembunyikan Highlight / SelectionBox (outline player)
        [x] Matikan chat & bubble chat
    ============================================================
]]

local BASE = "https://raw.githubusercontent.com/lixxWW/ViolenceDistrict/refs/heads/main/"

-- ==================== CONFIG ====================
local CONFIG = {
    StreamerMode = {
        Enabled         = true,                        -- master switch (true = nyala pas inject)
        ToggleKey       = Enum.KeyCode.RightShift,     -- tekan untuk ON/OFF live
        HideESP         = true,    -- ESP (kotak/teks/garis Drawing)
        HideNametags    = true,    -- nama di atas kepala player lain
        HideYourNametag = true,    -- namamu sendiri dari layar
        HideHighlights  = true,    -- Highlight / SelectionBox / esp outline
        HideChat        = true,    -- chat + bubble chat
        NotifyOnToggle  = true,
    },
}

-- ==================== GAME MAP ====================
local SCRIPTS = {
    [93978595733734] = BASE .. "violencedistrict.lua",   -- Violence District
    [97598239454123] = BASE .. "growagarden.lua",         -- Grow a Garden 2 (Old)
    [77085202503540] = BASE .. "growagarden.lua",         -- Grow a Garden 2 (New)
    [142823291]      = BASE .. "murdermystery2.lua",     -- Murder Mystery 2
    [66654135]       = BASE .. "murdermystery2.lua",     -- Murder Mystery 2 Trade Plaza
}

-- ==================== SERVICES ====================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local TextChatService   = game:GetService("TextChatService")

local StreamerEnabled   = CONFIG.StreamerMode.Enabled
local trackedDrawings   = {}

-- ============================================================
--  STREAMER / OBS MODE MODULE
-- ============================================================

-- Ambil library Drawing (ESP) dari executor
local function getDrawingLib()
    local ok, genv = pcall(getgenv)
    if ok and genv and type(genv.Drawing) == "table" and genv.Drawing.new then
        return genv.Drawing
    end
    local ok2, g = pcall(function() return Drawing end)
    if ok2 and type(g) == "table" and g.new then
        return g
    end
    return nil
end

-- Pasang hook ke Drawing.new supaya tiap objek ESP ke-track
local function installEspHook()
    local lib = getDrawingLib()
    if not lib then return false end

    local origNew = lib.new
    lib.new = function(class, props)
        local d = origNew(class, props)
        if d then
            table.insert(trackedDrawings, d)
            if StreamerEnabled and CONFIG.StreamerMode.HideESP then
                pcall(function() d.Visible = false end)
            end
        end
        return d
    end
    return true
end

-- Terapkan state streamer (dipanggil saat inject + saat toggle)
local function applyStreamerState()
    local hide = StreamerEnabled

    -- ESP: sembunyikan/tampilkan semua Drawing yang sudah dibuat
    for _, d in ipairs(trackedDrawings) do
        pcall(function()
            d.Visible = not (hide and CONFIG.StreamerMode.HideESP)
        end)
    end

    -- Chat legacy + bubble chat modern
    pcall(function()
        StarterGui:SetCoreGuiEnabled(
            Enum.CoreGuiType.Chat,
            not (hide and CONFIG.StreamerMode.HideChat)
        )
    end)
    pcall(function()
        TextChatService.BubbleChatEnabled = not (hide and CONFIG.StreamerMode.HideChat)
    end)

    -- Nametag sendiri
    if CONFIG.StreamerMode.HideYourNametag then
        pcall(function()
            local lp = Players.LocalPlayer
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.NameDisplayDistance = hide and 0 or 100
            end
        end)
    end
end

-- Loop bersih-bersih tiap frame: nametag + highlight player lain
local function scrubWorld()
    if not StreamerEnabled then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            if CONFIG.StreamerMode.HideNametags then
                local head = char:FindFirstChild("Head")
                if head then
                    for _, g in ipairs(head:GetChildren()) do
                        if g:IsA("BillboardGui") then
                            g.Enabled = false
                        end
                    end
                end
            end
            if CONFIG.StreamerMode.HideHighlights then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("Highlight") or v:IsA("SelectionBox") then
                        v.Enabled = false
                    end
                end
            end
        end
    end
end

-- Notifikasi on-screen
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 2,
        })
    end)
end

-- Toggle keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == CONFIG.StreamerMode.ToggleKey then
        StreamerEnabled = not StreamerEnabled
        applyStreamerState()
        if CONFIG.StreamerMode.NotifyOnToggle then
            notify(
                "Streamer Mode",
                StreamerEnabled and "🟢 ON — overlay disembunyikan" or "🔴 OFF — overlay tampil"
            )
        end
    end
end)

-- Init streamer module
installEspHook()
applyStreamerState()
RunService.RenderStepped:Connect(scrubWorld)

-- ============================================================
--  LOADER LOGIC
-- ============================================================
local placeId = game.PlaceId
local url     = SCRIPTS[placeId]

if not url then
    local player   = Players.LocalPlayer
    local coinBags = player and player:FindFirstChild("PlayerGui")
        and player.PlayerGui:FindFirstChild("MainGUI")
        and player.PlayerGui.MainGUI:FindFirstChild("Game")
        and player.PlayerGui.MainGUI.Game:FindFirstChild("CoinBags")

    if coinBags then
        url = BASE .. "murdermystery2.lua"
        print("[Ghost] Game terdeteksi via CoinBags (Murder Mystery 2)")
    else
        warn("[Ghost] Tidak ada script untuk PlaceId: " .. tostring(placeId))
        return
    end
else
    print("[Ghost] Game terdeteksi: " .. tostring(placeId))
end

print("[Ghost] Downloading script dari ViolenceDistrict...")

local nocacheUrl = url .. "?t=" .. tostring(math.floor(os.time() or tick()))
local ok, scriptContent = pcall(function()
    return game:HttpGet(nocacheUrl)
end)

if not ok or not scriptContent or #scriptContent == 0 then
    ok, scriptContent = pcall(function()
        return game:HttpGet(url)
    end)
end

if not ok or not scriptContent or #scriptContent == 0 then
    warn("[Ghost] Gagal download script dari repository.")
    return
end

local fn, err = loadstring(scriptContent)
if not fn then
    warn("[Ghost] Compile error di script target: " .. tostring(err))
    return
end

print("[Ghost] Script loaded. Eksekusi... (Streamer Mode: " .. tostring(StreamerEnabled) .. ")")
fn()