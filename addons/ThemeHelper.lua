local HttpService = game:GetService('HttpService')

local ThemeHelper = {}
ThemeHelper.Folder = 'sillyUISettings'
ThemeHelper.Library = nil
ThemeHelper.DefaultTheme = 'Default'
ThemeHelper.Fields = { 'FontColor', 'MainColor', 'AccentColor', 'BackgroundColor', 'OutlineColor', 'RiskColor' }
ThemeHelper.BuiltInThemes = {
    ['Default'] = { 1, { FontColor = 'ffffff', MainColor = '151514', AccentColor = '93a1fe', BackgroundColor = '111110', OutlineColor = '1f1e1f' } },
    ['Primordial'] = { 2, { FontColor = 'ffffff', MainColor = '181818', AccentColor = 'd7a6b0', BackgroundColor = '1f1f1f', OutlineColor = '2a2a2a' } },
    ['BBot'] = { 3, { FontColor = 'ffffff', MainColor = '1e1e1e', AccentColor = '7e48a3', BackgroundColor = '232323', OutlineColor = '141414' } },
    ['Fatality'] = { 4, { FontColor = 'ffffff', MainColor = '1e1842', AccentColor = 'c50754', BackgroundColor = '191335', OutlineColor = '3c355d' } },
    ['Jester'] = { 5, { FontColor = 'ffffff', MainColor = '242424', AccentColor = 'db4467', BackgroundColor = '1c1c1c', OutlineColor = '373737' } },
    ['Mint'] = { 6, { FontColor = 'ffffff', MainColor = '242424', AccentColor = '3db488', BackgroundColor = '1c1c1c', OutlineColor = '373737' } },
    ['Tokyo Night'] = { 7, { FontColor = 'ffffff', MainColor = '191925', AccentColor = '6759b3', BackgroundColor = '16161f', OutlineColor = '323232' } },
    ['Ubuntu'] = { 8, { FontColor = 'ffffff', MainColor = '3e3e3e', AccentColor = 'e2581e', BackgroundColor = '323232', OutlineColor = '191919' } },
    ['Quartz'] = { 9, { FontColor = 'ffffff', MainColor = '232330', AccentColor = '426e87', BackgroundColor = '1d1b26', OutlineColor = '27232f' } },
    ['Inferno'] = { 10, { FontColor = 'ffffff', MainColor = '141414', AccentColor = 'a34848', BackgroundColor = '181818', OutlineColor = '141414' } },
    ['Neverlose'] = { 11, { FontColor = 'ffffff', MainColor = '242424', AccentColor = '0679b0', BackgroundColor = '1c1c1c', OutlineColor = '373737' } },
    ['GameSense'] = { 12, { FontColor = 'ffffff', MainColor = '181818', AccentColor = '4cb800', BackgroundColor = '141414', OutlineColor = '1f1f1f' } },
}

local function Shared(Name)
    if getgenv then
        local Success, Environment = pcall(getgenv)
        if Success and type(Environment) == 'table' then
            return Environment[Name]
        end
    end
end

function ThemeHelper:HasFilesystem()
    return type(isfolder) == 'function'
        and type(makefolder) == 'function'
        and type(isfile) == 'function'
        and type(readfile) == 'function'
        and type(writefile) == 'function'
        and type(listfiles) == 'function'
end

function ThemeHelper:GetOption(Name)
    local Options = (self.Library and self.Library.Options) or Shared('Options')
    if not Options then
        return nil
    end
    return Options[Name]
end

function ThemeHelper:Notify(Text, Time)
    if self.Library and self.Library.Notify then
        self.Library:Notify(Text, Time)
    end
end

function ThemeHelper:SetLibrary(Library)
    self.Library = Library
    Library.ThemeHelper = self
end

function ThemeHelper:ApplyTheme(Theme)
    if not Theme or not self.Library then
        return
    end

    local Custom = self:GetCustomTheme(Theme)
    local Data = Custom or self.BuiltInThemes[Theme]
    if not Data then
        return
    end

    local Scheme = Custom or Data[2]
    for Field, Color in next, Scheme do
        local Success, Parsed = pcall(Color3.fromHex, Color)
        if Success and Parsed then
            self.Library[Field] = Parsed

            local Option = self:GetOption(Field)
            if Option and Option.SetValueRGB then
                Option:SetValueRGB(Parsed)
            end
        end
    end

    self:ThemeUpdate()
end

function ThemeHelper:ThemeUpdate()
    if not self.Library then
        return
    end

    for _, Field in next, self.Fields do
        local Option = self:GetOption(Field)
        if Option and typeof(Option.Value) == 'Color3' then
            self.Library[Field] = Option.Value
        end
    end

    self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
    self.Library:UpdateColorsUsingRegistry()
end

function ThemeHelper:ReadDefault()
    if not self:HasFilesystem() then
        return nil
    end

    local Path = self.Folder .. '/themes/default.txt'
    local Found, Exists = pcall(isfile, Path)
    if not Found or not Exists then
        return nil
    end

    local Read, Content = pcall(readfile, Path)
    if not Read or type(Content) ~= 'string' then
        return nil
    end

    Content = Content:gsub('^%s+', ''):gsub('%s+$', '')
    if Content == '' then
        return nil
    end

    return Content
end

function ThemeHelper:LoadDefault()
    if not self.Library then
        return
    end

    local Theme = 'Default'
    local Content = self:ReadDefault()

    if Content and self.BuiltInThemes[Content] then
        Theme = Content
    elseif Content and self:GetCustomTheme(Content) then
        Theme = Content
    elseif self.DefaultTheme and self.BuiltInThemes[self.DefaultTheme] then
        Theme = self.DefaultTheme
    end

    local Dropdown = self:GetOption('ThemeHelper_ThemeList')

    if self.BuiltInThemes[Theme] then
        if Dropdown then
            Dropdown:SetValue(Theme)
        else
            self:ApplyTheme(Theme)
        end
    else
        self:ApplyTheme(Theme)
    end
end

function ThemeHelper:SaveDefault(Theme)
    if not Theme then
        return
    end

    if not self:HasFilesystem() then
        return self:Notify('the executor does not support file writes', 3)
    end

    self:BuildFolderTree()
    pcall(writefile, self.Folder .. '/themes/default.txt', Theme)
end

function ThemeHelper:CreateThemeSection(Groupbox)
    assert(self.Library, 'Must set ThemeHelper.Library first!')

    Groupbox:AddLabel('background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
    Groupbox:AddLabel('main color'):AddColorPicker('MainColor', { Default = self.Library.MainColor })
    Groupbox:AddLabel('accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor })
    Groupbox:AddLabel('outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor })
    Groupbox:AddLabel('font color'):AddColorPicker('FontColor', { Default = self.Library.FontColor })
    Groupbox:AddLabel('risk color'):AddColorPicker('RiskColor', { Default = self.Library.RiskColor or Color3.fromRGB(255, 50, 50) })

    local Themes = {}
    for Name in next, self.BuiltInThemes do
        table.insert(Themes, Name)
    end

    table.sort(Themes, function(A, B)
        return self.BuiltInThemes[A][1] < self.BuiltInThemes[B][1]
    end)

    Groupbox:AddDivider()
    Groupbox:AddDropdown('ThemeHelper_ThemeList', { Text = 'theme list', Values = Themes, Default = 1 })

    Groupbox:AddButton('set as default', function()
        local Selected = self:GetOption('ThemeHelper_ThemeList')
        if not Selected or not Selected.Value then
            return
        end

        self:SaveDefault(Selected.Value)
        self:Notify(string.format('set default theme to %q', Selected.Value))
    end)

    local ThemeList = self:GetOption('ThemeHelper_ThemeList')
    if ThemeList then
        ThemeList:OnChanged(function(Value)
            self:ApplyTheme(Value)
        end)
    end

    Groupbox:AddDivider()
    Groupbox:AddInput('ThemeHelper_CustomThemeName', { Text = 'custom theme name' })
    Groupbox:AddDropdown('ThemeHelper_CustomThemeList', {
        Text = 'custom themes',
        Values = self:ReloadCustomThemes(),
        AllowNull = true,
    })

    Groupbox:AddDivider()

    Groupbox:AddButton('save theme', function()
        local NameInput = self:GetOption('ThemeHelper_CustomThemeName')
        local Name = NameInput and tostring(NameInput.Value or ''):gsub('^%s+', ''):gsub('%s+$', '') or ''

        self:SaveCustomTheme(Name)

        local CustomList = self:GetOption('ThemeHelper_CustomThemeList')
        if CustomList then
            CustomList:SetValues(self:ReloadCustomThemes())
            CustomList:SetValue(nil)
        end
    end):AddButton('load theme', function()
        local CustomList = self:GetOption('ThemeHelper_CustomThemeList')
        if CustomList and CustomList.Value then
            self:ApplyTheme(CustomList.Value)
        end
    end)

    Groupbox:AddButton('refresh list', function()
        local CustomList = self:GetOption('ThemeHelper_CustomThemeList')
        if CustomList then
            CustomList:SetValues(self:ReloadCustomThemes())
            CustomList:SetValue(nil)
        end
    end)

    Groupbox:AddButton('set as default', function()
        local CustomList = self:GetOption('ThemeHelper_CustomThemeList')
        if not CustomList or not CustomList.Value or CustomList.Value == '' then
            return
        end

        self:SaveDefault(CustomList.Value)
        self:Notify(string.format('set default theme to %q', CustomList.Value))
    end)

    ThemeHelper:LoadDefault()

    local function UpdateTheme()
        self:ThemeUpdate()
    end

    for _, Field in next, self.Fields do
        local Option = self:GetOption(Field)
        if Option and Option.OnChanged then
            Option:OnChanged(UpdateTheme)
        end
    end
end

function ThemeHelper:GetCustomTheme(Name)
    if not Name or not self:HasFilesystem() then
        return nil
    end

    local Path = self.Folder .. '/themes/' .. Name .. '.json'
    local Found, Exists = pcall(isfile, Path)
    if not Found or not Exists then
        return nil
    end

    local Read, Content = pcall(readfile, Path)
    if not Read or type(Content) ~= 'string' then
        return nil
    end

    local Decoded, Data = pcall(HttpService.JSONDecode, HttpService, Content)
    if not Decoded or type(Data) ~= 'table' then
        return nil
    end

    return Data
end

function ThemeHelper:SaveCustomTheme(Name)
    Name = tostring(Name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if Name == '' then
        return self:Notify('invalid file name for theme (empty)', 3)
    end

    if not self:HasFilesystem() then
        return self:Notify('the executor does not support file writes', 3)
    end

    self:BuildFolderTree()

    local Theme = {}
    for _, Field in next, self.Fields do
        local Option = self:GetOption(Field)
        if Option and typeof(Option.Value) == 'Color3' then
            Theme[Field] = Option.Value:ToHex()
        end
    end

    local Encoded, EncodedData = pcall(HttpService.JSONEncode, HttpService, Theme)
    if not Encoded then
        return self:Notify('failed to encode theme', 3)
    end

    local Written = pcall(writefile, self.Folder .. '/themes/' .. Name .. '.json', EncodedData)
    if not Written then
        return self:Notify('failed to save theme', 3)
    end

    self:Notify(string.format('saved theme %q', Name))
end

function ThemeHelper:ReloadCustomThemes()
    local Out = {}
    if not self:HasFilesystem() then
        return Out
    end

    self:BuildFolderTree()

    local Listed, List = pcall(listfiles, self.Folder .. '/themes')
    if not Listed or type(List) ~= 'table' then
        return Out
    end

    for _, File in next, List do
        local Name = tostring(File):match('([^/\\]+)%.json$')
        if Name then
            table.insert(Out, Name)
        end
    end

    table.sort(Out)
    return Out
end

function ThemeHelper:BuildFolderTree()
    if not self:HasFilesystem() then
        return
    end

    local Parts = {}
    for Part in string.gmatch(self.Folder, '[^/\\]+') do
        table.insert(Parts, Part)
    end

    local Current = nil
    for _, Part in next, Parts do
        Current = Current and (Current .. '/' .. Part) or Part
        if not isfolder(Current) then
            pcall(makefolder, Current)
        end
    end

    for _, Path in next, { self.Folder .. '/themes', self.Folder .. '/settings' } do
        if not isfolder(Path) then
            pcall(makefolder, Path)
        end
    end
end

function ThemeHelper:SetFolder(Folder)
    self.Folder = Folder
    self:BuildFolderTree()
end

function ThemeHelper:CreateGroupBox(Tab)
    assert(self.Library, 'Must set ThemeHelper.Library first!')
    return Tab:AddLeftGroupbox('themes')
end

function ThemeHelper:ApplyToTab(Tab)
    local Groupbox = self:CreateGroupBox(Tab)
    self:CreateThemeSection(Groupbox)
end

function ThemeHelper:ApplyToGroupbox(Groupbox)
    assert(self.Library, 'Must set ThemeHelper.Library first!')
    self:CreateThemeSection(Groupbox)
end

ThemeHelper:BuildFolderTree()

if getgenv then
    local Success, Environment = pcall(getgenv)
    if Success and type(Environment) == 'table' then
        task.defer(function()
            if not ThemeHelper.Library or ThemeHelper.Library.IsDefaultNamespace then
                Environment.ThemeHelper = ThemeHelper
                Environment.ThemeManager = ThemeHelper
            end
        end)
    end
end

return ThemeHelper
