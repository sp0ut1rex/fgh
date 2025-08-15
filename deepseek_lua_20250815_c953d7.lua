local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Конфигурация
local Config = {
    GlitterArgs = { { Name = "Glitter" } },
    Whitelist = {
        ["2908768899"] = { name = "BlueFlower", fieldPosition = Vector3.new(139.61, 4.00, 97.26) },
        ["2908769190"] = { name = "PineTree", fieldPosition = Vector3.new(-332.0, 68.00, -194.90) },
        ["2908768829"] = { name = "Bamboo", fieldPosition = Vector3.new(116.43, 20.00, -21.75) }
    },
    Settings = {
        Delay = 1 * 60, -- 14 минут ожидания
        ScanRate = 5,    -- Проверка каждые 5 сек
        TweenTime = 3    -- Длительность полета
    }
}

-- Система
local ActiveBoosts = {}
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")

-- Логирование
local function log(msg)
    print("[BOOSTER]: " .. os.date("%H:%M:%S") .. " | " .. msg)
end

-- Жесткая телепортация с защитой
local function secureTeleport(position)
    local originalState = rootPart.Anchored
    rootPart.Anchored = true
    rootPart.CFrame = CFrame.new(position)
    
    -- Критическая задержка
    for _ = 1, 10 do  -- 10 попыток по 0.1 сек
        task.wait(0.1)
        rootPart.CFrame = CFrame.new(position)  -- Постоянная фиксация
    end
    
    return originalState
end

-- Основная функция буста
local function activateBoost(boostData)
    -- 1. Жесткая телепортация
    local originalAnchored = secureTeleport(boostData.fieldPosition)
    log("Телепортация на " .. boostData.name)
    
    -- 2. Гарантированный Glitter
    local success, err = pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
    end)
    
    if success then
        log("Glitter активирован")
    else
        warn("Ошибка Glitter: " .. tostring(err))
    end
    
    -- 3. Плавное восстановление
    task.wait(1)  -- Дополнительная фиксация
    rootPart.Anchored = originalAnchored
end

-- Сканер бустов
local function scanBoosts()
    local gui = player:WaitForChild("PlayerGui")
    local screenGui = gui:FindFirstChild("ScreenGui")
    if not screenGui then return end

    for _, iconTile in ipairs(screenGui:GetDescendants()) do
        if iconTile:IsA("ImageButton") and not iconTile:FindFirstChild("Tracked") then
            local id = tostring(iconTile.Image):match("rbxassetid://(%d+)")
            if id and Config.Whitelist[id] then
                local marker = Instance.new("BoolValue")
                marker.Name = "Tracked"
                marker.Parent = iconTile
                
                ActiveBoosts[id] = true
                task.delay(Config.Settings.Delay, function()
                    activateBoost(Config.Whitelist[id])
                    ActiveBoosts[id] = nil
                end)
                log(Config.Whitelist[id].name .. " в очереди")
            end
        end
    end
end

-- Запуск
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

while true do
    pcall(scanBoosts)
    task.wait(Config.Settings.ScanRate)
end
