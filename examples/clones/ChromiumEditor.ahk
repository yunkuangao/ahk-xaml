#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; CHROMIUM EDITOR CLONE
; A super sexy sleek XAML Mica window styled like a Chromium browser
; ==============================================================================

app := XAML_GUI("Chromium Editor", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35, AppIcon: false })

; Hide default TabControl since we are building a custom Chromium layout
app.tabs.Visibility("Collapsed")
app.main.Background("{DynamicResource ControlBg}")

; Main Layout Grid for Toolbar, Editor, and Status Bar
layout := app.main.Add("Grid").Grid_Row(1)
layout.Rows("Auto", "*", "Auto") ; Toolbar, Content Area, Status Bar

; ==============================================================================
; DUMMY DATA (Hierarchical File System)
; ==============================================================================
global fileSystem := Map(
    "src", Map(
        "main.rs", "fn main() {`n    println!(`"Hello, Chromium!`");`n}",
        "utils.rs", "pub fn helper() {`n    println!(`"Helpers!`");`n}"
    ),
    "css", Map(
        "styles.css", "/* Sexy Chromium Styles */`nbody {`n    background: #1E1E1E;`n    color: #fff;`n}",
        "theme.css", ":root {`n    --accent: #E34F26;`n}"
    ),
    "ChromiumEditor.ahk", "; Chromium Editor`n; Built with AHK-XAML`n`nMsgBox(`"Sleek and Sexy!`")",
    "README.md", "# Chromium Clone`nThis is a heavily modified example showing sidebar, status bar, and tab history."
)

global openTabs := ["ChromiumEditor.ahk", "styles.css", "main.rs"]
global currentTab := "ChromiumEditor.ahk"
global tabHistory := ["ChromiumEditor.ahk"]
global historyIndex := 1
global modifiedFiles := Map()

; Flatten file system to easy access content by filename
global filesData := Map()
global fileToParent := Map()

FlattenFS(fs, parentFolder := "") {
    global filesData, fileToParent
    for k, v in fs {
        if (Type(v) == "Map")
            FlattenFS(v, k)
        else {
            filesData[k] := v
            if (parentFolder != "")
                fileToParent[k] := parentFolder
        }
    }
}
FlattenFS(fileSystem)

; ==============================================================================
; 1. CHROMIUM TABS AREA (IN THE TITLE BAR)
; ==============================================================================
tabsBg := app.main.Add("Border").Grid_Row(0).Background("Transparent").Margin("0,0,160,0").Padding("0,0,0,0").HorizontalAlignment("Left").VerticalAlignment("Stretch").SetProp("Panel.ZIndex", "110")
tabsGrid := tabsBg.Add("Grid")
tabsGrid.Cols("*", "Auto")

tabsScroll := tabsGrid.Add("ScrollViewer").Grid_Column(0).HorizontalScrollBarVisibility("Hidden").VerticalScrollBarVisibility("Disabled")
scrollContent := tabsScroll.Add("StackPanel").Orientation("Horizontal")

tabsBar := scrollContent.Add("StackPanel").Orientation("Horizontal").Name("TabsPanel")

AddChromiumTab(parent, title) {
    id := RegExReplace(title, "[^a-zA-Z0-9]", "_")
    tabBorder := parent.Add("Border").Name("TabBorder_" id).CornerRadius("8,8,0,0").Margin("0,0,0,0").Cursor("Hand").WindowChrome_IsHitTestVisibleInChrome("True").Background("Transparent")

    tabGrid := tabBorder.Add("Grid")
    tabGrid.Add("Border").Name("TabOverlay_" id).CornerRadius("8,8,0,0").Background("{DynamicResource TextMain}").Opacity("0.06").SetProp("IsHitTestVisible", "False").Visibility("Collapsed")

    sp := tabGrid.Add("StackPanel").Orientation("Horizontal").Margin("15,0,12,0")

    iconColor := "#E34F26"
    if InStr(title, ".css")
        iconColor := "#264DE4"
    else if InStr(title, ".rs")
        iconColor := "#DEA584"
    else
        iconColor := "#AAAAAA"

    sp.Add("TextBlock").Text(Chr(0xE8A5)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground(iconColor).VerticalAlignment("Center").Margin("0,0,10,0").FontSize(14)
    sp.Add("TextBlock").Name("TabText_" id).Text(title).VerticalAlignment("Center").FontSize(13).Margin("0,0,15,0").FontWeight("SemiBold").Opacity("0.5")
    sp.Add("Button").Name("TabClose_" id).Content(Chr(0xE711)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").BorderThickness(0).Padding("5").FontSize(10).Cursor("Hand").Opacity("0.5")

    return id
}

for t in openTabs {
    AddChromiumTab(tabsBar, t)
}

newTabBtn := scrollContent.Add("Button").Content(Chr(0xE710)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).Margin("6,0,0,0").Padding("8").FontSize(14).Cursor("Hand").Name("BtnNewTab").WindowChrome_IsHitTestVisibleInChrome("True")


; ==============================================================================
; 2. CHROMIUM TOOLBAR AREA
; ==============================================================================
toolbarBase := layout.Add("Border").Grid_Row(0).Background("{DynamicResource DropdownBg}").BorderThickness("0").SetProp("Panel.ZIndex", "10")
toolbarGridWrap := toolbarBase.Add("Grid")
toolbarGridWrap.Add("Border").Background("{DynamicResource TextMain}").Opacity("0.06").SetProp("IsHitTestVisible", "False")

toolbarBg := toolbarGridWrap.Add("Border").Padding("10,8,10,8")
toolbarGrid := toolbarBg.Add("Grid")
toolbarGrid.Cols("Auto", "*", "Auto")

navSp := toolbarGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(0).VerticalAlignment("Center")
navSp.Add("Button").Content(Chr(0xE700)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Margin("5,0,10,0").FontSize(16).Padding("10").Cursor("Hand").Name("BtnToggleSidebar").ToolTip("Toggle Sidebar")
navSp.Add("Button").Content(Chr(0xE72B)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Margin("0,0,2,0").FontSize(16).Padding("10").Cursor("Hand").Name("BtnNavBack").ToolTip("Click to go back")
navSp.Add("Button").Content(Chr(0xE72A)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).Margin("0,0,2,0").FontSize(16).Padding("10").Cursor("Hand").Name("BtnNavFwd").ToolTip("Click to go forward")
navSp.Add("Button").Content(Chr(0xE72C)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Margin("0,0,15,0").FontSize(16).Padding("10").Cursor("Hand").Name("BtnNavReload").ToolTip("Reload current file to original state")

omniboxBorder := toolbarGrid.Add("Border").Grid_Column(1).Background("{DynamicResource ControlBg}").CornerRadius("18").Padding("15,6,15,6").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").VerticalAlignment("Center")
omniboxGrid := omniboxBorder.Add("Grid")
omniboxGrid.Cols("Auto", "*", "Auto")

omniboxGrid.Add("TextBlock").Text(Chr(0xE838)).FontFamily("Segoe Fluent Icons").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").Grid_Column(0).Margin("0,0,12,0").FontSize(14)
omniboxGrid.Add("TextBox").Name("OmniboxInput").Text("C:\projects\ahk\richide\ChromiumEditor.ahk").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).VerticalAlignment("Center").Grid_Column(1).FontSize(14).FontFamily("Segoe UI")
omniboxGrid.Add("Button").Content(Chr(0xE73E)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource Accent}").BorderThickness(0).VerticalAlignment("Center").Grid_Column(2).Margin("5,0,0,0").FontSize(14).Cursor("Hand").ToolTip("Bookmark this tab")

extSp := toolbarGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(2).VerticalAlignment("Center").Margin("15,0,5,0")

themeCombo := extSp.Add("ComboBox").Name("ComboTheme").Width(150).Margin("0,0,10,0").VerticalAlignment("Center").Height("30")
try {
    iniPath := FileExist("themes.ini") ? "themes.ini" : "..\themes.ini"
    Loop Parse, IniRead(iniPath), "`n", "`r"
        themeCombo.Add("ComboBoxItem").Content(A_LoopField)
}
themeCombo.SelectedIndex(0)

extBtn := extSp.Add("Button").Name("BtnExt").Content(Chr(0xE9D5)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Margin("0,0,2,0").FontSize(16).Padding("10").Cursor("Hand").ToolTip("Extensions")
extCtx := extBtn.Add("Button.ContextMenu").Add("ContextMenu").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}")
extCtx.Add("MenuItem").Header("Vim Emulator").Icon(Chr(0xE768))
extCtx.Add("MenuItem").Header("Prettier Code Formatter").Icon(Chr(0xE768))
extCtx.Add("MenuItem").Header("Manage Extensions...")

profBtn := extSp.Add("Button").Name("BtnProfile").Content(Chr(0xE77B)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Margin("0,0,2,0").FontSize(16).Padding("10").Cursor("Hand").ToolTip("Profile")
profCtx := profBtn.Add("Button.ContextMenu").Add("ContextMenu").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}")
profCtx.Add("MenuItem").Header("Sync is ON").Icon(Chr(0xE898))
profCtx.Add("Separator")
profCtx.Add("MenuItem").Header("Manage Google Account")
profCtx.Add("MenuItem").Header("Sign out")

extSp.Add("Button").Content(Chr(0xE712)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).FontSize(16).Padding("10").Cursor("Hand").Name("BtnMenu").ToolTip("More Options")

; Hidden Dummy Button to host the Global Context Menu for Tabs
dummyBtn := extSp.Add("Button").Name("DummyTabCtxBtn").Visibility("Collapsed")
globalTabCtx := dummyBtn.Add("Button.ContextMenu").Add("ContextMenu").Name("GlobalTabCtx").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}")
globalTabCtx.Add("MenuItem").Name("CtxClose").Header("Close Tab")
globalTabCtx.Add("MenuItem").Name("CtxCloseRight").Header("Close Tabs to Right")
globalTabCtx.Add("MenuItem").Name("CtxCloseOther").Header("Close Other Tabs")
globalTabCtx.Add("Separator")
globalTabCtx.Add("MenuItem").Name("CtxCopyPath").Header("Copy Path")
globalTabCtx.Add("MenuItem").Name("CtxReveal").Header("Reveal in File Explorer")
globalTabCtx.Add("Separator")
globalTabCtx.Add("MenuItem").Name("CtxNew").Header("New Tab")

; ==============================================================================
; 3. MIDDLE AREA (SIDEBAR + EDITOR)
; ==============================================================================
middleDock := layout.Add("DockPanel").Grid_Row(1)

sidebarContainer := middleDock.Add("Grid").SetProp("DockPanel.Dock", "Left").Name("SidebarContainer")
sidebarContainer.Cols("250", "Auto")

sidebarBg := sidebarContainer.Add("Border").Grid_Column(0).Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0")
sidebarSp := sidebarBg.Add("StackPanel")
sidebarSp.Add("TextBlock").Text("EXPLORER").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("15,10,10,10")
fileTree := sidebarSp.Add("TreeView").Name("FileExplorer").Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextMain}")

BuildTree(parentEl, fsMap) {
    for k, v in fsMap {
        if (Type(v) == "Map") {
            tvi := parentEl.Add("TreeViewItem").Name("FolderNode_" RegExReplace(k, "[^a-zA-Z0-9]", "_")).Header(k).Foreground("{DynamicResource TextMain}")
            tvi.IsExpanded("True")
            BuildTree(tvi, v)
        } else {
            tvi := parentEl.Add("TreeViewItem").Name("FileNode_" RegExReplace(k, "[^a-zA-Z0-9]", "_")).Header(k).Foreground("{DynamicResource TextSub}")
            tvi.SetProp("Tag", k)
        }
    }
}
BuildTree(fileTree, fileSystem)

sidebarContainer.Add("GridSplitter").Grid_Column(1).Width("3").Background("Transparent").HorizontalAlignment("Center").VerticalAlignment("Stretch").Cursor("SizeWE")

editorArea := middleDock.Add("Border").Background("{DynamicResource DropdownBg}")
codeEditor := editorArea.Add("TextBox").Name("MainEditor").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness("0").FontFamily("Consolas").FontSize(16).AcceptsReturn("True").Padding("30,30,30,50").VerticalContentAlignment("Top").TextWrapping("Wrap").HorizontalScrollBarVisibility("Auto").VerticalScrollBarVisibility("Auto")

; ==============================================================================
; 4. STATUS BAR
; ==============================================================================
statusBar := layout.Add("Border").Grid_Row(2).Background("{DynamicResource ControlBg}").Height(28).BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,1,0,0")
sbGrid := statusBar.Add("Grid")
sbGrid.Cols("Auto", "*", "Auto")

sbLeft := sbGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(0).VerticalAlignment("Center").Margin("10,0,0,0")
sbLeft.Add("TextBlock").Text(Chr(0xE783)).FontFamily("Segoe Fluent Icons").Foreground("{DynamicResource Accent}").FontSize(12).Margin("0,0,5,0").VerticalAlignment("Center")
sbLeft.Add("TextBlock").Text("main*").Foreground("{DynamicResource TextMain}").FontSize(12).VerticalAlignment("Center").Margin("0,0,15,0")
sbLeft.Add("TextBlock").Text(Chr(0xE711)).FontFamily("Segoe Fluent Icons").Foreground("{DynamicResource TextSub}").FontSize(10).Margin("0,0,5,0").VerticalAlignment("Center")
sbLeft.Add("TextBlock").Text("0 errors, 0 warnings").Foreground("{DynamicResource TextMain}").FontSize(12).VerticalAlignment("Center")

sbRight := sbGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(2).VerticalAlignment("Center").Margin("0,0,15,0")
sbRight.Add("TextBlock").Name("StatusBarLnCol").Text("Ln 1, Col 1").Foreground("{DynamicResource TextSub}").FontSize(12).Margin("0,0,15,0").VerticalAlignment("Center")
sbRight.Add("TextBlock").Text("UTF-8").Foreground("{DynamicResource TextSub}").FontSize(12).Margin("0,0,15,0").VerticalAlignment("Center")
sbRight.Add("TextBlock").Text("CRLF").Foreground("{DynamicResource TextSub}").FontSize(12).Margin("0,0,15,0").VerticalAlignment("Center")
sbRight.Add("TextBlock").Name("StatusBarLang").Text("AutoHotkey").Foreground("{DynamicResource TextSub}").FontSize(12).VerticalAlignment("Center")

; ==============================================================================
; COMMAND PALETTE
; ==============================================================================
cmdPalette := XCommandPalette(app.overlay, "CmdPal")
cmdPalette.AddCommand("new_tab", "New Tab", { Icon: Chr(0xE710), Callback: HandleNewTab })
cmdPalette.AddCommand("close_tab", "Close Current Tab", { Icon: Chr(0xE711), Callback: (*) => CloseTab(currentTab) })
cmdPalette.AddCommand("close_right", "Close Tabs to Right", { Icon: Chr(0xE711), Callback: (*) => CloseTabsRight(currentTab) })
cmdPalette.AddCommand("close_other", "Close Other Tabs", { Icon: Chr(0xE711), Callback: (*) => CloseOtherTabs(currentTab) })
cmdPalette.AddCommand("reload", "Reload Window", { Icon: Chr(0xE72C), Callback: (*) => Reload() })
cmdPalette.AddCommand("settings", "Settings", { Icon: Chr(0xE713), Callback: HandleSettings })
cmdPalette.AddCommand("help", "Help & About", { Icon: Chr(0xE946), Callback: HandleHelp })
cmdPalette.SetHomeCommands(["new_tab", "close_tab", "reload", "settings", "help"])

; ==============================================================================
; COMPILE & BIND EVENTS
; ==============================================================================
ui := app.Compile()
cmdPalette.Bind(ui, "^+P")

HotIfWinActive("Chromium Editor")
Hotkey("^t", (*) => HandleNewTab())
HotIfWinActive()

ui.OnEvent("CtxClose", "Click", (*) => CloseTab(ctxTargetTab))
ui.OnEvent("CtxCloseRight", "Click", (*) => CloseTabsRight(ctxTargetTab))
ui.OnEvent("CtxCloseOther", "Click", (*) => CloseOtherTabs(ctxTargetTab))
ui.OnEvent("CtxNew", "Click", HandleNewTab)

ui.Update("MainEditor", "BindEvent", "TextChanged")
ui.OnEvent("MainEditor", "TextChanged", EditorTextChanged)

EditorTextChanged(state, ctrl, ev) {
    global currentTab, filesData, modifiedFiles, ui
    if (filesData.Has(currentTab)) {
        if (filesData[currentTab] != state["MainEditor"]) {
            modifiedFiles[currentTab] := true
            id := RegExReplace(currentTab, "[^a-zA-Z0-9]", "_")
            ui.Update("TabText_" id, "Text", currentTab "*")
            ui.Update("StatusBarLnCol", "Text", "Ln " StrSplit(state["MainEditor"], "`n").Length ", Col 1")
        } else {
            modifiedFiles.Delete(currentTab)
            id := RegExReplace(currentTab, "[^a-zA-Z0-9]", "_")
            ui.Update("TabText_" id, "Text", currentTab)
        }
    }
}

ui.Update("FileExplorer", "BindEvent", "SelectedItemChanged")
ui.OnEvent("FileExplorer", "SelectedItemChanged", HandleTreeSelect)
HandleTreeSelect(state, ctrl, ev) {
    global filesData, openTabs, ui
    if (state.Has("FileExplorer") && state["FileExplorer"] != "") {
        selected := state["FileExplorer"]
        if (filesData.Has(selected)) {
            hasTab := false
            for t in openTabs {
                if (t == selected)
                    hasTab := true
            }
            if (!hasTab)
                AddChromiumTabDynamic(selected)
            else
                SelectTab(selected)
        }
    }
}

ui.OnEvent("BtnNavBack", "Click", HandleNavBack)
HandleNavBack(*) {
    global tabHistory, historyIndex
    if (historyIndex > 1) {
        historyIndex--
        SelectTab(tabHistory[historyIndex], true)
    }
}

ui.OnEvent("BtnNavFwd", "Click", HandleNavFwd)
HandleNavFwd(*) {
    global tabHistory, historyIndex
    if (historyIndex < tabHistory.Length) {
        historyIndex++
        SelectTab(tabHistory[historyIndex], true)
    }
}

ui.OnEvent("BtnExt", "Click", (*) => ui.Update("BtnExt.ContextMenu", "IsOpen", "True"))
ui.OnEvent("BtnProfile", "Click", (*) => ui.Update("BtnProfile.ContextMenu", "IsOpen", "True"))

ui.OnEvent("CtxCopyPath", "Click", (*) => A_Clipboard := "C:\projects\ahk\richide\" ctxTargetTab)
ui.OnEvent("CtxReveal", "Click", (*) => MsgBox("Revealed " ctxTargetTab " in File Explorer!", "Mock Action", 64))

AddChromiumTabDynamic(title) {
    global ui, openTabs
    id := RegExReplace(title, "[^a-zA-Z0-9]", "_")

    iconColor := "#E34F26"
    if InStr(title, ".css")
        iconColor := "#264DE4"
    else if InStr(title, ".rs")
        iconColor := "#DEA584"
    else
        iconColor := "#AAAAAA"

    xaml := '<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="TabBorder_' id '" CornerRadius="8,8,0,0" Margin="0,0,0,0" Cursor="Hand" WindowChrome.IsHitTestVisibleInChrome="True" Background="Transparent">'
        . '<Grid>'
        . '<Border x:Name="TabOverlay_' id '" CornerRadius="8,8,0,0" Background="{DynamicResource TextMain}" Opacity="0.06" IsHitTestVisible="False" Visibility="Collapsed"/>'
        . '<StackPanel Orientation="Horizontal" Margin="15,0,12,0">'
        . '<TextBlock Text="&#xE8A5;" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Foreground="' iconColor '" VerticalAlignment="Center" Margin="0,0,10,0" FontSize="14"/>'
        . '<TextBlock x:Name="TabText_' id '" Text="' title '" VerticalAlignment="Center" FontSize="13" Margin="0,0,15,0" FontWeight="SemiBold" Opacity="0.5"/>'
        . '<Button x:Name="TabClose_' id '" Content="&#xE711;" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Background="Transparent" BorderThickness="0" Padding="5" FontSize="10" Cursor="Hand" Opacity="0.5"/>'
        . '</StackPanel>'
        . '</Grid>'
        . '</Border>'

    ui.Update("TabsPanel", "AddXamlItem", xaml)
    openTabs.Push(title)

    BindTabEvents(title)
    SelectTab(title)
}

BindTabEvents(title) {
    global ui
    id := RegExReplace(title, "[^a-zA-Z0-9]", "_")

    ui.Update("TabBorder_" id, "BindEvent", "MouseLeftButtonUp")
    ui.OnEvent("TabBorder_" id, "MouseLeftButtonUp", ((t, *) => SelectTab(t)).Bind(title))

    ui.Update("TabClose_" id, "BindEvent", "Click")
    ui.OnEvent("TabClose_" id, "Click", ((t, *) => CloseTab(t)).Bind(title))

    ui.Update("TabBorder_" id, "BindEvent", "MouseRightButtonUp")
    ui.OnEvent("TabBorder_" id, "MouseRightButtonUp", ((t, *) => OpenTabCtx(t)).Bind(title))
}

global ctxTargetTab := ""
OpenTabCtx(title) {
    global ctxTargetTab, ui
    ctxTargetTab := title
    ui.Update("GlobalTabCtx", "IsOpen", "True")
}

SelectTab(tabTitle, isHistoryNav := false) {
    global openTabs, currentTab, filesData, tabHistory, historyIndex, modifiedFiles, ui

    if (!isHistoryNav && currentTab != tabTitle) {
        if (historyIndex < tabHistory.Length)
            tabHistory.RemoveAt(historyIndex + 1, tabHistory.Length - historyIndex)
        tabHistory.Push(tabTitle)
        historyIndex := tabHistory.Length
    }

    currentTab := tabTitle

    for t in openTabs {
        id := RegExReplace(t, "[^a-zA-Z0-9]", "_")
        isActive := (t == tabTitle)

        bg := isActive ? "{DynamicResource DropdownBg}" : "Transparent"
        overlayVis := isActive ? "Visible" : "Collapsed"
        opacity := isActive ? "1.0" : "0.5"
        bThick := isActive ? "0,2,0,0" : "0"
        bBrush := isActive ? "{DynamicResource Accent}" : "Transparent"

        ui.Update("TabBorder_" id, "Background", bg)
        ui.Update("TabOverlay_" id, "Visibility", overlayVis)
        ui.Update("TabBorder_" id, "BorderThickness", bThick)
        ui.Update("TabBorder_" id, "BorderBrush", bBrush)

        ui.Update("TabText_" id, "Foreground", "{DynamicResource TextMain}")
        ui.Update("TabText_" id, "Opacity", opacity)

        ui.Update("TabClose_" id, "Foreground", "{DynamicResource TextMain}")
        ui.Update("TabClose_" id, "Opacity", opacity)
        
        if (isActive)
            ui.Update("TabBorder_" id, "BringIntoView", "True")
    }

    ui.Update("OmniboxInput", "Text", "C:\projects\ahk\richide\" tabTitle)
    
    ext := "AutoHotkey"
    if InStr(tabTitle, ".rs")
        ext := "Rust"
    else if InStr(tabTitle, ".css")
        ext := "CSS"
    else if InStr(tabTitle, ".md")
        ext := "Markdown"
    ui.Update("StatusBarLang", "Text", ext)

    global fileToParent, fileSystem, lastSelectedFileNode
    isInTree := fileToParent.Has(tabTitle) || (fileSystem.Has(tabTitle) && Type(fileSystem[tabTitle]) != "Map")

    if (fileToParent.Has(tabTitle)) {
        parentName := "FolderNode_" RegExReplace(fileToParent[tabTitle], "[^a-zA-Z0-9]", "_")
        ui.Update(parentName, "IsExpanded", "True")
    }
    
    if (isInTree) {
        fileNodeName := "FileNode_" RegExReplace(tabTitle, "[^a-zA-Z0-9]", "_")
        ui.Update(fileNodeName, "IsSelected", "True")
        ui.Update(fileNodeName, "BringIntoView", "True")
        lastSelectedFileNode := fileNodeName
    } else {
        if (IsSet(lastSelectedFileNode) && lastSelectedFileNode != "") {
            ui.Update(lastSelectedFileNode, "IsSelected", "False")
            lastSelectedFileNode := ""
        }
    }

    ui.Update("MainEditor", "Text", filesData.Has(tabTitle) ? filesData[tabTitle] : "")
}

for t in openTabs {
    BindTabEvents(t)
}

CloseTab(tabTitle) {
    global openTabs, currentTab, ui

    id := RegExReplace(tabTitle, "[^a-zA-Z0-9]", "_")
    ui.Update("TabBorder_" id, "Visibility", "Collapsed")

    newOpenTabs := []
    for t in openTabs {
        if (t != tabTitle)
            newOpenTabs.Push(t)
    }
    openTabs := newOpenTabs

    if (currentTab == tabTitle) {
        if (openTabs.Length > 0)
            SelectTab(openTabs[openTabs.Length])
        else
            ui.Update("MainEditor", "Text", "")
    }
}

CloseTabsRight(tabTitle) {
    global openTabs, currentTab, ui
    found := false
    newTabs := []
    toClose := []

    for t in openTabs {
        if (!found) {
            newTabs.Push(t)
            if (t == tabTitle)
                found := true
        } else {
            toClose.Push(t)
        }
    }

    openTabs := newTabs
    for t in toClose {
        id := RegExReplace(t, "[^a-zA-Z0-9]", "_")
        ui.Update("TabBorder_" id, "Visibility", "Collapsed")
    }

    validCurrent := false
    for t in openTabs {
        if (t == currentTab)
            validCurrent := true
    }
    if (!validCurrent) {
        if (openTabs.Length > 0)
            SelectTab(openTabs[openTabs.Length])
        else
            ui.Update("MainEditor", "Text", "")
    }
}

CloseOtherTabs(tabTitle) {
    global openTabs, currentTab, ui
    newTabs := [tabTitle]
    toClose := []

    for t in openTabs {
        if (t != tabTitle)
            toClose.Push(t)
    }

    openTabs := newTabs
    for t in toClose {
        id := RegExReplace(t, "[^a-zA-Z0-9]", "_")
        ui.Update("TabBorder_" id, "Visibility", "Collapsed")
    }

    SelectTab(tabTitle)
}

ui.OnEvent("BtnNewTab", "Click", HandleNewTab)
HandleNewTab(*) {
    global filesData, openTabs
    newTitle := "Untitled_" (openTabs.Length + 1) ".txt"
    filesData[newTitle] := "New empty file created dynamically."
    AddChromiumTabDynamic(newTitle)
}

ui.OnEvent("BtnMenu", "Click", HandleMenu)
HandleMenu(*) {
    global cmdPalette
    cmdPalette.Open()
}

HandleSettings(*) {
    global ui
    XDialog.Show({ Title: "Settings", Message: "Settings pane would appear here.", Icon: Chr(0xE713), IconColor: "{DynamicResource Accent}", Buttons: ["OK"], Modal: true, Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" })
}

HandleHelp(*) {
    global ui
    XDialog.Show({ Title: "Chromium Clone", Message: "Massively improved dynamic clone. Try adding and closing tabs, right clicking them, or using Ctrl+Shift+P for the command palette!", Icon: Chr(0xE946), IconColor: "{DynamicResource Accent}", Buttons: ["Awesome!"], Modal: true, Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" })
}

ui.OnEvent("BtnNavReload", "Click", HandleReload)
HandleReload(*) {
    global currentTab, filesData, modifiedFiles, ui
    if (filesData.Has(currentTab)) {
        ui.Update("MainEditor", "Text", filesData[currentTab])
        if modifiedFiles.Has(currentTab)
            modifiedFiles.Delete(currentTab)
        id := RegExReplace(currentTab, "[^a-zA-Z0-9]", "_")
        ui.Update("TabText_" id, "Text", currentTab)
    }
}

InitUI(*) {
    ui.Update("AppTitle", "Visibility", "Collapsed")
    SelectTab(currentTab)
}

ui.OnEvent("BtnToggleSidebar", "Click", HandleToggleSidebar)
HandleToggleSidebar(*) {
    global ui, sidebarVisible
    if (!IsSet(sidebarVisible))
        sidebarVisible := true
    sidebarVisible := !sidebarVisible
    vis := sidebarVisible ? "Visible" : "Collapsed"
    
    ui.Update("SidebarContainer", "Visibility", vis)
}

ui.OnEvent("AppGrid", "Loaded", InitUI)

; Start the application
app.Show()