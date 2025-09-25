local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Конфигурация
local Config = {
    GlitterArgs = { { Name = "Glitter" } },
    Fields = {
        ["2908768899"] = { -- BlueFlower
            name = "BlueFlower",
            position = Vector3.new(139.61, 4.00, 97.26),
            flightTime = 3.5
        },
        ["2908769190"] = { -- PineTree
            name = "PineTree",
            position = Vector3.new(-332.0, 68.00, -194.90),
            flightTime = 4
        }
    },
    Settings = {
        WaitTime = 14 * 60, -- 14 минут ожидания
        ScanDelay = 5,      -- Проверка каждые 5 сек
        FreezeAfter = 1     -- Стоять 1 сек после Glitter
    }
}

-- Система
local ActiveBoosts = {}
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")
local isFlying = false

-- Логирование
local function Log(message)
    print("[FLIGHT SYSTEM]: "..os.date("%H:%M:%S").." | "..message)
end

-- Плавный полет с защитой
local function SmoothFlight(targetPosition, duration)
    if isFlying then return false end
    isFlying = true
    
    -- Фиксация начальной позиции
    local startPos = rootPart.Position
    local startTime = tick()
    local endTime = startTime + duration
    
    -- Создаем соединение для плавного перемещения
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local progress = math.min(1, (currentTime - startTime) / duration)
        
        -- Плавное перемещение
        rootPart.CFrame = CFrame.new(
            startPos:Lerp(targetPosition, progress),
            targetPosition
        )
        
        -- Завершение полета
        if progress >= 1 then
            connection:Disconnect()
            isFlying = false
        end
    end)
    
    -- Ожидаем завершения
    repeat task.wait() until tick() >= endTime
    if connection then connection:Disconnect() end
    return true
end

-- Основная функция буста
local function UseBoost(boostData)
    -- Плавный полет
    Log("Начинаю полет на "..boostData.name)
    SmoothFlight(boostData.position, boostData.flightTime)
    
    -- Фиксация после прилета
    rootPart.Anchored = true
    Log("Прибыл на поле, фиксирую позицию")
    
    -- Использование Glitter
    pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
        Log("Glitter успешно использован")
    end)
    
    -- Ожидание перед разблокировкой
    task.wait(Config.Settings.FreezeAfter)
    rootPart.Anchored = false
    Log("Завершено")
end

-- Сканер бустов
local function ScanBoosts()
    local gui = player:WaitForChild("PlayerGui")
    for _, element in ipairs(gui:GetDescendants()) do
        if element:IsA("ImageButton") and not element:FindFirstChild("Processed") then
            local id = tostring(element.Image):match("rbxassetid://(%d+)")
            if id and Config.Fields[id] and not ActiveBoosts[id] then
                local marker = Instance.new("BoolValue")
                marker.Name = "Processed"
                marker.Parent = element
                
                ActiveBoosts[id] = true
                Log("Обнаружен буст: "..Config.Fields[id].name)
                
                task.delay(Config.Settings.WaitTime, function()
                    UseBoost(Config.Fields[id])
                    ActiveBoosts[id] = nil
                end)
            end
        end
    end
end

-- Обработчик респавна
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Главный цикл
while true do
    pcall(ScanBoosts)
    task.wait(Config.Settings.ScanDelay)
end
