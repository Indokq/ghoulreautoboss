local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local healthThreshold = 0.37

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHRP()
    local character = getCharacter()
    return character:WaitForChild("HumanoidRootPart", 5)
end

local function getBoss()
    for _, model in pairs(Workspace.Entities:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("FirstName") == "Eto" then
            return model
        end
    end
    return nil
end

local function hasForceField()
    local entity = Workspace.Entities:FindFirstChild(player.Name)
    return entity and entity:FindFirstChild("ForceField") ~= nil
end

local function sendToVoid()
    local boss = getBoss()
    if not boss or not boss:FindFirstChild("HumanoidRootPart") then
        return
    end

    while not hasForceField() do
        local character = getCharacter()
        local hrp = getHRP()
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if hrp and humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

            for i = 1, 10 do
                hrp.CFrame = hrp.CFrame * CFrame.new(0, -60, 0)
                task.wait(0.3)
            end

            hrp.CFrame = CFrame.new(hrp.Position.X, -940, hrp.Position.Z)
        end

        repeat task.wait() until not character or not character.Parent
        repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        task.wait(0.5)
    end
end

local function autoEquipWeapon()
    local args = {
        [1] = {
            [1] = { ["Module"] = "Toggle", ["IsHolding"] = true },
            [2] = "\5"
        }
    }
    ReplicatedStorage:WaitForChild("Bridgenet2Main"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
end

local function autoM1()
    autoEquipWeapon()
    
    while hasForceField() do
        local args = {
            [1] = {
                [1] = { ["Module"] = "M1" },
                [2] = "\5"
            }
        }

        ReplicatedStorage:WaitForChild("Bridgenet2Main"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
        task.wait(0.2)
    end
end

local function tweenToBoss()
    while true do
        if not hasForceField() then 
            task.wait(0.5)
            continue
        end
        
        local boss = getBoss()
        if not boss or not boss:FindFirstChild("HumanoidRootPart") then 
            task.wait(1)
            continue
        end
        
        local hrp = getHRP()
        local bossPosition = boss.HumanoidRootPart.Position
        local distance = (hrp.Position - bossPosition).Magnitude
        local tweenTime = math.clamp(distance / 50, 1, 4)
        
        local goal = { CFrame = CFrame.new(bossPosition) }
        local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, goal)

        tween:Play()

        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not hasForceField() then
                tween:Cancel()
                break
            end
            task.wait(0.1)
        end

        task.wait(1)
    end
end

local function autoReplay()
    task.wait(6)

    local replayButton = player:WaitForChild("PlayerGui")
        :WaitForChild("Vote")
        :WaitForChild("Frame")
        :WaitForChild("CosmeticInterface")
        :WaitForChild("Replay")

    if replayButton then
        GuiService.SelectedObject = replayButton
        task.wait(0.5)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end
end

local function killNPC(npc)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health / humanoid.MaxHealth <= healthThreshold then
        humanoid.Health = 0
    end
end

RunService.Heartbeat:Connect(function()
    for _, npc in pairs(Workspace.Entities:GetChildren()) do
        if npc:IsA("Model") then
            killNPC(npc)
        end
    end
end)

task.spawn(tweenToBoss)

while true do
    sendToVoid()
    task.spawn(autoM1)

    repeat task.wait() until not hasForceField()

    local boss = getBoss()
    if not boss or not boss:FindFirstChild("Humanoid") or boss.Humanoid.Health <= 0 then
        autoReplay()
        task.wait(5)
    end
end
