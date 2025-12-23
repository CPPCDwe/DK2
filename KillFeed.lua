
local KillWebhookURL = "https://discord.com/api/webhooks/1452373471454560455/7W2XuU-YvP2n0hUlX74cb15P8GoFuKlVEP0E5IErsY7P9MMUiejsFx6LMuJsfUgO4RfT"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local KillsModule = {}
KillsModule.Kills = 0
KillsModule.TotalDamage = 0
KillsModule.HitLog = {}
KillsModule.DamageTaken = {}
KillsModule.LocalHooked = false
KillsModule.ProcessedKills = {}

local function SendWebhook(url, data)
    local jsonData = HttpService:JSONEncode(data)
    local requestData = {
        Url = url,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json", ["Accept"] = "application/json"},
        Body = jsonData
    }
    local funcs = {
        function() return request(requestData) end,
        function() return http_request(requestData) end,
        function() return syn and syn.request(requestData) end,
        function() return http and http.request(requestData) end,
        function() return fluxus and fluxus.request(requestData) end,
        function() return (getgenv().request or request)(requestData) end
    }
    for _, f in ipairs(funcs) do
        local s, r = pcall(f)
        if s and r then return true end
    end
    return false
end

local function GetCurrentWeapon()
    local char = Player.Character
    if not char then return "Unknown" end
    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Tool") then
            return item.Name
        end
    end
    return "Fists"
end

local function GetPlayerWeapon(player)
    if not player or not player.Character then return "Unknown" end
    for _, item in pairs(player.Character:GetChildren()) do
        if item:IsA("Tool") then
            return item.Name
        end
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                return item.Name
            end
        end
    end
    return "Fists"
end

local function GetBodypartFromPosition(character, hitPosition)
    if not character or not hitPosition then return "Body" end
    local parts = {
        {character:FindFirstChild("Head"), "Head"},
        {character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"), "Torso"},
        {character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"), "Left Arm"},
        {character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"), "Right Arm"},
        {character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"), "Left Leg"},
        {character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"), "Right Leg"}
    }
    local closest, closestDist = "Body", math.huge
    for _, data in pairs(parts) do
        if data[1] then
            local dist = (data[1].Position - hitPosition).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = data[2]
            end
        end
    end
    return closest
end

local function FindNearestEnemy(maxDist)
    local myChar = Player.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closestPlayer = nil
    local closestDist = maxDist or 9000
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local theirRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                local dist = (myRoot.Position - theirRoot.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = p
                end
            end
        end
    end
    return closestPlayer
end

local function FormatHitLog(victimName)
    local log = KillsModule.HitLog[victimName]
    if not log or #log == 0 then return "No hits logged" end
    local lines = {}
    local totalDmg = 0
    for i, hit in ipairs(log) do
        totalDmg = totalDmg + hit.damage
        table.insert(lines, string.format("#%d: -%d HP | %s | %s", i, math.floor(hit.damage), hit.bodypart, hit.weapon))
    end
    table.insert(lines, "─────────────")
    table.insert(lines, "Total: -" .. math.floor(totalDmg) .. " HP | " .. #log .. " hits")
    return table.concat(lines, "\n")
end

local function FormatDamageTaken()
    local lines = {}
    local totalDmg = 0
    local hitCount = 0
    for attackerName, hits in pairs(KillsModule.DamageTaken) do
        for _, hit in ipairs(hits) do
            hitCount = hitCount + 1
            totalDmg = totalDmg + hit.damage
            table.insert(lines, string.format("#%d: -%d HP | %s | %s | %s", hitCount, math.floor(hit.damage), hit.bodypart, hit.weapon, attackerName))
        end
    end
    if #lines == 0 then return "No damage logged" end
    table.insert(lines, "─────────────")
    table.insert(lines, "Total: -" .. math.floor(totalDmg) .. " HP | " .. hitCount .. " hits")
    return table.concat(lines, "\n")
end

local function SendDeathWebhook(deathData)
    local embed = {
        title = "Death Notification",
        color = 0x808080,
        fields = {
            {name = "Victim", value = "```Name:    " .. tostring(Player.Name) .. "\nDisplay: " .. tostring(Player.DisplayName) .. "```", inline = true},
            {name = "Killer", value = "```Name:    " .. tostring(deathData.KillerName or "Unknown") .. "\nDisplay: " .. tostring(deathData.KillerDisplay or "Unknown") .. "```", inline = true},
            {name = "Death Info", value = "```Weapon:   " .. tostring(deathData.Weapon or "Unknown") .. "\nBodypart: " .. tostring(deathData.Bodypart or "Unknown") .. "```", inline = false},
            {name = "Damage Log", value = "```" .. tostring(deathData.DamageLog or "No data") .. "```", inline = false}
        },
        footer = {text = "Magic Tulevo Deaths | " .. os.date("%d.%m.%Y %H:%M:%S")},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    SendWebhook(KillWebhookURL, {
        username = "Magic Tulevo Deaths",
        avatar_url = "https://i.imgur.com/AfFp7pu.png",
        content = "**" .. tostring(Player.Name) .. "** was killed by **" .. tostring(deathData.KillerName or "Unknown") .. "**",
        embeds = {embed}
    })
end

local function SendKillWebhook(killData)
    local hitLogText = FormatHitLog(killData.VictimName)
    local embed = {
        title = "Kill Notification",
        color = 0xFF4444,
        fields = {
            {name = "Killer", value = "```Name:    " .. tostring(Player.Name) .. "\nDisplay: " .. tostring(Player.DisplayName) .. "```", inline = true},
            {name = "Victim", value = "```Name:    " .. tostring(killData.VictimName or "Unknown") .. "\nDisplay: " .. tostring(killData.VictimDisplay or "Unknown") .. "```", inline = true},
            {name = "Final Hit", value = "```Weapon:   " .. tostring(killData.Weapon or "Unknown") .. "\nDamage:   " .. tostring(killData.Damage or "N/A") .. "\nBodypart: " .. tostring(killData.Bodypart or "Unknown") .. "```", inline = false},
            {name = "Hit Log", value = "```" .. hitLogText .. "```", inline = false},
            {name = "Session Stats", value = "```Total Kills:  " .. tostring(KillsModule.Kills) .. "\nTotal Damage: " .. math.floor(tostring(KillsModule.TotalDamage)) .. "```", inline = false}
        },
        footer = {text = "Magic Tulevo Kills | " .. os.date("%d.%m.%Y %H:%M:%S")},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    SendWebhook(KillWebhookURL, {
        username = "Magic Tulevo Kills",
        avatar_url = "https://i.imgur.com/AfFp7pu.png",
        content = "**" .. tostring(Player.Name) .. "** killed **" .. tostring(killData.VictimName or "Unknown") .. "**",
        embeds = {embed}
    })
end

function KillsModule.LogHit(victimName, damage, bodypart, weapon)
    if not KillsModule.HitLog[victimName] then
        KillsModule.HitLog[victimName] = {}
    end
    table.insert(KillsModule.HitLog[victimName], {
        damage = tonumber(damage) or 0,
        bodypart = bodypart or "Body",
        weapon = weapon or GetCurrentWeapon(),
        time = tick()
    })
    KillsModule.TotalDamage = KillsModule.TotalDamage + (tonumber(damage) or 0)
end

function KillsModule.LogDamageTaken(attackerName, damage, bodypart, weapon)
    if not KillsModule.DamageTaken[attackerName] then
        KillsModule.DamageTaken[attackerName] = {}
    end
    table.insert(KillsModule.DamageTaken[attackerName], {
        damage = tonumber(damage) or 0,
        bodypart = bodypart or "Body",
        weapon = weapon or "Unknown",
        time = tick()
    })
end

function KillsModule.RegisterDeath()
    local killerName = "Unknown"
    local killerDisplay = "Unknown"
    local lastWeapon = "Unknown"
    local lastBodypart = "Unknown"
    local mostDamage = 0
    local topAttacker = nil
    local damageByPlayer = {}
    
    for attackerName, hits in pairs(KillsModule.DamageTaken) do
        if attackerName ~= "Environment" then
            local totalDmg = 0
            local latestHit = nil
            for _, hit in ipairs(hits) do
                totalDmg = totalDmg + hit.damage
                if not latestHit or hit.time > latestHit.time then
                    latestHit = hit
                end
            end
            damageByPlayer[attackerName] = {total = totalDmg, lastHit = latestHit}
            if totalDmg > mostDamage then
                mostDamage = totalDmg
                topAttacker = attackerName
            end
        end
    end
    
    if topAttacker then
        killerName = topAttacker
        local data = damageByPlayer[topAttacker]
        if data and data.lastHit then
            lastWeapon = data.lastHit.weapon
            lastBodypart = data.lastHit.bodypart
        end
        local killerPlayer = Players:FindFirstChild(killerName)
        if killerPlayer then
            killerDisplay = killerPlayer.DisplayName
            if lastWeapon == "Unknown" then
                lastWeapon = GetPlayerWeapon(killerPlayer)
            end
        end
    else
        local attacker = FindNearestEnemy(9000)
        if attacker then
            killerName = attacker.Name
            killerDisplay = attacker.DisplayName
            lastWeapon = GetPlayerWeapon(attacker)
        end
    end
    
    SendDeathWebhook({
        KillerName = killerName,
        KillerDisplay = killerDisplay,
        Weapon = lastWeapon,
        Bodypart = lastBodypart,
        DamageLog = FormatDamageTaken()
    })
    KillsModule.DamageTaken = {}
end

function KillsModule.RegisterKill(victimName, victimDisplay, weapon, damage, bodypart)
    local killKey = victimName .. "_" .. tostring(math.floor(tick()))
    if KillsModule.ProcessedKills[killKey] then
        return
    end
    KillsModule.ProcessedKills[killKey] = true
    
    delay(5, function()
        KillsModule.ProcessedKills[killKey] = nil
    end)
    
    KillsModule.Kills = KillsModule.Kills + 1
    local log = KillsModule.HitLog[victimName]
    if log and #log > 0 then
        local lastHit = log[#log]
        weapon = weapon or lastHit.weapon
        bodypart = bodypart or lastHit.bodypart
        local totalDmg = 0
        for _, hit in ipairs(log) do
            totalDmg = totalDmg + hit.damage
        end
        damage = math.floor(totalDmg)
    end
    
    SendKillWebhook({
        VictimName = victimName,
        VictimDisplay = victimDisplay,
        Weapon = weapon or GetCurrentWeapon(),
        Damage = damage or "N/A",
        Bodypart = bodypart or "Unknown"
    })
    KillsModule.HitLog[victimName] = nil
end

local function HookPlayer(targetPlayer)
    if targetPlayer == Player then return end
    
    local function onCharacter(character)
        if not character then return end
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end
        
        local lastHealth = humanoid.Health
        
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            local newHealth = humanoid.Health
            local damage = lastHealth - newHealth
            if damage > 0 then
                local myChar = Player.Character
                if myChar then
                    local myHumanoid = myChar:FindFirstChild("Humanoid")
                    if myHumanoid and myHumanoid.Health > 0 then
                        local bodypart = GetBodypartFromPosition(character, character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position or nil)
                        KillsModule.LogHit(targetPlayer.Name, damage, bodypart, GetCurrentWeapon())
                    end
                end
            end
            lastHealth = newHealth
        end)
        
        humanoid.Died:Connect(function()
            local log = KillsModule.HitLog[targetPlayer.Name]
            if log and #log > 0 then
                local lastHit = log[#log]
                local timeSinceLastHit = tick() - lastHit.time
                
                if timeSinceLastHit < 1.5 then
                    coroutine.wrap(function()
                        KillsModule.RegisterKill(targetPlayer.Name, targetPlayer.DisplayName, nil, nil, nil)
                    end)()
                end
            end
            KillsModule.HitLog[targetPlayer.Name] = nil
        end)
    end
    
    targetPlayer.CharacterAdded:Connect(onCharacter)
    if targetPlayer.Character then
        coroutine.wrap(onCharacter)(targetPlayer.Character)
    end
end

local function HookLocalPlayer()
    if KillsModule.LocalHooked then return end
    KillsModule.LocalHooked = true
    
    local function onMyCharacter(character)
        if not character then return end
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end
        
        local lastHealth = humanoid.Health
        
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            local newHealth = humanoid.Health
            local damage = lastHealth - newHealth
            if damage > 0 then
                local attacker = FindNearestEnemy(9000)
                if attacker then
                    local weapon = GetPlayerWeapon(attacker)
                    local myRoot = character:FindFirstChild("HumanoidRootPart")
                    local bodypart = "Body"
                    if myRoot then
                        bodypart = GetBodypartFromPosition(character, myRoot.Position)
                    end
                    KillsModule.LogDamageTaken(attacker.Name, damage, bodypart, weapon)
                else
                    KillsModule.LogDamageTaken("Environment", damage, "Body", "Unknown")
                end
            end
            lastHealth = newHealth
        end)
        
        humanoid.Died:Connect(function()
            coroutine.wrap(function()
                KillsModule.RegisterDeath()
            end)()
        end)
    end
    
    Player.CharacterAdded:Connect(onMyCharacter)
    if Player.Character then
        coroutine.wrap(onMyCharacter)(Player.Character)
    end
end

function KillsModule.StartTracking()
    for _, p in pairs(Players:GetPlayers()) do
        HookPlayer(p)
    end
    Players.PlayerAdded:Connect(HookPlayer)
    HookLocalPlayer()
end

KillsModule.StartTracking()

return KillsModule
