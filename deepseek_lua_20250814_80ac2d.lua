local Players = game:GetService("Players")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

-- Ваши приватные сервера (полные ссылки)
local SERVER_LINKS = {
    "https://www.roblox.com/games/1537690962/Bee-Swarm-Simulator?privateServerLinkCode=13144669790150978796525156034582",
    "https://www.roblox.com/games/1537690962/Bee-Swarm-Simulator?privateServerLinkCode=05152044821246125845196560137248"
}

-- Создаем простой интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(0, 300, 0, 50)
textLabel.Position = UDim2.new(0, 10, 0, 10)
textLabel.BackgroundTransparency = 0.7
textLabel.TextScaled = true
textLabel.Text = "Мониторинг времени..."
textLabel.Parent = screenGui

local function joinServer(serverLink)
    if GuiService then
        GuiService:OpenBrowserWindow(serverLink)
    else
        -- Альтернатива для некоторых эксплоитов
        game:GetService("StarterGui"):SetCore("PromptBlockPlayer", {
            Title = "Переход на сервер",
            Text = "Нажмите OK для перехода",
            Duration = 5
        })
        task.wait(2)
        local success = pcall(function()
            HttpService:RequestAsync({
                Url = serverLink,
                Method = "GET"
            })
        end)
        if not success then
            textLabel.Text = "Ошибка открытия ссылки"
        end
    end
end

local function checkTime()
    while task.wait(1) do
        local currentTime = os.date("%H:%M:%S")
        local minutes = tonumber(os.date("%M"))
        
        textLabel.Text = "Текущее время: "..currentTime
        
        if minutes == 56 then
            textLabel.Text = "Переход на Сервер 1..."
            joinServer(SERVER_LINKS[1])
            task.wait(60) -- Защита от повтора
        elseif minutes == 31 then
            textLabel.Text = "Переход на Сервер 2..."
            joinServer(SERVER_LINKS[2])
            task.wait(60) -- Защита от повтора
        end
    end
end

coroutine.wrap(checkTime)()
