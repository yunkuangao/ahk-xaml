#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; Initialize the App Engine
app := XAML_GUI("Excel-like Ribbon Interface")

; We don't want the default tab control for a full-window ribbon app.
app.tabs.Visibility("Collapsed")

; Inject the Ribbon into the top row, spanning the title bar
mainContent := app.main.Add("Grid").Grid_Row(0).Grid_RowSpan(2)
mainContent.Rows("Auto", "*")

; 1. Create the Ribbon Container at the top
ribbonContainer := mainContent.Add("Border").Grid_Row(0)
ribbon := XRibbon(ribbonContainer)

; Push the tabs inline with the Hamburger Menu / Window Title!
ribbon.tabCtrl.Padding("280,12,0,0")

; ------------------------------------------------------------------------------
; TAB 1: HOME
; ------------------------------------------------------------------------------
homeTab := ribbon.AddTab("HOME")

; Group: Clipboard
grpClip := homeTab.AddGroup("Clipboard")
grpClip.AddLargeBtn("BtnPaste", "Paste", 0xE77F)
clipStack := grpClip.AddVerticalStack()
clipStack.AddSmallBtn("BtnCut", "Cut", 0xE8C6)
clipStack.AddSmallBtn("BtnCopy", "Copy", 0xE8C8)
clipStack.AddSmallBtn("BtnFmt", "Format Painter", 0xE790)

; Group: Font
grpFont := homeTab.AddGroup("Font")
grpFont.AddLargeBtn("BtnFont", "Font Settings", 0xE8D2)
grpFont.AddSeparator()
fontStack1 := grpFont.AddVerticalStack()
fontStack1.AddSmallBtn("BtnBold", "Bold", 0xE8DD)
fontStack1.AddSmallBtn("BtnItalic", "Italic", 0xE8DB)
fontStack1.AddSmallBtn("BtnUnder", "Underline", 0xE8DC)
fontStack2 := grpFont.AddVerticalStack()
fontStack2.AddSmallBtn("BtnColor", "Text Color", 0xE790)
fontStack2.AddSmallBtn("BtnHighlight", "Highlight", 0xE7E6)

; Group: Alignment
grpAlign := homeTab.AddGroup("Alignment")
alignLeftStack := grpAlign.AddVerticalStack()
alignLeftStack.AddSmallBtn("BtnAlignLeft", "Left", 0xE8E4)
alignLeftStack.AddSmallBtn("BtnAlignCenter", "Center", 0xE8E3)
alignLeftStack.AddSmallBtn("BtnAlignRight", "Right", 0xE8E2)
grpAlign.AddSeparator()
grpAlign.AddLargeBtn("BtnMerge", "Merge & Center", 0xE7EA)

; ------------------------------------------------------------------------------
; TAB 2: INSERT
; ------------------------------------------------------------------------------
insertTab := ribbon.AddTab("INSERT")

grpTables := insertTab.AddGroup("Tables")
grpTables.AddLargeBtn("BtnTable", "Table", 0xE8D2)
grpTables.AddLargeBtn("BtnPivot", "PivotTable", 0xE920)

grpIllus := insertTab.AddGroup("Illustrations")
grpIllus.AddLargeBtn("BtnPic", "Pictures", 0xE8B9)
illusStack := grpIllus.AddVerticalStack()
illusStack.AddSmallBtn("BtnShapes", "Shapes", 0xE81E)
illusStack.AddSmallBtn("BtnIcons", "Icons", 0xED56)

; ------------------------------------------------------------------------------
; TAB 3: VIEW
; ------------------------------------------------------------------------------
viewTab := ribbon.AddTab("VIEW")

grpWindow := viewTab.AddGroup("Window")
grpWindow.AddLargeBtn("BtnNewWin", "New Window", 0xE8A5)
grpWindow.AddLargeBtn("BtnArrange", "Arrange All", 0xE8A6)
grpWindow.AddSeparator()
winStack := grpWindow.AddVerticalStack()
winStack.AddSmallBtn("BtnFreeze", "Freeze Panes", 0xE81E)
winStack.AddSmallBtn("BtnSplit", "Split", 0xE8A6)


; ------------------------------------------------------------------------------
; MAIN DOCUMENT AREA
; ------------------------------------------------------------------------------
docArea := mainContent.Add("Border").Name("DocArea").Grid_Row(1).Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,1,0,0")
docArea.Add("TextBlock").Text("Your Excel spreadsheet or document goes here!").HorizontalAlignment("Center").VerticalAlignment("Center").Foreground("{DynamicResource TextSub}").FontSize(16)

; ------------------------------------------------------------------------------
; XAML BUILD CONFIGURATION
; ------------------------------------------------------------------------------
; Toggle XAML_DEBUG in lib\XAML_Config.ahk to switch between Dev and Prod!
if (XAML_DEBUG) {
    ; Development Mode: Generate the UI dynamically every time.
    ui := app.Compile()
} else {
    ; Production Mode: Compile into a standalone DLL on first run,
    ; then bypass XAML generation and boot straight from the DLL instantly!
    ui := app.Compile("ribbon_example_compiled.dll")
}

; Bind Events
ribbon.BindEvents(ui)
ui.OnEvent("BtnPaste", "Click", (*) => app.ShowSnackbar("Pasted content!"))
ui.OnEvent("BtnBold", "Click", (*) => app.ShowSnackbar("Toggled Bold!"))
ui.OnEvent("BtnTable", "Click", (*) => app.ShowSnackbar("Inserted Table!"))
ui.OnEvent("DocArea", "PreviewMouseLeftButtonDown", OnDocClick)

; Show the Window!
app.Show()

OnDocClick(state, ctrl, event) {
    if (!ribbon.isPinned) {
        ribbon.Collapse()
        ribbon.UpdateHost()
    }
}

Persistent()