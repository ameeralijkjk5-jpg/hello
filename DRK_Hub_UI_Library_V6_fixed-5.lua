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
  Cor_Hub = Color3.fromRGB(8, 8, 8), 
  Cor_Options = Color3.fromRGB(15, 15, 15), 
  Cor_Stroke = Color3.fromRGB(255, 0, 40), 
  Cor_Text = Color3.fromRGB(240, 240, 240), 
  Corner_Radius = UDim.new(0, 10), 
  Text_Font = Enum.Font.GothamBold,
  DefaultButtonIcon = "rbxassetid://92615117311099"
}

local ActiveStrokes = {}
local CurrentWindowRef = nil
local CurrentWindowSize = Vector2.new(540, 330)

local function Create(instance, parent, props)
  local new = Instance.new(instance)
  if props then
    for prop, value in pairs(props) do
      if type(prop) == "string" then
        new[prop] = value
      end
    end
  end
  if parent then
    new.Parent = parent
  end
  return new
end

local function Corner(parent, props)
  local new = Instance.new("UICorner", parent)
  new.CornerRadius = Configs_HUB.Corner_Radius
  if props then
    for prop, value in pairs(props) do new[prop] = value end
  end
  return new
end

local function Stroke(parent, props)
  local new = Create("UIStroke", parent)
  local strokeColor = (props and props.Color) or Configs_HUB.Cor_Stroke
  new.Color = strokeColor
  new.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  new.Thickness = (props and props.Thickness) or 1.2
  table.insert(ActiveStrokes, new)

  local gradient = Instance.new("UIGradient")
  gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
    ColorSequenceKeypoint.new(0.5, strokeColor),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
  }
  gradient.Rotation = 0
  gradient.Parent = new

  task.spawn(function()
    while new.Parent do
      gradient.Rotation = (gradient.Rotation + 2) % 360
      task.wait(0.05)
    end
  end)

  if props then
    for prop, value in pairs(props) do
      if prop ~= "Color" and prop ~= "Thickness" then
        new[prop] = value
      end
    end
  end
  return new
end
function DRKLib:SetThemeColor(newColor)
  if typeof(newColor) ~= "Color3" then
    return
  end

  local oldColor = Configs_HUB.Cor_Stroke
  Configs_HUB.Cor_Stroke = newColor

  local function isColorPickerObject(obj)
    local current = obj
    while current do
      if current:GetAttribute("DRK_ColorPicker") then
        return true
      end
      current = current.Parent
    end
    return false
  end

  local function replaceColor(obj, property)
    if isColorPickerObject(obj) then
      return
    end

    local ok, value = pcall(function()
      return obj[property]
    end)

    if ok and typeof(value) == "Color3" and value == oldColor then
      pcall(function()
        obj[property] = newColor
      end)
    end
  end

  for _, stroke in ipairs(ActiveStrokes) do
    if stroke and stroke.Parent and not isColorPickerObject(stroke) then
      local customColor = stroke:GetAttribute("DRK_CustomStroke")
      if not customColor then
        stroke.Color = newColor
      end

      for _, child in ipairs(stroke:GetChildren()) do
        if child:IsA("UIGradient") then
          child.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
            ColorSequenceKeypoint.new(0.5, newColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
          }
        end
      end
    end
  end

  if CurrentWindowRef and CurrentWindowRef.Parent then
    for _, obj in ipairs(CurrentWindowRef:GetDescendants()) do
      if not isColorPickerObject(obj) then
        replaceColor(obj, "BackgroundColor3")
        replaceColor(obj, "TextColor3")
        replaceColor(obj, "ImageColor3")
        replaceColor(obj, "ScrollBarImageColor3")
        replaceColor(obj, "PlaceholderColor3")

        if obj:IsA("UIGradient") then
          local sequence = obj.Color
          local points = sequence.Keypoints
          local changed = false
          local rebuilt = {}

          for _, point in ipairs(points) do
            local color = point.Value
            if color == oldColor then
              color = newColor
              changed = true
            end
            table.insert(rebuilt, ColorSequenceKeypoint.new(point.Time, color))
          end

          if changed then
            obj.Color = ColorSequence.new(rebuilt)
          end
        end
      end
    end
  end
end

function DRKLib:SetWindowSize(width, height)
  width = tonumber(width) or 540
  height = tonumber(height) or 330
  CurrentWindowSize = Vector2.new(width, height)
  if CurrentWindowRef and CurrentWindowRef.Parent then
    TweenService:Create(CurrentWindowRef, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
      Size = UDim2.new(0, width, 0, height)
    }):Play()
  end
end

local function ShowNotification(parentGui, text, color)
    local notif = Create("Frame", parentGui, {
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
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

    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -125, 0, 20)}):Play()
    task.delay(2.5, function()
        if notif and notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -125, 0, -50)}):Play()
            task.wait(0.3)
            notif:Destroy()
        end
    end)
end

function DRKLib:CreateWindow(titleText, customMinimizeConfig, keyConfig)
  local self = setmetatable({}, DRKLib)
  
  local oldGui = nil
  pcall(function()
    oldGui = CoreGui:FindFirstChild("DRK_Library_Gui")
  end)
  if oldGui then
    oldGui:Destroy()
  end
  pcall(function()
    local hui = gethui and gethui()
    if hui then
      local existing = hui:FindFirstChild("DRK_Library_Gui")
      if existing then existing:Destroy() end
    end
  end)

  local ScreenGui = Create("ScreenGui", nil, {
    Name = "DRK_Library_Gui",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false
  })

  if syn and syn.protect_gui then
      syn.protect_gui(ScreenGui)
  elseif protectgui then
      protectgui(ScreenGui)
  end
  local guiParent = CoreGui
  if gethui and type(gethui) == "function" then
    local ok, hui = pcall(gethui)
    if ok and hui then
      guiParent = hui
    end
  end
  ScreenGui.Parent = guiParent

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
        BackgroundColor3 = Color3.fromRGB(12, 12, 12),
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
        TextColor3 = Color3.fromRGB(255, 50, 70),
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
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
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
                  ShowNotification(ScreenGui, keyConfig.Notifi.CorrectKey or "Running the Script...", Color3.fromRGB(50, 255, 50))
              end
              KeyUnlocked = true
              TweenService:Create(KeyMainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)}):Play()
              task.wait(0.3)
              KeyMainFrame:Destroy()
          else
              if keyConfig.Notifi and keyConfig.Notifi.Notifications then
                  ShowNotification(ScreenGui, keyConfig.Notifi.Incorrectkey or "The key is incorrect", Color3.fromRGB(255, 50, 50))
              end
          end
      end)

      GetKeyBtn.MouseButton1Click:Connect(function()
          if keyConfig.KeyLink and keyConfig.KeyLink ~= "" then
              if setclipboard then
                  setclipboard(keyConfig.KeyLink)
                  if keyConfig.Notifi and keyConfig.Notifi.Notifications then
                      ShowNotification(ScreenGui, keyConfig.Notifi.CopyKeyLink or "Copied to Clipboard", Color3.fromRGB(50, 150, 255))
                  end
              end
          end
      end)

      repeat task.wait() until KeyUnlocked
  end

  local minConfig = customMinimizeConfig or {}
    local minSize = minConfig.Size and UDim2.new(0, minConfig.Size[1], 0, minConfig.Size[2]) or UDim2.new(0, 40, 0, 40)
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
    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
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
    Text = titleText or "DRK Hub | Library",
    TextColor3 = Color3.fromRGB(255, 50, 70),
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 51
  })

  local dragging, dragInput, dragStart, startPos
  TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
      dragInput = input
    end
  end)

  UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
      local delta = input.Position - dragStart
      MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
  end)

  local CloseButton = Create("TextButton", TopBar, {
    BackgroundColor3 = Color3.fromRGB(200, 30, 40),
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
      ScreenGui:Destroy()
  end)

  local MinimizeButton = Create("TextButton", TopBar, {
    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
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
    BackgroundColor3 = Color3.fromRGB(11, 11, 11),
    Position = UDim2.new(0, 8, 0, 43),
    Size = UDim2.new(0, 140, 1, -51),
    ClipsDescendants = true,
    ZIndex = 5
  })
  table.insert(self.HubElements, TabsContainer)
  Corner(TabsContainer, {CornerRadius = UDim.new(0, 8)})
  Stroke(TabsContainer)

  local CollapseBtn = Create("TextButton", MainFrame, {
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
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
      local targetTabsSize = isCollapsed and UDim2.new(0, 0, 1, -51) or UDim2.new(0, 140, 1, -51)
      local targetBtnPos = isCollapsed and UDim2.new(0, 10, 0, 43) or UDim2.new(0, 151, 0, 43)
      local targetContentPos = isCollapsed and UDim2.new(0, 18, 0, 43) or UDim2.new(0, 155, 0, 43)
      local targetContentSize = isCollapsed and UDim2.new(1, -26, 1, -51) or UDim2.new(1, -163, 1, -51)
      
      CollapseBtn.Text = isCollapsed and ">" or "<"
      
      TweenService:Create(TabsContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = targetTabsSize}):Play()
      TweenService:Create(CollapseBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Position = targetBtnPos}):Play()
      TweenService:Create(ContentContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Position = targetContentPos, Size = targetContentSize}):Play()
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
          BackgroundColor3 = Color3.fromRGB(88, 101, 242),
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
              setclipboard(inviteLink or "https://discord.gg/yourinvite")
              ShowNotification(ScreenGui, "Copied Discord Link to Clipboard!", Color3.fromRGB(88, 101, 242))
          end
      end)

      self.InnerTabsList.Size = UDim2.new(1, -12, 1, -54)
  end

  do
      local settingsTab = Create("ScrollingFrame", self.ContentContainer, {
        BackgroundColor3 = Color3.fromRGB(11, 11, 11),
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
      Create("UIPadding", settingsTab, { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12) })

      settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
          settingsTab.CanvasSize = UDim2.new(0, 0, 0, settingsLayout.AbsoluteContentSize.Y + 26)
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
                  TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(12, 12, 12), TextColor3 = Color3.fromRGB(160, 160, 160)}):Play()
              end
          end
          TweenService:Create(settingsTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
      end)

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
                  BackgroundColor3 = Color3.fromRGB(20, 20, 20),
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
                  TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -16, 0, 36)}):Play()
                  
                  if opt == "Small" then
                      DRKLib:SetWindowSize(450, 280)
                  elseif opt == "Normal" then
                      DRKLib:SetWindowSize(540, 330)
                  elseif opt == "Large" then
                      DRKLib:SetWindowSize(620, 390)
                  elseif opt == "Extra Large" then
                      DRKLib:SetWindowSize(720, 460)
                  end
                  ShowNotification(ScreenGui, "Window Size: " .. opt, Configs_HUB.Cor_Stroke)
              end)
          end

          btn.MouseButton1Click:Connect(function()
              isOpen = not isOpen
              arrow.Text = isOpen and "-" or "+"
              local contentHeight = (#options * 38) + 12
              local targetHeight = isOpen and (36 + contentHeight) or 36
              
              TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                  Size = UDim2.new(1, -16, 0, targetHeight)
              }):Play()
          end)
      end

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
                  BackgroundColor3 = Color3.fromRGB(20, 20, 20),
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
                  TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -16, 0, 36)}):Play()
                  
                  DRKLib:SetThemeColor(colData.Color)
                  ShowNotification(ScreenGui, "Theme Color: " .. colData.Name, colData.Color)
              end)
          end

          btn.MouseButton1Click:Connect(function()
              isOpen = not isOpen
              arrow.Text = isOpen and "-" or "+"
              local contentHeight = (#colorOptions * 38) + 12
              local targetHeight = isOpen and (36 + contentHeight) or 36
              
              TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                  Size = UDim2.new(1, -16, 0, targetHeight)
              }):Play()
          end)
      end
  end

  local MinimizeFloatingBtn = Create("ImageButton", ScreenGui, {
    BackgroundColor3 = minColor,
    Position = UDim2.new(0.05, 0, 0.15, 0),
    Size = minSize,
    Image = minImage,
    AutoButtonColor = true,
    Draggable = true,
    Active = true,
    ZIndex = 100
  })

  if minImage == "" then
      Create("TextLabel", MinimizeFloatingBtn, {
          BackgroundTransparency = 1,
          Size = UDim2.new(1, 0, 1, 0),
          Font = Configs_HUB.Text_Font,
          Text = "DRK",
          TextColor3 = Configs_HUB.Cor_Stroke,
          TextSize = 10,
          ZIndex = 101
      })
  end

  if hasCorner then
      Corner(MinimizeFloatingBtn, {CornerRadius = UDim.new(1, 0)})
  end
  
  if hasStroke then
      Stroke(MinimizeFloatingBtn, {Color = strokeColor})
  end

  local isMinimized = false
  MinimizeButton.MouseButton1Click:Connect(function()
      isMinimized = not isMinimized
      if isMinimized then
          for _, element in ipairs(self.HubElements) do
              element.Visible = false
          end
          CollapseBtn.Visible = false
          TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, CurrentWindowSize.X, 0, 35)}):Play()
          MinimizeButton.Text = "+"
      else
          TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, CurrentWindowSize.X, 0, CurrentWindowSize.Y)}):Play()
          task.wait(0.15)
          for _, element in ipairs(self.HubElements) do
              element.Visible = true
          end
          CollapseBtn.Visible = true
          MinimizeButton.Text = "-"
      end
  end)

  local isWindowMinimized = false
  MinimizeFloatingBtn.MouseButton1Click:Connect(function()
      isWindowMinimized = not isWindowMinimized
      MainFrame.Visible = not isWindowMinimized
  end)

  return self
end

function DRKLib:CreateTab(tabName, tabIcon)
  local tab = Create("ScrollingFrame", self.ContentContainer, {
    BackgroundColor3 = Color3.fromRGB(11, 11, 11),
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
  
  Create("UIPadding", tab, { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12) })

  tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
      tab.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 26)
  end)

  local tabBtn = Create("TextButton", self.InnerTabsList, {
    BackgroundColor3 = self.FirstTab and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(12, 12, 12),
    Size = UDim2.new(1, 0, 0, 32),
    Font = Configs_HUB.Text_Font,
    Text = tabName,
    TextColor3 = self.FirstTab and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160),
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
              TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(12, 12, 12), TextColor3 = Color3.fromRGB(160, 160, 160)}):Play()
          end
      end
      TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
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
        TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
        task.delay(0.1, function()
            if btn and btn.Parent then
                TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {BackgroundColor3 = Configs_HUB.Cor_Options}):Play()
            end
        end)
        if callback then pcall(callback) end
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
        BackgroundColor3 = toggled and Configs_HUB.Cor_Stroke or Color3.fromRGB(35, 35, 35),
        Position = UDim2.new(1, -48, 0.5, -10),
        Size = UDim2.new(0, 40, 0, 20),
        ZIndex = 6
    })
    Corner(toggleBg, {CornerRadius = UDim.new(1, 0)})

    local circle = Create("Frame", toggleBg, {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        ZIndex = 7
    })
    Corner(circle, {CornerRadius = UDim.new(1, 0)})

    local function update()
        TweenService:Create(toggleBg, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            BackgroundColor3 = toggled and Configs_HUB.Cor_Stroke or Color3.fromRGB(35, 35, 35)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
        if callback then pcall(callback, toggled) end
    end

    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        update()
    end)
  end

  function TabFunctions:AddSlider(text, min, max, default, callback)
    min = tonumber(min) or 0
    max = tonumber(max) or 100
    if min > max then
      min, max = max, min
    end
    if min == max then
      max = min + 1
    end
    local val = math.clamp(tonumber(default) or min, min, max)
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

    local fill = Create("Frame", sliderBar, {
        BackgroundColor3 = Configs_HUB.Cor_Stroke,
        Size = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), 0, 1, 0),
        ZIndex = 7
    })
    Corner(fill, {CornerRadius = UDim.new(1, 0)})

    local function update(input)
        local pos = UDim2.new(math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1), 0, 1, 0)
        TweenService:Create(fill, TweenInfo.new(0.08, Enum.EasingStyle.Quart), {Size = pos}):Play()
        val = math.floor(min + ((max - min) * pos.X.Scale) + 0.5)
        val = math.clamp(val, min, max)
        valLbl.Text = tostring(val)
        if callback then pcall(callback, val) end
    end

    if callback then
      pcall(callback, val)
    end

    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
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
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
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
        if callback then pcall(callback, textbox.Text, enterPressed) end
    end)
  end

  function TabFunctions:AddDropdown(text, options, callback)
    options = type(options) == "table" and options or {}
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
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
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
            TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -16, 0, 36)}):Play()
            if callback then pcall(callback, selectedOption) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        arrow.Text = isOpen and "-" or "+"
        local contentHeight = (#options * 38) + 12
        local targetHeight = isOpen and (36 + contentHeight) or 36
        
        TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -16, 0, targetHeight)
        }):Play()
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
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Position = UDim2.new(1, -110, 0.5, -11),
        Size = UDim2.new(0, 100, 0, 22),
        Font = Enum.Font.Gotham,
        Text = typeof(boundKey) == "EnumItem" and boundKey.Name or tostring(boundKey),
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
        if not gameProcessed and not binding and input.KeyCode == boundKey then
            if callback then pcall(callback, boundKey) end
        end
    end)
  end

  function TabFunctions:AddColorPicker(Configs)
    Configs = type(Configs) == "table" and Configs or {}

    local name = Configs.Name or "Color Picker"
    local Default = Configs.Default
    if typeof(Default) ~= "Color3" then
      Default = Color3.fromRGB(0, 0, 200)
    end

    local Callback = type(Configs.Callback) == "function" and Configs.Callback or function() end
    local ColorH, ColorS, ColorV = Color3.toHSV(Default)
    local pickerOpen = false
    local draggingHue = false
    local draggingSV = false

    local TextButton = Create("Frame", tab, {
      Size = UDim2.new(1, -16, 0, 36),
      BackgroundColor3 = Configs_HUB.Cor_Options,
      ClipsDescendants = true,
      ZIndex = 15
    })
    Corner(TextButton)
    Stroke(TextButton)
    TextButton:SetAttribute("DRK_ColorPicker", true)

    local click = Create("TextButton", TextButton, {
      Size = UDim2.new(1, 0, 0, 36),
      BackgroundTransparency = 1,
      AutoButtonColor = false,
      Text = "",
      ZIndex = 25
    })

    Create("TextLabel", TextButton, {
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
      ZIndex = 26
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
      BackgroundTransparency = 0,
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      Image = "rbxassetid://4155801252",
      ImageColor3 = Color3.fromHSV(ColorH, 1, 1),
      AutoButtonColor = false,
      ZIndex = 16
    })
    Corner(UI_Grade)
    Stroke(UI_Grade)

    local hueBar = Create("ImageButton", colorContainer, {
      Size = UDim2.new(0, 25, 0, 80),
      Position = UDim2.new(1, -25, 0, 0),
      BackgroundTransparency = 0,
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      Image = "",
      AutoButtonColor = false,
      ZIndex = 16
    })
    Corner(hueBar)
    Stroke(hueBar)

    Create("UIGradient", hueBar, {
      Rotation = 90,
      Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(234, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(21, 255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 17, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 251)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
      })
    })

    local hueSelector = Create("Frame", hueBar, {
      Size = UDim2.new(1, 0, 0, 8),
      Position = UDim2.new(0, 0, 0, 0),
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = 0.25,
      Active = false,
      ZIndex = 20
    })
    Corner(hueSelector, {CornerRadius = UDim.new(1, 0)})
    Stroke(hueSelector, {Color = Color3.fromRGB(255, 255, 255), Thickness = 1})

    local svSelector = Create("Frame", UI_Grade, {
      Size = UDim2.new(0, 12, 0, 12),
      Position = UDim2.new(0, 0, 0, 0),
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = 0.2,
      Active = false,
      ZIndex = 20
    })
    Corner(svSelector, {CornerRadius = UDim.new(1, 0)})
    Stroke(svSelector, {Color = Color3.fromRGB(255, 255, 255), Thickness = 1})

    local function applyColor()
      local color = Color3.fromHSV(ColorH, ColorS, ColorV)
      picker.BackgroundColor3 = color
      UI_Grade.ImageColor3 = Color3.fromHSV(ColorH, 1, 1)
      pcall(Callback, color)
    end

    local function updateHue(y)
      local height = math.max(1, hueBar.AbsoluteSize.Y - 8)
      local offset = math.clamp(y - hueBar.AbsolutePosition.Y - 4, 0, height)
      ColorH = offset / height
      hueSelector.Position = UDim2.new(0, 0, 0, offset)
      applyColor()
    end

    local function updateSV(x, y)
      local width = math.max(1, UI_Grade.AbsoluteSize.X - 12)
      local height = math.max(1, UI_Grade.AbsoluteSize.Y - 12)
      local xOffset = math.clamp(x - UI_Grade.AbsolutePosition.X - 6, 0, width)
      local yOffset = math.clamp(y - UI_Grade.AbsolutePosition.Y - 6, 0, height)

      ColorS = 1 - (xOffset / width)
      ColorV = 1 - (yOffset / height)

      svSelector.Position = UDim2.new(0, xOffset, 0, yOffset)
      applyColor()
    end

    local function refreshSelectors()
      local hueHeight = math.max(1, hueBar.AbsoluteSize.Y - 8)
      local svWidth = math.max(1, UI_Grade.AbsoluteSize.X - 12)
      local svHeight = math.max(1, UI_Grade.AbsoluteSize.Y - 12)

      hueSelector.Position = UDim2.new(0, 0, 0, math.clamp(ColorH * hueHeight, 0, hueHeight))
      svSelector.Position = UDim2.new(
        0,
        math.clamp((1 - ColorS) * svWidth, 0, svWidth),
        0,
        math.clamp((1 - ColorV) * svHeight, 0, svHeight)
      )
      UI_Grade.ImageColor3 = Color3.fromHSV(ColorH, 1, 1)
      picker.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
    end

    hueBar.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingHue = true
        updateHue(input.Position.Y)
      end
    end)

    UI_Grade.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSV = true
        updateSV(input.Position.X, input.Position.Y)
      end
    end)

    UserInputService.InputChanged:Connect(function(input)
      if draggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateHue(input.Position.Y)
      elseif draggingSV and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSV(input.Position.X, input.Position.Y)
      end
    end)

    UserInputService.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingHue = false
        draggingSV = false
      end
    end)

    click.MouseButton1Click:Connect(function()
      pickerOpen = not pickerOpen

      if pickerOpen then
        colorContainer.Visible = true
        refreshSelectors()
        TweenService:Create(TextButton, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
          Size = UDim2.new(1, -16, 0, 135)
        }):Play()
      else
        TweenService:Create(TextButton, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
          Size = UDim2.new(1, -16, 0, 36)
        }):Play()
        task.delay(0.3, function()
          if not pickerOpen and colorContainer.Parent then
            colorContainer.Visible = false
          end
        end)
      end
    end)

    UI_Grade:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshSelectors)
    hueBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshSelectors)

    refreshSelectors()
    pcall(Callback, Default)
  end
  return TabFunctions
end

return DRKLib