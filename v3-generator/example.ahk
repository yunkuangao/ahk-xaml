#Requires AutoHotkey v2.0

#Include "../v2-csc/xaml.ahk"
#Include "XAML_Generator.ahk"

; ==========================================
; CUSTOM POWER-TOOLS (Injected into Generator)
; ==========================================

XAMLElement.Prototype.DefineProp("TelemetryRow", { Call: TelemetryRow })
TelemetryRow(this, id, location, latencyMs, status, statusColor) {
    rowGrid := this.Add("ListBoxItem").Add("Grid")
    rowGrid.Cols("120", "170", "80", "*")
    rowGrid.Add("TextBlock").Grid_Column(0).Text(id).Foreground("{DynamicResource TextMain}").Margin("10,0,0,0").VerticalAlignment("Center")
    rowGrid.Add("TextBlock").Grid_Column(1).Text(location).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")
    rowGrid.Add("TextBlock").Grid_Column(2).Text(latencyMs).Foreground(statusColor).VerticalAlignment("Center")

    border := rowGrid.Add("Border").Grid_Column(3).Background("#20" StrReplace(statusColor, "#", "")).HorizontalAlignment("Left").Padding("8,3").CornerRadius(4)
    border.Add("TextBlock").Text(status).Foreground(statusColor).FontSize(10).FontWeight("Bold")
    return this
}

XAMLElement.Prototype.DefineProp("Toggle", { Call: Toggle })
Toggle(this, name, label, isChecked := false, tooltip := "") {
    grid := this.Add("Grid").Margin("0,0,0,15")
    grid.Add("TextBlock").Text(label).Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")
    chk := grid.Add("CheckBox").Name(name).Style("{StaticResource ToggleSwitch}").HorizontalAlignment("Right")
    if (isChecked)
        chk.IsChecked()
    if (tooltip != "")
        chk.ToolTip(tooltip)
    return this
}

XAMLElement.Prototype.DefineProp("SegmentGroup", { Call: SegmentGroup })
SegmentGroup(this, groupName, options, selectedIndex := 1) {
    border := this.Add("Border").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).CornerRadius(6).HorizontalAlignment("Left").Margin("0,0,0,25")
    sp := border.Add("StackPanel").Orientation("Horizontal")
    for index, opt in options {
        rb := sp.Add("RadioButton").Style("{StaticResource SegmentedBtn}").Content(opt).GroupName(groupName)
        if (index == selectedIndex)
            rb.IsChecked()
        if (index < options.Length)
            rb.BorderThickness("0,0,1,0")
        else
            rb.BorderThickness("0")
    }
    return this
}

; ==========================================
; EXAMPLE USAGE COMPILING YOUR UI
; ==========================================

X := XAML_Generator("Grid").Name("AppGrid").Background("{DynamicResource BgColor}")
X.Cols("240", "*")

; SIDEBAR (Col 0)
sidebar := X.Add("Border").Name("SidebarBorder").Grid_Column(0).Background("{DynamicResource SidebarColor}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0")

; Global default for TextBlocks in the sidebar
sidebar.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,12" })

sp := sidebar.Add("StackPanel").Margin("25,35,25,25")

sp.Add("TextBlock").Name("TxtLogo").Text("✦ FLUID UI").FontSize(22).FontWeight("Black").Foreground("{DynamicResource TextMain}").Margin("0,0,0,40")
sp.Add("TextBlock").Text("THEME ENGINE")
sp.Add("RadioButton").Name("RadDarkMica").Content("Dark Mica (Win 11)").IsChecked()
sp.Add("RadioButton").Name("RadDarkAcrylic").Content("Dark Acrylic (Win 10)")
sp.Add("RadioButton").Name("RadLightMica").Content("Light Frosted Mode")
sp.Add("RadioButton").Name("RadCyber").Content("Cyberpunk Neon")

sp.Add("TextBlock").Text("SYSTEM TOGGLES").Margin("0,15,0,15")
sp.Toggle("TglOverdrive", "Overdrive Mode", true, "Accelerate packet processing natively.")
sp.Toggle("TglProxy", "Anonymous Proxy", false)

; MAIN CONTENT (Col 1)
main := X.Add("Grid").Grid_Column(1)
main.Rows("50", "*", "90")

; Close Button Area (Row 0)
dragArea := main.Add("Border").Name("DragArea").Grid_Row(0).Background("Transparent").Cursor("SizeAll")
dragArea.Add("Button").Name("BtnClose").Width(45).Height(35).HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,10,10,0").Background("Transparent").BorderThickness(0).Cursor("Hand").ToolTip("Close Application")
    .Add("TextBlock").Text("✕").Foreground("{DynamicResource TextSub}").FontSize(16).VerticalAlignment("Center").HorizontalAlignment("Center")

; Tab Control (Row 1)
tabs := main.Add("TabControl").Grid_Row(1).Margin("40,0,40,10")

; DEPLOYMENT TAB
tab1 := tabs.Add("TabItem").Header("DEPLOYMENT")
sv1 := tab1.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Margin("0,10,0,0")
panel1 := sv1.Add("StackPanel").Margin("0,10,15,20")

; Define a default style for all TextBlocks inside panel1 (and its children)
panel1.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

head := panel1.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,5")
head.Add("TextBlock").Text("Interactive Components").FontSize(28).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").Margin("0")
head.Add("Border").Background("#200A84FF").CornerRadius(10).Padding("10,4").Margin("15,0,0,0").VerticalAlignment("Center")
    .Add("TextBlock").Text("v2.0 ACTIVE").Foreground("{DynamicResource Accent}").FontSize(10).FontWeight("Bold").Margin("0")

panel1.Add("TextBlock").Text("XAML natively binds elements. DynamicResources theme everything instantly.").FontSize(13).FontWeight("Normal").Margin("0,0,0,25").TextWrapping("Wrap")

credGrid := panel1.Add("Grid").Margin("0,0,0,25")
credGrid.Cols("*", "20", "*")
userSp := credGrid.Add("StackPanel").Grid_Column(0)
userSp.Add("TextBlock").Text("USERNAME")
userSp.Add("TextBox").Name("TxtUser").Text("Administrator").ToolTip("Must be an Active Directory alias")

passSp := credGrid.Add("StackPanel").Grid_Column(2)
passSp.Add("TextBlock").Text("SECURITY PIN")
passSp.Add("PasswordBox").Name("TxtPass").Password("hiddenpassword")

regionSp := panel1.Add("StackPanel").Margin("0,0,0,25")
regionSp.Add("TextBlock").Text("SERVER REGION")
combo := regionSp.Add("ComboBox").Name("ComboRegion").SelectedIndex(0).Height(40)
combo.Add("ComboBoxItem").Content("US-East-1 (N. Virginia)")
combo.Add("ComboBoxItem").Content("EU-West-2 (London)")
combo.Add("ComboBoxItem").Content("AP-Northeast-1 (Tokyo)")

panel1.Add("TextBlock").Text("PRIORITY TIER")
panel1.SegmentGroup("Priority", ["LOW", "BALANCED", "MAXIMUM"], 2)

expndr := panel1.Add("Expander").Margin("0,0,0,25")
expndr.Add("Expander.Header").Add("TextBlock").Text("Advanced Connection Settings").FontWeight("SemiBold").FontSize(13).Margin("0")
expSp := expndr.Add("StackPanel").Margin("0,10,0,0")
expSp.Add("TextBlock").Text("ENCRYPTION ALGORITHM")
expCombo := expSp.Add("ComboBox").SelectedIndex(1).Height(40)
expCombo.Add("ComboBoxItem").Content("AES-128-GCM")
expCombo.Add("ComboBoxItem").Content("AES-256-CBC (Recommended)")
expCombo.Add("ComboBoxItem").Content("ChaCha20-Poly1305")

panel1.Add("TextBlock").Text("PROCESSING POWER").Margin("0,0,0,12")
sliderGrid := panel1.Add("Grid").Margin("0,0,0,10")
sliderGrid.Add("Slider").Name("SldPower").Minimum(0).Maximum(100).Value(45).Margin("0,0,60,0").ToolTip("Adjust the thread workload priority.")
sliderGrid.Add("TextBlock").Text("{Binding Value, ElementName=SldPower, StringFormat={}{0:0}%}").Foreground("{DynamicResource Accent}").FontSize(20).HorizontalAlignment("Right").VerticalAlignment("Center").Margin("0")

progBar := panel1.Add("ProgressBar").Name("ProgBar").Value("{Binding Value, ElementName=SldPower}").Maximum(100).Height(8).BorderThickness(0).Background("{DynamicResource ControlBorder}").Foreground("{DynamicResource Accent}").Margin("0,0,0,10")
progBar.InjectResources('<Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style>')

; DATA GRID TAB
tab2 := tabs.Add("TabItem").Header("DATA GRID")
panel2 := tab2.Add("StackPanel").Margin("0,20,0,0")
panel2.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

panel2.Add("TextBlock").Text("Live Telemetry Grid").FontSize(28).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,5")
panel2.Add("TextBlock").Text("A fully styled Grid layout showcasing server nodes.").FontSize(13).FontWeight("Normal").Margin("0,0,0,20").TextWrapping("Wrap")

gridBorder := panel2.Add("Border").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).CornerRadius(8).Background("{DynamicResource ControlBg}").Margin("0,0,0,15")
telGrid := gridBorder.Add("Grid")
telGrid.Rows("35", "*")

headerGrid := telGrid.Add("Grid").Grid_Row(0).Background("{DynamicResource ControlBorder}")
headerGrid.SetDefaults("TextBlock", { VerticalAlignment: "Center", Margin: "0" }) ; Inherits colors/fonts, overrides Margin
headerGrid.Cols("120", "170", "80", "*")
headerGrid.Add("TextBlock").Grid_Column(0).Text("SERVER ID").Margin("15,0,0,0")
headerGrid.Add("TextBlock").Grid_Column(1).Text("LOCATION")
headerGrid.Add("TextBlock").Grid_Column(2).Text("LATENCY")
headerGrid.Add("TextBlock").Grid_Column(3).Text("STATUS")

lb := telGrid.Add("ListBox").Grid_Row(1).Background("Transparent").BorderThickness(0).ScrollViewer_HorizontalScrollBarVisibility("Disabled").Padding("0,5")
lb.TelemetryRow("SRV-US-01", "N. Virginia, USA", "14ms", "ONLINE", "#32D74B")
lb.TelemetryRow("SRV-EU-04", "London, UK", "89ms", "SYNCING", "#FF9F0A")
lb.TelemetryRow("SRV-AP-09", "Tokyo, Japan", "ERR", "OFFLINE", "#FF453A")

panel2.Add("TextBlock").Text("SYSTEM TERMINAL")
termBorder := panel2.Add("Border").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).CornerRadius(6).Background("{DynamicResource ControlBg}")
termLog := termBorder.Add("ListBox").Name("LogList").Height(130).Background("Transparent").Foreground("#32D74B").FontFamily("Consolas, Courier New").BorderThickness(0).Padding(8).ItemContainerStyle("{StaticResource TerminalItem}").ScrollViewer_HorizontalScrollBarVisibility("Disabled").ScrollViewer_VerticalScrollBarVisibility("Auto")
termLog.Add("ListBoxItem").Content("System ready. Awaiting instructions...")

; Bottom Actions (Row 2)
actions := main.Add("Grid").Grid_Row(2).Background("{DynamicResource SidebarColor}")
actions.Add("Border").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,1,0,0")

statusSp := actions.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Center").Margin("40,0")

spinner := statusSp.Add("Grid").Name("LoadingSpinner").Width(18).Height(18).Margin("0,0,15,0").Visibility("Hidden").VerticalAlignment("Center")
spinner.Add("Ellipse").Stroke("{DynamicResource Accent}").Opacity(0.25).StrokeThickness(2.5)
animEllipse := spinner.Add("Ellipse").Stroke("{DynamicResource Accent}").StrokeThickness(2.5).StrokeDashArray("3 10").StrokeDashCap("Round").RenderTransformOrigin("0.5,0.5")
animEllipse.Add("Ellipse.RenderTransform").Add("RotateTransform").Angle(0)
trigger := animEllipse.Add("Ellipse.Triggers").Add("EventTrigger").RoutedEvent("Loaded").Add("BeginStoryboard").Add("Storyboard")
trigger.Add("DoubleAnimation").Storyboard_TargetProperty("(UIElement.RenderTransform).(RotateTransform.Angle)").From(0).To(360).Duration("0:0:0.8").RepeatBehavior("Forever")

statusSp.Add("TextBlock").Name("TxtStatus").Text("Awaiting your command...").Foreground("{DynamicResource TextSub}").FontSize(14).FontWeight("SemiBold").VerticalAlignment("Center")

btnExec := actions.Add("Button").Name("BtnExecute").Content("INITIALIZE SEQUENCE").ToolTip("Commences the payload deployment via secure tunnel.").HorizontalAlignment("Right").VerticalAlignment("Center").Margin("0,0,40,0").Width(190).Height(45).Background("{DynamicResource Accent}").Foreground("White").FontWeight("Bold").BorderThickness(0).FontSize(13).Cursor("Hand")
btnExec.InjectResources('<Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style>')

; Generate the clean, compiled XAML string
CompiledMarkup := X.Compile()

; ==============================================================================
; 2. INSTANTIATE & BIND AHK LOGIC
; ==============================================================================

global ui := XAMLGUI(StrReplace(XAML_TEMPLATE, "%app%", CompiledMarkup))

ui.OnEvent("RadDarkMica", "Checked", ThemeChanged)
ui.OnEvent("RadDarkAcrylic", "Checked", ThemeChanged)
ui.OnEvent("RadLightMica", "Checked", ThemeChanged)
ui.OnEvent("RadCyber", "Checked", ThemeChanged)

ui.OnEvent("BtnExecute", "Click", ExecuteProcess)
ui.OnEvent("Window", "Loaded", OnUIReady)

ui.Track("TxtUser")
ui.Track("ComboRegion")
ui.Track("TglProxy")

ui.Show()

; --- EVENT CALLBACKS ---

OnUIReady(state, ctrl, event) {
    ui.Update("Window", "DWM", "2,1")
}

ThemeChanged(state, ctrl, event) {
    if (ctrl == "RadDarkMica" || ctrl == "RadDarkAcrylic") {
        ui.Update("Window", "DWM", (ctrl == "RadDarkAcrylic" ? "3" : "2") ",1")
        ui.Update("Resource", "BgColor", (ctrl == "RadDarkAcrylic" ? "#70000000" : "#90111114"))
        ui.Update("Resource", "SidebarColor", "#30000000")
        ui.Update("Resource", "TextMain", "#FFFFFF")
        ui.Update("Resource", "TextSub", "#AAAAAA")
        ui.Update("Resource", "ControlBg", "#15FFFFFF")
        ui.Update("Resource", "ControlBorder", "#20FFFFFF")
        ui.Update("Resource", "DropdownBg", "#1E1E1E")
        ui.Update("Resource", "Accent", "#0A84FF")
        ui.Update("LogList", "Foreground", "#32D74B")

    } else if (ctrl == "RadLightMica") {
        ui.Update("Window", "DWM", "2,0")
        ui.Update("Resource", "BgColor", "#90F5F5F5")
        ui.Update("Resource", "SidebarColor", "#50FFFFFF")
        ui.Update("Resource", "TextMain", "#111111")
        ui.Update("Resource", "TextSub", "#444444")
        ui.Update("Resource", "ControlBg", "#80FFFFFF")
        ui.Update("Resource", "ControlBorder", "#40000000")
        ui.Update("Resource", "DropdownBg", "#FAFAFA")
        ui.Update("Resource", "Accent", "#005CBA")
        ui.Update("LogList", "Foreground", "#005CBA")

    } else if (ctrl == "RadCyber") {
        ui.Update("Window", "DWM", "0,1")
        ui.Update("Resource", "BgColor", "#F009001A")
        ui.Update("Resource", "SidebarColor", "#30FF0055")
        ui.Update("Resource", "TextMain", "#00FFCC")
        ui.Update("Resource", "TextSub", "#FF0055")
        ui.Update("Resource", "ControlBg", "#2000FFCC")
        ui.Update("Resource", "ControlBorder", "#40FF0055")
        ui.Update("Resource", "DropdownBg", "#09001A")
        ui.Update("Resource", "Accent", "#FF0055")
        ui.Update("LogList", "Foreground", "#FF0055")
    }
}

ExecuteProcess(state, ctrl, event) {
    ui.Update("BtnExecute", "IsEnabled", "False")

    ui.Update("TxtStatus", "Text", "Connecting to " state["ComboRegion"] "...")
    ui.Update("TxtStatus", "Foreground", "#FF9F0A")
    ui.Update("LoadingSpinner", "Visibility", "Visible")

    ui.Update("LogList", "ClearItems", "")
    ui.Update("LogList", "AddItem", "Authenticating " state["TxtUser"] " on " state["ComboRegion"])
    ui.Update("LogList", "AddItem", "Proxy Active: " state["TglProxy"])

    Loop 20 {
        ui.Update("SldPower", "Value", String(A_Index * 5))
        ui.Update("LogList", "AddItem", "[" A_Hour ":" A_Min ":" A_Sec "." A_MSec "] Processing payload chunk " A_Index "...")
        Sleep(40)
    }

    ui.Update("LogList", "AddItem", "")
    ui.Update("LogList", "AddItem", "--> DEPLOYMENT SUCCESSFUL.")

    ui.Update("LoadingSpinner", "Visibility", "Hidden")
    ui.Update("TxtStatus", "Text", "Deployment Successful!")
    ui.Update("TxtStatus", "Foreground", "#32D74B")

    ui.Update("BtnExecute", "IsEnabled", "True")
    ui.Update("BtnExecute", "Content", "RESTART SEQUENCE")
}