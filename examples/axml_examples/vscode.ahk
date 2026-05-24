#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"
#Include "..\data\MockData.ahk"
#Include "..\..\lib\AXML.ahk"

; Initialize App with a dark theme structure
app := XAML_GUI("VS Code Clone - AHK-XAML", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35 })

; Hide default TabControl since we are building a custom layout
app.tabs.Visibility("Collapsed")

; Set the background of the main area
app.main.Background("{DynamicResource SolidBg}")

; 1. Define Reactive State
global AppState := AXML_State({ 
    SidebarOpen: true,
    SidebarMode: "Fixed",
    CurrentSidebarView: "EXPLORER",
    CurrentTab: "Main",
    CodeText: "Loading...",
    SidebarAnim: "AnimSnapIn"
})

; 2. Define Computed Properties
AppState.AddComputed("SidebarVis", ["SidebarMode", "SidebarOpen"], state => (state.SidebarMode == "Fixed" || state.SidebarOpen) ? "Visible" : "Collapsed")
AppState.AddComputed("SidebarMargin", ["SidebarMode", "SidebarOpen"], state => (state.SidebarMode == "Fixed" && state.SidebarOpen) ? "250,0,0,0" : "0,0,0,0")
AppState.AddComputed("ScrimVis", ["SidebarMode", "SidebarOpen"], state => (state.SidebarMode == "Hidden" && state.SidebarOpen) ? "Visible" : "Collapsed")

AppState.AddComputed("ExplorerVis", ["CurrentSidebarView"], state => state.CurrentSidebarView == "EXPLORER" ? "Visible" : "Collapsed")
AppState.AddComputed("SearchVis", ["CurrentSidebarView"], state => state.CurrentSidebarView == "SEARCH" ? "Visible" : "Collapsed")
AppState.AddComputed("GitVis", ["CurrentSidebarView"], state => state.CurrentSidebarView == "SOURCE CONTROL" ? "Visible" : "Collapsed")
AppState.AddComputed("RunVis", ["CurrentSidebarView"], state => state.CurrentSidebarView == "RUN AND DEBUG" ? "Visible" : "Collapsed")
AppState.AddComputed("ExtVis", ["CurrentSidebarView"], state => state.CurrentSidebarView == "EXTENSIONS" ? "Visible" : "Collapsed")

; Determine Editor Screen Visibilities
global filesData := Example_MockData.GetVSCodeFilesData()
global fileKeys := ["Main", "XAML_GUI", "README", "XAML_Components", "Chat", "Settings_Ini", "Settings"]
global openTabs := ["Main", "XAML_GUI", "README"]

AppState.AddComputed("CodeVis", ["CurrentTab"], state => (filesData.Has(state.CurrentTab) && filesData[state.CurrentTab].type == "code") ? "Visible" : "Collapsed")
AppState.AddComputed("ErrorVis", ["CurrentTab"], state => (filesData.Has(state.CurrentTab) && filesData[state.CurrentTab].type == "error") ? "Visible" : "Collapsed")
AppState.AddComputed("IniVis", ["CurrentTab"], state => (filesData.Has(state.CurrentTab) && filesData[state.CurrentTab].type == "ini") ? "Visible" : "Collapsed")
AppState.AddComputed("SettingsVis", ["CurrentTab"], state => (filesData.Has(state.CurrentTab) && filesData[state.CurrentTab].type == "settings") ? "Visible" : "Collapsed")

; Automatically fetch CodeText when CurrentTab changes
AppState.AddComputed("CodeText", ["CurrentTab"], state => (filesData.Has(state.CurrentTab) && filesData[state.CurrentTab].type == "code") ? filesData[state.CurrentTab].text : "")

; 3. Parse AXML Layout
result := AXML.ParseFile("vscode.axml", app.main, AppState)

; Inject Animations
sidebarPanel := app.main.Find("SidebarPanel")
sidebarPanel.InjectResources('
(
    <Storyboard x:Key="AnimSlideIn">
        <DoubleAnimation Storyboard.TargetName="SidebarTranslate" Storyboard.TargetProperty="X" To="0" Duration="0:0:0.2">
            <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="4"/></DoubleAnimation.EasingFunction>
        </DoubleAnimation>
    </Storyboard>
    <Storyboard x:Key="AnimSlideOut">
        <DoubleAnimation Storyboard.TargetName="SidebarTranslate" Storyboard.TargetProperty="X" To="-250" Duration="0:0:0.2">
            <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="4"/></DoubleAnimation.EasingFunction>
        </DoubleAnimation>
    </Storyboard>
    <Storyboard x:Key="AnimSnapIn">
        <DoubleAnimation Storyboard.TargetName="SidebarTranslate" Storyboard.TargetProperty="X" To="0" Duration="0:0:0"/>
    </Storyboard>
)')

; Populate MockData
activitySp := app.main.Find("ActivitySp")
Example_MockData.AddActivityIcon(activitySp, 0xE814, "BtnActExplorer", true)
Example_MockData.AddActivityIcon(activitySp, 0xE721, "BtnActSearch")
Example_MockData.AddActivityIcon(activitySp, 0xE90F, "BtnActSourceControl")
Example_MockData.AddActivityIcon(activitySp, 0xEBE8, "BtnActRun")
Example_MockData.AddActivityIcon(activitySp, 0xE718, "BtnActExtensions")

activityBottom := app.main.Find("ActivityBottomSp")
Example_MockData.AddActivityIcon(activityBottom, 0xE713, "BtnActSettings")
Example_MockData.AddActivityIcon(activityBottom, 0xE77B, "BtnActAccounts")

sideExplorer := app.main.Find("SideExplorer")
Example_MockData.AddFileNode(sideExplorer, 20, 0xE8B7, "#E3C93A", "lib", "Folder_Lib")
Example_MockData.AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "XAML_GUI.ahk", "XAML_GUI")
Example_MockData.AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "XAML_Components.ahk", "XAML_Components", false, true)
Example_MockData.AddFileNode(sideExplorer, 20, 0xE8B7, "#E3C93A", "examples", "Folder_Examples")
Example_MockData.AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "example_clone_vscode.ahk", "Main", true)
Example_MockData.AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "example_clone_chat.ahk", "Chat")
Example_MockData.AddFileNode(sideExplorer, 40, 0xE713, "#AAAAAA", "settings.ini", "Settings_Ini")

tabsBar := app.main.Find("TabsBar")
Example_MockData.AddTab(tabsBar, 0xE8A5, "#E34F26", "example_clone_vscode.ahk", "Main", true, true)
Example_MockData.AddTab(tabsBar, 0xE8A5, "#E34F26", "XAML_GUI.ahk", "XAML_GUI", false, true)
Example_MockData.AddTab(tabsBar, 0xEA86, "#519ABA", "README.md", "README", false, true)
Example_MockData.AddTab(tabsBar, 0xE8A5, "#E34F26", "XAML_Components.ahk", "XAML_Components", false, false)
Example_MockData.AddTab(tabsBar, 0xE8A5, "#E34F26", "example_clone_chat.ahk", "Chat", false, false)
Example_MockData.AddTab(tabsBar, 0xE713, "#AAAAAA", "settings.ini", "Settings_Ini", false, false)
Example_MockData.AddTab(tabsBar, 0xE713, "#AAAAAA", "Settings", "Settings", false, false)

iniSp := app.main.Find("IniSp")
Example_MockData.AddIniField(iniSp, "Window DWM Mode", "2,1")
Example_MockData.AddIniField(iniSp, "Background Color (Hex)", "#90111114")
Example_MockData.AddIniField(iniSp, "Sidebar Color (Hex)", "#30000000")
Example_MockData.AddIniField(iniSp, "Text Main (Hex)", "#FFFFFF")
Example_MockData.AddIniField(iniSp, "Accent Color (Hex)", "#0A84FF")

; Theme loader logic from previous code
try {
    themeCb := app.main.Find("AppThemeCb")
    iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
    Loop Parse, IniRead(iniPath), "`n", "`r"
        themeCb.Add("ComboBoxItem").Content(A_LoopField)
    themeCb.SelectedIndex(0)
}

; Command Palette logic (Must be added to UI BEFORE Compile)
global cmdPalette := XCommandPalette(app.overlay, "CmdPal")
Example_MockData.PopulateVSCodeCommandPalette(cmdPalette)
cmdPalette.DefineProp("OnCommandSelected", { Call: HandleCommand })

; 4. Compile, Bind, Show
ui := app.Compile()
AXML.BindAll(ui, result, AppState)

; MockData events need to be bound manually since they aren't parsed by AXML
ui.OnEvent("BtnActExplorer", "Click", ObjBindMethod(ActivityIconClicked, "Call", "EXPLORER"))
ui.OnEvent("BtnActSearch", "Click", ObjBindMethod(ActivityIconClicked, "Call", "SEARCH"))
ui.OnEvent("BtnActSourceControl", "Click", ObjBindMethod(ActivityIconClicked, "Call", "SOURCE CONTROL"))
ui.OnEvent("BtnActRun", "Click", ObjBindMethod(ActivityIconClicked, "Call", "RUN AND DEBUG"))
ui.OnEvent("BtnActExtensions", "Click", ObjBindMethod(ActivityIconClicked, "Call", "EXTENSIONS"))
ui.OnEvent("BtnActSettings", "Click", (*) => SelectTab("Settings"))

HandleTabClick(tabName, args*) {
    SelectTab(tabName)
}

HandleTabClose(tabName, args*) {
    CloseTab(tabName)
}

for t in fileKeys {
    boundName := t
    ui.OnEvent("BtnTab_" boundName, "MouseLeftButtonUp", HandleTabClick.Bind(boundName))
    ui.OnEvent("BtnNode_" boundName, "Click", HandleTabClick.Bind(boundName))
    ui.OnEvent("BtnCloseTab_" boundName, "Click", HandleTabClose.Bind(boundName))
}

cmdPalette.Bind(ui, "^+p")

HotIfWinActive("VS Code Clone - AHK-XAML")
Hotkey("^b", ToggleSidebarMode, "On")
HotIf()

global currentThemeMap := Map("BgColor", "#1E1E1E", "ControlBg", "#333333", "Accent", "#007ACC", "ControlBorder", "#2D2D2D", "TextMain", "White", "TextSub", "#CCCCCC", "SolidBg", "#1E1E1E", "SolidSidebar", "#252526", "SolidControl", "#333333", "SolidBorder", "#2D2D2D")

ui.OnEvent("Window", "Loaded", InitApp)
app.Show()

; ----------------------------------------------------------------------
; Business Logic
; ----------------------------------------------------------------------

InitApp(*) {
    ChangeTheme(Map("AppThemeCb", "Dark Mica (Win 11)"), "", "")
    UpdateTabVisuals()
    UpdateActivityHighlights(AppState.CurrentSidebarView)
}

ToggleSidebarMode(*) {
    if (AppState.SidebarMode == "Fixed") {
        AppState.SidebarMode := "Hidden"
        AppState.SidebarAnim := "AnimSlideOut"
        AppState.SidebarOpen := false
    } else {
        AppState.SidebarMode := "Fixed"
        AppState.SidebarAnim := "AnimSnapIn"
        AppState.SidebarOpen := true
    }
}

HandleScrimClick(state, ctrl, event) {
    if (AppState.SidebarMode == "Hidden" && AppState.SidebarOpen) {
        AppState.SidebarAnim := "AnimSlideOut"
        AppState.SidebarOpen := false
        UpdateActivityHighlights("")
    }
}

global lastClickTime := 0
global lastClickCtrl := ""
ActivityIconClicked(viewName, state, ctrlName, event) {
    global lastClickTime, lastClickCtrl

    if (ctrlName == lastClickCtrl && A_TickCount - lastClickTime < 400) {
        lastClickTime := 0
        ToggleSidebarMode()
        return
    }

    lastClickTime := A_TickCount
    lastClickCtrl := ctrlName

    if (AppState.SidebarOpen && AppState.CurrentSidebarView == viewName) {
        if (AppState.SidebarMode == "Fixed")
            return
        AppState.SidebarAnim := "AnimSlideOut"
        AppState.SidebarOpen := false
        UpdateActivityHighlights("")
    } else {
        AppState.CurrentSidebarView := viewName
        AppState.SidebarAnim := (AppState.SidebarMode == "Hidden") ? "AnimSlideIn" : "AnimSnapIn"
        AppState.SidebarOpen := true
        UpdateActivityHighlights(viewName)
    }
}

UpdateActivityHighlights(viewName) {
    global currentThemeMap, ui
    acts := Map("EXPLORER", "BtnActExplorer", "SEARCH", "BtnActSearch", "SOURCE CONTROL", "BtnActSourceControl", "RUN AND DEBUG", "BtnActRun", "EXTENSIONS", "BtnActExtensions")
    
    for v, btnName in acts {
        isActive := (v == viewName)
        fg := isActive ? currentThemeMap["TextMain"] : currentThemeMap["TextSub"]
        brd := isActive ? currentThemeMap["Accent"] : "Transparent"

        ui.Update(btnName, "Foreground", fg)
        ui.Update(btnName, "BorderBrush", brd)
    }
}

SelectTab(tabName) {
    global openTabs, fileKeys, ui
    
    isOpen := false
    for t in openTabs {
        if (t == tabName)
            isOpen := true
    }
    if (!isOpen) {
        openTabs.Push(tabName)
        ui.Update("BtnTab_" tabName, "Visibility", "Visible")
    }

    AppState.CurrentTab := tabName
    UpdateTabVisuals()
    ui.Update("BtnTab_" tabName, "BringIntoView", "")
}

CloseTab(tabName) {
    global openTabs, ui
    
    newOpenTabs := []
    for t in openTabs {
        if (t != tabName)
            newOpenTabs.Push(t)
    }
    openTabs := newOpenTabs
    ui.Update("BtnTab_" tabName, "Visibility", "Collapsed")

    if (AppState.CurrentTab == tabName) {
        if (openTabs.Length > 0) {
            SelectTab(openTabs[openTabs.Length])
        } else {
            AppState.CurrentTab := ""
            UpdateTabVisuals()
        }
    }
}

UpdateTabVisuals() {
    global fileKeys, currentThemeMap, ui
    for t in fileKeys {
        isSelected := (t == AppState.CurrentTab)
        bgCol := isSelected ? currentThemeMap["SolidBg"] : currentThemeMap["SolidControl"]
        brdCol := isSelected ? currentThemeMap["Accent"] : "Transparent"
        txtCol := isSelected ? currentThemeMap["TextMain"] : currentThemeMap["TextSub"]

        ui.Update("BtnTab_" t, "Background", bgCol)
        ui.Update("BtnTab_" t, "BorderBrush", brdCol)
        ui.Update("TxtTab_" t, "Foreground", txtCol)

        if (t != "README" && t != "Settings") {
            ui.Update("BtnNode_" t, "Background", isSelected ? currentThemeMap["SolidBorder"] : "Transparent")
            ui.Update("TxtNode_" t, "Foreground", txtCol)
        }
    }
}

HandleCommand(this, id) {
    global ui
    theme := "Dark Mica (Win 11)"
    owner := ui.wpfHwnd

    if (id == "settings") {
        SelectTab("Settings")
    } else if (id == "toggle_sidebar") {
        ToggleSidebarMode()
    } else if (id == "reload") {
        res := XDialog.Show({ Title: "Reload Window", Message: "Are you sure you want to reload the window? Any unsaved changes will be lost.", Icon: Chr(0xE72C), IconColor: "#FF9F0A", Buttons: ["Reload", "Cancel"], Width: 420, Modal: true, Owner: owner, Theme: theme })
        if (res.Button == "Reload")
            Reload()
    } else if (id == "terminal") {
        XDialog.Show({ Title: "Terminal Created", Message: "A new integrated terminal has been created.", Icon: Chr(0xE756), IconColor: "#32D74B", Buttons: ["OK"], Width: 380, Modal: true, Owner: owner, Theme: theme })
    } else {
        XDialog.Show({ Title: "Command Executed", Message: "Successfully ran: " id, Icon: Chr(0xE73E), IconColor: "#32D74B", Buttons: ["OK"], Width: 380, Modal: true, Owner: owner, Theme: theme })
    }
}

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

ChangeTheme(state, ctrl, event) {
    global currentThemeMap, ui
    if !state.Has("AppThemeCb")
        return

    theme := state["AppThemeCb"]
    try {
        iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
        themeData := IniRead(iniPath, theme)
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

        UpdateTabVisuals()
        UpdateActivityHighlights(AppState.CurrentSidebarView)
    }
}
