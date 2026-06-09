--[[
╔══════════════════════════════════════════════════════════════╗
║                        LuauUI v1.1                           ║
║         A complete, aesthetic, lightweight UI library        ║
║         Compatible with Roblox LocalScript & Executors       ║
╚══════════════════════════════════════════════════════════════╝
--]]

-- ─────────────────────────────────────────
--  SERVICES
-- ─────────────────────────────────────────
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local HttpService    = game:GetService("HttpService")

local LocalPlayer   = Players.LocalPlayer

-- ─────────────────────────────────────────
--  DESIGN TOKENS
-- ─────────────────────────────────────────
local T = {
    -- Colors
    Void        = Color3.fromRGB(10,  10,  15),
    Surface     = Color3.fromRGB(18,  18,  26),
    Elevated    = Color3.fromRGB(30,  30,  46),
    Border      = Color3.fromRGB(50,  50,  70),
    Accent      = Color3.fromRGB(124, 106, 247),
    AccentHover = Color3.fromRGB(145, 130, 255),
    Mint        = Color3.fromRGB(78,  205, 196),
    Danger      = Color3.fromRGB(255, 85,  100),
    Success     = Color3.fromRGB(80,  220, 130),
    Warning     = Color3.fromRGB(255, 180, 50),
    TextPrimary = Color3.fromRGB(248, 248, 242),
    TextMuted   = Color3.fromRGB(140, 140, 165),
    TextDisabled= Color3.fromRGB(80,  80,  100),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0,   0,   0),

    -- Sizing
    Radius      = { Sm = 4, Md = 8, Lg = 12, Xl = 16, Full = 100 },
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
    FontMono    = Enum.Font.Code,

    -- Tween speeds
    Fast   = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Medium = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow   = TweenInfo.new(0.40, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.35, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
}

-- ─────────────────────────────────────────
--  UTILITIES
-- ─────────────────────────────────────────
local Util = {}

function Util.Tween(obj, info, props)
    return TweenService:Create(obj, info, props):Play()
end

function Util.Signal()
    local callbacks = {}
    local signal = {}
    function signal:Connect(fn)
        table.insert(callbacks, fn)
        return { Disconnect = function() for i,v in ipairs(callbacks) do if v==fn then table.remove(callbacks,i) break end end end }
    end
    function signal:Fire(...)
        for _, fn in ipairs(callbacks) do fn(...) end
    end
    return signal
end

function Util.Make(cls, props, parent)
    local obj = Instance.new(cls)
    for k, v in pairs(props) do
        if k ~= "Parent" then obj[k] = v end
    end
    if parent then obj.Parent = parent end
    return obj
end

function Util.RippleEffect(btn, color)
    color = color or Color3.fromRGB(255,255,255)
    btn.ClipsDescendants = true
    btn.MouseButton1Click:Connect(function()
        local pos = UserInputService:GetMouseLocation()
        local abs = btn.AbsolutePosition
        local rel = Vector2.new(pos.X - abs.X, pos.Y - abs.Y - 36) -- Gui Inset compensation
        local circle = Util.Make("Frame", {
            Size = UDim2.new(0,0,0,0),
            Position = UDim2.new(0, rel.X, 0, rel.Y),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.7,
            BorderSizePixel = 0,
        }, btn)
        Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, circle)
        local size = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.5
        TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(0.5, function() circle:Destroy() end)
    end)
end

function Util.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ─────────────────────────────────────────
--  SCREEN GUI ROOT
-- ─────────────────────────────────────────
local targetParent = Players.LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
    targetParent = (gethui and gethui()) or game:GetService("CoreGui")
end)

local ScreenGui = Util.Make("ScreenGui", {
    Name = "LuauUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, targetParent)

-- Notification container
local NotifyContainer = Util.Make("Frame", {
    Name = "NotifyContainer",
    Size = UDim2.new(0, 280, 1, 0),
    Position = UDim2.new(1, -290, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, ScreenGui)
Util.Make("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8),
}, NotifyContainer)
Util.Make("UIPadding", {
    PaddingBottom = UDim.new(0, 12),
}, NotifyContainer)

-- ─────────────────────────────────────────
--  LuauUI MODULE
-- ─────────────────────────────────────────
local LuauUI = {
    _version = "1.1.0",
    Theme = T,
    Util = Util,
}

-- ══════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════
LuauUI.Window = {}
LuauUI.Window.__index = LuauUI.Window

function LuauUI.Window.new(title, options)
    options = options or {}
    local self = setmetatable({}, LuauUI.Window)
    self.Open = true

    local w = math.min(options.Width  or 340, 800)
    local h = math.min(options.Height or 420, 700)

    self.Root = Util.Make("Frame", {
        Name = "Window_" .. title,
        Size = UDim2.new(0, w, 0, h),
        Position = options.Position or UDim2.new(0.5, -w/2, 0.5, -h/2),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, ScreenGui)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Lg) }, self.Root)
    Util.Make("UIStroke", { Color = T.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, self.Root)

    local shadow = Util.Make("Frame", {
        Name = "Shadow",
        Size = UDim2.new(1, 16, 1, 16),
        Position = UDim2.new(0, -8, 0, -8),
        BackgroundColor3 = T.Black,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = self.Root.ZIndex - 1,
    }, self.Root)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Xl) }, shadow)

    self.TitleBar = Util.Make("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.Void,
        BorderSizePixel = 0,
    }, self.Root)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Lg) }, self.TitleBar)
    Util.Make("Frame", { Size = UDim2.new(1, 0, 0, T.Radius.Lg), Position = UDim2.new(0,0,1,-T.Radius.Lg), BackgroundColor3 = T.Void, BorderSizePixel = 0 }, self.TitleBar)
    Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0,0,1,0), BackgroundColor3 = T.Border, BorderSizePixel = 0 }, self.TitleBar)

    local dot = Util.Make("Frame", {
        Name = "Dot",
        Size = UDim2.new(0, 7, 0, 7),
        Position = UDim2.new(0, 14, 0.5, -3.5),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
    }, self.TitleBar)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, dot)

    self.TitleLabel = Util.Make("TextLabel", {
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.new(0, 28, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = T.TextPrimary,
        Font = T.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, self.TitleBar)

    local closeBtn = Util.Make("TextButton", {
        Name = "CloseBtn",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0.5, -14),
        BackgroundColor3 = T.Elevated,
        Text = "✕",
        TextColor3 = T.TextMuted,
        Font = T.Font,
        TextSize = 12,
        BorderSizePixel = 0,
    }, self.TitleBar)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Sm) }, closeBtn)
    closeBtn.MouseEnter:Connect(function() Util.Tween(closeBtn, T.Fast, { BackgroundColor3 = T.Danger, TextColor3 = T.White }) end)
    closeBtn.MouseLeave:Connect(function() Util.Tween(closeBtn, T.Fast, { BackgroundColor3 = T.Elevated, TextColor3 = T.TextMuted }) end)
    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    local minBtn = Util.Make("TextButton", {
        Name = "MinBtn",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -68, 0.5, -14),
        BackgroundColor3 = T.Elevated,
        Text = "–",
        TextColor3 = T.TextMuted,
        Font = T.FontBold,
        TextSize = 14,
        BorderSizePixel = 0,
    }, self.TitleBar)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Sm) }, minBtn)
    minBtn.MouseEnter:Connect(function() Util.Tween(minBtn, T.Fast, { BackgroundColor3 = T.Warning, TextColor3 = T.Black }) end)
    minBtn.MouseLeave:Connect(function() Util.Tween(minBtn, T.Fast, { BackgroundColor3 = T.Elevated, TextColor3 = T.TextMuted }) end)
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local targetH = minimized and 42 or h
        Util.Tween(self.Root, T.Medium, { Size = UDim2.new(0, w, 0, targetH) })
    end)

    self.Frame = Util.Make("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -43),
        Position = UDim2.new(0, 0, 0, 43),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, self.Root)
    Util.Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, self.Frame)
    Util.Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, self.Frame)

    Util.MakeDraggable(self.Root, self.TitleBar)

    self.Root.Size = UDim2.new(0, 0, 0, 0)
    self.Root.Position = UDim2.new(0.5, 0, 0.5, 0)
    Util.Tween(self.Root, T.Spring, { Size = UDim2.new(0, w, 0, h), Position = UDim2.new(0.5, -w/2, 0.5, -h/2) })

    return self
end

function LuauUI.Window:Destroy()
    local root = self.Root
    Util.Tween(root, T.Medium, { Size = UDim2.new(0, root.AbsoluteSize.X * 0.92, 0, root.AbsoluteSize.Y * 0.92), BackgroundTransparency = 1 })
    task.delay(0.22, function() root:Destroy() end)
end

function LuauUI.Window:SetTitle(text) self.TitleLabel.Text = text end

-- ══════════════════════════════════════════
--  BUTTON
-- ══════════════════════════════════════════
LuauUI.Button = {}
LuauUI.Button.__index = LuauUI.Button

function LuauUI.Button.new(text, parent, variant)
    variant = variant or "primary"
    local self = setmetatable({}, LuauUI.Button)
    self.OnClick = Util.Signal()

    local bgColor, textColor, strokeColor
    if variant == "primary" then bgColor, textColor, strokeColor = T.Accent, T.White, T.Accent
    elseif variant == "ghost" then bgColor, textColor, strokeColor = T.Surface, T.TextPrimary, T.Border
    elseif variant == "danger" then bgColor, textColor, strokeColor = Color3.fromRGB(60,15,20), T.Danger, T.Danger
    elseif variant == "success" then bgColor, textColor, strokeColor = Color3.fromRGB(10,50,30), T.Success, T.Success
    elseif variant == "mint" then bgColor, textColor, strokeColor = Color3.fromRGB(5,45,43), T.Mint, T.Mint
    end

    self.Button = Util.Make("TextButton", {
        Name = "Btn_" .. text,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = bgColor,
        Text = text,
        TextColor3 = textColor,
        Font = T.FontBold,
        TextSize = 13,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, self.Button)
    if strokeColor then Util.Make("UIStroke", { Color = strokeColor, Thickness = 1, Transparency = (variant == "primary") and 1 or 0.5 }, self.Button) end

    local hoverColor = (variant == "primary") and T.AccentHover or (variant == "danger") and Color3.fromRGB(80,20,28) or (variant == "success") and Color3.fromRGB(15,65,40) or (variant == "mint") and Color3.fromRGB(10,60,58) or T.Elevated

    self.Button.MouseEnter:Connect(function() Util.Tween(self.Button, T.Fast, { BackgroundColor3 = hoverColor }) end)
    self.Button.MouseLeave:Connect(function() Util.Tween(self.Button, T.Fast, { BackgroundColor3 = bgColor }) end)
    self.Button.MouseButton1Down:Connect(function() Util.Tween(self.Button, T.Fast, { Size = UDim2.new(1, 0, 0, 33) }) end)
    self.Button.MouseButton1Up:Connect(function() Util.Tween(self.Button, T.Spring, { Size = UDim2.new(1, 0, 0, 36) }) end)
    self.Button.MouseButton1Click:Connect(function() self.OnClick:Fire() end)
    Util.RippleEffect(self.Button, T.White)

    return self
end

function LuauUI.Button:SetText(text) self.Button.Text = text end
function LuauUI.Button:SetDisabled(state)
    self.Button.Active = not state
    self.Button.TextTransparency = state and 0.5 or 0
    self.Button.BackgroundTransparency = state and 0.5 or 0
end

-- ══════════════════════════════════════════
--  TOGGLE
-- ══════════════════════════════════════════
LuauUI.Toggle = {}
LuauUI.Toggle.__index = LuauUI.Toggle

function LuauUI.Toggle.new(text, parent, default)
    local self = setmetatable({}, LuauUI.Toggle)
    self.Value = default or false
    self.OnChanged = Util.Signal()

    local row = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Elevated, BorderSizePixel = 0 }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, row)

    Util.Make("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = T.TextPrimary, Font = T.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)

    local track = Util.Make("Frame", { Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -52, 0.5, -11), BackgroundColor3 = self.Value and T.Accent or T.Border, BorderSizePixel = 0 }, row)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, track)

    local thumb = Util.Make("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = self.Value and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8), BackgroundColor3 = T.White, BorderSizePixel = 0 }, track)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, thumb)

    local btn = Util.Make("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "" }, row)

    local function update()
        Util.Tween(track, T.Fast, { BackgroundColor3 = self.Value and T.Accent or T.Border })
        Util.Tween(thumb, T.Fast, { Position = self.Value and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) })
    end

    btn.MouseButton1Click:Connect(function()
        self.Value = not self.Value
        update()
        self.OnChanged:Fire(self.Value)
    end)
    update()

    self.Row = row
    return self
end

function LuauUI.Toggle:Set(state)
    self.Value = state
    Util.Tween(self.Row.Track, T.Fast, { BackgroundColor3 = self.Value and T.Accent or T.Border })
    Util.Tween(self.Row.Track.Thumb, T.Fast, { Position = self.Value and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) })
end

-- ══════════════════════════════════════════
--  SLIDER
-- ══════════════════════════════════════════
LuauUI.Slider = {}
LuauUI.Slider.__index = LuauUI.Slider

function LuauUI.Slider.new(text, parent, min, max, default)
    min, max, default = min or 0, max or 100, default or 50
    local self = setmetatable({}, LuauUI.Slider)
    self.Value = default
    self.OnChanged = Util.Signal()
    self.Min, self.Max = min, max

    local container = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.Elevated, BorderSizePixel = 0 }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, container)

    Util.Make("TextLabel", { Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1, Text = text, TextColor3 = T.TextPrimary, Font = T.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, container)
    local valLabel = Util.Make("TextLabel", { Size = UDim2.new(0.4, -12, 0, 20), Position = UDim2.new(0.6, 0, 0, 8), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = T.Accent, Font = T.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right }, container)

    local trackBg = Util.Make("Frame", { Size = UDim2.new(1, -24, 0, 4), Position = UDim2.new(0, 12, 0, 36), BackgroundColor3 = T.Border, BorderSizePixel = 0 }, container)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, trackBg)

    local fill = Util.Make("Frame", { Size = UDim2.new((default-min)/(max-min), 0, 1, 0), BackgroundColor3 = T.Accent, BorderSizePixel = 0 }, trackBg)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, fill)

    local thumb = Util.Make("Frame", { Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((default-min)/(max-min), 0, 0.5, 0), BackgroundColor3 = T.White, BorderSizePixel = 0 }, trackBg)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, thumb)
    Util.Make("UIStroke", { Color = T.Accent, Thickness = 2 }, thumb)

    local sliding = false
    local function setFromPos(x)
        local abs = trackBg.AbsolutePosition.X
        local w   = trackBg.AbsoluteSize.X
        local t   = math.clamp((x - abs) / w, 0, 1)
        local val = math.floor(min + t * (max - min) + 0.5)
        self.Value = val
        valLabel.Text = tostring(val)
        Util.Tween(fill,  T.Fast, { Size = UDim2.new(t, 0, 1, 0) })
        Util.Tween(thumb, T.Fast, { Position = UDim2.new(t, 0, 0.5, 0) })
        self.OnChanged:Fire(val)
    end

    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromPos(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            setFromPos(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    self.Container = container
    self.ValueLabel = valLabel
    return self
end

function LuauUI.Slider:Set(val)
    val = math.clamp(val, self.Min, self.Max)
    self.Value = val
    self.OnChanged:Fire(val)
end

-- ══════════════════════════════════════════
--  DROPDOWN
-- ══════════════════════════════════════════
LuauUI.Dropdown = {}
LuauUI.Dropdown.__index = LuauUI.Dropdown

function LuauUI.Dropdown.new(text, parent, options, default)
    local self = setmetatable({}, LuauUI.Dropdown)
    self.Value = default or (options and options[1]) or ""
    self.OnChanged = Util.Signal()
    self._open = false

    local wrapper = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = false }, parent)
    local header = Util.Make("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.Elevated, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, wrapper)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, header)
    Util.Make("UIStroke", { Color = T.Border, Thickness = 1 }, header)

    Util.Make("TextLabel", { Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = T.TextMuted, Font = T.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, header)
    self.Selected = Util.Make("TextLabel", { Size = UDim2.new(0.5, -40, 1, 0), Position = UDim2.new(0.45, 0, 0, 0), BackgroundTransparency = 1, Text = self.Value, TextColor3 = T.TextPrimary, Font = T.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right }, header)
    local arrow = Util.Make("TextLabel", { Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -28, 0, 0), BackgroundTransparency = 1, Text = "▾", TextColor3 = T.Accent, Font = T.Font, TextSize = 14 }, header)

    self.List = Util.Make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = T.Elevated,
        BorderSizePixel = 0,
        ZIndex = 10,
        Visible = false,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, wrapper)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, self.List)
    Util.Make("UIStroke", { Color = T.Border, Thickness = 1 }, self.List)
    self._listLayout = Util.Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, self.List)

    header.MouseButton1Click:Connect(function()
        self._open = not self._open
        local numItems = #(self.List:GetChildren()) - 1
        local listH = math.min(numItems, 5) * 32
        
        if self._open then
            self.List.Visible = true
            Util.Tween(self.List, T.Medium, { Size = UDim2.new(1,0,0,listH) })
            Util.Tween(arrow, T.Fast, { Rotation = 180 })
        else
            Util.Tween(self.List, T.Medium, { Size = UDim2.new(1,0,0,0) })
            Util.Tween(arrow, T.Fast, { Rotation = 0 })
            task.delay(0.22, function() self.List.Visible = false end)
        end
    end)

    header.MouseEnter:Connect(function() Util.Tween(header, T.Fast, { BackgroundColor3 = T.Border }) end)
    header.MouseLeave:Connect(function() Util.Tween(header, T.Fast, { BackgroundColor3 = T.Elevated }) end)

    self.Wrapper = wrapper
    self:Refresh(options or {})
    return self
end

function LuauUI.Dropdown:Refresh(options)
    for _, child in ipairs(self.List:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    if not table.find(options, self.Value) then
        self.Value = options[1] or "None"
        self.Selected.Text = self.Value
    end

    for _, opt in ipairs(options) do
        local item = Util.Make("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = T.Elevated, Text = "", BorderSizePixel = 0, ZIndex = 11 }, self.List)
        local lbl = Util.Make("TextLabel", { Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = opt, TextColor3 = (opt == self.Value) and T.Accent or T.TextPrimary, Font = T.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11 }, item)
        item.MouseEnter:Connect(function() Util.Tween(item, T.Fast, { BackgroundColor3 = T.Border }) end)
        item.MouseLeave:Connect(function() Util.Tween(item, T.Fast, { BackgroundColor3 = T.Elevated }) end)
        item.MouseButton1Click:Connect(function()
            self.Value = opt
            self.Selected.Text = opt
            self.OnChanged:Fire(opt)
            
            -- Set color for all labels to reset them
            for _, c in ipairs(self.List:GetChildren()) do
                if c:IsA("TextButton") then
                    c:FindFirstChildOfClass("TextLabel").TextColor3 = T.TextPrimary
                end
            end
            lbl.TextColor3 = T.Accent

            self._open = false
            Util.Tween(self.List, T.Medium, { Size = UDim2.new(1,0,0,0) })
            task.delay(0.22, function() self.List.Visible = false end)
        end)
    end
    
    if self._open then
        local listH = math.min(#options, 5) * 32
        Util.Tween(self.List, T.Medium, { Size = UDim2.new(1,0,0,listH) })
    end
end

-- ══════════════════════════════════════════
--  TEXT INPUT
-- ══════════════════════════════════════════
LuauUI.TextInput = {}
LuauUI.TextInput.__index = LuauUI.TextInput

function LuauUI.TextInput.new(placeholder, parent, options)
    options = options or {}
    local self = setmetatable({}, LuauUI.TextInput)
    self.OnChanged = Util.Signal()
    self.OnSubmit  = Util.Signal()

    local frame = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.Void, BorderSizePixel = 0 }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, frame)
    local stroke = Util.Make("UIStroke", { Color = T.Border, Thickness = 1 }, frame)

    local box = Util.Make("TextBox", {
        Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, PlaceholderText = placeholder, PlaceholderColor3 = T.TextDisabled,
        Text = options.Default or "", TextColor3 = T.TextPrimary,
        Font = options.Mono and T.FontMono or T.Font, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = options.ClearOnFocus ~= false, TextEditable = true,
    }, frame)

    box.Focused:Connect(function() Util.Tween(stroke, T.Fast, { Color = T.Accent, Thickness = 1.5 }) end)
    box.FocusLost:Connect(function(enter)
        Util.Tween(stroke, T.Fast, { Color = T.Border, Thickness = 1 })
        if enter then self.OnSubmit:Fire(box.Text) end
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function() self.OnChanged:Fire(box.Text) end)

    self.Frame = frame
    self.Box   = box
    return self
end

function LuauUI.TextInput:GetText() return self.Box.Text end
function LuauUI.TextInput:SetText(t) self.Box.Text = t end

-- ══════════════════════════════════════════
--  LABEL
-- ══════════════════════════════════════════
function LuauUI.Label(text, parent, size, color)
    return Util.Make("TextLabel", { Size = UDim2.new(1, 0, 0, size and (size + 4) or 20), BackgroundTransparency = 1, Text = text, TextColor3 = color or T.TextMuted, Font = T.Font, TextSize = size or 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, parent)
end

-- ══════════════════════════════════════════
--  SEPARATOR
-- ══════════════════════════════════════════
function LuauUI.Separator(parent, label)
    local f = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
    Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = T.Border, BorderSizePixel = 0 }, f)
    if label then
        Util.Make("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundColor3 = T.Surface, Text = "  " .. label .. "  ", TextColor3 = T.TextMuted, Font = T.Font, TextSize = 10, BorderSizePixel = 0 }, f)
    end
    return f
end

-- ══════════════════════════════════════════
--  BADGE
-- ══════════════════════════════════════════
function LuauUI.Badge(text, parent, variant)
    variant = variant or "default"
    local colors = {
        default = { bg = T.Elevated, fg = T.TextMuted },
        accent  = { bg = Color3.fromRGB(35,28,80), fg = T.Accent },
        success = { bg = Color3.fromRGB(10,40,25), fg = T.Success },
        danger  = { bg = Color3.fromRGB(50,10,15), fg = T.Danger },
        warning = { bg = Color3.fromRGB(50,35,5),  fg = T.Warning },
        mint    = { bg = Color3.fromRGB(5,40,38),  fg = T.Mint },
    }
    local c = colors[variant] or colors.default

    local badge = Util.Make("Frame", { Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = c.bg, BorderSizePixel = 0 }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, badge)
    Util.Make("UIStroke", { Color = c.fg, Thickness = 1, Transparency = 0.6 }, badge)
    Util.Make("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8) }, badge)
    Util.Make("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = text, TextColor3 = c.fg, Font = T.FontBold, TextSize = 10 }, badge)
    return badge
end

-- ══════════════════════════════════════════
--  PROGRESS BAR
-- ══════════════════════════════════════════
LuauUI.Progress = {}
LuauUI.Progress.__index = LuauUI.Progress

function LuauUI.Progress.new(text, parent, color)
    color = color or T.Accent
    local self = setmetatable({}, LuauUI.Progress)
    self.Value = 0

    local frame = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = T.Elevated, BorderSizePixel = 0 }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, frame)
    Util.Make("TextLabel", { Size = UDim2.new(0.7, 0, 0, 22), Position = UDim2.new(0, 12, 0, 4), BackgroundTransparency = 1, Text = text, TextColor3 = T.TextPrimary, Font = T.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, frame)
    local pct = Util.Make("TextLabel", { Size = UDim2.new(0.3, -12, 0, 22), Position = UDim2.new(0.7, 0, 0, 4), BackgroundTransparency = 1, Text = "0%", TextColor3 = color, Font = T.FontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right }, frame)
    local track = Util.Make("Frame", { Size = UDim2.new(1, -24, 0, 5), Position = UDim2.new(0, 12, 0, 30), BackgroundColor3 = T.Border, BorderSizePixel = 0 }, frame)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, track)
    self._fill = Util.Make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0 }, track)
    Util.Make("UICorner", { CornerRadius = UDim.new(1,0) }, self._fill)
    
    self._pct = pct
    self.Frame = frame
    return self
end

function LuauUI.Progress:Set(val)
    val = math.clamp(val, 0, 100)
    self.Value = val
    self._pct.Text = val .. "%"
    Util.Tween(self._fill, T.Medium, { Size = UDim2.new(val/100, 0, 1, 0) })
end

-- ══════════════════════════════════════════
--  SECTION (collapsible)
-- ══════════════════════════════════════════
LuauUI.Section = {}
LuauUI.Section.__index = LuauUI.Section

function LuauUI.Section.new(title, parent)
    local self = setmetatable({}, LuauUI.Section)
    self._collapsed = false

    local outer = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Elevated, BorderSizePixel = 0, ClipsDescendants = true }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, outer)
    Util.Make("UIStroke", { Color = T.Border, Thickness = 1 }, outer)

    local header = Util.Make("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = "", BorderSizePixel = 0 }, outer)
    Util.Make("TextLabel", { Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = title, TextColor3 = T.TextPrimary, Font = T.FontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, header)
    local chevron = Util.Make("TextLabel", { Size = UDim2.new(0, 24, 1, 0), Position = UDim2.new(1, -28, 0, 0), BackgroundTransparency = 1, Text = "▾", TextColor3 = T.Accent, Font = T.Font, TextSize = 12 }, header)
    Util.Make("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 34), BackgroundColor3 = T.Border, BorderSizePixel = 0 }, outer)

    self.Frame = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 36), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0 }, outer)
    Util.Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, self.Frame)
    Util.Make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }, self.Frame)

    header.MouseButton1Click:Connect(function()
        self._collapsed = not self._collapsed
        Util.Tween(chevron, T.Fast, { Rotation = self._collapsed and -90 or 0 })
        self.Frame.Visible = not self._collapsed
    end)

    self.Outer = outer
    return self
end

-- ══════════════════════════════════════════
--  TAB
-- ══════════════════════════════════════════
LuauUI.Tab = {}
LuauUI.Tab.__index = LuauUI.Tab

function LuauUI.Tab.new(parent, tabNames)
    local self = setmetatable({}, LuauUI.Tab)
    self.Frames = {}
    self._active = 1

    local container = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
    local bar = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.Elevated, BorderSizePixel = 0 }, container)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, bar)
    Util.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }, bar)

    local buttons = {}
    local contentArea = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 38), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0 }, container)

    local function switchTo(idx)
        for i, f in pairs(self.Frames) do f.Visible = (i == idx) end
        for i, b in ipairs(buttons) do
            Util.Tween(b.bg, T.Fast, { BackgroundColor3 = (i == idx) and T.Accent or Color3.fromRGB(0,0,0) })
            b.lbl.TextColor3 = (i == idx) and T.White or T.TextMuted
            b.bg.BackgroundTransparency = (i == idx) and 0 or 1
        end
        self._active = idx
    end

    for i, name in ipairs(tabNames) do
        local w = 1 / #tabNames
        local btnFrame = Util.Make("Frame", { Size = UDim2.new(w, -2, 1, -6), BackgroundColor3 = T.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = i }, bar)
        Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Sm) }, btnFrame)
        Util.Make("UIPadding", { PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3), PaddingLeft = UDim.new(0,1), PaddingRight = UDim.new(0,1) }, btnFrame)

        local lbl = Util.Make("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = name, TextColor3 = T.TextMuted, Font = T.Font, TextSize = 12 }, btnFrame)
        local btn = Util.Make("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "" }, btnFrame)
        btn.MouseButton1Click:Connect(function() switchTo(i) end)
        table.insert(buttons, { bg = btnFrame, lbl = lbl })

        local frame = Util.Make("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, Visible = (i == 1) }, contentArea)
        Util.Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, frame)
        self.Frames[i] = frame
    end

    switchTo(1)
    self.Container = container
    return self
end

function LuauUI.Tab:GetFrame(idx) return self.Frames[idx] end

-- ══════════════════════════════════════════
--  KEYBIND
-- ══════════════════════════════════════════
LuauUI.Keybind = {}
LuauUI.Keybind.__index = LuauUI.Keybind

function LuauUI.Keybind.new(text, parent, default)
    local self = setmetatable({}, LuauUI.Keybind)
    self.Key = default or Enum.KeyCode.Unknown
    self.OnChanged = Util.Signal()
    self._listening = false

    local row = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Elevated, BorderSizePixel = 0 }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, row)
    Util.Make("TextLabel", { Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = T.TextPrimary, Font = T.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)

    local keyBtn = Util.Make("TextButton", { Size = UDim2.new(0, 90, 0, 26), Position = UDim2.new(1, -100, 0.5, -13), BackgroundColor3 = T.Void, Text = default and default.Name or "None", TextColor3 = T.Accent, Font = T.FontMono, TextSize = 12, BorderSizePixel = 0 }, row)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Sm) }, keyBtn)
    Util.Make("UIStroke", { Color = T.Accent, Thickness = 1, Transparency = 0.5 }, keyBtn)

    keyBtn.MouseButton1Click:Connect(function()
        if self._listening then return end
        self._listening = true
        keyBtn.Text = "..."
        keyBtn.TextColor3 = T.Warning
        local conn
        conn = UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                self.Key = inp.KeyCode
                keyBtn.Text = inp.KeyCode.Name
                keyBtn.TextColor3 = T.Accent
                self._listening = false
                self.OnChanged:Fire(inp.KeyCode)
                conn:Disconnect()
            end
        end)
    end)

    self.Row    = row
    self.KeyBtn = keyBtn
    return self
end

-- ══════════════════════════════════════════
--  NOTIFY (Toast)
-- ══════════════════════════════════════════
LuauUI.Notify = {}

function LuauUI.Notify.send(title, message, variant, duration)
    variant  = variant  or "default"
    duration = duration or 3

    local colors = {
        default = T.Accent,
        success = T.Success,
        danger  = T.Danger,
        warning = T.Warning,
        mint    = T.Mint,
    }
    local accent = colors[variant] or T.Accent

    local card = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = T.Elevated, BorderSizePixel = 0, ClipsDescendants = true }, NotifyContainer)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, card)
    Util.Make("UIStroke", { Color = accent, Thickness = 1, Transparency = 0.5 }, card)

    Util.Make("Frame", { Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 0, 0, 6), BackgroundColor3 = accent, BorderSizePixel = 0 }, card)
    Util.Make("TextLabel", { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 14, 0, 10), BackgroundTransparency = 1, Text = title, TextColor3 = T.TextPrimary, Font = T.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, card)
    Util.Make("TextLabel", { Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 14, 0, 32), BackgroundTransparency = 1, Text = message, TextColor3 = T.TextMuted, Font = T.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, card)

    local pbar = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = accent, BorderSizePixel = 0 }, card)
    TweenService:Create(pbar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

    card.Position = UDim2.new(1, 10, 0, 0)
    Util.Tween(card, T.Spring, { Position = UDim2.new(0, 0, 0, 0) })

    task.delay(duration, function()
        Util.Tween(card, T.Medium, { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0) })
        task.delay(0.25, function() card:Destroy() end)
    end)

    return card
end

-- ══════════════════════════════════════════
--  COLOR PICKER
-- ══════════════════════════════════════════
LuauUI.ColorPicker = {}
LuauUI.ColorPicker.__index = LuauUI.ColorPicker

function LuauUI.ColorPicker.new(text, parent, default)
    local self = setmetatable({}, LuauUI.ColorPicker)
    self.Value = default or Color3.fromRGB(124, 106, 247)
    self.OnChanged = Util.Signal()

    local frame = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Elevated, BorderSizePixel = 0 }, parent)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Md) }, frame)
    Util.Make("TextLabel", { Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = T.TextPrimary, Font = T.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, frame)

    self._swatch = Util.Make("Frame", { Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -74, 0.5, -13), BackgroundColor3 = self.Value, BorderSizePixel = 0 }, frame)
    Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Sm) }, self._swatch)
    Util.Make("UIStroke", { Color = T.Border, Thickness = 1 }, self._swatch)

    local h = self.Value:ToHex()
    self._hexLabel = Util.Make("TextLabel", { Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -68, 0, 0), BackgroundTransparency = 1, Text = "#" .. h:upper():sub(1,6), TextColor3 = T.TextMuted, Font = T.FontMono, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, frame)

    local palette = nil
    local open = false
    local function toggle()
        open = not open
        if open then
            palette = Util.Make("Frame", { Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 1, 2), BackgroundColor3 = T.Void, BorderSizePixel = 0, ZIndex = 20 }, frame)
            Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Sm) }, palette)
            Util.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center }, palette)
            Util.Make("UIPadding", { PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4) }, palette)
            local swatches = {
                Color3.fromRGB(124,106,247), Color3.fromRGB(78,205,196), Color3.fromRGB(255, 85,100), Color3.fromRGB(255,180, 50),
                Color3.fromRGB( 80,220,130), Color3.fromRGB(255,140, 80), Color3.fromRGB(140,180,255), Color3.fromRGB(230, 80,230),
                Color3.fromRGB(248,248,242), Color3.fromRGB(100,100,120),
            }
            for _, col in ipairs(swatches) do
                local s = Util.Make("TextButton", { Size = UDim2.new(0, 18, 0, 18), BackgroundColor3 = col, Text = "", BorderSizePixel = 0, ZIndex = 21 }, palette)
                Util.Make("UICorner", { CornerRadius = UDim.new(0, T.Radius.Sm) }, s)
                s.MouseButton1Click:Connect(function()
                    self.Value = col
                    self._swatch.BackgroundColor3 = col
                    self._hexLabel.Text = "#"..col:ToHex():upper():sub(1,6)
                    self.OnChanged:Fire(col)
                    open = false
                    palette:Destroy()
                    palette = nil
                end)
            end
        else
            if palette then palette:Destroy() palette = nil end
        end
    end

    Util.Make("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "" }, frame).MouseButton1Click:Connect(toggle)

    self.Frame = frame
    return self
end

return LuauUI
