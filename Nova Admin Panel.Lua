--[[
    ⚡ NOVA ADMIN PANEL v2.1
    Full Featured Modern UI
]]

-- ===================== SERVICES =====================
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local Stats            = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ===================== STATE =====================
local Connections = {}
local State = {
    fly = false,
    noclip = false,
    infJump = false,
    freecam = false,
    playerESP = false,
    spin = false,
    godmode = false,
    -- ===== NEW =====
    invisible = false,
    invincible = false,
    -- ===============
    flyBV = nil,
    flyConn = nil,
    noclipConn = nil,
    infJumpConn = nil,
    freecamConn = nil,
    spinConn = nil,
    godConn = nil,
    -- ===== NEW =====
    invisConn = nil,
    invisCharConn = nil,
    invincConn = nil,
    invincCharConn = nil,
    invincLoop = nil,
    -- ===============
}

local function track(c)
    table.insert(Connections, c)
    return c
end

-- ===================== THEMES =====================
local Themes = {
    purple = { accent = Color3.fromRGB(124, 92, 255), accent2 = Color3.fromRGB(88, 180, 255) },
    green  = { accent = Color3.fromRGB(80, 220, 140), accent2 = Color3.fromRGB(120, 255, 180) },
    red    = { accent = Color3.fromRGB(255, 90, 90),  accent2 = Color3.fromRGB(255, 150, 100) },
    cyan   = { accent = Color3.fromRGB(0, 200, 255),  accent2 = Color3.fromRGB(100, 230, 255) },
}

local Theme = {
    bg        = Color3.fromRGB(18, 18, 24),
    bg2       = Color3.fromRGB(24, 24, 32),
    card      = Color3.fromRGB(30, 30, 40),
    cardHover = Color3.fromRGB(40, 40, 54),
    border    = Color3.fromRGB(48, 48, 64),
    text      = Color3.fromRGB(240, 240, 250),
    textDim   = Color3.fromRGB(150, 150, 170),
    accent    = Themes.purple.accent,
    accent2   = Themes.purple.accent2,
    success   = Color3.fromRGB(80, 220, 140),
    danger    = Color3.fromRGB(255, 90, 90),
}

local Font     = Enum.Font.Gotham
local FontBold = Enum.Font.GothamBold

-- ===================== HELPERS =====================
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = p
    return c
end

local function stroke(p, col, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.border
    s.Thickness = t or 1
    s.Transparency = tr or 0.4
    s.Parent = p
    return s
end

local function padding(p, t, b, l, r)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft = UDim.new(0, l or 0)
    u.PaddingRight = UDim.new(0, r or 0)
    u.Parent = p
    return u
end

local function getHum()
    if LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
end

local function getHRP()
    if LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
end

-- ===== NEW: clipboard + asset-id + coord parsing helpers =====
local function copyToClipboard(text)
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, text)
        if ok then return true end
    end
    return false
end

local function normalizeAssetId(text)
    if not text or text == "" then return nil end
    local id = string.match(text, "%d+")
    if not id then return nil end
    return "rbxassetid://" .. id
end

local function parseAssetIds(text)
    local ids = {}
    if not text then return ids end
    for n in string.gmatch(text, "%d+") do
        table.insert(ids, "rbxassetid://" .. n)
    end
    return ids
end

local function parseCoords(str)
    if not str then return nil end
    local nums = {}
    for n in string.gmatch(str, "%-?%d+%.?%d*") do
        local v = tonumber(n)
        if v then table.insert(nums, v) end
    end
    if #nums >= 3 then
        return nums[1], nums[2], nums[3]
    end
    return nil
end

local function teleportTo(x, y, z)
    local hrp = getHRP()
    if not hrp then
        toast and toast("No character", "error")
        return false
    end
    hrp.CFrame = CFrame.new(x, y, z)
    if toast then
        toast(string.format("Teleported to %.1f, %.1f, %.1f", x, y, z), "success")
    end
    return true
end
-- ============================================================

-- ===================== ROOT GUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NovaAdminPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Glow = Instance.new("Frame")
Glow.Size = UDim2.new(0, 560, 0, 460)
Glow.Position = UDim2.new(0.5, -280, 0.5, -230)
Glow.BackgroundColor3 = Theme.accent
Glow.BackgroundTransparency = 0.88
Glow.BorderSizePixel = 0
Glow.ZIndex = 0
Glow.Parent = ScreenGui
corner(Glow, 24)

local Window = Instance.new("Frame")
Window.Size = UDim2.new(0, 560, 0, 440)
Window.Position = UDim2.new(0.5, -280, 0.5, -220)
Window.BackgroundColor3 = Theme.bg
Window.BorderSizePixel = 0
Window.Active = true
Window.Draggable = true
Window.ZIndex = 1
Window.Parent = ScreenGui
corner(Window, 18)
stroke(Window, Theme.border, 1, 0.3)

track(Window:GetPropertyChangedSignal("Position"):Connect(function()
    Glow.Position = Window.Position
end))

-- ===================== TITLE BAR =====================
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = Theme.bg2
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2
TitleBar.Parent = Window
corner(TitleBar, 18)

local TitleMask = Instance.new("Frame")
TitleMask.Size = UDim2.new(1, 0, 0, 18)
TitleMask.Position = UDim2.new(0, 0, 1, -18)
TitleMask.BackgroundColor3 = Theme.bg2
TitleMask.BorderSizePixel = 0
TitleMask.ZIndex = 2
TitleMask.Parent = TitleBar

local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 10, 0, 10)
Dot.Position = UDim2.new(0, 20, 0.5, -5)
Dot.BackgroundColor3 = Theme.accent
Dot.BorderSizePixel = 0
Dot.ZIndex = 3
Dot.Parent = TitleBar
corner(Dot, 5)

local DotGlow = Instance.new("Frame")
DotGlow.Size = UDim2.new(0, 18, 0, 18)
DotGlow.Position = UDim2.new(0, 16, 0.5, -9)
DotGlow.BackgroundColor3 = Theme.accent
DotGlow.BackgroundTransparency = 0.7
DotGlow.BorderSizePixel = 0
DotGlow.ZIndex = 2
DotGlow.Parent = TitleBar
corner(DotGlow, 9)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -140, 1, 0)
Title.Position = UDim2.new(0, 42, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Nova  ·  Admin"
Title.TextColor3 = Theme.text
Title.Font = FontBold
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = TitleBar

local function makeControl(text, color, xOff, hoverColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 32, 0, 32)
    btn.Position = UDim2.new(1, xOff, 0.5, -16)
    btn.BackgroundColor3 = Theme.card
    btn.Text = text
    btn.TextColor3 = color
    btn.Font = FontBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    btn.Parent = TitleBar
    corner(btn, 8)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.card}):Play()
    end)
    return btn
end

local MinimizeBtn = makeControl("—", Theme.textDim, -88, Theme.cardHover)
local CloseBtn    = makeControl("✕", Theme.danger,  -48, Color3.fromRGB(60, 30, 30))

-- ===================== TAB BAR =====================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -32, 0, 40)
TabBar.Position = UDim2.new(0, 16, 0, 64)
TabBar.BackgroundColor3 = Theme.bg2
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 2
TabBar.Parent = Window
corner(TabBar, 12)
stroke(TabBar, Theme.border, 1, 0.5)

local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size = UDim2.new(1, -8, 1, 0)
TabScroll.Position = UDim2.new(0, 4, 0, 0)
TabScroll.BackgroundTransparency = 1
TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 0
TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TabScroll.ScrollingDirection = Enum.ScrollingDirection.X
TabScroll.ZIndex = 3
TabScroll.Parent = TabBar

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 4)
TabList.VerticalAlignment = Enum.VerticalAlignment.Center
TabList.Parent = TabScroll
padding(TabScroll, 4, 4, 6, 6)

local TabIndicator = Instance.new("Frame")
TabIndicator.BackgroundColor3 = Theme.accent
TabIndicator.BorderSizePixel = 0
TabIndicator.ZIndex = 2
TabIndicator.Parent = TabBar
corner(TabIndicator, 8)

track(TabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabScroll.CanvasSize = UDim2.new(0, TabList.AbsoluteContentSize.X + 12, 0, 0)
end))

-- ===================== CONTENT =====================
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -32, 1, -124)
Content.Position = UDim2.new(0, 16, 0, 112)
Content.BackgroundTransparency = 1
Content.ZIndex = 2
Content.Parent = Window

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, 0)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Theme.accent
Scroll.ScrollBarImageTransparency = 0.5
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ZIndex = 2
Scroll.Parent = Content

local ScrollList = Instance.new("UIListLayout")
ScrollList.Padding = UDim.new(0, 10)
ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
ScrollList.Parent = Scroll

track(ScrollList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, ScrollList.AbsoluteContentSize.Y + 8)
end))

-- ===== NEW: layout order counter (keeps element order deterministic) =====
local layoutOrder = 0
local function nextOrder()
    layoutOrder = layoutOrder + 1
    return layoutOrder
end
-- ========================================================================

-- ===================== TOASTS =====================
local ToastHolder = Instance.new("Frame")
ToastHolder.Size = UDim2.new(0, 300, 1, 0)
ToastHolder.Position = UDim2.new(0.5, -150, 0, 0)
ToastHolder.BackgroundTransparency = 1
ToastHolder.ZIndex = 50
ToastHolder.Parent = ScreenGui

local ToastList = Instance.new("UIListLayout")
ToastList.Padding = UDim.new(0, 8)
ToastList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ToastList.SortOrder = Enum.SortOrder.LayoutOrder
ToastList.Parent = ToastHolder
padding(ToastHolder, 20, 0, 0, 0)

function toast(text, kind)
    kind = kind or "info"
    local color = Theme.accent
    if kind == "success" then color = Theme.success end
    if kind == "error"   then color = Theme.danger end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 46)
    card.BackgroundColor3 = Theme.bg2
    card.BorderSizePixel = 0
    card.ZIndex = 51
    card.Parent = ToastHolder
    corner(card, 12)
    stroke(card, Theme.border, 1, 0.4)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -16)
    bar.Position = UDim2.new(0, 8, 0, 8)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.ZIndex = 52
    bar.Parent = card
    corner(bar, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -32, 1, 0)
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.text
    lbl.Font = Font
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 52
    lbl.Parent = card

    card.BackgroundTransparency = 1
    lbl.TextTransparency = 1
    TweenService:Create(card, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    TweenService:Create(lbl,  TweenInfo.new(0.2), {TextTransparency = 0}):Play()

    task.delay(2.2, function()
        TweenService:Create(card, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
        TweenService:Create(lbl,  TweenInfo.new(0.25), {TextTransparency = 1}):Play()
        task.wait(0.3)
        card:Destroy()
    end)
end

-- ===================== COMPONENTS =====================
local function clearContent()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("GuiObject") then
            c:Destroy()
        end
    end
    layoutOrder = 0
end

local function section(text)
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, -4, 0, 22)
    s.BackgroundTransparency = 1
    s.Text = string.upper(text)
    s.TextColor3 = Theme.textDim
    s.Font = FontBold
    s.TextSize = 11
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.ZIndex = 3
    s.LayoutOrder = nextOrder()
    s.Parent = Scroll
    padding(s, 0, 0, 6, 0)
    return s
end

local function button(text, color, callback)
    color = color or Theme.accent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 42)
    btn.BackgroundColor3 = Theme.card
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.ZIndex = 3
    btn.LayoutOrder = nextOrder()
    btn.Parent = Scroll
    corner(btn, 10)
    stroke(btn, Theme.border, 1, 0.5)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 0, 22)
    bar.Position = UDim2.new(0, 12, 0.5, -11)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.ZIndex = 4
    bar.Parent = btn
    corner(bar, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -32, 1, 0)
    lbl.Position = UDim2.new(0, 26, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.text
    lbl.Font = Font
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.cardHover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.card}):Play()
    end)

    track(btn.MouseButton1Click:Connect(callback))
    return btn
end

local function toggle(text, color, callback)
    color = color or Theme.accent
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 48)
    row.BackgroundColor3 = Theme.card
    row.BorderSizePixel = 0
    row.ZIndex = 3
    row.LayoutOrder = nextOrder()
    row.Parent = Scroll
    corner(row, 10)
    stroke(row, Theme.border, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -90, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.text
    lbl.Font = Font
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = row

    local trk = Instance.new("Frame")
    trk.Size = UDim2.new(0, 44, 0, 24)
    trk.Position = UDim2.new(1, -60, 0.5, -12)
    trk.BackgroundColor3 = Theme.bg2
    trk.BorderSizePixel = 0
    trk.ZIndex = 4
    trk.Parent = row
    corner(trk, 12)
    stroke(trk, Theme.border, 1, 0.3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Theme.textDim
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = trk
    corner(knob, 9)

    local clicker = Instance.new("TextButton")
    clicker.Size = UDim2.new(1, 0, 1, 0)
    clicker.BackgroundTransparency = 1
    clicker.Text = ""
    clicker.ZIndex = 6
    clicker.Parent = row

    local on = false
    local function setState(v, fire)
        on = v
        TweenService:Create(trk, TweenInfo.new(0.2), {BackgroundColor3 = on and color or Theme.bg2}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = on and Theme.text or Theme.textDim
        }):Play()
        if fire and callback then
            callback(on)
        end
    end

    track(clicker.MouseButton1Click:Connect(function()
        setState(not on, true)
    end))

    return row
end

local function slider(text, min, max, default, color, callback)
    color = color or Theme.accent
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 64)
    card.BackgroundColor3 = Theme.card
    card.BorderSizePixel = 0
    card.ZIndex = 3
    card.LayoutOrder = nextOrder()
    card.Parent = Scroll
    corner(card, 10)
    stroke(card, Theme.border, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 0, 24)
    lbl.Position = UDim2.new(0, 16, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.text
    lbl.Font = Font
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = card

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 52, 0, 22)
    badge.Position = UDim2.new(1, -66, 0, 9)
    badge.BackgroundColor3 = color
    badge.BackgroundTransparency = 0.75
    badge.BorderSizePixel = 0
    badge.ZIndex = 4
    badge.Parent = card
    corner(badge, 6)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = color
    valLbl.Font = FontBold
    valLbl.TextSize = 12
    valLbl.ZIndex = 5
    valLbl.Parent = badge

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -32, 0, 6)
    bar.Position = UDim2.new(0, 16, 1, -22)
    bar.BackgroundColor3 = Theme.bg2
    bar.BorderSizePixel = 0
    bar.ZIndex = 4
    bar.Parent = card
    corner(bar, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = bar
    corner(fill, 3)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Theme.text
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.AutoButtonColor = false
    knob.ZIndex = 6
    knob.Parent = bar
    corner(knob, 8)

    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -8, 0.5, -8)
        valLbl.Text = tostring(v)
        if callback then callback(v) end
    end

    track(knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end))

    track(bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            update(i)
        end
    end))

    track(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    return card
end

local function inputBox(placeholder, callback, initialText)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 42)
    card.BackgroundColor3 = Theme.card
    card.BorderSizePixel = 0
    card.ZIndex = 3
    card.LayoutOrder = nextOrder()
    card.Parent = Scroll
    corner(card, 10)
    stroke(card, Theme.border, 1, 0.5)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, 0)
    box.Position = UDim2.new(0, 10, 0, 0)
    box.BackgroundTransparency = 1
    box.Text = initialText or ""
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Theme.textDim
    box.TextColor3 = Theme.text
    box.Font = Font
    box.TextSize = 14
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.ZIndex = 4
    box.Parent = card

    track(box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end))
    return card, box
end

-- ===================== FEATURES =====================

-- FLY
local function startFly()
    if State.fly then return end
    local hrp = getHRP()
    if not hrp then return end
    State.fly = true
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    State.flyBV = bv
    State.flyConn = RunService.RenderStepped:Connect(function()
        if not State.fly or not hrp.Parent then return end
        local d = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
        bv.Velocity = d * 60
    end)
    track(State.flyConn)
end

local function stopFly()
    State.fly = false
    if State.flyBV then State.flyBV:Destroy(); State.flyBV = nil end
    if State.flyConn then State.flyConn:Disconnect(); State.flyConn = nil end
end

-- NOCLIP
local function startNoclip()
    if State.noclip then return end
    State.noclip = true
    State.noclipConn = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
    track(State.noclipConn)
end

local function stopNoclip()
    State.noclip = false
    if State.noclipConn then State.noclipConn:Disconnect(); State.noclipConn = nil end
    if LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end

-- INFINITE JUMP
local function startInfJump()
    if State.infJump then return end
    State.infJump = true
    State.infJumpConn = UserInputService.JumpRequest:Connect(function()
        local h = getHum()
        if h and State.infJump then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    track(State.infJumpConn)
end

local function stopInfJump()
    State.infJump = false
    if State.infJumpConn then State.infJumpConn:Disconnect(); State.infJumpConn = nil end
end

-- SPIN
local function startSpin()
    if State.spin then return end
    State.spin = true
    State.spinConn = RunService.Heartbeat:Connect(function(dt)
        local hrp = getHRP()
        if hrp and State.spin then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(360 * dt), 0)
        end
    end)
    track(State.spinConn)
end

local function stopSpin()
    State.spin = false
    if State.spinConn then State.spinConn:Disconnect(); State.spinConn = nil end
end

-- MOON GRAVITY
local function setMoon(on)
    workspace.Gravity = on and 40 or 196.2
end

-- GODMODE (legacy)
local function setGodmode(on)
    State.godmode = on
    local h = getHum()
    if not h then return end
    if on then
        h.MaxHealth = math.huge
        h.Health = math.huge
        State.godConn = h.HealthChanged:Connect(function(v)
            if State.godmode and v < h.MaxHealth then
                h.Health = h.MaxHealth
            end
        end)
        track(State.godConn)
    else
        if State.godConn then State.godConn:Disconnect(); State.godConn = nil end
        h.MaxHealth = 100
        h.Health = 100
    end
end

-- ===== NEW: INVISIBILITY =====
-- NOTE: Roblox's replication filter prevents a LocalScript from replicating
-- Transparency changes to the server. This hides the character on the local
-- client (and via LocalTransparencyModifier). True server-side invisibility
-- requires a server script or an exposed game RemoteEvent.
local invisBackup = {}

local function applyInvis(on)
    local char = LocalPlayer.Character
    if not char then return end

    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Decal") then
            if on then
                if invisBackup[d] == nil then
                    invisBackup[d] = d.Transparency
                end
                d.Transparency = 1
                if d:IsA("BasePart") then
                    d.LocalTransparencyModifier = 1
                end
            else
                if invisBackup[d] ~= nil then
                    d.Transparency = invisBackup[d]
                    invisBackup[d] = nil
                else
                    d.Transparency = 0
                end
                if d:IsA("BasePart") then
                    d.LocalTransparencyModifier = 0
                end
            end
        end
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.NameDisplayDistance   = on and 0 or 100
        hum.HealthDisplayDistance = on and 0 or 100
    end
end

local function setInvisible(on)
    State.invisible = on

    if on then
        applyInvis(true)

        if not State.invisConn then
            State.invisConn = RunService.Stepped:Connect(function()
                if State.invisible then
                    applyInvis(true)
                end
            end)
            track(State.invisConn)
        end

        if not State.invisCharConn then
            State.invisCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(0.4)
                if State.invisible then
                    applyInvis(true)
                end
            end)
            track(State.invisCharConn)
        end
    else
        if State.invisConn then State.invisConn:Disconnect(); State.invisConn = nil end
        if State.invisCharConn then State.invisCharConn:Disconnect(); State.invisCharConn = nil end
        applyInvis(false)
    end
end

-- ===== NEW: INVINCIBILITY =====
-- NOTE: Same replication caveat as invisibility. This keeps the local humanoid
-- pinned at max health, disables the Dead state, and rehooks on respawn.
-- That is the strongest client-side "invincibility" possible.
local function setInvincible(on)
    State.invincible = on

    local function hook(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        if on then
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
            hum.MaxHealth = math.huge
            hum.Health = math.huge

            if State.invincConn then
                State.invincConn:Disconnect()
                State.invincConn = nil
            end
            State.invincConn = hum.HealthChanged:Connect(function(v)
                if State.invincible and v < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end)
            track(State.invincConn)
        else
            if State.invincConn then
                State.invincConn:Disconnect()
                State.invincConn = nil
            end
            pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end

    if on then
        if LocalPlayer.Character then hook(LocalPlayer.Character) end

        if not State.invincCharConn then
            State.invincCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                if State.invincible then hook(char) end
            end)
            track(State.invincCharConn)
        end

        if not State.invincLoop then
            State.invincLoop = RunService.Heartbeat:Connect(function()
                if not State.invincible then return end
                local h = getHum()
                if h and h.Health < h.MaxHealth then
                    h.Health = h.MaxHealth
                end
            end)
            track(State.invincLoop)
        end
    else
        if State.invincCharConn then State.invincCharConn:Disconnect(); State.invincCharConn = nil end
        if State.invincLoop then State.invincLoop:Disconnect(); State.invincLoop = nil end

        local h = getHum()
        if h then
            pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
            h.MaxHealth = 100
            h.Health = 100
        end
    end
end

-- ===== NEW: TEXTURE REPLACEMENT =====
local textureBackup = {}

local function replaceTextures(assetId)
    local count = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Decal") or d:IsA("Texture") then
            if textureBackup[d] == nil then
                textureBackup[d] = d.Texture
            end
            pcall(function() d.Texture = assetId end)
            count = count + 1
        elseif d:IsA("SurfaceAppearance") then
            if textureBackup[d] == nil then
                textureBackup[d] = d.ColorMap
            end
            pcall(function() d.ColorMap = assetId end)
            count = count + 1
        end
    end
    return count
end

local function restoreTextures()
    local count = 0
    for inst, orig in pairs(textureBackup) do
        if inst and inst.Parent then
            pcall(function()
                if inst:IsA("SurfaceAppearance") then
                    inst.ColorMap = orig
                else
                    inst.Texture = orig
                end
            end)
            count = count + 1
        end
    end
    textureBackup = {}
    return count
end

-- ===== NEW: SKYBOX REPLACEMENT =====
local SkyFaces = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }

local function applySkybox(ids)
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end

    if #ids == 1 then
        for _, f in ipairs(SkyFaces) do
            sky[f] = ids[1]
        end
    elseif #ids >= 6 then
        for i, f in ipairs(SkyFaces) do
            sky[f] = ids[i]
        end
    else
        return false
    end
    return true
end

local function resetSkybox()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then sky:Destroy() end
end

-- PLAYER ESP
local espCache = {}
local function attachESP(player)
    if espCache[player] then return end
    local function add(character)
        local hl = Instance.new("Highlight")
        hl.FillColor = Theme.accent
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = character
        espCache[player] = hl
    end
    if player.Character then add(player.Character) end
    track(player.CharacterAdded:Connect(add))
end

local function setPlayerESP(on)
    State.playerESP = on
    if on then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then attachESP(p) end
        end
        track(Players.PlayerAdded:Connect(function(p)
            if State.playerESP then attachESP(p) end
        end))
    else
        for p, hl in pairs(espCache) do
            hl:Destroy()
            espCache[p] = nil
        end
    end
end

-- FULLBRIGHT
local function setFullbright(on)
    if on then
        Lighting.Brightness = 5
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
    else
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    end
end

-- FREECAM
local function startFreecam()
    if State.freecam then return end
    State.freecam = true
    local rotX, rotY = 0, 0
    local lastMouse = UserInputService:GetMouseLocation()

    track(UserInputService.InputChanged:Connect(function(i)
        if not State.freecam then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            local cur = UserInputService:GetMouseLocation()
            rotX = rotX - (cur.X - lastMouse.X) * 0.005
            rotY = math.clamp(rotY - (cur.Y - lastMouse.Y) * 0.005, -math.pi/2 + 0.01, math.pi/2 - 0.01)
            lastMouse = cur
        end
    end))

    State.freecamConn = RunService.RenderStepped:Connect(function(dt)
        if not State.freecam then return end
        local d = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end
        local newCF = CFrame.new(Camera.CFrame.Position + d * dt * 60) * CFrame.Angles(0, rotX, 0) * CFrame.Angles(rotY, 0, 0)
        Camera.CFrame = newCF
    end)
    track(State.freecamConn)
end

local function stopFreecam()
    State.freecam = false
    if State.freecamConn then State.freecamConn:Disconnect(); State.freecamConn = nil end
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then Camera.CameraSubject = h end
    end
end

-- ===== NEW: WAYPOINTS =====
local Waypoints = {}
local WAYPOINT_FILE = "nova_waypoints.json"

local UIState = {
    textureId    = "",
    skyId        = "",
    waypointName = "",
}

local function loadWaypoints()
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, exists = pcall(isfile, WAYPOINT_FILE)
        if ok and exists then
            local ok2, data = pcall(function()
                return HttpService:JSONDecode(readfile(WAYPOINT_FILE))
            end)
            if ok2 and type(data) == "table" then
                Waypoints = data
            end
        end
    end
end

local function saveWaypoints()
    if type(writefile) == "function" then
        pcall(function()
            writefile(WAYPOINT_FILE, HttpService:JSONEncode(Waypoints))
        end)
    end
end

loadWaypoints()

-- ===================== TABS =====================
local Tabs = {
    { name = "Players",  icon = "👤" },
    -- ===== NEW =====
    { name = "Teleport", icon = "📍" },
    -- ===============
    { name = "Movement", icon = "🏃" },
    { name = "Visual",   icon = "👁️" },
    { name = "World",    icon = "🌎" },
    { name = "Fun",      icon = "😂" },
    { name = "Settings", icon = "⚙️" },
}

local activeTab
local tabButtons = {}

local function renderTab(name)
    clearContent()

    if name == "Players" then
        section("Search")
        inputBox("Type a player name...", function(text)
            if text == "" then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and string.find(string.lower(p.Name), string.lower(text), 1, true) then
                    toast("Found: " .. p.Name, "success")
                    return
                end
            end
            toast("No player found", "error")
        end)

        section("Actions")
        button("Spectate Nearest", Theme.accent, function()
            local closest, dist = nil, math.huge
            local myHRP = getHRP()
            if not myHRP then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum then
                        local d = (hrp.Position - myHRP.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = { player = p, hum = hum }
                        end
                    end
                end
            end
            if closest then
                Camera.CameraSubject = closest.hum
                toast("Spectating " .. closest.player.Name, "success")
            else
                toast("No players found", "error")
            end
        end)

        button("Teleport to Nearest", Theme.accent, function()
            local closest, dist = nil, math.huge
            local myHRP = getHRP()
            if not myHRP then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - myHRP.Position).Magnitude
                        if d < dist then
                            dist = d
                            closest = hrp
                        end
                    end
                end
            end
            if closest then
                myHRP.CFrame = closest.CFrame + Vector3.new(0, 3, 0)
                toast("Teleported", "success")
            else
                toast("No target", "error")
            end
        end)

        button("Stop Spectating", Theme.textDim, function()
            local h = getHum()
            if h then
                Camera.CameraSubject = h
                toast("Back to self", "info")
            end
        end)

        -- ===== NEW: Self section =====
        section("Self")
        toggle("Invisibility", Theme.accent, function(on)
            setInvisible(on)
            toast(on and "Invisible" or "Visible", on and "success" or "info")
        end)
        toggle("Invincibility", Theme.success, function(on)
            setInvincible(on)
            toast(on and "Invincible" or "Mortal", on and "success" or "info")
        end)
        -- ===========================

        section("Player ESP")
        toggle("Player ESP", Theme.accent, setPlayerESP)

        section("Coordinates")
        local coordLabel = Instance.new("TextLabel")
        coordLabel.Size = UDim2.new(1, -4, 0, 46)
        coordLabel.BackgroundColor3 = Theme.card
        coordLabel.BorderSizePixel = 0
        coordLabel.Text = "X: --  Y: --  Z: --"
        coordLabel.TextColor3 = Theme.text
        coordLabel.Font = Font
        coordLabel.TextSize = 13
        coordLabel.ZIndex = 3
        coordLabel.LayoutOrder = nextOrder()
        coordLabel.Parent = Scroll
        corner(coordLabel, 10)
        stroke(coordLabel, Theme.border, 1, 0.5)
        track(RunService.Heartbeat:Connect(function()
            local hrp = getHRP()
            if hrp and coordLabel.Parent then
                local p = hrp.Position
                coordLabel.Text = string.format("X: %.1f   Y: %.1f   Z: %.1f", p.X, p.Y, p.Z)
            end
        end))

        -- ===== NEW: copy coordinates =====
        button("Copy Coordinates", Theme.accent, function()
            local hrp = getHRP()
            if not hrp then toast("No character", "error"); return end
            local p = hrp.Position
            local str = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
            if copyToClipboard(str) then
                toast("Copied: " .. str, "success")
            else
                toast("Clipboard unavailable", "error")
            end
        end)
        button("Save Current Position", Theme.accent2, function()
            local hrp = getHRP()
            if not hrp then toast("No character", "error"); return end
            local p = hrp.Position
            local nm = string.format("WP %d", #Waypoints + 1)
            table.insert(Waypoints, { name = nm, x = p.X, y = p.Y, z = p.Z })
            saveWaypoints()
            toast("Saved " .. nm, "success")
        end)
        -- ==============================

    -- ===== NEW: TELEPORT / WAYPOINTS TAB =====
    elseif name == "Teleport" then
        section("Current Position")
        local posLabel = Instance.new("TextLabel")
        posLabel.Size = UDim2.new(1, -4, 0, 46)
        posLabel.BackgroundColor3 = Theme.card
        posLabel.BorderSizePixel = 0
        posLabel.Text = "X: --  Y: --  Z: --"
        posLabel.TextColor3 = Theme.text
        posLabel.Font = Font
        posLabel.TextSize = 13
        posLabel.ZIndex = 3
        posLabel.LayoutOrder = nextOrder()
        posLabel.Parent = Scroll
        corner(posLabel, 10)
        stroke(posLabel, Theme.border, 1, 0.5)
        track(RunService.Heartbeat:Connect(function()
            local hrp = getHRP()
            if hrp and posLabel.Parent then
                local p = hrp.Position
                posLabel.Text = string.format("X: %.1f   Y: %.1f   Z: %.1f", p.X, p.Y, p.Z)
            end
        end))

        button("Copy Coordinates", Theme.accent, function()
            local hrp = getHRP()
            if not hrp then toast("No character", "error"); return end
            local p = hrp.Position
            local str = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
            if copyToClipboard(str) then
                toast("Copied: " .. str, "success")
            else
                toast("Clipboard unavailable", "error")
            end
        end)

        section("Save Waypoint")
        inputBox("Waypoint name...", function(text)
            UIState.waypointName = text
        end, UIState.waypointName)

        button("Save Current Position", Theme.accent, function()
            local hrp = getHRP()
            if not hrp then toast("No character", "error"); return end
            local p = hrp.Position
            local nm = UIState.waypointName
            if not nm or nm == "" then
                nm = string.format("WP %d", #Waypoints + 1)
            end
            table.insert(Waypoints, { name = nm, x = p.X, y = p.Y, z = p.Z })
            saveWaypoints()
            toast("Saved: " .. nm, "success")
            task.defer(function() renderTab("Teleport") end)
        end)

        section("Saved Waypoints (" .. #Waypoints .. ")")

        if #Waypoints == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, -4, 0, 44)
            empty.BackgroundColor3 = Theme.card
            empty.BackgroundTransparency = 0.4
            empty.BorderSizePixel = 0
            empty.Text = "No waypoints saved yet"
            empty.TextColor3 = Theme.textDim
            empty.Font = Font
            empty.TextSize = 13
            empty.ZIndex = 3
            empty.LayoutOrder = nextOrder()
            empty.Parent = Scroll
            corner(empty, 10)
            stroke(empty, Theme.border, 1, 0.6)
        else
            for i, wp in ipairs(Waypoints) do
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -4, 0, 50)
                row.BackgroundColor3 = Theme.card
                row.Text = ""
                row.AutoButtonColor = false
                row.BorderSizePixel = 0
                row.ZIndex = 3
                row.LayoutOrder = nextOrder()
                row.Parent = Scroll
                corner(row, 10)
                stroke(row, Theme.border, 1, 0.5)

                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(0, 4, 0, 26)
                bar.Position = UDim2.new(0, 12, 0.5, -13)
                bar.BackgroundColor3 = Theme.accent
                bar.BorderSizePixel = 0
                bar.ZIndex = 4
                bar.Parent = row
                corner(bar, 2)

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, -110, 0, 20)
                nameLbl.Position = UDim2.new(0, 26, 0, 6)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = wp.name
                nameLbl.TextColor3 = Theme.text
                nameLbl.Font = Font
                nameLbl.TextSize = 14
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.ZIndex = 4
                nameLbl.Parent = row

                local coordLbl = Instance.new("TextLabel")
                coordLbl.Size = UDim2.new(1, -110, 0, 16)
                coordLbl.Position = UDim2.new(0, 26, 0, 26)
                coordLbl.BackgroundTransparency = 1
                coordLbl.Text = string.format("%.1f, %.1f, %.1f", wp.x, wp.y, wp.z)
                coordLbl.TextColor3 = Theme.textDim
                coordLbl.Font = Font
                coordLbl.TextSize = 11
                coordLbl.TextXAlignment = Enum.TextXAlignment.Left
                coordLbl.ZIndex = 4
                coordLbl.Parent = row

                local del = Instance.new("TextButton")
                del.Size = UDim2.new(0, 28, 0, 28)
                del.Position = UDim2.new(1, -38, 0.5, -14)
                del.BackgroundColor3 = Theme.bg2
                del.Text = "✕"
                del.TextColor3 = Theme.danger
                del.Font = FontBold
                del.TextSize = 13
                del.AutoButtonColor = false
                del.BorderSizePixel = 0
                del.ZIndex = 5
                del.Parent = row
                corner(del, 8)

                row.MouseEnter:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Theme.cardHover}):Play()
                end)
                row.MouseLeave:Connect(function()
                    TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = Theme.card}):Play()
                end)

                row.MouseButton1Click:Connect(function()
                    teleportTo(wp.x, wp.y, wp.z)
                end)

                del.MouseButton1Click:Connect(function()
                    table.remove(Waypoints, i)
                    saveWaypoints()
                    toast("Removed " .. wp.name, "info")
                    task.defer(function() renderTab("Teleport") end)
                end)
            end
        end

        section("Teleport To Coordinates")
        inputBox("e.g. 100, 25, -50", function(text)
            local x, y, z = parseCoords(text)
            if x then
                teleportTo(x, y, z)
            else
                toast("Invalid coordinates", "error")
            end
        end)

    -- =========================================

    elseif name == "Movement" then
        section("Core")
        toggle("Fly", Theme.accent, function(on)
            if on then
                startFly()
                toast("Fly on", "success")
            else
                stopFly()
                toast("Fly off", "info")
            end
        end)
        toggle("Noclip", Theme.accent2, function(on)
            if on then
                startNoclip()
                toast("Noclip on", "success")
            else
                stopNoclip()
                toast("Noclip off", "info")
            end
        end)
        toggle("Infinite Jump", Theme.accent, function(on)
            if on then
                startInfJump()
                toast("Inf jump on", "success")
            else
                stopInfJump()
                toast("Inf jump off", "info")
            end
        end)

        section("Tuning")
        slider("Walk Speed", 16, 500, 16, Theme.accent, function(v)
            local h = getHum()
            if h then h.WalkSpeed = v end
        end)
        slider("Jump Power", 50, 500, 50, Theme.accent2, function(v)
            local h = getHum()
            if h then h.JumpPower = v end
        end)

        section("Presets")
        button("Reset Movement", Theme.textDim, function()
            local h = getHum()
            if h then
                h.WalkSpeed = 16
                h.JumpPower = 50
            end
            toast("Movement reset", "success")
        end)

    elseif name == "Visual" then
        section("ESP")
        toggle("Player ESP", Theme.accent, setPlayerESP)

        section("Lighting")
        toggle("Fullbright", Theme.accent2, setFullbright)
        toggle("No Fog", Theme.accent2, function(on)
            if on then
                Lighting.FogEnd = 1e6
                Lighting.FogStart = 1e6
            else
                Lighting.FogEnd = 100000
                Lighting.FogStart = 0
            end
        end)

        section("Camera")
        toggle("Freecam", Theme.accent, function(on)
            if on then
                startFreecam()
                toast("Freecam on", "success")
            else
                stopFreecam()
                toast("Freecam off", "info")
            end
        end)
        slider("Field of View", 40, 120, 70, Theme.accent2, function(v)
            Camera.FieldOfView = v
        end)

    elseif name == "World" then
        section("Lighting")
        slider("Brightness", 0, 10, 2, Theme.accent, function(v)
            Lighting.Brightness = v
        end)
        slider("Clock Time", 0, 24, 14, Theme.accent2, function(v)
            Lighting.ClockTime = v
        end)
        button("Fullbright", Theme.accent, function()
            setFullbright(true)
            toast("Fullbright on", "success")
        end)

        -- ===== NEW: TEXTURES =====
        section("Replace Textures")
        inputBox("Texture asset ID (e.g. 123456789)", function(text)
            UIState.textureId = text
        end, UIState.textureId)
        button("Replace All Textures", Theme.accent, function()
            local id = normalizeAssetId(UIState.textureId)
            if not id then
                toast("Enter a valid asset ID", "error")
                return
            end
            local n = replaceTextures(id)
            toast("Replaced " .. n .. " textures", "success")
        end)
        button("Restore Textures", Theme.textDim, function()
            local n = restoreTextures()
            toast("Restored " .. n .. " textures", "info")
        end)
        -- =========================

        -- ===== NEW: SKYBOX =====
        section("Replace Skybox")
        inputBox("Skybox ID(s) — 1 or 6 comma-separated", function(text)
            UIState.skyId = text
        end, UIState.skyId)
        button("Apply Skybox", Theme.accent, function()
            local ids = parseAssetIds(UIState.skyId)
            if #ids == 0 then
                toast("Enter a valid asset ID", "error")
                return
            end
            if #ids ~= 1 and #ids < 6 then
                toast("Provide 1 or 6 IDs", "error")
                return
            end
            if applySkybox(ids) then
                toast("Skybox applied", "success")
            else
                toast("Failed to apply skybox", "error")
            end
        end)
        button("Remove Skybox", Theme.textDim, function()
            resetSkybox()
            toast("Skybox removed", "info")
        end)
        -- ======================

        section("Environment")
        button("Clear Weather", Theme.textDim, function()
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") or c:IsA("Sky") or c:IsA("Clouds")
                    or c:IsA("BloomEffect") or c:IsA("BlurEffect") or c:IsA("ColorCorrectionEffect") then
                    c:Destroy()
                end
            end
            toast("Weather cleared", "success")
        end)

        section("Camera Effects")
        button("Remove All Post-Processing", Theme.accent2, function()
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("PostEffect") then c:Destroy() end
            end
            toast("Post-FX removed", "success")
        end)

    elseif name == "Fun" then
        section("Player")
        toggle("Spin", Theme.accent, function(on)
            if on then
                startSpin()
                toast("Spinning", "success")
            else
                stopSpin()
                toast("Stopped", "info")
            end
        end)
        toggle("Moon Gravity", Theme.accent2, function(on)
            setMoon(on)
            toast(on and "Moon gravity" or "Normal gravity", "success")
        end)

        section("Scale")
        button("Giant", Theme.accent, function()
            local char = LocalPlayer.Character
            if char then
                for _, v in ipairs(char:GetChildren()) do
                    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                        v.Size = v.Size * 2
                    end
                end
                toast("Giant mode", "success")
            end
        end)
        button("Tiny", Theme.accent2, function()
            local char = LocalPlayer.Character
            if char then
                for _, v in ipairs(char:GetChildren()) do
                    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                        v.Size = v.Size * 0.5
                    end
                end
                toast("Tiny mode", "success")
            end
        end)

        section("Ragdoll")
        button("Ragdoll Self", Theme.danger, function()
            local h = getHum()
            if h then
                h:ChangeState(Enum.HumanoidStateType.Physics)
                task.delay(3, function()
                    if h and h.Parent then
                        h:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end)
                toast("Ragdolled", "success")
            end
        end)

    elseif name == "Settings" then
        section("Theme")
        button("Purple Theme", Themes.purple.accent, function()
            Theme.accent = Themes.purple.accent
            Theme.accent2 = Themes.purple.accent2
            Glow.BackgroundColor3 = Theme.accent
            Dot.BackgroundColor3 = Theme.accent
            DotGlow.BackgroundColor3 = Theme.accent
            TabIndicator.BackgroundColor3 = Theme.accent
            Scroll.ScrollBarImageColor3 = Theme.accent
            toast("Theme: purple", "success")
            renderTab("Settings")
        end)
        button("Green Theme", Themes.green.accent, function()
            Theme.accent = Themes.green.accent
            Theme.accent2 = Themes.green.accent2
            Glow.BackgroundColor3 = Theme.accent
            Dot.BackgroundColor3 = Theme.accent
            DotGlow.BackgroundColor3 = Theme.accent
            TabIndicator.BackgroundColor3 = Theme.accent
            Scroll.ScrollBarImageColor3 = Theme.accent
            toast("Theme: green", "success")
            renderTab("Settings")
        end)
        button("Red Theme", Themes.red.accent, function()
            Theme.accent = Themes.red.accent
            Theme.accent2 = Themes.red.accent2
            Glow.BackgroundColor3 = Theme.accent
            Dot.BackgroundColor3 = Theme.accent
            DotGlow.BackgroundColor3 = Theme.accent
            TabIndicator.BackgroundColor3 = Theme.accent
            Scroll.ScrollBarImageColor3 = Theme.accent
            toast("Theme: red", "success")
            renderTab("Settings")
        end)
        button("Cyan Theme", Themes.cyan.accent, function()
            Theme.accent = Themes.cyan.accent
            Theme.accent2 = Themes.cyan.accent2
            Glow.BackgroundColor3 = Theme.accent
            Dot.BackgroundColor3 = Theme.accent
            DotGlow.BackgroundColor3 = Theme.accent
            TabIndicator.BackgroundColor3 = Theme.accent
            Scroll.ScrollBarImageColor3 = Theme.accent
            toast("Theme: cyan", "success")
            renderTab("Settings")
        end)

        section("UI Scale")
        slider("Scale %", 60, 150, 100, Theme.accent, function(v)
            local s = v / 100
            Window.Size = UDim2.new(0, 560 * s, 0, 440 * s)
            Window.Position = UDim2.new(0.5, -280 * s, 0.5, -220 * s)
            Glow.Size = Window.Size
        end)

        section("Performance")
        local perfLabel = Instance.new("TextLabel")
        perfLabel.Size = UDim2.new(1, -4, 0, 66)
        perfLabel.BackgroundColor3 = Theme.card
        perfLabel.BorderSizePixel = 0
        perfLabel.Text = "FPS: --  |  Ping: -- ms"
        perfLabel.TextColor3 = Theme.text
        perfLabel.Font = Font
        perfLabel.TextSize = 13
        perfLabel.ZIndex = 3
        perfLabel.LayoutOrder = nextOrder()
        perfLabel.Parent = Scroll
        corner(perfLabel, 10)
        stroke(perfLabel, Theme.border, 1, 0.5)

        local fps, frames, lastUpdate = 0, 0, tick()
        track(RunService.RenderStepped:Connect(function()
            frames = frames + 1
            if tick() - lastUpdate >= 1 then
                fps = frames
                frames = 0
                lastUpdate = tick()
            end
            if perfLabel.Parent then
                local ping = "?"
                pcall(function()
                    ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                perfLabel.Text = string.format("FPS: %d  |  Ping: %s ms", fps, tostring(ping))
            end
        end))

        section("Danger Zone")
        button("Unload Panel", Theme.danger, function()
            stopFly()
            stopNoclip()
            stopInfJump()
            stopSpin()
            stopFreecam()
            setGodmode(false)
            setPlayerESP(false)
            setMoon(false)
            -- ===== NEW =====
            setInvisible(false)
            setInvincible(false)
            restoreTextures()
            resetSkybox()
            -- ===============
            local h = getHum()
            if h then
                h.WalkSpeed = 16
                h.JumpPower = 50
            end
            for _, c in ipairs(Connections) do
                pcall(function() c:Disconnect() end)
            end
            Connections = {}
            TweenService:Create(Window, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
            task.wait(0.15)
            ScreenGui:Destroy()
        end)
    end
end

-- ===================== TAB BUTTONS =====================
local function setActive(name, btn)
    if activeTab == name then return end
    activeTab = name
    TweenService:Create(TabIndicator, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, btn.AbsolutePosition.X - TabBar.AbsolutePosition.X + 4, 0, 4),
        Size = UDim2.new(0, btn.AbsoluteSize.X, 1, -8),
    }):Play()
    for _, b in ipairs(tabButtons) do
        TweenService:Create(b.lbl, TweenInfo.new(0.15), {
            TextColor3 = (b.name == name) and Theme.text or Theme.textDim
        }):Play()
    end
    renderTab(name)
end

for _, t in ipairs(Tabs) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 0, 1, 0)
    b.AutomaticSize = Enum.AutomaticSize.X
    b.BackgroundTransparency = 1
    b.Text = ""
    b.AutoButtonColor = false
    b.ZIndex = 3
    b.Parent = TabScroll
    corner(b, 8)
    padding(b, 6, 6, 10, 10)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = t.icon .. " " .. t.name
    lbl.TextColor3 = Theme.textDim
    lbl.Font = Font
    lbl.TextSize = 13
    lbl.ZIndex = 4
    lbl.Parent = b

    b.MouseButton1Click:Connect(function()
        setActive(t.name, b)
    end)

    table.insert(tabButtons, { name = t.name, btn = b, lbl = lbl })
end

task.defer(function()
    task.wait(0.1)
    local first = tabButtons[1]
    if first then
        setActive(first.name, first.btn)
    end
end)

-- ===================== MINIMIZE / CLOSE =====================
local minimized = false
track(MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local target = minimized and UDim2.new(0, 560, 0, 52) or UDim2.new(0, 560, 0, 440)
    TweenService:Create(Window, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = target}):Play()
    MinimizeBtn.Text = minimized and "▢" or "—"
end))

track(CloseBtn.MouseButton1Click:Connect(function()
    stopFly()
    stopNoclip()
    stopInfJump()
    stopSpin()
    stopFreecam()
    setGodmode(false)
    setPlayerESP(false)
    setMoon(false)
    -- ===== NEW =====
    setInvisible(false)
    setInvincible(false)
    restoreTextures()
    resetSkybox()
    -- ===============
    local h = getHum()
    if h then
        h.WalkSpeed = 16
        h.JumpPower = 50
    end
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    Connections = {}
    TweenService:Create(Window, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
    task.wait(0.15)
    ScreenGui:Destroy()
end))

-- ===================== WELCOME =====================
toast("Nova Admin v2 loaded", "success")
task.delay(0.4, function()
    toast("7 tabs ready", "info")
end)
