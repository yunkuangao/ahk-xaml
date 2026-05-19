#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; WINDOWS FILE EXPLORER CLONE
; Demonstrates real file system looping, TreeView, and ListView
; ==============================================================================

app := XAML_GUI("File Explorer", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35, AppIcon: false })
app.tabs.Visibility("Collapsed")
app.main.Background("{DynamicResource ControlBg}")

layout := app.main.Add("Grid").Grid_Row(1)
layout.Rows("Auto", "*")

; ==============================================================================
; TOOLBAR & ADDRESS BAR
; ==============================================================================
topBar := layout.Add("Border").Grid_Row(0).Background("{DynamicResource DropdownBg}").Padding("10,8,10,8").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,0,1")
topGrid := topBar.Add("Grid")
topGrid.Cols("Auto", "*", "Auto")

navSp := topGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(0).VerticalAlignment("Center")
navSp.Add("Button").Content(Chr(0xE72B)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Margin("5,0,2,0").FontSize(16).Padding("10").Cursor("Hand")
navSp.Add("Button").Content(Chr(0xE72A)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).Margin("0,0,2,0").FontSize(16).Padding("10").Cursor("Hand")
navSp.Add("Button").Content(Chr(0xE72C)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Margin("0,0,15,0").FontSize(16).Padding("10").Cursor("Hand")

addressBorder := topGrid.Add("Border").Grid_Column(1).Background("{DynamicResource ControlBg}").CornerRadius("4").Padding("10,5,10,5").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").VerticalAlignment("Center")
addressBorder.Add("TextBlock").Name("AddressPath").Text("C:\").Foreground("{DynamicResource TextMain}").FontSize(14).VerticalAlignment("Center")

searchBorder := topGrid.Add("Border").Grid_Column(2).Background("{DynamicResource ControlBg}").CornerRadius("4").Padding("10,5,10,5").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").VerticalAlignment("Center").Margin("15,0,0,0").Width("200")
searchGrid := searchBorder.Add("Grid")
searchGrid.Cols("Auto", "*")
searchGrid.Add("TextBlock").Text(Chr(0xE721)).FontFamily("Segoe Fluent Icons").Foreground("{DynamicResource TextSub}").Grid_Column(0).Margin("0,0,10,0").VerticalAlignment("Center")
searchGrid.Add("TextBlock").Text("Search").Foreground("{DynamicResource TextSub}").Grid_Column(1).VerticalAlignment("Center")

; ==============================================================================
; MAIN CONTENT (SIDEBAR + FILE LIST)
; ==============================================================================
mainContent := layout.Add("DockPanel").Grid_Row(1)

; Sidebar
sidebarContainer := mainContent.Add("Grid").SetProp("DockPanel.Dock", "Left").Width(250)
sidebarBg := sidebarContainer.Add("Border").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0")
sidebarTree := sidebarBg.Add("TreeView").Name("SidebarTree").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextMain}").Margin("10")

; Add some dummy quick access nodes
qa := sidebarTree.Add("TreeViewItem").Header("Quick Access").IsExpanded("True").Foreground("{DynamicResource TextMain}")
qa.Add("TreeViewItem").Header("Desktop").Foreground("{DynamicResource TextSub}")
qa.Add("TreeViewItem").Header("Downloads").Foreground("{DynamicResource TextSub}")
qa.Add("TreeViewItem").Header("Documents").Foreground("{DynamicResource TextSub}")

thisPC := sidebarTree.Add("TreeViewItem").Header("This PC").IsExpanded("True").Foreground("{DynamicResource TextMain}")
thisPC.Add("TreeViewItem").Header("Local Disk (C:)").Name("NavC").Foreground("{DynamicResource TextSub}").SetProp("Tag", "C:\")
thisPC.Add("TreeViewItem").Header("Storage (D:)").Name("NavD").Foreground("{DynamicResource TextSub}").SetProp("Tag", "D:\")

; File List View
listBorder := mainContent.Add("Border").Background("{DynamicResource DropdownBg}")
lv := listBorder.Add("ListView").Name("FileListView").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextMain}")

; Define GridView Columns for ListView
gridView := '<ListView.View><GridView>'
gridView .= '<GridViewColumn Header="Name" Width="300" DisplayMemberBinding="{Binding Path=Name}" />'
gridView .= '<GridViewColumn Header="Date modified" Width="150" DisplayMemberBinding="{Binding Path=Date}" />'
gridView .= '<GridViewColumn Header="Type" Width="120" DisplayMemberBinding="{Binding Path=Type}" />'
gridView .= '<GridViewColumn Header="Size" Width="100" DisplayMemberBinding="{Binding Path=Size}" />'
gridView .= '</GridView></ListView.View>'
; Compile UI
ui := app.Compile()
ui.Update("FileListView", "AddXamlItem", gridView)

; Event Handlers
ui.Update("SidebarTree", "BindEvent", "SelectedItemChanged")
ui.OnEvent("SidebarTree", "SelectedItemChanged", HandleTreeNav)

HandleTreeNav(state, ctrl, ev) {
    global ui
    selected := state["SidebarTree"]
    if (selected == "Local Disk (C:)") {
        LoadDirectory("C:\")
    } else if (selected == "Storage (D:)") {
        LoadDirectory("D:\")
    }
}

LoadDirectory(path) {
    global ui
    ui.Update("AddressPath", "Text", path)
    ui.Update("FileListView", "Items.Clear", "")

    try {
        ; Use AHK Loop to read the actual filesystem
        Loop Files, path "*.*", "FD" 
        {
            if (A_Index > 100) ; Limit to 100 files for demo performance
                break

            typeStr := InStr(A_LoopFileAttrib, "D") ? "File folder" : A_LoopFileExt " File"
            sizeStr := InStr(A_LoopFileAttrib, "D") ? "" : Round(A_LoopFileSize / 1024) " KB"
            
            ; We use a C# Dictionary (injected via AHK-XAML) or simple ListViewItems. 
            ; Since ListView DataBinding requires objects with properties, we can manually create ListViewItems for simplicity if dynamic objects aren't configured.
            ; Actually, XAML_GUI allows creating items dynamically.
            
            item := '<ListViewItem Foreground="{DynamicResource TextMain}"><StackPanel Orientation="Horizontal">'
            item .= '<TextBlock Text="' (InStr(A_LoopFileAttrib, "D") ? Chr(0xE8B7) : Chr(0xE8A5)) '" FontFamily="Segoe Fluent Icons" Margin="0,0,10,0" Foreground="' (InStr(A_LoopFileAttrib, "D") ? "{DynamicResource Accent}" : "{DynamicResource TextSub}") '"/>'
            item .= '<TextBlock Text="' A_LoopFileName '" Width="280"/>'
            item .= '<TextBlock Text="' A_LoopFileTimeModified '" Width="150" Foreground="{DynamicResource TextSub}"/>'
            item .= '<TextBlock Text="' typeStr '" Width="120" Foreground="{DynamicResource TextSub}"/>'
            item .= '<TextBlock Text="' sizeStr '" Width="100" Foreground="{DynamicResource TextSub}"/>'
            item .= '</StackPanel></ListViewItem>'
            
            ui.Update("FileListView", "AddXamlItem", item)
        }
    } catch as e {
        ui.Update("FileListView", "AddXamlItem", '<ListViewItem><TextBlock Text="Access Denied or Path not found: ' path '" Foreground="Red"/></ListViewItem>')
    }
}

; Initial Load
LoadDirectory("C:\")

app.Show()
