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
        DelayBeforeAction = 14 * 60, -- 14 минут ожидания
        ScanInterval = 5,            -- Проверка каждые 5 секунд
        TweenDuration = 3,           -- Длительность полёта
        FreezeDuration = 1           -- Фиксация после прилёта
    }
}

--- Системные переменные ---
local ActiveBoosts = {}
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")
local isOperating = false  -- Флаг для блокировки параллельных операций

--- Логирование ---
local function log(message)
    print("[BOOST SYSTEM]: " .. os.date("%H:%M:%S") .. " | " .. message)
end

--- Отмена всех твинов персонажа ---
local function cancelAllCharacterTweens()
    for _, tween in ipairs(TweenService:GetActiveTweens()) do
        if tween.Instance:IsDescendantOf(character) then
            tween:Cancel()
        end
    end
end

--- Жёсткая фиксация позиции ---
local function lockPosition(targetCFrame)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = character.HumanoidRootPart
    local originalAnchored = rootPart.Anchored
    
    -- 1. Отменяем все твины
    cancelAllCharacterTweens()
    
    -- 2. Фиксируем позицию
    rootPart.Anchored = true
    rootPart.CFrame = targetCFrame
    
    -- 3. Защита через Heartbeat
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not isOperating then connection:Disconnect() return end
        rootPart.CFrame = targetCFrame
    end)
    
    return function()
        if connection then connection:Disconnect() end
        rootPart.Anchored = originalAnchored
    end
end

--- Плавное перемещение с защитой ---
local function smoothFlyTo(targetCFrame)
    if not character or isOperating then return false end
    isOperating = true
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        isOperating = false
        return false
    end

    -- 1. Блокируем другие скрипты
    local unlock = lockPosition(rootPart.CFrame)
    if not unlock then
        isOperating = false
        return false
    end

    -- 2. Настраиваем твин
    local tweenInfo = TweenInfo.new(
        Config.BoostSettings.TweenDuration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local success, tween = pcall(function()
        return TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    end)
    
    if not success then
        unlock()
        isOperating = false
        log("Ошибка создания твина: " .. tween)
        return false
    end

    -- 3. Запускаем перемещение
    local completed = false
    tween.Completed:Connect(function()
        completed = true
    end)
    
    tween:Play()
    
    -- 4. Ждём завершения с таймаутом
    local startTime = os.time()
    while not completed and os.time() - startTime < Config.BoostSettings.TweenDuration + 2 do
        task.wait(0.1)
    end
    
    -- 5. Фиксация после прилёта
    task.wait(Config.BoostSettings.FreezeDuration)
    unlock()
    isOperating = false
    
    return true
end

--- Основная функция буста ---
local function executeBoost(boostData)
    if isOperating then
        log("Попытка запуска во время работы другой операции")
        return
    end
    
    log("Начало выполнения буста: " .. boostData.name)
    
    -- Плавный полёт
    local flySuccess = smoothFlyTo(CFrame.new(boostData.fieldPosition))
    if not flySuccess then
        log("Провал перемещения", true)
        return
    end
    
    -- Использование Glitter
    local glitterSuccess = pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
    end)
    
    if glitterSuccess then
        log("Glitter успешно использован")
    else
        log("Ошибка Glitter", true)
    end
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
        if not iconTile:IsA("Frame") or iconTile:FindFirstChild("Tracked") then continue end
        
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
            task.delay(Config.BoostSettings.DelayBeforeAction, function()
                executeBoost(Config.Whitelist[id])
                ActiveBoosts[id] = nil
            end)
            log("Буст " .. Config.Whitelist[id].name .. " добавлен в очередь")
        end
    end
end

--- Обработчик респавна ---
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    log("Персонаж перезагружен")
end)

--- Основной цикл ---
log("Система активирована")
while true do
    local success, err = pcall(scanBoosts)
    if not success then
        log("Ошибка сканирования: " .. err, true)
    end
    task.wait(Config.BoostSettings.ScanInterval)
end