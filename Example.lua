-- This example mirrors the upstream demo menu, using the elements and options
-- this fork implements. The reference example lives at:
-- https://raw.githubusercontent.com/sickletone/unnamed/main/Example.lua
--
-- Point `repo` at wherever this fork's Library.lua and addons/ are hosted.
local repo = 'https://raw.githubusercontent.com/sickletone/hgjsvdnbdsnvxhdvsgsvdhskdvjhdjsbjdbdisvshbsuvabaababbababHahbbshsvsjsvsuvssvhsvejejsvisvshsvehgsshvs/main/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Options = getgenv().Options
local Toggles = getgenv().Toggles

local Window = Library:CreateWindow({
	-- Set Center to true if you want the menu to appear in the center
	-- Set AutoShow to true if you want the menu to appear when it is created
	-- Position and Size are also valid options here
	-- Resizing is always available: drag any window edge or the bottom-right grip

	Title = "Example menu",
	Center = true,
	AutoShow = true,
	TabPadding = 8,
	MenuFadeTime = 0.2
})

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

-- You do not have to set your tabs & groups up this way, just a preference.
local Tabs = {
	-- Creates a new tab titled Main
	Main = Window:AddTab("Main"),
	["UI Settings"] = Window:AddTab("UI Settings"),
}

-- Groupbox and Tabbox inherit the same functions
-- except Tabboxes you have to call the functions on a tab (Tabbox:AddTab(name))
local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Groupbox")

-- We can also get our Main tab via the following code:
-- local LeftGroupBox = Window.Tabs.Main:AddLeftGroupbox("Groupbox")

-- Tabboxes are a tiny bit different, but here's a basic example:
--[[

local TabBox = Tabs.Main:AddLeftTabbox() -- Add Tabbox on left side

local Tab1 = TabBox:AddTab("Tab 1")
local Tab2 = TabBox:AddTab("Tab 2")

-- You can now call AddToggle, etc on the tabs you added to the Tabbox
]]

-- Groupbox:AddToggle
-- Arguments: Index, Options
LeftGroupBox:AddToggle("MyToggle", {
	Text = "This is a toggle",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the toggle

	Default = true, -- Default value (true / false)
	Risky = false, -- Makes the text red (the color can be changed using Library.RiskColor) (Default value = false)

	Callback = function(Value)
		print("[cb] MyToggle changed to:", Value)
	end
}):AddColorPicker("ColorPicker1", {
	Default = Color3.new(1, 0, 0),
	Title = "Some color1", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker

	Callback = function(Value)
		print("[cb] Color changed!", Value)
	end
}):AddColorPicker("ColorPicker2", {
	Default = Color3.new(0, 1, 0),
	Title = "Some color2",
	Transparency = 0,

	Callback = function(Value)
		print("[cb] Color changed!", Value)
	end
}):AddColorPicker("ColorPicker3", {
	Default = Color3.new(0, 0, 1),
	Title = "Some color3",
	Transparency = 0,

	Callback = function(Value)
		print("[cb] Color changed!", Value)
	end
})

-- Fetching a toggle object for later use:
-- Toggles.MyToggle.Value

-- Toggles is a table added to getgenv() by the library
-- You index Toggles with the specified index, in this case it is "MyToggle"
-- To get the state of the toggle you do Toggles.MyToggle.Value

-- Calls the passed function when the toggle is updated
Toggles.MyToggle:OnChanged(function()
	print("MyToggle changed to:", Toggles.MyToggle.Value)
end)

-- This should print to the console: "MyToggle state changed! New value: false"
Toggles.MyToggle:SetValue(false)

LeftGroupBox:AddToggle("DisabledToggle", {
	Text = "This toggle is disabled",
	Default = true,
	Disabled = true,
	DisabledTooltip = "I am disabled!",
})

--[[
	Groupbox:AddButton
	Arguments: {
		Text = string,
		Func = function,
		DoubleClick = boolean,
		Tooltip = string,
	}

	You can call :AddButton on a button to add a SubButton!
]]

local MyButton = LeftGroupBox:AddButton({
	Text = "Button",
	Func = function()
		print("You clicked a button!")
		Library:Notify("This is a notification")
	end,
	DoubleClick = false,

	Tooltip = "This is the main button",
})

local MyDisabledButton = LeftGroupBox:AddButton({
	Text = "Disabled button",
	Func = function()
		print("You somehow clicked a disabled button!")
	end,
	Disabled = true,
	Tooltip = "This is a disabled button",
	DisabledTooltip = "I am disabled!",
})

local MyButton2 = MyButton:AddButton({
	Text = "Sub button",
	Func = function()
		print("You clicked a sub button!")
		Library:Notify("This is a notification with a longer duration", 3)
	end,
	DoubleClick = true, -- You will have to click this button twice to trigger the callback
	Tooltip = "This is the sub button (double click me!)"
})

--[[
	NOTE: You can chain the button methods!
	EXAMPLE:

	LeftGroupBox:AddButton({ Text = "Kill all", Func = Functions.KillAll, Tooltip = "This will kill everyone in the game!" })
		:AddButton({ Text = "Kick all", Func = Functions.KickAll, Tooltip = "This will kick everyone in the game!" })
]]

-- Groupbox:AddLabel
-- Arguments: Text, DoesWrap
LeftGroupBox:AddLabel("This is a label")
LeftGroupBox:AddLabel("This is a label\n\nwhich wraps its text!", true)

-- AddLabel returns the label object, so you can update it later with :SetText
local StatusLabel = LeftGroupBox:AddLabel("This label gets updated below")
StatusLabel:SetText("This label was updated with :SetText")

-- Groupbox:AddDivider
-- Arguments: None
LeftGroupBox:AddDivider()

--[[
	Groupbox:AddSlider
	Arguments: Idx, SliderOptions

	SliderOptions: {
		Text = string,
		Default = number,
		Min = number,
		Max = number,
		Suffix = string,
		Rounding = number,
		Compact = boolean,
		HideMax = boolean,
	}

	Text, Default, Min, Max, Rounding must be specified.
	Suffix is optional.
	Rounding is the number of decimal places for precision.

	Compact will hide the title label of the Slider
	HideMax will only display the value instead of the value & max value of the slider
]]
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

	Tooltip = "I am a slider!", -- Information shown when you hover over the slider
})

-- Options is a table added to getgenv() by the library
-- You index Options with the specified index, in this case it is "MySlider"
-- To get the value of the slider you do slider.Value

local Number = Options.MySlider.Value
Options.MySlider:OnChanged(function()
	print("MySlider was changed! New value:", Options.MySlider.Value)
end)

-- This should print to the console: "MySlider was changed! New value: 3"
Options.MySlider:SetValue(3)

LeftGroupBox:AddSlider("MySlider2", {
	Text = "This is my compact slider!",
	Default = 0,
	Min = 0,
	Max = 5,
	Rounding = 1,
	Suffix = "s",
	Compact = true, -- Shows the label and value on the bar instead of above it
	HideMax = false,

	Tooltip = "I am a compact slider!",
})

LeftGroupBox:AddSlider("MyRatingSlider", {
	Text = "Rate this menu",
	Default = 3,
	Min = 1,
	Max = 5,
	Rounding = 0,

	FormatDisplayValue = function(slider, value)
		if value == slider.Min then return "Terrible" end
		if value == slider.Max then return "Amazing" end
	end,
})

-- Groupbox:AddInput
-- Arguments: Idx, Info
LeftGroupBox:AddInput("MyTextbox", {
	Default = "My textbox!",
	Numeric = false, -- true / false, only allows numbers
	Finished = false, -- true / false, only calls callback when you press enter

	Text = "This is a textbox",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the textbox

	Placeholder = "Placeholder text", -- placeholder text when the box is empty
	MaxLength = 64, -- Max length of the text

	Callback = function(Value)
		print("[cb] Text updated. New text:", Value)
	end
})

Options.MyTextbox:OnChanged(function()
	print("Text updated. New text:", Options.MyTextbox.Value)
end)

-- Groupbox:AddDropdown
-- Arguments: Idx, Info

local DropdownGroupBox = Tabs.Main:AddRightGroupbox("Dropdowns")

DropdownGroupBox:AddDropdown("MyDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1, -- number index of the value / string
	Multi = false, -- true / false, allows multiple choices to be selected

	Text = "A dropdown",
	Tooltip = "This is a tooltip", -- Information shown when you hover over the dropdown

	Callback = function(Value)
		print("[cb] Dropdown got changed. New value:", Value)
	end
})

Options.MyDropdown:OnChanged(function()
	print("Dropdown got changed. New value:", Options.MyDropdown.Value)
end)

Options.MyDropdown:SetValue("This")

-- Multi dropdowns
DropdownGroupBox:AddDropdown("MyMultiDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Multi = true, -- true / false, allows multiple choices to be selected

	Text = "A multi dropdown",
	Tooltip = "This is a tooltip",

	Callback = function(Value)
		print("[cb] Multi dropdown got changed:")
		for Key, Selected in next, Options.MyMultiDropdown.Value do
			print(Key, Selected) -- should print something like This, true
		end
	end
})

Options.MyMultiDropdown:SetValue({
	This = true,
	is = true,
})

-- Special dropdowns are filled from the player / team list and refresh automatically
DropdownGroupBox:AddDropdown("MyPlayerDropdown", {
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Text = "A player dropdown",
	Tooltip = "This is a tooltip",

	Callback = function(Value)
		print("[cb] Player dropdown got changed:", Value)
	end
})

DropdownGroupBox:AddDropdown("MyTeamDropdown", {
	SpecialType = "Team",
	Text = "A team dropdown",
	Tooltip = "This is a tooltip",

	Callback = function(Value)
		print("[cb] Team dropdown got changed:", Value)
	end
})

DropdownGroupBox:AddDropdown("MySearchableDropdown", {
	Values = { "This", "is", "a", "searchable", "dropdown" },
	Default = 1,
	Text = "A searchable dropdown",
	Searchable = true,
})

DropdownGroupBox:AddDropdown("MyDisplayDropdown", {
	Values = { "This", "is", "a", "formatted", "dropdown" },
	Default = 1,
	Text = "A display formatted dropdown",

	FormatDisplayValue = function(Value)
		if Value == "formatted" then return "display formatted" end
		return Value
	end,
})

DropdownGroupBox:AddDropdown("MyLongDropdown", {
	Values = { "This", "is", "a", "long", "dropdown", "with", "disabled", "values", "and", "more", "items" },
	Default = 1,
	Text = "A long dropdown",
	DisabledValues = { "disabled" },
	MaxVisibleDropdownItems = 12,
})

DropdownGroupBox:AddDropdown("MyDisabledDropdown", {
	Values = { "This", "is", "a", "dropdown" },
	Default = 1,
	Text = "A disabled dropdown",
	Disabled = true,
})

-- Label:AddColorPicker
-- Arguments: Idx, Info

-- You can also add a ColorPicker & KeyPicker to a Toggle as well
LeftGroupBox:AddLabel("Color"):AddColorPicker("ColorPicker", {
	Default = Color3.new(0, 1, 0),
	Title = "Some color", -- Optional. Allows you to have a custom color picker title (when you open it)
	Transparency = 0, -- Optional. Enables transparency changing for this color picker

	Callback = function(Value)
		print("[cb] Color changed!", Value)
	end
})

Options.ColorPicker:OnChanged(function()
	print("Color changed!", Options.ColorPicker.Value)
end)

Options.ColorPicker:OnTransparencyChanged(function(Transparency)
	print("Transparency changed!", Transparency)
end)

Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140), 0)

-- Label:AddKeyPicker
-- Arguments: Idx, Info
LeftGroupBox:AddLabel("Keybind"):AddKeyPicker("KeyPicker", {
	-- SyncToggleState only works with toggles.
	-- It allows you to make a keybind which has its state synced with its parent toggle
	Default = "MB2", -- String as the name of the keybind (MB1, MB2 for mouse buttons)
	SyncToggleState = false,

	Mode = "Toggle", -- Modes: Always, Toggle, Hold

	Text = "Auto lockpick safes", -- Text to display in the keybind menu
	NoUI = false, -- Set to true if you want to hide from the Keybind menu

	-- Occurs when the keybind is clicked, Value is `true`/`false`
	Callback = function(Value)
		print("[cb] Keybind clicked!", Value)
	end,

	-- Occurs when the keybind itself is changed, `NewKey` is a KeyCode Enum or a UserInputType Enum
	ChangedCallback = function(NewKey)
		print("[cb] Keybind changed!", NewKey)
	end,
})

-- OnClick is only fired when you press the keybind and the mode is Toggle
-- Otherwise, you will have to use Keybind:GetState()
Options.KeyPicker:OnClick(function()
	print("Keybind clicked!", Options.KeyPicker:GetState())
end)

Options.KeyPicker:OnChanged(function()
	print("Keybind changed!", Options.KeyPicker.Value, Options.KeyPicker.Mode)
end)

task.spawn(function()
	while task.wait(1) do
		-- example for checking if a keybind is being pressed
		local State = Options.KeyPicker:GetState()
		if State then
			print("KeyPicker is being held down")
		end

		if Library.Unloaded then break end
	end
end)

Options.KeyPicker:SetValue({ "MB2", "Hold" }) -- Sets keybind to MB2, mode to Hold

LeftGroupBox:AddLabel("Press Keybind"):AddKeyPicker("KeyPicker2", {
	Default = "X",
	Mode = "Press",
	Text = "Increase number",
	WaitForCallback = false,

	Callback = function()
		print("[cb] Press keybind clicked!")
	end,
})

Options.KeyPicker2:OnChanged(function(Value, Modifiers)
	print("Press keybind changed!", Value, table.unpack(Modifiers or {}))
end)

-- Long text label to demonstrate UI scrolling behaviour.
local LeftGroupBox2 = Tabs.Main:AddLeftGroupbox("Groupbox #2")
LeftGroupBox2:AddLabel("Oh no...\nThis label spans multiple lines!\n\nWe are gonna run out of UI space...\nJust kidding! Scroll down!\n\n\nHello from below!", true)

local TabBox = Tabs.Main:AddRightTabbox() -- Add Tabbox on right side

-- Anything we can do in a Groupbox, we can do in a Tabbox tab (AddToggle, AddSlider, AddLabel, etc etc...)
local Tab1 = TabBox:AddTab("Tab 1")
Tab1:AddToggle("Tab1Toggle", { Text = "Tab1 Toggle" })

local Tab2 = TabBox:AddTab("Tab 2")
Tab2:AddToggle("Tab2Toggle", { Text = "Tab2 Toggle" })

-- Dependency boxes let us control the visibility of UI elements depending on another UI elements state.
-- e.g. we have a "Feature Enabled" toggle, and we only want to show that features sliders, dropdowns etc when it's enabled!
local RightGroupbox = Tabs.Main:AddRightGroupbox("Groupbox #3")
RightGroupbox:AddToggle("ControlToggle", { Text = "Dependency box toggle" })

local Depbox = RightGroupbox:AddDependencyBox()
Depbox:AddToggle("DepboxToggle", { Text = "Sub-dependency box toggle" })

-- We can also nest dependency boxes!
-- When we do this, our SubDepbox is hidden together with its parent, on top of whatever
-- additional dependencies we set.
local SubDepbox = Depbox:AddDependencyBox()
SubDepbox:AddSlider("DepboxSlider", { Text = "Slider", Default = 50, Min = 0, Max = 100, Rounding = 0 })
SubDepbox:AddDropdown("DepboxDropdown", { Text = "Dropdown", Default = 1, Values = { "a", "b", "c" } })
SubDepbox:AddToggle("SecretToggle", { Text = "Reveal the secret" })

local SecretDepbox = SubDepbox:AddDependencyBox()
SecretDepbox:AddLabel("You found a secret!")

Depbox:SetupDependencies({
	{ Toggles.ControlToggle, true } -- We can also pass `false` if we only want our features to show when the toggle is off!
})

SubDepbox:SetupDependencies({
	{ Toggles.DepboxToggle, true }
})

SecretDepbox:SetupDependencies({
	{ Toggles.SecretToggle, true }
})

-- Library functions
-- The watermark shows silly.lua, your fps, ping, player count and the build version by default.
-- Call Library:SetWatermark("custom text") if you would rather show your own text.
Library:SetWatermarkVisibility(true)

Library:OnUnload(function()
	print("Unloaded!")
	Library.Unloaded = true
end)

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(Value) Library.KeybindFrame.Visible = Value end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = Library.CursorEnabled, Callback = function(Value) Library.CursorEnabled = Value; Library:SetCursorEnabled(Library.Toggled) end })
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we don't want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs["UI Settings"])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
