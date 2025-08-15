local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

---=== СОЗДАЕМ ИНТЕРФЕЙС ===---
local gui = Instance.new("ScreenGui")
gui.Name = "Sp0ut1rexAutoFarm"
gui.Parent = player.PlayerGui
gui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 180)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -90) -- Центр экрана
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Text = "AUTO FARM by sp0ut1rex"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Parent = mainFrame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 70, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 120, 220))
})
gradient.Rotation = 90
gradient.Parent = title

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Text = "START"
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextSize = 14
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.4, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 150)
toggleBtn.TextColor3 = Color3.white
toggleBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Text = "Status: Ready"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0.7, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Parent = mainFrame

-- Добавляем кнопку закрытия в правом верхнем углу
local closeButton = Instance.new("TextButton")
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeButton.BorderSizePixel = 0
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

---=== КОНФИГУРАЦИЯ ===---
local Config = {
    GlitterArgs = { { Name = "Glitter" } },
    Whitelist = {
        ["2908768899"] = { name = "BlueFlower", fieldPosition = Vector3.new(139.61, 4.00, 97.26) },
        ["2908769190"] = { name = "PineTree", fieldPosition = Vector3.new(-332.0, 68.00, -194.90) },
        ["2908768829"] = { name = "Bamboo", fieldPosition = Vector3.new(116.43, 20.00, -21.75) }
    },
    BoostSettings = {
        DelayBeforeAction = 14 * 60, -- 14 минут ожидания
        ScanInterval = 5
    },
    ToggleKey = Enum.KeyCode.F, -- Клавиша для скрытия/показа интерфейса
    AnimationDuration = 0.3 -- Длительность анимации в секундах
}

---=== СИСТЕМНЫЕ ПЕРЕМЕННЫЕ ===---
local ActiveBoosts = {}
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")
local isRunning = false
local character = player.Character or player.CharacterAdded:Wait()
local isUIVisible = true

---=== ФУНКЦИИ ===---
local function updateStatus(text, color)
    statusLabel.Text = "Status: "..text
    statusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

local function teleportToField(position)
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(position)
        return true
    end
    return false
end

local function useGlitter()
    pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
    end)
end

local function startBoostProcess(boostData)
    updateStatus("Waiting 14min...", Color3.fromRGB(255, 200, 100))
    task.wait(Config.BoostSettings.DelayBeforeAction)
    
    updateStatus("Teleporting...", Color3.fromRGB(100, 200, 255))
    teleportToField(boostData.fieldPosition)
    
    updateStatus("Using Glitter", Color3.fromRGB(100, 255, 150))
    useGlitter()
    
    updateStatus("Completed!", Color3.fromRGB(100, 255, 100))
    task.wait(2)
    updateStatus("Ready")
end

local function toggleUI()
    isUIVisible = not isUIVisible
    
    if isUIVisible then
        -- Анимация появления (из прозрачного в видимый)
        mainFrame.Visible = true
        mainFrame.BackgroundTransparency = 1
        title.TextTransparency = 1
        toggleBtn.TextTransparency = 1
        statusLabel.TextTransparency = 1
        closeButton.TextTransparency = 1
        
        local tweenInfo = TweenInfo.new(Config.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        local tween1 = TweenService:Create(mainFrame, tweenInfo, {BackgroundTransparency = 0.15})
        local tween2 = TweenService:Create(title, tweenInfo, {TextTransparency = 0})
        local tween3 = TweenService:Create(toggleBtn, tweenInfo, {TextTransparency = 0})
        local tween4 = TweenService:Create(statusLabel, tweenInfo, {TextTransparency = 0})
        local tween5 = TweenService:Create(closeButton, tweenInfo, {TextTransparency = 0})
        
        tween1:Play()
        tween2:Play()
        tween3:Play()
        tween4:Play()
        tween5:Play()
    else
        -- Анимация исчезновения (из видимого в прозрачный)
        local tweenInfo = TweenInfo.new(Config.AnimationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        local tween1 = TweenService:Create(mainFrame, tweenInfo, {BackgroundTransparency = 1})
        local tween2 = TweenService:Create(title, tweenInfo, {TextTransparency = 1})
        local tween3 = TweenService:Create(toggleBtn, tweenInfo, {TextTransparency = 1})
        local tween4 = TweenService:Create(statusLabel, tweenInfo, {TextTransparency = 1})
        local tween5 = TweenService:Create(closeButton, tweenInfo, {TextTransparency = 1})
        
        tween1:Play()
        tween2:Play()
        tween3:Play()
        tween4:Play()
        tween5:Play()
        
        tween1.Completed:Wait()
        mainFrame.Visible = false
    end
end

---=== ОБРАБОТЧИКИ ===---
toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        toggleBtn.Text = "STOP"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        updateStatus("Scanning...", Color3.fromRGB(100, 200, 255))
    else
        toggleBtn.Text = "START"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 150)
        updateStatus("Paused", Color3.fromRGB(255, 150, 100))
    end
end)

closeButton.MouseButton1Click:Connect(function()
    toggleUI()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Config.ToggleKey then
        toggleUI()
    end
end)

---=== ОСНОВНОЙ ЦИКЛ ===---
coroutine.wrap(function()
    while true do
        if isRunning then
            local gui = player.PlayerGui:FindFirstChild("ScreenGui")
            if gui then
                local tileGrid = gui:FindFirstChild("TileGrid")
                if tileGrid then
                    for _, iconTile in ipairs(tileGrid:GetChildren()) do
                        if not iconTile:FindFirstChild("Tracked") then
                            local bg = iconTile:FindFirstChild("BG")
                            if bg then
                                local icon = bg:FindFirstChildOfClass("ImageButton")
                                if icon then
                                    local id = tostring(icon.Image):match("rbxassetid://(%d+)")
                                    if id and Config.Whitelist[id] and not ActiveBoosts[id] then
                                        ActiveBoosts[id] = true
                                        local marker = Instance.new("BoolValue")
                                        marker.Name = "Tracked"
                                        marker.Parent = iconTile
                                        startBoostProcess(Config.Whitelist[id])
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(Config.BoostSettings.ScanInterval)
    end
end)()

---=== ОБНОВЛЕНИЕ ПЕРСОНАЖА ===---
player.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

-- Инициализация интерфейса
toggleUI() -- Сначала скрываем
toggleUI() -- Затем показываем с анимацией