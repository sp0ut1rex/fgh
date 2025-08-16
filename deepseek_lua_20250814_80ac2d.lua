local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- Коды приватных серверов (только код, без ссылки)
local PRIVATE_SERVER_1 = "13144669790150978796525156034582"
local PRIVATE_SERVER_2 = "05152044821246125845196560137248"

-- Создаем интерфейс для отображения времени
local ScreenGui = Instance.new("ScreenGui")
local TextLabel = Instance.new("TextLabel")

ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

TextLabel.Parent = ScreenGui
TextLabel.Size = UDim2.new(0, 250, 0, 50)
TextLabel.Position = UDim2.new(0, 10, 0, 10)
TextLabel.BackgroundTransparency = 0.5
TextLabel.BackgroundColor3 = Color3.new(0, 0, 0)
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.TextScaled = true
TextLabel.Text = "Мониторинг времени..."

local function teleportToServer(serverCode)
    local placeId = 1537690962 -- ID Bee Swarm Simulator
    local success, err = pcall(function()
        -- Правильный вызов TeleportToPrivateServer (3 аргумента)
        TeleportService:TeleportToPrivateServer(
            placeId,     -- ID игры
            serverCode,   -- Код приватного сервера
            player.UserId -- ID игрока (новый обязательный аргумент)
        )
    end)
    
    if not success then
        warn("❌ Ошибка телепорта: " .. err)
        TextLabel.Text = "Ошибка: " .. err
    else
        TextLabel.Text = "Успешно! Переход..."
    end
end

local function checkTime()
    while true do
        local currentTime = os.date("%H:%M:%S")
        local minutes = tonumber(os.date("%M"))
        
        TextLabel.Text = "Время: " .. currentTime
        
        -- В 56 минут → на первый сервер
        if minutes == 56 then
            TextLabel.Text = "Переход на сервер 1..."
            teleportToServer(PRIVATE_SERVER_1)
            wait(60) -- Защита от повторного срабатывания
        end
        
        -- В 02 минуты → на второй сервер
        if minutes == 16 then
            TextLabel.Text = "Переход на сервер 2..."
            teleportToServer(PRIVATE_SERVER_2)
            wait(60) -- Защита от повторного срабатывания
        end
        
        wait(1)
    end
end

coroutine.wrap(checkTime)()
