local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

for _, gui in pairs(CoreGui:GetChildren()) do
    if gui.Name:find("MagicTulevo") then
        gui:Destroy()
    end
end

local MagicTulevo = {}
MagicTulevo.ToggleKey = Enum.KeyCode.K
MagicTulevo.OnThemeChangeCallbacks = {}

-- ═══════════════════════════════════════════════════════════════
-- OPTIMIZATION: Cached TweenInfo objects (avoid creating new ones)
-- ═══════════════════════════════════════════════════════════════
local TweenInfoCache = {
    Fast = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Back = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    BackIn = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In),
    Linear = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
}

-- Custom TweenInfo cache for specific durations
local CustomTweenCache = {}
local function GetCachedTweenInfo(duration, style, direction)
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    local key = duration .. "_" .. style.Name .. "_" .. direction.Name
    if not CustomTweenCache[key] then
        CustomTweenCache[key] = TweenInfo.new(duration, style, direction)
    end
    return CustomTweenCache[key]
end

-- ═══════════════════════════════════════════════════════════════
-- OPTIMIZATION: Consolidated Animation Loop (single RenderStepped)
-- ═══════════════════════════════════════════════════════════════
local AnimationQueue = {
    GradientOffsets = {},  -- {gradient = {offset = 0, speed = 0.3}}
    Rotations = {},        -- {object = {rotation = 0, speed = 45}}
    Active = false
}

local function RegisterGradientAnimation(gradient, speed)
    AnimationQueue.GradientOffsets[gradient] = {offset = math.random(), speed = speed or 0.3}
end

local function UnregisterGradientAnimation(gradient)
    AnimationQueue.GradientOffsets[gradient] = nil
end

local function RegisterRotationAnimation(object, speed)
    AnimationQueue.Rotations[object] = {rotation = 0, speed = speed or 45}
end

local function UnregisterRotationAnimation(object)
    AnimationQueue.Rotations[object] = nil
end

local MainAnimationConnection = nil
local function StartAnimationLoop()
    if AnimationQueue.Active then return end
    AnimationQueue.Active = true
    
    MainAnimationConnection = RunService.RenderStepped:Connect(function(dt)
        -- Update all gradient offsets
        for gradient, data in pairs(AnimationQueue.GradientOffsets) do
            if gradient and gradient.Parent then
                data.offset = (data.offset + dt * data.speed) % 1
                gradient.Offset = Vector2.new(data.offset, 0)
            else
                AnimationQueue.GradientOffsets[gradient] = nil
            end
        end
        
        -- Update all rotations
        for object, data in pairs(AnimationQueue.Rotations) do
            if object and object.Parent then
                data.rotation = (data.rotation + dt * data.speed) % 360
                object.Rotation = data.rotation
            else
                AnimationQueue.Rotations[object] = nil
            end
        end
    end)
end

local function StopAnimationLoop()
    if MainAnimationConnection then
        MainAnimationConnection:Disconnect()
        MainAnimationConnection = nil
    end
    AnimationQueue.Active = false
    AnimationQueue.GradientOffsets = {}
    AnimationQueue.Rotations = {}
end

-- ═══════════════════════════════════════════════════════════════
-- OPTIMIZATION: Throttle/Debounce utility
-- ═══════════════════════════════════════════════════════════════
local function Debounce(func, delay)
    local lastCall = 0
    local scheduled = false
    return function(...)
        local args = {...}
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            func(unpack(args))
        elseif not scheduled then
            scheduled = true
            task.delay(delay - (now - lastCall), function()
                scheduled = false
                lastCall = tick()
                func(unpack(args))
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- OPTIMIZATION: Object Pool for reusable UI elements
-- ═══════════════════════════════════════════════════════════════
local ObjectPool = {
    Frames = {},
    TextLabels = {},
    TextButtons = {},
    ImageLabels = {},
}

local function GetPooledObject(className, props)
    local pool = ObjectPool[className .. "s"]
    local obj
    if pool and #pool > 0 then
        obj = table.remove(pool)
        obj.Visible = true
        obj.Parent = nil
    else
        obj = Instance.new(className)
    end
    for k, v in pairs(props) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function ReturnToPool(obj)
    local className = obj.ClassName
    local pool = ObjectPool[className .. "s"]
    if pool and #pool < 50 then -- Max 50 per type
        obj.Visible = false
        obj.Parent = nil
        -- Clear children except UICorner/UIStroke
        for _, child in pairs(obj:GetChildren()) do
            if not child:IsA("UICorner") and not child:IsA("UIStroke") then
                child:Destroy()
            end
        end
        table.insert(pool, obj)
    else
        obj:Destroy()
    end
end

MagicTulevo.Theme = {
    Background = Color3.fromRGB(13, 13, 18),
    Secondary = Color3.fromRGB(18, 18, 25),
    Card = Color3.fromRGB(24, 24, 34),
    CardHover = Color3.fromRGB(32, 32, 45),
    Accent = Color3.fromRGB(138, 92, 246),
    AccentDark = Color3.fromRGB(108, 62, 216),
    AccentGlow = Color3.fromRGB(168, 122, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextMuted = Color3.fromRGB(140, 140, 165),
    TextDark = Color3.fromRGB(90, 90, 110),
    Border = Color3.fromRGB(38, 38, 52),
    Success = Color3.fromRGB(34, 197, 94),
    Error = Color3.fromRGB(239, 68, 68),
    Warning = Color3.fromRGB(245, 158, 11)
}

local Theme = MagicTulevo.Theme

-- OPTIMIZED: Sound system with rate limiting to prevent lag
local lastSoundTime = 0
local soundCooldown = 0.1 -- Minimum time between sounds

local function PlaySound(id, vol)
    local now = tick()
    if now - lastSoundTime < soundCooldown then return end -- Rate limit
    lastSoundTime = now
    
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol or 0.5
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- OPTIMIZED: Create function with property batching
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

-- OPTIMIZED: Tween function using cached TweenInfo
local function Tween(obj, t, props, style, dir)
    local tweenInfo
    -- Use cached TweenInfo when possible
    if not style and not dir then
        if t <= 0.1 then
            tweenInfo = TweenInfoCache.Fast
        elseif t <= 0.2 then
            tweenInfo = TweenInfoCache.Normal
        elseif t <= 0.35 then
            tweenInfo = TweenInfoCache.Smooth
        else
            tweenInfo = TweenInfoCache.Slow
        end
    else
        tweenInfo = GetCachedTweenInfo(t, style, dir)
    end
    local tw = TweenService:Create(obj, tweenInfo, props)
    tw:Play()
    return tw
end

local function AddGlow(parent, color, size)
    local glow = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, size or 30, 1, size or 30),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://5554236805",
        ImageColor3 = color or Theme.Accent,
        ImageTransparency = 0.85,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = -1,
        Parent = parent
    })
    return glow
end

-- Save/Load System
local HttpService = game:GetService("HttpService")
local SaveFileName = "MagicTulevoSettings.json"

-- Config Folder System - Uses C:\MagicTulevo\Configs on Windows
MagicTulevo.ConfigFolderPath = "MagicTulevo/Configs"
MagicTulevo.ConfigFolderDisplay = "C:\\MagicTulevo\\Configs"

-- Initialize config folders with proper structure
MagicTulevo.InitializeConfigFolders = function()
    if makefolder then
        pcall(function()
            if not isfolder("MagicTulevo") then
                makefolder("MagicTulevo")
            end
            if not isfolder(MagicTulevo.ConfigFolderPath) then
                makefolder(MagicTulevo.ConfigFolderPath)
            end
        end)
    end
end

-- Get all config files from folder
MagicTulevo.GetConfigFiles = function()
    local configs = {}
    if listfiles and isfolder then
        pcall(function()
            if isfolder(MagicTulevo.ConfigFolderPath) then
                local files = listfiles(MagicTulevo.ConfigFolderPath)
                for _, filePath in ipairs(files) do
                    if filePath:match("%.lua$") then
                        local fileName = filePath:match("([^/\\]+)$")
                        if fileName then
                            local configName = fileName:gsub("%.lua$", "")
                            local fileContent = ""
                            if readfile then
                                pcall(function()
                                    fileContent = readfile(filePath)
                                end)
                            end
                            table.insert(configs, {
                                Name = configName,
                                FileName = fileName,
                                Path = filePath,
                                Content = fileContent
                            })
                        end
                    end
                end
            end
        end)
    end
    return configs
end

-- Save config to file with full Lua code structure
MagicTulevo.SaveConfigToFile = function(configName, configData)
    if writefile then
        local success = pcall(function()
            local filePath = MagicTulevo.ConfigFolderPath .. "/" .. configName .. ".lua"
            local dateStr = os.date("%d.%m.%Y %H:%M:%S")
            local settingsJson = HttpService:JSONEncode(configData.Settings or {})
            
            local content = "--[[\n"
            content = content .. "    MAGIC TULEVO CONFIG\n"
            content = content .. "    Config Name: " .. configName .. "\n"
            content = content .. "    Created: " .. dateStr .. "\n"
            content = content .. "    Path: " .. MagicTulevo.ConfigFolderDisplay .. "\\" .. configName .. ".lua\n"
            content = content .. "--]]\n\n"
            content = content .. "-- MagicTulevo Configuration File\n"
            content = content .. "-- Do not edit manually unless you know what you're doing\n\n"
            content = content .. "local ConfigData = {\n"
            content = content .. "    _metadata = {\n"
            content = content .. '        name = "' .. configName .. '",\n'
            content = content .. '        version = "1.0",\n'
            content = content .. '        created = "' .. dateStr .. '",\n'
            content = content .. '        lastModified = "' .. dateStr .. '",\n'
            content = content .. '        author = "MagicTulevo User"\n'
            content = content .. "    },\n"
            content = content .. "    settings = " .. settingsJson .. ",\n"
            content = content .. "    uiState = {\n"
            content = content .. '        theme = "Default Purple",\n'
            content = content .. "        windowPosition = {x = 100, y = 100},\n"
            content = content .. "        windowSize = {width = 600, height = 450}\n"
            content = content .. "    },\n"
            content = content .. "    customData = {}\n"
            content = content .. "}\n\n"
            content = content .. "return ConfigData\n"
            
            writefile(filePath, content)
        end)
        return success
    end
    return false
end

-- Load config from file
MagicTulevo.LoadConfigFromFile = function(configName)
    if readfile and isfile then
        local filePath = MagicTulevo.ConfigFolderPath .. "/" .. configName .. ".lua"
        local success, result = pcall(function()
            if isfile(filePath) then
                local content = readfile(filePath)
                -- Extract JSON from lua file
                local jsonStart = content:find("return ")
                if jsonStart then
                    local jsonStr = content:sub(jsonStart + 7)
                    return HttpService:JSONDecode(jsonStr)
                end
            end
            return nil
        end)
        if success then return result end
    end
    return nil
end

-- Delete config file
MagicTulevo.DeleteConfigFile = function(configName)
    if delfile and isfile then
        local filePath = MagicTulevo.ConfigFolderPath .. "/" .. configName .. ".lua"
        local success = pcall(function()
            if isfile(filePath) then
                delfile(filePath)
            end
        end)
        return success
    end
    return false
end

-- Initialize folders on script start
MagicTulevo.InitializeConfigFolders()

local function SaveSettings(data)
    if writefile then
        local success, err = pcall(function()
            writefile(SaveFileName, HttpService:JSONEncode(data))
        end)
        return success
    end
    return false
end

local function LoadSettings()
    if readfile and isfile then
        local success, result = pcall(function()
            if isfile(SaveFileName) then
                return HttpService:JSONDecode(readfile(SaveFileName))
            end
            return nil
        end)
        if success then return result end
    end
    return nil
end

-- Global state for cleanup
MagicTulevo.Connections = {}
MagicTulevo.Sounds = {}
MagicTulevo.Windows = {}
MagicTulevo.SavedSettings = LoadSettings() or {}

function MagicTulevo:OnThemeChange(callback)
    if type(callback) == "function" then
        table.insert(MagicTulevo.OnThemeChangeCallbacks, callback)
    end
end

function MagicTulevo:GetAccentColor()
    return Theme.Accent
end

function MagicTulevo:Notify(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "Notification"
    local message = cfg.Message or ""
    local duration = cfg.Duration or 4
    local notifyType = cfg.Type or "Info"
    local typeColors = {Info = Theme.Accent, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error}
    local typeIcons = {Info = "i", Success = "+", Warning = "!", Error = "x"}
    local typeSounds = {Success = "rbxassetid://1555493683", Warning = "rbxassetid://1862047553", Error = "rbxassetid://1862045322"}
    local color = typeColors[notifyType] or Theme.Accent
    local icon = typeIcons[notifyType] or "i"
    if typeSounds[notifyType] then PlaySound(typeSounds[notifyType], 0.6) end

    local NotifyGui = CoreGui:FindFirstChild("MagicTulevoNotifications")
    if not NotifyGui then
        NotifyGui = Create("ScreenGui", {Name = "MagicTulevoNotifications", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = CoreGui})
        local NotifyHolder = Create("Frame", {
            Name = "Holder",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 320, 1, -40),
            Position = UDim2.new(1, -340, 0, 20),
            Parent = NotifyGui
        })
        Create("UIListLayout", {Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotifyHolder})
    end

    local Holder = NotifyGui:FindFirstChild("Holder")
    local Notify = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Parent = Holder
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Notify})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = Notify})

    local NotifyGlow = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://5554236805",
        ImageColor3 = color,
        ImageTransparency = 0.9,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = 0,
        Parent = Notify
    })

    local AccentBar = Create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new(0, 4, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BorderSizePixel = 0,
        Parent = Notify
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = AccentBar})

    local IconHolder = Create("Frame", {
        BackgroundColor3 = color,
        BackgroundTransparency = 0.85,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 20, 0, 14),
        Parent = Notify
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = IconHolder})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = icon,
        TextColor3 = color,
        TextSize = 16,
        Parent = IconHolder
    })

    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.new(0, 60, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Notify
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -70, 0, 36),
        Position = UDim2.new(0, 60, 0, 32),
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = Notify
    })

    local ProgressBar = Create("Frame", {
        BackgroundColor3 = color,
        BackgroundTransparency = 0.7,
        Size = UDim2.new(1, -16, 0, 3),
        Position = UDim2.new(0, 8, 1, -8),
        BorderSizePixel = 0,
        Parent = Notify
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = ProgressBar})
    local ProgressFill = Create("Frame", {
        BackgroundColor3 = color,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = ProgressBar
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = ProgressFill})

    Notify.Position = UDim2.new(1, 50, 0, 0)
    Tween(Notify, 0.5, {Size = UDim2.new(1, 0, 0, 80)}, Enum.EasingStyle.Back)
    task.delay(0.1, function()
        Tween(Notify, 0.4, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
    end)
    Tween(ProgressFill, duration, {Size = UDim2.new(0, 0, 1, 0)}, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(Notify, 0.4, {Position = UDim2.new(1, 50, 0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.3, function()
            Tween(Notify, 0.3, {Size = UDim2.new(1, 0, 0, 0)})
            task.delay(0.35, function() Notify:Destroy() end)
        end)
    end)
end

function MagicTulevo:CreateWindow(config)
    config = config or {}
    local Window = {}
    local title = config.Title or "Magic Tulevo"
    local subtitle = config.SubTitle or "Premium UI"
    local logoText = config.Logo or "M"
    local size = config.Size or UDim2.new(0, 620, 0, 420)
    local minSize = config.MinSize or Vector2.new(500, 350)
    local toggleKey = config.ToggleKey or MagicTulevo.ToggleKey
    
    -- Restore saved window position and size
    local savedPosition = nil
    local savedSize = nil
    if MagicTulevo.SavedSettings then
        if MagicTulevo.SavedSettings.WindowSize then
            local ws = MagicTulevo.SavedSettings.WindowSize
            if ws[1] and ws[2] and ws[1] >= minSize.X and ws[2] >= minSize.Y then
                savedSize = UDim2.new(0, ws[1], 0, ws[2])
                size = savedSize
            end
        end
        if MagicTulevo.SavedSettings.WindowPosition then
            local wp = MagicTulevo.SavedSettings.WindowPosition
            if wp[1] and wp[2] then
                savedPosition = UDim2.new(0, wp[1], 0, wp[2])
            end
        end
    end
    Window.Visible = true
    Window.Tabs = {}
    Window.Toggles = {}
    Window.TabOrder = 0
    Window.CurrentTab = nil
    Window.ToggleKey = toggleKey

    local ScreenGui = Create("ScreenGui", {
        Name = "MagicTulevoUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = CoreGui
    })

    -- Shadow is now inside Main to not extend beyond menu
    local MainShadow = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = false, -- Hidden - no shadow outside menu
        Parent = ScreenGui
    })

    local Main = Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = savedPosition and Vector2.new(0, 0) or Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        Parent = ScreenGui
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Main})

    local MainStroke = Create("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = Main
    })

    local AccentTop = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(1, 0, 0, 3),
        BorderSizePixel = 0,
        Parent = Main
    })
    local AccentGradient = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(217, 70, 239)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
        }),
        Parent = AccentTop
    })
    -- OPTIMIZED: Use consolidated animation loop instead of individual connection
    RegisterGradientAnimation(AccentGradient, 0.3)
    -- OPTIMIZED: Delay animation start to reduce startup lag
    task.delay(0.5, function()
        StartAnimationLoop()
    end)

    local Header = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0, 3),
        Parent = Main
    })

    local LogoHolder = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 14, 0.5, -22),
        Parent = Header
    })
    local LogoContainer = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = LogoHolder
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = LogoContainer})
    AddGlow(LogoHolder, Theme.Accent, 20)

    local LogoGradient = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(217, 70, 239)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
        }),
        Rotation = 0,
        Parent = LogoContainer
    })
    -- OPTIMIZED: Removed logo rotation animation - static gradient for better startup performance
    local LogoLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = logoText,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = #logoText > 1 and 16 or 20,
        Parent = LogoContainer
    })

    local TitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 250, 0, 22),
        Position = UDim2.new(0, 68, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header
    })
    local SubTitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 250, 0, 16),
        Position = UDim2.new(0, 68, 0, 34),
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header
    })
    
    -- Store references for dynamic updates
    Window.TitleLabel = TitleLabel
    Window.SubTitleLabel = SubTitleLabel
    Window.LogoLabel = LogoLabel
    Window.Title = title
    Window.SubTitle = subtitle
    Window.Logo = logoText

    local HeaderButtons = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 216, 0, 32),
        Position = UDim2.new(1, -192, 0.5, -16),
        Parent = Header
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = HeaderButtons
    })

    -- UI Elements table (consolidated to reduce local variables)
    local UI = {
        SearchBtnContainer = nil,
        SearchBtn = nil,
        SearchIcon = nil,
        SearchTooltip = nil,
        ConfigsBtnContainer = nil,
        ConfigsBtn = nil,
        ConfigsIcon = nil,
        ConfigsTooltip = nil,
        CustomBtnContainer = nil,
        CustomBtn = nil,
        CustomIcon = nil,
        CustomTooltip = nil,
        SettingsBtnContainer = nil,
        SettingsBtn = nil,
        GearIcon = nil,
        SettingsTooltip = nil,
        InfoBtnContainer = nil,
        InfoBtn = nil,
        InfoIcon = nil,
        InfoTooltip = nil,
        CloseBtn = nil,
        SearchPanel = nil,
        SearchPanelStroke = nil,
        SearchPanelGlow = nil,
        SearchInput = nil,
        SearchInputContainer = nil,
        SearchInputStroke = nil,
        SearchInputIcon = nil,
        SearchResults = nil,
        SearchCounter = nil,
        ClearBtn = nil,
        -- Animation states
        configsIconRotating = false,
        gearRotation = 0,
        gearRotating = false,
        searchAnimating = false,
        infoShaking = false,
        SearchOpen = false
    }
    
    -- ═══════════════════════════════════════════════════════════════
    -- COLOR PICKER SYSTEM (Rayfield Style)
    -- ═══════════════════════════════════════════════════════════════
    
    -- Custom Theme Colors Storage
    local CustomThemeColors = {
        Background = Color3.fromRGB(13, 13, 18),
        Secondary = Color3.fromRGB(18, 18, 25),
        Card = Color3.fromRGB(24, 24, 34),
        CardHover = Color3.fromRGB(32, 32, 45),
        Accent = Color3.fromRGB(138, 92, 246),
        AccentDark = Color3.fromRGB(108, 62, 216),
        AccentGlow = Color3.fromRGB(168, 122, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(140, 140, 165),
        TextDark = Color3.fromRGB(90, 90, 110),
        Border = Color3.fromRGB(38, 38, 52),
        Success = Color3.fromRGB(34, 197, 94),
        Error = Color3.fromRGB(239, 68, 68),
        Warning = Color3.fromRGB(245, 158, 11)
    }
    
    -- Load saved custom colors
    if MagicTulevo.SavedSettings and MagicTulevo.SavedSettings.CustomThemeColors then
        for key, colorData in pairs(MagicTulevo.SavedSettings.CustomThemeColors) do
            if colorData and colorData[1] and colorData[2] and colorData[3] then
                CustomThemeColors[key] = Color3.fromRGB(colorData[1], colorData[2], colorData[3])
            end
        end
    end
    
    -- HSV to RGB conversion
    local function HSVtoRGB(h, s, v)
        local r, g, b
        local i = math.floor(h * 6)
        local f = h * 6 - i
        local p = v * (1 - s)
        local q = v * (1 - f * s)
        local t = v * (1 - (1 - f) * s)
        i = i % 6
        if i == 0 then r, g, b = v, t, p
        elseif i == 1 then r, g, b = q, v, p
        elseif i == 2 then r, g, b = p, v, t
        elseif i == 3 then r, g, b = p, q, v
        elseif i == 4 then r, g, b = t, p, v
        elseif i == 5 then r, g, b = v, p, q
        end
        return Color3.fromRGB(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    end
    
    -- RGB to HSV conversion
    local function RGBtoHSV(color)
        local r, g, b = color.R, color.G, color.B
        local max, min = math.max(r, g, b), math.min(r, g, b)
        local h, s, v
        v = max
        local d = max - min
        if max == 0 then s = 0 else s = d / max end
        if max == min then
            h = 0
        else
            if max == r then
                h = (g - b) / d
                if g < b then h = h + 6 end
            elseif max == g then
                h = (b - r) / d + 2
            elseif max == b then
                h = (r - g) / d + 4
            end
            h = h / 6
        end
        return h, s, v
    end
    
    -- Create Color Picker Component
    local function CreateColorPicker(parent, colorName, defaultColor, callback)
        local currentColor = defaultColor
        local h, s, v = RGBtoHSV(currentColor)
        local pickerOpen = false
        
        local PickerFrame = Create("Frame", {
            BackgroundColor3 = Theme.Card,
            Size = UDim2.new(1, 0, 0, 36),
            Parent = parent
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = PickerFrame})
        Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = PickerFrame})
        
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -80, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            Font = Enum.Font.GothamMedium,
            Text = colorName,
            TextColor3 = Theme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = PickerFrame
        })
        
        local ColorPreview = Create("Frame", {
            BackgroundColor3 = currentColor,
            Size = UDim2.new(0, 60, 0, 24),
            Position = UDim2.new(1, -72, 0.5, -12),
            Parent = PickerFrame
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = ColorPreview})
        Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = ColorPreview})
        
        local ColorBtn = Create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
            Parent = ColorPreview
        })
        
        -- Expanded picker panel
        local PickerPanel = Create("Frame", {
            BackgroundColor3 = Theme.Secondary,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 4),
            ClipsDescendants = true,
            ZIndex = 50,
            Parent = PickerFrame
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = PickerPanel})
        Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = PickerPanel})
        
        -- Saturation/Value picker (main color square)
        local SVPicker = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            Size = UDim2.new(1, -70, 0, 120),
            Position = UDim2.new(0, 8, 0, 8),
            ZIndex = 51,
            Parent = PickerPanel
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = SVPicker})
        
        -- White gradient (left to right)
        local WhiteGradient = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 52,
            Parent = SVPicker
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = WhiteGradient})
        Create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Parent = WhiteGradient
        })
        
        -- Black gradient (top to bottom)
        local BlackGradient = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 53,
            Parent = SVPicker
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = BlackGradient})
        Create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0)
            }),
            Rotation = 90,
            Parent = BlackGradient
        })
        
        -- SV Cursor
        local SVCursor = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(s, -6, 1 - v, -6),
            ZIndex = 54,
            Parent = SVPicker
        })
        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SVCursor})
        Create("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Parent = SVCursor})
        
        -- Hue slider (vertical rainbow)
        local HueSlider = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(0, 20, 0, 120),
            Position = UDim2.new(1, -54, 0, 8),
            ZIndex = 51,
            Parent = PickerPanel
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = HueSlider})
        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }),
            Rotation = 90,
            Parent = HueSlider
        })
        
        -- Hue cursor
        local HueCursor = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(1, 4, 0, 6),
            Position = UDim2.new(0, -2, h, -3),
            ZIndex = 52,
            Parent = HueSlider
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = HueCursor})
        Create("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Parent = HueCursor})
        
        -- Alpha slider
        local AlphaSlider = Create("Frame", {
            BackgroundColor3 = currentColor,
            Size = UDim2.new(0, 20, 0, 120),
            Position = UDim2.new(1, -28, 0, 8),
            ZIndex = 51,
            Parent = PickerPanel
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = AlphaSlider})
        Create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Rotation = 90,
            Parent = AlphaSlider
        })
        
        -- RGB Input fields
        local RGBContainer = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 28),
            Position = UDim2.new(0, 8, 0, 136),
            ZIndex = 51,
            Parent = PickerPanel
        })
        
        local function CreateRGBInput(name, pos, defaultVal)
            local InputFrame = Create("Frame", {
                BackgroundColor3 = Theme.Background,
                Size = UDim2.new(0.3, -4, 1, 0),
                Position = pos,
                ZIndex = 51,
                Parent = RGBContainer
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = InputFrame})
            
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 14, 1, 0),
                Position = UDim2.new(0, 4, 0, 0),
                Font = Enum.Font.GothamBold,
                Text = name,
                TextColor3 = Theme.TextMuted,
                TextSize = 10,
                ZIndex = 52,
                Parent = InputFrame
            })
            
            local Input = Create("TextBox", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 18, 0, 0),
                Font = Enum.Font.GothamMedium,
                Text = tostring(defaultVal),
                TextColor3 = Theme.Text,
                TextSize = 11,
                ClearTextOnFocus = false,
                ZIndex = 52,
                Parent = InputFrame
            })
            
            return Input
        end
        
        local RInput = CreateRGBInput("R", UDim2.new(0, 0, 0, 0), math.floor(currentColor.R * 255))
        local GInput = CreateRGBInput("G", UDim2.new(0.35, 0, 0, 0), math.floor(currentColor.G * 255))
        local BInput = CreateRGBInput("B", UDim2.new(0.7, 0, 0, 0), math.floor(currentColor.B * 255))
        
        -- Hex input
        local HexFrame = Create("Frame", {
            BackgroundColor3 = Theme.Background,
            Size = UDim2.new(1, -16, 0, 28),
            Position = UDim2.new(0, 8, 0, 170),
            ZIndex = 51,
            Parent = PickerPanel
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = HexFrame})
        
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            Font = Enum.Font.GothamBold,
            Text = "#",
            TextColor3 = Theme.TextMuted,
            TextSize = 12,
            ZIndex = 52,
            Parent = HexFrame
        })
        
        local HexInput = Create("TextBox", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 26, 0, 0),
            Font = Enum.Font.GothamMedium,
            Text = string.format("%02X%02X%02X", math.floor(currentColor.R * 255), math.floor(currentColor.G * 255), math.floor(currentColor.B * 255)),
            TextColor3 = Theme.Text,
            TextSize = 12,
            ClearTextOnFocus = false,
            ZIndex = 52,
            Parent = HexFrame
        })
        
        -- Update functions
        local function UpdateColor()
            currentColor = HSVtoRGB(h, s, v)
            ColorPreview.BackgroundColor3 = currentColor
            SVPicker.BackgroundColor3 = HSVtoRGB(h, 1, 1)
            AlphaSlider.BackgroundColor3 = currentColor
            SVCursor.Position = UDim2.new(s, -6, 1 - v, -6)
            HueCursor.Position = UDim2.new(0, -2, h, -3)
            
            RInput.Text = tostring(math.floor(currentColor.R * 255))
            GInput.Text = tostring(math.floor(currentColor.G * 255))
            BInput.Text = tostring(math.floor(currentColor.B * 255))
            HexInput.Text = string.format("%02X%02X%02X", math.floor(currentColor.R * 255), math.floor(currentColor.G * 255), math.floor(currentColor.B * 255))
            
            if callback then
                callback(currentColor)
            end
        end
        
        local function UpdateFromRGB()
            local r = math.clamp(tonumber(RInput.Text) or 0, 0, 255)
            local g = math.clamp(tonumber(GInput.Text) or 0, 0, 255)
            local b = math.clamp(tonumber(BInput.Text) or 0, 0, 255)
            currentColor = Color3.fromRGB(r, g, b)
            h, s, v = RGBtoHSV(currentColor)
            UpdateColor()
        end
        
        local function UpdateFromHex()
            local hex = HexInput.Text:gsub("#", "")
            if #hex == 6 then
                local r = tonumber(hex:sub(1, 2), 16) or 0
                local g = tonumber(hex:sub(3, 4), 16) or 0
                local b = tonumber(hex:sub(5, 6), 16) or 0
                currentColor = Color3.fromRGB(r, g, b)
                h, s, v = RGBtoHSV(currentColor)
                UpdateColor()
            end
        end
        
        -- Input connections
        RInput.FocusLost:Connect(UpdateFromRGB)
        GInput.FocusLost:Connect(UpdateFromRGB)
        BInput.FocusLost:Connect(UpdateFromRGB)
        HexInput.FocusLost:Connect(UpdateFromHex)
        
        -- SV Picker interaction
        local svDragging = false
        SVPicker.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = true
                -- Update on initial click
                local relX = math.clamp((input.Position.X - SVPicker.AbsolutePosition.X) / SVPicker.AbsoluteSize.X, 0, 1)
                local relY = math.clamp((input.Position.Y - SVPicker.AbsolutePosition.Y) / SVPicker.AbsoluteSize.Y, 0, 1)
                s = relX
                v = 1 - relY
                UpdateColor()
            end
        end)
        SVPicker.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = false
            end
        end)
        
        -- Hue slider interaction
        local hueDragging = false
        HueSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDragging = true
                -- Update on initial click
                local relY = math.clamp((input.Position.Y - HueSlider.AbsolutePosition.Y) / HueSlider.AbsoluteSize.Y, 0, 1)
                h = relY
                UpdateColor()
            end
        end)
        HueSlider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                hueDragging = false
            end
        end)
        
        -- Global input ended to stop dragging when mouse released anywhere
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                svDragging = false
                hueDragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if svDragging then
                    local relX = math.clamp((input.Position.X - SVPicker.AbsolutePosition.X) / SVPicker.AbsoluteSize.X, 0, 1)
                    local relY = math.clamp((input.Position.Y - SVPicker.AbsolutePosition.Y) / SVPicker.AbsoluteSize.Y, 0, 1)
                    s = relX
                    v = 1 - relY
                    UpdateColor()
                elseif hueDragging then
                    local relY = math.clamp((input.Position.Y - HueSlider.AbsolutePosition.Y) / HueSlider.AbsoluteSize.Y, 0, 1)
                    h = relY
                    UpdateColor()
                end
            end
        end)
        
        -- Toggle picker
        ColorBtn.MouseButton1Click:Connect(function()
            pickerOpen = not pickerOpen
            if pickerOpen then
                Tween(PickerPanel, 0.3, {Size = UDim2.new(1, 0, 0, 210)}, Enum.EasingStyle.Back)
            else
                Tween(PickerPanel, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
            end
        end)
        
        -- Hover effects
        ColorBtn.MouseEnter:Connect(function()
            Tween(PickerFrame, 0.15, {BackgroundColor3 = Theme.CardHover})
        end)
        ColorBtn.MouseLeave:Connect(function()
            Tween(PickerFrame, 0.15, {BackgroundColor3 = Theme.Card})
        end)
        
        -- Return object with methods
        return {
            Frame = PickerFrame,
            SetColor = function(color)
                currentColor = color
                h, s, v = RGBtoHSV(color)
                UpdateColor()
            end,
            GetColor = function()
                return currentColor
            end
        }
    end

    -- Search Button Container
    UI.SearchBtnContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        ClipsDescendants = false,
        Parent = HeaderButtons
    })
    UI.SearchBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.TextMuted,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = UI.SearchBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = UI.SearchBtn})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = UI.SearchBtn})
    
    -- Search Icon (magnifying glass)
    UI.SearchIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(964, 324),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Theme.TextMuted,
        Parent = UI.SearchBtn
    })
    
    -- Search Tooltip (appears to the left)
    UI.SearchTooltip = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 0, 0, 26),
        Position = UDim2.new(0, -6, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ClipsDescendants = true,
        Parent = UI.SearchBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = UI.SearchTooltip})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = UI.SearchTooltip})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Search",
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = UI.SearchTooltip
    })

    -- Configs Button Container (between Search and Settings)
    UI.ConfigsBtnContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        ClipsDescendants = false,
        Parent = HeaderButtons
    })
    UI.ConfigsBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.TextMuted,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = UI.ConfigsBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = UI.ConfigsBtn})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = UI.ConfigsBtn})
    
    -- Configs Icon (folder/file icon)
    UI.ConfigsIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://3926307971",
        ImageRectOffset = Vector2.new(564, 244),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Theme.TextMuted,
        Parent = UI.ConfigsBtn
    })
    
    -- Configs Tooltip
    UI.ConfigsTooltip = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 0, 0, 26),
        Position = UDim2.new(0, -6, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ClipsDescendants = true,
        Parent = UI.ConfigsBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = UI.ConfigsTooltip})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = UI.ConfigsTooltip})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Configs",
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = UI.ConfigsTooltip
    })
    
    -- OPTIMIZED: Configs Button Hover - simplified animation without infinite loop
    UI.ConfigsBtn.MouseEnter:Connect(function()
        Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.CardHover})
        Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.Accent})
        Tween(UI.ConfigsTooltip, 0.3, {Size = UDim2.new(0, 65, 0, 26)}, Enum.EasingStyle.Back)
        -- Single rotation animation instead of infinite loop
        Tween(UI.ConfigsIcon, 0.3, {Rotation = 15}, Enum.EasingStyle.Quad)
    end)
    UI.ConfigsBtn.MouseLeave:Connect(function()
        Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.Card})
        Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.TextMuted, Rotation = 0})
        Tween(UI.ConfigsTooltip, 0.2, {Size = UDim2.new(0, 0, 0, 26)})
    end)

    -- Custom Theme Button Container (between Configs and Settings)
    UI.CustomBtnContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        ClipsDescendants = false,
        Visible = false, -- Hidden by default, shown when Custom theme is selected
        Parent = HeaderButtons
    })
    UI.CustomBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.TextMuted,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = UI.CustomBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = UI.CustomBtn})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = UI.CustomBtn})
    
    -- Custom Icon (palette/brush icon)
    UI.CustomIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://3926307971",
        ImageRectOffset = Vector2.new(404, 164),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Theme.TextMuted,
        Parent = UI.CustomBtn
    })
    
    -- Custom Tooltip
    UI.CustomTooltip = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 0, 0, 26),
        Position = UDim2.new(0, -6, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ClipsDescendants = true,
        Parent = UI.CustomBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = UI.CustomTooltip})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = UI.CustomTooltip})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Custom",
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = UI.CustomTooltip
    })
    
    -- Custom Button Hover
    UI.CustomBtn.MouseEnter:Connect(function()
        Tween(UI.CustomBtn, 0.2, {BackgroundColor3 = Theme.CardHover})
        Tween(UI.CustomIcon, 0.2, {ImageColor3 = Theme.Accent})
        Tween(UI.CustomTooltip, 0.3, {Size = UDim2.new(0, 65, 0, 26)}, Enum.EasingStyle.Back)
        Tween(UI.CustomIcon, 0.3, {Rotation = 15}, Enum.EasingStyle.Quad)
    end)
    UI.CustomBtn.MouseLeave:Connect(function()
        Tween(UI.CustomBtn, 0.2, {BackgroundColor3 = Theme.Card})
        Tween(UI.CustomIcon, 0.2, {ImageColor3 = Theme.TextMuted, Rotation = 0})
        Tween(UI.CustomTooltip, 0.2, {Size = UDim2.new(0, 0, 0, 26)})
    end)

    -- Settings Button Container
    UI.SettingsBtnContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        ClipsDescendants = false,
        Parent = HeaderButtons
    })
    UI.SettingsBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.TextMuted,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = UI.SettingsBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = UI.SettingsBtn})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = UI.SettingsBtn})
    
    -- Settings Gear Icon (detailed like Rayfield)
    UI.GearIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0.5, -9, 0.5, -9),
        Image = "rbxassetid://3926307971",
        ImageRectOffset = Vector2.new(324, 124),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Theme.TextMuted,
        Parent = UI.SettingsBtn
    })
    
    -- Settings Tooltip (appears to the left)
    UI.SettingsTooltip = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 0, 0, 26),
        Position = UDim2.new(0, -6, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ClipsDescendants = true,
        Parent = UI.SettingsBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = UI.SettingsTooltip})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = UI.SettingsTooltip})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Settings",
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = UI.SettingsTooltip
    })

    -- Info Button Container
    UI.InfoBtnContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        ClipsDescendants = false,
        Parent = HeaderButtons
    })
    UI.InfoBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextColor3 = Theme.TextMuted,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = UI.InfoBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = UI.InfoBtn})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = UI.InfoBtn})
    
    -- Info Icon (i in circle)
    UI.InfoIcon = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "i",
        TextColor3 = Theme.TextMuted,
        TextSize = 16,
        Parent = UI.InfoBtn
    })
    
    -- Info Tooltip (appears to the left)
    UI.InfoTooltip = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 0, 0, 26),
        Position = UDim2.new(0, -6, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ClipsDescendants = true,
        Parent = UI.InfoBtnContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = UI.InfoTooltip})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = UI.InfoTooltip})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Info",
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = UI.InfoTooltip
    })
    
    -- OPTIMIZED: Info Button Hover - removed shake animation loop
    UI.InfoBtn.MouseEnter:Connect(function()
        Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.CardHover})
        Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.Accent})
        Tween(UI.InfoTooltip, 0.3, {Size = UDim2.new(0, 50, 0, 26)}, Enum.EasingStyle.Back)
    end)
    UI.InfoBtn.MouseLeave:Connect(function()
        Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.Card})
        Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.TextMuted})
        Tween(UI.InfoTooltip, 0.2, {Size = UDim2.new(0, 0, 0, 26)})
    end)

    UI.CloseBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.TextMuted,
        TextSize = 20,
        AutoButtonColor = false,
        Parent = HeaderButtons
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = UI.CloseBtn})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = UI.CloseBtn})
    
    -- OPTIMIZED: Search Button Hover - simplified animation without infinite backflip loop
    UI.SearchBtn.MouseEnter:Connect(function()
        Tween(UI.SearchBtn, 0.2, {BackgroundColor3 = Theme.CardHover})
        Tween(UI.SearchIcon, 0.2, {ImageColor3 = Theme.Accent})
        Tween(UI.SearchTooltip, 0.3, {Size = UDim2.new(0, 60, 0, 26)}, Enum.EasingStyle.Back)
        -- Single bounce animation instead of infinite loop
        Tween(UI.SearchIcon, 0.2, {Position = UDim2.new(0.5, 0, 0.5, -3)}, Enum.EasingStyle.Back)
    end)
    UI.SearchBtn.MouseLeave:Connect(function()
        Tween(UI.SearchBtn, 0.2, {BackgroundColor3 = Theme.Card})
        Tween(UI.SearchIcon, 0.2, {
            ImageColor3 = Theme.TextMuted,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Rotation = 0,
            Size = UDim2.new(0, 16, 0, 16)
        })
        Tween(UI.SearchTooltip, 0.2, {Size = UDim2.new(0, 0, 0, 26)})
    end)
    
    -- OPTIMIZED: Settings Button Hover - simplified without infinite rotation loop
    UI.SettingsBtn.MouseEnter:Connect(function()
        Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.CardHover})
        Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.Accent})
        Tween(UI.SettingsTooltip, 0.3, {Size = UDim2.new(0, 70, 0, 26)}, Enum.EasingStyle.Back)
        -- Single rotation instead of infinite loop
        Tween(UI.GearIcon, 0.4, {Rotation = 90}, Enum.EasingStyle.Quint)
    end)
    UI.SettingsBtn.MouseLeave:Connect(function()
        Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.Card})
        Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.TextMuted})
        Tween(UI.SettingsTooltip, 0.2, {Size = UDim2.new(0, 0, 0, 26)})
        Tween(UI.GearIcon, 0.3, {Rotation = 0})
    end)
    
    UI.CloseBtn.MouseEnter:Connect(function()
        Tween(UI.CloseBtn, 0.2, {BackgroundColor3 = Theme.Error, TextColor3 = Theme.Text})
    end)
    UI.CloseBtn.MouseLeave:Connect(function()
        Tween(UI.CloseBtn, 0.2, {BackgroundColor3 = Theme.Card, TextColor3 = Theme.TextMuted})
    end)
    UI.CloseBtn.MouseButton1Click:Connect(function()
        -- Full unhook - completely destroy menu and all sounds
        PlaySound("rbxassetid://6895079853", 0.4) -- Close sound
        
        -- Animate close
        Tween(Main, 0.4, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        
        task.delay(0.4, function()
            -- OPTIMIZED: Stop consolidated animation loop
            StopAnimationLoop()
            
            -- Stop all sounds
            for _, sound in pairs(SoundService:GetChildren()) do
                if sound:IsA("Sound") then
                    sound:Stop()
                    sound:Destroy()
                end
            end
            
            -- Disconnect all connections
            for _, conn in pairs(MagicTulevo.Connections) do
                if conn and conn.Connected then
                    conn:Disconnect()
                end
            end
            MagicTulevo.Connections = {}
            
            -- Clear object pools
            for poolName, pool in pairs(ObjectPool) do
                for _, obj in pairs(pool) do
                    if obj and obj.Parent then
                        obj:Destroy()
                    end
                end
                ObjectPool[poolName] = {}
            end
            
            -- Clear TweenInfo cache
            CustomTweenCache = {}
            
            -- Clear theme callbacks
            MagicTulevo.OnThemeChangeCallbacks = {}
            
            -- Destroy all MagicTulevo GUIs (including notifications)
            for _, gui in pairs(CoreGui:GetChildren()) do
                if gui.Name:find("MagicTulevo") then
                    gui:Destroy()
                end
            end
            
            -- Clear windows table
            MagicTulevo.Windows = {}
            
            -- Clear saved settings reference
            MagicTulevo.SavedSettings = {}
            
            -- Notify user
            print("[MagicTulevo] Menu fully unhooked and destroyed - all resources cleaned up")
        end)
    end)
    
    -- Search Panel (Rayfield style)
    UI.SearchPanel = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, -28, 0, 0),
        Position = UDim2.new(0, 14, 0, 68),
        ClipsDescendants = true,
        ZIndex = 10,
        BackgroundTransparency = 1,
        Parent = Main
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = UI.SearchPanel})
    UI.SearchPanelStroke = Create("UIStroke", {Color = Theme.Accent, Thickness = 2, Transparency = 1, Parent = UI.SearchPanel})
    UI.SearchPanelGlow = AddGlow(UI.SearchPanel, Theme.Accent, 20)
    if UI.SearchPanelGlow then UI.SearchPanelGlow.ImageTransparency = 1 end
    
    UI.SearchInputContainer = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, -20, 0, 42),
        Position = UDim2.new(0, 10, 0, 12),
        BackgroundTransparency = 1,
        Parent = UI.SearchPanel
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = UI.SearchInputContainer})
    UI.SearchInputStroke = Create("UIStroke", {Color = Theme.Accent, Thickness = 2, Transparency = 1, Parent = UI.SearchInputContainer})
    
    -- Animated search icon in input
    UI.SearchInputIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(964, 324),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Theme.Accent,
        ImageTransparency = 1,
        Parent = UI.SearchInputContainer
    })
    
    -- Clear button
    UI.ClearBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Error,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -34, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "x",
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        AutoButtonColor = false,
        Visible = false,
        Parent = UI.SearchInputContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = UI.ClearBtn})
    
    UI.SearchInput = Create("TextBox", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 42, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "",
        PlaceholderText = "Search functions, themes...",
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.TextMuted,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = UI.SearchInputContainer
    })
    
    -- Search results counter
    UI.SearchCounter = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.new(0, 10, 0, 58),
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        Parent = UI.SearchPanel
    })
    
    UI.SearchResults = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 240),
        Position = UDim2.new(0, 10, 0, 76),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = UI.SearchPanel
    })
    Create("UIListLayout", {Padding = UDim.new(0, 6), Parent = UI.SearchResults})
    
    -- Search functionality
    Window.AllElements = {}
    Window.AllThemes = {} -- Will be populated after themes are created
    
    -- Smart search function with fuzzy matching
    local function SmartMatch(text, query)
        text = text:lower()
        query = query:lower()
        
        -- Exact match (highest priority)
        if text == query then return 100 end
        
        -- Starts with query (high priority)
        if text:sub(1, #query) == query then return 90 end
        
        -- Contains query as substring
        if text:find(query, 1, true) then return 70 end
        
        -- First letters match (e.g. "dt" matches "Default Theme")
        local words = {}
        for word in text:gmatch("%S+") do
            table.insert(words, word)
        end
        local firstLetters = ""
        for _, word in ipairs(words) do
            firstLetters = firstLetters .. word:sub(1, 1)
        end
        if firstLetters:find(query, 1, true) then return 60 end
        
        -- Fuzzy match - all query chars appear in order
        local queryIdx = 1
        for i = 1, #text do
            if text:sub(i, i) == query:sub(queryIdx, queryIdx) then
                queryIdx = queryIdx + 1
                if queryIdx > #query then return 40 end
            end
        end
        
        -- Partial word match
        for word in text:gmatch("%S+") do
            if word:find(query, 1, true) then return 30 end
        end
        
        return 0
    end
    
    local CloseSearch
    local ApplyTheme
    local CurrentThemeIndex = 1
    
    local function UpdateSearch(query)
        for _, child in pairs(UI.SearchResults:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        if query == "" then 
            UI.SearchResults.CanvasSize = UDim2.new(0, 0, 0, 0)
            UI.SearchCounter.Text = ""
            UI.ClearBtn.Visible = false
            return 
        end
        
        UI.ClearBtn.Visible = true
        query = query:lower()
        
        -- Collect and score all matches
        local matches = {}
        
        -- Search through regular elements
        for _, element in pairs(Window.AllElements) do
            local score = SmartMatch(element.Name, query)
            if element.TabName then
                score = math.max(score, SmartMatch(element.TabName, query) * 0.5)
            end
            if element.Type then
                score = math.max(score, SmartMatch(element.Type, query) * 0.3)
            end
            if score > 0 then
                table.insert(matches, {data = element, score = score, isTheme = false})
            end
        end
        
        -- Search through themes
        for _, themeData in pairs(Window.AllThemes) do
            local score = SmartMatch(themeData.Name, query)
            -- Boost gradient themes when searching "gradient"
            if query:find("grad") and themeData.IsGradient then score = score + 50 end
            -- Boost christmas themes when searching "christmas" or "holiday"
            if (query:find("christ") or query:find("holid") or query:find("new") or query:find("winter")) and themeData.IsChristmas then score = score + 50 end
            if score > 0 then
                table.insert(matches, {data = themeData, score = score, isTheme = true})
            end
        end
        
        -- Sort by score
        table.sort(matches, function(a, b) return a.score > b.score end)
        
        local found = 0
        local totalHeight = 0
        local maxResults = 6
        
        local typeIcons = {
            Button = ">",
            Toggle = "o",
            Slider = "-",
            Dropdown = "v",
            Keybind = "K",
            TextBox = "T"
        }
        local typeColors = {
            Button = Theme.Accent,
            Toggle = Theme.Success,
            Slider = Theme.Warning,
            Dropdown = Color3.fromRGB(147, 112, 219),
            Keybind = Color3.fromRGB(255, 165, 0),
            TextBox = Color3.fromRGB(100, 149, 237)
        }
        
        for idx, match in ipairs(matches) do
            if found >= maxResults then break end
            found = found + 1
            
            if match.isTheme then
                -- Theme result card with description
                local themeData = match.data
                local themeDesc = themeData.Description or ""
                if themeDesc == "" then
                    -- Auto-generate description
                    if themeData.IsGradient then
                        themeDesc = "Beautiful gradient theme with " .. #(themeData.GradientColors or {}) .. " colors"
                    elseif themeData.IsChristmas then
                        themeDesc = "Festive holiday theme for the season"
                    else
                        themeDesc = "Clean and elegant color scheme"
                    end
                end
                
                local ResultItem = Create("Frame", {
                    BackgroundColor3 = themeData.Colors.Card,
                    Size = UDim2.new(1, 0, 0, 88),
                    BackgroundTransparency = 1,
                    Parent = UI.SearchResults
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = ResultItem})
                Create("UIStroke", {Color = themeData.Colors.Accent, Thickness = 1, Transparency = 0.3, Parent = ResultItem})
                
                -- Animate appearance
                task.delay(idx * 0.05, function()
                    Tween(ResultItem, 0.3, {BackgroundTransparency = 0}, Enum.EasingStyle.Back)
                end)
                
                -- Accent bar at top
                local AccentBar = Create("Frame", {
                    BackgroundColor3 = themeData.Colors.Accent,
                    Size = UDim2.new(1, 0, 0, 4),
                    Position = UDim2.new(0, 0, 0, 0),
                    Parent = ResultItem
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = AccentBar})
                
                if themeData.IsGradient and themeData.GradientColors then
                    local keypoints = {}
                    for j, color in ipairs(themeData.GradientColors) do
                        table.insert(keypoints, ColorSequenceKeypoint.new((j-1)/(#themeData.GradientColors-1), color))
                    end
                    Create("UIGradient", {
                        Color = ColorSequence.new(keypoints),
                        Rotation = themeData.GradientRotation or 0,
                        Parent = AccentBar
                    })
                end
                
                -- Color palette dots
                local DotsContainer = Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 80, 0, 20),
                    Position = UDim2.new(0, 8, 0, 12),
                    Parent = ResultItem
                })
                Create("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDim.new(0, 6),
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Parent = DotsContainer
                })
                
                local paletteColors = {themeData.Colors.Accent, themeData.Colors.AccentDark, themeData.Colors.AccentGlow}
                for _, color in ipairs(paletteColors) do
                    local Dot = Create("Frame", {
                        BackgroundColor3 = color,
                        Size = UDim2.new(0, 14, 0, 14),
                        Parent = DotsContainer
                    })
                    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Dot})
                end
                
                -- Theme name
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -100, 0, 16),
                    Position = UDim2.new(0, 8, 0, 34),
                    Font = Enum.Font.GothamBold,
                    Text = themeData.Name,
                    TextColor3 = themeData.Colors.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ResultItem
                })
                
                -- Theme description
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -16, 0, 14),
                    Position = UDim2.new(0, 8, 0, 52),
                    Font = Enum.Font.Gotham,
                    Text = themeDesc,
                    TextColor3 = themeData.Colors.TextMuted,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = ResultItem
                })
                
                -- Info badges
                local infoText = "Settings"
                if themeData.IsGradient then infoText = infoText .. "  |  Gradient" end
                if themeData.IsChristmas then infoText = infoText .. "  |  Holiday" end
                
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -16, 0, 12),
                    Position = UDim2.new(0, 8, 0, 70),
                    Font = Enum.Font.Gotham,
                    Text = infoText,
                    TextColor3 = themeData.Colors.TextDark,
                    TextSize = 9,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ResultItem
                })
                
                -- Click hint
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 60, 0, 12),
                    Position = UDim2.new(1, -68, 0, 12),
                    Font = Enum.Font.Gotham,
                    Text = "LMB Apply",
                    TextColor3 = themeData.Colors.TextDark,
                    TextSize = 8,
                    Parent = ResultItem
                })
                
                local ResultBtn = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ResultItem
                })
                ResultBtn.MouseEnter:Connect(function()
                    Tween(ResultItem, 0.15, {BackgroundColor3 = themeData.Colors.CardHover})
                end)
                ResultBtn.MouseLeave:Connect(function()
                    Tween(ResultItem, 0.15, {BackgroundColor3 = themeData.Colors.Card})
                end)
                ResultBtn.MouseButton1Click:Connect(function()
                    -- LMB: Apply theme
                    for i, t in ipairs(Window.AllThemes) do
                        if t.Name == themeData.Name then
                            CurrentThemeIndex = i
                            ApplyTheme(themeData)
                            break
                        end
                    end
                    CloseSearch()
                end)
                totalHeight = totalHeight + 94
            else
                -- Regular element result card with description
                local element = match.data
                local elemDesc = element.Description or ""
                local hasDesc = elemDesc ~= ""
                local cardHeight = hasDesc and 68 or 52
                
                local ResultItem = Create("Frame", {
                    BackgroundColor3 = Theme.Card,
                    Size = UDim2.new(1, 0, 0, cardHeight),
                    BackgroundTransparency = 1,
                    Parent = UI.SearchResults
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = ResultItem})
                local ResultStroke = Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = ResultItem})
                
                -- Flash overlay for ping effect
                local FlashOverlay = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 5,
                    Parent = ResultItem
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = FlashOverlay})
                
                -- Animate appearance
                task.delay(idx * 0.05, function()
                    Tween(ResultItem, 0.3, {BackgroundTransparency = 0}, Enum.EasingStyle.Back)
                end)
                
                local IconBg = Create("Frame", {
                    BackgroundColor3 = typeColors[element.Type] or Theme.Accent,
                    BackgroundTransparency = 0.85,
                    Size = UDim2.new(0, 36, 0, 36),
                    Position = UDim2.new(0, 8, 0, 8),
                    Parent = ResultItem
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = IconBg})
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.GothamBold,
                    Text = typeIcons[element.Type] or "*",
                    TextColor3 = typeColors[element.Type] or Theme.Accent,
                    TextSize = 16,
                    Parent = IconBg
                })
                
                -- Toggle state indicator for toggles
                local StateIndicator = nil
                if element.Type == "Toggle" and element.ToggleObj then
                    StateIndicator = Create("Frame", {
                        BackgroundColor3 = element.ToggleObj.Value and Theme.Success or Theme.Error,
                        Size = UDim2.new(0, 8, 0, 8),
                        Position = UDim2.new(0, 40, 0, 8),
                        Parent = ResultItem
                    })
                    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = StateIndicator})
                end
                
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -120, 0, 16),
                    Position = UDim2.new(0, 52, 0, 8),
                    Font = Enum.Font.GothamBold,
                    Text = element.Name,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = ResultItem
                })
                
                local tabName = element.TabName or "Unknown"
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -120, 0, 12),
                    Position = UDim2.new(0, 52, 0, 26),
                    Font = Enum.Font.Gotham,
                    Text = "[" .. tabName .. "]  |  " .. (element.Type or "Element"),
                    TextColor3 = Theme.TextMuted,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ResultItem
                })
                
                -- Description if exists
                if hasDesc then
                    Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -60, 0, 14),
                        Position = UDim2.new(0, 52, 0, 42),
                        Font = Enum.Font.Gotham,
                        Text = "> " .. elemDesc,
                        TextColor3 = Theme.TextDark,
                        TextSize = 9,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = ResultItem
                    })
                end
                
                -- Click hints
                local HintText = "LMB"
                if element.Type == "Toggle" then
                    HintText = "LMB Toggle"
                elseif element.Type == "Button" then
                    HintText = "LMB Click"
                else
                    HintText = "RMB Go to"
                end
                
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 55, 0, 10),
                    Position = UDim2.new(1, -60, 0, 8),
                    Font = Enum.Font.Gotham,
                    Text = HintText,
                    TextColor3 = Theme.TextDark,
                    TextSize = 8,
                    Parent = ResultItem
                })
                
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 55, 0, 10),
                    Position = UDim2.new(1, -60, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = "RMB Go to",
                    TextColor3 = Theme.TextDark,
                    TextSize = 8,
                    Parent = ResultItem
                })
                
                local ResultBtn = Create("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ResultItem
                })
                ResultBtn.MouseEnter:Connect(function()
                    Tween(ResultItem, 0.15, {BackgroundColor3 = Theme.CardHover})
                    Tween(ResultStroke, 0.15, {Color = Theme.Accent})
                end)
                ResultBtn.MouseLeave:Connect(function()
                    Tween(ResultItem, 0.15, {BackgroundColor3 = Theme.Card})
                    Tween(ResultStroke, 0.15, {Color = Theme.Border})
                end)
                
                -- LMB: Toggle/Click function
                ResultBtn.MouseButton1Click:Connect(function()
                    if element.Type == "Toggle" and element.ToggleObj then
                        element.ToggleObj.Value = not element.ToggleObj.Value
                        if element.ToggleObj.Update then
                            element.ToggleObj:Update()
                        end
                        if StateIndicator then
                            local targetColor = element.ToggleObj.Value and Theme.Success or Theme.Error
                            Tween(StateIndicator, 0.15, {Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 38, 0, 6)}, Enum.EasingStyle.Back)
                            task.delay(0.15, function()
                                Tween(StateIndicator, 0.2, {BackgroundColor3 = targetColor, Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 40, 0, 8)}, Enum.EasingStyle.Back)
                            end)
                        end
                        Tween(FlashOverlay, 0.08, {BackgroundTransparency = 0.5})
                        Tween(ResultItem, 0.08, {Size = UDim2.new(1, 4, 0, cardHeight + 2), Position = UDim2.new(0, -2, 0, -1)})
                        task.delay(0.08, function()
                            Tween(FlashOverlay, 0.25, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
                            Tween(ResultItem, 0.2, {Size = UDim2.new(1, 0, 0, cardHeight), Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
                        end)
                        PlaySound("rbxassetid://6895079853", 0.25)
                    elseif element.Type == "Button" then
                        if element.Callback then
                            element.Callback()
                        end
                        Tween(FlashOverlay, 0.06, {BackgroundTransparency = 0.4})
                        Tween(ResultItem, 0.06, {BackgroundColor3 = Theme.Accent})
                        task.delay(0.1, function()
                            Tween(FlashOverlay, 0.2, {BackgroundTransparency = 1})
                            Tween(ResultItem, 0.15, {BackgroundColor3 = Theme.Card})
                        end)
                        PlaySound("rbxassetid://6895079853", 0.3)
                        task.delay(0.25, function()
                            CloseSearch()
                        end)
                    elseif element.Type == "Slider" or element.Type == "Dropdown" or element.Type == "Keybind" or element.Type == "TextBox" then
                        CloseSearch()
                        PlaySound("rbxassetid://6895079853", 0.3)
                        if element.Tab then
                            element.Tab:Select()
                        end
                        task.delay(0.35, function()
                            if element.UIElement and element.UIElement.Parent then
                                local uiElem = element.UIElement
                                if element.Tab and element.Tab.Content then
                                    local content = element.Tab.Content
                                    local elemPos = uiElem.AbsolutePosition.Y - content.AbsolutePosition.Y
                                    Tween(content, 0.4, {CanvasPosition = Vector2.new(0, math.max(0, elemPos - 60))}, Enum.EasingStyle.Quint)
                                end
                                task.delay(0.2, function()
                                    local HighlightBorder = Create("UIStroke", {
                                        Color = Theme.Accent,
                                        Thickness = 0,
                                        Transparency = 0,
                                        Parent = uiElem
                                    })
                                    Tween(HighlightBorder, 0.3, {Thickness = 3}, Enum.EasingStyle.Back)
                                    task.delay(1.5, function()
                                        Tween(HighlightBorder, 0.4, {Thickness = 0, Transparency = 1})
                                        task.delay(0.4, function()
                                            if HighlightBorder then HighlightBorder:Destroy() end
                                        end)
                                    end)
                                end)
                            end
                        end)
                    else
                        if element.Tab then
                            element.Tab:Select()
                        end
                        CloseSearch()
                    end
                end)
                
                -- RMB: Go to element and ping it
                -- Debounce to prevent multiple pings
                local isPinging = false
                ResultBtn.MouseButton2Click:Connect(function()
                    if isPinging then return end -- Prevent multiple pings
                    isPinging = true
                    
                    CloseSearch()
                    PlaySound("rbxassetid://6895079853", 0.3)
          
                    if element.Tab then
                        for _, t in pairs(Window.Tabs) do
                            if t == element.Tab then
                                t:Select()
                                break
                            end
                        end
                    end
                    
                    task.delay(0.35, function()
                        if element.UIElement and element.UIElement.Parent then
                            local uiElem = element.UIElement
                            
                            if element.Tab and element.Tab.Content then
                                local content = element.Tab.Content
                                local elemPos = uiElem.AbsolutePosition.Y - content.AbsolutePosition.Y
                                Tween(content, 0.4, {CanvasPosition = Vector2.new(0, math.max(0, elemPos - 60))}, Enum.EasingStyle.Quint)
                            end
                            
                            task.delay(0.2, function()
                                -- Elegant single ping animation
                                local PingContainer = Create("Frame", {
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(1, 40, 1, 40),
                                    Position = UDim2.new(0.5, 0, 0.5, 0),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    ZIndex = 20,
                                    Parent = uiElem
                                })
                                
                                -- Main glow overlay
                                local PingOverlay = Create("Frame", {
                                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(0, 0, 0, 0),
                                    Position = UDim2.new(0.5, 0, 0.5, 0),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    ZIndex = 15,
                                    Parent = PingContainer
                                })
                                Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = PingOverlay})
                                
                                -- Elegant border stroke
                                local PingStroke = Create("UIStroke", {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Thickness = 0,
                                    Transparency = 1,
                                    Parent = PingOverlay
                                })
                                
                                -- Soft outer glow
                                local PingGlow = Create("ImageLabel", {
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(1.2, 0, 1.2, 0),
                                    Position = UDim2.new(0.5, 0, 0.5, 0),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    Image = "rbxassetid://5554236805",
                                    ImageColor3 = Color3.fromRGB(255, 255, 255),
                                    ImageTransparency = 1,
                                    ScaleType = Enum.ScaleType.Slice,
                                    SliceCenter = Rect.new(23, 23, 277, 277),
                                    ZIndex = 14,
                                    Parent = PingContainer
                                })
                                
                                -- Single elegant expanding ring
                                local Ring = Create("Frame", {
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(0.8, 0, 0.8, 0),
                                    Position = UDim2.new(0.5, 0, 0.5, 0),
                                    AnchorPoint = Vector2.new(0.5, 0.5),
                                    ZIndex = 13,
                                    Parent = PingContainer
                                })
                                Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Ring})
                                local RingStroke = Create("UIStroke", {
                                    Color = Color3.fromRGB(255, 255, 255),
                                    Thickness = 2,
                                    Transparency = 0.5,
                                    Parent = Ring
                                })
                                
                                -- Smooth appearance animation
                                Tween(PingOverlay, 0.35, {
                                    Size = UDim2.new(1, 12, 1, 12), 
                                    BackgroundTransparency = 0.88
                                }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                                Tween(PingStroke, 0.3, {Transparency = 0.3, Thickness = 2})
                                Tween(PingGlow, 0.35, {ImageTransparency = 0.7, Size = UDim2.new(1.6, 0, 1.6, 0)}, Enum.EasingStyle.Quint)
                                
                                -- Ring expansion
                                task.delay(0.1, function()
                                    if not Ring or not Ring.Parent then return end
                                    Tween(Ring, 0.7, {Size = UDim2.new(1.8, 0, 1.8, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                                    Tween(RingStroke, 0.7, {Transparency = 1, Thickness = 0.5}, Enum.EasingStyle.Quint)
                                end)
                                
                                -- First pulse
                                task.delay(0.4, function()
                                    if not PingOverlay or not PingOverlay.Parent then return end
                                    Tween(PingOverlay, 0.2, {
                                        Size = UDim2.new(1, 18, 1, 18),
                                        BackgroundTransparency = 0.82
                                    }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                                    Tween(PingStroke, 0.2, {Thickness = 2.5, Transparency = 0.2})
                                    Tween(PingGlow, 0.2, {ImageTransparency = 0.6, Size = UDim2.new(1.8, 0, 1.8, 0)})
                                    
                                    task.delay(0.2, function()
                                        if not PingOverlay or not PingOverlay.Parent then return end
                                        Tween(PingOverlay, 0.25, {
                                            Size = UDim2.new(1, 12, 1, 12),
                                            BackgroundTransparency = 0.88
                                        }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                                        Tween(PingStroke, 0.25, {Thickness = 2, Transparency = 0.3})
                                        Tween(PingGlow, 0.25, {ImageTransparency = 0.7, Size = UDim2.new(1.6, 0, 1.6, 0)})
                                    end)
                                end)
                                
                                -- Second pulse
                                task.delay(0.9, function()
                                    if not PingOverlay or not PingOverlay.Parent then return end
                                    Tween(PingOverlay, 0.2, {
                                        Size = UDim2.new(1, 18, 1, 18),
                                        BackgroundTransparency = 0.82
                                    }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                                    Tween(PingStroke, 0.2, {Thickness = 2.5, Transparency = 0.2})
                                    Tween(PingGlow, 0.2, {ImageTransparency = 0.6, Size = UDim2.new(1.8, 0, 1.8, 0)})
                                    
                                    task.delay(0.2, function()
                                        if not PingOverlay or not PingOverlay.Parent then return end
                                        Tween(PingOverlay, 0.25, {
                                            Size = UDim2.new(1, 12, 1, 12),
                                            BackgroundTransparency = 0.88
                                        }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                                        Tween(PingStroke, 0.25, {Thickness = 2, Transparency = 0.3})
                                        Tween(PingGlow, 0.25, {ImageTransparency = 0.7, Size = UDim2.new(1.6, 0, 1.6, 0)})
                                    end)
                                end)
                                
                                -- Elegant fade out
                                task.delay(1.5, function()
                                    if PingContainer and PingContainer.Parent then
                                        Tween(PingOverlay, 0.4, {
                                            BackgroundTransparency = 1, 
                                            Size = UDim2.new(0.6, 0, 0.6, 0)
                                        }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
                                        Tween(PingStroke, 0.35, {Transparency = 1, Thickness = 0})
                                        Tween(PingGlow, 0.4, {ImageTransparency = 1, Size = UDim2.new(2, 0, 2, 0)})
                                        task.delay(0.4, function()
                                            if PingContainer then PingContainer:Destroy() end
                                            isPinging = false
                                        end)
                                    else
                                        isPinging = false
                                    end
                                end)
                            end)
                        end
                    end)
                end)
                
                totalHeight = totalHeight + cardHeight + 6
            end
        end
        
        -- Update counter
        local totalMatches = #matches
        if totalMatches > 0 then
            UI.SearchCounter.Text = "Found " .. totalMatches .. " result" .. (totalMatches > 1 and "s" or "") .. (totalMatches > maxResults and " (showing " .. maxResults .. ")" or "")
        else
            UI.SearchCounter.Text = "No results found"
        end
        
        UI.SearchResults.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end
    
    CloseSearch = function()
        UI.SearchOpen = false
        Tween(UI.SearchPanel, 0.3, {Size = UDim2.new(1, -28, 0, 0), BackgroundTransparency = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        Tween(UI.SearchPanelStroke, 0.2, {Transparency = 1})
        if UI.SearchPanelGlow then Tween(UI.SearchPanelGlow, 0.2, {ImageTransparency = 1}) end
        Tween(UI.SearchInputContainer, 0.2, {BackgroundTransparency = 1})
        Tween(UI.SearchInputStroke, 0.2, {Transparency = 1})
        Tween(UI.SearchInputIcon, 0.2, {ImageTransparency = 1})
        Tween(UI.SearchCounter, 0.2, {TextTransparency = 1})
    end
    
    -- Clear button functionality
    UI.ClearBtn.MouseEnter:Connect(function()
        Tween(UI.ClearBtn, 0.15, {BackgroundTransparency = 0.8, TextColor3 = Theme.Error})
    end)
    UI.ClearBtn.MouseLeave:Connect(function()
        Tween(UI.ClearBtn, 0.15, {BackgroundTransparency = 1, TextColor3 = Theme.TextMuted})
    end)
    UI.ClearBtn.MouseButton1Click:Connect(function()
        UI.SearchInput.Text = ""
        -- Animate clear
        Tween(UI.SearchInputIcon, 0.2, {Rotation = -360})
        task.delay(0.2, function()
            UI.SearchInputIcon.Rotation = 0
        end)
    end)
    
    -- Text input animations with beautiful effects
    local lastTextLength = 0
    local typingParticles = {}
    
    -- OPTIMIZED: Removed keyboard click sound to reduce lag during typing
    -- Sound creation on every keystroke was causing performance issues
    local function PlayKeyboardClick()
        -- Disabled for performance
    end
    
    -- OPTIMIZED: Debounced search update with longer delay to reduce lag
    local DebouncedUpdateSearch = Debounce(function(text)
        UpdateSearch(text)
    end, 0.15) -- 150ms debounce for better performance
    
    UI.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local newLength = #UI.SearchInput.Text
        
        if newLength > lastTextLength then
            -- Play keyboard click sound
            PlayKeyboardClick()
            
            -- Character added - beautiful typing animation
            -- Icon pulse with glow
            Tween(UI.SearchInputIcon, 0.08, {Size = UDim2.new(0, 24, 0, 24), ImageTransparency = 0})
            task.delay(0.08, function()
                Tween(UI.SearchInputIcon, 0.2, {Size = UDim2.new(0, 18, 0, 18)}, Enum.EasingStyle.Back)
            end)
            
            -- Input container glow effect
            Tween(UI.SearchInputStroke, 0.1, {Color = Theme.Accent, Thickness = 2, Transparency = 0})
            Tween(UI.SearchInputContainer, 0.1, {BackgroundColor3 = Theme.CardHover})
            task.delay(0.15, function()
                Tween(UI.SearchInputContainer, 0.2, {BackgroundColor3 = Theme.Card})
            end)
            
            -- OPTIMIZED: Reduced particle effects - only every 5th character and simplified
            if newLength % 5 == 0 then
                local Particle = Create("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(0, 3, 0, 3),
                    Position = UDim2.new(0, 42 + newLength * 6, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    ZIndex = 10,
                    Parent = UI.SearchInputContainer
                })
                Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Particle})
                
                Tween(Particle, 0.3, {
                    Position = UDim2.new(0, 42 + newLength * 6, 0.5, -15),
                    BackgroundTransparency = 1
                }, Enum.EasingStyle.Quint)
                task.delay(0.3, function()
                    if Particle then Particle:Destroy() end
                end)
            end
            
        elseif newLength < lastTextLength then
            -- Character removed - elegant delete animation
            -- Icon shake with color change
            local shakeAmount = 8
            Tween(UI.SearchInputIcon, 0.05, {Position = UDim2.new(0, 14 + shakeAmount, 0.5, 0), ImageColor3 = Theme.Warning})
            task.delay(0.05, function()
                Tween(UI.SearchInputIcon, 0.05, {Position = UDim2.new(0, 14 - shakeAmount, 0.5, 0)})
            end)
            task.delay(0.1, function()
                Tween(UI.SearchInputIcon, 0.15, {Position = UDim2.new(0, 14, 0.5, 0), ImageColor3 = Theme.Accent}, Enum.EasingStyle.Elastic)
            end)
            
            -- Stroke flash warning then back
            Tween(UI.SearchInputStroke, 0.08, {Color = Theme.Warning, Thickness = 3})
            task.delay(0.12, function()
                Tween(UI.SearchInputStroke, 0.25, {Color = Theme.Accent, Thickness = 2})
            end)
        end
        
        -- Text cleared completely - special animation
        if newLength == 0 and lastTextLength > 0 then
            Tween(UI.SearchInputIcon, 0.3, {Rotation = -360}, Enum.EasingStyle.Back)
            task.delay(0.3, function() UI.SearchInputIcon.Rotation = 0 end)
            Tween(UI.SearchInputStroke, 0.3, {Color = Theme.TextMuted, Thickness = 1})
        end
        
        lastTextLength = newLength
        -- OPTIMIZED: Use debounced search
        DebouncedUpdateSearch(UI.SearchInput.Text)
    end)
    
    -- Focus animations
    UI.SearchInput.Focused:Connect(function()
        Tween(UI.SearchInputStroke, 0.2, {Color = Theme.Accent, Thickness = 2, Transparency = 0})
        Tween(UI.SearchInputIcon, 0.3, {Rotation = 360})
        task.delay(0.3, function() UI.SearchInputIcon.Rotation = 0 end)
    end)
    UI.SearchInput.FocusLost:Connect(function()
        Tween(UI.SearchInputStroke, 0.2, {Thickness = 1, Transparency = 0.3})
    end)
    
    UI.SearchBtn.MouseButton1Click:Connect(function()
        UI.SearchOpen = not UI.SearchOpen
        if UI.SearchOpen then
            -- Beautiful open animation
            UI.SearchPanel.BackgroundTransparency = 1
            Tween(UI.SearchPanel, 0.5, {Size = UDim2.new(1, -28, 0, 340), BackgroundTransparency = 0}, Enum.EasingStyle.Back)
            
            -- Staggered element animations
            task.delay(0.1, function()
                Tween(UI.SearchPanelStroke, 0.3, {Transparency = 0.3})
                if UI.SearchPanelGlow then Tween(UI.SearchPanelGlow, 0.4, {ImageTransparency = 0.85}) end
            end)
            task.delay(0.15, function()
                Tween(UI.SearchInputContainer, 0.35, {BackgroundTransparency = 0}, Enum.EasingStyle.Back)
                Tween(UI.SearchInputStroke, 0.3, {Transparency = 0.3})
            end)
            task.delay(0.2, function()
                Tween(UI.SearchInputIcon, 0.4, {ImageTransparency = 0, Rotation = 360}, Enum.EasingStyle.Back)
                task.delay(0.4, function() UI.SearchInputIcon.Rotation = 0 end)
            end)
            task.delay(0.25, function()
                Tween(UI.SearchCounter, 0.3, {TextTransparency = 0})
            end)
            task.delay(0.3, function()
                UI.SearchInput:CaptureFocus()
            end)
        else
            CloseSearch()
        end
    end)

    -- All Themes Definition
    local AllThemes = {
        -- Standard Themes (6+)
        {
            Name = "Default Purple",
            Description = "Classic purple theme with elegant dark tones",
            IsGradient = false,
            Colors = {
                Background = Color3.fromRGB(13, 13, 18),
                Secondary = Color3.fromRGB(18, 18, 25),
                Card = Color3.fromRGB(24, 24, 34),
                CardHover = Color3.fromRGB(32, 32, 45),
                Accent = Color3.fromRGB(138, 92, 246),
                AccentDark = Color3.fromRGB(108, 62, 216),
                AccentGlow = Color3.fromRGB(168, 122, 255),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(140, 140, 165),
                TextDark = Color3.fromRGB(90, 90, 110),
                Border = Color3.fromRGB(38, 38, 52),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Ocean Blue",
            Description = "Deep sea inspired blue color scheme",
            IsGradient = false,
            Colors = {
                Background = Color3.fromRGB(10, 15, 25),
                Secondary = Color3.fromRGB(15, 22, 35),
                Card = Color3.fromRGB(20, 30, 48),
                CardHover = Color3.fromRGB(28, 42, 65),
                Accent = Color3.fromRGB(59, 130, 246),
                AccentDark = Color3.fromRGB(37, 99, 235),
                AccentGlow = Color3.fromRGB(96, 165, 250),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(148, 163, 184),
                TextDark = Color3.fromRGB(71, 85, 105),
                Border = Color3.fromRGB(30, 41, 59),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Emerald Green",
            Description = "Fresh nature-inspired green palette",
            IsGradient = false,
            Colors = {
                Background = Color3.fromRGB(10, 18, 15),
                Secondary = Color3.fromRGB(15, 25, 20),
                Card = Color3.fromRGB(20, 35, 28),
                CardHover = Color3.fromRGB(28, 48, 38),
                Accent = Color3.fromRGB(16, 185, 129),
                AccentDark = Color3.fromRGB(5, 150, 105),
                AccentGlow = Color3.fromRGB(52, 211, 153),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(134, 169, 154),
                TextDark = Color3.fromRGB(74, 109, 94),
                Border = Color3.fromRGB(30, 50, 40),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Rose Pink",
            Description = "Soft romantic pink aesthetic",
            IsGradient = false,
            Colors = {
                Background = Color3.fromRGB(20, 12, 18),
                Secondary = Color3.fromRGB(28, 18, 25),
                Card = Color3.fromRGB(40, 24, 35),
                CardHover = Color3.fromRGB(55, 32, 48),
                Accent = Color3.fromRGB(244, 114, 182),
                AccentDark = Color3.fromRGB(219, 39, 119),
                AccentGlow = Color3.fromRGB(251, 146, 201),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(180, 140, 165),
                TextDark = Color3.fromRGB(120, 80, 105),
                Border = Color3.fromRGB(55, 35, 48),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Amber Orange",
            Description = "Warm sunset orange vibes",
            IsGradient = false,
            Colors = {
                Background = Color3.fromRGB(20, 14, 10),
                Secondary = Color3.fromRGB(28, 20, 15),
                Card = Color3.fromRGB(40, 28, 20),
                CardHover = Color3.fromRGB(55, 38, 28),
                Accent = Color3.fromRGB(245, 158, 11),
                AccentDark = Color3.fromRGB(217, 119, 6),
                AccentGlow = Color3.fromRGB(251, 191, 36),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(180, 160, 140),
                TextDark = Color3.fromRGB(120, 100, 80),
                Border = Color3.fromRGB(55, 40, 28),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Crimson Red",
            Description = "Bold and passionate red design",
            IsGradient = false,
            Colors = {
                Background = Color3.fromRGB(18, 10, 12),
                Secondary = Color3.fromRGB(25, 15, 18),
                Card = Color3.fromRGB(38, 22, 26),
                CardHover = Color3.fromRGB(52, 30, 36),
                Accent = Color3.fromRGB(239, 68, 68),
                AccentDark = Color3.fromRGB(185, 28, 28),
                AccentGlow = Color3.fromRGB(252, 129, 129),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(175, 140, 145),
                TextDark = Color3.fromRGB(115, 80, 85),
                Border = Color3.fromRGB(52, 32, 38),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Midnight Dark",
            Description = "Ultra dark theme for night owls",
            IsGradient = false,
            Colors = {
                Background = Color3.fromRGB(5, 5, 8),
                Secondary = Color3.fromRGB(10, 10, 15),
                Card = Color3.fromRGB(18, 18, 25),
                CardHover = Color3.fromRGB(25, 25, 35),
                Accent = Color3.fromRGB(99, 102, 241),
                AccentDark = Color3.fromRGB(79, 70, 229),
                AccentGlow = Color3.fromRGB(129, 140, 248),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(120, 120, 140),
                TextDark = Color3.fromRGB(70, 70, 90),
                Border = Color3.fromRGB(28, 28, 40),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Light Mode",
            Description = "Clean bright theme for daytime use",
            IsGradient = false,
            Colors = {
                Background = Color3.fromRGB(245, 245, 250),
                Secondary = Color3.fromRGB(235, 235, 242),
                Card = Color3.fromRGB(255, 255, 255),
                CardHover = Color3.fromRGB(240, 240, 248),
                Accent = Color3.fromRGB(99, 102, 241),
                AccentDark = Color3.fromRGB(79, 70, 229),
                AccentGlow = Color3.fromRGB(129, 140, 248),
                Text = Color3.fromRGB(15, 15, 25),
                TextMuted = Color3.fromRGB(100, 100, 120),
                TextDark = Color3.fromRGB(150, 150, 170),
                Border = Color3.fromRGB(210, 210, 225),
                Success = Color3.fromRGB(22, 163, 74),
                Error = Color3.fromRGB(220, 38, 38),
                Warning = Color3.fromRGB(217, 119, 6)
            }
        },
        -- Gradient Themes (4+)
        {
            Name = "Sunset Gradient",
            Description = "Warm sunset colors flowing together",
            IsGradient = true,
            GradientColors = {Color3.fromRGB(255, 95, 109), Color3.fromRGB(255, 195, 113)},
            GradientRotation = 45,
            Colors = {
                Background = Color3.fromRGB(18, 12, 15),
                Secondary = Color3.fromRGB(25, 18, 22),
                Card = Color3.fromRGB(38, 26, 32),
                CardHover = Color3.fromRGB(52, 36, 44),
                Accent = Color3.fromRGB(255, 95, 109),
                AccentDark = Color3.fromRGB(255, 140, 100),
                AccentGlow = Color3.fromRGB(255, 195, 113),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(180, 155, 165),
                TextDark = Color3.fromRGB(120, 95, 105),
                Border = Color3.fromRGB(55, 38, 45),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Ocean Wave",
            Description = "Cool ocean blues in motion",
            IsGradient = true,
            GradientColors = {Color3.fromRGB(0, 198, 255), Color3.fromRGB(0, 114, 255)},
            GradientRotation = 135,
            Colors = {
                Background = Color3.fromRGB(8, 15, 22),
                Secondary = Color3.fromRGB(12, 22, 32),
                Card = Color3.fromRGB(18, 32, 48),
                CardHover = Color3.fromRGB(25, 45, 65),
                Accent = Color3.fromRGB(0, 198, 255),
                AccentDark = Color3.fromRGB(0, 114, 255),
                AccentGlow = Color3.fromRGB(100, 220, 255),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(140, 170, 195),
                TextDark = Color3.fromRGB(80, 110, 135),
                Border = Color3.fromRGB(25, 45, 65),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Mystic Purple",
            Description = "Magical 3-color gradient experience",
            IsGradient = true,
            GradientColors = {Color3.fromRGB(131, 58, 180), Color3.fromRGB(253, 29, 29), Color3.fromRGB(252, 176, 69)},
            GradientRotation = 90,
            Colors = {
                Background = Color3.fromRGB(15, 10, 20),
                Secondary = Color3.fromRGB(22, 15, 30),
                Card = Color3.fromRGB(32, 22, 45),
                CardHover = Color3.fromRGB(45, 32, 62),
                Accent = Color3.fromRGB(131, 58, 180),
                AccentDark = Color3.fromRGB(180, 80, 120),
                AccentGlow = Color3.fromRGB(200, 100, 180),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(170, 145, 185),
                TextDark = Color3.fromRGB(110, 85, 125),
                Border = Color3.fromRGB(45, 32, 60),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Forest Mist",
            Description = "Refreshing forest greens blend",
            IsGradient = true,
            GradientColors = {Color3.fromRGB(17, 153, 142), Color3.fromRGB(56, 239, 125)},
            GradientRotation = 120,
            Colors = {
                Background = Color3.fromRGB(8, 18, 15),
                Secondary = Color3.fromRGB(12, 26, 22),
                Card = Color3.fromRGB(18, 38, 32),
                CardHover = Color3.fromRGB(25, 52, 44),
                Accent = Color3.fromRGB(17, 153, 142),
                AccentDark = Color3.fromRGB(56, 239, 125),
                AccentGlow = Color3.fromRGB(80, 255, 160),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(140, 180, 168),
                TextDark = Color3.fromRGB(80, 120, 108),
                Border = Color3.fromRGB(25, 50, 42),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Neon Cyber",
            Description = "Futuristic cyberpunk neon glow",
            IsGradient = true,
            GradientColors = {Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255)},
            GradientRotation = 45,
            Colors = {
                Background = Color3.fromRGB(5, 5, 15),
                Secondary = Color3.fromRGB(10, 10, 25),
                Card = Color3.fromRGB(18, 18, 40),
                CardHover = Color3.fromRGB(28, 28, 55),
                Accent = Color3.fromRGB(255, 0, 255),
                AccentDark = Color3.fromRGB(0, 255, 255),
                AccentGlow = Color3.fromRGB(200, 100, 255),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(180, 150, 200),
                TextDark = Color3.fromRGB(120, 90, 140),
                Border = Color3.fromRGB(40, 20, 60),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        -- Christmas/New Year Themes (3+)
        {
            Name = "Christmas Classic",
            Description = "Traditional red and green holiday spirit",
            IsGradient = false,
            IsChristmas = true,
            Colors = {
                Background = Color3.fromRGB(15, 8, 8),
                Secondary = Color3.fromRGB(22, 12, 12),
                Card = Color3.fromRGB(35, 18, 18),
                CardHover = Color3.fromRGB(48, 25, 25),
                Accent = Color3.fromRGB(220, 38, 38),
                AccentDark = Color3.fromRGB(34, 139, 34),
                AccentGlow = Color3.fromRGB(255, 215, 0),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(180, 150, 150),
                TextDark = Color3.fromRGB(120, 90, 90),
                Border = Color3.fromRGB(50, 28, 28),
                Success = Color3.fromRGB(34, 139, 34),
                Error = Color3.fromRGB(220, 38, 38),
                Warning = Color3.fromRGB(255, 215, 0)
            }
        },
        {
            Name = "Winter Frost",
            Description = "Icy cold winter wonderland theme",
            IsGradient = true,
            IsChristmas = true,
            GradientColors = {Color3.fromRGB(200, 230, 255), Color3.fromRGB(100, 180, 255), Color3.fromRGB(255, 255, 255)},
            GradientRotation = 180,
            Colors = {
                Background = Color3.fromRGB(15, 20, 28),
                Secondary = Color3.fromRGB(22, 30, 42),
                Card = Color3.fromRGB(32, 45, 62),
                CardHover = Color3.fromRGB(45, 62, 85),
                Accent = Color3.fromRGB(135, 206, 250),
                AccentDark = Color3.fromRGB(70, 130, 180),
                AccentGlow = Color3.fromRGB(200, 230, 255),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(170, 195, 220),
                TextDark = Color3.fromRGB(110, 135, 160),
                Border = Color3.fromRGB(50, 70, 95),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "New Year Gold",
            Description = "Luxurious golden celebration theme",
            IsGradient = true,
            IsChristmas = true,
            GradientColors = {Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 223, 128)},
            GradientRotation = 45,
            Colors = {
                Background = Color3.fromRGB(12, 10, 5),
                Secondary = Color3.fromRGB(20, 16, 8),
                Card = Color3.fromRGB(32, 26, 12),
                CardHover = Color3.fromRGB(45, 38, 18),
                Accent = Color3.fromRGB(255, 215, 0),
                AccentDark = Color3.fromRGB(218, 165, 32),
                AccentGlow = Color3.fromRGB(255, 235, 100),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(200, 180, 140),
                TextDark = Color3.fromRGB(140, 120, 80),
                Border = Color3.fromRGB(55, 45, 20),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        {
            Name = "Starry Night",
            Description = "Magical starlit night sky theme",
            IsGradient = true,
            IsChristmas = true,
            GradientColors = {Color3.fromRGB(25, 25, 112), Color3.fromRGB(138, 43, 226), Color3.fromRGB(255, 255, 255)},
            GradientRotation = 135,
            Colors = {
                Background = Color3.fromRGB(8, 8, 25),
                Secondary = Color3.fromRGB(15, 15, 40),
                Card = Color3.fromRGB(25, 25, 60),
                CardHover = Color3.fromRGB(35, 35, 80),
                Accent = Color3.fromRGB(138, 43, 226),
                AccentDark = Color3.fromRGB(75, 0, 130),
                AccentGlow = Color3.fromRGB(255, 255, 255),
                Text = Color3.fromRGB(255, 255, 255),
                TextMuted = Color3.fromRGB(160, 150, 200),
                TextDark = Color3.fromRGB(100, 90, 140),
                Border = Color3.fromRGB(40, 40, 80),
                Success = Color3.fromRGB(34, 197, 94),
                Error = Color3.fromRGB(239, 68, 68),
                Warning = Color3.fromRGB(245, 158, 11)
            }
        },
        -- Custom Theme (User Configurable)
        {
            Name = "Custom",
            Description = "Create your own custom color scheme",
            IsGradient = false,
            IsCustom = true,
            Colors = CustomThemeColors
        }
    }
    
    -- Custom Theme Index (last theme)
    local CustomThemeIndex = #AllThemes
    
    if MagicTulevo.SavedSettings and MagicTulevo.SavedSettings.ThemeIndex then
        local savedIdx = MagicTulevo.SavedSettings.ThemeIndex
        if savedIdx >= 1 and savedIdx <= #AllThemes then
            CurrentThemeIndex = savedIdx
        end
    end
    
    local SidePanel, ContentPanel, Divider
    
    ApplyTheme = function(themeData)
        -- For Custom theme, use CustomThemeColors
        if themeData.IsCustom then
            for key, value in pairs(CustomThemeColors) do
                Theme[key] = value
            end
        else
            for key, value in pairs(themeData.Colors) do
                Theme[key] = value
            end
        end
        
        -- Show/Hide Custom button based on theme
        if UI.CustomBtnContainer then
            UI.CustomBtnContainer.Visible = themeData.IsCustom == true
        end
        
        Main.BackgroundColor3 = Theme.Background
        MainStroke.Color = Theme.Border
        if SidePanel then SidePanel.BackgroundColor3 = Theme.Secondary end
        if ContentPanel then ContentPanel.BackgroundColor3 = Theme.Secondary end
        TitleLabel.TextColor3 = Theme.Text
        SubTitleLabel.TextColor3 = Theme.TextMuted
        if Divider then Divider.BackgroundColor3 = Theme.Border end
        
        UI.SearchBtn.BackgroundColor3 = Theme.Card
        UI.SettingsBtn.BackgroundColor3 = Theme.Card
        UI.CloseBtn.BackgroundColor3 = Theme.Card
        UI.SearchIcon.ImageColor3 = Theme.TextMuted
        UI.GearIcon.ImageColor3 = Theme.TextMuted
        UI.CloseBtn.TextColor3 = Theme.TextMuted
        UI.SearchTooltip.BackgroundColor3 = Theme.Secondary
        UI.SettingsTooltip.BackgroundColor3 = Theme.Secondary
        UI.SearchPanel.BackgroundColor3 = Theme.Secondary
        UI.SearchInputContainer.BackgroundColor3 = Theme.Card
        UI.SearchInput.TextColor3 = Theme.Text
        UI.SearchInput.PlaceholderColor3 = Theme.TextMuted
        UI.SearchCounter.TextColor3 = Theme.TextMuted
        UI.SearchResults.ScrollBarImageColor3 = Theme.Accent
        
        -- Update all UI elements (buttons, toggles, sliders, etc.) backgrounds
        for _, element in pairs(Window.AllElements) do
            if element.UIElement and element.UIElement.Parent then
                local uiElem = element.UIElement
                if uiElem:IsA("Frame") or uiElem:IsA("TextButton") then
                    Tween(uiElem, 0.3, {BackgroundColor3 = Theme.Card})
                    local stroke = uiElem:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        Tween(stroke, 0.3, {Color = Theme.Border})
                    end
                    -- Update text colors
                    for _, child in pairs(uiElem:GetDescendants()) do
                        if child:IsA("TextLabel") then
                            if child.TextColor3 ~= Theme.TextDark and child.TextColor3 ~= Theme.Accent then
                                Tween(child, 0.3, {TextColor3 = Theme.Text})
                            end
                        elseif child:IsA("TextBox") then
                            Tween(child, 0.3, {TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextMuted, BackgroundColor3 = Theme.Background})
                        end
                    end
                end
            end
        end
        
        -- Update tab buttons and content
        for _, tab in pairs(Window.Tabs) do
            if tab.Button then
                local isSelected = Window.CurrentTab == tab
                if isSelected then
                    Tween(tab.Button, 0.3, {BackgroundColor3 = Theme.Card})
                end
                Tween(tab.Label, 0.3, {TextColor3 = isSelected and Theme.Text or Theme.TextMuted})
                Tween(tab.Indicator, 0.3, {BackgroundColor3 = Theme.Accent})
                Tween(tab.Glow, 0.3, {BackgroundColor3 = Theme.Accent})
                if tab.Icon then
                    Tween(tab.Icon, 0.3, {ImageColor3 = isSelected and Theme.Accent or Theme.TextMuted})
                end
            end
            if tab.Content then
                tab.Content.ScrollBarImageColor3 = Theme.Accent
            end
        end
        
        if themeData.IsGradient and themeData.GradientColors then
            local keypoints = {}
            for i, color in ipairs(themeData.GradientColors) do
                table.insert(keypoints, ColorSequenceKeypoint.new((i-1)/(#themeData.GradientColors-1), color))
            end
            AccentGradient.Color = ColorSequence.new(keypoints)
            LogoGradient.Color = ColorSequence.new(keypoints)
        else
            AccentGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Accent),
                ColorSequenceKeypoint.new(0.5, Theme.AccentGlow),
                ColorSequenceKeypoint.new(1, Theme.Accent)
            })
            LogoGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Accent),
                ColorSequenceKeypoint.new(0.5, Theme.AccentGlow),
                ColorSequenceKeypoint.new(1, Theme.Accent)
            })
        end
        
        MagicTulevo:Notify({Title = "Theme Changed", Message = "Applied: " .. themeData.Name, Type = "Success", Duration = 2})
        
        -- Call all registered theme change callbacks
        for _, callback in ipairs(MagicTulevo.OnThemeChangeCallbacks) do
            pcall(callback, Theme.Accent, Theme)
        end
    end

    -- Panel state (consolidated to reduce local variables)
    local PanelState = {
        SettingsOpen = false,
        InfoOpen = false,
        ConfigsOpen = false,
        AccountOpen = false,
        CustomOpen = false,
        SettingsTabContent = nil,
        InfoTabContent = nil,
        ConfigsTabContent = nil,
        AccountTabContent = nil,
        CustomTabContent = nil,
        AccountPanel = nil
    }

    -- Configs Button Click Handler
    UI.ConfigsBtn.MouseButton1Click:Connect(function()
        PanelState.ConfigsOpen = not PanelState.ConfigsOpen
        if PanelState.ConfigsOpen then
            -- Hide Info tab if open
            if PanelState.InfoOpen then
                PanelState.InfoOpen = false
                if PanelState.InfoTabContent then
                    PanelState.InfoTabContent.Visible = false
                end
                Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.TextMuted})
            end
            -- Hide Settings tab if open
            if PanelState.SettingsOpen then
                PanelState.SettingsOpen = false
                if PanelState.SettingsTabContent then
                    PanelState.SettingsTabContent.Visible = false
                end
                Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            -- Hide Account tab if open
            if PanelState.AccountOpen then
                PanelState.AccountOpen = false
                if PanelState.AccountTabContent then
                    PanelState.AccountTabContent.Visible = false
                end
                Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.Card})
            end
            -- Hide Custom tab if open
            if PanelState.CustomOpen then
                PanelState.CustomOpen = false
                if PanelState.CustomTabContent then
                    PanelState.CustomTabContent.Visible = false
                end
                Tween(UI.CustomBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.CustomIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            for _, t in pairs(Window.Tabs) do
                if t.Content.Visible then
                    t.Content.Visible = false
                    Tween(t.Button, 0.25, {BackgroundTransparency = 1})
                    Tween(t.Label, 0.25, {TextColor3 = Theme.TextMuted})
                    Tween(t.Indicator, 0.25, {Size = UDim2.new(0, 3, 0, 0)})
                    Tween(t.Glow, 0.25, {BackgroundTransparency = 1})
                    if t.Icon then Tween(t.Icon, 0.25, {ImageColor3 = Theme.TextMuted}) end
                end
            end
            Window.CurrentTab = nil
            if PanelState.ConfigsTabContent then
                PanelState.ConfigsTabContent.Visible = true
                PanelState.ConfigsTabContent.Position = UDim2.new(0.05, 0, 0, 0)
                Tween(PanelState.ConfigsTabContent, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
            end
            Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.Accent})
            Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.Text})
        else
            -- Hide Configs tab and show first user tab
            if PanelState.ConfigsTabContent then
                PanelState.ConfigsTabContent.Visible = false
            end
            Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.Card})
            Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            -- Select first tab if exists
            if #Window.Tabs > 0 then
                Window.Tabs[1]:Select()
            end
        end
    end)

    UI.SettingsBtn.MouseButton1Click:Connect(function()
        PanelState.SettingsOpen = not PanelState.SettingsOpen
        if PanelState.SettingsOpen then
            -- Hide Info tab if open
            if PanelState.InfoOpen then
                PanelState.InfoOpen = false
                if PanelState.InfoTabContent then
                    PanelState.InfoTabContent.Visible = false
                end
                Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.TextMuted})
            end
            -- Hide Configs tab if open
            if PanelState.ConfigsOpen then
                PanelState.ConfigsOpen = false
                if PanelState.ConfigsTabContent then
                    PanelState.ConfigsTabContent.Visible = false
                end
                Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            -- Hide Account tab if open
            if PanelState.AccountOpen then
                PanelState.AccountOpen = false
                if PanelState.AccountTabContent then
                    PanelState.AccountTabContent.Visible = false
                end
                Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.Card})
            end
            -- Hide Custom tab if open
            if PanelState.CustomOpen then
                PanelState.CustomOpen = false
                if PanelState.CustomTabContent then
                    PanelState.CustomTabContent.Visible = false
                end
                Tween(UI.CustomBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.CustomIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            for _, t in pairs(Window.Tabs) do
                if t.Content.Visible then
                    t.Content.Visible = false
                    Tween(t.Button, 0.25, {BackgroundTransparency = 1})
                    Tween(t.Label, 0.25, {TextColor3 = Theme.TextMuted})
                    Tween(t.Indicator, 0.25, {Size = UDim2.new(0, 3, 0, 0)})
                    Tween(t.Glow, 0.25, {BackgroundTransparency = 1})
                    if t.Icon then Tween(t.Icon, 0.25, {ImageColor3 = Theme.TextMuted}) end
                end
            end
            Window.CurrentTab = nil
            if PanelState.SettingsTabContent then
                PanelState.SettingsTabContent.Visible = true
                PanelState.SettingsTabContent.Position = UDim2.new(0.05, 0, 0, 0)
                Tween(PanelState.SettingsTabContent, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
            end
            Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.Accent})
            Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.Text})
        else
            -- Hide Settings tab and show first user tab
            if PanelState.SettingsTabContent then
                PanelState.SettingsTabContent.Visible = false
            end
            Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.Card})
            Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            -- Select first tab if exists
            if #Window.Tabs > 0 then
                Window.Tabs[1]:Select()
            end
        end
    end)

    Divider = Create("Frame", {
        BackgroundColor3 = Theme.Border,
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.new(0, 14, 0, 63),
        BorderSizePixel = 0,
        Parent = Main
    })

    SidePanel = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 150, 1, -78),
        Position = UDim2.new(0, 14, 0, 70),
        Parent = Main
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = SidePanel})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = SidePanel})

    local TabList = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 1, -70),
        Position = UDim2.new(0, 6, 0, 6),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        Parent = SidePanel
    })
    local TabLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabList
    })
    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.new(0, 0, 0, TabLayout.AbsoluteContentSize.Y)
    end)
    
    -- Account Info Panel (bottom left) - Premium Design
    PanelState.AccountPanel = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, -12, 0, 60),
        Position = UDim2.new(0, 6, 1, -66),
        Parent = SidePanel
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = PanelState.AccountPanel})
    local AccountPanelStroke = Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.6, Parent = PanelState.AccountPanel})
    
    -- Subtle gradient overlay
    local AccountPanelGradient = Create("Frame", {
        BackgroundTransparency = 0.95,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = PanelState.AccountPanel
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = AccountPanelGradient})
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(147, 112, 219))
        }),
        Rotation = 45,
        Parent = AccountPanelGradient
    })
    
    local player = game:GetService("Players").LocalPlayer
    local playerName = player and player.Name or "Unknown"
    local playerDisplayName = player and player.DisplayName or "Unknown"
    local playerUserId = player and player.UserId or 0
    local playerAge = player and player.AccountAge or 0
    
    -- Generate HWID-like ID
    local function GenerateHWID()
        local hwid = ""
        local chars = "0123456789ABCDEF"
        math.randomseed(playerUserId + os.time())
        for i = 1, 16 do
            if i == 5 or i == 9 or i == 13 then
                hwid = hwid .. "-"
            end
            hwid = hwid .. chars:sub(math.random(1, 16), math.random(1, 16))
        end
        return hwid
    end
    local playerHWID = GenerateHWID()
    
    -- Avatar container with ring
    local AvatarContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 8, 0.5, -22),
        Parent = PanelState.AccountPanel
    })
    
    -- Avatar ring
    local AvatarRingSmall = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0, -2, 0, -2),
        Parent = AvatarContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = AvatarRingSmall})
    Create("UIStroke", {
        Color = Theme.Accent,
        Thickness = 2,
        Transparency = 0.3,
        Parent = AvatarRingSmall
    })
    
    -- Avatar thumbnail
    local AvatarHolder = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = AvatarContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = AvatarHolder})
    
    local AvatarImage = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0, 2, 0, 2),
        Image = player and ("https://www.roblox.com/headshot-thumbnail/image?userId=" .. playerUserId .. "&width=150&height=150&format=png") or "",
        Parent = AvatarHolder
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = AvatarImage})
    
    -- Online indicator (small)
    local OnlineIndicatorSmall = Create("Frame", {
        BackgroundColor3 = Theme.Success,
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(1, -8, 1, -8),
        Parent = AvatarContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = OnlineIndicatorSmall})
    Create("UIStroke", {Color = Theme.Card, Thickness = 2, Parent = OnlineIndicatorSmall})
    
    -- Player name
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -62, 0, 18),
        Position = UDim2.new(0, 58, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = playerDisplayName,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = PanelState.AccountPanel
    })
    
    -- HWID (small text)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -62, 0, 14),
        Position = UDim2.new(0, 58, 0, 32),
        Font = Enum.Font.Gotham,
        Text = playerHWID:sub(1, 14) .. "...",
        TextColor3 = Theme.TextDark,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = PanelState.AccountPanel
    })
    
    -- Account Info Button
    local AccountBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = PanelState.AccountPanel
    })
    
    -- Tooltip for Account Info
    local AccountTooltip = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, -5),
        AnchorPoint = Vector2.new(0, 1),
        ClipsDescendants = true,
        ZIndex = 100,
        Parent = PanelState.AccountPanel
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = AccountTooltip})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = AccountTooltip})
    
    local AccountTooltipText = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Enum.Font.Gotham,
        Text = "Your account information. (Don't worry, it's safe.)",
        TextColor3 = Theme.Text,
        TextSize = 9,
        TextWrapped = true,
        ZIndex = 101,
        Parent = AccountTooltip
    })
    
    AccountBtn.MouseEnter:Connect(function()
        Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.CardHover})
        Tween(AccountTooltip, 0.3, {Size = UDim2.new(1, 0, 0, 40)}, Enum.EasingStyle.Back)
    end)
    AccountBtn.MouseLeave:Connect(function()
        Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.Card})
        Tween(AccountTooltip, 0.2, {Size = UDim2.new(0, 0, 0, 0)})
    end)
    
    -- Account Button Click Handler
    AccountBtn.MouseButton1Click:Connect(function()
        PanelState.AccountOpen = not PanelState.AccountOpen
        PlaySound("rbxassetid://6895079853", 0.3)
        
        if PanelState.AccountOpen then
            -- Hide other tabs
            for _, t in pairs(Window.Tabs) do
                if t.Content.Visible then
                    t.Content.Visible = false
                    Tween(t.Button, 0.25, {BackgroundTransparency = 1})
                    Tween(t.Label, 0.25, {TextColor3 = Theme.TextMuted})
                    Tween(t.Indicator, 0.25, {Size = UDim2.new(0, 3, 0, 0)})
                    Tween(t.Glow, 0.25, {BackgroundTransparency = 1})
                    if t.Icon then Tween(t.Icon, 0.25, {ImageColor3 = Theme.TextMuted}) end
                end
            end
            Window.CurrentTab = nil
            
            -- Hide Settings if open
            if PanelState.SettingsOpen then
                PanelState.SettingsOpen = false
                if PanelState.SettingsTabContent then PanelState.SettingsTabContent.Visible = false end
                Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Info if open
            if PanelState.InfoOpen then
                PanelState.InfoOpen = false
                if PanelState.InfoTabContent then PanelState.InfoTabContent.Visible = false end
                Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.TextMuted})
            end
            
            -- Hide Configs if open
            if PanelState.ConfigsOpen then
                PanelState.ConfigsOpen = false
                if PanelState.ConfigsTabContent then PanelState.ConfigsTabContent.Visible = false end
                Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Custom if open
            if PanelState.CustomOpen then
                PanelState.CustomOpen = false
                if PanelState.CustomTabContent then PanelState.CustomTabContent.Visible = false end
                Tween(UI.CustomBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.CustomIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Show Account tab
            if PanelState.AccountTabContent then
                PanelState.AccountTabContent.Visible = true
                PanelState.AccountTabContent.Position = UDim2.new(0.05, 0, 0, 0)
                Tween(PanelState.AccountTabContent, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
            end
            Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.Accent})
        else
            -- Hide Account tab and show first user tab
            if PanelState.AccountTabContent then
                PanelState.AccountTabContent.Visible = false
            end
            Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.Card})
            
            if Window.Tabs[1] then
                Window.Tabs[1]:Select()
            end
        end
    end)

    ContentPanel = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, -180, 1, -78),
        Position = UDim2.new(0, 170, 0, 70),
        Parent = Main
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = ContentPanel})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = ContentPanel})

    local ContentContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        ClipsDescendants = true,
        Parent = ContentPanel
    })

    -- Create Settings Tab Content (System Tab)
    PanelState.SettingsTabContent = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 520),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.3,
        Visible = false,
        BorderSizePixel = 0,
        Parent = ContentContainer
    })
    local SettingsLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = PanelState.SettingsTabContent
    })
    
    -- Settings Header
    local SettingsHeaderFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 50),
        LayoutOrder = 0,
        Parent = PanelState.SettingsTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = SettingsHeaderFrame})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = SettingsHeaderFrame})
    
    local SettingsHeaderIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 12, 0.5, -12),
        Image = "rbxassetid://3926307971",
        ImageRectOffset = Vector2.new(324, 124),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Theme.Accent,
        Parent = SettingsHeaderFrame
    })
    
    -- OPTIMIZED: Removed settings gear rotation animation for better startup performance
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 44, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "Settings",
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = SettingsHeaderFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -90, 0, 0),
        Font = Enum.Font.Gotham,
        Text = "System",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = SettingsHeaderFrame
    })
    
    -- Keybind Section Label
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "KEYBIND",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = PanelState.SettingsTabContent
    })
    
    -- Keybind Frame
    local KeybindFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 44),
        LayoutOrder = 2,
        Parent = PanelState.SettingsTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = KeybindFrame})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = KeybindFrame})
    
    Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 12, 0.5, -9),
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(764, 244),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Theme.TextMuted,
        Parent = KeybindFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 38, 0, 0),
        Font = Enum.Font.GothamMedium,
        Text = "Toggle Menu",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = KeybindFrame
    })
    
    local KeybindBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(0, 80, 0, 32),
        Position = UDim2.new(1, -92, 0.5, -16),
        Font = Enum.Font.GothamBold,
        Text = toggleKey.Name,
        TextColor3 = Theme.Accent,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = KeybindFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = KeybindBtn})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.7, Parent = KeybindBtn})
    
    local listeningKey = false
    KeybindBtn.MouseButton1Click:Connect(function()
        listeningKey = true
        KeybindBtn.Text = "..."
        Tween(KeybindBtn, 0.2, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text})
    end)
    KeybindBtn.MouseEnter:Connect(function()
        if not listeningKey then
            Tween(KeybindBtn, 0.2, {BackgroundColor3 = Theme.CardHover})
        end
    end)
    KeybindBtn.MouseLeave:Connect(function()
        if not listeningKey then
            Tween(KeybindBtn, 0.2, {BackgroundColor3 = Theme.Background})
        end
    end)
    
    -- Themes Section Label
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "THEMES",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 3,
        Parent = PanelState.SettingsTabContent
    })
    
    -- Theme Grid Container with shimmer background
    local ThemeGridWrapper = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 380),
        LayoutOrder = 4,
        ClipsDescendants = true,
        Parent = PanelState.SettingsTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = ThemeGridWrapper})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = ThemeGridWrapper})
    
    -- Shimmer effect background
    local ShimmerBg = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.95,
        Size = UDim2.new(2, 0, 2, 0),
        Position = UDim2.new(-0.5, 0, -0.5, 0),
        Parent = ThemeGridWrapper
    })
    local ShimmerGradient = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(217, 70, 239)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
        }),
        Rotation = 45,
        Parent = ShimmerBg
    })
    
    -- OPTIMIZED: Removed shimmer animation - static background for better performance
    
    local ThemeGrid = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        CanvasSize = UDim2.new(0, 0, 0, 320),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = ThemeGridWrapper
    })
    Create("UIGridLayout", {
        CellSize = UDim2.new(0, 115, 0, 70),
        CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ThemeGrid
    })
    
    -- Create theme buttons
    for i, themeData in ipairs(AllThemes) do
        local ThemeBtn = Create("TextButton", {
            BackgroundColor3 = themeData.Colors.Card,
            Size = UDim2.new(0, 115, 0, 70),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
            ClipsDescendants = true,
            Parent = ThemeGrid
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = ThemeBtn})
        local ThemeBtnStroke = Create("UIStroke", {
            Color = i == CurrentThemeIndex and Theme.Accent or themeData.Colors.Border, 
            Thickness = i == CurrentThemeIndex and 2 or 1, 
            Transparency = 0.3, 
            Parent = ThemeBtn
        })
        
        -- Animated gradient background for theme preview
        local ThemeBgGradient = Create("Frame", {
            BackgroundColor3 = themeData.Colors.Background,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 0,
            Parent = ThemeBtn
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = ThemeBgGradient})
        
        -- Add animated gradient overlay
        local GradientOverlay = Create("Frame", {
            BackgroundTransparency = 0.85,
            BackgroundColor3 = themeData.Colors.Accent,
            Size = UDim2.new(2, 0, 2, 0),
            Position = UDim2.new(-0.5, 0, -0.5, 0),
            ZIndex = 1,
            Parent = ThemeBtn
        })
        
        local themeGradientColors
        if themeData.IsGradient and themeData.GradientColors then
            local keypoints = {}
            for j, color in ipairs(themeData.GradientColors) do
                table.insert(keypoints, ColorSequenceKeypoint.new((j-1)/(#themeData.GradientColors-1), color))
            end
            themeGradientColors = ColorSequence.new(keypoints)
        else
            themeGradientColors = ColorSequence.new({
                ColorSequenceKeypoint.new(0, themeData.Colors.Accent),
                ColorSequenceKeypoint.new(0.5, themeData.Colors.AccentGlow),
                ColorSequenceKeypoint.new(1, themeData.Colors.AccentDark)
            })
        end
        
        local ThemePreviewGradient = Create("UIGradient", {
            Color = themeGradientColors,
            Rotation = themeData.GradientRotation or 45,
            Parent = GradientOverlay
        })
        
        -- OPTIMIZED: Removed gradient animation for theme buttons to reduce startup lag
        -- Animation only starts when hovering over theme button
        
        -- Theme preview bar
        local PreviewBar = Create("Frame", {
            BackgroundColor3 = themeData.Colors.Accent,
            Size = UDim2.new(1, 0, 0, 4),
            Position = UDim2.new(0, 0, 0, 0),
            ZIndex = 2,
            Parent = ThemeBtn
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = PreviewBar})
        
        if themeData.IsGradient and themeData.GradientColors then
            local keypoints = {}
            for j, color in ipairs(themeData.GradientColors) do
                table.insert(keypoints, ColorSequenceKeypoint.new((j-1)/(#themeData.GradientColors-1), color))
            end
            Create("UIGradient", {
                Color = ColorSequence.new(keypoints),
                Rotation = themeData.GradientRotation or 0,
                Parent = PreviewBar
            })
        end
        
        -- Color dots preview
        local DotsContainer = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 0, 14),
            Position = UDim2.new(0, 5, 0, 10),
            ZIndex = 2,
            Parent = ThemeBtn
        })
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 4),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = DotsContainer
        })
        
        local previewColors = {themeData.Colors.Accent, themeData.Colors.AccentDark, themeData.Colors.AccentGlow}
        for _, color in ipairs(previewColors) do
            local Dot = Create("Frame", {
                BackgroundColor3 = color,
                Size = UDim2.new(0, 12, 0, 12),
                ZIndex = 2,
                Parent = DotsContainer
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Dot})
        end
        
        -- Theme name
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 0, 32),
            Position = UDim2.new(0, 4, 0, 30),
            Font = Enum.Font.GothamMedium,
            Text = themeData.Name,
            TextColor3 = themeData.Colors.Text,
            TextSize = 10,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 2,
            Parent = ThemeBtn
        })
        
        -- Christmas badge
        if themeData.IsChristmas then
            local Badge = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(220, 38, 38),
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(1, -12, 0, 8),
                ZIndex = 3,
                Parent = ThemeBtn
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Badge})
        end
        
        ThemeBtn.MouseEnter:Connect(function()
            Tween(ThemeBtn, 0.2, {BackgroundColor3 = themeData.Colors.CardHover})
            Tween(ThemeBtnStroke, 0.2, {Color = themeData.Colors.Accent, Thickness = 2})
        end)
        ThemeBtn.MouseLeave:Connect(function()
            if CurrentThemeIndex ~= i then
                Tween(ThemeBtn, 0.2, {BackgroundColor3 = themeData.Colors.Card})
                Tween(ThemeBtnStroke, 0.2, {Color = themeData.Colors.Border, Thickness = 1})
            end
        end)
        ThemeBtn.MouseButton1Click:Connect(function()
            CurrentThemeIndex = i
            ApplyTheme(themeData)
            
            for _, child in pairs(ThemeGrid:GetChildren()) do
                if child:IsA("TextButton") then
                    local stroke = child:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        local idx = child.LayoutOrder
                        if idx == i then
                            Tween(stroke, 0.2, {Color = Theme.Accent, Thickness = 2})
                        else
                            Tween(stroke, 0.2, {Color = AllThemes[idx].Colors.Border, Thickness = 1})
                        end
                    end
                end
            end
        end)
        
        -- Add theme to searchable elements
        table.insert(Window.AllThemes, themeData)
    end
    
    -- Apply saved theme after all themes are loaded
    if CurrentThemeIndex > 1 and AllThemes[CurrentThemeIndex] then
        ApplyTheme(AllThemes[CurrentThemeIndex])
        -- Update theme button strokes
        for _, child in pairs(ThemeGrid:GetChildren()) do
            if child:IsA("TextButton") then
                local stroke = child:FindFirstChildOfClass("UIStroke")
                if stroke then
                    local idx = child.LayoutOrder
                    if idx == CurrentThemeIndex then
                        stroke.Color = Theme.Accent
                        stroke.Thickness = 2
                    end
                end
            end
        end
    end

    -- =====================================================
    -- Create Account Tab Content (Player Info)
    -- =====================================================
    local Players = game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    local playerUserId = localPlayer and localPlayer.UserId or 0
    local playerDisplayName = localPlayer and localPlayer.DisplayName or "Unknown"
    local playerAccountAge = localPlayer and localPlayer.AccountAge or 0
    local currentPlace = game.PlaceId or 0
    local currentPlaceName = game:GetService("MarketplaceService"):GetProductInfo(currentPlace).Name or "Unknown"
    
    -- Generate HWID-ID (unique per session)
    local hwidChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local hwidId = ""
    math.randomseed(playerUserId + os.time())
    for i = 1, 8 do
        local idx = math.random(1, #hwidChars)
        hwidId = hwidId .. hwidChars:sub(idx, idx)
    end
    
    PanelState.AccountTabContent = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 480),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.3,
        Visible = false,
        BorderSizePixel = 0,
        Parent = ContentContainer
    })
    local AccountLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = PanelState.AccountTabContent
    })
    
    -- ═══════════════════════════════════════════════════════════════
    -- COMPACT PREMIUM PROFILE HEADER
    -- ═══════════════════════════════════════════════════════════════
    local ProfileHeaderFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 100),
        LayoutOrder = 0,
        ClipsDescendants = true,
        Parent = PanelState.AccountTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = ProfileHeaderFrame})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1.5, Transparency = 0.4, Parent = ProfileHeaderFrame})
    
    -- Gradient background
    local ProfileGradientBg = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.85,
        Size = UDim2.new(2, 0, 2, 0),
        Position = UDim2.new(-0.5, 0, -0.5, 0),
        Parent = ProfileHeaderFrame
    })
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(147, 112, 219)),
            ColorSequenceKeypoint.new(1, Theme.Accent)
        }),
        Rotation = 45,
        Parent = ProfileGradientBg
    })
    
    -- Compact avatar with ring
    local AvatarContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 70, 0, 70),
        Position = UDim2.new(0, 14, 0.5, -35),
        Parent = ProfileHeaderFrame
    })
    local AvatarRing = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 6, 1, 6),
        Position = UDim2.new(0, -3, 0, -3),
        Parent = AvatarContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = AvatarRing})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 2.5, Parent = AvatarRing})
    
    local AvatarHolder = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = AvatarContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = AvatarHolder})
    Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 1, -6),
        Position = UDim2.new(0, 3, 0, 3),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. playerUserId .. "&width=150&height=150&format=png",
        Parent = AvatarHolder
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = AvatarHolder})
    
    -- Online indicator
    local OnlineIndicator = Create("Frame", {
        BackgroundColor3 = Theme.Success,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(1, -10, 1, -10),
        Parent = AvatarContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = OnlineIndicator})
    Create("UIStroke", {Color = Theme.Card, Thickness = 2, Parent = OnlineIndicator})
    
    -- User info (compact)
    local UserInfoContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -110, 0, 70),
        Position = UDim2.new(0, 96, 0.5, -35),
        Parent = ProfileHeaderFrame
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0, 5),
        Font = Enum.Font.GothamBlack,
        Text = playerDisplayName,
        TextColor3 = Theme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = UserInfoContainer
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 28),
        Font = Enum.Font.GothamMedium,
        Text = "@" .. (localPlayer and localPlayer.Name or "Unknown"),
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = UserInfoContainer
    })
    -- Age badge
    local AgeBadge = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 90, 0, 22),
        Position = UDim2.new(0, 0, 0, 48),
        Parent = UserInfoContainer
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = AgeBadge})
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(147, 112, 219))
        }),
        Rotation = 90,
        Parent = AgeBadge
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "📅 " .. playerAccountAge .. " дней",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        Parent = AgeBadge
    })
    
    -- ═══════════════════════════════════════════════════════════════
    -- COMPACT INFO GRID (2 columns)
    -- ═══════════════════════════════════════════════════════════════
    local function CreateCompactInfoCard(title, value, icon, iconColor, layoutOrder)
        local card = Create("Frame", {
            BackgroundColor3 = Theme.Card,
            Size = UDim2.new(1, 0, 0, 52),
            LayoutOrder = layoutOrder,
            Parent = PanelState.AccountTabContent
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = card})
        Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.6, Parent = card})
        
        -- Icon
        local iconHolder = Create("Frame", {
            BackgroundColor3 = iconColor,
            BackgroundTransparency = 0.85,
            Size = UDim2.new(0, 36, 0, 36),
            Position = UDim2.new(0, 10, 0.5, -18),
            Parent = card
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = iconHolder})
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = icon,
            TextColor3 = iconColor,
            TextSize = 16,
            Parent = iconHolder
        })
        
        -- Title & Value
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 0, 14),
            Position = UDim2.new(0, 54, 0, 10),
            Font = Enum.Font.GothamMedium,
            Text = title,
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = card
        })
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 0, 18),
            Position = UDim2.new(0, 54, 0, 26),
            Font = Enum.Font.GothamBold,
            Text = value,
            TextColor3 = Theme.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = card
        })
        
        card.MouseEnter:Connect(function()
            Tween(card, 0.15, {BackgroundColor3 = Theme.Secondary})
        end)
        card.MouseLeave:Connect(function()
            Tween(card, 0.15, {BackgroundColor3 = Theme.Card})
        end)
        return card
    end
    
    CreateCompactInfoCard("Юзернейм", localPlayer and localPlayer.Name or "Unknown", "@", Theme.Accent, 1)
    CreateCompactInfoCard("Дисплей", playerDisplayName, "👤", Theme.Success, 2)
    CreateCompactInfoCard("HWID-ID", hwidId, "#", Color3.fromRGB(147, 112, 219), 3)
    CreateCompactInfoCard("Игра", currentPlaceName, "🎮", Theme.Info, 4)
    CreateCompactInfoCard("Place ID", tostring(currentPlace), "🆔", Color3.fromRGB(255, 107, 129), 5)
    
    -- ═══════════════════════════════════════════════════════════════
    -- COPY HWID BUTTON (Compact)
    -- ═══════════════════════════════════════════════════════════════
    local CopyHwidBtn = Create("TextButton", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(1, 0, 0, 40),
        LayoutOrder = 6,
        Font = Enum.Font.GothamBold,
        Text = "📋 Скопировать HWID",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 13,
        AutoButtonColor = false,
        Parent = PanelState.AccountTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = CopyHwidBtn})
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(147, 112, 219))
        }),
        Rotation = 90,
        Parent = CopyHwidBtn
    })
    
    CopyHwidBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(hwidId)
            CopyHwidBtn.Text = "✓ Скопировано!"
            Tween(CopyHwidBtn, 0.2, {BackgroundColor3 = Theme.Success})
            task.delay(1.5, function()
                CopyHwidBtn.Text = "📋 Скопировать HWID"
                Tween(CopyHwidBtn, 0.2, {BackgroundColor3 = Theme.Accent})
            end)
            MagicTulevo:Notify({Title = "✅ Готово", Message = "HWID скопирован", Type = "Success", Duration = 2})
        end
    end)
    
    CopyHwidBtn.MouseEnter:Connect(function()
        Tween(CopyHwidBtn, 0.15, {Size = UDim2.new(1, 0, 0, 43)})
    end)
    CopyHwidBtn.MouseLeave:Connect(function()
        Tween(CopyHwidBtn, 0.15, {Size = UDim2.new(1, 0, 0, 40)})
    end)
    
    -- Create Info Tab Content with Beautiful Design
    PanelState.InfoTabContent = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 850),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.3,
        Visible = false,
        BorderSizePixel = 0,
        Parent = ContentContainer
    })
    local InfoLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = PanelState.InfoTabContent
    })
    
    -- ═══════════════════════════════════════════════════════════════
    -- HERO HEADER with animated gradient background
    -- ═══════════════════════════════════════════════════════════════
    local InfoHeaderFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 100),
        LayoutOrder = 0,
        ClipsDescendants = true,
        Parent = PanelState.InfoTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = InfoHeaderFrame})
    
    -- Animated gradient background
    local HeaderGradientBg = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.85,
        Size = UDim2.new(3, 0, 3, 0),
        Position = UDim2.new(-1, 0, -1, 0),
        Parent = InfoHeaderFrame
    })
    local HeaderGradient = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(217, 70, 239)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
        }),
        Rotation = 45,
        Parent = HeaderGradientBg
    })
    
    -- OPTIMIZED: Use consolidated animation loop for header gradient
    RegisterGradientAnimation(HeaderGradient, 0.15)
    
    -- Glowing accent line at top
    local HeaderAccentLine = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = InfoHeaderFrame
    })
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(217, 70, 239)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
        }),
        Parent = HeaderAccentLine
    })
    
    -- Animated icon container with glow
    local InfoIconContainer = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(0, 18, 0.5, -28),
        Parent = InfoHeaderFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = InfoIconContainer})
    
    -- Icon glow effect
    local InfoIconGlow = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://5554236805",
        ImageColor3 = Theme.Accent,
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = 0,
        Parent = InfoIconContainer
    })
    
    -- Gradient on icon
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(217, 70, 239)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 92, 246))
        }),
        Rotation = 45,
        Parent = InfoIconContainer
    })
    
    local InfoHeaderIcon = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = "i",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 28,
        Parent = InfoIconContainer
    })
    
    -- OPTIMIZED: Removed individual RenderStepped for info icon - static position instead
    -- Floating animation removed to reduce lag on startup
    
    -- Title and subtitle
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 0, 26),
        Position = UDim2.new(0, 88, 0, 20),
        Font = Enum.Font.GothamBlack,
        Text = "Magic Tulevo",
        TextColor3 = Theme.Text,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = InfoHeaderFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 0, 18),
        Position = UDim2.new(0, 88, 0, 48),
        Font = Enum.Font.GothamMedium,
        Text = "Premium UI Library for Roblox",
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = InfoHeaderFrame
    })
    
    -- Version badge
    local VersionBadge = Create("Frame", {
        BackgroundColor3 = Theme.Success,
        BackgroundTransparency = 0.8,
        Size = UDim2.new(0, 50, 0, 22),
        Position = UDim2.new(1, -62, 0, 12),
        Parent = InfoHeaderFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = VersionBadge})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "1.0 Beta",
        TextColor3 = Theme.Success,
        TextSize = 11,
        Parent = VersionBadge
    })
    
    -- ═══════════════════════════════════════════════════════════════
    -- STATISTICS CARDS ROW
    -- ═══════════════════════════════════════════════════════════════
    local StatsContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 70),
        LayoutOrder = 1,
        Parent = PanelState.InfoTabContent
    })
    
    local function CreateStatCard(parent, position, icon, value, label, color)
        local Card = Create("Frame", {
            BackgroundColor3 = Theme.Card,
            Size = UDim2.new(0.32, -4, 1, 0),
            Position = position,
            Parent = parent
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Card})
        Create("UIStroke", {Color = color, Thickness = 1, Transparency = 0.7, Parent = Card})
        
        local IconBg = Create("Frame", {
            BackgroundColor3 = color,
            BackgroundTransparency = 0.85,
            Size = UDim2.new(0, 36, 0, 36),
            Position = UDim2.new(0, 10, 0.5, -18),
            Parent = Card
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = IconBg})
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = icon,
            TextColor3 = color,
            TextSize = 16,
            Parent = IconBg
        })
        
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -56, 0, 22),
            Position = UDim2.new(0, 52, 0, 12),
            Font = Enum.Font.GothamBlack,
            Text = value,
            TextColor3 = Theme.Text,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Card
        })
        
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -56, 0, 14),
            Position = UDim2.new(0, 52, 0, 36),
            Font = Enum.Font.Gotham,
            Text = label,
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Card
        })
        
        return Card
    end
    
    CreateStatCard(StatsContainer, UDim2.new(0, 0, 0, 0), "+", "FREE", "Price", Theme.Success)
    CreateStatCard(StatsContainer, UDim2.new(0.34, 0, 0, 0), "*", "17+", "Themes", Theme.Accent)
    CreateStatCard(StatsContainer, UDim2.new(0.68, 0, 0, 0), "^", "100%", "Open Source", Theme.Warning)
    
    -- ═══════════════════════════════════════════════════════════════
    -- SOCIAL LINKS SECTION
    -- ═══════════════════════════════════════════════════════════════
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "SOCIAL LINKS",
        TextColor3 = Theme.TextDark,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        Parent = PanelState.InfoTabContent
    })
    
    -- Discord Card with beautiful design
    local DiscordFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 72),
        LayoutOrder = 3,
        ClipsDescendants = true,
        Parent = PanelState.InfoTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = DiscordFrame})
    local DiscordStroke = Create("UIStroke", {Color = Color3.fromRGB(88, 101, 242), Thickness = 1, Transparency = 0.5, Parent = DiscordFrame})
    
    -- Discord gradient accent
    local DiscordAccent = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(88, 101, 242),
        Size = UDim2.new(0, 5, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = DiscordFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = DiscordAccent})
    
    -- Discord icon with glow
    local DiscordIconBg = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(88, 101, 242),
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 16, 0.5, -22),
        Parent = DiscordFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = DiscordIconBg})
    AddGlow(DiscordIconBg, Color3.fromRGB(88, 101, 242), 15)
    
    Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(0.5, -13, 0.5, -13),
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(324, 764),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        Parent = DiscordIconBg
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 0, 18),
        Position = UDim2.new(0, 72, 0, 14),
        Font = Enum.Font.GothamBold,
        Text = "Discord Server",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = DiscordFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -180, 0, 16),
        Position = UDim2.new(0, 72, 0, 34),
        Font = Enum.Font.Gotham,
        Text = "Join our community for updates and support",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = DiscordFrame
    })
    
    local DiscordLink = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 0, 14),
        Position = UDim2.new(0, 72, 0, 52),
        Font = Enum.Font.GothamMedium,
        Text = "discord.gg/3X64JmSWsa",
        TextColor3 = Color3.fromRGB(88, 101, 242),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = DiscordFrame
    })
    
    local DiscordCopyBtn = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(88, 101, 242),
        Size = UDim2.new(0, 70, 0, 34),
        Position = UDim2.new(1, -82, 0.5, -17),
        Font = Enum.Font.GothamBold,
        Text = "Join",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        AutoButtonColor = false,
        Parent = DiscordFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = DiscordCopyBtn})
    
    DiscordCopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard("https://discord.gg/3X64JmSWsa")
            DiscordCopyBtn.Text = "Copied!"
            Tween(DiscordCopyBtn, 0.2, {BackgroundColor3 = Theme.Success})
            task.delay(1.5, function()
                DiscordCopyBtn.Text = "Join"
                Tween(DiscordCopyBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(88, 101, 242)})
            end)
            MagicTulevo:Notify({Title = "Copied!", Message = "Discord link copied to clipboard", Type = "Success", Duration = 2})
        end
    end)
    DiscordCopyBtn.MouseEnter:Connect(function()
        Tween(DiscordCopyBtn, 0.2, {Size = UDim2.new(0, 74, 0, 38), Position = UDim2.new(1, -84, 0.5, -19)})
        Tween(DiscordStroke, 0.2, {Transparency = 0})
    end)
    DiscordCopyBtn.MouseLeave:Connect(function()
        Tween(DiscordCopyBtn, 0.2, {Size = UDim2.new(0, 70, 0, 34), Position = UDim2.new(1, -82, 0.5, -17)})
        Tween(DiscordStroke, 0.2, {Transparency = 0.5})
    end)
    
    -- Telegram Card
    local TelegramFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 72),
        LayoutOrder = 4,
        ClipsDescendants = true,
        Parent = PanelState.InfoTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = TelegramFrame})
    local TelegramStroke = Create("UIStroke", {Color = Color3.fromRGB(0, 136, 204), Thickness = 1, Transparency = 0.5, Parent = TelegramFrame})
    
    local TelegramAccent = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 136, 204),
        Size = UDim2.new(0, 5, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = TelegramFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = TelegramAccent})
    
    local TelegramIconBg = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 136, 204),
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 16, 0.5, -22),
        Parent = TelegramFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = TelegramIconBg})
    AddGlow(TelegramIconBg, Color3.fromRGB(0, 136, 204), 15)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = "T",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 22,
        Parent = TelegramIconBg
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 0, 18),
        Position = UDim2.new(0, 72, 0, 14),
        Font = Enum.Font.GothamBold,
        Text = "Telegram Channel",
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TelegramFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -180, 0, 16),
        Position = UDim2.new(0, 72, 0, 34),
        Font = Enum.Font.Gotham,
        Text = "Follow for news and announcements",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = TelegramFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 0, 14),
        Position = UDim2.new(0, 72, 0, 52),
        Font = Enum.Font.GothamMedium,
        Text = "t.me/tsunami_offical",
        TextColor3 = Color3.fromRGB(0, 136, 204),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TelegramFrame
    })
    
    local TelegramCopyBtn = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(0, 136, 204),
        Size = UDim2.new(0, 70, 0, 34),
        Position = UDim2.new(1, -82, 0.5, -17),
        Font = Enum.Font.GothamBold,
        Text = "Follow",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        AutoButtonColor = false,
        Parent = TelegramFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = TelegramCopyBtn})
    
    TelegramCopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard("https://t.me/tsunami_offical")
            TelegramCopyBtn.Text = "Copied!"
            Tween(TelegramCopyBtn, 0.2, {BackgroundColor3 = Theme.Success})
            task.delay(1.5, function()
                TelegramCopyBtn.Text = "Follow"
                Tween(TelegramCopyBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(0, 136, 204)})
            end)
            MagicTulevo:Notify({Title = "Copied!", Message = "Telegram link copied to clipboard", Type = "Success", Duration = 2})
        end
    end)
    TelegramCopyBtn.MouseEnter:Connect(function()
        Tween(TelegramCopyBtn, 0.2, {Size = UDim2.new(0, 74, 0, 38), Position = UDim2.new(1, -84, 0.5, -19)})
        Tween(TelegramStroke, 0.2, {Transparency = 0})
    end)
    TelegramCopyBtn.MouseLeave:Connect(function()
        Tween(TelegramCopyBtn, 0.2, {Size = UDim2.new(0, 70, 0, 34), Position = UDim2.new(1, -82, 0.5, -17)})
        Tween(TelegramStroke, 0.2, {Transparency = 0.5})
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- DEVELOPERS SECTION
    -- ═══════════════════════════════════════════════════════════════
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "DEVELOPMENT TEAM",
        TextColor3 = Theme.TextDark,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 5,
        Parent = PanelState.InfoTabContent
    })
    
    -- Lead Developer Card with premium design
    local LeadDevFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 90),
        LayoutOrder = 6,
        ClipsDescendants = true,
        Parent = PanelState.InfoTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = LeadDevFrame})
    
    -- Premium gradient border for lead dev
    local LeadDevStroke = Create("UIStroke", {
        Color = Theme.Accent,
        Thickness = 2,
        Transparency = 0.3,
        Parent = LeadDevFrame
    })
    
    -- Animated background shimmer
    local LeadDevShimmer = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.92,
        Size = UDim2.new(2, 0, 2, 0),
        Position = UDim2.new(-0.5, 0, -0.5, 0),
        Parent = LeadDevFrame
    })
    local LeadDevShimmerGrad = Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(217, 70, 239)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
        }),
        Rotation = 45,
        Parent = LeadDevShimmer
    })
    
    -- OPTIMIZED: Removed lead dev shimmer animation for better startup performance
    
    -- Crown badge for lead dev
    local LeadDevBadge = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 16, 0.5, -25),
        Parent = LeadDevFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = LeadDevBadge})
    Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
        }),
        Rotation = 45,
        Parent = LeadDevBadge
    })
    AddGlow(LeadDevBadge, Color3.fromRGB(255, 215, 0), 20)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = "1",
        TextColor3 = Color3.fromRGB(30, 30, 30),
        TextSize = 22,
        Parent = LeadDevBadge
    })
    
    -- Lead dev info
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 78, 0, 14),
        Font = Enum.Font.GothamBlack,
        Text = "tsunamioffical",
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = LeadDevFrame
    })
    
    -- Role badge
    local LeadRoleBadge = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 215, 0),
        BackgroundTransparency = 0.8,
        Size = UDim2.new(0, 100, 0, 20),
        Position = UDim2.new(0, 78, 0, 36),
        Parent = LeadDevFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = LeadRoleBadge})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "Lead Developer",
        TextColor3 = Color3.fromRGB(255, 215, 0),
        TextSize = 10,
        Parent = LeadRoleBadge
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 0, 16),
        Position = UDim2.new(0, 78, 0, 62),
        Font = Enum.Font.Gotham,
        Text = "Discord: tsunamioffical",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = LeadDevFrame
    })
    
    -- Assistant Developer Card
    local AssistantDevFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 100),
        LayoutOrder = 7,
        ClipsDescendants = true,
        Parent = PanelState.InfoTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = AssistantDevFrame})
    Create("UIStroke", {Color = Theme.Success, Thickness = 1, Transparency = 0.5, Parent = AssistantDevFrame})
    
    -- Assistant badge
    local AssistantDevBadge = Create("Frame", {
        BackgroundColor3 = Theme.Success,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 16, 0.5, -25),
        Parent = AssistantDevFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = AssistantDevBadge})
    AddGlow(AssistantDevBadge, Theme.Success, 15)
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBlack,
        Text = "2",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 22,
        Parent = AssistantDevBadge
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 78, 0, 12),
        Font = Enum.Font.GothamBlack,
        Text = "zenjiux",
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = AssistantDevFrame
    })
    
    local AssistantRoleBadge = Create("Frame", {
        BackgroundColor3 = Theme.Success,
        BackgroundTransparency = 0.8,
        Size = UDim2.new(0, 80, 0, 20),
        Position = UDim2.new(0, 78, 0, 34),
        Parent = AssistantDevFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = AssistantRoleBadge})
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "Co-Developer",
        TextColor3 = Theme.Success,
        TextSize = 10,
        Parent = AssistantRoleBadge
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 0, 16),
        Position = UDim2.new(0, 78, 0, 60),
        Font = Enum.Font.Gotham,
        Text = "Discord: zenjiux",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = AssistantDevFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 0, 16),
        Position = UDim2.new(0, 78, 0, 78),
        Font = Enum.Font.Gotham,
        Text = "Telegram: zenijux",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = AssistantDevFrame
    })
    
    -- ═══════════════════════════════════════════════════════════════
    -- ABOUT SECTION
    -- ═══════════════════════════════════════════════════════════════
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "ABOUT PROJECT",
        TextColor3 = Theme.TextDark,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 8,
        Parent = PanelState.InfoTabContent
    })
    
    local AboutFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 150),
        LayoutOrder = 9,
        ClipsDescendants = true,
        Parent = PanelState.InfoTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = AboutFrame})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = AboutFrame})
    
    -- Quote icon
    local QuoteIcon = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 12, 0, 8),
        Font = Enum.Font.GothamBlack,
        Text = '"',
        TextColor3 = Theme.Accent,
        TextTransparency = 0.7,
        TextSize = 50,
        Parent = AboutFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 80),
        Position = UDim2.new(0, 15, 0, 35),
        Font = Enum.Font.Gotham,
        Text = "This script library is unlike other libraries before, and I hope you'll really like it. Support us by joining our Discord server, because we only make menus and free scripts with a lot of features for 0 rubles or dollars, for all of you who join Discord and never leave...",
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = AboutFrame
    })
    
    -- Signature line
    local SignatureLine = Create("Frame", {
        BackgroundColor3 = Theme.Border,
        Size = UDim2.new(1, -30, 0, 1),
        Position = UDim2.new(0, 15, 1, -40),
        Parent = AboutFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 28),
        Position = UDim2.new(0, 15, 1, -35),
        Font = Enum.Font.GothamMedium,
        Text = "- tsunamioffical, Creator & Script Manager",
        TextColor3 = Theme.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = AboutFrame
    })
    
    -- GitHub Link Frame
    local GitHubFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 50),
        LayoutOrder = 5,
        Parent = PanelState.InfoTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = GitHubFrame})
    Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = GitHubFrame})
    
    -- GitHub Icon (using custom drawing)
    local GitHubIconHolder = Create("Frame", {
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 12, 0.5, -16),
        Parent = GitHubFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = GitHubIconHolder})
    
    local GitHubIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://6031280882",
        ImageColor3 = Theme.TextMuted,
        Parent = GitHubIconHolder
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 100, 0, 18),
        Position = UDim2.new(0, 54, 0, 8),
        Font = Enum.Font.GothamBold,
        Text = "Source Code",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = GitHubFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 14),
        Position = UDim2.new(0, 54, 0, 28),
        Font = Enum.Font.Gotham,
        Text = "View on GitHub",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = GitHubFrame
    })
    
    local GitHubBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = GitHubFrame
    })
    
    GitHubBtn.MouseEnter:Connect(function()
        Tween(GitHubFrame, 0.2, {BackgroundColor3 = Theme.CardHover})
        Tween(GitHubIcon, 0.2, {ImageColor3 = Theme.Accent})
        Tween(GitHubIconHolder, 0.2, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85})
    end)
    GitHubBtn.MouseLeave:Connect(function()
        Tween(GitHubFrame, 0.2, {BackgroundColor3 = Theme.Card})
        Tween(GitHubIcon, 0.2, {ImageColor3 = Theme.TextMuted})
        Tween(GitHubIconHolder, 0.2, {BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0})
    end)
    GitHubBtn.MouseButton1Click:Connect(function()
        PlaySound("rbxassetid://6895079853", 0.3)
        setclipboard("https://github.com/TSMOffical/MagicTulevo-UI/")
        MagicTulevo:Notify({
            Title = "GitHub",
            Message = "Link copied to clipboard!",
            Type = "Success",
            Duration = 3
        })
    end)
    
    -- =====================================================
    -- CONFIGS TAB - Coming Soon
    -- =====================================================
    PanelState.ConfigsTabContent = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = ContentContainer
    })
    
    -- Coming Soon Message
    local ConfigSoonLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "Soon To config system :<",
        TextColor3 = Theme.TextMuted,
        TextSize = 18,
        Parent = PanelState.ConfigsTabContent
    })
    
    -- =====================================================
    -- CUSTOM THEME TAB - Color Picker Panel
    -- =====================================================
    PanelState.CustomTabContent = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 900),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.3,
        Visible = false,
        BorderSizePixel = 0,
        Parent = ContentContainer
    })
    local CustomLayout = Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = PanelState.CustomTabContent
    })
    
    -- Auto-adjust canvas size based on content
    CustomLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        PanelState.CustomTabContent.CanvasSize = UDim2.new(0, 0, 0, CustomLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Custom Theme Header
    local CustomHeaderFrame = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(1, 0, 0, 60),
        LayoutOrder = 0,
        Parent = PanelState.CustomTabContent
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = CustomHeaderFrame})
    Create("UIStroke", {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = CustomHeaderFrame})
    
    local CustomHeaderIcon = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 14, 0.5, -16),
        Image = "rbxassetid://3926307971",
        ImageRectOffset = Vector2.new(404, 164),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = Theme.Accent,
        Parent = CustomHeaderFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 22),
        Position = UDim2.new(0, 56, 0, 10),
        Font = Enum.Font.GothamBold,
        Text = "Custom Theme Editor",
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = CustomHeaderFrame
    })
    
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 16),
        Position = UDim2.new(0, 56, 0, 34),
        Font = Enum.Font.Gotham,
        Text = "Customize every color in the UI",
        TextColor3 = Theme.TextMuted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = CustomHeaderFrame
    })
    
    -- Color Pickers Storage
    local ColorPickers = {}
    
    -- Function to update custom theme and apply
    local function UpdateCustomTheme(colorKey, newColor)
        CustomThemeColors[colorKey] = newColor
        -- Update the Custom theme in AllThemes
        AllThemes[CustomThemeIndex].Colors = CustomThemeColors
        -- If Custom theme is currently active, apply changes
        if CurrentThemeIndex == CustomThemeIndex then
            ApplyTheme(AllThemes[CustomThemeIndex])
        end
    end
    
    -- Background Colors Section
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "BACKGROUND COLORS",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = PanelState.CustomTabContent
    })
    
    ColorPickers.Background = CreateColorPicker(PanelState.CustomTabContent, "Background", CustomThemeColors.Background, function(c)
        UpdateCustomTheme("Background", c)
    end)
    ColorPickers.Background.Frame.LayoutOrder = 2
    
    ColorPickers.Secondary = CreateColorPicker(PanelState.CustomTabContent, "Secondary", CustomThemeColors.Secondary, function(c)
        UpdateCustomTheme("Secondary", c)
    end)
    ColorPickers.Secondary.Frame.LayoutOrder = 3
    
    ColorPickers.Card = CreateColorPicker(PanelState.CustomTabContent, "Card", CustomThemeColors.Card, function(c)
        UpdateCustomTheme("Card", c)
    end)
    ColorPickers.Card.Frame.LayoutOrder = 4
    
    ColorPickers.CardHover = CreateColorPicker(PanelState.CustomTabContent, "Card Hover", CustomThemeColors.CardHover, function(c)
        UpdateCustomTheme("CardHover", c)
    end)
    ColorPickers.CardHover.Frame.LayoutOrder = 5
    
    ColorPickers.Border = CreateColorPicker(PanelState.CustomTabContent, "Border", CustomThemeColors.Border, function(c)
        UpdateCustomTheme("Border", c)
    end)
    ColorPickers.Border.Frame.LayoutOrder = 6
    
    -- Accent Colors Section
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "ACCENT COLORS",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 7,
        Parent = PanelState.CustomTabContent
    })
    
    ColorPickers.Accent = CreateColorPicker(PanelState.CustomTabContent, "Accent", CustomThemeColors.Accent, function(c)
        UpdateCustomTheme("Accent", c)
    end)
    ColorPickers.Accent.Frame.LayoutOrder = 8
    
    ColorPickers.AccentDark = CreateColorPicker(PanelState.CustomTabContent, "Accent Dark", CustomThemeColors.AccentDark, function(c)
        UpdateCustomTheme("AccentDark", c)
    end)
    ColorPickers.AccentDark.Frame.LayoutOrder = 9
    
    ColorPickers.AccentGlow = CreateColorPicker(PanelState.CustomTabContent, "Accent Glow", CustomThemeColors.AccentGlow, function(c)
        UpdateCustomTheme("AccentGlow", c)
    end)
    ColorPickers.AccentGlow.Frame.LayoutOrder = 10
    
    -- Text Colors Section
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "TEXT COLORS",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 11,
        Parent = PanelState.CustomTabContent
    })
    
    ColorPickers.Text = CreateColorPicker(PanelState.CustomTabContent, "Text", CustomThemeColors.Text, function(c)
        UpdateCustomTheme("Text", c)
    end)
    ColorPickers.Text.Frame.LayoutOrder = 12
    
    ColorPickers.TextMuted = CreateColorPicker(PanelState.CustomTabContent, "Text Muted", CustomThemeColors.TextMuted, function(c)
        UpdateCustomTheme("TextMuted", c)
    end)
    ColorPickers.TextMuted.Frame.LayoutOrder = 13
    
    ColorPickers.TextDark = CreateColorPicker(PanelState.CustomTabContent, "Text Dark", CustomThemeColors.TextDark, function(c)
        UpdateCustomTheme("TextDark", c)
    end)
    ColorPickers.TextDark.Frame.LayoutOrder = 14
    
    -- Status Colors Section
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "STATUS COLORS",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 15,
        Parent = PanelState.CustomTabContent
    })
    
    ColorPickers.Success = CreateColorPicker(PanelState.CustomTabContent, "Success", CustomThemeColors.Success, function(c)
        UpdateCustomTheme("Success", c)
    end)
    ColorPickers.Success.Frame.LayoutOrder = 16
    
    ColorPickers.Error = CreateColorPicker(PanelState.CustomTabContent, "Error", CustomThemeColors.Error, function(c)
        UpdateCustomTheme("Error", c)
    end)
    ColorPickers.Error.Frame.LayoutOrder = 17
    
    ColorPickers.Warning = CreateColorPicker(PanelState.CustomTabContent, "Warning", CustomThemeColors.Warning, function(c)
        UpdateCustomTheme("Warning", c)
    end)
    ColorPickers.Warning.Frame.LayoutOrder = 18
    
    -- Preset Buttons Section
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "QUICK PRESETS",
        TextColor3 = Theme.TextDark,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 19,
        Parent = PanelState.CustomTabContent
    })
    
    local PresetContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = 20,
        Parent = PanelState.CustomTabContent
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        Parent = PresetContainer
    })
    
    local function CreatePresetButton(name, colors)
        local btn = Create("TextButton", {
            BackgroundColor3 = colors.Accent,
            Size = UDim2.new(0, 80, 0, 32),
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 11,
            AutoButtonColor = false,
            Parent = PresetContainer
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = btn})
        
        btn.MouseEnter:Connect(function()
            Tween(btn, 0.15, {Size = UDim2.new(0, 84, 0, 34)})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.15, {Size = UDim2.new(0, 80, 0, 32)})
        end)
        btn.MouseButton1Click:Connect(function()
            for key, color in pairs(colors) do
                CustomThemeColors[key] = color
                if ColorPickers[key] then
                    ColorPickers[key].SetColor(color)
                end
            end
            AllThemes[CustomThemeIndex].Colors = CustomThemeColors
            if CurrentThemeIndex == CustomThemeIndex then
                ApplyTheme(AllThemes[CustomThemeIndex])
            end
            MagicTulevo:Notify({Title = "Preset Applied", Message = name .. " colors loaded!", Type = "Success", Duration = 2})
        end)
        return btn
    end
    
    -- Quick preset buttons
    CreatePresetButton("Purple", {
        Background = Color3.fromRGB(13, 13, 18),
        Secondary = Color3.fromRGB(18, 18, 25),
        Card = Color3.fromRGB(24, 24, 34),
        CardHover = Color3.fromRGB(32, 32, 45),
        Accent = Color3.fromRGB(138, 92, 246),
        AccentDark = Color3.fromRGB(108, 62, 216),
        AccentGlow = Color3.fromRGB(168, 122, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(140, 140, 165),
        TextDark = Color3.fromRGB(90, 90, 110),
        Border = Color3.fromRGB(38, 38, 52),
        Success = Color3.fromRGB(34, 197, 94),
        Error = Color3.fromRGB(239, 68, 68),
        Warning = Color3.fromRGB(245, 158, 11)
    })
    
    CreatePresetButton("Blue", {
        Background = Color3.fromRGB(10, 15, 25),
        Secondary = Color3.fromRGB(15, 22, 35),
        Card = Color3.fromRGB(20, 30, 48),
        CardHover = Color3.fromRGB(28, 42, 65),
        Accent = Color3.fromRGB(59, 130, 246),
        AccentDark = Color3.fromRGB(37, 99, 235),
        AccentGlow = Color3.fromRGB(96, 165, 250),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(148, 163, 184),
        TextDark = Color3.fromRGB(71, 85, 105),
        Border = Color3.fromRGB(30, 41, 59),
        Success = Color3.fromRGB(34, 197, 94),
        Error = Color3.fromRGB(239, 68, 68),
        Warning = Color3.fromRGB(245, 158, 11)
    })
    
    CreatePresetButton("Red", {
        Background = Color3.fromRGB(18, 10, 12),
        Secondary = Color3.fromRGB(25, 15, 18),
        Card = Color3.fromRGB(38, 22, 26),
        CardHover = Color3.fromRGB(52, 30, 36),
        Accent = Color3.fromRGB(239, 68, 68),
        AccentDark = Color3.fromRGB(185, 28, 28),
        AccentGlow = Color3.fromRGB(252, 129, 129),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(175, 140, 145),
        TextDark = Color3.fromRGB(115, 80, 85),
        Border = Color3.fromRGB(52, 32, 38),
        Success = Color3.fromRGB(34, 197, 94),
        Error = Color3.fromRGB(239, 68, 68),
        Warning = Color3.fromRGB(245, 158, 11)
    })
    
    CreatePresetButton("Green", {
        Background = Color3.fromRGB(10, 18, 15),
        Secondary = Color3.fromRGB(15, 25, 20),
        Card = Color3.fromRGB(20, 35, 28),
        CardHover = Color3.fromRGB(28, 48, 38),
        Accent = Color3.fromRGB(16, 185, 129),
        AccentDark = Color3.fromRGB(5, 150, 105),
        AccentGlow = Color3.fromRGB(52, 211, 153),
        Text = Color3.fromRGB(255, 255, 255),
        TextMuted = Color3.fromRGB(134, 169, 154),
        TextDark = Color3.fromRGB(74, 109, 94),
        Border = Color3.fromRGB(30, 50, 40),
        Success = Color3.fromRGB(34, 197, 94),
        Error = Color3.fromRGB(239, 68, 68),
        Warning = Color3.fromRGB(245, 158, 11)
    })
    
    -- Custom Button Click Handler
    UI.CustomBtn.MouseButton1Click:Connect(function()
        PanelState.CustomOpen = not PanelState.CustomOpen
        if PanelState.CustomOpen then
            -- Hide other tabs
            for _, t in pairs(Window.Tabs) do
                if t.Content.Visible then
                    t.Content.Visible = false
                    Tween(t.Button, 0.25, {BackgroundTransparency = 1})
                    Tween(t.Label, 0.25, {TextColor3 = Theme.TextMuted})
                    Tween(t.Indicator, 0.25, {Size = UDim2.new(0, 3, 0, 0)})
                    Tween(t.Glow, 0.25, {BackgroundTransparency = 1})
                    if t.Icon then Tween(t.Icon, 0.25, {ImageColor3 = Theme.TextMuted}) end
                end
            end
            Window.CurrentTab = nil
            
            -- Hide Settings if open
            if PanelState.SettingsOpen then
                PanelState.SettingsOpen = false
                if PanelState.SettingsTabContent then PanelState.SettingsTabContent.Visible = false end
                Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Info if open
            if PanelState.InfoOpen then
                PanelState.InfoOpen = false
                if PanelState.InfoTabContent then PanelState.InfoTabContent.Visible = false end
                Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.TextMuted})
            end
            
            -- Hide Configs if open
            if PanelState.ConfigsOpen then
                PanelState.ConfigsOpen = false
                if PanelState.ConfigsTabContent then PanelState.ConfigsTabContent.Visible = false end
                Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Account if open
            if PanelState.AccountOpen then
                PanelState.AccountOpen = false
                if PanelState.AccountTabContent then PanelState.AccountTabContent.Visible = false end
                Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.Card})
            end
            
            -- Show Custom tab
            if PanelState.CustomTabContent then
                PanelState.CustomTabContent.Visible = true
                PanelState.CustomTabContent.Position = UDim2.new(0.05, 0, 0, 0)
                Tween(PanelState.CustomTabContent, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
            end
            Tween(UI.CustomBtn, 0.2, {BackgroundColor3 = Theme.Accent})
            Tween(UI.CustomIcon, 0.2, {ImageColor3 = Theme.Text})
        else
            -- Hide Custom tab and show first user tab
            if PanelState.CustomTabContent then
                PanelState.CustomTabContent.Visible = false
            end
            Tween(UI.CustomBtn, 0.2, {BackgroundColor3 = Theme.Card})
            Tween(UI.CustomIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            
            if Window.Tabs[1] then
                Window.Tabs[1]:Select()
            end
        end
    end)
    
    -- Info Button Click Handler
    UI.InfoBtn.MouseButton1Click:Connect(function()
        PanelState.InfoOpen = not PanelState.InfoOpen
        if PanelState.InfoOpen then
            -- Hide other tabs
            for _, t in pairs(Window.Tabs) do
                if t.Content.Visible then
                    t.Content.Visible = false
                    Tween(t.Button, 0.25, {BackgroundTransparency = 1})
                    Tween(t.Label, 0.25, {TextColor3 = Theme.TextMuted})
                    Tween(t.Indicator, 0.25, {Size = UDim2.new(0, 3, 0, 0)})
                    Tween(t.Glow, 0.25, {BackgroundTransparency = 1})
                    if t.Icon then Tween(t.Icon, 0.25, {ImageColor3 = Theme.TextMuted}) end
                end
            end
            Window.CurrentTab = nil
            
            -- Hide Settings if open
            if PanelState.SettingsOpen then
                PanelState.SettingsOpen = false
                PanelState.SettingsTabContent.Visible = false
                Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Configs if open
            if PanelState.ConfigsOpen then
                PanelState.ConfigsOpen = false
                if PanelState.ConfigsTabContent then
                    PanelState.ConfigsTabContent.Visible = false
                end
                Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Custom if open
            if PanelState.CustomOpen then
                PanelState.CustomOpen = false
                if PanelState.CustomTabContent then
                    PanelState.CustomTabContent.Visible = false
                end
                Tween(UI.CustomBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.CustomIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Account if open
            if PanelState.AccountOpen then
                PanelState.AccountOpen = false
                if PanelState.AccountTabContent then
                    PanelState.AccountTabContent.Visible = false
                end
                Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.Card})
            end
            
            -- Show Info tab
            PanelState.InfoTabContent.Visible = true
            PanelState.InfoTabContent.Position = UDim2.new(0.05, 0, 0, 0)
            Tween(PanelState.InfoTabContent, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
            Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.Accent})
            Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.Text})
        else
            -- Hide Info tab and show first user tab
            PanelState.InfoTabContent.Visible = false
            Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.Card})
            Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.TextMuted})
            -- Select first tab if exists
            if #Window.Tabs > 0 then
                Window.Tabs[1]:Select()
            end
        end
    end)

    local dragging = false
    local dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            -- Convert to absolute position if using center anchor
            if Main.AnchorPoint.X > 0 or Main.AnchorPoint.Y > 0 then
                local absPos = Main.AbsolutePosition
                Main.AnchorPoint = Vector2.new(0, 0)
                Main.Position = UDim2.new(0, absPos.X, 0, absPos.Y)
            end
            startPos = Main.Position
        end
    end)
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    -- OPTIMIZED: Track dragging connection for cleanup
    local dragConn = RunService.RenderStepped:Connect(function()
        if dragging and dragStart then
            local mouse = UserInputService:GetMouseLocation()
            local delta = Vector2.new(mouse.X - dragStart.X, mouse.Y - dragStart.Y)
            local target = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            Main.Position = Main.Position:Lerp(target, 0.2)
        end
    end)
    table.insert(MagicTulevo.Connections, dragConn)

    local resizing = false
    local resizeStart, startSize
    
    local ResizeHandle = Create("Frame", {
        BackgroundColor3 = Theme.Card,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -24, 1, -24),
        Parent = Main
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = ResizeHandle})
    
    local ResizeArrow = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "↘",
        TextColor3 = Theme.TextDark,
        TextSize = 14,
        Parent = ResizeHandle
    })
    
    local ResizeBtn = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = ResizeHandle
    })
    
    ResizeBtn.MouseEnter:Connect(function()
        Tween(ResizeHandle, 0.2, {BackgroundColor3 = Theme.CardHover})
        Tween(ResizeArrow, 0.2, {TextColor3 = Theme.Accent})
    end)
    ResizeBtn.MouseLeave:Connect(function()
        if not resizing then
            Tween(ResizeHandle, 0.2, {BackgroundColor3 = Theme.Card})
            Tween(ResizeArrow, 0.2, {TextColor3 = Theme.TextDark})
        end
    end)
    ResizeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = Main.AbsoluteSize
            Tween(ResizeHandle, 0.15, {BackgroundColor3 = Theme.Accent})
            Tween(ResizeArrow, 0.15, {TextColor3 = Theme.Text})
        end
    end)
    ResizeBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
            Tween(ResizeHandle, 0.2, {BackgroundColor3 = Theme.Card})
            Tween(ResizeArrow, 0.2, {TextColor3 = Theme.TextDark})
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and resizeStart and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local nw = math.max(minSize.X, startSize.X + delta.X)
            local nh = math.max(minSize.Y, startSize.Y + delta.Y)
            Tween(Main, 0.08, {Size = UDim2.new(0, nw, 0, nh)})
        end
    end)

    local keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if listeningKey and input.UserInputType == Enum.UserInputType.Keyboard then
            Window.ToggleKey = input.KeyCode
            toggleKey = input.KeyCode
            KeybindBtn.Text = input.KeyCode.Name
            listeningKey = false
            Tween(KeybindBtn, 0.2, {BackgroundColor3 = Theme.Secondary, TextColor3 = Theme.Accent})
            return
        end
        if processed then return end
        if input.KeyCode == toggleKey then
            Window.Visible = not Window.Visible
            if Window.Visible then
                ScreenGui.Enabled = true
                local currentPos = Main.Position
                local currentSize = Main.Size
                Main.Size = UDim2.new(0, 0, 0, 0)
                Main.BackgroundTransparency = 1
                
                Tween(Main, 0.4, {
                    Size = currentSize, 
                    Position = currentPos,
                    BackgroundTransparency = 0
                }, Enum.EasingStyle.Quint)
                
                PlaySound("rbxassetid://6895079853", 0.4)
            else
                PlaySound("rbxassetid://6895079853", 0.3)
                
                local toggleStates = {}
                for _, tog in pairs(Window.Toggles) do
                    if tog.Name then
                        toggleStates[tog.Name] = tog.Value
                    end
                end
                
                -- Convert CustomThemeColors to saveable format
                local customColorsToSave = {}
                for key, color in pairs(CustomThemeColors) do
                    customColorsToSave[key] = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
                end
                
                local settingsToSave = {
                    ThemeIndex = CurrentThemeIndex,
                    ToggleKey = toggleKey.Name,
                    WindowPosition = {Main.Position.X.Offset, Main.Position.Y.Offset},
                    WindowSize = {Main.Size.X.Offset, Main.Size.Y.Offset},
                    Toggles = toggleStates,
                    CustomThemeColors = customColorsToSave
                }
                SaveSettings(settingsToSave)
                
                local currentSize = Main.Size
                Tween(Main, 0.3, {
                    Size = UDim2.new(0, currentSize.X.Offset * 0.9, 0, currentSize.Y.Offset * 0.9),
                    BackgroundTransparency = 1
                }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
                
                task.delay(0.3, function()
                    if not Window.Visible then ScreenGui.Enabled = false end
                end)
            end
        end
    end)
    
    -- Store connection for cleanup
    table.insert(MagicTulevo.Connections, keyConnection)

    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Position = UDim2.new(0.5, 0, 0.6, 0)
    Main.BackgroundTransparency = 1
    
    task.delay(0.1, function()
        local targetPosition = savedPosition or UDim2.new(0.5, 0, 0.5, 0)
        Tween(Main, 0.5, {
            Size = size, 
            Position = targetPosition,
            BackgroundTransparency = 0
        }, Enum.EasingStyle.Quint)
        PlaySound("rbxassetid://6895079853", 0.5)
        task.delay(0.4, function()
            MagicTulevo:Notify({Title = "Magic Tulevo", Message = "UI успешно загружен!", Type = "Success", Duration = 3})
        end)
    end)

    function Window:Reload()
        for _, tog in pairs(Window.Toggles) do if tog.Value then tog:Set(false) end end
        ScreenGui:Destroy()
    end

    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local Tab = {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon or ""
        local tabIconRectOffset = tabConfig.IconRectOffset
        local tabIconRectSize = tabConfig.IconRectSize
        Window.TabOrder = Window.TabOrder + 1
        local order = Window.TabOrder

        local TabButton = Create("TextButton", {
            BackgroundColor3 = Theme.Card,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 38),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = TabList
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = TabButton})

        local TabGlow = Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 4, 1, 4),
            Position = UDim2.new(0, -2, 0, -2),
            ZIndex = 0,
            Parent = TabButton
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TabGlow})

        local TabIndicator = Create("Frame", {
            BackgroundColor3 = Theme.Accent,
            Size = UDim2.new(0, 3, 0, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Parent = TabButton
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = TabIndicator})

        local TabIcon = nil
        if tabIcon ~= "" then
            local iconProps = {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 12, 0.5, -9),
                Image = tabIcon,
                ImageColor3 = Theme.TextMuted,
                Parent = TabButton
            }
            if tabIconRectOffset then
                iconProps.ImageRectOffset = tabIconRectOffset
            end
            if tabIconRectSize then
                iconProps.ImageRectSize = tabIconRectSize
            end
            TabIcon = Create("ImageLabel", iconProps)
        end

        local TabLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, tabIcon ~= "" and -38 or -20, 1, 0),
            Position = UDim2.new(0, tabIcon ~= "" and 34 or 12, 0, 0),
            Font = Enum.Font.GothamMedium,
            Text = tabName,
            TextColor3 = Theme.TextMuted,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = TabButton
        })

        local TabContent = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarImageTransparency = 0.3,
            Visible = false,
            BorderSizePixel = 0,
            Parent = ContentContainer
        })
        local ContentLayout = Create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TabContent
        })
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 4)
        end)

        local function SelectTab()
            if Window.CurrentTab == Tab then return end
            
            -- Hide Settings tab if open
            if PanelState.SettingsOpen then
                PanelState.SettingsOpen = false
                if PanelState.SettingsTabContent then
                    PanelState.SettingsTabContent.Visible = false
                end
                Tween(UI.SettingsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.GearIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Info tab if open
            if PanelState.InfoOpen then
                PanelState.InfoOpen = false
                if PanelState.InfoTabContent then
                    PanelState.InfoTabContent.Visible = false
                end
                Tween(UI.InfoBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.InfoIcon, 0.2, {TextColor3 = Theme.TextMuted})
            end
            
            -- Hide Configs tab if open
            if PanelState.ConfigsOpen then
                PanelState.ConfigsOpen = false
                if PanelState.ConfigsTabContent then
                    PanelState.ConfigsTabContent.Visible = false
                end
                Tween(UI.ConfigsBtn, 0.2, {BackgroundColor3 = Theme.Card})
                Tween(UI.ConfigsIcon, 0.2, {ImageColor3 = Theme.TextMuted})
            end
            
            -- Hide Account tab if open
            if PanelState.AccountOpen then
                PanelState.AccountOpen = false
                if PanelState.AccountTabContent then
                    PanelState.AccountTabContent.Visible = false
                end
                Tween(PanelState.AccountPanel, 0.2, {BackgroundColor3 = Theme.Card})
            end
            
            for _, t in pairs(Window.Tabs) do
                if t.Content.Visible then
                    t.Content.Visible = false
                    Tween(t.Button, 0.25, {BackgroundTransparency = 1})
                    Tween(t.Label, 0.25, {TextColor3 = Theme.TextMuted})
                    Tween(t.Indicator, 0.25, {Size = UDim2.new(0, 3, 0, 0)})
                    Tween(t.Glow, 0.25, {BackgroundTransparency = 1})
                    if t.Icon then Tween(t.Icon, 0.25, {ImageColor3 = Theme.TextMuted}) end
                end
            end
            Window.CurrentTab = Tab
            TabContent.Position = UDim2.new(0.05, 0, 0, 0)
            TabContent.BackgroundTransparency = 1
            TabContent.Visible = true
            Tween(TabContent, 0.35, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
            Tween(TabButton, 0.25, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Card})
            Tween(TabLabel, 0.25, {TextColor3 = Theme.Text})
            Tween(TabIndicator, 0.3, {Size = UDim2.new(0, 3, 0, 22)}, Enum.EasingStyle.Back)
            Tween(TabGlow, 0.3, {BackgroundTransparency = 0.92})
            if TabIcon then Tween(TabIcon, 0.25, {ImageColor3 = Theme.Accent}) end
        end

        TabButton.MouseButton1Click:Connect(SelectTab)
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, 0.2, {BackgroundTransparency = 0.6, BackgroundColor3 = Theme.Card})
                Tween(TabLabel, 0.2, {TextColor3 = Theme.Text})
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, 0.2, {BackgroundTransparency = 1})
                Tween(TabLabel, 0.2, {TextColor3 = Theme.TextMuted})
            end
        end)

        Tab.Button = TabButton
        Tab.Content = TabContent
        Tab.Label = TabLabel
        Tab.Icon = TabIcon
        Tab.Name = tabName
        Tab.Indicator = TabIndicator
        Tab.Glow = TabGlow
        Tab.Select = SelectTab
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then SelectTab() end

        function Tab:CreateSection(cfg)
            cfg = cfg or {}
            local Section = Create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Parent = TabContent})
            Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 4, 0, 0), Font = Enum.Font.GothamBold, Text = (cfg.Name or "Section"):upper(), TextColor3 = Theme.TextDark, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = Section})
            return Section
        end

        function Tab:CreateLabel(cfg)
            cfg = cfg or {}
            local Label = Create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = TabContent})
            local LabelText = Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.Gotham, Text = cfg.Text or "Label", TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Label})
            local obj = {}
            function obj:Set(t) LabelText.Text = t end
            return obj
        end

        function Tab:CreateButton(cfg)
            cfg = cfg or {}
            local callback = cfg.Callback or function() end
            local description = cfg.Description or ""
            local Button = Create("TextButton", {BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 36), Font = Enum.Font.GothamMedium, Text = cfg.Name or "Button", TextColor3 = Theme.Text, TextSize = 13, AutoButtonColor = false, Parent = TabContent})
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Button})
            Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = Button})
            Button.MouseEnter:Connect(function() Tween(Button, 0.2, {BackgroundColor3 = Theme.CardHover}) end)
            Button.MouseLeave:Connect(function() Tween(Button, 0.2, {BackgroundColor3 = Theme.Card}) end)
            Button.MouseButton1Click:Connect(function()
                Tween(Button, 0.1, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text})
                task.delay(0.15, function() Tween(Button, 0.25, {BackgroundColor3 = Theme.Card, TextColor3 = Theme.Text}) end)
                callback()
            end)
            table.insert(Window.AllElements, {Name = cfg.Name or "Button", Tab = Tab, TabName = Tab.Name, Type = "Button", Description = description, Callback = callback, UIElement = Button})
            return Button
        end

        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local toggleName = cfg.Name or "Toggle"
            local default = cfg.Default or false
            local callback = cfg.Callback or function() end
            local description = cfg.Description or ""
            
            if MagicTulevo.SavedSettings and MagicTulevo.SavedSettings.Toggles and MagicTulevo.SavedSettings.Toggles[toggleName] ~= nil then
                default = MagicTulevo.SavedSettings.Toggles[toggleName]
            end
            
            local ToggleObj = {Value = default, Name = toggleName}
            local Toggle = Create("Frame", {BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 36), Parent = TabContent})
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Toggle})
            Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = Toggle})
            Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamMedium, Text = toggleName, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Toggle})
            local ToggleBg = Create("Frame", {BackgroundColor3 = default and Theme.Accent or Theme.Background, Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -52, 0.5, -11), Parent = Toggle})
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ToggleBg})
            local ToggleCircle = Create("Frame", {BackgroundColor3 = Theme.Text, Size = UDim2.new(0, 16, 0, 16), Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), Parent = ToggleBg})
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ToggleCircle})
            local function Update()
                if ToggleObj.Value then
                    Tween(ToggleBg, 0.25, {BackgroundColor3 = Theme.Accent})
                    Tween(ToggleCircle, 0.25, {Position = UDim2.new(1, -19, 0.5, -8)}, Enum.EasingStyle.Back)
                else
                    Tween(ToggleBg, 0.25, {BackgroundColor3 = Theme.Background})
                    Tween(ToggleCircle, 0.25, {Position = UDim2.new(0, 3, 0.5, -8)}, Enum.EasingStyle.Back)
                end
                callback(ToggleObj.Value)
            end
            ToggleObj.Update = Update
            local Click = Create("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = Toggle})
            Click.MouseButton1Click:Connect(function() ToggleObj.Value = not ToggleObj.Value Update() end)
            function ToggleObj:Set(v) ToggleObj.Value = v Update() end
            if default then callback(true) end
            table.insert(Window.Toggles, ToggleObj)
            table.insert(Window.AllElements, {Name = toggleName, Tab = Tab, TabName = Tab.Name, Type = "Toggle", Description = description, ToggleObj = ToggleObj, UIElement = Toggle})
            return ToggleObj
        end

        function Tab:CreateSlider(cfg)
            cfg = cfg or {}
            local minVal, maxVal = cfg.Min or 0, cfg.Max or 100
            local default = cfg.Default or minVal
            local callback = cfg.Callback or function() end
            local SliderObj = {Value = default}
            local Slider = Create("Frame", {BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 50), Parent = TabContent})
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Slider})
            Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = Slider})
            Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 20), Position = UDim2.new(0, 12, 0, 6), Font = Enum.Font.GothamMedium, Text = cfg.Name or "Slider", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Slider})
            local SliderValue = Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -58, 0, 6), Font = Enum.Font.GothamBold, Text = tostring(default), TextColor3 = Theme.Accent, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = Slider})
            local SliderBar = Create("Frame", {BackgroundColor3 = Theme.Background, Size = UDim2.new(1, -24, 0, 8), Position = UDim2.new(0, 12, 0, 34), Parent = Slider})
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SliderBar})
            local SliderFill = Create("Frame", {BackgroundColor3 = Theme.Accent, Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0), Parent = SliderBar})
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SliderFill})
            Create("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Theme.AccentDark), ColorSequenceKeypoint.new(1, Theme.Accent)}), Parent = SliderFill})
            local sliding = false
            local function UpdateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local value = math.floor(minVal + (maxVal - minVal) * pos)
                SliderObj.Value = value
                SliderValue.Text = tostring(value)
                Tween(SliderFill, 0.08, {Size = UDim2.new(pos, 0, 1, 0)})
                callback(value)
            end
            SliderBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true UpdateSlider(input) end end)
            SliderBar.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
            UserInputService.InputChanged:Connect(function(input) if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider(input) end end)
            function SliderObj:Set(v) local p = (v - minVal) / (maxVal - minVal) SliderObj.Value = v SliderValue.Text = tostring(v) Tween(SliderFill, 0.2, {Size = UDim2.new(p, 0, 1, 0)}) end
            table.insert(Window.AllElements, {Name = cfg.Name or "Slider", Tab = Tab, TabName = Tab.Name, Type = "Slider", Description = cfg.Description or "", UIElement = Slider})
            return SliderObj
        end

        function Tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local options = cfg.Options or {}
            local default = cfg.Default or (options[1] or "")
            local callback = cfg.Callback or function() end
            local description = cfg.Description or ""
            local DropdownObj = {Value = default, Open = false}
            local Dropdown = Create("Frame", {BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 36), ClipsDescendants = true, Parent = TabContent})
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Dropdown})
            Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = Dropdown})
            Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -90, 0, 36), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamMedium, Text = cfg.Name or "Dropdown", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Dropdown})
            local Selected = Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 70, 0, 36), Position = UDim2.new(1, -90, 0, 0), Font = Enum.Font.Gotham, Text = default, TextColor3 = Theme.TextMuted, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = Dropdown})
            local Arrow = Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 20, 0, 36), Position = UDim2.new(1, -24, 0, 0), Font = Enum.Font.GothamBold, Text = "▼", TextColor3 = Theme.TextMuted, TextSize = 10, Parent = Dropdown})
            local DropList = Create("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 0, 40), Parent = Dropdown})
            Create("UIListLayout", {Padding = UDim.new(0, 4), Parent = DropList})
            for _, opt in ipairs(options) do
                local OptBtn = Create("TextButton", {BackgroundColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.Gotham, Text = opt, TextColor3 = Theme.Text, TextSize = 12, AutoButtonColor = false, Parent = DropList})
                Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = OptBtn})
                OptBtn.MouseEnter:Connect(function() Tween(OptBtn, 0.15, {BackgroundColor3 = Theme.CardHover}) end)
                OptBtn.MouseLeave:Connect(function() Tween(OptBtn, 0.15, {BackgroundColor3 = Theme.Background}) end)
                OptBtn.MouseButton1Click:Connect(function()
                    DropdownObj.Value = opt
                    Selected.Text = opt
                    DropdownObj.Open = false
                    Tween(Dropdown, 0.3, {Size = UDim2.new(1, 0, 0, 36)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                    Tween(Arrow, 0.3, {Rotation = 0})
                    callback(opt)
                end)
            end
            local DropClick = Create("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Text = "", Parent = Dropdown})
            DropClick.MouseButton1Click:Connect(function()
                DropdownObj.Open = not DropdownObj.Open
                if DropdownObj.Open then
                    Tween(Dropdown, 0.35, {Size = UDim2.new(1, 0, 0, 44 + #options * 32)}, Enum.EasingStyle.Back)
                    Tween(Arrow, 0.3, {Rotation = 180})
                else
                    Tween(Dropdown, 0.25, {Size = UDim2.new(1, 0, 0, 36)})
                    Tween(Arrow, 0.25, {Rotation = 0})
                end
            end)
            function DropdownObj:Set(v) DropdownObj.Value = v Selected.Text = v end
            table.insert(Window.AllElements, {Name = cfg.Name or "Dropdown", Tab = Tab, TabName = Tab.Name, Type = "Dropdown", Description = description, UIElement = Dropdown})
            return DropdownObj
        end

        function Tab:CreateKeybind(cfg)
            cfg = cfg or {}
            local default = cfg.Default or Enum.KeyCode.Unknown
            local callback = cfg.Callback or function() end
            local description = cfg.Description or ""
            local KeybindObj = {Value = default, Listening = false}
            local Keybind = Create("Frame", {BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 36), Parent = TabContent})
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Keybind})
            Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = Keybind})
            Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamMedium, Text = cfg.Name or "Keybind", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Keybind})
            local KeyBtn = Create("TextButton", {BackgroundColor3 = Theme.Background, Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -72, 0.5, -12), Font = Enum.Font.GothamBold, Text = default.Name or "None", TextColor3 = Theme.Accent, TextSize = 11, AutoButtonColor = false, Parent = Keybind})
            Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = KeyBtn})
            KeyBtn.MouseButton1Click:Connect(function()
                KeybindObj.Listening = true
                KeyBtn.Text = "..."
                Tween(KeyBtn, 0.2, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text})
            end)
            UserInputService.InputBegan:Connect(function(input, processed)
                if KeybindObj.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    KeybindObj.Value = input.KeyCode
                    KeyBtn.Text = input.KeyCode.Name
                    KeybindObj.Listening = false
                    Tween(KeyBtn, 0.2, {BackgroundColor3 = Theme.Background, TextColor3 = Theme.Accent})
                elseif not processed and input.KeyCode == KeybindObj.Value then
                    callback(KeybindObj.Value)
                end
            end)
            function KeybindObj:Set(k) KeybindObj.Value = k KeyBtn.Text = k.Name end
            table.insert(Window.AllElements, {Name = cfg.Name or "Keybind", Tab = Tab, TabName = Tab.Name, Type = "Keybind", Description = description, UIElement = Keybind})
            return KeybindObj
        end

        function Tab:CreateTextBox(cfg)
            cfg = cfg or {}
            local callback = cfg.Callback or function() end
            local description = cfg.Description or ""
            local TextBoxObj = {Value = ""}
            local TBFrame = Create("Frame", {BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 36), Parent = TabContent})
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = TBFrame})
            Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = TBFrame})
            Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), Font = Enum.Font.GothamMedium, Text = cfg.Name or "TextBox", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TBFrame})
            local TB = Create("TextBox", {BackgroundColor3 = Theme.Background, Size = UDim2.new(0.5, -16, 0, 24), Position = UDim2.new(0.5, 4, 0.5, -12), Font = Enum.Font.Gotham, Text = "", PlaceholderText = cfg.Placeholder or "...", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextMuted, TextSize = 12, ClearTextOnFocus = false, Parent = TBFrame})
            Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TB})
            Create("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = TB})
            TB.FocusLost:Connect(function(enter) TextBoxObj.Value = TB.Text callback(TB.Text, enter) end)
            function TextBoxObj:Set(v) TB.Text = v TextBoxObj.Value = v end
            table.insert(Window.AllElements, {Name = cfg.Name or "TextBox", Tab = Tab, TabName = Tab.Name, Type = "TextBox", Description = description, UIElement = TBFrame})
            return TextBoxObj
        end

        function Tab:CreateTable(cfg)
            cfg = cfg or {}
            local tableName = cfg.Name or "Table"
            local columns = cfg.Columns or {"#", "Item"}
            local data = cfg.Data or {}
            local onRemove = cfg.OnRemove or function() end
            local maxHeight = cfg.MaxHeight or 150
            
            local TableObj = {Data = data, Rows = {}}
            
            -- Main container
            local TableFrame = Create("Frame", {
                BackgroundColor3 = Theme.Card,
                Size = UDim2.new(1, 0, 0, 36),
                ClipsDescendants = true,
                Parent = TabContent
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = TableFrame})
            local TableStroke = Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.7, Parent = TableFrame})
            
            -- Header
            local Header = Create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Parent = TableFrame
            })
            
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -80, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Font = Enum.Font.GothamMedium,
                Text = tableName,
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Header
            })
            
            local CountBadge = Create("Frame", {
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.85,
                Size = UDim2.new(0, 24, 0, 20),
                Position = UDim2.new(1, -70, 0.5, -10),
                Parent = Header
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = CountBadge})
            local CountLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                Text = tostring(#data),
                TextColor3 = Theme.Accent,
                TextSize = 11,
                Parent = CountBadge
            })
            
            local ExpandBtn = Create("TextButton", {
                BackgroundColor3 = Theme.Background,
                Size = UDim2.new(0, 28, 0, 24),
                Position = UDim2.new(1, -40, 0.5, -12),
                Font = Enum.Font.GothamBold,
                Text = "▼",
                TextColor3 = Theme.TextMuted,
                TextSize = 10,
                AutoButtonColor = false,
                Parent = Header
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = ExpandBtn})
            
            -- Table content
            local TableContent = Create("ScrollingFrame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -16, 0, 0),
                Position = UDim2.new(0, 8, 0, 40),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Visible = false,
                Parent = TableFrame
            })
            local ContentLayout = Create("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TableContent
            })
            
            -- Column headers
            local ColumnHeader = Create("Frame", {
                BackgroundColor3 = Theme.Background,
                Size = UDim2.new(1, 0, 0, 24),
                Parent = TableContent
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = ColumnHeader})
            
            local colWidth = 1 / (#columns + 1)
            for i, col in ipairs(columns) do
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(colWidth, 0, 1, 0),
                    Position = UDim2.new(colWidth * (i - 1), 8, 0, 0),
                    Font = Enum.Font.GothamBold,
                    Text = col,
                    TextColor3 = Theme.TextMuted,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ColumnHeader
                })
            end
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(colWidth, 0, 1, 0),
                Position = UDim2.new(1 - colWidth, 0, 0, 0),
                Font = Enum.Font.GothamBold,
                Text = "Action",
                TextColor3 = Theme.TextMuted,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = ColumnHeader
            })
            
            local isExpanded = false
            
            local function UpdateCanvasSize()
                local totalHeight = ContentLayout.AbsoluteContentSize.Y
                TableContent.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
            end
            
            local function CreateRow(index, item)
                local Row = Create("Frame", {
                    BackgroundColor3 = Theme.Background,
                    BackgroundTransparency = 0.5,
                    Size = UDim2.new(1, 0, 0, 28),
                    LayoutOrder = index,
                    Parent = TableContent
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Row})
                
                -- Animate row appearance
                Row.BackgroundTransparency = 1
                Row.Size = UDim2.new(0.9, 0, 0, 0)
                Row.Position = UDim2.new(0.05, 0, 0, 0)
                
                task.delay(index * 0.05, function()
                    Tween(Row, 0.3, {
                        BackgroundTransparency = 0.5,
                        Size = UDim2.new(1, 0, 0, 28),
                        Position = UDim2.new(0, 0, 0, 0)
                    }, Enum.EasingStyle.Back)
                end)
                
                -- Index column
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(colWidth, 0, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    Font = Enum.Font.Gotham,
                    Text = tostring(index),
                    TextColor3 = Theme.TextDark,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row
                })
                
                -- Item column
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(colWidth, 0, 1, 0),
                    Position = UDim2.new(colWidth, 8, 0, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(item),
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = Row
                })
                
                -- Remove button
                local RemoveBtn = Create("TextButton", {
                    BackgroundColor3 = Theme.Error,
                    BackgroundTransparency = 0.85,
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(1, -28, 0.5, -10),
                    Font = Enum.Font.GothamBold,
                    Text = "×",
                    TextColor3 = Theme.Error,
                    TextSize = 14,
                    AutoButtonColor = false,
                    Parent = Row
                })
                Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = RemoveBtn})
                
                RemoveBtn.MouseEnter:Connect(function()
                    Tween(RemoveBtn, 0.15, {BackgroundTransparency = 0, TextColor3 = Theme.Text})
                    Tween(Row, 0.15, {BackgroundColor3 = Theme.Error, BackgroundTransparency = 0.85})
                end)
                RemoveBtn.MouseLeave:Connect(function()
                    Tween(RemoveBtn, 0.15, {BackgroundTransparency = 0.85, TextColor3 = Theme.Error})
                    Tween(Row, 0.15, {BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.5})
                end)
                RemoveBtn.MouseButton1Click:Connect(function()
                    -- Find current index of item in data array
                    local currentIndex = nil
                    for i, v in ipairs(TableObj.Data) do
                        if v == item then
                            currentIndex = i
                            break
                        end
                    end
                    
                    if not currentIndex then return end
                    
                    -- Animate removal
                    Tween(Row, 0.2, {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.9, 0, 0, 0),
                        Position = UDim2.new(0.1, 0, 0, 0)
                    }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                    
                    task.delay(0.2, function()
                        Row:Destroy()
                        onRemove(currentIndex, item)
                        TableObj:Refresh()
                    end)
                end)
                
                return Row
            end
            
            function TableObj:Refresh()
                -- Clear existing rows (except header)
                for _, child in pairs(TableContent:GetChildren()) do
                    if child:IsA("Frame") and child ~= ColumnHeader then
                        child:Destroy()
                    end
                end
                TableObj.Rows = {}
                
                -- Recreate rows
                for i, item in ipairs(TableObj.Data) do
                    local row = CreateRow(i, item)
                    table.insert(TableObj.Rows, row)
                end
                
                CountLabel.Text = tostring(#TableObj.Data)
                
                -- Pulse count badge
                Tween(CountBadge, 0.1, {Size = UDim2.new(0, 30, 0, 24)}, Enum.EasingStyle.Back)
                task.delay(0.1, function()
                    Tween(CountBadge, 0.2, {Size = UDim2.new(0, 24, 0, 20)}, Enum.EasingStyle.Back)
                end)
                
                task.delay(0.1, function()
                    UpdateCanvasSize()
                end)
            end
            
            function TableObj:AddRow(item)
                table.insert(TableObj.Data, item)
                local row = CreateRow(#TableObj.Data, item)
                table.insert(TableObj.Rows, row)
                CountLabel.Text = tostring(#TableObj.Data)
                
                -- Pulse animation
                Tween(CountBadge, 0.1, {Size = UDim2.new(0, 30, 0, 24), BackgroundTransparency = 0.7}, Enum.EasingStyle.Back)
                task.delay(0.1, function()
                    Tween(CountBadge, 0.2, {Size = UDim2.new(0, 24, 0, 20), BackgroundTransparency = 0.85}, Enum.EasingStyle.Back)
                end)
                
                task.delay(0.1, function()
                    UpdateCanvasSize()
                end)
            end
            
            function TableObj:Clear()
                TableObj.Data = {}
                for _, row in pairs(TableObj.Rows) do
                    if row and row.Parent then
                        row:Destroy()
                    end
                end
                TableObj.Rows = {}
                CountLabel.Text = "0"
                UpdateCanvasSize()
            end
            
            -- Expand/collapse
            ExpandBtn.MouseEnter:Connect(function()
                Tween(ExpandBtn, 0.15, {BackgroundColor3 = Theme.CardHover, TextColor3 = Theme.Accent})
            end)
            ExpandBtn.MouseLeave:Connect(function()
                Tween(ExpandBtn, 0.15, {BackgroundColor3 = Theme.Background, TextColor3 = Theme.TextMuted})
            end)
            ExpandBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                
                if isExpanded then
                    TableContent.Visible = true
                    local contentHeight = math.min(maxHeight, 28 + (#TableObj.Data + 1) * 32)
                    Tween(TableFrame, 0.35, {Size = UDim2.new(1, 0, 0, 44 + contentHeight)}, Enum.EasingStyle.Back)
                    Tween(TableContent, 0.3, {Size = UDim2.new(1, -16, 0, contentHeight)})
                    Tween(ExpandBtn, 0.3, {Rotation = 180})
                    Tween(TableStroke, 0.2, {Color = Theme.Accent})
                else
                    Tween(TableFrame, 0.25, {Size = UDim2.new(1, 0, 0, 36)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                    Tween(TableContent, 0.2, {Size = UDim2.new(1, -16, 0, 0)})
                    Tween(ExpandBtn, 0.3, {Rotation = 0})
                    Tween(TableStroke, 0.2, {Color = Theme.Border})
                    task.delay(0.25, function()
                        if not isExpanded then
                            TableContent.Visible = false
                        end
                    end)
                end
            end)
            
            -- Initialize with existing data
            for i, item in ipairs(data) do
                local row = CreateRow(i, item)
                table.insert(TableObj.Rows, row)
            end
            task.delay(0.1, function()
                UpdateCanvasSize()
            end)
            
            return TableObj
        end

        return Tab
    end
    
    -- Add window to global list
    table.insert(MagicTulevo.Windows, Window)
    
    -- ═══════════════════════════════════════════════════════════════
    -- DYNAMIC WINDOW CUSTOMIZATION METHODS
    -- ═══════════════════════════════════════════════════════════════
    
    -- Set window title with animation
    function Window:SetTitle(newTitle)
        if not newTitle or newTitle == "" then return end
        Window.Title = newTitle
        if Window.TitleLabel then
            -- Animate title change
            Tween(Window.TitleLabel, 0.15, {TextTransparency = 1})
            task.delay(0.15, function()
                Window.TitleLabel.Text = newTitle
                Tween(Window.TitleLabel, 0.2, {TextTransparency = 0})
            end)
        end
    end
    
    -- Set window subtitle with animation
    function Window:SetSubTitle(newSubTitle)
        if not newSubTitle then return end
        Window.SubTitle = newSubTitle
        if Window.SubTitleLabel then
            -- Animate subtitle change
            Tween(Window.SubTitleLabel, 0.15, {TextTransparency = 1})
            task.delay(0.15, function()
                Window.SubTitleLabel.Text = newSubTitle
                Tween(Window.SubTitleLabel, 0.2, {TextTransparency = 0})
            end)
        end
    end
    
    -- Set window logo (1-2 letters) with animation
    function Window:SetLogo(newLogo)
        if not newLogo or newLogo == "" then return end
        -- Limit to 2 characters
        newLogo = string.sub(newLogo, 1, 2)
        Window.Logo = newLogo
        if Window.LogoLabel then
            -- Animate logo change with scale effect
            Tween(Window.LogoLabel, 0.15, {TextTransparency = 1, Size = UDim2.new(0.5, 0, 0.5, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            task.delay(0.15, function()
                Window.LogoLabel.Text = newLogo
                -- Adjust text size based on logo length
                Window.LogoLabel.TextSize = #newLogo > 1 and 16 or 20
                Window.LogoLabel.Size = UDim2.new(1, 0, 1, 0)
                Tween(Window.LogoLabel, 0.25, {TextTransparency = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)
        end
    end
    
    -- Set all window info at once
    function Window:SetWindowInfo(info)
        info = info or {}
        if info.Title then Window:SetTitle(info.Title) end
        if info.SubTitle then Window:SetSubTitle(info.SubTitle) end
        if info.Logo then Window:SetLogo(info.Logo) end
    end
    
    -- Get current window info
    function Window:GetWindowInfo()
        return {
            Title = Window.Title,
            SubTitle = Window.SubTitle,
            Logo = Window.Logo
        }
    end
    
    -- Window destroy function
    function Window:Destroy()
        -- Convert CustomThemeColors to saveable format
        local customColorsToSave = {}
        for key, color in pairs(CustomThemeColors) do
            customColorsToSave[key] = {math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)}
        end
        
        -- Save settings before destroying
        local settingsToSave = {
            ThemeIndex = CurrentThemeIndex,
            ToggleKey = toggleKey.Name,
            CustomThemeColors = customColorsToSave
        }
        SaveSettings(settingsToSave)
        
        -- Destroy the GUI
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end
    
    return Window
end

-- Full cleanup function
function MagicTulevo:Destroy()
    -- Save settings
    if #MagicTulevo.Windows > 0 then
        local settingsToSave = {
            ThemeIndex = 1,
            ToggleKey = MagicTulevo.ToggleKey.Name
        }
        SaveSettings(settingsToSave)
    end
    
    -- OPTIMIZED: Stop consolidated animation loop
    StopAnimationLoop()
    
    -- Stop all sounds
    for _, sound in pairs(SoundService:GetChildren()) do
        if sound:IsA("Sound") then
            sound:Stop()
            sound:Destroy()
        end
    end
    
    -- Disconnect all connections
    for _, conn in pairs(MagicTulevo.Connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    MagicTulevo.Connections = {}
    
    -- OPTIMIZED: Clear object pools
    for poolName, pool in pairs(ObjectPool) do
        for _, obj in pairs(pool) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
        ObjectPool[poolName] = {}
    end
    
    -- Clear TweenInfo cache
    CustomTweenCache = {}
    
    -- Destroy all GUIs
    for _, gui in pairs(CoreGui:GetChildren()) do
        if gui.Name:find("MagicTulevo") then
            gui:Destroy()
        end
    end
    
    MagicTulevo.Windows = {}
    print("...")
end

return MagicTulevo
