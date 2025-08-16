local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- Настройки серверов
local SERVER_SETTINGS = {
    {
        code = "13144669790150978796525156034582",
        name = "Сервер 1"
    },
    {
        code = "05152044821246125845196560137248",
        name = "Сервер 2"
    }
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

local function createTeleportOptions()
    local options = Instance.new("TeleportOptions")
    options.ShouldReserveServer = false
    options.ServerInstanceId = "" -- Оставьте пустым для приватных серверов
    return options
end

local function safeTeleport(placeId, serverCode)
    local options = createTeleportOptions()
    
    local success, err = pcall(function()
        TeleportService:TeleportToPrivateServer(
            placeId,
            serverCode,
            player.UserId,
            options
        )
    end)
    
    if not success then
        warn("Ошибка телепортации: "..tostring(err))
        TextLabel.Text = "Ошибка: "..tostring(err)
        return false
    end
    return true
end

local function checkTime()
    while task.wait(1) do
        local currentTime = os.date("%H:%M:%S")
        local minutes = tonumber(os.date("%M"))
        
        TextLabel.Text = "Текущее время: "..currentTime
        
        -- В 56 минут → первый сервер
        if minutes == 56 then
            TextLabel.Text = "Переход на "..SERVER_SETTINGS[1].name
            if safeTeleport(1537690962, SERVER_SETTINGS[1].code) then
                task.wait(60)
            end
        end
        
        -- В 02 минуты → второй сервер
        if minutes == 28 then
            TextLabel.Text = "Переход на "..SERVER_SETTINGS[2].name
            if safeTeleport(1537690962, SERVER_SETTINGS[2].code) then
                task.wait(60)
            end
        end
    end
end

coroutine.wrap(checkTime)()
