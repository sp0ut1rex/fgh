local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

--- Конфигурация ---
local Config = {
    GlitterArgs = { { Name = "Glitter" } },
    Whitelist = {
        ["2908768899"] = { name = "BlueFlower", fieldPosition = Vector3.new(139.61, 4.00, 97.26) },
        ["2908769190"] = { name = "PineTree", fieldPosition = Vector3.new(-332.0, 68.00, -194.90) },
        ["2908768829"] = { name = "Bamboo", fieldPosition = Vector3.new(116.43, 20.00, -21.75) }
    },
    BoostSettings = {
        DelayBeforeAction = 14 * 60, -- 14 минут
        ScanInterval = 5,            -- Проверка каждые 5 сек
        FreezeDuration = 1           -- Фиксация на 1 секунду
    }
}

--- Системные переменные ---
local ActiveBoosts = {}
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")
local isPositionLocked = false
local originalCFrame = nil

--- Логирование ---
local function log(message)
    print("[BOOST SYSTEM]: " .. message)
end

--- Отменяет все твины и блокирует перемещение ---
local function lockPosition(targetCFrame)
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- 1. Отменяем все активные твины
    for _, tween in ipairs(TweenService:GetActiveTweens()) do
        if tween.Instance:IsDescendantOf(character) then
            tween:Cancel()
        end
    end

    -- 2. Фиксируем позицию
    isPositionLocked = true
    originalCFrame = rootPart.CFrame
    rootPart.Anchored = true
    rootPart.CFrame = targetCFrame

    -- 3. Защита от изменений в реальном времени
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if isPositionLocked and rootPart then
            rootPart.CFrame = targetCFrame
        else
            connection:Disconnect()
        end
    end)

    return connection
end

--- Разблокирует перемещение ---
local function unlockPosition(connection)
    if connection then
        connection:Disconnect()
    end
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.Anchored = false
    end
    isPositionLocked = false
end

--- Основное действие: телепорт + glitter ---
local function doBoostAction(boostData)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local targetCFrame = CFrame.new(boostData.fieldPosition)
    local connection = lockPosition(targetCFrame)
    log("Телепортирован на поле " .. boostData.name)

    -- Ждем 1 секунду (фиксация позиции)
    task.wait(Config.BoostSettings.FreezeDuration)

    -- Используем Glitter
    pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
        log("Glitter использован")
    end)

    -- Разблокируем перемещение
    unlockPosition(connection)
end

--- Таймер для буста ---
local function startBoostTimer(boostId, boostData)
    log("Обнаружен буст: " .. boostData.name)
    task.wait(Config.BoostSettings.DelayBeforeAction)
    doBoostAction(boostData)
    ActiveBoosts[boostId] = nil
end

--- Сканирование бустов ---
local function scanBoosts()
    local gui = player:WaitForChild("PlayerGui")
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
            coroutine.wrap(startBoostTimer)(id, Config.Whitelist[id])
        end
    end
end

--- Обработчик респавна ---
player.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

--- Запуск ---
log("Система активирована")
while true do
    pcall(scanBoosts)
    task.wait(Config.BoostSettings.ScanInterval)
end