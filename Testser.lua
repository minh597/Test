local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
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

local running = false

local function getCash()
    local raw = cashLabel.Text or ""
    local clean = raw:gsub("[^%d%-]", "")
    return tonumber(clean) or 0
end

local function waitCash(amount)
    while getCash() < amount do
        task.wait(1)
    end
end

local function safeInvoke(args, cost)
    waitCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(0.5)
end

function place(pos, name, cost)
    if name == "none" or cost == 0 then
        return
    end
    local args = {
        "Troops",
        "Pl\208\176ce",
        {
            Rotation = CFrame.new(),
            Position = pos
        },
        name
    }
    safeInvoke(args, cost)
end

function upgrade(num, cost)
    if getgenv().Config["Auto Upgrade Loop"] then
        return
    end
    if cost == 0 then
        return
    end
    local tower = towerFolder:GetChildren()[num]
    if tower then
        local args = {
            "Troops",
            "Upgrade",
            "Set",
            { Troop = tower }
        }
        safeInvoke(args, cost)
    end
end

local function sellAll()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        pcall(function()
            remoteFunction:InvokeServer("Troops", "Se\108\108", { Troop = tower })
        end)
        task.wait(0.2)
    end
end

local function autoUpgradeLoop()
    task.spawn(function()
        while running and getgenv().Config["Auto Upgrade Loop"] do
            local towers = towerFolder:GetChildren()
            for i = 1, #towers do
                local t = towers[i]
                if not running then
                    return
                end
                pcall(function()
                    remoteFunction:InvokeServer("Troops", "Upgrade", "Set", { Troop = t })
                end)
                task.wait(1)
            end
            task.wait(3)
        end
    end)
end

local function startFarm()
    if running then
        return
    end
    running = true

    task.spawn(function()
        while running do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)

    if getgenv().Config["Auto Upgrade Loop"] then
        autoUpgradeLoop()
    end

    if getgenv().FarmScript then
        getgenv().FarmScript()
    end

    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            label:GetPropertyChangedSignal("Text"):Connect(function()
                local wave = tonumber(label.Text:match("^(%d+)"))
                if
                    wave
                    and getgenv().Config["Auto Sell"]["Enabled"]
                    and wave == getgenv().Config["Auto Sell"]["At Wave"]
                then
                    sellAll()
                    running = false
                end
            end)
        end
    end
end

gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(1)
        startFarm()
    end
end)

startFarm()
