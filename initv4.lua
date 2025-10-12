-- 🌙 CONFIG
local LunarisX = getgenv().LunarisX or {}
local map = LunarisX.map or "halloween"
local autoskip = LunarisX.autoskip or true
local SellAllTower = LunarisX.SellAllTower or true
local AtWave = LunarisX.AtWave or 7

-- ⚙️ SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local TeleportService = game:GetService("TeleportService")

-- 🏁 START MAP
if workspace:FindFirstChild("Elevators") then
    remoteFunction:InvokeServer("Multiplayer", "v2:start", {
        count = 1,
        mode = map
    })
else
    remoteFunction:InvokeServer("Voting", "Skip")
end

-- 🧩 PLAYER VARS
local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

local cashLabel = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

local waveContainer = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

local gameOverGui = player
    :WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

-- 💰 CASH
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

-- 🧱 CORE FUNCS
function placeTower(position, name, cost)
    local args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = position }, name }
    waitForCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(1)
end

function upgradeTower(num, cost)
    local tower = towerFolder:GetChildren()[num]
    if tower then
        local args = { "Troops", "Upgrade", "Set", { Troop = tower } }
        waitForCash(cost)
        pcall(function()
            remoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(1)
    end
end

function sellAllTowers()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        local args = { "Troops", "Se\108\108", { Troop = tower } }
        pcall(function()
            remoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(0.2)
    end
end

-- 🔁 AUTO SELL AT WAVE
if SellAllTower then
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            label:GetPropertyChangedSignal("Text"):Connect(function()
                local waveNum = tonumber(label.Text:match("^(%d+)"))
                if waveNum and waveNum == AtWave then
                    sellAllTowers()
                end
            end)
        end
    end
end

-- 🌀 AUTO TELEPORT ON GAME OVER
local function teleportToTDS()
    TeleportService:Teleport(3260590327)
end

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(5)
        teleportToTDS()
    end
end)

-- ⏩ AUTO SKIP WAVE
local function skipwave()
    task.spawn(function()
        while true do
            pcall(function()
                ReplicatedStorage:WaitForChild("RemoteFunction"):InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)
end

if autoskip then
    skipwave()
end
