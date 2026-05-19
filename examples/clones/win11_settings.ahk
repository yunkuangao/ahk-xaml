#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; WINDOWS 11 SETTINGS CLONE
; Demonstrates Fluent Design, ToggleSwitches, Sliders, and native feel
; ==============================================================================

app := XAML_GUI("Settings", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35, AppIcon: false })

app.tabs.Visibility("Collapsed")
app.main.Background("{DynamicResource ControlBg}")

; Main Layout
layout := app.main.Add("Grid").Grid_Row(1)
layout.Cols("300", "*")

; ==============================================================================
; LEFT NAVIGATION (SIDEBAR)
; ==============================================================================
sidebar := layout.Add("Border").Grid_Column(0).Padding("15,10,15,10").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0")
sidebarSp := sidebar.Add("StackPanel")

; User Profile Header
userProfile := sidebarSp.Add("Grid").Margin("0,0,0,20")
userProfile.Cols("Auto", "*")
userProfile.Add("Ellipse").Width(50).Height(50).Grid_Column(0).Margin("0,0,15,0").SetProp("Fill", "Gray") ; Placeholder for avatar
userInfo := userProfile.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
userInfo.Add("TextBlock").Text("John Doe").Foreground("{DynamicResource TextMain}").FontSize(16).FontWeight("SemiBold")
userInfo.Add("TextBlock").Text("Local Account").Foreground("{DynamicResource TextSub}").FontSize(12)

; Search Box
searchBorder := sidebarSp.Add("Border").CornerRadius("4").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Margin("0,0,0,20")
searchBox := searchBorder.Add("TextBox").Text("Find a setting").Background("{DynamicResource DropdownBg}").Foreground("{DynamicResource TextSub}").BorderThickness("0").Padding("10,6,10,6")

; Navigation List
AddNavItem(sp, icon, label, isSelected := false) {
    bg := isSelected ? "{DynamicResource Accent}" : "Transparent"
    fg := isSelected ? "White" : "{DynamicResource TextMain}"
    op := isSelected ? "1.0" : "0.7"
    item := sp.Add("Border").CornerRadius("4").Background(bg).Padding("10").Margin("0,0,0,5").Cursor("Hand")
    grid := item.Add("Grid")
    grid.Cols("Auto", "*")
    grid.Add("TextBlock").Text(icon).FontFamily("Segoe Fluent Icons").FontSize(16).Foreground(fg).Margin("0,0,15,0").VerticalAlignment("Center").Grid_Column(0)
    grid.Add("TextBlock").Text(label).FontSize(14).Foreground(fg).Opacity(op).VerticalAlignment("Center").Grid_Column(1)
    return item
}

AddNavItem(sidebarSp, Chr(0xE770), "System", true)
AddNavItem(sidebarSp, Chr(0xE702), "Bluetooth & devices")
AddNavItem(sidebarSp, Chr(0xE774), "Network & internet")
AddNavItem(sidebarSp, Chr(0xE771), "Personalization")
AddNavItem(sidebarSp, Chr(0xE713), "Apps")
AddNavItem(sidebarSp, Chr(0xE779), "Accounts")
AddNavItem(sidebarSp, Chr(0xE74C), "Windows Update")

; ==============================================================================
; RIGHT CONTENT AREA (SYSTEM SETTINGS)
; ==============================================================================
scrollArea := layout.Add("ScrollViewer").Grid_Column(1).Padding("30")
contentSp := scrollArea.Add("StackPanel")

; Header
headerGrid := contentSp.Add("Grid").Margin("0,0,0,20")
headerGrid.Add("TextBlock").Text("System").FontSize(32).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}")

; System Info Card
sysInfoCard := contentSp.Add("Border").CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("20").Margin("0,0,0,20")
sysInfoGrid := sysInfoCard.Add("Grid")
sysInfoGrid.Cols("Auto", "*")
sysInfoGrid.Add("TextBlock").Text(Chr(0xE7F8)).FontFamily("Segoe Fluent Icons").FontSize(48).Foreground("{DynamicResource Accent}").Grid_Column(0).Margin("0,0,20,0").VerticalAlignment("Center")
sysInfoText := sysInfoGrid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
sysInfoText.Add("TextBlock").Text("Desktop-PC-01").FontSize(20).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}")
sysInfoText.Add("TextBlock").Text("Windows 11 Pro").FontSize(14).Foreground("{DynamicResource TextSub}")

; Setting Item Helper
AddSettingCard(parent, icon, title, desc, controlType, name) {
    card := parent.Add("Border").CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,10,15,10").Margin("0,0,0,10")
    grid := card.Add("Grid")
    grid.Cols("Auto", "*", "Auto")
    grid.Add("TextBlock").Text(icon).FontFamily("Segoe Fluent Icons").FontSize(18).Foreground("{DynamicResource TextMain}").Grid_Column(0).Margin("0,0,15,0").VerticalAlignment("Center")
    
    texts := grid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
    texts.Add("TextBlock").Text(title).FontSize(14).Foreground("{DynamicResource TextMain}")
    if (desc != "")
        texts.Add("TextBlock").Text(desc).FontSize(12).Foreground("{DynamicResource TextSub}").Margin("0,2,0,0")
        
    ctrlArea := grid.Add("StackPanel").Grid_Column(2).VerticalAlignment("Center")
    
    if (controlType == "Toggle") {
        ctrlArea.Add("ToggleButton").Name(name).Content("On").IsChecked("True").Width(50).Height(24).Cursor("Hand")
    } else if (controlType == "Slider") {
        ctrlArea.Add("Slider").Name(name).Width(150).Minimum(0).Maximum(100).Value(50)
    } else if (controlType == "Button") {
        ctrlArea.Add("Button").Name(name).Content("Open").Padding("15,5,15,5")
    }
    
    return card
}

contentSp.Add("TextBlock").Text("Display").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")
AddSettingCard(contentSp, Chr(0xE793), "Night light", "Use warmer colors to help block blue light", "Toggle", "TglNightLight")
AddSettingCard(contentSp, Chr(0xE706), "Brightness", "Adjust the brightness of the built-in display", "Slider", "SldBrightness")

contentSp.Add("TextBlock").Text("Sound").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,20,0,10")
AddSettingCard(contentSp, Chr(0xE767), "Volume", "Adjust the system volume", "Slider", "SldVolume")
AddSettingCard(contentSp, Chr(0xE710), "Add a new output device", "", "Button", "BtnAddDevice")


ui := app.Compile()

ui.OnEvent("TglNightLight", "Click", HandleNightLight)
HandleNightLight(state, *) {
    isChecked := state["TglNightLight"]
    MsgBox("Night light turned " (isChecked == "True" ? "On" : "Off"), "Settings Triggered", 64)
}

ui.OnEvent("BtnAddDevice", "Click", HandleAddDevice)
HandleAddDevice(*) {
    XDialog.Show({ Title: "Add Device", Message: "Searching for audio devices...", Icon: Chr(0xE710), Buttons: ["Cancel"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" })
}

app.Show()
