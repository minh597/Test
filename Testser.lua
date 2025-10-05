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

local function getCash()
    local rawText = cashLabel.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "")
    return tonumber(cleaned) or 0
end

local function waitForCash(minAmount)
    while getCash() < minAmount do
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

function sellAllTowers()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        local args = { "Troops", "Se\108\108", { Troop = tower } }
        pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
        task.wait(0.2)
    end
end

local function autoSkip()
    task.spawn(function()
        while true do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)
end

local function autoUpgradeSequence()
    task.spawn(function()
        while getgenv().Config["Auto Upgrade Loop"] do
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

local function monitorWave()
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            label:GetPropertyChangedSignal("Text"):Connect(function()
                local waveNum = tonumber(label.Text:match("^(%d+)"))
                if waveNum and getgenv().Config['Auto Sell']['Enabled'] and waveNum == getgenv().Config['Auto Sell']['At Wave'] then
                    sellAllTowers()
                end
            end)
        end
    end
end

local function monitorGameOver()
    gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
        if gameOverGui.Visible then
            task.wait(5)
            if getgenv().Config['Auto Replay'] then
                local replayButton = gameOverGui.Parent:FindFirstChild("replay")
                if replayButton and replayButton.Visible then
                    firesignal(replayButton.MouseButton1Click)
                end
            end
        end
    end)
end

function startFarm()
    autoSkip()
    if getgenv().Config["Auto Upgrade Loop"] then
        autoUpgradeSequence()
    end
    monitorWave()
    monitorGameOver()
    if getgenv().FarmScript then
        getgenv().FarmScript()
    end
end

startFarm()
