-- 📦 Dịch vusigmaboy
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

-- 💰 GUI tiền
local cashLabel = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

-- 🌊 GUI wave
local waveContainer = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

-- 🎮 GUI GameOver
local gameOverGui = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

---------------------------------------------------------------------
-- 🔧 Hỗ trợ
---------------------------------------------------------------------
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
    if cost then waitForCash(cost) end
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
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
        pcall(function()
            remoteFunction:InvokeServer(unpack(args))
        end)
        task.wait(0.1)
    end
end

---------------------------------------------------------------------
-- 🚀 AUTO FARM (AutoSkip + Place + Upgrade + AutoSell)
---------------------------------------------------------------------
function startFarm()
    -- 🌊 Auto Skip vòng
    task.spawn(function()
        while true do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)

    -- ⚙️ Thực thi FarmScript người dùng viết
    if getgenv().FarmScript then
        getgenv().FarmScript()
    end

    -- 💰 Auto Sell (nếu bật)
    if getgenv().Config and getgenv().Config['Auto Sell'] and getgenv().Config['Auto Sell'].Enabled then
        local targetWave = getgenv().Config['Auto Sell']['At Wave']
        for _, label in ipairs(waveContainer:GetDescendants()) do
            if label:IsA("TextLabel") then
                label:GetPropertyChangedSignal("Text"):Connect(function()
                    local waveNum = tonumber(label.Text:match("^(%d+)"))
                    if waveNum and waveNum >= targetWave then
                        sellAll()
                    end
                end)
            end
        end
    end
end

---------------------------------------------------------------------
-- 🎮 Khi GameOver: Replay + Farm lại + Sell hết
---------------------------------------------------------------------
gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(3)
        if getgenv().Config and getgenv().Config['Auto Replay'] then
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
