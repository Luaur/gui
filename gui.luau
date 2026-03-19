-- ==========================================
-- KEMPLONGXD HUB V7 - BAGIAN 1
-- Copy semua kode di bawah ini terlebih dahulu
-- ==========================================
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
    for _, conn in ipairs(Library.Connections) do if conn.Disconnect then conn:Disconnect() end end
    table.clear(Library.Connections)
end

local NotifContainer = Make("Frame", {Parent = ParentGui, BackgroundTransparency = 1, Position = UDim2.new(1, -260, 1, -150), Size = UDim2.new(0, 250, 0, 400), AnchorPoint = Vector2.new(0, 1)})
Make("UIListLayout", {Parent = NotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10)})

function Library:Notify(Title, Content, Duration)
    local NF = Make("Frame", {Parent = NotifContainer, BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1, ZIndex = 50})
    Make("UICorner", {Parent = NF, CornerRadius = UDim.new(0, 8)})
    local TL = Make("TextLabel", {Parent = NF, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.GothamSemibold, Text = Title, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 51})
    local CL = Make("TextLabel", {Parent = NF, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 25), Size = UDim2.new(1, -20, 0, 25), Font = Enum.Font.Gotham, Text = Content, TextColor3 = Color3.fromRGB(200,200,200), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextTransparency = 1, ZIndex = 51})
    
    TS:Create(NF, TweenInfo.new(0.4), {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}):Play(); TS:Create(TL, TweenInfo.new(0.4), {TextTransparency = 0}):Play(); TS:Create(CL, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    task.delay(Duration or 3, function()
        if not NF then return end
        TS:Create(NF, TweenInfo.new(0.4), {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}):Play(); TS:Create(TL, TweenInfo.new(0.4), {TextTransparency = 1}):Play(); TS:Create(CL, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        task.wait(0.4); if NF then NF:Destroy() end
    end)
end

function Library:CreateWindow(Config)
    local Name = Config.Name or "MacOS UI"
    local UseKey = Config.UseKey or false
    local ExpectedKey = Config.Key or "ilmuireng1337"

    if ParentGui:FindFirstChild("MacOS_UI") then ParentGui.MacOS_UI:Destroy() end
    local SG = Make("ScreenGui", {Parent = ParentGui, Name = "MacOS_UI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    Library.UI = SG; NotifContainer.Parent = SG

    local function LoadMainUI()
        local WMFrame = Make("Frame", {Parent = SG, BackgroundColor3 = Color3.fromRGB(30,30,30), Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 250, 0, 25), ZIndex = 100})
        Make("UICorner", {Parent = WMFrame, CornerRadius = UDim.new(0, 6)}); Make("UIStroke", {Parent = WMFrame, Color = Color3.fromRGB(60,60,60), Thickness = 1})
        local WMLabel = Make("TextLabel", {Parent = WMFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), Font = Enum.Font.Gotham, Text = Name .. " | FPS: 0 | Ping: 0ms", TextColor3 = Color3.fromRGB(220,220,220), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101})
        
        local LastTick, FrameCount = tick(), 0
        table.insert(Library.Connections, RunService.RenderStepped:Connect(function()
            FrameCount = FrameCount + 1
            if tick() - LastTick >= 1 then
                local pcallSuccess, PingData = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
                local Ping = pcallSuccess and string.split(string.split(PingData, " ")[1], ".")[1] or "0"
                WMLabel.Text = Name .. " | FPS: " .. FrameCount .. " | Ping: " .. Ping .. "ms"
                FrameCount, LastTick = 0, tick()
            end
        end))

        local MainSizeDef, MainSizeMax, MainSizeMin = UDim2.new(0, 500, 0, 350), UDim2.new(0, 650, 0, 420), UDim2.new(0, 500, 0, 30)
        local Main = Make("Frame", {Parent = SG, BackgroundColor3 = Color3.fromRGB(30,30,30), Position = UDim2.new(0.5, -250, 0.5, -175), Size = MainSizeDef, ClipsDescendants = true, ZIndex = 1})
        Make("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 10)})
        local Top = Make("Frame", {Parent = Main, BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(1, 0, 0, 30), ZIndex = 2})
        Make("UICorner", {Parent = Top, CornerRadius = UDim.new(0, 10)})
        Make("Frame", {Parent = Top, BackgroundColor3 = Color3.fromRGB(40,40,40), Position = UDim2.new(0,0,0.5,0), Size = UDim2.new(1,0,0.5,0), BorderSizePixel = 0, ZIndex = 2})
        
        local CloseBtn = Make("TextButton", {Parent = Top, BackgroundColor3 = Color3.fromRGB(255,95,86), Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,10,0.5,-6), ZIndex = 3, Text = ""}); Make("UICorner", {Parent = CloseBtn, CornerRadius = UDim.new(1,0)})
        local MinBtn = Make("TextButton", {Parent = Top, BackgroundColor3 = Color3.fromRGB(255,189,46), Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,28,0.5,-6), ZIndex = 3, Text = ""}); Make("UICorner", {Parent = MinBtn, CornerRadius = UDim.new(1,0)})
        local MaxBtn = Make("TextButton", {Parent = Top, BackgroundColor3 = Color3.fromRGB(39,201,63), Size = UDim2.new(0,12,0,12), Position = UDim2.new(0,46,0.5,-6), ZIndex = 3, Text = ""}); Make("UICorner", {Parent = MaxBtn, CornerRadius = UDim.new(1,0)})
        Make("TextLabel", {Parent = Top, BackgroundTransparency = 1, Position = UDim2.new(0,70,0,0), Size = UDim2.new(1,-70,1,0), Font = Enum.Font.GothamSemibold, Text = Name, TextColor3 = Color3.fromRGB(200,200,200), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})

        local isMinimized, isMaximized = false, false
        CloseBtn.MouseButton1Click:Connect(function() Library:Unload() end)
        MinBtn.MouseButton1Click:Connect(function() isMinimized = not isMinimized; TS:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = isMinimized and MainSizeMin or (isMaximized and MainSizeMax or MainSizeDef)}):Play() end)
        MaxBtn.MouseButton1Click:Connect(function() if isMinimized then return end; isMaximized = not isMaximized; TS:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = isMaximized and MainSizeMax or MainSizeDef}):Play() end)

        local drag, dragStart, startPos
        table.insert(Library.Connections, Top.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; dragStart = i.Position; startPos = Main.Position end end))
        table.insert(Library.Connections, UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end))
        table.insert(Library.Connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end))
        table.insert(Library.Connections, UIS.InputBegan:Connect(function(i, gp) if gp then return end; if i.KeyCode == Library.ToggleKey then Main.Visible = not Main.Visible end end))

        local Sidebar = Make("ScrollingFrame", {Parent = Main, BackgroundColor3 = Color3.fromRGB(35,35,35), Position = UDim2.new(0,0,0,30), Size = UDim2.new(0,130,1,-30), ScrollBarThickness = 2, BorderSizePixel = 0, ZIndex = 2})
        local SideLayout = Make("UIListLayout", {Parent = Sidebar, Padding = UDim.new(0, 5)})
        local Content = Make("Frame", {Parent = Main, BackgroundTransparency = 1, Position = UDim2.new(0,135,0,35), Size = UDim2.new(1,-140,1,-40), ZIndex = 2})
        SideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Sidebar.CanvasSize = UDim2.new(0, 0, 0, SideLayout.AbsoluteContentSize.Y + 10) end)

        local WinObj, FirstTab = {}, true

        function WinObj:CreateTab(TabName)
            local TBtn = Make("TextButton", {Parent = Sidebar, BackgroundColor3 = Color3.fromRGB(45,45,45), BackgroundTransparency = FirstTab and 0 or 1, Size = UDim2.new(1,-10,0,30), Position = UDim2.new(0,5,0,0), Font = Enum.Font.Gotham, Text = TabName, TextColor3 = FirstTab and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150), TextSize = 13, ZIndex = 3})
            Make("UICorner", {Parent = TBtn, CornerRadius = UDim.new(0, 6)})
            local TContent = Make("ScrollingFrame", {Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), ScrollBarThickness = 2, Visible = FirstTab, BorderSizePixel = 0, ZIndex = 3})
            local CntLayout = Make("UIListLayout", {Parent = TContent, Padding = UDim.new(0, 8)})
            CntLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TContent.CanvasSize = UDim2.new(0, 0, 0, CntLayout.AbsoluteContentSize.Y + 20) end)
            FirstTab = false

            TBtn.MouseButton1Click:Connect(function()
                for _, c in ipairs(Sidebar:GetChildren()) do if c:IsA("TextButton") then TS:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150,150,150)}):Play() end end
                for _, c in ipairs(Content:GetChildren()) do if c:IsA("ScrollingFrame") then c.Visible = false end end
                TS:Create(TBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(255,255,255)}):Play(); TContent.Visible = true
            end)

            local Elements = {}

            function Elements:CreateSection(SName)
                local Sec = Make("Frame", {Parent = TContent, BackgroundTransparency = 1, Size = UDim2.new(1,-10,0,25), ZIndex = 4})
                Make("TextLabel", {Parent = Sec, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Font = Enum.Font.GothamBold, Text = "  " .. SName, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
                Make("Frame", {Parent = Sec, BackgroundColor3 = Color3.fromRGB(60,60,60), Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,0), BorderSizePixel = 0, ZIndex = 4})
            end

            function Elements:CreateLabel(Text) Make("TextLabel", {Parent = TContent, BackgroundTransparency = 1, Size = UDim2.new(1,-10,0,20), Font = Enum.Font.GothamSemibold, Text = "  " .. Text, TextColor3 = Color3.fromRGB(200,200,200), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4}) end
            
            function Elements:CreateParagraph(Title, Desc)
                local PF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(1,-10,0,0), ZIndex = 4})
                Make("UICorner", {Parent = PF, CornerRadius = UDim.new(0, 6)})
                local PTitle = Make("TextLabel", {Parent = PF, BackgroundTransparency = 1, Size = UDim2.new(1,-10,0,20), Position = UDim2.new(0,10,0,5), Font = Enum.Font.GothamBold, Text = Title, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
                local PDesc = Make("TextLabel", {Parent = PF, BackgroundTransparency = 1, Size = UDim2.new(1,-20,0,0), Position = UDim2.new(0,10,0,25), Font = Enum.Font.Gotham, Text = Desc, TextColor3 = Color3.fromRGB(180,180,180), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 5})
                local function UpdateSize() PDesc.Size = UDim2.new(1, -20, 0, PDesc.TextBounds.Y); PF.Size = UDim2.new(1, -10, 0, PDesc.TextBounds.Y + 35) end
                UpdateSize(); PDesc:GetPropertyChangedSignal("TextBounds"):Connect(UpdateSize)
            end
-- ==========================================
-- KEMPLONGXD HUB V7 - BAGIAN 2
-- Paste kode ini persis di bawah baris terakhir Bagian 1
-- ==========================================
            function Elements:CreateButton(BName, Call)
                local Btn = Make("TextButton", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35), Font = Enum.Font.Gotham, Text = "  " .. BName, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4})
                Make("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
                Btn.MouseButton1Click:Connect(function() pcall(Call); TS:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play(); task.wait(0.1); TS:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play() end)
            end

            function Elements:CreateToggle(Flag, TName, Call)
                Library.Flags[Flag] = Library.Flags[Flag] or false
                local TF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35), ZIndex = 4})
                Make("UICorner", {Parent = TF, CornerRadius = UDim.new(0, 6)})
                Make("TextLabel", {Parent = TF, BackgroundTransparency = 1, Size = UDim2.new(1,-50,1,0), Position = UDim2.new(0,10,0,0), Font = Enum.Font.Gotham, Text = TName, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
                local Sw = Make("TextButton", {Parent = TF, BackgroundColor3 = Library.Flags[Flag] and Color3.fromRGB(39,201,63) or Color3.fromRGB(60,60,60), Position = UDim2.new(1,-45,0.5,-10), Size = UDim2.new(0,36,0,20), Text = "", ZIndex = 5})
                Make("UICorner", {Parent = Sw, CornerRadius = UDim.new(1, 0)})
                local Ind = Make("Frame", {Parent = Sw, BackgroundColor3 = Library.Flags[Flag] and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200), Position = Library.Flags[Flag] and UDim2.new(0,18,0.5,-8) or UDim2.new(0,2,0.5,-8), Size = UDim2.new(0,16,0,16), ZIndex = 6})
                Make("UICorner", {Parent = Ind, CornerRadius = UDim.new(1, 0)})
                
                local function Set(state)
                    Library.Flags[Flag] = state; pcall(Call, state)
                    TS:Create(Ind, TweenInfo.new(0.2), {Position = state and UDim2.new(0,18,0.5,-8) or UDim2.new(0,2,0.5,-8), BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)}):Play()
                    TS:Create(Sw, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(39,201,63) or Color3.fromRGB(60,60,60)}):Play()
                end
                Sw.MouseButton1Click:Connect(function() Set(not Library.Flags[Flag]) end)
                if Library.Flags[Flag] then pcall(Call, true) end
            end

            function Elements:CreateSlider(Flag, SName, Min, Max, Def, Call)
                Library.Flags[Flag] = Library.Flags[Flag] or Def
                local SF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,45), ZIndex = 4})
                Make("UICorner", {Parent = SF, CornerRadius = UDim.new(0, 6)})
                Make("TextLabel", {Parent = SF, BackgroundTransparency = 1, Position = UDim2.new(0,10,0,5), Size = UDim2.new(1,-20,0,15), Font = Enum.Font.Gotham, Text = SName, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
                local Val = Make("TextLabel", {Parent = SF, BackgroundTransparency = 1, Position = UDim2.new(1,-50,0,5), Size = UDim2.new(0,40,0,15), Font = Enum.Font.Gotham, Text = tostring(Library.Flags[Flag]), TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5})
                local Area = Make("TextButton", {Parent = SF, BackgroundTransparency = 1, Position = UDim2.new(0,10,0,25), Size = UDim2.new(1,-20,0,10), Text = "", ZIndex = 5})
                local BG = Make("Frame", {Parent = Area, BackgroundColor3 = Color3.fromRGB(30,30,30), Size = UDim2.new(1,0,1,0), ZIndex = 5}); Make("UICorner", {Parent = BG, CornerRadius = UDim.new(1,0)})
                local Fill = Make("Frame", {Parent = BG, BackgroundColor3 = Color3.fromRGB(10,132,255), Size = UDim2.new((Library.Flags[Flag]-Min)/(Max-Min),0,1,0), ZIndex = 6}); Make("UICorner", {Parent = Fill, CornerRadius = UDim.new(1,0)})

                local drag
                local function update(input)
                    local pos = math.clamp((input.Position.X - BG.AbsolutePosition.X) / BG.AbsoluteSize.X, 0, 1)
                    local v = math.floor(Min + (pos * (Max - Min)))
                    Library.Flags[Flag] = v; TS:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos,0,1,0)}):Play(); Val.Text = tostring(v); pcall(Call, v)
                end
                Area.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true; update(i) end end)
                table.insert(Library.Connections, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end end))
                table.insert(Library.Connections, UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end))
            end

            function Elements:CreateDropdown(Flag, DName, Opts, Call)
                Library.Flags[Flag] = Library.Flags[Flag] or ""
                local DF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35), ClipsDescendants = true, ZIndex = 4})
                Make("UICorner", {Parent = DF, CornerRadius = UDim.new(0, 6)})
                local DBtn = Make("TextButton", {Parent = DF, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,35), Font = Enum.Font.Gotham, Text = "  " .. DName .. " : " .. (Library.Flags[Flag] == "" and "-" or tostring(Library.Flags[Flag])), TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
                local DScroll = Make("ScrollingFrame", {Parent = DF, BackgroundTransparency = 1, Position = UDim2.new(0,0,0,35), Size = UDim2.new(1,0,1,-35), ScrollBarThickness = 2, BorderSizePixel = 0, ZIndex = 5}); Make("UIListLayout", {Parent = DScroll})

                local open = false
                DBtn.MouseButton1Click:Connect(function() open = not open; TS:Create(DF, TweenInfo.new(0.2), {Size = open and UDim2.new(1,-10,0,35 + math.clamp(#DScroll:GetChildren()-1, 0, 4)*25) or UDim2.new(1,-10,0,35)}):Play() end)

                local DropObj = {}
                function DropObj:Refresh(NewOpts)
                    for _, child in ipairs(DScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                    for _, o in ipairs(NewOpts) do
                        local OBtn = Make("TextButton", {Parent = DScroll, BackgroundColor3 = Color3.fromRGB(55,55,55), Size = UDim2.new(1,0,0,25), Font = Enum.Font.Gotham, Text = "  " .. tostring(o), TextColor3 = Color3.fromRGB(200,200,200), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 6})
                        OBtn.MouseButton1Click:Connect(function() Library.Flags[Flag] = o; DBtn.Text = "  " .. DName .. " : " .. tostring(o); open = false; TS:Create(DF, TweenInfo.new(0.2), {Size = UDim2.new(1,-10,0,35)}):Play(); pcall(Call, o) end)
                    end
                    if open then TS:Create(DF, TweenInfo.new(0.2), {Size = UDim2.new(1,-10,0,35 + math.clamp(#NewOpts, 0, 4)*25)}):Play() end
                end
                DropObj:Refresh(Opts); return DropObj
            end

            function Elements:CreateInput(Flag, IName, PlaceHolder, Call)
                Library.Flags[Flag] = Library.Flags[Flag] or ""
                local IF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35), ZIndex = 4})
                Make("UICorner", {Parent = IF, CornerRadius = UDim.new(0, 6)})
                Make("TextLabel", {Parent = IF, BackgroundTransparency = 1, Size = UDim2.new(0.5,0,1,0), Position = UDim2.new(0,10,0,0), Font = Enum.Font.Gotham, Text = IName, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
                local Box = Make("TextBox", {Parent = IF, BackgroundColor3 = Color3.fromRGB(30,30,30), Size = UDim2.new(0.4,0,0,25), Position = UDim2.new(0.6,-10,0.5,-12.5), Font = Enum.Font.Gotham, PlaceholderText = PlaceHolder, Text = Library.Flags[Flag], TextColor3 = Color3.fromRGB(255,255,255), TextSize = 12, ClearTextOnFocus = false, ZIndex = 5})
                Make("UICorner", {Parent = Box, CornerRadius = UDim.new(0, 4)})
                Box.Focused:Connect(function() Box.Text = "" end)
                Box.FocusLost:Connect(function() Library.Flags[Flag] = Box.Text; pcall(Call, Box.Text) end)
            end

            function Elements:CreateColorPicker(Flag, CName, DefColor, Call)
                Library.Flags[Flag] = Library.Flags[Flag] or {DefColor.R, DefColor.G, DefColor.B}
                local CF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35), ZIndex = 4})
                Make("UICorner", {Parent = CF, CornerRadius = UDim.new(0, 6)})
                Make("TextLabel", {Parent = CF, BackgroundTransparency = 1, Size = UDim2.new(0.6,0,1,0), Position = UDim2.new(0,10,0,0), Font = Enum.Font.Gotham, Text = CName, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
                
                local CBtn = Make("TextButton", {Parent = CF, BackgroundColor3 = Color3.fromRGB(Library.Flags[Flag][1]*255, Library.Flags[Flag][2]*255, Library.Flags[Flag][3]*255), Position = UDim2.new(1,-40,0.5,-10), Size = UDim2.new(0,30,0,20), Text = "", ZIndex = 5})
                Make("UICorner", {Parent = CBtn, CornerRadius = UDim.new(0,4)})
                
                local RGBBox = Make("TextBox", {Parent = CF, BackgroundColor3 = Color3.fromRGB(30,30,30), Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(1, -110, 0.5, -10), Font = Enum.Font.Gotham, PlaceholderText = "R,G,B", Text = "", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 11, ZIndex = 5})
                Make("UICorner", {Parent = RGBBox, CornerRadius = UDim.new(0, 4)})

                RGBBox.FocusLost:Connect(function()
                    local r, g, b = RGBBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
                    if r and g and b then
                        r, g, b = math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255)
                        Library.Flags[Flag] = {r/255, g/255, b/255}
                        CBtn.BackgroundColor3 = Color3.fromRGB(r, g, b)
                        pcall(Call, Color3.fromRGB(r, g, b))
                    end
                    RGBBox.Text = ""
                end)
            end

            function Elements:CreateKeybind(Flag, KName, DefKey, Call)
                Library.Flags[Flag] = Library.Flags[Flag] or DefKey.Name
                local KF = Make("Frame", {Parent = TContent, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(1,-10,0,35), ZIndex = 4})
                Make("UICorner", {Parent = KF, CornerRadius = UDim.new(0, 6)})
                Make("TextLabel", {Parent = KF, BackgroundTransparency = 1, Size = UDim2.new(0.5,0,1,0), Position = UDim2.new(0,10,0,0), Font = Enum.Font.Gotham, Text = KName, TextColor3 = Color3.fromRGB(220,220,220), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
                local KBtn = Make("TextButton", {Parent = KF, BackgroundColor3 = Color3.fromRGB(60,60,60), Size = UDim2.new(0,80,0,25), Position = UDim2.new(1,-90,0.5,-12.5), Font = Enum.Font.GothamSemibold, Text = Library.Flags[Flag], TextColor3 = Color3.fromRGB(200,200,200), TextSize = 12, ZIndex = 5})
                Make("UICorner", {Parent = KBtn, CornerRadius = UDim.new(0, 4)})
                
                local Key = Enum.KeyCode[Library.Flags[Flag]] or DefKey
                KBtn.MouseButton1Click:Connect(function()
                    KBtn.Text = "..."
                    local conn; conn = UIS.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.Keyboard then
                            Key = i.KeyCode; Library.Flags[Flag] = Key.Name; KBtn.Text = Key.Name; conn:Disconnect()
                        end
                    end)
                end)
                table.insert(Library.Connections, UIS.InputBegan:Connect(function(i, gp) if gp then return end; if i.KeyCode == Key then pcall(Call) end end))
            end

            return Elements
        end return WinObj
    end

    if UseKey then
        local AuthMain = Make("Frame", {Parent = SG, BackgroundColor3 = Color3.fromRGB(30,30,30), Position = UDim2.new(0.5, -150, 0.5, -75), Size = UDim2.new(0, 300, 0, 150), ClipsDescendants = true, ZIndex = 10})
        Make("UICorner", {Parent = AuthMain, CornerRadius = UDim.new(0, 10)})
        local AuthTop = Make("Frame", {Parent = AuthMain, BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(1, 0, 0, 30), ZIndex = 11}); Make("UICorner", {Parent = AuthTop, CornerRadius = UDim.new(0, 10)})
        Make("Frame", {Parent = AuthTop, BackgroundColor3 = Color3.fromRGB(40,40,40), Position = UDim2.new(0,0,0.5,0), Size = UDim2.new(1,0,0.5,0), BorderSizePixel = 0, ZIndex = 11})
        Make("TextLabel", {Parent = AuthTop, BackgroundTransparency = 1, Position = UDim2.new(0,10,0,0), Size = UDim2.new(1,-20,1,0), Font = Enum.Font.GothamSemibold, Text = "Authentication", TextColor3 = Color3.fromRGB(200,200,200), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 12})
        
        local KeyBox = Make("TextBox", {Parent = AuthMain, BackgroundColor3 = Color3.fromRGB(45,45,45), Position = UDim2.new(0.1, 0, 0.4, 0), Size = UDim2.new(0.8, 0, 0, 30), Font = Enum.Font.Gotham, PlaceholderText = "Enter Key Here...", Text = "", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 13, ZIndex = 11})
        Make("UICorner", {Parent = KeyBox, CornerRadius = UDim.new(0, 6)})

        local VerifyBtn = Make("TextButton", {Parent = AuthMain, BackgroundColor3 = Color3.fromRGB(10,132,255), Position = UDim2.new(0.1, 0, 0.7, 0), Size = UDim2.new(0.8, 0, 0, 30), Font = Enum.Font.GothamBold, Text = "Verify Key", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 13, ZIndex = 11})
        Make("UICorner", {Parent = VerifyBtn, CornerRadius = UDim.new(0, 6)})

        VerifyBtn.MouseButton1Click:Connect(function()
            if KeyBox.Text == ExpectedKey then
                TS:Create(AuthMain, TweenInfo.new(0.3), {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}):Play()
                task.wait(0.3); AuthMain:Destroy()
                Library:Notify("Access Granted", "Welcome back to " .. Name, 4)
                return LoadMainUI()
            else
                Library:Notify("Error", "Invalid Key!", 3)
            end
        end)
    else
        return LoadMainUI()
    end
end

return Library
