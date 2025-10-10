local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local Towers = workspace:WaitForChild("Towers")
local player = Players.LocalPlayer
local cfg = getgenv().Config or {}

local cashLabel = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

local function getCash()
    return tonumber((cashLabel.Text or ""):gsub("[^%d%-]", "")) or 0
end

local function waitForCash(c)
    while getCash() < c do task.wait(1) end
end

local function invoke(args)
    pcall(function() RemoteFunction:InvokeServer(unpack(args)) end)
end

function place(pos, name, cost)
    waitForCash(cost)
    invoke({ "Troops", "Place", { Rotation = CFrame.new(), Position = pos }, name })
end

function upgrade(index, cost)
    local tower = Towers:GetChildren()[index]
    if not tower then return end
    waitForCash(cost)
    invoke({ "Troops", "Upgrade", "Set", { Troop = tower } })
end

function sellAll()
    for _, t in ipairs(Towers:GetChildren()) do
        invoke({ "Troops", "Sell", { Troop = t } })
        task.wait(0.2)
    end
end

function sellTower(index, wave)
    local tower = Towers:GetChildren()[index]
    if not tower then return end
    local waveLabel = player:WaitForChild("PlayerGui")
        :WaitForChild("ReactGameTopGameDisplay")
        :WaitForChild("Frame")
        :WaitForChild("wave")
        :WaitForChild("container"):FindFirstChildWhichIsA("TextLabel")

    waveLabel:GetPropertyChangedSignal("Text"):Connect(function()
        local waveNum = tonumber(waveLabel.Text:match("^(%d+)"))
        if waveNum and waveNum == wave then
            invoke({ "Troops", "Sell", { Troop = tower } })
        end
    end)
end

local autoSkipRunning = false

function startAutoSkip()
    if autoSkipRunning then return end
    autoSkipRunning = true
    task.spawn(function()
        while autoSkipRunning do
            pcall(function()
                RemoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)
end

function stopAutoSkip()
    autoSkipRunning = false
end

local function autoStartGame()
    local startCfg = cfg['Auto Start']
    if not startCfg or not startCfg['Enabled'] then return end

    local mode = startCfg['Mode'] or "survival"
    local diff = startCfg['Difficulty'] or "Intermediate"
    local map = startCfg['Map'] or "Crossroads"

    task.spawn(function()
        task.wait(1)
        invoke({
            "Multiplayer",
            "v2:start",
            {
                ["difficulty"] = diff,
                ["mode"] = mode,
            }
        })
        task.wait(1)
        invoke({ "LobbyVoting", "Override", map })
        task.wait(1)
        invoke({ "Voting", "Ready" })
    end)
end

autoStartGame()

local waveContainer = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

for _, label in ipairs(waveContainer:GetDescendants()) do
    if label:IsA("TextLabel") then
        label:GetPropertyChangedSignal("Text"):Connect(function()
            local waveNum = tonumber(label.Text:match("^(%d+)"))
            if not waveNum then return end

            local sellWave = cfg['Sell All'] and cfg['Sell All']['Wave']
            local stopWave = cfg['Auto Skip'] and cfg['Auto Skip']['Stop At Wave']

            if sellWave and tostring(sellWave) ~= "None" and waveNum == sellWave then
                stopAutoSkip()
                sellAll()
            end

            if stopWave and tostring(stopWave) ~= "None" and waveNum == stopWave then
                stopAutoSkip()
            end
        end)
    end
end

if cfg['Auto Skip'] and tostring(cfg['Auto Skip']['Stop At Wave']) ~= "None" then
    startAutoSkip()
end

local gameOverGui = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(5)
        TeleportService:Teleport(3260590327, player)
    end
end)
