-- ============================================================
-- KUKIRIN AUTO STANT | STABLE GUI + MOBILE OPTIMIZED
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- ASSUMPTION: Названия свойств скутера могут отличаться. Код пытается найти их по стандартным именам.
local AUTO_STANT_ENABLED = false
local MAX_SPEED_ENABLED = false
local CURRENT_SCOOTER = nil
local STANT_CONNECTION = nil

-- Функция для безопасного получения скутера (VehicleSeat)
local function getScooter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local seat = humanoid.SeatPart
    if seat and seat:IsA("VehicleSeat") then
        return seat
    end
    return nil
end

-- Эмуляция нажатия клавиши (безопасный fallback)
local function pressKey(keyCode, duration)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    end)
    task.wait(duration or 0.06)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- Попытка поднять переднее колесо через физику (HingeConstraint)
local function tryPhysicsStant(scooter)
    if not scooter then return false end
    local success = false
    pcall(function()
        -- Ищем HingeConstraint, отвечающий за наклон
        for _, constraint in pairs(scooter:GetDescendants()) do
            if constraint:IsA("HingeConstraint") then
                local name = constraint.Name:lower()
                if name:find("wheel") or name:find("tilt") or name:find("stant") or name:find("angle") then
                    constraint.TargetAngle = 75 -- максимальный угол подъёма
                    constraint.AngularVelocity = 0
                    constraint.MotorMaxTorque = math.huge
                    success = true
                end
            end
        end
        -- Альтернативный метод: BodyAngularVelocity
        local bodyAngular = scooter:FindFirstChildOfClass("BodyAngularVelocity")
        if bodyAngular then
            bodyAngular.AngularVelocity = Vector3.new(0, 0, math.rad(75))
            bodyAngular.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            success = true
        end
    end)
    return success
end

-- Сброс физики станта
local function resetPhysicsStant(scooter)
    if not scooter then return end
    pcall(function()
        for _, constraint in pairs(scooter:GetDescendants()) do
            if constraint:IsA("HingeConstraint") then
                local name = constraint.Name:lower()
                if name:find("wheel") or name:find("tilt") or name:find("stant") or name:find("angle") then
                    constraint.TargetAngle = 0
                end
            end
        end
        local bodyAngular = scooter:FindFirstChildOfClass("BodyAngularVelocity")
        if bodyAngular then
            bodyAngular.AngularVelocity = Vector3.zero
        end
    end)
end

-- Цикл Auto Stant
local function autoStantLoop()
    while AUTO_STANT_ENABLED do
        local scooter = getScooter()
        if scooter then
            local physicsOK = tryPhysicsStant(scooter)
            if not physicsOK then
                -- Fallback: эмуляция Shift (если физика не сработала)
                pressKey(Enum.KeyCode.LeftShift, 0.06)
            end
        end
        task.wait(0.05)
    end
    -- При выключении сбрасываем физику
    local scooter = getScooter()
    if scooter then
        resetPhysicsStant(scooter)
    end
end

-- Применить Max Speed
local function applyMaxSpeed()
    local scooter = getScooter()
    if scooter then
        pcall(function()
            scooter.MaxSpeed = 500
        end)
        pcall(function()
            local bodyVelocity = scooter:FindFirstChildOfClass("BodyVelocity")
            if bodyVelocity then
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.Velocity = scooter.CFrame.LookVector * 300
            end
        end)
    end
end

-- ======================== GUI =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KukirinStantGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Иконка для открытия/закрытия меню (перетаскиваемая)
local Icon = Instance.new("TextButton")
Icon.Size = UDim2.new(0, 60, 0, 60)
Icon.Position = UDim2.new(0, 20, 0, 100)
Icon.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Icon.Text = "🛴"
Icon.TextSize = 32
Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
Icon.BorderSizePixel = 0
Icon.Parent = ScreenGui
local iconCorner = Instance.new("UICorner", Icon)
iconCorner.CornerRadius = UDim.new(0, 15)

-- Основное меню (изначально скрыто, перетаскиваемое)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 320)
MainFrame.Position = UDim2.new(0, 20, 0, 180)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
local mainCorner = Instance.new("UICorner", MainFrame)
mainCorner.CornerRadius = UDim.new(0, 12)

-- Заголовок меню (перетаскивание за него)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Title.Text = "Kukirin Stant"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame
local titleCorner = Instance.new("UICorner", Title)
titleCorner.CornerRadius = UDim.new(0, 12)

-- Кнопка Auto Stant
local StantBtn = Instance.new("TextButton")
StantBtn.Size = UDim2.new(0.9, 0, 0, 50)
StantBtn.Position = UDim2.new(0.05, 0, 0, 60)
StantBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
StantBtn.Text = "Auto Stant: OFF"
StantBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StantBtn.TextSize = 18
StantBtn.Font = Enum.Font.Gotham
StantBtn.BorderSizePixel = 0
StantBtn.Parent = MainFrame
local stantCorner = Instance.new("UICorner", StantBtn)
stantCorner.CornerRadius = UDim.new(0, 10)

-- Кнопка Max Speed
local SpeedBtn = Instance.new("TextButton")
SpeedBtn.Size = UDim2.new(0.9, 0, 0, 50)
SpeedBtn.Position = UDim2.new(0.05, 0, 0, 125)
SpeedBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SpeedBtn.Text = "Max Speed: OFF"
SpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBtn.TextSize = 18
SpeedBtn.Font = Enum.Font.Gotham
SpeedBtn.BorderSizePixel = 0
SpeedBtn.Parent = MainFrame
local speedCorner = Instance.new("UICorner", SpeedBtn)
speedCorner.CornerRadius = UDim.new(0, 10)

-- Информационная метка
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0.9, 0, 0, 40)
InfoLabel.Position = UDim2.new(0.05, 0, 0, 190)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Сядь на скутер для активации"
InfoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
InfoLabel.TextSize = 14
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.Parent = MainFrame

-- ======================== ПЕРЕТАСКИВАНИЕ =========================
-- Перетаскивание иконки
local iconDragging, iconDragInput, iconDragStart, iconStartPos
Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = Icon.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                iconDragging = false
            end
        end)
    end
end)
Icon.InputChanged:Connect(function(input)
    if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - iconDragStart
        Icon.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
    end
end)

-- Перетаскивание меню за заголовок
local menuDragging, menuDragInput, menuDragStart, menuStartPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        menuDragging = true
        menuDragStart = input.Position
        menuStartPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                menuDragging = false
            end
        end)
    end
end)
Title.InputChanged:Connect(function(input)
    if menuDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - menuDragStart
        MainFrame.Position = UDim2.new(menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X, menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y)
    end
end)

-- Переключение видимости меню
Icon.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ======================== ОБРАБОТЧИКИ КНОПОК =========================
StantBtn.MouseButton1Click:Connect(function()
    AUTO_STANT_ENABLED = not AUTO_STANT_ENABLED
    StantBtn.Text = "Auto Stant: " .. (AUTO_STANT_ENABLED and "ON" or "OFF")
    StantBtn.BackgroundColor3 = AUTO_STANT_ENABLED and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 80)
    if AUTO_STANT_ENABLED then
        task.spawn(autoStantLoop)
    end
end)

SpeedBtn.MouseButton1Click:Connect(function()
    MAX_SPEED_ENABLED = not MAX_SPEED_ENABLED
    SpeedBtn.Text = "Max Speed: " .. (MAX_SPEED_ENABLED and "ON" or "OFF")
    SpeedBtn.BackgroundColor3 = MAX_SPEED_ENABLED and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 80)
    if MAX_SPEED_ENABLED then
        task.spawn(function()
            while MAX_SPEED_ENABLED do
                applyMaxSpeed()
                task.wait(0.5)
            end
        end)
    end
end)

-- ======================== RESPAWN =========================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    CURRENT_SCOOTER = nil
    if AUTO_STANT_ENABLED then task.spawn(autoStantLoop) end
end)

warn("[KUKIRIN] Скрипт загружен. Нажми на иконку 🛴, чтобы открыть меню.")
