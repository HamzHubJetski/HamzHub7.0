-- HamzHub v7 | Blox Fruits | Auto Quest/Farm + AUTO FRUIT TELEPORT (MAX 2800, Anti-Detect 2026)
-- Fixed: Fruit detect spesifik, Prompt deep search, Dynamic tween, Touch fallback, Loop 0.5s

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("HamzHub - Blox Fruits", "DarkTheme")

local MainTab = Window:NewTab("Main")
local FarmSection = MainTab:NewSection("Auto Farm & Quest")

local FruitTab = Window:NewTab("Fruits")
local FruitSection = FruitTab:NewSection("Auto Fruit Teleport")

-- Variables
local _G = _G or {}
_G.AutoFarm = false
_G.AutoQuest = false
_G.AutoFruit = false
_G.FarmMethod = "Upper"
_G.Distance = 8
_G.FruitType = "All"  -- "All", "Mythical", "Legendary"
_G.FruitSpeedLimit = 250  -- studs per detik (adjust kalau kena kick)

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local baseTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Linear)

-- Fruit rarity lists (wiki 2026)
local MythicalFruits = {"Dragon", "Kitsune", "Leopard", "Mammoth", "T-Rex", "Venom", "Gas", "Spirit", "Shadow", "Dough", "Control", "Yeti"}
local LegendaryFruits = {"Buddha", "Portal", "Phoenix", "Quake", "Love", "Spider", "Sound", "Pain", "Blizzard", "Lightning"}

-- QuestData (sama seperti v6, expand kalau perlu full list Sea1-3)

local function GetLevel()
    local data = player:FindFirstChild("Data")
    if data then
        local lvl = data:FindFirstChild("Level")
        if lvl then return lvl.Value end
    end
    return 1
end

-- ... (GetQuestInfo, FindQuestNPC, TakeQuest, GetTargetMob dari v6/v5, paste sendiri biar lengkap)

-- IMPROVED FindNearestFruit
local function FindNearestFruit()
    local nearest, minDist = nil, math.huge
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local droppedFolder = workspace:FindFirstChild("Dropped") or workspace  -- fallback kalau ada folder khusus
    
    for _, obj in ipairs(droppedFolder:GetDescendants()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") and obj.Name:lower():find("fruit") then
            local fruitHandle = obj:FindFirstChild("Handle") or obj.PrimaryPart
            if fruitHandle then
                local dist = (hrp.Position - fruitHandle.Position).Magnitude
                if dist < minDist then
                    local nameLow = obj.Name:lower()
                    local match = false
                    if _G.FruitType == "All" then
                        match = true
                    elseif _G.FruitType == "Mythical" then
                        for _, f in ipairs(MythicalFruits) do
                            if nameLow:find(f:lower()) then match = true break end
                        end
                    elseif _G.FruitType == "Legendary" then
                        for _, f in ipairs(LegendaryFruits) do
                            if nameLow:find(f:lower()) then match = true break end
                        end
                    end
                    
                    if match then
                        nearest = fruitHandle
                        minDist = dist
                    end
                end
            end
        end
    end
    return nearest
end

-- Main loop
spawn(function()
    while true do
        task.wait(0.5)  -- lebih aman & stabil
        
        local char = player.Character
        if not char then task.wait(2) continue end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then task.wait(2) continue end
        
        -- Quest & Farm logic (paste dari v6/v5: hasQuest, TakeQuest, AutoFarm tween)
        -- ... (asumsi lu copy bagian itu)
        
        -- Auto Fruit Teleport
        if _G.AutoFruit then
            local fruitTarget = FindNearestFruit()
            if fruitTarget then
                print("[HamzHub] Fruit detected: " .. fruitTarget.Parent.Name .. " | Distance: " .. math.floor((hrp.Position - fruitTarget.Position).Magnitude))
                
                local distance = (hrp.Position - fruitTarget.Position).Magnitude
                local tweenTime = math.clamp(distance / _G.FruitSpeedLimit, 0.5, 5)  -- max 5s biar aman
                local customTweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
                
                local tween = TweenService:Create(hrp, customTweenInfo, {CFrame = fruitTarget.CFrame + Vector3.new(0, 5, 0)})
                tween:Play()
                tween.Completed:Wait()
                
                -- Collect safe
                pcall(function()
                    local prompt = fruitTarget:FindFirstChildOfClass("ProximityPrompt") 
                        or fruitTarget.Parent:FindFirstChildOfClass("ProximityPrompt")
                        or fruitTarget.Parent.Parent:FindFirstChildOfClass("ProximityPrompt")  -- deep search
                    
                    if prompt then
                        fireproximityprompt(prompt)
                    else
                        -- Fallback touch
                        firetouchinterest(hrp, fruitTarget, 0)
                        task.wait(0.1)
                        firetouchinterest(hrp, fruitTarget, 1)
                    end
                    
                    -- Equip kalau tool
                    local tool = fruitTarget.Parent
                    if tool and tool:IsA("Tool") then
                        hum:EquipTool(tool)
                    end
                end)
                
                task.wait(1)  -- cooldown setelah collect
            end
        end
    end
end)

-- UI (sama seperti v6)
FarmSection:NewToggle("Auto Farm", "", function(v) _G.AutoFarm = v end)
FarmSection:NewToggle("Auto Quest", "", function(v) _G.AutoQuest = v if v then TakeQuest() end end)
FarmSection:NewDropdown("Farm Method", "", {"Upper", "Behind"}, function(v) _G.FarmMethod = v end)
FarmSection:NewSlider("Distance", "", 25, 3, function(v) _G.Distance = v end)

FruitSection:NewToggle("Auto Fruit Teleport", "Auto TP & collect fruit", function(v) _G.AutoFruit = v end)
FruitSection:NewDropdown("Fruit Type", "", {"All", "Mythical", "Legendary"}, function(v) _G.FruitType = v end)
FruitSection:NewSlider("TP Speed Limit", "Studs/detik (lebih rendah = lebih aman)", 500, 100, function(v) _G.FruitSpeedLimit = v end)

print("[HamzHub v7] Loaded! Fruit detect akurat, dynamic tween anti-detect, collect fallback. Gas rare fruit bro!")

-- Note: Quest/Farm functions lengkap copy dari v6 lu ya, gw fokus fix fruit part biar gak kepanjangan.
