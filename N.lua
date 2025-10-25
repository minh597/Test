local LunarisX = getgenv().LunarisX or {}
local map = LunarisX.map
local Mode = LunarisX.Mode
local Difficulty = LunarisX.Difficulty
local autoskip = LunarisX.autoskip
local SellAllTower = LunarisX.SellAllTower
local AtWave = LunarisX.AtWave
local autoCommander = LunarisX.autoCommander

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

local player = Players.LocalPlayer
local towerFolder = Workspace:WaitForChild("Towers")

local playerGui = player:WaitForChild("PlayerGui")
local hotbar = playerGui:WaitForChild("ReactUniversalHotbar")
local hotbarFrame = hotbar:WaitForChild("Frame")
local hotbarValues = hotbarFrame:WaitForChild("values")
local cash = hotbarValues:WaitForChild("cash")
local cashLabel = cash:WaitForChild("amount")

local gameTopDisplay = playerGui:WaitForChild("ReactGameTopGameDisplay")
local topFrame = gameTopDisplay:WaitForChild("Frame")
local wave = topFrame:WaitForChild("wave")
local waveContainer = wave:WaitForChild("container")

local rewardsGui = playerGui:WaitForChild("ReactGameNewRewards")
local rewardsFrame = rewardsGui:WaitForChild("Frame")
local gameOverGui = rewardsFrame:WaitForChild("gameOver")

if Workspace:FindFirstChild("Elevators") then
    RemoteFunction:InvokeServer("Multiplayer", "v2:start", {difficulty = "Difficulty", mode = "Mode", count = 1})
    task.wait(3)
else
    task.wait(3)
    RemoteFunction:InvokeServer("LobbyVoting", "Override", "map")
    RemoteEvent:FireServer("LobbyVoting", "Vote", "map", Vector3.new(14.947, 9.6, 55.556))
    RemoteEvent:FireServer("LobbyVoting", "Ready")
    task.wait(5)
    RemoteFunction:InvokeServer("Voting", "Skip")
end

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

local function placeTower(position, name, cost)
    local args = {"Troops", "Place", {Rotation = CFrame.new(), Position = position}, name}
    waitForCash(cost)
    pcall(function()
        RemoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(1)
end

local function upgradeTower(num, cost)
    local tower = towerFolder:GetChildren()[num]
    if tower then
        local args = {"Troops", "Upgrade", "Set", {Troop = tower}}
        waitForCash(cost)
        pcall(function()
            RemoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(1)
    end
end

local function sellAllTowers()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        local args = {"Troops", "Sell", {Troop = tower}}
        pcall(function()
            RemoteFunction:InvokeServer(unpack(args))
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

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(5)
        TeleportService:Teleport(3260590327)
    end
end)

local function skipwave()
    task.spawn(function()
        while true do
            pcall(function()
                RemoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)
end

if autoskip == true then
    skipwave()
end

local function autoCTA()
    if VirtualInputManager and VirtualInputManager.SendKeyEvent then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            task.wait(0.04)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    end
end

if autoCommander == true then
    task.spawn(function()
        while task.wait(10) do
            autoCTA()
        end
    end)
end
