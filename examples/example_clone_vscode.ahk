#Requires AutoHotkey v2.0
#Include "..\lib\XAML_GUI.ahk"
#Include "..\lib\XAML_Adv_Components.ahk"

; Initialize App with a dark theme structure
app := XAML_GUI("VS Code Clone - AHK-XAML", { BurgerMenu: false })

; Hide default TabControl since we are building a custom layout
app.tabs.Visibility("Collapsed")

; Set the background of the main area to match VS Code dark theme
app.main.Background("{DynamicResource SolidBg}")

; Main Layout Grid
layout := app.main.Add("Grid").Grid_Row(1)
layout.Rows("*", "22") ; Main area, Status bar

; Main Area Splitter
mainArea := layout.Add("Grid").Grid_Row(0)
mainArea.Cols("50", "Auto", "*")

; 1. Activity Bar (Far Left)
activityBarBorder := mainArea.Add("Border").Grid_Column(0).Background("{DynamicResource SolidControl}").BorderBrush("{DynamicResource SolidBorder}").BorderThickness("0,0,1,0")
activityBar := activityBarBorder.Add("Grid")
activitySp := activityBar.Add("StackPanel").Margin("0,10,0,0").VerticalAlignment("Top")

AddActivityIcon(sp, iconHex, name, isActive := false) {
    btn := sp.Add("Button").Name(name).Content(Chr(iconHex)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(24).Margin("0,10")
    btn.Background("Transparent").BorderThickness("2,0,0,0").Foreground(isActive ? "{DynamicResource TextMain}" : "{DynamicResource TextSub}")
    btn.BorderBrush(isActive ? "{DynamicResource TextMain}" : "Transparent")
    btn.Cursor("Hand")
    
    ; Define Template
    tpl := btn.Add("Button.Template").Add("ControlTemplate").TargetType("Button")
    bdr := tpl.Add("Border").Background("{TemplateBinding Background}").BorderBrush("{TemplateBinding BorderBrush}").BorderThickness("{TemplateBinding BorderThickness}")
    bdr.Add("ContentPresenter").HorizontalAlignment("Center").VerticalAlignment("Center")
    
    ; Hover style
    style := btn.Add("Button.Style").Add("Style").TargetType("Button")
    t := style.Add("Style.Triggers").Add("Trigger").Property("IsMouseOver").Value("True")
    t.Add("Setter").Property("Foreground").Value("{DynamicResource TextMain}")
    return btn
}

AddActivityIcon(activitySp, 0xE814, "BtnActExplorer", true)  ; Explorer
AddActivityIcon(activitySp, 0xE721, "BtnActSearch")        ; Search
AddActivityIcon(activitySp, 0xE90F, "BtnActSourceControl") ; Source Control
AddActivityIcon(activitySp, 0xEBE8, "BtnActRun")           ; Run/Debug
AddActivityIcon(activitySp, 0xE718, "BtnActExtensions")    ; Extensions

; Bottom Activity Icons
activityBottom := activityBar.Add("StackPanel").VerticalAlignment("Bottom").Margin("0,0,0,10")
AddActivityIcon(activityBottom, 0xE713, "BtnActSettings")  ; Settings
AddActivityIcon(activityBottom, 0xE77B, "BtnActAccounts")  ; Accounts

; 2. Sidebar (Explorer)
sidebar := mainArea.Add("Border").Name("SidebarPanel").Grid_Column(1).Width("250").Background("{DynamicResource SolidSidebar}").BorderBrush("{DynamicResource SolidBorder}").BorderThickness("0,0,1,0")
sidebarGrid := sidebar.Add("Grid")
sidebarGrid.Rows("Auto", "*")

sidebarGrid.Add("TextBlock").Name("SidebarTitle").Text("EXPLORER").Grid_Row(0).Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("SemiBold").Margin("20,15,0,10")

; Explorer View
sideExplorer := sidebarGrid.Add("StackPanel").Name("View_EXPLORER").Grid_Row(1)
sideExplorer.Add("TextBlock").Text("V AHK-XAML").Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(12).Margin("10,5,0,5")

AddFileNode(sp, indent, iconHex, color, text, name, isSelected := false, isError := false) {
    btn := sp.Add("Button").Name("BtnNode_" name).Background(isSelected ? "{DynamicResource SolidBorder}" : "Transparent").BorderThickness("0").HorizontalContentAlignment("Left").Padding(String(indent) ",4,0,4").Cursor("Hand")
    
    tpl := btn.Add("Button.Template").Add("ControlTemplate").TargetType("Button")
    tpl.Add("Border").Background("{TemplateBinding Background}").Padding("{TemplateBinding Padding}").Add("ContentPresenter")
    
    style := btn.Add("Button.Style").Add("Style").TargetType("Button")
    t := style.Add("Style.Triggers").Add("Trigger").Property("IsMouseOver").Value("True")
    t.Add("Setter").Property("Background").Value("{DynamicResource ControlBgHover}")
    
    panel := btn.Add("StackPanel").Orientation("Horizontal")
    panel.Add("TextBlock").Text(Chr(iconHex)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground(isError ? "{DynamicResource ErrorColor}" : color).FontSize(14).Margin("0,0,8,0").VerticalAlignment("Center")
    
    textColor := isError ? "{DynamicResource ErrorColor}" : (isSelected ? "{DynamicResource TextMain}" : "{DynamicResource TextSub}")
    panel.Add("TextBlock").Name("TxtNode_" name).Text(text).Foreground(textColor).TextDecorations(isError ? "Strikethrough" : "None").VerticalAlignment("Center")
}

AddFileNode(sideExplorer, 20, 0xE8B7, "#E3C93A", "lib", "Folder_Lib")
AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "XAML_GUI.ahk", "XAML_GUI")
AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "XAML_Components.ahk", "XAML_Components", false, true)
AddFileNode(sideExplorer, 20, 0xE8B7, "#E3C93A", "examples", "Folder_Examples")
AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "example_clone_vscode.ahk", "Main", true)
AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "example_clone_chat.ahk", "Chat")
AddFileNode(sideExplorer, 40, 0xE713, "#AAAAAA", "settings.ini", "Settings_Ini")

; Search View
sideSearch := sidebarGrid.Add("StackPanel").Name("View_SEARCH").Grid_Row(1).Visibility("Collapsed").Margin("10,5")
sideSearch.Add("TextBox").Text("Search").Background("{DynamicResource SolidControl}").Foreground("{DynamicResource TextSub}").BorderThickness("1").BorderBrush("{DynamicResource Accent}").Padding("5")

; Source Control View
sideGit := sidebarGrid.Add("StackPanel").Name("View_SOURCE_CONTROL").Grid_Row(1).Visibility("Collapsed").Margin("10,5")
sideGit.Add("TextBlock").Text("No source control providers registered.").Foreground("{DynamicResource TextSub}").TextWrapping("Wrap")

; Run View
sideRun := sidebarGrid.Add("StackPanel").Name("View_RUN_AND_DEBUG").Grid_Row(1).Visibility("Collapsed").Margin("10,5")
sideRun.Add("Button").Content("Run and Debug").Background("{DynamicResource Accent}").Foreground("{DynamicResource TextMain}").Padding("5").BorderThickness("0")

; Extensions View
sideExt := sidebarGrid.Add("StackPanel").Name("View_EXTENSIONS").Grid_Row(1).Visibility("Collapsed").Margin("10,5")
sideExt.Add("TextBox").Text("Search Extensions in Marketplace").Background("{DynamicResource SolidControl}").Foreground("{DynamicResource TextSub}").BorderThickness("1").BorderBrush("Transparent").Padding("5")

; Settings View has been moved to the Editor Area as a Tab

; 3. Editor Area
editorArea := mainArea.Add("Grid").Grid_Column(2)
editorArea.Rows("Auto", "*")

; Tabs Container
topBarGrid := editorArea.Add("Grid").Grid_Row(0).Background("{DynamicResource SolidControl}")
topBarGrid.Cols("*", "Auto")

tabsScroll := topBarGrid.Add("ScrollViewer").Name("tabsScroll").Grid_Column(0).HorizontalScrollBarVisibility("Auto").VerticalScrollBarVisibility("Disabled")
tabsBar := tabsScroll.Add("StackPanel").Orientation("Horizontal")

global currentThemeMap := Map("BgColor", "#1E1E1E", "ControlBg", "#333333", "Accent", "#007ACC", "ControlBorder", "#2D2D2D", "TextMain", "White", "TextSub", "#CCCCCC", "SolidBg", "#1E1E1E", "SolidSidebar", "#252526", "SolidControl", "#333333", "SolidBorder", "#2D2D2D")

AddTab(container, icon, color, text, name, isSelected := false, isVisible := false) {
    bdr := container.Add("Border").Name("BtnTab_" name).Background(isSelected ? "{DynamicResource SolidBg}" : "{DynamicResource SolidControl}").BorderBrush(isSelected ? "{DynamicResource Accent}" : "Transparent").BorderThickness("0,2,0,0").Padding("15,0").Height("35").VerticalAlignment("Top").Cursor("Hand")
    bdr.Visibility(isVisible ? "Visible" : "Collapsed")
    
    sp := bdr.Add("StackPanel").Orientation("Horizontal")
    sp.Add("TextBlock").Text(Chr(icon)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground(color).FontSize(14).Margin("0,0,8,0").VerticalAlignment("Center")
    sp.Add("TextBlock").Name("TxtTab_" name).Text(text).Foreground(isSelected ? "{DynamicResource TextMain}" : "{DynamicResource TextSub}").VerticalAlignment("Center").IsHitTestVisible("False")
    
    closeBtn := sp.Add("Button").Name("BtnCloseTab_" name).Content(Chr(0xE711)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextSub}").FontSize(10).Margin("10,0,0,0").VerticalAlignment("Center").Cursor("Hand")
    
    ctpl := closeBtn.Add("Button.Template").Add("ControlTemplate").TargetType("Button")
    cbdr := ctpl.Add("Border").Background("{TemplateBinding Background}").Padding("2").CornerRadius("2")
    cbdr.Add("ContentPresenter").HorizontalAlignment("Center").VerticalAlignment("Center")
    
    cstyle := closeBtn.Add("Button.Style").Add("Style").TargetType("Button")
    ct := cstyle.Add("Style.Triggers").Add("Trigger").Property("IsMouseOver").Value("True")
    ct.Add("Setter").Property("Background").Value("{DynamicResource ControlBgHover}")
}

AddTab(tabsBar, 0xE8A5, "#E34F26", "example_clone_vscode.ahk", "Main", true, true)
AddTab(tabsBar, 0xE8A5, "#E34F26", "XAML_GUI.ahk", "XAML_GUI", false, true)
AddTab(tabsBar, 0xEA86, "#519ABA", "README.md", "README", false, true)
AddTab(tabsBar, 0xE8A5, "#E34F26", "XAML_Components.ahk", "XAML_Components", false, false)
AddTab(tabsBar, 0xE8A5, "#E34F26", "example_clone_chat.ahk", "Chat", false, false)
AddTab(tabsBar, 0xE713, "#AAAAAA", "settings.ini", "Settings_Ini", false, false)
AddTab(tabsBar, 0xE713, "#AAAAAA", "Settings", "Settings", false, false)

; Right Side Tab Actions
tabActions := topBarGrid.Add("StackPanel").Grid_Column(1).Orientation("Horizontal").Margin("0,0,10,0").HorizontalAlignment("Right")
tabActions.Add("Button").Content(Chr(0xE718)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextSub}").FontSize(14).Margin("5,0")
tabActions.Add("Button").Content(Chr(0xE72D)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextSub}").FontSize(14).Margin("5,0")

; Text Editor Area
codeEditor := editorArea.Add("Border").Grid_Row(1).Background("{DynamicResource SolidBg}")
codeEditor.Add("TextBox").Name("MainTextBox").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness("0").FontFamily("Consolas").FontSize(14).AcceptsReturn("True").Padding("20").VerticalContentAlignment("Top")

; Error Screen (Not Found)
errorScreen := editorArea.Add("Grid").Name("ErrorScreen").Grid_Row(1).Visibility("Collapsed").Background("{DynamicResource SolidBg}")
errSp := errorScreen.Add("StackPanel").VerticalAlignment("Center").HorizontalAlignment("Center")
errSp.Add("TextBlock").Text(Chr(0xEA39)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(64).Foreground("{DynamicResource ErrorColor}").HorizontalAlignment("Center").Margin("0,0,0,20")
errSp.Add("TextBlock").Text("The editor could not be opened because the file was not found.").Foreground("{DynamicResource TextSub}").FontSize(16).HorizontalAlignment("Center")

; INI Settings Viewer (Custom Interactive Dummy File)
iniEditorScreen := editorArea.Add("Grid").Name("IniEditorScreen").Grid_Row(1).Visibility("Collapsed").Background("{DynamicResource SolidBg}")
iniScroll := iniEditorScreen.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Padding("20")
iniSp := iniScroll.Add("StackPanel").Margin("10")
iniSp.Add("TextBlock").Text("SETTINGS CONFIGURATION").FontSize(22).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,25")

AddIniField(sp, label, value) {
    p := sp.Add("StackPanel").Margin("0,0,0,20")
    p.Add("TextBlock").Text(label).Foreground("{DynamicResource TextSub}").FontSize(12).FontWeight("SemiBold").Margin("0,0,0,8")
    p.Add("TextBox").Text(value).Background("{DynamicResource SolidControl}").Foreground("{DynamicResource TextMain}").BorderThickness("1").BorderBrush("{DynamicResource SolidBorder}").Padding("10,8").FontSize(14).Width("300").HorizontalAlignment("Left")
}

AddIniField(iniSp, "Window DWM Mode", "2,1")
AddIniField(iniSp, "Background Color (Hex)", "#90111114")
AddIniField(iniSp, "Sidebar Color (Hex)", "#30000000")
AddIniField(iniSp, "Text Main (Hex)", "#FFFFFF")
AddIniField(iniSp, "Accent Color (Hex)", "#0A84FF")
iniSp.Add("Button").Content("Save Configuration").Background("{DynamicResource Accent}").Foreground("{DynamicResource TextMain}").Padding("15,10").BorderThickness("0").Margin("0,15,0,0").HorizontalAlignment("Left").Cursor("Hand")

; Settings Tab Screen
settingsScreen := editorArea.Add("Grid").Name("SettingsScreen").Grid_Row(1).Visibility("Collapsed").Background("{DynamicResource SolidBg}")
setScroll := settingsScreen.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Padding("30")
setSp := setScroll.Add("StackPanel")
setSp.Add("TextBlock").Text("Settings").FontSize(24).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,30")

setSp.Add("TextBlock").Text("APPEARANCE").Foreground("{DynamicResource TextSub}").FontSize(12).FontWeight("SemiBold").Margin("0,0,0,10")
themeCb := setSp.Add("ComboBox").Name("AppThemeCb").Margin("0,0,0,20").Width("300").HorizontalAlignment("Left")

try {
    Loop Parse, IniRead("themes.ini"), "`n", "`r"
        themeCb.Add("ComboBoxItem").Content(A_LoopField)
}
themeCb.SelectedIndex(0)

; 4. Status Bar (Bottom)
statusBar := layout.Add("Grid").Grid_Row(1).Background("{DynamicResource Accent}")
statusBar.Cols("Auto", "*", "Auto")

statusLeft := statusBar.Add("StackPanel").Grid_Column(0).Orientation("Horizontal").Margin("10,0")
statusLeft.Add("TextBlock").Text(Chr(0xE83D)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("0,0,5,0")
statusLeft.Add("TextBlock").Text("main*").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("0,0,15,0")
statusLeft.Add("TextBlock").Text(Chr(0xE814) " 0  " Chr(0xE711) " 0").FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets, Segoe UI").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("0,0,15,0")

statusRight := statusBar.Add("StackPanel").Grid_Column(2).Orientation("Horizontal").Margin("10,0")
statusRight.Add("TextBlock").Text("Ln 15, Col 42").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")
statusRight.Add("TextBlock").Text("Spaces: 4").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")
statusRight.Add("TextBlock").Text("UTF-8").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")
statusRight.Add("TextBlock").Text("CRLF").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")
statusRight.Add("TextBlock").Text("AutoHotkey").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")

; Command Palette Component
cmdPalette := XCommandPalette(app.overlay, "CmdPal")

cmdPalette.AddCommand("reload", "Developer: Reload Window")
cmdPalette.AddCommand("terminal", "Terminal: Create New Terminal")
cmdPalette.AddCommand("settings", "Preferences: Open Settings")
cmdPalette.AddCommand("file_new", "File: New File")
cmdPalette.AddCommand("theme_dark", "Preferences: Color Theme (Dark)")
cmdPalette.AddCommand("theme_light", "Preferences: Color Theme (Light)")

cmdPalette.SetHomeCommands(["reload", "terminal", "settings"])

cmdPalette.DefineProp("OnCommandSelected", { Call: HandleCommand })
HandleCommand(this, id) {
    if (id == "settings")
        SelectTab("Settings")
    else
        MsgBox("Executed command: " id, "Command Palette", "Iconi")
}

; Compile UI
ui := app.Compile()

; Bind hotkey
cmdPalette.Bind(ui, "^+P")  ; Ctrl+Shift+P

; Populate Editor Content
global fileKeys := ["Main", "XAML_GUI", "README", "XAML_Components", "Chat", "Settings_Ini", "Settings"]
global filesData := Map(
    "Main", {text: "#Requires AutoHotkey v2.0`nMsgBox `"Welcome to VS Code Clone!`"`n`n; Press Ctrl+Shift+P to open Command Palette!`n", type: "code"},
    "XAML_GUI", {text: "class XAML_GUI {`n    __New(title, config) {`n        this.title := title`n    }`n}", type: "code"},
    "README", {text: "# AHK-XAML`n`nA modern UI framework for AutoHotkey.`n", type: "code"},
    "XAML_Components", {text: "", type: "error"},
    "Chat", {text: "; example_clone_chat.ahk`n; Chat clone implementation coming soon!`n", type: "code"},
    "Settings_Ini", {text: "", type: "ini"},
    "Settings", {text: "", type: "settings"}
)

global openTabs := ["Main", "XAML_GUI", "README"]
global currentTab := "Main"

; Sidebar Toggle Logic
global sidebarVisible := true
global currentSidebarView := "EXPLORER"

UpdateActivityHighlights(viewName) {
    global currentThemeMap
    acts := Map("EXPLORER", "BtnActExplorer", "SEARCH", "BtnActSearch", "SOURCE CONTROL", "BtnActSourceControl", "RUN AND DEBUG", "BtnActRun", "EXTENSIONS", "BtnActExtensions")
    
    for v, btnName in acts {
        isActive := (v == viewName)
        fg := isActive ? currentThemeMap["TextMain"] : currentThemeMap["TextSub"]
        brd := isActive ? currentThemeMap["TextMain"] : "Transparent"
        
        ui.Update(btnName, "Foreground", fg)
        ui.Update(btnName, "BorderBrush", brd)
    }
}

ToggleSidebar(viewName) {
    global sidebarVisible, currentSidebarView
    
    if (sidebarVisible && currentSidebarView == viewName) {
        ui.Update("SidebarPanel", "Visibility", "Collapsed")
        sidebarVisible := false
        UpdateActivityHighlights("")
    } else {
        ui.Update("SidebarPanel", "Visibility", "Visible")
        ui.Update("SidebarTitle", "Text", viewName)
        
        ; Hide all views
        views := ["EXPLORER", "SEARCH", "SOURCE_CONTROL", "RUN_AND_DEBUG", "EXTENSIONS"]
        for v in views {
            ui.Update("View_" v, "Visibility", (v == StrReplace(viewName, " ", "_")) ? "Visible" : "Collapsed")
        }
        
        sidebarVisible := true
        currentSidebarView := viewName
        UpdateActivityHighlights(viewName)
    }
}

ui.OnEvent("BtnActExplorer", "Click", (*) => ToggleSidebar("EXPLORER"))
ui.OnEvent("BtnActSearch", "Click", (*) => ToggleSidebar("SEARCH"))
ui.OnEvent("BtnActSourceControl", "Click", (*) => ToggleSidebar("SOURCE CONTROL"))
ui.OnEvent("BtnActRun", "Click", (*) => ToggleSidebar("RUN AND DEBUG"))
ui.OnEvent("BtnActExtensions", "Click", (*) => ToggleSidebar("EXTENSIONS"))
ui.OnEvent("BtnActSettings", "Click", (*) => SelectTab("Settings"))

; Tab Switching Logic
SelectTab(tabName) {
    global openTabs, currentTab, fileKeys, filesData, currentThemeMap
    
    ; Add to open tabs if not open
    isOpen := false
    for t in openTabs {
        if (t == tabName)
            isOpen := true
    }
    if (!isOpen) {
        openTabs.Push(tabName)
        ui.Update("BtnTab_" tabName, "Visibility", "Visible")
    }
    
    currentTab := tabName
    
    ; Update Visuals
    for t in fileKeys {
        isSelected := (t == tabName)
        
        ; Extract active/inactive colors from the global map instead of sending raw "{DynamicResource}" 
        ; since the XAML framework might not dynamically re-resolve it via ui.Update
        bgCol := isSelected ? currentThemeMap["SolidBg"] : currentThemeMap["SolidControl"]
        brdCol := isSelected ? currentThemeMap["Accent"] : "Transparent"
        txtCol := isSelected ? currentThemeMap["TextMain"] : currentThemeMap["TextSub"]
        
        ui.Update("BtnTab_" t, "Background", bgCol)
        ui.Update("BtnTab_" t, "BorderBrush", brdCol)
        ui.Update("TxtTab_" t, "Foreground", txtCol)
        
        ui.Update("BtnNode_" t, "Background", isSelected ? currentThemeMap["SolidBorder"] : "Transparent")
        ui.Update("TxtNode_" t, "Foreground", txtCol)
    }
    
    ; Auto-scroll to the selected tab
    ui.Update("BtnTab_" tabName, "BringIntoView", "")
    
    ; Toggle Panes
    type := filesData[tabName].type
    ui.Update("MainTextBox", "Visibility", type == "code" ? "Visible" : "Collapsed")
    ui.Update("ErrorScreen", "Visibility", type == "error" ? "Visible" : "Collapsed")
    ui.Update("IniEditorScreen", "Visibility", type == "ini" ? "Visible" : "Collapsed")
    ui.Update("SettingsScreen", "Visibility", type == "settings" ? "Visible" : "Collapsed")
    
    if (type == "code") {
        ui.Update("MainTextBox", "Text", filesData[tabName].text)
    }
}

CloseTab(tabName) {
    global openTabs, currentTab
    
    ; Remove from openTabs
    newOpenTabs := []
    for t in openTabs {
        if (t != tabName)
            newOpenTabs.Push(t)
    }
    openTabs := newOpenTabs
    
    ui.Update("BtnTab_" tabName, "Visibility", "Collapsed")
    
    ; Handle focus switch if closing current tab
    if (currentTab == tabName) {
        if (openTabs.Length > 0) {
            SelectTab(openTabs[openTabs.Length])
        } else {
            currentTab := ""
            ui.Update("MainTextBox", "Text", "")
            ui.Update("MainTextBox", "Visibility", "Visible")
            ui.Update("ErrorScreen", "Visibility", "Collapsed")
            ui.Update("IniEditorScreen", "Visibility", "Collapsed")
            ui.Update("SettingsScreen", "Visibility", "Collapsed")
            for t in fileKeys {
                ui.Update("BtnNode_" t, "Background", "Transparent")
                ui.Update("TxtNode_" t, "Foreground", "{DynamicResource TextSub}")
            }
        }
    }
}

; Helper for Color Blending
BlendColor(fg, bg) {
    fg := StrReplace(fg, "#", "")
    if (StrLen(fg) == 6)
        fg := "FF" fg
    
    bg := StrReplace(bg, "#", "")
    if (StrLen(bg) == 6)
        bg := "FF" bg
        
    a_fg := Integer("0x" SubStr(fg, 1, 2)) / 255.0
    r_fg := Integer("0x" SubStr(fg, 3, 2))
    g_fg := Integer("0x" SubStr(fg, 5, 2))
    b_fg := Integer("0x" SubStr(fg, 7, 2))
    
    r_bg := Integer("0x" SubStr(bg, 3, 2))
    g_bg := Integer("0x" SubStr(bg, 5, 2))
    b_bg := Integer("0x" SubStr(bg, 7, 2))
    
    r_out := Round(r_fg * a_fg + r_bg * (1 - a_fg))
    g_out := Round(g_fg * a_fg + g_bg * (1 - a_fg))
    b_out := Round(b_fg * a_fg + b_bg * (1 - a_fg))
    
    return "#FF" Format("{:02X}", r_out) Format("{:02X}", g_out) Format("{:02X}", b_out)
}

IsLightColor(hex) {
    hex := StrReplace(hex, "#", "")
    if (StrLen(hex) == 8)
        hex := SubStr(hex, 3)
    r := Integer("0x" SubStr(hex, 1, 2))
    g := Integer("0x" SubStr(hex, 3, 2))
    b := Integer("0x" SubStr(hex, 5, 2))
    return (r + g + b) > 380
}

; Themes
ChangeTheme(state, ctrl, event) {
    global currentThemeMap
    if !state.Has("AppThemeCb")
        return
        
    theme := state["AppThemeCb"]
    try {
        themeData := IniRead("themes.ini", theme)
        tempMap := Map()
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2) {
                key := parts[1]
                val := parts[2]
                if (InStr(key, "Resource_") == 1) {
                    resName := SubStr(key, 10)
                    tempMap[resName] := val
                    ui.Update("Resource", resName, val)
                    currentThemeMap[resName] := val
                }
                if (key == "Resource_TextSub") {
                    ui.Update("Resource", "ErrorColor", val)
                }
            }
        }
        
        ; Generate Solid Colors
        bgColor := tempMap.Has("BgColor") ? tempMap["BgColor"] : "#FF1E1E1E"
        isLight := IsLightColor(bgColor)
        baseBg := isLight ? "#FFFFFFFF" : "#FF000000"
        
        solidBg := BlendColor(bgColor, baseBg)
        solidSidebar := tempMap.Has("SidebarColor") ? BlendColor(tempMap["SidebarColor"], solidBg) : solidBg
        solidControl := tempMap.Has("ControlBg") ? BlendColor(tempMap["ControlBg"], solidBg) : solidBg
        solidBorder := tempMap.Has("ControlBorder") ? BlendColor(tempMap["ControlBorder"], solidBg) : solidBg
        
        ui.Update("Resource", "SolidBg", solidBg)
        ui.Update("Resource", "SolidSidebar", solidSidebar)
        ui.Update("Resource", "SolidControl", solidControl)
        ui.Update("Resource", "SolidBorder", solidBorder)
        
        currentThemeMap["SolidBg"] := solidBg
        currentThemeMap["SolidSidebar"] := solidSidebar
        currentThemeMap["SolidControl"] := solidControl
        currentThemeMap["SolidBorder"] := solidBorder
        
        ; Refresh tabs to apply new raw colors
        global currentTab
        if (currentTab != "")
            SelectTab(currentTab)
    } catch {
        ; Do nothing
    }
}

InitApp(*) {
    ChangeTheme(Map("AppThemeCb", "Dark Mica (Win 11)"), "", "")
    SelectTab("Main")
}

ui.OnEvent("AppGrid", "Loaded", InitApp)
ui.Track("AppThemeCb")
ui.OnEvent("AppThemeCb", "SelectionChanged", ChangeTheme)

; Bind Tab Click Events
for t in fileKeys {
    boundName := t
    ui.OnEvent("BtnTab_" boundName, "MouseLeftButtonUp", ((name, *) => SelectTab(name)).Bind(boundName))
    ui.OnEvent("BtnNode_" boundName, "Click", ((name, *) => SelectTab(name)).Bind(boundName))
    ui.OnEvent("BtnCloseTab_" boundName, "Click", ((name, *) => CloseTab(name)).Bind(boundName))
}

app.Show()
