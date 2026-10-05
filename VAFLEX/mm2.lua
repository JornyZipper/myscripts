--// ============================================================
--// VAFLEX HUB v0.3 - Watermark stream update
--// Base: v0.3
--// Visual -> Game ESP / Menu
--// ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// ============================================================
--// CLEAN OLD VAFLEX
--// ============================================================

local oldGui = PlayerGui:FindFirstChild("VAFLEX_HUB")
if oldGui then oldGui:Destroy() end

local oldLoader = PlayerGui:FindFirstChild("VAFLEX_LOADER")
if oldLoader then oldLoader:Destroy() end

local oldSounds = SoundService:FindFirstChild("VAFLEX_SOUNDS")
if oldSounds then oldSounds:Destroy() end

--// ============================================================
--// CONFIG
--// ============================================================

local Config = {
    Version = "0.3",

    RoleESP = true,
    GunESP = true,
    MaxDistance = 2500,

    RoleOptions = {
        ShowUsernames = true,
        ShowDistance = true,
    },

    Watermark = true,
    WatermarkOptions = {
        ShowNickname = true,
        ShowFPS = true,
        ShowPing = true,
        ShowAvatar = false,
    },

    -- Extra bright loader.
    Water = Color3.fromRGB(180, 226, 248),
    WaterBright = Color3.fromRGB(242, 250, 255),
    WaterWhite = Color3.fromRGB(255, 255, 255),

    LoaderTop = Color3.fromRGB(225, 239, 248),
    LoaderMiddle = Color3.fromRGB(184, 220, 241),
    LoaderBottom = Color3.fromRGB(132, 189, 224),

    Panel = Color3.fromRGB(19, 24, 34),
    Panel2 = Color3.fromRGB(32, 39, 52),
    Panel3 = Color3.fromRGB(27, 34, 47),
    Text = Color3.fromRGB(245, 248, 252),
    Muted = Color3.fromRGB(165, 178, 195),
    Border = Color3.fromRGB(55, 67, 88),

    Murderer = Color3.fromRGB(255, 76, 88),
    Sheriff = Color3.fromRGB(77, 158, 236),
    Hero = Color3.fromRGB(255, 210, 78),
    Innocent = Color3.fromRGB(88, 220, 148),
    Unknown = Color3.fromRGB(190, 198, 210),
    Dead = Color3.fromRGB(135, 143, 153),
}

local Running = true
local Connections = {}
local RoleESPObjects = {}
local GunESPObjects = {}
local RemoteRoles = {}
local DeadPlayers = {}
local PlayedPlayers = {}

--// ============================================================
--// HELPERS
--// ============================================================

local function New(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    return object
end

local function Corner(object, radius)
    local corner = New("UICorner", { CornerRadius = UDim.new(0, radius) })
    corner.Parent = object
    return corner
end

local function Stroke(object, color, transparency, thickness)
    local stroke = New("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    })
    stroke.Parent = object
    return stroke
end

local function Tween(object, duration, properties, style, direction)
    if not object or not object.Parent then return nil end
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            style or Enum.EasingStyle.Quart,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )
    tween:Play()
    return tween
end

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

--// ============================================================
--// SOUNDS
--// ============================================================

local SoundsFolder = New("Folder", { Name = "VAFLEX_SOUNDS" })
SoundsFolder.Parent = SoundService

local ImpactSound = New("Sound", {
    Name = "Impact",
    SoundId = "rbxasset://sounds/impact_water.mp3",
    Volume = 0.42,
})
ImpactSound.Parent = SoundsFolder

local RevealSound = New("Sound", {
    Name = "Reveal",
    SoundId = "rbxasset://sounds/electronicpingshort.wav",
    Volume = 0.23,
})
RevealSound.Parent = SoundsFolder

local ClickSound = New("Sound", {
    Name = "Click",
    SoundId = "rbxasset://sounds/clickfast.wav",
    Volume = 0.12,
})
ClickSound.Parent = SoundsFolder

--// ============================================================
--// MAIN GUI
--// ============================================================

local Gui = New("ScreenGui", {
    Name = "VAFLEX_HUB",
    ResetOnSpawn = false,
    DisplayOrder = 2147483647,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
    SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
})
Gui.Parent = PlayerGui

--// ============================================================
--// FULL SCREEN LOADER GUI
--// ============================================================

local LoaderGui = New("ScreenGui", {
    Name = "VAFLEX_LOADER",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 2147483646,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ScreenInsets = Enum.ScreenInsets.None,
    SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
})
LoaderGui.Parent = PlayerGui

local Loading = New("CanvasGroup", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Config.LoaderMiddle,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    GroupTransparency = 0,
    ZIndex = 500,
})
Loading.Parent = LoaderGui

local LoadingGradient = New("UIGradient", {
    Rotation = 35,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.LoaderTop),
        ColorSequenceKeypoint.new(0.48, Config.LoaderMiddle),
        ColorSequenceKeypoint.new(1, Config.LoaderBottom),
    }),
})
LoadingGradient.Parent = Loading

local AnimationContainer = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(350, 350),
    BackgroundTransparency = 1,
    ZIndex = 510,
})
AnimationContainer.Parent = Loading

local AmbientGlow = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(175, 175),
    Size = UDim2.fromOffset(280, 280),
    BackgroundColor3 = Config.WaterWhite,
    BackgroundTransparency = 0.52,
    BorderSizePixel = 0,
    ZIndex = 510,
})
AmbientGlow.Parent = AnimationContainer
Corner(AmbientGlow, 999)

local SphereSize = 126
local Radius = SphereSize / 2

local SphereGlow = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(175, 175),
    Size = UDim2.fromOffset(178, 178),
    BackgroundColor3 = Config.WaterBright,
    BackgroundTransparency = 0.30,
    BorderSizePixel = 0,
    ZIndex = 512,
})
SphereGlow.Parent = AnimationContainer
Corner(SphereGlow, 999)

local Sphere = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(175, 175),
    Size = UDim2.fromOffset(SphereSize, SphereSize),
    BackgroundColor3 = Color3.fromRGB(135, 188, 215),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 515,
})
Sphere.Parent = AnimationContainer
Corner(Sphere, 999)

local SphereStroke = Stroke(Sphere, Config.WaterWhite, 0, 2)

local SphereGradient = New("UIGradient", {
    Rotation = 45,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 242, 253)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(158, 207, 231)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(103, 160, 193)),
    }),
})
SphereGradient.Parent = Sphere

local GlassHighlight = New("Frame", {
    Position = UDim2.fromScale(0.20, 0.105),
    Size = UDim2.fromScale(0.31, 0.075),
    Rotation = -27,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.10,
    BorderSizePixel = 0,
    ZIndex = 550,
})
GlassHighlight.Parent = Sphere
Corner(GlassHighlight, 999)

local StripCount = 96
local StripHeight = SphereSize / StripCount
local StripOverlap = 3.6
local WaterStrips = {}

for index = 1, StripCount do
    local centerY = SphereSize - ((index - 0.5) * StripHeight)
    local relativeY = centerY - Radius
    local halfWidth = math.sqrt(math.max(0, Radius * Radius - relativeY * relativeY))
    local width = halfWidth * 2
    local y = SphereSize - index * StripHeight - 1.5

    local strip = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromOffset(Radius, y),
        Size = UDim2.fromOffset(width + 2, StripHeight + StripOverlap),
        BackgroundColor3 = Config.Water:Lerp(Config.WaterBright, (index / StripCount) * 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 520,
    })
    strip.Parent = Sphere

    table.insert(WaterStrips, {
        Object = strip,
        Width = width,
        Y = y,
    })
end

local WaterSurface = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(Radius, SphereSize),
    Size = UDim2.fromOffset(8, 5),
    BackgroundColor3 = Config.WaterWhite,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 524,
})
WaterSurface.Parent = Sphere
Corner(WaterSurface, 999)

local SphereLogo = New("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, -8, 0, 34),
    BackgroundTransparency = 1,
    Text = "VAFLEX HUB",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextTransparency = 1,
    TextStrokeColor3 = Color3.fromRGB(65, 118, 148),
    TextStrokeTransparency = 0.06,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    ZIndex = 560,
})
SphereLogo.Parent = Sphere

local SphereLogoScale = New("UIScale", { Scale = 0.55 })
SphereLogoScale.Parent = SphereLogo

local DropGroup = New("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(175, -25),
    Size = UDim2.fromOffset(42, 54),
    BackgroundTransparency = 1,
    GroupTransparency = 0,
    ZIndex = 540,
})
DropGroup.Parent = AnimationContainer

local DropTip = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.27),
    Size = UDim2.fromOffset(15, 15),
    Rotation = 45,
    BackgroundColor3 = Config.WaterWhite,
    BorderSizePixel = 0,
    ZIndex = 541,
})
DropTip.Parent = DropGroup
Corner(DropTip, 4)

local DropBody = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.58),
    Size = UDim2.fromOffset(23, 31),
    BackgroundColor3 = Config.WaterBright,
    BorderSizePixel = 0,
    ZIndex = 542,
})
DropBody.Parent = DropGroup
Corner(DropBody, 999)

local DropGradient = New("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.WaterWhite),
        ColorSequenceKeypoint.new(0.45, Config.WaterBright),
        ColorSequenceKeypoint.new(1, Config.Water),
    }),
})
DropGradient.Parent = DropBody

local function CreateParticle(size, color, zIndex)
    local particle = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = color or Config.WaterBright,
        BorderSizePixel = 0,
        ZIndex = zIndex or 535,
    })
    particle.Parent = AnimationContainer
    Corner(particle, 999)
    return particle
end

local function ImpactSplash()
    for i = 1, 12 do
        local particle = CreateParticle(math.random(3, 6), Config.WaterWhite, 539)
        particle.Position = UDim2.fromOffset(175 + math.random(-6, 6), 111)

        local angle = math.rad(math.random(195, 345))
        local distance = math.random(35, 70)

        Tween(particle, math.random(28, 45) / 100, {
            Position = UDim2.fromOffset(
                175 + math.cos(angle) * distance,
                111 + math.sin(angle) * distance
            ),
            Size = UDim2.fromOffset(1, 1),
            BackgroundTransparency = 1,
        })

        task.delay(0.5, function()
            if particle.Parent then particle:Destroy() end
        end)
    end
end

local function FillSphere()
    WaterSurface.BackgroundTransparency = 0
    local duration = 1.05
    local delayPerStrip = duration / StripCount

    for index, data in ipairs(WaterStrips) do
        if not Running then return end

        local strip = data.Object
        strip.Size = UDim2.fromOffset(data.Width * 0.68, StripHeight + StripOverlap)

        Tween(strip, 0.10, {
            Size = UDim2.fromOffset(data.Width + 3, StripHeight + StripOverlap),
            BackgroundTransparency = 0,
        }, Enum.EasingStyle.Sine)

        WaterSurface.Position = UDim2.fromOffset(Radius, data.Y)
        WaterSurface.Size = UDim2.fromOffset(math.max(10, data.Width + 5), 5)
        WaterSurface.Rotation = index % 2 == 0 and 1.1 or -1.1

        task.wait(delayPerStrip)
    end

    WaterSurface.BackgroundTransparency = 1
end

local function OrbitWater(first, second, duration)
    local started = os.clock()

    while Running and os.clock() - started < duration do
        local progress = (os.clock() - started) / duration
        local angle = progress * math.pi * 2.35
        local radiusX = 84
        local radiusY = 65
        local depth1 = math.sin(angle)
        local depth2 = math.sin(angle + math.pi)

        first.Position = UDim2.fromOffset(
            175 + math.cos(angle) * radiusX,
            175 + math.sin(angle) * radiusY
        )

        second.Position = UDim2.fromOffset(
            175 + math.cos(angle + math.pi) * radiusX,
            175 + math.sin(angle + math.pi) * radiusY
        )

        local size1 = 12 + (depth1 + 1) * 3
        local size2 = 12 + (depth2 + 1) * 3
        first.Size = UDim2.fromOffset(size1, size1)
        second.Size = UDim2.fromOffset(size2, size2)
        first.ZIndex = depth1 > 0 and 542 or 513
        second.ZIndex = depth2 > 0 and 542 or 513

        RunService.RenderStepped:Wait()
    end
end

local function LogoSplash()
    RevealSound:Play()

    local ring = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(175, 175),
        Size = UDim2.fromOffset(45, 45),
        BackgroundTransparency = 1,
        ZIndex = 545,
    })
    ring.Parent = AnimationContainer
    Corner(ring, 999)

    local ringStroke = Stroke(ring, Config.WaterWhite, 0, 2)
    Tween(ring, 0.55, { Size = UDim2.fromOffset(250, 250) })
    Tween(ringStroke, 0.55, { Transparency = 1 })

    for i = 1, 42 do
        local angle = (i / 42) * math.pi * 2 + math.rad(math.random(-7, 7))
        local startRadius = math.random(48, 61)
        local targetRadius = math.random(105, 165)

        local particle = CreateParticle(
            math.random(3, 8),
            i % 5 == 0 and Config.WaterWhite or Config.WaterBright,
            550
        )

        particle.Position = UDim2.fromOffset(
            175 + math.cos(angle) * startRadius,
            175 + math.sin(angle) * startRadius
        )

        if i % 3 == 0 then
            particle.Size = UDim2.fromOffset(math.random(3, 5), math.random(10, 18))
            particle.Rotation = math.deg(angle) + 90
        end

        Tween(particle, math.random(42, 68) / 100, {
            Position = UDim2.fromOffset(
                175 + math.cos(angle) * targetRadius,
                175 + math.sin(angle) * targetRadius
            ),
            Size = UDim2.fromOffset(1, 1),
            BackgroundTransparency = 1,
        })

        task.delay(0.75, function()
            if particle.Parent then particle:Destroy() end
        end)
    end

    Tween(SphereLogo, 0.27, { TextTransparency = 0 })
    Tween(SphereLogoScale, 0.46, { Scale = 1 }, Enum.EasingStyle.Back)

    task.delay(0.6, function()
        if ring.Parent then ring:Destroy() end
    end)
end

local function PopSphere()
    ImpactSound:Play()

    Tween(Sphere, 0.08, { Size = UDim2.fromOffset(116, 116) })
    Tween(SphereGlow, 0.08, { Size = UDim2.fromOffset(150, 150) })
    task.wait(0.07)

    for i = 1, 30 do
        local angle = (i / 30) * math.pi * 2 + math.rad(math.random(-10, 10))
        local particle = CreateParticle(math.random(3, 9), Config.WaterWhite, 570)
        local startRadius = math.random(18, 50)
        local distance = math.random(115, 185)

        particle.Position = UDim2.fromOffset(
            175 + math.cos(angle) * startRadius,
            175 + math.sin(angle) * startRadius
        )

        Tween(particle, math.random(38, 60) / 100, {
            Position = UDim2.fromOffset(
                175 + math.cos(angle) * distance,
                175 + math.sin(angle) * distance
            ),
            Size = UDim2.fromOffset(1, 1),
            BackgroundTransparency = 1,
        })

        task.delay(0.7, function()
            if particle.Parent then particle:Destroy() end
        end)
    end

    Tween(Sphere, 0.16, {
        Size = UDim2.fromOffset(166, 166),
        BackgroundTransparency = 1,
    }, Enum.EasingStyle.Quint)

    Tween(SphereGlow, 0.20, {
        Size = UDim2.fromOffset(240, 240),
        BackgroundTransparency = 1,
    })

    Tween(SphereLogo, 0.16, { TextTransparency = 1 })

    for _, data in ipairs(WaterStrips) do
        Tween(data.Object, 0.16, { BackgroundTransparency = 1 })
    end

    SphereStroke.Transparency = 1
    task.wait(0.12)

    Tween(Loading, 0.42, { GroupTransparency = 1 }, Enum.EasingStyle.Sine)
    task.wait(0.43)
end

local function PlayLoader()
    Sphere.Size = UDim2.fromOffset(78, 78)
    SphereGlow.Size = UDim2.fromOffset(94, 94)

    Tween(Sphere, 0.58, { Size = UDim2.fromOffset(SphereSize, SphereSize) }, Enum.EasingStyle.Back)
    Tween(SphereGlow, 0.72, { Size = UDim2.fromOffset(178, 178) })
    Tween(AmbientGlow, 0.90, { Size = UDim2.fromOffset(330, 330) })

    task.wait(0.38)

    DropGroup.Position = UDim2.fromOffset(175, -25)
    DropGroup.Size = UDim2.fromOffset(42, 54)
    DropGroup.GroupTransparency = 0

    Tween(DropGroup, 0.67, {
        Position = UDim2.fromOffset(175, 108),
        Size = UDim2.fromOffset(35, 64),
    }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

    task.wait(0.63)

    ImpactSound:Play()
    ImpactSplash()

    Tween(DropGroup, 0.07, {
        Size = UDim2.fromOffset(60, 18),
        Position = UDim2.fromOffset(175, 111),
    })

    Tween(Sphere, 0.07, { Size = UDim2.fromOffset(134, 116) })
    Tween(SphereGlow, 0.09, {
        Size = UDim2.fromOffset(185, 154),
        BackgroundTransparency = 0.18,
    })

    task.wait(0.07)

    Tween(Sphere, 0.22, { Size = UDim2.fromOffset(SphereSize, SphereSize) }, Enum.EasingStyle.Back)
    Tween(SphereGlow, 0.24, {
        Size = UDim2.fromOffset(178, 178),
        BackgroundTransparency = 0.30,
    }, Enum.EasingStyle.Back)

    DropGroup.GroupTransparency = 1

    local Left = CreateParticle(17, Config.WaterWhite, 541)
    local Right = CreateParticle(17, Config.WaterWhite, 541)
    Left.Position = UDim2.fromOffset(164, 111)
    Right.Position = UDim2.fromOffset(186, 111)

    Tween(Left, 0.19, {
        Position = UDim2.fromOffset(110, 130),
        Size = UDim2.fromOffset(13, 22),
    })

    Tween(Right, 0.19, {
        Position = UDim2.fromOffset(240, 130),
        Size = UDim2.fromOffset(13, 22),
    })

    task.wait(0.16)
    task.spawn(FillSphere)
    OrbitWater(Left, Right, 1.32)

    Tween(Left, 0.22, {
        Position = UDim2.fromOffset(175, 175),
        Size = UDim2.fromOffset(2, 2),
        BackgroundTransparency = 1,
    })

    Tween(Right, 0.22, {
        Position = UDim2.fromOffset(175, 175),
        Size = UDim2.fromOffset(2, 2),
        BackgroundTransparency = 1,
    })

    task.wait(0.23)
    if Left.Parent then Left:Destroy() end
    if Right.Parent then Right:Destroy() end

    SphereLogo.TextTransparency = 1
    SphereLogoScale.Scale = 0.55
    LogoSplash()

    Tween(SphereGlow, 0.18, {
        Size = UDim2.fromOffset(215, 215),
        BackgroundTransparency = 0.15,
    })

    task.wait(0.18)

    Tween(SphereGlow, 0.50, {
        Size = UDim2.fromOffset(178, 178),
        BackgroundTransparency = 0.30,
    })

    task.wait(0.82)
    PopSphere()
end

--// ============================================================
--// MAIN WINDOW
--// ============================================================

local Main = New("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(430, 320),
    BackgroundColor3 = Config.Panel,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Visible = false,
    Active = true,
    ZIndex = 100,
})
Main.Parent = Gui
Corner(Main, 22)
Stroke(Main, Config.Border, 0, 1)

local MainScale = New("UIScale", { Scale = 1 })
MainScale.Parent = Main
local TargetScale = 1

local TopLine = New("Frame", {
    Position = UDim2.new(0, 25, 0, 0),
    Size = UDim2.new(1, -50, 0, 2),
    BackgroundColor3 = Config.WaterBright,
    BorderSizePixel = 0,
    ZIndex = 105,
})
TopLine.Parent = Main
Corner(TopLine, 999)

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundTransparency = 1,
    ZIndex = 103,
})
Header.Parent = Main

local Logo = New("TextLabel", {
    Position = UDim2.fromOffset(21, 15),
    Size = UDim2.fromOffset(190, 28),
    BackgroundTransparency = 1,
    Text = "VAFLEX HUB",
    TextColor3 = Config.Text,
    TextSize = 19,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 104,
})
Logo.Parent = Header

local CloseButton = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -17, 0.5, 0),
    Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = Config.Panel2,
    BackgroundTransparency = 0.06,
    Text = "×",
    TextColor3 = Config.Text,
    TextSize = 24,
    Font = Enum.Font.Gotham,
    AutoButtonColor = false,
    ZIndex = 105,
})
CloseButton.Parent = Header
Corner(CloseButton, 12)

local Sidebar = New("Frame", {
    Position = UDim2.fromOffset(14, 66),
    Size = UDim2.new(0, 108, 1, -80),
    BackgroundColor3 = Color3.fromRGB(24, 30, 41),
    BackgroundTransparency = 0.10,
    BorderSizePixel = 0,
    ZIndex = 102,
})
Sidebar.Parent = Main
Corner(Sidebar, 15)
Stroke(Sidebar, Config.Border, 0, 1)

local SidebarPadding = New("UIPadding", {
    PaddingTop = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 7),
    PaddingRight = UDim.new(0, 7),
})
SidebarPadding.Parent = Sidebar

local SidebarList = New("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
})
SidebarList.Parent = Sidebar

local Content = New("Frame", {
    Position = UDim2.fromOffset(135, 66),
    Size = UDim2.new(1, -149, 1, -80),
    BackgroundTransparency = 1,
    ZIndex = 102,
})
Content.Parent = Main

local Pages = {}

local function SelectTab(name)
    if not Pages[name] then return end
    ClickSound:Play()

    for pageName, data in pairs(Pages) do
        local selected = pageName == name
        data.Page.Visible = selected
        Tween(data.Button, 0.18, { BackgroundTransparency = selected and 0 or 1 })
        Tween(data.Label, 0.18, { TextColor3 = selected and Config.Text or Config.Muted })
        Tween(data.Icon, 0.18, { TextColor3 = selected and Config.WaterBright or Config.Muted })
    end
end

local function CreateTab(name, icon)
    local Button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Config.Panel2,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 103,
    })
    Button.Parent = Sidebar
    Corner(Button, 11)

    local Icon = New("TextLabel", {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.fromOffset(23, 44),
        BackgroundTransparency = 1,
        Text = icon,
        TextColor3 = Config.Muted,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        ZIndex = 104,
    })
    Icon.Parent = Button

    local Label = New("TextLabel", {
        Position = UDim2.fromOffset(32, 0),
        Size = UDim2.new(1, -34, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Config.Muted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 104,
    })
    Label.Parent = Button

    local Page = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 103,
    })
    Page.Parent = Content

    Pages[name] = {
        Button = Button,
        Label = Label,
        Icon = Icon,
        Page = Page,
    }

    Connect(Button.MouseButton1Click, function()
        SelectTab(name)
    end)

    return Page
end

local VisualPage = CreateTab("Visual", "◉")
local SettingsPage = CreateTab("Settings", "⚙")

local function CreatePageTitle(parent, title, subtitle)
    local Title = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 27),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 104,
    })
    Title.Parent = parent

    local Subtitle = New("TextLabel", {
        Position = UDim2.fromOffset(0, 27),
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = Config.Muted,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 104,
    })
    Subtitle.Parent = parent
end

CreatePageTitle(VisualPage, "Visual", "Visual modules")
CreatePageTitle(SettingsPage, "Settings", "VAFLEX configuration")

local function CreateSwitch(parent, position, default, callback)
    local Switch = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = position,
        Size = UDim2.fromOffset(45, 25),
        BackgroundColor3 = default and Config.Water or Color3.fromRGB(55, 64, 79),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 130,
    })
    Switch.Parent = parent
    Corner(Switch, 999)

    local Dot = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = default
            and UDim2.new(1, -12.5, 0.5, 0)
            or UDim2.new(0, 12.5, 0.5, 0),
        Size = UDim2.fromOffset(19, 19),
        BackgroundColor3 = Color3.fromRGB(248, 251, 255),
        BorderSizePixel = 0,
        ZIndex = 131,
    })
    Dot.Parent = Switch
    Corner(Dot, 999)

    local enabled = default

    Connect(Switch.MouseButton1Click, function()
        ClickSound:Play()
        enabled = not enabled

        Tween(Switch, 0.20, {
            BackgroundColor3 = enabled and Config.Water or Color3.fromRGB(55, 64, 79),
        })

        Tween(Dot, 0.20, {
            Position = enabled
                and UDim2.new(1, -12.5, 0.5, 0)
                or UDim2.new(0, 12.5, 0.5, 0),
        })

        callback(enabled)
    end)

    return Switch
end

--// ============================================================
--// VISUAL ACCORDION STACK
--// ============================================================

local VisualStack = New("Frame", {
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 1, -58),
    BackgroundTransparency = 1,
    ZIndex = 105,
})
VisualStack.Parent = VisualPage

local VisualList = New("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})
VisualList.Parent = VisualStack

local function MakeSection(parent, title, order)
    local Section = New("Frame", {
        Size = UDim2.new(1, 0, 0, 49),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        LayoutOrder = order,
        ZIndex = 106,
    })
    Section.Parent = parent

    local HeaderButton = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 49),
        BackgroundColor3 = Config.Panel2,
        BackgroundTransparency = 0.05,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 107,
    })
    HeaderButton.Parent = Section
    Corner(HeaderButton, 14)
    Stroke(HeaderButton, Config.Border, 0.05, 1)

    local HeaderTitle = New("TextLabel", {
        Position = UDim2.fromOffset(15, 0),
        Size = UDim2.new(1, -58, 1, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Text,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 108,
    })
    HeaderTitle.Parent = HeaderButton

    local Arrow = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        BackgroundTransparency = 1,
        Text = ">",
        TextColor3 = Config.Muted,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        ZIndex = 108,
    })
    Arrow.Parent = HeaderButton

    local Body = New("Frame", {
        Position = UDim2.fromOffset(0, 57),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 106,
    })
    Body.Parent = Section

    return Section, HeaderButton, Arrow, Body
end

local GameSection, GameHeader, GameArrow, GameBody = MakeSection(VisualStack, "Game ESP", 1)
local MenuSection, MenuHeader, MenuArrow, MenuBody = MakeSection(VisualStack, "Menu", 2)

local GameExpanded = false
local MenuExpanded = false

local function SetGameExpanded(value)
    GameExpanded = value
    Tween(GameSection, 0.22, { Size = UDim2.new(1, 0, 0, value and 153 or 49) })
    Tween(GameBody, 0.22, { Size = UDim2.new(1, 0, 0, value and 96 or 0) })
    Tween(GameArrow, 0.22, {
        Rotation = value and 90 or 0,
        TextColor3 = value and Config.WaterBright or Config.Muted,
    })
end

local function SetMenuExpanded(value)
    MenuExpanded = value
    Tween(MenuSection, 0.22, { Size = UDim2.new(1, 0, 0, value and 109 or 49) })
    Tween(MenuBody, 0.22, { Size = UDim2.new(1, 0, 0, value and 52 or 0) })
    Tween(MenuArrow, 0.22, {
        Rotation = value and 90 or 0,
        TextColor3 = value and Config.WaterBright or Config.Muted,
    })
end

Connect(GameHeader.MouseButton1Click, function()
    ClickSound:Play()
    if not GameExpanded and MenuExpanded then SetMenuExpanded(false) end
    SetGameExpanded(not GameExpanded)
end)

Connect(MenuHeader.MouseButton1Click, function()
    ClickSound:Play()
    if not MenuExpanded and GameExpanded then SetGameExpanded(false) end
    SetMenuExpanded(not MenuExpanded)
end)

--// ============================================================
--// GAME ESP ROWS
--// ============================================================

local RoleRow = New("Frame", {
    Position = UDim2.fromOffset(8, 0),
    Size = UDim2.new(1, -16, 0, 44),
    BackgroundColor3 = Config.Panel3,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    ZIndex = 109,
})
RoleRow.Parent = GameBody
Corner(RoleRow, 11)

local RoleTitle = New("TextLabel", {
    Position = UDim2.fromOffset(13, 0),
    Size = UDim2.new(1, -120, 1, 0),
    BackgroundTransparency = 1,
    Text = "Role ESP",
    TextColor3 = Config.Text,
    TextSize = 10,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 110,
})
RoleTitle.Parent = RoleRow

local RoleGear = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -63, 0.5, 0),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Color3.fromRGB(40, 48, 62),
    BackgroundTransparency = 0.05,
    Text = "⚙",
    TextColor3 = Config.Muted,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 113,
})
RoleGear.Parent = RoleRow
Corner(RoleGear, 8)

CreateSwitch(RoleRow, UDim2.new(1, -9, 0.5, 0), Config.RoleESP, function(value)
    Config.RoleESP = value
end)

local GunRow = New("Frame", {
    Position = UDim2.fromOffset(8, 52),
    Size = UDim2.new(1, -16, 0, 44),
    BackgroundColor3 = Config.Panel3,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    ZIndex = 109,
})
GunRow.Parent = GameBody
Corner(GunRow, 11)

local GunTitle = New("TextLabel", {
    Position = UDim2.fromOffset(13, 0),
    Size = UDim2.new(1, -80, 1, 0),
    BackgroundTransparency = 1,
    Text = "Gun ESP",
    TextColor3 = Config.Text,
    TextSize = 10,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 110,
})
GunTitle.Parent = GunRow

CreateSwitch(GunRow, UDim2.new(1, -9, 0.5, 0), Config.GunESP, function(value)
    Config.GunESP = value
end)

--// ============================================================
--// MENU -> WATERMARK ROW
--// ============================================================

local WatermarkRow = New("Frame", {
    Position = UDim2.fromOffset(8, 0),
    Size = UDim2.new(1, -16, 0, 44),
    BackgroundColor3 = Config.Panel3,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    ZIndex = 109,
})
WatermarkRow.Parent = MenuBody
Corner(WatermarkRow, 11)

local WatermarkRowTitle = New("TextLabel", {
    Position = UDim2.fromOffset(13, 0),
    Size = UDim2.new(1, -120, 1, 0),
    BackgroundTransparency = 1,
    Text = "Watermark",
    TextColor3 = Config.Text,
    TextSize = 10,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 110,
})
WatermarkRowTitle.Parent = WatermarkRow

local WatermarkRowSub = New("TextLabel", {
    Position = UDim2.fromOffset(13, 25),
    Size = UDim2.new(1, -120, 0, 16),
    BackgroundTransparency = 1,
    Text = "FPS, ping, nickname and avatar",
    TextColor3 = Config.Muted,
    TextSize = 7,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 110,
})
WatermarkRowSub.Parent = WatermarkRow

local WatermarkGear = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -63, 0.5, 0),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Color3.fromRGB(40, 48, 62),
    BackgroundTransparency = 0.05,
    Text = "⚙",
    TextColor3 = Config.Muted,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
    ZIndex = 113,
})
WatermarkGear.Parent = WatermarkRow
Corner(WatermarkGear, 8)

local SetWatermarkEnabled
CreateSwitch(WatermarkRow, UDim2.new(1, -9, 0.5, 0), Config.Watermark, function(value)
    Config.Watermark = value
    if SetWatermarkEnabled then SetWatermarkEnabled(value) end
end)

--// ============================================================
--// ROLE SETTINGS POPUP
--// ============================================================

local RoleSettingsShade = New("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.48,
    Text = "",
    AutoButtonColor = false,
    Visible = false,
    ZIndex = 300,
})
RoleSettingsShade.Parent = Main

local RoleSettingsPanel = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(260, 170),
    BackgroundColor3 = Color3.fromRGB(24, 30, 42),
    BackgroundTransparency = 0.03,
    BorderSizePixel = 0,
    ZIndex = 310,
})
RoleSettingsPanel.Parent = RoleSettingsShade
Corner(RoleSettingsPanel, 17)
Stroke(RoleSettingsPanel, Config.Border, 0, 1)

local RoleSettingsScale = New("UIScale", { Scale = 1 })
RoleSettingsScale.Parent = RoleSettingsPanel

local SettingsPopupTitle = New("TextLabel", {
    Position = UDim2.fromOffset(16, 13),
    Size = UDim2.new(1, -55, 0, 22),
    BackgroundTransparency = 1,
    Text = "Role ESP Settings",
    TextColor3 = Config.Text,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 311,
})
SettingsPopupTitle.Parent = RoleSettingsPanel

local SettingsPopupSub = New("TextLabel", {
    Position = UDim2.fromOffset(16, 36),
    Size = UDim2.new(1, -32, 0, 16),
    BackgroundTransparency = 1,
    Text = "Choose information shown above players",
    TextColor3 = Config.Muted,
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 311,
})
SettingsPopupSub.Parent = RoleSettingsPanel

local RoleSettingsClose = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -11, 0, 10),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = Config.Panel2,
    Text = "×",
    TextColor3 = Config.Text,
    TextSize = 20,
    Font = Enum.Font.Gotham,
    AutoButtonColor = false,
    ZIndex = 312,
})
RoleSettingsClose.Parent = RoleSettingsPanel
Corner(RoleSettingsClose, 9)

local function CreateOptionRow(parent, y, title, description, default, callback)
    local Row = New("Frame", {
        Position = UDim2.fromOffset(12, y),
        Size = UDim2.new(1, -24, 0, 44),
        BackgroundColor3 = Config.Panel2,
        BackgroundTransparency = 0.07,
        BorderSizePixel = 0,
        ZIndex = 311,
    })
    Row.Parent = parent
    Corner(Row, 11)

    local Title = New("TextLabel", {
        Position = UDim2.fromOffset(12, 6),
        Size = UDim2.new(1, -75, 0, 17),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.Text,
        TextSize = 8,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 312,
    })
    Title.Parent = Row

    local Description = New("TextLabel", {
        Position = UDim2.fromOffset(12, 23),
        Size = UDim2.new(1, -75, 0, 14),
        BackgroundTransparency = 1,
        Text = description,
        TextColor3 = Config.Muted,
        TextSize = 7,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 312,
    })
    Description.Parent = Row

    CreateSwitch(Row, UDim2.new(1, -9, 0.5, 0), default, callback)
end

CreateOptionRow(
    RoleSettingsPanel,
    63,
    "Show Usernames",
    "Display player names",
    Config.RoleOptions.ShowUsernames,
    function(value) Config.RoleOptions.ShowUsernames = value end
)

CreateOptionRow(
    RoleSettingsPanel,
    112,
    "Show Distance",
    "Display distance below names",
    Config.RoleOptions.ShowDistance,
    function(value) Config.RoleOptions.ShowDistance = value end
)

local RoleSettingsOpen = false

local function OpenRoleSettings()
    if RoleSettingsOpen then return end
    RoleSettingsOpen = true
    ClickSound:Play()

    RoleSettingsShade.Visible = true
    RoleSettingsShade.BackgroundTransparency = 1
    RoleSettingsScale.Scale = 0.88

    Tween(RoleSettingsShade, 0.18, { BackgroundTransparency = 0.48 })
    Tween(RoleSettingsScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

local function CloseRoleSettings()
    if not RoleSettingsOpen then return end
    RoleSettingsOpen = false
    ClickSound:Play()

    Tween(RoleSettingsShade, 0.15, { BackgroundTransparency = 1 })
    Tween(RoleSettingsScale, 0.15, { Scale = 0.92 })

    task.delay(0.16, function()
        if not RoleSettingsOpen then RoleSettingsShade.Visible = false end
    end)
end

Connect(RoleGear.MouseButton1Click, OpenRoleSettings)
Connect(RoleSettingsClose.MouseButton1Click, CloseRoleSettings)

--// ============================================================
--// WATERMARK SETTINGS POPUP
--// ============================================================

local WatermarkSettingsShade = New("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.48,
    Text = "",
    AutoButtonColor = false,
    Visible = false,
    ZIndex = 320,
})
WatermarkSettingsShade.Parent = Main

local WatermarkSettingsPanel = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(270, 214),
    BackgroundColor3 = Color3.fromRGB(24, 30, 42),
    BackgroundTransparency = 0.03,
    BorderSizePixel = 0,
    ZIndex = 330,
})
WatermarkSettingsPanel.Parent = WatermarkSettingsShade
Corner(WatermarkSettingsPanel, 17)
Stroke(WatermarkSettingsPanel, Config.Border, 0, 1)

local WatermarkSettingsScale = New("UIScale", { Scale = 1 })
WatermarkSettingsScale.Parent = WatermarkSettingsPanel

local WatermarkSettingsTitle = New("TextLabel", {
    Position = UDim2.fromOffset(16, 13),
    Size = UDim2.new(1, -55, 0, 22),
    BackgroundTransparency = 1,
    Text = "Watermark Settings",
    TextColor3 = Config.Text,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 331,
})
WatermarkSettingsTitle.Parent = WatermarkSettingsPanel

local WatermarkSettingsSub = New("TextLabel", {
    Position = UDim2.fromOffset(16, 36),
    Size = UDim2.new(1, -32, 0, 16),
    BackgroundTransparency = 1,
    Text = "Choose watermark information",
    TextColor3 = Config.Muted,
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 331,
})
WatermarkSettingsSub.Parent = WatermarkSettingsPanel

local WatermarkSettingsClose = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -11, 0, 10),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = Config.Panel2,
    Text = "×",
    TextColor3 = Config.Text,
    TextSize = 20,
    Font = Enum.Font.Gotham,
    AutoButtonColor = false,
    ZIndex = 332,
})
WatermarkSettingsClose.Parent = WatermarkSettingsPanel
Corner(WatermarkSettingsClose, 9)

CreateOptionRow(
    WatermarkSettingsPanel,
    62,
    "Nickname",
    "Show your display name",
    Config.WatermarkOptions.ShowNickname,
    function(value) Config.WatermarkOptions.ShowNickname = value end
)

CreateOptionRow(
    WatermarkSettingsPanel,
    111,
    "FPS",
    "Show current frame rate",
    Config.WatermarkOptions.ShowFPS,
    function(value) Config.WatermarkOptions.ShowFPS = value end
)

CreateOptionRow(
    WatermarkSettingsPanel,
    160,
    "Ping",
    "Show your network ping",
    Config.WatermarkOptions.ShowPing,
    function(value) Config.WatermarkOptions.ShowPing = value end
)

local WatermarkSettingsOpen = false

local function OpenWatermarkSettings()
    if WatermarkSettingsOpen then return end
    WatermarkSettingsOpen = true
    ClickSound:Play()

    WatermarkSettingsShade.Visible = true
    WatermarkSettingsShade.BackgroundTransparency = 1
    WatermarkSettingsScale.Scale = 0.88

    Tween(WatermarkSettingsShade, 0.18, { BackgroundTransparency = 0.48 })
    Tween(WatermarkSettingsScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

local function CloseWatermarkSettings()
    if not WatermarkSettingsOpen then return end
    WatermarkSettingsOpen = false
    ClickSound:Play()

    Tween(WatermarkSettingsShade, 0.15, { BackgroundTransparency = 1 })
    Tween(WatermarkSettingsScale, 0.15, { Scale = 0.92 })

    task.delay(0.16, function()
        if not WatermarkSettingsOpen then WatermarkSettingsShade.Visible = false end
    end)
end

Connect(WatermarkGear.MouseButton1Click, OpenWatermarkSettings)
Connect(WatermarkSettingsClose.MouseButton1Click, CloseWatermarkSettings)

--// ============================================================
--// SETTINGS PAGE
--// ============================================================

local About = New("Frame", {
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 0, 106),
    BackgroundColor3 = Config.Panel2,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    ZIndex = 104,
})
About.Parent = SettingsPage
Corner(About, 15)
Stroke(About, Config.Border, 0, 1)

local AboutTitle = New("TextLabel", {
    Position = UDim2.fromOffset(14, 12),
    Size = UDim2.new(1, -28, 0, 20),
    BackgroundTransparency = 1,
    Text = "About",
    TextColor3 = Config.Text,
    TextSize = 12,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 105,
})
AboutTitle.Parent = About

local function InfoRow(name, value, y)
    local Left = New("TextLabel", {
        Position = UDim2.fromOffset(14, y),
        Size = UDim2.fromOffset(100, 18),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Config.Muted,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 105,
    })
    Left.Parent = About

    local Right = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, y),
        Size = UDim2.fromOffset(120, 18),
        BackgroundTransparency = 1,
        Text = value,
        TextColor3 = Config.Text,
        TextSize = 9,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 105,
    })
    Right.Parent = About
end

InfoRow("Version", Config.Version, 43)
InfoRow("Device", UserInputService.TouchEnabled and "Mobile" or "Desktop", 70)

local CrashButton = New("TextButton", {
    Position = UDim2.fromOffset(0, 176),
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = Color3.fromRGB(48, 16, 22),
    BackgroundTransparency = 0.08,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 104,
})
CrashButton.Parent = SettingsPage
Corner(CrashButton, 15)
Stroke(CrashButton, Color3.fromRGB(182, 55, 71), 0.25, 1)

local CrashTitle = New("TextLabel", {
    Position = UDim2.fromOffset(14, 8),
    Size = UDim2.new(1, -28, 0, 20),
    BackgroundTransparency = 1,
    Text = "Crash VAFLEX",
    TextColor3 = Color3.fromRGB(255, 112, 125),
    TextSize = 10,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 105,
})
CrashTitle.Parent = CrashButton

local CrashDescription = New("TextLabel", {
    Position = UDim2.fromOffset(14, 29),
    Size = UDim2.new(1, -28, 0, 17),
    BackgroundTransparency = 1,
    Text = "Stop and unload VAFLEX HUB",
    TextColor3 = Color3.fromRGB(201, 132, 140),
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 105,
})
CrashDescription.Parent = CrashButton

--// ============================================================
--// WATERMARK
--// ============================================================

local Watermark = New("TextButton", {
    Position = UDim2.fromOffset(12, 12),
    Size = UDim2.fromOffset(332, 48),
    BackgroundColor3 = Color3.fromRGB(28, 36, 49),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false,
    Visible = false,
    Active = true,
    ZIndex = 210,
})
Watermark.Parent = Gui
Corner(Watermark, 14)
local WatermarkStroke = Stroke(Watermark, Config.Border, 0.04, 1)

local WatermarkScale = New("UIScale", { Scale = 1 })
WatermarkScale.Parent = Watermark

local WatermarkGradient = New("UIGradient", {
    Rotation = 0,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 59, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(33, 43, 59)),
    }),
})
WatermarkGradient.Parent = Watermark

local WatermarkPadding = New("UIPadding", {
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
})
WatermarkPadding.Parent = Watermark

local WatermarkLayout = New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
})
WatermarkLayout.Parent = Watermark

local function CreateMarkCard(width, order)
    local card = New("Frame", {
        Size = UDim2.fromOffset(width, 36),
        BackgroundColor3 = Color3.fromRGB(46, 59, 80),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 212,
    })
    card.Parent = Watermark
    Corner(card, 10)
    Stroke(card, Color3.fromRGB(78, 93, 117), 0.20, 1)
    return card
end

local BrandCard = CreateMarkCard(130, 1)

local BrandIconWrap = New("Frame", {
    Position = UDim2.fromOffset(8, 4),
    Size = UDim2.fromOffset(28, 28),
    BackgroundTransparency = 1,
    ZIndex = 214,
})
BrandIconWrap.Parent = BrandCard

local BrandLeft = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(10, 14),
    Size = UDim2.fromOffset(10, 24),
    Rotation = -35,
    BackgroundColor3 = Color3.fromRGB(12, 55, 153),
    BorderSizePixel = 0,
    ZIndex = 215,
})
BrandLeft.Parent = BrandIconWrap
Corner(BrandLeft, 8)
local BrandLeftGradient = New("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 42, 129)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 122, 255)),
    }),
})
BrandLeftGradient.Parent = BrandLeft

local BrandRight = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromOffset(20, 11),
    Size = UDim2.fromOffset(9, 20),
    Rotation = 35,
    BackgroundColor3 = Color3.fromRGB(34, 175, 255),
    BorderSizePixel = 0,
    ZIndex = 215,
})
BrandRight.Parent = BrandIconWrap
Corner(BrandRight, 8)
local BrandRightGradient = New("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 131, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 204, 255)),
    }),
})
BrandRightGradient.Parent = BrandRight

local BrandDivider = New("Frame", {
    Position = UDim2.fromOffset(42, 7),
    Size = UDim2.fromOffset(1, 22),
    BackgroundColor3 = Color3.fromRGB(108, 124, 146),
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
    ZIndex = 214,
})
BrandDivider.Parent = BrandCard

local BrandTitle = New("TextLabel", {
    Position = UDim2.fromOffset(52, 4),
    Size = UDim2.fromOffset(70, 14),
    BackgroundTransparency = 1,
    Text = "VAFLEX",
    TextColor3 = Color3.fromRGB(245, 248, 252),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 214,
})
BrandTitle.Parent = BrandCard

local BrandSub = New("TextLabel", {
    Position = UDim2.fromOffset(52, 17),
    Size = UDim2.fromOffset(70, 11),
    BackgroundTransparency = 1,
    Text = "HUB",
    TextColor3 = Color3.fromRGB(193, 206, 220),
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 214,
})
BrandSub.Parent = BrandCard

local AvatarCard = CreateMarkCard(38, 2)
local AvatarViewport = New("ViewportFrame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Color3.fromRGB(38, 48, 64),
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    Ambient = Color3.fromRGB(180, 190, 205),
    LightColor = Color3.fromRGB(255, 255, 255),
    LightDirection = Vector3.new(-1, -1, -1),
    ZIndex = 214,
})
AvatarViewport.Parent = AvatarCard
Corner(AvatarViewport, 999)
Stroke(AvatarViewport, Color3.fromRGB(78, 93, 117), 0.25, 1)

local AvatarWorld = New("WorldModel", { Name = "AvatarWorld" })
AvatarWorld.Parent = AvatarViewport

local AvatarCamera = New("Camera", { Name = "AvatarCamera" })
AvatarCamera.Parent = AvatarViewport
AvatarViewport.CurrentCamera = AvatarCamera

local function CreateStatCard(width, order, iconText, initialValue)
    local card = CreateMarkCard(width, order)

    local icon = New("TextLabel", {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.fromOffset(24, 36),
        BackgroundTransparency = 1,
        Text = iconText,
        TextColor3 = Color3.fromRGB(229, 236, 244),
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        ZIndex = 214,
    })
    icon.Parent = card

    local divider = New("Frame", {
        Position = UDim2.fromOffset(31, 7),
        Size = UDim2.fromOffset(1, 22),
        BackgroundColor3 = Color3.fromRGB(108, 124, 146),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 214,
    })
    divider.Parent = card

    local value = New("TextLabel", {
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -46, 1, 0),
        BackgroundTransparency = 1,
        Text = initialValue,
        TextColor3 = Config.Text,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 214,
    })
    value.Parent = card

    return card, value
end

local NameCard, NameValue = CreateStatCard(94, 3, "ID", LocalPlayer.DisplayName ~= "" and LocalPlayer.DisplayName or LocalPlayer.Name)
local FPSCard, FPSValueLabel = CreateStatCard(70, 4, "FPS", "60")
local PingCard, PingValueLabel = CreateStatCard(76, 5, "PING", "0 ms")

local WatermarkShimmer = New("Frame", {
    Size = UDim2.fromOffset(34, 56),
    Position = UDim2.fromOffset(-44, -4),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.92,
    Rotation = 10,
    BorderSizePixel = 0,
    ZIndex = 216,
})
WatermarkShimmer.Parent = Watermark
local WatermarkShimmerGradient = New("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.18),
        NumberSequenceKeypoint.new(1, 1),
    }),
})
WatermarkShimmerGradient.Parent = WatermarkShimmer

local WatermarkDragState = { Dragging = false, DragInput = nil, DragStart = nil, StartPosition = nil }

Connect(Watermark.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        WatermarkDragState.Dragging = true
        WatermarkDragState.DragStart = input.Position
        WatermarkDragState.StartPosition = Watermark.Position
    end
end)

Connect(Watermark.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        WatermarkDragState.DragInput = input
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not WatermarkDragState.Dragging or input ~= WatermarkDragState.DragInput then return end
    local delta = input.Position - WatermarkDragState.DragStart
    Watermark.Position = UDim2.new(
        WatermarkDragState.StartPosition.X.Scale,
        WatermarkDragState.StartPosition.X.Offset + delta.X,
        WatermarkDragState.StartPosition.Y.Scale,
        WatermarkDragState.StartPosition.Y.Offset + delta.Y
    )
end)

Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        WatermarkDragState.Dragging = false
    end
end)

local function ClearWatermarkAvatar()
    for _, child in ipairs(AvatarWorld:GetChildren()) do
        child:Destroy()
    end
end

local function BuildWatermarkAvatar()
    ClearWatermarkAvatar()

    local character = LocalPlayer.Character
    if not character then return end

    local oldArchivable = character.Archivable
    character.Archivable = true

    local success, clone = pcall(function()
        return character:Clone()
    end)

    character.Archivable = oldArchivable
    if not success or not clone then return end

    local rotationParts = {}

    for _, item in ipairs(clone:GetDescendants()) do
        if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then
            item:Destroy()
        elseif item:IsA("Humanoid") then
            item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
            table.insert(rotationParts, item)
        end
    end

    clone.Parent = AvatarWorld

    local ok, boxCF, boxSize = pcall(function()
        local cf, size = clone:GetBoundingBox()
        return cf, size
    end)
    if not ok then return end

    local center = boxCF.Position
    local target = center + Vector3.new(0, boxSize.Y * 0.08, 0)
    local cameraPos = target + Vector3.new(0, 0, -math.max(3.8, math.max(boxSize.X, boxSize.Y, boxSize.Z) * 1.30))
    AvatarCamera.CFrame = CFrame.new(cameraPos, target)

    task.spawn(function()
        while Running and clone.Parent == AvatarWorld and AvatarViewport.Parent do
            local pivot = clone:GetPivot()
            clone:PivotTo(pivot * CFrame.Angles(0, math.rad(1.2), 0))
            task.wait()
        end
    end)
end

local FPSValue = 60
local FPSFrames = 0
local FPSTime = 0

Connect(RunService.RenderStepped, function(delta)
    FPSFrames = FPSFrames + 1
    FPSTime = FPSTime + delta

    if FPSTime >= 0.5 then
        FPSValue = math.floor(FPSFrames / FPSTime + 0.5)
        FPSFrames = 0
        FPSTime = 0
    end
end)

local function GetLocalPing()
    local ping = nil
    local success, value = pcall(function()
        return LocalPlayer:GetNetworkPing()
    end)

    if success and type(value) == "number" then
        ping = math.max(0, math.floor(value * 1000 + 0.5))
    end

    return ping
end

local function RefreshWatermarkText()
    local nickname = LocalPlayer.DisplayName
    if not nickname or nickname == "" then nickname = LocalPlayer.Name end

    NameValue.Text = nickname
    FPSValueLabel.Text = tostring(FPSValue)

    local ping = GetLocalPing()
    PingValueLabel.Text = ping and (tostring(ping) .. " ms") or "-- ms"

    AvatarCard.Visible = false
    NameCard.Visible = Config.WatermarkOptions.ShowNickname
    FPSCard.Visible = Config.WatermarkOptions.ShowFPS
    PingCard.Visible = Config.WatermarkOptions.ShowPing

    local visible = {BrandCard}
    if NameCard.Visible then table.insert(visible, NameCard) end
    if FPSCard.Visible then table.insert(visible, FPSCard) end
    if PingCard.Visible then table.insert(visible, PingCard) end

    local width = 18
    for i, gui in ipairs(visible) do
        width = width + gui.Size.X.Offset
        if i < #visible then width = width + 7 end
    end
    width = width + 18

    Watermark.Size = UDim2.fromOffset(width, 48)
end

Connect(RunService.RenderStepped, function()
    if Watermark.Visible then
        local x = WatermarkShimmer.Position.X.Offset + 1
        if x > Watermark.AbsoluteSize.X + 22 then
            x = -44
        end
        WatermarkShimmer.Position = UDim2.fromOffset(x, -4)
    end
end)

--// ============================================================
--// SMOOTH MENU <-> WATERMARK TRANSITION
--// ============================================================

local MenuOpen = true
local TransitionBusy = false

local function ShowWatermarkAnimated()
    if not Config.Watermark or MenuOpen then
        Watermark.Visible = false
        return
    end

    RefreshWatermarkText()
    Watermark.Visible = true
    WatermarkScale.Scale = 0.86
    Watermark.BackgroundTransparency = 1
    WatermarkStroke.Transparency = 1

    Tween(WatermarkScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
    Tween(Watermark, 0.22, { BackgroundTransparency = 0.08 })
    Tween(WatermarkStroke, 0.22, { Transparency = 0.04 })
end

local function HideWatermarkAnimated(callback)
    if not Watermark.Visible then
        if callback then callback() end
        return
    end

    Tween(WatermarkScale, 0.17, { Scale = 0.82 })
    Tween(Watermark, 0.17, { BackgroundTransparency = 1 })
    Tween(WatermarkStroke, 0.17, { Transparency = 1 })

    task.delay(0.18, function()
        Watermark.Visible = false
        if callback then callback() end
    end)
end

local function CloseMenu()
    if not MenuOpen or not Running or TransitionBusy then return end

    if RoleSettingsOpen then CloseRoleSettings() end
    if WatermarkSettingsOpen then CloseWatermarkSettings() end

    TransitionBusy = true
    MenuOpen = false
    ClickSound:Play()

    Tween(MainScale, 0.20, { Scale = TargetScale * 0.82 }, Enum.EasingStyle.Quart)

    task.delay(0.20, function()
        if not Running or MenuOpen then
            TransitionBusy = false
            return
        end

        Main.Visible = false
        ShowWatermarkAnimated()
        TransitionBusy = false
    end)
end

local function OpenMenu()
    if MenuOpen or not Running or TransitionBusy then return end

    TransitionBusy = true
    MenuOpen = true
    ClickSound:Play()

    HideWatermarkAnimated(function()
        if not Running then
            TransitionBusy = false
            return
        end

        Main.Visible = true
        MainScale.Scale = TargetScale * 0.82
        Tween(MainScale, 0.28, { Scale = TargetScale }, Enum.EasingStyle.Back)

        task.delay(0.24, function()
            TransitionBusy = false
        end)
    end)
end

SetWatermarkEnabled = function(value)
    if not value then
        Watermark.Visible = false
    elseif not MenuOpen then
        ShowWatermarkAnimated()
    end
end

Connect(Watermark.MouseButton1Click, OpenMenu)
Connect(CloseButton.MouseButton1Click, CloseMenu)

Connect(UserInputService.InputBegan, function(input, processed)
    if processed or not Running then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        if MenuOpen then CloseMenu() else OpenMenu() end
    end
end)

--// ============================================================
--// DRAGGING
--// ============================================================

local Dragging = false
local DragInput = nil
local DragStart = nil
local StartPosition = nil

Connect(Header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position
    end
end)

Connect(Header.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        DragInput = input
    end
end)

Connect(UserInputService.InputChanged, function(input)
    if not Dragging or input ~= DragInput then return end

    local delta = input.Position - DragStart
    Main.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + delta.Y
    )
end)

Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = false
    end
end)

--// ============================================================
--// MOBILE SCALE
--// ============================================================

local function UpdateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local width = camera.ViewportSize.X

    if width < 470 then
        TargetScale = math.clamp(width / 455, 0.76, 0.94)
    else
        TargetScale = 1
    end

    if MenuOpen and not TransitionBusy then
        MainScale.Scale = TargetScale
    end
end

UpdateScale()

if workspace.CurrentCamera then
    Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), UpdateScale)
end

--// ============================================================
--// ROLE DETECTION
--// ============================================================

local function NormalizeRole(value)
    if value == nil then return nil end

    local valueString = string.lower(tostring(value))

    if valueString == "murderer" or valueString == "murder" or valueString == "killer" then
        return "Murderer"
    end

    if valueString == "sheriff" or valueString == "detective" then
        return "Sheriff"
    end

    if valueString == "hero" then
        return "Hero"
    end

    if valueString == "innocent" or valueString == "innocents" then
        return "Innocent"
    end

    return nil
end

local GetPlayerDataRemote = nil
local RoleRequestBusy = false

local function FindGetPlayerData()
    if GetPlayerDataRemote and GetPlayerDataRemote.Parent then
        return GetPlayerDataRemote
    end

    local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)

    if remote and remote:IsA("RemoteFunction") then
        GetPlayerDataRemote = remote
        return remote
    end

    return nil
end

local function RefreshRemoteRoles()
    if not Running or RoleRequestBusy then return end

    local remote = FindGetPlayerData()
    if not remote then return end

    RoleRequestBusy = true

    local success, result = pcall(function()
        return remote:InvokeServer()
    end)

    RoleRequestBusy = false

    if not success or type(result) ~= "table" then return end

    local updatedRoles = {}

    for playerName, data in pairs(result) do
        if type(data) == "table" then
            local role = NormalizeRole(
                data.Role
                or data.role
                or data.CurrentRole
                or data.RoundRole
            )

            if role then updatedRoles[tostring(playerName)] = role end
        elseif type(data) == "string" then
            local role = NormalizeRole(data)
            if role then updatedRoles[tostring(playerName)] = role end
        end
    end

    RemoteRoles = updatedRoles
end

local RoleAttributeNames = {
    "Role",
    "CurrentRole",
    "AssignedRole",
    "RoundRole",
}

local function ReadRoleAttribute(object)
    if not object then return nil end

    for _, name in ipairs(RoleAttributeNames) do
        local role = NormalizeRole(object:GetAttribute(name))
        if role then return role end
    end

    return nil
end

local function ReadRoleValue(object)
    if not object then return nil end

    for _, name in ipairs(RoleAttributeNames) do
        local valueObject = object:FindFirstChild(name)

        if valueObject then
            local success, value = pcall(function()
                return valueObject.Value
            end)

            if success then
                local role = NormalizeRole(value)
                if role then return role end
            end
        end
    end

    return nil
end

local function HasTool(player, name)
    local backpack = player:FindFirstChild("Backpack")

    if backpack and backpack:FindFirstChild(name) then return true end
    if player.Character and player.Character:FindFirstChild(name) then return true end

    return false
end

local function GetRole(player)
    local role = RemoteRoles[player.Name]
    if role then return role end

    role = ReadRoleAttribute(player)
    if role then return role end

    role = ReadRoleAttribute(player.Character)
    if role then return role end

    role = ReadRoleValue(player)
    if role then return role end

    role = ReadRoleValue(player.Character)
    if role then return role end

    if HasTool(player, "Knife") then return "Murderer" end
    if HasTool(player, "Gun") or HasTool(player, "Revolver") then return "Sheriff" end

    return "Unknown"
end

local function GetRoleColor(role)
    if role == "Murderer" then return Config.Murderer end
    if role == "Sheriff" then return Config.Sheriff end
    if role == "Hero" then return Config.Hero end
    if role == "Innocent" then return Config.Innocent end
    return Config.Unknown
end

--// ============================================================
--// ROLE ESP
--// ============================================================

local function RemoveRoleESP(player)
    local data = RoleESPObjects[player]
    if not data then return end

    if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
    if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end

    RoleESPObjects[player] = nil
end

local function CreateRoleESP(player)
    local character = player.Character
    if not character then return end

    RemoveRoleESP(player)

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local Highlight = New("Highlight", {
        Name = "VAFLEX_ROLE",
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        FillTransparency = 0.92,
        OutlineTransparency = 0.03,
    })
    Highlight.Adornee = character
    Highlight.Parent = character

    if player == LocalPlayer then
        RoleESPObjects[player] = {
            Highlight = Highlight,
            Self = true,
        }
        return
    end

    local head = character:FindFirstChild("Head")

    if not head then
        Highlight:Destroy()
        return
    end

    local Billboard = New("BillboardGui", {
        Name = "VAFLEX_ROLE_LABEL",
        Adornee = head,
        Size = UDim2.fromOffset(220, 50),
        StudsOffset = Vector3.new(0, 2.8, 0),
        AlwaysOnTop = true,
        LightInfluence = 0,
        MaxDistance = Config.MaxDistance,
    })
    Billboard.Parent = head

    local Holder = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    })
    Holder.Parent = Billboard

    local Scale = New("UIScale", { Scale = 1 })
    Scale.Parent = Holder

    local NameLabel = New("TextLabel", {
        Position = UDim2.fromOffset(0, 1),
        Size = UDim2.new(1, 0, 0, 23),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Config.Unknown,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeColor3 = Color3.fromRGB(7, 9, 12),
        TextStrokeTransparency = 0.20,
    })
    NameLabel.Parent = Holder

    local DistanceLabel = New("TextLabel", {
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 17),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(228, 234, 242),
        TextSize = 9,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeColor3 = Color3.fromRGB(6, 8, 11),
        TextStrokeTransparency = 0.25,
    })
    DistanceLabel.Parent = Holder

    RoleESPObjects[player] = {
        Highlight = Highlight,
        Billboard = Billboard,
        Scale = Scale,
        Name = NameLabel,
        Distance = DistanceLabel,
    }
end

--// ============================================================
--// PLAYER DEATH -> GRAY
--// ============================================================

local function TrackCharacter(player, character)
    DeadPlayers[player] = false

    task.defer(function()
        if not Running or not character.Parent then return end
        task.wait(0.25)
        if not Running or not character.Parent then return end
        CreateRoleESP(player)
    end)

    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        local success, result = pcall(function()
            return character:WaitForChild("Humanoid", 5)
        end)
        if success then humanoid = result end
    end

    if humanoid then
        Connect(humanoid.Died, function()
            if PlayedPlayers[player] then
                DeadPlayers[player] = true
            else
                -- If role data arrives at exactly the death moment,
                -- still treat the player as having played the round.
                local role = GetRole(player)
                if role ~= "Unknown" then
                    PlayedPlayers[player] = true
                    DeadPlayers[player] = true
                end
            end
        end)
    end
end

local function SetupPlayer(player)
    Connect(player.CharacterAdded, function(character)
        TrackCharacter(player, character)
    end)

    if player.Character then
        TrackCharacter(player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

Connect(Players.PlayerAdded, SetupPlayer)

Connect(Players.PlayerRemoving, function(player)
    RemoveRoleESP(player)
    RemoteRoles[player.Name] = nil
    DeadPlayers[player] = nil
    PlayedPlayers[player] = nil
end)

--// ============================================================
--// GUN ESP
--// ============================================================

local function IsGunObject(object)
    local name = string.lower(object.Name)
    return name == "gundrop"
        or name == "droppedgun"
        or name == "dropped gun"
        or name == "gun drop"
end

local function GetGunPart(object)
    if object:IsA("BasePart") then return object end

    if object:IsA("Model") then
        return object.PrimaryPart
            or object:FindFirstChildWhichIsA("BasePart", true)
    end

    if object:IsA("Tool") then
        return object:FindFirstChild("Handle")
            or object:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function RemoveGunESP(object)
    local data = GunESPObjects[object]
    if not data then return end

    if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
    if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end

    GunESPObjects[object] = nil
end

local function CreateGunESP(object)
    if GunESPObjects[object] then return end

    local part = GetGunPart(object)
    if not part then return end

    local adornee = object:IsA("Model") and object or part

    local highlight = New("Highlight", {
        Name = "VAFLEX_GUN",
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        FillColor = Config.Water,
        OutlineColor = Config.WaterBright,
        FillTransparency = 0.84,
        OutlineTransparency = 0.02,
    })
    highlight.Adornee = adornee
    highlight.Parent = part

    local billboard = New("BillboardGui", {
        Name = "VAFLEX_GUN_LABEL",
        Adornee = part,
        Size = UDim2.fromOffset(150, 42),
        StudsOffset = Vector3.new(0, 2, 0),
        AlwaysOnTop = true,
        LightInfluence = 0,
        MaxDistance = Config.MaxDistance,
    })
    billboard.Parent = part

    local holder = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    })
    holder.Parent = billboard

    local scale = New("UIScale", { Scale = 1 })
    scale.Parent = holder

    local label = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "GUN",
        TextColor3 = Config.WaterBright,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextStrokeColor3 = Color3.fromRGB(6, 8, 11),
        TextStrokeTransparency = 0.2,
    })
    label.Parent = holder

    local distanceLabel = New("TextLabel", {
        Position = UDim2.fromOffset(0, 21),
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Config.Text,
        TextSize = 9,
        Font = Enum.Font.GothamMedium,
        TextStrokeColor3 = Color3.fromRGB(6, 8, 11),
        TextStrokeTransparency = 0.3,
    })
    distanceLabel.Parent = holder

    GunESPObjects[object] = {
        Highlight = highlight,
        Billboard = billboard,
        Part = part,
        Scale = scale,
        Distance = distanceLabel,
    }
end

task.defer(function()
    for _, object in ipairs(workspace:GetDescendants()) do
        if IsGunObject(object) then CreateGunESP(object) end
    end
end)

Connect(workspace.DescendantAdded, function(object)
    if not Running then return end

    if IsGunObject(object) then
        task.delay(0.15, function()
            if object.Parent then CreateGunESP(object) end
        end)
    end
end)

--// ============================================================
--// ROLE REFRESH BEFORE / DURING ROUND
--// ============================================================

task.spawn(function()
    while Running do
        RefreshRemoteRoles()
        task.wait(0.8)
    end
end)

--// ============================================================
--// ESP UPDATE
--// ============================================================

local RoleTimer = 0

Connect(RunService.Heartbeat, function(delta)
    if not Running then return end

    RoleTimer = RoleTimer + delta
    if RoleTimer < 0.10 then return end
    RoleTimer = 0

    local localCharacter = LocalPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character

        if character and not RoleESPObjects[player] then
            CreateRoleESP(player)
        end

        local data = RoleESPObjects[player]
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if data and root then
            local distance = (root.Position - localRoot.Position).Magnitude
            local enabled = Config.RoleESP
                and (player == LocalPlayer or distance <= Config.MaxDistance)

            data.Highlight.Enabled = enabled

            local role = GetRole(player)

            if role ~= "Unknown" then
                PlayedPlayers[player] = true
            end

            local color = DeadPlayers[player]
                and Config.Dead
                or GetRoleColor(role)

            data.Highlight.FillColor = color
            data.Highlight.OutlineColor = color

            if player ~= LocalPlayer and data.Billboard then
                data.Billboard.Enabled = enabled

                if enabled then
                    local distanceScale = math.clamp(
                        1 - (distance / Config.MaxDistance) * 0.58,
                        0.42,
                        1
                    )

                    data.Scale.Scale = distanceScale

                    local displayName = player.DisplayName
                    if not displayName or displayName == "" then displayName = player.Name end

                    data.Name.Text = displayName
                    data.Name.TextColor3 = color
                    data.Name.Visible = Config.RoleOptions.ShowUsernames

                    data.Distance.Text = tostring(math.floor(distance)) .. " studs"
                    data.Distance.Visible = Config.RoleOptions.ShowDistance

                    if Config.RoleOptions.ShowUsernames then
                        data.Distance.Position = UDim2.fromOffset(0, 24)
                    else
                        data.Distance.Position = UDim2.fromOffset(0, 11)
                    end
                end
            end
        end
    end

    for object, data in pairs(GunESPObjects) do
        if not object.Parent or not data.Part or not data.Part.Parent then
            RemoveGunESP(object)
        else
            local distance = (data.Part.Position - localRoot.Position).Magnitude
            local enabled = Config.GunESP and distance <= Config.MaxDistance

            data.Highlight.Enabled = enabled
            data.Billboard.Enabled = enabled

            if enabled then
                data.Distance.Text = tostring(math.floor(distance)) .. " studs"
                data.Scale.Scale = math.clamp(
                    1 - (distance / Config.MaxDistance) * 0.58,
                    0.45,
                    1
                )
            end
        end
    end
end)

--// ============================================================
--// WATERMARK LIVE UPDATE
--// ============================================================

task.spawn(function()
    while Running do
        RefreshWatermarkText()
        task.wait(0.5)
    end
end)

Connect(LocalPlayer.CharacterAdded, function()
    task.delay(0.65, function()
        if Running then BuildWatermarkAvatar() end
    end)
end)

pcall(function()
    Connect(LocalPlayer.CharacterAppearanceLoaded, function()
        task.delay(0.15, function()
            if Running then BuildWatermarkAvatar() end
        end)
    end)
end)

--// ============================================================
--// CRASH / UNLOAD
--// ============================================================

local function CrashVaflex()
    if not Running then return end
    Running = false

    Tween(CrashButton, 0.1, {
        BackgroundColor3 = Color3.fromRGB(105, 20, 31),
    })

    Tween(MainScale, 0.25, {
        Scale = TargetScale * 0.78,
    }, Enum.EasingStyle.Quint)

    task.wait(0.25)

    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end

    table.clear(Connections)

    local roleKeys = {}
    for player in pairs(RoleESPObjects) do table.insert(roleKeys, player) end
    for _, player in ipairs(roleKeys) do RemoveRoleESP(player) end

    local gunKeys = {}
    for object in pairs(GunESPObjects) do table.insert(gunKeys, object) end
    for _, object in ipairs(gunKeys) do RemoveGunESP(object) end

    if LoaderGui and LoaderGui.Parent then LoaderGui:Destroy() end
    if SoundsFolder and SoundsFolder.Parent then SoundsFolder:Destroy() end
    if Gui and Gui.Parent then Gui:Destroy() end

    pcall(function()
        if script and script.Parent then script:Destroy() end
    end)
end

Connect(CrashButton.MouseButton1Click, CrashVaflex)

--// ============================================================
--// START
--// ============================================================

task.spawn(function()
    PlayLoader()

    if not Running then return end

    BuildWatermarkAvatar()
    RefreshWatermarkText()

    Main.Visible = true
    MainScale.Scale = TargetScale * 0.92
    MenuOpen = true
    Watermark.Visible = false

    SelectTab("Visual")

    Tween(MainScale, 0.35, {
        Scale = TargetScale,
    }, Enum.EasingStyle.Back)

    task.wait(0.15)

    if LoaderGui and LoaderGui.Parent then
        LoaderGui:Destroy()
    end
end)
