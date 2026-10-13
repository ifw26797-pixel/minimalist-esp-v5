-- ====================================================================
-- ================= [ULTRA-MINIMALIST GUI & ESP V5] ==================
-- ====================================================================

if _G.MinimalistUIRunning then _G.MinimalistUIRunning = false end
task.wait(0.05)
_G.MinimalistUIRunning = true

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService        = game:GetService("TweenService")
local CoreGui             = game:GetService("CoreGui")
local Lighting            = game:GetService("Lighting")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local function Italic(str)
    return "<i>" .. tostring(str) .. "</i>"
end

local function Tween(instance, properties, duration)
    local tween = TweenService:Create(instance, TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

-- ====================================================================
-- ================= [КЭШИ И ДЕФОЛТНЫЕ ПАРАМЕТРЫ] =====================
-- ====================================================================

local OrigLighting = {
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime
}

local OrigAtmosphere = nil
local initAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if initAtmosphere then
    OrigAtmosphere = {
        Density = initAtmosphere.Density,
        Offset = initAtmosphere.Offset,
        Haze = initAtmosphere.Haze,
        Glare = initAtmosphere.Glare,
        Color = initAtmosphere.Color,
        Decay = initAtmosphere.Decay
    }
end

local OrigColorCorrection = nil
local initCC = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
if initCC then
    OrigColorCorrection = {
        Brightness = initCC.Brightness,
        Contrast = initCC.Contrast,
        Saturation = initCC.Saturation,
        TintColor = initCC.TintColor,
        Enabled = initCC.Enabled
    }
end

local OrigCamera = {
    FieldOfView = (workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70,
    MinZoom = (LP and LP.CameraMinZoomDistance) or 0.5,
    MaxZoom = (LP and LP.CameraMaxZoomDistance) or 128
}

local savedMouseBehavior = nil

-- Проверка матча
local function IsInMatch()
    local team = (LP.Team and LP.Team.Name:lower()) or ""
    if team:find("lobby") or team:find("spectator") or team == "" then
        return false
    end
    local hasMap = workspace:FindFirstChild("Map") ~= nil
    local hasGenerators = workspace:FindFirstChild("Generator", true) ~= nil
    return (hasMap or hasGenerators)
end

-- ====================================================================
-- ================= [ЦЕНТРАЛЬНАЯ СИСТЕМА КЕЙБИНДОВ] ==================
-- ====================================================================

local RegisteredKeybinds = {}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.Unknown then return end

    for _, bindData in ipairs(RegisteredKeybinds) do
        if bindData.Key == input.KeyCode and bindData.Toggle then
            bindData.Toggle()
        end
    end
end)

-- ====================================================================
-- ===================== [НАСТРОЙКИ И ДВИЖОК ESP] =====================
-- ====================================================================

local ESP_Config = {
    Me = {
        Enabled = false,
        OutlineColor = Color3.fromRGB(255, 255, 255),
        OutlineTransparency = 0.2,
        FillColor = Color3.fromRGB(74, 255, 181),
        FillTransparency = 0.6,
        Type = "AlwaysOnTop"
    },
    Survivors = {
        Enabled = false,
        OutlineColor = Color3.fromRGB(64, 224, 255),
        OutlineTransparency = 0.2,
        FillColor = Color3.fromRGB(0, 180, 255),
        FillTransparency = 0.65,
        Type = "AlwaysOnTop",
        Distance = 450,
        ShowName = true,
        ShowDistance = true,
        ShowItem = false,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextOutlineColor = Color3.fromRGB(0, 0, 0)
    },
    Killers = {
        Enabled = false,
        OutlineColor = Color3.fromRGB(255, 65, 65),
        OutlineTransparency = 0.1,
        FillColor = Color3.fromRGB(200, 20, 20),
        FillTransparency = 0.5,
        Type = "AlwaysOnTop",
        Distance = 600,
        CustomKillerlight = true,
        ShowName = true,
        ShowDistance = true,
        TextColor = Color3.fromRGB(255, 75, 75),
        TextOutlineColor = Color3.fromRGB(0, 0, 0)
    },
    Pallets = {
        Enabled = false,
        OutlineColor = Color3.fromRGB(74, 255, 181),
        OutlineTransparency = 0.2,
        FillColor = Color3.fromRGB(74, 255, 181),
        FillTransparency = 0.7,
        Type = "AlwaysOnTop",
        ShowName = true,
        ShowDistance = false,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextOutlineColor = Color3.fromRGB(0, 0, 0)
    },
    Windows = {
        Enabled = false,
        OutlineColor = Color3.fromRGB(74, 255, 181),
        OutlineTransparency = 0.2,
        FillColor = Color3.fromRGB(74, 255, 181),
        FillTransparency = 0.7,
        Type = "AlwaysOnTop",
        ShowName = true,
        ShowDistance = false,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextOutlineColor = Color3.fromRGB(0, 0, 0)
    },
    Hooks = {
        Enabled = false,
        OutlineColor = Color3.fromRGB(132, 255, 169),
        OutlineTransparency = 0.2,
        FillColor = Color3.fromRGB(132, 255, 169),
        FillTransparency = 0.7,
        Type = "AlwaysOnTop",
        ShowName = true,
        ShowDistance = false,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextOutlineColor = Color3.fromRGB(0, 0, 0)
    },
    Generators = {
        Enabled = false,
        OutlineColor = Color3.fromRGB(200, 100, 255),
        OutlineTransparency = 0.2,
        FillColor = Color3.fromRGB(150, 0, 200),
        FillTransparency = 0.65,
        Type = "AlwaysOnTop",
        ShowName = true,
        ShowDistance = true,
        ShowProgress = true,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextOutlineColor = Color3.fromRGB(0, 0, 0)
    }
}

local ESP_Cache = {
    Objects = { Pallets = {}, Windows = {}, Hooks = {}, Generators = {} }
}

local function GetDepthMode(typeStr)
    return (typeStr == "Occluded") and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
end

local function ApplyHighlight(target, cfg)
    if not target or not target.Parent then return end
    local hl = target:FindFirstChild("ESPHighlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "ESPHighlight"
        hl.Adornee = target
        hl.Parent = target
    end
    hl.Enabled = cfg.Enabled
    hl.FillColor = cfg.FillColor
    hl.OutlineColor = cfg.OutlineColor
    hl.FillTransparency = cfg.FillTransparency
    hl.OutlineTransparency = cfg.OutlineTransparency
    hl.DepthMode = GetDepthMode(cfg.Type)
    return hl
end

local function ApplyBillboard(target, adorneePart, cfg, textContent)
    if not target or not target.Parent or not adorneePart then return end
    local bb = target:FindFirstChild("ESPTag")
    if not bb then
        bb = Instance.new("BillboardGui")
        bb.Name = "ESPTag"
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 140, 0, 30)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.Adornee = adorneePart

        local lbl = Instance.new("TextLabel", bb)
        lbl.Name = "Label"
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 10
        lbl.RichText = true
        lbl.TextWrapped = true
        bb.Parent = target
    end

    local lbl = bb:FindFirstChild("Label")
    if lbl then
        lbl.Text = Italic(textContent)
        lbl.TextColor3 = cfg.TextColor or Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeColor3 = cfg.TextOutlineColor or Color3.fromRGB(0, 0, 0)
        lbl.TextStrokeTransparency = 0.2
    end
    bb.Enabled = cfg.Enabled
    return bb
end

local function CleanupESP(instance)
    if not instance then return end
    local hl = instance:FindFirstChild("ESPHighlight")
    if hl then hl.Enabled = false end
    local bb = instance:FindFirstChild("ESPTag")
    if bb then bb.Enabled = false end
end

local function ScanMap()
    for _, list in pairs(ESP_Cache.Objects) do table.clear(list) end
    local windowModelSet = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Pallet" or obj.Name == "Palletwrong" then
            table.insert(ESP_Cache.Objects.Pallets, obj)
        elseif obj.Name == "VaultTrigger" and obj:IsA("BasePart") then
            local parentModel = obj.Parent
            if parentModel and not windowModelSet[parentModel] then
                windowModelSet[parentModel] = true
                table.insert(ESP_Cache.Objects.Windows, parentModel)
            end
        elseif obj.Name == "Window" then
            if not windowModelSet[obj] then
                windowModelSet[obj] = true
                table.insert(ESP_Cache.Objects.Windows, obj)
            end
        elseif obj.Name == "Hook" then
            table.insert(ESP_Cache.Objects.Hooks, obj)
        elseif obj.Name == "Generator" then
            table.insert(ESP_Cache.Objects.Generators, obj)
        end
    end
end
ScanMap()

workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "Pallet" or obj.Name == "Palletwrong" then table.insert(ESP_Cache.Objects.Pallets, obj)
    elseif obj.Name == "VaultTrigger" and obj:IsA("BasePart") then
        local p = obj.Parent
        if p and not table.find(ESP_Cache.Objects.Windows, p) then table.insert(ESP_Cache.Objects.Windows, p) end
    elseif obj.Name == "Window" then
        if not table.find(ESP_Cache.Objects.Windows, obj) then table.insert(ESP_Cache.Objects.Windows, obj) end
    elseif obj.Name == "Hook" then table.insert(ESP_Cache.Objects.Hooks, obj)
    elseif obj.Name == "Generator" then table.insert(ESP_Cache.Objects.Generators, obj) end
end)

-- Рендер ESP в Heartbeat
RunService.Heartbeat:Connect(function()
    if not _G.MinimalistUIRunning then return end

    local inMatch = IsInMatch()
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if not inMatch or not myRoot then
        CleanupESP(myChar)
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then CleanupESP(p.Character) end end
        for _, list in pairs(ESP_Cache.Objects) do
            for _, o in ipairs(list) do CleanupESP(o) end
        end
        return
    end

    local myPos = myRoot.Position

    -- Me ESP
    if ESP_Config.Me.Enabled and myChar then
        ApplyHighlight(myChar, ESP_Config.Me)
    else
        CleanupESP(myChar)
    end

    -- Survivors & Killers
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local char = p.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - myPos).Magnitude
                local pTeam = (p.Team and p.Team.Name:lower()) or ""
                local isKiller = pTeam:find("killer") ~= nil or p:GetAttribute("SelectedKiller") ~= nil
                local cfg = isKiller and ESP_Config.Killers or ESP_Config.Survivors

                if cfg.Enabled and dist <= cfg.Distance then
                    ApplyHighlight(char, cfg)
                    local txt = ""
                    if cfg.ShowName then txt = txt .. p.DisplayName end
                    if cfg.ShowDistance then txt = txt .. "\n[" .. math.floor(dist) .. "m]" end
                    if not isKiller and cfg.ShowItem then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool then txt = txt .. "\n<font color=\"#ffffaa\">" .. tool.Name .. "</font>" end
                    end
                    ApplyBillboard(char, root, cfg, txt)
                else
                    CleanupESP(char)
                end
            end
        end
    end

    -- Objects ESP (Бесконечная дистанция)
    local function ProcessObjList(list, cfg, dName, hasProg)
        for i = #list, 1, -1 do
            local obj = list[i]
            if obj and obj.Parent then
                local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
                if part then
                    local dist = (part.Position - myPos).Magnitude
                    if cfg.Enabled then
                        ApplyHighlight(obj, cfg)
                        local txt = ""
                        if cfg.ShowName then txt = txt .. dName end
                        if cfg.ShowDistance then txt = txt .. "\n[" .. math.floor(dist) .. "m]" end
                        if hasProg and cfg.ShowProgress then
                            local prog = obj:GetAttribute("RepairProgress") or obj:GetAttribute("Progress") or 0
                            if prog <= 1 and prog > 0 then prog = prog * 100 end
                            txt = txt .. string.format("\n[%.0f%%]", prog)
                        end
                        ApplyBillboard(obj, part, cfg, txt)
                    else
                        CleanupESP(obj)
                    end
                end
            else
                table.remove(list, i)
            end
        end
    end

    ProcessObjList(ESP_Cache.Objects.Pallets, ESP_Config.Pallets, "Pallet", false)
    ProcessObjList(ESP_Cache.Objects.Windows, ESP_Config.Windows, "Window", false)
    ProcessObjList(ESP_Cache.Objects.Hooks, ESP_Config.Hooks, "Hook", false)
    ProcessObjList(ESP_Cache.Objects.Generators, ESP_Config.Generators, "Generator", true)
end)

-- ====================================================================
-- =================== [КАМЕРА: РАЗДЕЛЬНЫЕ МОДУЛИ] ====================
-- ====================================================================

local CamConfig = {
    FOV = { Enabled = false, Value = 120 },
    AspectRatio = { Enabled = false, Value = 0.65 },
    Zoom = { Enabled = false, Value = 8 }
}

-- ====================================================================
-- ==================== [СВЕТ И ОКРУЖАЮЩИЙ МИР] =======================
-- ====================================================================

local WorldSettings = {
    RemoveFog = false,
    Fullbright = false
}

RunService.RenderStepped:Connect(function()
    if not _G.MinimalistUIRunning then return end

    -- 1. Камера
    local cam = workspace.CurrentCamera
    if cam then
        if CamConfig.FOV.Enabled then
            cam.FieldOfView = CamConfig.FOV.Value
        end

        if CamConfig.AspectRatio.Enabled then
            cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, CamConfig.AspectRatio.Value, 0, 0, 0, 1)
        end
    end

    if CamConfig.Zoom.Enabled and LP then
        LP.CameraMaxZoomDistance = CamConfig.Zoom.Value
        LP.CameraMinZoomDistance = CamConfig.Zoom.Value
    end

    -- 2. Принудительное удержание тумана (Remove Fog) каждый кадр
    if WorldSettings.RemoveFog then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
        local at = Lighting:FindFirstChildOfClass("Atmosphere")
        if at then
            at.Density = 0
            at.Haze = 0
        end
    end
end)

-- ====================================================================
-- =============== [ДИНАМИЧЕСКИЙ СПИДБУСТ В HEARTBEAT] ================
-- ====================================================================

local SpeedSettings = {
    Enabled = false,
    Percent = 15,
    BaseFallback = 16
}

local lastAppliedSpeed = nil
local detectedGameSpeed = 16

RunService.Heartbeat:Connect(function()
    if not _G.MinimalistUIRunning then return end

    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        lastAppliedSpeed = nil
        return
    end

    if SpeedSettings.Enabled then
        local currentSpeed = hum.WalkSpeed
        if lastAppliedSpeed == nil or math.abs(currentSpeed - lastAppliedSpeed) > 0.05 then
            detectedGameSpeed = (currentSpeed > 0) and currentSpeed or SpeedSettings.BaseFallback
        end

        local bonus = detectedGameSpeed * (SpeedSettings.Percent / 100)
        local targetSpeed = detectedGameSpeed + bonus
        hum.WalkSpeed = targetSpeed
        lastAppliedSpeed = targetSpeed
    else
        if lastAppliedSpeed ~= nil then
            hum.WalkSpeed = detectedGameSpeed
            lastAppliedSpeed = nil
        end
    end
end)

-- ====================================================================
-- ================== [БЭКЕНД SKILLCHECK HELPER] ======================
-- ====================================================================

local SkillSettings = {
    Enabled = false,
    Mode = "Perfect",
    NormalChance = 60,
    ScourgeChance = 0,
    ScourgeTrigger = 88,
    ActiveTarget = "Great"
}

local ZONES = {
    ["Great"] = { Start = 104, End = 114 },
    ["Good"]  = { Start = 118, End = 135 },
}

local CheckGui = PG:WaitForChild("SkillCheckPromptGui")
local Check = CheckGui:WaitForChild("Check")
local Line = Check:WaitForChild("Line")
local Goal = Check:WaitForChild("Goal")

local HeartbeatConn = nil
local readyForNext = true
local lastPressTime = 0

local function GetNearestGenProg()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    local sDist, nGen = 22, nil
    for _, gen in ipairs(ESP_Cache.Objects.Generators) do
        if gen and gen.Parent then
            local pos = gen:IsA("Model") and (gen.PrimaryPart and gen.PrimaryPart.Position or gen:GetPivot().Position) or (gen:IsA("BasePart") and gen.Position)
            if pos then
                local dist = (root.Position - pos).Magnitude
                if dist < sDist then sDist = dist nGen = gen end
            end
        end
    end
    if nGen then
        local p = nGen:GetAttribute("RepairProgress") or nGen:GetAttribute("Progress") or 0
        if p <= 1 and p > 0 then p = p * 100 end
        return p
    end
    return 0
end

local function RollSkillTarget()
    local genProg = GetNearestGenProg()
    if genProg >= SkillSettings.ScourgeTrigger then
        if SkillSettings.ScourgeChance <= 0 then SkillSettings.ActiveTarget = "Good"
        elseif SkillSettings.ScourgeChance >= 100 then SkillSettings.ActiveTarget = "Great"
        else SkillSettings.ActiveTarget = (math.random(1, 100) <= SkillSettings.ScourgeChance) and "Great" or "Good" end
    else
        if SkillSettings.Mode == "Random" then
            SkillSettings.ActiveTarget = (math.random(1, 100) <= SkillSettings.NormalChance) and "Great" or "Good"
        elseif SkillSettings.Mode == "Good" then
            SkillSettings.ActiveTarget = "Good"
        else
            SkillSettings.ActiveTarget = "Great"
        end
    end
end

local function PressSpace()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait(0.01)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
end

local function CheckLineHit()
    local lr, gr = Line.Rotation % 360, Goal.Rotation % 360
    local zone = ZONES[SkillSettings.ActiveTarget] or ZONES["Great"]
    local gs, ge = (gr + zone.Start) % 360, (gr + zone.End) % 360
    if gs > ge then return (lr >= gs or lr <= ge) else return (lr >= gs and lr <= ge) end
end

local function SkillHeartbeatCheck()
    if not _G.MinimalistUIRunning or not SkillSettings.Enabled or not Check.Visible then readyForNext = true return end
    if LP.Team and LP.Team.Name == "Survivors" then
        if CheckLineHit() then
            local now = tick()
            if readyForNext and (now - lastPressTime > 0.12) then
                readyForNext = false
                lastPressTime = now
                PressSpace()
            end
        else
            if not readyForNext and (tick() - lastPressTime > 0.08) then
                readyForNext = true
                RollSkillTarget()
            end
        end
    end
end

Goal:GetPropertyChangedSignal("Rotation"):Connect(function() readyForNext = true RollSkillTarget() end)
Check:GetPropertyChangedSignal("Visible"):Connect(function()
    if Check.Visible and LP.Team and LP.Team.Name == "Survivors" and SkillSettings.Enabled then
        if not HeartbeatConn then readyForNext = true RollSkillTarget() HeartbeatConn = RunService.Heartbeat:Connect(SkillHeartbeatCheck) end
    else
        if HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn = nil end
        readyForNext = true
    end
end)

-- ====================================================================
-- ===================== [ИНТЕРФЕЙС / GUI СТИЛЬ] ======================
-- ====================================================================

local oldUI = CoreGui:FindFirstChild("MinimalistV5Gui") or PG:FindFirstChild("MinimalistV5Gui")
if oldUI then oldUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinimalistV5Gui"
screenGui.ResetOnSpawn = false
local ok = pcall(function() screenGui.Parent = CoreGui end)
if not ok or not screenGui.Parent then screenGui.Parent = PG end

local UIConfig = {
    ToggleKey = Enum.KeyCode.K,
    IsVisible = true
}

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 530, 0, 360)
mainFrame.Position = UDim2.new(0.5, -265, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 13)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame) mainCorner.CornerRadius = UDim.new(0, 8)
local mainStroke = Instance.new("UIStroke", mainFrame) mainStroke.Color = Color3.fromRGB(28, 28, 33) mainStroke.Thickness = 1

local sidebar = Instance.new("Frame", mainFrame)
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 42, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(13, 13, 15)
sidebar.BorderSizePixel = 0
local sideCorner = Instance.new("UICorner", sidebar) sideCorner.CornerRadius = UDim.new(0, 8)

local iconContainer = Instance.new("Frame", sidebar)
iconContainer.Size = UDim2.new(1, 0, 0.48, 0)
iconContainer.Position = UDim2.new(0, 0, 0, 10)
iconContainer.BackgroundTransparency = 1

local iconLayout = Instance.new("UIListLayout", iconContainer)
iconLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
iconLayout.Padding = UDim.new(0, 4)

local headerTitle = Instance.new("TextLabel", mainFrame)
headerTitle.Size = UDim2.new(1, -60, 0, 30)
headerTitle.Position = UDim2.new(0, 54, 0, 8)
headerTitle.BackgroundTransparency = 1
headerTitle.Font = Enum.Font.GothamBold
headerTitle.RichText = true
headerTitle.Text = Italic("Visuals")
headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
headerTitle.TextSize = 13
headerTitle.TextXAlignment = Enum.TextXAlignment.Left

local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size = UDim2.new(1, -56, 1, -44)
contentArea.Position = UDim2.new(0, 50, 0, 38)
contentArea.BackgroundTransparency = 1

local TabDefinitions = {
    { Id = "Combat",     Icon = "rbxassetid://6034684937" },
    { Id = "Movement",   Icon = "rbxassetid://6031075931" },
    { Id = "Player",     Icon = "rbxassetid://6034287594" },
    { Id = "Visuals",    Icon = "rbxassetid://6034509993" },
    { Id = "Automation", Icon = "rbxassetid://6031265976" },
    { Id = "Config",     Icon = "rbxassetid://6034287525" }
}

local tabPages, tabButtons = {}, {}
local currentTab = "Visuals"

local function SwitchTab(tabId)
    if currentTab == tabId and tabPages[tabId] and tabPages[tabId].Visible then return end
    currentTab = tabId
    headerTitle.Text = Italic(tabId)

    for id, page in pairs(tabPages) do
        if id == tabId then
            page.Visible = true
            page.GroupTransparency = 1
            Tween(page, { GroupTransparency = 0 }, 0.15)
        else
            page.Visible = false
        end
    end

    for id, btn in pairs(tabButtons) do
        local isSel = (id == tabId)
        local icon = btn:FindFirstChildOfClass("ImageLabel")
        if icon then Tween(icon, { ImageColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(75, 75, 85) }, 0.12) end
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then Tween(stroke, { Transparency = isSel and 0 or 1 }, 0.12) end
    end
end

-- ====================================================================
-- =================== [КНОПКА UNLOAD СИСТЕМЫ] ========================
-- ====================================================================

local function UnloadScript()
    _G.MinimalistUIRunning = false

    -- Восстановление освещения
    Lighting.FogEnd = OrigLighting.FogEnd
    Lighting.FogStart = OrigLighting.FogStart
    Lighting.FogColor = OrigLighting.FogColor
    Lighting.Ambient = OrigLighting.Ambient
    Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient
    Lighting.Brightness = OrigLighting.Brightness
    Lighting.ClockTime = OrigLighting.ClockTime

    -- Восстановление атмосферы
    local at = Lighting:FindFirstChildOfClass("Atmosphere")
    if at and OrigAtmosphere then
        at.Density = OrigAtmosphere.Density
        at.Offset = OrigAtmosphere.Offset
        at.Haze = OrigAtmosphere.Haze
        at.Glare = OrigAtmosphere.Glare
        at.Color = OrigAtmosphere.Color
        at.Decay = OrigAtmosphere.Decay
    end

    -- Восстановление цветокоррекции
    local customCC = Lighting:FindFirstChild("MinimalistUI_CC")
    if customCC then customCC:Destroy() end

    local gameCC = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if gameCC and OrigColorCorrection then
        gameCC.Brightness = OrigColorCorrection.Brightness
        gameCC.Contrast = OrigColorCorrection.Contrast
        gameCC.Saturation = OrigColorCorrection.Saturation
        gameCC.TintColor = OrigColorCorrection.TintColor
        gameCC.Enabled = OrigColorCorrection.Enabled
    end

    -- Восстановление камеры
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = OrigCamera.FieldOfView end
    if LP then
        LP.CameraMaxZoomDistance = OrigCamera.MaxZoom
        LP.CameraMinZoomDistance = OrigCamera.MinZoom
    end

    -- Восстановление скорости
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and detectedGameSpeed then
        hum.WalkSpeed = detectedGameSpeed
    end

    -- Восстановление мыши
    if savedMouseBehavior then
        UserInputService.MouseBehavior = savedMouseBehavior
    end

    -- Очистка ESP
    CleanupESP(LP.Character)
    for _, p in ipairs(Players:GetPlayers()) do if p.Character then CleanupESP(p.Character) end end
    for _, list in pairs(ESP_Cache.Objects) do
        for _, o in ipairs(list) do CleanupESP(o) end
    end

    if HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn = nil end

    screenGui:Destroy()
end

-- ====================================================================
-- =================== [КОМПАКТНЫЙ COLOR PICKER] ======================
-- ====================================================================

local activeColorPicker, activeOverlay = nil, nil

local function CloseColorPicker()
    if activeColorPicker then activeColorPicker:Destroy() activeColorPicker = nil end
    if activeOverlay then activeOverlay:Destroy() activeOverlay = nil end
end

local function OpenColorPicker(anchorBtn, initialColor, onColorChanged)
    if activeColorPicker then CloseColorPicker() return end

    activeOverlay = Instance.new("TextButton", screenGui)
    activeOverlay.Size = UDim2.new(1, 0, 1, 0)
    activeOverlay.BackgroundTransparency = 1
    activeOverlay.Text = ""
    activeOverlay.ZIndex = 90
    activeOverlay.MouseButton1Click:Connect(CloseColorPicker)

    local popup = Instance.new("Frame", screenGui)
    popup.Name = "ColorPickerPopup"
    popup.Size = UDim2.new(0, 140, 0, 145)
    local ax, ay = anchorBtn.AbsolutePosition.X, anchorBtn.AbsolutePosition.Y
    popup.Position = UDim2.new(0, math.clamp(ax + 20, 10, screenGui.AbsoluteSize.X - 150), 0, math.clamp(ay - 20, 10, screenGui.AbsoluteSize.Y - 155))
    popup.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    popup.BorderSizePixel = 0
    popup.ZIndex = 95
    activeColorPicker = popup

    local popCorner = Instance.new("UICorner", popup) popCorner.CornerRadius = UDim.new(0, 6)
    local popStroke = Instance.new("UIStroke", popup) popStroke.Color = Color3.fromRGB(38, 38, 45) popStroke.Thickness = 1

    local h, s, v = Color3.toHSV(initialColor)

    local svBox = Instance.new("ImageButton", popup)
    svBox.Size = UDim2.new(1, -16, 0, 75)
    svBox.Position = UDim2.new(0, 8, 0, 8)
    svBox.Image = "rbxassetid://4155801252"
    svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    svBox.BorderSizePixel = 0
    svBox.AutoButtonColor = false
    svBox.ZIndex = 96

    local svCursor = Instance.new("Frame", svBox)
    svCursor.Size = UDim2.new(0, 5, 0, 5)
    svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
    svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    svCursor.BorderSizePixel = 0
    local svC = Instance.new("UICorner", svCursor) svC.CornerRadius = UDim.new(1, 0)

    local hueBar = Instance.new("TextButton", popup)
    hueBar.Size = UDim2.new(1, -16, 0, 7)
    hueBar.Position = UDim2.new(0, 8, 0, 88)
    hueBar.BorderSizePixel = 0
    hueBar.Text = ""
    hueBar.AutoButtonColor = false
    hueBar.ZIndex = 96
    local hbC = Instance.new("UICorner", hueBar) hbC.CornerRadius = UDim.new(1, 0)

    local hueGrad = Instance.new("UIGradient", hueBar)
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
    })

    local hexInput = Instance.new("TextBox", popup)
    hexInput.Size = UDim2.new(1, -16, 0, 20)
    hexInput.Position = UDim2.new(0, 8, 0, 102)
    hexInput.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    hexInput.BorderSizePixel = 0
    hexInput.Font = Enum.Font.GothamMedium
    hexInput.RichText = true
    hexInput.Text = Italic("#" .. initialColor:ToHex():upper())
    hexInput.TextColor3 = Color3.fromRGB(230, 230, 235)
    hexInput.TextSize = 10
    hexInput.ZIndex = 96
    local hiC = Instance.new("UICorner", hexInput) hiC.CornerRadius = UDim.new(0, 4)

    local function ApplyColor(c)
        anchorBtn.BackgroundColor3 = c
        hexInput.Text = Italic("#" .. c:ToHex():upper())
        onColorChanged(c)
    end

    local function UpdateHSV()
        local c = Color3.fromHSV(h, s, v)
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        ApplyColor(c)
    end

    hexInput.FocusLost:Connect(function()
        local raw = hexInput.Text:gsub("#", ""):gsub("%s+", "")
        local success, newColor = pcall(function() return Color3.fromHex(raw) end)
        if success and newColor then
            h, s, v = Color3.toHSV(newColor)
            UpdateHSV()
        else
            hexInput.Text = Italic("#" .. Color3.fromHSV(h, s, v):ToHex():upper())
        end
    end)

    local isDragSV, isDragHue = false, false
    svBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragSV = true
            s = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
            UpdateHSV()
        end
    end)
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragHue = true
            h = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
            UpdateHSV()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragSV = false isDragHue = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if isDragSV then
                s = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                UpdateHSV()
            elseif isDragHue then
                h = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                UpdateHSV()
            end
        end
    end)
end

-- ====================================================================
-- ========= [РАЗДЕЛЬНЫЕ ХИТБОКСЫ: ТЕКСТ vs СТРЕЛОЧКА] ================
-- ====================================================================

local function CreateCategory(parent, titleText)
    local catFrame = Instance.new("Frame", parent)
    catFrame.Name = "Cat_" .. titleText
    catFrame.Size = UDim2.new(1, 0, 0, 22)
    catFrame.BackgroundTransparency = 1
    catFrame.BorderSizePixel = 0
    catFrame.ClipsDescendants = true

    local header = Instance.new("Frame", catFrame)
    header.Size = UDim2.new(1, 0, 0, 20)
    header.BackgroundTransparency = 1

    local arrow = Instance.new("TextLabel", header)
    arrow.Size = UDim2.new(0, 12, 1, 0)
    arrow.Position = UDim2.new(0, 3, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamMedium
    arrow.Text = "▶"
    arrow.TextColor3 = Color3.fromRGB(110, 110, 120)
    arrow.TextSize = 7

    local titleLbl = Instance.new("TextLabel", header)
    titleLbl.Size = UDim2.new(1, -20, 1, 0)
    titleLbl.Position = UDim2.new(0, 18, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.RichText = true
    titleLbl.Text = Italic(titleText)
    titleLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
    titleLbl.TextSize = 10
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local expandBtn = Instance.new("TextButton", header)
    expandBtn.Size = UDim2.new(1, 0, 1, 0)
    expandBtn.BackgroundTransparency = 1
    expandBtn.Text = ""

    local content = Instance.new("Frame", catFrame)
    content.Size = UDim2.new(1, -4, 0, 0)
    content.Position = UDim2.new(0, 4, 0, 22)
    content.BackgroundTransparency = 1
    content.Visible = false

    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0, 4)

    local isExpanded = false
    expandBtn.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        content.Visible = isExpanded
        Tween(arrow, { Rotation = isExpanded and 90 or 0 }, 0.15)
        Tween(titleLbl, { TextColor3 = isExpanded and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140) }, 0.15)
        Tween(catFrame, { Size = UDim2.new(1, 0, 0, isExpanded and (layout.AbsoluteContentSize.Y + 26) or 22) }, 0.15)
    end)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if isExpanded then
            Tween(catFrame, { Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 26) }, 0.1)
        end
    end)

    return content
end

local function CreateFunctionModule(parent, titleText, defaultBind, onToggleCallback, onBindSet)
    local modFrame = Instance.new("Frame", parent)
    modFrame.Name = "Mod_" .. titleText
    modFrame.Size = UDim2.new(1, 0, 0, 22)
    modFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    modFrame.BackgroundTransparency = 1
    modFrame.BorderSizePixel = 0
    modFrame.ClipsDescendants = true

    local mC = Instance.new("UICorner", modFrame) mC.CornerRadius = UDim.new(0, 5)
    local mStroke = Instance.new("UIStroke", modFrame)
    mStroke.Color = Color3.fromRGB(32, 32, 38)
    mStroke.Thickness = 1
    mStroke.Transparency = 1

    local header = Instance.new("Frame", modFrame)
    header.Size = UDim2.new(1, 0, 0, 20)
    header.BackgroundTransparency = 1

    local arrow = Instance.new("TextLabel", header)
    arrow.Size = UDim2.new(0, 12, 1, 0)
    arrow.Position = UDim2.new(0, 3, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Font = Enum.Font.GothamMedium
    arrow.Text = "▶"
    arrow.TextColor3 = Color3.fromRGB(110, 110, 120)
    arrow.TextSize = 7

    -- Хитбокс треугольника (~20x20) для раскрытия/сворачивания
    local arrowHitbox = Instance.new("TextButton", header)
    arrowHitbox.Size = UDim2.new(0, 20, 0, 20)
    arrowHitbox.Position = UDim2.new(0, 0, 0, 0)
    arrowHitbox.BackgroundTransparency = 1
    arrowHitbox.Text = ""

    -- Клик по тексту переключает статус ВКЛ/ВЫКЛ (0 мс)
    local titleBtn = Instance.new("TextButton", header)
    titleBtn.Size = UDim2.new(1, -62, 1, 0)
    titleBtn.Position = UDim2.new(0, 20, 0, 0)
    titleBtn.BackgroundTransparency = 1
    titleBtn.Font = Enum.Font.GothamMedium
    titleBtn.RichText = true
    titleBtn.Text = Italic(titleText)
    titleBtn.TextColor3 = Color3.fromRGB(110, 110, 120)
    titleBtn.TextSize = 10
    titleBtn.TextXAlignment = Enum.TextXAlignment.Left

    local bindKeyStr = defaultBind or "None"
    local bindBtn = Instance.new("TextButton", header)
    bindBtn.Size = UDim2.new(0, 35, 1, 0)
    bindBtn.Position = UDim2.new(1, -38, 0, 0)
    bindBtn.BackgroundTransparency = 1
    bindBtn.Font = Enum.Font.GothamMedium
    bindBtn.RichText = true
    bindBtn.Text = Italic("[" .. bindKeyStr .. "]")
    bindBtn.TextColor3 = Color3.fromRGB(80, 80, 90)
    bindBtn.TextSize = 9
    bindBtn.TextXAlignment = Enum.TextXAlignment.Right

    local isEnabled = false
    local isExpanded = false

    local parsedKey = Enum.KeyCode.Unknown
    if defaultBind and defaultBind ~= "None" then
        pcall(function() parsedKey = Enum.KeyCode[defaultBind] end)
    end

    -- Регистрация кейбинда в центральном диспетчере
    local bindData = {
        Name = titleText,
        Key = parsedKey,
        Toggle = function()
            isEnabled = not isEnabled
            Tween(titleBtn, { TextColor3 = isEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 120) }, 0.12)
            if onToggleCallback then onToggleCallback(isEnabled) end
        end
    }
    table.insert(RegisteredKeybinds, bindData)

    -- Удаление биндов через Backspace
    bindBtn.MouseButton1Click:Connect(function()
        bindBtn.Text = Italic("[...]")
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                if input.KeyCode == Enum.KeyCode.Backspace then
                    bindData.Key = Enum.KeyCode.Unknown
                    bindBtn.Text = Italic("[None]")
                    if onBindSet then onBindSet(nil) end
                elseif input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
                    bindData.Key = input.KeyCode
                    bindBtn.Text = Italic("[" .. input.KeyCode.Name .. "]")
                    if onBindSet then onBindSet(input.KeyCode) end
                end
            end
        end)
    end)

    local content = Instance.new("Frame", modFrame)
    content.Size = UDim2.new(1, -12, 0, 0)
    content.Position = UDim2.new(0, 6, 0, 22)
    content.BackgroundTransparency = 1
    content.Visible = false

    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0, 4)

    -- Мгновенный клик по тексту (0 мс)
    titleBtn.MouseButton1Click:Connect(function()
        bindData.Toggle()
    end)

    -- Клик по стрелочке только сворачивает/разворачивает
    arrowHitbox.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        content.Visible = isExpanded
        Tween(arrow, { Rotation = isExpanded and 90 or 0 }, 0.15)
        Tween(mStroke, { Transparency = isExpanded and 0 or 1 }, 0.15)
        Tween(modFrame, {
            BackgroundTransparency = isExpanded and 0 or 1,
            Size = UDim2.new(1, 0, 0, isExpanded and (layout.AbsoluteContentSize.Y + 28) or 22)
        }, 0.15)
    end)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if isExpanded then
            Tween(modFrame, { Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 28) }, 0.1)
        end
    end)

    return content, modFrame
end

local function AddTextToggle(parent, labelText, defaultState, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, -20, 1, 0)
    btn.Position = UDim2.new(0, 20, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.GothamMedium
    btn.RichText = true
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextSize = 10
    btn.Text = Italic(labelText)

    local isAct = defaultState
    btn.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 120)

    btn.MouseButton1Click:Connect(function()
        isAct = not isAct
        Tween(btn, { TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 120) }, 0.12)
        if callback then callback(isAct) end
    end)
end

local function AddInlineToggles(parent, items, defaultIndex, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 16)
    row.BackgroundTransparency = 1
    local l = Instance.new("UIListLayout", row)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, 8)

    local activeIdx = defaultIndex or 1
    local btnRefs = {}
    for i, name in ipairs(items) do
        local b = Instance.new("TextButton", row)
        b.Size = UDim2.new(0, 0, 1, 0)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundTransparency = 1
        b.Font = Enum.Font.GothamMedium
        b.RichText = true
        b.Text = Italic(name)
        b.TextSize = 10
        b.TextColor3 = (i == activeIdx) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 120)
        table.insert(btnRefs, b)

        b.MouseButton1Click:Connect(function()
            activeIdx = i
            for idx, ref in ipairs(btnRefs) do
                Tween(ref, { TextColor3 = (idx == activeIdx) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(110, 110, 120) }, 0.12)
            end
            if callback then callback(name, i) end
        end)
    end
end

local function AddSlider(parent, labelText, minVal, maxVal, defaultVal, isFloat, callback)
    local s = Instance.new("Frame", parent)
    s.Size = UDim2.new(1, 0, 0, 24)
    s.BackgroundTransparency = 1

    local titleLbl = Instance.new("TextLabel", s)
    titleLbl.Size = UDim2.new(0.65, 0, 0, 12)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.RichText = true
    titleLbl.Text = Italic(labelText)
    titleLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
    titleLbl.TextSize = 9
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", s)
    valLbl.Size = UDim2.new(0.35, 0, 0, 12)
    valLbl.Position = UDim2.new(0.65, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamMedium
    valLbl.RichText = true
    valLbl.Text = Italic(isFloat and string.format("%.2f", defaultVal) or tostring(math.floor(defaultVal)))
    valLbl.TextColor3 = Color3.fromRGB(220, 220, 225)
    valLbl.TextSize = 9
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("TextButton", s)
    track.Size = UDim2.new(1, 0, 0, 2)
    track.Position = UDim2.new(0, 0, 0, 16)
    track.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    track.BorderSizePixel = 0
    track.Text = ""

    local currentPct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(currentPct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(200, 200, 205)
    fill.BorderSizePixel = 0

    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0, 5, 0, 5)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(currentPct, 0, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    local thC = Instance.new("UICorner", thumb) thC.CornerRadius = UDim.new(1, 0)

    local currentNum = defaultVal
    local isDrag = false

    local function SmoothUpdate(inp)
        local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local targetVal = minVal + (rel * (maxVal - minVal))

        Tween(fill, { Size = UDim2.new(rel, 0, 1, 0) }, 0.07)
        Tween(thumb, { Position = UDim2.new(rel, 0, 0.5, 0) }, 0.07)

        local startVal = currentNum
        local startTime = tick()
        task.spawn(function()
            while tick() - startTime < 0.07 do
                local a = (tick() - startTime) / 0.07
                local cur = startVal + (targetVal - startVal) * a
                valLbl.Text = Italic(isFloat and string.format("%.2f", cur) or tostring(math.floor(cur + 0.5)))
                task.wait()
            end
            currentNum = targetVal
            valLbl.Text = Italic(isFloat and string.format("%.2f", targetVal) or tostring(math.floor(targetVal + 0.5)))
        end)

        if callback then callback(targetVal) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then isDrag = true SmoothUpdate(inp) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then isDrag = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if isDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then SmoothUpdate(inp) end
    end)
end

local function AddColorOption(parent, labelText, defaultColor, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 16)
    row.BackgroundTransparency = 1

    local t = Instance.new("TextLabel", row)
    t.Size = UDim2.new(1, -20, 1, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamMedium
    t.RichText = true
    t.Text = Italic(labelText)
    t.TextColor3 = Color3.fromRGB(120, 120, 130)
    t.TextSize = 10
    t.TextXAlignment = Enum.TextXAlignment.Left

    local p = Instance.new("TextButton", row)
    p.Size = UDim2.new(0, 10, 0, 10)
    p.Position = UDim2.new(1, -12, 0.5, -5)
    p.BackgroundColor3 = defaultColor
    p.BorderSizePixel = 0
    p.Text = ""
    local pc = Instance.new("UICorner", p) pc.CornerRadius = UDim.new(0, 2)
    local ps = Instance.new("UIStroke", p) ps.Color = Color3.fromRGB(38, 38, 44) ps.Thickness = 1

    p.MouseButton1Click:Connect(function()
        OpenColorPicker(p, p.BackgroundColor3, callback)
    end)
end

local function CreateTwoColumnPage(pageName)
    local page = Instance.new("CanvasGroup", contentArea)
    page.Name = "Page_" .. pageName
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Visible = false

    local leftCol = Instance.new("ScrollingFrame", page)
    leftCol.Size = UDim2.new(0.5, -6, 1, 0)
    leftCol.Position = UDim2.new(0, 0, 0, 0)
    leftCol.BackgroundTransparency = 1
    leftCol.BorderSizePixel = 0
    leftCol.ScrollBarThickness = 1
    leftCol.ScrollBarImageColor3 = Color3.fromRGB(30, 30, 36)
    leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local l1 = Instance.new("UIListLayout", leftCol) l1.Padding = UDim.new(0, 5)

    local rightCol = Instance.new("ScrollingFrame", page)
    rightCol.Size = UDim2.new(0.5, -6, 1, 0)
    rightCol.Position = UDim2.new(0.5, 6, 0, 0)
    rightCol.BackgroundTransparency = 1
    rightCol.BorderSizePixel = 0
    rightCol.ScrollBarThickness = 1
    rightCol.ScrollBarImageColor3 = Color3.fromRGB(30, 30, 36)
    rightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local l2 = Instance.new("UIListLayout", rightCol) l2.Padding = UDim.new(0, 5)

    tabPages[pageName] = page
    return leftCol, rightCol
end

for _, def in ipairs(TabDefinitions) do
    local btn = Instance.new("TextButton", iconContainer)
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    local str = Instance.new("UIStroke", btn)
    str.Color = Color3.fromRGB(36, 36, 42)
    str.Thickness = 1
    str.Transparency = 1
    local c = Instance.new("UICorner", btn) c.CornerRadius = UDim.new(0, 5)

    local img = Instance.new("ImageLabel", btn)
    img.Size = UDim2.new(0, 14, 0, 14)
    img.Position = UDim2.new(0.5, -7, 0.5, -7)
    img.BackgroundTransparency = 1
    img.Image = def.Icon
    img.ImageColor3 = Color3.fromRGB(75, 75, 85)

    tabButtons[def.Id] = btn
    btn.MouseButton1Click:Connect(function() SwitchTab(def.Id) end)
end

-- Кнопка Unload в сайдбаре
local unloadBtn = Instance.new("TextButton", sidebar)
unloadBtn.Size = UDim2.new(0, 26, 0, 26)
unloadBtn.Position = UDim2.new(0.5, -13, 1, -34)
unloadBtn.BackgroundTransparency = 1
unloadBtn.Text = ""

local uStr = Instance.new("UIStroke", unloadBtn)
uStr.Color = Color3.fromRGB(50, 25, 25)
uStr.Thickness = 1
local uC = Instance.new("UICorner", unloadBtn) uC.CornerRadius = UDim.new(0, 5)

local uImg = Instance.new("ImageLabel", unloadBtn)
uImg.Size = UDim2.new(0, 14, 0, 14)
uImg.Position = UDim2.new(0.5, -7, 0.5, -7)
uImg.BackgroundTransparency = 1
uImg.Image = "rbxassetid://6031094678"
uImg.ImageColor3 = Color3.fromRGB(180, 70, 70)

unloadBtn.MouseButton1Click:Connect(UnloadScript)

-- ====================================================================
-- ================== [ВКЛАДКА VISUALS: СТРУКТУРА И ESP] ==============
-- ====================================================================
local vLeft, vRight = CreateTwoColumnPage("Visuals")

-- ЛЕВАЯ КОЛОНКА: "Player ESP"
local pEspContent = CreateCategory(vLeft, "Player ESP")

local meContent = CreateFunctionModule(pEspContent, "Me", "None", function(on) ESP_Config.Me.Enabled = on end)
AddColorOption(meContent, "Outline Color", ESP_Config.Me.OutlineColor, function(c) ESP_Config.Me.OutlineColor = c end)
AddSlider(meContent, "Outline Transparency", 0, 1, ESP_Config.Me.OutlineTransparency, true, function(v) ESP_Config.Me.OutlineTransparency = v end)
AddColorOption(meContent, "Fill Color", ESP_Config.Me.FillColor, function(c) ESP_Config.Me.FillColor = c end)
AddSlider(meContent, "Fill Transparency", 0, 1, ESP_Config.Me.FillTransparency, true, function(v) ESP_Config.Me.FillTransparency = v end)
AddInlineToggles(meContent, { "Occluded", "AlwaysOnTop" }, 2, function(name) ESP_Config.Me.Type = name end)

local survContent = CreateFunctionModule(pEspContent, "Survivors", "None", function(on) ESP_Config.Survivors.Enabled = on end)
AddColorOption(survContent, "Outline Color", ESP_Config.Survivors.OutlineColor, function(c) ESP_Config.Survivors.OutlineColor = c end)
AddSlider(survContent, "Outline Transparency", 0, 1, ESP_Config.Survivors.OutlineTransparency, true, function(v) ESP_Config.Survivors.OutlineTransparency = v end)
AddColorOption(survContent, "Fill Color", ESP_Config.Survivors.FillColor, function(c) ESP_Config.Survivors.FillColor = c end)
AddSlider(survContent, "Fill Transparency", 0, 1, ESP_Config.Survivors.FillTransparency, true, function(v) ESP_Config.Survivors.FillTransparency = v end)
AddInlineToggles(survContent, { "Occluded", "AlwaysOnTop" }, 2, function(name) ESP_Config.Survivors.Type = name end)
AddSlider(survContent, "Distance", 0, 1000, ESP_Config.Survivors.Distance, false, function(v) ESP_Config.Survivors.Distance = v end)
AddTextToggle(survContent, "Show Name", ESP_Config.Survivors.ShowName, function(on) ESP_Config.Survivors.ShowName = on end)
AddTextToggle(survContent, "Show Distance", ESP_Config.Survivors.ShowDistance, function(on) ESP_Config.Survivors.ShowDistance = on end)
AddTextToggle(survContent, "Show Item", ESP_Config.Survivors.ShowItem, function(on) ESP_Config.Survivors.ShowItem = on end)
AddColorOption(survContent, "Text Color", ESP_Config.Survivors.TextColor, function(c) ESP_Config.Survivors.TextColor = c end)
AddColorOption(survContent, "Text Outline Color", ESP_Config.Survivors.TextOutlineColor, function(c) ESP_Config.Survivors.TextOutlineColor = c end)

local killerContent = CreateFunctionModule(pEspContent, "Killers", "None", function(on) ESP_Config.Killers.Enabled = on end)
AddColorOption(killerContent, "Outline Color", ESP_Config.Killers.OutlineColor, function(c) ESP_Config.Killers.OutlineColor = c end)
AddSlider(killerContent, "Outline Transparency", 0, 1, ESP_Config.Killers.OutlineTransparency, true, function(v) ESP_Config.Killers.OutlineTransparency = v end)
AddColorOption(killerContent, "Fill Color", ESP_Config.Killers.FillColor, function(c) ESP_Config.Killers.FillColor = c end)
AddSlider(killerContent, "Fill Transparency", 0, 1, ESP_Config.Killers.FillTransparency, true, function(v) ESP_Config.Killers.FillTransparency = v end)
AddInlineToggles(killerContent, { "Occluded", "AlwaysOnTop" }, 2, function(name) ESP_Config.Killers.Type = name end)
AddSlider(killerContent, "Distance", 0, 1000, ESP_Config.Killers.Distance, false, function(v) ESP_Config.Killers.Distance = v end)
AddTextToggle(killerContent, "Custom Killerlight", ESP_Config.Killers.CustomKillerlight, function(on) ESP_Config.Killers.CustomKillerlight = on end)
AddTextToggle(killerContent, "Show Name", ESP_Config.Killers.ShowName, function(on) ESP_Config.Killers.ShowName = on end)
AddTextToggle(killerContent, "Show Distance", ESP_Config.Killers.ShowDistance, function(on) ESP_Config.Killers.ShowDistance = on end)
AddColorOption(killerContent, "Text Color", ESP_Config.Killers.TextColor, function(c) ESP_Config.Killers.TextColor = c end)
AddColorOption(killerContent, "Text Outline Color", ESP_Config.Killers.TextOutlineColor, function(c) ESP_Config.Killers.TextOutlineColor = c end)

-- ПРАВАЯ КОЛОНКА: "Object ESP" (Бесконечная дистанция)
local objEspContent = CreateCategory(vRight, "Object ESP")

local palContent = CreateFunctionModule(objEspContent, "Pallets", "None", function(on) ESP_Config.Pallets.Enabled = on end)
AddColorOption(palContent, "Outline Color", ESP_Config.Pallets.OutlineColor, function(c) ESP_Config.Pallets.OutlineColor = c end)
AddSlider(palContent, "Outline Transparency", 0, 1, ESP_Config.Pallets.OutlineTransparency, true, function(v) ESP_Config.Pallets.OutlineTransparency = v end)
AddColorOption(palContent, "Fill Color", ESP_Config.Pallets.FillColor, function(c) ESP_Config.Pallets.FillColor = c end)
AddSlider(palContent, "Fill Transparency", 0, 1, ESP_Config.Pallets.FillTransparency, true, function(v) ESP_Config.Pallets.FillTransparency = v end)
AddInlineToggles(palContent, { "Occluded", "AlwaysOnTop" }, 2, function(name) ESP_Config.Pallets.Type = name end)
AddTextToggle(palContent, "Show Name", ESP_Config.Pallets.ShowName, function(on) ESP_Config.Pallets.ShowName = on end)
AddTextToggle(palContent, "Show Distance", ESP_Config.Pallets.ShowDistance, function(on) ESP_Config.Pallets.ShowDistance = on end)
AddColorOption(palContent, "Text Color", ESP_Config.Pallets.TextColor, function(c) ESP_Config.Pallets.TextColor = c end)
AddColorOption(palContent, "Text Outline Color", ESP_Config.Pallets.TextOutlineColor, function(c) ESP_Config.Pallets.TextOutlineColor = c end)

local winContent = CreateFunctionModule(objEspContent, "Windows", "None", function(on) ESP_Config.Windows.Enabled = on end)
AddColorOption(winContent, "Outline Color", ESP_Config.Windows.OutlineColor, function(c) ESP_Config.Windows.OutlineColor = c end)
AddSlider(winContent, "Outline Transparency", 0, 1, ESP_Config.Windows.OutlineTransparency, true, function(v) ESP_Config.Windows.OutlineTransparency = v end)
AddColorOption(winContent, "Fill Color", ESP_Config.Windows.FillColor, function(c) ESP_Config.Windows.FillColor = c end)
AddSlider(winContent, "Fill Transparency", 0, 1, ESP_Config.Windows.FillTransparency, true, function(v) ESP_Config.Windows.FillTransparency = v end)
AddInlineToggles(winContent, { "Occluded", "AlwaysOnTop" }, 2, function(name) ESP_Config.Windows.Type = name end)
AddTextToggle(winContent, "Show Name", ESP_Config.Windows.ShowName, function(on) ESP_Config.Windows.ShowName = on end)
AddTextToggle(winContent, "Show Distance", ESP_Config.Windows.ShowDistance, function(on) ESP_Config.Windows.ShowDistance = on end)
AddColorOption(winContent, "Text Color", ESP_Config.Windows.TextColor, function(c) ESP_Config.Windows.TextColor = c end)
AddColorOption(winContent, "Text Outline Color", ESP_Config.Windows.TextOutlineColor, function(c) ESP_Config.Windows.TextOutlineColor = c end)

local hookContent = CreateFunctionModule(objEspContent, "Hooks", "None", function(on) ESP_Config.Hooks.Enabled = on end)
AddColorOption(hookContent, "Outline Color", ESP_Config.Hooks.OutlineColor, function(c) ESP_Config.Hooks.OutlineColor = c end)
AddSlider(hookContent, "Outline Transparency", 0, 1, ESP_Config.Hooks.OutlineTransparency, true, function(v) ESP_Config.Hooks.OutlineTransparency = v end)
AddColorOption(hookContent, "Fill Color", ESP_Config.Hooks.FillColor, function(c) ESP_Config.Hooks.FillColor = c end)
AddSlider(hookContent, "Fill Transparency", 0, 1, ESP_Config.Hooks.FillTransparency, true, function(v) ESP_Config.Hooks.FillTransparency = v end)
AddInlineToggles(hookContent, { "Occluded", "AlwaysOnTop" }, 2, function(name) ESP_Config.Hooks.Type = name end)
AddTextToggle(hookContent, "Show Name", ESP_Config.Hooks.ShowName, function(on) ESP_Config.Hooks.ShowName = on end)
AddTextToggle(hookContent, "Show Distance", ESP_Config.Hooks.ShowDistance, function(on) ESP_Config.Hooks.ShowDistance = on end)
AddColorOption(hookContent, "Text Color", ESP_Config.Hooks.TextColor, function(c) ESP_Config.Hooks.TextColor = c end)
AddColorOption(hookContent, "Text Outline Color", ESP_Config.Hooks.TextOutlineColor, function(c) ESP_Config.Hooks.TextOutlineColor = c end)

local genContent = CreateFunctionModule(objEspContent, "Generators", "None", function(on) ESP_Config.Generators.Enabled = on end)
AddColorOption(genContent, "Outline Color", ESP_Config.Generators.OutlineColor, function(c) ESP_Config.Generators.OutlineColor = c end)
AddSlider(genContent, "Outline Transparency", 0, 1, ESP_Config.Generators.OutlineTransparency, true, function(v) ESP_Config.Generators.OutlineTransparency = v end)
AddColorOption(genContent, "Fill Color", ESP_Config.Generators.FillColor, function(c) ESP_Config.Generators.FillColor = c end)
AddSlider(genContent, "Fill Transparency", 0, 1, ESP_Config.Generators.FillTransparency, true, function(v) ESP_Config.Generators.FillTransparency = v end)
AddInlineToggles(genContent, { "Occluded", "AlwaysOnTop" }, 2, function(name) ESP_Config.Generators.Type = name end)
AddTextToggle(genContent, "Show Name", ESP_Config.Generators.ShowName, function(on) ESP_Config.Generators.ShowName = on end)
AddTextToggle(genContent, "Show Distance", ESP_Config.Generators.ShowDistance, function(on) ESP_Config.Generators.ShowDistance = on end)
AddTextToggle(genContent, "Show Progress", ESP_Config.Generators.ShowProgress, function(on) ESP_Config.Generators.ShowProgress = on end)
AddColorOption(genContent, "Text Color", ESP_Config.Generators.TextColor, function(c) ESP_Config.Generators.TextColor = c end)
AddColorOption(genContent, "Text Outline Color", ESP_Config.Generators.TextOutlineColor, function(c) ESP_Config.Generators.TextOutlineColor = c end)

-- КАТЕГОРИЯ "World"
local worldCategory = CreateCategory(vRight, "World")

local customCC = Lighting:FindFirstChild("MinimalistUI_CC")
if not customCC then
    customCC = Instance.new("ColorCorrectionEffect")
    customCC.Name = "MinimalistUI_CC"
    customCC.Enabled = false
    customCC.Parent = Lighting
end

local ccSettings = { Brightness = -0.05, Contrast = 0.15, Saturation = -0.70, Tint = Color3.fromRGB(255, 255, 255) }
local function UpdateColorCorrection(on)
    if on then
        customCC.Brightness = ccSettings.Brightness
        customCC.Contrast = ccSettings.Contrast
        customCC.Saturation = ccSettings.Saturation
        customCC.TintColor = ccSettings.Tint
        customCC.Enabled = true
    else
        customCC.Enabled = false
        local gameCC = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if gameCC and gameCC ~= customCC and OrigColorCorrection then
            gameCC.Brightness = OrigColorCorrection.Brightness
            gameCC.Contrast = OrigColorCorrection.Contrast
            gameCC.Saturation = OrigColorCorrection.Saturation
            gameCC.TintColor = OrigColorCorrection.TintColor
            gameCC.Enabled = OrigColorCorrection.Enabled
        end
    end
end

local ccContent = CreateFunctionModule(worldCategory, "Color Correction", "None", function(on)
    UpdateColorCorrection(on)
end)
AddSlider(ccContent, "Brightness", -1, 1, ccSettings.Brightness, true, function(v) ccSettings.Brightness = v UpdateColorCorrection(true) end)
AddSlider(ccContent, "Contrast", -1, 1, ccSettings.Contrast, true, function(v) ccSettings.Contrast = v UpdateColorCorrection(true) end)
AddSlider(ccContent, "Saturation", -1, 1, ccSettings.Saturation, true, function(v) ccSettings.Saturation = v UpdateColorCorrection(true) end)
AddColorOption(ccContent, "Tint Color", ccSettings.Tint, function(c) ccSettings.Tint = c UpdateColorCorrection(true) end)

local atSettings = { Color = Color3.fromRGB(200, 200, 220), Decay = Color3.fromRGB(120, 120, 140), Glare = 0.17, Haze = 10.00, Density = 0.51, Offset = 0.00 }
local function UpdateAtmosphere(on)
    local a = Lighting:FindFirstChildOfClass("Atmosphere")
    if on and a then
        a.Color = atSettings.Color
        a.Decay = atSettings.Decay
        a.Glare = atSettings.Glare
        a.Haze = atSettings.Haze
        a.Density = atSettings.Density
        a.Offset = atSettings.Offset
    elseif not on and a and OrigAtmosphere then
        a.Color = OrigAtmosphere.Color
        a.Decay = OrigAtmosphere.Decay
        a.Glare = OrigAtmosphere.Glare
        a.Haze = OrigAtmosphere.Haze
        a.Density = OrigAtmosphere.Density
        a.Offset = OrigAtmosphere.Offset
    end
end

local atContent = CreateFunctionModule(worldCategory, "Atmosphere", "None", function(on)
    UpdateAtmosphere(on)
end)
AddColorOption(atContent, "Color", atSettings.Color, function(c) atSettings.Color = c UpdateAtmosphere(true) end)
AddColorOption(atContent, "Decay", atSettings.Decay, function(c) atSettings.Decay = c UpdateAtmosphere(true) end)
AddSlider(atContent, "Glare", 0, 1, atSettings.Glare, true, function(v) atSettings.Glare = v UpdateAtmosphere(true) end)
AddSlider(atContent, "Haze", 0, 20, atSettings.Haze, true, function(v) atSettings.Haze = v UpdateAtmosphere(true) end)
AddSlider(atContent, "Density", 0, 1, atSettings.Density, true, function(v) atSettings.Density = v UpdateAtmosphere(true) end)
AddSlider(atContent, "Offset", 0, 1, atSettings.Offset, true, function(v) atSettings.Offset = v UpdateAtmosphere(true) end)

AddTextToggle(worldCategory, "Remove Fog", false, function(on)
    WorldSettings.RemoveFog = on
    if not on then
        Lighting.FogEnd = OrigLighting.FogEnd
        Lighting.FogStart = OrigLighting.FogStart
        Lighting.FogColor = OrigLighting.FogColor
        local a = Lighting:FindFirstChildOfClass("Atmosphere")
        if a and OrigAtmosphere then
            a.Density = OrigAtmosphere.Density
            a.Haze = OrigAtmosphere.Haze
        end
    end
end)

AddTextToggle(worldCategory, "Fullbright", false, function(on)
    WorldSettings.Fullbright = on
    if on then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
    else
        Lighting.Ambient = OrigLighting.Ambient
        Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient
        Lighting.Brightness = OrigLighting.Brightness
    end
end)

-- КАТЕГОРИЯ "Camera"
local camCategory = CreateCategory(vRight, "Camera")

local fovContent = CreateFunctionModule(camCategory, "FOV", "None", function(on)
    CamConfig.FOV.Enabled = on
    if not on then
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = OrigCamera.FieldOfView end
    end
end)
AddSlider(fovContent, "Field of View", 60, 120, CamConfig.FOV.Value, false, function(v)
    CamConfig.FOV.Value = v
end)

local aspectContent = CreateFunctionModule(camCategory, "Aspect Ratio", "None", function(on)
    CamConfig.AspectRatio.Enabled = on
end)
AddSlider(aspectContent, "Resolution Scale", 0.1, 2.0, CamConfig.AspectRatio.Value, true, function(v)
    CamConfig.AspectRatio.Value = v
end)

local zoomContent = CreateFunctionModule(camCategory, "Zoom", "None", function(on)
    CamConfig.Zoom.Enabled = on
    if on and LP then
        OrigCamera.MinZoom = LP.CameraMinZoomDistance
        OrigCamera.MaxZoom = LP.CameraMaxZoomDistance
    elseif not on and LP then
        LP.CameraMinZoomDistance = OrigCamera.MinZoom
        LP.CameraMaxZoomDistance = OrigCamera.MaxZoom
    end
end)
AddSlider(zoomContent, "Distance", 1, 50, CamConfig.Zoom.Value, false, function(v)
    CamConfig.Zoom.Value = v
end)

-- ====================================================================
-- ================== [ВКЛАДКА AUTOMATION: SKILLCHECK] ================
-- ====================================================================
local aLeft, aRight = CreateTwoColumnPage("Automation")
local skContent = CreateFunctionModule(aLeft, "Skill Check Helper", "None", function(on)
    SkillSettings.Enabled = on
    if not on and HeartbeatConn then HeartbeatConn:Disconnect() HeartbeatConn = nil end
end)

local randomSubFrame = Instance.new("Frame", skContent)
randomSubFrame.Size = UDim2.new(1, 0, 0, 0)
randomSubFrame.BackgroundTransparency = 1
randomSubFrame.ClipsDescendants = true
randomSubFrame.Visible = false
local rLayout = Instance.new("UIListLayout", randomSubFrame)
rLayout.Padding = UDim.new(0, 4)

AddSlider(randomSubFrame, "Perfect %", 0, 100, SkillSettings.NormalChance, false, function(v)
    SkillSettings.NormalChance = v RollSkillTarget()
end)
AddSlider(randomSubFrame, "King Scorch Perfect %", 0, 100, SkillSettings.ScourgeChance, false, function(v)
    SkillSettings.ScourgeChance = v RollSkillTarget()
end)

AddInlineToggles(skContent, { "Perfect", "Good", "Random" }, 1, function(name)
    SkillSettings.Mode = name
    RollSkillTarget()
    if name == "Random" then
        randomSubFrame.Visible = true
        Tween(randomSubFrame, { Size = UDim2.new(1, 0, 0, 56) }, 0.15)
    else
        local tw = Tween(randomSubFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
        tw.Completed:Connect(function()
            if SkillSettings.Mode ~= "Random" then randomSubFrame.Visible = false end
        end)
    end
end)

-- ====================================================================
-- =================== [ВКЛАДКА MOVEMENT: SPEED] ======================
-- ====================================================================
local mLeft, mRight = CreateTwoColumnPage("Movement")
local speedContent = CreateFunctionModule(mLeft, "Speed", "None", function(on)
    SpeedSettings.Enabled = on
end)
AddSlider(speedContent, "Boost Percent", 1, 100, SpeedSettings.Percent, false, function(v)
    SpeedSettings.Percent = v
end)

CreateFunctionModule(mRight, "Fly", "None")

local cLeft, cRight = CreateTwoColumnPage("Combat")
CreateFunctionModule(cLeft, "Attack Aura", "R")
CreateFunctionModule(cRight, "Triggerbot", "None")

local pLeft, pRight = CreateTwoColumnPage("Player")
CreateFunctionModule(pLeft, "Auto Vault", "None")
CreateFunctionModule(pRight, "Auto Heal", "None")

local cfgLeft, cfgRight = CreateTwoColumnPage("Config")
CreateFunctionModule(cfgLeft, "Menu Settings", UIConfig.ToggleKey.Name, nil, function(newKey) UIConfig.ToggleKey = newKey end)
AddTextToggle(cfgLeft, "Save Configuration", false, function() print("[Config] Saved.") end)
AddTextToggle(cfgLeft, "Load Configuration", false, function() print("[Config] Loaded.") end)

-- ====================================================================
-- =============== [ФИКС РЕСАЙЗА И БЛОКИРОВКА DRAG] ===================
-- ====================================================================

local resizeHitbox = Instance.new("TextButton", mainFrame)
resizeHitbox.Size = UDim2.new(0, 22, 0, 22)
resizeHitbox.Position = UDim2.new(1, -22, 1, -22)
resizeHitbox.BackgroundTransparency = 1
resizeHitbox.Text = ""
resizeHitbox.ZIndex = 30

local gripperVisual = Instance.new("Frame", resizeHitbox)
gripperVisual.Size = UDim2.new(0, 14, 0, 14)
gripperVisual.Position = UDim2.new(1, -14, 1, -14)
gripperVisual.BackgroundTransparency = 1
for offset = 1, 3 do
    local l = Instance.new("Frame", gripperVisual)
    l.Size = UDim2.new(0, 2 + (offset * 2), 0, 1)
    l.Position = UDim2.new(1, -(2 + offset * 3), 1, -(offset * 3))
    l.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
    l.BorderSizePixel = 0
end

local isResizing, resizeStart, initSize = false, nil, nil

resizeHitbox.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        isResizing = true
        resizeStart = inp.Position
        initSize = mainFrame.AbsoluteSize
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then isResizing = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if isResizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - resizeStart
        mainFrame.Size = UDim2.fromOffset(math.clamp(initSize.X + delta.X, 420, 800), math.clamp(initSize.Y + delta.Y, 260, 600))
    end
end)

local isDragging, dragStart, startPos = false, nil, nil

local function IsInResizeZone(pos)
    local gp = resizeHitbox.AbsolutePosition
    local gs = resizeHitbox.AbsoluteSize
    return pos.X >= gp.X and pos.X <= gp.X + gs.X and pos.Y >= gp.Y and pos.Y <= gp.Y + gs.Y
end

mainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if IsInResizeZone(inp.Position) or isResizing then
            return
        end
        isDragging = true
        dragStart = inp.Position
        startPos = mainFrame.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then isDragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if isDragging and not isResizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Разблокировка мыши
local function SetUIVisible(visible)
    UIConfig.IsVisible = visible
    mainFrame.Visible = visible
    if visible then
        savedMouseBehavior = UserInputService.MouseBehavior
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        if savedMouseBehavior then
            UserInputService.MouseBehavior = savedMouseBehavior
            savedMouseBehavior = nil
        end
        CloseColorPicker()
    end
end

UserInputService.InputBegan:Connect(function(inp, proc)
    if proc then return end
    if inp.KeyCode == UIConfig.ToggleKey then
        SetUIVisible(not UIConfig.IsVisible)
    end
end)

if UIConfig.IsVisible then
    savedMouseBehavior = UserInputService.MouseBehavior
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

SwitchTab("Visuals")