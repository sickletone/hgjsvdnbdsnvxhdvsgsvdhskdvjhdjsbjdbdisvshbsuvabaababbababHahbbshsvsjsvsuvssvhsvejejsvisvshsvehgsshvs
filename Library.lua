local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = nil;
pcall(function()
    CoreGui = game:GetService('CoreGui');
end);
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local Lighting = game:GetService('Lighting');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local function GetGuiParent()
    local Success, Hidden = pcall(function()
        return gethui and gethui()
    end)
    if Success and Hidden then
        return Hidden
    end
    if CoreGui then
        return CoreGui
    end
    return LocalPlayer:WaitForChild('PlayerGui')
end

local function GetEnv()
    if getgenv then
        return getgenv()
    end
    return _G
end

local RequestedNamespace = ...
local Env = GetEnv()
local Namespace = type(RequestedNamespace) == 'string' and RequestedNamespace
    or (type(Env.SillyUINamespace) == 'string' and Env.SillyUINamespace)
    or 'silly'
local IsDefaultNamespace = Namespace == 'silly'
local GuiSuffix = IsDefaultNamespace and '' or ('_' .. Namespace)

local Libraries = Env.SillyLibraries
if type(Libraries) ~= 'table' then
    Libraries = {}
    Env.SillyLibraries = Libraries
end

local Existing = Libraries[Namespace]
if type(Existing) == 'table' and Existing.IsSillyLibrary and not Existing.Unloaded then
    return Existing
end

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
ScreenGui.Name = 'angel' .. GuiSuffix;
ScreenGui.IgnoreGuiInset = true;
ScreenGui.ResetOnSpawn = false;
ScreenGui.DisplayOrder = 999;
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
ScreenGui.Parent = GetGuiParent();

local Toggles = {};
local Options = {};

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(21, 21, 20);
    BackgroundColor = Color3.fromRGB(17, 17, 16);
    AccentColor = Color3.fromRGB(147, 161, 254);
    OutlineColor = Color3.fromRGB(31, 30, 31);
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0);

    Font = Enum.Font.SourceSans,
    FontSize = 13,

    OpenedFrames = {};
    DependencyBoxes = {};
    Labels = {};
    Windows = {};
    Scale = 1;

    Signals = {};
    ScreenGui = ScreenGui;

    Namespace = Namespace;
    IsDefaultNamespace = IsDefaultNamespace;
    IsSillyLibrary = true;

    BuildVersion = '0.1';
    Suffix = '.lua';

    Toggled = false;
    WireframeDrag = false;
    Locked = false;
    SilentLoad = false;
    ShowCustomCursor = true;
    UnlockMouseWhileOpen = true;
    ShowToggleFrameInKeybinds = true;
    NotifySide = 'Left';
    WatermarkCustom = false;
    WatermarkStats = true;
    MenuFadeTime = 0.2;
    UseBlur = false;
    BlurSize = 15;

    ResizeHandles = true;
    ResizeThickness = 6;
    MinWindowSize = Vector2.new(360, 320);
    MaxWindowSize = Vector2.new(1200, 900);

    KeybindMode = 'All';

    NotifyConfig = {
        Alignment = 'Left';
        BarSide   = 'Left';
        PositionX = 0;
        PositionY = 40;
    };
};

Library.KeyPickerList = {};
Library.Toggles = Toggles;
Library.Options = Options;
Libraries[Namespace] = Library;

if IsDefaultNamespace then
    Env.Toggles = Toggles;
    Env.Options = Options;
    Env.Library = Library;
end

Library.ToggleKey = IsDefaultNamespace and Enum.KeyCode.RightControl or Enum.KeyCode.F1;
Library.CursorEnabled = true;

Library.BlurEffect = Instance.new("BlurEffect")
Library.BlurEffect.Name = "angelBlur" .. GuiSuffix
Library.BlurEffect.Size = 0
Library.BlurEffect.Enabled = false
pcall(function() Library.BlurEffect.Parent = Lighting end)

function Library:UpdateBlur()
    if Library.UseBlur then
        if Library.Toggled then
            Library.BlurEffect.Enabled = true
            TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = Library.BlurSize}):Play()
        end
    else
        local tween = TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = 0})
        tween:Play()

        task.delay(0.2, function()
            if not Library.UseBlur then
                Library.BlurEffect.Enabled = false
            end
        end)
    end
end

function Library:SetFontSize(Size)
    Library.FontSize = Size
    for _, descendant in pairs(ScreenGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
            local offset = descendant:GetAttribute("FontSizeOffset")
            if offset then
                descendant.TextSize = Size + offset
            end
        end
    end
    local mobileUI = Library.MobileUI
    if mobileUI then
        for _, descendant in pairs(mobileUI:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
                local offset = descendant:GetAttribute("FontSizeOffset")
                if offset then
                    descendant.TextSize = Size + offset
                end
            end
        end
    end
end

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);
        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;
    table.sort(TeamList, function(str1, str2) return str1 < str2 end);

    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;
    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then
            return Library:Notify(event);
        end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    if _Instance:IsA("TextLabel") or _Instance:IsA("TextBox") or _Instance:IsA("TextButton") then
        if Properties.TextSize then
            _Instance:SetAttribute("FontSizeOffset", Properties.TextSize - Library.FontSize)
        else
            _Instance:SetAttribute("FontSizeOffset", 0)
        end
    end

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:ApplyGlow(Inst)

end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = Library.FontSize + 2;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);
    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff, IsWindow, MoveTarget)
    local Target = MoveTarget or Instance;
    Instance.Active = true;
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
            return;
        end

        if IsWindow and Library.Locked then
            return;
        end

        local StartPos = Target.Position;
        local DragStart = Input.Position;

        if (DragStart.Y - Instance.AbsolutePosition.Y) > (Cutoff or 40) then
            return;
        end

        local HasMoved = false;
        local Wireframe = nil;
        local ChangedConn, EndedConn;

        ChangedConn = InputService.InputChanged:Connect(function(Change)
            if Change.UserInputType ~= Enum.UserInputType.MouseMovement and Change ~= Input then
                return;
            end

            local Delta = Change.Position - DragStart;

            if IsWindow and Library.WireframeDrag then
                if not HasMoved and Delta.Magnitude > 2 then
                    HasMoved = true;
                    Wireframe = Library:Create('Frame', {
                        Size = Target.Size;
                        Position = Target.Position;
                        AnchorPoint = Target.AnchorPoint;
                        BackgroundTransparency = 1;
                        Active = false;
                        ZIndex = 100000;
                        Parent = ScreenGui;
                    });
                    Library:Create('UIStroke', {
                        Color = Library.AccentColor;
                        Thickness = 1;
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
                        Parent = Wireframe;
                    });
                end

                if HasMoved and Wireframe then
                    Wireframe.Position = UDim2.new(
                        StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                        StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                    );
                end
            else
                Target.Position = UDim2.new(
                    StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                    StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                );
            end
        end);

        EndedConn = InputService.InputEnded:Connect(function(EndInput)
            if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                ChangedConn:Disconnect();
                EndedConn:Disconnect();

                if IsWindow and Library.WireframeDrag and HasMoved and Wireframe then
                    Target.Position = Wireframe.Position;
                    Wireframe:Destroy();
                    Wireframe = nil;
                end
            end
        end);
    end);
end;

function Library:GetViewportSize()
    local Camera = workspace.CurrentCamera;
    return (Camera and Camera.ViewportSize) or Vector2.new(1920, 1080);
end;

function Library:GetResizeThickness()
    return Library.ResizeThickness + (InputService.TouchEnabled and 4 or 0);
end;

function Library:GetWindowSizeLimits()
    local Viewport = Library:GetViewportSize();
    local Minimum = Library.MinWindowSize;
    local Maximum = Vector2.new(
        math.min(Library.MaxWindowSize.X, math.max(Minimum.X, Viewport.X - 20)),
        math.min(Library.MaxWindowSize.Y, math.max(Minimum.Y, Viewport.Y - 20))
    );
    return Minimum, Maximum;
end;

function Library:ClampWindowPosition(Position, Size)
    local Viewport = Library:GetViewportSize();
    local X = math.clamp(Position.X, 0, math.max(0, Viewport.X - Size.X));
    local Y = math.clamp(Position.Y, 0, math.max(0, Viewport.Y - Size.Y));
    return Vector2.new(X, Y);
end;

function Library:AddResizeHandles(Target)
    if not Library.ResizeHandles then
        return;
    end

    local Thickness = Library:GetResizeThickness();
    local CornerSize = math.max(Thickness, 14);

    local Edges = {
        { Name = 'N'; Position = UDim2.new(0, Thickness, 0, 0); Size = UDim2.new(1, -Thickness * 2, 0, Thickness); X = 0; Y = -1; HighlightPosition = UDim2.new(0, 0, 0, 0); HighlightSize = UDim2.new(1, 0, 0, 2); };
        { Name = 'S'; Position = UDim2.new(0, Thickness, 1, -Thickness); Size = UDim2.new(1, -Thickness * 2, 0, Thickness); X = 0; Y = 1; HighlightPosition = UDim2.new(0, 0, 1, -2); HighlightSize = UDim2.new(1, 0, 0, 2); };
        { Name = 'W'; Position = UDim2.new(0, 0, 0, Thickness); Size = UDim2.new(0, Thickness, 1, -Thickness * 2); X = -1; Y = 0; HighlightPosition = UDim2.new(0, 0, 0, 0); HighlightSize = UDim2.new(0, 2, 1, 0); };
        { Name = 'E'; Position = UDim2.new(1, -Thickness, 0, Thickness); Size = UDim2.new(0, Thickness, 1, -Thickness * 2); X = 1; Y = 0; HighlightPosition = UDim2.new(1, -2, 0, 0); HighlightSize = UDim2.new(0, 2, 1, 0); };
        { Name = 'NW'; Position = UDim2.new(0, 0, 0, 0); Size = UDim2.fromOffset(CornerSize, CornerSize); X = -1; Y = -1; HighlightPosition = UDim2.new(0, 0, 0, 0); HighlightSize = UDim2.new(1, 0, 1, 0); };
        { Name = 'NE'; Position = UDim2.new(1, -CornerSize, 0, 0); Size = UDim2.fromOffset(CornerSize, CornerSize); X = 1; Y = -1; HighlightPosition = UDim2.new(0, 0, 0, 0); HighlightSize = UDim2.new(1, 0, 1, 0); };
        { Name = 'SW'; Position = UDim2.new(0, 0, 1, -CornerSize); Size = UDim2.fromOffset(CornerSize, CornerSize); X = -1; Y = 1; HighlightPosition = UDim2.new(0, 0, 0, 0); HighlightSize = UDim2.new(1, 0, 1, 0); };
        { Name = 'SE'; Position = UDim2.new(1, -CornerSize, 1, -CornerSize); Size = UDim2.fromOffset(CornerSize, CornerSize); X = 1; Y = 1; HighlightPosition = UDim2.new(0, 0, 0, 0); HighlightSize = UDim2.new(1, 0, 1, 0); };
    }

    local Active, ActiveEdge, ActiveInput = false, nil, nil;
    local StartSize, StartPosition, StartPointer = nil, nil, nil;
    local Highlights, GripLines = {}, {};

    local function SetGripAccent(Active)
        for _, Line in next, GripLines do
            Line.BackgroundColor3 = Active and Library.AccentColor or Library.FontColor;
            Line.BackgroundTransparency = Active and 0.35 or 0.7;
            Library.RegistryMap[Line].Properties.BackgroundColor3 = Active and 'AccentColor' or 'FontColor';
        end
    end

    local function PrepareResize()
        local Absolute = Target.AbsolutePosition;
        Target.AnchorPoint = Vector2.zero;
        Target.Position = UDim2.fromOffset(Absolute.X, Absolute.Y);
    end

    for _, Edge in next, Edges do
        local Handle = Library:Create('TextButton', {
            Name = 'Resize' .. Edge.Name;
            Text = '';
            BackgroundTransparency = 1;
            AutoButtonColor = false;
            Position = Edge.Position;
            Size = Edge.Size;
            ZIndex = 100;
            Parent = Target;
        });

        local Highlight = Library:Create('Frame', {
            Name = 'Highlight';
            BackgroundColor3 = Library.AccentColor;
            BackgroundTransparency = 0.7;
            BorderSizePixel = 0;
            Position = Edge.HighlightPosition;
            Size = Edge.HighlightSize;
            Visible = false;
            Active = false;
            ZIndex = 102;
            Parent = Handle;
        });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' });
        table.insert(Highlights, Highlight);

        Handle.MouseEnter:Connect(function()
            Highlight.Visible = true;
            if Edge.Name == 'SE' then
                SetGripAccent(true);
            end
        end);

        Handle.MouseLeave:Connect(function()
            Highlight.Visible = false;
            if Edge.Name == 'SE' then
                SetGripAccent(false);
            end
        end);

        if Edge.Name == 'SE' then
            local Grip = Library:Create('Frame', {
                Name = 'ResizeGrip';
                BackgroundTransparency = 1;
                AnchorPoint = Vector2.new(0.5, 0.5);
                Position = UDim2.fromScale(0.5, 0.5);
                Size = UDim2.fromOffset(12, 12);
                ZIndex = 103;
                Parent = Handle;
            });

            local Parts = {
                { Position = UDim2.fromOffset(2, 9); Size = UDim2.fromOffset(9, 1); };
                { Position = UDim2.fromOffset(5, 6); Size = UDim2.fromOffset(6, 1); };
                { Position = UDim2.fromOffset(8, 3); Size = UDim2.fromOffset(3, 1); };
            }

            for _, Part in next, Parts do
                local Line = Library:Create('Frame', {
                    BackgroundColor3 = Library.FontColor;
                    BackgroundTransparency = 0.7;
                    BorderSizePixel = 0;
                    Position = Part.Position;
                    Size = Part.Size;
                    ZIndex = 104;
                    Parent = Grip;
                });
                Library:AddToRegistry(Line, { BackgroundColor3 = 'FontColor' });
                table.insert(GripLines, Line);
            end
        end

        Handle.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                return;
            end
            if Library.Locked then
                return;
            end

            PrepareResize();

            Active = true;
            ActiveEdge = Edge;
            ActiveInput = Input;
            StartSize = Target.AbsoluteSize;
            StartPosition = Vector2.new(Target.Position.X.Offset, Target.Position.Y.Offset);
            StartPointer = Input.Position;
        end);
    end

    Library:GiveSignal(InputService.InputChanged:Connect(function(Input)
        if not Active then
            return;
        end

        if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input ~= ActiveInput then
            return;
        end

        local Delta = Input.Position - StartPointer;
        local Minimum, Maximum = Library:GetWindowSizeLimits();

        local Width = math.clamp(StartSize.X + ActiveEdge.X * Delta.X, Minimum.X, Maximum.X);
        local Height = math.clamp(StartSize.Y + ActiveEdge.Y * Delta.Y, Minimum.Y, Maximum.Y);

        local OffsetX = (ActiveEdge.X < 0) and (StartSize.X - Width) or 0;
        local OffsetY = (ActiveEdge.Y < 0) and (StartSize.Y - Height) or 0;

        local Position = Library:ClampWindowPosition(
            Vector2.new(StartPosition.X + OffsetX, StartPosition.Y + OffsetY),
            Vector2.new(Width, Height)
        );

        local UIScale = Target:FindFirstChildOfClass('UIScale');
        local Scale = UIScale and UIScale.Scale or 1;

        Target.Size = UDim2.fromOffset(Width / Scale, Height / Scale);
        Target.Position = UDim2.fromOffset(Position.X, Position.Y);
    end));

    Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
        if not Active then
            return;
        end

        if Input == ActiveInput or Input.UserInputType == Enum.UserInputType.Touch then
            Active = false;
            ActiveEdge = nil;
            ActiveInput = nil;

            if InputService.TouchEnabled then
                for _, Highlight in next, Highlights do
                    Highlight.Visible = false;
                end

                SetGripAccent(false);
            end
        end
    end));
end;

function Library:AddToolTip(InfoStr, HoverInstance, DisabledStr, IsDisabled)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, Library.FontSize);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = Library.FontSize;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });
    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        local Text = InfoStr;
        if DisabledStr and IsDisabled and IsDisabled() then
            Text = DisabledStr;
        end

        if Label.Text ~= Text then
            Label.Text = Text;

            local TextX, TextY = Library:GetTextBounds(Text, Library.Font, Library.FontSize);
            Tooltip.Size = UDim2.fromOffset(TextX + 5, TextY + 4);
            Label.Size = UDim2.fromOffset(TextX, TextY);
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

function Library:ColorToHex(Color)
    return string.format(
        '%02X%02X%02X',
        math.floor(math.clamp(Color.R, 0, 1) * 255 + 0.5),
        math.floor(math.clamp(Color.G, 0, 1) * 255 + 0.5),
        math.floor(math.clamp(Color.B, 0, 1) * 255 + 0.5)
    );
end;

function Library:FormatTitle(Title, Suffix)
    Title = type(Title) == 'string' and Title or 'silly';
    Suffix = Suffix == nil and Library.Suffix or Suffix;

    if type(Suffix) ~= 'string' or Suffix == '' then
        return Title;
    end

    local Separator = Title:find('|', 1, true);
    local Base = Separator and Title:sub(1, Separator - 1) or Title;
    local Rest = Separator and Title:sub(Separator) or '';
    local Trimmed = Base:gsub('%s+$', '');
    local Whitespace = Base:sub(#Trimmed + 1);

    if Trimmed == '' then
        Trimmed = 'silly';
    end

    if #Trimmed >= #Suffix and Trimmed:sub(-#Suffix) == Suffix then
        Trimmed = Trimmed:sub(1, -#Suffix - 1);
    end

    if Trimmed == '' then
        Trimmed = 'silly';
    end

    return Trimmed .. '<font color="#' .. Library:ColorToHex(Library.AccentColor) .. '">' .. Suffix .. '</font>' .. Whitespace .. Rest;
end;

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;

    if Library.RefreshSuffixes then
        Library:RefreshSuffixes();
    end
end;

function Library:GiveSignal(Signal)
    if Library.Unloaded then
        pcall(function()
            Signal:Disconnect();
        end);
        return;
    end

    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    if Library.Unloaded then
        return;
    end

    Library:SetCursorEnabled(false);
    Library.Unloaded = true;
    Library.Toggled = false;

    if Library.OnUnload then
        pcall(Library.OnUnload);
        Library.OnUnload = nil;
    end

    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx);
        pcall(function()
            Connection:Disconnect();
        end);
    end
    table.clear(Library.Signals);

    if Library.BlurEffect then
        Library.BlurEffect:Destroy();
        Library.BlurEffect = nil;
    end

    if Library.MobileUI then
        Library.MobileUI:Destroy();
        Library.MobileUI = nil;
    end

    table.clear(Library.OpenedFrames);

    for _, Window in next, Library.Windows do
        if Window.Tabs then
            table.clear(Window.Tabs);
            Window.Tabs = nil;
        end

        Window.Holder = nil;
        Window.UIScale = nil;
    end

    ScreenGui:Destroy();

    table.clear(Library.Toggles);
    table.clear(Library.Options);
    table.clear(Library.Labels);
    table.clear(Library.Windows);
    table.clear(Library.DependencyBoxes);
    table.clear(Library.KeyPickerList);
    table.clear(Library.RegistryMap);

    if Library.MobileButtons then
        table.clear(Library.MobileButtons);
    end

    Library.Toggles = nil;
    Library.Options = nil;
    Library.Labels = nil;
    Library.Windows = nil;
    Library.DependencyBoxes = nil;
    Library.KeyPickerList = nil;
    Library.MobileButtons = nil;
    Library.MobileToggleButton = nil;
    Library.MobileLockButton = nil;
    Library.KeybindFrame = nil;
    Library.KeybindContainer = nil;
    Library.Watermark = nil;
    Library.WatermarkText = nil;
    Library.NotificationArea = nil;
    Library.NotifLayout = nil;
    Library.Cursor = nil;
    Library.CursorConnections = nil;
    Library.UpdateNotifAlignment = nil;
    Library.UpdateColorsUsingRegistry = nil;
    Library.Toggle = nil;
    Library.ToggleKeybind = nil;
    Library.ScreenGui = nil;

    local Env = GetEnv();
    if Env then
        if Env.Options == Options then Env.Options = nil end
        if Env.Toggles == Toggles then Env.Toggles = nil end
        if Env.Library == Library then Env.Library = nil end
        if Env.SillyLibraries and Env.SillyLibraries[Namespace] == Library then
            Env.SillyLibraries[Namespace] = nil
        end
    end
end

function Library:OnUnload(Callback)
    if Library.Unloaded then
        return;
    end

    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local CursorHost = Library:Create('Frame', {
    Name = 'Cursor';
    BackgroundTransparency = 1;
    AnchorPoint = Vector2.new(0.5, 0.5);
    Size = UDim2.fromOffset(11, 11);
    Visible = false;
    Active = false;
    ZIndex = 1000000;
    Parent = ScreenGui;
});
pcall(function()
    CursorHost.Interactable = false;
end);

local function CursorBar(Color, X, Y, W, H, Z)
    local Bar = Library:Create('Frame', {
        BackgroundColor3 = Color;
        BorderSizePixel = 0;
        Position = UDim2.fromOffset(X, Y);
        Size = UDim2.fromOffset(W, H);
        Active = false;
        ZIndex = Z;
        Parent = CursorHost;
    });
    pcall(function()
        Bar.Interactable = false;
    end);
end

CursorBar(Library.OutlineColor, 0, 4, 11, 3, 1);
CursorBar(Library.OutlineColor, 4, 0, 3, 11, 1);
CursorBar(Library.FontColor, 1, 5, 9, 1, 2);
CursorBar(Library.FontColor, 5, 1, 1, 9, 2);

Library.Cursor = CursorHost;
Library.CursorConnections = {};

function Library:SetCursorEnabled(Enabled)
    if Library.Unloaded then
        return;
    end

    Enabled = (not not Enabled) and Library.CursorEnabled and Library.ShowCustomCursor and (not InputService.TouchEnabled);

    if Enabled and Library.Toggled and not Library.UnlockMouseWhileOpen then
        Enabled = false;
    end

    CursorHost.Visible = Enabled;
    if not InputService.TouchEnabled then
        InputService.MouseIconEnabled = not Enabled;
    end

    for _, Connection in next, Library.CursorConnections do
        Connection:Disconnect();
    end
    table.clear(Library.CursorConnections);

    if not Enabled then
        return;
    end

    local function UpdateCursor()
        local MouseLocation = InputService:GetMouseLocation();
        CursorHost.Position = UDim2.fromOffset(MouseLocation.X, MouseLocation.Y);
    end

    UpdateCursor();
    table.insert(Library.CursorConnections, RenderStepped:Connect(UpdateCursor));
    table.insert(Library.CursorConnections, InputService.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateCursor();
        end
    end));
end

local BaseAddons = {};
do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddColorPicker: Missing default value.');

        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);
        local SwatchContainer = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = false;
            Parent = SwatchContainer;
        });
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SwatchContainer;
        });

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });
        local PickerScale = InputService.TouchEnabled and 0.7 or 1;
        local PickerWidth = 230 * PickerScale;
        local PickerHeight = (Info.Transparency and 271 or 253) * PickerScale;
        Library:Create('UIScale', {
            Scale = PickerScale;
            Parent = PickerFrameOuter;
        });
        local function UpdatePickerPosition()
            local Camera = workspace.CurrentCamera;
            local Viewport = (Camera and Camera.ViewportSize) or Vector2.new(1920, 1080);
            local X = math.clamp(DisplayFrame.AbsolutePosition.X, 8, math.max(8, Viewport.X - PickerWidth - 8));
            local Y = DisplayFrame.AbsolutePosition.Y + 18;

            if Y + PickerHeight > Viewport.Y - 8 then
                Y = math.max(8, DisplayFrame.AbsolutePosition.Y - PickerHeight - 4);
            end

            PickerFrameOuter.Position = UDim2.fromOffset(X, Y);
        end
        UpdatePickerPosition();
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdatePickerPosition);

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });
        Library:Create('TextButton', {
            Name = 'Blocker';
            Text = '';
            BackgroundTransparency = 1;
            AutoButtonColor = false;
            Modal = true;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameInner;
        });
        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 25);
            Size = UDim2.new(0, 200, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });
        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });
        local CursorOuter = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5);
            Size = UDim2.new(0, 6, 0, 6);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ImageColor3 = Color3.new(0, 0, 0);
            ZIndex = 19;
            Parent = SatVibMap;
        });
        local CursorInner = Library:Create('ImageLabel', {
            Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2);
            Position = UDim2.new(0, 1, 0, 1);
            BackgroundTransparency = 1;
            Image = 'http://www.roblox.com/asset/?id=9619665977';
            ZIndex = 20;
            Parent = CursorOuter;
        })

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 208, 0, 25);
            Size = UDim2.new(0, 15, 0, 200);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });
        local HueCursor = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            AnchorPoint = Vector2.new(0, 0.5);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, 0, 0, 1);
            ZIndex = 18;
            Parent = HueSelectorInner;
        });

        local HueBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(4, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            ZIndex = 18,
            Parent = PickerFrameInner;
        });
        local HueBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18,
            Parent = HueBoxOuter;
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = HueBoxInner;
        });

        local HueBox = Library:Create('TextBox', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = 'Hex color',
            Text = '#FFFFFF',
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 20,
            Parent = HueBoxInner;
        });

        Library:ApplyTextStroke(HueBox);

        local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
            Position = UDim2.new(0.5, 2, 0, 228),
            Size = UDim2.new(0.5, -6, 0, 20),
            Parent = PickerFrameInner
        });
        local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild('TextBox'), {
            Text = '255, 255, 255',
            PlaceholderText = 'RGB color',
            TextColor3 = Library.FontColor
        });
        local TransparencyBoxOuter, TransparencyBoxInner, TransparencyColor, TransparencyCursor;

        if Info.Transparency then
            TransparencyBoxOuter = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = UDim2.fromOffset(4, 251);
                Size = UDim2.new(1, -8, 0, 15);
                ZIndex = 19;
                Parent = PickerFrameInner;
            });
            TransparencyBoxInner = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BackgroundTransparency = 1;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 19;
                Parent = TransparencyBoxOuter;
            });
            Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = 'OutlineColor' });

            Library:Create('ImageLabel', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Image = 'http://www.roblox.com/asset/?id=12978095818';
                ZIndex = 20;
                Parent = TransparencyBoxInner;
            });
            TransparencyColor = Library:Create('Frame', {
                BackgroundColor3 = ColorPicker.Value;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 21;
                Parent = TransparencyBoxInner;
            });
            Library:Create('UIGradient', {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                });
                Parent = TransparencyColor;
            });
            TransparencyCursor = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(1, 1, 1);
                AnchorPoint = Vector2.new(0.5, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(0, 1, 1, 0);
                ZIndex = 22;
                Parent = TransparencyBoxInner;
            });
        end;

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 14);
            Position = UDim2.fromOffset(5, 5);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = Library.FontSize;
            Text = ColorPicker.Title,
            TextWrapped = false;
            ZIndex = 16;
            Parent = PickerFrameInner;
        });
        local ContextMenu = {}
        do
            ContextMenu.Options = {}
            ContextMenu.Container = Library:Create('Frame', {
                BorderColor3 = Color3.new(),
                ZIndex = 14,
                Visible = false,
                Parent = ScreenGui
            })

            ContextMenu.Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1, 1);
                ZIndex = 15;
                Parent = ContextMenu.Container;
            });
            Library:Create('UIListLayout', {
                Name = 'Layout',
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = ContextMenu.Inner;
            });
            Library:Create('UIPadding', {
                Name = 'Padding',
                PaddingLeft = UDim.new(0, 4),
                Parent = ContextMenu.Inner,
            });
            local function updateMenuPosition()
                ContextMenu.Container.Position = UDim2.fromOffset(
                    (DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
                    DisplayFrame.AbsolutePosition.Y + 1
                )
            end

            local function updateMenuSize()
                local menuWidth = 60
                for i, label in next, ContextMenu.Inner:GetChildren() do
                    if label:IsA('TextLabel') then
                        menuWidth = math.max(menuWidth, label.TextBounds.X)
                    end
                end

                ContextMenu.Container.Size = UDim2.fromOffset(
                    menuWidth + 8,
                    ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4
                )
            end

            DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(updateMenuPosition)
            ContextMenu.Inner.Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateMenuSize)

            task.spawn(updateMenuPosition)
            task.spawn(updateMenuSize)

            Library:AddToRegistry(ContextMenu.Inner, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            function ContextMenu:Show()
                self.Container.Visible = true
            end

            function ContextMenu:Hide()
                self.Container.Visible = false
            end

            function ContextMenu:AddOption(Str, Callback)
                if type(Callback) ~= 'function' then
                    Callback = function() end
                end

                local Button = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, 0, 0, 15);
                    TextSize = Library.FontSize - 1;
                    Text = Str;
                    ZIndex = 16;
                    Parent = self.Inner;
                    TextXAlignment = Enum.TextXAlignment.Left,
                });
                Library:OnHighlight(Button, Button,
                    { TextColor3 = 'AccentColor' },
                    { TextColor3 = 'FontColor' }
                );
                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    Callback()
                end)
            end

            ContextMenu:AddOption('Copy color', function()
                Library.ColorClipboard = ColorPicker.Value
                Library:Notify('Copied color!', 2)
            end)

            ContextMenu:AddOption('Paste color', function()
                if not Library.ColorClipboard then
                    return Library:Notify('You have not copied a color!', 2)
                end
                ColorPicker:SetValueRGB(Library.ColorClipboard)
            end)

            ContextMenu:AddOption('Copy HEX', function()
                pcall(setclipboard, ColorPicker.Value:ToHex())
                Library:Notify('Copied hex code to clipboard!', 2)
            end)

            ContextMenu:AddOption('Copy RGB', function()
                pcall(setclipboard, table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', '))
                Library:Notify('Copied RGB values to clipboard!', 2)
            end)

        end

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(RgbBox, { TextColor3 = 'FontColor', });
        Library:AddToRegistry(HueBox, { TextColor3 = 'FontColor', });

        local SequenceTable = {};
        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        local HueSelectorGradient = Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 90;
            Parent = HueSelectorInner;
        });
        HueBox.FocusLost:Connect(function(enter)
            if enter then
                local success, result = pcall(Color3.fromHex, HueBox.Text)
                if success and typeof(result) == 'Color3' then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
                end
            end

            ColorPicker:Display()
        end)

        RgbBox.FocusLost:Connect(function(enter)
            if enter then
                local r, g, b = RgbBox.Text:match('(%d+),%s*(%d+),%s*(%d+)')
                if r and g and b then
                    ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
                end
            end

            ColorPicker:Display()
        end)

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            DisplayFrame.BackgroundColor3 = ColorPicker.Value;
            DisplayFrame.BackgroundTransparency = ColorPicker.Transparency;
            CheckerFrame.Visible = ColorPicker.Transparency > 0;
            DisplayFrame.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            if TransparencyBoxInner then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value;
                TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0);
            end;

            CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0);
            HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0);

            HueBox.Text = '#' .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({ math.floor(ColorPicker.Value.R * 255), math.floor(ColorPicker.Value.G * 255), math.floor(ColorPicker.Value.B * 255) }, ', ')

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value, ColorPicker.Transparency);
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value, ColorPicker.Transparency);
        end;

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;
        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;
        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Transparency or 0;
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateColor(PosX, PosY)
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(PosX, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                end

                UpdateColor(Input.Position.X, Input.Position.Y)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateColor(Change.Position.X, Change.Position.Y)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end);
        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                local function UpdateHue(PosY)
                    local MinY = HueSelectorInner.AbsolutePosition.Y;
                    local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y;
                    local MouseY = math.clamp(PosY, MinY, MaxY);

                    ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();
                end

                UpdateHue(Input.Position.Y)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateHue(Change.Position.Y)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end
        end);
        DisplayFrame.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide()
                else
                    ContextMenu:Hide()
                    ColorPicker:Show()
                end;
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ContextMenu:Show()
                ColorPicker:Hide()
            end
        end);

        if TransparencyBoxInner then
            TransparencyBoxInner.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local function UpdateAlpha(PosX)
                        local MinX = TransparencyBoxInner.AbsolutePosition.X;
                        local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X;
                        local MouseX = math.clamp(PosX, MinX, MaxX);

                        ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX));
                        ColorPicker:Display();
                    end

                    UpdateAlpha(Input.Position.X)

                    local ChangedConn = InputService.InputChanged:Connect(function(Change)
                        if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                            UpdateAlpha(Change.Position.X)
                        end
                    end)

                    local EndedConn
                    EndedConn = InputService.InputEnded:Connect(function(EndInput)
                        if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                            ChangedConn:Disconnect()
                            EndedConn:Disconnect()
                            Library:AttemptSave()
                        end
                    end)
                end
            end);
        end;

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;
                local DFPos = DisplayFrame.AbsolutePosition;
                local DFSize = DisplayFrame.AbsoluteSize;
                local MousePos = Input.Position;

                if MousePos.X < AbsPos.X or MousePos.X > AbsPos.X + AbsSize.X
                    or MousePos.Y < AbsPos.Y or MousePos.Y > AbsPos.Y + AbsSize.Y then

                    if not (MousePos.X >= DFPos.X and MousePos.X <= DFPos.X + DFSize.X
                        and MousePos.Y >= DFPos.Y and MousePos.Y <= DFPos.Y + DFSize.Y) then
                        ColorPicker:Hide();
                    end
                end;

                if not Library:IsMouseOverFrame(ContextMenu.Container) then
                    ContextMenu:Hide()
                end
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
                if not Library:IsMouseOverFrame(ContextMenu.Container) and not Library:IsMouseOverFrame(DisplayFrame) then
                    ContextMenu:Hide()
                end
            end
        end))

        function ColorPicker:GetTransparency()
            return ColorPicker.Transparency;
        end;

        function ColorPicker:OnTransparencyChanged(Func)
            ColorPicker.TransparencyChanged = Func;
            Func(ColorPicker.Transparency);
        end;

        local _OrigDisplay = ColorPicker.Display;
        ColorPicker.Display = function(self)
            _OrigDisplay(self);
            Library:SafeCallback(ColorPicker.TransparencyChanged, ColorPicker.Transparency);
        end;

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddColorPickerAlpha(Idx, Info)
        Info = Info or {};
        if Info.Transparency == nil then
            Info.Transparency = 0;
        end;
        return Funcs.AddColorPicker(self, Idx, Info);
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        assert(Info.Default, 'AddKeyPicker: Missing default value.');

        local KeyPicker = {
            Value = Info.Default;
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';
            Callback = Info.Callback or function(Value) end;
            ChangedCallback = Info.ChangedCallback or function(New) end;

            SyncToggleState = Info.SyncToggleState or false;
            WaitForCallback = Info.WaitForCallback or false;
            Busy = false;
            Modifiers = nil;
        };
        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });
        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize - 1;
            Text = Info.Default;
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });
        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = ScreenGui;
        });
        ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
        end);
        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });
        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });
        local KeybindEntry = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Visible = false,
            ZIndex = 110,
            Parent = Library.KeybindContainer,
        })

        local ContainerLabel = Library:CreateLabel({
            Position = UDim2.new(0, 2, 0, 0),
            Size = UDim2.new(1, -4, 1, 0),
            TextSize = Library.FontSize - 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 111,
            Parent = KeybindEntry,
        }, true)

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold', 'Press' };
        local ModeButtons = {};

        ModeSelectOuter.Size = UDim2.new(0, 60, 0, (#Modes * 15) + 2);

        for Idx, Mode in next, Modes do
            local ModeButton = {};
            local Label = Library:CreateLabel({
                Active = false;
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = Library.FontSize - 1;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });
            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;
            function ModeButton:Deselect()
                KeyPicker.Mode = nil;
                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);
            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            if ParentObj.Type == 'Toggle' and not Library.ShowToggleFrameInKeybinds then
                KeybindEntry.Visible = false;
                return;
            end

            local State = KeyPicker:GetState();

            local displayKey = (KeyPicker.Value == 'None') and '...' or KeyPicker.Value
            ContainerLabel.Text = string.format('[%s] %s (%s)', displayKey, Info.Text, KeyPicker.Mode);
            local kbMode = Library.KeybindMode or 'All'
            if kbMode == 'Active' then
                KeybindEntry.Visible = State == true
            elseif kbMode == 'Toggled' then
                local parentOn = false
                if ParentObj and ParentObj.Type == 'Toggle' then
                    parentOn = ParentObj.Value == true
                elseif KeyPicker.SyncToggleState and ParentObj then
                    parentOn = ParentObj.Value == true
                else
                    parentOn = true
                end
                KeybindEntry.Visible = parentOn
            else
                KeybindEntry.Visible = true
            end

            ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor;
            Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

            local YSize = 0
            local XSize = 0

            for _, Frame in next, Library.KeybindContainer:GetChildren() do
                if Frame:IsA('Frame') and Frame.Visible then
                    YSize = YSize + 18;
                    local LabelChild = Frame:FindFirstChildOfClass('TextLabel')
                    if LabelChild and (LabelChild.TextBounds.X + 20 > XSize) then
                        XSize = LabelChild.TextBounds.X + 20
                    end
                end;
            end;

            Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10 + 15, 210), 0, YSize + 23)
        end;
        function KeyPicker:GetState()
            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                if KeyPicker.Value == 'None' then
                    return false;
                end

                local Key = KeyPicker.Value;
                if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                        or Key == 'Touch' and true
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            DisplayLabel.Text = Key;
            KeyPicker.Value = Key;
            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select();
            end
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end

        function KeyPicker:OnChanged(Callback)
            KeyPicker.Changed = Callback
            Callback(KeyPicker.Value, KeyPicker.Modifiers)
        end

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
            table.insert(Library.KeyPickerList, KeyPicker)
        end

        function KeyPicker:DoClick()
            if KeyPicker.Busy then
                return;
            end

            KeyPicker.Busy = true;

            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            KeyPicker.Busy = false;
        end

        local Picking = false;
        PickOuter.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    elseif Input.UserInputType == Enum.UserInputType.Touch then
                        Key = 'Touch';
                    end;

                    local Modifiers = {};
                    for _, Modifier in next, { Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.LeftAlt, Enum.KeyCode.RightAlt } do
                        if InputService:IsKeyDown(Modifier) and Modifier ~= Input.KeyCode then
                            table.insert(Modifiers, Modifier);
                        end
                    end

                    Break = true;
                    Picking = false;

                    DisplayLabel.Text = Key;
                    KeyPicker.Value = Key;
                    KeyPicker.Modifiers = (#Modifiers > 0) and Modifiers or nil;
                    Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType, KeyPicker.Modifiers)
                    Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType, KeyPicker.Modifiers)

                    Library:AttemptSave();
                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2
                        or Key == 'Touch' and Input.UserInputType == Enum.UserInputType.Touch then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                if KeyPicker.Mode == 'Press' then
                    local Key = KeyPicker.Value;
                    local Pressed = false;

                    if Key == 'MB1' or Key == 'MB2' or Key == 'Touch' then
                        Pressed = (Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1)
                            or (Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2)
                            or (Key == 'Touch' and Input.UserInputType == Enum.UserInputType.Touch);
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        Pressed = Input.KeyCode.Name == Key;
                    end

                    if Pressed then
                        KeyPicker.Toggled = true;
                        KeyPicker:DoClick();
                        KeyPicker.Toggled = false;
                    end
                end

                KeyPicker:Update();
            end;
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;
                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();
        Options[Idx] = KeyPicker;

        return self;
    end;

    function Funcs:AddMiniWindow(Config)
        local Mini = Library:CreateMiniWindow(Config);

        if self.Type == 'Toggle' then
            table.insert(self.Addons, { Type = 'MiniWindow'; Window = Mini; });
            Mini:SetVisible(self.Value);

            Mini.OnClose = function()
                self:SetValue(false);
            end;
        end

        return Mini;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};
    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddRow(Columns)
        local Groupbox = self
        local Container = Groupbox.Container

        local ColumnsCount = type(Columns) == 'number' and math.max(1, Columns) or 2

        local RowOuter = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 1,
            Parent = Container
        })

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = RowOuter
        })

        local Boxes = {}

        for i = 1, ColumnsCount do
            local Box = { Type = 'Groupbox' }

            local BoxContainer = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Size = UDim2.new(1 / ColumnsCount, -((ColumnsCount - 1) * 8) / ColumnsCount, 1, 0),
                ZIndex = 1,
                Parent = RowOuter
            })

            local BoxLayout = Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = BoxContainer
            })

            Box.Container = BoxContainer
            setmetatable(Box, BaseGroupbox)

            function Box:Resize()
                local maxHeight = 0
                for _, child in next, RowOuter:GetChildren() do
                    if child:IsA('Frame') then
                        local layout = child:FindFirstChildOfClass('UIListLayout')
                        if layout and layout.AbsoluteContentSize.Y > maxHeight then
                            maxHeight = layout.AbsoluteContentSize.Y
                        end
                    end
                end
                RowOuter.Size = UDim2.new(1, 0, 0, maxHeight)
                if Groupbox.Resize then
                    Groupbox:Resize()
                end
            end

            BoxLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Box:Resize()
            end)

            table.insert(Boxes, Box)
        end

        Groupbox:AddBlank(1)
        if Groupbox.Resize then Groupbox:Resize() end

        return unpack(Boxes)
    end;
    function Funcs:AddLabel(Text, DoesWrap, Idx)
        if type(DoesWrap) == 'table' then
            Idx = Text;
            Text = DoesWrap.Text or '';
            DoesWrap = DoesWrap.DoesWrap;
        end

        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = Library.FontSize;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });
        local function UpdateLabelSize()
            if not DoesWrap then
                return;
            end

            local Available = TextLabel.AbsoluteSize.X;
            if Available <= 1 then
                Available = 216;
            end

            local Y = select(2, Library:GetTextBounds(TextLabel.Text, Library.Font, Library.FontSize, Vector2.new(Available, math.huge)));
            if math.abs(TextLabel.Size.Y.Offset - Y) > 1 then
                TextLabel.Size = UDim2.new(1, -4, 0, Y);
                if Groupbox.Resize then
                    Groupbox:Resize();
                end
            end
        end

        if DoesWrap then
            UpdateLabelSize();
            TextLabel:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateLabelSize);
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;
        function Label:SetText(Text)
            TextLabel.Text = Text
            UpdateLabelSize()
            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        if Idx then
            Library.Labels[Idx] = Label;
        end

        return Label;
    end;
    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
                Obj.Disabled = Props.Disabled
                Obj.Visible = Props.Visible
                Obj.DisabledTooltip = Props.DisabledTooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end

            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end

        ProcessButtonParams('Button', Button, ...)

        local Groupbox = self;
        local Container = Groupbox.Container;

        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });
            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = Library.FontSize;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });
            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });
            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            );
            return Outer, Inner, Label
        end

        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)

                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:Disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end

            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end

                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                    return false
                end

                return true
            end

            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end

                if Button.Disabled then return end

                if Button.Locked then return end

                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })

                    Button.Label.TextColor3 = Library.AccentColor
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true

                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)

                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })

                    Button.Label.TextColor3 = Library.FontColor
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)

                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    return
                end

                Library:SafeCallback(Button.Func);
            end)
        end

        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container

        Button.Outer.Visible = Button.Visible ~= false;

        if Button.Disabled then
            Button.Outer.Active = false;
            Button.Inner.BackgroundTransparency = 0.5;
            Button.Label.TextTransparency = 0.5;
        end

        InitEvents(Button)

        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer, self.DisabledTooltip, function()
                    return self.Disabled;
                end)
            end
            return self
        end

        function Button:AddButton(...)
            local SubButton = {}

            ProcessButtonParams('SubButton', SubButton, ...)

            self.Outer.Size = UDim2.new(0.5, -2, 0, 20)

            SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

            SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
            SubButton.Outer.Parent = self.Outer

            SubButton.Outer.Visible = SubButton.Visible ~= false;

            if SubButton.Disabled then
                SubButton.Outer.Active = false;
                SubButton.Inner.BackgroundTransparency = 0.5;
                SubButton.Label.TextTransparency = 0.5;
            end

            local function UpdateSubButton()
                SubButton.Outer.Size = UDim2.fromOffset(
                    math.max(0, self.Outer.AbsoluteSize.X - 2),
                    math.max(0, self.Outer.AbsoluteSize.Y)
                )
            end

            UpdateSubButton()
            self.Outer:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateSubButton)

            function SubButton:AddTooltip(tooltip)
                if type(tooltip) == 'string' then
                    Library:AddToolTip(tooltip, self.Outer, self.DisabledTooltip, function()
                        return self.Disabled;
                    end)
                 end
                return SubButton
            end

            if type(SubButton.Tooltip) == 'string' then
                SubButton:AddTooltip(SubButton.Tooltip)
            end

            InitEvents(SubButton)
            return SubButton
        end

        function Button:AddMiniWindow(Config)
            local Mini = Library:CreateMiniWindow(Config);
            local BaseFunc = Button.Func;

            Button.Func = function(...)
                Mini:Toggle();

                if type(BaseFunc) == 'function' then
                    return BaseFunc(...);
                end
            end;

            return Mini;
        end

        if type(Button.Tooltip) == 'string' then
            Button:AddTooltip(Button.Tooltip)
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });
        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });
        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });
        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
            Disabled = Info.Disabled or false;
            Visible = Info.Visible ~= false;
            Callback = Info.Callback or function(Value) end;
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });
        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, TextBoxOuter, Info.DisabledTooltip, function()
                return Textbox.Disabled;
            end)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });
        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),

            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });

        Library:ApplyTextStroke(Box);
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;

            Library:SafeCallback(Textbox.Callback, Textbox.Value);
            Library:SafeCallback(Textbox.Changed, Textbox.Value);
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end

                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        local function Update()
            local PADDING = 2
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

                    local currentCursorPos = Box.Position.X.Offset + width

                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)
        Container:GetPropertyChangedSignal('AbsoluteSize'):Connect(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        TextBoxOuter.Visible = Textbox.Visible;
        InputLabel.Visible = Textbox.Visible;

        if Textbox.Disabled then
            TextBoxOuter.Active = false;
            TextBoxInner.BackgroundTransparency = 0.5;
            InputLabel.TextTransparency = 0.5;
            Box.TextEditable = false;
            Box.TextTransparency = 0.5;
        end

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')

        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Callback = Info.Callback or function(Value) end;
            Addons = {},
            Risky = Info.Risky,
            Disabled = Info.Disabled or false;
            Visible = Info.Visible ~= false;
        };
        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });
        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });
        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = Library.FontSize;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });

        local function UpdateToggleWidth()
            local Available = Container.AbsoluteSize.X;
            if Available <= 1 then
                Available = 239;
            end

            local LeftInset = math.max(0, ToggleOuter.AbsolutePosition.X - Container.AbsolutePosition.X);
            ToggleLabel.Size = UDim2.fromOffset(math.max(28, Available - LeftInset - 23), 13);
        end

        UpdateToggleWidth();
        Container:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateToggleWidth);

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });
        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        function Toggle:UpdateColors()
            Toggle:Display();
        end;
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion, Info.DisabledTooltip, function()
                return Toggle.Disabled;
            end)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetText(Text)
            Toggle.TextLabel.Text = Text;
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                elseif Addon.Type == 'MiniWindow' then
                    Addon.Window:SetVisible(Bool);
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;
        ToggleRegion.InputBegan:Connect(function(Input)
            if Toggle.Disabled then
                return;
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);
        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        ToggleOuter.Visible = Toggle.Visible;

        if Toggle.Disabled then
            ToggleRegion.Active = false;
            ToggleInner.BackgroundTransparency = 0.5;
            ToggleLabel.TextTransparency = 0.5;
        end

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        Library:UpdateDependencyBoxes();

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        assert(Info.Default, 'AddSlider: Missing default value.');
        assert(Info.Text, 'AddSlider: Missing slider text.');
        assert(Info.Min, 'AddSlider: Missing minimum value.');
        assert(Info.Max, 'AddSlider: Missing maximum value.');
        assert(Info.Rounding, 'AddSlider: Missing rounding value.');
        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            MaxSize = 232;
            Type = 'Slider';
            Disabled = Info.Disabled or false;
            Visible = Info.Visible ~= false;
            Editing = false;
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;
        local SliderLabel;
        if not Info.Compact then
            SliderLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(SliderOuter, {
            BorderColor3 = 'Black';
        });
        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });
        Library:AddToRegistry(SliderInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderColor3 = Library.AccentColorDark;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderInner;
        });
        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
            BorderColor3 = 'AccentColorDark';
        });
        local HideBorderRight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(1, 0, 0, 0);
            Size = UDim2.new(0, 1, 1, 0);
            ZIndex = 8;
            Parent = Fill;
        });

        Library:AddToRegistry(HideBorderRight, {
            BackgroundColor3 = 'AccentColor';
        });
        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = Library.FontSize;
            Text = 'Infinite';
            ZIndex = 9;
            Parent = SliderInner;
        });
        local EditBox = Library:Create('TextBox', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(130, 130, 130);
            Text = '';
            TextColor3 = Library.FontColor;
            TextSize = Library.FontSize;
            TextXAlignment = Enum.TextXAlignment.Center;
            ClearTextOnFocus = false;
            Visible = false;
            ZIndex = 12;
            Parent = SliderInner;
        });
        Library:AddToRegistry(EditBox, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
            TextColor3 = 'FontColor';
        });
        Library:OnHighlight(SliderOuter, SliderOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter, Info.DisabledTooltip, function()
                return Slider.Disabled;
            end)
        end

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
            Fill.BorderColor3 = Library.AccentColorDark;
        end;

        function Slider:GetWidth()
            local Width = SliderInner.AbsoluteSize.X;
            if Width <= 1 then
                Width = Slider.MaxSize;
            end
            return math.max(1, Width);
        end;

        function Slider:Display()
            local Suffix = Info.Suffix or '';
            local Custom;

            if Info.FormatDisplayValue then
                local Success, Result = pcall(Info.FormatDisplayValue, Slider, Slider.Value);
                if Success then
                    Custom = Result;
                end
            end

            if Custom ~= nil then
                DisplayLabel.Text = Custom;
            elseif Info.Compact then
                DisplayLabel.Text = Info.Text .. ': ' .. Slider.Value .. Suffix
            elseif Info.HideMax then
                DisplayLabel.Text = string.format('%s', Slider.Value .. Suffix)
            else
                DisplayLabel.Text = string.format('%s/%s', Slider.Value .. Suffix, Slider.Max .. Suffix);
            end

            local Width = Slider:GetWidth();
            local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Width));
            Fill.Size = UDim2.new(0, X, 1, 0);

            HideBorderRight.Visible = not (X == Width or X == 0);
        end;
        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;
        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;

            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:BeginEdit()
            if Slider.Disabled then
                return;
            end

            Slider.Editing = true;
            EditBox.Text = '';
            EditBox.PlaceholderText = tostring(Slider.Value);
            EditBox.Visible = true;
            DisplayLabel.Visible = false;
            EditBox:CaptureFocus();
        end;

        EditBox.FocusLost:Connect(function()
            if not Slider.Editing then
                return;
            end

            local Num = tonumber(EditBox.Text);
            if Num then
                Slider:SetValue(Round(Num));
            else
                Slider:SetValue(Slider.Value);
            end

            Slider.Editing = false;
            EditBox.Visible = false;
            DisplayLabel.Visible = true;
            Library:AttemptSave();
        end);
        function Slider:GetValueFromXOffset(X)
            return Round(Library:MapValue(X, 0, Slider:GetWidth(), Slider.Min, Slider.Max));
        end;
        function Slider:SetValue(Str)
            local Num = tonumber(Str);
            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display();

            Library:SafeCallback(Slider.Callback, Slider.Value);
            Library:SafeCallback(Slider.Changed, Slider.Value);
        end;
        SliderInner.InputBegan:Connect(function(Input)
            if Slider.Disabled or Slider.Editing then
                return;
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                local Now = os.clock();

                if Slider.LastClick and (Now - Slider.LastClick) <= 0.35 then
                    Slider.LastClick = nil;

                    if Slider.PreClickValue ~= nil then
                        Slider.Value = Slider.PreClickValue;
                        Slider:Display();
                    end

                    Slider:BeginEdit();
                    return;
                end

                Slider.LastClick = Now;

                local function UpdateSlider(PosX)
                    local gPos = Fill.AbsolutePosition.X

                    local Diff = PosX - gPos
                    local nX = math.clamp(Diff, 0, Slider:GetWidth())

                    local nValue = Slider:GetValueFromXOffset(nX);
                    local OldValue = Slider.Value;

                    Slider.Value = nValue;

                    Slider:Display();

                    if nValue ~= OldValue then
                        Library:SafeCallback(Slider.Callback, Slider.Value);
                        Library:SafeCallback(Slider.Changed, Slider.Value);
                    end;
                end

                Slider.PreClickValue = Slider.Value;

                UpdateSlider(Input.Position.X)

                local ChangedConn = InputService.InputChanged:Connect(function(Change)
                    if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                        UpdateSlider(Change.Position.X)
                    end
                end)

                local EndedConn
                EndedConn = InputService.InputEnded:Connect(function(EndInput)
                    if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                        ChangedConn:Disconnect()
                        EndedConn:Disconnect()
                        Library:AttemptSave()
                    end
                end)
            end;
        end);

        SliderInner:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            Slider:Display();
        end);

        Slider:Display();
        Groupbox:AddBlank(Info.BlankSize or 6);
        Groupbox:Resize();

        SliderOuter.Visible = Slider.Visible;

        if SliderLabel then
            SliderLabel.Visible = Slider.Visible;
        end

        if Slider.Disabled then
            SliderOuter.Active = false;
            SliderInner.BackgroundTransparency = 0.5;
            DisplayLabel.TextTransparency = 0.5;
            Fill.BackgroundTransparency = 0.5;
        end

        Options[Idx] = Slider;

        return Slider;
    end;
    function Funcs:AddDropdown(Idx, Info)
        if Info.SpecialType == 'Player' then
            Info.Values = GetPlayersString();

            if Info.ExcludeLocalPlayer then
                local Filtered = {};
                for _, Name in next, Info.Values do
                    if Name ~= LocalPlayer.Name then
                        table.insert(Filtered, Name);
                    end
                end
                Info.Values = Filtered;
            end

            Info.AllowNull = true;
        elseif Info.SpecialType == 'Team' then
            Info.Values = GetTeamsString();
            Info.AllowNull = true;
        end;

        assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
        assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

        if (not Info.Text) then
            Info.Compact = true;
        end;

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
            SpecialType = Info.SpecialType;
            Disabled = Info.Disabled or false;
            Visible = Info.Visible ~= false;
            Searchable = Info.Searchable or false;
            DisabledValues = Info.DisabledValues;
            MaxVisible = Info.MaxVisibleDropdownItems or 8;
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer;
            Callback = Info.Callback or function(Value) end;
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;
        local DropdownLabel;
        if not Info.Compact then
            DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = Library.FontSize;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });
            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });
        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });
        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });
        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 8;
            Parent = DropdownInner;
        });
        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = Library.FontSize;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });
        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter, Info.DisabledTooltip, function()
                return Dropdown.Disabled;
            end)
        end

        local SearchBox;
        local ListOffset = 0;

        local MAX_DROPDOWN_ITEMS = 8;
        local function GetMaxVisible()
            return Dropdown.MaxVisible or MAX_DROPDOWN_ITEMS;
        end
        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            ZIndex = 20;
            Visible = false;
            Parent = ScreenGui;
        });
        local function RecalculateListPosition()
            ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
        end;

        local function RecalculateListSize(YSize)
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, (YSize or (GetMaxVisible() * 20 + 2)) + ListOffset)
        end;
        RecalculateListPosition();
        RecalculateListSize();

        DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);
        DropdownOuter:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, ListOuter.Size.Y.Offset);
        end);

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });
        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        if Info.Searchable then
            ListOffset = 22;

            local SearchOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 22);
                ZIndex = 23;
                Parent = ListInner;
            });
            Library:AddToRegistry(SearchOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            SearchBox = Library:Create('TextBox', {
                BackgroundTransparency = 1;
                Position = UDim2.fromOffset(5, 0);
                Size = UDim2.new(1, -10, 1, 0);
                Font = Library.Font;
                PlaceholderText = 'Search...';
                PlaceholderColor3 = Color3.fromRGB(120, 120, 120);
                Text = '';
                TextColor3 = Library.FontColor;
                TextSize = Library.FontSize;
                TextXAlignment = Enum.TextXAlignment.Left;
                ClearTextOnFocus = false;
                ZIndex = 24;
                Parent = SearchOuter;
            });
            Library:AddToRegistry(SearchBox, { TextColor3 = 'FontColor' });
        end

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Position = UDim2.fromOffset(0, ListOffset);
            Size = UDim2.new(1, 0, 1, -ListOffset);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
        });
        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });
        local function FormatValue(Value)
            if Info.FormatDisplayValue then
                local Success, Result = pcall(Info.FormatDisplayValue, Value);
                if Success and Result ~= nil then
                    return Result;
                end
            end

            return Value;
        end

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. FormatValue(Value) .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value and FormatValue(Dropdown.Value) or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;
        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};
                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:BuildDropdownList(Filter)
            local Values = Dropdown.Values;
            local Buttons = {};

            Filter = (Filter or ''):lower();
            if Filter ~= '' then
                local Filtered = {};
                for _, Value in next, Values do
                    if string.find(string.lower(tostring(Value)), Filter, 1, true) then
                        table.insert(Filtered, Value);
                    end
                end
                Values = Filtered;
            end

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};
                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Active = false;
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = Library.FontSize;
                    Text = FormatValue(Value);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                local IsDisabled = false;
                if Info.DisabledValues then
                    for _, DisabledValue in next, Info.DisabledValues do
                        if DisabledValue == Value then
                            IsDisabled = true;
                            break;
                        end
                    end
                end

                if IsDisabled then
                    ButtonLabel.TextTransparency = 0.5;
                    Button.BackgroundTransparency = 0.5;
                end

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );
                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;
                ButtonLabel.InputBegan:Connect(function(Input)
                    if IsDisabled then
                        return;
                    end

                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();
                            Library:UpdateDependencyBoxes();

                            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
                            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;
            Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

            local Y = math.clamp(Count * 20, 0, GetMaxVisible() * 20) + 1;
            RecalculateListSize(Y);
        end;

        if SearchBox then
            SearchBox:GetPropertyChangedSignal('Text'):Connect(function()
                Dropdown:BuildDropdownList(SearchBox.Text);
            end);
        end

        function Dropdown:SetValues(NewValues)
            if NewValues then
                if Dropdown.ExcludeLocalPlayer then
                    local Filtered = {};
                    for _, Name in next, NewValues do
                        if Name ~= LocalPlayer.Name then
                            table.insert(Filtered, Name);
                        end
                    end
                    NewValues = Filtered;
                end

                Dropdown.Values = NewValues;
            end;

            Dropdown:BuildDropdownList();
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;

            if SearchBox then
                SearchBox.Text = '';
                SearchBox:CaptureFocus();
            end
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;

            if SearchBox then
                SearchBox:ReleaseFocus();
            end
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};
                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:BuildDropdownList();

            Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

            Library:UpdateDependencyBoxes();
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Dropdown.Disabled then
                return;
            end

            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);
        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end));
        Dropdown:BuildDropdownList();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:BuildDropdownList();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        DropdownOuter.Visible = Dropdown.Visible;

        if DropdownLabel then
            DropdownLabel.Visible = Dropdown.Visible;
        end

        if Dropdown.Disabled then
            DropdownOuter.Active = false;
            DropdownInner.BackgroundTransparency = 0.5;
            ItemList.TextTransparency = 0.5;
            DropdownArrow.ImageTransparency = 0.5;
        end

        Options[Idx] = Dropdown;

        return Dropdown;
    end;
    function Funcs:AddMiniWindow(Config)
        local Mini = Library:CreateMiniWindow(Config);

        if self.Type == 'Toggle' then
            table.insert(self.Addons, { Type = 'MiniWindow'; Window = Mini; });
            Mini:SetVisible(self.Value);

            Mini.OnClose = function()
                self:SetValue(false);
            end;
        end

        return Mini;
    end

    function Funcs:AddDependencyBox()
        local Depbox = {
            Dependencies = {};
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local Holder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 0);
            Visible = false;
            Parent = Container;
        });
        local Frame = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = true;
            Parent = Holder;
        });
        local Layout = Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Frame;
        });
        function Depbox:Resize()
            Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
            Groupbox:Resize();
        end;

        Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            Depbox:Resize();
        end);
        Holder:GetPropertyChangedSignal('Visible'):Connect(function()
            Depbox:Resize();
        end);
        function Depbox:Update()
            for _, Dependency in next, Depbox.Dependencies do
                local Elem = Dependency[1];
                local Value = Dependency[2];

                local Matches = true;

                if Elem.Type == 'Toggle' then
                    Matches = Elem.Value == Value;
                elseif Elem.Type == 'Dropdown' then
                    if type(Elem.Value) == 'table' then
                        Matches = Elem.Value[Value] == true;
                    else
                        Matches = Elem.Value == Value;
                    end
                end

                if not Matches then
                    Holder.Visible = false;
                    Depbox:Resize();
                    return;
                end;
            end;

            Holder.Visible = true;
            Depbox:Resize();
        end;

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in next, Dependencies do
                assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
                assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
                assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
            end;

            Depbox.Dependencies = Dependencies;
            Depbox:Update();
        end;

        function Depbox:AddMiniWindow(Config)
            local Mini = Library:CreateMiniWindow(Config);
            Mini:SetVisible(Holder.Visible);

            Holder:GetPropertyChangedSignal('Visible'):Connect(function()
                Mini:SetVisible(Holder.Visible);
            end);

            return Mini;
        end;

        Depbox.Container = Frame;

        setmetatable(Depbox, BaseGroupbox);

        table.insert(Library.DependencyBoxes, Depbox);

        return Depbox;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, Library.NotifyConfig.PositionX, 0, Library.NotifyConfig.PositionY);
        Size = UDim2.new(0, 300, 1, -Library.NotifyConfig.PositionY);
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library.NotifLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });
    local function Library_UpdateNotifAlignment()
        local cfg = Library.NotifyConfig
        local area = Library.NotificationArea
        local layout = Library.NotifLayout

        area.Position = UDim2.new(0, cfg.PositionX, 0, cfg.PositionY)
        area.Size     = UDim2.new(0, 300, 1, -cfg.PositionY)

        local align = cfg.Alignment or 'Left'
        if align == 'Left' then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
            area.AnchorPoint = Vector2.new(0, 0)
        elseif align == 'Right' then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            area.AnchorPoint = Vector2.new(0, 0)
        elseif align == 'Center' then
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            area.AnchorPoint = Vector2.new(0, 0)
        end
    end
    Library.UpdateNotifAlignment = Library_UpdateNotifAlignment
    Library_UpdateNotifAlignment()

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.fromOffset(10, 10);
        Size = UDim2.new(0, 213, 0, 20);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });
    Library:AddToRegistry(WatermarkInner, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.BackgroundColor)),
            ColorSequenceKeypoint.new(1, Library.BackgroundColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.BackgroundColor)),
                ColorSequenceKeypoint.new(1, Library.BackgroundColor),
            });
        end
    });
    local WatermarkLabel = Library:CreateLabel({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = Library.FontSize;
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });
    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);

    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 210, 0, 20);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });
    Library:ApplyGlow(KeybindOuter);

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });
    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    local ColorFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 2);
        ZIndex = 102;
        Parent = KeybindInner;
    });
    Library:AddToRegistry(ColorFrame, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    local KeybindLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,

        Text = 'Keybinds';
        ZIndex = 104;
        Parent = KeybindInner;
    });
    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -20);
        Position = UDim2.new(0, 0, 0, 20);
        ZIndex = 1;
        Parent = KeybindInner;
    });
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });
    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetKeybindMode(Mode)
    assert(Mode == 'All' or Mode == 'Active' or Mode == 'Toggled',
        "SetKeybindMode: Mode must be 'All', 'Active', or 'Toggled'")
    Library.KeybindMode = Mode
    Library:RefreshKeybinds()
end

function Library:RefreshKeybinds()
    for _, kp in ipairs(Library.KeyPickerList) do
        if not kp.NoUI then
            pcall(function() kp:Update() end)
        end
    end
end

function Library:SetWatermarkVisibility(Bool)
    if Library.Unloaded or not Library.Watermark then
        return;
    end

    Library.Watermark.Visible = Bool;
end;

function Library:SetWatermarkText(Text)
    if Library.Unloaded or not Library.Watermark then
        return;
    end

    Text = Text or Library.DefaultWatermark or 'silly.lua';

    local Plain = Text:gsub('<[^>]*>', '');
    local X, Y = Library:GetTextBounds(Plain, Library.Font, Library.FontSize);
    Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);

    Library.WatermarkText.Text = Text;
end;

function Library:SetWatermark(Text)
    if Library.Unloaded then
        return;
    end

    Library.WatermarkCustom = true;
    Library:SetWatermarkText(Text);
end;

function Library:SetWatermarkStats(Enabled)
    if Library.Unloaded then
        return;
    end

    Library.WatermarkStats = Enabled;
    Library.WatermarkCustom = not Enabled;
end;

Library.DefaultWatermark = string.format('%s | v%s', Library:FormatTitle('silly'), Library.BuildVersion);
Library.Watermark.Position = UDim2.fromOffset(10, 10);
Library:SetWatermarkText(Library.DefaultWatermark);
Library:SetWatermarkVisibility(true);

function Library:RefreshSuffixes()
    if Library.Unloaded then
        return;
    end

    Library.DefaultWatermark = string.format('%s | v%s', Library:FormatTitle('silly'), Library.BuildVersion);

    for _, Window in next, Library.Windows do
        if Window.RefreshTitle then
            Window:RefreshTitle();
        end
    end

    if Library.Watermark and not Library.WatermarkCustom then
        Library:SetWatermarkText(Library.DefaultWatermark);
    end
end;

function Library:SetSuffix(Suffix)
    if Library.Unloaded then
        return;
    end

    Suffix = Suffix == nil and '.lua' or Suffix;
    Library.Suffix = type(Suffix) == 'string' and Suffix or '';
    Library:RefreshSuffixes();
end;

function Library:SetSilentLoad(Enabled)
    Library.SilentLoad = not not Enabled;
end;

function Library:SetMenuVisible(Visible)
    if Library.Unloaded then
        return;
    end

    for _, Window in next, Library.Windows do
        if not Window.Mini or not Visible then
            Window:SetVisible(Visible);
        end
    end
end;

do
    local Frames, FPS, Last = 0, 0, os.clock();
    local Ping = 0;

    Library:GiveSignal(RenderStepped:Connect(function()
        Frames += 1;
        local Now = os.clock();
        if Now - Last >= 1 then
            FPS = Frames;
            Frames = 0;
            Last = Now;
        end
    end));

    task.spawn(function()
        while not Library.Unloaded do
            task.wait(1);

            if Library.Unloaded then
                break;
            end

            if Library.WatermarkStats and not Library.WatermarkCustom then
                local Success, Value = pcall(function()
                    return game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue();
                end);
                if Success then
                    Ping = math.floor(Value);
                end

                Library:SetWatermarkText(('%s | %d fps • %d ms • %d players • v%s'):format(
                    Library:FormatTitle('silly'),
                    FPS,
                    Ping,
                    #game:GetService('Players'):GetPlayers(),
                    Library.BuildVersion
                ));
            end
        end
    end);
end;
function Library:Notify(Text, Time, SoundId)
    if Library.Unloaded or Library.SilentLoad or not Library.NotificationArea then
        return;
    end

    local cfg     = Library.NotifyConfig

    if Library.NotifySide and (cfg.Alignment ~= Library.NotifySide or cfg.BarSide ~= Library.NotifySide) then
        cfg.Alignment = Library.NotifySide;
        cfg.BarSide = Library.NotifySide;

        if Library.UpdateNotifAlignment then
            Library.UpdateNotifAlignment();
        end
    end

    local barSide = cfg.BarSide   or 'Left'
    local align   = cfg.Alignment or 'Left'

    if SoundId then
        local Sound = Instance.new('Sound');
        Sound.SoundId = 'rbxassetid://' .. tostring(SoundId);
        Sound.Parent = game:GetService('SoundService');
        pcall(function()
            game:GetService('SoundService'):PlayLocalSound(Sound);
        end);

        task.delay(3, function()
            Sound:Destroy();
        end);
    end

    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, Library.FontSize)
    YSize = YSize + 7

    local BAR_THIN  = 3
    local BAR_THICK = 3

    local innerPosX  = (barSide == 'Left')   and 1 or 1
    local innerPosY  = (barSide == 'Top')    and BAR_THICK or 1
    local innerSizeW = (barSide == 'Left' or barSide == 'Right') and -2 or -2
    local innerSizeH = (barSide == 'Top' or barSide == 'Bottom') and -(BAR_THICK + 1) or -2

    local labelPosX  = (barSide == 'Left')  and BAR_THIN + 2 or 4
    local labelSizeW = (barSide == 'Left' or barSide == 'Right') and -(BAR_THIN + 4) or -4

    local outerAnchor = Vector2.new(0, 0)
    local outerPosX   = 0
    if align == 'Center' then
        outerAnchor = Vector2.new(0.5, 0)
        outerPosX   = 0
    elseif align == 'Right' then
        outerAnchor = Vector2.new(1, 0)
        outerPosX   = 0
    end

    local NotifyOuter = Library:Create('Frame', {
        BackgroundTransparency = 1;
        AnchorPoint = outerAnchor;
        BorderColor3 = Color3.new(0, 0, 0);
        Position     = (align == 'Center')
            and UDim2.new(0.5, 0, 0, 0)
            or  (align == 'Right' and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0));
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });
    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });
    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, innerPosX, 0, innerPosY);
        Size     = UDim2.new(1, innerSizeW, 1, innerSizeH);
        ZIndex = 102;
        Parent = NotifyInner;
    });
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });
    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, labelPosX, 0, 0);
        Size     = UDim2.new(1, labelSizeW, 1, 0);
        Text     = Text;
        TextXAlignment = (align == 'Center')
            and Enum.TextXAlignment.Center
            or  Enum.TextXAlignment.Left;
        TextSize = Library.FontSize;
        ZIndex   = 103;
        Parent   = InnerFrame;
    });
    local AccentBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel  = 0;
        ZIndex           = 104;
        Parent           = NotifyOuter;
    });
    if barSide == 'Left' then
        AccentBar.Position = UDim2.new(0, -1, 0, -1)
        AccentBar.Size     = UDim2.new(0, BAR_THIN, 1, 2)
    elseif barSide == 'Right' then
        AccentBar.Position = UDim2.new(1, -BAR_THIN + 1, 0, -1)
        AccentBar.Size     = UDim2.new(0, BAR_THIN, 1, 2)
    elseif barSide == 'Top' then
        AccentBar.Position = UDim2.new(0, -1, 0, -1)
        AccentBar.Size     = UDim2.new(1, 2, 0, BAR_THICK)
    elseif barSide == 'Bottom' then
        AccentBar.Position = UDim2.new(0, -1, 1, -BAR_THICK + 1)
        AccentBar.Size     = UDim2.new(1, 2, 0, BAR_THICK)
    end

    Library:AddToRegistry(AccentBar, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    local finalWidth = XSize + 8 + 4
    if barSide == 'Left' or barSide == 'Right' then
        finalWidth = finalWidth + BAR_THIN
    end
    pcall(NotifyOuter.TweenSize, NotifyOuter,
        UDim2.new(0, finalWidth, 0, YSize), 'Out', 'Quad', 0.4, true);
    task.spawn(function()
        wait(Time or 5);
        pcall(NotifyOuter.TweenSize, NotifyOuter,
            UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);
        wait(0.4);
        NotifyOuter:Destroy();
    end);
end;

function Library:CreateWindow(...)
    if Library.Unloaded then
        return;
    end

    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end

    local Mini = Config.Mini == true;

    if type(Config.Title) ~= 'string' then
        Config.Title = 'silly'
    end
    if not Mini and (type(Config.Suffix) == 'string' or Config.Suffix == false) then
        Library:SetSuffix(Config.Suffix);
    end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end
    Library.MenuFadeTime = Config.MenuFadeTime;

    if Config.ShowCustomCursor ~= nil then Library.ShowCustomCursor = Config.ShowCustomCursor end
    if Config.UnlockMouseWhileOpen ~= nil then Library.UnlockMouseWhileOpen = Config.UnlockMouseWhileOpen end

    if type(Config.NotifySide) == 'string' then
        Library.NotifySide = Config.NotifySide;
        Library.NotifyConfig.Alignment = Config.NotifySide;
        Library.NotifyConfig.BarSide = Config.NotifySide;

        if Library.UpdateNotifAlignment then
            Library.UpdateNotifAlignment();
        end
    end

    if typeof(Config.Size) ~= 'UDim2' then
        Config.Size = Mini and UDim2.fromOffset(360, 420) or UDim2.fromOffset(530, 640);
    end
    if typeof(Config.Position) ~= 'UDim2' then
        Config.Position = Mini and UDim2.fromOffset(60, 90) or UDim2.fromOffset(175, 50);
    end

    if InputService.TouchEnabled then
        local Camera = workspace.CurrentCamera
        local Viewport = (Camera and Camera.ViewportSize) or Vector2.new(800, 450)

        local MaxWidth = math.max(260, math.min(Config.Size.X.Offset, Viewport.X - 20))
        local MaxHeight = math.max(260, math.min(Config.Size.Y.Offset, Viewport.Y - 70))

        Config.Size = UDim2.fromOffset(MaxWidth, MaxHeight)
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
        Title = Config.Title;
        Suffix = Config.Suffix;
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = Mini and 2 or 1;
        Parent = ScreenGui;
    });
    local WindowScale = tonumber(Config.Scale) or Library.Scale or 1;
    local WindowScaleObject = Library:Create('UIScale', {
        Scale = WindowScale;
        Parent = Outer;
    });
    Window.UIScale = WindowScaleObject;
    Window.Scale = WindowScale;
    Window.Mini = Mini;
    local TitleDrag = Library:Create('TextButton', {
        Name = 'TitleDrag';
        Text = '';
        BackgroundTransparency = 1;
        AutoButtonColor = false;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, (Mini and -30 or 0), 0, 25);
        ZIndex = 105;
        Parent = Outer;
    });
    Library:MakeDraggable(TitleDrag, 25, true, Outer);
    if Config.Resizable ~= false and Library.ResizeHandles then
        Library:AddResizeHandles(Outer);
    end

    local Inner = Library:Create('Frame', {
        Name = "Inner",
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 25);
        Text = Library:FormatTitle(Config.Title, Config.Suffix);
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 1;
        Parent = Inner;
    });
    if Mini then
        local CloseButton = Library:Create('TextButton', {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -6, 0, 2),
            Size = UDim2.fromOffset(22, 21),
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Font = Library.Font,
            Text = '×',
            TextColor3 = Library.FontColor,
            TextSize = Library.FontSize + 3,
            ZIndex = 110,
            Parent = Outer;
        });
        Library:AddToRegistry(CloseButton, { TextColor3 = 'FontColor' });
        CloseButton.MouseButton1Click:Connect(function()
            if Window.OnClose then
                Window.OnClose();
            else
                Window:SetVisible(false);
            end
        end);
    else
        local MapNameLabel = Library:CreateLabel({
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -7, 0, 0),
            Size = UDim2.new(0, 0, 0, 25),
            Text = 'Loading...',
            TextColor3 = Library.AccentColor,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 1,
            Parent = Inner;
        });
        Library:AddToRegistry(MapNameLabel, {
            TextColor3 = 'AccentColor';
        });
        task.spawn(function()
            local success, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            end)
            if success and info and info.Name then
                MapNameLabel.Text = info.Name
            else
                MapNameLabel.Text = game.Name or "Unknown Map"
            end
        end)
    end

    local TabBarOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 0, 29);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:AddToRegistry(TabBarOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local TabBarInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = TabBarOuter;
    });
    Library:AddToRegistry(TabBarInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabArea = Library:Create('ScrollingFrame', {
        BackgroundTransparency = 1;
        BorderSizePixel = 0;
        Position = UDim2.new(0, 4, 0, 4);
        Size = UDim2.new(1, -8, 1, -8);
        CanvasSize = UDim2.new(0, 0, 0, 0);
        AutomaticCanvasSize = Enum.AutomaticSize.X;
        ScrollingDirection = Enum.ScrollingDirection.X;
        ScrollBarThickness = 0;
        ZIndex = 1;
        Parent = TabBarInner;
    });
    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    local TabDragActive, TabDragStart, TabDragOrigin = false, 0, 0;

    TabArea.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return;
        end

        TabDragActive = true;
        TabDragStart = Input.Position.X;
        TabDragOrigin = TabArea.CanvasPosition.X;
    end);

    Library:GiveSignal(InputService.InputChanged:Connect(function(Input)
        if not TabDragActive or Input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return;
        end

        local Delta = Input.Position.X - TabDragStart;
        local MaxScroll = math.max(0, TabListLayout.AbsoluteContentSize.X - TabArea.AbsoluteSize.X);

        TabArea.CanvasPosition = Vector2.new(math.clamp(TabDragOrigin - Delta, 0, MaxScroll), 0);
    end));

    Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            TabDragActive = false;
        end
    end));
    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 58);
        Size = UDim2.new(1, -16, 1, -66);
        ZIndex = 1;
        Parent = Inner;
    });
    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });
    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });
    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });
    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 1, -16);
        ZIndex = 2;
        Parent = MainSectionInner;
    });
    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Outer.ClipsDescendants = true;
    local CornerCircle = Library:Create('Frame', {
        AnchorPoint      = Vector2.new(0.5, 0.5);
        BackgroundColor3 = Library.AccentColor;
        BackgroundTransparency = 0.5;
        BorderSizePixel  = 0;
        Position         = UDim2.new(1, 0, 1, 0);
        Size             = UDim2.fromOffset(46, 46);
        ZIndex           = 10;
        Parent           = Inner;
    });
    Library:Create('UICorner', {
        CornerRadius = UDim.new(1, 0);
        Parent       = CornerCircle;
    });
    Library:AddToRegistry(CornerCircle, {
        BackgroundColor3 = 'AccentColor';
    });
    function Window:GetSuffix()
        return Window.Suffix == nil and Library.Suffix or Window.Suffix;
    end;
    function Window:RefreshTitle()
        WindowLabel.Text = Library:FormatTitle(Window.Title, Window:GetSuffix());
    end;
    function Window:SetWindowTitle(Title)
        Window.Title = Title;
        Window:RefreshTitle();
    end;
    function Window:SetSuffix(Suffix)
        Window.Suffix = Suffix;
        Window:RefreshTitle();
    end;
    function Window:SetScale(Scale)
        Scale = tonumber(Scale) or 1;
        Window.Scale = Scale;
        WindowScaleObject.Scale = Scale;
    end;
    function Window:SetVisible(Visible)
        Visible = not not Visible;

        if Window.Mini then
            Outer.Visible = Visible;
            Window.Visible = Visible;

            if not Visible then
                for Frame in next, Library.OpenedFrames do
                    Frame.Visible = false;
                end
                table.clear(Library.OpenedFrames);
            end
        elseif Library.Toggle and Library.Toggled ~= Visible then
            task.spawn(Library.Toggle);
        end
    end;
    function Window:Open()
        Window:SetVisible(true);
    end;
    function Window:Close()
        Window:SetVisible(false);
    end;
    function Window:Toggle()
        Window:SetVisible(not Outer.Visible);
    end;
    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, Library.FontSize + 2);
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });
        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });
        local TabIndicator = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 0, 2);
            Visible = false;
            ZIndex = 4;
            Parent = TabButton;
        });
        Library:AddToRegistry(TabIndicator, { BackgroundColor3 = 'AccentColor' });

        local Blocker = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 0, 0, 0);
            Visible = false;
            Parent = TabButton;
        });
        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });
        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
            Size = UDim2.new(0.5, -12 + 2, 1, -16);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            BottomImage = '';
            TopImage = '';
            ScrollBarThickness = 0;
            ZIndex = 2;
            Parent = TabFrame;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = LeftSide;
        });
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            Parent = RightSide;
        });
        for _, Side in next, { LeftSide, RightSide } do
            Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
            end);
        end;

        local SubTabs = {};
        local ActiveSubTab = nil;
        local ActiveLeft, ActiveRight = LeftSide, RightSide;

        local function LayoutColumns(Left, Right, Frame)
            if Frame.AbsoluteSize.X >= 470 then
                Left.Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
                Left.Size = UDim2.new(0.5, -12 + 2, 1, -16);
                Right.Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
                Right.Size = UDim2.new(0.5, -12 + 2, 1, -16);
            else
                Left.Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
                Left.Size = UDim2.new(1, -12 + 2, 0.5, -10);
                Right.Position = UDim2.new(0, 8 - 1, 0.5, 4 + 1);
                Right.Size = UDim2.new(1, -12 + 2, 0.5, -10);
            end
        end

        local function UpdateSideLayout()
            LayoutColumns(LeftSide, RightSide, TabFrame);

            for _, SubTab in next, SubTabs do
                LayoutColumns(SubTab.Left, SubTab.Right, SubTab.Content);
            end
        end

        UpdateSideLayout();
        TabFrame:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateSideLayout);

        function Tab:ShowTab()
            for _, Tab in next, Window.Tabs do
                Tab:HideTab();
            end;

            Blocker.BackgroundTransparency = 0;
            TabButton.BackgroundColor3 = Library.MainColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
            TabIndicator.Visible = true;

            if ActiveSubTab then
                ActiveSubTab:Show();
            end

            UpdateSideLayout();
        end;
        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1;
            TabButton.BackgroundColor3 = Library.BackgroundColor;
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            TabFrame.Visible = false;
            TabIndicator.Visible = false;
        end;
        function Tab:SetLayoutOrder(Position)
            TabButton.LayoutOrder = Position;
            TabListLayout:ApplyLayout();
        end;
        function Tab:AddSubTab(Name)
            if not Tab.SubTabBar then
                Tab.SubTabBar = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Inset;
                    Position = UDim2.new(0, 8, 0, 8);
                    Size = UDim2.new(1, -16, 0, 24);
                    ZIndex = 3;
                    Parent = TabFrame;
                });
                Library:AddToRegistry(Tab.SubTabBar, {
                    BackgroundColor3 = 'BackgroundColor';
                    BorderColor3 = 'OutlineColor';
                });
                local SubTabBarInner = Library:Create('ScrollingFrame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 1, 0);
                    CanvasSize = UDim2.new(0, 0, 0, 0);
                    AutomaticCanvasSize = Enum.AutomaticSize.X;
                    ScrollingDirection = Enum.ScrollingDirection.X;
                    ScrollBarThickness = 0;
                    BottomImage = '';
                    TopImage = '';
                    ZIndex = 1;
                    Parent = Tab.SubTabBar;
                });
                Library:AddToRegistry(SubTabBarInner, { BackgroundColor3 = 'BackgroundColor' });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Padding = UDim.new(0, 4);
                    Parent = SubTabBarInner;
                });
                Tab.SubTabBarInner = SubTabBarInner;
                LeftSide.Visible = false;
                RightSide.Visible = false;
            end

            local SubTab = {
                Groupboxes = {};
                Tabboxes = {};
            };
            local Button = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.fromOffset(Library:GetTextBounds(Name, Library.Font, Library.FontSize) + 16, 24);
                ZIndex = 5;
                Parent = Tab.SubTabBarInner;
            });
            Library:AddToRegistry(Button, { BackgroundColor3 = 'BackgroundColor' });
            local ButtonLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                Text = Name;
                TextSize = Library.FontSize;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 6;
                Parent = Button;
            });
            local Indicator = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                Visible = false;
                ZIndex = 7;
                Parent = Button;
            });
            Library:AddToRegistry(Indicator, { BackgroundColor3 = 'AccentColor' });
            local Content = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 34);
                Size = UDim2.new(1, 0, 1, -34);
                Visible = false;
                ZIndex = 2;
                Parent = TabFrame;
            });
            local function CreateColumn(Parent)
                local Column = Library:Create('ScrollingFrame', {
                    BackgroundTransparency = 1;
                    BorderSizePixel = 0;
                    CanvasSize = UDim2.new(0, 0, 0, 0);
                    BottomImage = '';
                    TopImage = '';
                    ScrollBarThickness = 0;
                    ZIndex = 2;
                    Parent = Parent;
                });
                Library:Create('UIListLayout', {
                    Padding = UDim.new(0, 8);
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    HorizontalAlignment = Enum.HorizontalAlignment.Center;
                    Parent = Column;
                });
                Column:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
                    Column.CanvasSize = UDim2.fromOffset(0, Column.UIListLayout.AbsoluteContentSize.Y);
                end);
                return Column;
            end
            local SubLeft = CreateColumn(Content);
            local SubRight = CreateColumn(Content);
            LayoutColumns(SubLeft, SubRight, Content);

            function SubTab:Show()
                for _, Other in next, SubTabs do
                    if Other ~= SubTab then
                        Other:Hide();
                    end
                end

                Content.Visible = true;
                Button.BackgroundColor3 = Library.MainColor;
                Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                Indicator.Visible = true;

                ActiveSubTab = SubTab;
                ActiveLeft = SubLeft;
                ActiveRight = SubRight;

                UpdateSideLayout();
            end;
            function SubTab:Hide()
                Content.Visible = false;
                Button.BackgroundColor3 = Library.BackgroundColor;
                Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';
                Indicator.Visible = false;
            end;
            function SubTab:AddLeftGroupbox(GroupboxName)
                return Tab:AddGroupbox({ Side = 1; Name = GroupboxName; Left = SubLeft; Right = SubRight; });
            end;
            function SubTab:AddRightGroupbox(GroupboxName)
                return Tab:AddGroupbox({ Side = 2; Name = GroupboxName; Left = SubLeft; Right = SubRight; });
            end;
            function SubTab:AddLeftTabbox(TabboxName)
                return Tab:AddTabbox({ Name = TabboxName; Side = 1; Left = SubLeft; Right = SubRight; });
            end;
            function SubTab:AddRightTabbox(TabboxName)
                return Tab:AddTabbox({ Name = TabboxName; Side = 2; Left = SubLeft; Right = SubRight; });
            end;
            Button.InputBegan:Connect(function(Input)
                if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                    SubTab:Show();
                end
            end);

            SubTab.Content = Content;
            SubTab.Left = SubLeft;
            SubTab.Right = SubRight;
            SubTab.Button = Button;
            SubTabs[Name] = SubTab;
            Tab.SubTabs = SubTabs;

            if not ActiveSubTab then
                SubTab:Show();
            end

            return SubTab;
        end;
        function Tab:AddGroupbox(Info)
            local Groupbox = {};
            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 507 + 2);
                ZIndex = 2;
                Parent = Info.Side == 1 and (Info.Left or ActiveLeft) or (Info.Right or ActiveRight);
            });
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 2);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });
            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = Library.FontSize;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });
            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });
            function Groupbox:Resize()
                local Size = 0;
                for _, Element in next, Groupbox.Container:GetChildren() do
                    if (not Element:IsA('UIListLayout')) and Element.Visible then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);
            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; Left = ActiveLeft; Right = ActiveRight; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; Left = ActiveLeft; Right = ActiveRight; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and (Info.Left or ActiveLeft) or (Info.Right or ActiveRight);
            });
            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });
            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -2, 1, -2);
                Position = UDim2.new(0, 1, 0, 1);
                ZIndex = 4;
                Parent = BoxOuter;
            });
            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });
            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });
            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });
            function Tabbox:AddTab(Name)
                local Tab = {};
                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });
                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });
                local TabHighlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 2);
                    Visible = false;
                    ZIndex = 10;
                    Parent = Button;
                });
                Library:AddToRegistry(TabHighlight, {
                    BackgroundColor3 = 'AccentColor';
                });
                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = Library.FontSize;
                    Text = Name;
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });
                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(1, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });
                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });
                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });
                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });
                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;
                    TabHighlight.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

                    Tab:Resize();
                end;
                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;
                    TabHighlight.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;
                function Tab:Resize()
                    local TabCount = 0;
                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount + 1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    if (not Container.Visible) then
                        return;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if (not Element:IsA('UIListLayout')) and Element.Visible then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
                end;
                Button.InputBegan:Connect(function(Input)
                    if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                        Tab:Resize();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;
        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1, Left = ActiveLeft, Right = ActiveRight; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2, Left = ActiveLeft, Right = ActiveRight; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                return;
            end

            local StartPosition = Input.Position;
            local Moved = false;
            local ChangedConn, EndedConn;

            ChangedConn = InputService.InputChanged:Connect(function(Change)
                if Change == Input or Change.UserInputType == Enum.UserInputType.MouseMovement or Change.UserInputType == Enum.UserInputType.Touch then
                    if (Change.Position - StartPosition).Magnitude > 6 then
                        Moved = true;
                    end
                end
            end);

            EndedConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                    ChangedConn:Disconnect();
                    EndedConn:Disconnect();

                    if not Moved and EndInput.UserInputState ~= Enum.UserInputState.Cancel then
                        Tab:ShowTab();
                    end
                end
            end);
        end);
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;
        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    if not Mini then
    function Library:Toggle()
        if Library.Unloaded then
            return;
        end

        Library.Toggled = not Library.Toggled;
        Outer.Visible = Library.Toggled;

        for Frame in next, Library.OpenedFrames do
            Frame.Visible = false;
        end
        table.clear(Library.OpenedFrames);

        if Library.MobileToggleButton then
            Library.MobileToggleButton.Text = Library.Toggled and 'Close' or 'Menu';
        end

        Library:SetCursorEnabled(Library.Toggled);
        if Library.UseBlur then
            if Library.Toggled then
                Library.BlurEffect.Enabled = true
                Library.BlurEffect.Size = Library.BlurSize
            else
                Library.BlurEffect.Size = 0
                Library.BlurEffect.Enabled = false
            end
        else
            Library.BlurEffect.Size = 0
            Library.BlurEffect.Enabled = false
        end
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return;
        end

        local Bind = Library.ToggleKeybind;
        local Name = nil;

        if type(Bind) == 'table' and Bind.Type == 'KeyPicker' then
            Name = Bind.Value;
        elseif typeof(Bind) == 'EnumItem' and Bind.EnumType == Enum.KeyCode then
            Name = Bind.Name;
        elseif type(Bind) == 'string' then
            Name = Bind;
        end

        if Name then
            if Input.KeyCode.Name == Name then
                task.spawn(Library.Toggle);
            end
        elseif Input.KeyCode == Library.ToggleKey or (Library.IsDefaultNamespace and Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle);
        end
    end))

    if Config.AutoShow and not Library.SilentLoad then task.spawn(Library.Toggle) end
    else
        if Config.AutoShow and not Library.SilentLoad then Window:SetVisible(true) end
    end

    Window.Holder = Outer;
    table.insert(Library.Windows, Window);
    return Window;
end;

function Library:SetScale(Scale)
    if Library.Unloaded then
        return;
    end

    Scale = math.clamp(tonumber(Scale) or 1, 0.5, 2);
    Library.Scale = Scale;

    for _, Window in next, Library.Windows do
        if Window.SetScale then
            Window:SetScale(Scale);
        end
    end
end;

function Library:SetDPI(Scale)
    return self:SetScale(Scale);
end;

function Library:CreateMiniWindow(Config)
    if Library.Unloaded then
        return;
    end

    Config = Config or {};
    Config.Mini = true;
    return Library:CreateWindow(Config);
end;

local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange));
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange));

if InputService.TouchEnabled then
    local MobileGui = Instance.new('ScreenGui')
    MobileGui.Name = 'angelMobileUI' .. GuiSuffix
    MobileGui.IgnoreGuiInset = true
    MobileGui.ResetOnSpawn = false
    MobileGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    MobileGui.DisplayOrder = 1000
    ProtectGui(MobileGui)
    MobileGui.Parent = GetGuiParent()

    local BTN_W, BTN_H, BTN_GAP = 96, 30, 8

    local function CreateMobileButton(Name, Text, OffsetY)
        local Outer = Library:Create('Frame', {
            Name             = Name .. 'Outer';
            BackgroundColor3 = Library.OutlineColor;
            BorderSizePixel  = 0;
            AnchorPoint      = Vector2.new(1, 0);
            Position         = UDim2.new(1, -12, 0, OffsetY);
            Size             = UDim2.fromOffset(BTN_W, BTN_H);
            ZIndex           = 300;
            Active           = true;
            Parent           = MobileGui;
        })
        Library:AddToRegistry(Outer, { BackgroundColor3 = 'OutlineColor' })

        local Inner = Library:Create('Frame', {
            Name             = Name .. 'Inner';
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel  = 0;
            Position         = UDim2.new(0, 1, 0, 1);
            Size             = UDim2.new(1, -2, 1, -2);
            ZIndex           = 301;
            Parent           = Outer;
        })
        Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor' })

        local Accent = Library:Create('Frame', {
            Name             = Name .. 'Accent';
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 0, 2);
            ZIndex           = 302;
            Parent           = Inner;
        })
        Library:AddToRegistry(Accent, { BackgroundColor3 = 'AccentColor' })

        local Gradient = Library:Create('Frame', {
            Name             = Name .. 'Gradient';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel  = 0;
            Size             = UDim2.new(1, 0, 1, 0);
            ZIndex           = 303;
            Parent           = Inner;
        })
        Library:Create('UIGradient', {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.94);
                NumberSequenceKeypoint.new(1, 1);
            });
            Rotation = 90;
            Parent = Gradient;
        })

        local Button = Library:Create('TextButton', {
            Name                   = Name .. 'Button';
            BackgroundTransparency = 1;
            Size                   = UDim2.new(1, 0, 1, 0);
            Font                   = Library.Font;
            Text                   = Text;
            TextColor3             = Library.FontColor;
            TextSize               = Library.FontSize;
            ZIndex                 = 304;
            Active                 = true;
            Parent                 = Inner;
        })
        Library:AddToRegistry(Button, { TextColor3 = 'FontColor' })

        return Outer, Button
    end

    local ToggleOuter, ToggleButton = CreateMobileButton('Toggle', 'Menu', 10)
    local LockOuter, LockButton = CreateMobileButton('Lock', 'Lock', 10 + BTN_H + BTN_GAP)

    local function BindMobileButton(Button, Outer, OnClick)
        local Dragging, DragInput, DragStart, StartPos, Moved = false, nil, nil, nil, false

        Button.InputBegan:Connect(function(Input)
            if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            Dragging = true
            Moved = false
            DragStart = Input.Position
            StartPos = Outer.Position
            DragInput = Input

            local Connection
            Connection = Input.Changed:Connect(function()
                if Input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Dragging = false
                Connection:Disconnect()

                if not Moved then
                    OnClick()
                end
            end)
        end)

        Library:GiveSignal(InputService.InputChanged:Connect(function(Input)
            if Input ~= DragInput or not Dragging then
                return
            end

            local Delta = Input.Position - DragStart

            if Delta.Magnitude > 4 then
                Moved = true
            end

            if not Library.Locked and Moved then
                Outer.Position = UDim2.new(
                    StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                    StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                )
            end
        end))
    end

    BindMobileButton(ToggleButton, ToggleOuter, function()
        if Library.Toggle then
            Library:Toggle()
        end
    end)

    local function UpdateLockButton()
        LockButton.Text = Library.Locked and 'Unlock' or 'Lock'
        LockButton.TextColor3 = Library.Locked and Library.AccentColor or Library.FontColor

        local Registry = Library.RegistryMap[LockButton]
        if Registry then
            Registry.Properties.TextColor3 = Library.Locked and 'AccentColor' or 'FontColor'
        end
    end

    BindMobileButton(LockButton, LockOuter, function()
        Library.Locked = not Library.Locked
        UpdateLockButton()
    end)

    UpdateLockButton()

    Library.MobileUI = MobileGui
    Library.MobileButtons = { ToggleOuter, LockOuter }
    Library.MobileToggleButton = ToggleButton
    Library.MobileLockButton = LockButton

    local BaseUpdateColors = Library.UpdateColorsUsingRegistry
    Library.UpdateColorsUsingRegistry = function(Self)
        BaseUpdateColors(Self)
        UpdateLockButton()
    end
end

return Library
