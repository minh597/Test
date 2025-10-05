local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

local cashLabel = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

local waveContainer = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

local gameOverGui = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

local running = false

local function getCash()
    local rawText = cashLabel.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "")
    return tonumber(cleaned) or 0
end

local function waitForCash(minAmount)
    while getCash() < minAmount and running do
        task.wait(1)
    end
end

local function safeInvoke(args, cost)
    waitForCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(0.5)
end

function place(pos, name, cost)
    if name == "none" or cost == 0 then return end
    local args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = pos }, name }
    safeInvoke(args, cost)
end

function upgrade(num, cost)
    if getgenv().Config["Auto Upgrade Loop"] then return end
    if cost == 0 then return end
    local tower = towerFolder:GetChildren()[num]
    if tower then
        local args = { "Troops", "Upgrade", "Set", { Troop = tower } }
        safeInvoke(args, cost)
    end
end

local function sellAllTowers()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        local args = { "Troops", "Se\108\108", { Troop = tower } }
        pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
        task.wait(0.2)
    end
end

local function autoUpgradeSequence()
    task.spawn(function()
        while running and getgenv().Config["Auto Upgrade Loop"] do
            local towers = towerFolder:GetChildren()
            for i = 1, #towers do
                local tower = towers[i]
                if tower and tower.Parent then
                    local args = { "Troops", "Upgrade", "Set", { Troop = tower } }
                    pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
                    task.wait(1)
                end
            end
            task.wait(3)
        end
    end)
end

local function getWave()
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            local num = tonumber(label.Text:match("^(%d+)"))
            if num then return num end
        end
    end
    return 0
end

function startFarm()
    if running then return end
    running = true

    if getgenv().FarmScript then
        getgenv().FarmScript()
    end

    task.spawn(function()
        while running do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)

    if getgenv().Config["Auto Upgrade Loop"] then
        autoUpgradeSequence()
    end

    task.spawn(function()
        while running do
            local wave = getWave()
            if getgenv().Config["Auto Sell"]["Enabled"] and wave >= getgenv().Config["Auto Sell"]["At Wave"] then
                sellAllTowers()
                running = false
                print("Auto sell triggered — ending farm cycle.")
                break
            end
            task.wait(2)
        end
    end)

    while running do task.wait(1) end
    print("Farm stopped.")
end

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible and getgenv().Config["Auto Replay"] then
        task.wait(1)
        print("Restarting farm after game over...")
        startFarm()
    end
end)

startFarm()
