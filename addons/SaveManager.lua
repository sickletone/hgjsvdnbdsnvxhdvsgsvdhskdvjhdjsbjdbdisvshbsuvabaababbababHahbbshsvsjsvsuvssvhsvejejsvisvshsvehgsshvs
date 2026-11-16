local HttpService = game:GetService('HttpService')

local SaveManager = {}
SaveManager.Folder = 'angelLibSettings'
SaveManager.Ignore = {}
SaveManager.Library = nil

local function Shared(Name)
    if getgenv then
        local Success, Environment = pcall(getgenv)
        if Success and type(Environment) == 'table' then
            return Environment[Name]
        end
    end
end

function SaveManager:GetToggles()
    if self.Library and self.Library.Toggles then
        return self.Library.Toggles
    end
    return Shared('Toggles') or {}
end

function SaveManager:GetOptions()
    if self.Library and self.Library.Options then
        return self.Library.Options
    end
    return Shared('Options') or {}
end

function SaveManager:HasFilesystem()
    return type(isfolder) == 'function'
        and type(makefolder) == 'function'
        and type(isfile) == 'function'
        and type(readfile) == 'function'
        and type(writefile) == 'function'
        and type(listfiles) == 'function'
        and type(delfile) == 'function'
end

SaveManager.Parser = {
    Toggle = {
        Save = function(Index, Object)
            return { type = 'Toggle', idx = Index, value = Object.Value }
        end,
        Load = function(Index, Data)
            local Toggles = SaveManager:GetToggles()
            if Toggles[Index] then
                Toggles[Index]:SetValue(Data.value)
            end
        end,
    },
    Slider = {
        Save = function(Index, Object)
            return { type = 'Slider', idx = Index, value = tostring(Object.Value) }
        end,
        Load = function(Index, Data)
            local Options = SaveManager:GetOptions()
            if Options[Index] then
                Options[Index]:SetValue(Data.value)
            end
        end,
    },
    Dropdown = {
        Save = function(Index, Object)
            return { type = 'Dropdown', idx = Index, value = Object.Value, multi = Object.Multi }
        end,
        Load = function(Index, Data)
            local Options = SaveManager:GetOptions()
            if Options[Index] then
                Options[Index]:SetValue(Data.value)
            end
        end,
    },
    ColorPicker = {
        Save = function(Index, Object)
            return {
                type = 'ColorPicker',
                idx = Index,
                value = Object.Value:ToHex(),
                transparency = Object.Transparency,
            }
        end,
        Load = function(Index, Data)
            local Options = SaveManager:GetOptions()
            local Option = Options[Index]
            if not Option or type(Data.value) ~= 'string' then
                return
            end

            local Success, Color = pcall(Color3.fromHex, Data.value)
            if Success then
                Option:SetValueRGB(Color, Data.transparency or 0)
            end
        end,
    },
    KeyPicker = {
        Save = function(Index, Object)
            return { type = 'KeyPicker', idx = Index, mode = Object.Mode, key = Object.Value }
        end,
        Load = function(Index, Data)
            local Options = SaveManager:GetOptions()
            if Options[Index] and Data.key then
                Options[Index]:SetValue({ Data.key, Data.mode })
            end
        end,
    },
    Input = {
        Save = function(Index, Object)
            return { type = 'Input', idx = Index, text = Object.Value }
        end,
        Load = function(Index, Data)
            local Options = SaveManager:GetOptions()
            if Options[Index] and type(Data.text) == 'string' then
                Options[Index]:SetValue(Data.text)
            end
        end,
    },
}

function SaveManager:SetIgnoreIndexes(List)
    for _, Key in next, List do
        self.Ignore[Key] = true
    end
end

function SaveManager:SetFolder(Folder)
    self.Folder = Folder
    self:BuildFolderTree()
end

function SaveManager:BuildFolderTree()
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

function SaveManager:Save(Name)
    if not Name then
        return false, 'no config file is selected'
    end

    if not self:HasFilesystem() then
        return false, 'the executor does not support file writes'
    end

    self:BuildFolderTree()

    local Data = { objects = {} }

    for Index, Toggle in next, self:GetToggles() do
        if not self.Ignore[Index] and self.Parser[Toggle.Type] then
            table.insert(Data.objects, self.Parser[Toggle.Type].Save(Index, Toggle))
        end
    end

    for Index, Option in next, self:GetOptions() do
        if not self.Ignore[Index] and self.Parser[Option.Type] then
            table.insert(Data.objects, self.Parser[Option.Type].Save(Index, Option))
        end
    end

    local Encoded, EncodedData = pcall(HttpService.JSONEncode, HttpService, Data)
    if not Encoded then
        return false, 'failed to encode data'
    end

    local Written = pcall(writefile, self.Folder .. '/settings/' .. Name .. '.json', EncodedData)
    if not Written then
        return false, 'failed to write config file'
    end

    return true
end

function SaveManager:Load(Name)
    if not Name then
        return false, 'no config file is selected'
    end

    if not self:HasFilesystem() then
        return false, 'the executor does not support file reads'
    end

    local Path = self.Folder .. '/settings/' .. Name .. '.json'
    local Found, Exists = pcall(isfile, Path)
    if not Found or not Exists then
        return false, 'invalid file'
    end

    local Read, Content = pcall(readfile, Path)
    if not Read or type(Content) ~= 'string' then
        return false, 'failed to read config file'
    end

    local Decoded, Data = pcall(HttpService.JSONDecode, HttpService, Content)
    if not Decoded or type(Data) ~= 'table' or type(Data.objects) ~= 'table' then
        return false, 'decode error'
    end

    for _, Entry in next, Data.objects do
        if type(Entry) == 'table' and self.Parser[Entry.type] and Entry.idx then
            task.spawn(function()
                pcall(self.Parser[Entry.type].Load, Entry.idx, Entry)
            end)
        end
    end

    return true
end

function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({
        'BackgroundColor',
        'MainColor',
        'AccentColor',
        'OutlineColor',
        'FontColor',
        'RiskColor',
        'ThemeManager_ThemeList',
        'ThemeManager_CustomThemeList',
        'ThemeManager_CustomThemeName',
    })
end

function SaveManager:RefreshConfigList()
    if not self:HasFilesystem() then
        return {}
    end

    self:BuildFolderTree()

    local Listed, List = pcall(listfiles, self.Folder .. '/settings')
    if not Listed or type(List) ~= 'table' then
        return {}
    end

    local Out = {}
    for _, File in next, List do
        local Config = tostring(File):match('([^/\\]+)%.json$')
        if Config then
            table.insert(Out, Config)
        end
    end

    table.sort(Out)
    return Out
end

function SaveManager:SetLibrary(Library)
    self.Library = Library
    Library.SaveManager = self
end

function SaveManager:Notify(Text, Time)
    if self.Library and self.Library.Notify then
        self.Library:Notify(Text, Time)
    end
end

function SaveManager:GetConfigName()
    local Input = self:GetOptions().SaveManager_ConfigName
    if not Input then
        return nil
    end
    local Name = tostring(Input.Value or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if Name == '' then
        return nil
    end
    return Name
end

function SaveManager:GetSelectedConfig()
    local Dropdown = self:GetOptions().SaveManager_ConfigList
    if not Dropdown then
        return nil
    end
    return Dropdown.Value
end

function SaveManager:LoadAutoloadConfig()
    if not self:HasFilesystem() then
        return
    end

    local Path = self.Folder .. '/settings/autoload.txt'
    local Found, Exists = pcall(isfile, Path)
    if not Found or not Exists then
        return
    end

    local Read, Name = pcall(readfile, Path)
    if not Read or type(Name) ~= 'string' then
        return
    end

    Name = Name:gsub('^%s+', ''):gsub('%s+$', '')
    if Name == '' then
        return
    end

    local Loaded, Error = self:Load(Name)
    if not Loaded then
        return self:Notify('failed to load autoload config: ' .. tostring(Error))
    end

    self:Notify(string.format('auto loaded config %q', Name))
end

function SaveManager:BuildConfigSection(Tab)
    assert(self.Library, 'Must set SaveManager.Library')

    local Library = self.Library
    local Section = Tab:AddRightGroupbox('configuration')
    local Options = self:GetOptions()

    local function SetRisk(Button, Text)
        Library:RemoveFromRegistry(Button.Label)
        Library:AddToRegistry(Button.Label, { TextColor3 = 'RiskColor' })
        Button.Label.TextColor3 = Library.RiskColor or Color3.fromRGB(255, 50, 50)
        Button.Label.Text = Text
    end

    local function ResetLabel(Button, Text)
        Library:RemoveFromRegistry(Button.Label)
        Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })
        Button.Label.TextColor3 = Library.FontColor
        Button.Label.Text = Text
    end

    Section:AddInput('SaveManager_ConfigName', { Text = 'config name' })
    Section:AddDropdown('SaveManager_ConfigList', {
        Text = 'config list',
        Values = self:RefreshConfigList(),
        AllowNull = true,
    })

    Section:AddDivider()

    Section:AddButton('create config', function()
        local Name = self:GetConfigName()
        if not Name then
            return self:Notify('invalid config name (empty)', 2)
        end

        local Saved, Error = self:Save(Name)
        if not Saved then
            return self:Notify('failed to save config: ' .. tostring(Error))
        end

        self:Notify(string.format('created config %q', Name))
        Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
        Options.SaveManager_ConfigList:SetValue(nil)
    end):AddButton('load config', function()
        local Name = self:GetSelectedConfig()
        local Loaded, Error = self:Load(Name)
        if not Loaded then
            return self:Notify('failed to load config: ' .. tostring(Error))
        end

        self:Notify(string.format('loaded config %q', Name))
    end)

    local OverwriteConfirming, OverwriteTimer = false, nil
    local DeleteConfirming, DeleteTimer = false, nil
    local OverwriteButton, DeleteButton

    OverwriteButton = Section:AddButton('overwrite config', function()
        if not OverwriteConfirming then
            OverwriteConfirming = true
            SetRisk(OverwriteButton, 'are you sure?')

            if OverwriteTimer then
                task.cancel(OverwriteTimer)
            end

            OverwriteTimer = task.delay(1, function()
                OverwriteConfirming = false
                ResetLabel(OverwriteButton, 'overwrite config')
            end)

            return
        end

        if OverwriteTimer then
            task.cancel(OverwriteTimer)
        end

        OverwriteConfirming = false
        ResetLabel(OverwriteButton, 'overwrite config')

        local Name = self:GetSelectedConfig()
        local Saved, Error = self:Save(Name)
        if not Saved then
            return self:Notify('failed to overwrite config: ' .. tostring(Error))
        end

        self:Notify(string.format('overwrote config %q', Name))
    end)

    DeleteButton = OverwriteButton:AddButton('delete config', function()
        if not DeleteConfirming then
            DeleteConfirming = true
            SetRisk(DeleteButton, 'are you sure?')

            if DeleteTimer then
                task.cancel(DeleteTimer)
            end

            DeleteTimer = task.delay(1, function()
                DeleteConfirming = false
                ResetLabel(DeleteButton, 'delete config')
            end)

            return
        end

        if DeleteTimer then
            task.cancel(DeleteTimer)
        end

        DeleteConfirming = false
        ResetLabel(DeleteButton, 'delete config')

        local Name = self:GetSelectedConfig()
        if not Name then
            return self:Notify('no config selected')
        end

        if not self:HasFilesystem() then
            return self:Notify('the executor does not support file deletes')
        end

        local Path = self.Folder .. '/settings/' .. Name .. '.json'
        local Found, Exists = pcall(isfile, Path)
        if Found and Exists then
            pcall(delfile, Path)
            self:Notify(string.format('deleted config %q', Name))
        else
            self:Notify('config file not found')
        end

        Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
        Options.SaveManager_ConfigList:SetValue(nil)
    end)

    task.defer(function()
        if not OverwriteButton or not OverwriteButton.Outer or not DeleteButton or not DeleteButton.Outer then
            return
        end

        local Width, Height = OverwriteButton.Outer.AbsoluteSize.X, OverwriteButton.Outer.AbsoluteSize.Y
        if Width > 0 then
            DeleteButton.Outer.Size = UDim2.fromOffset(Width - 2, Height)
        end
    end)

    Section:AddButton('refresh list', function()
        Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
        Options.SaveManager_ConfigList:SetValue(nil)
    end)

    Section:AddButton('set autoload', function()
        local Name = self:GetSelectedConfig()
        if not Name then
            return self:Notify('no config selected')
        end

        if not self:HasFilesystem() then
            return self:Notify('the executor does not support file writes')
        end

        pcall(writefile, self.Folder .. '/settings/autoload.txt', Name)
        SaveManager.AutoloadLabel:SetText('current autoload config: ' .. Name)
        self:Notify(string.format('set %q to auto load', Name))
    end):AddButton('remove autoload', function()
        if not self:HasFilesystem() then
            return self:Notify('the executor does not support file deletes')
        end

        local Path = self.Folder .. '/settings/autoload.txt'
        local Found, Exists = pcall(isfile, Path)
        if Found and Exists then
            pcall(delfile, Path)
        end

        SaveManager.AutoloadLabel:SetText('current autoload config: none')
        self:Notify('removed autoload')
    end)

    SaveManager.AutoloadLabel = Section:AddLabel('current autoload config: none', true)

    if self:HasFilesystem() then
        local Path = self.Folder .. '/settings/autoload.txt'
        local Found, Exists = pcall(isfile, Path)
        if Found and Exists then
            local Read, Name = pcall(readfile, Path)
            if Read and type(Name) == 'string' then
                Name = Name:gsub('^%s+', ''):gsub('%s+$', '')
                if Name ~= '' then
                    SaveManager.AutoloadLabel:SetText('current autoload config: ' .. Name)
                end
            end
        end
    end

    self:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
end

SaveManager:BuildFolderTree()

if getgenv then
    local Success, Environment = pcall(getgenv)
    if Success and type(Environment) == 'table' then
        Environment.SaveManager = SaveManager
    end
end

return SaveManager
