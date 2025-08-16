local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- Настройки серверов (только коды)
local SERVER_CODES = {
    SERVER_1 = "13144669790150978796525156034582",
    SERVER_2 = "05152044821246125845196560137248"
}

-- Создаем интерфейс
local ScreenGui = Instance.new("ScreenGui")
local TextLabel = Instance.new("TextLabel")

ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

TextLabel.Parent = ScreenGui
TextLabel.Size = UDim2.new(0, 300, 0, 60)
TextLabel.Position = UDim2.new(0, 10, 0, 10)
TextLabel.BackgroundTransparency = 0.7
TextLabel.BackgroundColor3 = Color3.new(0, 0, 0)
TextLabel.TextColor3 = Color3.new(1, 1, 1)
TextLabel.TextScaled = true
TextLabel.Text = "Ожидание времени перехода..."

local function teleportToServer(serverCode)
    local placeId = 1537690962  -- ID Bee Swarm Simulator
    local teleportOptions = Instance.new("TeleportOptions")
    teleportOptions.ShouldReserveServer = false
    
    local success, errorMsg = pcall(function()
        TeleportService:TeleportToPrivateServer(
            placeId,
            serverCode,
            player.UserId,
            teleportOptions
        )
    end)
    
    if not success then
        warn("Ошибка телепортации: " .. tostring(errorMsg))
        TextLabel.Text = "Ошибка: " .. tostring(errorMsg)
        return false
    end
    return true
end

local function checkTime()
    while task.wait(1) do
        local currentTime = os.date("%H:%M:%S")
        local minutes = tonumber(os.date("%M"))
        
        TextLabel.Text = "Текущее время: " .. currentTime
        
        -- В 56 минут → первый сервер
        if minutes == 56 then
            TextLabel.Text = "Переход на Сервер 1..."
            if teleportToServer(SERVER_CODES.SERVER_1) then
                task.wait(60)  -- Защита от повторного срабатывания
            end
        end
        
        -- В 02 минуты → второй сервер
        if minutes == 21 then
            TextLabel.Text = "Переход на Сервер 2..."
            if teleportToServer(SERVER_CODES.SERVER_2) then
                task.wait(60)  -- Защита от повторного срабатывания
            end
        end
    end
end

coroutine.wrap(checkTime)()
