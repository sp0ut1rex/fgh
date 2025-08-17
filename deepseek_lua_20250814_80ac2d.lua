local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local GlitterEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand")

--- Конфиг с 3 ПОЛЯМИ ---
local Config = {
    GlitterArgs = { { Name = "Glitter" } },
    Fields = {
        ["2908768899"] = { -- BlueFlower
            name = "BlueFlower",
            position = Vector3.new(139.61, 4.00, 97.26),
            flightTime = 3.5,
            freezeTime = 1.5
        },
        ["2908769190"] = { -- PineTree
            name = "PineTree", 
            position = Vector3.new(-332.0, 68.00, -194.90),
            flightTime = 4,
            freezeTime = 1.5
        },
        ["2908768829"] = { -- Bamboo
            name = "Bamboo",
            position = Vector3.new(116.43, 20.00, -21.75),
            flightTime = 3,
            freezeTime = 1.5
        }
    },
    Settings = {
        WaitBeforeUse = 14 * 60, -- Ожидание 14 минут
        ScanInterval = 5         -- Проверка каждые 5 сек
    }
}

--- Системные переменные ---
local ActiveBoosts = {}
local PausedTweens = {}
local IsOperating = false

--- Логирование ---
local function Log(msg)
    print("[BOOSTER]: "..os.date("%H:%M:%S").." | "..msg)
end

--- Блокировка конфликтующих твинов ---
local function PauseOtherTweens()
    PausedTweens = {}
    for _, tween in ipairs(TweenService:GetActiveTweens()) do
        if tween.Instance:IsDescendantOf(character) then
            PausedTweens[tween] = {
                state = tween.PlaybackState,
                cf = tween.Instance.CFrame
            }
            tween:Pause()
            Log("Приостановлен твин: "..tween.Instance:GetFullName())
        end
    end
end

--- Восстановление твинов ---
local function ResumeOtherTweens()
    for tween, data in pairs(PausedTweens) do
        if data.state == Enum.PlaybackState.Playing then
            tween.Instance.CFrame = data.cf
            tween:Play()
        end
    end
    PausedTweens = {}
end

--- Плавный полет ---
local function SmoothFlight(target)
    IsOperating = true
    PauseOtherTweens()
    
    local startPos = rootPart.Position
    local startTime = tick()
    local endTime = startTime + target.flightTime
    
    -- Heartbeat-based движение
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local now = tick()
        local progress = math.min(1, (now - startTime) / target.flightTime)
        rootPart.CFrame = CFrame.new(startPos:Lerp(target.position, progress))
        
        if now >= endTime then
            conn:Disconnect()
            rootPart.CFrame = CFrame.new(target.position)
        end
    end)
    
    task.wait(target.flightTime)
    if conn then conn:Disconnect() end
    IsOperating = false
end

--- Основная функция ---
local function UseBoost(field)
    -- Полет
    Log("Полет на "..field.name)
    SmoothFlight({
        position = field.position,
        flightTime = field.flightTime
    })
    
    -- Фиксация + Glitter
    rootPart.Anchored = true
    pcall(function()
        GlitterEvent:FireServer(unpack(Config.GlitterArgs))
        Log("Glitter использован")
    end)
    
    -- Ожидание перед разблокировкой
    task.wait(field.freezeTime)
    rootPart.Anchored = false
    ResumeOtherTweens()
end

--- Сканер бустов ---
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
                Log("Найден буст: "..Config.Fields[id].name)
                
                task.delay(Config.Settings.WaitBeforeUse, function()
                    UseBoost(Config.Fields[id])
                    ActiveBoosts[id] = nil
                end)
            end
        end
    end
end

--- Запуск ---
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

while true do
    pcall(ScanBoosts)
    task.wait(Config.Settings.ScanInterval)
end
