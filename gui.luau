local Library = { Flags = {}, Connections = {}, ToggleKey = Enum.KeyCode.RightControl }
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local ParentGui = (gethui and gethui()) or (pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui")) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local function Make(Class, Props)
    local Obj = Instance.new(Class)
    for k, v in pairs(Props) do Obj[k] = v end
    return Obj
end

-- Sistem Config & Unload
function Library:SaveConfig(Name)
    if writefile then writefile(Name..".json", Http:JSONEncode(Library.Flags)) end
    Library:Notify("Config Saved", "Settings applied.", 3)
end

function Library:LoadConfig(Name)
    if readfile and isfile and isfile(Name..".json") then
        local data = Http:JSONDecode(readfile(Name..".json"))
        for k, v in pairs(data) do Library.Flags[k] = v end
        Library:Notify("Config Loaded", "Settings loaded.", 3)
    end
end

function Library:Unload()
    if Library.UI then Library.UI:Destroy() end
    for _, conn in ipairs(Library.Connections) do conn:Disconnect() end
end

-- Container Notifikasi
local NotifContainer = Make("Frame", {Parent = ParentGui, BackgroundTransparency = 1, Position = UDim2.new(1, -260, 1, -150), Size = UDim2.new(0, 250, 0, 400), AnchorPoint = Vector2.new(0, 1)})
Make("UIListLayout", {Parent = NotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10)})

function Library:Notify(Title, Content, Duration)
    local NF = Make("Frame", {Parent = NotifContainer, BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1})
    Make("UICorner", {Parent = NF, CornerRadius = UDim.new(0, 8)})
    local TL = Make("TextLabel", {Parent = NF, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.GothamSemibold, Text = Title, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1})
    local CL = Make("TextLabel", {Parent = NF, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 25), Size = UDim2.new(1, -20, 0, 25), Font = Enum.Font.Gotham, Text = Content, TextColor3 = Color3.fromRGB(200,200,200), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextTransparency = 1})
    
    TS:Create(NF, TweenInfo.new(0.4), {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}):Play(); TS:Create(TL, TweenInfo.new(0.4), {TextTransparency = 0}):Play(); TS:Create(CL, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    task.delay(Duration or 3, function()
        if not NF then return end
        TS:Create(NF, TweenInfo.new(0.4), {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}):Play(); TS:Create(TL, TweenInfo.new(0.4), {TextTransparency = 1}):Play(); TS:Create(CL, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        task.wait(0.4); NF:Destroy()
    end)
end

function Library:CreateWindow(Name)
    if ParentGui:FindFirstChild("MacOS_UI") then ParentGui.MacOS_UI:Destroy() end
    local SG = Make("ScreenGui", {Parent = ParentGui, Name = "MacOS_UI", ResetOnSpawn = false})
    Library.UI = SG; NotifContainer.Parent = SG
    
    -- Watermark HUD
    local WMFrame = Make("Frame", {Parent = SG, BackgroundColor3 = Color3.fromRGB(30,30,30), Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 250, 0, 25)})
    Make("UICorner", {Parent = WMFrame, CornerRadius = UDim.new(0, 6)})
    Make("UIStroke", {Parent = WMFrame, Color = Color3.fromRGB(60,60,60), Thickness = 1})
    local WMLabel = Make("TextLabel", {Parent = WMFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), Font = Enum.Font.Gotham, Text = Name .. " | FPS: 0 | Ping: 0ms", TextColor3 = Color3.fromRGB(220,220,220), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
    
    local LastTick, FrameCount = tick(), 0
    table.insert(Library.Connections, RunService.RenderStepped:Connect(function()
        FrameCount = FrameCount + 1
        if tick() - LastTick >= 1 then
            local Ping = string.split(string.split(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString(), " ")[1], ".")[1]
            WMLabel.Text = Name .. " | FPS: " .. FrameCount .. " | Ping: " .. (Ping or "0") .. "ms"
            FrameCount, LastTick = 0, tick()
        end
    end))

    -- Main UI
    local Main = Make("Frame", {Parent = SG, BackgroundColor3 = Color3.fromRGB(30,30,30), Position = UDim2.new(0.5, -250, 0.5, -175), Size = UDim2.new(0, 500, 0, 350), ClipsDescendants = true})
    Make("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 10)})
    local Top = Make("Frame", {Parent = Main, BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(1, 0, 0, 30)})
    Make("UICorner", {Parent = Top, CornerRadius = UDim.new(0, 10)})
    Make("Frame", {Parent = Top, BackgroundColor3 = Color3.fromRGB(40,40,40), Position = UDim2.new(0,0,0.5,0), Size = UDim2.new(1,0,0.5,0), BorderSizePixel = 0})
    
    Make("UICorner", {Parent = Make("Frame", {Parent = Top, BackgroundColor3 = Color3.fromRGB(255,95,86), Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,10,0.5,-6)}), CornerRadius = UDim.new(1,0)})
    Make("UICorner", {Parent = Make("Frame", {Parent = Top, BackgroundColor3 = Color3.fromRGB(255,189,46), Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,28,0.5,-6)}), CornerRadius = UDim.new(1,0)})
    Make("UICorner", {Parent = Make("Frame", {Parent = Top, BackgroundColor3 = Color3.fromRGB(39,201,63), Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,46,0.5,-6)}), CornerRadius = UDim.new(1,0)})
    Make("TextLabel", {Parent = Top, BackgroundTransparency = 1, Position = UDim2.new(0,70,0,0), Size = UDim2.new(1,-70,1,0), Font = Enum.Font.GothamSemibold, Text = Name, TextColor3 = Color3.fromRGB(200,200,200), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})

    local drag, dragStart, startPos
    table.insert(Library.Connections, Top.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; dragStart = i.Position; startPos = Main.Position end end))
    table.insert(Library.Connections, UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (i.Position - dragStart).X, startPos.Y.Scale, startPos.Y.Offset + (i.Position - dragStart).Y) end end))
    table.insert(Library.Connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end))
    table.insert(Library.Connections, UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Library.ToggleKey then Main.Visible = not Main.Visible end end))

    local Sidebar = Make("ScrollingFrame", {Parent = Main, BackgroundColor3 = Color3.fromRGB(35,35,35), Position = UDim2.new(0,0,0,30), Size = UDim2.new(0,130,1,-30), ScrollBarThickness = 2, BorderSizePixel = 0})
    local SideLayout = Make("UIListLayout", {Parent = Sidebar, Padding = UDim.new(0, 5)})
    local Content = Make("Frame", {Parent = Main, BackgroundTransparency = 1, Position = UDim2.new(0,135,0,35), Size = UDim2.new(1,-140,1,-40)})

    SideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Sidebar.CanvasSize = UDim2.new(0, 0, 0, SideLayout.AbsoluteContentSize.Y + 10) end)

    local WinObj, FirstTab = {}, true

    function WinObj:CreateTab(TabName)
        local TBtn = Make("TextButton", {Parent = Sidebar, BackgroundColor3 = Color3.fromRGB(45,45,45), BackgroundTransparency = FirstTab and 0 or 1, Size = UDim2.new(1,-10,0,30), Position = UDim2.new(0,5,0,0), Font = Enum.Font.Gotham, Text = TabName, TextColor3 = FirstTab and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150), TextSize = 13})
        Make("UICorner", {Parent = TBtn, CornerRadius = UDim.new(0, 6)})
        local TContent = Make("ScrollingFrame", {Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), ScrollBarThickness = 2, Visible = FirstTab, BorderSizePixel = 0})
        local CntLayout = Make("UIListLayout", {Parent = TContent, Padding = UDim.new(0, 8)})
        
        CntLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TContent.CanvasSize = UDim2.new(0, 0, 0, CntLayout.AbsoluteContentSize.Y + 10) end)
        FirstTab = false

        TBtn.MouseButton1Click:Connect(function()
            for _, c in ipairs(Sidebar:GetChildren()) do if c:IsA("TextButton") then TS:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150,150,150)}):Play() end end
            for _, c in ipairs(Content:GetChildren()) do if c:IsA("ScrollingFrame") then c.Visible = false end end
            TS:Create(TBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(255,255,255)}):Play(); TContent.Visible = true
        end)

        local Elements = {}

        function Elements:CreateSection(Name)
            local Sec = Make("Frame", {Parent = TContent, BackgroundTransparency = 1, Size = UDim2.new(1,-10,0,25)})
            Make("TextLabel", {Parent = Sec, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Font = Enum.Font.GothamBold, Text = "  " .. Name, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
            Make("Frame", {Parent = Sec, BackgroundColor3 = Color3.fromRGB(60,60,60), Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,0), BorderSizePixel = 0})
        end

        function Elements:CreateLabel(Text)
            Make("TextLabel", {Parent = TContent, BackgroundTransparency = 1, Size = UDim2.new(1,-10,0,20), Font = Enum.Font.GothamSemibold, Text = "  " .. Text, TextColor3 = Color3.fromRGB(200,200,200), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
        end

        function Elements:CreateParagraph(Title, Desc)
            local PF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(1,-10,0,0)})
            Make("UICorner", {Parent = PF, CornerRadius = UDim.new(0, 6)})
            local PTitle = Make("TextLabel", {Parent = PF, BackgroundTransparency = 1, Size = UDim2.new(1,-10,0,20), Position = UDim2.new(0,10,0,5), Font = Enum.Font.GothamBold, Text = Title, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
            local PDesc = Make("TextLabel", {Parent = PF, BackgroundTransparency = 1, Size = UDim2.new(1,-20,0,0), Position = UDim2.new(0,10,0,25), Font = Enum.Font.Gotham, Text = Desc, TextColor3 = Color3.fromRGB(180,180,180), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})
            
            -- Auto Resize Paragraph Height
            local function UpdateSize()
                PDesc.Size = UDim2.new(1, -20, 0, PDesc.TextBounds.Y)
                PF.Size = UDim2.new(1, -10, 0, PDesc.TextBounds.Y + 35)
            end
            UpdateSize(); PDesc:GetPropertyChangedSignal("TextBounds"):Connect(UpdateSize)
        end

        function Elements:CreateButton(Name, Call)
            local Btn = Make("TextButton", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35), Font = Enum.Font.Gotham, Text = "  " .. Name, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
            Make("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
            Btn.MouseButton1Click:Connect(function() pcall(Call); TS:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play(); task.wait(0.1); TS:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play() end)
        end

        function Elements:CreateToggle(Flag, Name, Call)
            Library.Flags[Flag] = Library.Flags[Flag] or false
            local TF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35)})
            Make("UICorner", {Parent = TF, CornerRadius = UDim.new(0, 6)})
            Make("TextLabel", {Parent = TF, BackgroundTransparency = 1, Size = UDim2.new(1,-50,1,0), Position = UDim2.new(0,10,0,0), Font = Enum.Font.Gotham, Text = Name, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
            local Sw = Make("TextButton", {Parent = TF, BackgroundColor3 = Library.Flags[Flag] and Color3.fromRGB(39,201,63) or Color3.fromRGB(60,60,60), Position = UDim2.new(1,-45,0.5,-10), Size = UDim2.new(0,36,0,20), Text = ""})
            Make("UICorner", {Parent = Sw, CornerRadius = UDim.new(1, 0)})
            local Ind = Make("Frame", {Parent = Sw, BackgroundColor3 = Library.Flags[Flag] and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200), Position = Library.Flags[Flag] and UDim2.new(0,18,0.5,-8) or UDim2.new(0,2,0.5,-8), Size = UDim2.new(0,16,0,16)})
            Make("UICorner", {Parent = Ind, CornerRadius = UDim.new(1, 0)})
            
            local function Set(state)
                Library.Flags[Flag] = state; pcall(Call, state)
                TS:Create(Ind, TweenInfo.new(0.2), {Position = state and UDim2.new(0,18,0.5,-8) or UDim2.new(0,2,0.5,-8), BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)}):Play()
                TS:Create(Sw, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(39,201,63) or Color3.fromRGB(60,60,60)}):Play()
            end
            Sw.MouseButton1Click:Connect(function() Set(not Library.Flags[Flag]) end)
            if Library.Flags[Flag] then pcall(Call, true) end
        end

        function Elements:CreateSlider(Flag, Name, Min, Max, Def, Call)
            Library.Flags[Flag] = Library.Flags[Flag] or Def
            local SF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,45)})
            Make("UICorner", {Parent = SF, CornerRadius = UDim.new(0, 6)})
            Make("TextLabel", {Parent = SF, BackgroundTransparency = 1, Position = UDim2.new(0,10,0,5), Size = UDim2.new(1,-20,0,15), Font = Enum.Font.Gotham, Text = Name, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
            local Val = Make("TextLabel", {Parent = SF, BackgroundTransparency = 1, Position = UDim2.new(1,-50,0,5), Size = UDim2.new(0,40,0,15), Font = Enum.Font.Gotham, Text = tostring(Library.Flags[Flag]), TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right})
            local Area = Make("TextButton", {Parent = SF, BackgroundTransparency = 1, Position = UDim2.new(0,10,0,25), Size = UDim2.new(1,-20,0,10), Text = ""})
            local BG = Make("Frame", {Parent = Area, BackgroundColor3 = Color3.fromRGB(30,30,30), Size = UDim2.new(1,0,1,0)})
            Make("UICorner", {Parent = BG, CornerRadius = UDim.new(1,0)})
            local Fill = Make("Frame", {Parent = BG, BackgroundColor3 = Color3.fromRGB(10,132,255), Size = UDim2.new((Library.Flags[Flag]-Min)/(Max-Min),0,1,0)})
            Make("UICorner", {Parent = Fill, CornerRadius = UDim.new(1,0)})

            local drag
            local function update(input)
                local pos = math.clamp((input.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X, 0, 1)
                local v = math.floor(Min + (pos * (Max - Min)))
                Library.Flags[Flag] = v
                TS:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos,0,1,0)}):Play()
                Val.Text = tostring(v); pcall(Call, v)
            end
            Area.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; update(i) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
            UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
        end

        function Elements:CreateDropdown(Flag, Name, Opts, Call)
            Library.Flags[Flag] = Library.Flags[Flag] or ""
            local DF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35), ClipsDescendants = true})
            Make("UICorner", {Parent = DF, CornerRadius = UDim.new(0, 6)})
            local DBtn = Make("TextButton", {Parent = DF, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,35), Font = Enum.Font.Gotham, Text = "  " .. Name .. " : " .. (Library.Flags[Flag] == "" and "-" or tostring(Library.Flags[Flag])), TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left})
            local DScroll = Make("ScrollingFrame", {Parent = DF, BackgroundTransparency = 1, Position = UDim2.new(0,0,0,35), Size = UDim2.new(1,0,1,-35), ScrollBarThickness = 2, BorderSizePixel = 0})
            Make("UIListLayout", {Parent = DScroll})

            local open = false
            DBtn.MouseButton1Click:Connect(function()
                open = not open
                TS:Create(DF, TweenInfo.new(0.2), {Size = open and UDim2.new(1,-10,0,35 + math.clamp(#DScroll:GetChildren()-1, 0, 4)*25) or UDim2.new(1,-10,0,35)}):Play()
            end)

            local DropObj = {}
            function DropObj:Refresh(NewOpts)
                for _, child in ipairs(DScroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, o in ipairs(NewOpts) do
                    local OBtn = Make("TextButton", {Parent = DScroll, BackgroundColor3 = Color3.fromRGB(55,55,55), Size = UDim2.new(1,0,0,25), Font = Enum.Font.Gotham, Text = "  " .. tostring(o), TextColor3 = Color3.fromRGB(200,200,200), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0})
                    OBtn.MouseButton1Click:Connect(function() Library.Flags[Flag] = o; DBtn.Text = "  " .. Name .. " : " .. tostring(o); open = false; TS:Create(DF, TweenInfo.new(0.2), {Size = UDim2.new(1,-10,0,35)}):Play(); pcall(Call, o) end)
                end
                if open then TS:Create(DF, TweenInfo.new(0.2), {Size = UDim2.new(1,-10,0,35 + math.clamp(#NewOpts, 0, 4)*25)}):Play() end
            end
            
            DropObj:Refresh(Opts)
            return DropObj
        end

        return Elements
    end return WinObj
end

return Library
