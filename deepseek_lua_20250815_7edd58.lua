local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

--- Конфигурация ---
local Config = {
    GlitterArgs = { { Name = "Glitter" } },
    Whitelist = {
        ["2908768899"] = {  -- BlueFlower
            name = "BlueFlower",
            fieldPosition = Vector3.new(139.61, 4.00, 97.26)
        },
        ["2908769190"] = {  -- PineTree
            name = "PineTree", 
            fieldPosition = Vector3.new(-332.0, 68.00, -194.90)
        },
        ["2908768829"] = {  -- Bamboo
            name = "Bamboo",
            fieldPosition = Vector3.new(116.43, 20.00, -21.75)
        }
    },
    BoostSettings = {
        DelayBeforeAction = 14 * 60, -- 14 минут ожидания
        ScanInterval = 5,            -- Проверка каждые 5 секунд
        FreezeDuration = 1           -- Фиксация позиции на 1 секунду
    }
}

--- Системные переменные ---
local ActiveBoosts = {}
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")

--- Логирование ---
local function log(message)
    print("[BOOST SYSTEM]: " .. message)
end

--- Отменяет все активные твины персонажа ---
local function cancelCharacterTweens()
    for _, tween in ipairs(TweenService:GetActiveTweens()) do
        if tween.Instance:IsDescendantOf(character) then
            tween:Cancel()
        end
    end
end

--- Фиксирует позицию персонажа на время ---
local function freezeCharacter(duration)
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    -- 1. Отменяем твины (только в момент телепортации)
    cancelCharacterTweens()

    -- 2. Фиксируем позицию (Anchored + защита от изменений)
    local originalAnchored = rootPart.Anchored
    rootPart.Anchored = true

    -- 3. Ждем указанное время
    task.wait(duration)

    -- 4. Восстанавливаем физику
    rootPart.Anchored = originalAnchored
end

--- Телепортация + Glitter ---
local function doBoostAction(boostData)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    -- Телепортация
    pcall(function()
        -- Отменяем твины только в этот момент
        cancelCharacterTweens()
        
        -- Фиксируем позицию на 1 секунду
        character.HumanoidRootPart.CFrame = CFrame.new(boostData.fieldPosition)
        log("Телепортирован на поле " .. boostData.name)
        freezeCharacter(Config.BoostSettings.FreezeDuration)
    end)

    -- Glitter (после разморозки)
    pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
        log("Glitter использован")
    end)
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

--- Основной цикл ---
log("Система активирована")
while true do
    pcall(scanBoosts)
    task.wait(Config.BoostSettings.ScanInterval)
end