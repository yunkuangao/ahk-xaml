#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"
#Include "../../lib/AXML.ahk"
#Include "../../lib/XAML_Adv_Components.ahk"
#Include "../../lib/XAML_Dialog.ahk"

; ==============================================================================
; STATE & MEMORY
; ==============================================================================
global AppState := {
    ActiveTabId: 1,
    NextTabId: 2,
    SaveMode: 0, ; 0 = Memory, 1 = Temp File, 2 = Local File
    isSnapEnabled: true,
    Graphs: Map()
}

global Graphs := Map()
global InMemoryState := Map()

; ==============================================================================
; UI INITIALIZATION
; ==============================================================================
app := XAML_GUI("Node Studio - AHK-XAML", { Sidebar: false, AppIcon: true, BurgerMenu: false })

AXML_TEMPLATE := FileRead("node_editor.axml")
result := AXML.ParseString(AXML_TEMPLATE, app.main, AppState)

; The single NodeGraph instance we manage (we will hot-swap the canvas to emulate tabs)
; Actually, wait. XNodeGraph creates UI elements inside `GraphContainer`.
; The easiest way to do multiple tabs with XNodeGraph is to instantiate multiple XNodeGraphs
; and toggle their Visibility!

; Wait, XNodeGraph creates elements inside the container.
; Let's create multiple XNodeGraphs, each in its own container grid.

; ==============================================================================
; TAB AND GRAPH MANAGEMENT
; ==============================================================================

CreateNewTab(id, isInitial := false) {
    global ui, app
    
    ; Create a new graph container
    containerName := "GraphTab_" id
    
    if (!isInitial) {
        ; Inject the container into the AXML visual tree
        ui.Update("GraphContainer", "AddXamlItem", "<Grid xmlns=`"http://schemas.microsoft.com/winfx/2006/xaml/presentation`" Name=`"" containerName "`" Visibility=`"Collapsed`" Background=`"Transparent`" />")
    } else {
        ; Initial container was built before Compile, so we can just add it
        app.main.Find("GraphContainer").Add("Grid").Name(containerName).Visibility("Collapsed").Background("Transparent")
    }
    
    ; Create the graph instance (pass the tab's specific Grid container instead of the main GraphContainer)
    ; And pass the correct ID for the Canvas
    containerElement := isInitial ? app.main.Find(containerName) : ""
    graph := XNodeGraph(containerElement, containerName "_Canvas")
    
    AppState.Graphs[id] := graph
    
    ; If UI is already compiled, we must push the graph canvas manually
    if (!isInitial) {
        xamlStr := graph.canvas.ToString()
        xamlStr := StrReplace(xamlStr, "<Canvas ", "<Canvas xmlns=`"http://schemas.microsoft.com/winfx/2006/xaml/presentation`" ")
        ui.Update(containerName, "AddXamlItem", xamlStr)
        graph.Bind(ui)
        graph.EnableDrag(ui, true)
    }
}

; 1. Create the initial tab before compile so AXML parser captures it
CreateNewTab(1, true)

ui := app.Compile()
AXML.BindAll(ui, result, AppState)

; 2. Bind the initial graph after compile
AppState.Graphs[1].Bind(ui)

; Apply Theme
ui.OnEvent("Window", "Loaded", InitApp)

InitApp(*) {
    ui.Update("Window", "DWM", "2,1") ; Dark Mica
    ui.Update("Resource", "SolidBg", "#FF181818")
    ui.Update("Resource", "SolidSidebar", "#FF202020")
    ui.Update("Resource", "SolidControl", "#FF252525")
    ui.Update("Resource", "SolidBorder", "#FF333333")
    ui.Update("Resource", "Accent", "#FF60A0FF")
    ui.Update("Resource", "TextMain", "White")
    ui.Update("Resource", "TextSub", "#FFAAAAAA")
    ui.Update("Resource", "ControlBg", "#FF2D2D2D")
    ui.Update("Resource", "ControlBorder", "#FF3E3E42")
    ui.Update("Resource", "DropdownBg", "#FF252526")

    AppState.Graphs[1].EnableDrag(ui, true)
    
    ; Add Example Nodes with spatial layout
    graph := AppState.Graphs[1]
    
    ; Input Node
    graph.lastRightClickX := graph.offsetX + 150
    graph.lastRightClickY := graph.offsetY + 300
    graph.OnNewNode("Input", Map(), "", "")
    
    ; Process Node
    graph.lastRightClickX := graph.offsetX + 450
    graph.lastRightClickY := graph.offsetY + 250
    graph.OnNewNode("Process", Map(), "", "")
    
    ; Output Node
    graph.lastRightClickX := graph.offsetX + 750
    graph.lastRightClickY := graph.offsetY + 350
    graph.OnNewNode("Output", Map(), "", "")
    
    ; Connect them programmatically to demonstrate links!
    ; Since we just spawned them, they are GraphTab_1_Canvas_Node1, etc
    graph.AddConnection("GraphTab_1_Canvas_Node1", "GraphTab_1_Canvas_Node2")
    graph.AddConnection("GraphTab_1_Canvas_Node2", "GraphTab_1_Canvas_Node3")
    
    SetToolMode("Pan", "BtnModePan")
    ui.OnEvent("BtnSnapToggle", "Click", (*) => ToggleSnap())
    
    AddTabUI(1)
    SelectTab(1)
}

ToggleSnap() {
    AppState.isSnapEnabled := !AppState.isSnapEnabled
    graph := AppState.Graphs[AppState.ActiveTabId]
    graph.SetGridSnap(ui, AppState.isSnapEnabled)
    
    ; Update button styling
    bg := AppState.isSnapEnabled ? "{DynamicResource Accent}" : "Transparent"
    fg := AppState.isSnapEnabled ? "White" : "{DynamicResource TextMain}"
    tt := AppState.isSnapEnabled ? "Toggle Grid Snap (On)" : "Toggle Grid Snap (Off)"
    
    ui.Update("BtnSnapToggle", "Background", bg)
    ui.Update("BtnSnapToggle", "Foreground", fg)
    ui.Update("BtnSnapToggle", "ToolTip", tt)
}

; ==============================================================================
; STATE MANAGEMENT (MEMORY, TEMP, LOCAL)
; ==============================================================================

ui.OnEvent("CbSaveMode", "SelectionChanged", (state, ctrl, event) => AppState.SaveMode := Integer(state[ctrl]))

ui.OnEvent("BtnSave", "Click", (*) => SaveCurrentState())
ui.OnEvent("BtnLoad", "Click", (*) => LoadCurrentState())

HotIfWinActive("Node Studio - AHK-XAML")
Hotkey("^s", (*) => SaveCurrentState(), "On")
Hotkey("^o", (*) => LoadCurrentState(), "On")
HotIf()

SaveCurrentState() {
    graphId := AppState.ActiveTabId
    mode := AppState.SaveMode
    if !AppState.Graphs.Has(graphId)
        return
        
    graph := AppState.Graphs[graphId]
    tempFile := A_Temp "\AhkNodeEditor_Temp.ini"
    
    if (mode == 0) {
        ; Memory: Save to temp, read to string, delete temp
        graph.SaveState(tempFile)
        InMemoryState[graphId] := FileRead(tempFile)
        FileDelete(tempFile)
        ToolTip("Saved Graph " graphId " to Memory")
    } else if (mode == 1) {
        ; Temp file
        graph.SaveState(A_Temp "\AhkNodeEditor_Tab_" graphId ".ini")
        ToolTip("Saved Graph " graphId " to Temp File")
    } else {
        ; Local file
        graph.SaveState(A_ScriptDir "\AhkNodeEditor_Tab_" graphId ".ini")
        ToolTip("Saved Graph " graphId " to Local File")
    }
    SetTimer(() => ToolTip(), -2000)
}

LoadCurrentState() {
    graphId := AppState.ActiveTabId
    mode := AppState.SaveMode
    if !AppState.Graphs.Has(graphId)
        return
        
    graph := AppState.Graphs[graphId]
    tempFile := A_Temp "\AhkNodeEditor_TempLoad.ini"
    
    if (mode == 0) {
        if InMemoryState.Has(graphId) {
            if FileExist(tempFile)
                FileDelete(tempFile)
            FileAppend(InMemoryState[graphId], tempFile)
            graph.LoadState(tempFile, ui)
            FileDelete(tempFile)
            ToolTip("Loaded Graph " graphId " from Memory")
        }
    } else if (mode == 1) {
        path := A_Temp "\AhkNodeEditor_Tab_" graphId ".ini"
        if FileExist(path)
            graph.LoadState(path, ui)
    } else {
        path := A_ScriptDir "\AhkNodeEditor_Tab_" graphId ".ini"
        if FileExist(path)
            graph.LoadState(path, ui)
    }
    SetTimer(() => ToolTip(), -2000)
}

; ==============================================================================
; TAB MANAGEMENT
; ==============================================================================

ui.OnEvent("BtnNewTab", "Click", (*) => CreateTab())

CreateTab() {
    id := AppState.NextTabId++
    CreateNewTab(id)
    AddTabUI(id)
    SelectTab(id)
}

AddTabUI(id) {
    xamlStr := '<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Name="BtnTab_' id '" Margin="0,0,0,4" Background="Transparent" BorderThickness="0" HorizontalContentAlignment="Left" Padding="15,8" Cursor="Hand"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock Text="Graph ' id '" Foreground="{DynamicResource TextMain}" FontSize="13" VerticalAlignment="Center"/><TextBlock Grid.Column="1" Name="BtnTabActive_' id '" Text="&#xE73E;" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Foreground="{DynamicResource Accent}" FontSize="10" VerticalAlignment="Center" Visibility="Collapsed"/></Grid></Button>'
    ui.Update("TabList", "AddXamlItem", xamlStr)
    
    ; We must use a short delay so WPF can parse the new item before we bind events
    SetTimer(() => ui.OnEvent("BtnTab_" id, "Click", HandleTabClick.Bind(id)), -100)
}

HandleTabClick(id, args*) {
    SelectTab(id)
}

SelectTab(id) {
    ; Save current state before switching
    if (AppState.ActiveTabId != id) {
        SaveCurrentState()
    }
    
    ; Update Visuals
    oldId := AppState.ActiveTabId
    try ui.Update("BtnTabActive_" oldId, "Visibility", "Collapsed")
    try ui.Update("BtnTab_" oldId, "Background", "Transparent")
    
    ; Hide old graph container, show new graph container
    try ui.Update("GraphTab_" oldId, "Visibility", "Collapsed")
    
    AppState.ActiveTabId := id
    
    try ui.Update("BtnTabActive_" id, "Visibility", "Visible")
    try ui.Update("BtnTab_" id, "Background", "{DynamicResource ControlBg}")
    try ui.Update("GraphTab_" id, "Visibility", "Visible")
    
    ; Load new state if it exists
    LoadCurrentState()
}

; ==============================================================================
; NODE PALETTE TOOLS
; ==============================================================================

ui.OnEvent("BtnAddInput", "Click", (*) => AppState.Graphs[AppState.ActiveTabId].OnNewNode("Input", Map(), "", ""))
ui.OnEvent("BtnAddProcess", "Click", (*) => AppState.Graphs[AppState.ActiveTabId].OnNewNode("Process", Map(), "", ""))
ui.OnEvent("BtnAddMultiProcess", "Click", (*) => AppState.Graphs[AppState.ActiveTabId].OnNewNode("MultiProcess", Map(), "", ""))
ui.OnEvent("BtnAddOutput", "Click", (*) => AppState.Graphs[AppState.ActiveTabId].OnNewNode("Output", Map(), "", ""))

; ==============================================================================
; TOOLBAR MODES & CONTROLS
; ==============================================================================

SetToolMode(mode, activeBtn) {
    ui.Update("GraphTab_" AppState.ActiveTabId "_Canvas", "SetCanvasMode", mode)
    
    ui.Update("BtnModeSelect", "Background", "Transparent")
    ui.Update("BtnModePan", "Background", "Transparent")
    ui.Update("BtnModeSlice", "Background", "Transparent")
    
    ui.Update(activeBtn, "Background", "{DynamicResource ControlBorder}")
}

ui.OnEvent("BtnModeSelect", "Click", (*) => SetToolMode("Select", "BtnModeSelect"))
ui.OnEvent("BtnModePan", "Click", (*) => SetToolMode("Pan", "BtnModePan"))
ui.OnEvent("BtnModeSlice", "Click", (*) => SetToolMode("Knife", "BtnModeSlice"))

ui.OnEvent("BtnZoomFit", "Click", (*) => ui.Update("GraphTab_" AppState.ActiveTabId "_Canvas", "ZoomAll", ""))
ui.OnEvent("BtnZoomIn", "Click", (*) => ui.Update("GraphTab_" AppState.ActiveTabId "_Canvas", "Zoom", "1.25"))
ui.OnEvent("BtnZoomOut", "Click", (*) => ui.Update("GraphTab_" AppState.ActiveTabId "_Canvas", "Zoom", "0.8"))

app.Show()

