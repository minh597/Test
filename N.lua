local LunarisX = getgenv().LunarisX or {}
local map = LunarisX.map
local autoskip = LunarisX.autoskip
local SellAllTower = LunarisX.SellAllTower
local AtWave = LunarisX.AtWave
local autoCommander = LunarisX.autoCommander
local Difficulty = LunarisX.difficulty

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local TeleportService = game:GetService("TeleportService")
local player = game.Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

if workspace:FindFirstChild("Elevators") then
    local args = {
        [1] = "Multiplayer",
        [2] = "v2:start",
        [3] = {
            ["difficulty"] = Difficulty,
            ["mode"] = "survival",
            ["count"] = 1
        }
    }
    remoteFunction:InvokeServer(unpack(args))
    task.wait(3)
else
    game:GetService("ReplicatedStorage").RemoteFunction:InvokeServer(table.unpack({
        [1] = "LobbyVoting",
        [2] = "Override",
        [3] = map,
    }))
    game:GetService("ReplicatedStorage").RemoteEvent:FireServer(table.unpack({
        [1] = "LobbyVoting",
        [2] = "Vote",
        [3] = map,
        [4] = Vector3.new(14.94717025756836, 9.59998607635498, 55.556156158447266),
    }))
    game:GetService("ReplicatedStorage").RemoteEvent:FireServer(table.unpack({
        [1] = "LobbyVoting",
        [2] = "Ready",
    }))
    task.wait(7)
    remoteFunction:InvokeServer("Voting", "Skip")
    task.wait(1)
end

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

if SellAllTower == true then
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

local function teleportToTDS()
    TeleportService:Teleport(3260590327)
end

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(5)
        teleportToTDS()
    end
end)

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

if autoskip == true then
    skipwave()
end

local interval = 10
local vim_ok, vim = pcall(function()
    return game:GetService("VirtualInputManager")
end)

local function autoCTA()
    if vim_ok and vim and vim.SendKeyEvent then
        pcall(function()
            vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.04)
            vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    end
end

if autoCommander == true and waveStart == waveNum then
    task.spawn(function()
        while task.wait(interval) do
            autoCTA()
        end
    end)
end
