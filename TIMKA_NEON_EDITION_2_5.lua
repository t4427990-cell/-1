
-- ОТ ТИМКИ | NEON EDITION 2.5 — SKETCH REPLICA | Neon UI Refined + Player Fling
-- ЧАСТЬ 1. ВСТАВЛЯТЬ В НАЧАЛО НОВОГО ФАЙЛА.
-- Запускать только ПОСЛЕ добавления последней части.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

-- Закрываем предыдущую копию, чтобы не копились события.
local oldGui = playerGui:FindFirstChild("CompactMenu")
if oldGui then
    local oldShutdown = oldGui:FindFirstChild("TimkaShutdown")
    if oldShutdown and oldShutdown:IsA("BindableEvent") then
        oldShutdown:Fire()
    end
    if oldGui.Parent then oldGui:Destroy() end
end

local bootGui = Instance.new("ScreenGui")
bootGui.Name = "TimkaStartupMessage"
bootGui.ResetOnSpawn = false
bootGui.DisplayOrder = 10000
local staleBoot = playerGui:FindFirstChild(bootGui.Name)
if staleBoot then staleBoot:Destroy() end
bootGui.Parent = playerGui
local bootText = Instance.new("TextLabel")
bootText.Size = UDim2.new(0.8, 0, 0, 96)
bootText.Position = UDim2.new(0.1, 0, 0.5, -48)
bootText.BackgroundColor3 = Color3.fromRGB(12, 18, 34)
bootText.TextColor3 = Color3.fromRGB(65, 221, 255)
bootText.TextWrapped = true
bootText.TextSize = 16
bootText.Font = Enum.Font.GothamBold
bootText.Text = "ОТ ТИМКИ | Загрузка Neon UI..."
bootText.Parent = bootGui
Instance.new("UICorner", bootText).CornerRadius = UDim.new(0, 14)

local cleanupOnFailure
local ok, err = xpcall(function()
    local saveFileName = "timka_settings_v8.json"
    local defaults = {
        espEnabled = false, aimEnabled = false, infJumpEnabled = false,
        aim360 = true, autoReturn = false, espColor = {255, 255, 255},
        fovRadius = 150, smoothness = 0.15, customSpeed = 16,
        customJump = 50, customSize = 1, gazeESPEnabled = false,
        nearDistance = 60, preferVisible = true, preferLooking = true,
        ignoreFriends = true, distanceColors = true, greenFriends = true,
        spinEnabled = false, spinSpeed = 1500,
        hitboxEnabled = false, hitboxSize = 10,
        wallbangEnabled = false, antiFlingEnabled = false,
        theme = "cyan",
        menuWidth = 950, menuHeight = 515,
        espBoxes = true, espTracers = true, espHealth = true,
        espNames = true, espMeters = true, espFriendTag = true,
        espHighlight = false, espPaletteVersion = 0,
        menuTransparency = 0,
        flingAllSkipFriends = true, flingAllSkipWhitelist = true,
        popupEnabled = true, popupBehindWalls = false,
        popupHold = 0, popupRadius = 35, popupCenter = false,
        fpsOverlay = true, audioId = "", audioVolume = 0.5,
        audioLoop = false
    }
    -- Настройки нового раздела храним отдельно от старых опций.
    local visualDefaults = {
        trail = "off", trailColor = {45, 220, 255}, trailLength = 1,
        trailBrightness = 1, weather = "off", weatherPower = 0.5,
        weatherColor = {180, 220, 255}, sky = "default",
        light = "default", brightness = 2, contrast = 0,
        saturation = 0, aura = "off", auraColor = {115, 95, 255},
        fps = "off", cinematic = false, nightVision = false,
        magic = false, magicColor = {155, 100, 255},
        hd = "original", hdStrength = 0.6,
        jumpCircle = false, jumpColor = {165, 105, 255},
        jumpRadius = 3, jumpLife = 0.65,
        skinEnabled = false, skinOpacity = 0.45,
        skinColor = {165, 105, 255}, skinAll = false,
        auraBallEnabled = false, auraBallColor = {255, 90, 225},
        auraBallSize = 5, auraBallGlow = 0.75,
        auraRingEnabled = true, auraArcsEnabled = true,
        auraParticlesEnabled = true, auraSpin = 1.1,
        ambientEnabled = false, ambientStrength = 0.4,
        skyCycle = false, skyCycleMinutes = 10
    }
    local settings = table.clone(defaults)
    settings.visuals = table.clone(visualDefaults)
    for k,v in pairs(visualDefaults) do
        if type(v)=="table" then settings.visuals[k] = table.clone(v) end
    end
    if readfile and isfile and isfile(saveFileName) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(saveFileName))
        end)
        if success and type(data) == "table" then
            for key, value in pairs(defaults) do
                if type(data[key]) == type(value) then
                    settings[key] = data[key]
                end
            end
            if type(data.visuals) == "table" then
                for key, value in pairs(visualDefaults) do
                    if type(data.visuals[key]) == type(value) then
                        settings.visuals[key] = data.visuals[key]
                    end
                end
            end
        end
    end
    -- Старый стандартный красный ESP обновляем до нового белого.
    -- Любой вручную настроенный цвет пользователя сохраняется.
    if (tonumber(settings.espPaletteVersion) or 0) < 1 then
        local old = settings.espColor
        if type(old) == "table" and tonumber(old[1]) == 255
            and tonumber(old[2]) == 65 and tonumber(old[3]) == 95 then
            settings.espColor = {255, 255, 255}
        end
        settings.espPaletteVersion = 1
    end
    local visuals = settings.visuals
    local extrasAPI = {}  -- связи новых модулей без лишних local в общем xpcall
    local function saveSettings()
        if not writefile then return end
        pcall(function()
            writefile(saveFileName, HttpService:JSONEncode(settings))
        end)
    end

    -- Состояния оригинального скрипта. Сохраняем совместимость.
    local active = true
    local connections, playerConnections, highlights = {}, {}, {}
    local cleanupTasks = {}
    local camera = Workspace.CurrentCamera
    local espEnabled = settings.espEnabled
    local aimEnabled = settings.aimEnabled
    local infJumpEnabled = settings.infJumpEnabled
    local aim360 = settings.aim360
    local autoReturn = settings.autoReturn
    local fovRadius, smoothness = settings.fovRadius, settings.smoothness
    local customSpeed, customJump = settings.customSpeed, settings.customJump
    local customSize = settings.customSize
    local speedChanged = customSpeed ~= 16
    local jumpChanged = customJump ~= 50
    local sizeChanged = customSize ~= 1
    local spinEnabled, spinSpeed = settings.spinEnabled, settings.spinSpeed
    local hitboxEnabled, hitboxSize = settings.hitboxEnabled, settings.hitboxSize
    local wallbangEnabled = settings.wallbangEnabled
    local antiFlingEnabled = settings.antiFlingEnabled
    local originalHitboxes, savedWallCollisions = {}, {}
    local whiteList, superPriorityTargets = {}, {}
    local savedRoot, marker = nil, nil
    local preAimRotation, returning = nil, false
    local lastManualInput, lastJump = 0, 0
    local cameraTouches = {}
    local preferVisible = settings.preferVisible
    local preferLooking = settings.preferLooking
    local ignoreFriends = settings.ignoreFriends
    local distanceColors, greenFriends = settings.distanceColors, settings.greenFriends
    local gazeESPEnabled, nearDistance = settings.gazeESPEnabled, settings.nearDistance
    local friendCache, friendPending, friendFailures = {}, {}, {}
    local friendStatus, selectedTarget = nil, nil
    local nextTargetScan = 0
    local cyan = Color3.fromRGB(63, 215, 255)
    local violet = Color3.fromRGB(149, 104, 255)
    local farColor = Color3.fromRGB(140, 110, 255)
    local friendColor = Color3.fromRGB(60, 245, 120)
    local espColor = Color3.fromRGB(
        settings.espColor[1], settings.espColor[2], settings.espColor[3]
    )

    -- Общая библиотека UI: все модули используют эти функции.
    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(connections, connection)
        return connection
    end
    local function new(className, parent, props)
        local object = Instance.new(className)
        for key, value in pairs(props or {}) do
            object[key] = value
        end
        object.Parent = parent
        return object
    end
    local function corner(object, radius)
        return new("UICorner", object, {
            CornerRadius = UDim.new(0, radius or 10)
        })
    end
    local function stroke(object, color, transparency, thickness)
        return new("UIStroke", object, {
            Color = color or cyan,
            Transparency = transparency or 0.35,
            Thickness = thickness or 1
        })
    end
    local function gradient(object, colorA, colorB, rotation)
        return new("UIGradient", object, {
            Color = ColorSequence.new(colorA, colorB),
            Rotation = rotation or 45
        })
    end
    local function registerCleanup(callback)
        table.insert(cleanupTasks, callback)
    end
    local function tween(object, time, values, style, direction)
        local animation = TweenService:Create(object, TweenInfo.new(
            time, style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        ), values)
        animation:Play()
        return animation
    end

    local gui = new("ScreenGui", playerGui, {
        Name = "CompactMenu", ResetOnSpawn = false,
        IgnoreGuiInset = false, DisplayOrder = 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    local shutdown = new("BindableEvent", gui, {Name = "TimkaShutdown"})
    local function cleanup()
        if not active then return end
        active = false
        for _, callback in ipairs(cleanupTasks) do
            pcall(callback)
        end
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        for _, bucket in pairs(playerConnections) do
            for _, connection in ipairs(bucket) do
                pcall(function() connection:Disconnect() end)
            end
        end
        for _, highlight in pairs(highlights) do
            if highlight.Parent then highlight:Destroy() end
        end
        if marker then marker:Destroy() end
        if gui.Parent then gui:Destroy() end
    end
    cleanupOnFailure = cleanup
    connect(shutdown.Event, cleanup)
    connect(gui.Destroying, cleanup)

    -- Дизайн: тёмное стекло + цианово-фиолетовый неон.
    -- Единая палитра всех страниц: фон насыщенный, текст контрастный.
    local C = {
        base = Color3.fromRGB(3, 5, 22),
        panel = Color3.fromRGB(9, 11, 39),
        panelLight = Color3.fromRGB(20, 18, 64),
        muted = Color3.fromRGB(187, 201, 244),
        white = Color3.fromRGB(251, 251, 255),
        green = Color3.fromRGB(61, 240, 160),
        red = Color3.fromRGB(247, 70, 125)
    }
    local openButton = new("TextButton", gui, {
        Name = "TimkaOpenButton",
        Size = UDim2.fromOffset(130, 39),
        Position = UDim2.fromOffset(12, 12),
        BackgroundColor3 = C.base,
        Text = "◆  ОТ ТИМКИ",
        TextColor3 = C.white,
        Font = Enum.Font.GothamBold,
        TextSize = 14, AutoButtonColor = false,
        ZIndex = 20
    })
    corner(openButton, 19)
    stroke(openButton, cyan, 0.04, 2)
    -- Не используем UIGradient на текстовой кнопке: иначе тускнеют буквы.
    openButton.BackgroundColor3 = C.panel
    openButton.TextColor3 = C.white
    openButton.TextStrokeTransparency = 0.72


    -- ===== ЧАСТЬ 2: NEON LANDSCAPE UI =====

    -- CanvasGroup + UIGradient затемнял всё окно вместе с текстом.
    -- Обычный Frame исключает групповое умножение цвета потомков.
    local menu = new("Frame", gui, {
        Name = "NeonMainWindow",
        Size = UDim2.fromOffset(760, 330),
        Position = UDim2.fromOffset(20, 15),
        BackgroundColor3 = C.base,
        BackgroundTransparency = math.clamp(tonumber(settings.menuTransparency) or 0, 0, 0.30),
        BorderSizePixel = 0,
        Visible = false,
        Active = true,
        ClipsDescendants = false,
        ZIndex = 3
    })
    corner(menu, 19)
    local menuStroke = stroke(menu, cyan, 0.012, 3.0)
    local menuScale = new("UIScale", menu, {Scale = 0.92})

    -- Слой неонового фона делаем ОТДЕЛЬНО от текста.
    -- Градиент на Frame не окрашивает вложенные UI других слоёв.
    local neonBackdrop = new("Frame", menu, {
        Name = "TimkaNeonBackdrop", Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.base, BorderSizePixel = 0, ZIndex = 1,
        ClipsDescendants = true
    })
    corner(neonBackdrop, 19)
    gradient(neonBackdrop, Color3.fromRGB(2, 6, 28),
        Color3.fromRGB(31, 5, 67), 25)
    -- Имитация светящихся диагональных полос (без внешних assets).
    for i = 1, 16 do
        local x = 0.07 + (i - 1) * 0.071
        local streak = new("Frame", neonBackdrop, {
            Name = "EnergyStreak" .. i,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(x, 0, 0.56, 0),
            Size = UDim2.new(0, i % 3 == 0 and 4 or 2, 1.65, 0),
            Rotation = 32,
            BackgroundColor3 = i % 2 == 0 and cyan or violet,
            BackgroundTransparency = i % 3 == 0 and 0.81 or 0.94,
            BorderSizePixel = 0, ZIndex = 1
        })
        new("UIGradient", streak, {
            Rotation = 90, Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.44, 0.03),
                NumberSequenceKeypoint.new(1, 1)
            })
        })
    end
    -- Два тонких светящихся контура вокруг окна.
    local rim = new("Frame", menu, {
        Name = "NeonInnerRim", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(1, -6, 1, -6), ZIndex = 2
    })
    corner(rim, 16)
    stroke(rim, violet, 0.45, 1)
    local halo = new("Frame", menu, {
        Name = "NeonOuterGlow", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(-1, -1),
        Size = UDim2.new(1, 2, 1, 2), ZIndex = 2
    })
    corner(halo, 20)
    stroke(halo, Color3.fromRGB(207, 53, 255), 0.72, 6)

    -- Верхняя неоновая шапка.
    local header = new("Frame", menu, {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Color3.fromRGB(6, 6, 30),
        BorderSizePixel = 0,
        ZIndex = 5
    })
    gradient(header, Color3.fromRGB(5, 16, 51),
        Color3.fromRGB(58, 5, 81), 12)

    local headerLine = new("Frame", header, {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = cyan,
        BorderSizePixel = 0
    })
    gradient(headerLine, cyan, violet, 0)

    local headerEmblem = new("TextLabel", header, {
        Name = "NeonEmblem", Position = UDim2.fromOffset(12, 8),
        Size = UDim2.fromOffset(43, 43), BackgroundColor3 = C.base,
        Text = "◆", TextColor3 = cyan, TextSize = 29,
        TextStrokeColor3 = violet, TextStrokeTransparency = 0.18,
        Font = Enum.Font.GothamBold, ZIndex = 7
    })
    corner(headerEmblem, 12)
    stroke(headerEmblem, cyan, 0.02, 2)
    local dragArea = new("TextLabel", header, {
        Name = "DragArea",
        Size = UDim2.new(1, -274, 1, 0),
        Position = UDim2.fromOffset(65, 0),
        BackgroundTransparency = 1,
        Text = "♛  ОТ ТИМКИ   |   NEON EDITION 2.5",
        TextColor3 = C.white,
        TextSize = 16,
        TextStrokeColor3 = Color3.fromRGB(43, 14, 79),
        TextStrokeTransparency = 0.6,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = true, ZIndex = 8
    })

    extrasAPI.fpsLabel = new("TextLabel", header, {
        Name = "TimkaHeaderFPS",
        Size = UDim2.fromOffset(94, 31),
        Position = UDim2.new(1, -193, 0, 13),
        BackgroundColor3 = C.panelLight,
        Text = "-- FPS", TextColor3 = C.green,
        TextSize = 12, Font = Enum.Font.GothamBold,
        ZIndex = 6, BorderSizePixel = 0
    })
    corner(extrasAPI.fpsLabel, 8)
    local minimizeButton = new("TextButton", header, {
        Size = UDim2.fromOffset(36, 32),
        Position = UDim2.new(1, -87, 0, 12),
        BackgroundColor3 = C.panelLight,
        Text = "−",
        TextColor3 = cyan,
        TextSize = 24,
        Font = Enum.Font.GothamBold
    })
    corner(minimizeButton, 8)
    stroke(minimizeButton, violet, 0.3)

    local closeButton = new("TextButton", header, {
        Size = UDim2.fromOffset(36, 32),
        Position = UDim2.new(1, -44, 0, 12),
        BackgroundColor3 = Color3.fromRGB(68, 30, 69),
        Text = "×",
        TextColor3 = C.white,
        TextSize = 24,
        Font = Enum.Font.GothamBold
    })
    corner(closeButton, 8)
    stroke(closeButton, violet, 0.2)

    local body = new("Frame", menu, {
        Position = UDim2.fromOffset(9, 72),
        Size = UDim2.new(1, -18, 1, -84),
        BackgroundTransparency = 1
    })

    -- Боковые вкладки прокручиваются независимо.
    local sidebar = new("ScrollingFrame", body, {
        Name = "Navigation",
        Size = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = Color3.fromRGB(7, 7, 35),
        BackgroundTransparency = 0.025,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = violet,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y
    })
    corner(sidebar, 12)
    stroke(sidebar, violet, 0.25, 1.6)

    new("UIListLayout", sidebar, {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    new("UIPadding", sidebar, {
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 7)
    })

    local content = new("Frame", body, {
        Name = "Content",
        Position = UDim2.fromOffset(170, 0),
        Size = UDim2.new(1, -170, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    })

    local contentTitle = new("TextLabel", content, {
        Size = UDim2.new(1, 0, 0, 31),
        BackgroundTransparency = 1,
        Text = "ГЛАВНАЯ",
        TextColor3 = C.white,
        TextSize = 19,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local pageHost = new("CanvasGroup", content, {
        GroupTransparency = 0,
        Position = UDim2.fromOffset(0, 36),
        Size = UDim2.new(1, 0, 1, -36),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    })

    local pages, navButtons = {}, {}
    local currentPage = nil

    local function makePage(id)
        local page = new("ScrollingFrame", pageHost, {
            Name = "Page_" .. id,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = cyan,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y
        })
        new("UIListLayout", page, {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        new("UIPadding", page, {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 8)
        })
        pages[id] = page
        return page
    end

    local navItems = {
        {"home", "⌂  Главная", "ГЛАВНАЯ"},
        {"esp", "⊕  ESP", "ESP"},
        {"visuals", "◉  Визуалы+", "ВИЗУАЛЫ+"},
        {"priority", "♙  Игроки", "ИГРОКИ / ПРИОРИТЕТ"},
        {"aim", "⊕  Aimbot", "AIMBOT"},
        {"flight", "✈  Полёт", "ПОЛЁТ / NOCLIP"},
        {"protection", "ϟ  Флинг", "FLING / ЗАЩИТА"},
        {"themes", "◉  Темы", "ТЕМЫ / СТИЛЬ"},
        {"character", "♟  Персонаж", "ПЕРСОНАЖ"},
        {"spawn", "⌖  Возрождение", "ТОЧКА ВОЗРОЖДЕНИЯ"},
        {"camera", "▣  Камера", "КАМЕРА"},
        {"whitelist", "⬡  Белый список", "БЕЛЫЙ СПИСОК"},
        {"playerpopup", "♛  Мини-меню", "МИНИ-МЕНЮ ИГРОКА"},
        {"music", "♫  Музыка", "NEON MUSIC PLAYER"}
    }
    local function setPage(id)
        if not pages[id] then return end
        currentPage = id
        for pageId, page in pairs(pages) do
            page.Visible = pageId == id
        end
        for pageId, object in pairs(navButtons) do
            local chosen = pageId == id
            object.BackgroundColor3 = chosen
                and Color3.fromRGB(83, 21, 141) or C.panel
            object.TextColor3 = chosen and C.white or C.muted
            local outline = object:FindFirstChildOfClass("UIStroke")
            if outline then
                outline.Color = chosen and Color3.fromRGB(255, 65, 229) or violet
                outline.Thickness = chosen and 2 or 1
                outline.Transparency = chosen and 0.05 or 0.6
            end
        end
        for _, item in ipairs(navItems) do
            if item[1] == id then
                contentTitle.Text = item[3]
                break
            end
        end
    end

    for index, item in ipairs(navItems) do
        makePage(item[1])
        local nav = new("TextButton", sidebar, {
            Name = "Nav_" .. item[1],
            Size = UDim2.new(1, 0, 0, 41),
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
            Text = item[2],
            TextColor3 = C.white,
            TextSize = 12,
            TextWrapped = true,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = index,
            AutoButtonColor = false
        })
        corner(nav, 10)
        stroke(nav, violet, 0.62, 1)
        navButtons[item[1]] = nav
        connect(nav.Activated, function()
            setPage(item[1])
        end)
    end
    setPage("home")


    -- ===== ЧАСТЬ 3: NEON UI COMPONENTS =====
    -- Общие элементы для всех вкладок.

    local uiOrder = {}
    local function nextOrder(pageId)
        uiOrder[pageId] = (uiOrder[pageId] or 0) + 1
        return uiOrder[pageId]
    end

    local function uiCard(pageId, titleText, height)
        local page = pages[pageId]
        assert(page, "Unknown page: " .. tostring(pageId))

        local frame = new("Frame", page, {
            Name = "Card_" .. tostring(nextOrder(pageId)),
            Size = UDim2.new(1, -4, 0, height or 110),
            BackgroundColor3 = Color3.fromRGB(8, 9, 36),
            BackgroundTransparency = 0.025,
            BorderSizePixel = 0,
            LayoutOrder = uiOrder[pageId],
            ClipsDescendants = true
        })
        corner(frame, 12)
        stroke(frame, Color3.fromRGB(126, 79, 255), 0.17, 1.55)
        local topGlow = new("Frame", frame, {
            Name = "CardNeonAccent", Position = UDim2.fromOffset(10, 30),
            Size = UDim2.new(1, -20, 0, 1),
            BackgroundColor3 = cyan, BackgroundTransparency = 0.4,
            BorderSizePixel = 0
        })
        gradient(topGlow, cyan, Color3.fromRGB(245, 40, 240), 0)

        local titleLabel = new("TextLabel", frame, {
            Position = UDim2.fromOffset(12, 6),
            Size = UDim2.new(1, -24, 0, 24),
            BackgroundTransparency = 1,
            Text = titleText,
            TextColor3 = Color3.fromRGB(106, 231, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local inside = new("Frame", frame, {
            Position = UDim2.fromOffset(10, 33),
            Size = UDim2.new(1, -20, 1, -40),
            BackgroundTransparency = 1
        })
        return frame, inside, titleLabel
    end

    local function uiRow(parent, y, height)
        return new("Frame", parent, {
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, 0, 0, height or 34),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })
    end

    local function uiLabel(parent, textValue, y, height)
        return new("TextLabel", parent, {
            Position = UDim2.fromOffset(5, y),
            Size = UDim2.new(1, -10, 0, height or 24),
            BackgroundTransparency = 1,
            Text = textValue,
            TextColor3 = C.muted,
            TextSize = 12,
            TextWrapped = true,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    end

    local function uiButton(parent, textValue, y, callback, color)
        local object = new("TextButton", parent, {
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = C.panelLight,
            BorderSizePixel = 0,
            Text = textValue,
            TextColor3 = C.white,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false
        })
        corner(object, 9)
        local outline = stroke(object, color or violet, 0.22, 1.2)
        connect(object.Activated, function()
            tween(object, 0.08, {
                BackgroundColor3 = color or cyan
            })
            task.delay(0.12, function()
                if active and object.Parent then
                    tween(object, 0.18, {
                        BackgroundColor3 = C.panelLight
                    })
                end
            end)
            if callback then callback() end
        end)
        return object, outline
    end

    local function uiToggle(parent, textValue, y, initial, callback)
        local holder = uiRow(parent, y, 34)
        holder.BackgroundColor3 = Color3.fromRGB(11, 13, 47)
        holder.BackgroundTransparency = 0.08
        corner(holder, 10)
        stroke(holder, Color3.fromRGB(102, 85, 226), 0.34, 1.25)
        local caption = new("TextLabel", holder, {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -76, 1, 0),
            BackgroundTransparency = 1,
            Text = textValue,
            TextColor3 = C.white,
            TextSize = 12,
            TextWrapped = true,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local state = initial == true
        local track = new("TextButton", holder, {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(46, 24),
            BackgroundColor3 = C.panelLight,
            Text = "",
            AutoButtonColor = false
        })
        corner(track, 12)
        local dot = new("Frame", track, {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.fromOffset(3, 3),
            BackgroundColor3 = C.muted,
            BorderSizePixel = 0
        })
        corner(dot, 9)

        local function render(animated)
            local trackColor = state and Color3.fromRGB(170, 38, 229)
                or C.panelLight
            local dotColor = state and C.white or C.muted
            local dotPos = UDim2.fromOffset(state and 25 or 3, 3)
            if animated then
                tween(track, 0.18, {BackgroundColor3 = trackColor})
                tween(dot, 0.18, {
                    BackgroundColor3 = dotColor,
                    Position = dotPos
                }, Enum.EasingStyle.Back)
            else
                track.BackgroundColor3 = trackColor
                dot.BackgroundColor3 = dotColor
                dot.Position = dotPos
            end
        end
        render(false)

        connect(track.Activated, function()
            state = not state
            render(true)
            if callback then callback(state) end
        end)
        return holder, function() return state end
    end

    local function uiStepper(parent, textValue, y, initial,
        minimum, maximum, step, decimals, callback)

        local value = initial
        local holder = uiRow(parent, y, 38)
        holder.BackgroundColor3 = Color3.fromRGB(14, 24, 54)
        holder.BackgroundTransparency = 0.10
        corner(holder, 9)
        stroke(holder, Color3.fromRGB(76, 70, 167), 0.62)
        local caption = new("TextLabel", holder, {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -138, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = C.white,
            TextSize = 12,
            TextWrapped = true,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local function render()
            caption.Text = textValue .. ": " ..
                string.format("%." .. decimals .. "f", value)
        end

        for index, direction in ipairs({-1, 1}) do
            local object = new("TextButton", holder, {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -((2 - index) * 51), 0.5, 0),
                Size = UDim2.fromOffset(43, 30),
                BackgroundColor3 = C.panelLight,
                Text = direction < 0 and "−" or "+",
                TextColor3 = cyan,
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false
            })
            corner(object, 8)
            stroke(object, violet, 0.55)

            connect(object.Activated, function()
                local nextValue = value + direction * step
                value = math.clamp(
                    math.round(nextValue * 10000) / 10000,
                    minimum, maximum
                )
                render()
                if callback then callback(value) end
            end)
        end

        render()
        return holder
    end

    local function uiSeparator(parent, y)
        return new("Frame", parent, {
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = violet,
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0
        })
    end

    local function uiStatus(parent, textValue, y)
        return new("TextLabel", parent, {
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = textValue,
            TextColor3 = Color3.fromRGB(192, 217, 249),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    end


    -- ===== ЧАСТЬ 4: HOME / SPAWN / CHARACTER =====
local status
do

    -- Статус и быстрые переходы.
    local homeCard, homeInside = uiCard(
        "home", "◆  ОТ ТИМКИ | NEON EDITION", 232
    )
    uiLabel(homeInside,
        "Мобильное меню для горизонтального экрана", 0, 24)
    uiLabel(homeInside,
        "Выбери раздел слева или открой его здесь.", 25, 24)
    uiSeparator(homeInside, 53)

    local homeStatus = uiStatus(
        homeInside, "Система готова к настройке", 61
    )
    status = function(message)
        if not active then return end
        if homeStatus and homeStatus.Parent then
            homeStatus.Text = tostring(message)
        end
    end

    local quickESP = uiButton(
        homeInside, "◉  Открыть ESP", 96,
        function() setPage("esp") end, cyan
    )
    quickESP.Size = UDim2.new(0.49, 0, 0, 34)

    local quickVisuals = uiButton(
        homeInside, "✧  ВИЗУАЛЫ+", 96,
        function() setPage("visuals") end, violet
    )
    quickVisuals.Position = UDim2.new(0.51, 0, 0, 96)
    quickVisuals.Size = UDim2.new(0.49, 0, 0, 34)

    local quickAim = uiButton(
        homeInside, "⊕  AIMBOT", 140,
        function() setPage("aim") end, violet
    )
    quickAim.Size = UDim2.new(0.49, 0, 0, 34)

    local quickCharacter = uiButton(
        homeInside, "♟  ПЕРСОНАЖ", 140,
        function() setPage("character") end, cyan
    )
    quickCharacter.Position = UDim2.new(0.51, 0, 0, 140)
    quickCharacter.Size = UDim2.new(0.49, 0, 0, 34)

    -- ===== ТОЧКА ВОЗРОЖДЕНИЯ =====
    local spawnCard, spawnInside = uiCard(
        "spawn", "◇  СОХРАНЕНИЕ ПОЗИЦИИ", 259
    )
    local pointStatus = uiStatus(
        spawnInside, "Точка пока не сохранена", 0
    )

    local function returnToPoint(character)
        if not savedRoot then
            return false, "Сначала сохрани точку"
        end
        if not character or character ~= player.Character then
            return false, "Персонаж ещё не готов"
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        local hum = character:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then
            return false, "Дождись возрождения"
        end
        if hum.Sit then
            return false, "Сначала встань с сиденья"
        end

        local success = pcall(function()
            local offset = root.CFrame:ToObjectSpace(
                character:GetPivot()
            )
            character:PivotTo(savedRoot * offset)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        if success then
            return true, "Возврат к точке выполнен"
        end
        return false, "Не удалось переместиться"
    end

    local function savePoint()
        local character = player.Character
        local root = character and character:FindFirstChild(
            "HumanoidRootPart"
        )
        local hum = character and character:FindFirstChildOfClass(
            "Humanoid"
        )
        if not root or not hum or hum.Health <= 0 then
            pointStatus.Text = "Дождись появления персонажа"
            return
        end

        savedRoot = root.CFrame
        if marker then marker:Destroy(); marker = nil end
        marker = new("Part", Workspace, {
            Name = "TimkaSavedPoint",
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(0.08, 3, 3),
            Anchored = true,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
            Material = Enum.Material.Neon,
            Color = cyan,
            Transparency = 0.35,
            CFrame = CFrame.new(
                root.Position - Vector3.new(
                    0, hum.HipHeight + root.Size.Y * 0.5 - 0.04, 0
                )
            ) * CFrame.Angles(0, 0, math.rad(90))
        })
        local p = savedRoot.Position
        pointStatus.Text = string.format(
            "Сохранено: %.1f / %.1f / %.1f", p.X, p.Y, p.Z
        )
        status("Точка возрождения сохранена")
    end

    local savePointBtn = uiButton(
        spawnInside, "◇  Сохранить точку здесь", 38, savePoint, cyan
    )
    savePointBtn.Size = UDim2.new(0.49, 0, 0, 34)

    local returnPointBtn = uiButton(
        spawnInside, "➤  Вернуться к точке", 38,
        function()
            local success, message = returnToPoint(player.Character)
            pointStatus.Text = message
            status(message)
        end, violet
    )
    returnPointBtn.Position = UDim2.new(0.51, 0, 0, 38)
    returnPointBtn.Size = UDim2.new(0.49, 0, 0, 34)

    uiToggle(spawnInside,
        "Автовозврат после смерти", 87,
        autoReturn, function(value)
            autoReturn = value
            settings.autoReturn = value
            saveSettings()
            if value and not savedRoot then
                pointStatus.Text = "Сначала сохрани точку!"
            end
        end
    )

    uiButton(spawnInside,
        "Респавн персонажа", 131, function()
            local character = player.Character
            local hum = character and character:FindFirstChildOfClass(
                "Humanoid"
            )
            if hum and hum.Health > 0 then
                hum.Health = 0
                status("Запрошен респавн")
            end
        end, violet
    )

    uiButton(spawnInside,
        "Удалить сохранённую точку", 173, function()
            savedRoot = nil
            if marker then marker:Destroy(); marker = nil end
            pointStatus.Text = "Точка не сохранена"
            status("Точка удалена")
        end, C.red
    )

    -- ===== ПЕРСОНАЖ =====
    local function applyStats()
        local character = player.Character
        local hum = character and character:FindFirstChildOfClass(
            "Humanoid"
        )
        if not hum then return end
        if speedChanged then hum.WalkSpeed = customSpeed end
        if jumpChanged then
            hum.UseJumpPower = true
            hum.JumpPower = customJump
        end
    end

    local scaleNames = {
        "BodyHeightScale", "BodyWidthScale",
        "BodyDepthScale", "HeadScale"
    }
    local function applySize()
        if not sizeChanged then return end
        local character = player.Character
        local hum = character and character:FindFirstChildOfClass(
            "Humanoid"
        )
        if not hum then return end
        for _, name in ipairs(scaleNames) do
            local value = hum:FindFirstChild(name)
            if value and value:IsA("NumberValue") then
                value.Value = customSize
            end
        end
    end

    local charCard, charInside = uiCard(
        "character", "♟  НАСТРОЙКИ ПЕРСОНАЖА", 252
    )
    uiStepper(charInside,
        "Скорость", 0, customSpeed, 16, 200, 5, 0,
        function(value)
            customSpeed = value
            speedChanged = true
            settings.customSpeed = value
            applyStats()
            saveSettings()
        end
    )
    uiStepper(charInside,
        "Сила прыжка", 43, customJump, 50, 300, 10, 0,
        function(value)
            customJump = value
            jumpChanged = true
            settings.customJump = value
            applyStats()
            saveSettings()
        end
    )
    uiStepper(charInside,
        "Размер R15", 86, customSize, 0.5, 3, 0.1, 1,
        function(value)
            customSize = value
            sizeChanged = true
            settings.customSize = value
            applySize()
            saveSettings()
        end
    )

    uiSeparator(charInside, 132)
    uiToggle(charInside,
        "Бесконечный прыжок", 144, infJumpEnabled,
        function(value)
            infJumpEnabled = value
            settings.infJumpEnabled = value
            saveSettings()
        end
    )
    uiButton(charInside, "Применить настройки", 183, function()
        applyStats()
        applySize()
        status("Параметры персонажа применены")
    end, cyan)

    connect(UIS.JumpRequest, function()
        if not active or not infJumpEnabled then return end
        if UIS:GetFocusedTextBox() then return end
        if os.clock() - lastJump < 0.12 then return end
        local character = player.Character
        local hum = character and character:FindFirstChildOfClass(
            "Humanoid"
        )
        if hum and hum.Health > 0 and not hum.Sit then
            lastJump = os.clock()
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    connect(player.CharacterAdded, function(character)
        task.spawn(function()
            local root = character:WaitForChild("HumanoidRootPart", 10)
            local hum = character:WaitForChild("Humanoid", 10)
            if not active or not root or not hum then return end
            task.wait(0.8)
            if not active or player.Character ~= character then return end
            applyStats()
            applySize()
            if autoReturn and savedRoot then
                task.wait(0.2)
                if not active or not autoReturn then return end
                if player.Character ~= character then return end
                local _, message = returnToPoint(character)
                pointStatus.Text = message
            end
        end)
    end)
    task.defer(function()
        if active then applyStats(); applySize() end
    end)


    end
-- ===== ЧАСТЬ 5: ESP SYSTEM =====
do

    local gazeThreshold = math.cos(math.rad(25))
    local espTimer = 0
    local friendRefreshTime = 0
    local espSightParams = RaycastParams.new()
    espSightParams.FilterType = Enum.RaycastFilterType.Exclude
    espSightParams.IgnoreWater = true

    local function espVisible(origin, destination, targetChar)
        local myChar = player.Character
        local filter = {}
        if myChar then table.insert(filter, myChar) end
        espSightParams.FilterDescendantsInstances = filter
        local direction = destination - origin
        if direction.Magnitude < 0.001 then return true end
        local result = Workspace:Raycast(
            origin, direction, espSightParams
        )
        return not result
            or result.Instance:IsDescendantOf(targetChar)
    end

    local function clearESP(other)
        local highlight = highlights[other]
        if highlight then
            highlights[other] = nil
            pcall(function() highlight:Destroy() end)
        end
    end

    local function updateESP()
        if not active or not espEnabled then return end

        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild(
            "HumanoidRootPart"
        )
        local myHead = myChar and (
            myChar:FindFirstChild("Head") or myRoot
        )

        for other, highlight in pairs(highlights) do
            local targetChar = other.Character
            if not targetChar or not highlight.Parent then
                clearESP(other)
            else
                local targetRoot = targetChar:FindFirstChild(
                    "HumanoidRootPart"
                )
                local targetHead = targetChar:FindFirstChild(
                    "Head"
                ) or targetRoot

                local color = espColor
                local friend = friendCache[other] == true

                if gazeESPEnabled and myHead and targetHead then
                    local direction = myHead.Position
                        - targetHead.Position
                    local looking = false

                    if direction.Magnitude > 0.001 then
                        local dot = targetHead.CFrame.LookVector:Dot(
                            direction.Unit
                        )
                        looking = dot >= gazeThreshold
                    end

                    local canSee = espVisible(
                        targetHead.Position,
                        myHead.Position,
                        myChar or targetChar
                    )
                    color = looking and canSee
                        and Color3.fromRGB(255, 55, 75)
                        or Color3.fromRGB(30, 150, 255)

                elseif greenFriends and friend then
                    color = friendColor

                elseif distanceColors and myRoot and targetRoot then
                    local distance = (
                        myRoot.Position - targetRoot.Position
                    ).Magnitude
                    if distance > nearDistance then
                        color = farColor
                    end
                end

                highlight.FillColor = color
                highlight.OutlineColor = color
                highlight.Enabled = settings.espHighlight == true
            end
        end
    end

    local function addESP(other, character)
        clearESP(other)
        if not active or not espEnabled then return end
        if other == player or not character then return end

        local highlight = new("Highlight", character, {
            Name = "TimkaESP",
            Adornee = character,
            FillColor = espColor,
            OutlineColor = espColor,
            FillTransparency = 0.5,
            OutlineTransparency = 0.05,
            Enabled = settings.espHighlight == true,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        })
        highlights[other] = highlight
    end

    local function refreshAllESP()
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player then
                if espEnabled then
                    if not highlights[other]
                        or not highlights[other].Parent then
                        addESP(other, other.Character)
                    end
                else
                    clearESP(other)
                end
            end
        end
        updateESP()
    end

    local function checkFriend(other)
        if other == player or friendPending[other] then return end
        friendPending[other] = true
        task.spawn(function()
            for attempt = 1, 3 do
                if not active or other.Parent ~= Players then break end
                local success, result = pcall(function()
                    return player:IsFriendsWithAsync(other.UserId)
                end)
                if not active or other.Parent ~= Players then break end
                if success and type(result) == "boolean" then
                    friendCache[other] = result
                    friendFailures[other] = nil
                    friendPending[other] = nil
                    updateESP()
                    nextTargetScan = 0
                    return
                end
                if attempt < 3 then task.wait(2) end
            end
            friendPending[other] = nil
            if active and other.Parent == Players then
                friendFailures[other] = true
            end
        end)
    end

    local function watchESPPlayer(other)
        if other == player or playerConnections[other] then return end
        playerConnections[other] = {
            other.CharacterAdded:Connect(function(character)
                addESP(other, character)
            end),
            other.CharacterRemoving:Connect(function()
                clearESP(other)
            end)
        }
        checkFriend(other)
        addESP(other, other.Character)
    end

    connect(Players.PlayerAdded, watchESPPlayer)
    connect(Players.PlayerRemoving, function(other)
        clearESP(other)
        for _, connection in ipairs(
            playerConnections[other] or {}
        ) do
            connection:Disconnect()
        end
        playerConnections[other] = nil
        friendCache[other] = nil
        friendPending[other] = nil
        friendFailures[other] = nil
        nextTargetScan = 0
    end)

    for _, other in ipairs(Players:GetPlayers()) do
        watchESPPlayer(other)
    end

    connect(RunService.Heartbeat, function(dt)
        if not active then return end
        espTimer = espTimer + dt
        if espTimer >= 0.15 then
            espTimer = 0
            updateESP()
        end
    end)

    extrasAPI.setESPEnabled = function(value)
        espEnabled = value == true
        settings.espEnabled = espEnabled
        refreshAllESP()
        saveSettings()
    end
    extrasAPI.refreshESP = refreshAllESP

    -- ===== ESP MENU =====
    local espCard, espInside = uiCard(
        "esp", "◉  ПОДСВЕТКА ИГРОКОВ", 285
    )

    uiToggle(espInside, "Включить ESP", 0,
        espEnabled, function(value)
            espEnabled = value
            settings.espEnabled = value
            refreshAllESP()
            saveSettings()
        end)

    uiToggle(espInside, "Смотрит на меня", 37,
        gazeESPEnabled, function(value)
            gazeESPEnabled = value
            settings.gazeESPEnabled = value
            updateESP()
            saveSettings()
        end)

    uiToggle(espInside, "Цвет по расстоянию", 74,
        distanceColors, function(value)
            distanceColors = value
            settings.distanceColors = value
            updateESP()
            saveSettings()
        end)

    uiToggle(espInside, "Друзья зелёным", 111,
        greenFriends, function(value)
            greenFriends = value
            settings.greenFriends = value
            updateESP()
            saveSettings()
        end)

    uiStepper(espInside, "Близко (studs)", 148,
        nearDistance, 10, 300, 10, 0, function(value)
            nearDistance = value
            settings.nearDistance = value
            updateESP()
            saveSettings()
        end)

    uiButton(espInside, "Обновить игроков", 194,
        function()
            refreshAllESP()
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player then checkFriend(other) end
            end
            status("ESP: список игроков обновлён")
        end, cyan)

    uiLabel(espInside,
        "Красный — смотрит на тебя, синий — нет", 232, 18)
end


    -- ===== ЧАСТЬ 5A: ESP 2D / BOXES / TRACERS / HEALTH =====
    -- Собственная реализация через ScreenGui. Не зависит от Drawing API.
    do
        local oldOverlay = playerGui:FindFirstChild("TimkaNeonESP2D")
        if oldOverlay then oldOverlay:Destroy() end
        local overlay = new("ScreenGui", playerGui, {
            Name = "TimkaNeonESP2D", ResetOnSpawn = false,
            DisplayOrder = 45, IgnoreGuiInset = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })
        local surface = new("Frame", overlay, {
            Name = "ScreenLayer", Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Active = false
        })
        local overlays = {}
        local paintTimer = 0
        local function espBoxColor()
            local rgb = settings.espColor or {255, 255, 255}
            return Color3.fromRGB(
                math.clamp(math.floor((tonumber(rgb[1]) or 255) + 0.5), 0, 255),
                math.clamp(math.floor((tonumber(rgb[2]) or 255) + 0.5), 0, 255),
                math.clamp(math.floor((tonumber(rgb[3]) or 255) + 0.5), 0, 255)
            )
        end
        local function makeView(other)
            local group = new("Frame", surface, {
                Name = "ESP2D_" .. tostring(other.UserId),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Visible = false, Active = false
            })
            local box = new("Frame", group, {
                BackgroundTransparency = 1, BorderSizePixel = 0,
                Size = UDim2.fromOffset(20, 50)
            })
            local outline = new("UIStroke", box, {
                Color = espBoxColor(), Thickness = 1.7,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            local tracer = new("Frame", group, {
                Name = "Tracer", BackgroundColor3 = espBoxColor(),
                BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(1.5, 50)
            })
            local nameLabel = new("TextLabel", group, {
                Name = "PlayerName", BackgroundTransparency = 1,
                TextColor3 = C.white, TextStrokeColor3 = Color3.new(),
                TextStrokeTransparency = 0.05, Font = Enum.Font.GothamBold,
                TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
                Text = "", TextXAlignment = Enum.TextXAlignment.Center
            })
            local friendLabel = new("TextLabel", group, {
                Name = "FriendLabel", BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(70, 255, 125),
                TextStrokeColor3 = Color3.new(),
                TextStrokeTransparency = 0.1,
                Font = Enum.Font.GothamBold, TextSize = 12,
                Text = "(Друг)", TextXAlignment = Enum.TextXAlignment.Center
            })
            local healthBg = new("Frame", group, {
                Name = "HealthBack", BackgroundColor3 = Color3.fromRGB(15, 17, 22),
                BorderSizePixel = 0, Size = UDim2.fromOffset(4, 50)
            })
            local healthFill = new("Frame", healthBg, {
                Name = "HealthFill", BackgroundColor3 = Color3.fromRGB(45, 235, 80),
                BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.fromScale(0, 1),
                Size = UDim2.fromScale(1, 1)
            })
            local record = {
                group = group, box = box, outline = outline, tracer = tracer,
                name = nameLabel, friend = friendLabel,
                health = healthBg, fill = healthFill
            }
            overlays[other] = record
            return record
        end
        local function removeView(other)
            local view = overlays[other]
            if view then
                overlays[other] = nil
                view.group:Destroy()
            end
        end
        -- Границы R6/R15 только по реальным частям тела.
        -- Accessory, Tool, оружие и прочие вложения не влияют на рамку.
        local bodyParts = {
            Head=true, Torso=true, UpperTorso=true, LowerTorso=true,
            ["Left Arm"]=true, ["Right Arm"]=true,
            ["Left Leg"]=true, ["Right Leg"]=true,
            LeftUpperArm=true, LeftLowerArm=true, LeftHand=true,
            RightUpperArm=true, RightLowerArm=true, RightHand=true,
            LeftUpperLeg=true, LeftLowerLeg=true, LeftFoot=true,
            RightUpperLeg=true, RightLowerLeg=true, RightFoot=true
        }
        -- Объединяем габариты частей тела в системе координат корня,
        -- после чего проецируем лишь 8 углов: это легче для телефона.
        local function projectBounds(cam, character)
            local root = character:FindFirstChild("HumanoidRootPart")
                or character:FindFirstChild("Torso")
                or character:FindFirstChild("Head")
            if not root or not root:IsA("BasePart") then return nil end
            local rootCF = root.CFrame
            local low = Vector3.new(math.huge, math.huge, math.huge)
            local high = Vector3.new(-math.huge, -math.huge, -math.huge)
            local count = 0
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") and bodyParts[part.Name]
                    and part.Transparency < 0.98 then
                    count = count + 1
                    local relative = rootCF:ToObjectSpace(part.CFrame)
                    -- Не раздуваем рамку при изменении Hitbox.
                    local half = Vector3.new(
                        math.min(part.Size.X, 4.5),
                        math.min(part.Size.Y, 6),
                        math.min(part.Size.Z, 3.8)) * 0.5
                    local r, u, f = relative.RightVector,
                        relative.UpVector, relative.LookVector
                    local extent = Vector3.new(
                        math.abs(r.X)*half.X+math.abs(u.X)*half.Y+math.abs(f.X)*half.Z,
                        math.abs(r.Y)*half.X+math.abs(u.Y)*half.Y+math.abs(f.Y)*half.Z,
                        math.abs(r.Z)*half.X+math.abs(u.Z)*half.Y+math.abs(f.Z)*half.Z)
                    local p = relative.Position
                    low = Vector3.new(math.min(low.X,p.X-extent.X),
                        math.min(low.Y,p.Y-extent.Y),math.min(low.Z,p.Z-extent.Z))
                    high = Vector3.new(math.max(high.X,p.X+extent.X),
                        math.max(high.Y,p.Y+extent.Y),math.max(high.Z,p.Z+extent.Z))
                end
            end
            if count == 0 then
                -- Нестандартная модель: компактный запасной контур.
                local hum = character:FindFirstChildOfClass("Humanoid")
                local h = math.clamp(hum and hum.HipHeight*2+2 or 5,4,8)
                low,high = Vector3.new(-1.15,-h*0.5+0.5,-0.95),
                    Vector3.new(1.15,h*0.5+0.5,0.95)
            end
            local center,half = (low+high)*0.5,(high-low)*0.5
            local left,top = math.huge,math.huge
            local right,bottom = -math.huge,-math.huge
            for xi=-1,1,2 do
                for yi=-1,1,2 do
                    for zi=-1,1,2 do
                        local world = rootCF:PointToWorldSpace(center + Vector3.new(
                            xi*half.X,yi*half.Y,zi*half.Z))
                        local projected = cam:WorldToScreenPoint(world)
                        if projected.Z <= 0.15 then return nil end
                        left = math.min(left,projected.X)
                        top = math.min(top,projected.Y)
                        right = math.max(right,projected.X)
                        bottom = math.max(bottom,projected.Y)
                    end
                end
            end
            local width,height = right-left,bottom-top
            local viewSize = surface.AbsoluteSize
            if width < 3 or height < 7 or viewSize.X < 10 or viewSize.Y < 10 then
                return nil
            end
            if width > viewSize.X*0.82 or height > viewSize.Y*1.55 then
                return nil  -- слишком близко к камере, не закрываем весь экран
            end
            if right < 0 or bottom < 0 or left > viewSize.X
                or top > viewSize.Y then return nil end
            local padX = math.clamp(width*0.027,0.2,2.2)
            local padY = math.clamp(height*0.016,0.2,2.2)
            return left-padX,top-padY,right+padX,bottom+padY
        end
        local function drawView(other, cam, selfRoot)
            local view = overlays[other] or makeView(other)
            local character = other.Character
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not character or not hum or hum.Health <= 0
                or not root or not root:IsA("BasePart") then
                view.group.Visible = false
                return
            end
            local left, top, right, bottom = projectBounds(cam, character)
            if not left then view.group.Visible = false; return end
            local width, height = right - left, bottom - top
            local color = espBoxColor()
            view.group.Visible = true
            view.box.Visible = settings.espBoxes ~= false
            view.box.Position = UDim2.fromOffset(left, top)
            view.box.Size = UDim2.fromOffset(width, height)
            view.outline.Color = color

            local showName = settings.espNames ~= false
            local showMeters = settings.espMeters ~= false
            view.name.Visible = showName or showMeters
            local distanceMeters = selfRoot and math.floor(
                (selfRoot.Position - root.Position).Magnitude * 0.28 + 0.5) or 0
            local userLabel = showName and other.Name or ""
            local metersLabel = showMeters and ("[" .. distanceMeters .. "м]") or ""
            view.name.Text = userLabel .. (userLabel ~= "" and " " or "")
                .. metersLabel
            -- Белый ник с тёмным контуром читается при любом цвете рамок.
            view.name.TextColor3 = C.white
            local labelWidth = math.max(100, math.min(235, width + 105))
            local labelX = math.clamp((left + right - labelWidth)*0.5,
                0, math.max(0, surface.AbsoluteSize.X-labelWidth))
            view.name.Position = UDim2.fromOffset(labelX, top - 22)
            view.name.Size = UDim2.fromOffset(labelWidth, 20)

            view.friend.Visible = settings.espFriendTag ~= false
                and friendCache[other] == true
            view.friend.Position = UDim2.fromOffset(labelX, top - 39)
            view.friend.Size = UDim2.fromOffset(labelWidth, 18)

            local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            view.health.Visible = settings.espHealth ~= false
            view.health.Position = UDim2.fromOffset(left - 9, top)
            view.health.Size = UDim2.fromOffset(5, height)
            view.fill.Size = UDim2.fromScale(1, ratio)
            view.fill.BackgroundColor3 = Color3.fromHSV(ratio / 3, 0.95, 1)

            local showTracer = settings.espTracers ~= false
            view.tracer.Visible = showTracer
            if showTracer then
                local viewSize = surface.AbsoluteSize
                local x1, y1 = viewSize.X * 0.5, viewSize.Y - 5
                local x2, y2 = (left + right) * 0.5, bottom
                local dx, dy = x2 - x1, y2 - y1
                local length = math.sqrt(dx * dx + dy * dy)
                view.tracer.Position = UDim2.fromOffset((x1 + x2) * 0.5,
                    (y1 + y2) * 0.5)
                view.tracer.Size = UDim2.fromOffset(length, 1.5)
                view.tracer.Rotation = math.deg(math.atan2(dy, dx))
                view.tracer.BackgroundColor3 = color
            end
        end
        local function redrawAll()
            local cam = Workspace.CurrentCamera
            if not active or not espEnabled or not cam then
                for _, view in pairs(overlays) do view.group.Visible = false end
                return
            end
            local char = player.Character
            local selfRoot = char and char:FindFirstChild("HumanoidRootPart")
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player then drawView(other, cam, selfRoot) end
            end
        end
        connect(RunService.RenderStepped, function(dt)
            paintTimer = paintTimer + dt
            local interval = #Players:GetPlayers() > 18 and 0.12 or 0.065
            if paintTimer >= interval then
                paintTimer = 0
                redrawAll()
            end
        end)
        connect(Players.PlayerRemoving, removeView)
        registerCleanup(function()
            for other in pairs(overlays) do removeView(other) end
            if overlay.Parent then overlay:Destroy() end
        end)

        -- Управляем поверх старого ESP, не меняя его данные об игроках.
        local card, inside = uiCard("esp", "▣  ESP 2D / РАМКИ И ЗДОРОВЬЕ", 682)
        local toggles = {
            {"2D-рамка вокруг игрока", "espBoxes"},
            {"Линия от низа экрана", "espTracers"},
            {"Полоска здоровья слева", "espHealth"},
            {"Показывать ник", "espNames"},
            {"Расстояние в метрах", "espMeters"},
            {"Зелёная метка (Друг)", "espFriendTag"},
            {"Старая подсветка тела", "espHighlight"}
        }
        for index, item in ipairs(toggles) do
            local key = item[2]
            uiToggle(inside, item[1], (index-1)*36,
                settings[key] ~= false, function(value)
                    settings[key] = value
                    saveSettings()
                end)
        end
        uiLabel(inside, "Цвет 2D-рамки и линий", 257, 24)
        local swatches = {
            {"Белый", {255,255,255}}, {"Красный", {255,50,75}},
            {"Розовый", {255,49,221}}, {"Пурпур", {183,34,255}},
            {"Оранжевый", {255,135,35}}, {"Жёлтый", {255,220,52}},
            {"Зелёный", {57,241,100}}, {"Бирюза", {21,232,193}},
            {"Циан", {63,215,255}}, {"Синий", {52,95,255}}
        }
        local swatchButtons = {}
        local channelLabels = {}
        local channelTracks = {}
        local hexBox
        local preview = new("Frame", inside, {
            Position = UDim2.fromOffset(0, 294),
            Size = UDim2.new(1, 0, 0, 31),
            BackgroundColor3 = espBoxColor(), BorderSizePixel = 0
        })
        corner(preview, 8)
        stroke(preview, C.white, 0.18, 1)
        local previewLabel = new("TextLabel", preview, {
            Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
            Text = "#FFFFFF", TextColor3 = C.white,
            TextStrokeColor3 = Color3.new(0,0,0), TextStrokeTransparency = 0.12,
            TextSize = 14, Font = Enum.Font.GothamBold
        })
        local paletteRow = new("Frame", inside, {
            Position = UDim2.fromOffset(0, 332),
            Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1
        })
        local function getCurrentRGB()
            local t = settings.espColor
            if type(t) ~= "table" then t = {255,255,255} end
            local result = {}
            for i = 1, 3 do
                result[i] = math.clamp(math.floor((tonumber(t[i]) or 255)+0.5),0,255)
            end
            return result
        end
        local function updateColorUI()
            local rgb = getCurrentRGB()
            local chosen = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
            preview.BackgroundColor3 = chosen
            local perceived = 0.299*rgb[1]+0.587*rgb[2]+0.114*rgb[3]
            previewLabel.TextColor3 = perceived > 150
                and Color3.fromRGB(17,24,42) or C.white
            local hex = string.format("#%02X%02X%02X", rgb[1], rgb[2], rgb[3])
            previewLabel.Text = hex
            if hexBox and not hexBox:IsFocused() then hexBox.Text = hex end
            for i, label in ipairs(channelLabels) do
                if label then label.Text = ({"R", "G", "B"})[i]..": "..rgb[i] end
            end
            for i, track in ipairs(channelTracks) do
                local fraction = rgb[i] / 255
                track.fill.Size = UDim2.fromScale(fraction, 1)
                track.thumb.Position = UDim2.new(fraction, 0, 0.5, 0)
            end
            for i, button in ipairs(swatchButtons) do
                local target = swatches[i][2]
                local chosenThis = rgb[1]==target[1] and rgb[2]==target[2]
                    and rgb[3]==target[3]
                button.Text = chosenThis and "✓" or ""
                button.BorderSizePixel = 0
                local border = button:FindFirstChildOfClass("UIStroke")
                if border then
                    border.Thickness = chosenThis and 3 or 1
                    border.Color = chosenThis and cyan or C.white
                end
            end
        end
        local function setRGB(rgb)
            settings.espColor = {
                math.clamp(math.floor((tonumber(rgb[1]) or 255)+0.5),0,255),
                math.clamp(math.floor((tonumber(rgb[2]) or 255)+0.5),0,255),
                math.clamp(math.floor((tonumber(rgb[3]) or 255)+0.5),0,255)
            }
            espColor = espBoxColor()  -- старый Highlight использует тот же цвет
            updateColorUI()
            saveSettings()
        end
        extrasAPI.setESPColor = setRGB
        extrasAPI.getESPColor = getCurrentRGB
        extrasAPI.updateESPColorUI = updateColorUI
        for i, item in ipairs(swatches) do
            local values = item[2]
            local tile = new("TextButton", paletteRow, {
                Position = UDim2.new((i-1)/#swatches, 3, 0, 1),
                Size = UDim2.new(1/#swatches, -6, 1, -2),
                BackgroundColor3 = Color3.fromRGB(values[1],values[2],values[3]),
                Text = "", TextSize = 19, Font = Enum.Font.GothamBold,
                TextColor3 = values[1]+values[2]+values[3] > 510
                    and Color3.new(0,0,0) or Color3.new(1,1,1),
                AutoButtonColor = false
            })
            corner(tile, 7)
            stroke(tile, C.white, 0.20, 1)
            swatchButtons[i] = tile
            connect(tile.Activated, function() setRGB(values) end)
        end
        uiLabel(inside, "RGB: двигай ползунок или жми − / +", 378, 20)
        for i = 1, 3 do
            local channel = i
            local row = uiRow(inside, 404 + (i-1)*41, 36)
            channelLabels[i] = new("TextLabel", row, {
                Position = UDim2.fromOffset(3, 0),
                Size = UDim2.fromOffset(88, 36),
                BackgroundTransparency = 1,
                TextColor3 = C.white, TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local track = new("TextButton", row, {
                Name = "ESP_RGB_" .. channel,
                Position = UDim2.fromOffset(94, 12),
                Size = UDim2.new(1, -210, 0, 12),
                BackgroundColor3 = Color3.fromRGB(29, 39, 85),
                Text = "", AutoButtonColor = false, ZIndex = 2
            })
            corner(track, 6)
            local channelColor = ({Color3.fromRGB(255,49,105),
                Color3.fromRGB(43,236,150),
                Color3.fromRGB(64,156,255)})[channel]
            local fill = new("Frame", track, {
                Size = UDim2.fromScale(0, 1),
                BackgroundColor3 = channelColor,
                BorderSizePixel = 0, ZIndex = 3
            })
            corner(fill, 6)
            local thumb = new("Frame", track, {
                Size = UDim2.fromOffset(16, 19),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = C.white,
                BorderSizePixel = 0, ZIndex = 4
            })
            corner(thumb, 9)
            stroke(thumb, channelColor, 0, 1)
            channelTracks[channel] = {fill = fill, thumb = thumb}
            local heldInput = nil
            local function updateFromX(x)
                local width = math.max(track.AbsoluteSize.X, 1)
                local t = math.clamp((x-track.AbsolutePosition.X)/width, 0, 1)
                local rgb = getCurrentRGB()
                rgb[channel] = math.floor(t*255+0.5)
                setRGB(rgb)
            end
            connect(track.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.Touch or
                    input.UserInputType == Enum.UserInputType.MouseButton1 then
                    heldInput = input
                    updateFromX(input.Position.X)
                end
            end)
            connect(UIS.InputChanged, function(input)
                if not heldInput then return end
                local touch = heldInput.UserInputType == Enum.UserInputType.Touch
                if (touch and input == heldInput) or
                    (not touch and input.UserInputType ==
                        Enum.UserInputType.MouseMovement) then
                    updateFromX(input.Position.X)
                end
            end)
            connect(UIS.InputEnded, function(input)
                if input == heldInput then heldInput = nil end
            end)
            for _, opt in ipairs({{direction=-1, right=57}, {direction=1, right=5}}) do
                local step = new("TextButton", row, {
                    Position = UDim2.new(1, -opt.right-42, 0, 2),
                    Size = UDim2.fromOffset(42, 31),
                    BackgroundColor3 = C.panelLight,
                    Text = opt.direction == -1 and "−" or "+",
                    TextColor3 = cyan, Font = Enum.Font.GothamBold,
                    TextSize = 19, AutoButtonColor = false
                })
                corner(step, 7)
                stroke(step, violet, 0.35)
                local delta = opt.direction
                connect(step.Activated, function()
                    local rgb = getCurrentRGB()
                    rgb[channel] = math.clamp(rgb[channel]+delta*5, 0, 255)
                    setRGB(rgb)
                end)
            end
        end
        uiLabel(inside, "Свой HEX (#RRGGBB или #RGB)", 533, 21)
        hexBox = new("TextBox", inside, {
            Position = UDim2.fromOffset(0, 559),
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundColor3 = C.panelLight,
            Text = "#FFFFFF", TextColor3 = C.white,
            PlaceholderText = "#FFFFFF", PlaceholderColor3 = C.muted,
            Font = Enum.Font.Code, TextSize = 15,
            ClearTextOnFocus = false, BorderSizePixel = 0
        })
        corner(hexBox, 8)
        stroke(hexBox, violet, 0.22, 1)
        connect(hexBox.FocusLost, function()
            local h = hexBox.Text:match("^%s*#?([A-Fa-f0-9]+)%s*$")
            if not h or (#h ~= 3 and #h ~= 6) then
                updateColorUI()
                return
            end
            if #h == 3 then
                h = h:sub(1,1):rep(2)..h:sub(2,2):rep(2)..h:sub(3,3):rep(2)
            end
            setRGB({tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16),
                tonumber(h:sub(5,6),16)})
        end)
        uiLabel(inside, "По умолчанию белый. Цвет сохраняется автоматически.",
            607, 30)
        updateColorUI()
    end

    -- ===== ЧАСТЬ 6: AIMBOT / TARGET SELECTION =====
    -- СП > обычный приоритет > остальные игроки.
    -- Raycast ESP и аимбота намеренно разделены.
local priorityTargets = {}
do
    local priorityEnabled = true
    local aimSightParams = RaycastParams.new()
    aimSightParams.FilterType = Enum.RaycastFilterType.Exclude
    aimSightParams.IgnoreWater = true
    local aimGazeThreshold = math.cos(math.rad(25))

    local function targetLooksAtMe(targetCharacter, myPosition)
        local head = targetCharacter:FindFirstChild("Head")
            or targetCharacter:FindFirstChild("HumanoidRootPart")
        if not head or not head:IsA("BasePart") then return false end
        local direction = myPosition - head.Position
        if direction.Magnitude < 0.001 then return true end
        return head.CFrame.LookVector:Dot(direction.Unit)
            >= aimGazeThreshold
    end

    local function targetIsVisible(part, targetCharacter, origin)
        local direction = part.Position - origin
        if direction.Magnitude < 0.001 then return true end
        local result = Workspace:Raycast(origin, direction, aimSightParams)
        return result == nil
            or result.Instance:IsDescendantOf(targetCharacter)
    end

    -- Считаем ранг каждого кандидата только один раз за сканирование.
    local function getTarget()
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        local myCharacter = player.Character
        local root = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        local hum = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return nil end
        local myHead = myCharacter:FindFirstChild("Head") or root
        local center = cam.ViewportSize * 0.5
        aimSightParams.FilterDescendantsInstances = {myCharacter}

        local bestPart = nil
        local bestGroup, bestVisible, bestLooking = -1, -1, -1
        local bestDistance = math.huge

        for _, other in ipairs(Players:GetPlayers()) do
            local allowed = other ~= player
                and not whiteList[other.UserId]
                and (not ignoreFriends or friendCache[other] ~= true)
            if allowed then
                local character = other.Character
                local targetHum = character
                    and character:FindFirstChildOfClass("Humanoid")
                local part = character and (
                    character:FindFirstChild("Head")
                    or character:FindFirstChild("HumanoidRootPart")
                )
                if targetHum and targetHum.Health > 0
                    and part and part:IsA("BasePart")
                    and part:IsDescendantOf(Workspace) then
                    local screenPoint, onScreen = cam:WorldToViewportPoint(
                        part.Position
                    )
                    local inFov = onScreen and (
                        Vector2.new(screenPoint.X, screenPoint.Y) - center
                    ).Magnitude <= fovRadius
                    if aim360 or inFov then
                        local group = 1
                        if superPriorityTargets[other.UserId] then
                            group = 3
                        elseif priorityEnabled
                            and priorityTargets[other.UserId] then
                            group = 2
                        end
                        local visible = targetIsVisible(
                            part, character, cam.CFrame.Position
                        )
                        local visibleRank = preferVisible
                            and (visible and 1 or 0) or 0
                        local lookingRank = preferLooking
                            and visible
                            and targetLooksAtMe(character, myHead.Position)
                            and 1 or 0
                        local distance = (part.Position - root.Position).Magnitude

                        local better = group > bestGroup
                            or (group == bestGroup
                                and visibleRank > bestVisible)
                            or (group == bestGroup
                                and visibleRank == bestVisible
                                and lookingRank > bestLooking)
                            or (group == bestGroup
                                and visibleRank == bestVisible
                                and lookingRank == bestLooking
                                and distance < bestDistance)
                        if better then
                            bestPart = part
                            bestGroup = group
                            bestVisible = visibleRank
                            bestLooking = lookingRank
                            bestDistance = distance
                        end
                    end
                end
            end
        end
        return bestPart
    end

    -- Временное отключение аима, если игрок сам крутит камеру.
    connect(UIS.InputBegan, function(input, processed)
        local cam = Workspace.CurrentCamera
        if not cam or processed then return end
        if input.UserInputType == Enum.UserInputType.Touch
            and input.Position.X > cam.ViewportSize.X * 0.45 then
            cameraTouches[input] = true
        end
    end)
    connect(UIS.InputChanged, function(input, processed)
        local isMouse = input.UserInputType
            == Enum.UserInputType.MouseMovement and not processed
        if isMouse or cameraTouches[input] then
            lastManualInput = os.clock()
            if returning then
                returning = false
                preAimRotation = nil
            end
        end
    end)
    connect(UIS.InputEnded, function(input)
        cameraTouches[input] = nil
    end)
    connect(UIS.WindowFocusReleased, function()
        table.clear(cameraTouches)
    end)

    connect(RunService.RenderStepped, function(dt)
        if not active then return end
        camera = Workspace.CurrentCamera
        if not camera then return end
        if returning and preAimRotation then
            local desired = CFrame.new(camera.CFrame.Position)
                * preAimRotation
            local factor = 1 - math.exp(-dt / 0.12)
            camera.CFrame = camera.CFrame:Lerp(desired, factor)
            if (camera.CFrame.LookVector - desired.LookVector).Magnitude
                < 0.01 then
                camera.CFrame = desired
                returning = false
                preAimRotation = nil
            end
            return
        end
        if not aimEnabled or os.clock() - lastManualInput < 0.35 then
            return
        end
        local now = os.clock()
        if now >= nextTargetScan then
            selectedTarget = getTarget()
            nextTargetScan = now + 0.1
        end
        local target = selectedTarget
        if not target or not target.Parent
            or not target:IsDescendantOf(Workspace) then return end
        if (target.Position - camera.CFrame.Position).Magnitude
            < 0.001 then return end
        if not preAimRotation then
            preAimRotation = camera.CFrame.Rotation
        end
        local desired = CFrame.lookAt(
            camera.CFrame.Position, target.Position
        )
        local factor = smoothness <= 0
            and 1 or math.clamp(dt / smoothness, 0, 1)
        camera.CFrame = camera.CFrame:Lerp(desired, factor)
    end)
    connect(player.CharacterAdded, function()
        selectedTarget, nextTargetScan = nil, 0
        preAimRotation, returning = nil, false
        table.clear(cameraTouches)
    end)

    -- ===== КАРТОЧКА AIMBOT =====
    local aimCard, aimInside = uiCard(
        "aim", "⊕  НАВЕДЕНИЕ И ПРИОРИТЕТЫ", 390
    )
    uiToggle(aimInside, "Автонаводка", 0,
        aimEnabled, function(value)
            local wasEnabled = aimEnabled
            aimEnabled = value
            settings.aimEnabled = value
            selectedTarget, nextTargetScan = nil, 0
            if value then
                preAimRotation, returning = nil, false
            else
                returning = wasEnabled and preAimRotation ~= nil
            end
            saveSettings()
        end)
    uiToggle(aimInside, "Обзор 360°", 36,
        aim360, function(value)
            aim360 = value
            settings.aim360 = value
            selectedTarget, nextTargetScan = nil, 0
            saveSettings()
        end)
    uiToggle(aimInside, "Приоритет без стен", 72,
        preferVisible, function(value)
            preferVisible = value
            settings.preferVisible = value
            nextTargetScan = 0
            saveSettings()
        end)
    uiToggle(aimInside, "Приоритет: смотрит на меня", 108,
        preferLooking, function(value)
            preferLooking = value
            settings.preferLooking = value
            nextTargetScan = 0
            saveSettings()
        end)
    uiToggle(aimInside, "Не целиться в друзей", 144,
        ignoreFriends, function(value)
            ignoreFriends = value
            settings.ignoreFriends = value
            selectedTarget, nextTargetScan = nil, 0
            saveSettings()
        end)
    uiToggle(aimInside, "Приоритет выбранных игроков", 180,
        priorityEnabled, function(value)
            priorityEnabled = value
            selectedTarget, nextTargetScan = nil, 0
        end)
    uiStepper(aimInside, "FOV", 218,
        fovRadius, 20, 600, 10, 0, function(value)
            fovRadius = value
            settings.fovRadius = value
            nextTargetScan = 0
            saveSettings()
        end)
    uiStepper(aimInside, "Плавность", 260,
        smoothness, 0, 1, 0.05, 2, function(value)
            smoothness = value
            settings.smoothness = value
            saveSettings()
        end)
    uiLabel(aimInside,
        "СП > выбранные > остальные. Белый список исключён.",
        306, 33)
end

    -- ===== ЧАСТЬ 7: ИГРОКИ / СП / ТП / БЕЛЫЙ СПИСОК =====
    -- Используем таблицы из частей 1 и 6, НЕ создаём их повторно.
    local priorityRows, whiteRows = {}, {}
    local invalidateTarget

    local priorityCard, priorityInside = uiCard(
        "priority", "♛  ПРИОРИТЕТ ИГРОКОВ", 300
    )
    local prioritySummary = uiStatus(priorityInside, "Загрузка игроков...", 0)
    uiButton(priorityInside, "Снять все приоритеты", 32, function()
        table.clear(priorityTargets)
        table.clear(superPriorityTargets)
        invalidateTarget()
    end, violet)

    local whiteCard, whiteInside = uiCard(
        "whitelist", "♧  БЕЛЫЙ СПИСОК", 260
    )
    local whiteSummary = uiStatus(whiteInside, "Загрузка игроков...", 0)

    -- Прокручиваемые списки, чтобы не растягивать окно на сервере
    -- с большим количеством участников.
    local function makePlayerList(parent, y, height)
        local list = new("ScrollingFrame", parent, {
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = C.base,
            BackgroundTransparency = 0.22,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = cyan,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y
        })
        corner(list, 9)
        stroke(list, violet, 0.72)
        new("UIListLayout", list, {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        })
        new("UIPadding", list, {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 9)
        })
        return list
    end

    local priorityList = makePlayerList(priorityInside, 76, 154)
    uiLabel(priorityInside,
        "П — приоритет  |  СП — супер  |  Б — белый список", 235, 20)
    local whiteListFrame = makePlayerList(whiteInside, 32, 132)
    uiButton(whiteInside, "Очистить белый список", 174, function()
        table.clear(whiteList)
        invalidateTarget()
    end, C.red)

    -- Все кнопки создаются один раз на игрока.
    local function smallPlayerButton(parent, caption, x, width)
        local btn = new("TextButton", parent, {
            Position = UDim2.new(x, 2, 0, 3),
            Size = UDim2.new(width, -4, 1, -6),
            BackgroundColor3 = C.panelLight,
            Text = caption,
            TextColor3 = C.white,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            TextWrapped = true
        })
        corner(btn, 7)
        stroke(btn, violet, 0.7)
        return btn
    end

    local function refreshSelections()
        if not active then return end
        local sorted = {}
        for other in pairs(priorityRows) do
            table.insert(sorted, other)
        end
        table.sort(sorted, function(a, b)
            return a.Name:lower() < b.Name:lower()
        end)

        local normalCount, superCount, whiteCount = 0, 0, 0
        for index, other in ipairs(sorted) do
            local id = other.UserId
            local normal = priorityTargets[id] == true
            local super = superPriorityTargets[id] == true
            local white = whiteList[id] == true
            if normal then normalCount = normalCount + 1 end
            if super then superCount = superCount + 1 end
            if white then whiteCount = whiteCount + 1 end

            local data = priorityRows[other]
            data.frame.LayoutOrder = index
            data.name.Text = other.DisplayName .. "\n@" .. other.Name
            data.normal.Text = normal and "П ✓" or "П"
            data.super.Text = super and "СП ✓" or "СП"
            data.white.Text = white and "Б ✓" or "Б"
            data.normal.BackgroundColor3 = normal and violet or C.panelLight
            data.super.BackgroundColor3 = super and C.red or C.panelLight
            data.white.BackgroundColor3 = white and C.green or C.panelLight

            local whiteData = whiteRows[other]
            if whiteData then
                whiteData.frame.LayoutOrder = index
                whiteData.button.Text = (white and "[✓]  " or "[ ]  ")
                    .. other.DisplayName .. "  @" .. other.Name
                whiteData.button.BackgroundColor3 = white
                    and Color3.fromRGB(27, 104, 101) or C.panelLight
            end
        end
        prioritySummary.Text = string.format(
            "Игроков: %d   |   П: %d   |   СП: %d",
            #sorted, normalCount, superCount
        )
        whiteSummary.Text = string.format(
            "В белом списке: %d   |   игроков: %d",
            whiteCount, #sorted
        )
    end

    invalidateTarget = function()
        selectedTarget = nil
        nextTargetScan = 0
        refreshSelections()
    end

    -- Безопасная попытка телепорта: персонажи могут исчезнуть
    -- или возродиться в момент нажатия кнопки.
    local function teleportToPlayer(other)
        if not active or other.Parent ~= Players then
            status("ТП: игрок уже вышел")
            return
        end
        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local targetChar = other.Character
        local targetRoot = targetChar and targetChar:FindFirstChild(
            "HumanoidRootPart"
        )
        local targetHum = targetChar and targetChar:FindFirstChildOfClass(
            "Humanoid"
        )
        if not myRoot or not myHum or myHum.Health <= 0 or myHum.Sit then
            status("ТП: дождись возрождения или встань")
            return
        end
        if not targetRoot or not targetHum or targetHum.Health <= 0
            or not targetRoot:IsDescendantOf(Workspace) then
            status("ТП: цель не загружена")
            return
        end
        local success = pcall(function()
            local pivotOffset = myRoot.CFrame:ToObjectSpace(
                myChar:GetPivot()
            )
            local destination = targetRoot.CFrame * CFrame.new(4, 0, 0)
            myChar:PivotTo(destination * pivotOffset)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end)
        status(success and ("Попытка ТП к @" .. other.Name)
            or "ТП: ошибка перемещения")
        if success then invalidateTarget() end
    end

    local function addListPlayer(other)
        if other == player or priorityRows[other] then return end
        local frame = new("Frame", priorityList, {
            Name = "Player_" .. other.UserId,
            Size = UDim2.new(1, 0, 0, 43),
            BackgroundColor3 = C.panel,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0
        })
        corner(frame, 8)
        local name = smallPlayerButton(frame, other.DisplayName, 0, 0.42)
        name.TextSize = 10
        name.TextXAlignment = Enum.TextXAlignment.Left
        local normal = smallPlayerButton(frame, "П", 0.42, 0.145)
        local super = smallPlayerButton(frame, "СП", 0.565, 0.145)
        local white = smallPlayerButton(frame, "Б", 0.71, 0.145)
        local tp = smallPlayerButton(frame, "ТП", 0.855, 0.145)
        priorityRows[other] = {
            frame = frame, name = name, normal = normal,
            super = super, white = white
        }
        connect(normal.Activated, function()
            priorityTargets[other.UserId] = not priorityTargets[other.UserId]
                or nil
            invalidateTarget()
        end)
        connect(super.Activated, function()
            superPriorityTargets[other.UserId] =
                not superPriorityTargets[other.UserId] or nil
            invalidateTarget()
        end)
        connect(white.Activated, function()
            whiteList[other.UserId] = not whiteList[other.UserId] or nil
            invalidateTarget()
        end)
        connect(tp.Activated, function() teleportToPlayer(other) end)
        connect(name.Activated, function()
            status("Выбран игрок: @" .. other.Name)
        end)

        local whiteFrame = new("Frame", whiteListFrame, {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1
        })
        local whiteButton = smallPlayerButton(whiteFrame, "", 0, 1)
        whiteButton.TextXAlignment = Enum.TextXAlignment.Left
        whiteRows[other] = {frame = whiteFrame, button = whiteButton}
        connect(whiteButton.Activated, function()
            whiteList[other.UserId] = not whiteList[other.UserId] or nil
            invalidateTarget()
        end)
        refreshSelections()
    end

    connect(Players.PlayerAdded, addListPlayer)
    connect(Players.PlayerRemoving, function(other)
        local data, whiteData = priorityRows[other], whiteRows[other]
        if data then data.frame:Destroy(); priorityRows[other] = nil end
        if whiteData then
            whiteData.frame:Destroy()
            whiteRows[other] = nil
        end
        priorityTargets[other.UserId] = nil
        superPriorityTargets[other.UserId] = nil
        whiteList[other.UserId] = nil
        invalidateTarget()
    end)
    for _, other in ipairs(Players:GetPlayers()) do
        addListPlayer(other)
    end
    refreshSelections()


    -- ===== ЧАСТЬ 8: ЗАЩИТА / HITBOX / СТЕНЫ / КАМЕРА =====
do
    -- Все изменённые свойства восстанавливаем при выключении.
    local spinHumanoid, savedAutoRotate = nil, nil
    local function stopSpin()
        if spinHumanoid and spinHumanoid.Parent then
            pcall(function() spinHumanoid.AutoRotate = savedAutoRotate end)
        end
        spinHumanoid, savedAutoRotate = nil, nil
    end

    local function restoreHitbox(other)
        local data = originalHitboxes[other]
        if not data then return end
        originalHitboxes[other] = nil
        local root = data.root
        if root and root.Parent then
            pcall(function()
                root.Size = data.size
                root.Transparency = data.transparency
                root.CanCollide = data.canCollide
            end)
        end
    end

    local function updateHitboxes()
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player then
                local char = other.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local allowed = hitboxEnabled and not whiteList[other.UserId]
                    and root and root:IsA("BasePart")
                local previous = originalHitboxes[other]
                if previous and (not allowed or previous.root ~= root) then
                    restoreHitbox(other)
                end
                if allowed then
                    if not originalHitboxes[other] then
                        originalHitboxes[other] = {
                            root = root, size = root.Size,
                            transparency = root.Transparency,
                            canCollide = root.CanCollide
                        }
                    end
                    local targetSize = Vector3.new(
                        hitboxSize, hitboxSize, hitboxSize
                    )
                    if root.Size ~= targetSize then root.Size = targetSize end
                    if root.Transparency ~= 0.7 then root.Transparency = 0.7 end
                    if root.CanCollide then root.CanCollide = false end
                end
            end
        end
    end

    -- В старом скрипте «Wallbang» отключал коллизии объектов.
    -- Оставляем этот режим, но не обещаем пробитие пуль сервером.
    local wallGeneration = 0
    local function isWallPart(part)
        if not part:IsA("BasePart") or not part.CanCollide then
            return false
        end
        local name = part.Name:lower()
        -- Только достаточно вертикальные и тонкие перегородки.
        -- Горизонтальные платформы и пол никогда не отключаем.
        if part.Size.Y < 3 or math.min(part.Size.X, part.Size.Z) > 4 then
            return false
        end
        if name == "baseplate" or name == "floor"
            or name == "ground" or name == "humanoidrootpart"
            or name == "head" then return false end
        local ancestor = part.Parent
        while ancestor and ancestor ~= Workspace do
            if ancestor:IsA("Model")
                and ancestor:FindFirstChildOfClass("Humanoid") then
                return false
            end
            ancestor = ancestor.Parent
        end
        return true
    end
    local function changeWall(part)
        if not isWallPart(part) then return end
        if savedWallCollisions[part] ~= nil then return end
        savedWallCollisions[part] = part.CanCollide
        part.CanCollide = false
    end
    local function restoreWalls()
        wallGeneration = wallGeneration + 1
        for part, oldValue in pairs(savedWallCollisions) do
            if part and part.Parent then
                pcall(function() part.CanCollide = oldValue end)
            end
        end
        table.clear(savedWallCollisions)
    end
    local function setWallbang(enabled)
        wallbangEnabled = enabled
        wallGeneration = wallGeneration + 1
        if not enabled then restoreWalls(); return end
        local generation = wallGeneration
        task.spawn(function()
            for index, part in ipairs(Workspace:GetDescendants()) do
                if not active or not wallbangEnabled
                    or generation ~= wallGeneration then return end
                changeWall(part)
                if index % 120 == 0 then task.wait() end
            end
        end)
    end
    connect(Workspace.DescendantAdded, function(part)
        if not wallbangEnabled then return end
        task.defer(function()
            if active and wallbangEnabled and part.Parent then
                changeWall(part)
            end
        end)
    end)
    connect(Players.PlayerRemoving, restoreHitbox)

    local protectionTimer = 0
    connect(RunService.Heartbeat, function(dt)
        if not active then return end
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if spinEnabled and root and hum and hum.Health > 0 then
            if spinHumanoid ~= hum then
                stopSpin()
                spinHumanoid, savedAutoRotate = hum, hum.AutoRotate
            end
            hum.AutoRotate = false
            root.CFrame = root.CFrame * CFrame.Angles(
                0, math.rad(spinSpeed * dt), 0
            )
        else
            stopSpin()
        end
        if antiFlingEnabled and root and hum and hum.Health > 0 then
            if root.AssemblyAngularVelocity.Magnitude > 100 then
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
        protectionTimer = protectionTimer + dt
        if protectionTimer >= 0.35 then
            protectionTimer = 0
            updateHitboxes()
        end
    end)

    local protectCard, protectInside = uiCard(
        "protection", "⬡  ЗАЩИТА И ЧИТЫ", 333
    )
    uiToggle(protectInside, "Anti-Fling", 0,
        antiFlingEnabled, function(value)
            antiFlingEnabled = value
            settings.antiFlingEnabled = value
            saveSettings()
        end)
    uiToggle(protectInside, "Кручение персонажа", 38,
        spinEnabled, function(value)
            spinEnabled = value
            settings.spinEnabled = value
            if not value then stopSpin() end
            saveSettings()
        end)
    uiStepper(protectInside, "Скорость вращения", 76,
        spinSpeed, 100, 5000, 100, 0, function(value)
            spinSpeed = value
            settings.spinSpeed = value
            saveSettings()
        end)
    uiSeparator(protectInside, 117)
    uiToggle(protectInside, "Hitbox Expander", 127,
        hitboxEnabled, function(value)
            hitboxEnabled = value
            settings.hitboxEnabled = value
            updateHitboxes()
            saveSettings()
        end)
    uiStepper(protectInside, "Размер Hitbox", 165,
        hitboxSize, 2, 50, 1, 0, function(value)
            hitboxSize = value
            settings.hitboxSize = value
            updateHitboxes()
            saveSettings()
        end)
    uiSeparator(protectInside, 207)
    uiToggle(protectInside, "Стены без коллизий (локально)", 217,
        wallbangEnabled, function(value)
            setWallbang(value)
            settings.wallbangEnabled = value
            saveSettings()
        end)
    uiLabel(protectInside,
        "Это старый режим Wallbang: он меняет коллизии, а не пули.",
        255, 27)

    -- Правильные свойства зума принадлежат Player, а не Camera.
    local originalCameraMode = player.CameraMode
    local originalMinZoom = player.CameraMinZoomDistance
    local originalMaxZoom = player.CameraMaxZoomDistance
    local cameraChanged, thirdPerson = false, false
    local function restoreCamera()
        if not cameraChanged then return end
        pcall(function()
            player.CameraMode = Enum.CameraMode.Classic
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = originalMaxZoom
            player.CameraMinZoomDistance = originalMinZoom
            player.CameraMode = originalCameraMode
        end)
        cameraChanged = false
    end
    local cameraCard, cameraInside = uiCard(
        "camera", "▣  НАСТРОЙКИ КАМЕРЫ", 170
    )
    local cameraStatus = uiStatus(
        cameraInside, "Используются настройки камеры игры", 0
    )
    local cameraButton
    cameraButton = uiButton(cameraInside, "Переключить вид камеры", 38,
        function()
            thirdPerson = not thirdPerson
            local success = pcall(function()
                player.CameraMode = Enum.CameraMode.Classic
                if thirdPerson then
                    player.CameraMaxZoomDistance = 20
                    player.CameraMinZoomDistance = 10
                else
                    player.CameraMinZoomDistance = 0.5
                    player.CameraMaxZoomDistance = 0.5
                    player.CameraMode = Enum.CameraMode.LockFirstPerson
                end
            end)
            if success then
                cameraChanged = true
                cameraStatus.Text = thirdPerson
                    and "Вид от третьего лица" or "Вид от первого лица"
            else
                thirdPerson = not thirdPerson
                cameraStatus.Text = "Камера: игра ограничивает управление"
            end
        end, cyan)
    uiButton(cameraInside, "Вернуть камеру игры", 82, function()
        restoreCamera()
        thirdPerson = false
        cameraStatus.Text = "Настройки камеры восстановлены"
    end, violet)

    registerCleanup(function()
        stopSpin()
        for other in pairs(originalHitboxes) do restoreHitbox(other) end
        restoreWalls()
        restoreCamera()
    end)
    if wallbangEnabled then setWallbang(true) end
    if hitboxEnabled then updateHitboxes() end
end


    -- ===== ЧАСТЬ 9: ПОЛЁТ И NOCLIP =====
    -- Управление: джойстик Roblox + отдельные кнопки высоты.
    do
        local flyEnabled, noclipEnabled = false, false
        local flySpeed, failedRoot = 50, nil
        local flyRoot, flyHumanoid, originalAutoRotate
        local flyAttachment, flyVelocity, flyOrientation
        local verticalHeld, collisions = {}, {}
        local noclipCharacter, noclipDescConnection
        local collisionTimer, flyTextTimer = 0, 0
        -- Кнопки высоты появляются только при полёте.
        local flightPad = new("Frame", gui, {
            Name = "TimkaFlightControls",
            Size = UDim2.fromOffset(82, 130),
            Position = UDim2.new(1, -94, 0.5, -65),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 30
        })
        local function heightButton(textValue, offsetY, direction)
            local object = new("TextButton", flightPad, {
                Size = UDim2.fromOffset(80, 58),
                Position = UDim2.fromOffset(0, offsetY),
                BackgroundColor3 = C.panel,
                BackgroundTransparency = 0.08,
                Text = textValue, TextColor3 = C.white,
                TextSize = 12, Font = Enum.Font.GothamBold,
                AutoButtonColor = false, ZIndex = 31
            })
            corner(object, 12)
            stroke(object, direction > 0 and cyan or violet, 0.12, 2)
            connect(object.InputBegan, function(input)
                local t = input.UserInputType
                if t == Enum.UserInputType.Touch
                    or t == Enum.UserInputType.MouseButton1 then
                    verticalHeld[input] = direction
                end
            end)
            return object
        end
        heightButton("▲ ВВЕРХ", 0, 1)
        heightButton("▼ ВНИЗ", 70, -1)
        connect(UIS.InputEnded, function(input)
            verticalHeld[input] = nil
        end)
        connect(UIS.WindowFocusReleased, function()
            table.clear(verticalHeld)
        end)
        local function stopFlight()
            if flyVelocity then flyVelocity:Destroy() end
            if flyOrientation then flyOrientation:Destroy() end
            if flyAttachment then flyAttachment:Destroy() end
            flyVelocity, flyOrientation, flyAttachment = nil, nil, nil
            if flyHumanoid and flyHumanoid.Parent then
                if not spinEnabled and originalAutoRotate ~= nil then
                    flyHumanoid.AutoRotate = originalAutoRotate
                end
            end
            if flyRoot and flyRoot.Parent then
                flyRoot.AssemblyLinearVelocity = Vector3.zero
                flyRoot.AssemblyAngularVelocity = Vector3.zero
            end
            flyRoot, flyHumanoid, originalAutoRotate = nil, nil, nil
            table.clear(verticalHeld)
            flightPad.Visible = false
        end
        local function restoreCollisions()
            for part, original in pairs(collisions) do
                if part and part.Parent then
                    pcall(function() part.CanCollide = original end)
                end
            end
            table.clear(collisions)
        end
        local function trackNoclipPart(part)
            if not noclipEnabled or not part:IsA("BasePart") then return end
            if collisions[part] == nil then
                collisions[part] = part.CanCollide
            end
            part.CanCollide = false
        end
        local function watchNoclipCharacter(character)
            if noclipDescConnection then
                noclipDescConnection:Disconnect()
                noclipDescConnection = nil
            end
            noclipCharacter = character
            if not character then return end
            noclipDescConnection = character.DescendantAdded:Connect(
                function(part)
                    if active and noclipEnabled then
                        trackNoclipPart(part)
                    end
                end
            )
            if noclipEnabled then
                for _, part in ipairs(character:GetDescendants()) do
                    trackNoclipPart(part)
                end
            end
        end
        local function setNoclip(enabled)
            noclipEnabled = enabled
            if not enabled then
                restoreCollisions()
            elseif noclipCharacter then
                for _, part in ipairs(noclipCharacter:GetDescendants()) do
                    trackNoclipPart(part)
                end
            end
        end
        local function startFlight(root, humanoid)
            stopFlight()
            flyRoot, flyHumanoid = root, humanoid
            originalAutoRotate = humanoid.AutoRotate
            humanoid.AutoRotate = false
            flyAttachment = new("Attachment", root, {
                Name = "TimkaFlyAttachment"
            })
            flyVelocity = new("LinearVelocity", root, {
                Name = "TimkaFlyVelocity",
                Attachment0 = flyAttachment,
                RelativeTo = Enum.ActuatorRelativeTo.World,
                VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
                ForceLimitsEnabled = false,
                VectorVelocity = Vector3.zero
            })
            flyOrientation = new("AlignOrientation", root, {
                Name = "TimkaFlyOrientation",
                Attachment0 = flyAttachment,
                Mode = Enum.OrientationAlignmentMode.OneAttachment,
                MaxTorque = 1000000,
                Responsiveness = 25,
                CFrame = root.CFrame.Rotation
            })
            root.AssemblyLinearVelocity = Vector3.zero
            flightPad.Visible = UIS.TouchEnabled
        end
        -- Отдельная вкладка в горизонтальном меню.
        local flyCard, flyInside = uiCard(
            "flight", "➤  ПОЛЁТ / NOCLIP", 228
        )
        local flyStatus = uiStatus(flyInside, "Полёт выключен", 131)
        uiToggle(flyInside, "Включить полёт", 0, false, function(value)
            flyEnabled = value
            failedRoot = nil
            if not value then stopFlight() end
            flyStatus.Text = value and "Полёт включён" or "Полёт выключен"
        end)
        uiStepper(flyInside, "Скорость полёта", 42,
            flySpeed, 10, 150, 10, 0, function(value)
                flySpeed = value
            end)
        uiToggle(flyInside, "Noclip / сквозь стены", 87,
            false, function(value)
                setNoclip(value)
                status(value and "Noclip включён" or "Noclip выключен")
            end)
        uiLabel(flyInside,
            "Джойстик — движение, ▲ / ▼ — высота.", 163, 26)
        watchNoclipCharacter(player.Character)
        connect(player.CharacterAdded, function(character)
            failedRoot = nil
            restoreCollisions()
            watchNoclipCharacter(character)
        end)
        connect(player.CharacterRemoving, function()
            stopFlight()
            restoreCollisions()
            watchNoclipCharacter(nil)
            failedRoot = nil
        end)
        -- Обновляем коллизии без постоянного сканирования мира.
        connect(RunService.Stepped, function(_, dt)
            if not active or not noclipEnabled then return end
            collisionTimer = collisionTimer + dt
            if collisionTimer < 0.05 then return end
            collisionTimer = 0
            for part in pairs(collisions) do
                if part and part.Parent then
                    if part.CanCollide then
                        part.CanCollide = false
                    end
                else
                    collisions[part] = nil
                end
            end
        end)
        local function key(code)
            return UIS:IsKeyDown(code) and 1 or 0
        end
        connect(RunService.Heartbeat, function(dt)
            if not active or not flyEnabled then return end
            local character = player.Character
            local root = character and character:FindFirstChild(
                "HumanoidRootPart"
            )
            local hum = character and character:FindFirstChildOfClass(
                "Humanoid"
            )
            if not root or not hum or hum.Health <= 0
                or root.Anchored or hum.Sit then
                if flyRoot then stopFlight() end
                flyStatus.Text = "Полёт: ожидаю персонажа"
                return
            end
            if root == failedRoot then return end
            if root ~= flyRoot or not flyVelocity or not flyVelocity.Parent
                or not flyOrientation or not flyOrientation.Parent then
                local ok = pcall(startFlight, root, hum)
                if not ok then
                    stopFlight()
                    failedRoot = root
                    flyStatus.Text = "Полёт недоступен в этой игре"
                    return
                end
            end
            local cam = Workspace.CurrentCamera
            if not cam then
                flyVelocity.VectorVelocity = Vector3.zero
                return
            end
            local look = cam.CFrame.LookVector
            local forward = Vector3.new(look.X, 0, look.Z)
            if forward.Magnitude < 0.001 then
                local fallback = root.CFrame.LookVector
                forward = Vector3.new(fallback.X, 0, fallback.Z)
            end
            forward = forward.Magnitude > 0.001
                and forward.Unit or Vector3.new(0, 0, -1)
            local right = Vector3.new(-forward.Z, 0, forward.X)
            local movement = hum.MoveDirection
            movement = Vector3.new(movement.X, 0, movement.Z)
            local vertical = 0
            if not UIS:GetFocusedTextBox() then
                for _, direction in pairs(verticalHeld) do
                    vertical = vertical + direction
                end
                if UIS.KeyboardEnabled then
                    local x = key(Enum.KeyCode.D)
                        + key(Enum.KeyCode.Right)
                        - key(Enum.KeyCode.A)
                        - key(Enum.KeyCode.Left)
                    local z = key(Enum.KeyCode.W)
                        + key(Enum.KeyCode.Up)
                        - key(Enum.KeyCode.S)
                        - key(Enum.KeyCode.Down)
                    if x ~= 0 or z ~= 0 then
                        movement = right * x + forward * z
                    end
                    vertical = vertical + key(Enum.KeyCode.Space)
                        - math.max(key(Enum.KeyCode.LeftControl),
                            key(Enum.KeyCode.RightControl))
                end
            else
                movement = Vector3.zero
            end
            local desired = movement
                + Vector3.new(0, math.clamp(vertical, -1, 1), 0)
            if desired.Magnitude > 1 then desired = desired.Unit end
            flyVelocity.VectorVelocity = desired * flySpeed
            flyOrientation.CFrame = CFrame.lookAt(Vector3.zero, forward)
            hum.AutoRotate = false
            flyTextTimer = flyTextTimer + dt
            if flyTextTimer >= 0.25 then
                flyTextTimer = 0
                flyStatus.Text = "Полёт включён · " .. flySpeed
            end
        end)
        registerCleanup(function()
            flyEnabled, noclipEnabled = false, false
            stopFlight()
            restoreCollisions()
            if noclipDescConnection then
                noclipDescConnection:Disconnect()
            end
            noclipDescConnection, noclipCharacter = nil, nil
        end)
    end


    -- ===== ЧАСТЬ 10: НЕОНОВОЕ МИНИ-МЕНЮ ИГРОКА =====
do
    -- Одна система выбора: таблицы из частей 1, 6 и 7.
    local currentClickedPlayer = nil
    local clickRadius = math.clamp(tonumber(settings.popupRadius) or 35, 12, 90)
    local flingActive = false
    local flingSpin = nil
    local flingGeneration = 0
    local flingRoot, flingCharacter, flingOldPivot = nil, nil, nil
    local priorAntiFling = nil
    local popupGeneration = 0

    -- Мини-меню в том же стиле, что большое: без группового градиента
    -- поверх текста, с непрозрачными карточками и RGB-неоном.
    -- SKETCH REPLICA: independent cyan/magenta neon mini-window.
    local clickMenu = new("Frame", gui, {
        Name = "TimkaPlayerPopup", Size = UDim2.fromOffset(312, 372),
        Position = UDim2.new(0.5, -156, 0.5, -186),
        BackgroundColor3 = Color3.fromRGB(3, 7, 31),
        BackgroundTransparency = 0.01, BorderSizePixel = 0,
        Visible = false, Active = true, ZIndex = 40
    })
    corner(clickMenu, 20)
    stroke(clickMenu, Color3.fromRGB(0, 230, 255), 0.01, 3)
    do
        local glow = new("Frame", clickMenu, {
            Name = "PopupSoftNeonGlow", BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-2, -2),
            Size = UDim2.new(1, 4, 1, 4), ZIndex = 40
        })
        corner(glow, 21)
        stroke(glow, Color3.fromRGB(232, 28, 255), 0.73, 8)
    end
    local popupBackdrop = new("Frame", clickMenu, {
        Name = "SketchPopupBackdrop", Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(1, -6, 1, -6), BackgroundColor3 = C.base,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 40
    })
    corner(popupBackdrop, 18)
    gradient(popupBackdrop, Color3.fromRGB(2, 11, 39),
        Color3.fromRGB(24, 3, 49), 28)
    for i = 1, 7 do
        new("Frame", popupBackdrop, {
            Position = UDim2.new(i/7, 0, .55, 0),
            AnchorPoint = Vector2.new(.5, .5),
            Size = UDim2.new(0, i%2==0 and 2 or 1, 1.7, 0),
            Rotation = 39, BackgroundColor3 = i%2==0 and cyan or violet,
            BackgroundTransparency = 0.91,
            BorderSizePixel = 0, ZIndex = 40
        })
    end
    local popupHead = new("Frame", clickMenu, {
        Name = "PopupCrownHeader", Size = UDim2.new(1, -6, 0, 47),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.fromRGB(5, 9, 38),
        BorderSizePixel = 0, ZIndex = 41
    })
    corner(popupHead, 17)
    gradient(popupHead, Color3.fromRGB(4, 14, 47),
        Color3.fromRGB(34, 4, 58), 6)
    local popupBar = new("Frame", popupHead, {
        Position = UDim2.new(0, 7, 1, -2),
        Size = UDim2.new(1, -14, 0, 2),
        BackgroundColor3 = cyan, BorderSizePixel = 0, ZIndex = 42
    })
    gradient(popupBar, cyan, Color3.fromRGB(251, 43, 255), 0)
    local popupScale = new("UIScale", clickMenu, {Scale = 0.88})
    local popupCrown = new("TextLabel", popupHead, {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.fromOffset(37, 44), BackgroundTransparency = 1,
        Text = "♛", Font = Enum.Font.GothamBold,
        TextColor3 = cyan, TextSize = 31,
        TextStrokeColor3 = violet, TextStrokeTransparency = .12, ZIndex = 43
    })
    local popupTitle = new("TextLabel", popupHead, {
        Position = UDim2.fromOffset(47, 0),
        Size = UDim2.new(1, -100, 1, -1),
        BackgroundTransparency = 1, Text = "МИНИ-МЕНЮ",
        TextColor3 = C.white, TextSize = 17,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43
    })
    local popupClose = new("TextButton", popupHead, {
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -41, 0, 6),
        BackgroundColor3 = Color3.fromRGB(49, 6, 81),
        Text = "×", TextColor3 = C.white,
        TextSize = 25, Font = Enum.Font.GothamBold, ZIndex = 44
    })
    corner(popupClose, 10)
    stroke(popupClose, Color3.fromRGB(243, 55, 255), 0.02, 2)
    local avatar = new("ImageLabel", clickMenu, {
        Name = "SelectedAvatar", Position = UDim2.fromOffset(15, 60),
        Size = UDim2.fromOffset(62, 62), BackgroundColor3 = C.panel,
        BackgroundTransparency = 0, Image = "", ZIndex = 43
    })
    corner(avatar, 10)
    stroke(avatar, cyan, 0.01, 2.1)
    local popupSub = new("TextLabel", clickMenu, {
        Position = UDim2.fromOffset(90, 63),
        Size = UDim2.new(1, -102, 0, 30),
        BackgroundTransparency = 1, Text = "@username",
        TextColor3 = C.white, TextSize = 16,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43
    })
    local popupDetail = new("TextLabel", clickMenu, {
        Position = UDim2.fromOffset(90, 91),
        Size = UDim2.new(1, -102, 0, 25),
        BackgroundTransparency = 1, Text = "● Онлайн",
        TextColor3 = Color3.fromRGB(52, 255, 128),
        TextSize = 12, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43
    })
    local function popupButton(caption, x, y, outlineColor)
        local object = new("TextButton", clickMenu, {
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(136, 52),
            BackgroundColor3 = Color3.fromRGB(7, 15, 48),
            BackgroundTransparency = 0.01,
            Text = caption, TextColor3 = C.white,
            TextSize = 14, TextWrapped = true,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false, ZIndex = 43
        })
        corner(object, 11)
        stroke(object, outlineColor, 0.015, 2.1)
        local outer = new("Frame", object, {
            Name = "ButtonGlow", BackgroundTransparency = 1,
            Size = UDim2.new(1, 4, 1, 4),
            Position = UDim2.fromOffset(-2, -2), ZIndex = 42
        })
        corner(outer, 12)
        stroke(outer, outlineColor, 0.85, 5)
        return object
    end
    local flingClickBtn = popupButton("ϟ  ФЛИНГ", 13, 135,
        Color3.fromRGB(241, 44, 252))
    local spClickBtn = popupButton("♛  ПРИОРИТЕТ", 163, 135, cyan)
    local whiteClickBtn = popupButton("⬡  БЕЛЫЙ СПИСОК", 13, 196, cyan)
    local tpClickBtn = popupButton("➤  ТЕЛЕПОРТ", 163, 196,
        Color3.fromRGB(177, 88, 255))
    local colorClickBtn = popupButton("◉  ЦВЕТ ESP", 13, 257,
        Color3.fromRGB(242, 59, 255))
    local moreClickBtn = popupButton("•••  ЕЩЁ", 163, 257, cyan)
    local popupActionStatus = new("TextLabel", clickMenu, {
        Position = UDim2.fromOffset(14, 317),
        Size = UDim2.new(1, -28, 0, 18),
        BackgroundTransparency = 1, Text = "Готов к действию",
        TextColor3 = Color3.fromRGB(113, 241, 255),
        Font = Enum.Font.Gotham, TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43
    })
    local stopClickBtn = new("TextButton", clickMenu, {
        Position = UDim2.fromOffset(13, 340),
        Size = UDim2.new(1, -26, 0, 22),
        BackgroundColor3 = Color3.fromRGB(40, 9, 67),
        Text = "■  Остановить Fling",
        TextColor3 = Color3.fromRGB(238, 221, 255),
        Font = Enum.Font.GothamBold, TextSize = 11,
        BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 43
    })
    corner(stopClickBtn, 8)
    stroke(stopClickBtn, Color3.fromRGB(240, 69, 255), 0.19, 1.4)

    local function closePlayerPopup()
        currentClickedPlayer = nil
        popupGeneration = popupGeneration + 1
        local thisGeneration = popupGeneration
        if not clickMenu.Visible then return end
        tween(popupScale, 0.22, {Scale = 0.86},
            Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        tween(clickMenu, 0.22, {BackgroundTransparency = 0.35},
            Enum.EasingStyle.Sine)
        task.delay(0.24, function()
            if active and popupGeneration == thisGeneration then
                clickMenu.Visible = false
            end
        end)
    end
    local function refreshPopupButtons()
        local other = currentClickedPlayer
        if not other then return end
        local id = other.UserId
        local isSuper = superPriorityTargets[id] == true
        local isWhite = whiteList[id] == true
        spClickBtn.Text = isSuper and "♛  ПРИОРИТЕТ ✓" or "♛  ПРИОРИТЕТ"
        whiteClickBtn.Text = isWhite and "⬡  БЕЛЫЙ СПИСОК ✓"
            or "⬡  БЕЛЫЙ СПИСОК"
        spClickBtn.BackgroundColor3 = isSuper and
            Color3.fromRGB(82, 21, 113) or C.panelLight
        whiteClickBtn.BackgroundColor3 = isWhite and
            Color3.fromRGB(15, 81, 78) or C.panelLight
    end
    local function openPlayerPopup(other)
        if not active or other == player or other.Parent ~= Players then
            return
        end
        currentClickedPlayer = other
        popupSub.Text = "@" .. other.Name
        popupDetail.Text = "● Онлайн  ·  ID " .. tostring(other.UserId)
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" ..
            tostring(other.UserId) .. "&w=150&h=150"
        popupActionStatus.Text = "Выбран игрок: " .. other.Name
        refreshPopupButtons()
        popupGeneration = popupGeneration + 1
        if not clickMenu.Visible then
            popupScale.Scale = 0.88
        end
        clickMenu.BackgroundTransparency = 0.02
        clickMenu.Visible = true
        local view = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize
            or Vector2.new(800, 360)
        local fitScale = math.clamp(math.min((view.X - 22)/312,
            (view.Y - 16)/372), 0.48, 1)
        local x = clickMenu.Position.X.Offset
        local y = clickMenu.Position.Y.Offset
        if settings.popupCenter then
            x = (view.X - 312 * fitScale) / 2
            y = (view.Y - 372 * fitScale) / 2
        end
        clickMenu.Position = UDim2.fromOffset(
            math.clamp(x, 4, math.max(4, view.X - 312*fitScale - 4)),
            math.clamp(y, 4, math.max(4, view.Y - 372*fitScale - 4)))
        tween(popupScale, 0.37, {Scale = fitScale}, Enum.EasingStyle.Back)
    end
    connect(popupClose.Activated, closePlayerPopup)
    connect(Players.PlayerRemoving, function(other)
        if currentClickedPlayer == other then closePlayerPopup() end
    end)

    -- ===== FLING ИЗ SYNT FLING PANEL =====
    -- Источник: rawscripts.net/raw/Universal-Script-Synt-Fling-Panel-46669
    -- Основа оригинала: BodyAngularVelocity + CFrame цели со смещением.
    -- Адаптация: таймер, отмена, возврат позиции и общие обработчики.
    local function stopFling()
        flingGeneration = flingGeneration + 1
        flingActive = false
        if flingSpin then
            pcall(function() flingSpin:Destroy() end)
            flingSpin = nil
        end
        if flingRoot and flingRoot.Parent then
            pcall(function()
                flingRoot.AssemblyAngularVelocity = Vector3.zero
                flingRoot.AssemblyLinearVelocity = Vector3.zero
                if flingCharacter == player.Character and flingOldPivot then
                    flingCharacter:PivotTo(flingOldPivot)
                end
            end)
        end
        flingRoot, flingCharacter, flingOldPivot = nil, nil, nil
        if priorAntiFling ~= nil then
            antiFlingEnabled, priorAntiFling = priorAntiFling, nil
        end
    end

    local function doFling(other, onFinished)
        if flingActive then
            status("Флинг уже выполняется")
            if onFinished then pcall(onFinished, false) end
            return
        end
        if not active or not other or other.Parent ~= Players then
            if onFinished then pcall(onFinished, false) end
            return
        end
        if spinEnabled then
            status("Перед флингом выключи Spin")
            if onFinished then pcall(onFinished, false) end
            return
        end
        local myChar, targetChar = player.Character, other.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if not myHum or myHum.Health <= 0 or not myRoot or myRoot.Anchored
            or not targetHum or targetHum.Health <= 0 or not targetRoot then
            status("Флинг: персонаж или цель не готовы")
            if onFinished then pcall(onFinished, false) end
            return
        end

        flingGeneration = flingGeneration + 1
        local token = flingGeneration
        flingActive = true
        priorAntiFling = antiFlingEnabled
        antiFlingEnabled = false
        flingRoot, flingCharacter = myRoot, myChar
        flingOldPivot = myChar:GetPivot()

        -- Значения перенесены из Synt.t startFling() с ограничением времени.
        local spinOK, spinError = pcall(function()
            flingSpin = Instance.new("BodyAngularVelocity")
            flingSpin.Name = "TimkaSyntFlingSpin"
            flingSpin.AngularVelocity = Vector3.new(0, 999999, 0)
            flingSpin.MaxTorque = Vector3.new(999999, 999999, 999999)
            flingSpin.P = 10000
            flingSpin.Parent = myRoot
        end)
        if not spinOK then
            stopFling()
            status("Флинг: не удалось включить вращение — " .. tostring(spinError))
            if onFinished then pcall(onFinished, false) end
            return
        end

        task.spawn(function()
            local success, message = pcall(function()
                local began = os.clock()
                local lastTeleport = -math.huge
                while active and flingActive and token == flingGeneration
                    and os.clock() - began < 1.55 do
                    if myChar ~= player.Character or not myRoot.Parent
                        or not targetRoot.Parent or targetHum.Health <= 0 then
                        break
                    end
                    -- Приближаем корень к цели по локальным координатам.
                    -- Серверная физика/защита игры всё равно могут отменить Fling.
                    if os.clock() - lastTeleport >= 0.075 then
                        local phase = math.floor((os.clock()-began)/0.075) % 4
                        local x = phase < 2 and 0.32 or -0.32
                        local z = phase % 2 == 0 and 0.36 or -0.36
                        myRoot.CFrame = targetRoot.CFrame *
                            CFrame.new(x, 0, z)
                        myRoot.AssemblyAngularVelocity =
                            Vector3.new(0, 180, 0)
                        lastTeleport = os.clock()
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
            local completedNormally = token == flingGeneration
            if completedNormally then stopFling() end
            if onFinished then pcall(onFinished, completedNormally and success) end
            if active and completedNormally then
                status(success and "Synt Fling завершён (зависит от игры)"
                    or ("Ошибка Synt Fling: " .. tostring(message)))
            end
        end)
    end
    connect(flingClickBtn.Activated, function()
        local other = currentClickedPlayer
        if not other or other.Parent ~= Players then
            popupActionStatus.Text = "⚠ Сначала выбери игрока"
            return
        end
        if flingActive then
            popupActionStatus.Text = "Флинг уже выполняется — нажми Стоп"
            return
        end
        if spinEnabled then
            popupActionStatus.Text = "⚠ Выключи Spin перед флингом"
            return
        end
        popupActionStatus.Text = "⚡ Fling: " .. other.Name .. " (запуск...)"
        doFling(other, function(success)
            if active and clickMenu.Visible and currentClickedPlayer == other then
                popupActionStatus.Text = success
                    and "✓ Попытка завершена (зависит от сервера)"
                    or "⚠ Не удалось завершить Fling"
            end
        end)
    end)
    connect(stopClickBtn.Activated, function()
        stopFling()
        popupActionStatus.Text = "■ Fling остановлен"
    end)
    connect(spClickBtn.Activated, function()
        local other = currentClickedPlayer
        if not other or other.Parent ~= Players then return end
        local id = other.UserId
        superPriorityTargets[id] = not superPriorityTargets[id] or nil
        invalidateTarget()
        refreshPopupButtons()
    end)
    connect(whiteClickBtn.Activated, function()
        local other = currentClickedPlayer
        if not other or other.Parent ~= Players then return end
        local id = other.UserId
        whiteList[id] = not whiteList[id] or nil
        invalidateTarget()
        refreshPopupButtons()
    end)
    connect(colorClickBtn.Activated, function()
        closePlayerPopup()
        if extrasAPI.showMenu then extrasAPI.showMenu("esp") end
    end)
    connect(moreClickBtn.Activated, function()
        closePlayerPopup()
        if extrasAPI.showMenu then extrasAPI.showMenu("playerpopup") end
    end)
    connect(tpClickBtn.Activated, function()
        local other = currentClickedPlayer
        closePlayerPopup()
        if other then teleportToPlayer(other) end
    end)

    -- Мини-меню открываем по короткому тапу, а не по свайпу камеры.
    local tapBegins = {}
    local function getTappedPlayer(position)
        if settings.popupEnabled == false then return nil end
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        local best, bestDistance = nil, math.clamp(tonumber(settings.popupRadius) or clickRadius, 12, 90)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.IgnoreWater = true
        rayParams.FilterDescendantsInstances = player.Character and {player.Character} or {}
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player and other.Character then
                for _, partName in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso"}) do
                    local part = other.Character:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        local point, onScreen = cam:WorldToScreenPoint(
                            part.Position)
                        if onScreen then
                            local distance = (
                                Vector2.new(point.X, point.Y)
                                - Vector2.new(position.X, position.Y)
                            ).Magnitude
                            if distance < bestDistance then
                                local visible = true
                                if not settings.popupBehindWalls then
                                    local direction = part.Position - cam.CFrame.Position
                                    local hit = Workspace:Raycast(cam.CFrame.Position, direction, rayParams)
                                    visible = not hit or hit.Instance:IsDescendantOf(other.Character)
                                end
                                if visible then best, bestDistance = other, distance end
                            end
                        end
                    end
                end
            end
        end
        return best
    end
    connect(UIS.InputBegan, function(input, processed)
        if not active or menu.Visible or clickMenu.Visible or settings.popupEnabled == false then return end
        if processed and UIS:GetFocusedTextBox() then return end
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            tapBegins[input] = {pos = input.Position, time = os.clock()}
        end
    end)
    connect(UIS.InputEnded, function(input)
        local started = tapBegins[input]
        tapBegins[input] = nil
        if not started or not active or menu.Visible
            or settings.popupEnabled == false then return end
        if (input.Position - started.pos).Magnitude > 16 then return end
        local held = os.clock() - started.time
        if held < math.clamp(tonumber(settings.popupHold) or 0, 0, 1.5) then return end
        local target = getTappedPlayer(input.Position)
        if target then
            if not settings.popupCenter then
                local cam = Workspace.CurrentCamera
                local view = cam and cam.ViewportSize or Vector2.new(800, 360)
                local factor = math.clamp(math.min((view.X - 22)/312,
                    (view.Y - 16)/372), 0.48, 1)
                local x = math.clamp(input.Position.X - 156*factor, 4,
                    math.max(4, view.X - 312*factor - 4))
                local y = math.clamp(input.Position.Y - 186*factor, 4,
                    math.max(4, view.Y - 372*factor - 4))
                clickMenu.Position = UDim2.fromOffset(x, y)
            end
            openPlayerPopup(target)
        end
    end)
    connect(UIS.WindowFocusReleased, function()
        table.clear(tapBegins)
    end)
    extrasAPI.closePopup = closePlayerPopup
    registerCleanup(function()
        stopFling()
        table.clear(tapBegins)
        popupGeneration = popupGeneration + 1
    end)
    -- ===== FLING TP (ALL PLAYERS): ПО ОДНОЙ ЦЕЛИ =====
    -- Независимая очередь. Остановить можно одной кнопкой.
    local flingAllRunning = false
    local flingAllTicket = 0
    local function stopFlingAll()
        flingAllTicket = flingAllTicket + 1
        flingAllRunning = false
        stopFling()
    end
    local function startFlingAll()
        if flingAllRunning or flingActive then
            status("Fling TP: дождись завершения предыдущего действия")
            return
        end
        if spinEnabled then
            status("Fling TP: сначала выключи Spin")
            return
        end
        local targets = {}
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player
                and (not settings.flingAllSkipFriends
                    or friendCache[other] ~= true)
                and (not settings.flingAllSkipWhitelist
                    or not whiteList[other.UserId]) then
                table.insert(targets, other)
            end
        end
        if #targets == 0 then
            status("Fling TP: нет подходящих игроков")
            return
        end
        flingAllRunning = true
        flingAllTicket = flingAllTicket + 1
        local ticket = flingAllTicket
        status("Fling TP: очередь из " .. #targets .. " игроков")
        task.spawn(function()
            for index, other in ipairs(targets) do
                if not active or not flingAllRunning
                    or ticket ~= flingAllTicket then break end
                if other.Parent == Players then
                    local finished = false
                    status("Fling TP: " .. index .. "/" .. #targets
                        .. " — " .. other.Name)
                    doFling(other, function()
                        finished = true
                    end)
                    local deadline = os.clock() + 2.2
                    while active and flingAllRunning
                        and ticket == flingAllTicket
                        and not finished and os.clock() < deadline do
                        task.wait(0.05)
                    end
                    if not finished and flingActive then stopFling() end
                    task.wait(0.12)
                end
            end
            if active and ticket == flingAllTicket then
                flingAllRunning = false
                status("Fling TP: очередь завершена (результат зависит от игры)")
            end
        end)
    end
    -- ===== FLING ВЫБРАННОГО ИГРОКА: ВСТРОЕН В НАШЕ МЕНЮ =====
    -- Принцип поиска по части ника из Synt findTarget().
    do
        local selectedPlayer = nil
        local flingSelectCard, selectInside = uiCard(
            "protection", "⚡  SYNT FLING / ВЫБОР ИГРОКА", 343)
        local searchBox = new("TextBox", selectInside, {
            Name = "TimkaFlingPlayerSearch",
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = C.panelLight,
            BorderSizePixel = 0, Text = "",
            PlaceholderText = "Имя или часть ника игрока...",
            PlaceholderColor3 = C.muted,
            ClearTextOnFocus = false,
            TextColor3 = C.white, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham
        })
        corner(searchBox, 9)
        stroke(searchBox, violet, 0.48)
        local selectedStatus = uiStatus(
            selectInside, "Выбери игрока из списка ниже", 37)

        local listSurface = new("CanvasGroup", selectInside, {
            Name = "TimkaFlingPlayerList",
            Position = UDim2.fromOffset(0, 74),
            Size = UDim2.new(1, 0, 0, 127),
            BackgroundColor3 = C.base,
            BackgroundTransparency = 0.48,
            GroupTransparency = 0,
            BorderSizePixel = 0, ClipsDescendants = true
        })
        corner(listSurface, 9)
        local results = new("ScrollingFrame", listSurface, {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = cyan,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y
        })
        new("UIListLayout", results, {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        new("UIPadding", results, {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 9)
        })
        local renderedButtons = {}
        local function updateResults()
            if not active then return end
            for _, button in ipairs(renderedButtons) do
                if button.Parent then button:Destroy() end
            end
            table.clear(renderedButtons)
            local needle = string.lower(searchBox.Text)
            local candidates = {}
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player and (
                    needle == ""
                    or string.find(string.lower(other.Name), needle, 1, true)
                    or string.find(string.lower(other.DisplayName), needle, 1, true)
                ) then
                    table.insert(candidates, other)
                end
            end
            table.sort(candidates, function(a,b) return a.Name < b.Name end)
            for index, other in ipairs(candidates) do
                local button = new("TextButton", results, {
                    Name = "Target_" .. other.UserId,
                    Size = UDim2.new(1, 0, 0, 29),
                    LayoutOrder = index,
                    BackgroundColor3 = selectedPlayer == other
                        and Color3.fromRGB(24, 101, 119) or C.panelLight,
                    Text = other.DisplayName .. " (@" .. other.Name .. ")",
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = C.white,
                    TextSize = 12, Font = Enum.Font.Gotham,
                    BorderSizePixel = 0, AutoButtonColor = false
                })
                corner(button, 7)
                -- Destroy() автоматически отключает событие от старой кнопки.
                button.Activated:Connect(function()
                    if not active or other.Parent ~= Players then return end
                    selectedPlayer = other
                    selectedStatus.Text = "Выбран: " .. other.Name
                    for _, listed in ipairs(renderedButtons) do
                        if listed.Parent then
                            tween(listed, 0.19, {
                                BackgroundColor3 = listed == button
                                    and Color3.fromRGB(24, 101, 119)
                                    or C.panelLight
                            }, Enum.EasingStyle.Sine)
                        end
                    end
                end)
                table.insert(renderedButtons, button)
            end
            -- Переполнение списка не создаёт второго всплывающего окна.
            tween(listSurface, 0.19, {GroupTransparency = 0}, Enum.EasingStyle.Sine)
        end
        connect(searchBox:GetPropertyChangedSignal("Text"), function()
            if not active then return end
            listSurface.GroupTransparency = 0.17
            updateResults()
        end)
        connect(Players.PlayerAdded, updateResults)
        connect(Players.PlayerRemoving, function(other)
            if selectedPlayer == other then
                selectedPlayer = nil
                selectedStatus.Text = "Игрок вышел — выбери другого"
            end
            task.defer(updateResults)
        end)
        local selectFlingButton = uiButton(
            selectInside, "⚡ Флинг выбранного игрока", 214, function()
                local other = selectedPlayer
                if (not other or other.Parent ~= Players)
                    and searchBox.Text ~= "" then
                    local term = string.lower(searchBox.Text)
                    for _, candidate in ipairs(Players:GetPlayers()) do
                        if candidate ~= player and
                            string.sub(string.lower(candidate.Name), 1, #term) == term then
                            other = candidate
                            break
                        end
                    end
                end
                if not other or other.Parent ~= Players then
                    selectedStatus.Text = "Сначала выбери игрока!"
                    return
                end
                selectedPlayer = other
                selectedStatus.Text = "Fling: " .. other.Name
                doFling(other)
            end, cyan)
        selectFlingButton.Size = UDim2.new(0.70, -3, 0, 35)
        local selectStopButton = uiButton(
            selectInside, "■ СТОП", 214, function()
                stopFling()
                selectedStatus.Text = "Fling остановлен"
            end, C.red)
        selectStopButton.Position = UDim2.new(0.71, 0, 0, 214)
        selectStopButton.Size = UDim2.new(0.29, 0, 0, 35)
        uiLabel(selectInside,
            "Никаких отдельных окон: список и кнопка внутри вкладки «Защита».",
            259, 28)
        updateResults()
    end

    local allCard, allInside = uiCard(
        "protection", "⚡  FLING TP / ВСЕ ИГРОКИ", 215)
    uiLabel(allInside,
        "Обходит цели по очереди. Способ срабатывает не во всех играх.",
        0, 35)
    uiToggle(allInside, "Пропускать друзей", 42,
        settings.flingAllSkipFriends ~= false, function(value)
            settings.flingAllSkipFriends = value
            saveSettings()
        end)
    uiToggle(allInside, "Пропускать белый список", 78,
        settings.flingAllSkipWhitelist ~= false, function(value)
            settings.flingAllSkipWhitelist = value
            saveSettings()
        end)
    local flingAllButton = uiButton(
        allInside, "⚡ FLING TP (ALL PLAYERS)", 118, startFlingAll, cyan)
    flingAllButton.Size = UDim2.new(0.6, -4, 0, 34)
    local stopAllButton = uiButton(
        allInside, "СТОП", 118, stopFlingAll, C.red)
    stopAllButton.Position = UDim2.new(0.61, 0, 0, 118)
    stopAllButton.Size = UDim2.new(0.39, 0, 0, 34)
    registerCleanup(stopFlingAll)

    end


    -- ===== ЧАСТЬ 11: ВИЗУАЛЫ+ / ОСВЕЩЕНИЕ =====
    -- Только локальная графика. Не меняем чужие игровые объекты.
    -- Остальные эффекты добавим отдельными частями.

    -- Сохраняем исходные свойства до применения пресетов.
    local originalVisualLight = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        ExposureCompensation = Lighting.ExposureCompensation,
        GlobalShadows = Lighting.GlobalShadows
    }
    local visualColorEffect = new("ColorCorrectionEffect", Lighting, {
        Name = "TimkaVisualsColor", Enabled = false,
        Brightness = 0, Contrast = 0, Saturation = 0,
        TintColor = Color3.new(1, 1, 1)
    })
    local visualBloomEffect = new("BloomEffect", Lighting, {
        Name = "TimkaVisualsBloom", Enabled = false,
        Intensity = 0.35, Size = 24, Threshold = 1.05
    })
    local knownLightModes = {
        default = true, fullbright = true, warm = true,
        day = true, cave = true
    }
    local lightNames = {
        default = "Графика игры", fullbright = "FullBright",
        warm = "Тёплый свет", day = "Яркий день",
        cave = "Светлые пещеры"
    }

    local function restoreVisualLighting()
        for property, original in pairs(originalVisualLight) do
            pcall(function() Lighting[property] = original end)
        end
        if visualColorEffect.Parent then
            visualColorEffect.Enabled = false
        end
        if visualBloomEffect.Parent then
            visualBloomEffect.Enabled = false
        end
    end

    local function applyVisualLighting()
        if not active then return end
        restoreVisualLighting()
        local mode = visuals.light
        if not knownLightModes[mode] then
            mode = "default"
            visuals.light = mode
        end
        local brightness = math.clamp(
            tonumber(visuals.brightness) or 2, 0, 5
        )
        local contrast = math.clamp(
            tonumber(visuals.contrast) or 0, -1, 1
        )
        local saturation = math.clamp(
            tonumber(visuals.saturation) or 0, -1, 1
        )

        if mode == "fullbright" then
            Lighting.ClockTime = 14
            Lighting.Brightness = brightness
            Lighting.Ambient = Color3.fromRGB(225, 225, 225)
            Lighting.OutdoorAmbient = Color3.fromRGB(225, 225, 225)
            Lighting.GlobalShadows = false
        elseif mode == "warm" then
            Lighting.ClockTime = 17.5
            Lighting.Brightness = brightness
            Lighting.Ambient = Color3.fromRGB(185, 145, 115)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 205, 165)
        elseif mode == "day" then
            Lighting.ClockTime = 13
            Lighting.Brightness = brightness
            Lighting.Ambient = Color3.fromRGB(145, 155, 175)
            Lighting.OutdoorAmbient = Color3.fromRGB(210, 220, 240)
        elseif mode == "cave" then
            Lighting.Brightness = brightness
            Lighting.Ambient = Color3.fromRGB(215, 215, 225)
            Lighting.OutdoorAmbient = Color3.fromRGB(215, 215, 225)
            Lighting.GlobalShadows = false
        end

        if visuals.nightVision then
            Lighting.Ambient = Color3.fromRGB(200, 220, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 220, 200)
            Lighting.GlobalShadows = false
            Lighting.ExposureCompensation = 1.1
        end
        -- Режим FPS в следующих частях будет вызывать эту функцию,
        -- чтобы не конфликтовать с FullBright и ночным зрением.
        if visuals.fps == "max" then
            Lighting.GlobalShadows = false
        end
        local cinematic = visuals.cinematic == true
        local night = visuals.nightVision == true
        visualColorEffect.Brightness = night and 0.08 or 0
        visualColorEffect.Contrast = math.clamp(
            contrast + (cinematic and 0.12 or 0), -1, 1
        )
        visualColorEffect.Saturation = math.clamp(
            saturation + (cinematic and 0.18 or 0), -1, 1
        )
        visualColorEffect.TintColor = night
            and Color3.fromRGB(175, 255, 190)
            or (cinematic and Color3.fromRGB(255, 238, 225)
            or Color3.new(1, 1, 1))
        visualColorEffect.Enabled = night or cinematic
            or math.abs(contrast) > 0.001
            or math.abs(saturation) > 0.001
        visualBloomEffect.Enabled = cinematic
    end

    registerCleanup(function()
        restoreVisualLighting()
        if visualColorEffect.Parent then visualColorEffect:Destroy() end
        if visualBloomEffect.Parent then visualBloomEffect:Destroy() end
    end)

    -- ===== КАРТОЧКА 1: ПРЕСЕТЫ ОСВЕЩЕНИЯ =====
    local lightCard, lightInside = uiCard(
        "visuals", "☀  ВИЗУАЛЫ+  /  ОСВЕЩЕНИЕ", 300
    )
    local lightStatus = uiStatus(lightInside, "Режим: графика игры", 0)
    local function updateLightStatus()
        lightStatus.Text = "Режим: "
            .. (lightNames[visuals.light] or "Графика игры")
    end
    local function selectLightMode(mode)
        visuals.light = mode
        applyVisualLighting()
        updateLightStatus()
        saveSettings()
    end
    local function lightChoice(labelText, mode, y, right)
        local b = uiButton(lightInside, labelText, y,
            function() selectLightMode(mode) end,
            mode == "default" and violet or cyan)
        b.Size = UDim2.new(0.49, 0, 0, 34)
        if right then
            b.Position = UDim2.new(0.51, 0, 0, y)
        end
        return b
    end
    lightChoice("Оригинал", "default", 32, false)
    lightChoice("FullBright", "fullbright", 32, true)
    lightChoice("Тёплый свет", "warm", 74, false)
    lightChoice("Яркий день", "day", 74, true)
    lightChoice("Светлые пещеры", "cave", 116, false)
    uiStepper(lightInside, "Яркость", 164,
        math.clamp(visuals.brightness, 0, 5),
        0, 5, 0.5, 1, function(value)
            visuals.brightness = value
            applyVisualLighting()
            saveSettings()
        end)
    uiLabel(lightInside,
        "Освещение изменяется только у тебя. Игры могут его сбрасывать.",
        211, 35)

    -- ===== КАРТОЧКА 2: КИНО И НОЧНОЕ ЗРЕНИЕ =====
    local postCard, postInside = uiCard(
        "visuals", "✦  ЦВЕТ И ПОСТОБРАБОТКА", 270
    )
    uiToggle(postInside, "Кинематографический режим", 0,
        visuals.cinematic, function(value)
            visuals.cinematic = value
            applyVisualLighting()
            saveSettings()
        end)
    uiToggle(postInside, "Ночное зрение", 38,
        visuals.nightVision, function(value)
            visuals.nightVision = value
            applyVisualLighting()
            saveSettings()
        end)
    uiStepper(postInside, "Контраст", 79,
        math.clamp(visuals.contrast, -1, 1),
        -1, 1, 0.1, 1, function(value)
            visuals.contrast = value
            applyVisualLighting()
            saveSettings()
        end)
    uiStepper(postInside, "Насыщенность", 121,
        math.clamp(visuals.saturation, -1, 1),
        -1, 1, 0.1, 1, function(value)
            visuals.saturation = value
            applyVisualLighting()
            saveSettings()
        end)
    uiButton(postInside, "Повторно применить графику", 167,
        function()
            applyVisualLighting()
            status("ВИЗУАЛЫ+: освещение обновлено")
        end, cyan)
    uiLabel(postInside,
        "Эти эффекты отключаются вместе со скриптом.", 210, 20)

    -- Сохранённые параметры применяем один раз при запуске.
    updateLightStatus()
    applyVisualLighting()


    -- ===== ЧАСТЬ 12: ВИЗУАЛЫ+ / ПОГОДА =====
    -- Локальные частицы возле камеры, без изменения карты.
    local weatherModes = {
        off = "Выключено", rain = "Дождь", heavy = "Ливень",
        snow = "Снег", storm = "Гроза", fog = "Туман"
    }
    local weatherRandom = Random.new()
    local weatherFogOriginal = {
        Start = Lighting.FogStart,
        End = Lighting.FogEnd,
        Color = Lighting.FogColor
    }
    local weatherAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    local weatherAtmosphereOriginal = weatherAtmosphere and {
        Density = weatherAtmosphere.Density,
        Haze = weatherAtmosphere.Haze,
        Color = weatherAtmosphere.Color
    } or nil
    local weatherFogChanged = false
    local weatherHost = new("Part", Workspace, {
        Name = "TimkaLocalWeather", Size = Vector3.new(44, 1, 44),
        CFrame = CFrame.new(0, -10000, 0),
        Anchored = true, Transparency = 1, CastShadow = false,
        CanCollide = false, CanQuery = false, CanTouch = false
    })
    local weatherEmitter = new("ParticleEmitter", weatherHost, {
        Name = "TimkaWeatherParticles", Enabled = false, Rate = 0,
        Shape = Enum.ParticleEmitterShape.Box,
        ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
        EmissionDirection = Enum.NormalId.Bottom,
        Orientation = Enum.ParticleOrientation.VelocityParallel,
        LockedToPart = false, LightInfluence = 0,
        Speed = NumberRange.new(35, 50),
        Lifetime = NumberRange.new(1.1, 1.7),
        Size = NumberSequence.new(0.15),
        Transparency = NumberSequence.new(0.2)
    })
    local weatherFlash = new("ColorCorrectionEffect", Lighting, {
        Name = "TimkaLightning", Enabled = false,
        Brightness = 0.3, Contrast = 0.1,
        TintColor = Color3.fromRGB(215, 228, 255)
    })
    local stormTimer = 0
    local stormDelay = weatherRandom:NextNumber(7, 13)
    local flashRemaining = 0

    local function restoreWeatherFog()
        if not weatherFogChanged then return end
        weatherFogChanged = false
        pcall(function()
            Lighting.FogStart = weatherFogOriginal.Start
            Lighting.FogEnd = weatherFogOriginal.End
            Lighting.FogColor = weatherFogOriginal.Color
        end)
        if weatherAtmosphere and weatherAtmosphere.Parent
            and weatherAtmosphereOriginal then
            pcall(function()
                weatherAtmosphere.Density = weatherAtmosphereOriginal.Density
                weatherAtmosphere.Haze = weatherAtmosphereOriginal.Haze
                weatherAtmosphere.Color = weatherAtmosphereOriginal.Color
            end)
        end
    end

    local function applyWeatherFog(mode, intensity)
        restoreWeatherFog()
        if mode ~= "fog" and mode ~= "storm" then return end
        weatherFogChanged = true
        local thick = mode == "fog"
        Lighting.FogStart = thick and 8 or 35
        Lighting.FogEnd = thick and (125 - intensity * 80)
            or (280 - intensity * 100)
        Lighting.FogColor = thick
            and Color3.fromRGB(175, 185, 205)
            or Color3.fromRGB(105, 120, 155)
        if weatherAtmosphere and weatherAtmosphere.Parent then
            weatherAtmosphere.Density = thick
                and (0.3 + 0.2 * intensity) or (0.2 + 0.1 * intensity)
            weatherAtmosphere.Haze = thick
                and (1.5 + intensity * 1.5) or (1 + intensity)
        end
    end

    local function applyWeather()
        if not active then return end
        local mode = visuals.weather
        if not weatherModes[mode] then
            mode = "off"
            visuals.weather = "off"
        end
        local intensity = math.clamp(
            tonumber(visuals.weatherPower) or 0.5, 0.1, 1
        )
        local rgb = visuals.weatherColor
        if type(rgb) ~= "table" then rgb = {180, 220, 255} end
        local color = Color3.fromRGB(
            math.clamp(tonumber(rgb[1]) or 180, 0, 255),
            math.clamp(tonumber(rgb[2]) or 220, 0, 255),
            math.clamp(tonumber(rgb[3]) or 255, 0, 255)
        )
        weatherEmitter.Enabled = false
        weatherEmitter:Clear()
        weatherFlash.Enabled = false
        flashRemaining, stormTimer = 0, 0
        stormDelay = weatherRandom:NextNumber(7, 13)
        applyWeatherFog(mode, intensity)
        if mode == "off" or mode == "fog" then return end

        local snow = mode == "snow"
        weatherEmitter.Color = ColorSequence.new(
            snow and Color3.fromRGB(245, 250, 255) or color
        )
        weatherEmitter.Rate = snow and (12 + intensity * 25)
            or (mode == "rain" and (25 + intensity * 35)
            or (45 + intensity * 50))
        weatherEmitter.Size = NumberSequence.new(
            snow and 0.38 or 0.12
        )
        weatherEmitter.Squash = NumberSequence.new(
            snow and 0 or 0.78
        )
        weatherEmitter.Speed = snow
            and NumberRange.new(4, 7)
            or NumberRange.new(42, 57)
        weatherEmitter.Lifetime = snow
            and NumberRange.new(3, 4.5)
            or NumberRange.new(1.1, 1.7)
        weatherEmitter.Acceleration = snow
            and Vector3.new(2, -3, 0)
            or Vector3.new(0, -24, 0)
        weatherEmitter.SpreadAngle = snow
            and Vector2.new(18, 18)
            or Vector2.new(5, 5)
        weatherEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.24),
            NumberSequenceKeypoint.new(0.7, 0.32),
            NumberSequenceKeypoint.new(1, 1)
        })
        weatherEmitter.Enabled = true
    end

    -- Следим только за камерой; физику и карту не трогаем.
    connect(RunService.RenderStepped, function()
        if not active or not weatherEmitter.Enabled then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local origin = cam.CFrame.Position
            + cam.CFrame.LookVector * 12
            + Vector3.new(0, 18, 0)
        weatherHost.CFrame = CFrame.new(origin)
    end)
    connect(RunService.Heartbeat, function(dt)
        if not active then return end
        if flashRemaining > 0 then
            flashRemaining = flashRemaining - dt
            if flashRemaining <= 0 then weatherFlash.Enabled = false end
        end
        if visuals.weather ~= "storm" then return end
        stormTimer = stormTimer + dt
        if stormTimer < stormDelay then return end
        stormTimer = 0
        stormDelay = weatherRandom:NextNumber(7, 13)
        weatherFlash.Brightness = weatherRandom:NextNumber(0.18, 0.38)
        weatherFlash.Enabled = true
        flashRemaining = 0.10
    end)

    registerCleanup(function()
        weatherEmitter.Enabled = false
        weatherEmitter:Clear()
        weatherFlash.Enabled = false
        restoreWeatherFog()
        if weatherHost.Parent then weatherHost:Destroy() end
        if weatherFlash.Parent then weatherFlash:Destroy() end
    end)

    -- ===== МЕНЮ ПОГОДЫ =====
    local weatherCard, weatherInside = uiCard(
        "visuals", "☁  ВИЗУАЛЫ+ / ПОГОДА", 329
    )
    local weatherStatus = uiStatus(weatherInside, "Погода выключена", 0)
    local function weatherChoice(name, mode, y, right)
        local buttonObject = uiButton(weatherInside, name, y,
            function()
                visuals.weather = mode
                applyWeather()
                weatherStatus.Text = "Погода: " .. weatherModes[mode]
                saveSettings()
            end, mode == "off" and violet or cyan)
        buttonObject.Size = UDim2.new(0.49, 0, 0, 34)
        if right then
            buttonObject.Position = UDim2.new(0.51, 0, 0, y)
        end
    end
    weatherChoice("Выключить", "off", 32, false)
    weatherChoice("Дождь", "rain", 32, true)
    weatherChoice("Ливень", "heavy", 74, false)
    weatherChoice("Снег", "snow", 74, true)
    weatherChoice("Гроза ⚡", "storm", 116, false)
    weatherChoice("Туман", "fog", 116, true)
    uiStepper(weatherInside, "Интенсивность", 163,
        math.clamp(tonumber(visuals.weatherPower) or 0.5, 0.1, 1),
        0.1, 1, 0.1, 1, function(value)
            visuals.weatherPower = value
            applyWeather()
            saveSettings()
        end)
    uiLabel(weatherInside,
        "Локальная погода. Молнии — только вспышки света.", 210, 26)
    uiLabel(weatherInside,
        "Цвет осадков настроим в редакторе цветов.", 247, 22)
    applyWeather()
    weatherStatus.Text = "Погода: " .. weatherModes[visuals.weather]


    -- ===== ЧАСТЬ 13: ВИЗУАЛЫ+ / НЕБО =====
do
    -- Без неизвестных asset ID: стандартные звёзды и цветокоррекция.
    local skyModes = {
        default = "Небо игры", clear = "Чистое небо",
        sunrise = "Рассвет", sunset = "Закат",
        stars = "Звёздная ночь", space = "Космос",
        anime = "Аниме", aurora = "Северное сияние",
        warmbox = "Тёплый Skybox"
    }
    local skyPresets = {
        warmbox = {
            time = 17.2, stars = 0, sun = 16, moon = 0,
            tint = Color3.fromRGB(255, 228, 199),
            brightness = 0.01, contrast = 0.10, saturation = 0.12
        },
        clear = {
            time = 12.7, stars = 0, sun = 18, moon = 0,
            tint = Color3.fromRGB(205, 230, 255),
            brightness = 0.02, contrast = 0.06, saturation = 0.12
        },
        sunrise = {
            time = 6.4, stars = 0, sun = 22, moon = 0,
            tint = Color3.fromRGB(255, 202, 174),
            brightness = 0.03, contrast = 0.08, saturation = 0.14
        },
        sunset = {
            time = 18.2, stars = 0, sun = 25, moon = 0,
            tint = Color3.fromRGB(255, 175, 150),
            brightness = -0.02, contrast = 0.15, saturation = 0.25
        },
        stars = {
            time = 0, stars = 3000, sun = 0, moon = 14,
            tint = Color3.fromRGB(172, 195, 255),
            brightness = -0.04, contrast = 0.14, saturation = 0.10
        },
        space = {
            time = 0, stars = 3000, sun = 0, moon = 0,
            tint = Color3.fromRGB(181, 151, 255),
            brightness = -0.08, contrast = 0.22, saturation = 0.22
        },
        anime = {
            time = 11.5, stars = 0, sun = 24, moon = 0,
            tint = Color3.fromRGB(255, 214, 248),
            brightness = 0.04, contrast = 0.10, saturation = 0.35
        },
        aurora = {
            time = 1, stars = 2600, sun = 0, moon = 9,
            tint = Color3.fromRGB(153, 255, 214),
            brightness = -0.05, contrast = 0.14, saturation = 0.28
        }
    }

    -- Оригинальное небо запоминаем и не удаляем.
    local gameSky = Lighting:FindFirstChildOfClass("Sky")
    local gameSkyData = nil
    if gameSky then
        gameSkyData = {
            StarCount = gameSky.StarCount,
            CelestialBodiesShown = gameSky.CelestialBodiesShown,
            SunAngularSize = gameSky.SunAngularSize,
            MoonAngularSize = gameSky.MoonAngularSize,
            SkyboxBk = gameSky.SkyboxBk, SkyboxDn = gameSky.SkyboxDn,
            SkyboxFt = gameSky.SkyboxFt, SkyboxLf = gameSky.SkyboxLf,
            SkyboxRt = gameSky.SkyboxRt, SkyboxUp = gameSky.SkyboxUp
        }
    end
    local customSky = nil
    local skyTint = new("ColorCorrectionEffect", Lighting, {
        Name = "TimkaSkyColor", Enabled = false,
        Brightness = 0, Contrast = 0, Saturation = 0,
        TintColor = Color3.new(1, 1, 1)
    })
    local function getSky()
        if gameSky and gameSky.Parent == Lighting then
            return gameSky
        end
        if customSky and customSky.Parent == Lighting then
            return customSky
        end
        customSky = new("Sky", Lighting, {
            Name = "TimkaTemporarySky"
        })
        return customSky
    end
    local function restoreSky()
        if gameSky and gameSky.Parent == Lighting and gameSkyData then
            for property, original in pairs(gameSkyData) do
                pcall(function() gameSky[property] = original end)
            end
        end
        if customSky then
            if customSky.Parent then customSky:Destroy() end
            customSky = nil
        end
        if skyTint and skyTint.Parent then
            skyTint.Enabled = false
        end
    end
    local function applySky()
        if not active then return end
        restoreSky()
        local mode = visuals.sky
        if not skyModes[mode] then
            mode = "default"
            visuals.sky = mode
        end
        local preset = skyPresets[mode]
        if not preset then return end
        local sky = getSky()
        -- StarCount работает вместе с CelestialBodiesShown.
        pcall(function()
            sky.CelestialBodiesShown = true
            sky.StarCount = preset.stars
            sky.SunAngularSize = preset.sun
            sky.MoonAngularSize = preset.moon
            if mode == "warmbox" then
                -- IDs from official Roblox skybox documentation.
                sky.SkyboxBk = "rbxassetid://162001887"
                sky.SkyboxDn = "rbxassetid://161998893"
                sky.SkyboxFt = "rbxassetid://162001897"
                sky.SkyboxLf = "rbxassetid://162001904"
                sky.SkyboxRt = "rbxassetid://162001919"
                sky.SkyboxUp = "rbxassetid://162001926"
            end
        end)
        -- Часы, звёзды и цвет дают разные атмосферы без загрузки файлов.
        Lighting.ClockTime = preset.time
        skyTint.TintColor = preset.tint
        skyTint.Brightness = preset.brightness
        skyTint.Contrast = preset.contrast
        skyTint.Saturation = preset.saturation
        skyTint.Enabled = true
    end

    -- После смены освещения из части 11 возвращаем выбранное небо.
    local applyBaseVisualLighting = applyVisualLighting
    applyVisualLighting = function()
        applyBaseVisualLighting()
        if active then applySky() end
    end
    registerCleanup(function()
        restoreSky()
        if skyTint and skyTint.Parent then skyTint:Destroy() end
    end)

    -- ===== МЕНЮ НЕБА =====
    local skyCard, skyInside = uiCard(
        "visuals", "✧  ВИЗУАЛЫ+ / НЕБО", 405
    )
    local skyStatus = uiStatus(skyInside, "Небо: игра", 0)
    local skyButtons = {}
    local function updateSkyButtons()
        for mode, object in pairs(skyButtons) do
            local chosen = visuals.sky == mode
            object.BackgroundColor3 = chosen
                and Color3.fromRGB(26, 102, 120) or C.panelLight
            object.TextColor3 = chosen and cyan or C.white
        end
        skyStatus.Text = "Небо: "
            .. (skyModes[visuals.sky] or "Небо игры")
    end
    local function setSkyMode(mode)
        visuals.sky = mode
        -- Сначала восстанавливаем базовую картинку освещения,
        -- затем поверх неё применяется выбранный пресет неба.
        applyVisualLighting()
        updateSkyButtons()
        saveSettings()
        status("ВИЗУАЛЫ+: " .. skyModes[mode])
    end
    local function skyChoice(caption, mode, y, right)
        local object = uiButton(skyInside, caption, y,
            function() setSkyMode(mode) end,
            mode == "default" and violet or cyan)
        object.Size = UDim2.new(0.49, 0, 0, 34)
        if right then
            object.Position = UDim2.new(0.51, 0, 0, y)
        end
        skyButtons[mode] = object
    end
    skyChoice("Оригинал", "default", 32, false)
    skyChoice("Чистое небо", "clear", 32, true)
    skyChoice("Рассвет", "sunrise", 74, false)
    skyChoice("Закат", "sunset", 74, true)
    skyChoice("Звёздная ночь", "stars", 116, false)
    skyChoice("Космос", "space", 116, true)
    skyChoice("Аниме", "anime", 158, false)
    skyChoice("Северное сияние", "aurora", 158, true)
    skyChoice("Тёплый Skybox HD", "warmbox", 200, false)
    uiButton(skyInside, "↺  Вернуть небо игры", 246, function()
        setSkyMode("default")
    end, violet)
    uiLabel(skyInside,
        "Тёплый Skybox — настоящий набор из 6 текстур Roblox.",
        293, 29)
    uiLabel(skyInside,
        "Остальные пресеты используют свет, время и звёзды.",
        325, 29)
    updateSkyButtons()
    applySky()
end

    -- ===== ЧАСТЬ 14: ВИЗУАЛЫ+ / СЛЕДЫ =====
    -- Локальные Trail и ParticleEmitter: без изменения карты.
    do
        local trailModes = {
            off = "Выключено", rainbow = "Радуга", fire = "Огонь",
            electric = "Электричество", neon = "Неон",
            particles = "Искры"
        }
        local trailCharacter, ribbon, sparks = nil, nil, nil
        local trailAttachments = {}
        local trailTimer, trailHue = 0, 0

        local function trailColor()
            local rgb = visuals.trailColor
            if type(rgb) ~= "table" then rgb = {45, 220, 255} end
            local function channel(index, fallback)
                return math.clamp(tonumber(rgb[index]) or fallback, 0, 255)
            end
            return Color3.fromRGB(
                channel(1, 45), channel(2, 220), channel(3, 255)
            )
        end

        local function clearTrail()
            if ribbon then
                ribbon.Enabled = false
                ribbon:Clear()
                ribbon:Destroy()
                ribbon = nil
            end
            if sparks then
                sparks.Enabled = false
                sparks:Clear()
                sparks:Destroy()
                sparks = nil
            end
            for _, attachment in ipairs(trailAttachments) do
                if attachment.Parent then attachment:Destroy() end
            end
            table.clear(trailAttachments)
            trailCharacter = nil
            trailTimer = 0
        end

        local function createTrail(character)
            clearTrail()
            if not active then return end
            local mode = visuals.trail
            if not trailModes[mode] or mode == "off" then return end
            if not character or character ~= player.Character then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local root = character:FindFirstChild("HumanoidRootPart")
            if not humanoid or humanoid.Health <= 0
                or not root or not root:IsA("BasePart") then return end

            local length = math.clamp(
                tonumber(visuals.trailLength) or 1, 0.2, 3
            )
            local brightness = math.clamp(
                tonumber(visuals.trailBrightness) or 1, 0.5, 4
            )
            local chosenColor = trailColor()
            local left = new("Attachment", root, {
                Name = "TimkaTrailLeft",
                Position = Vector3.new(-0.55, -0.4, 0.4)
            })
            local right = new("Attachment", root, {
                Name = "TimkaTrailRight",
                Position = Vector3.new(0.55, -0.4, 0.4)
            })
            table.insert(trailAttachments, left)
            table.insert(trailAttachments, right)
            trailCharacter = character

            if mode ~= "particles" then
                local initialColor = chosenColor
                if mode == "fire" then
                    initialColor = Color3.fromRGB(255, 125, 35)
                elseif mode == "electric" then
                    initialColor = Color3.fromRGB(95, 235, 255)
                end
                ribbon = new("Trail", root, {
                    Name = "TimkaVisualTrail",
                    Attachment0 = left, Attachment1 = right,
                    Enabled = true, FaceCamera = true,
                    Lifetime = length, MinLength = 0.05,
                    MaxLength = 35, Brightness = brightness,
                    LightEmission = 0.85, LightInfluence = 0,
                    Color = ColorSequence.new(initialColor),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.12),
                        NumberSequenceKeypoint.new(0.65, 0.35),
                        NumberSequenceKeypoint.new(1, 1)
                    }),
                    WidthScale = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.9),
                        NumberSequenceKeypoint.new(1, 0)
                    })
                })
                if mode == "fire" then
                    ribbon.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 85)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 90, 20)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(125, 25, 15))
                    })
                end
            end

            if mode == "fire" or mode == "electric"
                or mode == "particles" then
                local color = chosenColor
                if mode == "fire" then
                    color = Color3.fromRGB(255, 135, 40)
                elseif mode == "electric" then
                    color = Color3.fromRGB(90, 230, 255)
                end
                sparks = new("ParticleEmitter", left, {
                    Name = "TimkaTrailParticles",
                    Texture = "rbxasset://textures/particles/sparkles_main.dds",
                    Enabled = true,
                    Rate = mode == "particles" and 24 or 12,
                    Lifetime = NumberRange.new(0.3, 0.65),
                    Speed = NumberRange.new(1, 3),
                    SpreadAngle = Vector2.new(80, 80),
                    Color = ColorSequence.new(color),
                    Brightness = brightness,
                    LightEmission = 0.85, LightInfluence = 0,
                    LockedToPart = false,
                    Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.32),
                        NumberSequenceKeypoint.new(1, 0)
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.12),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                })
                if mode == "fire" then
                    sparks.Acceleration = Vector3.new(0, 8, 0)
                end
            end
        end

        local function refreshTrail()
            createTrail(player.Character)
        end
        connect(player.CharacterAdded, function(character)
            task.spawn(function()
                character:WaitForChild("HumanoidRootPart", 10)
                if active and character == player.Character then
                    createTrail(character)
                end
            end)
        end)
        connect(player.CharacterRemoving, function(character)
            if trailCharacter == character then clearTrail() end
        end)
        connect(RunService.Heartbeat, function(dt)
            if not active or not ribbon or not ribbon.Parent then return end
            local mode = visuals.trail
            if mode ~= "rainbow" and mode ~= "electric" then return end
            trailTimer = trailTimer + dt
            if trailTimer < 0.12 then return end
            trailTimer = 0
            if mode == "rainbow" then
                trailHue = (trailHue + 0.035) % 1
                ribbon.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHSV(trailHue, 1, 1)),
                    ColorSequenceKeypoint.new(0.5,
                        Color3.fromHSV((trailHue + 0.33) % 1, 1, 1)),
                    ColorSequenceKeypoint.new(1,
                        Color3.fromHSV((trailHue + 0.66) % 1, 1, 1))
                })
            elseif mode == "electric" then
                local flicker = math.random(65, 100) / 100
                ribbon.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1 - flicker),
                    NumberSequenceKeypoint.new(1, 1)
                })
            end
        end)
        registerCleanup(clearTrail)

        -- ===== КАРТОЧКА СЛЕДОВ =====
        local trailCard, trailInside = uiCard(
            "visuals", "🌈  ВИЗУАЛЫ+ / СЛЕДЫ", 327
        )
        local trailStatus = uiStatus(trailInside, "Следы выключены", 0)
        local trailButtons = {}
        local function updateTrailMenu()
            trailStatus.Text = "След: "
                .. (trailModes[visuals.trail] or "Выключено")
            for mode, object in pairs(trailButtons) do
                local selected = visuals.trail == mode
                object.BackgroundColor3 = selected
                    and Color3.fromRGB(23, 105, 117) or C.panelLight
                object.TextColor3 = selected and cyan or C.white
            end
        end
        local function trailChoice(caption, mode, y, right)
            local object = uiButton(trailInside, caption, y, function()
                visuals.trail = mode
                refreshTrail()
                updateTrailMenu()
                task.delay(0.16, function()
                    if active then updateTrailMenu() end
                end)
                saveSettings()
            end, mode == "off" and violet or cyan)
            object.Size = UDim2.new(0.49, 0, 0, 34)
            if right then
                object.Position = UDim2.new(0.51, 0, 0, y)
            end
            trailButtons[mode] = object
        end
        trailChoice("Выключить", "off", 32, false)
        trailChoice("🌈 Радуга", "rainbow", 32, true)
        trailChoice("🔥 Огонь", "fire", 74, false)
        trailChoice("⚡ Электро", "electric", 74, true)
        trailChoice("✧ Неон", "neon", 116, false)
        trailChoice("✦ Частицы", "particles", 116, true)
        uiStepper(trailInside, "Длина", 162,
            math.clamp(tonumber(visuals.trailLength) or 1, 0.2, 3),
            0.2, 3, 0.2, 1, function(value)
                visuals.trailLength = value
                refreshTrail()
                saveSettings()
            end)
        uiStepper(trailInside, "Яркость", 205,
            math.clamp(tonumber(visuals.trailBrightness) or 1, 0.5, 4),
            0.5, 4, 0.5, 1, function(value)
                visuals.trailBrightness = value
                refreshTrail()
                saveSettings()
            end)
        uiLabel(trailInside,
            "Собственный цвет неона и искр зададим в редакторе цветов.",
            254, 30)
        updateTrailMenu()
        task.defer(function()
            if active then refreshTrail() end
        end)
    end


    -- ===== ЧАСТЬ 15: ВИЗУАЛЫ+ / АУРЫ И МАГИЯ =====
    -- Отдельный модуль: не вмешивается в следы из части 14.
    -- Ссылку используем в будущих редакторе цветов и FPS Boost.
    local refreshAuraVisuals
    do
        local auraModes = {
            off = "Выключено", glow = "Неоновая аура",
            sparks = "Искры", fireflies = "Светлячки",
            steps = "Искры при ходьбе", jumps = "Эффект прыжка"
        }
        local auraObjects, auraConnections = {}, {}
        local auraCharacter = nil
        local lastStep = 0

        local function rgbFromSaved(rgb, fallback)
            if type(rgb) ~= "table" then rgb = fallback end
            local r = math.clamp(tonumber(rgb[1]) or fallback[1], 0, 255)
            local g = math.clamp(tonumber(rgb[2]) or fallback[2], 0, 255)
            local b = math.clamp(tonumber(rgb[3]) or fallback[3], 0, 255)
            return Color3.fromRGB(r, g, b)
        end

        local function own(object)
            table.insert(auraObjects, object)
            return object
        end
        local function listen(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(auraConnections, connection)
        end
        local function clearAura()
            for _, connection in ipairs(auraConnections) do
                connection:Disconnect()
            end
            table.clear(auraConnections)
            for _, object in ipairs(auraObjects) do
                if object and object.Parent then object:Destroy() end
            end
            table.clear(auraObjects)
            auraCharacter = nil
            lastStep = 0
        end

        local function makeEmitter(parent, name, color)
            return own(new("ParticleEmitter", parent, {
                Name = name,
                Texture = "rbxasset://textures/particles/sparkles_main.dds",
                Enabled = false, Rate = 0,
                Lifetime = NumberRange.new(0.55, 1.2),
                Speed = NumberRange.new(1, 3),
                SpreadAngle = Vector2.new(180, 180),
                Rotation = NumberRange.new(0, 360),
                RotSpeed = NumberRange.new(-50, 50),
                Color = ColorSequence.new(color),
                LightEmission = 0.85, LightInfluence = 0,
                Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.27),
                    NumberSequenceKeypoint.new(1, 0)
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.12),
                    NumberSequenceKeypoint.new(1, 1)
                })
            }))
        end

        local function buildAura(character)
            clearAura()
            if not active or character ~= player.Character then return end
            if not character then return end
            local root = character:FindFirstChild("HumanoidRootPart")
            local hum = character:FindFirstChildOfClass("Humanoid")
            if not root or not hum or hum.Health <= 0 then return end
            local mode = visuals.aura
            if not auraModes[mode] then
                mode = "off"
                visuals.aura = "off"
            end
            if mode == "off" and not visuals.magic then return end
            auraCharacter = character
            local auraColor = rgbFromSaved(
                visuals.auraColor, {115, 95, 255})
            local magicColor = rgbFromSaved(
                visuals.magicColor, {155, 100, 255})
            local attachment = own(new("Attachment", root, {
                Name = "TimkaAuraAttachment",
                Position = Vector3.new(0, -0.6, 0)
            }))
            local reduced = visuals.fps == "max"
            local emitter = nil

            if mode == "glow" then
                own(new("Highlight", character, {
                    Name = "TimkaAuraGlow", Adornee = character,
                    FillColor = auraColor, OutlineColor = auraColor,
                    FillTransparency = 0.78,
                    OutlineTransparency = 0.12,
                    DepthMode = Enum.HighlightDepthMode.Occluded
                }))
                own(new("PointLight", root, {
                    Name = "TimkaAuraLight", Color = auraColor,
                    Brightness = reduced and 0.5 or 1.2,
                    Range = reduced and 8 or 13,
                    Shadows = false
                }))
            elseif mode ~= "off" then
                emitter = makeEmitter(attachment, "TimkaAuraParticles", auraColor)
                if mode == "sparks" then
                    emitter.Enabled = true
                    emitter.Rate = reduced and 5 or 17
                    emitter.Speed = NumberRange.new(1.5, 4)
                elseif mode == "fireflies" then
                    emitter.Enabled = true
                    emitter.Rate = reduced and 3 or 9
                    emitter.Speed = NumberRange.new(0.2, 1.1)
                    emitter.Lifetime = NumberRange.new(2, 3.2)
                    emitter.Size = NumberSequence.new(0.18)
                    emitter.Acceleration = Vector3.new(0, 0.7, 0)
                elseif mode == "steps" then
                    emitter.Lifetime = NumberRange.new(0.3, 0.65)
                    listen(hum.Running, function(speed)
                        if not active or auraCharacter ~= character then return end
                        if speed < 3 or os.clock() - lastStep < 0.18 then return end
                        lastStep = os.clock()
                        emitter:Emit(reduced and 1 or 3)
                    end)
                elseif mode == "jumps" then
                    emitter.Lifetime = NumberRange.new(0.5, 1.2)
                    emitter.Speed = NumberRange.new(3, 7)
                    listen(hum.StateChanged, function(_, state)
                        if not active or auraCharacter ~= character then return end
                        if state == Enum.HumanoidStateType.Jumping then
                            emitter:Emit(reduced and 5 or 18)
                        end
                    end)
                end
            end

            if visuals.magic then
                local magicEmitter = makeEmitter(
                    attachment, "TimkaMagicAtmosphere", magicColor)
                magicEmitter.Enabled = true
                magicEmitter.Rate = reduced and 3 or 10
                magicEmitter.Speed = NumberRange.new(0.35, 1.5)
                magicEmitter.Lifetime = NumberRange.new(1.6, 2.6)
                magicEmitter.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.1),
                    NumberSequenceKeypoint.new(0.45, 0.4),
                    NumberSequenceKeypoint.new(1, 0)
                })
                magicEmitter.Acceleration = Vector3.new(0, 1.5, 0)
            end
        end

        refreshAuraVisuals = function()
            if active then buildAura(player.Character) end
        end
        connect(player.CharacterAdded, function(character)
            task.spawn(function()
                local root = character:WaitForChild("HumanoidRootPart", 10)
                local hum = character:WaitForChild("Humanoid", 10)
                if active and root and hum
                    and character == player.Character then
                    buildAura(character)
                end
            end)
        end)
        connect(player.CharacterRemoving, function(character)
            if auraCharacter == character then clearAura() end
        end)
        registerCleanup(clearAura)

        -- ===== КАРТОЧКА АУР И МАГИИ =====
        local auraCard, auraInside = uiCard(
            "visuals", "✦  ВИЗУАЛЫ+ / АУРЫ И МАГИЯ", 339)
        local auraStatus = uiStatus(auraInside, "Аура выключена", 0)
        local auraButtons = {}
        local function refreshAuraButtons()
            auraStatus.Text = "Аура: "
                .. (auraModes[visuals.aura] or "Выключено")
            for mode, object in pairs(auraButtons) do
                local chosen = visuals.aura == mode
                object.BackgroundColor3 = chosen
                    and Color3.fromRGB(23, 105, 117) or C.panelLight
                object.TextColor3 = chosen and cyan or C.white
            end
        end
        local function auraChoice(caption, mode, y, right)
            local object = uiButton(auraInside, caption, y, function()
                visuals.aura = mode
                refreshAuraVisuals()
                saveSettings()
                task.delay(0.2, function()
                    if active then refreshAuraButtons() end
                end)
            end, mode == "off" and violet or cyan)
            object.Size = UDim2.new(0.49, 0, 0, 34)
            if right then
                object.Position = UDim2.new(0.51, 0, 0, y)
            end
            auraButtons[mode] = object
        end
        auraChoice("Выключить", "off", 32, false)
        auraChoice("Неоновая аура", "glow", 32, true)
        auraChoice("Искры", "sparks", 74, false)
        auraChoice("Светлячки", "fireflies", 74, true)
        auraChoice("Искры при ходьбе", "steps", 116, false)
        auraChoice("Эффект прыжка", "jumps", 116, true)
        uiToggle(auraInside, "Магическая атмосфера", 169,
            visuals.magic == true, function(value)
                visuals.magic = value
                refreshAuraVisuals()
                saveSettings()
            end)
        uiLabel(auraInside,
            "Магические частицы можно включить вместе с любой аурой.",
            217, 33)
        uiLabel(auraInside,
            "Цвет ауры и магии выберем в редакторе цветов.",
            255, 28)
        refreshAuraButtons()
        task.defer(function()
            if active then refreshAuraVisuals() end
        end)
    end


    -- ===== ЧАСТЬ 16: FPS BOOST =====
    -- Локальная оптимизация графики.
    -- Все изменённые свойства запоминаются и восстанавливаются.

    local setFpsVisualMode
    do
        local fpsModes = {
            off = "Выключено",
            beauty = "Красота",
            balance = "Баланс",
            max = "Максимум FPS"
        }
        local savedParticleRates = {}
        local savedPostEffects = {}
        local fpsGeneration = 0
        local fpsButtons = {}
        local fpsStatus, fpsCounterLabel

        -- Восстановление частиц из карты.
        local function restoreParticles()
            for emitter, oldRate in pairs(savedParticleRates) do
                if emitter and emitter.Parent then
                    pcall(function() emitter.Rate = oldRate end)
                end
            end
            table.clear(savedParticleRates)
        end

        -- Восстановление графических эффектов игры.
        local function restorePostEffects()
            for effect, enabled in pairs(savedPostEffects) do
                if effect and effect.Parent then
                    pcall(function() effect.Enabled = enabled end)
                end
            end
            table.clear(savedPostEffects)
        end

        local function particleMultiplier()
            if visuals.fps == "balance" then return 0.55 end
            if visuals.fps == "max" then return 0.12 end
            return 1
        end

        local function reduceWorldEmitter(emitter)
            if not active or not emitter:IsA("ParticleEmitter") then
                return
            end
            -- Не меняем собственные частицы этого скрипта здесь.
            if string.sub(emitter.Name, 1, 5) == "Timka" then
                return
            end
            local character = player.Character
            if character and emitter:IsDescendantOf(character) then
                return
            end
            local factor = particleMultiplier()
            if factor >= 1 then return end
            if savedParticleRates[emitter] == nil then
                savedParticleRates[emitter] = emitter.Rate
            end
            local originalRate = savedParticleRates[emitter]
            local newRate = math.max(0, originalRate * factor)
            if emitter.Rate ~= newRate then
                emitter.Rate = newRate
            end
        end

        -- Тяжёлые эффекты Lighting.
        local function heavyPostEffect(object)
            return object:IsA("BloomEffect")
                or object:IsA("BlurEffect")
                or object:IsA("DepthOfFieldEffect")
                or object:IsA("SunRaysEffect")
        end

        local function applyFpsPost()
            local mode = visuals.fps

            -- Собственный Bloom из части 11.
            if visualBloomEffect and visualBloomEffect.Parent then
                visualBloomEffect.Intensity =
                    mode == "balance" and 0.15 or 0.35
                visualBloomEffect.Size =
                    mode == "balance" and 12 or 24
                if mode == "max" then
                    visualBloomEffect.Enabled = false
                end
            end

            if mode == "max" then
                Lighting.GlobalShadows = false
            end

            if mode ~= "balance" and mode ~= "max" then
                return
            end

            for _, effect in ipairs(Lighting:GetDescendants()) do
                if heavyPostEffect(effect)
                    and string.sub(effect.Name, 1, 5) ~= "Timka" then
                    local suppress = mode == "max"
                        or effect:IsA("BlurEffect")
                        or effect:IsA("DepthOfFieldEffect")

                    if suppress and effect.Enabled then
                        if savedPostEffects[effect] == nil then
                            savedPostEffects[effect] = effect.Enabled
                        end
                        effect.Enabled = false
                    end
                end
            end
        end

        -- Связываем FPS Boost с освещением из частей 11 и 13.
        local previousApplyVisualLighting = applyVisualLighting
        applyVisualLighting = function()
            previousApplyVisualLighting()
            if active then applyFpsPost() end
        end

        -- Связываем с погодой из части 12.
        local previousApplyWeather = applyWeather
        applyWeather = function()
            previousApplyWeather()
            if not active or not weatherEmitter.Parent then return end
            local factor = particleMultiplier()
            weatherEmitter.Rate = weatherEmitter.Rate * factor
        end

        -- Следы из части 14 находятся в отдельном do-блоке.
        -- Меняем их скорость генерации через собственный объект.
        local function adjustTrailParticles()
            local character = player.Character
            if not character then return end
            local emitter = character:FindFirstChild(
                "TimkaTrailParticles", true
            )
            if not emitter or not emitter:IsA("ParticleEmitter") then
                return
            end
            local normalRate = visuals.trail == "particles" and 24 or 12
            emitter.Rate = normalRate * particleMultiplier()
        end

        -- Сканирование карты делаем частями, без длинного зависания.
        local function scanWorldParticles()
            local mode = visuals.fps
            if mode ~= "balance" and mode ~= "max" then return end

            local generation = fpsGeneration
            task.spawn(function()
                local descendants = Workspace:GetDescendants()
                for index, object in ipairs(descendants) do
                    if not active or generation ~= fpsGeneration then
                        return
                    end
                    if object:IsA("ParticleEmitter") then
                        reduceWorldEmitter(object)
                    end
                    if index % 120 == 0 then
                        task.wait()
                    end
                end
            end)
        end

        connect(Workspace.DescendantAdded, function(object)
            if visuals.fps ~= "balance"
                and visuals.fps ~= "max" then return end
            if object:IsA("ParticleEmitter") then
                task.defer(function()
                    if active and object.Parent then
                        reduceWorldEmitter(object)
                    end
                end)
            end
        end)

        connect(Lighting.DescendantAdded, function(object)
            if visuals.fps ~= "max"
                and visuals.fps ~= "balance" then return end
            if heavyPostEffect(object) then
                task.defer(function()
                    if active then applyFpsPost() end
                end)
            end
        end)

        local function refreshFpsButtons()
            for mode, buttonObject in pairs(fpsButtons) do
                local selected = visuals.fps == mode
                buttonObject.BackgroundColor3 = selected
                    and Color3.fromRGB(23, 105, 117)
                    or C.panelLight
                buttonObject.TextColor3 = selected and cyan or C.white
            end
            if fpsStatus then
                fpsStatus.Text = "Режим: "
                    .. (fpsModes[visuals.fps] or "Выключено")
            end
        end

        -- Единая точка переключения всех режимов.
        setFpsVisualMode = function(mode, persist)
            if not fpsModes[mode] then mode = "off" end
            fpsGeneration = fpsGeneration + 1

            restoreParticles()
            restorePostEffects()
            visuals.fps = mode

            applyVisualLighting()
            applyWeather()

            if refreshAuraVisuals then
                refreshAuraVisuals()
            end
            adjustTrailParticles()
            scanWorldParticles()
            refreshFpsButtons()

            if persist ~= false then
                saveSettings()
                status("FPS Boost: " .. fpsModes[mode])
            end
        end

        -- ===== МЕНЮ FPS BOOST =====
        local fpsCard, fpsInside = uiCard(
            "visuals", "🚀  ВИЗУАЛЫ+ / FPS BOOST", 306
        )
        fpsStatus = uiStatus(
            fpsInside, "Режим: выключено", 0
        )

        local function fpsChoice(caption, mode, y, right)
            local object = uiButton(fpsInside, caption, y,
                function()
                    setFpsVisualMode(mode, true)
                    task.delay(0.16, function()
                        if active then refreshFpsButtons() end
                    end)
                end, mode == "max" and violet or cyan)

            object.Size = UDim2.new(0.49, 0, 0, 34)
            if right then
                object.Position = UDim2.new(0.51, 0, 0, y)
            end
            fpsButtons[mode] = object
        end

        fpsChoice("Выключено", "off", 34, false)
        fpsChoice("✨ Красота", "beauty", 34, true)
        fpsChoice("⚖ Баланс", "balance", 77, false)
        fpsChoice("🚀 Максимум FPS", "max", 77, true)

        fpsCounterLabel = uiStatus(
            fpsInside, "Текущий FPS: измерение...", 125
        )
        uiLabel(fpsInside,
            "Баланс уменьшает частицы и тяжёлые эффекты.",
            162, 23
        )
        uiLabel(fpsInside,
            "Максимум FPS дополнительно отключает тени.",
            186, 23
        )
        uiButton(fpsInside, "↺  Восстановить графику", 218,
            function()
                setFpsVisualMode("off", true)
            end, violet
        )

        -- Счётчик частоты отрисовки. Обновление раз в секунду.
        local frameCount, frameElapsed = 0, 0
        connect(RunService.RenderStepped, function(dt)
            if not active then return end
            frameCount = frameCount + 1
            frameElapsed = frameElapsed + dt
            if frameElapsed >= 1 then
                local fps = math.floor(
                    frameCount / frameElapsed + 0.5
                )
                fpsCounterLabel.Text = "Текущий FPS: " .. fps
                if extrasAPI.fpsLabel and extrasAPI.fpsLabel.Parent then
                    extrasAPI.fpsLabel.Text = tostring(fps) .. " FPS"
                end
                frameCount, frameElapsed = 0, 0
                adjustTrailParticles()
            end
        end)

        registerCleanup(function()
            fpsGeneration = fpsGeneration + 1
            restoreParticles()
            restorePostEffects()
        end)

        setFpsVisualMode(visuals.fps, false)
    end


    -- ===== ЧАСТЬ 17: ВИЗУАЛЫ+ / РЕДАКТОР ЦВЕТОВ =====
    -- RGB 0-255, палитра, предпросмотр и сохранение.
    -- Не создаём новые эффекты: используем существующие.
    local refreshColorEditor
    do
        local colorDefaults = {
            weatherColor = {180, 220, 255},
            trailColor = {45, 220, 255},
            auraColor = {115, 95, 255},
            magicColor = {155, 100, 255},
            jumpColor = {165, 105, 255},
            auraBallColor = {255, 90, 225},
            skinColor = {165, 105, 255}
        }
        local colorTargets = {
            {"weatherColor", "Дождь"},
            {"trailColor", "Следы"},
            {"auraColor", "Аура"},
            {"magicColor", "Магия"},
            {"jumpColor", "Jump Circle"},
            {"auraBallColor", "Aura Ball"},
            {"skinColor", "Скин"}
        }
        local selectedColorKey = "trailColor"
        local targetButtons = {}
        local rgbLabels = {}

        local function getRGB(key)
            local fallback = colorDefaults[key]
            local rgb = visuals[key]
            if type(rgb) ~= "table" then
                rgb = table.clone(fallback)
                visuals[key] = rgb
            end
            for index = 1, 3 do
                rgb[index] = math.clamp(
                    math.floor((tonumber(rgb[index])
                        or fallback[index]) + 0.5), 0, 255
                )
            end
            return rgb
        end

        local function currentColor()
            local rgb = getRGB(selectedColorKey)
            return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
        end

        -- Применяем новый цвет к уже включённым эффектам.
        local function applyEditedColor()
            local color = currentColor()
            if selectedColorKey == "weatherColor" then
                applyWeather()

            elseif selectedColorKey == "trailColor" then
                local character = player.Character
                if character then
                    local trail = character:FindFirstChild(
                        "TimkaVisualTrail", true
                    )
                    -- Радуга и огонь сохраняют свои специальные цвета.
                    if trail and trail:IsA("Trail")
                        and visuals.trail == "neon" then
                        trail.Color = ColorSequence.new(color)
                    end

                    local particles = character:FindFirstChild(
                        "TimkaTrailParticles", true
                    )
                    if particles and particles:IsA("ParticleEmitter")
                        and visuals.trail == "particles" then
                        particles.Color = ColorSequence.new(color)
                    end
                end

            elseif selectedColorKey == "auraColor"
                or selectedColorKey == "magicColor" then
                if refreshAuraVisuals then
                    refreshAuraVisuals()
                end
            elseif selectedColorKey == "auraBallColor" then
                if extrasAPI.refreshAuraFX then extrasAPI.refreshAuraFX() end
            elseif selectedColorKey == "skinColor" then
                if extrasAPI.applySkin then extrasAPI.applySkin() end
            elseif selectedColorKey == "jumpColor" then
                -- Jump Circle берёт цвет при следующем прыжке.
            end
        end

        local colorCard, colorInside = uiCard(
            "visuals", "🎨  ВИЗУАЛЫ+ / РЕДАКТОР ЦВЕТОВ", 430
        )
        local colorStatus = uiStatus(
            colorInside, "Выбери эффект для изменения цвета", 0
        )

        local colorPreview = new("Frame", colorInside, {
            Position = UDim2.fromOffset(0, 205),
            Size = UDim2.new(1, 0, 0, 37),
            BackgroundColor3 = cyan,
            BorderSizePixel = 0
        })
        corner(colorPreview, 9)
        stroke(colorPreview, C.white, 0.4)

        local hexLabel = new("TextLabel", colorPreview, {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "#00FFFF",
            TextColor3 = C.white,
            TextStrokeTransparency = 0.35,
            TextSize = 14,
            Font = Enum.Font.GothamBold
        })

        local function renderColorEditor()
            local rgb = getRGB(selectedColorKey)
            colorPreview.BackgroundColor3 = currentColor()
            hexLabel.Text = string.format(
                "#%02X%02X%02X", rgb[1], rgb[2], rgb[3]
            )
            for index, label in ipairs(rgbLabels) do
                local names = {"Красный", "Зелёный", "Синий"}
                label.Text = names[index] .. ": " .. rgb[index]
            end
            for key, object in pairs(targetButtons) do
                local selected = key == selectedColorKey
                object.BackgroundColor3 = selected
                    and Color3.fromRGB(24, 111, 125) or C.panelLight
                object.TextColor3 = selected and cyan or C.white
            end
            for _, target in ipairs(colorTargets) do
                if target[1] == selectedColorKey then
                    colorStatus.Text = "Редактируем: " .. target[2]
                    break
                end
            end
        end
        refreshColorEditor = renderColorEditor

        local function changeColorChannel(index, direction)
            local rgb = getRGB(selectedColorKey)
            rgb[index] = math.clamp(
                rgb[index] + direction * 5, 0, 255
            )
            renderColorEditor()
            applyEditedColor()
            saveSettings()
        end

        -- Четыре кнопки выбора редактируемого эффекта.
        for index, target in ipairs(colorTargets) do
            local key, name = target[1], target[2]
            local column = (index - 1) % 2
            local rowIndex = math.floor((index - 1) / 2)
            local y = 28 + rowIndex * 41

            local object = uiButton(colorInside, name, y,
                function()
                    selectedColorKey = key
                    renderColorEditor()
                    task.delay(0.16, function()
                        if active then renderColorEditor() end
                    end)
                end, cyan)
            object.Size = UDim2.new(0.49, 0, 0, 34)
            object.Position = UDim2.new(
                column == 0 and 0 or 0.51, 0, 0, y
            )
            targetButtons[key] = object
        end

        -- Регуляторы RGB. При смене эффекта значения обновляются.
        local channelNames = {"R", "G", "B"}
        for index = 1, 3 do
            local y = 251 + (index - 1) * 39
            local holder = uiRow(colorInside, y, 35)

            local caption = new("TextLabel", holder, {
                Size = UDim2.new(1, -125, 1, 0),
                BackgroundTransparency = 1,
                TextColor3 = C.white,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            rgbLabels[index] = caption

            for buttonIndex, direction in ipairs({-1, 1}) do
                local object = new("TextButton", holder, {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(
                        1, -((2 - buttonIndex) * 50), 0.5, 0
                    ),
                    Size = UDim2.fromOffset(42, 29),
                    BackgroundColor3 = C.panelLight,
                    Text = direction < 0 and "−" or "+",
                    TextColor3 = cyan,
                    TextSize = 19,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false
                })
                corner(object, 8)
                stroke(object, violet, 0.45)

                local channel = index
                local delta = direction
                connect(object.Activated, function()
                    changeColorChannel(channel, delta)
                end)
            end
        end

        -- ===== ГОТОВАЯ ЦВЕТОВАЯ ПАЛИТРА =====
        local paletteCard, paletteInside = uiCard(
            "visuals", "◈  БЫСТРАЯ ПАЛИТРА", 238
        )
        local colorPresets = {
            {"Циан", {63, 215, 255}},
            {"Фиолет", {149, 104, 255}},
            {"Розовый", {255, 95, 178}},
            {"Красный", {255, 65, 95}},
            {"Зелёный", {60, 245, 120}},
            {"Золотой", {255, 202, 70}}
        }

        for index, preset in ipairs(colorPresets) do
            local name, values = preset[1], preset[2]
            local col = (index - 1) % 2
            local rowIndex = math.floor((index - 1) / 2)
            local y = rowIndex * 40

            local object = uiButton(paletteInside, name, y,
                function()
                    visuals[selectedColorKey] = table.clone(values)
                    renderColorEditor()
                    applyEditedColor()
                    saveSettings()
                    status("Цвет изменён: " .. name)
                end, Color3.fromRGB(
                    values[1], values[2], values[3]
                ))
            object.Size = UDim2.new(0.49, 0, 0, 33)
            object.Position = UDim2.new(
                col == 0 and 0 or 0.51, 0, 0, y
            )
        end

        uiButton(paletteInside, "↺  Стандартный цвет", 129,
            function()
                visuals[selectedColorKey] = table.clone(
                    colorDefaults[selectedColorKey]
                )
                renderColorEditor()
                applyEditedColor()
                saveSettings()
                status("Стандартный цвет восстановлен")
            end, violet)

        uiLabel(paletteInside,
            "Изменения сохраняются в JSON автоматически.",
            172, 21)

        -- При загрузке отображаем текущий сохранённый цвет.
        renderColorEditor()
    end


    -- ===== ЧАСТЬ 18: ГОРИЗОНТАЛЬНЫЙ UI / АНИМАЦИИ / ТЕМЫ =====
    -- Не создаём второе меню: используем объекты из части 2.
    do
        local transitionId = 0
        local menuTargetOpen = false
        local dragInput, dragStart, dragOrigin = nil, nil, nil
        local dragMoved = false
        local buttonInput, buttonStart, buttonOrigin = nil, nil, nil
        local buttonMoved = false
        local suppressButtonUntil = 0
        local layoutReady = false

        -- ScreenGui может обновить размеры не сразу после запуска.
        local function screenSize()
            local size = gui.AbsoluteSize
            if size.X < 100 or size.Y < 100 then
                local cam = Workspace.CurrentCamera
                size = cam and cam.ViewportSize or Vector2.new(800, 360)
            end
            return size
        end

        local function clampWindow()
            local bounds = screenSize()
            local w = menu.Size.X.Offset
            local h = menu.Size.Y.Offset
            local halfW, halfH = w / 2, h / 2
            local x = menu.Position.X.Offset
            local y = menu.Position.Y.Offset
            x = math.clamp(x, halfW, math.max(halfW, bounds.X - halfW))
            y = math.clamp(y, halfH, math.max(halfH, bounds.Y - halfH))
            menu.Position = UDim2.fromOffset(x, y)
        end

        local function clampLaunchButton()
            local bounds = screenSize()
            local w, h = openButton.Size.X.Offset, openButton.Size.Y.Offset
            local x = math.clamp(openButton.Position.X.Offset,
                0, math.max(0, bounds.X - w))
            local y = math.clamp(openButton.Position.Y.Offset,
                0, math.max(0, bounds.Y - h))
            openButton.Position = UDim2.fromOffset(x, y)
        end

        local function fitLandscape()
            if not active then return end
            local bounds = screenSize()
            local minW = math.min(430, math.max(230, bounds.X - 18))
            local minH = math.min(275, math.max(175, bounds.Y - 16))
            local maxW = math.max(minW, bounds.X - 18)
            local maxH = math.max(minH, bounds.Y - 16)
            local width = math.clamp(tonumber(settings.menuWidth) or 950,
                minW, maxW)
            local height = math.clamp(tonumber(settings.menuHeight) or 515,
                minH, maxH)
            menu.Size = UDim2.fromOffset(width, height)
            local navWidth = width < 550 and 128 or
                (width < 780 and 164 or 214)
            sidebar.Size = UDim2.new(0, navWidth, 1, 0)
            content.Position = UDim2.fromOffset(navWidth + 12, 0)
            content.Size = UDim2.new(1, -(navWidth + 12), 1, 0)
            dragArea.TextSize = width < 580 and 12 or
                (width < 860 and 14 or 17)
            if extrasAPI.fpsLabel then
                extrasAPI.fpsLabel.Visible = settings.fpsOverlay ~= false
                extrasAPI.fpsLabel.Size = UDim2.fromOffset(
                    width < 580 and 56 or 94, 31)
                extrasAPI.fpsLabel.Position = UDim2.new(1,
                    width < 580 and -153 or -193, 0, 13)
            end
            if not layoutReady then
                menu.Position = UDim2.fromOffset(
                    math.floor(bounds.X / 2), math.floor(bounds.Y / 2))
                layoutReady = true
            end
            clampWindow()
            clampLaunchButton()
        end

        -- AnchorPoint = центр: окно не уползает при смене масштаба.
        menu.AnchorPoint = Vector2.new(0.5, 0.5)
        menu.Position = UDim2.fromOffset(400, 180)
        fitLandscape()
        connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fitLandscape)
        connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
            task.defer(fitLandscape)
        end)

        -- Плавное масштабирование и проявление содержимого без
        -- группового умножения цвета всего окна (текст остаётся ярким).
        local function setMenuOpen(open)
            if not active or menuTargetOpen == open then return end
            menuTargetOpen = open
            transitionId = transitionId + 1
            local id = transitionId
            local baseTransparency = math.clamp(
                tonumber(settings.menuTransparency) or 0, 0, 0.30)
            if open then
                fitLandscape()
                if not menu.Visible then
                    menuScale.Scale = 0.95
                    menu.BackgroundTransparency = math.min(0.30, baseTransparency+0.15)
                    pageHost.GroupTransparency = 0.65
                end
                menu.Visible = true
                tween(menuScale, 0.53, {Scale=1}, Enum.EasingStyle.Quint)
                tween(menu, 0.35, {BackgroundTransparency=baseTransparency},
                    Enum.EasingStyle.Sine)
                tween(pageHost, 0.45, {GroupTransparency=0},
                    Enum.EasingStyle.Sine)
                tween(menuStroke, 0.39, {Transparency=0.04}, Enum.EasingStyle.Sine)
                tween(openButton, 0.2, {BackgroundTransparency=0.12})
            else
                dragInput = nil
                tween(menuScale, 0.29, {Scale=0.95},
                    Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                tween(menu, 0.29, {
                    BackgroundTransparency=math.min(0.30,baseTransparency+0.18)
                }, Enum.EasingStyle.Sine)
                tween(pageHost, 0.22, {GroupTransparency=0.88},
                    Enum.EasingStyle.Sine)
                tween(menuStroke, 0.29, {Transparency=0.65})
                tween(openButton, 0.22, {BackgroundTransparency=0})
                task.delay(0.31, function()
                    if active and transitionId==id and not menuTargetOpen then
                        menu.Visible = false
                    end
                end)
            end
        end

        extrasAPI.showMenu = function(pageId)
            if pageId and pages[pageId] then setPage(pageId) end
            setMenuOpen(true)
        end
        -- Маленькая кнопка двигается и открывает окно только по тапу.
        connect(openButton.InputBegan, function(input)
            if buttonInput then return end
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                buttonInput, buttonStart = input, input.Position
                buttonOrigin, buttonMoved = openButton.Position, false
            end
        end)
        connect(UIS.InputChanged, function(input)
            if not buttonInput then return end
            local touch = buttonInput.UserInputType == Enum.UserInputType.Touch
            if (touch and input ~= buttonInput)
                or (not touch and input.UserInputType
                    ~= Enum.UserInputType.MouseMovement) then return end
            local delta = input.Position - buttonStart
            if delta.Magnitude > 7 then buttonMoved = true end
            if buttonMoved then
                openButton.Position = UDim2.fromOffset(
                    buttonOrigin.X.Offset + delta.X,
                    buttonOrigin.Y.Offset + delta.Y)
                clampLaunchButton()
            end
        end)
        connect(UIS.InputEnded, function(input)
            if input ~= buttonInput then return end
            if (input.Position - buttonStart).Magnitude > 7 then
                buttonMoved = true
            end
            if buttonMoved then suppressButtonUntil = os.clock() + 0.3 end
            buttonInput, buttonStart, buttonOrigin = nil, nil, nil
            buttonMoved = false
            clampLaunchButton()
        end)
        connect(openButton.Activated, function()
            if buttonMoved or os.clock() < suppressButtonUntil then return end
            setMenuOpen(not menuTargetOpen)
        end)
        connect(closeButton.Activated, function() setMenuOpen(false) end)
        connect(minimizeButton.Activated, function() setMenuOpen(false) end)

        -- Перетаскивание окна только за шапку, чтобы не мешать скроллу.
        connect(dragArea.InputBegan, function(input)
            if dragInput then return end
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragInput, dragStart = input, input.Position
                dragOrigin = menu.Position
                dragMoved = false
            end
        end)
        connect(UIS.InputChanged, function(input)
            if not dragInput or not menuTargetOpen then return end
            local touch = dragInput.UserInputType == Enum.UserInputType.Touch
            if (touch and input ~= dragInput)
                or (not touch and input.UserInputType
                    ~= Enum.UserInputType.MouseMovement) then return end
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then dragMoved = true end
            if dragMoved then
                menu.Position = UDim2.fromOffset(
                    dragOrigin.X.Offset + delta.X,
                    dragOrigin.Y.Offset + delta.Y)
                clampWindow()
            end
        end)
        connect(UIS.InputEnded, function(input)
            if input == dragInput then
                dragInput, dragStart, dragOrigin = nil, nil, nil
                dragMoved = false
            end
        end)
        connect(UIS.WindowFocusReleased, function()
            dragInput, buttonInput = nil, nil
            dragMoved, buttonMoved = false, false
        end)

        -- Потяни правый нижний угол: размер сохраняется между запусками.
        do
            local grip = new("TextButton", menu, {
                Name = "TimkaResizeGrip", Size = UDim2.fromOffset(43, 43),
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, 1, 1, 1),
                BackgroundTransparency = 1, Text = "◢",
                TextColor3 = Color3.fromRGB(241, 75, 255),
                TextSize = 31, Font = Enum.Font.GothamBold,
                AutoButtonColor = false, ZIndex = 35
            })
            local movingInput, movingOrigin, movingSize, movingCenter
            connect(grip.InputBegan, function(input)
                local typ = input.UserInputType
                if typ ~= Enum.UserInputType.Touch and
                    typ ~= Enum.UserInputType.MouseButton1 then return end
                movingInput, movingOrigin = input, input.Position
                movingSize, movingCenter = menu.AbsoluteSize, menu.Position
            end)
            connect(UIS.InputChanged, function(input)
                if not movingInput then return end
                local touch = movingInput.UserInputType == Enum.UserInputType.Touch
                if (touch and input ~= movingInput) or (not touch and
                    input.UserInputType ~= Enum.UserInputType.MouseMovement) then
                    return
                end
                local delta = input.Position - movingOrigin
                local bounds = screenSize()
                local minW = math.min(430, math.max(230, bounds.X-18))
                local minH = math.min(275, math.max(175, bounds.Y-16))
                local w = math.clamp(movingSize.X + delta.X,
                    minW, math.max(minW, bounds.X-18))
                local h = math.clamp(movingSize.Y + delta.Y,
                    minH, math.max(minH, bounds.Y-16))
                settings.menuWidth, settings.menuHeight = w, h
                menu.Position = UDim2.fromOffset(
                    movingCenter.X.Offset + (w-movingSize.X)/2,
                    movingCenter.Y.Offset + (h-movingSize.Y)/2)
                fitLandscape()
            end)
            connect(UIS.InputEnded, function(input)
                if input ~= movingInput then return end
                movingInput = nil
                saveSettings()
            end)
            local themePage = pages.themes
            if themePage then
                local card, inner = uiCard("themes", "▣  РАЗМЕР ОКНА", 125)
                uiLabel(inner, "Потяни ◢ в правом нижнем углу окна", 0, 27)
                uiButton(inner, "↺  Стандартный размер", 33, function()
                    settings.menuWidth, settings.menuHeight = 950, 515
                    fitLandscape()
                    saveSettings()
                end, cyan)
            end
        end

        -- Переключаем вкладки через плавный fade-out и fade-in.
        local pageScale = new("UIScale", pageHost, {Scale = 1})
        local oldSetPage = setPage
        local pageTransitionId = 0
        local requestedPage = currentPage
        setPage = function(id)
            if not pages[id] or requestedPage == id then return end
            requestedPage = id
            pageTransitionId = pageTransitionId + 1
            local requestId = pageTransitionId
            tween(pageHost, 0.11, {GroupTransparency = 1}, Enum.EasingStyle.Sine)
            tween(pageScale, 0.11, {Scale = 0.98}, Enum.EasingStyle.Sine)
            task.delay(0.12, function()
                if not active or requestId ~= pageTransitionId then return end
                oldSetPage(id)
                pageHost.GroupTransparency = 1
                pageScale.Scale = 0.97
                tween(pageHost, 0.29, {GroupTransparency = 0}, Enum.EasingStyle.Sine)
                tween(pageScale, 0.32, {Scale = 1}, Enum.EasingStyle.Quint)
            end)
        end

        -- ===== ТЕМЫ ОФОРМЛЕНИЯ =====
        local themePresets = {
            cyan = {"Голубой неон", Color3.fromRGB(63, 215, 255),
                Color3.fromRGB(149, 104, 255)},
            purple = {"Фиолетовый", Color3.fromRGB(195, 130, 255),
                Color3.fromRGB(255, 100, 190)},
            green = {"Изумрудный", Color3.fromRGB(75, 245, 145),
                Color3.fromRGB(36, 190, 200)}
        }
        local themeCard, themeInside = uiCard(
            "themes", "◈  ТЕМА МЕНЮ", 304)
        local themeStatus = uiStatus(themeInside, "Тема: голубой неон", 0)
        local themeButtons = {}
        local function applyTheme(name)
            local preset = themePresets[name] or themePresets.cyan
            local oldPrimary, oldSecondary = cyan, violet
            cyan, violet = preset[2], preset[3]
            for _, object in ipairs(gui:GetDescendants()) do
                pcall(function()
                    if object:IsA("UIStroke") then
                        if object.Color == oldPrimary then object.Color = cyan
                        elseif object.Color == oldSecondary then
                            object.Color = violet end
                    elseif object:IsA("TextLabel")
                        or object:IsA("TextButton")
                        or object:IsA("TextBox") then
                        if object.TextColor3 == oldPrimary then
                            object.TextColor3 = cyan
                        elseif object.TextColor3 == oldSecondary then
                            object.TextColor3 = violet end
                    elseif object:IsA("ScrollingFrame") then
                        if object.ScrollBarImageColor3 == oldPrimary then
                            object.ScrollBarImageColor3 = cyan
                        elseif object.ScrollBarImageColor3 == oldSecondary then
                            object.ScrollBarImageColor3 = violet end
                    end
                end)
            end
            local headerGradient = headerLine:FindFirstChildOfClass("UIGradient")
            if headerGradient then
                headerGradient.Color = ColorSequence.new(cyan, violet)
            end
            themeStatus.Text = "Тема: " .. preset[1]
            settings.theme = name
            for key, object in pairs(themeButtons) do
                object.BackgroundColor3 = key == name
                    and Color3.fromRGB(24, 103, 120) or C.panelLight
            end
            setPage(currentPage)
        end
        for index, item in ipairs({
            {"cyan", "Голубой неон"},
            {"purple", "Фиолетовый"},
            {"green", "Изумрудный"}
        }) do
            local key, caption = item[1], item[2]
            local object = uiButton(themeInside, caption,
                33 + (index - 1) * 44, function()
                    applyTheme(key)
                    saveSettings()
                end, themePresets[key][2])
            themeButtons[key] = object
        end
        uiLabel(themeInside,
            "По умолчанию непрозрачное меню с ярким текстом.",
            172, 30)
        uiStepper(themeInside, "Прозрачность фона", 209,
            math.clamp(tonumber(settings.menuTransparency) or 0, 0, 0.30),
            0, 0.30, 0.05, 2, function(value)
                settings.menuTransparency = value
                menu.BackgroundTransparency = value
                saveSettings()
            end)
        applyTheme(settings.theme)
    end


    -- ===== ЧАСТЬ 20: УПРАВЛЕНИЕ МИНИ-МЕНЮ И FPS =====
    do
        local c, inside = uiCard("playerpopup", "◎  НАСТРОЙКИ МИНИ-МЕНЮ ИГРОКА", 349)
        uiToggle(inside, "Включить мини-меню игрока", 2,
            settings.popupEnabled ~= false, function(value)
                settings.popupEnabled = value
                if not value and extrasAPI.closePopup then extrasAPI.closePopup() end
                saveSettings()
            end)
        uiToggle(inside, "Выбор игрока через стены", 41,
            settings.popupBehindWalls == true, function(value)
                settings.popupBehindWalls = value
                saveSettings()
            end)
        uiToggle(inside, "Открывать по центру экрана", 80,
            settings.popupCenter == true, function(value)
                settings.popupCenter = value
                saveSettings()
            end)
        uiStepper(inside, "Удержание (сек)", 125,
            math.clamp(tonumber(settings.popupHold) or 0, 0, 1.5),
            0, 1.5, 0.1, 1, function(value)
                settings.popupHold = value
                saveSettings()
            end)
        uiStepper(inside, "Радиус выбора (px)", 170,
            math.clamp(tonumber(settings.popupRadius) or 35, 12, 90),
            15, 90, 5, 0, function(value)
                settings.popupRadius = value
                saveSettings()
            end)
        uiLabel(inside, "0 сек = короткое касание; чем больше радиус, тем легче выбрать цель.", 216, 46)
        uiLabel(inside, "Через стены: только персонажи, загруженные твоим клиентом.", 259, 37)

        local fpsC, fpsIn = uiCard("home", "◉  СЧЁТЧИК FPS", 115)
        uiToggle(fpsIn, "Показывать FPS в шапке меню", 0,
            settings.fpsOverlay ~= false, function(value)
                settings.fpsOverlay = value
                if extrasAPI.fpsLabel then extrasAPI.fpsLabel.Visible = value end
                saveSettings()
            end)
        uiLabel(fpsIn, "Показания берутся из существующего счётчика, без лишнего цикла.", 40, 34)
        if extrasAPI.fpsLabel then
            extrasAPI.fpsLabel.Visible = settings.fpsOverlay ~= false
        end
    end

    -- ===== ЧАСТЬ 21: МУЗЫКА (ROBLOX SOUND ID) =====
    do
        local SoundService = game:GetService("SoundService")
        local musicSound = new("Sound", SoundService, {
            Name = "TimkaNeonMusic", SoundId = "", Volume =
                math.clamp(tonumber(settings.audioVolume) or 0.5, 0, 1),
            Looped = settings.audioLoop == true
        })
        local mc, mi = uiCard("music", "♫  NEON MUSIC PLAYER", 326)
        uiLabel(mi, "Введи Roblox Audio ID (не ссылку на посторонний сайт):", 0, 38)
        local audioBox = new("TextBox", mi, {
            Position = UDim2.fromOffset(0, 42),
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = C.panelLight,
            Text = tostring(settings.audioId or ""),
            PlaceholderText = "Например: 123456789", ClearTextOnFocus = false,
            TextColor3 = C.white, PlaceholderColor3 = C.muted,
            Font = Enum.Font.Gotham, TextSize = 13,
            BorderSizePixel = 0
        })
        corner(audioBox, 8)
        local musicState = uiStatus(mi, "Не играет", 81)
        local function soundFromBox()
            local id = tostring(audioBox.Text):match("(%d+)")
            if not id or #id > 20 then
                musicState.Text = "Некорректный Roblox Audio ID"
                return false
            end
            settings.audioId = id
            musicSound.SoundId = "rbxassetid://" .. id
            saveSettings()
            return true
        end
        local play = uiButton(mi, "▶ Играть", 117, function()
            if not soundFromBox() then return end
            local success, message = pcall(function() musicSound:Play() end)
            musicState.Text = success and "Запуск аудио..."
                or ("Ошибка: " .. tostring(message))
        end, cyan)
        play.Size = UDim2.new(0.49, 0, 0, 34)
        local stop = uiButton(mi, "■ Стоп", 117, function()
            musicSound:Stop()
            musicState.Text = "Остановлено"
        end, violet)
        stop.Size = UDim2.new(0.49, 0, 0, 34)
        stop.Position = UDim2.new(0.51, 0, 0, 117)
        uiStepper(mi, "Громкость", 158,
            math.clamp(tonumber(settings.audioVolume) or 0.5, 0, 1),
            0, 1, 0.1, 1, function(value)
                musicSound.Volume = value
                settings.audioVolume = value
                saveSettings()
            end)
        uiToggle(mi, "Повторять трек", 204, settings.audioLoop == true,
            function(value)
                settings.audioLoop = value
                musicSound.Looped = value
                saveSettings()
            end)
        uiLabel(mi, "Работают только доступные тебе Roblox Audio. MP3 с телефона сюда не загружается.", 242, 34)
        connect(musicSound.Ended, function()
            if active and musicState.Parent then musicState.Text = "Трек завершён" end
        end)
        extrasAPI.resetMusic = function()
            musicSound:Stop()
            musicState.Text = "Остановлено"
        end
        registerCleanup(function()
            musicSound:Stop()
            if musicSound.Parent then musicSound:Destroy() end
        end)
    end

    -- ===== ЧАСТЬ 22: JUMP CIRCLE (НЕОНОВОЕ КОЛЬЦО) =====
    do
        local Debris = game:GetService("Debris")
        local activePieces = {}
        local jumpHumanoidConnection = nil
        local lastJumpCircle = 0
        local function circleColor()
            local t = visuals.jumpColor or {165, 105, 255}
            return Color3.fromRGB(math.clamp(tonumber(t[1]) or 165, 0, 255),
                math.clamp(tonumber(t[2]) or 105, 0, 255),
                math.clamp(tonumber(t[3]) or 255, 0, 255))
        end
        local function clearCircles()
            for part in pairs(activePieces) do
                if part and part.Parent then part:Destroy() end
                activePieces[part] = nil
            end
        end
        local function spawnCircle()
            if not active or not visuals.jumpCircle
                or os.clock()-lastJumpCircle < 0.4 then return end
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            lastJumpCircle = os.clock()
            local r = math.clamp(tonumber(visuals.jumpRadius) or 3, 1.5, 8)
            local life = math.clamp(tonumber(visuals.jumpLife) or 0.65, 0.25, 1.5)
            local origin = root.Position - Vector3.new(0, 2.8, 0)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {char}
            local hit = Workspace:Raycast(root.Position, Vector3.new(0, -10, 0), params)
            if hit then origin = hit.Position + Vector3.new(0, 0.1, 0) end
            local steps = visuals.fps == "max" and 10 or 20
            local color = circleColor()
            local chord = 2 * math.pi * r / steps
            for n=1, steps do
                local a = 2*math.pi*n/steps
                local direction = Vector3.new(math.cos(a), 0, math.sin(a))
                local tangent = Vector3.new(-math.sin(a), 0, math.cos(a))
                local p = new("Part", Workspace, {
                    Name = "TimkaJumpCirclePart", Anchored = true,
                    CanCollide = false, CanTouch = false, CanQuery = false,
                    CastShadow = false, Material = Enum.Material.Neon,
                    Color = color, Transparency = 0.06,
                    Size = Vector3.new(0.11, 0.07, chord * 0.91),
                    CFrame = CFrame.lookAt(origin + direction*r,
                        origin + direction*r + tangent)
                })
                activePieces[p] = true
                local destination = origin + direction*(r*1.30)
                tween(p, life, {
                    CFrame = CFrame.lookAt(destination,
                        destination + tangent), Transparency = 1,
                    Size = Vector3.new(0.035, 0.035, chord)
                }, Enum.EasingStyle.Sine)
                Debris:AddItem(p, life + 0.12)
                task.delay(life+0.15, function() activePieces[p] = nil end)
            end
        end
        local function watchJump(char)
            if jumpHumanoidConnection then
                jumpHumanoidConnection:Disconnect()
                jumpHumanoidConnection = nil
            end
            task.spawn(function()
                local hum = char:WaitForChild("Humanoid", 10)
                if not active or not hum or char ~= player.Character then return end
                jumpHumanoidConnection = hum.StateChanged:Connect(function(_, state)
                    if state == Enum.HumanoidStateType.Jumping then
                        spawnCircle()
                    end
                end)
            end)
        end
        connect(player.CharacterAdded, watchJump)
        if player.Character then watchJump(player.Character) end
        local jc, ji = uiCard("visuals", "◎  JUMP CIRCLE", 241)
        uiToggle(ji, "Круг при прыжке", 0, visuals.jumpCircle == true,
            function(v) visuals.jumpCircle = v; saveSettings() end)
        uiStepper(ji, "Размер кольца", 41,
            math.clamp(tonumber(visuals.jumpRadius) or 3, 1.5, 8),
            1.5, 8, 0.5, 1, function(v)
                visuals.jumpRadius = v; saveSettings()
            end)
        uiStepper(ji, "Время свечения", 84,
            math.clamp(tonumber(visuals.jumpLife) or 0.65, 0.25, 1.5),
            0.25, 1.5, 0.05, 2, function(v)
                visuals.jumpLife = v; saveSettings()
            end)
        uiButton(ji, "◎  Проверить кольцо", 128, spawnCircle, cyan)
        uiLabel(ji, "Цвет Jump Circle доступен в редакторе RGB.", 171, 25)
        extrasAPI.refreshJump = function() end
        extrasAPI.resetJump = function() clearCircles() end
        registerCleanup(function()
            if jumpHumanoidConnection then jumpHumanoidConnection:Disconnect() end
            clearCircles()
        end)
    end

    -- ===== ЧАСТЬ 23: HD / ULTRA HD / АТМОСФЕРА / ВРЕМЯ =====
    do
        local hdNames = {original = "Оригинал", hd = "HD",
            ultra = "Ultra HD", film = "Кино"}
        local hdColor = new("ColorCorrectionEffect", Lighting, {
            Name = "TimkaHDColor", Enabled = false,
            Brightness = 0, Contrast = 0, Saturation = 0,
            TintColor = Color3.new(1,1,1)
        })
        local hdBloom = new("BloomEffect", Lighting, {
            Name = "TimkaHDBloom", Enabled = false,
            Intensity = 0, Size = 18, Threshold = 1.15
        })
        local hdRays = new("SunRaysEffect", Lighting, {
            Name = "TimkaHDRays", Enabled = false,
            Intensity = 0, Spread = 0.8
        })
        local originalAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        local atmosphere = originalAtmosphere
        local originalAtmosphereProps = nil
        if atmosphere then
            originalAtmosphereProps = {
                Density = atmosphere.Density, Offset = atmosphere.Offset,
                Color = atmosphere.Color, Decay = atmosphere.Decay,
                Glare = atmosphere.Glare, Haze = atmosphere.Haze
            }
        else
            atmosphere = new("Atmosphere", Lighting, {Name="TimkaHDAtmosphere"})
        end
        local graphicsStatus
        local function restoreAtmosphere()
            if originalAtmosphere and originalAtmosphere.Parent then
                for k,v in pairs(originalAtmosphereProps) do
                    pcall(function() originalAtmosphere[k] = v end)
                end
            elseif atmosphere and atmosphere.Parent then
                -- Новый Atmosphere отключаем без изменения исходной карты.
                atmosphere.Density = 0
                atmosphere.Haze = 0
                atmosphere.Glare = 0
            end
        end
        local function applyHD()
            if not active then return end
            local mode = visuals.hd or "original"
            if not hdNames[mode] then mode = "original" end
            local power = math.clamp(tonumber(visuals.hdStrength) or 0.6, 0, 1)
            local fpsMax = visuals.fps == "max"
            local hdOn = mode ~= "original" and not fpsMax
            hdColor.Enabled = hdOn
            hdBloom.Enabled = hdOn
            hdRays.Enabled = hdOn and (mode=="ultra" or mode=="film")
            if hdOn then
                hdColor.Brightness = mode == "film" and -0.03 or 0.015*power
                hdColor.Contrast = power * (mode == "ultra" and 0.22 or 0.12)
                hdColor.Saturation = power * (mode == "film" and 0.08 or 0.25)
                hdColor.TintColor = mode == "film"
                    and Color3.fromRGB(255,235,218) or Color3.fromRGB(242,248,255)
                hdBloom.Intensity = power*(mode == "ultra" and 0.48 or 0.25)
                hdBloom.Size = mode == "ultra" and 28 or 18
                hdRays.Intensity = power*0.08
            end
            restoreAtmosphere()
            if atmosphere and atmosphere.Parent and visuals.ambientEnabled then
                local p = math.clamp(tonumber(visuals.ambientStrength) or 0.4, 0, 1)
                atmosphere.Density = 0.12 + 0.22*p
                atmosphere.Haze = 0.3 + 2*p
                atmosphere.Glare = 0.08 + 0.16*p
                atmosphere.Color = Color3.fromRGB(189,204,245)
                atmosphere.Decay = Color3.fromRGB(105,130,180)
            end
            if graphicsStatus and graphicsStatus.Parent then
                graphicsStatus.Text = "Графика: " .. (hdNames[mode] or "Оригинал")
                    .. (fpsMax and " (ограничено FPS Boost)" or "")
            end
        end
        local oldApplyVisualLighting = applyVisualLighting
        applyVisualLighting = function()
            oldApplyVisualLighting()
            applyHD()
        end
        extrasAPI.refreshHD = applyHD
        extrasAPI.resetHD = function()
            hdColor.Enabled, hdBloom.Enabled, hdRays.Enabled = false, false, false
            restoreAtmosphere()
        end

        local gCard, gInside = uiCard("visuals", "✦  HD И ULTRA HD", 312)
        graphicsStatus = uiStatus(gInside, "Графика: Оригинал", 0)
        local function graphicsChoice(title, mode, y, right)
            local button = uiButton(gInside, title, y, function()
                visuals.hd = mode
                applyVisualLighting()
                applyWeather()
                saveSettings()
            end, mode == "ultra" and violet or cyan)
            button.Size = UDim2.new(0.49, 0, 0, 34)
            if right then button.Position = UDim2.new(0.51, 0, 0, y) end
        end
        graphicsChoice("Оригинал", "original", 34, false)
        graphicsChoice("HD", "hd", 34, true)
        graphicsChoice("Ultra HD", "ultra", 76, false)
        graphicsChoice("Кино", "film", 76, true)
        uiStepper(gInside, "Сила улучшений", 120,
            math.clamp(tonumber(visuals.hdStrength) or 0.6, 0, 1),
            0, 1, 0.1, 1, function(v)
                visuals.hdStrength = v
                applyHD(); saveSettings()
            end)
        uiLabel(gInside, "Это локальная постобработка, не новые HD-текстуры.", 164, 37)
        uiLabel(gInside, "При максимальном FPS HD временно подавляется.", 213, 35)

        local aCard, aInside = uiCard("visuals", "☀  ЖИВАЯ АТМОСФЕРА", 260)
        uiToggle(aInside, "Атмосферная дымка", 0,
            visuals.ambientEnabled == true, function(v)
                visuals.ambientEnabled = v
                applyVisualLighting(); applyWeather(); saveSettings()
            end)
        uiStepper(aInside, "Сила атмосферы", 43,
            math.clamp(tonumber(visuals.ambientStrength) or 0.4,0,1),
            0, 1, 0.1, 1, function(v)
                visuals.ambientStrength = v
                applyVisualLighting(); applyWeather(); saveSettings()
            end)
        uiToggle(aInside, "Плавная смена дня и ночи", 86,
            visuals.skyCycle == true, function(v)
                visuals.skyCycle = v
                if not v then applyVisualLighting() end
                saveSettings()
            end)
        uiStepper(aInside, "Цикл (мин)", 129,
            math.clamp(tonumber(visuals.skyCycleMinutes) or 10,2,60),
            2, 60, 2, 0, function(v)
                visuals.skyCycleMinutes = v
                saveSettings()
            end)
        uiLabel(aInside, "Время плавно меняется только локально. Игра может его переопределять.", 176, 38)
        local cycleTimer = 0
        connect(RunService.Heartbeat, function(dt)
            if not active or visuals.skyCycle ~= true then return end
            cycleTimer = cycleTimer + dt
            if cycleTimer < 0.12 then return end
            local seconds = math.max(120, (tonumber(visuals.skyCycleMinutes) or 10)*60)
            Lighting.ClockTime = (Lighting.ClockTime + (cycleTimer*24/seconds)) % 24
            cycleTimer = 0
        end)
        applyHD()
        registerCleanup(function()
            extrasAPI.resetHD()
            if hdColor.Parent then hdColor:Destroy() end
            if hdBloom.Parent then hdBloom:Destroy() end
            if hdRays.Parent then hdRays:Destroy() end
            if not originalAtmosphere and atmosphere and atmosphere.Parent then
                atmosphere:Destroy()
            end
        end)
    end

    -- ===== ЧАСТЬ 24: ПОЛУПРОЗРАЧНЫЙ ПЕРСОНАЖ =====
    do
        local originalParts = {}
        local descConnection = nil
        local function colorFromSettings()
            local rgb = visuals.skinColor or {165,105,255}
            return Color3.fromRGB(math.clamp(tonumber(rgb[1]) or 165,0,255),
                math.clamp(tonumber(rgb[2]) or 105,0,255),
                math.clamp(tonumber(rgb[3]) or 255,0,255))
        end
        local function isTargetPart(part)
            if not part:IsA("BasePart") or part.Name == "HumanoidRootPart" then
                return false
            end
            local char = player.Character
            if not char or not part:IsDescendantOf(char) then return false end
            if part.Parent == char then return true end
            return visuals.skinAll and part.Parent:IsA("Accessory")
        end
        local function resetSkin()
            for part, old in pairs(originalParts) do
                if part and part.Parent then
                    pcall(function()
                        part.LocalTransparencyModifier = old.transparency
                        part.Color = old.color
                    end)
                end
                originalParts[part] = nil
            end
        end
        local function applySkin()
            resetSkin()
            if not active or not visuals.skinEnabled then return end
            local char = player.Character
            if not char then return end
            local color = colorFromSettings()
            local opacity = math.clamp(tonumber(visuals.skinOpacity) or 0.45,0,0.95)
            for _, part in ipairs(char:GetDescendants()) do
                if isTargetPart(part) then
                    originalParts[part] = {
                        color = part.Color, transparency = part.LocalTransparencyModifier
                    }
                    pcall(function()
                        part.LocalTransparencyModifier = opacity
                        part.Color = color
                    end)
                end
            end
        end
        extrasAPI.applySkin = applySkin
        extrasAPI.resetSkin = resetSkin
        local function watchSkin(char)
            resetSkin()
            if descConnection then descConnection:Disconnect(); descConnection = nil end
            descConnection = char.DescendantAdded:Connect(function(object)
                if object:IsA("BasePart") and visuals.skinEnabled then
                    task.defer(function()
                        if active and char == player.Character then applySkin() end
                    end)
                end
            end)
            task.defer(function()
                if active and player.Character == char then applySkin() end
            end)
        end
        connect(player.CharacterAdded, watchSkin)
        if player.Character then watchSkin(player.Character) end
        local sCard, sInside = uiCard("visuals", "◐  ПРОЗРАЧНЫЙ СКИН", 226)
        uiToggle(sInside, "Полупрозрачный персонаж", 0,
            visuals.skinEnabled == true, function(v)
                visuals.skinEnabled = v
                applySkin(); saveSettings()
            end)
        uiToggle(sInside, "Включить аксессуары", 40,
            visuals.skinAll == true, function(v)
                visuals.skinAll = v
                applySkin(); saveSettings()
            end)
        uiStepper(sInside, "Прозрачность", 81,
            math.clamp(tonumber(visuals.skinOpacity) or 0.45,0,0.95),
            0,0.95,0.05,2, function(v)
                visuals.skinOpacity = v
                applySkin(); saveSettings()
            end)
        uiButton(sInside, "↺ Восстановить скин", 128, function()
            visuals.skinEnabled = false
            resetSkin(); saveSettings()
            status("Скин восстановлен. Перезайди для обновления тумблера.")
        end, violet)
        uiLabel(sInside, "RGB-цвет кожи/аксессуаров — в редакторе цветов.", 170, 27)
        registerCleanup(function()
            if descConnection then descConnection:Disconnect() end
            resetSkin()
        end)
    end

    -- ===== ЧАСТЬ 25: AURA BALL / КОЛЬЦА / ЭНЕРГИЯ =====
    do
        local folder, orb, pointLight, orbEmitter
        local rings = {}
        local currentChar = nil
        local auraTick = 0
        local angle = 0
        local function auraRGB()
            local rgb = visuals.auraBallColor or {255,90,225}
            return Color3.fromRGB(math.clamp(tonumber(rgb[1]) or 255,0,255),
                math.clamp(tonumber(rgb[2]) or 90,0,255),
                math.clamp(tonumber(rgb[3]) or 225,0,255))
        end
        local function deleteOrb()
            if orbEmitter and orbEmitter.Parent then
                orbEmitter.Enabled = false
                orbEmitter:Clear()
                orbEmitter:Destroy()
            end
            orbEmitter = nil
            if folder and folder.Parent then folder:Destroy() end
            for _, item in ipairs(rings) do
                if item.attachment and item.attachment.Parent then
                    item.attachment:Destroy()
                end
            end
            folder, orb, pointLight = nil, nil, nil
            table.clear(rings)
            currentChar = nil
        end
        local function makeSegment(parent, color)
            local piece = new("Part", parent, {
                Name = "TimkaOrbArc", Anchored = true,
                CanCollide = false, CanTouch = false, CanQuery = false,
                CastShadow = false, Material = Enum.Material.Neon,
                Color = color, Transparency = 0.10,
                Size = Vector3.new(0.10, 0.10, 0.5)
            })
            return piece
        end
        local function refreshOrb()
            deleteOrb()
            if not active or visuals.auraBallEnabled ~= true then return end
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            currentChar = char
            local c = auraRGB()
            folder = new("Folder", Workspace, {Name = "TimkaAuraBallLocal"})
            orb = new("Part", folder, {
                Name = "TimkaAuraSphere", Shape = Enum.PartType.Ball,
                Material = Enum.Material.ForceField,
                Anchored = true, CanCollide = false, CanTouch = false,
                CanQuery = false, CastShadow = false,
                Size = Vector3.new(5,5,5), Color = c,
                Transparency = 0.65
            })
            pointLight = new("PointLight", orb, {
                Name = "TimkaAuraOrbLight", Color = c,
                Brightness = 0.8, Range = 10, Shadows = false
            })
            if visuals.auraParticlesEnabled ~= false then
                local att = new("Attachment",root, {
                    Name = "TimkaOrbParticlesAttachment"
                })
                orbEmitter = new("ParticleEmitter",att,{
                    Name = "TimkaOrbSparkles", Enabled = true,
                    Texture = "rbxasset://textures/particles/sparkles_main.dds",
                    Color = ColorSequence.new(c), LightEmission = 1,
                    LightInfluence = 0, Rate = 12,
                    Speed = NumberRange.new(0.5,2),
                    Lifetime = NumberRange.new(0.6,1.5),
                    SpreadAngle = Vector2.new(180,180),
                    Size = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,0.22),
                        NumberSequenceKeypoint.new(1,0)
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,0.07),
                        NumberSequenceKeypoint.new(1,1)
                    })
                })
                -- Attachment должен удаляться отдельно от Folder.
                table.insert(rings, {attachment = att})
            end
            local steps = visuals.fps == "max" and 10 or 18
            for _, kind in ipairs({"floor", "orbit"}) do
                local enabled = (kind=="floor" and visuals.auraRingEnabled ~= false)
                    or (kind=="orbit" and visuals.auraArcsEnabled ~= false)
                if enabled then
                    for i=1,steps do
                        table.insert(rings, {part=makeSegment(folder,c),
                            kind=kind, index=i, steps=steps})
                    end
                end
            end
        end
        local function refreshAuraBall()
            refreshOrb()
        end
        extrasAPI.refreshAuraFX = refreshAuraBall
        extrasAPI.resetAuraFX = deleteOrb
        local lastCharacter = player.Character
        connect(player.CharacterAdded, function(character)
            lastCharacter = character
            task.spawn(function()
                character:WaitForChild("HumanoidRootPart",10)
                if active and character == player.Character then refreshOrb() end
            end)
        end)
        connect(player.CharacterRemoving, function(char)
            if char==currentChar then deleteOrb() end
        end)
        connect(RunService.Heartbeat, function(dt)
            if not active then return end
            if visuals.auraBallEnabled ~= true then
                if folder then deleteOrb() end
                return
            end
            if not folder then
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then refreshOrb() end
                return
            end
            auraTick = auraTick + dt
            local interval = visuals.fps == "max" and 0.11 or 0.045
            if auraTick < interval then return end
            local step = auraTick
            auraTick = 0
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root or currentChar ~= char then return end
            local r = math.clamp(tonumber(visuals.auraBallSize) or 5,2,12)
            local glow = math.clamp(tonumber(visuals.auraBallGlow) or 0.75,0,1)
            angle = (angle + step*math.clamp(
                tonumber(visuals.auraSpin) or 1.1,0,5)) % (math.pi*2)
            orb.CFrame = CFrame.new(root.Position)
            orb.Size = Vector3.new(r,r,r)
            orb.Transparency = 0.91 - glow*0.21
            pointLight.Color = auraRGB()
            pointLight.Brightness = visuals.fps == "max" and 0 or glow*1.5
            pointLight.Range = r*2
            local ground = root.Position - Vector3.new(0,2.65,0)
            for _, item in ipairs(rings) do
                local part = item.part
                if part then
                    local a = 2*math.pi*item.index/item.steps + angle
                    local radius = r*0.69
                    local p, tangent
                    if item.kind == "floor" then
                        p = ground + Vector3.new(
                            math.cos(a)*radius, 0.1, math.sin(a)*radius)
                        tangent = Vector3.new(-math.sin(a),0,math.cos(a))
                    else
                        p = root.Position + Vector3.new(
                            math.cos(a)*radius,
                            math.sin(a)*radius*0.54, math.cos(a*1.7)*0.35)
                        tangent = Vector3.new(-math.sin(a),math.cos(a)*0.54,0.1)
                    end
                    part.CFrame = CFrame.lookAt(p,p+tangent)
                    part.Size = Vector3.new(0.08+glow*0.08,0.10,radius*2*math.pi/item.steps*0.88)
                    part.Transparency = 0.35 - glow*0.3
                end
            end
            if orbEmitter then
                orbEmitter.Color = ColorSequence.new(auraRGB())
                orbEmitter.Rate = visuals.fps == "max" and 3 or 12
            end
        end)
        local bc, bi = uiCard("visuals", "✦  AURA BALL / МАГИЧЕСКИЕ КОЛЬЦА", 374)
        uiToggle(bi, "Включить Aura Ball", 0,
            visuals.auraBallEnabled == true, function(v)
                visuals.auraBallEnabled = v
                refreshOrb(); saveSettings()
            end)
        uiToggle(bi, "Круги под ногами", 39,
            visuals.auraRingEnabled ~= false, function(v)
                visuals.auraRingEnabled = v
                refreshOrb(); saveSettings()
            end)
        uiToggle(bi, "Вращающиеся световые ленты", 78,
            visuals.auraArcsEnabled ~= false, function(v)
                visuals.auraArcsEnabled = v
                refreshOrb(); saveSettings()
            end)
        uiToggle(bi, "Звёзды и частицы", 117,
            visuals.auraParticlesEnabled ~= false, function(v)
                visuals.auraParticlesEnabled = v
                refreshOrb(); saveSettings()
            end)
        uiStepper(bi, "Размер", 156,
            math.clamp(tonumber(visuals.auraBallSize) or 5,2,12),
            2,12,1,0,function(v)
                visuals.auraBallSize = v; saveSettings()
            end)
        uiStepper(bi, "Свечение", 198,
            math.clamp(tonumber(visuals.auraBallGlow) or 0.75,0,1),
            0,1,0.1,1,function(v)
                visuals.auraBallGlow = v; saveSettings()
            end)
        uiButton(bi, "✧ Белая энергия", 242, function()
            visuals.auraBallColor = {240,248,255}
            visuals.auraBallEnabled = true
            refreshOrb(); saveSettings()
        end, cyan)
        uiButton(bi, "✦ Розовая магия", 281, function()
            visuals.auraBallColor = {255,80,225}
            visuals.auraBallEnabled = true
            refreshOrb(); saveSettings()
        end, violet)
        registerCleanup(deleteOrb)
    end

    -- ===== ЧАСТЬ 26: ЕДИНЫЙ СБРОС НОВЫХ ЭФФЕКТОВ =====
    do
        extrasAPI.resetExtras = function()
            if extrasAPI.resetSkin then extrasAPI.resetSkin() end
            if extrasAPI.resetAuraFX then extrasAPI.resetAuraFX() end
            if extrasAPI.resetJump then extrasAPI.resetJump() end
            if extrasAPI.resetHD then extrasAPI.resetHD() end
        end
    end

    -- =====================================================================
    -- OPTIONAL MP3 PLAYLIST | DELTA EXECUTOR'S LOCAL FILE FOLDER
    -- Does not assume Roblox can access /storage/emulated/0 directly.
    -- Requires listfiles and getcustomasset in the actual executor.
    -- =====================================================================
    (function()
        local folder = "TIMKA_MUSIC"
        local songs = {}
        local selection = 1
        local SoundService = game:GetService("SoundService")
        local localAudio = new("Sound", SoundService, {
            Name = "TimkaCustomMP3", SoundId = "",
            Volume = math.clamp(tonumber(settings.audioVolume) or .5,0,1),
            Looped = settings.audioLoop == true
        })
        local mp3Card, mp3Inside = uiCard("music", "♫  МОИ MP3 / TIMKA MUSIC", 350)
        local info = uiStatus(mp3Inside,"Проверка поддержки файлов Delta...",0)
        local current = uiStatus(mp3Inside,"Трек не выбран",24)
        local scroll = new("ScrollingFrame",mp3Inside,{
            Name="LocalMusicPlaylist",Position=UDim2.fromOffset(0,102),
            Size=UDim2.new(1,0,0,166), BackgroundColor3=C.base,
            BackgroundTransparency=.06,BorderSizePixel=0,
            CanvasSize=UDim2.fromOffset(0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ScrollingDirection=Enum.ScrollingDirection.Y,
            ScrollBarThickness=4,ScrollBarImageColor3=violet
        })
        corner(scroll,10)
        stroke(scroll,cyan,.2,1.4)
        new("UIListLayout",scroll,{
            Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder
        })
        new("UIPadding",scroll,{
            PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),
            PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,10)
        })
        local function playSelected(index)
            if not active or not songs[index] then
                info.Text="Сначала выбери MP3 в списке"
                return
            end
            if type(getcustomasset)~="function" then
                info.Text="Delta: функция getcustomasset недоступна"
                return
            end
            local okAsset,assetOrError=pcall(getcustomasset,songs[index])
            if not okAsset or type(assetOrError)~="string" then
                info.Text="MP3 не распознан: "..tostring(assetOrError):sub(1,65)
                return
            end
            selection=index
            if extrasAPI.resetMusic then extrasAPI.resetMusic() end
            local okPlay,playError=pcall(function()
                localAudio:Stop()
                localAudio.SoundId=assetOrError
                localAudio.Volume=math.clamp(tonumber(settings.audioVolume) or .5,0,1)
                localAudio.Looped=settings.audioLoop==true
                localAudio:Play()
            end)
            current.Text="♫  "..songs[index]:match("[^/\\]+$")
            info.Text=okPlay and "Запуск MP3 (проверь звук в игре)"
                or "Ошибка воспроизведения: "..tostring(playError):sub(1,75)
        end
        local function reload()
            for _,el in ipairs(scroll:GetChildren()) do
                if el:IsA("TextButton") then el:Destroy() end
            end
            table.clear(songs)
            if type(listfiles)~="function" then
                info.Text="Delta не предоставляет listfiles — локальный список недоступен"
                return
            end
            if type(isfolder)=="function" and type(makefolder)=="function" then
                pcall(function() if not isfolder(folder) then makefolder(folder) end end)
            end
            local ok,found=pcall(listfiles,folder)
            if not ok or type(found)~="table" then
                info.Text="Не удалось открыть TIMKA_MUSIC в рабочей папке Delta"
                return
            end
            for _,filePath in ipairs(found) do
                if type(filePath)=="string" and filePath:lower():match("%.mp3$") then
                    table.insert(songs,filePath)
                end
            end
            table.sort(songs,function(a,b)return a:lower()<b:lower() end)
            info.Text=(#songs>0 and ("Найдено MP3: "..#songs)
                or "Папка TIMKA_MUSIC пуста — скопируй туда MP3")
            for index,path in ipairs(songs) do
                local btn=new("TextButton",scroll,{
                    Size=UDim2.new(1,-5,0,33),
                    BackgroundColor3=Color3.fromRGB(13,16,48),
                    Text="♫  "..path:match("[^/\\]+$"),
                    TextColor3=C.white,TextSize=12,
                    Font=Enum.Font.GothamBold,
                    TextTruncate=Enum.TextTruncate.AtEnd,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    LayoutOrder=index,AutoButtonColor=false
                })
                corner(btn,7)
                stroke(btn,index==selection and cyan or violet,.23,1.1)
                connect(btn.Activated,function() playSelected(index) end)
            end
        end
        local refresh=uiButton(mp3Inside,"↺  Найти MP3 в папке Delta",55,reload,cyan)
        refresh.Size=UDim2.new(1,0,0,34)
        local back=uiButton(mp3Inside,"◀  Предыдущая",277,function()
            if #songs==0 then return end
            playSelected((selection-2+#songs)%#songs+1)
        end,violet)
        back.Size=UDim2.new(.32,0,0,33)
        local stop=uiButton(mp3Inside,"■  Стоп",277,function()
            localAudio:Stop()
            info.Text="MP3 остановлен"
        end,Color3.fromRGB(250,57,210))
        stop.Position=UDim2.new(.34,0,0,277)
        stop.Size=UDim2.new(.32,0,0,33)
        local nextBtn=uiButton(mp3Inside,"Следующая  ▶",277,function()
            if #songs==0 then return end
            playSelected(selection%#songs+1)
        end,cyan)
        nextBtn.Position=UDim2.new(.68,0,0,277)
        nextBtn.Size=UDim2.new(.32,0,0,33)
        connect(localAudio.Ended,function()
            if active and not localAudio.Looped and #songs>1 then
                playSelected(selection%#songs+1)
            end
        end)
        registerCleanup(function()
            localAudio:Stop()
            if localAudio.Parent then localAudio:Destroy() end
        end)
        reload()
    end)()

    -- ===== ЧАСТЬ 19: СБРОС / ПРОВЕРКА / ЗАВЕРШЕНИЕ =====
    -- Важно: это последние строки общего xpcall из части 1.
    -- Модули не объявляем повторно и не создаём второй ScreenGui.

    -- Следы из части 14 живут внутри отдельного do-блока.
    -- Удаляем только принадлежащие этому модулю объекты.
    local trailObjectNames = {
        TimkaVisualTrail = true,
        TimkaTrailParticles = true,
        TimkaTrailLeft = true,
        TimkaTrailRight = true
    }
    local function removeLiveTrail()
        local character = player.Character
        if not character then return end
        for _, object in ipairs(character:GetDescendants()) do
            if trailObjectNames[object.Name]
                and (object:IsA("Trail")
                    or object:IsA("ParticleEmitter")
                    or object:IsA("Attachment")) then
                pcall(function()
                    if object:IsA("Trail")
                        or object:IsA("ParticleEmitter") then
                        object.Enabled = false
                        object:Clear()
                    end
                    object:Destroy()
                end)
            end
        end
    end

    -- Не заменяем таблицу visuals: на неё ссылаются прошлые части.
    -- Цвета из части 1 создавались неглубокой копией таблицы.
    -- Поэтому заводские значения RGB храним здесь отдельно.
    local factoryColors = {
        weatherColor = {180, 220, 255},
        trailColor = {45, 220, 255},
        auraColor = {115, 95, 255},
        magicColor = {155, 100, 255}
    }
    local function resetAllVisuals()
        if not active then return end
        for key, defaultValue in pairs(visualDefaults) do
            visuals[key] = type(defaultValue) == "table"
                and table.clone(defaultValue) or defaultValue
        end

        for key, originalRGB in pairs(factoryColors) do
            visuals[key] = table.clone(originalRGB)
        end

        -- Откат визуальных ограничений, освещения, погоды и аур.
        if setFpsVisualMode then
            setFpsVisualMode("off", false)
        else
            applyVisualLighting()
            applyWeather()
            if refreshAuraVisuals then refreshAuraVisuals() end
        end
        removeLiveTrail()
        if extrasAPI.resetExtras then extrasAPI.resetExtras() end

        -- Обновляем доступные статусы и выбранные цвета.
        if updateLightStatus then updateLightStatus() end
        if weatherStatus and weatherStatus.Parent then
            weatherStatus.Text = "Погода: Выключено"
        end
        if refreshColorEditor then refreshColorEditor() end
        saveSettings()
        status("Визуалы сброшены. Перезапусти меню для обновления тумблеров.")
    end

    -- ===== ПОСЛЕДНЯЯ КАРТОЧКА ВИЗУАЛОВ =====
    local resetCard, resetInside = uiCard(
        "visuals", "↺  УПРАВЛЕНИЕ ВИЗУАЛАМИ", 193
    )
    uiLabel(resetInside,
        "Сбросит погоду, небо, следы, ауры, освещение и FPS Boost.",
        0, 41)
    uiButton(resetInside, "↺  Сбросить все визуальные эффекты",
        49, resetAllVisuals, C.red)
    uiLabel(resetInside,
        "Параметры Aimbot, ESP и персонажа останутся без изменений.",
        97, 38)

    -- ===== ДИАГНОСТИКА ОБОЛОЧКИ =====
    local diagnosticCard, diagnosticInside = uiCard(
        "home", "✓  СОСТОЯНИЕ СБОРКИ", 159
    )
    local diagnosticText = uiStatus(
        diagnosticInside, "Модули: первичная проверка...", 0
    )
    local function checkInterface()
        local tests = {
            {"Окно", menu.Parent == gui},
            {"Вкладки", pages.visuals ~= nil and pages.flight ~= nil},
            {"Персонаж", pages.character ~= nil},
            {"ESP", pages.esp ~= nil},
            {"Aimbot", pages.aim ~= nil},
            {"Погода", weatherHost ~= nil and weatherHost.Parent ~= nil},
            {"Ауры", type(refreshAuraVisuals) == "function"},
            {"FPS Boost", type(setFpsVisualMode) == "function"}
        }
        local passed = 0
        local failedNames = {}
        for _, test in ipairs(tests) do
            if test[2] then
                passed = passed + 1
            else
                table.insert(failedNames, test[1])
            end
        end
        diagnosticText.Text = string.format(
            "Объекты интерфейса: %d/%d", passed, #tests
        )
        if #failedNames > 0 then
            diagnosticText.Text = diagnosticText.Text
                .. " | Не найдены: " .. table.concat(failedNames, ", ")
        end
        return passed == #tests
    end
    uiButton(diagnosticInside, "Проверить объекты интерфейса", 38,
        function()
            local passed = checkInterface()
            status(passed
                and "Объекты найдены; игровые функции проверь вручную."
                or "Некоторые объекты не найдены — смотри диагностику.")
        end, cyan)
    uiLabel(diagnosticInside,
        "Проверка объектов НЕ заменяет тест функций в Roblox.",
        83, 34)

    -- =====================================================================
    -- NEON EDITION 2.5 | SKETCH REPLICA VISUAL SYSTEM
    -- Референс: второй утверждённый пользователем неоновый макет.
    -- Все старые игровые модули, связи и настройки оставляем на месте.
    -- Новый ESP-экран — альтернативное представление тех же настроек.
    -- =====================================================================
    ;(function()
        local HOT = Color3.fromRGB(247, 31, 252)
        local ICE = Color3.fromRGB(0, 229, 255)
        local BLUE = Color3.fromRGB(64, 84, 255)
        local WHITE = Color3.fromRGB(252, 249, 255)
        local BACK = Color3.fromRGB(3, 5, 27)
        local TILE = Color3.fromRGB(7, 9, 39)
        local SILVER = Color3.fromRGB(198, 202, 247)
        local renderActive = true
        local function makeLabel(parent, text, position, size, color, font, textSize, z)
            return new("TextLabel", parent, {
                Position = position, Size = size, BackgroundTransparency = 1,
                Text = text, TextColor3 = color or WHITE,
                Font = font or Enum.Font.GothamBold, TextSize = textSize or 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = z or 13
            })
        end
        local function edge(object, col, fade, thick)
            return stroke(object, col or ICE, fade or 0.06, thick or 1.9)
        end
        local function glass(parent, position, size, col, z)
            local f = new("Frame", parent, {
                Position = position, Size = size,
                BackgroundColor3 = col or TILE, BorderSizePixel = 0,
                BackgroundTransparency = 0.02, ZIndex = z or 12,
                ClipsDescendants = false
            })
            corner(f, 12)
            edge(f, Color3.fromRGB(99, 90, 255), 0.13, 1.45)
            return f
        end
        local function hotGlow(object, color, radius)
            local haloFrame = new("Frame", object, {
                Name = "SketchHalo", Position = UDim2.fromOffset(-2, -2),
                Size = UDim2.new(1, 4, 1, 4),
                BackgroundTransparency = 1, BorderSizePixel = 0,
                ZIndex = math.max(1, (object.ZIndex or 5) - 1)
            })
            corner(haloFrame, radius or 12)
            edge(haloFrame, color, 0.86, 6)
            return haloFrame
        end
        -- Заголовок из эскиза: два оттенка, корона, яркое стекло.
        header.BackgroundColor3 = BACK
        menu.BackgroundColor3 = BACK
        menuStroke.Color = ICE
        menuStroke.Thickness = 3
        neonBackdrop.BackgroundColor3 = BACK
        headerEmblem.Text = "♛"
        headerEmblem.TextSize = 29
        headerEmblem.BackgroundColor3 = Color3.fromRGB(9, 4, 42)
        headerEmblem.TextColor3 = ICE
        headerEmblem.Position = UDim2.fromOffset(11, 9)
        headerEmblem.Size = UDim2.fromOffset(46, 43)
        dragArea.Text = "ОТ ТИМКИ"
        dragArea.TextColor3 = WHITE
        dragArea.TextStrokeColor3 = HOT
        dragArea.TextStrokeTransparency = 0.56
        dragArea.Position = UDim2.fromOffset(71, 0)
        dragArea.Size = UDim2.fromOffset(171, 62)
        dragArea.TextSize = 20
        hotGlow(headerEmblem, ICE, 14)
        local edition = makeLabel(header, "NEON EDITION 2.5",
            UDim2.fromOffset(243, 13), UDim2.fromOffset(240, 39),
            HOT, Enum.Font.GothamBold, 19, 10)
        edition.TextStrokeColor3 = HOT
        edition.TextStrokeTransparency = .58
        local logoLightning = makeLabel(header, "◢",
            UDim2.fromOffset(48, 31), UDim2.fromOffset(24, 25),
            ICE, Enum.Font.GothamBold, 20, 11)
        local crown = makeLabel(header, "♛",
            UDim2.fromOffset(81, -5), UDim2.fromOffset(41, 26),
            HOT, Enum.Font.GothamBold, 20, 11)
        crown.TextStrokeColor3 = ICE
        crown.TextStrokeTransparency = .54
        local fpsOutline = edge(extrasAPI.fpsLabel, HOT, 0.09, 1.5)
        extrasAPI.fpsLabel.TextColor3 = ICE
        extrasAPI.fpsLabel.BackgroundColor3 = Color3.fromRGB(8, 6, 38)
        minimizeButton.BackgroundColor3 = Color3.fromRGB(11, 7, 48)
        closeButton.BackgroundColor3 = Color3.fromRGB(30, 5, 54)
        edge(minimizeButton, HOT, 0.05, 1.5)
        edge(closeButton, HOT, 0.04, 1.6)
        hotGlow(closeButton, HOT, 10)

        -- Отдельные слои свечения: только на фоне, чтобы не затемнять текст.
        local topNeon = new("Frame", menu, {
            Name = "SketchTopNeon", Position = UDim2.fromOffset(7, 0),
            Size = UDim2.new(1, -14, 0, 3), BackgroundColor3 = HOT,
            BorderSizePixel = 0, ZIndex = 4
        })
        gradient(topNeon, HOT, ICE, 0)
        local botNeon = new("Frame", menu, {
            Name = "SketchBottomNeon", Position = UDim2.new(0, 9, 1, -3),
            Size = UDim2.new(1, -18, 0, 2), BackgroundColor3 = ICE,
            BorderSizePixel = 0, ZIndex = 4
        })
        gradient(botNeon, ICE, HOT, 0)
        for i = 1, 8 do
            local beam = new("Frame", neonBackdrop, {
                Name = "SketchEnergyBeam"..i,
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new((i - 1) / 7, 0, .51, 0),
                Size = UDim2.new(0, i%3==0 and 10 or 3, 1.55, 0),
                BackgroundColor3 = i%2 == 0 and HOT or ICE,
                BackgroundTransparency = i%3==0 and .955 or .91,
                Rotation = 39, BorderSizePixel = 0, ZIndex = 1
            })
            new("UIGradient", beam, {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0,1),
                    NumberSequenceKeypoint.new(.35,.45),
                    NumberSequenceKeypoint.new(.63,.15),
                    NumberSequenceKeypoint.new(1,1)
                })
            })
        end
        -- Боковая полоса и карточки: RGB-рамки и чёткий контраст.
        sidebar.BackgroundColor3 = Color3.fromRGB(5, 6, 29)
        sidebar.ScrollBarImageColor3 = HOT
        local sidebarOutline = sidebar:FindFirstChildOfClass("UIStroke")
        if sidebarOutline then sidebarOutline.Color = HOT; sidebarOutline.Transparency = .30 end
        for pageId, nav in pairs(navButtons) do
            nav.TextColor3 = WHITE
            nav.Font = Enum.Font.GothamBold
            nav.TextSize = 13
            nav.TextXAlignment = Enum.TextXAlignment.Left
            nav.BackgroundColor3 = Color3.fromRGB(8, 7, 40)
            local outline = nav:FindFirstChildOfClass("UIStroke")
            if outline then
                outline.Color = BLUE
                outline.Thickness = 1.35
                outline.Transparency = 0.20
            end
            local shine = new("Frame", nav, {
                Name = "NeonNavShine", Position = UDim2.fromOffset(2, 3),
                Size = UDim2.new(0, 3, 1, -6),
                BackgroundColor3 = pageId=="esp" and HOT or ICE,
                BackgroundTransparency = .34, BorderSizePixel = 0
            })
            corner(shine, 2)
        end
        contentTitle.Font = Enum.Font.GothamBold
        contentTitle.TextColor3 = WHITE
        contentTitle.TextSize = 23
        local pageHeaderLine = new("Frame", content, {
            Name = "SketchSectionUnderline", Position = UDim2.fromOffset(0, 33),
            Size = UDim2.new(1, -5, 0, 2),
            BackgroundColor3 = ICE, BorderSizePixel = 0, ZIndex = 5
        })
        gradient(pageHeaderLine, ICE, HOT, 0)
        for _, page in pairs(pages) do
            page.ScrollBarImageColor3 = HOT
            for _, card in ipairs(page:GetChildren()) do
                if card:IsA("Frame") and card.Name:match("^Card_") then
                    card.BackgroundColor3 = Color3.fromRGB(5, 8, 36)
                    local outline = card:FindFirstChildOfClass("UIStroke")
                    if outline then
                        outline.Color = Color3.fromRGB(129, 95, 255)
                        outline.Transparency = .21
                        outline.Thickness = 1.5
                    end
                    local accent = card:FindFirstChild("CardNeonAccent")
                    if accent then accent.BackgroundTransparency = .12 end
                    for _, field in ipairs(card:GetDescendants()) do
                        if field:IsA("TextButton") then
                            field.Font = Enum.Font.GothamBold
                            field.TextColor3 = WHITE
                            local s = field:FindFirstChildOfClass("UIStroke")
                            if s and s.Transparency > .35 then
                                s.Transparency = .25
                            end
                        elseif field:IsA("TextBox") then
                            field.TextColor3 = WHITE
                        end
                    end
                end
            end
        end
        -- Resize bar and title respond to the same landscape window.
        local function updateHeadSize()
            if not active then return end
            local width = menu.AbsoluteSize.X
            local small = width < 610
            edition.Visible = not small
            crown.Visible = not small
            dragArea.TextSize = width < 540 and 14 or (width < 720 and 17 or 20)
            dragArea.Size = UDim2.fromOffset(small and (width-232) or 174, 62)
            headerEmblem.Visible = width >= 400
            if width < 420 then
                dragArea.Position = UDim2.fromOffset(19,0)
            else
                dragArea.Position = UDim2.fromOffset(71,0)
            end
        end
        connect(menu:GetPropertyChangedSignal("AbsoluteSize"), updateHeadSize)
        task.defer(updateHeadSize)

        -- Полный ESP-экран по эскизу: слева настройки, справа палитра.
        -- Существующие более подробные настройки открываются через кнопку.
        local dash = new("Frame", content, {
            Name = "SketchESPPage", Position = UDim2.fromOffset(0,0),
            Size = UDim2.fromScale(1,1), BackgroundColor3 = BACK,
            BackgroundTransparency = .03, BorderSizePixel = 0,
            Visible = false, ClipsDescendants = true, ZIndex = 12
        })
        corner(dash, 12)
        local dashTitle = makeLabel(dash, "⊕  ESP",
            UDim2.fromOffset(8,1), UDim2.new(.48,0,0,35),
            WHITE, Enum.Font.GothamBold, 25, 14)
        makeLabel(dash, "Настройка отображения игроков",
            UDim2.fromOffset(12,36), UDim2.new(.70,0,0,18),
            SILVER, Enum.Font.Gotham, 11, 14)
        local dashboardTopToggle = new("TextButton", dash, {
            Name="SketchMainESPSwitch",
            AnchorPoint = Vector2.new(1,0),
            Position = UDim2.new(1,-10,0,10),
            Size = UDim2.fromOffset(132,34),
            BackgroundColor3 = Color3.fromRGB(46, 11, 81),
            TextColor3 = WHITE, Font = Enum.Font.GothamBold,
            TextSize = 12, AutoButtonColor = false, ZIndex = 14
        })
        corner(dashboardTopToggle, 14)
        edge(dashboardTopToggle,HOT,.05,1.8)
        local underHeader = new("Frame",dash,{
            Position = UDim2.fromOffset(8,59),
            Size = UDim2.new(1,-16,0,2),
            BackgroundColor3=ICE, BorderSizePixel=0, ZIndex=14
        })
        gradient(underHeader,ICE,HOT,0)
        local dashScroller = new("ScrollingFrame",dash,{
            Name="SketchESPScroll", Position=UDim2.fromOffset(6,65),
            Size=UDim2.new(1,-12,1,-70),
            BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=3, ScrollBarImageColor3=HOT,
            CanvasSize=UDim2.fromOffset(0,397),
            ScrollingDirection=Enum.ScrollingDirection.Y, ZIndex=13
        })
        local lPane = glass(dashScroller,UDim2.fromOffset(4,4),
            UDim2.new(.51,-8,0,283),TILE,14)
        local rPane = glass(dashScroller,UDim2.new(.53,0,0,4),
            UDim2.new(.47,-7,0,283),TILE,14)
        local lTitle = makeLabel(lPane,"ИГРОКИ",
            UDim2.fromOffset(13,6),UDim2.new(1,-26,0,24),
            ICE,Enum.Font.GothamBold,13,16)
        local rTitle = makeLabel(rPane,"◉  ЦВЕТ И СТИЛЬ",
            UDim2.fromOffset(10,6),UDim2.new(1,-20,0,24),
            WHITE,Enum.Font.GothamBold,13,16)
        local renderRows = {}
        local function setESP2D(key, value)
            if key == "espEnabled" then
                if extrasAPI.setESPEnabled then extrasAPI.setESPEnabled(value) end
            else
                settings[key] = value
                saveSettings()
            end
        end
        local function makeSwitch(y, symbol, name, sub, key)
            local row = glass(lPane,UDim2.fromOffset(7,y),
                UDim2.new(1,-14,0,49),Color3.fromRGB(6,13,43),15)
            local outline = row:FindFirstChildOfClass("UIStroke")
            if outline then outline.Color=Color3.fromRGB(66,100,230); outline.Transparency=.16 end
            local sig = new("TextLabel",row,{
                Position=UDim2.fromOffset(6,5), Size=UDim2.fromOffset(40,40),
                BackgroundColor3=Color3.fromRGB(10,7,44), Text=symbol,
                TextColor3=ICE, Font=Enum.Font.GothamBold,TextSize=22,ZIndex=17
            })
            corner(sig,10)
            edge(sig,ICE,.19,1.35)
            makeLabel(row,name,UDim2.fromOffset(51,5),
                UDim2.new(1,-110,0,22),WHITE,Enum.Font.GothamBold,12,17)
            makeLabel(row,sub,UDim2.fromOffset(51,27),
                UDim2.new(1,-112,0,16),SILVER,Enum.Font.Gotham,9,17)
            local sw = new("TextButton",row,{
                AnchorPoint=Vector2.new(1,.5),
                Position=UDim2.new(1,-9,.5,0),
                Size=UDim2.fromOffset(49,26),
                BackgroundColor3=Color3.fromRGB(37,36,83),
                Text="",AutoButtonColor=false,ZIndex=18
            })
            corner(sw,14)
            edge(sw,HOT,.24,1)
            local thumb = new("Frame",sw,{
                Size=UDim2.fromOffset(20,20),
                Position=UDim2.fromOffset(3,3),
                BackgroundColor3=WHITE,BorderSizePixel=0,ZIndex=19
            })
            corner(thumb,11)
            local function render(animate)
                local enabled = settings[key] == true
                if key ~= "espEnabled" then enabled = settings[key] ~= false end
                local pos=UDim2.fromOffset(enabled and 26 or 3,3)
                local bg=enabled and HOT or Color3.fromRGB(37,36,83)
                if animate then
                    tween(sw,.18,{BackgroundColor3=bg})
                    tween(thumb,.2,{Position=pos},Enum.EasingStyle.Back)
                else
                    sw.BackgroundColor3=bg
                    thumb.Position=pos
                end
            end
            connect(sw.Activated,function()
                local state=(key == "espEnabled") and settings[key]==true
                    or (key ~= "espEnabled" and settings[key]~=false)
                setESP2D(key,not state)
                render(true)
            end)
            renderRows[key]=render
            render(false)
        end
        makeSwitch(36,"▣","ESP 2D (рамки)","Контур игроков","espBoxes")
        makeSwitch(91,"╱","Линии","Линии к игрокам","espTracers")
        makeSwitch(146,"♡","HP (здоровье)","Полоска здоровья","espHealth")
        makeSwitch(201,"Aa","Ники","Имена игроков","espNames")
        local palette = {
            {255,255,255},{255,42,65},{255,20,216},{255,105,24},{255,227,25},
            {25,245,63},{0,227,186},{0,223,255},{23,87,254},{158,20,241}
        }
        local swatchButtons={}
        local colorChannels={}
        local hexField
        local colorPreview
        local function getRgb()
            if extrasAPI.getESPColor then return extrasAPI.getESPColor() end
            return settings.espColor or {255,255,255}
        end
        local function setRgb(rgb)
            if extrasAPI.setESPColor then extrasAPI.setESPColor(rgb) end
            if renderActive and hexField and hexField.Parent then
                local arr=getRgb()
                local value=string.format("#%02X%02X%02X",arr[1],arr[2],arr[3])
                if not hexField:IsFocused() then hexField.Text=value end
                if colorPreview then
                    colorPreview.BackgroundColor3=Color3.fromRGB(arr[1],arr[2],arr[3])
                end
                for index,item in ipairs(colorChannels) do
                    item.label.Text=({"R","G","B"})[index].."  "..arr[index]
                    item.fill.Size=UDim2.fromScale(arr[index]/255,1)
                    item.thumb.Position=UDim2.new(arr[index]/255,0,.5,0)
                end
                for i,btn in ipairs(swatchButtons) do
                    local rgb0=palette[i]
                    local selected=arr[1]==rgb0[1] and arr[2]==rgb0[2] and arr[3]==rgb0[3]
                    local border=btn:FindFirstChildOfClass("UIStroke")
                    if border then border.Thickness=selected and 3 or 1 end
                end
            end
        end
        for i,rgb in ipairs(palette) do
            local col=(i-1)%5
            local row=math.floor((i-1)/5)
            local sw = new("TextButton",rPane,{
                Position=UDim2.new(col*.196,7,0,36+row*37),
                Size=UDim2.new(.196,-10,0,29),
                BackgroundColor3=Color3.fromRGB(rgb[1],rgb[2],rgb[3]),
                Text="",BorderSizePixel=0,AutoButtonColor=false,ZIndex=18
            })
            corner(sw,7)
            edge(sw,WHITE,.3,1)
            swatchButtons[i]=sw
            connect(sw.Activated,function() setRgb(rgb) end)
        end
        colorPreview = new("Frame",rPane,{
            Position=UDim2.fromOffset(10,119),Size=UDim2.fromOffset(29,26),
            BackgroundColor3=WHITE,BorderSizePixel=0,ZIndex=16
        })
        corner(colorPreview,6)
        edge(colorPreview,ICE,.1,1.5)
        hexField = new("TextBox",rPane,{
            Position=UDim2.new(0,45,0,119),
            Size=UDim2.new(1,-55,0,26),
            BackgroundColor3=Color3.fromRGB(5,6,31),
            Text="#FFFFFF",TextColor3=WHITE,PlaceholderText="#FFFFFF",
            ClearTextOnFocus=false,Font=Enum.Font.Code,TextSize=13,
            BorderSizePixel=0,ZIndex=18
        })
        corner(hexField,6)
        edge(hexField,HOT,.14,1.4)
        connect(hexField.FocusLost,function()
            local raw=hexField.Text:match("^%s*#?([%x]+)%s*$")
            if raw and #raw==3 then
                raw=raw:sub(1,1):rep(2)..raw:sub(2,2):rep(2)..raw:sub(3,3):rep(2)
            end
            if raw and #raw==6 then
                setRgb({tonumber(raw:sub(1,2),16),
                    tonumber(raw:sub(3,4),16), tonumber(raw:sub(5,6),16)})
            else
                setRgb(getRgb())
            end
        end)
        for index=1,3 do
            local y=162+(index-1)*37
            local row = new("Frame",rPane,{
                Position=UDim2.fromOffset(9,y),
                Size=UDim2.new(1,-18,0,29),BackgroundTransparency=1,ZIndex=16
            })
            local label=makeLabel(row,"R  255",UDim2.fromOffset(2,1),
                UDim2.fromOffset(48,26),WHITE,Enum.Font.GothamBold,11,17)
            local track=new("TextButton",row,{
                Position=UDim2.fromOffset(50,10),
                Size=UDim2.new(1,-58,0,10),
                BackgroundColor3=Color3.fromRGB(27,25,82),
                Text="",AutoButtonColor=false,ZIndex=18
            })
            corner(track,6)
            local fill = new("Frame",track,{
                Size=UDim2.fromScale(1,1),BorderSizePixel=0,
                BackgroundColor3=({HOT,ICE,BLUE})[index],ZIndex=18
            })
            corner(fill,6)
            gradient(fill,({HOT,ICE,BLUE})[index],WHITE,0)
            local thumb=new("Frame",track,{
                AnchorPoint=Vector2.new(.5,.5),
                Position=UDim2.new(1,0,.5,0),
                Size=UDim2.fromOffset(13,17),
                BackgroundColor3=WHITE,BorderSizePixel=0,ZIndex=19
            })
            corner(thumb,7)
            colorChannels[index]={label=label,fill=fill,thumb=thumb}
            local held
            local function setByX(px)
                local fraction=math.clamp((px-track.AbsolutePosition.X)/
                    math.max(track.AbsoluteSize.X,1),0,1)
                local arr=getRgb()
                arr[index]=math.floor(fraction*255+.5)
                setRgb(arr)
            end
            connect(track.InputBegan,function(inp)
                if inp.UserInputType==Enum.UserInputType.Touch
                    or inp.UserInputType==Enum.UserInputType.MouseButton1 then
                    held=inp
                    setByX(inp.Position.X)
                end
            end)
            connect(UIS.InputChanged,function(inp)
                if not held then return end
                local touch=held.UserInputType==Enum.UserInputType.Touch
                if (touch and inp==held) or (not touch and
                    inp.UserInputType==Enum.UserInputType.MouseMovement) then
                    setByX(inp.Position.X)
                end
            end)
            connect(UIS.InputEnded,function(inp)
                if held==inp then held=nil end
            end)
        end
        local resetESP=new("TextButton",dashScroller,{
            Position=UDim2.fromOffset(4,300),
            Size=UDim2.new(.52,-8,0,39),
            BackgroundColor3=Color3.fromRGB(30,5,77),
            Text="↺  СБРОСИТЬ ESP",TextColor3=WHITE,
            TextSize=13,Font=Enum.Font.GothamBold,
            AutoButtonColor=false,ZIndex=16
        })
        corner(resetESP,12)
        edge(resetESP,HOT,.02,2)
        hotGlow(resetESP,HOT,12)
        local advancedBtn=new("TextButton",dashScroller,{
            Position=UDim2.new(.53,0,0,300),
            Size=UDim2.new(.47,-7,0,39),
            BackgroundColor3=Color3.fromRGB(3,22,65),
            Text="⚙  ВСЕ НАСТРОЙКИ ESP",TextColor3=WHITE,
            TextSize=11,Font=Enum.Font.GothamBold,
            TextWrapped=true,AutoButtonColor=false,ZIndex=16
        })
        corner(advancedBtn,12)
        edge(advancedBtn,ICE,.02,2)
        local statusLine=makeLabel(dashScroller,"●  Готов к работе   ◈  NEON EDITION",
            UDim2.fromOffset(8,354),UDim2.new(1,-16,0,19),
            Color3.fromRGB(65,247,142),Enum.Font.Gotham,11,16)
        local advanced=false
        local function renderDash()
            for _,render in pairs(renderRows) do render(false) end
            dashboardTopToggle.Text=settings.espEnabled and "●  ESP ВКЛ" or "○  Включить ESP"
            dashboardTopToggle.BackgroundColor3=settings.espEnabled and
                Color3.fromRGB(113,15,164) or Color3.fromRGB(32,13,59)
            setRgb(getRgb())
        end
        connect(dashboardTopToggle.Activated,function()
            setESP2D("espEnabled",not (settings.espEnabled==true))
            renderDash()
            statusLine.Text=settings.espEnabled and "●  ESP включён"
                or "○  ESP выключен"
        end)
        connect(resetESP.Activated,function()
            for _,key in ipairs({"espBoxes","espTracers","espHealth","espNames"}) do
                settings[key]=true
            end
            setESP2D("espEnabled",false)
            setRgb({255,255,255})
            renderDash()
            saveSettings()
            statusLine.Text="↺  Настройки ESP восстановлены"
        end)
        local oldPageHandler=setPage
        local function applyDashboard(pageId)
            local show=(pageId=="esp" and not advanced)
            dash.Visible=show
            pageHost.Visible=not show
            contentTitle.Visible=not show
            pageHeaderLine.Visible=not show
            if show then renderDash() end
        end
        connect(advancedBtn.Activated,function()
            advanced=true
            dash.Visible=false
            pageHost.Visible=true
            contentTitle.Visible=true
            pageHeaderLine.Visible=true
            status("Открыты расширенные настройки ESP")
        end)
        setPage=function(id)
            if id~="esp" then advanced=false end
            if id=="esp" and currentPage~="esp" then advanced=false end
            oldPageHandler(id)
            applyDashboard(id)
        end
        -- Исходная выбранная страница может сохраниться при редизайне.
        applyDashboard(currentPage)
        -- Подстройка обеих колонок под ширину окна.
        local function fitDashboard()
            local width=content.AbsoluteSize.X
            local narrow=width<420
            if narrow then
                lPane.Position=UDim2.fromOffset(4,4)
                lPane.Size=UDim2.new(1,-12,0,283)
                rPane.Position=UDim2.fromOffset(4,296)
                rPane.Size=UDim2.new(1,-12,0,283)
                resetESP.Position=UDim2.fromOffset(4,591)
                resetESP.Size=UDim2.new(1,-12,0,39)
                advancedBtn.Position=UDim2.fromOffset(4,638)
                advancedBtn.Size=UDim2.new(1,-12,0,39)
                statusLine.Position=UDim2.fromOffset(8,693)
                dashScroller.CanvasSize=UDim2.fromOffset(0,724)
            else
                lPane.Position=UDim2.fromOffset(4,4)
                lPane.Size=UDim2.new(.51,-8,0,283)
                rPane.Position=UDim2.new(.53,0,0,4)
                rPane.Size=UDim2.new(.47,-7,0,283)
                resetESP.Position=UDim2.fromOffset(4,300)
                resetESP.Size=UDim2.new(.52,-8,0,39)
                advancedBtn.Position=UDim2.new(.53,0,0,300)
                advancedBtn.Size=UDim2.new(.47,-7,0,39)
                statusLine.Position=UDim2.fromOffset(8,354)
                dashScroller.CanvasSize=UDim2.fromOffset(0,391)
            end
            renderDash()
        end
        connect(content:GetPropertyChangedSignal("AbsoluteSize"),fitDashboard)
        task.defer(fitDashboard)
        registerCleanup(function() renderActive=false end)
    end)()


    -- ===== КРАТКАЯ ЗАСТАВКА ПОСЛЕ ЗАГРУЗКИ =====
    local splash = new("TextLabel", gui, {
        Name = "TimkaNeonSplash",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.78, 0, 0, 76),
        BackgroundColor3 = C.base,
        BackgroundTransparency = 1,
        Text = "◆  ОТ ТИМКИ  |  NEON EDITION",
        TextColor3 = cyan,
        TextTransparency = 1,
        TextScaled = true,
        Font = Enum.Font.GothamBold,
        ZIndex = 60
    })
    new("UISizeConstraint", splash, {
        MaxSize = Vector2.new(400, 76)
    })
    corner(splash, 14)
    local splashOutline = stroke(splash, violet, 1, 2)
    task.spawn(function()
        task.wait(0.15)
        if not active or not splash.Parent then return end
        tween(splash, 0.25, {
            TextTransparency = 0, BackgroundTransparency = 0.08
        })
        tween(splashOutline, 0.25, {Transparency = 0.1})
        task.wait(1.1)
        if not active or not splash.Parent then return end
        tween(splash, 0.3, {
            TextTransparency = 1, BackgroundTransparency = 1
        })
        tween(splashOutline, 0.3, {Transparency = 1})
        task.wait(0.35)
        if splash.Parent then splash:Destroy() end
    end)

    -- Первичная самопроверка после создания всех страниц.
    checkInterface()
    print("ОТ ТИМКИ | NEON EDITION: загрузка завершена")

-- Закрываем xpcall(function() из ЧАСТИ 1.
end, function(message)
    if debug and debug.traceback then
        return debug.traceback(tostring(message), 2)
    end
    return tostring(message)
end)

-- Сообщение загрузки не должно исчезать при ошибке.
if ok then
    if bootGui.Parent then bootGui:Destroy() end
else
    if cleanupOnFailure then pcall(cleanupOnFailure) end
    warn("ОТ ТИМКИ | NEON EDITION: " .. tostring(err))
    if bootGui.Parent and bootText.Parent then
        bootText.TextColor3 = Color3.fromRGB(255, 125, 135)
        bootText.Text = "ОШИБКА ЗАПУСКА\n\n"
            .. string.sub(tostring(err), 1, 950)
            .. "\n\nПришли скриншот этой ошибки."
    end
end
