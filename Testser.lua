local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

local cashLabel = player:WaitForChild("PlayerGui"):WaitForChild("ReactUniversalHotbar"):WaitForChild("Frame"):WaitForChild("values"):WaitForChild("cash"):WaitForChild("amount")
local waveContainer = player:WaitForChild("PlayerGui"):WaitForChild("ReactGameTopGameDisplay"):WaitForChild("Frame"):WaitForChild("wave"):WaitForChild("container")
local gameOverGui = player:WaitForChild("PlayerGui"):WaitForChild("ReactGameNewRewards"):WaitForChild("Frame"):WaitForChild("gameOver")

local function getCash()
    local raw = cashLabel.Text or ""
    return tonumber(raw:gsub("[^%d%-]", "")) or 0
end

local function waitForCash(v)
    while getCash() < v do task.wait(1) end
end

local function safeInvoke(args, cost)
    waitForCash(cost)
    pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
    task.wait(0.5)
end

function place(pos, name, cost)
    if name == "none" or cost == 0 then return end
    safeInvoke({ "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = pos }, name }, cost)
end

function upgrade(num, cost)
    if getgenv().Config["Auto Upgrade Loop"] or cost == 0 then return end
    local t = towerFolder:GetChildren()[num]
    if t then safeInvoke({ "Troops", "Upgrade", "Set", { Troop = t } }, cost) end
end

function sellAllTowers()
    for _, t in ipairs(towerFolder:GetChildren()) do
        pcall(function() remoteFunction:InvokeServer("Troops", "Se\108\108", { Troop = t }) end)
        task.wait(0.2)
    end
end

local function autoUpgradeLoop()
    task.spawn(function()
        while getgenv().Config["Auto Upgrade Loop"] do
            local towers = towerFolder:GetChildren()
            for _, t in ipairs(towers) do
                if t and t.Parent then
                    pcall(function() remoteFunction:InvokeServer("Troops", "Upgrade", "Set", { Troop = t }) end)
                    task.wait(1)
                end
            end
            task.wait(3)
        end
    end)
end

local function monitorWave()
    for _, lbl in ipairs(waveContainer:GetDescendants()) do
        if lbl:IsA("TextLabel") then
            lbl:GetPropertyChangedSignal("Text"):Connect(function()
                local n = tonumber(lbl.Text:match("^(%d+)"))
                if n and getgenv().Config['Auto Sell']['Enabled'] and n == getgenv().Config['Auto Sell']['At Wave'] then
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
                startFarm()
            end
        end
    end)
end

function startFarm()
    task.spawn(function()
        while true do
            pcall(function() remoteFunction:InvokeServer("Voting", "Skip") end)
            task.wait(1)
        end
    end)

    if getgenv().Config["Auto Upgrade Loop"] then autoUpgradeLoop() end
    monitorWave()
    monitorGameOver()

    if getgenv().FarmScript then getgenv().FarmScript() end

    print("Farm cycle completed.")
end

startFarm()    gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
        if gameOverGui.Visible then
            task.wait(5)
            if getgenv().Config['Auto Replay'] then
                startFarm()
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

    task.wait(3)
    print("Farm cycle completed. Waiting for replay or restart...")
end

startFarm()
