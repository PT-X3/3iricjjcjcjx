local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- ฟังก์ชันสร้าง ESP
local function createESP(player)
    if player == localPlayer then return end

    -- ฟังก์ชันสร้าง ESP เมื่อตัวละครถูกเพิ่ม
    local function onCharacterAdded(character)
        -- ตรวจสอบว่า PlayerGui ของ LocalPlayer โหลดแล้ว
        if not localPlayer:FindFirstChild("PlayerGui") then
            localPlayer:WaitForChild("PlayerGui")
        end

        -- สร้าง ScreenGui เก็บ ESP หากยังไม่มี
        local espScreenGui = localPlayer.PlayerGui:FindFirstChild("ESP_ScreenGui")
        if not espScreenGui then
            espScreenGui = Instance.new("ScreenGui")
            espScreenGui.Name = "ESP_ScreenGui"
            espScreenGui.Parent = localPlayer.PlayerGui
            espScreenGui.ResetOnSpawn = false  -- ปิด ResetOnSpawn สำหรับ ScreenGui ทั้งหมด
        end

        local guiName = player.Name .. "BillboardESP"
        -- ลบ ESP เดิมถ้ามี
        local oldESP = espScreenGui:FindFirstChild(guiName)
        if oldESP then oldESP:Destroy() end

        -- ใช้ HumanoidRootPart เป็นจุดอ้างอิง
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoidRootPart then return end

        -- สร้าง BillboardGui
        local esp = Instance.new("BillboardGui")
        esp.Name = guiName
        esp.Adornee = humanoidRootPart
        esp.Size = UDim2.new(4.5, 0, 6.5, 0)  -- ปรับขนาดให้กว้างและยาว
        esp.SizeOffset = Vector2.new(0, -0.5)
        esp.AlwaysOnTop = true
        esp.LightInfluence = 0
        esp.StudsOffset = Vector3.new(0, 2.75, 0)  -- ปรับตำแหน่งให้สูงขึ้นจากจุดกลางตัวละคร
        esp.ResetOnSpawn = false  -- ปิด ResetOnSpawn เพื่อให้ ESP อยู่เมื่อเกิดใหม่
        esp.Parent = espScreenGui  -- เก็บ ESP ไว้ใน ScreenGui

        -- สร้างสี่เหลี่ยมล่องหนตรงกลาง (ไม่แสดงผลแต่ใช้สำหรับจุดอ้างอิง)
        local invisibleSquare = Instance.new("Frame")
        invisibleSquare.BackgroundTransparency = 1
        invisibleSquare.Size = UDim2.new(1, 0, 1, 0)
        invisibleSquare.Position = UDim2.new(0.5, 0, 0.5, 0)
        invisibleSquare.ZIndex = 0
        invisibleSquare.Parent = esp

        -- กรอบรอบตัว - ขนาด 1px
        local borderColor = Color3.fromRGB(0, 255, 255)
        local thickness = 1  -- ปรับความหนาของเส้นเป็น 1px
        local borders = {
            Top = {Size = UDim2.new(1, 0, 0, thickness), Position = UDim2.new(0, 0, 0, 0)},
            Bottom = {Size = UDim2.new(1, 0, 0, thickness), Position = UDim2.new(0, 0, 1, -thickness)},
            Left = {Size = UDim2.new(0, thickness, 1, 0), Position = UDim2.new(0, 0, 0, 0)},
            Right = {Size = UDim2.new(0, thickness, 1, 0), Position = UDim2.new(1, -thickness, 0, 0)},
        }

        for name, data in pairs(borders) do
            local frame = Instance.new("Frame")
            frame.Name = name
            frame.Size = data.Size
            frame.Position = data.Position
            frame.BorderSizePixel = 0
            frame.BackgroundColor3 = borderColor
            frame.ZIndex = 1
            frame.Parent = esp
        end
    end

    -- ถ้ามีตัวละครอยู่แล้ว ให้สร้าง ESP ทันที
    if player.Character then
        onCharacterAdded(player.Character)
    end

    -- เชื่อมต่อฟังก์ชันเมื่อมีการเพิ่ม Character
    player.CharacterAdded:Connect(onCharacterAdded)
end

-- ฟังก์ชันลบ ESP เมื่อผู้เล่นออกจากเกม
local function removeESP(player)
    local guiName = player.Name .. "BillboardESP"
    local espScreenGui = localPlayer.PlayerGui:FindFirstChild("ESP_ScreenGui")
    if espScreenGui then
        local esp = espScreenGui:FindFirstChild(guiName)
        if esp then esp:Destroy() end
    end
end

-- สร้าง ESP สำหรับผู้เล่นที่อยู่ในเกมตอนเริ่มต้น
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        createESP(player)
    end
end

-- เมื่อมีผู้เล่นเข้ามาในเกม ให้สร้าง ESP
Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        createESP(player)
    end
end)

-- เมื่อผู้เล่นออกจากเกม ให้ลบ ESP
Players.PlayerRemoving:Connect(removeESP)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getPlayerGui()
    local gui = localPlayer:FindFirstChild("PlayerGui")
    if not gui then
        gui = localPlayer:WaitForChild("PlayerGui", 5)
    end
    return gui
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_ScreenGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = getPlayerGui()

local function getFeetMidpoint(character)
    local left = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
    local right = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")

    if left and right then
        local center = (left.Position + right.Position) / 2
        center = center - Vector3.new(0, 0.5, 0) -- ลดลงให้ดูเหมือน "ใต้เท้า"
        return center
    end

    return nil
end

local function createLineToPlayer(targetPlayer)
    if targetPlayer == localPlayer then return end

    local line = Instance.new("Frame")
    line.Name = "LineTo_" .. targetPlayer.Name
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Size = UDim2.new(0, 1, 0, 1)
    line.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    line.BorderSizePixel = 0
    line.BackgroundTransparency = 0
    line.ZIndex = 2
    line.Visible = true
    line.Parent = screenGui

    local function updateLine()
        if not targetPlayer.Character then
            line.Visible = false
            return
        end

        local feetPos = getFeetMidpoint(targetPlayer.Character)
        if not feetPos then
            line.Visible = false
            return
        end

        local screenTo, onScreen = camera:WorldToViewportPoint(feetPos)
        if screenTo.Z < 0 then
            line.Visible = false
            return
        end

        local screenCenterX = camera.ViewportSize.X / 2
        local screenBottomY = camera.ViewportSize.Y

        local fromVec = Vector2.new(screenCenterX, screenBottomY)
        local toVec = Vector2.new(screenTo.X, screenTo.Y)

        local center = (fromVec + toVec) / 2
        local distance = (fromVec - toVec).Magnitude
        local angle = math.deg(math.atan2(toVec.Y - fromVec.Y, toVec.X - fromVec.X))

        line.Size = UDim2.new(0, distance, 0, 1)
        line.Position = UDim2.new(0, center.X, 0, center.Y)
        line.Rotation = angle
        line.Visible = true
    end

    RunService.RenderStepped:Connect(updateLine)
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        createLineToPlayer(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    createLineToPlayer(player)
end)
