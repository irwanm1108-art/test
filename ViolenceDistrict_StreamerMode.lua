--[[
    ============================================================
      VIOLENCE DISTRICT — STREAMER MODE PRO
      Dirombak oleh: Ghost
      Fitur:
        [x] STREAMER / OBS MODE (toggle on/off)
        [x] PANIC BUTTON F8 — sekali pencet semua bersih
        [x] WATERMARK OBS — branding "LIVE" di pojok layar
        [x] KEYBIND CUSTOM — semua tombol bisa diganti di config
        [x] SCENE SELECTOR — 3 profil streamer (ringan/normal/full)
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
        ToggleKey       = Enum.KeyCode.RightShift,     -- toggle ON/OFF streamer mode
        PanicKey        = Enum.KeyCode.F8,             -- PANIC: langsung bersih semua (termasuk watermark)
        NotifyOnToggle  = true,
    },

    -- Profil streamer. Lo bisa switch live pake NumberPad1/2/3 atau ubah DefaultScene.
    --   1 = Light  (cuma ESP yang ilang)
    --   2 = Normal (chat, nametag, highlight ilang — ini safe buat kebanyakan stream)
    --   3 = Full   (semua ilang, termasuk watermark ikut mati pas panic)
    Scenes = {
        Default = 2,

        [1] = { Name = "Light",  HideESP = true,  HideNametags = false, HideYourNametag = false, HideHighlights = false, HideChat = false },
        [2] = { Name = "Normal", HideESP = true,  HideNametags = true,  HideYourNametag = true,  HideHighlights = true,  HideChat = true  },
        [3] = { Name = "Full",   HideESP = true,  HideNametags = true,  HideYourNametag = true,  HideHighlights = true,  HideChat = true  },
    },

    Watermark = {
        Enabled   = true,
        Text      = "LIVE",                           -- teks yang tampil
        Position  = UDim2.new(0, 20, 1, -60),         -- pojok kiri bawah
        Size      = 24,
        Color     = Color3.fromRGB(255, 60, 60),
        Stroke    = Color3.fromRGB(0, 0, 0),
        StrokeWidth = 3,
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
local CurrentScene      = CONFIG.Scenes.Default
local PanicActive       = false
local trackedDrawings   = {}

-- ============================================================
--  WATERMARK OBS
-- ============================================================
local watermarkLabel
local function buildWatermark()
    if watermarkLabel then return end
    local gui = nil
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if pg then gui = pg end

    if not gui then
        -- fallback: kalo PlayerGui belum ready, pasang di CoreGui lewat Instance biasa
        gui = Instance.new("ScreenGui")
        gui.Parent = game:GetService("CoreGui")
    end

    local lbl = Instance.new("TextLabel")
    lbl.Name = "GhostWatermark"
    lbl.Text = CONFIG.Watermark.Text
    lbl.Position = CONFIG.Watermark.Position
    lbl.AnchorPoint = Vector2.new(0, 1)
    lbl.Size = UDim2.new(0, 0, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.XY
    lbl.BackgroundTransparency = 1
    lbl.TextSize = CONFIG.Watermark.Size
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextColor3 = CONFIG.Watermark.Color
    lbl.TextStrokeColor3 = CONFIG.Watermark.Stroke
    lbl.TextStrokeTransparency = 0
    lbl.ZIndex = 999
    lbl.Visible = CONFIG.Watermark.Enabled
    lbl.Parent = gui
    watermarkLabel = lbl
end

local function setWatermarkVisible(v)
    if watermarkLabel then
        watermarkLabel.Visible = v and CONFIG.Watermark.Enabled
    end
end

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
            if StreamerEnabled and not PanicActive and CurrentScene and CONFIG.Scenes[CurrentScene].HideESP then
                pcall(function() d.Visible = false end)
            end
        end
        return d
    end
    return true
end

-- Terapkan state streamer (dipanggil saat inject + saat toggle + saat ganti scene)
local function applyStreamerState()
    local scene = CONFIG.Scenes[CurrentScene] or CONFIG.Scenes[2]
    local hide = StreamerEnabled and not PanicActive

    -- ESP: sembunyikan/tampilkan semua Drawing yang sudah dibuat
    for _, d in ipairs(trackedDrawings) do
        pcall(function()
            d.Visible = not (hide and scene.HideESP)
        end)
    end

    -- Chat legacy + bubble chat modern
    pcall(function()
        StarterGui:SetCoreGuiEnabled(
            Enum.CoreGuiType.Chat,
            not (hide and scene.HideChat)
        )
    end)
    pcall(function()
        TextChatService.BubbleChatEnabled = not (hide and scene.HideChat)
    end)

    -- Nametag sendiri
    if scene.HideYourNametag then
        pcall(function()
            local lp = Players.LocalPlayer
            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.NameDisplayDistance = hide and 0 or 100
            end
        end)
    end

    -- Watermark ikut mati pas panic, tapi gak ikut off pas streamer mode normal
    setWatermarkVisible(not PanicActive)
end

-- Loop bersih-bersih tiap frame: nametag + highlight player lain
local function scrubWorld()
    if not StreamerEnabled or PanicActive then return end
    local scene = CONFIG.Scenes[CurrentScene] or CONFIG.Scenes[2]

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            if scene.HideNametags then
                local head = char:FindFirstChild("Head")
                if head then
                    for _, g in ipairs(head:GetChildren()) do
                        if g:IsA("BillboardGui") then
                            g.Enabled = false
                        end
                    end
                end
            end
            if scene.HideHighlights then
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

-- Panic: langsung bersih semua, matiin watermark
local function panic()
    PanicActive = true
    applyStreamerState()
    notify("🚨 PANIC MODE", "Semua overlay dibersihkan. Tekan F8 lagi untuk balik.")
end

-- Balik dari panic
local function unpanic()
    PanicActive = false
    applyStreamerState()
    notify("✅ NORMAL", "Overlay kembali aktif (" .. (CONFIG.Scenes[CurrentScene] or {}).Name .. ")")
end

-- Ganti scene
local function setScene(id)
    if not CONFIG.Scenes[id] then return end
    CurrentScene = id
    applyStreamerState()
    notify("🎬 Scene", "Profil: " .. CONFIG.Scenes[id].Name)
end

-- Keybind handler
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == CONFIG.StreamerMode.ToggleKey then
        if PanicActive then
            unpanic()
        else
            StreamerEnabled = not StreamerEnabled
            applyStreamerState()
            if CONFIG.StreamerMode.NotifyOnToggle then
                notify(
                    "Streamer Mode",
                    StreamerEnabled and "🟢 ON — overlay disembunyikan" or "🔴 OFF — overlay tampil"
                )
            end
        end
    elseif input.KeyCode == CONFIG.StreamerMode.PanicKey then
        if PanicActive then
            unpanic()
        else
            panic()
        end
    elseif input.KeyCode == Enum.KeyCode.KeypadOne or input.KeyCode == Enum.KeyCode.One then
        setScene(1)
    elseif input.KeyCode == Enum.KeyCode.KeypadTwo or input.KeyCode == Enum.KeyCode.Two then
        setScene(2)
    elseif input.KeyCode == Enum.KeyCode.KeypadThree or input.KeyCode == Enum.KeyCode.Three then
        setScene(3)
    end
end)

-- ============================================================
--  INIT STREAMER MODULE
-- ============================================================
buildWatermark()
installEspHook()
setScene(CONFIG.Scenes.Default)
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

print("[Ghost] Script loaded. Eksekusi... (Streamer Mode: " .. tostring(StreamerEnabled) .. ", Scene: " .. tostring(CONFIG.Scenes[CurrentScene].Name) .. ")")
fn()
