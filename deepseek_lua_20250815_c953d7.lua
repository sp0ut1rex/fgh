local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

--- Конфигурация (ВСЕ ПОЛЯ ВНЕСЕНЫ) ---
local Config = {
    GlitterArgs = { { Name = "Glitter" } },
    Whitelist = {
        ["2908768899"] = {  -- BlueFlower
            name = "BlueFlower",
            fieldPosition = Vector3.new(139.61, 4.00, 97.26),
            tweenDuration = 3.5  -- Индивидуальное время полёта
        },
        ["2908769190"] = {  -- PineTree
            name = "PineTree", 
            fieldPosition = Vector3.new(-332.0, 68.00, -194.90),
            tweenDuration = 4
        },
        ["2908768829"] = {  -- Bamboo
            name = "Bamboo",
            fieldPosition = Vector3.new(116.43, 20.00, -21.75),
            tweenDuration = 3
        }
    },
    BoostSettings = {
        DelayBeforeAction = 14 * 60,  -- 14 минут ожидания
        ScanInterval = 5,             -- Проверка каждые 5 сек
        FreezeDuration = 1            -- Фиксация после прилёта
    }
}

--- Системные переменные ---
local ActiveBoosts = {}
local ActiveTweens = {}  -- Для ручного управления твинами
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")

--- Логирование ---
local function log(message)
    print("[BOOST SYSTEM]: " .. os.date("%H:%M:%S") .. " | " .. message)
end

--- Отслеживание твинов (альтернатива GetActiveTweens) ---
local function trackTween(tween)
    table.insert(ActiveTweens, tween)
    tween.Completed:Connect(function()
        for i, v in ipairs(ActiveTweens) do
            if v == tween then
                table.remove(ActiveTweens, i)
                break
            end
        end
    end)
end

--- Отмена ВСЕХ твинов персонажа ---
local function cancelAllCharacterTweens()
    for i = #ActiveTweens, 1, -1 do
        local tween = ActiveTweens[i]
        if tween.Instance:IsDescendantOf(character) then
            tween:Cancel()
            table.remove(ActiveTweens, i)
        end
    end
end

--- Плавный полёт с защитой ---
local function smoothFlyTo(boostData)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end

    local rootPart = character.HumanoidRootPart
    local targetCFrame = CFrame.new(boostData.fieldPosition)
    
    -- 1. Отменяем конфликтующие твины
    cancelAllCharacterTweens()

    -- 2. Создаём новый твин
    local tweenInfo = TweenInfo.new(
        boostData.tweenDuration or 3,  -- Индивидуальное время для каждого поля
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    trackTween(tween)
    tween:Play()

    -- 3. Ждём завершения
    local success = pcall(function()
        tween.Completed:Wait()
        task.wait(Config.BoostSettings.FreezeDuration)  -- Фиксация позиции
    end)

    return success
end

--- Сканирование бустов ---
local function scanBoosts()
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return end

    local screenGui = gui:FindFirstChild("ScreenGui")
    if not screenGui then return end

    local tileGrid = screenGui:FindFirstChild("TileGrid")
    if not tileGrid then return end

    for _, iconTile in ipairs(tileGrid:GetChildren()) do
        if iconTile:FindFirstChild("Tracked") then continue end

        local bg = iconTile:FindFirstChild("BG")
        if not bg then continue end

        local icon = bg:FindFirstChildOfClass("ImageButton")
        if not icon then continue end

        local id = tostring(icon.Image):match("rbxassetid://(%d+)")
        if not id or not Config.Whitelist[id] then continue end

        -- Помечаем буст как обработанный
        local marker = Instance.new("BoolValue")
        marker.Name = "Tracked"
        marker.Parent = iconTile

        -- Запускаем таймер
        if not ActiveBoosts[id] then
            ActiveBoosts[id] = true
            log("Буст " .. Config.Whitelist[id].name .. " добавлен в очередь")

            task.delay(Config.BoostSettings.DelayBeforeAction, function()
                log("Начало выполнения буста: " .. Config.Whitelist[id].name)
                smoothFlyTo(Config.Whitelist[id])
                ActiveBoosts[id] = nil
            end)
        end
    end
end

--- Обработчик респавна ---
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    log("Персонаж перезагружен")
end)

--- Запуск системы ---
log("Система активирована")
while true do
    pcall(scanBoosts)
    task.wait(Config.BoostSettings.ScanInterval)
end