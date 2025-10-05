-- 📦 Dịch vusi
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

-- 💰 Cash GUI
local cashLabel = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

-- 🌊 Wave GUI
local waveContainer = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

-- 🎮 GameOver GUI
local gameOverGui = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

---------------------------------------------------------------------
-- 🔧 Support functions
---------------------------------------------------------------------
local function getCash()
    local rawText = cashLabel.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "")
    return tonumber(cleaned) or 0
end

local function waitForCash(minAmount)
    while getCash() < minAmount do task.wait(1) end
end

local function safeInvoke(args, cost)
    waitForCash(cost)
    pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
    task.wait(0.5)
end

function place(pos, name, cost)
    local args = {"Troops", "Place", {Rotation = CFrame.new(), Position = pos}, name}
    safeInvoke(args, cost)
end

function upgrade(num, cost)
    local tower = towerFolder:GetChildren()[num]
    if tower then
        local args = {"Troops", "Upgrade", "Set", {Troop = tower}}
        safeInvoke(args, cost)
    end
end

function sellAll()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        local args = {"Troops", "Sell", {Troop = tower}}
        pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
        task.wait(0.1)
    end
end

---------------------------------------------------------------------
-- 🚀 MAIN AUTO FARM (AutoSkip + Place + Upgrade + Sell)
---------------------------------------------------------------------
function startFarm()
    task.spawn(function()
        while true do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)

    if getgenv().FarmScript then
        getgenv().FarmScript()
    end

    if getgenv().Config['Auto Sell'].Enabled then
        for _, label in ipairs(waveContainer:GetDescendants()) do
            if label:IsA("TextLabel") then
                label:GetPropertyChangedSignal("Text"):Connect(function()
                    local waveNum = tonumber(label.Text:match("^(%d+)"))
                    if waveNum and waveNum >= getgenv().Config['Auto Sell']['At Wave'] then
                        sellAll()
                    end
                end)
            end
        end
    end
end

---------------------------------------------------------------------
-- 🎮 Khi gameOver: replay + farm lại + sell hết
---------------------------------------------------------------------
gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(3)
        if getgenv().Config['Auto Replay'] then
            startFarm()
            task.wait(5)
            sellAll()
        end
    end
end)

---------------------------------------------------------------------
-- ▶️ Bắt đầu
---------------------------------------------------------------------
startFarm()
