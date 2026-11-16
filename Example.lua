local repo = "https://raw.githubusercontent.com/sickletone/hgjsvdnbdsnvxhdvsgsvdhskdvjhdjsbjdbdisvshbsuvabaababbababHahbbshsvsjsvsuvssvhsvejejsvisvshsvehgsshvs/main/"

-- silly.lua example script
--
-- Every section from the original unnamed example is included here, plus the
-- newer library features:
--   * sub tabs (Tab:AddSubTab)
--   * mini windows (Library:CreateMiniWindow and element bindings)
--   * DPI / scale (Library:SetDPI, Window:SetScale or CreateWindow({ Scale = ... }))
--
-- The loader below fetches this fork from GitHub, so keep the repo in sync.

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = getgenv().Options
local Toggles = getgenv().Toggles

Library.ShowToggleFrameInKeybinds = true
Library.ShowCustomCursor = true
Library.NotifySide = "Left"

-- CALLBACK NOTE:
-- Passing callbacks via the initial element parameters works, but using
-- Toggles/Options.INDEX:OnChanged(function(Value) ... end) is recommended.
-- Create the UI first, then wire your game logic to it later.

-- Window options:
-- Center     -> center the menu on screen
-- AutoShow   -> show the menu as soon as it is created
-- Resizable  -> adds edge resize handles and the corner grip
-- Scale      -> optional per-window DPI (defaults to Library.Scale)
-- Position / Size are also accepted and are not required.
local Window = Library:CreateWindow({
	Title = "silly.lua | Example",
	Center = true,
	AutoShow = true,
	Resizable = true,
	ShowCustomCursor = false,
	UnlockMouseWhileOpen = true,
	NotifySide = "Left",
	TabPadding = 8,
	MenuFadeTime = 0.2,
})

-- DPI / scale:
-- 1 = 100%. Change this line (or the Menu DPI dropdown under UI Settings)
-- to scale the menu and every mini window together. The same value can also
-- be passed per window with CreateWindow({ Scale = 1.15 }).
Library:SetDPI(1)

local Tabs = {
	Main = Window:AddTab("Main"),
	["Sub Tabs"] = Window:AddTab("Sub Tabs"),
	["Mini Windows"] = Window:AddTab("Mini Windows"),
	["UI Settings"] = Window:AddTab("UI Settings"),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Groupbox")

LeftGroupBox:AddToggle("MyToggle", {
	Text = "This is a toggle",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Default = true,
	Disabled = false,
	Visible = true,
	Risky = false,
	Callback = function(Value)
		print("[cb] MyToggle changed to:", Value)
	end,
}):AddColorPicker("ColorPicker1", {
	Default = Color3.new(1, 0, 0),
	Title = "Some color1",
	Transparency = 0,
	Callback = function(Value, Transparency)
		print("[cb] Color changed!", Value, "| Transparency changed to:", Transparency)
	end,
}):AddColorPicker("ColorPicker2", {
	Default = Color3.new(0, 1, 0),
	Title = "Some color2",
	Transparency = 0,
	Callback = function(Value, Transparency)
		print("[cb] Color changed!", Value, "| Transparency changed to:", Transparency)
	end,
}):AddColorPicker("ColorPicker3", {
	Default = Color3.new(0, 0, 1),
	Title = "Some color3",
	Transparency = 0,
	Callback = function(Value, Transparency)
		print("[cb] Color changed!", Value, "| Transparency changed to:", Transparency)
	end,
})

Toggles.MyToggle:OnChanged(function()
	print("MyToggle changed to:", Toggles.MyToggle.Value)
end)

Toggles.MyToggle:SetValue(false)

local MyButton = LeftGroupBox:AddButton({
	Text = "Button",
	Func = function()
		print("You clicked a button!")
		Library:Notify("This is a notification")
	end,
	DoubleClick = false,
	Tooltip = "This is the main button",
	DisabledTooltip = "I am disabled!",
	Disabled = false,
	Visible = true,
})

local MyButton2 = MyButton:AddButton({
	Text = "Sub button",
	Func = function()
		print("You clicked a sub button!")
		Library:Notify("This is a notification with sound", nil, 4590657391)
	end,
	DoubleClick = true,
	Tooltip = "This is the sub button (double click me!)",
})

local MyDisabledButton = LeftGroupBox:AddButton({
	Text = "Disabled Button",
	Func = function()
		print("You somehow clicked a disabled button!")
	end,
	DoubleClick = false,
	Tooltip = "This is a disabled button",
	DisabledTooltip = "I am disabled!",
	Disabled = true,
})

LeftGroupBox:AddLabel("This is a label")
LeftGroupBox:AddLabel("This is a label\n\nwhich wraps its text!", true)
LeftGroupBox:AddLabel("This is a label exposed to Labels", true, "TestLabel")
LeftGroupBox:AddLabel("SecondTestLabel", {
	Text = "This is a label made with table options and an index",
	DoesWrap = true,
})
LeftGroupBox:AddLabel("SecondTestLabel", {
	Text = "This is a label that doesn\"t wrap it\"s own text",
	DoesWrap = false,
})

LeftGroupBox:AddDivider()

LeftGroupBox:AddSlider("MySlider", {
	Text = "This is my slider!",
	Default = 0,
	Min = 0,
	Max = 5,
	Rounding = 1,
	Compact = false,
	Callback = function(Value)
		print("[cb] MySlider was changed! New value:", Value)
	end,
	Tooltip = "I am a slider!",
	DisabledTooltip = "I am disabled!",
	Disabled = false,
	Visible = true,
})

local Number = Options.MySlider.Value

Options.MySlider:OnChanged(function()
	print("MySlider was changed! New value:", Options.MySlider.Value)
end)

Options.MySlider:SetValue(3)

LeftGroupBox:AddSlider("MySlider2", {
	Text = "This is my custom display slider!",
	Default = 0,
	Min = 0,
	Max = 5,
	Rounding = 1,
	Compact = false,
	FormatDisplayValue = function(slider, value)
		if value == slider.Max then return "Everything" end
		if value == slider.Min then return "Nothing" end
	end,
	Tooltip = "I am a slider!",
	DisabledTooltip = "I am disabled!",
	Disabled = false,
	Visible = true,
})

LeftGroupBox:AddInput("MyTextbox", {
	Default = "My textbox!",
	Numeric = false,
	Finished = false,
	ClearTextOnFocus = true,
	Text = "This is a textbox",
	Tooltip = "This is a tooltip",
	Placeholder = "Placeholder text",
	Callback = function(Value)
		print("[cb] Text updated. New text:", Value)
	end,
})

Options.MyTextbox:OnChanged(function()
	print("Text updated. New text:", Options.MyTextbox.Value)
end)

local DropdownGroupBox = Tabs.Main:AddRightGroupbox("Dropdowns")

DropdownGroupBox:AddDropdown("MyDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = false,
	Text = "A dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Searchable = false,
	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

Options.MyDropdown:OnChanged(function()
	print("Dropdown got changed. New value:", Options.MyDropdown.Value)
end)

Options.MyDropdown:SetValue("This")

DropdownGroupBox:AddDropdown("MySearchableDropdown", {
	Values = { "This", "is", "a", "searchable", "dropdown" },
	Default = 1,
	Multi = false,
	Text = "A searchable dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Searchable = true,
	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyDisplayFormattedDropdown", {
	Values = { "This", "is", "a", "formatted", "dropdown" },
	Default = 1,
	Multi = false,
	Text = "A display formatted dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	FormatDisplayValue = function(Value)
		if Value == "formatted" then
			return "display formatted"
		end

		return Value
	end,
	Searchable = false,
	Callback = function(Value)
		print("[cb] Display formatted dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyMultiDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = true,
	Text = "A multi dropdown",
	Tooltip = "This is a tooltip",
	Callback = function(Value)
		print("[cb] Multi dropdown got changed:")
		for key, value in next, Options.MyMultiDropdown.Value do
			print(key, value)
		end
	end,
})

Options.MyMultiDropdown:SetValue({
	This = true,
	is = true,
})

DropdownGroupBox:AddDropdown("MyDisabledDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = false,
	Text = "A disabled dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Callback = function(Value)
		print("[cb] Disabled dropdown got changed. New value:", Value)
	end,
	Disabled = true,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyDisabledValueDropdown", {
	Values = { "This", "is", "a", "dropdown", "with", "disabled", "value" },
	DisabledValues = { "disabled" },
	Default = 1,
	Multi = false,
	Text = "A dropdown with disabled value",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Callback = function(Value)
		print("[cb] Dropdown with disabled value got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyVeryLongDropdown", {
	Values = { "This", "is", "a", "very", "long", "dropdown", "with", "a", "lot", "of", "values", "but", "you", "can", "see", "more", "than", "8", "values" },
	Default = 1,
	Multi = false,
	MaxVisibleDropdownItems = 12,
	Text = "A very long dropdown",
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Searchable = false,
	Callback = function(Value)
		print("[cb] Very long dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

DropdownGroupBox:AddDropdown("MyPlayerDropdown", {
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Text = "A player dropdown",
	Tooltip = "This is a tooltip",
	Callback = function(Value)
		print("[cb] Player dropdown got changed:", Value)
	end,
})

DropdownGroupBox:AddDropdown("MyTeamDropdown", {
	SpecialType = "Team",
	Text = "A team dropdown",
	Tooltip = "This is a tooltip",
	Callback = function(Value)
		print("[cb] Team dropdown got changed:", Value)
	end,
})

LeftGroupBox:AddLabel("Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0),
	Title = "Some color",
	Transparency = 0,
	Callback = function(Value)
		print("[cb] Color changed!", Value)
	end,
})

Options.ColorPicker:OnChanged(function()
	print("Color changed!", Options.ColorPicker.Value)
	print("Transparency changed!", Options.ColorPicker.Transparency)
end)

Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

LeftGroupBox:AddLabel("Keybind"):AddKeyPicker("KeyPicker", {
	Default = "MB2",
	SyncToggleState = false,
	Mode = "Toggle",
	Text = "Auto lockpick safes",
	NoUI = false,
	Callback = function(Value)
		print("[cb] Keybind clicked!", Value)
	end,
	ChangedCallback = function(NewKey, NewModifiers)
		print("[cb] Keybind changed!", NewKey, table.unpack(NewModifiers or {}))
	end,
})

Options.KeyPicker:OnClick(function()
	print("Keybind clicked!", Options.KeyPicker:GetState())
end)

Options.KeyPicker:OnChanged(function()
	print("Keybind changed!", Options.KeyPicker.Value, table.unpack(Options.KeyPicker.Modifiers or {}))
end)

task.spawn(function()
	while task.wait(1) do
		if Library.Unloaded then break end

		local state = Options.KeyPicker:GetState()
		if state then
			print("KeyPicker is being held down")
		end
	end
end)

Options.KeyPicker:SetValue({ "MB2", "Hold" })

local KeybindNumber = 0

LeftGroupBox:AddLabel("Press Keybind"):AddKeyPicker("KeyPicker2", {
	Default = "X",
	Mode = "Press",
	WaitForCallback = false,
	Text = "Increase Number",
	Callback = function()
		KeybindNumber = KeybindNumber + 1
		print("[cb] Keybind clicked! Number increased to:", KeybindNumber)
	end,
})

LeftGroupBox:AddDropdown("MyDropdown2", {
	Text = "Compact Dropdown",
	Values = { "Addon", "Dropdown" },
	Default = 1,
	Multi = false,
	Tooltip = "This is a tooltip",
	DisabledTooltip = "I am disabled!",
	Searchable = false,
	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end,
	Disabled = false,
	Visible = true,
})

local LeftGroupBox2 = Tabs.Main:AddLeftGroupbox("Groupbox #2")
LeftGroupBox2:AddLabel("Oh no...\nThis label spans multiple lines!\n\nWe\'re gonna run out of UI space...\nJust kidding! Scroll down!\n\n\nHello from below!", true)

local TabBox = Tabs.Main:AddRightTabbox()

local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

local RightGroupbox = Tabs.Main:AddRightGroupbox("Groupbox #3")
RightGroupbox:AddToggle("ControlToggle", { Text = "Dependency box toggle" })

local Depbox = RightGroupbox:AddDependencyBox()
Depbox:AddToggle("DepboxToggle", { Text = "Sub-dependency box toggle" })

local SubDepbox = Depbox:AddDependencyBox()
SubDepbox:AddSlider("DepboxSlider", { Text = "Slider", Default = 50, Min = 0, Max = 100, Rounding = 0 })
SubDepbox:AddDropdown("DepboxDropdown", { Text = "Dropdown", Default = 1, Values = { "a", "b", "c" } })

local SecretDepbox = SubDepbox:AddDependencyBox()
SecretDepbox:AddLabel("You found a secret!")

Depbox:SetupDependencies({
	{ Toggles.ControlToggle, true },
})

SubDepbox:SetupDependencies({
	{ Toggles.DepboxToggle, true },
})

SecretDepbox:SetupDependencies({
	{ Options.DepboxDropdown, "c" },
})

-- Dependency binding:
-- This mini window is only visible while the Depbox above is visible, so it
-- appears when "Dependency box toggle" is enabled.
local DependencyMiniWindow = Depbox:AddMiniWindow({
	Title = "silly.lua | Dependency Mini",
	Size = UDim2.fromOffset(340, 360),
	Position = UDim2.fromOffset(60, 500),
})

local DependencyMiniTab = DependencyMiniWindow:AddTab("Dependency")
DependencyMiniTab:AddLeftGroupbox("Dependency Mini"):AddLabel("This mini window follows the dependency box.\nEnable \"Dependency box toggle\" to show it.", true)

-- Sub tabs:
-- Tab:AddSubTab(Name) returns a sub tab with its own left and right columns.
-- Use SubTab:AddLeftGroupbox / AddRightGroupbox / AddLeftTabbox / AddRightTabbox.
-- The first sub tab is shown automatically. Sub tabs work in mini windows too.
local SubTabsTab = Tabs["Sub Tabs"]

local CombatSubTab = SubTabsTab:AddSubTab("Combat")
local CombatGroupbox = CombatSubTab:AddLeftGroupbox("Combat options")
CombatGroupbox:AddLabel("Each sub tab has its own left and right columns.")
CombatGroupbox:AddToggle("SubCombatToggle", {
	Text = "Aim assist",
	Default = true,
	Callback = function(Value)
		print("[cb] Aim assist:", Value)
	end,
})
CombatGroupbox:AddSlider("SubCombatFOV", {
	Text = "FOV",
	Default = 90,
	Min = 30,
	Max = 180,
	Rounding = 0,
	Suffix = "°",
})

local CombatRight = CombatSubTab:AddRightGroupbox("Combat targets")
CombatRight:AddDropdown("SubCombatTarget", {
	Text = "Target part",
	Values = { "Head", "Torso", "Random" },
	Default = 1,
})

local VisualSubTab = SubTabsTab:AddSubTab("Visuals")
local VisualGroupbox = VisualSubTab:AddLeftGroupbox("Visual options")
VisualGroupbox:AddToggle("SubVisualToggle", { Text = "Full bright", Default = false })
VisualGroupbox:AddLabel("Accent"):AddColorPicker("SubVisualColor", {
	Default = Color3.fromRGB(147, 161, 254),
	Title = "Sub tab accent",
})
VisualSubTab:AddRightGroupbox("Other visuals"):AddLabel("Right side content for the Visuals sub tab.")

local MiscSubTab = SubTabsTab:AddSubTab("Misc")
local MiscGroupbox = MiscSubTab:AddLeftGroupbox("Misc options")
MiscGroupbox:AddButton({
	Text = "Sub tab notification",
	Func = function()
		Library:Notify("Hello from a sub tab!")
	end,
})
MiscGroupbox:AddInput("SubMiscInput", {
	Text = "A sub tab textbox",
	Default = "Hello!",
	Placeholder = "Type something",
})
MiscGroupbox:AddDivider()
MiscGroupbox:AddLabel("Sub tabs work in the main window and in every mini window.", true)

-- Mini windows:
-- A mini window is a second Window created with Config.Mini = true.
-- It supports every tab, sub tab, groupbox and element the main window does,
-- has its own close button, drags by its title bar and resizes with its grip.
--
-- Bind one to a toggle:
--   Toggle:AddMiniWindow({ Title = ..., Size = ..., Position = ... })
-- Bind one to a button (the button toggles it):
--   Button:AddMiniWindow(...)
-- Bind one to a dependency box (it follows the box visibility):
--   Depbox:AddMiniWindow(...)
-- Or create one manually:
--   Library:CreateMiniWindow({ Title = ... })
local MiniGroupbox = Tabs["Mini Windows"]:AddLeftGroupbox("Toggle-bound mini window")
local MiniToggle = MiniGroupbox:AddToggle("MiniWindowToggle", {
	Text = "Open the mini window",
	Default = false,
	Callback = function(Value)
		print("[cb] Mini window toggle:", Value)
	end,
})

local MiniWindow = MiniToggle:AddMiniWindow({
	Title = "silly.lua | Mini",
	Size = UDim2.fromOffset(380, 430),
	Position = UDim2.fromOffset(60, 80),
})

local MiniTab = MiniWindow:AddTab("Mini")
local MiniLeft = MiniTab:AddLeftGroupbox("All components")
MiniLeft:AddLabel("This is a full second window.\nIt has its own tabs and every library element.", true)
MiniLeft:AddToggle("MiniToggleDemo", {
	Text = "A mini toggle",
	Default = true,
})
MiniLeft:AddSlider("MiniSliderDemo", {
	Text = "A mini slider",
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
})
MiniLeft:AddInput("MiniInputDemo", {
	Text = "A mini textbox",
	Default = "Hello from the mini window!",
	Placeholder = "Type here",
})
MiniLeft:AddDropdown("MiniDropdownDemo", {
	Text = "A mini dropdown",
	Values = { "One", "Two", "Three" },
	Default = 1,
	Searchable = true,
})
MiniLeft:AddButton({
	Text = "Mini notification",
	Func = function()
		Library:Notify("Hello from the mini window!")
	end,
})
MiniLeft:AddLabel("Accent"):AddColorPicker("MiniColorPicker", {
	Default = Color3.fromRGB(147, 161, 254),
	Title = "Mini accent",
})
MiniLeft:AddLabel("Keybind"):AddKeyPicker("MiniKeyPicker", {
	Default = "Z",
	Mode = "Press",
	Text = "Mini keybind",
})
MiniLeft:AddDivider()

local MiniRight = MiniTab:AddRightGroupbox("Mini groupbox")
MiniRight:AddLabel("The mini window has a corner grip.\nDrag its edges to resize it.", true)
MiniRight:AddLabel("Its title bar is draggable too.")

local MiniTab2 = MiniWindow:AddTab("More")
MiniTab2:AddLeftGroupbox("Second mini tab"):AddLabel("Mini windows support multiple tabs.")

local MiniSubTab = MiniWindow:AddTab("Mini Sub Tabs")
local MiniSub1 = MiniSubTab:AddSubTab("First")
MiniSub1:AddLeftGroupbox("Mini sub tab"):AddLabel("Sub tabs work inside mini windows as well.")
MiniSub1:AddToggle("MiniSubToggle", { Text = "A mini sub tab toggle", Default = true })
local MiniSub2 = MiniSubTab:AddSubTab("Second")
MiniSub2:AddRightGroupbox("Second mini sub tab"):AddLabel("Another mini sub tab.")

local ButtonMiniGroupbox = Tabs["Mini Windows"]:AddRightGroupbox("Button-bound mini window")
ButtonMiniGroupbox:AddLabel("Clicking the button below opens or closes its mini window.", true)
local ButtonMiniButton = ButtonMiniGroupbox:AddButton({
	Text = "Toggle button mini window",
	Func = function()
		Library:Notify("Button mini window toggled")
	end,
})

local ButtonMiniWindow = ButtonMiniButton:AddMiniWindow({
	Title = "silly.lua | Button Mini",
	Size = UDim2.fromOffset(340, 380),
	Position = UDim2.fromOffset(470, 80),
})

ButtonMiniWindow:AddTab("Button"):AddLeftGroupbox("Button Mini"):AddLabel("This window is bound to the button above.")
ButtonMiniWindow:AddTab("Info"):AddLeftGroupbox("Information"):AddLabel("Every mini window is a second window.\nAdd tabs and elements like normal.", true)

local DependencyMiniInfo = Tabs["Mini Windows"]:AddRightGroupbox("Dependency-bound mini window")
DependencyMiniInfo:AddLabel("Open the Main tab and enable \"Dependency box toggle\".\nThe dependency mini window appears with the dependency box.", true)

-- The library renders the silly.lua watermark with live FPS, ping, players
-- and BuildVersion. UI Settings can hide/show it with the Watermark toggle.
Library:OnUnload(function()
	print("Unloaded!")
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(Value)
		Library.KeybindFrame.Visible = Value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

local WatermarkToggle
WatermarkToggle = MenuGroup:AddToggle("ShowWatermark", {
	Text = "Hide Watermark",
	Default = true,
	Callback = function(Value)
		Library:SetWatermarkVisibility(Value)

		if WatermarkToggle then
			WatermarkToggle:SetText(Value and "Hide Watermark" or "Show Watermark")
		end
	end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})

-- Live DPI / scale control. This is optional; the source line near the top
-- is the simplest way to set the DPI for your script.
local DPIScales = {
	["75%"] = 0.75,
	["90%"] = 0.9,
	["100%"] = 1,
	["110%"] = 1.1,
	["125%"] = 1.25,
	["150%"] = 1.5,
}

MenuGroup:AddDropdown("MenuDPI", {
	Text = "Menu DPI / scale",
	Values = { "75%", "90%", "100%", "110%", "125%", "150%" },
	Default = "100%",
	Tooltip = "Scales the menu and every mini window",
	Callback = function(Value)
		Library:SetDPI(DPIScales[Value] or 1)
	end,
})

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Addons:
-- SaveManager saves/loads configs and ThemeManager handles themes.
-- Settings that should not be per-config are ignored below.
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "MenuDPI" })
ThemeManager:SetFolder("silly.lua")
SaveManager:SetFolder("silly.lua/example")
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:BuildConfigSection(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
