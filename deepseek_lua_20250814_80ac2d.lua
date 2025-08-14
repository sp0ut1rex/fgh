local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

--- Конфигурация ---
local Config = {
    GlitterArgs = { { Name = "Glitter" } },
    Whitelist = {
        ["2908768899"] = { name = "BlueFlower" },
        ["2908769190"] = { name = "PineTree" },
        ["2908768829"] = { name = "Bamboo" }
    },
    BoostSettings = {
        DelayBeforeGlitter = 14 * 60, -- 14 минут (в секундах)
        GlitterCount = 5, -- Количество использований Glitter
        GlitterInterval = 0.5 -- Интервал между использованиями (в секундах)
    },
    ScanInterval = 5
}

--- Системные переменные ---
local ActiveBoosts = {}
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")

--- Логирование ---
local function log(message)
    print("[BOOST SYSTEM]: " .. message)
end

--- Активация Glitter ---
local function useGlitter()
    local success, err = pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
    end)
    if success then
        log("Glitter активирован")
        return true
    else
        warn("Ошибка: " .. tostring(err))
        return false
    end
end

--- Таймер для Glitter ---
local function startGlitterTimer(boostId, boostName)
    task.delay(Config.BoostSettings.DelayBeforeGlitter, function()
        log("Активация Glitter для " .. boostName)
        
        for i = 1, Config.BoostSettings.GlitterCount do
            useGlitter()
            if i < Config.BoostSettings.GlitterCount then
                task.wait(Config.BoostSettings.GlitterInterval)
            end
        end
        
        log("Завершено 5 использований Glitter для " .. boostName)
        ActiveBoosts[boostId] = nil
    end)
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
            log("Обнаружен буст: " .. Config.Whitelist[id].name)
            startGlitterTimer(id, Config.Whitelist[id].name)
        end
    end
end

--- Основной цикл ---
log("Система активирована")
while true do
    local success, err = pcall(scanBoosts)
    if not success then warn("Ошибка сканирования: " .. err) end
    task.wait(Config.ScanInterval)
end