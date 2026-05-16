#Requires AutoHotkey v2.0
#Include "../v2-csc/xaml.ahk"
#Include "XAML_Generator.ahk"

; ==============================================================================
; 1. CUSTOM UI COMPONENTS (Extend the XAML Generator)
; ==============================================================================
; Here we define reusable UI components by extending the XAMLElement prototype.
; This allows us to write clean, declarative code when building the application.

XAMLElement.Prototype.DefineProp("TelemetryRow", { Call: _TelemetryRow })
_TelemetryRow(this, id, location, latencyMs, status, statusColor) {
    rowGrid := this.Add("ListBoxItem").Add("Grid")
    rowGrid.Cols("120", "170", "80", "*")
    rowGrid.Add("TextBlock").Grid_Column(0).Text(id).Foreground("{DynamicResource TextMain}").Margin("10,0,0,0").VerticalAlignment("Center")
    rowGrid.Add("TextBlock").Grid_Column(1).Text(location).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")
    rowGrid.Add("TextBlock").Grid_Column(2).Text(latencyMs).Foreground(statusColor).VerticalAlignment("Center")

    border := rowGrid.Add("Border").Grid_Column(3).Background("#20" StrReplace(statusColor, "#", "")).HorizontalAlignment("Left").Padding("8,3").CornerRadius(4)
    border.Add("TextBlock").Text(status).Foreground(statusColor).FontSize(10).FontWeight("Bold")
    return this
}

XAMLElement.Prototype.DefineProp("Toggle", { Call: _Toggle })
_Toggle(this, name, label, isChecked := false, tooltip := "") {
    grid := this.Add("Grid").Margin("0,0,0,15")
    grid.Add("TextBlock").Text(label).Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")
    chk := grid.Add("CheckBox").Name(name).Style("{StaticResource ToggleSwitch}").HorizontalAlignment("Right")
    if (isChecked)
        chk.IsChecked()
    if (tooltip != "")
        chk.ToolTip(tooltip)
    return this
}

XAMLElement.Prototype.DefineProp("SegmentGroup", { Call: _SegmentGroup })
_SegmentGroup(this, groupName, options, selectedIndex := 1) {
    border := this.Add("Border").Use("CardPanel").HorizontalAlignment("Left").Margin("0,0,0,25")
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

XAMLElement.Prototype.DefineProp("MetricCard", { Call: _MetricCard })
_MetricCard(this, title, mainValue, subValue, subColor := "#32D74B", progressValue := -1) {
    card := this.Add("Border").Use("CardPanel").Padding("15")
    sp := card.Add("StackPanel")
    sp.Add("TextBlock").Text(title).Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold")
    sp.Add("TextBlock").Text(mainValue).Foreground("{DynamicResource TextMain}").FontSize(24).FontWeight("Light").Margin("0,10,0,0")
    
    if (progressValue != -1) {
        sp.Add("ProgressBar").Value(progressValue).Maximum(100).Height(4).Margin("0,10,0,0").Foreground("{DynamicResource Accent}").Background("{DynamicResource ControlBorder}").BorderThickness(0)
    } else {
        sp.Add("TextBlock").Text(subValue).Foreground(subColor).FontSize(11).Margin("0,5,0,0")
    }
    return card
}

XAMLElement.Prototype.DefineProp("CodeEditor", { Call: _CodeEditor })
_CodeEditor(this, filename) {
    ideBdr := this.Add("Border").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).CornerRadius(6).Margin("0,0,0,20")
    ideGrid := ideBdr.Add("Grid")
    ideGrid.Rows("30", "*")

    ideHeader := ideGrid.Add("Border").Grid_Row(0).Background("#2D2D30").CornerRadius("5,5,0,0")
    headerInner := ideHeader.Add("Grid")
    headerInner.Add("TextBlock").Text(filename).Foreground("#CCCCCC").FontSize(11).HorizontalAlignment("Left").VerticalAlignment("Center").Margin("15,0,0,0")
    
    btns := headerInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right").Margin("0,0,10,0")
    btns.SetDefaults("Button", { Background: "Transparent", BorderThickness: 0, Foreground: "#AAAAAA", FontSize: 10, Padding: "8,2", Margin: "2,0", Cursor: "Hand" })
    btns.Add("Button").Content("Save")
    btns.Add("Button").Content("Select All")
    btns.Add("Button").Content("Run").Foreground("#4DB33D").FontWeight("Bold")

    editorBorder := ideGrid.Add("Border").Grid_Row(1).Background("#1E1E1E").CornerRadius("0,0,5,5")
    editor := editorBorder.Add("RichTextBox").FontFamily("Consolas, Courier New").Background("Transparent").BorderThickness(0).Padding("15").Height(130).Foreground("#D4D4D4").CaretBrush("#FFFFFF")
    
    return editor ; Return the RichTextBox so syntax highlighting flows can be easily chained to it
}

; ==============================================================================
; 2. APPLICATION LAYOUT COMPILER
; ==============================================================================

BuildApplication() {
    X := XAML_Generator("Grid").Name("AppGrid").Background("{DynamicResource BgColor}")
    X.Add("Grid.LayoutTransform").Add("ScaleTransform").SetProp("x:Name", "AppScale").ScaleX(1).ScaleY(1)
    X.Cols("240", "*")

    ; -- 2.1 Theme & Global Styles --
    PrimaryButtonTemplate(el) {
        el.Background("{DynamicResource Accent}").Foreground("White").FontWeight("Bold").BorderThickness(0).FontSize(13).Cursor("Hand")
        el.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.85"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
    }
    
    X.DefineTemplate("PrimaryBtn", PrimaryButtonTemplate)
    X.DefineTemplate("SubtitleText", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,12" })
    X.DefineTemplate("PageTitle", { FontSize: 28, FontWeight: "SemiBold", Foreground: "{DynamicResource TextMain}", Margin: "0" })
    X.DefineTemplate("BodyText", { FontSize: 13, FontWeight: "Normal", TextWrapping: "Wrap" })
    X.DefineTemplate("CardPanel", { BorderBrush: "{DynamicResource ControlBorder}", BorderThickness: 1, CornerRadius: 6, Background: "{DynamicResource ControlBg}" })
    X.SetDefaults("ListBox", { Background: "Transparent", BorderThickness: 0, ScrollViewer_HorizontalScrollBarVisibility: "Disabled" })

    ; -- 2.2 Navigation Sidebar --
    sidebar := X.Add("Border").Name("SidebarBorder").Grid_Column(0).Background("{DynamicResource SidebarColor}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0")
    BuildSidebar(sidebar)

    ; -- 2.3 Main Application Area --
    main := X.Add("Grid").Grid_Column(1)
    main.Rows("50", "*", "90")
    
    BuildWindowControls(main.Add("Border").Name("DragArea").Grid_Row(0).Background("Transparent").Cursor("Arrow"))
    
    tabs := main.Add("TabControl").Grid_Row(1).Margin("40,0,40,10")
    BuildDeploymentTab(tabs.Add("TabItem").Header("DEPLOYMENT"))
    BuildDataGridTab(tabs.Add("TabItem").Header("DATA GRID"))
    BuildComponentsTab(tabs.Add("TabItem").Header("UI COMPONENTS"))
    
    BuildBottomBar(main.Add("Grid").Grid_Row(2).Background("{DynamicResource SidebarColor}"))

    return X.Compile()
}

; --- Layout Constructors ---

BuildSidebar(container) {
    sp := container.Add("StackPanel").Margin("25,35,25,25")
    sp.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,12" })

    sp.Add("TextBlock").Name("TxtLogo").Text("✦ FLUID UI").FontSize(22).FontWeight("Black").Foreground("{DynamicResource TextMain}").Margin("0,0,0,40")
    
    sp.Add("TextBlock").Text("THEME ENGINE").Margin("0,0,0,5")
    themeCombo := sp.Add("ComboBox").Name("ComboTheme").Height(35).Margin("0,0,0,15")
    try {
        Loop Parse, IniRead("themes.ini"), "`n", "`r"
            themeCombo.Add("ComboBoxItem").Content(A_LoopField)
    }
    themeCombo.SelectedIndex(0)

    sp.Add("TextBlock").Text("INTERFACE SCALE").Margin("0,15,0,5")
    scaleCombo := sp.Add("ComboBox").Name("ComboScale").SelectedIndex(1).Height(35).Margin("0,0,0,15")
    scaleCombo.Add("ComboBoxItem").Content("Thin")
    scaleCombo.Add("ComboBoxItem").Content("Balanced")
    scaleCombo.Add("ComboBoxItem").Content("Chunky")

    sp.Add("TextBlock").Text("SYSTEM TOGGLES").Margin("0,15,0,15")
    sp.Toggle("TglOverdrive", "Overdrive Mode", true, "Accelerate packet processing natively.")
    sp.Toggle("TglProxy", "Anonymous Proxy", false)
}

BuildWindowControls(container) {
    grid := container.Add("Grid")
    
    titleSp := grid.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Center").Margin("15,0,0,0").IsHitTestVisible("False")
    titleSp.Add("Image").Name("AppIcon").Width(16).Height(16).Margin("0,0,10,0")
    titleSp.Add("TextBlock").Name("AppTitle").Text("").Foreground("{DynamicResource TextMain}").FontSize(12).FontWeight("SemiBold")

    winBtns := grid.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right").VerticalAlignment("Top")
    
    ; Define a transparent chrome button template
    ChromeBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#20FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
    CloseBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#E0FF3333"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'

    minBtn := winBtns.Add("Button").Name("BtnMinimize").WindowChrome_IsHitTestVisibleInChrome("True").Width(45).Height(35).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Cursor("Hand").ToolTip("Minimize")
    minBtn.InjectResources(ChromeBtnTemplate)
    minBtn.Add("TextBlock").Text(Chr(0xE921)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

    maxBtn := winBtns.Add("Button").Name("BtnMaximize").WindowChrome_IsHitTestVisibleInChrome("True").Width(45).Height(35).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Cursor("Hand").ToolTip("Maximize")
    maxBtn.InjectResources(ChromeBtnTemplate)
    maxBtn.Add("TextBlock").Name("BtnMaximizeTxt").Text(Chr(0xE922)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

    closeBtn := winBtns.Add("Button").Name("BtnClose").WindowChrome_IsHitTestVisibleInChrome("True").Width(45).Height(35).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Cursor("Hand").ToolTip("Close Application")
    closeBtn.InjectResources(CloseBtnTemplate)
    closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")
}

BuildDeploymentTab(tab) {
    sv := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Margin("0,10,0,0")
    panel := sv.Add("StackPanel").Margin("0,10,15,20")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    head := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,5")
    head.Add("TextBlock").Text("Interactive Components").Use("PageTitle").VerticalAlignment("Center")
    head.Add("Border").Background("#200A84FF").CornerRadius(10).Padding("10,4").Margin("15,0,0,0").VerticalAlignment("Center")
        .Add("TextBlock").Text("v2.0 ACTIVE").Foreground("{DynamicResource Accent}").FontSize(10).FontWeight("Bold").Margin("0")

    panel.Add("TextBlock").Text("XAML natively binds elements. DynamicResources theme everything instantly.").Use("BodyText").Margin("0,0,0,25")

    credGrid := panel.Add("Grid").Margin("0,0,0,25")
    credGrid.Cols("*", "20", "*")
    
    userSp := credGrid.Add("StackPanel").Grid_Column(0)
    userSp.Add("TextBlock").Text("USERNAME")
    userSp.Add("TextBox").Name("TxtUser").Text("Administrator").ToolTip("Must be an Active Directory alias")

    passSp := credGrid.Add("StackPanel").Grid_Column(2)
    passSp.Add("TextBlock").Text("SECURITY PIN")
    passSp.Add("PasswordBox").Name("TxtPass").Password("hiddenpassword")

    regionSp := panel.Add("StackPanel").Margin("0,0,0,25")
    regionSp.Add("TextBlock").Text("SERVER REGION")
    combo := regionSp.Add("ComboBox").Name("ComboRegion").SelectedIndex(0).Height(40)
    combo.Add("ComboBoxItem").Content("US-East-1 (N. Virginia)")
    combo.Add("ComboBoxItem").Content("EU-West-2 (London)")
    combo.Add("ComboBoxItem").Content("AP-Northeast-1 (Tokyo)")

    panel.Add("TextBlock").Text("PRIORITY TIER")
    panel.SegmentGroup("Priority", ["LOW", "BALANCED", "MAXIMUM"], 2)

    expndr := panel.Add("Expander").Margin("0,0,0,25")
    expndr.Add("Expander.Header").Add("TextBlock").Text("Advanced Connection Settings").FontWeight("SemiBold").FontSize(13).Margin("0")
    expSp := expndr.Add("StackPanel").Margin("0,10,0,0")
    expSp.Add("TextBlock").Text("ENCRYPTION ALGORITHM")
    expCombo := expSp.Add("ComboBox").SelectedIndex(1).Height(40)
    expCombo.Add("ComboBoxItem").Content("AES-128-GCM")
    expCombo.Add("ComboBoxItem").Content("AES-256-CBC (Recommended)")
    expCombo.Add("ComboBoxItem").Content("ChaCha20-Poly1305")

    panel.Add("TextBlock").Text("PROCESSING POWER").Margin("0,0,0,12")
    sliderGrid := panel.Add("Grid").Margin("0,0,0,10")
    sliderGrid.Add("Slider").Name("SldPower").Minimum(0).Maximum(100).Value(45).Margin("0,0,60,0").ToolTip("Adjust the thread workload priority.")
    sliderGrid.Add("TextBlock").Text("{Binding Value, ElementName=SldPower, StringFormat={}{0:0}%}").Foreground("{DynamicResource Accent}").FontSize(20).HorizontalAlignment("Right").VerticalAlignment("Center").Margin("0")

    progBar := panel.Add("ProgressBar").Name("ProgBar").Value("{Binding Value, ElementName=SldPower}").Maximum(100).Height(8).BorderThickness(0).Background("{DynamicResource ControlBorder}").Foreground("{DynamicResource Accent}").Margin("0,0,0,10")
    progBar.InjectResources('<Style TargetType="Border"><Setter Property="CornerRadius" Value="4"/></Style>')
}

BuildDataGridTab(tab) {
    scroll := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,0")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Live Telemetry Grid").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("A fully styled Grid layout showcasing server nodes.").Use("BodyText").Margin("0,0,0,20")

    gridBorder := panel.Add("Border").Use("CardPanel").CornerRadius(8).Margin("0,0,0,15")
    telGrid := gridBorder.Add("Grid")
    telGrid.Rows("35", "*")

    headerGrid := telGrid.Add("Grid").Grid_Row(0).Background("{DynamicResource ControlBorder}")
    headerGrid.SetDefaults("TextBlock", { VerticalAlignment: "Center", Margin: "0" })
    headerGrid.Cols("120", "170", "80", "*")
    headerGrid.Add("TextBlock").Grid_Column(0).Text("SERVER ID").Margin("15,0,0,0")
    headerGrid.Add("TextBlock").Grid_Column(1).Text("LOCATION")
    headerGrid.Add("TextBlock").Grid_Column(2).Text("LATENCY")
    headerGrid.Add("TextBlock").Grid_Column(3).Text("STATUS")

    lb := telGrid.Add("ListBox").Grid_Row(1).Padding("0,5")
    lb.TelemetryRow("SRV-US-01", "N. Virginia, USA", "14ms", "ONLINE", "#32D74B")
    lb.TelemetryRow("SRV-EU-04", "London, UK", "89ms", "SYNCING", "#FF9F0A")
    lb.TelemetryRow("SRV-AP-09", "Tokyo, Japan", "ERR", "OFFLINE", "#FF453A")

    panel.Add("TextBlock").Text("SYSTEM TERMINAL")
    termBorder := panel.Add("Border").Use("CardPanel")
    termLog := termBorder.Add("ListBox").Name("LogList").Height(130).Foreground("#32D74B").FontFamily("Consolas, Courier New").Padding(8).ItemContainerStyle("{StaticResource TerminalItem}").ScrollViewer_VerticalScrollBarVisibility("Auto")
    termLog.Add("ListBoxItem").Content("System ready. Awaiting instructions...")
}

BuildComponentsTab(tab) {
    scroll := tab.Add("ScrollViewer").CanContentScroll("False").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,0")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Interactive UI Components").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("A showcase of rich, native WPF elements styled to match the theme.").Use("BodyText").Margin("0,0,0,20")

    panel.Add("TextBlock").Text("METRIC DASHBOARD")
    metrics := panel.Add("Grid").Margin("0,0,0,20")
    metrics.Cols("*", "15", "*", "15", "*")
    metrics.MetricCard("ACTIVE SESSIONS", "24,592", "↑ 12% this week", "#32D74B").Grid_Column(0)
    metrics.MetricCard("NETWORK LOAD", "42%", "", "", 42).Grid_Column(2)
    metrics.MetricCard("SECURITY THREATS", "ELEVATED", "2 alerts pending", "#FF9F0A").Grid_Column(4)

    panel.Add("TextBlock").Text("SELECTION CONTROLS")
    selGrid := panel.Add("Grid").Margin("0,0,0,20")
    selGrid.Cols("*", "15", "*")

    radSp := selGrid.Add("Border").Grid_Column(0).Use("CardPanel").Padding("15").Add("StackPanel")
    radSp.Add("RadioButton").Content("Standard Telemetry").Foreground("{DynamicResource TextMain}").IsChecked("True").Margin("0,0,0,10")
    radSp.Add("RadioButton").Content("Verbose Logging").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")
    radSp.Add("RadioButton").Content("Debug Mode (Slow)").Foreground("{DynamicResource TextMain}")

    chkSp := selGrid.Add("Border").Grid_Column(2).Use("CardPanel").Padding("15").Add("StackPanel")
    chkSp.Add("CheckBox").Content("Auto-connect on launch").Foreground("{DynamicResource TextMain}").IsChecked("True").Margin("0,0,0,10")
    chkSp.Add("CheckBox").Content("Save credentials securely").Foreground("{DynamicResource TextMain}").IsChecked("True").Margin("0,0,0,10")
    chkSp.Add("CheckBox").Content("Enable hardware acceleration").Foreground("{DynamicResource TextMain}")

    panel.Add("TextBlock").Text("HIERARCHICAL TREEVIEW")
    tv := panel.Add("Border").Use("CardPanel").Margin("0,0,0,20").Add("TreeView").Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextMain}").Margin("10")
    n1 := tv.Add("TreeViewItem").Header("Local Network").IsExpanded("True")
    n1.Add("TreeViewItem").Header("Workstation-Alpha")
    n1.Add("TreeViewItem").Header("Gateway-Router-01")
    n2 := tv.Add("TreeViewItem").Header("Cloud Infrastructure").IsExpanded("True")
    n2.Add("TreeViewItem").Header("AWS-us-east-1")
    n2.Add("TreeViewItem").Header("Azure-WestEurope")

    panel.Add("TextBlock").Text("RICH TEXT / CODE EDITOR")
    editor := panel.CodeEditor("core.js")
    flow := editor.Add("FlowDocument").LineHeight(20)
    para := flow.Add("Paragraph").Margin("0")
    
    ; VS Code Dark+ Syntax highlighting
    cFunction := "#569CD6", cClass := "#4EC9B0", cVar := "#9CDCFE", cString := "#CE9178", cOperator := "#D4D4D4", cKeyword := "#C586C0", cMethod := "#DCDCAA"
    
    para.Add("Run").Text("function").Foreground(cFunction)
    para.Add("Run").Text(" ").Foreground(cOperator)
    para.Add("Run").Text("initializeCore").Foreground(cMethod)
    para.Add("Run").Text("() {").Foreground(cOperator)
    para.Add("LineBreak")
    para.Add("Run").Text("    console.").Foreground(cOperator)
    para.Add("Run").Text("log").Foreground(cMethod)
    para.Add("Run").Text("(").Foreground(cOperator)
    para.Add("Run").Text("'System online.'").Foreground(cString)
    para.Add("Run").Text(");").Foreground(cOperator)
    para.Add("LineBreak")
    para.Add("Run").Text("    return ").Foreground(cKeyword)
    para.Add("Run").Text("true").Foreground(cFunction)
    para.Add("Run").Text(";").Foreground(cOperator)
    para.Add("LineBreak")
    para.Add("Run").Text("}").Foreground(cOperator)
}

BuildBottomBar(actions) {
    actions.Add("Border").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,1,0,0")
    statusSp := actions.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Center").Margin("40,0")
    
    spinner := statusSp.Add("Grid").Name("LoadingSpinner").Width(18).Height(18).Margin("0,0,15,0").Visibility("Hidden").VerticalAlignment("Center")
    spinner.Add("Ellipse").Stroke("{DynamicResource Accent}").Opacity(0.25).StrokeThickness(2.5)
    animEllipse := spinner.Add("Ellipse").Stroke("{DynamicResource Accent}").StrokeThickness(2.5).StrokeDashArray("3 10").StrokeDashCap("Round").RenderTransformOrigin("0.5,0.5")
    animEllipse.Add("Ellipse.RenderTransform").Add("RotateTransform").Angle(0)
    
    trigger := animEllipse.Add("Ellipse.Triggers").Add("EventTrigger").RoutedEvent("Loaded").Add("BeginStoryboard").Add("Storyboard")
    trigger.Add("DoubleAnimation").Storyboard_TargetProperty("(UIElement.RenderTransform).(RotateTransform.Angle)").From(0).To(360).Duration("0:0:0.8").RepeatBehavior("Forever")
    
    statusSp.Add("TextBlock").Name("TxtStatus").Text("Awaiting your command...").Foreground("{DynamicResource TextSub}").FontSize(14).FontWeight("SemiBold").VerticalAlignment("Center")
    
    actions.Add("Button").Name("BtnExecute").Content("INITIALIZE SEQUENCE").ToolTip("Commences the payload deployment via secure tunnel.").HorizontalAlignment("Right").VerticalAlignment("Center").Margin("0,0,40,0").Width(190).Height(45).Use("PrimaryBtn")
}

; ==============================================================================
; 3. INSTANTIATE & BIND AHK LOGIC
; ==============================================================================

global ui := XAMLGUI(StrReplace(XAML_TEMPLATE, "%app%", BuildApplication()))

ui.OnEvent("ComboTheme", "SelectionChanged", ThemeChanged)
ui.OnEvent("ComboScale", "SelectionChanged", ScaleChanged)
ui.OnEvent("BtnExecute", "Click", ExecuteProcess)
ui.OnEvent("Window", "Loaded", OnUIReady)

ui.Track("ComboTheme")
ui.Track("ComboScale")
ui.Track("TxtUser")
ui.Track("ComboRegion")
ui.Track("TglProxy")

ui.Show()

; --- EVENT CALLBACKS ---

OnUIReady(state, ctrl, event) {
    ui.Update("Window", "DWM", "2,1")
    ui.Update("Window", "Title", "Fluid UI Workbench")
    
    hIcon := LoadPicture("shell32.dll", "Icon15", &ImageType := 1)
    ui.Update("Window", "Icon", "HICON:" hIcon)
    TraySetIcon("shell32.dll", 15)
    
    ; Map the title and icon into our custom UI title bar!
    ui.Update("AppTitle", "Text", "Fluid UI Workbench")
    ui.Update("AppIcon", "Source", "HICON:" hIcon)
    
    ThemeChanged(state, ctrl, event)
    ScaleChanged(state, ctrl, event)
}

ThemeChanged(state, ctrl, event) {
    theme := state["ComboTheme"]
    try {
        themeData := IniRead("themes.ini", theme)
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2) {
                key := parts[1]
                val := parts[2]
                if (key == "Window_DWM")
                    ui.Update("Window", "DWM", val)
                else if (InStr(key, "Resource_") == 1)
                    ui.Update("Resource", SubStr(key, 10), val)
                else if (InStr(key, "LogList_") == 1)
                    ui.Update("LogList", SubStr(key, 9), val)
            }
        }
    } catch {
        ; Do nothing
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

ScaleChanged(state, ctrl, event) {
    scale := state["ComboScale"]
    if (scale == "Thin") {
        ui.Update("AppScale", "ScaleX", "0.9")
        ui.Update("AppScale", "ScaleY", "0.9")
    } else if (scale == "Balanced") {
        ui.Update("AppScale", "ScaleX", "1.0")
        ui.Update("AppScale", "ScaleY", "1.0")
    } else if (scale == "Chunky") {
        ui.Update("AppScale", "ScaleX", "1.15")
        ui.Update("AppScale", "ScaleY", "1.15")
    }
}