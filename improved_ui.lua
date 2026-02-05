local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
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

local Library = {
    Flags = {},
    Connections = {},
    Unloaded = false,
    SearchableElements = {},
    Sections = {},
    Tabs = {}
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

local ScreenGui = Create("ScreenGui", {
    Name = "EclipseUI",
    Parent = game:GetService("CoreGui"),
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
    IgnoreGuiInset = true
})

local UIScale = Create("UIScale", {Parent = ScreenGui})

local function UpdateScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local widthRatio = (vp.X - 40) / CFG.BaseSize.X
    local heightRatio = (vp.Y - 40) / CFG.BaseSize.Y
    local scale = math.min(widthRatio, heightRatio, 1)
    UIScale.Scale = math.max(scale, 0.6)
end

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
UpdateScale()

local NotificationContainer = Create("Frame", {
    Parent = ScreenGui,
    Position = UDim2.new(1, -20, 0, 20),
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.new(0, 300, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 100
})
local UIListNotif = Create("UIListLayout", {
    Parent = NotificationContainer,
    Padding = UDim.new(0, 5),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Top
})

function Library:Notify(config)
    if type(config) == "string" then
        config = {Text = config}
    end
    
    local Title = config.Title or config.title or "Notification"
    local Text = config.Text or config.text or config[1] or ""
    local Duration = config.Duration or config.duration or 3
    local Status = config.Status or config.status or config[2] or "info"
    local Icon = config.Icon or config.icon
    
    local color = (Status == "success" and Color3.fromRGB(100, 255, 100)) or 
                  (Status == "failed" or Status == "error" and Color3.fromRGB(255, 100, 100)) or 
                  (Status == "warning" and Color3.fromRGB(255, 200, 100)) or
                  CFG.AccentColor
    
    local strokeColor = (Status == "success" and Color3.fromRGB(100, 255, 100)) or 
                        (Status == "failed" or Status == "error" and Color3.fromRGB(255, 100, 100)) or 
                        (Status == "warning" and Color3.fromRGB(255, 200, 100)) or
                        CFG.AccentColor

    local Frame = Create("Frame", {
        Parent = NotificationContainer,
        Size = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = CFG.MainColor,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, {
        Create("UIStroke", {Color = strokeColor, Thickness = 1, Transparency = 0.5}),
        Create("Frame", {
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = color
        }),
        Create("UICorner", {CornerRadius = UDim.new(0, 4)})
    })
    
    local xOffset = 10
    
    if Icon then
        local iconData = Icons.Image({
            Icon = Icon,
            Size = UDim2.new(0, 16, 0, 16),
            Colors = {color}
        })
        if iconData and iconData.IconFrame then
            iconData.IconFrame.Position = UDim2.new(0, 10, 0.5, -8)
            iconData.IconFrame.Parent = Frame
            xOffset = 32
        end
    end
    
    local ContentFrame = Create("Frame", {
        Parent = Frame,
        Size = UDim2.new(1, -xOffset - 5, 1, 0),
        Position = UDim2.new(0, xOffset, 0, 0),
        BackgroundTransparency = 1
    })
    
    Create("TextLabel", {
        Parent = ContentFrame,
        Text = Title,
        TextColor3 = CFG.TextColor,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 3),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    
    Create("TextLabel", {
        Parent = ContentFrame,
        Text = Text,
        TextColor3 = CFG.TextDark,
        Font = CFG.Font,
        TextSize = 10,
        Size = UDim2.new(1, 0, 0, 13),
        Position = UDim2.new(0, 0, 0, 17),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })

    local finalHeight = (Text ~= "" and Title ~= "Notification") and 45 or 35
    Tween(Frame, {Size = UDim2.new(0, 280, 0, finalHeight)}, 0.5, Enum.EasingStyle.Back)
    
    task.delay(Duration, function()
        Tween(Frame, {Size = UDim2.new(0, 280, 0, 0), BackgroundTransparency = 1}, 0.5)
        task.wait(0.5)
        Frame:Destroy()
    end)
end

local TooltipLabel = Create("TextLabel", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 0, 0, 20),
    BackgroundColor3 = CFG.SecondaryColor,
    TextColor3 = CFG.TextColor,
    TextSize = 11,
    Font = CFG.Font,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 200
}, {
    Create("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}),
    Create("UIStroke", {Color = CFG.StrokeColor})
})

local function AddTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        TooltipLabel.Text = text
        TooltipLabel.Size = UDim2.fromOffset(GetTextSize(text, 11, CFG.Font).X + 12, 20)
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
    Size = UDim2.fromOffset(CFG.BaseSize.X, CFG.BaseSize.Y),
    Position = UDim2.new(0.5, -300, 0.5, -225),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0
}, {
    Create("UIStroke", {Color = CFG.StrokeColor}),
    Create("UICorner", {CornerRadius = UDim.new(0, 3)})
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
        Tween(MainFrame, {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)}, 0.05)
    end
end)

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

local TopBar = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = CFG.MainColor,
    BorderSizePixel = 0
}, {
    Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CFG.StrokeColor
    })
})

local TitleLabel = Create("TextLabel", {
    Parent = TopBar,
    Text = "Dotfunc | https://discord.gg/2WTGPhrr6F |",
    TextColor3 = CFG.TextDark,
    TextSize = 13,
    Font = CFG.Font,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 300, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    RichText = true
})

local SearchContainer = Create("Frame", {
    Parent = TopBar,
    Size = UDim2.new(0, 200, 0, 22),
    Position = UDim2.new(1, -205, 0.5, -11),
    BackgroundColor3 = CFG.SecondaryColor,
    BorderSizePixel = 0
}, {
    Create("UIStroke", {Color = CFG.StrokeColor}),
    Create("UICorner", {CornerRadius = UDim.new(0, 4)})
})

local SearchIcon = Create("ImageLabel", {
    Parent = SearchContainer,
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(0, 6, 0.5, -7),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6031068433",
    ImageColor3 = CFG.TextDark
})

local SearchBox = Create("TextBox", {
    Parent = SearchContainer,
    Size = UDim2.new(1, -26, 1, 0),
    Position = UDim2.new(0, 26, 0, 0),
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

-- IMPROVED SEARCH LOGIC
local function FilterElements(query)
    query = query:lower()
    
    if query == "" then
        -- Reset everything to visible
        for _, element in pairs(Library.SearchableElements) do
            if element.Frame then
                element.Frame.Visible = true
            end
        end
        for _, section in pairs(Library.Sections) do
            section.Frame.Visible = true
        end
        return
    end
    
    -- Track which tabs and sections have matches
    local tabsWithMatches = {}
    local sectionsWithMatches = {}
    
    -- First pass: find matching elements
    for _, element in pairs(Library.SearchableElements) do
        local elementName = element.Name:lower()
        local elementMatches = elementName:find(query, 1, true) ~= nil
        
        if element.Frame then
            element.Frame.Visible = elementMatches
            
            if elementMatches then
                -- Mark this element's section and tab as having matches
                if element.GroupFrame then
                    sectionsWithMatches[element.GroupFrame] = true
                    
                    -- Find which tab this section belongs to
                    for _, tabData in pairs(Library.Tabs) do
                        if element.GroupFrame:IsDescendantOf(tabData.Page) then
                            tabsWithMatches[tabData] = true
                            break
                        end
                    end
                end
            end
        end
    end
    
    -- Second pass: check section names
    for _, section in pairs(Library.Sections) do
        local sectionName = section.Name:lower()
        local sectionMatches = sectionName:find(query, 1, true) ~= nil
        
        if sectionMatches then
            sectionsWithMatches[section.Frame] = true
            
            -- Show all elements in this section
            for _, element in pairs(Library.SearchableElements) do
                if element.GroupFrame == section.Frame and element.Frame then
                    element.Frame.Visible = true
                end
            end
            
            -- Mark tab as having matches
            for _, tabData in pairs(Library.Tabs) do
                if section.Frame:IsDescendantOf(tabData.Page) then
                    tabsWithMatches[tabData] = true
                    break
                end
            end
        end
    end
    
    -- Third pass: update section visibility
    for _, section in pairs(Library.Sections) do
        section.Frame.Visible = sectionsWithMatches[section.Frame] == true
    end
    
    -- If there are matches, switch to the first tab that has them
    if query ~= "" then
        for tabData, _ in pairs(tabsWithMatches) do
            -- Switch to this tab
            for _, t in pairs(Library.Tabs) do
                Tween(t.Btn.Icon, {ImageColor3 = CFG.TextDark}, 0.2)
                Tween(t.Btn, {BackgroundColor3 = CFG.MainColor}, 0.2)
                t.Page.Visible = false
            end
            Tween(tabData.Btn.Icon, {ImageColor3 = CFG.AccentColor}, 0.2)
            Tween(tabData.Btn, {BackgroundColor3 = CFG.SecondaryColor}, 0.2)
            tabData.Page.Visible = true
            break -- Only switch to the first matching tab
        end
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    FilterElements(SearchBox.Text)
end)

task.spawn(function()
    local textList = {
        '', 'D', 'Do', 'Dot', 'Dotf', 'Dotfu', 'Dotfun', 'Dotfunc',
        'Dotfunc |', 'Dotfunc | h', 'Dotfunc | ht', 'Dotfunc | htt',
        'Dotfunc | http', 'Dotfunc | https', 'Dotfunc | https:', 'Dotfunc | https:/',
        'Dotfunc | https://', 'Dotfunc | https://d', 'Dotfunc | https://di',
        'Dotfunc | https://dis', 'Dotfunc | https://disc', 'Dotfunc | https://disco',
        'Dotfunc | https://discor', 'Dotfunc | https://discord', 'Dotfunc | https://discord.',
        'Dotfunc | https://discord.g', 'Dotfunc | https://discord.gg',
        'Dotfunc | https://discord.gg/', 'Dotfunc | https://discord.gg/2',
        'Dotfunc | https://discord.gg/2W', 'Dotfunc | https://discord.gg/2WT',
        'Dotfunc | https://discord.gg/2WTG', 'Dotfunc | https://discord.gg/2WTGP',
        'Dotfunc | https://discord.gg/2WTGPh', 'Dotfunc | https://discord.gg/2WTGPhr',
        'Dotfunc | https://discord.gg/2WTGPhrr', 'Dotfunc | https://discord.gg/2WTGPhrr6',
        'Dotfunc | https://discord.gg/2WTGPhrr6F', 'Dotfunc | https://discord.gg/2WTGPhrr6F |',
        'Dotfunc | https://discord.gg/2WTGPhrr6F', 'Dotfunc | https://discord.gg/2WTGPhrr6',
        'Dotfunc | https://discord.gg/2WTGPhrr', 'Dotfunc | https://discord.gg/2WTGPhr',
        'Dotfunc | https://discord.gg/2WTGPh', 'Dotfunc | https://discord.gg/2WTGP',
        'Dotfunc | https://discord.gg/2WTG', 'Dotfunc | https://discord.gg/2WT',
        'Dotfunc | https://discord.gg/2W', 'Dotfunc | https://discord.gg/2',
        'Dotfunc | https://discord.gg/', 'Dotfunc | https://discord.gg',
        'Dotfunc | https://discord.g', 'Dotfunc | https://discord.',
        'Dotfunc | https://discord', 'Dotfunc | https://discor', 'Dotfunc | https://disco',
        'Dotfunc | https://disc', 'Dotfunc | https://dis', 'Dotfunc | https://di',
        'Dotfunc | https://d', 'Dotfunc | https://', 'Dotfunc | https:/',
        'Dotfunc | https:', 'Dotfunc | https', 'Dotfunc | http', 'Dotfunc | htt',
        'Dotfunc | ht', 'Dotfunc | h', 'Dotfunc |', 'Dotfunc', 'Dotfun', 'Dotfu',
        'Dotf', 'Dot', 'Do', 'D'
    }
    while not Library.Unloaded do
        for _, text in ipairs(textList) do
            if Library.Unloaded then break end
            local display = text
            if string.find(text, "discord.gg/2WTGPhrr6F") then
                display = string.gsub(text, "discord.gg/2WTGPhrr6F", '<font color="#bdacff">discord.gg/2WTGPhrr6F</font>')
            elseif string.find(text, "Dotfunc") then
                display = string.gsub(text, "Dotfunc", '<font color="#bdacff">Dotfunc</font>')
            end
            TitleLabel.Text = display
            task.wait(0.15)
        end
    end
end)

local ContentContainer = Create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1
})

local SidebarContainer = Create("Frame", {
    Parent = ContentContainer,
    Size = UDim2.new(0, 60, 1, 0),
    BackgroundColor3 = Color3.fromRGB(17, 17, 17),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0)
}, {
    Create("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundColor3 = CFG.StrokeColor})
})

local Sidebar = Create("ScrollingFrame", {
    Parent = SidebarContainer,
    Size = UDim2.new(1, 0, 1, -60),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y
}, {
    Create("UIListLayout", {
        Name = "TabLayout",
        Padding = UDim.new(0, 10), 
        HorizontalAlignment = Enum.HorizontalAlignment.Center, 
        VerticalAlignment = Enum.VerticalAlignment.Top
    }),
    Create("UIPadding", {PaddingTop = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15)})
})

local UserProfileButton = Create("TextButton", {
    Parent = SidebarContainer,
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0.5, -20, 1, -50),
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
    Create("UICorner", {CornerRadius = UDim.new(0, 3)})
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

local DisplayName = Create("TextLabel", {
    Parent = ProfileInfo,
    Text = Player.DisplayName,
    TextColor3 = CFG.TextColor,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Size = UDim2.new(0.5, -10, 0, 20),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top
})

local Username = Create("TextLabel", {
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

local GameID = Create("TextLabel", {
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

local GameName = Create("TextLabel", {
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
    if success then
        GameName.Text = result
    else
        GameName.Text = "Unknown Game"
    end
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

local PagesContainer = Create("Frame", {
    Parent = ContentContainer,
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.new(0, 60, 0, 0),
    BackgroundTransparency = 1
})

local Tabs = {}
local CurrentTab = nil

function Library:Tab(name, icon)
    local TabButton = Create("TextButton", {
        Parent = Sidebar,
        Size = UDim2.new(0, 40, 0, 40),
        BackgroundColor3 = CFG.MainColor,
        Text = "",
        TextSize = 20,
        TextColor3 = CFG.TextDark,
        Font = CFG.Font,
        AutoButtonColor = false
    }, {
        Create("ImageLabel", {
            Name = "Icon",
            Size = UDim2.new(0.6, 0, 0.6, 0),
            Position = UDim2.new(0.2, 0, 0.2, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. icon,
            ImageColor3 = CFG.TextDark
        }),
        Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })

    local PageFrame = Create("ScrollingFrame", {
        Parent = PagesContainer,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CFG.AccentColor,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    local Padding = Create("UIPadding", {
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
        Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
    })
    
    local RightCol = Create("Frame", {
        Parent = PageFrame, 
        Size = UDim2.new(0.48, 0, 1, 0), 
        Position = UDim2.new(0.52, 0, 0, 0), 
        BackgroundTransparency = 1
    }, {
        Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
    })

    local TabData = {Btn = TabButton, Page = PageFrame, Name = name}
    table.insert(Tabs, TabData)
    table.insert(Library.Tabs, TabData)

    TabButton.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do
            Tween(t.Btn.Icon, {ImageColor3 = CFG.TextDark}, 0.2)
            Tween(t.Btn, {BackgroundColor3 = CFG.MainColor}, 0.2)
            t.Page.Visible = false
        end
        Tween(TabButton.Icon, {ImageColor3 = CFG.AccentColor}, 0.2)
        Tween(TabButton, {BackgroundColor3 = CFG.SecondaryColor}, 0.2)
        PageFrame.Visible = true
        CurrentTab = PageFrame
    end)

    if #Tabs == 1 then
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
            Create("UICorner", {CornerRadius = UDim.new(0, 2)})
        })

        Create("Frame", {
            Parent = GroupFrame,
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = CFG.SecondaryColor,
            BorderSizePixel = 0
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 2)}),
            Create("Frame", {
                Size = UDim2.new(1, 0, 0, 5),
                Position = UDim2.new(0, 0, 1, -5),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }),
            Create("TextLabel", {
                Text = title,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = CFG.TextColor,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left
            }),
            Create("Frame", {
                Size = UDim2.new(0, 4, 0, 4),
                Position = UDim2.new(1, -10, 0.5, -2),
                BackgroundColor3 = CFG.AccentColor,
                BorderSizePixel = 0
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
        })

        local Content = Create("Frame", {
            Parent = GroupFrame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 25),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1
        }, {
            Create("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
        })

        table.insert(Library.Sections, {Frame = GroupFrame, Name = title})

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
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = ""
            })

            local Box = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(0, 0, 0.5, -6),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {Create("UIStroke", {Color = CFG.StrokeColor})})

            local Check = Create("Frame", {
                Parent = Box,
                Size = UDim2.new(1, -4, 1, -4),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = CFG.AccentColor,
                BackgroundTransparency = Enabled and 0 or 1
            })

            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = config.Name,
                TextColor3 = Enabled and CFG.TextColor or (config.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark),
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 18, 0, 0),
                Size = UDim2.new(1, -18, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            if config.Tooltip then AddTooltip(Frame, config.Tooltip) end

            local function Update()
                Enabled = not Enabled
                Tween(Check, {BackgroundTransparency = Enabled and 0 or 1}, 0.1)
                Tween(Label, {TextColor3 = Enabled and CFG.TextColor or (config.Risky and Color3.fromRGB(200, 80, 80) or CFG.TextDark)}, 0.1)
                config.Callback(Enabled)
            end

            Frame.MouseButton1Click:Connect(Update)
            
            table.insert(Library.SearchableElements, {Name = config.Name, Frame = Frame, Group = Content, GroupFrame = GroupFrame})
            
            return {Set = function(v) if v ~= Enabled then Update() end end, Get = function() return Enabled end}
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
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1
            })

            local Label = Create("TextLabel", {
                Parent = Frame,
                Text = config.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.6, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ValueBox = Create("TextBox", {
                Parent = Frame,
                Text = tostring(Value) .. (config.Unit or ""),
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundColor3 = CFG.SecondaryColor,
                Size = UDim2.new(0, 50, 0, 15),
                Position = UDim2.new(1, -50, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Center,
                BorderSizePixel = 0
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                Create("UIStroke", {Color = CFG.StrokeColor})
            })

            local SliderBG = Create("Frame", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.new(0, 0, 0, 20),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })

            local Fill = Create("Frame", {
                Parent = SliderBG,
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = CFG.AccentColor
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})

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
                if config.Increment < 1 then
                    Value = math.floor(Value / config.Increment + 0.5) * config.Increment
                else
                    Value = math.floor(Value / config.Increment + 0.5) * config.Increment
                end
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
            
            table.insert(Library.SearchableElements, {Name = config.Name, Frame = Frame, Group = Content, GroupFrame = GroupFrame})
            
            return {Set = function(v) UpdateSlider(v) end, Get = function() return Value end}
        end

        function SectionFuncs:Dropdown(options)
            local config = {
                Name = options.Name or options[1] or "Dropdown",
                Options = options.Options or options[2] or {},
                Default = options.Default or options[3] or (options.Options and options.Options[1]) or "",
                Multi = options.Multi or false,
                Callback = options.Callback or options[4] or function() end,
                Tooltip = options.Tooltip
            }
            
            local Expanded = false
            local Current = config.Multi and {} or config.Default
            local Selected = {}
            
            -- Initialize multi-select defaults
            if config.Multi then
                if type(config.Default) == "table" then
                    for _, v in pairs(config.Default) do
                        Selected[v] = true
                        table.insert(Current, v)
                    end
                end
            end

            local Frame = Create("Frame", {
                Parent = Content,
                Size = UDim2.new(1, 0, 0, 36),
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
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local function GetDisplayText()
                if config.Multi then
                    if #Current == 0 then
                        return "None"
                    elseif #Current == 1 then
                        return Current[1]
                    else
                        return Current[1] .. " (+" .. (#Current - 1) .. ")"
                    end
                else
                    return Current
                end
            end

            local MainBox = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 16),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                Create("TextLabel", {
                    Name = "Val",
                    Text = GetDisplayText(),
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 5, 0, 0),
                    BackgroundTransparency = 1,
                    TextColor3 = CFG.TextColor,
                    TextSize = 11,
                    Font = CFG.Font,
                    TextXAlignment = Enum.TextXAlignment.Left
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
                Position = UDim2.new(0, 0, 1, 2),
                BackgroundColor3 = CFG.SecondaryColor,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 50,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            for _, opt in pairs(config.Options) do
                local Btn = Create("TextButton", {
                    Parent = ListFrame,
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = config.Multi and "" or opt,
                    TextColor3 = (not config.Multi and opt == Current) and CFG.AccentColor or CFG.TextDark,
                    TextSize = 11,
                    Font = CFG.Font,
                    TextXAlignment = config.Multi and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
                })
                
                if config.Multi then
                    -- Add checkbox for multi-select
                    local Checkbox = Create("Frame", {
                        Parent = Btn,
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0, 5, 0.5, -6),
                        BackgroundColor3 = CFG.SecondaryColor,
                        BorderSizePixel = 0
                    }, {
                        Create("UIStroke", {Color = CFG.StrokeColor}),
                        Create("Frame", {
                            Name = "Check",
                            Size = UDim2.new(1, -4, 1, -4),
                            Position = UDim2.new(0.5, 0, 0.5, 0),
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            BackgroundColor3 = CFG.AccentColor,
                            BackgroundTransparency = Selected[opt] and 0 or 1
                        })
                    })
                    
                    local Label = Create("TextLabel", {
                        Parent = Btn,
                        Text = opt,
                        TextColor3 = Selected[opt] and CFG.AccentColor or CFG.TextDark,
                        TextSize = 11,
                        Font = CFG.Font,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 22, 0, 0),
                        Size = UDim2.new(1, -22, 1, 0),
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    
                    Btn.MouseButton1Click:Connect(function()
                        Selected[opt] = not Selected[opt]
                        Tween(Checkbox.Check, {BackgroundTransparency = Selected[opt] and 0 or 1}, 0.1)
                        Tween(Label, {TextColor3 = Selected[opt] and CFG.AccentColor or CFG.TextDark}, 0.1)
                        
                        -- Update Current table
                        Current = {}
                        for option, isSelected in pairs(Selected) do
                            if isSelected then
                                table.insert(Current, option)
                            end
                        end
                        
                        MainBox.Val.Text = GetDisplayText()
                        config.Callback(Current)
                    end)
                else
                    -- Single select behavior
                    Btn.MouseButton1Click:Connect(function()
                        Current = opt
                        MainBox.Val.Text = opt
                        config.Callback(opt)
                        
                        -- Update all button colors
                        for _, child in pairs(ListFrame:GetChildren()) do
                            if child:IsA("TextButton") then
                                child.TextColor3 = (child.Text == opt) and CFG.AccentColor or CFG.TextDark
                            end
                        end
                        
                        Expanded = false
                        Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.1)
                        task.wait(0.1)
                        ListFrame.Visible = false
                    end)
                end
            end

            MainBox.MouseButton1Click:Connect(function()
                Expanded = not Expanded
                if Expanded then
                    ListFrame.Visible = true
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, math.min(#config.Options * 20, 100))}, 0.1)
                else
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.1)
                    task.wait(0.1)
                    ListFrame.Visible = false
                end
            end)
            if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
            
            table.insert(Library.SearchableElements, {Name = config.Name, Frame = Frame, Group = Content, GroupFrame = GroupFrame})
            
            return {
                Set = function(v) 
                    if config.Multi then
                        Selected = {}
                        Current = {}
                        if type(v) == "table" then
                            for _, val in pairs(v) do
                                Selected[val] = true
                                table.insert(Current, val)
                            end
                        end
                        MainBox.Val.Text = GetDisplayText()
                        -- Update UI
                        for _, child in pairs(ListFrame:GetChildren()) do
                            if child:IsA("TextButton") then
                                local checkFrame = child:FindFirstChild("Frame")
                                local label = child:FindFirstChildOfClass("TextLabel")
                                if checkFrame and label then
                                    local isSelected = Selected[label.Text]
                                    checkFrame.Check.BackgroundTransparency = isSelected and 0 or 1
                                    label.TextColor3 = isSelected and CFG.AccentColor or CFG.TextDark
                                end
                            end
                        end
                    else
                        Current = v
                        MainBox.Val.Text = v
                    end
                end,
                Get = function() 
                    return Current 
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
                Size = UDim2.new(1, 0, 0, 20),
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
                Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Preview = Create("TextButton", {
                Parent = Frame,
                Size = UDim2.new(0, 30, 0, 14),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                BackgroundColor3 = Color,
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            local PickerFrame = Create("Frame", {
                Parent = Preview,
                Size = UDim2.new(0, 180, 0, 0),
                Position = UDim2.new(1, 0, 1, 5),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = CFG.MainColor,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 60
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            local SatValPanel = Create("TextButton", {
                Parent = PickerFrame,
                Size = UDim2.new(1, -20, 0, 100),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4801885019"
                }),
                Create("ImageLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://4801885019",
                    ImageColor3 = Color3.new(0,0,0),
                    Rotation = 90
                })
            })

            local Cursor = Create("Frame", {
                Parent = SatValPanel,
                Size = UDim2.new(0, 4, 0, 4),
                BackgroundColor3 = Color3.new(1,1,1),
                AnchorPoint = Vector2.new(0.5, 0.5)
            }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})

            local HueSlider = Create("TextButton", {
                Parent = PickerFrame,
                Size = UDim2.new(1, -20, 0, 10),
                Position = UDim2.new(0, 10, 0, 120),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1))
                    })
                }),
                Create("UICorner", {CornerRadius = UDim.new(0, 2)})
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
                    DraggingHSV = false; DraggingHue = false 
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
                    Tween(PickerFrame, {Size = UDim2.new(0, 180, 0, 170)}, 0.2)
                else
                    Tween(PickerFrame, {Size = UDim2.new(0, 180, 0, 0)}, 0.2)
                end
            end)
            if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
            
            table.insert(Library.SearchableElements, {Name = config.Name, Frame = Frame, Group = Content, GroupFrame = GroupFrame})
            
            return {Set = function(c) Color = c; Preview.BackgroundColor3 = c; H, S, V = Color:ToHSV(); UpdateColor() end, Get = function() return Color end}
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
                Size = UDim2.new(1, 0, 0, 35),
                BackgroundTransparency = 1
            })
            
            Create("TextLabel", {
                Parent = Frame,
                Text = config.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 11,
                Font = CFG.Font,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15),
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Box = Create("TextBox", {
                Parent = Frame,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 15),
                BackgroundColor3 = CFG.SecondaryColor,
                TextColor3 = CFG.TextColor,
                PlaceholderText = config.Placeholder,
                Text = config.Default,
                Font = CFG.Font,
                TextSize = 11,
                BorderSizePixel = 0
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
                Create("UIPadding", {PaddingLeft = UDim.new(0, 5)})
            })

            Box.FocusLost:Connect(function()
                config.Callback(Box.Text)
            end)
            if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
            
            table.insert(Library.SearchableElements, {Name = config.Name, Frame = Frame, Group = Content, GroupFrame = GroupFrame})
            
            return {Set = function(v) Box.Text = v end, Get = function() return Box.Text end}
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
                Size = UDim2.new(1, 0, 0, 20),
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
                Size = UDim2.new(0, 60, 1, 0),
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = CFG.SecondaryColor,
                Text = Key.Name,
                TextColor3 = CFG.TextDark,
                TextSize = 10,
                Font = CFG.Font
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
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
                    Btn.TextColor3 = CFG.TextDark
                    config.Callback(Key)
                end
            end)
            if config.Tooltip then AddTooltip(Frame, config.Tooltip) end
            
            table.insert(Library.SearchableElements, {Name = config.Name, Frame = Frame, Group = Content, GroupFrame = GroupFrame})
            
            return {Set = function(k) Key = k; Btn.Text = k.Name end, Get = function() return Key end}
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
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundColor3 = CFG.SecondaryColor,
                Text = config.Name,
                TextColor3 = CFG.TextDark,
                Font = Enum.Font.GothamBold,
                TextSize = 10
            }, {
                Create("UIStroke", {Color = CFG.StrokeColor}),
                Create("UICorner", {CornerRadius = UDim.new(0, 3)})
            })

            if config.Variant == "Primary" then
                Btn.BackgroundColor3 = CFG.AccentColor
                Btn.TextColor3 = Color3.new(0,0,0)
            elseif config.Variant == "Danger" then
                Btn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                Btn.TextColor3 = Color3.new(0,0,0)
            end

            Btn.MouseButton1Click:Connect(function()
                config.Callback()
            end)
            if config.Tooltip then AddTooltip(Btn, config.Tooltip) end
            
            table.insert(Library.SearchableElements, {Name = config.Name, Frame = Btn, Group = Content, GroupFrame = GroupFrame})
            
            return Btn
        end

        return SectionFuncs
    end
    return TabFunctions
end

return Library
