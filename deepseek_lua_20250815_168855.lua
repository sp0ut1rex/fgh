local player = game:GetService("Players").LocalPlayer
local VK_LINKS = { -- Используем VK как прокси для открытия ссылок
    [1] = "https://vk.com/away.php?to="..escape_url("https://www.roblox.com/games/1537690962/Bee-Swarm-Simulator?privateServerLinkCode=13144669790150978796525156034582"),
    [2] = "https://vk.com/away.php?to="..escape_url("https://www.roblox.com/games/1537690962/Bee-Swarm-Simulator?privateServerLinkCode=05152044821246125845196560137248")
}

-- Создаем кнопки для ручного перехода
local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.5, -150, 0.5, -75)
frame.Parent = gui

local function createBtn(text, pos, link)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = UDim2.new(0, 280, 0, 60)
    btn.Position = pos
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        game:GetService("GuiService"):OpenBrowserWindow(link)
    end)
end

createBtn("Сервер 1 (56 мин)", UDim2.new(0, 10, 0, 20), VK_LINKS[1])
createBtn("Сервер 2 (02 мин)", UDim2.new(0, 10, 0, 90), VK_LINKS[2])

-- Автоматический мониторинг времени
local timeLabel = Instance.new("TextLabel")
timeLabel.Text = os.date("%H:%M:%S")
timeLabel.Size = UDim2.new(0, 280, 0, 30)
timeLabel.Position = UDim2.new(0, 10, 0, 160)
timeLabel.Parent = gui

spawn(function()
    while wait(1) do
        timeLabel.Text = os.date("%H:%M:%S")
        local min = tonumber(os.date("%M"))
        if min == 56 then
            game:GetService("GuiService"):OpenBrowserWindow(VK_LINKS[1])
            wait(60)
        elseif min == 36 then
            game:GetService("GuiService"):OpenBrowserWindow(VK_LINKS[2])
            wait(60)
        end
    end
end)
