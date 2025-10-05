-- 📦 Dịch vụ Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

-- 💰 Lấy GUI tiền
local cashLabel = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

-- 🌊 Lấy GUI wave
local waveContainer = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameTopGameDisplay")
    :WaitForChild("Frame")
    :WaitForChild("wave")
    :WaitForChild("container")

local waveLabel
for _, v in ipairs(waveContainer:GetDescendants()) do
    if v:IsA("TextLabel") then
        waveLabel = v
        break
    end
end

-- 🎮 GUI game over
local gameOverGui = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

---------------------------------------------------------------------
-- ⚙️ Hỗ trợ cơ bản
---------------------------------------------------------------------
local function getCash()
    local text = cashLabel.Text or ""
    return tonumber(text:gsub("[^%d]", "")) or 0
end

local function waitCash(cost)
    while getCash() < cost do
        task.wait(0.5)
    end
end

local function invoke(args)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
end

---------------------------------------------------------------------
-- 🧱 Hành động cơ bản
---------------------------------------------------------------------
function place(pos, name, cost)
    waitCash(cost)
    invoke({ "Troops", "Place", { Rotation = CFrame.new(), Position = pos }, name })
    task.wait(0.3)
end

function upgrade(index, cost)
    waitCash(cost)
    local tower = towerFolder:GetChildren()[index]
    if tower then
        invoke({ "Troops", "Upgrade", "Set", { Troop = tower } })
        task.wait(0.3)
    end
end

local function sellAll()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        invoke({ "Troops", "Sell", { Troop = tower } })
        task.wait(0.2)
    end
end

---------------------------------------------------------------------
-- 🌊 Auto Sell (giữ như gốc)
---------------------------------------------------------------------
local function autoSell()
    local auto = getgenv().Config['Auto Sell']
    if not (auto and auto.Enabled) then return end
    local waveTarget = tonumber(auto['At Wave'])
    if waveLabel then
        waveLabel:GetPropertyChangedSignal("Text"):Connect(function()
            local currentWave = tonumber(waveLabel.Text:match("(%d+)"))
            if currentWave and currentWave >= waveTarget then
                sellAll()
            end
        end)
    end
end

---------------------------------------------------------------------
-- 🚀 Hàm farm chính (auto skip bên trong)
---------------------------------------------------------------------
function startFarm()
    if not getgenv().Config['Auto Farm'] then return end

    -- 🌀 AutoSkip
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
        end
    end)

    -- 🧱 Thực thi script farm
    if getgenv().FarmScript then
        pcall(getgenv().FarmScript)
    else
        warn("⚠️ Chưa có getgenv().FarmScript được khai báo.")
    end
end

---------------------------------------------------------------------
-- 🔁 Auto Replay (khi gameOver → chạy lại farm)
---------------------------------------------------------------------
local function autoReplay()
    if not getgenv().Config['Auto Replay'] then return end

    gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
        if gameOverGui.Visible then
            task.wait(6)
            warn("🌀 Trận đấu kết thúc → chạy lại farm...")
            startFarm()
        end
    end)
end

---------------------------------------------------------------------
-- ▶️ Bắt đầu
---------------------------------------------------------------------
autoSell()
autoReplay()
startFarm()
