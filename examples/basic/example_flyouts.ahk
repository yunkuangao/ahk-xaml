#Requires AutoHotkey v2.0
#Include "..\../lib\XAML_GUI.ahk"
#Include "..\../lib\XAML_Adv_Components.ahk"

; Initialize App with the built-in sidebar enabled to show they can coexist
app := XAML_GUI("Flyout Component Demo", { Sidebar: true })

; Create an inner grid to manage our custom flyout layout
layout := app.main.Add("Grid").Grid_Row(1)
layout.Rows("Auto", "*", "Auto")
layout.Cols("Auto", "Auto", "*", "Auto") ; Notice the two 'Auto' columns for stacking Left sidebars!

; Center Content Area
content := layout.Add("Border").Grid_Row(1).Grid_Column(2).Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Margin("10").CornerRadius("8")
sp := content.Add("StackPanel").VerticalAlignment("Center").HorizontalAlignment("Center")
sp.Add("TextBlock").Text("Flyout System Demo").Use("PageTitle").HorizontalAlignment("Center")
sp.Add("TextBlock").Text("Use the buttons below or hotkeys to trigger flyouts.").Use("BodyText").HorizontalAlignment("Center").Margin("0,10,0,20")

btnGrid := sp.Add("Grid").HorizontalAlignment("Center")
btnGrid.Cols("Auto", "Auto", "Auto")
btnGrid.Rows("Auto", "Auto")

btnLeft := btnGrid.Add("Button").Content("Toggle Left (Push)").Name("BtnLeft").Grid_Row(0).Grid_Column(0).Margin("5")
    .On("Click", (*) => flyLeft.Toggle())
btnRight := btnGrid.Add("Button").Content("Toggle Right (Overlay)").Name("BtnRight").Grid_Row(0).Grid_Column(1).Margin("5")
    .On("Click", (*) => flyRight.Toggle())
btnGlobal := btnGrid.Add("Button").Content("Toggle Global (Overlay)").Name("BtnGlobal").Grid_Row(0).Grid_Column(2).Margin("5")
    .On("Click", (*) => flyGlobal.Toggle())
btnTop := btnGrid.Add("Button").Content("Toggle Top (PopPush)").Name("BtnTop").Grid_Row(1).Grid_Column(0).Margin("5")
    .On("Click", (*) => flyTop.Toggle())
btnBottom := btnGrid.Add("Button").Content("Toggle Bottom (PopOverlay)").Name("BtnBottom").Grid_Row(1).Grid_Column(1).Margin("5")
    .On("Click", (*) => flyBottom.Toggle())

; 6. Sub-Flyout Example (Contained within a specific card/panel)
subCard := sp.Add("Border").Width(400).Height(200).Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("8").Margin("0,40,0,0")
subGrid := subCard.Add("Grid").ClipToBounds("True")
subGrid.Cols("Auto", "*")

subContent := subGrid.Add("StackPanel").Grid_Column(1).Margin("20").VerticalAlignment("Center")
subContent.Add("TextBlock").Text("Sub-Flyout Demo").FontWeight("Bold").FontSize(16).Margin("0,0,0,10")
subContent.Add("TextBlock").Text("This flyout is completely confined to this specific card container.").Foreground("{DynamicResource TextSub}").Margin("0,0,0,15").TextWrapping("Wrap")
btnSub := subContent.Add("Button").Content("Toggle Sub-Flyout").Name("BtnSub").HorizontalAlignment("Left")
    .On("Click", (*) => flySub.Toggle())

flySub := XFlyout("SubMenu", "Left", "Push", 150)
flySub.Build(subGrid).Grid_Column(0)
flySub.container.Add("TextBlock").Text("Nested Menu").Margin("20").Foreground("{DynamicResource Accent}").FontWeight("Bold")


; 1. Left Flyout (Push Mode) - occupies Column 0
flyLeft := XFlyout("Menu", "Left", "Push", 250)
flyLeft.Build(layout).Grid_RowSpan(3).Grid_Column(0)
flyLeft.Hotkey("^+L")  ; Ctrl+Shift+L
navSp := flyLeft.container.Add("StackPanel").Margin("10")
navSp.Add("TextBlock").Text("DASHBOARD").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold").Margin("10,10,10,20")

; Use transparent buttons with left alignment for nav menu
navSp.Add("Button").Content(Chr(0xE80F) "  Home").Background("Transparent").BorderThickness("0").HorizontalAlignment("Left").Foreground("{DynamicResource TextMain}").FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets, Segoe UI").Margin("0,0,0,10")
navSp.Add("Button").Content(Chr(0xE9D9) "  Analytics").Background("Transparent").BorderThickness("0").HorizontalAlignment("Left").Foreground("{DynamicResource TextMain}").FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets, Segoe UI").Margin("0,0,0,10")
navSp.Add("Button").Content(Chr(0xE713) "  Settings").Background("Transparent").BorderThickness("0").HorizontalAlignment("Left").Foreground("{DynamicResource TextMain}").FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets, Segoe UI").Margin("0,0,0,10")

; 2. Right Flyout (Overlay Mode) - occupies Column 2, spans backwards
flyRight := XFlyout("Settings", "Right", "Overlay", 300)
flyRight.Build(layout).Grid_RowSpan(3).Grid_ColumnSpan(3)
flyRight.Hotkey("^+R")  ; Ctrl+Shift+R
rightSp := flyRight.container.Add("StackPanel").Margin("20")
rightSp.Add("TextBlock").Text("PROPERTIES").Use("PageTitle").Margin("0,0,0,20")
rightSp.Add("TextBlock").Text("Enable Fast Sync").Foreground("{DynamicResource TextSub}")
; Use CheckBox for ToggleSwitch
rightSp.Add("CheckBox").Style("{StaticResource ToggleSwitch}").IsChecked("True").Margin("0,5,0,20")
rightSp.Add("TextBlock").Text("Opacity").Foreground("{DynamicResource TextSub}")
rightSp.Add("Slider").Minimum("0").Maximum("100").Value("80").Margin("0,5,0,0")

; 3. Top Flyout (PopPush Mode) - occupies Row 0
flyTop := XFlyout("Banner", "Top", "PopPush", 60)
flyTop.Build(layout).Grid_ColumnSpan(3).Grid_Row(0)
flyTop.Hotkey("^+T")  ; Ctrl+Shift+T
flyTop.container.Background("#1A73E8") ; Blue notification banner
topGrid := flyTop.container.Add("Grid").Margin("20,0")
topGrid.Cols("Auto", "*", "Auto")
topGrid.Add("TextBlock").Text(Chr(0xE9CE)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("White").VerticalAlignment("Center").FontSize(18).Grid_Column(0).Margin("0,0,15,0")
topGrid.Add("TextBlock").Text("A new software update is available. Restart to apply.").Foreground("White").VerticalAlignment("Center").FontWeight("SemiBold").Grid_Column(1)
closeTopBtn := topGrid.Add("Button").Content(Chr(0xE711)).Use("IconBtn").FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("White").Grid_Column(2).Name("BtnCloseTop")
    .On("Click", (*) => flyTop.Toggle())

; 4. Bottom Flyout (PopOverlay Mode) - occupies Row 2
flyBottom := XFlyout("Console", "Bottom", "PopOverlay", 200)
flyBottom.Build(layout).Grid_ColumnSpan(3).Grid_RowSpan(3)
flyBottom.Hotkey("^+B")  ; Ctrl+Shift+B
flyBottom.container.Background("#0C0C0C").BorderBrush("#333333").BorderThickness("0,1,0,0")
consoleSp := flyBottom.container.Add("StackPanel").Margin("20")
consoleSp.Add("TextBlock").Text("TERMINAL").Foreground("#888888").FontSize(10).FontWeight("Bold").Margin("0,0,0,10")
consoleSp.Add("TextBlock").Text("> Initializing XAML engine...").Foreground("#00FF00").FontFamily("Consolas").Margin("0,2")
consoleSp.Add("TextBlock").Text("> Compiling UI components... Done.").Foreground("#00FF00").FontFamily("Consolas").Margin("0,2")
consoleSp.Add("TextBlock").Text("> Ready.").Foreground("#00FF00").FontFamily("Consolas").Margin("0,2")

; 5. Global Overlay (Covers the entire app including original sidebar/tabs)
flyGlobal := XFlyout("GlobalMenu", "Left", "Overlay", 350, true)
flyGlobal.Build(app.overlay).Margin("0,50,0,0")
flyGlobal.Hotkey("^+G")  ; Ctrl+Shift+G
globalGrid := flyGlobal.container.Add("Grid").Margin("20")
globalGrid.Rows("Auto", "*")
headerGrid := globalGrid.Add("Grid").Grid_Row(0).Margin("0,0,0,30")
headerGrid.Cols("*", "Auto")
headerGrid.Add("TextBlock").Text("SETTINGS").Use("PageTitle").Grid_Column(0)
closeBtn := headerGrid.Add("Button").Content(Chr(0xE711)).Use("IconBtn").FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Grid_Column(1).Name("BtnCloseGlobal")
    .On("Click", (*) => flyGlobal.Toggle())

contentSp := globalGrid.Add("StackPanel").Grid_Row(1)
contentSp.Add("TextBlock").Text("Global Overlay Menu").Foreground("{DynamicResource TextSub}").Margin("0,0,0,30")
contentSp.Add("TextBlock").Text("THEME ENGINE").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold").Margin("0,0,0,10")
cb := contentSp.Add("ComboBox").Margin("0,0,0,30")
cb.Add("ComboBoxItem").Content("Dark Mode")
cb.Add("ComboBoxItem").Content("Light Frosted Mode").IsSelected("True")

contentSp.Add("TextBlock").Text("INTERFACE SCALE").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold").Margin("0,0,0,10")
cb2 := contentSp.Add("ComboBox")
cb2.Add("ComboBoxItem").Content("Compact")
cb2.Add("ComboBoxItem").Content("Balanced").IsSelected("True")

; Compile UI
ui := app.Compile()

app.Show()