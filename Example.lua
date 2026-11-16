local REPO = 'https://raw.githubusercontent.com/sickletone/hgjsvdnbdsnvxhdvsgsvdhskdvjhdjsbjdbdisvshbsuvabaababbababHahbbshsvsjsvsuvssvhsvejejsvisvshsvehgsshvs/main/'

local function Load(Path)
    local Success, Result = pcall(function()
        return loadstring(game:HttpGet(REPO .. Path))()
    end)
    if not Success then
        error('failed to load ' .. Path .. ': ' .. tostring(Result))
    end
    return Result
end

local Library = Load('Library.lua')
local ThemeManager = Load('addons/ThemeManager.lua')
local SaveManager = Load('addons/SaveManager.lua')

local Window = Library:CreateWindow({
    Title = 'remade by angel',
    Center = true,
    AutoShow = true,
    TabPadding = 6,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Main = Window:AddTab('main'),
    Visuals = Window:AddTab('visuals'),
    Settings = Window:AddTab('settings'),
}

local General = Tabs.Main:AddLeftGroupbox('general')

General:AddToggle('FeatureEnabled', { Text = 'enabled', Default = true, Callback = function(Value) end })
General:AddSlider('FeatureSpeed', { Text = 'speed', Min = 1, Max = 32, Default = 16, Rounding = 1, Suffix = '' })
General:AddDropdown('FeatureMode', { Text = 'mode', Values = { 'legit', 'rage', 'auto' }, Default = 'legit' })
General:AddDropdown('FeatureParts', { Text = 'parts', Values = { 'head', 'torso', 'arms', 'legs' }, Multi = true, Default = { 'head', 'arms' } })
General:AddDivider()
General:AddLabel('remade by angel')

local Extra = Tabs.Main:AddRightGroupbox('extra')

Extra:AddColorPicker('FeatureColor', { Default = Color3.fromRGB(147, 161, 254), Title = 'feature color' })
Extra:AddKeyPicker('FeatureKey', { Text = 'feature key', Default = 'None', Mode = 'Toggle' })
Extra:AddInput('FeatureName', { Text = 'name', Default = '', Placeholder = 'type here' })
Extra:AddButton('notify', function()
    Library:Notify('notified from the example', 3)
end):AddButton('reset', function()
    Library.Toggles.FeatureEnabled:SetValue(false)
end)

local Dependencies = Extra:AddDependencyBox()
Dependencies:SetupDependencies({ { Library.Toggles.FeatureEnabled, true } })
Dependencies:AddToggle('FeatureNested', { Text = 'only when enabled', Default = false })
Dependencies:AddSlider('FeatureNestedScale', { Text = 'scale', Min = 0, Max = 1, Default = 0.5, Rounding = 3 })

local VisualsBox = Tabs.Visuals:AddLeftGroupbox('visuals')
VisualsBox:AddToggle('EspEnabled', { Text = 'esp', Default = false })
VisualsBox:AddColorPicker('EspColor', { Default = Color3.fromRGB(255, 255, 255) })
VisualsBox:AddSlider('EspDistance', { Text = 'distance', Min = 0, Max = 1000, Default = 500, Rounding = 0, Suffix = 'm' })

local VisualTabs = Tabs.Visuals:AddRightTabbox('options')
local PlayerTab = VisualTabs:AddTab('players')
PlayerTab:AddToggle('EspPlayers', { Text = 'players', Default = true })
PlayerTab:AddToggle('EspBoxes', { Text = 'boxes', Default = true })
local WorldTab = VisualTabs:AddTab('world')
WorldTab:AddToggle('EspWorld', { Text = 'world', Default = false })
WorldTab:AddSlider('EspAlpha', { Text = 'alpha', Min = 0, Max = 1, Default = 0.8, Rounding = 2 })

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'FeatureKey' })
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

SaveManager:LoadAutoloadConfig()

Library:SetWatermark('remade by <font color="#93A1FE">angel</font>')

return {
    Library = Library,
    Window = Window,
    Tabs = Tabs,
    ThemeManager = ThemeManager,
    SaveManager = SaveManager,
}
