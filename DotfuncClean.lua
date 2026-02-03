local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local ViewportSize = workspace.CurrentCamera.ViewportSize

local Icons = (function()
    local IconModule = {
        IconsType = "lucide",
        New = nil,
        IconThemeTag = nil,
        Icons = {
            ["lucide"] = {},
            ["craft"] = {},
            ["geist"] = {},
            ["sfsymbols"] = {},
        },
    }
    
    local function safeLoad(url)
        local success, result = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        return success and result or {}
    end
    
    IconModule.Icons["lucide"] = safeLoad("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua")
    IconModule.Icons["craft"] = safeLoad("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua")
    IconModule.Icons["geist"] = safeLoad("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua")
    IconModule.Icons["sfsymbols"] = safeLoad("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/sfsymbols/dist/Icons.lua")
    
    local function parseIconString(iconString)
        if type(iconString) == "string" then
            local splitIndex = iconString:find(":")
            if splitIndex then
                local iconType = iconString:sub(1, splitIndex - 1)
                local iconName = iconString:sub(splitIndex + 1)
                return iconType, iconName
            end
        end
        return nil, iconString
    end
    
    function IconModule.AddIcons(packName, iconsData)
        if type(packName) ~= "string" or type(iconsData) ~= "table" then
            error("AddIcons: packName must be string, iconsData must be table")
            return
        end
      
        if not IconModule.Icons[packName] then
            IconModule.Icons[packName] = { Icons = {}, Spritesheets = {} }
        end
      
        for iconName, iconValue in pairs(iconsData) do
            if type(iconValue) == "number" or (type(iconValue) == "string" and iconValue:match("^rbxassetid://")) then
                local imageId = type(iconValue) == "number" and "rbxassetid://" .. iconValue or iconValue
                IconModule.Icons[packName].Icons[iconName] = {
                    Image = imageId,
                    ImageRectSize = Vector2.new(0, 0),
                    ImageRectPosition = Vector2.new(0, 0),
                    Parts = nil
                }
                IconModule.Icons[packName].Spritesheets[imageId] = imageId
            elseif type(iconValue) == "table" and iconValue.Image then
                local imageId = type(iconValue.Image) == "number" and "rbxassetid://" .. iconValue.Image or iconValue.Image
                IconModule.Icons[packName].Icons[iconName] = {
                    Image = imageId,
                    ImageRectSize = iconValue.ImageRectSize or Vector2.new(0,0),
                    ImageRectPosition = iconValue.ImageRectPosition or Vector2.new(0,0),
                    Parts = iconValue.Parts
                }
                IconModule.Icons[packName].Spritesheets[imageId] = imageId
            end
        end
    end
    
    function IconModule.SetIconsType(iconType)
        IconModule.IconsType = iconType
    end
    
    function IconModule.Init(New, IconThemeTag)
        IconModule.New = New
        IconModule.IconThemeTag = IconThemeTag
        return IconModule
    end
    
    function IconModule.Icon(Icon, Type)
        local iconType, iconName = parseIconString(Icon)
        local targetType = iconType or Type or IconModule.IconsType
        local targetName = iconName or Icon
        local iconSet = IconModule.Icons[targetType]
        if not iconSet then return nil end
        
        if iconSet[targetName] and (type(iconSet[targetName]) == "string" or type(iconSet[targetName]) == "number") then
            local asset = type(iconSet[targetName]) == "number" and "rbxassetid://" .. iconSet[targetName] or iconSet[targetName]
            return { asset, { ImageRectSize = Vector2.new(0,0), ImageRectPosition = Vector2.new(0,0), Parts = nil } }
        end
        
        if iconSet.Icons and iconSet.Icons[targetName] then
            local data = iconSet.Icons[targetName]
            local imageId = type(data.Image) == "number" and "rbxassetid://" .. data.Image or data.Image
            return { iconSet.Spritesheets[imageId] or imageId, data }
        end
        
        return nil
    end
    
    function IconModule.Image(IconConfig)
        IconConfig = IconConfig or {}
        local Icon = {
            Icon = IconConfig.Icon or nil,
            Type = IconConfig.Type,
            Colors = IconConfig.Colors or { IconModule.IconThemeTag or Color3.new(1,1,1), Color3.new(1,1,1) },
            Size = IconConfig.Size or UDim2.new(0,24,0,24),
            IconFrame = nil,
        }
        
        local Colors = {}
        for i, color in ipairs(Icon.Colors) do
            Colors[i] = {
                ThemeTag = typeof(color) == "string" and color,
                Color = typeof(color) == "Color3" and color,
            }
        end
        
        local IconLabel = IconModule.Icon(Icon.Icon, Icon.Type)
        if not IconLabel then
            local fallback = Instance.new("ImageLabel")
            fallback.Size = Icon.Size
            fallback.BackgroundTransparency = 1
            if typeof(Icon.Icon) == "string" and Icon.Icon:match("^rbxassetid://") then
                fallback.Image = Icon.Icon
            end
            Icon.IconFrame = fallback
            return Icon
        end
        
        local image = type(IconLabel) == "table" and IconLabel[1] or IconLabel
        local data = type(IconLabel) == "table" and IconLabel[2] or { ImageRectSize = Vector2.new(0,0), ImageRectPosition = Vector2.new(0,0), Parts = nil }
        
        local frame = Instance.new("ImageLabel")
        frame.Size = Icon.Size
        frame.BackgroundTransparency = 1
        frame.ImageColor3 = Colors[1].Color or Color3.new(1,1,1)
        frame.Image = image
        frame.ImageRectSize = data.ImageRectSize
        frame.ImageRectOffset = data.ImageRectPosition
        
        if data.Parts then
            for i, partName in ipairs(data.Parts) do
                local part = IconModule.Icon(partName, Icon.Type)
                if part then
                    local p = Instance.new("ImageLabel")
                    p.Size = UDim2.new(1,0,1,0)
                    p.BackgroundTransparency = 1
                    p.ImageColor3 = Colors[1+i].Color or Color3.new(1,1,1)
                    p.Image = type(part) == "table" and part[1] or part
                    p.ImageRectSize = type(part) == "table" and part[2].ImageRectSize or Vector2.new(0,0)
                    p.ImageRectOffset = type(part) == "table" and part[2].ImageRectPosition or Vector2.new(0,0)
                    p.Parent = frame
                end
            end
        end
        
        Icon.IconFrame = frame
        return Icon
    end
    
    return IconModule
end)()

Icons.SetIconsType("lucide")

local CFG = {
    MainColor = Color3.fromRGB(14, 14, 14),
    SecondaryColor = Color3.fromRGB(26, 26, 26),
    AccentColor = Color3.fromRGB(189, 172, 255),
    TextColor = Color3.fromRGB(200, 200, 200),
    TextDark = Color3.fromRGB(120, 120, 120),
    StrokeColor = Color3.fromRGB(40, 40, 40),
    Font = Enum.Font.Code,
    BaseSize = Vector2.new(600, 450),
    MinSize = Vector2.new(400, 300)
}

local function Create(class, props, children)
    local inst = Instance.new(class)
    for i, v in pairs(props or {}) do
        inst[i] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(obj, props, time, style, dir)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local function GetTextSize(text, size, font)
    return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
end

local Dotfunc = {
    Version = "2.0.0",
    Flags = {},
    Connections = {},
    Unloaded = false,
    SearchableElements = {},
    Sections = {},
    Tabs = {},
    Windows = {}
}

function Dotfunc:CreateWindow(config)
    config = config or {}
    
    local Window = {
        Title = config.Title or "Dotfunc UI",
        Size = config.Size or UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
        Resizable = config.Resizable ~= false,
        UserPanel = config.UserPanel ~= false,
        Icon = config.Icon,
        Tabs = {},
        SearchableElements = {},
        Sections = {},
        MenuKey = Enum.KeyCode.Insert
    }
    
    local ScreenGui = Create("ScreenGui", {
        Name = "DotfuncUI",
        Parent = game:GetService("CoreGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    })
    
    local UIScale = Create("UIScale", {Parent = ScreenGui})
    
    local function UpdateScale()
        local vp = workspace.CurrentCamera.ViewportSize
        local widthRatio = (vp.X - 40) / Window.Size.X.Offset
        local heightRatio = (vp.Y - 40) / Window.Size.Y.Offset
        local scale = math.min(widthRatio, heightRatio, 1)
        UIScale.Scale = math.max(scale, 0.6)
    end
    
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
    UpdateScale()
    
    local NotificationContainer = Create("Frame", {
        Parent = ScreenGui,
        Position = UDim2.new(1, -10, 0, 10),
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.new(0, 320, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 100
    })
    
    local UIListNotif = Create("UIListLayout", {
        Parent = NotificationContainer,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top
    })
    
    function Window:Notify(config)
        if type(config) == "string" then
            config = {Text = config}
        end
        
        local Title = config.Title or "Notification"
        local Text = config.Text or config[1] or ""
        local Duration = config.Duration or 3
        local Status = config.Status or "info"
        local Icon = config.Icon
        
        local statusColors = {
            success = Color3.fromRGB(72, 187, 120),
            error = Color3.fromRGB(245, 101, 101),
            warning = Color3.fromRGB(246, 173, 85),
            info = CFG.AccentColor
        }
        
        local color = statusColors[Status] or CFG.AccentColor
        
        local NotifFrame = Create("Frame", {
            Parent = NotificationContainer,
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = CFG.MainColor,
            BorderSizePixel = 0,
            ClipsDescendants = true
        }, {
            Create("UIStroke", {
                Color = color,
                Thickness = 1.5,
                Transparency = 0.3
            }),
            Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        Create("Frame", {
            Parent = NotifFrame,
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        local contentPadding = 12
        local iconSize = 20
        local xOffset = contentPadding + 3
        
        if Icon then
            local iconData = Icons.Image({
                Icon = Icon,
                Size = UDim2.new(0, iconSize, 0, iconSize),
                Colors = {color}
            })
            
            if iconData and iconData.IconFrame then
                iconData.IconFrame.Position = UDim2.new(0, xOffset, 0, contentPadding)
                iconData.IconFrame.Parent = NotifFrame
                xOffset = xOffset + iconSize + 8
            end
        end
        
        local ContentFrame = Create("Frame", {
            Parent = NotifFrame,
            Size = UDim2.new(1, -(xOffset + contentPadding), 1, -contentPadding * 2),
            Position = UDim2.new(0, xOffset, 0, contentPadding),
            BackgroundTransparency = 1
        })
        
        local TitleLabel = Create("TextLabel", {
            Parent = ContentFrame,
            Text = Title,
            TextColor3 = CFG.TextColor,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        
        local DescLabel = Create("TextLabel", {
            Parent = ContentFrame,
            Text = Text,
            TextColor3 = CFG.TextDark,
            Font = CFG.Font,
            TextSize = 11,
            Size = UDim2.new(1, 0, 1, -18),
            Position = UDim2.new(0, 0, 0, 18),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true
        })
        
        local textHeight = math.max(40, GetTextSize(Text, 11, CFG.Font).Y + 30)
        local finalHeight = math.min(textHeight, 80)
        
        Tween(NotifFrame, {Size = UDim2.new(0, 300, 0, finalHeight)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        task.delay(Duration, function()
            Tween(NotifFrame, {
                Size = UDim2.new(0, 300, 0, 0),
                BackgroundTransparency = 1
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            
            task.wait(0.3)
            NotifFrame:Destroy()
        end)
        
        return NotifFrame
    end
    
    local TooltipLabel = Create("TextLabel", {
        Parent = ScreenGui,
        Size = UDim2.new(0, 0, 0, 24),
        BackgroundColor3 = CFG.SecondaryColor,
        TextColor3 = CFG.TextColor,
        TextSize = 11,
        Font = CFG.Font,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 200
    }, {
        Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4)
        }),
        Create("UIStroke", {Color = CFG.StrokeColor}),
        Create("UICorner", {CornerRadius = UDim.new(0, 4)})
    })
    
    local function AddTooltip(obj, text)
        obj.MouseEnter:Connect(function()
            TooltipLabel.Text = text
            TooltipLabel.Size = UDim2.fromOffset(GetTextSize(text, 11, CFG.Font).X + 16, 24)
            TooltipLabel.Visible = true
        end)
        obj.MouseLeave:Connect(function()
            TooltipLabel.Visible = false
        end)
    end
    
    RunService.RenderStepped:Connect(function()
        if TooltipLabel.Visible then
            local m = UserInputService:GetMouseLocation()
            TooltipLabel.Position = UDim2.fromOffset(m.X + 15, m.Y + 15)
        end
    end)
    
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        Size = Window.Size,
        Position = UDim2.new(0.5, -Window.Size.X.Offset/2, 0.5, -Window.Size.Y.Offset/2),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel = 0
    }, {
        Create("UIStroke", {Color = CFG.StrokeColor}),
        Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    
    local Dragging, DragInput, DragStart, StartPos = false, nil, nil, nil
    
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local delta = input.Position - DragStart
            Tween(MainFrame, {
                Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
            }, 0.05)
        end
    end)
    
    if Window.Resizable then
        local ResizeHandle = Create("TextButton", {
            Parent = MainFrame,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -20, 1, -20),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 10,
            AutoButtonColor = false
        })
        
        local Resizing = false
        local ResizeStart, ResizeStartSize = nil, nil
        
        ResizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Resizing = true
                ResizeStart = input.Position
                ResizeStartSize = MainFrame.Size
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Resizing = false
                    end
                end)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if Resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - ResizeStart
                local newWidth = math.max(ResizeStartSize.X.Offset + delta.X, CFG.MinSize.X)
                local newHeight = math.max(ResizeStartSize.Y.Offset + delta.Y, CFG.MinSize.Y)
                MainFrame.Size = UDim2.fromOffset(newWidth, newHeight)
            end
        end)
    end
    
    local TopBar = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel = 0
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
        Create("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = CFG.StrokeColor,
            BorderSizePixel = 0
        })
    })
    
    Create("Frame", {
        Parent = TopBar,
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel = 0
    })
    
    local TitleLabel = Create("TextLabel", {
        Parent = TopBar,
        Text = Window.Title,
        TextColor3 = CFG.TextColor,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true
    })
    
    local SearchContainer = Create("Frame", {
        Parent = TopBar,
        Size = UDim2.new(0, 200, 0, 24),
        Position = UDim2.new(1, -210, 0.5, -12),
        BackgroundColor3 = CFG.SecondaryColor,
        BorderSizePixel = 0
    }, {
        Create("UIStroke", {Color = CFG.StrokeColor}),
        Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    
    local SearchIcon = Create("ImageLabel", {
        Parent = SearchContainer,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 8, 0.5, -7),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031068433",
        ImageColor3 = CFG.TextDark
    })
    
    local SearchBox = Create("TextBox", {
        Parent = SearchContainer,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = CFG.TextDark,
        TextColor3 = CFG.TextColor,
        TextSize = 11,
        Font = CFG.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })
    
    local function FilterElements(query)
        query = query:lower()
        
        if query == "" then
            for _, element in pairs(Window.SearchableElements) do
                if element.Frame then element.Frame.Visible = true end
            end
            for _, section in pairs(Window.Sections) do
                section.Frame.Visible = true
            end
            return
        end
        
        local tabsWithMatches = {}
        local sectionsWithMatches = {}
        
        for _, element in pairs(Window.SearchableElements) do
            local elementName = element.Name:lower()
            local elementMatches = elementName:find(query, 1, true) ~= nil
            
            if element.Frame then
                element.Frame.Visible = elementMatches
                
                if elementMatches and element.GroupFrame then
                    sectionsWithMatches[element.GroupFrame] = true
                    
                    for _, tabData in pairs(Window.Tabs) do
                        if element.GroupFrame:IsDescendantOf(tabData.Page) then
                            tabsWithMatches[tabData] = true
                            break
                        end
                    end
                end
            end
        end
        
        for _, section in pairs(Window.Sections) do
            local sectionName = section.Name:lower()
            local sectionMatches = sectionName:find(query, 1, true) ~= nil
            
            if sectionMatches then
                sectionsWithMatches[section.Frame] = true
                
                for _, element in pairs(Window.SearchableElements) do
                    if element.GroupFrame == section.Frame and element.Frame then
                        element.Frame.Visible = true
                    end
                end
                
                for _, tabData in pairs(Window.Tabs) do
                    if section.Frame:IsDescendantOf(tabData.Page) then
                        tabsWithMatches[tabData] = true
                        break
                    end
                end
            end
        end
        
        for _, section in pairs(Window.Sections) do
            section.Frame.Visible = sectionsWithMatches[section.Frame] == true
        end
        
        if query ~= "" then
            for tabData, _ in pairs(tabsWithMatches) do
                for _, t in pairs(Window.Tabs) do
                    Tween(t.Btn.Icon, {ImageColor3 = CFG.TextDark}, 0.2)
                    Tween(t.Btn, {BackgroundColor3 = CFG.MainColor}, 0.2)
                    t.Page.Visible = false
                end
                Tween(tabData.Btn.Icon, {ImageColor3 = CFG.AccentColor}, 0.2)
                Tween(tabData.Btn, {BackgroundColor3 = CFG.SecondaryColor}, 0.2)
                tabData.Page.Visible = true
                break
            end
        end
    end
    
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        FilterElements(SearchBox.Text)
    end)
    
    local ContentContainer = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundTransparency = 1
    })
    
    local SidebarContainer = Create("Frame", {
        Parent = ContentContainer,
        Size = UDim2.new(0, 65, 1, 0),
        BackgroundColor3 = Color3.fromRGB(17, 17, 17),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0)
    }, {
        Create("Frame", {
            Size = UDim2.new(0, 1, 1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = CFG.StrokeColor
        })
    })
    
    local Sidebar = Create("ScrollingFrame", {
        Parent = SidebarContainer,
        Size = UDim2.new(1, 0, 1, Window.UserPanel and -70 or 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    }, {
        Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top
        }),
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 15),
            PaddingBottom = UDim.new(0, 15)
        })
    })
    
    if Window.UserPanel then
        local UserProfileButton = Create("TextButton", {
            Parent = SidebarContainer,
            Size = UDim2.new(0, 45, 0, 45),
            Position = UDim2.new(0.5, -22.5, 1, -55),
            BackgroundColor3 = CFG.MainColor,
            Text = "",
            AutoButtonColor = false
        }, {
            Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Create("UIStroke", {Color = CFG.AccentColor, Thickness = 2}),
            Create("ImageLabel", {
                Name = "Avatar",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = "rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=150&h=150",
                ScaleType = Enum.ScaleType.Crop
            }, {
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
        })
        
        local ProfilePanel = Create("Frame", {
            Parent = MainFrame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 0),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Color3.fromRGB(17, 17, 17),
            BorderSizePixel = 0,
            ZIndex = 50,
            ClipsDescendants = true
        }, {
            Create("UIStroke", {Color = CFG.StrokeColor}),
            Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        
        local ProfilePanelOpen = false
        
        local ProfileAvatar = Create("ImageLabel", {
            Parent = ProfilePanel,
            Size = UDim2.new(0, 80, 0, 80),
            Position = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=420&h=420",
            ScaleType = Enum.ScaleType.Crop
        }, {
            Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Create("UIStroke", {Color = CFG.StrokeColor, Thickness = 2})
        })
        
        local ProfileInfo = Create("Frame", {
            Parent = ProfilePanel,
            Size = UDim2.new(1, -120, 0, 80),
            Position = UDim2.new(0, 110, 0, 20),
            BackgroundTransparency = 1
        })
        
        Create("TextLabel", {
            Parent = ProfileInfo,
            Text = Player.DisplayName,
            TextColor3 = CFG.TextColor,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            Size = UDim2.new(0.5, -10, 0, 20),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        
        Create("TextLabel", {
            Parent = ProfileInfo,
            Text = "@" .. Player.Name,
            TextColor3 = CFG.TextDark,
            Font = CFG.Font,
            TextSize = 12,
            Size = UDim2.new(0.5, -10, 0, 20),
            Position = UDim2.new(0, 0, 0, 25),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        
        Create("TextLabel", {
            Parent = ProfileInfo,
            Text = "Game ID: " .. game.PlaceId,
            TextColor3 = CFG.TextDark,
            Font = CFG.Font,
            TextSize = 11,
            Size = UDim2.new(0.5, -10, 0, 20),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        })
        
        local GameNameLabel = Create("TextLabel", {
            Parent = ProfileInfo,
            Text = "Loading...",
            TextColor3 = CFG.TextDark,
            Font = CFG.Font,
            TextSize = 11,
            Size = UDim2.new(0.5, -10, 0, 40),
            Position = UDim2.new(0.5, 0, 0, 25),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true
        })
        
        task.spawn(function()
            local success, result = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            end)
            GameNameLabel.Text = success and result or "Unknown Game"
        end)
        
        local function CloseProfilePanel()
            if ProfilePanelOpen then
                ProfilePanelOpen = false
                Tween(ProfilePanel, {Size = UDim2.new(1, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
                Tween(UserProfileButton.Avatar, {ImageTransparency = 0}, 0.2)
            end
        end
        
        UserInputService.InputBegan:Connect(function(input)
            if ProfilePanelOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                local mousePos = UserInputService:GetMouseLocation()
                local panelPos = ProfilePanel.AbsolutePosition
                local panelSize = ProfilePanel.AbsoluteSize
                local buttonPos = UserProfileButton.AbsolutePosition
                local buttonSize = UserProfileButton.AbsoluteSize
                
                if (mousePos.X < panelPos.X or mousePos.X > panelPos.X + panelSize.X or
                    mousePos.Y < panelPos.Y or mousePos.Y > panelPos.Y + panelSize.Y) and
                   (mousePos.X < buttonPos.X or mousePos.X > buttonPos.X + buttonSize.X or
                    mousePos.Y < buttonPos.Y or mousePos.Y > buttonPos.Y + buttonSize.Y) then
                    CloseProfilePanel()
                end
            end
        end)
        
        UserProfileButton.MouseButton1Click:Connect(function()
            ProfilePanelOpen = not ProfilePanelOpen
            if ProfilePanelOpen then
                Tween(ProfilePanel, {Size = UDim2.new(1, 0, 0, 120)}, 0.3, Enum.EasingStyle.Back)
                Tween(UserProfileButton.Avatar, {ImageTransparency = 0.3}, 0.2)
            else
                CloseProfilePanel()
            end
        end)
    end
    
    local PagesContainer = Create("Frame", {
        Parent = ContentContainer,
        Size = UDim2.new(1, -65, 1, 0),
        Position = UDim2.new(0, 65, 0, 0),
        BackgroundTransparency = 1
    })
    
    function Window:Tab(config)
        config = config or {}
        
        local name = config.Name or config[1] or "Tab"
        local icon = config.Icon or config[2] or "folder"
        
        local TabButton = Create("TextButton", {
            Parent = Sidebar,
            Size = UDim2.new(0, 45, 0, 45),
            BackgroundColor3 = CFG.MainColor,
            Text = "",
            AutoButtonColor = false
        }, {
            Create("ImageLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0.5, -12, 0.5, -12),
                BackgroundTransparency = 1,
                Image = "rbxassetid://" .. icon,
                ImageColor3 = CFG.TextDark
            }),
            Create("UICorner", {CornerRadius = UDim.new(0, 8)})
        })
        
        local PageFrame = Create("ScrollingFrame", {
            Parent = PagesContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = CFG.AccentColor,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        
        Create("UIPadding", {
            Parent = PageFrame,
            PaddingTop = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingBottom = UDim.new(0, 15)
        })
        
        local LeftCol = Create("Frame", {
            Parent = PageFrame,
            Size = UDim2.new(0.48, 0, 1, 0),
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", {
                Padding = UDim.new(0, 12),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        })
        
        local RightCol = Create("Frame", {
            Parent = PageFrame,
            Size = UDim2.new(0.48, 0, 1, 0),
            Position = UDim2.new(0.52, 0, 0, 0),
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", {
                Padding = UDim.new(0, 12),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        })
        
        local TabData = {
            Btn = TabButton,
            Page = PageFrame,
            Name = name
        }
        
        table.insert(Window.Tabs, TabData)
        
        TabButton.MouseButton1Click:Connect(function()
            for _, t in pairs(Window.Tabs) do
                Tween(t.Btn.Icon, {ImageColor3 = CFG.TextDark}, 0.2)
                Tween(t.Btn, {BackgroundColor3 = CFG.MainColor}, 0.2)
                t.Page.Visible = false
            end
            Tween(TabButton.Icon, {ImageColor3 = CFG.AccentColor}, 0.2)
            Tween(TabButton, {BackgroundColor3 = CFG.SecondaryColor}, 0.2)
            PageFrame.Visible = true
        end)
        
        if #Window.Tabs == 1 then
            Tween(TabButton.Icon, {ImageColor3 = CFG.AccentColor}, 0.2)
            Tween(TabButton, {BackgroundColor3 = CFG.SecondaryColor}, 0.2)
            PageFrame.Visible = true
        end
        
        local TabFunctions = {}
        local LeftSide = true
        
        function TabFunctions:Section(title)
            local ParentCol = LeftSide and LeftCol or RightCol
            LeftSide = not LeftSide
            
            local GroupFrame = Create("Frame", {
                Parent = ParentCol,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(17, 17, 17),
                BorderSizePixel = 0
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 6)})
            })
            
            local Header = Create("Frame", {
                Parent = GroupFrame,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 1, -6),
                    BackgroundColor3 = CFG.SecondaryColor,
                    BorderSizePixel = 0
                })
            })
            
            Create("TextLabel", {
                Parent = Header,
                Text = title,
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = CFG.TextColor,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            Create("Frame", {
                Parent = Header,
                Size = UDim2.new(0, 5, 0, 5),
                Position = UDim2.new(1, -14, 0.5, -2.5),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel = 0
            }, {
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
            
            local Content = Create("Frame", {
                Parent = GroupFrame,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 30),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            }, {
                Create("UIListLayout", {
                    Padding = UDim.new(0, 6),
                    SortOrder = Enum.SortOrder.LayoutOrder
                }),
                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10)
                })
            })
            
            table.insert(Window.Sections, {Frame = GroupFrame, Name = title})
            
            local SectionFuncs = {}
            
            function SectionFuncs:Toggle(options)
                local config = {
                    Name = options.Name or options[1] or "Toggle",
                    Default = options.Default or options[2] or false,
                    Callback = options.Callback or options[3] or function() end,
                    Risky = options.Risky,
                    Tooltip = options.Tooltip
                }
                
                local Enabled = config.Default
                
                local Frame = Create("TextButton", {
                    Parent = Content,
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Text = ""
                })
                
                local Box = Create("Frame", {
                    Parent = Frame,
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 0, 0.5, -7),
                    BackgroundColor3 = CFG.SecondaryColor,
                    BorderSizePixel = 0
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 3)})
                })
                
                local Check = Create("Frame", {
                    Parent = Box,
                    Size = UDim2.new(1, -4, 1, -4),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = CFG.AccentColor,
                    BackgroundTransparency = Enabled and 0 or 1,
                    BorderSizePixel = 0
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 2)})
                })
                
                local Label = Create("TextLabel", {
                    Parent = Frame,
                    Text = config.Name,
                    TextColor3 = Enabled and CFG.TextColor or (config.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark),
                    TextSize = 12,
                    Font = CFG.Font,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 20, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
                
                local function Update()
                    Enabled = not Enabled
                    Tween(Check, {BackgroundTransparency = Enabled and 0 or 1}, 0.15)
                    Tween(Label, {TextColor3 = Enabled and CFG.TextColor or (config.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)}, 0.15)
                    config.Callback(Enabled)
                end
                
                Frame.MouseButton1Click:Connect(Update)
                
                table.insert(Window.SearchableElements, {
                    Name = config.Name,
                    Frame = Frame,
                    Group = Content,
                    GroupFrame = GroupFrame
                })
                
                return {
                    Set = function(v) if v ~= Enabled then Update() end end,
                    Get = function() return Enabled end
                }
            end
            
            function SectionFuncs:Slider(options)
                local config = {
                    Name = options.Name or options[1] or "Slider",
                    Min = options.Min or options[2] or 0,
                    Max = options.Max or options[3] or 100,
                    Default = options.Default or options[4] or options.Min or 0,
                    Increment = options.Increment or options.increment or 1,
                    Unit = options.Unit,
                    Callback = options.Callback or options[5] or function() end,
                    Tooltip = options.Tooltip
                }
                
                local Value = config.Default
                local DraggingSlider = false
                
                local Frame = Create("Frame", {
                    Parent = Content,
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundTransparency = 1
                })
                
                local Label = Create("TextLabel", {
                    Parent = Frame,
                    Text = config.Name,
                    TextColor3 = CFG.TextDark,
                    TextSize = 11,
                    Font = CFG.Font,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.6, 0, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local ValueBox = Create("TextBox", {
                    Parent = Frame,
                    Text = tostring(Value) .. (config.Unit or ""),
                    TextColor3 = CFG.TextColor,
                    TextSize = 11,
                    Font = CFG.Font,
                    BackgroundColor3 = CFG.SecondaryColor,
                    Size = UDim2.new(0, 55, 0, 18),
                    Position = UDim2.new(1, -55, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    BorderSizePixel = 0
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Create("UIStroke", {Color = CFG.StrokeColor})
                })
                
                local SliderBG = Create("Frame", {
                    Parent = Frame,
                    Size = UDim2.new(1, 0, 0, 8),
                    Position = UDim2.new(0, 0, 0, 24),
                    BackgroundColor3 = CFG.SecondaryColor,
                    BorderSizePixel = 0
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)})
                })
                
                local Fill = Create("Frame", {
                    Parent = SliderBG,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = CFG.AccentColor,
                    BorderSizePixel = 0
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)})
                })
                
                local function UpdateDisplay()
                    local displayValue = Value
                    if config.Increment < 1 then
                        displayValue = math.floor(Value / config.Increment + 0.5) * config.Increment
                        displayValue = tonumber(string.format("%.2f", displayValue))
                    end
                    ValueBox.Text = tostring(displayValue) .. (config.Unit or "")
                end
                
                local function UpdateSlider(newValue)
                    Value = math.clamp(newValue, config.Min, config.Max)
                    Value = math.floor(Value / config.Increment + 0.5) * config.Increment
                    
                    local percent = (Value - config.Min) / (config.Max - config.Min)
                    Fill.Size = UDim2.new(percent, 0, 1, 0)
                    UpdateDisplay()
                    config.Callback(Value)
                end
                
                local function Update(input)
                    local SizeX = SliderBG.AbsoluteSize.X
                    local PosX = SliderBG.AbsolutePosition.X
                    local InputX = input.Position.X
                    
                    local Percent = math.clamp((InputX - PosX) / SizeX, 0, 1)
                    local newValue = config.Min + (config.Max - config.Min) * Percent
                    UpdateSlider(newValue)
                end
                
                Frame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        DraggingSlider = true
                        Update(input)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if DraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        Update(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        DraggingSlider = false
                    end
                end)
                
                ValueBox.FocusLost:Connect(function()
                    local text = ValueBox.Text:gsub(config.Unit or "", "")
                    local num = tonumber(text)
                    if num then
                        UpdateSlider(num)
                    else
                        UpdateDisplay()
                    end
                end)
                
                UpdateSlider(Value)
                if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
                
                table.insert(Window.SearchableElements, {
                    Name = config.Name,
                    Frame = Frame,
                    Group = Content,
                    GroupFrame = GroupFrame
                })
                
                return {
                    Set = function(v) UpdateSlider(v) end,
                    Get = function() return Value end
                }
            end
            
            function SectionFuncs:Dropdown(options)
                local config = {
                    Name = options.Name or options[1] or "Dropdown",
                    Options = options.Options or options[2] or {},
                    Default = options.Default or options[3],
                    Multi = options.Multi or false,
                    Callback = options.Callback or options[4] or function() end,
                    Tooltip = options.Tooltip
                }
                
                if config.Multi then
                    if not config.Default then
                        config.Default = {}
                    elseif type(config.Default) ~= "table" then
                        config.Default = {config.Default}
                    end
                else
                    if not config.Default and config.Options[1] then
                        config.Default = config.Options[1]
                    end
                end
                
                local Expanded = false
                local Selected = config.Multi and config.Default or {config.Default}
                
                local Frame = Create("Frame", {
                    Parent = Content,
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    ZIndex = 20
                })
                
                Create("TextLabel", {
                    Parent = Frame,
                    Text = config.Name,
                    TextColor3 = CFG.TextDark,
                    TextSize = 11,
                    Font = CFG.Font,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local function GetDisplayText()
                    if config.Multi then
                        return #Selected > 0 and table.concat(Selected, ", ") or "None"
                    else
                        return Selected[1] or "None"
                    end
                end
                
                local MainBox = Create("TextButton", {
                    Parent = Frame,
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = CFG.SecondaryColor,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Create("TextLabel", {
                        Name = "Val",
                        Text = GetDisplayText(),
                        Size = UDim2.new(1, -28, 1, 0),
                        Position = UDim2.new(0, 8, 0, 0),
                        BackgroundTransparency = 1,
                        TextColor3 = CFG.TextColor,
                        TextSize = 11,
                        Font = CFG.Font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd
                    }),
                    Create("TextLabel", {
                        Text = "▼",
                        Size = UDim2.new(0, 20, 1, 0),
                        Position = UDim2.new(1, -20, 0, 0),
                        BackgroundTransparency = 1,
                        TextColor3 = CFG.TextDark,
                        TextSize = 10
                    })
                })
                
                local ListFrame = Create("ScrollingFrame", {
                    Parent = MainBox,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 1, 4),
                    BackgroundColor3 = CFG.SecondaryColor,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 50,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = CFG.AccentColor
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Create("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)})
                })
                
                local function IsSelected(opt)
                    for _, v in pairs(Selected) do
                        if v == opt then return true end
                    end
                    return false
                end
                
                local function UpdateSelection(opt)
                    if config.Multi then
                        local found = false
                        for i, v in pairs(Selected) do
                            if v == opt then
                                table.remove(Selected, i)
                                found = true
                                break
                            end
                        end
                        if not found then
                            table.insert(Selected, opt)
                        end
                    else
                        Selected = {opt}
                        Expanded = false
                        Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
                        task.wait(0.15)
                        ListFrame.Visible = false
                    end
                    
                    MainBox.Val.Text = GetDisplayText()
                    config.Callback(config.Multi and Selected or Selected[1])
                end
                
                for _, opt in pairs(config.Options) do
                    local OptionBtn = Create("TextButton", {
                        Parent = ListFrame,
                        Size = UDim2.new(1, -8, 0, 22),
                        BackgroundColor3 = CFG.MainColor,
                        BackgroundTransparency = 0.5,
                        Text = "",
                        AutoButtonColor = false
                    }, {
                        Create("UICorner", {CornerRadius = UDim.new(0, 3)})
                    })
                    
                    if config.Multi then
                        local CheckBox = Create("Frame", {
                            Parent = OptionBtn,
                            Size = UDim2.new(0, 12, 0, 12),
                            Position = UDim2.new(0, 6, 0.5, -6),
                            BackgroundColor3 = CFG.SecondaryColor,
                            BorderSizePixel = 0
                        }, {
                            Create("UIStroke", {Color = CFG.StrokeColor}),
                            Create("UICorner", {CornerRadius = UDim.new(0, 2)})
                        })
                        
                        local Check = Create("Frame", {
                            Parent = CheckBox,
                            Size = UDim2.new(1, -4, 1, -4),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundColor3 = CFG.AccentColor,
                            BackgroundTransparency = IsSelected(opt) and 0 or 1,
                            BorderSizePixel = 0
                        }, {
                            Create("UICorner", {CornerRadius = UDim.new(0, 1)})
                        })
                        
                        Create("TextLabel", {
                            Parent = OptionBtn,
                            Text = opt,
                            Size = UDim2.new(1, -24, 1, 0),
                            Position = UDim2.new(0, 24, 0, 0),
                            BackgroundTransparency = 1,
                            TextColor3 = IsSelected(opt) and CFG.AccentColor or CFG.TextColor,
                            TextSize = 11,
                            Font = CFG.Font,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        
                        OptionBtn.MouseButton1Click:Connect(function()
                            UpdateSelection(opt)
                            Check.BackgroundTransparency = IsSelected(opt) and 0 or 1
                            OptionBtn:FindFirstChildOfClass("TextLabel").TextColor3 = IsSelected(opt) and CFG.AccentColor or CFG.TextColor
                        end)
                    else
                        Create("TextLabel", {
                            Parent = OptionBtn,
                            Text = opt,
                            Size = UDim2.new(1, -12, 1, 0),
                            Position = UDim2.new(0, 6, 0, 0),
                            BackgroundTransparency = 1,
                            TextColor3 = (opt == Selected[1]) and CFG.AccentColor or CFG.TextColor,
                            TextSize = 11,
                            Font = CFG.Font,
                            TextXAlignment = Enum.TextXAlignment.Left
                        })
                        
                        OptionBtn.MouseButton1Click:Connect(function()
                            for _, child in pairs(ListFrame:GetChildren()) do
                                if child:IsA("TextButton") then
                                    local label = child:FindFirstChildOfClass("TextLabel")
                                    if label then
                                        label.TextColor3 = CFG.TextColor
                                    end
                                end
                            end
                            
                            UpdateSelection(opt)
                            OptionBtn:FindFirstChildOfClass("TextLabel").TextColor3 = CFG.AccentColor
                        end)
                    end
                end
                
                MainBox.MouseButton1Click:Connect(function()
                    Expanded = not Expanded
                    if Expanded then
                        ListFrame.Visible = true
                        Tween(ListFrame, {Size = UDim2.new(1, 0, 0, math.min(#config.Options * 24 + 8, 120))}, 0.15)
                    else
                        Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.15)
                        task.wait(0.15)
                        ListFrame.Visible = false
                    end
                end)
                
                if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
                
                table.insert(Window.SearchableElements, {
                    Name = config.Name,
                    Frame = Frame,
                    Group = Content,
                    GroupFrame = GroupFrame
                })
                
                return {
                    Set = function(v)
                        if config.Multi then
                            Selected = type(v) == "table" and v or {v}
                        else
                            Selected = {v}
                        end
                        MainBox.Val.Text = GetDisplayText()
                    end,
                    Get = function()
                        return config.Multi and Selected or Selected[1]
                    end
                }
            end
            
            function SectionFuncs:ColorPicker(options)
                local config = {
                    Name = options.Name or options[1] or "Color",
                    Default = options.Default or options[2] or Color3.fromRGB(255, 255, 255),
                    Callback = options.Callback or options[3] or function() end,
                    Tooltip = options.Tooltip
                }
                
                local Color = config.Default
                local Opened = false
                
                local Frame = Create("Frame", {
                    Parent = Content,
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    ZIndex = 15
                })
                
                Create("TextLabel", {
                    Parent = Frame,
                    Text = config.Name,
                    TextColor3 = CFG.TextDark,
                    TextSize = 11,
                    Font = CFG.Font,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.7, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local Preview = Create("TextButton", {
                    Parent = Frame,
                    Size = UDim2.new(0, 35, 0, 16),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    BackgroundColor3 = Color,
                    Text = "",
                    AutoButtonColor = false
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                
                local PickerFrame = Create("Frame", {
                    Parent = Preview,
                    Size = UDim2.new(0, 200, 0, 0),
                    Position = UDim2.new(1, 0, 1, 6),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = CFG.MainColor,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 60
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 6)})
                })
                
                local SatValPanel = Create("TextButton", {
                    Parent = PickerFrame,
                    Size = UDim2.new(1, -20, 0, 120),
                    Position = UDim2.new(0, 10, 0, 10),
                    BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                    Text = "",
                    AutoButtonColor = false
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Create("ImageLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://4801885019"
                    }, {
                        Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                    }),
                    Create("ImageLabel", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = "rbxassetid://4801885019",
                        ImageColor3 = Color3.new(0, 0, 0),
                        Rotation = 90
                    }, {
                        Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                    })
                })
                
                local Cursor = Create("Frame", {
                    Parent = SatValPanel,
                    Size = UDim2.new(0, 6, 0, 6),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BorderSizePixel = 0
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
                    Create("UIStroke", {Color = Color3.new(0, 0, 0), Thickness = 1})
                })
                
                local HueSlider = Create("TextButton", {
                    Parent = PickerFrame,
                    Size = UDim2.new(1, -20, 0, 12),
                    Position = UDim2.new(0, 10, 0, 140),
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0
                }, {
                    Create("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
                        })
                    }),
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)})
                })
                
                local H, S, V = 0, 1, 1
                local DraggingHSV, DraggingHue = false, false
                
                local function UpdateColor()
                    Color = Color3.fromHSV(H, S, V)
                    Preview.BackgroundColor3 = Color
                    SatValPanel.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                    Cursor.Position = UDim2.new(S, 0, 1 - V, 0)
                    config.Callback(Color)
                end
                
                SatValPanel.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        DraggingHSV = true
                    end
                end)
                
                HueSlider.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        DraggingHue = true
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        DraggingHSV = false
                        DraggingHue = false
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        if DraggingHSV then
                            local size = SatValPanel.AbsoluteSize
                            local pos = SatValPanel.AbsolutePosition
                            local x = math.clamp((inp.Position.X - pos.X) / size.X, 0, 1)
                            local y = math.clamp((inp.Position.Y - pos.Y) / size.Y, 0, 1)
                            S = x
                            V = 1 - y
                            UpdateColor()
                        elseif DraggingHue then
                            local size = HueSlider.AbsoluteSize
                            local pos = HueSlider.AbsolutePosition
                            local x = math.clamp((inp.Position.X - pos.X) / size.X, 0, 1)
                            H = x
                            UpdateColor()
                        end
                    end
                end)
                
                Preview.MouseButton1Click:Connect(function()
                    Opened = not Opened
                    if Opened then
                        Tween(PickerFrame, {Size = UDim2.new(0, 200, 0, 190)}, 0.2)
                    else
                        Tween(PickerFrame, {Size = UDim2.new(0, 200, 0, 0)}, 0.2)
                    end
                end)
                
                if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
                
                table.insert(Window.SearchableElements, {
                    Name = config.Name,
                    Frame = Frame,
                    Group = Content,
                    GroupFrame = GroupFrame
                })
                
                return {
                    Set = function(c)
                        Color = c
                        Preview.BackgroundColor3 = c
                        H, S, V = Color:ToHSV()
                        UpdateColor()
                    end,
                    Get = function() return Color end
                }
            end
            
            function SectionFuncs:Textbox(options)
                local config = {
                    Name = options.Name or options[1] or "Textbox",
                    Placeholder = options.Placeholder or options[2] or "...",
                    Default = options.Default or options[3] or "",
                    Callback = options.Callback or options[4] or function() end,
                    Tooltip = options.Tooltip
                }
                
                local Frame = Create("Frame", {
                    Parent = Content,
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1
                })
                
                Create("TextLabel", {
                    Parent = Frame,
                    Text = config.Name,
                    TextColor3 = CFG.TextDark,
                    TextSize = 11,
                    Font = CFG.Font,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local Box = Create("TextBox", {
                    Parent = Frame,
                    Size = UDim2.new(1, 0, 0, 22),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = CFG.SecondaryColor,
                    TextColor3 = CFG.TextColor,
                    PlaceholderText = config.Placeholder,
                    PlaceholderColor3 = CFG.TextDark,
                    Text = config.Default,
                    Font = CFG.Font,
                    TextSize = 11,
                    BorderSizePixel = 0,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
                    Create("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
                })
                
                Box.FocusLost:Connect(function()
                    config.Callback(Box.Text)
                end)
                
                if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
                
                table.insert(Window.SearchableElements, {
                    Name = config.Name,
                    Frame = Frame,
                    Group = Content,
                    GroupFrame = GroupFrame
                })
                
                return {
                    Set = function(v) Box.Text = v end,
                    Get = function() return Box.Text end
                }
            end
            
            function SectionFuncs:Keybind(options)
                local config = {
                    Name = options.Name or options[1] or "Keybind",
                    Default = options.Default or options[2] or Enum.KeyCode.Insert,
                    Callback = options.Callback or options[3] or function() end,
                    Tooltip = options.Tooltip
                }
                
                local Key = config.Default
                local Waiting = false
                
                local Frame = Create("Frame", {
                    Parent = Content,
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1
                })
                
                Create("TextLabel", {
                    Parent = Frame,
                    Text = config.Name,
                    TextColor3 = CFG.TextDark,
                    TextSize = 11,
                    Font = CFG.Font,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.6, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local Btn = Create("TextButton", {
                    Parent = Frame,
                    Size = UDim2.new(0, 70, 1, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = CFG.SecondaryColor,
                    Text = Key.Name,
                    TextColor3 = CFG.TextColor,
                    TextSize = 10,
                    Font = CFG.Font
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                
                Btn.MouseButton1Click:Connect(function()
                    Waiting = true
                    Btn.Text = "..."
                    Btn.TextColor3 = CFG.AccentColor
                end)
                
                UserInputService.InputBegan:Connect(function(inp)
                    if Waiting and inp.UserInputType == Enum.UserInputType.Keyboard then
                        Waiting = false
                        Key = inp.KeyCode
                        Btn.Text = Key.Name
                        Btn.TextColor3 = CFG.TextColor
                        config.Callback(Key)
                    end
                end)
                
                if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
                
                table.insert(Window.SearchableElements, {
                    Name = config.Name,
                    Frame = Frame,
                    Group = Content,
                    GroupFrame = GroupFrame
                })
                
                return {
                    Set = function(k)
                        Key = k
                        Btn.Text = k.Name
                    end,
                    Get = function() return Key end
                }
            end
            
            function SectionFuncs:Button(options)
                local config = {
                    Name = options.Name or options[1] or "Button",
                    Callback = options.Callback or options[2] or function() end,
                    Variant = options.Variant,
                    Tooltip = options.Tooltip
                }
                
                local Btn = Create("TextButton", {
                    Parent = Content,
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = CFG.SecondaryColor,
                    Text = config.Name,
                    TextColor3 = CFG.TextColor,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11
                }, {
                    Create("UIStroke", {Color = CFG.StrokeColor}),
                    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                })
                
                if config.Variant == "Primary" then
                    Btn.BackgroundColor3 = CFG.AccentColor
                    Btn.TextColor3 = Color3.fromRGB(20, 20, 20)
                elseif config.Variant == "Danger" then
                    Btn.BackgroundColor3 = Color3.fromRGB(245, 101, 101)
                    Btn.TextColor3 = Color3.fromRGB(20, 20, 20)
                end
                
                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.1)
                    task.wait(0.1)
                    Tween(Btn, {
                        BackgroundColor3 = config.Variant == "Primary" and CFG.AccentColor or
                                         config.Variant == "Danger" and Color3.fromRGB(245, 101, 101) or
                                         CFG.SecondaryColor
                    }, 0.1)
                    config.Callback()
                end)
                
                if config.Tooltip then AddTooltip(Btn, config.Tooltip) end
                
                table.insert(Window.SearchableElements, {
                    Name = config.Name,
                    Frame = Btn,
                    Group = Content,
                    GroupFrame = GroupFrame
                })
                
                return Btn
            end
            
            return SectionFuncs
        end
        
        return TabFunctions
    end
    
    local Visible = true
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Window.MenuKey then
            Visible = not Visible
            MainFrame.Visible = Visible
        end
    end)
    
    local MobileToggle = Create("ImageButton", {
        Parent = ScreenGui,
        Size = UDim2.new(0, 45, 0, 45),
        Position = UDim2.new(0.5, 0, 0, 15),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = CFG.MainColor,
        Image = "rbxassetid://3926305904",
        ImageColor3 = CFG.AccentColor,
        AutoButtonColor = false
    }, {
        Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Create("UIStroke", {Color = CFG.AccentColor, Thickness = 2.5})
    })
    
    MobileToggle.MouseButton1Click:Connect(function()
        Visible = not Visible
        MainFrame.Visible = Visible
    end)
    
    table.insert(Dotfunc.Windows, Window)
    return Window
end

return Dotfunc
