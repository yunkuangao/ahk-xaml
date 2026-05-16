#Requires AutoHotkey v2.0
#Include "../v2-csc/xaml.ahk"
#Include "XAML_Generator.ahk"
#Include "FluidDialog.ahk"
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

    ideHeader := ideGrid.Add("Border").Grid_Row(0).Background("{DynamicResource ControlBorder}").CornerRadius("5,5,0,0")
    headerInner := ideHeader.Add("Grid")
    headerInner.Add("TextBlock").Text(filename).Foreground("{DynamicResource TextMain}").FontSize(11).HorizontalAlignment("Left").VerticalAlignment("Center").Margin("15,0,0,0")

    btns := headerInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right").Margin("0,0,10,0")
    btns.SetDefaults("Button", { Background: "Transparent", BorderThickness: 0, Foreground: "{DynamicResource TextSub}", FontSize: 10, Padding: "8,2", Margin: "2,0", Cursor: "Hand" })
    btns.Add("Button").Content("Save")
    btns.Add("Button").Content("Select All")
    btns.Add("Button").Content("Run").Foreground("{DynamicResource Accent}").FontWeight("Bold")

    editorBorder := ideGrid.Add("Border").Grid_Row(1).Background("{DynamicResource ControlBg}").CornerRadius("0,0,5,5")
    editor := editorBorder.Add("RichTextBox").FontFamily("Consolas, Courier New").Background("Transparent").BorderThickness(0).Padding("15").Height(130).Foreground("{DynamicResource TextMain}").CaretBrush("{DynamicResource TextMain}")

    return editor ; Return the RichTextBox so syntax highlighting flows can be easily chained to it
}

; ==============================================================================
; 2. APPLICATION LAYOUT COMPILER
; ==============================================================================

BuildApplication() {
    X := XAML_Generator("Grid").Name("AppGrid").Background("{DynamicResource BgColor}").Focusable("True")
    X.Add("Grid.LayoutTransform").Add("ScaleTransform").SetProp("x:Name", "AppScale").ScaleX(1).ScaleY(1)
    X.Cols("Auto", "*")

    ; -- 2.1 Theme & Global Styles --
    PrimaryButtonTemplate(el) {
        el.Background("{DynamicResource Accent}").Foreground("White").FontWeight("Bold").BorderThickness(0).FontSize(13).Cursor("Hand")
        el.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.85"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
    }

    X.DefineTemplate("PrimaryBtn", PrimaryButtonTemplate)
    X.DefineTemplate("SubtitleText", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,12" })
    X.DefineTemplate("PageTitle", { FontSize: 28, FontWeight: "SemiBold", Foreground: "{DynamicResource TextMain}", Margin: "0" })
    X.DefineTemplate("BodyText", { FontSize: 13, FontWeight: "Normal", TextWrapping: "Wrap" })
    X.DefineTemplate("CardPanel", { BorderBrush: "{DynamicResource ControlBorder}", BorderThickness: 1, CornerRadius: 6, Background: "{DynamicResource ControlBg}" })
    X.SetDefaults("ListBox", { Background: "Transparent", BorderThickness: 0, ScrollViewer_HorizontalScrollBarVisibility: "Disabled" })

    ; -- 2.2 Navigation Sidebar --
    sidebar := X.Add("Border").Name("SidebarBorder").Style("{StaticResource SidebarAnimStyle}").Grid_Column(0).Background("{DynamicResource SidebarColor}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0").ClipToBounds("True")
    BuildSidebar(sidebar)

    ; -- 2.3 Main Application Area --
    main := X.Add("Grid").Grid_Column(1)
    main.Rows("50", "*", "90")

    BuildWindowControls(main.Add("Border").Name("DragArea").Grid_Row(0).Background("Transparent").Cursor("Arrow"))

    tabs := main.Add("TabControl").Grid_Row(1).Margin("40,0,40,10")
    BuildDeploymentTab(tabs.Add("TabItem").Header("DEPLOYMENT"))
    BuildDataGridTab(tabs.Add("TabItem").Header("DATA GRID"))
    BuildComponentsTab(tabs.Add("TabItem").Header("UI COMPONENTS"))
    BuildAdvancedInputsTab(tabs.Add("TabItem").Header("ADVANCED INPUTS"))
    BuildFluidDialogsTab(tabs.Add("TabItem").Header("FLUID DIALOGS"))
    BuildRichComponentsTab(tabs.Add("TabItem").Header("RICH COMPONENTS"))

    BuildBottomBar(main.Add("Grid").Grid_Row(2).Background("{DynamicResource SidebarColor}"))

    ; Overlay Layer (In-Window Modals and Snackbars)
    overlay := X.Add("Grid").Name("AppOverlay").Grid_ColumnSpan(2)
    overlay.Add("Border").Name("ModalOverlay").Style("{StaticResource OverlayDialogLayer}")

    ; The Dialog Box
    modalBox := overlay.Add("Border").Name("ModalBox").Style("{StaticResource OverlayDialogBox}").Visibility("Collapsed")
    modalSp := modalBox.Add("StackPanel")
    modalSp.Add("TextBlock").Text("In-Window Modal").Use("PageTitle").Margin("0,0,0,10")
    modalSp.Add("TextBlock").Text("This is a fixed modal dialog that blocks the parent UI without creating a new OS window.").Use("BodyText").Margin("0,0,0,20")
    modalSp.Add("Button").Name("BtnCloseModal").Content("Close Dialog").Use("PrimaryBtn").HorizontalAlignment("Right").Width("120").Height("32").Margin("0,10,0,0")

    ; Snackbar
    snackbar := overlay.Add("Border").Name("SnackbarContainer").Style("{StaticResource SnackbarNotification}").Visibility("Collapsed")
    snackSp := snackbar.Add("StackPanel").Orientation("Horizontal")
    snackSp.Add("TextBlock").Text(Chr(0xE73E)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("{DynamicResource Accent}").FontSize("16").VerticalAlignment("Center").Margin("0,0,10,0")
    snackSp.Add("TextBlock").Text("Action completed successfully.").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")

    ; Color Picker Dialog Box
    cpBox := overlay.Add("Border").Name("ColorPickerBox").Style("{StaticResource OverlayDialogBox}").Visibility("Collapsed")
    cpSp := cpBox.Add("StackPanel")
    cpSp.Add("TextBlock").Text("Select Color").Use("PageTitle").Margin("0,0,0,10")

    cpGrid := cpSp.Add("Grid").Margin("0,10,0,20")
    cpGrid.Cols("Auto", "20", "*")
    cpGrid.Rows("Auto", "15", "Auto", "15", "Auto")

    cpGrid.Add("Border").Name("ColorPreview").Grid_Column(0).Grid_RowSpan(5).Width("70").Height("70").CornerRadius("35").Background("#FF0A84FF").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")

    hueGrid := cpGrid.Add("Grid").Grid_Column(2).Grid_Row(0)
    hueBg := hueGrid.Add("Border").Height("8").CornerRadius("4").Margin("0,10,0,0").Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,0")
    hueBg.Add("GradientStop").Color("#FFFF0000").Offset("0")
    hueBg.Add("GradientStop").Color("#FFFFFF00").Offset("0.16")
    hueBg.Add("GradientStop").Color("#FF00FF00").Offset("0.33")
    hueBg.Add("GradientStop").Color("#FF00FFFF").Offset("0.5")
    hueBg.Add("GradientStop").Color("#FF0000FF").Offset("0.66")
    hueBg.Add("GradientStop").Color("#FFFF00FF").Offset("0.83")
    hueBg.Add("GradientStop").Color("#FFFF0000").Offset("1")
    hueGrid.Add("Slider").Name("HueSlider").Minimum("0").Maximum("360").Value("210")

    alphaGrid := cpGrid.Add("Grid").Grid_Column(2).Grid_Row(2)
    alphaBg := alphaGrid.Add("Border").Height("8").CornerRadius("4").Margin("0,10,0,0").Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,0")
    alphaBg.Add("GradientStop").Color("Transparent").Offset("0")
    alphaBg.Add("GradientStop").Color("White").Offset("1")
    alphaGrid.Add("Slider").Name("AlphaSlider").Minimum("0").Maximum("255").Value("255")

    rgbGrid := cpGrid.Add("Grid").Grid_Column(2).Grid_Row(4)
    rgbGrid.Cols("Auto", "5", "45", "15", "Auto", "5", "45", "15", "Auto", "5", "45", "*", "Auto", "5", "70")
    rgbGrid.Add("TextBlock").Text("R").Grid_Column(0).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").FontSize(11).FontWeight("Bold")
    rgbGrid.Add("TextBox").Name("RInput").Text("10").Grid_Column(2).Height("24").Padding("4,2").HorizontalContentAlignment("Center")
    rgbGrid.Add("TextBlock").Text("G").Grid_Column(4).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").FontSize(11).FontWeight("Bold")
    rgbGrid.Add("TextBox").Name("GInput").Text("132").Grid_Column(6).Height("24").Padding("4,2").HorizontalContentAlignment("Center")
    rgbGrid.Add("TextBlock").Text("B").Grid_Column(8).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").FontSize(11).FontWeight("Bold")
    rgbGrid.Add("TextBox").Name("BInput").Text("255").Grid_Column(10).Height("24").Padding("4,2").HorizontalContentAlignment("Center")

    rgbGrid.Add("TextBlock").Text("HEX").Grid_Column(12).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").FontSize(11).FontWeight("Bold")
    rgbGrid.Add("TextBox").Name("HexInput").Text("#FF0A84FF").Grid_Column(14).Height("24").Padding("4,2").HorizontalContentAlignment("Center")

    cpSp.Add("Button").Name("BtnCloseColorPicker").Content("Confirm").Use("PrimaryBtn").HorizontalAlignment("Right").Width("120").Height("32").Margin("0,10,0,0")

    return X.Compile()
}

; --- Layout Constructors ---

BuildSidebar(container) {
    sp := container.Add("StackPanel").Margin("25,35,25,25")
    sp.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,12" })

    sp.Add("TextBlock").Name("TxtLogo").Text("SETTINGS").FontSize(22).FontWeight("Black").Foreground("{DynamicResource TextMain}").Margin("0,0,0,40")

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

    ; Left side (Button + Title)
    leftSp := grid.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Center").Margin("15,0,0,0")

    ; Menu Button
    menuBtn := leftSp.Add("ToggleButton").Name("BtnToggleSidebar").Style("{StaticResource HamburgerButton}").WindowChrome_IsHitTestVisibleInChrome("True").ToolTip("Toggle Sidebar (Ctrl+B)").Margin("0,0,10,0")

    ; App Title container (IsHitTestVisible=False)
    titleSp := leftSp.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Center").IsHitTestVisible("False")
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

    ; Theme-aware Syntax highlighting
    cKeyword := "{DynamicResource Accent}"
    cMethod := "{DynamicResource TextMain}"
    cString := "{DynamicResource TextSub}"
    cOperator := "{DynamicResource TextMain}"

    para.Add("Run").Text("function").Foreground(cKeyword).FontWeight("Bold")
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
    para.Add("Run").Text("    return ").Foreground(cKeyword).FontWeight("Bold")
    para.Add("Run").Text("true").Foreground(cKeyword)
    para.Add("Run").Text(";").Foreground(cOperator)
    para.Add("LineBreak")
    para.Add("Run").Text("}").Foreground(cOperator)
}

BuildAdvancedInputsTab(tab) {
    scroll := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,0")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Advanced XAML Inputs").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("Dynamic search boxes and filtering capabilities.").Use("BodyText").Margin("0,0,0,20")

    ; Free-type Auto-Suggest
    panel.Add("TextBlock").Text("FREE-TYPE AUTO-SUGGEST SEARCH")
    panel.Add("TextBlock").Text("Type anything, or use the dropdown to see suggestions. It acts like a search box.").Use("BodyText").Margin("0,0,0,15").Opacity(0.7)
    c1 := panel.Add("ComboBox").Name("ComboFreeSearch").IsEditable("True").IsTextSearchEnabled("True").StaysOpenOnEdit("True").Margin("0,0,0,30").Width(400).HorizontalAlignment("Left")
    c1.Add("ComboBoxItem").Content("Apple")
    c1.Add("ComboBoxItem").Content("Banana")
    c1.Add("ComboBoxItem").Content("Cherry")
    c1.Add("ComboBoxItem").Content("Date")
    c1.Add("ComboBoxItem").Content("Elderberry")

    ; Strict Search
    panel.Add("TextBlock").Text("STRICT LIST SEARCH")
    panel.Add("TextBlock").Text("Editable combobox configured for strict matching workflows. You can type to filter/jump.").Use("BodyText").Margin("0,0,0,15").Opacity(0.7)
    c2 := panel.Add("ComboBox").Name("ComboStrictSearch").IsEditable("True").IsTextSearchEnabled("True").Margin("0,0,0,30").Width(400).HorizontalAlignment("Left")
    c2.Add("ComboBoxItem").Content("Administrator")
    c2.Add("ComboBoxItem").Content("Moderator")
    c2.Add("ComboBoxItem").Content("User")
    c2.Add("ComboBoxItem").Content("Guest")
}

BuildFluidDialogsTab(tab) {
    scroll := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,0")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Fluid Dialog Engine").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("A robust, non-blocking asynchronous event flow for rich popups and modals.").Use("BodyText").Margin("0,0,0,20")

    ; Basic Dialogs
    panel.Add("TextBlock").Text("BASIC INTERACTIONS")
    basicSp := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,20")
    basicSp.Add("Button").Name("BtnShowAlert").Content("Show Alert").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn")
    basicSp.Add("Button").Name("BtnShowInput").Content("Ask Name").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn")
    basicSp.Add("Button").Name("BtnShowError").Content("Critical Error").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("#FF3B30").BorderBrush("#FF3B30").BorderThickness(1)
    basicSp.Add("Button").Name("BtnShowAuth").Content("Auth Dialog").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("{DynamicResource Accent}").BorderBrush("{DynamicResource Accent}").BorderThickness(1)

    ; Complex Dialogs
    panel.Add("TextBlock").Text("COMPLEX & DYNAMIC")
    cmplxSp := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,20")
    cmplxSp.Add("Button").Name("BtnShowComplex1").Content("Progress Task").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1)
    cmplxSp.Add("Button").Name("BtnShowComplex2").Content("Detail Log View").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1)
    cmplxSp.Add("Button").Name("BtnShowComplex3").Content("Resizable Tool").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("{DynamicResource Accent}").BorderBrush("{DynamicResource Accent}").BorderThickness(1)
    cmplxSp.Add("Button").Name("BtnShowComplex4").Content("File Deletion").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("#FF453A").BorderBrush("#FF453A").BorderThickness(1)
}

BuildRichComponentsTab(tab) {
    scroll := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,20")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Rich UI Components").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("Showcasing newly added advanced controls.").Use("BodyText").Margin("0,0,0,20")

    ; Buttons & Indicators
    panel.Add("TextBlock").Text("BUTTONS & INDICATORS")
    grid1 := panel.Add("Grid").Margin("0,0,0,20")
    grid1.Cols("Auto", "20", "Auto", "20", "Auto", "20", "Auto")

    ; Icon Button
    grid1.Add("Button").Grid_Column(0).Style("{StaticResource IconButton}").Add("TextBlock").Text(Chr(0xE713)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")

    ; Split Button (Dropdown)
    splitBtn := grid1.Add("ToggleButton").Name("SplitBtn").Grid_Column(2).Style("{StaticResource SplitButton}").Content("Options")
    popup := grid1.Add("Popup").Name("SplitPopup").PlacementTarget("{Binding ElementName=SplitBtn}").Placement("Bottom").StaysOpen("False").AllowsTransparency("True").IsOpen("{Binding IsChecked, ElementName=SplitBtn, Mode=TwoWay}")
    popupBorder := popup.Add("Border").Background("{DynamicResource DropdownBg}").BorderThickness(1).BorderBrush("{DynamicResource ControlBorder}").CornerRadius(6).Margin("0,5,0,0").Padding(4)
    popupStack := popupBorder.Add("StackPanel").Width(200)

    popBtn1 := popupStack.Add("Button").Name("BtnManageUsers").Style("{StaticResource DropdownMenuItem}").Margin("0,0,0,4")
    popSp1 := popBtn1.Add("StackPanel").Orientation("Horizontal")
    popSp1.Add("TextBlock").Text(Chr(0xE77B)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("{DynamicResource Accent}").FontSize(16).VerticalAlignment("Center").Margin("0,0,10,0")
    popSp1.Add("TextBlock").Text("Manage Users").VerticalAlignment("Center")

    popBtn2 := popupStack.Add("Button").Name("BtnSettingsMenu").Style("{StaticResource DropdownMenuItem}")
    popSp2 := popBtn2.Add("StackPanel").Orientation("Horizontal")
    popSp2.Add("TextBlock").Text(Chr(0xE713)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("{DynamicResource TextSub}").FontSize(16).VerticalAlignment("Center").Margin("0,0,10,0")
    popSp2.Add("TextBlock").Text("Settings").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")


    ; Badge
    badgeContainer := grid1.Add("Grid").Grid_Column(4).Width(40).Height(40)
    badgeContainer.Add("Border").Background("{DynamicResource ControlBg}").CornerRadius(4)
    badgeContainer.Add("TextBlock").Text(Chr(0xE715)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Foreground("{DynamicResource TextMain}")
    bdg := badgeContainer.Add("Border").Name("BdgBorder").Style("{StaticResource BadgeStyle}").Background("{DynamicResource Accent}")
    bdg.Add("TextBlock").Name("BdgText").Style("{StaticResource BadgeText}").Foreground("White").Text("3")
    badgeContainer.Add("Button").Name("BtnBadgeToggle").Background("Transparent").BorderThickness("0").Cursor("Hand")

    ; Spinner / Pulsing
    pulseGrid := grid1.Add("Grid").Grid_Column(6)
    pulseGrid.Cols("Auto", "15", "Auto")
    pulseGrid.Add("ProgressBar").Grid_Column(0).Name("TaskSpinner").Style("{StaticResource ProgressRing}").Visibility("Hidden")
    pulseGrid.Add("ProgressBar").Grid_Column(0).Name("TaskPulsing").Style("{StaticResource PulsingRing}").Visibility("Visible")
    pulseGrid.Add("Button").Grid_Column(2).Name("BtnToggleTask").Content("Start Task").Use("PrimaryBtn").Padding("20,8").Width(100)
    pulseGrid.Add("Button").Grid_Column(2).Name("BtnStopTask").Content("Stop Task").Background("Transparent").Foreground("#FF453A").BorderBrush("#FF453A").BorderThickness("1").Padding("20,8").Visibility("Collapsed").Width(100)

    ; InfoBar
    panel.Add("TextBlock").Text("INFOBAR / ALERTBOX")
    infobar := panel.Add("Border").Style("{StaticResource InfoBar}").Background("#20FF9F0A").BorderBrush("#40FF9F0A").Margin("0,0,0,20")
    infoStack := infobar.Add("StackPanel").Orientation("Horizontal")
    infoStack.Add("TextBlock").Text(Chr(0xE7BA)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("#FF9F0A").FontSize(16).VerticalAlignment("Center").Margin("0,0,10,0")
    infoStack.Add("TextBlock").Text("System maintenance is scheduled for 02:00 AM UTC.").Foreground("#FF9F0A").VerticalAlignment("Center").Margin("0")

    ; Inputs
    panel.Add("TextBlock").Text("ADVANCED INPUTS").Margin("0,0,0,8")
    inputGrid := panel.Add("Grid").Margin("0,0,0,20")
    inputGrid.Cols("200", "20", "200")

    ; SearchBox
    searchGrid := inputGrid.Add("Grid").Grid_Column(0)
    searchGrid.Add("TextBox").Name("TxtSearch").Style("{StaticResource SearchBox}").Tag("Search query...").Text("")
    searchGrid.Add("Button").Name("BtnClearSearch").Content(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).HorizontalAlignment("Right").VerticalAlignment("Center").Margin("0,0,10,0").FontSize(10).Cursor("Hand")

    ; NumericUpDown
    numSp := inputGrid.Add("StackPanel").Grid_Column(2)
    numSp.Add("TextBox").Name("NumInput").Style("{StaticResource NumericUpDown}").Text("42").HorizontalContentAlignment("Center").Margin("0,0,0,10")
    numSp.Add("TextBox").Name("DecInput").Style("{StaticResource NumericUpDown}").Text("3.14").HorizontalContentAlignment("Center")

    ; Progress Bar
    panel.Add("TextBlock").Text("STANDARD PROGRESS BAR")
    panel.Add("ProgressBar").Value(65).Maximum(100).Margin("0,0,0,20")

    ; Calendar / DatePicker
    panel.Add("TextBlock").Text("DATE SELECTION").Margin("0,0,0,8")
    dateGrid := panel.Add("Grid").Margin("0,0,0,20")
    dateGrid.Cols("Auto", "*")
    dateGrid.Add("DatePicker").Grid_Column(0).Height(30).Width(200)

    ; Notifications & Modals
    panel.Add("TextBlock").Text("NOTIFICATIONS & DIALOGS").Margin("0,0,0,8")
    ndGrid := panel.Add("Grid").Margin("0,0,0,20")
    ndGrid.Cols("Auto", "20", "Auto")
    ndGrid.Add("Button").Grid_Column(0).Name("BtnShowSnackbar").Content("Show Snackbar").Width(150).Use("PrimaryBtn")
    ndGrid.Add("Button").Grid_Column(2).Name("BtnShowModal").Content("In-Window Modal").Width(150)

    ; Breadcrumb Bar
    panel.Add("TextBlock").Text("BREADCRUMB BAR").Margin("0,0,0,8")
    bc := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,20")
    bc.Add("Button").Style("{StaticResource BreadcrumbButton}").Content("Home")
    bc.Add("TextBlock").Text(Chr(0xE76C)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).Foreground("{DynamicResource TextSub}").Margin("8,0").VerticalAlignment("Center")
    bc.Add("Button").Style("{StaticResource BreadcrumbButton}").Content("System")
    bc.Add("TextBlock").Text(Chr(0xE76C)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).Foreground("{DynamicResource TextSub}").Margin("8,0").VerticalAlignment("Center")
    bc.Add("Button").Style("{StaticResource BreadcrumbButton}").Content("Configuration").Foreground("{DynamicResource Accent}")

    ; Tokenizer (Tag Input)
    tokHeaderSp := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,8")
    tokHeaderSp.Add("TextBlock").Text("TOKENIZING SEARCH (TAGS)").VerticalAlignment("Center").Margin("0,0,15,0")
    tokCombo := tokHeaderSp.Add("ComboBox").Name("ComboTokenSplit").Width(180).Height(35).SelectedIndex(0)
    tokCombo.Add("ComboBoxItem").Content("Comma (,)")
    tokCombo.Add("ComboBoxItem").Content("Space ( )")
    tokHeaderSp.Add("CheckBox").Name("ChkConfirmDelete").Content("Confirm Deletion").VerticalAlignment("Center").Margin("15,0,0,0").IsChecked("True")

    tokBorder := panel.Add("Border").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("6").Padding("6,6,0,0").Margin("0,0,0,20")
    tokWp := tokBorder.Add("WrapPanel").Name("TokenWrapPanel").Orientation("Horizontal").Background("Transparent").Cursor("IBeam")

    tag1 := tokWp.Add("Border").Name("TagBorder1").Style("{StaticResource TagToken}")
    tag1Sp := tag1.Add("StackPanel").Orientation("Horizontal")
    tag1Sp.Add("TextBlock").Name("TagText1").Text("system32").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontSize(12)
    tag1Sp.Add("Button").Name("BtnDeleteTag1").Style("{StaticResource TagTokenCloseBtn}")

    tag2 := tokWp.Add("Border").Name("TagBorder2").Style("{StaticResource TagToken}")
    tag2Sp := tag2.Add("StackPanel").Orientation("Horizontal")
    tag2Sp.Add("TextBlock").Name("TagText2").Text("drivers").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontSize(12)
    tag2Sp.Add("Button").Name("BtnDeleteTag2").Style("{StaticResource TagTokenCloseBtn}")

    Loop 8 {
        idx := A_Index + 2
        tag := tokWp.Add("Border").Name("TagBorder" idx).Style("{StaticResource TagToken}").Visibility("Collapsed")
        tagSp := tag.Add("StackPanel").Orientation("Horizontal")
        tagSp.Add("TextBlock").Name("TagText" idx).Text("").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontSize(12)
        tagSp.Add("Button").Name("BtnDeleteTag" idx).Style("{StaticResource TagTokenCloseBtn}")
    }

    tokWp.Add("TextBox").Name("TxtTokenInput").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").MinWidth("100").Tag("Add filter...").Margin("0,0,0,6")

    ; Advanced Color Picker
    panel.Add("TextBlock").Text("ADVANCED COLOR PICKER").Margin("0,0,0,8")
    cpBtn := panel.Add("Button").Name("BtnOpenColorPicker").Width(150).HorizontalAlignment("Left").Margin("0,0,0,20")
    cpSp2 := cpBtn.Add("StackPanel").Orientation("Horizontal")
    cpSp2.Add("Border").Name("BtnColorPreview").Width(12).Height(12).CornerRadius("6").Background("#FF0A84FF").Margin("0,0,8,0").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
    cpSp2.Add("TextBlock").Text("Select Color...")

    panel.Add("TextBlock").Text("CONTEXT MENU").Use("PageTitle").Margin("0,20,0,0")
    ctxBtn := panel.Add("Button").Content("Right-Click Me!").Width(200).HorizontalAlignment("Left")
    ctxMenu := ctxBtn.Add("Button.ContextMenu").Add("ContextMenu")

    mi1 := ctxMenu.Add("MenuItem").Header("Edit")
    mi1.Add("MenuItem.Icon").Add("TextBlock").Text(Chr(0xE70F)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(12).Foreground("{DynamicResource TextMain}").Margin("0")

    mi2 := ctxMenu.Add("MenuItem").Header("Share").InputGestureText("Ctrl+S")
    mi2.Add("MenuItem.Icon").Add("TextBlock").Text(Chr(0xE72D)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(12).Foreground("{DynamicResource TextMain}").Margin("0")

    mi3 := ctxMenu.Add("MenuItem").Header("Delete").InputGestureText("Del").Foreground("#FF453A")
    mi3.Add("MenuItem.Icon").Add("TextBlock").Text(Chr(0xE74D)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(12).Foreground("#FF453A").Margin("0")
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
ui.OnEvent("BtnShowAlert", "Click", ShowAlertDialog)
ui.OnEvent("BtnShowInput", "Click", ShowInputDialog)
ui.OnEvent("BtnShowError", "Click", ShowErrorDialog)
ui.OnEvent("BtnShowAuth", "Click", ShowAuthDialog)

ui.OnEvent("BtnShowComplex1", "Click", ShowComplexDialog1)
ui.OnEvent("BtnShowComplex2", "Click", ShowComplexDialog2)
ui.OnEvent("BtnShowComplex3", "Click", ShowComplexDialog3)

ui.OnEvent("BtnToggleTask", "Click", ToggleTaskSpinner)
ui.OnEvent("BtnClearSearch", "Click", ClearSearchBox)
ui.OnEvent("PART_UpButton", "Click", IncrementNum)
ui.OnEvent("PART_DownButton", "Click", DecrementNum)
ui.OnEvent("NumInput", "TextChanged", OnNumTextChanged)
ui.OnEvent("NumInput", "GotFocus", OnInputFocus)
ui.OnEvent("NumInput", "LostFocus", OnInputBlur)
ui.OnEvent("DecInput", "TextChanged", OnNumTextChanged)
ui.OnEvent("DecInput", "GotFocus", OnInputFocus)
ui.OnEvent("DecInput", "LostFocus", OnInputBlur)

ui.OnEvent("TxtSearch", "GotFocus", OnInputFocus)
ui.OnEvent("TxtSearch", "LostFocus", OnInputBlur)
ui.OnEvent("TxtTokenInput", "GotFocus", OnInputFocus)
ui.OnEvent("TxtTokenInput", "LostFocus", OnInputBlur)
ui.OnEvent("ComboFreeSearch", "GotFocus", OnInputFocus)
ui.OnEvent("ComboFreeSearch", "LostFocus", OnInputBlur)
ui.OnEvent("ComboStrictSearch", "GotFocus", OnInputFocus)
ui.OnEvent("BtnManageUsers", "Click", CloseDropdown)
ui.OnEvent("BtnSettingsMenu", "Click", CloseDropdown)
ui.OnEvent("BtnBadgeToggle", "Click", ToggleBadge)
ui.OnEvent("BtnStopTask", "Click", ToggleTaskSpinner)
ui.OnEvent("BtnShowSnackbar", "Click", ShowSnackbar)
ui.OnEvent("BtnShowModal", "Click", ShowInWindowModal)
ui.OnEvent("BtnCloseModal", "Click", CloseInWindowModal)
ui.OnEvent("BtnToggleSidebar", "Click", OnSidebarClick)
ui.OnEvent("BtnShowComplex4", "Click", ShowComplexDialog4)
ui.OnEvent("BtnOpenColorPicker", "Click", ShowColorPickerModal)
ui.OnEvent("BtnCloseColorPicker", "Click", CloseColorPickerModal)

Loop 10 {
    ui.OnEvent("BtnDeleteTag" A_Index, "Click", DeleteTokenTag)
}

ui.OnEvent("HueSlider", "ValueChanged", UpdateColorPicker)
ui.OnEvent("AlphaSlider", "ValueChanged", UpdateColorPicker)
ui.OnEvent("RInput", "TextChanged", UpdateColorPickerFromRGB)
ui.OnEvent("GInput", "TextChanged", UpdateColorPickerFromRGB)
ui.OnEvent("BInput", "TextChanged", UpdateColorPickerFromRGB)
ui.OnEvent("TxtTokenInput", "TextChanged", OnTokenTextChanged)
ui.OnEvent("TokenWrapPanel", "PreviewMouseLeftButtonDown", FocusTokenInput)

ui.OnEvent("ComboStrictSearch", "LostFocus", OnStrictSearchLostFocus)
ui.OnEvent("Window", "Loaded", OnUIReady)
ui.OnEvent("Window", "Closed", (*) => ExitApp())

ui.Track("ComboTheme")
ui.Track("ComboScale")
ui.Track("TxtUser")
ui.Track("ComboRegion")
ui.Track("TglProxy")
ui.Track("ComboStrictSearch")
ui.Track("NumInput")
ui.Track("TxtSearch")
ui.Track("HueSlider")
ui.Track("AlphaSlider")
ui.Track("RInput")
ui.Track("GInput")
ui.Track("BInput")
ui.Track("TxtTokenInput")
ui.Track("BtnToggleSidebar")
ui.Track("ComboTokenSplit")
ui.Track("ChkConfirmDelete")

ui.Show()

; Map Ctrl+B to Toggle Sidebar when window is active
HotIf (*) => WinActive("ahk_id " ui.wpfHwnd)
Hotkey "^b", (*) => ToggleSidebarHotkey(), "On"
HotIf


; Keyboard hooks for NumInput
global focusedInput := ""
global currentNumVal := 42
global currentDecVal := 3.14

OnInputFocus(state, ctrl, event) {
    global focusedInput := ctrl
}
OnInputBlur(state, ctrl, event) {
    global focusedInput := ""
}

HotIf (*) => (WinActive("ahk_id " ui.wpfHwnd) && focusedInput != "")
Hotkey "Up", (*) => IncrementNum(Map(), "", ""), "On"
Hotkey "Down", (*) => DecrementNum(Map(), "", ""), "On"
Hotkey "+Up", (*) => IncrementNum(Map(), "", ""), "On"
Hotkey "+Down", (*) => DecrementNum(Map(), "", ""), "On"
Hotkey "Enter", (*) => ValidateInput(Map(), "", ""), "On"
Hotkey "Escape", (*) => ClearOrBlurInput(Map(), "", ""), "On"
HotIf

; --- EVENT CALLBACKS ---

OnStrictSearchLostFocus(state, ctrl, event) {
    text := state["ComboStrictSearch"]
    valid := false
    for item in ["Administrator", "Moderator", "User", "Guest"] {
        if (text == item) {
            valid := true
            break
        }
    }
    if (!valid && text != "") {
        ui.Update("ComboStrictSearch", "Text", "")
    }
}

ToggleTaskSpinner(state, ctrl, event) {
    static taskActive := false
    taskActive := !taskActive
    if (taskActive) {
        ui.Update("TaskSpinner", "Visibility", "Visible")
        ui.Update("TaskPulsing", "Visibility", "Hidden")
        ui.Update("BtnToggleTask", "Visibility", "Collapsed")
        ui.Update("BtnStopTask", "Visibility", "Visible")
    } else {
        ui.Update("TaskSpinner", "Visibility", "Hidden")
        ui.Update("TaskPulsing", "Visibility", "Visible")
        ui.Update("BtnToggleTask", "Visibility", "Visible")
        ui.Update("BtnStopTask", "Visibility", "Collapsed")
    }
}

ValidateInput(state, ctrl, event) {
    global focusedInput, currentTokenInput, currentTokenSplitMode, activeTagCount
    if (focusedInput == "TxtTokenInput") {
        token := currentTokenInput
        if (token != "") {
            trimmed := Trim(token)
            if (trimmed != "") {
                if (activeTagCount < 10) {
                    activeTagCount++
                    ui.Update("TagText" activeTagCount, "Text", trimmed)
                    ui.Update("TagBorder" activeTagCount, "Visibility", "Visible")
                    ui.Update("LogList", "AddItem", "Captured Tag: " trimmed)
                }
            }
            ui.Update("TxtTokenInput", "Text", "")
            currentTokenInput := ""
        }
    }
    if (focusedInput != "") {
        ui.Update("AppGrid", "Focus", "True")
    }
}

FocusTokenInput(state, ctrl, event) {
    ui.Update("TxtTokenInput", "Focus", "True")
}

ClearOrBlurInput(state, ctrl, event) {
    global focusedInput
    if (focusedInput == "TxtSearch") {
        ui.Update("TxtSearch", "Text", "")
    } else if (focusedInput == "TxtTokenInput") {
        ui.Update("TxtTokenInput", "Text", "")
    }
    if (focusedInput != "") {
        ui.Update("AppGrid", "Focus", "True")
    }
}

ClearSearchBox(state, ctrl, event) {
    ui.Update("TxtSearch", "Text", "")
    ui.Update("AppGrid", "Focus", "True")
}

CloseDropdown(state, ctrl, event) {
    ui.Update("SplitBtn", "IsChecked", "False")
    if (ctrl == "BtnManageUsers") {
        FluidDialog.Show({
            Title: "Manage Users", Message: "You clicked the Manage Users button!", Icon: Chr(0xE77B), Buttons: ["OK"], Width: 300, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"]
        })
    } else if (ctrl == "BtnSettingsMenu") {
        FluidDialog.Show({
            Title: "Settings", Message: "You clicked the Settings button!", Icon: Chr(0xE713), Buttons: ["OK"], Width: 300, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"]
        })
    }
}

ToggleBadge(state, ctrl, event) {
    static badgeState := 0
    badgeState++
    if (badgeState > 3)
        badgeState := 0

    if (badgeState == 0) {
        ui.Update("BdgBorder", "Visibility", "Collapsed")
    } else {
        ui.Update("BdgBorder", "Visibility", "Visible")
        if (badgeState == 1)
            ui.Update("BdgText", "Text", "1")
        else if (badgeState == 2)
            ui.Update("BdgText", "Text", "99+")
        else if (badgeState == 3)
            ui.Update("BdgText", "Text", "!")
    }
}

ShowInWindowModal(state, ctrl, event) {
    ui.Update("ModalOverlay", "Visibility", "Visible")
    ui.Update("ModalBox", "Visibility", "Visible")
}

CloseInWindowModal(state, ctrl, event) {
    ui.Update("ModalOverlay", "Visibility", "Collapsed")
    ui.Update("ModalBox", "Visibility", "Collapsed")
}

ShowSnackbar(state, ctrl, event) {
    ui.Update("SnackbarContainer", "Visibility", "Visible")
    SetTimer(HideSnackbar, -3000)
}

HideSnackbar() {
    ui.Update("SnackbarContainer", "Visibility", "Collapsed")
}

ShowColorPickerModal(state, ctrl, event) {
    ui.Update("ModalOverlay", "Visibility", "Visible")
    ui.Update("ColorPickerBox", "Visibility", "Visible")
}

CloseColorPickerModal(state, ctrl, event) {
    ui.Update("ModalOverlay", "Visibility", "Collapsed")
    ui.Update("ColorPickerBox", "Visibility", "Collapsed")
}

DeleteTokenTag(state, ctrl, event) {
    if (state.Has("ChkConfirmDelete") && state["ChkConfirmDelete"] == "True") {
        res := FluidDialog.Show({
            Title: "Delete Tag?",
            Message: "Are you sure you want to remove this tag?",
            Icon: Chr(0xE74D), ; Delete icon
            IconColor: "#FF453A",
            Buttons: ["Delete", "Cancel"],
            Width: 350,
            Modal: true,
            Owner: ui.wpfHwnd,
            Theme: state["ComboTheme"]
        })

        if (res.Button == "Delete") {
            idx := RegExReplace(ctrl, "\D")
            if (idx != "") {
                ui.Update("TagBorder" idx, "Visibility", "Collapsed")
                ui.Update("TagText" idx, "Text", "")
            }
        }
    } else {
        idx := RegExReplace(ctrl, "\D")
        if (idx != "") {
            ui.Update("TagBorder" idx, "Visibility", "Collapsed")
            ui.Update("TagText" idx, "Text", "")
        }
    }
}

global activeTagCount := 2
global currentTokenInput := ""
global currentTokenSplitMode := "Comma (,)"

OnTokenTextChanged(state, ctrl, event) {
    global activeTagCount, currentTokenInput, currentTokenSplitMode
    if (!state.Has("TxtTokenInput") || !state.Has("ComboTokenSplit")) {
        return
    }

    text := state["TxtTokenInput"]
    splitMode := state["ComboTokenSplit"]
    currentTokenInput := text
    currentTokenSplitMode := splitMode

    splitChar := (splitMode == "Space ( )") ? " " : ","

    if (InStr(text, splitChar) || InStr(text, "`n")) {
        ; Handle pasting newlines
        text := StrReplace(text, "`n", splitChar)
        text := StrReplace(text, "`r", "")

        parts := StrSplit(text, splitChar)

        for index, part in parts {
            trimmed := Trim(part)
            if (trimmed != "") {
                if (activeTagCount < 10) {
                    activeTagCount++
                    ui.Update("TagText" activeTagCount, "Text", trimmed)
                    ui.Update("TagBorder" activeTagCount, "Visibility", "Visible")
                    ui.Update("LogList", "AddItem", "Captured Tag: " trimmed)
                }
            }
        }

        ui.Update("TxtTokenInput", "Text", "")
    }
}

OnSidebarClick(state, ctrl, event) {
    global sidebarVisible
    sidebarVisible := !sidebarVisible
}

ToggleSidebarHotkey() {
    ui.Update("BtnToggleSidebar", "Invoke", "1")
    global sidebarVisible
}

UpdateColorPicker(state, ctrl, event) {
    hue := state["HueSlider"] != "" ? Float(state["HueSlider"]) : 0
    alpha := state["AlphaSlider"] != "" ? Integer(state["AlphaSlider"]) : 255

    c := 1.0
    x := c * (1.0 - Abs(Mod(hue / 60.0, 2) - 1.0))
    r := 0.0, g := 0.0, b := 0.0
    if (0 <= hue && hue < 60) {
        r := c, g := x, b := 0
    } else if (60 <= hue && hue < 120) {
        r := x, g := c, b := 0
    } else if (120 <= hue && hue < 180) {
        r := 0, g := c, b := x
    } else if (180 <= hue && hue < 240) {
        r := 0, g := x, b := c
    } else if (240 <= hue && hue < 300) {
        r := x, g := 0, b := c
    } else if (300 <= hue && hue <= 360) {
        r := c, g := 0, b := x
    }

    rInt := Round(r * 255)
    gInt := Round(g * 255)
    bInt := Round(b * 255)

    hex := Format("#{:02X}{:02X}{:02X}{:02X}", alpha, rInt, gInt, bInt)

    ui.Update("ColorPreview", "Background", hex)
    ui.Update("BtnColorPreview", "Background", hex)
    ui.Update("HexInput", "Text", hex)
    ui.Update("RInput", "Text", String(rInt))
    ui.Update("GInput", "Text", String(gInt))
    ui.Update("BInput", "Text", String(bInt))
}

UpdateColorPickerFromRGB(state, ctrl, event) {
    try {
        r := state["RInput"] != "" ? Integer(state["RInput"]) : 0
        g := state["GInput"] != "" ? Integer(state["GInput"]) : 0
        b := state["BInput"] != "" ? Integer(state["BInput"]) : 0

        r := Min(Max(r, 0), 255)
        g := Min(Max(g, 0), 255)
        b := Min(Max(b, 0), 255)

        alpha := state["AlphaSlider"] != "" ? Integer(state["AlphaSlider"]) : 255
        hex := Format("#{:02X}{:02X}{:02X}{:02X}", alpha, r, g, b)

        ui.Update("HexInput", "Text", hex)
        ui.Update("ColorPreview", "Background", hex)
        ui.Update("BtnColorPreview", "Background", hex)
    }
}

OnTokenKeyDown(state, ctrl, event) {
    ; Handled via hotkeys
}


OnNumTextChanged(state, ctrl, event) {
    global currentNumVal, currentDecVal
    if (ctrl == "NumInput") {
        val := state["NumInput"]
        clean := RegExReplace(val, "[^\d\-]")
        if (clean != val) {
            ui.Update("NumInput", "Text", clean)
            currentNumVal := clean != "" && clean != "-" ? Integer(clean) : 0
        } else {
            currentNumVal := val != "" && val != "-" ? Integer(val) : 0
        }
    } else if (ctrl == "DecInput") {
        val := state["DecInput"]
        clean := RegExReplace(val, "[^\d\.\-]")
        StrReplace(clean, ".", ".", , &dotCount)
        if (dotCount > 1) {
            clean := SubStr(clean, 1, InStr(clean, ".", , , 2) - 1)
        }
        if (clean != val) {
            ui.Update("DecInput", "Text", clean)
        }
        if (clean != "" && clean != "-" && clean != "." && !RegExMatch(clean, "\.$")) {
            currentDecVal := Float(clean)
        }
    }
}

IncrementNum(state, ctrl, event) {
    global currentNumVal, currentDecVal, focusedInput
    target := ctrl ? ctrl : focusedInput

    if (target == "NumInput" || target == "PART_UpButton") {
        step := GetKeyState("Shift", "P") ? 10 : 1
        if (currentNumVal + step <= 100) {
            currentNumVal += step
            ui.Update("NumInput", "Text", String(currentNumVal))
        }
    } else if (target == "DecInput" || target == "PART_UpButton") {
        step := GetKeyState("Shift", "P") ? 1.0 : 0.1
        if (currentDecVal + step <= 100.0) {
            currentDecVal += step
            ui.Update("DecInput", "Text", String(Round(currentDecVal, 2)))
        }
    }
}

DecrementNum(state, ctrl, event) {
    global currentNumVal, currentDecVal, focusedInput
    target := ctrl ? ctrl : focusedInput

    if (target == "NumInput" || target == "PART_DownButton") {
        step := GetKeyState("Shift", "P") ? 10 : 1
        if (currentNumVal - step >= 0) {
            currentNumVal -= step
            ui.Update("NumInput", "Text", String(currentNumVal))
        }
    } else if (target == "DecInput" || target == "PART_DownButton") {
        step := GetKeyState("Shift", "P") ? 1.0 : 0.1
        if (currentDecVal - step >= 0.0) {
            currentDecVal -= step
            ui.Update("DecInput", "Text", String(Round(currentDecVal, 2)))
        }
    }
}

OnNumKey(state, ctrl, event) {
    ; Event might not pass Key natively without C# changes, but we can bind to KeyUp instead if we supported args.
    ; For now, if we cannot get the Key pressed from state directly, we'll wait.
    ; Wait, the XAML Engine CollectState doesn't pass the key pressed automatically.
}

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

global sidebarVisible := false


ShowAlertDialog(state, ctrl, event) {
    res := FluidDialog.Show({
        Title: "Alert",
        Message: "This is your custom message content.",
        Icon: Chr(0xE946), ; Info icon
        IconColor: "#FF453A",
        Progress: true,
        Buttons: ["OK", "Cancel"],
        Width: 400,
        Modal: true,
        Owner: ui.wpfHwnd,
        Theme: state["ComboTheme"],
        Sound: "*-1" ; Default beep
    })

    if (res.Button == "OK") {
        ui.Update("LogList", "AddItem", "Alert dialog accepted!")
    }
}

ShowInputDialog(state, ctrl, event) {
    res := FluidDialog.Show({
        Title: "What is your name?",
        Message: "This is your custom message content.",
        Icon: Chr(0xE70F), ; Pencil icon
        IconColor: "#0A84FF",
        InputText: "Type here...",
        Buttons: ["OK", "Cancel"],
        Width: 450,
        Modal: true,
        Owner: ui.wpfHwnd,
        Theme: state["ComboTheme"]
    })

    if (res.Button == "OK") {
        ui.Update("LogList", "AddItem", "User inputted: " res.Input)

        ; Chain a second dialog to prove sequential execution works!
        FluidDialog.Show({
            Title: "Hello there!",
            Message: "Welcome to the AHKAST Workbench, " res.Input "!",
            Icon: Chr(0xE77B), ; User icon
            IconColor: "#32D74B",
            Buttons: ["Awesome"],
            Width: 400,
            Modal: true,
            Owner: ui.wpfHwnd,
            Theme: state["ComboTheme"],
            Sound: "*-1"
        })
    }
}

ShowErrorDialog(state, ctrl, event) {
    res := FluidDialog.Show({
        Title: "Critical Error",
        Message: "There was a critical error found before saving!`nThe following error was found in the board file:",
        Icon: Chr(0xE7BA), ; Warning icon
        IconColor: "#FFD60A",
        DetailText: "MESSAGE: 0x0000000`n`nThis is a very long error message that will definitely wrap around to`nmultiple lines`n`nto test the selection functionality and ensure`nthat it works`ncorrectly`nacross all visible text within the control's boundaries.",
        DetailRows: 10,
        Buttons: ["Close"],
        Width: 550,
        Modal: true,
        Owner: ui.wpfHwnd,
        Theme: state["ComboTheme"],
        Sound: "*16" ; Critical stop
    })
}

ShowAuthDialog(state, ctrl, event) {
    res := FluidDialog.Show({
        Title: "Advanced Tool Authentication",
        Message: "The AI Agent has requested to execute a tool:",
        Icon: Chr(0xE7BA),
        IconColor: "#E0AA00",
        DetailText: "GET_TIME",
        DetailRows: 5,
        InputText: "Provide feedback or a reason for denial (Optional):",
        Buttons: ["Allow Execution", "Deny & Send Feedback"],
        Width: 500,
        Modal: true,
        Owner: ui.wpfHwnd,
        Theme: state["ComboTheme"],
        Sound: "*-1"
    })

    ui.Update("LogList", "AddItem", "Auth result: " res.Button)
}

ShowComplexDialog1(state, ctrl, event) {
    res := FluidDialog.Show({
        Title: "Analyzing Workspace",
        Message: "The internal AST analyzer is currently scanning the environment and building the tree index. This might take a few moments.",
        Progress: true,
        Buttons: ["Cancel"],
        Width: 480,
        Modal: true,
        Owner: ui.wpfHwnd,
        Theme: state["ComboTheme"],
        WaitForResponse: false
    })

    dialogUi := res.Instance

    ; Simulate work
    Loop 10 {
        if (res.Button != "") ; User clicked Cancel or closed
            return

        dialogUi.Update("DialogProgSub1", "Text", "Scanning file " A_Index " of 10...")
        dialogUi.Update("DialogProg1", "Value", String(A_Index * 10))

        Sleep(300)
    }

    if (res.Button == "") {
        dialogUi.Update("DialogProgSub1", "Text", "Analysis complete.")
        Sleep(500)
        dialogUi.Update("Window", "Close", "")
        ui.Update("LogList", "AddItem", "Complex 1 result: Success")
    } else {
        ui.Update("LogList", "AddItem", "Complex 1 result: " res.Button)
    }
}

ShowComplexDialog2(state, ctrl, event) {
    res := FluidDialog.Show({
        Title: "Diagnostic Terminal",
        Message: "Streaming live verbose logs from the backend engine. Press 'Abort' to stop.",
        DetailText: "Initializing diagnostics...",
        DetailRows: 7,
        Icon: Chr(0xE7BA),
        IconColor: "#FFD60A",
        Buttons: ["Abort", "Close"],
        Width: 550,
        Modal: true,
        Owner: ui.wpfHwnd,
        Theme: state["ComboTheme"],
        WaitForResponse: false
    })

    dialogUi := res.Instance
    logText := "Initializing diagnostics...`n"

    Loop 25 {
        if (res.Button != "")
            break

        logStr := "[" A_Hour ":" A_Min ":" A_Sec "." A_MSec "] Checking subsystem " A_Index "...`n"
        logText .= logStr
        dialogUi.Update("DialogDetail", "AppendText", logStr)
        Sleep(150)
    }

    if (res.Button == "") {
        dialogUi.Update("DialogDetail", "AppendText", "Diagnostics complete.")
        res.Button := "Closed by script"
    }
}

ShowComplexDialog3(state, ctrl, event) {
    res := FluidDialog.Show({
        Title: "Regex Workspace Tool",
        Message: "Draft a new Regular Expression pattern. You can test it below:",
        InputText: "^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$",
        DetailText: "Test String Input:`nsupport@ahkast.io",
        DetailRows: 5,
        Resizable: true,
        Width: 600,
        Height: 500,
        Buttons: ["Execute Matches", "Clear", "Close"],
        Modal: false,
        AlwaysOnTop: true,
        Owner: ui.wpfHwnd,
        Theme: state["ComboTheme"]
    })
    ui.Update("LogList", "AddItem", "Complex 3 Tool Exit: " res.Button)
}

ShowComplexDialog4(state, ctrl, event) {
    res := FluidDialog.Show({
        Title: "Permanent Deletion",
        Message: "Are you sure you want to permanently delete these 14 files? This action cannot be undone.",
        DetailText: "C:\projects\ahk\ahk-xaml\v3-generator\example.ahk`nC:\projects\ahk\ahk-xaml\v2-csc\xaml.components.xaml`nC:\projects\ahk\ahk-xaml\v2-csc\XAMLEngine.ahk",
        DetailRows: 4,
        Icon: Chr(0xE74D), ; Delete icon
        IconColor: "#FF453A",
        Buttons: ["Permanently Delete", "Cancel"],
        Width: 500,
        Modal: true,
        Owner: ui.wpfHwnd,
        Theme: state["ComboTheme"],
        Sound: "*16"
    })
    ui.Update("LogList", "AddItem", "Deletion result: " res.Button)
}