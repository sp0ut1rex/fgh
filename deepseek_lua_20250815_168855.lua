local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
        DelayBeforeAction = 14 * 60, -- Ждать 14 минут
        ScanInterval = 5              -- Проверка бустов каждые 5 сек
    }
}

--- Системные переменные ---
local ActiveBoosts = {}
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")

--- Логирование ---
local function log(message)
    print("[BOOST SYSTEM]: " .. message)
end

--- Телепортация + Glitter ---
local function doBoostAction(boostData)
    -- Телепортация
    if character and character:FindFirstChild("HumanoidRootPart") then
        pcall(function()
            character.HumanoidRootPart.CFrame = CFrame.new(boostData.fieldPosition)
            log("Телепортирован на поле " .. boostData.name)
        end)
    end

    -- Glitter
    pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
        log("Glitter использован")
    end)
end

--- Таймер для буста ---
local function startBoostTimer(boostId, boostData)
    log("Обнаружен буст: " .. boostData.name)
    
    task.wait(Config.BoostSettings.DelayBeforeAction) -- Ждём 14 минут
    
    doBoostAction(boostData) -- Телепорт + Glitter
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

        -- Пометить буст как обработанный
        local marker = Instance.new("BoolValue")
        marker.Name = "Tracked"
        marker.Parent = iconTile

        -- Запустить таймер
        if not ActiveBoosts[id] then
            ActiveBoosts[id] = true
            coroutine.wrap(startBoostTimer)(id, Config.Whitelist[id])
        end
    end
end

--- Основной цикл ---
log("Система активирована")
while true do
    pcall(scanBoosts)
    task.wait(Config.BoostSettings.ScanInterval)
end