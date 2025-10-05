-- 📦 Dịch vụ
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local player = game.Players.LocalPlayer
local towerFolder = workspace:WaitForChild("Towers")

-- 💰 GUI cash
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

-- 🎮 GUI gameOver
local gameOverGui = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactGameNewRewards")
    :WaitForChild("Frame")
    :WaitForChild("gameOver")

---------------------------------------------------------------------
-- 🔧 HÀM HỖ TRỢ
---------------------------------------------------------------------
local function getCash()
    local text = cashLabel.Text or ""
    return tonumber(text:gsub("[^%d%-]", "")) or 0
end

local function waitForCash(amount)
    while getCash() < amount do
        task.wait(0.5)
    end
end

local function safeInvoke(args, cost)
    waitForCash(cost)
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(0.25)
end

function place(pos, name, cost)
    local args = { "Troops", "Place", { Rotation = CFrame.new(), Position = pos }, name }
    safeInvoke(args, cost)
end

function upgrade(num, cost)
    local tower = towerFolder:GetChildren()[num]
    if tower then
        local args = { "Troops", "Upgrade", "Set", { Troop = tower } }
        safeInvoke(args, cost)
    end
end

function sellAll()
    for _, tower in ipairs(towerFolder:GetChildren()) do
        local args = { "Troops", "Sell", { Troop = tower } }
        pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
        task.wait(0.2)
    end
end

---------------------------------------------------------------------
-- 🚀 AUTO FARM (Auto Skip nằm trong luôn)
---------------------------------------------------------------------
function startFarm()
    -- Auto skip
    task.spawn(function()
        while true do
            pcall(function()
                remoteFunction:InvokeServer("Voting", "Skip")
            end)
            task.wait(1)
        end
    end)

    -- Gọi farm script người dùng
    if getgenv().FarmScript then
        getgenv().FarmScript()
    else
        warn("⚠️ Không tìm thấy getgenv().FarmScript — hãy chắc chắn config đã load trước!")
    end
end

---------------------------------------------------------------------
-- 🌊 AUTO SELL Ở WAVE CẤU HÌNH
---------------------------------------------------------------------
local autoSell = getgenv().Config and getgenv().Config["Auto Sell"]
if autoSell and autoSell.Enabled then
    for _, label in ipairs(waveContainer:GetDescendants()) do
        if label:IsA("TextLabel") then
            label:GetPropertyChangedSignal("Text"):Connect(function()
                local wave = tonumber(label.Text:match("^(%d+)"))
                if wave and wave == autoSell["At Wave"] then
                    sellAll()
                end
            end)
        end
    end
end

---------------------------------------------------------------------
-- 🎮 GAMEOVER → FARM LẠI + SELL HẾT
---------------------------------------------------------------------
gameOverGui:GetPropertyChangedSignal("Visible"):Connect(function()
    if gameOverGui.Visible then
        task.wait(3)
        startFarm()
        task.wait(2)
        sellAll()
        warn("✅ Farm loop completed (GameOver detected)")
    end
end)

---------------------------------------------------------------------
-- ▶️ BẮT ĐẦU FARM
---------------------------------------------------------------------
if getgenv().Config and getgenv().Config["Auto Farm"] then
    startFarm()
else
    warn("⚠️ getgenv().Config hoặc Auto Farm chưa bật!")
end
