--[[
    DRK Hub UI Library V6
]]

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local DRKLib = {}
DRKLib.__index = DRKLib

local Configs_HUB = {
    Cor_Hub = Color3.fromRGB(7, 7, 7),
    Cor_Options = Color3.fromRGB(13, 13, 13),
    Cor_Stroke = Color3.fromRGB(255, 45, 45),
    Cor_Text = Color3.fromRGB(235, 235, 235),
    Corner_Radius = UDim.new(0, 10),
    Text_Font = Enum.Font.GothamBold,
    DefaultButtonIcon = "rbxassetid://92615117311099"
}

local ActiveStrokes = {}
local ActiveAccentObjects = {}
local CurrentWindowRef = nil

local function Create(className, parent, props)
    local new = Instance.new(className)
    new.Parent = parent

    if props then
        for prop, value in pairs(props) do
            pcall(function()
                new[prop] = value
            end)
        end
    end

    return new
end

local function Corner(parent, props)
    local new = Instance.new("UICorner")
    new.CornerRadius = Configs_HUB.Corner_Radius

    if props then
        for prop, value in pairs(props) do
            pcall(function()
                new[prop] = value
            end)
        end
    end

    new.Parent = parent
    return new
end

local function Stroke(parent, props)
    local new = Instance.new("UIStroke")
    new.Color = Configs_HUB.Cor_Stroke
    new.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    new.Thickness = 1.2

    if props then
        for prop, value in pairs(props) do
            pcall(function()
                new[prop] = value
            end)
        end
    end

    new.Parent = parent
    table.insert(ActiveStrokes, new)

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
        ColorSequenceKeypoint.new(0.5, Configs_HUB.Cor_Stroke),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
    })
    gradient.Rotation = 0
    gradient.Parent = new

    task.spawn(function()
        while new.Parent do
            gradient.Rotation = (gradient.Rotation + 2) % 360
            task.wait(0.03)
        end
    end)

    return new
end

function DRKLib:SetThemeColor(newColor)
    if typeof(newColor) ~= "Color3" then
        return
    end

    local oldColor = Configs_HUB.Cor_Stroke
    Configs_HUB.Cor_Stroke = newColor

    for _, stroke in ipairs(ActiveStrokes) do
        if stroke and stroke.Parent then
            stroke.Color = newColor
            for _, child in ipairs(stroke:GetChildren()) do
                if child:IsA("UIGradient") then
                    child.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
                        ColorSequenceKeypoint.new(0.5, newColor),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
                    })
                end
            end
        end
    end

    for _, object in ipairs(ActiveAccentObjects) do
        if object and object.Parent then
            pcall(function() object.BackgroundColor3 = newColor end)
            pcall(function() object.TextColor3 = newColor end)
            pcall(function() object.ImageColor3 = newColor end)
            pcall(function() object.Color = newColor end)
        end
    end

    if CurrentWindowRef and CurrentWindowRef.Parent then
        for _, object in ipairs(CurrentWindowRef:GetDescendants()) do
            pcall(function()
                if object:IsA("UIStroke") then
                    if object.Color == oldColor then
                        object.Color = newColor
                    end
                elseif object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    if object.TextColor3 == oldColor then
                        object.TextColor3 = newColor
                    end
                    if object.BackgroundColor3 == oldColor then
                        object.BackgroundColor3 = newColor
                    end
                elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
                    if object.ImageColor3 == oldColor then
                        object.ImageColor3 = newColor
                    end
                    if object.BackgroundColor3 == oldColor then
                        object.BackgroundColor3 = newColor
                    end
                elseif object:IsA("Frame") then
                    if object.BackgroundColor3 == oldColor then
                        object.BackgroundColor3 = newColor
                    end
                elseif object:IsA("UIGradient") then
                    local keys = object.Color.Keypoints
                    local changed = false
                    local rebuilt = {}
                    for _, keypoint in ipairs(keys) do
                        local keyColor = keypoint.Value
                        if keyColor == oldColor then
                            keyColor = newColor
                            changed = true
                        end
                        table.insert(rebuilt, ColorSequenceKeypoint.new(keypoint.Time, keyColor))
                    end
                    if changed then
                        object.Color = ColorSequence.new(rebuilt)
                    end
                end
            end)
        end
    end

    if _G.DRKThemeChanged then
        pcall(_G.DRKThemeChanged, newColor)
    end
end

function DRKLib:SetWindowSize(width, height)
    if CurrentWindowRef and CurrentWindowRef.Parent then
        TweenService:Create(
            CurrentWindowRef,
            TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, width, 0, height)}
        ):Play()
    end
end

local function ShowNotification(parentGui, text, color)
    local notif = Create("Frame", parentGui, {
        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
        Position = UDim2.new(0.5, -125, 0, -50),
        Size = UDim2.new(0, 250, 0, 35),
        ZIndex = 999
    })

    Corner(notif)
    Stroke(notif, {Thickness = 1})

    Create("TextLabel", notif, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Configs_HUB.Text_Font,
        Text = text,
        TextColor3 = color or Configs_HUB.Cor_Stroke,
        TextSize = 11,
        ZIndex = 1000
    })

    TweenService:Create(
        notif,
        TweenInfo.new(0.3, Enum.EasingStyle.Quart),
        {Position = UDim2.new(0.5, -125, 0, 20)}
    ):Play()

    task.delay(2.5, function()
        if notif and notif.Parent then
            TweenService:Create(
                notif,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                {Position = UDim2.new(0.5, -125, 0, -50)}
            ):Play()

            task.wait(0.3)

            if notif and notif.Parent then
                notif:Destroy()
            end
        end
    end)
end

function DRKLib:CreateWindow(titleText, customMinimizeConfig, keyConfig)
    local self = setmetatable({}, DRKLib)

    local ScreenGui = Create("ScreenGui", CoreGui, {
        Name = "DRK_Library_Gui",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    if syn and syn.protect_gui then
        pcall(function()
            syn.protect_gui(ScreenGui)
        end)
    elseif protectgui then
        pcall(function()
            protectgui(ScreenGui)
        end)
    end

    pcall(function()
        ScreenGui.Parent = gethui and gethui() or CoreGui
    end)

    if keyConfig and keyConfig.KeySystem == true then
        local KeyUnlocked = false

        local KeyMainFrame = Create("Frame", ScreenGui, {
            BackgroundColor3 = Configs_HUB.Cor_Hub,
            Position = UDim2.new(0.5, -180, 0.5, -110),
            Size = UDim2.new(0, 360, 0, 220),
            Active = true,
            ZIndex = 100
        })

        Corner(KeyMainFrame)
        local KeyStroke = Stroke(KeyMainFrame)
        KeyStroke.Thickness = 2

    
        local KeyTopBar = Create("Frame", KeyMainFrame, {
            BackgroundColor3 = Color3.fromRGB(10, 10, 10),
            Size = UDim2.new(1, 0, 0, 32),
            BorderSizePixel = 0,
            ZIndex = 101
        })

        Corner(KeyTopBar)

        Create("TextLabel", KeyTopBar, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 300, 1, 0),
            Font = Configs_HUB.Text_Font,
            Text = keyConfig.Title or "Key System",
            TextColor3 = Configs_HUB.Cor_Stroke,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102
        })

        if keyConfig.Description and keyConfig.Description ~= "" then
            Create("TextLabel", KeyMainFrame, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 45),
                Size = UDim2.new(1, -30, 0, 30),
                Font = Enum.Font.Gotham,
                Text = keyConfig.Description,
                TextColor3 = Configs_HUB.Cor_Text,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextWrapped = true,
                ZIndex = 101
            })
        end

        local KeyBox = Create("TextBox", KeyMainFrame, {
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            Position = UDim2.new(0.5, -150, 0, 85),
            Size = UDim2.new(0, 300, 0, 36),
            Font = Enum.Font.Gotham,
            PlaceholderText = "Enter your key here...",
            Text = "",
            TextColor3 = Configs_HUB.Cor_Text,
            PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
            TextSize = 11,
            ZIndex = 101
        })

        Corner(KeyBox, {CornerRadius = UDim.new(0, 6)})
        Stroke(KeyBox, {Thickness = 1})

        local EnterBtn = Create("TextButton", KeyMainFrame, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Position = UDim2.new(0.5, -150, 0, 132),
            Size = UDim2.new(0, 145, 0, 34),
            Font = Configs_HUB.Text_Font,
            Text = "Check Key",
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            AutoButtonColor = true,
            ZIndex = 101
        })

        Corner(EnterBtn)
        Stroke(EnterBtn, {Thickness = 1})

        local GetKeyBtn = Create("TextButton", KeyMainFrame, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Position = UDim2.new(0.5, 5, 0, 132),
            Size = UDim2.new(0, 145, 0, 34),
            Font = Configs_HUB.Text_Font,
            Text = "Get Key",
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            AutoButtonColor = true,
            ZIndex = 101
        })

        Corner(GetKeyBtn)
        Stroke(GetKeyBtn, {Thickness = 1})

        EnterBtn.MouseButton1Click:Connect(function()
            local enteredText = KeyBox.Text
            local isValid = false

            for _, k in ipairs(keyConfig.Keys or {}) do
                if k == enteredText then
                    isValid = true
                    break
                end
            end

            if isValid then
                if keyConfig.Notifi and keyConfig.Notifi.Notifications then
                    ShowNotification(
                        ScreenGui,
                        keyConfig.Notifi.CorrectKey or "Running the Script...",
                        Color3.fromRGB(50, 255, 50)
                    )
                end

                KeyUnlocked = true

                TweenService:Create(
                    KeyMainFrame,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                    {Size = UDim2.new(0, 0, 0, 0)}
                ):Play()

                task.wait(0.3)

                if KeyMainFrame.Parent then
                    KeyMainFrame:Destroy()
                end
            else
                if keyConfig.Notifi and keyConfig.Notifi.Notifications then
                    ShowNotification(
                        ScreenGui,
                        keyConfig.Notifi.Incorrectkey or "The key is incorrect",
                        Color3.fromRGB(255, 50, 50)
                    )
                end
            end
        end)

        GetKeyBtn.MouseButton1Click:Connect(function()
            if keyConfig.KeyLink and keyConfig.KeyLink ~= "" then
                if setclipboard then
                    pcall(function()
                        setclipboard(keyConfig.KeyLink)
                    end)

                    if keyConfig.Notifi and keyConfig.Notifi.Notifications then
                        ShowNotification(
                            ScreenGui,
                            keyConfig.Notifi.CopyKeyLink or "Copied to Clipboard",
                            Color3.fromRGB(50, 150, 255)
                        )
                    end
                end
            end
        end)

        repeat
            task.wait()
        until KeyUnlocked
    end

    local minConfig = customMinimizeConfig or {}

    local minSize = minConfig.Size
        and UDim2.new(0, minConfig.Size[1], 0, minConfig.Size[2])
        or UDim2.new(0, 40, 0, 40)

    local minColor = minConfig.Color or Configs_HUB.Cor_Hub
    local minImage = minConfig.Image or ""
    local hasCorner = minConfig.Corner ~= false
    local hasStroke = minConfig.Stroke == true
    local strokeColor = minConfig.StrokeColor or Configs_HUB.Cor_Stroke

    local MainFrame = Create("Frame", ScreenGui, {
        BackgroundColor3 = Configs_HUB.Cor_Hub,
        Position = UDim2.new(0.5, -270, 0.5, -165),
        Size = UDim2.new(0, 540, 0, 330),
        Active = true,
        ClipsDescendants = false,
        ZIndex = 1
    })

    CurrentWindowRef = MainFrame

    Corner(MainFrame)
    local MainStroke = Stroke(MainFrame)
    MainStroke.Thickness = 2.2

    local TopBar = Create("Frame", MainFrame, {
        BackgroundColor3 = Color3.fromRGB(9, 9, 9),
        Size = UDim2.new(1, 0, 0, 35),
        BorderSizePixel = 0,
        ZIndex = 50
    })

    Corner(TopBar)

    Create("TextLabel", TopBar, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 350, 1, 0),
        Font = Configs_HUB.Text_Font,
        Text = titleText or "DRK Hub",
        TextColor3 = Configs_HUB.Cor_Stroke,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 51
    })

    local dragging, dragInput, dragStart, startPos

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    local CloseButton = Create("TextButton", TopBar, {
        BackgroundColor3 = Configs_HUB.Cor_Stroke,
        Position = UDim2.new(1, -28, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Font = Configs_HUB.Text_Font,
        Text = "X",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 9,
        AutoButtonColor = true,
        ZIndex = 52
    })

    Corner(CloseButton, {CornerRadius = UDim.new(1, 0)})

    CloseButton.MouseButton1Click:Connect(function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end)

    local MinimizeButton = Create("TextButton", TopBar, {
        BackgroundColor3 = Color3.fromRGB(45, 45, 45),
        Position = UDim2.new(1, -52, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Font = Configs_HUB.Text_Font,
        Text = "-",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        AutoButtonColor = true,
        ZIndex = 52
    })

    Corner(MinimizeButton, {CornerRadius = UDim.new(1, 0)})

    self.HubElements = {}

    local TabsContainer = Create("Frame", MainFrame, {
        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
        Position = UDim2.new(0, 8, 0, 43),
        Size = UDim2.new(0, 140, 1, -51),
        ClipsDescendants = true,
        ZIndex = 5
    })

    table.insert(self.HubElements, TabsContainer)

    Corner(TabsContainer, {CornerRadius = UDim.new(0, 8)})
    Stroke(TabsContainer)

    local CollapseBtn = Create("TextButton", MainFrame, {
        BackgroundColor3 = Color3.fromRGB(18, 18, 18),
        Position = UDim2.new(0, 151, 0, 43),
        Size = UDim2.new(0, 16, 0, 32),
        Font = Configs_HUB.Text_Font,
        Text = "<",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        AutoButtonColor = true,
        ZIndex = 12
    })

    table.insert(self.HubElements, CollapseBtn)

    Corner(CollapseBtn, {CornerRadius = UDim.new(0, 4)})
    Stroke(CollapseBtn, {Thickness = 1})

    local ContentContainer = Create("Frame", MainFrame, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 155, 0, 43),
        Size = UDim2.new(1, -163, 1, -51),
        ClipsDescendants = false,
        ZIndex = 2
    })

    table.insert(self.HubElements, ContentContainer)

    local isCollapsed = false

    CollapseBtn.MouseButton1Click:Connect(function()
        isCollapsed = not isCollapsed

        local targetTabsSize = isCollapsed
            and UDim2.new(0, 0, 1, -51)
            or UDim2.new(0, 140, 1, -51)

        local targetBtnPos = isCollapsed
            and UDim2.new(0, 10, 0, 43)
            or UDim2.new(0, 151, 0, 43)

        local targetContentPos = isCollapsed
            and UDim2.new(0, 18, 0, 43)
            or UDim2.new(0, 155, 0, 43)

        local targetContentSize = isCollapsed
            and UDim2.new(1, -26, 1, -51)
            or UDim2.new(1, -163, 1, -51)

        CollapseBtn.Text = isCollapsed and ">" or "<"

        TweenService:Create(
            TabsContainer,
            TweenInfo.new(0.25, Enum.EasingStyle.Quart),
            {Size = targetTabsSize}
        ):Play()

        TweenService:Create(
            CollapseBtn,
            TweenInfo.new(0.25, Enum.EasingStyle.Quart),
            {Position = targetBtnPos}
        ):Play()

        TweenService:Create(
            ContentContainer,
            TweenInfo.new(0.25, Enum.EasingStyle.Quart),
            {
                Position = targetContentPos,
                Size = targetContentSize
            }
        ):Play()
    end)

    self.InnerTabsList = Create("ScrollingFrame", TabsContainer, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 0, 10),
        Size = UDim2.new(1, -12, 1, -16),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ZIndex = 6
    })

    Create("UIListLayout", self.InnerTabsList, {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    self.ContentContainer = ContentContainer
    self.TabsListLayout = self.InnerTabsList
    self.FirstTab = true

    function self:AddDiscordButton(inviteLink)
        local discordBtn = Create("TextButton", TabsContainer, {
            BackgroundColor3 = Color3.fromRGB(45, 45, 45),
            Position = UDim2.new(0, 6, 1, -38),
            Size = UDim2.new(1, -12, 0, 32),
            Font = Configs_HUB.Text_Font,
            Text = "  Discord",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            AutoButtonColor = true,
            ZIndex = 15
        })

        Corner(discordBtn, {CornerRadius = UDim.new(0, 6)})
        Stroke(discordBtn)

        Create("ImageLabel", discordBtn, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0.5, -8),
            Size = UDim2.new(0, 16, 0, 16),
            Image = "rbxassetid://89370162590209",
            ZIndex = 16
        })

        discordBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                pcall(function()
                    setclipboard(inviteLink or "https://discord.gg/yourinvite")
                end)

                ShowNotification(
                    ScreenGui,
                    "Copied Discord Link!",
                    Color3.fromRGB(120, 120, 255)
                )
            end
        end)

        self.InnerTabsList.Size = UDim2.new(1, -12, 1, -54)
    end

    -- Settings tab
    do
        local settingsTab = Create("ScrollingFrame", self.ContentContainer, {
            BackgroundColor3 = Color3.fromRGB(10, 10, 10),
            BackgroundTransparency = 0.7,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            Visible = false,
            ZIndex = 3
        })

        Corner(settingsTab, {CornerRadius = UDim.new(0, 8)})
        Stroke(settingsTab)

        local settingsLayout = Create("UIListLayout", settingsTab, {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Center
        })

        Create("UIPadding", settingsTab, {
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 12)
        })

        settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            settingsTab.CanvasSize = UDim2.new(
                0,
                0,
                0,
                settingsLayout.AbsoluteContentSize.Y + 26
            )
        end)

        local settingsTabBtn = Create("TextButton", self.InnerTabsList, {
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Size = UDim2.new(1, 0, 0, 32),
            Font = Configs_HUB.Text_Font,
            Text = "Settings",
            TextColor3 = Color3.fromRGB(160, 160, 160),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            AutoButtonColor = true,
            ZIndex = 7
        })

        Corner(settingsTabBtn, {CornerRadius = UDim.new(0, 6)})
        Stroke(settingsTabBtn)

        Create("ImageLabel", settingsTabBtn, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0.5, -8),
            Size = UDim2.new(0, 16, 0, 16),
            Image = "rbxassetid://80758916183665",
            ZIndex = 8
        })

        settingsTabBtn.MouseButton1Click:Connect(function()
            for _, child in ipairs(self.ContentContainer:GetChildren()) do
                if child:IsA("ScrollingFrame") then
                    child.Visible = (child == settingsTab)
                end
            end

            for _, btn in ipairs(self.InnerTabsList:GetChildren()) do
                if btn:IsA("TextButton") then
                    TweenService:Create(
                        btn,
                        TweenInfo.new(0.2),
                        {
                            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                            TextColor3 = Color3.fromRGB(160, 160, 160)
                        }
                    ):Play()
                end
            end

            TweenService:Create(
                settingsTabBtn,
                TweenInfo.new(0.2),
                {
                    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }
            ):Play()
        end)

        -- Window size dropdown
        do
            local isOpen = false
            local options = {"Small", "Normal", "Large", "Extra Large"}
            local selectedOption = "Normal"

            local dropFrame = Create("Frame", settingsTab, {
                BackgroundColor3 = Configs_HUB.Cor_Options,
                Size = UDim2.new(1, -16, 0, 36),
                ClipsDescendants = true,
                ZIndex = 15
            })

            Corner(dropFrame)
            Stroke(dropFrame, {Thickness = 1})

            local btn = Create("TextButton", dropFrame, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Font = Configs_HUB.Text_Font,
                Text = "  Window Size :  " .. selectedOption,
                TextColor3 = Configs_HUB.Cor_Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 16
            })

            local arrow = Create("TextLabel", btn, {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -30, 0, 0),
                Size = UDim2.new(0, 20, 0, 36),
                Font = Configs_HUB.Text_Font,
                Text = "+",
                TextColor3 = Configs_HUB.Cor_Stroke,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 17
            })

            local container = Create("Frame", dropFrame, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 38),
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 16
            })

            Create("UIListLayout", container, {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top
            })

            for _, opt in ipairs(options) do
                local optBtn = Create("TextButton", container, {
                    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
                    Size = UDim2.new(1, -16, 0, 32),
                    Font = Enum.Font.Gotham,
                    Text = opt,
                    TextColor3 = Configs_HUB.Cor_Text,
                    TextSize = 10,
                    AutoButtonColor = true,
                    ZIndex = 17
                })

                Corner(optBtn, {CornerRadius = UDim.new(0, 6)})
                Stroke(optBtn, {Thickness = 1})

                optBtn.MouseButton1Click:Connect(function()
                    selectedOption = opt
                    btn.Text = "  Window Size :  " .. selectedOption
                    isOpen = false
                    arrow.Text = "+"

                    TweenService:Create(
                        dropFrame,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                        {Size = UDim2.new(1, -16, 0, 36)}
                    ):Play()

                    if opt == "Small" then
                        DRKLib:SetWindowSize(450, 280)
                    elseif opt == "Normal" then
                        DRKLib:SetWindowSize(540, 330)
                    elseif opt == "Large" then
                        DRKLib:SetWindowSize(620, 390)
                    elseif opt == "Extra Large" then
                        DRKLib:SetWindowSize(720, 460)
                    end

                    ShowNotification(
                        ScreenGui,
                        "Window Size: " .. opt,
                        Configs_HUB.Cor_Stroke
                    )
                end)
            end

            btn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                arrow.Text = isOpen and "-" or "+"

                local contentHeight = (#options * 38) + 12
                local targetHeight = isOpen and (36 + contentHeight) or 36

                TweenService:Create(
                    dropFrame,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                    {Size = UDim2.new(1, -16, 0, targetHeight)}
                ):Play()
            end)
        end

        -- Theme color dropdown
        do
            local isOpen = false

            local colorOptions = {
                {Name = "Red", Color = Color3.fromRGB(255, 0, 40)},
                {Name = "Orange", Color = Color3.fromRGB(255, 120, 0)},
                {Name = "Yellow", Color = Color3.fromRGB(255, 230, 0)},
                {Name = "Green", Color = Color3.fromRGB(0, 255, 100)},
                {Name = "Cyan", Color = Color3.fromRGB(0, 255, 255)},
                {Name = "Blue", Color = Color3.fromRGB(0, 120, 255)},
                {Name = "Purple", Color = Color3.fromRGB(170, 0, 255)},
                {Name = "Pink", Color = Color3.fromRGB(255, 0, 200)},
                {Name = "White", Color = Color3.fromRGB(255, 255, 255)},
                {Name = "Lime", Color = Color3.fromRGB(120, 255, 0)},
                {Name = "Teal", Color = Color3.fromRGB(0, 180, 150)},
                {Name = "Magenta", Color = Color3.fromRGB(255, 0, 100)}
            }

            local selectedColorName = "Red"

            local dropFrame = Create("Frame", settingsTab, {
                BackgroundColor3 = Configs_HUB.Cor_Options,
                Size = UDim2.new(1, -16, 0, 36),
                ClipsDescendants = true,
                ZIndex = 15
            })

            Corner(dropFrame)
            Stroke(dropFrame, {Thickness = 1})

            local btn = Create("TextButton", dropFrame, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 36),
                Font = Configs_HUB.Text_Font,
                Text = "  Theme Color :  " .. selectedColorName,
                TextColor3 = Configs_HUB.Cor_Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 16
            })

            local arrow = Create("TextLabel", btn, {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -30, 0, 0),
                Size = UDim2.new(0, 20, 0, 36),
                Font = Configs_HUB.Text_Font,
                Text = "+",
                TextColor3 = Configs_HUB.Cor_Stroke,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 17
            })

            local container = Create("Frame", dropFrame, {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 38),
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 16
            })

            Create("UIListLayout", container, {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top
            })

            for _, colData in ipairs(colorOptions) do
                local optBtn = Create("TextButton", container, {
                    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
                    Size = UDim2.new(1, -16, 0, 32),
                    Font = Enum.Font.Gotham,
                    Text = colData.Name,
                    TextColor3 = colData.Color,
                    TextSize = 10,
                    AutoButtonColor = true,
                    ZIndex = 17
                })

                Corner(optBtn, {CornerRadius = UDim.new(0, 6)})
                Stroke(optBtn, {Thickness = 1})

                optBtn.MouseButton1Click:Connect(function()
                    selectedColorName = colData.Name
                    btn.Text = "  Theme Color :  " .. selectedColorName
                    isOpen = false
                    arrow.Text = "+"

                    TweenService:Create(
                        dropFrame,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                        {Size = UDim2.new(1, -16, 0, 36)}
                    ):Play()

                    DRKLib:SetThemeColor(colData.Color)

                    ShowNotification(
                        ScreenGui,
                        "Theme Color: " .. colData.Name,
                        colData.Color
                    )
                end)
            end

            btn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                arrow.Text = isOpen and "-" or "+"

                local contentHeight = (#colorOptions * 38) + 12
                local targetHeight = isOpen and (36 + contentHeight) or 36

                TweenService:Create(
                    dropFrame,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                    {Size = UDim2.new(1, -16, 0, targetHeight)}
                ):Play()
            end)
        end
    end

    local MinimizeFloatingBtn = Create("ImageButton", ScreenGui, {
        BackgroundColor3 = minColor,
        Position = UDim2.new(0.05, 0, 0.15, 0),
        Size = minSize,
        Image = minImage,
        AutoButtonColor = true,
        Active = true,
        Draggable = true,
        ZIndex = 100
    })

    table.insert(ActiveAccentObjects, MinimizeFloatingBtn)

    if minImage == "" then
        Create("TextLabel", MinimizeFloatingBtn, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Configs_HUB.Text_Font,
            Text = "DRK",
            TextColor3 = Configs_HUB.Cor_Stroke,
            TextSize = 18,
            ZIndex = 101
        })
    end

    if hasCorner then
        Corner(MinimizeFloatingBtn, {
            CornerRadius = UDim.new(1, 0)
        })
    end

    if hasStroke then
        Stroke(MinimizeFloatingBtn, {
            Color = strokeColor
        })
    end

    local isMinimized = false

    MinimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized

        if isMinimized then
            for _, element in ipairs(self.HubElements) do
                element.Visible = false
            end

            CollapseBtn.Visible = false

            TweenService:Create(
                MainFrame,
                TweenInfo.new(0.25, Enum.EasingStyle.Quart),
                {Size = UDim2.new(0, 540, 0, 35)}
            ):Play()

            MinimizeButton.Text = "+"
        else
            TweenService:Create(
                MainFrame,
                TweenInfo.new(0.25, Enum.EasingStyle.Quart),
                {Size = UDim2.new(0, 540, 0, 330)}
            ):Play()

            task.wait(0.15)

            for _, element in ipairs(self.HubElements) do
                element.Visible = true
            end

            CollapseBtn.Visible = true
            MinimizeButton.Text = "-"
        end
    end)

    local isWindowHidden = false

    MinimizeFloatingBtn.MouseButton1Click:Connect(function()
        isWindowHidden = not isWindowHidden
        MainFrame.Visible = not isWindowHidden
    end)

    return self
end

function DRKLib:CreateTab(tabName, tabIcon)
    local tab = Create("ScrollingFrame", self.ContentContainer, {
        BackgroundColor3 = Color3.fromRGB(10, 10, 10),
        BackgroundTransparency = 0.7,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        Visible = self.FirstTab,
        ZIndex = 3
    })

    Corner(tab, {CornerRadius = UDim.new(0, 8)})
    Stroke(tab)

    local tabLayout = Create("UIListLayout", tab, {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    Create("UIPadding", tab, {
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 12)
    })

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab.CanvasSize = UDim2.new(
            0,
            0,
            0,
            tabLayout.AbsoluteContentSize.Y + 26
        )
    end)

    local tabBtn = Create("TextButton", self.InnerTabsList, {
        BackgroundColor3 = self.FirstTab
            and Color3.fromRGB(20, 20, 20)
            or Color3.fromRGB(12, 12, 12),

        Size = UDim2.new(1, 0, 0, 32),
        Font = Configs_HUB.Text_Font,
        Text = tabName,
        TextColor3 = self.FirstTab
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(160, 160, 160),

        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        AutoButtonColor = true,
        ZIndex = 7
    })

    Corner(tabBtn, {CornerRadius = UDim.new(0, 6)})
    Stroke(tabBtn)

    if tabIcon then
        Create("ImageLabel", tabBtn, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0.5, -8),
            Size = UDim2.new(0, 16, 0, 16),
            Image = tabIcon,
            ZIndex = 8
        })
    end

    self.FirstTab = false

    tabBtn.MouseButton1Click:Connect(function()
        for _, child in ipairs(self.ContentContainer:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                child.Visible = (child == tab)
            end
        end

        for _, btn in ipairs(self.InnerTabsList:GetChildren()) do
            if btn:IsA("TextButton") then
                TweenService:Create(
                    btn,
                    TweenInfo.new(0.2),
                    {
                        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                        TextColor3 = Color3.fromRGB(160, 160, 160)
                    }
                ):Play()
            end
        end

        TweenService:Create(
            tabBtn,
            TweenInfo.new(0.2),
            {
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }
        ):Play()
    end)

    local TabFunctions = {}

    function TabFunctions:AddSection(text)
        local sec = Create("Frame", tab, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 24),
            ZIndex = 5
        })

        Create("TextLabel", sec, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Configs_HUB.Text_Font,
            Text = text,
            TextColor3 = Configs_HUB.Cor_Stroke,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6
        })
    end

    function TabFunctions:AddTextLabel(text)
        local lbl = Create("Frame", tab, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 22),
            ZIndex = 5
        })

        Create("TextLabel", lbl, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Configs_HUB.Text_Font,
            Text = text,
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6
        })
    end

    function TabFunctions:AddParagraph(title, desc)
        local par = Create("Frame", tab, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Size = UDim2.new(1, -16, 0, 55),
            ZIndex = 5
        })

        Corner(par)
        Stroke(par, {Thickness = 1})

        Create("TextLabel", par, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 6),
            Size = UDim2.new(1, -24, 0, 18),
            Font = Configs_HUB.Text_Font,
            Text = title,
            TextColor3 = Configs_HUB.Cor_Stroke,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6
        })

        Create("TextLabel", par, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 26),
            Size = UDim2.new(1, -24, 0, 22),
            Font = Enum.Font.Gotham,
            Text = desc,
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ZIndex = 6
        })
    end

    function TabFunctions:AddButton(text, callback)
        local btn = Create("TextButton", tab, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Size = UDim2.new(1, -16, 0, 36),
            Text = "",
            AutoButtonColor = true,
            ZIndex = 5
        })

        Corner(btn)
        Stroke(btn, {Thickness = 1})

        local holder = Create("Frame", btn, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
            ZIndex = 6
        })

        Create("UIListLayout", holder, {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8)
        })

        Create("ImageLabel", holder, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 16, 0, 16),
            Image = Configs_HUB.DefaultButtonIcon,
            ImageColor3 = Configs_HUB.Cor_Stroke,
            LayoutOrder = 1,
            ZIndex = 7
        })

        Create("TextLabel", holder, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 1, 0),
            Font = Configs_HUB.Text_Font,
            Text = text,
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ZIndex = 7
        })

        btn.MouseButton1Click:Connect(function()
            TweenService:Create(
                btn,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad),
                {BackgroundColor3 = Color3.fromRGB(28, 28, 28)}
            ):Play()

            task.delay(0.1, function()
                if btn and btn.Parent then
                    TweenService:Create(
                        btn,
                        TweenInfo.new(0.1, Enum.EasingStyle.Quad),
                        {BackgroundColor3 = Configs_HUB.Cor_Options}
                    ):Play()
                end
            end)

            if callback then
                pcall(callback)
            end
        end)
    end

    function TabFunctions:AddToggle(text, default, callback)
        local toggled = default or false

        local btn = Create("TextButton", tab, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Size = UDim2.new(1, -16, 0, 36),
            Font = Configs_HUB.Text_Font,
            Text = "  " .. text,
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = true,
            ZIndex = 5
        })

        Corner(btn)
        Stroke(btn, {Thickness = 1})

        local toggleBg = Create("Frame", btn, {
            BackgroundColor3 = toggled
                and Configs_HUB.Cor_Stroke
                or Color3.fromRGB(35, 35, 35),

            Position = UDim2.new(1, -48, 0.5, -10),
            Size = UDim2.new(0, 40, 0, 20),
            ZIndex = 6
        })

        Corner(toggleBg, {CornerRadius = UDim.new(1, 0)})

        local circle = Create("Frame", toggleBg, {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Position = toggled
                and UDim2.new(1, -18, 0.5, -8)
                or UDim2.new(0, 2, 0.5, -8),

            Size = UDim2.new(0, 16, 0, 16),
            ZIndex = 7
        })

        Corner(circle, {CornerRadius = UDim.new(1, 0)})

        local function update()
            TweenService:Create(
                toggleBg,
                TweenInfo.new(0.2, Enum.EasingStyle.Quart),
                {
                    BackgroundColor3 = toggled
                        and Configs_HUB.Cor_Stroke
                        or Color3.fromRGB(35, 35, 35)
                }
            ):Play()

            TweenService:Create(
                circle,
                TweenInfo.new(0.2, Enum.EasingStyle.Quart),
                {
                    Position = toggled
                        and UDim2.new(1, -18, 0.5, -8)
                        or UDim2.new(0, 2, 0.5, -8)
                }
            ):Play()

            if callback then
                pcall(callback, toggled)
            end
        end

        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            update()
        end)
    end

    function TabFunctions:AddSlider(text, min, max, default, callback)
        local val = default or min
        local dragging = false

        local slider = Create("Frame", tab, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Size = UDim2.new(1, -16, 0, 50),
            ZIndex = 5
        })

        Corner(slider)
        Stroke(slider, {Thickness = 1})

        Create("TextLabel", slider, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(1, -24, 0, 16),
            Font = Configs_HUB.Text_Font,
            Text = text,
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6
        })

        local valLbl = Create("TextLabel", slider, {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -100, 0, 8),
            Size = UDim2.new(0, 88, 0, 16),
            Font = Configs_HUB.Text_Font,
            Text = tostring(val),
            TextColor3 = Configs_HUB.Cor_Stroke,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 6
        })

        local sliderBar = Create("Frame", slider, {
            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
            Position = UDim2.new(0, 12, 0, 32),
            Size = UDim2.new(1, -24, 0, 6),
            ZIndex = 6
        })

        Corner(sliderBar, {CornerRadius = UDim.new(1, 0)})

        local initialAlpha = 0
        if max ~= min then
            initialAlpha = math.clamp((val - min) / (max - min), 0, 1)
        end

        local fill = Create("Frame", sliderBar, {
            BackgroundColor3 = Configs_HUB.Cor_Stroke,
            Size = UDim2.new(initialAlpha, 0, 1, 0),
            ZIndex = 7
        })

        Corner(fill, {CornerRadius = UDim.new(1, 0)})

        local function update(input)
            if sliderBar.AbsoluteSize.X <= 0 then
                return
            end

            local alpha = math.clamp(
                (input.Position.X - sliderBar.AbsolutePosition.X)
                    / sliderBar.AbsoluteSize.X,
                0,
                1
            )

            TweenService:Create(
                fill,
                TweenInfo.new(0.08, Enum.EasingStyle.Quart),
                {Size = UDim2.new(alpha, 0, 1, 0)}
            ):Play()

            val = math.floor(min + ((max - min) * alpha))
            valLbl.Text = tostring(val)

            if callback then
                pcall(callback, val)
            end
        end

        sliderBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = true
                update(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging
                and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then

                update(input)
            end
        end)
    end

    function TabFunctions:AddTextbox(text, placeholder, callback)
        local box = Create("Frame", tab, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Size = UDim2.new(1, -16, 0, 36),
            ZIndex = 5
        })

        Corner(box)
        Stroke(box, {Thickness = 1})

        Create("TextLabel", box, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 150, 1, 0),
            Font = Configs_HUB.Text_Font,
            Text = text,
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6
        })

        local textbox = Create("TextBox", box, {
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            Position = UDim2.new(1, -155, 0.5, -11),
            Size = UDim2.new(0, 145, 0, 22),
            Font = Enum.Font.Gotham,
            PlaceholderText = placeholder or "",
            Text = "",
            TextColor3 = Configs_HUB.Cor_Text,
            PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
            TextSize = 10,
            ZIndex = 6
        })

        Corner(textbox, {CornerRadius = UDim.new(0, 4)})
        Stroke(textbox, {Thickness = 1})

        textbox.FocusLost:Connect(function(enterPressed)
            if callback then
                pcall(callback, textbox.Text, enterPressed)
            end
        end)
    end

    function TabFunctions:AddDropdown(text, options, callback)
        local isOpen = false
        local selectedOption = options[1] or ""

        local dropFrame = Create("Frame", tab, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Size = UDim2.new(1, -16, 0, 36),
            ClipsDescendants = true,
            ZIndex = 15
        })

        Corner(dropFrame)
        Stroke(dropFrame, {Thickness = 1})

        local btn = Create("TextButton", dropFrame, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 36),
            Font = Configs_HUB.Text_Font,
            Text = "  " .. text .. " :  " .. selectedOption,
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 16
        })

        local arrow = Create("TextLabel", btn, {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -30, 0, 0),
            Size = UDim2.new(0, 20, 0, 36),
            Font = Configs_HUB.Text_Font,
            Text = "+",
            TextColor3 = Configs_HUB.Cor_Stroke,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 17
        })

        local container = Create("Frame", dropFrame, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 38),
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 16
        })

        Create("UIListLayout", container, {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top
        })

        for _, opt in ipairs(options) do
            local optBtn = Create("TextButton", container, {
                BackgroundColor3 = Color3.fromRGB(18, 18, 18),
                Size = UDim2.new(1, -16, 0, 32),
                Font = Enum.Font.Gotham,
                Text = opt,
                TextColor3 = Configs_HUB.Cor_Text,
                TextSize = 10,
                AutoButtonColor = true,
                ZIndex = 17
            })

            Corner(optBtn, {CornerRadius = UDim.new(0, 6)})
            Stroke(optBtn, {Thickness = 1})

            optBtn.MouseButton1Click:Connect(function()
                selectedOption = opt
                btn.Text = "  " .. text .. " :  " .. selectedOption
                isOpen = false
                arrow.Text = "+"

                TweenService:Create(
                    dropFrame,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                    {Size = UDim2.new(1, -16, 0, 36)}
                ):Play()

                if callback then
                    pcall(callback, selectedOption)
                end
            end)
        end

        btn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            arrow.Text = isOpen and "-" or "+"

            local contentHeight = (#options * 38) + 12
            local targetHeight = isOpen and (36 + contentHeight) or 36

            TweenService:Create(
                dropFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                {Size = UDim2.new(1, -16, 0, targetHeight)}
            ):Play()
        end)
    end

    function TabFunctions:AddKeybind(text, defaultKey, callback)
        local boundKey = defaultKey or Enum.KeyCode.RightShift
        local binding = false

        local bindFrame = Create("Frame", tab, {
            BackgroundColor3 = Configs_HUB.Cor_Options,
            Size = UDim2.new(1, -16, 0, 36),
            ZIndex = 5
        })

        Corner(bindFrame)
        Stroke(bindFrame, {Thickness = 1})

        Create("TextLabel", bindFrame, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(0, 200, 1, 0),
            Font = Configs_HUB.Text_Font,
            Text = text,
            TextColor3 = Configs_HUB.Cor_Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6
        })

        local bindBtn = Create("TextButton", bindFrame, {
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            Position = UDim2.new(1, -110, 0.5, -11),
            Size = UDim2.new(0, 100, 0, 22),
            Font = Enum.Font.Gotham,
            Text = typeof(boundKey) == "EnumItem"
                and boundKey.Name
                or tostring(boundKey),

            TextColor3 = Configs_HUB.Cor_Stroke,
            TextSize = 10,
            AutoButtonColor = true,
            ZIndex = 6
        })

        Corner(bindBtn, {CornerRadius = UDim.new(0, 4)})
        Stroke(bindBtn, {Thickness = 1})

        bindBtn.MouseButton1Click:Connect(function()
            binding = true
            bindBtn.Text = "..."

            task.spawn(function()
                local input = UserInputService.InputBegan:Wait()

                if input.UserInputType == Enum.UserInputType.Keyboard then
                    boundKey = input.KeyCode
                    bindBtn.Text = boundKey.Name
                end

                binding = false
            end)
        end)

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed
                and not binding
                and input.KeyCode == boundKey then

                if callback then
                    pcall(callback, boundKey)
                end
            end
        end)
    end

    function TabFunctions:AddColorPicker(Configs)
        Configs = Configs or {}

        local name = Configs.Name or "Color Picker"
        local Default = Configs.Default or Color3.fromRGB(255, 0, 0)
        local Callback = Configs.Callback or function() end

        local ColorH, ColorS, ColorV = Default:ToHSV()

        local TextButton = Create("Frame", tab, {
            Size = UDim2.new(1, -16, 0, 36),
            BackgroundColor3 = Configs_HUB.Cor_Options,
            ClipsDescendants = true,
            ZIndex = 15
        })

        Corner(TextButton)
        Stroke(TextButton)

        local click = Create("TextButton", TextButton, {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 25
        })

        local TextLabel = Create("TextLabel", TextButton, {
            Size = UDim2.new(1, -50, 0, 36),
            Position = UDim2.new(0, 35, 0, 0),
            TextSize = 11,
            TextColor3 = Configs_HUB.Cor_Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = name,
            Font = Configs_HUB.Text_Font,
            BackgroundTransparency = 1,
            ZIndex = 16
        })

        local picker = Create("Frame", TextButton, {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = Default,
            ZIndex = 16
        })

        Corner(picker)
        Stroke(picker)

        local colorContainer = Create("Frame", TextButton, {
            Size = UDim2.new(1, -24, 0, 85),
            Position = UDim2.new(0, 12, 0, 40),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 16
        })

        local UI_Grade = Create("ImageButton", colorContainer, {
            Size = UDim2.new(1, -35, 0, 80),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1),
            Image = "rbxassetid://4155801252",
            AutoButtonColor = false,
            Active = true,
            ZIndex = 16
        })

        Corner(UI_Grade)
        Stroke(UI_Grade)

        local grade = Create("TextButton", colorContainer, {
            Size = UDim2.new(0, 25, 0, 80),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            Text = "",
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            AutoButtonColor = false,
            Active = true,
            ZIndex = 16
        })

        Corner(grade)
        Stroke(grade)

        Create("UIGradient", grade, {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
                ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
                ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
                ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
                ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
            })
        })

        local Select1 = Create("Frame", grade, {
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.15,
            Active = true,
            ZIndex = 20
        })

        Corner(Select1, {CornerRadius = UDim.new(1, 0)})
        Stroke(Select1, {Color = Color3.fromRGB(255, 255, 255), Thickness = 1})

        local Select2 = Create("Frame", UI_Grade, {
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.15,
            Active = true,
            ZIndex = 20
        })

        Corner(Select2, {CornerRadius = UDim.new(1, 0)})
        Stroke(Select2, {Color = Color3.fromRGB(255, 255, 255), Thickness = 1})

        local function getSVSize()
            return math.max(1, UI_Grade.AbsoluteSize.X), math.max(1, UI_Grade.AbsoluteSize.Y)
        end

        local function updateFromColor()
            local w, h = getSVSize()
            local sx = math.clamp(ColorS * math.max(1, w - 12), 0, math.max(0, w - 12))
            local sy = math.clamp((1 - ColorV) * math.max(1, h - 12), 0, math.max(0, h - 12))
            local hy = math.clamp(ColorH * math.max(0, grade.AbsoluteSize.Y - 8), 0, math.max(0, grade.AbsoluteSize.Y - 8))

            Select2.Position = UDim2.new(0, sx, 0, sy)
            Select1.Position = UDim2.new(0, 0, 0, hy)
            UI_Grade.ImageColor3 = Color3.fromHSV(ColorH, 1, 1)
            picker.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
        end

        local function fireCallback()
            local selectedColor = Color3.fromHSV(ColorH, ColorS, ColorV)
            DRKLib:SetThemeColor(selectedColor)
            pcall(Callback, selectedColor)
        end

        local function updateSV(position)
            local pos = UI_Grade.AbsolutePosition
            local size = UI_Grade.AbsoluteSize
            local maxX = math.max(1, size.X - 12)
            local maxY = math.max(1, size.Y - 12)
            local x = math.clamp(position.X - pos.X - 6, 0, maxX)
            local y = math.clamp(position.Y - pos.Y - 6, 0, maxY)

            ColorS = math.clamp(x / maxX, 0, 1)
            ColorV = math.clamp(1 - (y / maxY), 0, 1)

            Select2.Position = UDim2.new(0, x, 0, y)
            UI_Grade.ImageColor3 = Color3.fromHSV(ColorH, 1, 1)
            picker.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
            fireCallback()
        end

        local function updateHue(position)
            local pos = grade.AbsolutePosition
            local size = grade.AbsoluteSize
            local maxY = math.max(1, size.Y - 8)
            local y = math.clamp(position.Y - pos.Y - 4, 0, maxY)

            ColorH = math.clamp(y / maxY, 0, 1)
            Select1.Position = UDim2.new(0, 0, 0, y)
            UI_Grade.ImageColor3 = Color3.fromHSV(ColorH, 1, 1)
            picker.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
            fireCallback()
        end

        local draggingSV = false
        local draggingHue = false

        UI_Grade.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSV = true
                updateSV(input.Position)
            end
        end)

        grade.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingHue = true
                updateHue(input.Position)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if draggingSV then
                    updateSV(input.Position)
                elseif draggingHue then
                    updateHue(input.Position)
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingSV = false
                draggingHue = false
            end
        end)

        local onoff = false

        click.MouseButton1Click:Connect(function()
            onoff = not onoff

            if onoff then
                colorContainer.Visible = true
                TweenService:Create(
                    TextButton,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                    {Size = UDim2.new(1, -16, 0, 135)}
                ):Play()
            else
                TweenService:Create(
                    TextButton,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart),
                    {Size = UDim2.new(1, -16, 0, 36)}
                ):Play()

                task.delay(0.25, function()
                    if not onoff then
                        colorContainer.Visible = false
                    end
                end)
            end
        end)

        task.defer(function()
            updateFromColor()
        end)
    end

    return TabFunctions
end

return DRKLib
