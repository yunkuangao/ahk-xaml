#Requires AutoHotkey v2.0
#Include "../lib/XAML_Host.ahk"
#Include "../lib/XAML_Generator.ahk"
#Include "../lib/XAML_Dialog.ahk"
#Include "../lib/XAML_GUI.ahk"
#Include "../lib/XAML_Components.ahk"

app := XAML_GUI("Fluid UI Workbench")

; Add toggles to the sidebar
app.sidebarPanel.Add("TextBlock").Text("SYSTEM TOGGLES").Margin("0,15,0,15")
app.sidebarPanel.Toggle("TglOverdrive", "Overdrive Mode", true, "Accelerate packet processing natively.")
app.sidebarPanel.Toggle("TglProxy", "Anonymous Proxy", false)

; DEPLOYMENT TAB
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
app.AddTab("DEPLOYMENT", BuildDeploymentTab)

; DATA GRID TAB
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
app.AddTab("DATA GRID", BuildDataGridTab)

; DATAGRID EX TAB
global myGrid := ""
BuildDataGridExTab(tab) {
    global myGrid
    
    ; Generate test data
    testData := []
    roles := ["Administrator", "Developer", "Guest", "Manager", "Analyst"]
    statuses := ["Active", "Offline", "Pending"]
    names := ["John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Eve", "Frank"]
    lasts := ["Doe", "Smith", "Wilson", "Johnson", "Brown", "Taylor", "Anderson"]
    loop 200 {
        n := names[Random(1, names.Length)] " " lasts[Random(1, lasts.Length)]
        r := roles[Random(1, roles.Length)]
        s := statuses[Random(1, statuses.Length)]
        testData.Push({ Id: A_Index, Name: n, Role: r, Status: s })
    }
    
    ; Scramble the data to prove "random order"
    scrambled := []
    while (testData.Length > 0) {
        idx := Random(1, testData.Length)
        scrambled.Push(testData[idx])
        testData.RemoveAt(idx)
    }
    
    ; Create DataGridEx with all features enabled
    myGrid := DataGridEx("DGX", scrambled, {
        PageSize: 50,
        ShowSearch: true,
        ShowFilters: true,
        ShowPagination: true,
        ShowReset: true,
        ShowRowCount: true,
        FilterColumn: "Status",
        FilterValues: ["Active", "Offline", "Pending"],
        SortCol: "Id",
        HiddenColumns: ["Id"],
        ColumnWidths: { Id: "50", Name: "250", Role: "180", Status: "180" }
    })
    
    panel := tab.Add("Grid").Margin("0,20,0,20")
    panel.Rows("Auto", "*")
    panel.Add("TextBlock").Text("Data View Engine").Use("PageTitle").Margin("0,0,0,10").Grid_Row(0)
    myGrid.Build(panel).Grid_Row(1)
}
app.AddTab("DATAGRID EX", BuildDataGridExTab)

; UI COMPONENTS TAB
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
    tv := panel.Add("Border").Use("CardPanel").Margin("0,0,0,20").Add("TreeView").MaxHeight(200).Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextMain}").Margin("10")
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
app.AddTab("UI COMPONENTS", BuildComponentsTab)

; ADVANCED INPUTS TAB
BuildAdvancedInputsTab(tab) {
    scroll := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,0")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Advanced XAML Inputs").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("Dynamic search boxes and filtering capabilities.").Use("BodyText").Margin("0,0,0,20")

    panel.Add("TextBlock").Text("FREE-TYPE AUTO-SUGGEST SEARCH")
    panel.Add("TextBlock").Text("Type anything, or use the dropdown to see suggestions. It acts like a search box.").Use("BodyText").Margin("0,0,0,15").Opacity(0.7)
    c1 := panel.Add("ComboBox").Name("ComboFreeSearch").IsEditable("True").IsTextSearchEnabled("True").StaysOpenOnEdit("True").Margin("0,0,0,30").Width(400).HorizontalAlignment("Left")
    c1.Add("ComboBoxItem").Content("Apple")
    c1.Add("ComboBoxItem").Content("Banana")
    c1.Add("ComboBoxItem").Content("Cherry")
    c1.Add("ComboBoxItem").Content("Date")
    c1.Add("ComboBoxItem").Content("Elderberry")

    panel.Add("TextBlock").Text("STRICT LIST SEARCH")
    panel.Add("TextBlock").Text("Editable combobox configured for strict matching workflows. You can type to filter/jump.").Use("BodyText").Margin("0,0,0,15").Opacity(0.7)
    c2 := panel.Add("ComboBox").Name("ComboStrictSearch").IsEditable("True").IsTextSearchEnabled("True").Margin("0,0,0,30").Width(400).HorizontalAlignment("Left")
    c2.Add("ComboBoxItem").Content("Administrator")
    c2.Add("ComboBoxItem").Content("Moderator")
    c2.Add("ComboBoxItem").Content("User")
    c2.Add("ComboBoxItem").Content("Guest")
}
app.AddTab("ADVANCED INPUTS", BuildAdvancedInputsTab)

; FLUID DIALOGS TAB
BuildXDialogsTab(tab) {
    scroll := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,0")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Fluid Dialog Engine").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("A robust, non-blocking asynchronous event flow for rich popups and modals.").Use("BodyText").Margin("0,0,0,20")

    panel.Add("TextBlock").Text("BASIC INTERACTIONS")
    basicSp := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,20")
    basicSp.Add("Button").Name("BtnShowAlert").Content("Show Alert").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn")
    basicSp.Add("Button").Name("BtnShowInput").Content("Ask Name").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn")
    basicSp.Add("Button").Name("BtnShowError").Content("Critical Error").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("#FF3B30").BorderBrush("#FF3B30").BorderThickness(1)
    basicSp.Add("Button").Name("BtnShowAuth").Content("Auth Dialog").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("{DynamicResource Accent}").BorderBrush("{DynamicResource Accent}").BorderThickness(1)

    panel.Add("TextBlock").Text("COMPLEX & DYNAMIC")
    cmplxSp := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,20")
    cmplxSp.Add("Button").Name("BtnShowComplex1").Content("Progress Task").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1)
    cmplxSp.Add("Button").Name("BtnShowComplex2").Content("Detail Log View").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1)
    cmplxSp.Add("Button").Name("BtnShowComplex3").Content("Resizable Tool").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("{DynamicResource Accent}").BorderBrush("{DynamicResource Accent}").BorderThickness(1)
    cmplxSp.Add("Button").Name("BtnShowComplex4").Content("File Deletion").Width(120).Height(35).Margin("0,0,10,0").Use("PrimaryBtn").Background("Transparent").Foreground("#FF453A").BorderBrush("#FF453A").BorderThickness(1)
}
app.AddTab("FLUID DIALOGS", BuildXDialogsTab)

; RICH COMPONENTS TAB
BuildRichComponentsTab(tab) {
    scroll := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,20")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Rich UI Components").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("Showcasing newly added advanced controls.").Use("BodyText").Margin("0,0,0,20")

    panel.Add("TextBlock").Text("BUTTONS & INDICATORS")
    grid1 := panel.Add("Grid").Margin("0,0,0,20")
    grid1.Cols("Auto", "20", "Auto", "20", "Auto", "20", "Auto")

    grid1.Add("Button").Grid_Column(0).Style("{StaticResource IconButton}").Add("TextBlock").Text(Chr(0xE713)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")

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

    badgeContainer := grid1.Add("Grid").Grid_Column(4).Width(40).Height(40)
    badgeContainer.Add("Border").Background("{DynamicResource ControlBg}").CornerRadius(4)
    badgeContainer.Add("TextBlock").Text(Chr(0xE715)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Foreground("{DynamicResource TextMain}")
    bdg := badgeContainer.Add("Border").Name("BdgBorder").Style("{StaticResource BadgeStyle}").Background("{DynamicResource Accent}")
    bdg.Add("TextBlock").Name("BdgText").Style("{StaticResource BadgeText}").Foreground("White").Text("3")
    badgeContainer.Add("Button").Name("BtnBadgeToggle").Background("Transparent").BorderThickness("0").Cursor("Hand")

    pulseGrid := grid1.Add("Grid").Grid_Column(6)
    pulseGrid.Cols("Auto", "15", "Auto")
    pulseGrid.Add("ProgressBar").Grid_Column(0).Name("TaskSpinner").Style("{StaticResource ProgressRing}").Visibility("Hidden")
    pulseGrid.Add("ProgressBar").Grid_Column(0).Name("TaskPulsing").Style("{StaticResource PulsingRing}").Visibility("Visible")
    pulseGrid.Add("Button").Grid_Column(2).Name("BtnToggleTask").Content("Start Task").Use("PrimaryBtn").Padding("20,8").Width(100)
    pulseGrid.Add("Button").Grid_Column(2).Name("BtnStopTask").Content("Stop Task").Background("Transparent").Foreground("#FF453A").BorderBrush("#FF453A").BorderThickness("1").Padding("20,8").Visibility("Collapsed").Width(100)

    panel.Add("TextBlock").Text("INFOBAR / ALERTBOX")
    infobar := panel.Add("Border").Style("{StaticResource InfoBar}").Background("#20FF9F0A").BorderBrush("#40FF9F0A").Margin("0,0,0,20")
    infoStack := infobar.Add("StackPanel").Orientation("Horizontal")
    infoStack.Add("TextBlock").Text(Chr(0xE7BA)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("#FF9F0A").FontSize(16).VerticalAlignment("Center").Margin("0,0,10,0")
    infoStack.Add("TextBlock").Text("System maintenance is scheduled for 02:00 AM UTC.").Foreground("#FF9F0A").VerticalAlignment("Center").Margin("0")

    panel.Add("TextBlock").Text("ADVANCED INPUTS").Margin("0,0,0,8")
    inputGrid := panel.Add("Grid").Margin("0,0,0,20")
    inputGrid.Cols("200", "20", "200")

    searchGrid := inputGrid.Add("Grid").Grid_Column(0)
    searchGrid.Add("TextBox").Name("TxtSearch").Style("{StaticResource SearchBox}").Tag("Search query...").Text("")
    searchGrid.Add("Button").Name("BtnClearSearch").Content(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).HorizontalAlignment("Right").VerticalAlignment("Center").Margin("0,0,10,0").FontSize(10).Cursor("Hand")

    ; --- USING NEW COMPONENT CLASSES ---
    numSp := inputGrid.Add("StackPanel").Grid_Column(2)
    num1 := XNumericUpDown(app, numSp, false, { Default: 42 })
    num2 := XNumericUpDown(app, numSp, true, { Default: 3.14 })
    app.RegisterNumericInput(num1)
    app.RegisterNumericInput(num2)
    ; -----------------------------------

    panel.Add("TextBlock").Text("STANDARD PROGRESS BAR")
    panel.Add("ProgressBar").Value(65).Maximum(100).Margin("0,0,0,20")

    panel.Add("TextBlock").Text("DATE SELECTION").Margin("0,0,0,8")
    dateGrid := panel.Add("Grid").Margin("0,0,0,20")
    dateGrid.Cols("Auto", "*")
    dateGrid.Add("DatePicker").Grid_Column(0).Height(30).Width(200)

    panel.Add("TextBlock").Text("NOTIFICATIONS & DIALOGS").Margin("0,0,0,8")
    ndGrid := panel.Add("Grid").Margin("0,0,0,20")
    ndGrid.Cols("Auto", "20", "Auto")
    ndGrid.Add("Button").Grid_Column(0).Name("BtnShowSnackbar").Content("Show Snackbar").Width(150).Height(32).Use("PrimaryBtn")
    ndGrid.Add("Button").Grid_Column(2).Name("BtnShowTestModal").Content("Test Modal").Width(150).Height(32).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Cursor("Hand")

    panel.Add("TextBlock").Text("BREADCRUMB BAR").Margin("0,0,0,8")
    bc := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,20")
    bc.Add("Button").Style("{StaticResource BreadcrumbButton}").Content("Home")
    bc.Add("TextBlock").Text(Chr(0xE76C)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).Foreground("{DynamicResource TextSub}").Margin("8,0").VerticalAlignment("Center")
    bc.Add("Button").Style("{StaticResource BreadcrumbButton}").Content("System")
    bc.Add("TextBlock").Text(Chr(0xE76C)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).Foreground("{DynamicResource TextSub}").Margin("8,0").VerticalAlignment("Center")
    bc.Add("Button").Style("{StaticResource BreadcrumbButton}").Content("Configuration").Foreground("{DynamicResource Accent}")

    ; --- USING NEW COMPONENT CLASSES ---
    tok := XTokenizer(app, panel, { InitialTags: ["system32", "drivers"], LogTarget: "LogList" })
    app.RegisterTokenizer(tok)
    ; -----------------------------------

    panel.Add("TextBlock").Text("ADVANCED COLOR PICKER").Margin("0,0,0,8").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold")
    cpBtn := panel.Add("Button").Name("BtnOpenColorPicker").Width(150).HorizontalAlignment("Left").Margin("0,0,0,20").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}").Padding("10,6").Cursor("Hand")
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
app.AddTab("RICH COMPONENTS", BuildRichComponentsTab)
app.AddTab("ADVANCED UI", BuildAdvancedUITab)

; BOTTOM BAR
BuildBottomBar(actions) {
    actions.Height(90)
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
app.SetBottomBar(BuildBottomBar)

; COMPILE THE UI (This generates the host and binds the base classes)
ui := app.Compile()

; ==============================================================================
; APP SPECIFIC EVENT HANDLERS
; ==============================================================================

ui.OnEvent("BtnExecute", "Click", ExecuteProcess)
ui.OnEvent("BtnShowAlert", "Click", ShowAlertDialog)
ui.OnEvent("BtnShowInput", "Click", ShowInputDialog)
ui.OnEvent("BtnShowError", "Click", ShowErrorDialog)
ui.OnEvent("BtnShowAuth", "Click", ShowAuthDialog)
ui.OnEvent("BtnShowComplex1", "Click", ShowComplexDialog1)
ui.OnEvent("BtnShowComplex2", "Click", ShowComplexDialog2)
ui.OnEvent("BtnShowComplex3", "Click", ShowComplexDialog3)
ui.OnEvent("BtnShowComplex4", "Click", ShowComplexDialog4)
ui.OnEvent("BtnToggleTask", "Click", ToggleTaskSpinner)
ui.OnEvent("BtnStopTask", "Click", ToggleTaskSpinner)
ui.OnEvent("BtnClearSearch", "Click", ClearSearchBox)
ui.OnEvent("BtnManageUsers", "Click", CloseDropdown)
ui.OnEvent("BtnSettingsMenu", "Click", CloseDropdown)
ui.OnEvent("BtnBadgeToggle", "Click", ToggleBadge)
ui.OnEvent("BtnShowSnackbar", "Click", (*) => app.ShowSnackbar("Action completed successfully!"))
ui.OnEvent("BtnShowTestModal", "Click", ShowTestModal)
ui.OnEvent("ComboStrictSearch", "LostFocus", OnStrictSearchLostFocus)
ui.OnEvent("BtnOpenColorPicker", "Click", ShowColorPickerModal)

; Advanced UI Tab Events
ui.OnEvent("MyDropZone", "PreviewMouseLeftButtonDown", OnFileDropClick)
ui.OnEvent("BtnBadge", "Click", (*) => app.ShowSnackbar("You have 3 new notifications!", "DISMISS"))

; Rating — bind star click events
RatingBind(ui, "Rating5", 5, false, Chr(0xE735), Chr(0xE734), "#FFD700", "{DynamicResource TextSub}")
RatingBind(ui, "Rating10", 10, false, Chr(0xEB52), Chr(0xEB51), "#FF453A", "{DynamicResource TextSub}")

; Emoji Picker — bind all emoji button events
emojiList := ["😀","😁","😂","🤣","😃","😄","😅","😆","😉","😊","😋","😎","😍","🥰","😘","😗","😙","🤗","🤩","🤔","🤨","😐","😑","😶","🙄","😏","😣","😥","😮","🤐","😯","😪","😫","🥱","😴","😌","👍","👎","👏","🙌","🤝","👋","✌️","🤞","🤟","🤘","👌","🤌","👈","👉","👆","👇","☝️","✋","❤️","🧡","💛","💚","💙","💜","🖤","🤍","💔","❣️","💕","💞","💓","💗","💖","💘","💝","💟","🔥","⭐","🌟","✨","💫","🎉","🎊","🏆","🥇","🎯","💡","📌","📎","🔑","🔒","💬","💭","🗨️"]
EmojiPickerBind(ui, "MyEmoji", emojiList)

; Bind DateRangePickerEx events
myDatePicker.Bind(ui)
ui.OnEvent("PriceFilter_SliderMin", "ValueChanged", ClampSliderMin)
ui.OnEvent("PriceFilter_SliderMax", "ValueChanged", ClampSliderMax)
ui.Track("PriceFilter_SliderMin")
ui.Track("PriceFilter_SliderMax")

; DataGridEx — single call to register all events
myGrid.Bind(ui)

ui.Track("TxtUser")
ui.Track("ComboRegion")
ui.Track("TglProxy")
ui.Track("ComboStrictSearch")
ui.Track("TxtSearch")
ui.Track("ComboTheme")

app.Show()

; Prevent scroll leak on emoji picker's inner ScrollViewer
ui.Update("MyEmoji_EmojiScroll", "TrapScroll", "")

; --- Custom Event Implementations ---

ShowColorPickerModal(state, ctrl, event) {
    theme := state.Has("ComboTheme") ? state["ComboTheme"] : "Dark Mica (Win 11)"
    ; Retrieve the current color from the preview element's background (or rely on a bound variable)
    res := XColorPicker.Show({
        Title: "Advanced Color Selector",
        DefaultColor: "#FF0A84FF",
        Owner: ui.wpfHwnd,
        Modal: true,
        Theme: theme
    })

    if (res.Status == "OK") {
        ui.Update("BtnColorPreview", "Background", res.Color)
        app.ShowSnackbar("Color updated to " res.Color)
    }
}

OnFileDropClick(state, ctrl, event) {
    selectedFile := FileSelect(3, , "Select a file to load")
    if (selectedFile) {
        OnFileDropped(selectedFile)
    }
}

OnFileDropped(filePath) {
    SplitPath filePath, &name, &dir, &ext, &name_no_ext, &drive
    ui.Update("MyDropZone_Text", "Text", name)
    ui.Update("MyDropZone_Icon", "Text", Chr(0xE8A5)) ; Document icon
}

; Slider clamping: prevent min > max and max < min
ClampSliderMin(state, ctrl, event) {
    if (state.Has("PriceFilter_SliderMin") && state.Has("PriceFilter_SliderMax")) {
        minVal := Number(state["PriceFilter_SliderMin"])
        maxVal := Number(state["PriceFilter_SliderMax"])
        if (minVal > maxVal)
            ui.Update("PriceFilter_SliderMin", "Value", String(maxVal))
    }
}
ClampSliderMax(state, ctrl, event) {
    if (state.Has("PriceFilter_SliderMin") && state.Has("PriceFilter_SliderMax")) {
        minVal := Number(state["PriceFilter_SliderMin"])
        maxVal := Number(state["PriceFilter_SliderMax"])
        if (maxVal < minVal)
            ui.Update("PriceFilter_SliderMax", "Value", String(minVal))
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

ClearSearchBox(state, ctrl, event) {
    ui.Update("TxtSearch", "Text", "")
    ui.Update("AppGrid", "Focus", "True")
}

CloseDropdown(state, ctrl, event) {
    ui.Update("SplitBtn", "IsChecked", "False")
    if (ctrl == "BtnManageUsers") {
        XDialog.Show({ Title: "Manage Users", Message: "You clicked the Manage Users button!", Icon: Chr(0xE77B), Buttons: ["OK"], Width: 300, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"] })
    } else if (ctrl == "BtnSettingsMenu") {
        XDialog.Show({ Title: "Settings", Message: "You clicked the Settings button!", Icon: Chr(0xE713), Buttons: ["OK"], Width: 300, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"] })
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

ShowAlertDialog(state, ctrl, event) {
    res := XDialog.Show({ Title: "Alert", Message: "This is your custom message content.", Icon: Chr(0xE946), IconColor: "#FF453A", Progress: true, Buttons: ["OK", "Cancel"], Width: 400, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*-1" })
    if (res.Button == "OK")
        ui.Update("LogList", "AddItem", "Alert dialog accepted!")
}

ShowInputDialog(state, ctrl, event) {
    res := XDialog.Show({ Title: "What is your name?", Message: "This is your custom message content.", Icon: Chr(0xE70F), IconColor: "#0A84FF", InputText: "Type here...", Buttons: ["OK", "Cancel"], Width: 450, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"] })
    if (res.Button == "OK") {
        ui.Update("LogList", "AddItem", "User inputted: " res.Input)
        XDialog.Show({ Title: "Hello there!", Message: "Welcome to the AHKAST Workbench, " res.Input "!", Icon: Chr(0xE77B), IconColor: "#32D74B", Buttons: ["Awesome"], Width: 400, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*-1" })
    }
}

ShowErrorDialog(state, ctrl, event) {
    XDialog.Show({ Title: "Critical Error", Message: "There was a critical error found before saving!`nThe following error was found in the board file:", Icon: Chr(0xE7BA), IconColor: "#FFD60A", DetailText: "MESSAGE: 0x0000000`n`nThis is a very long error message that will definitely wrap around to`nmultiple lines`n`nto test the selection functionality and ensure`nthat it works`ncorrectly`nacross all visible text within the control's boundaries.", DetailRows: 10, Buttons: ["Close"], Width: 550, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*16" })
}

ShowAuthDialog(state, ctrl, event) {
    res := XDialog.Show({ Title: "Advanced Tool Authentication", Message: "The AI Agent has requested to execute a tool:", Icon: Chr(0xE7BA), IconColor: "#E0AA00", DetailText: "GET_TIME", DetailRows: 5, InputText: "Provide feedback or a reason for denial (Optional):", Buttons: ["Allow Execution", "Deny & Send Feedback"], Width: 500, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*-1" })
    ui.Update("LogList", "AddItem", "Auth result: " res.Button)
}

ShowComplexDialog1(state, ctrl, event) {
    res := XDialog.Show({ Title: "Analyzing Workspace", Message: "The internal AST analyzer is currently scanning the environment and building the tree index. This might take a few moments.", Progress: true, Buttons: ["Cancel"], Width: 480, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], WaitForResponse: false })
    dialogUi := res.Instance
    Loop 10 {
        if (res.Button != "")
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
    res := XDialog.Show({ Title: "Diagnostic Terminal", Message: "Streaming live verbose logs from the backend engine. Press 'Abort' to stop.", DetailText: "Initializing diagnostics...", DetailRows: 7, Icon: Chr(0xE7BA), IconColor: "#FFD60A", Buttons: ["Abort", "Close"], Width: 550, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], WaitForResponse: false })
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
    res := XDialog.Show({ Title: "Regex Workspace Tool", Message: "Draft a new Regular Expression pattern. You can test it below:", InputText: "^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$", DetailText: "Test String Input:`nsupport@ahkast.io", DetailRows: 5, Resizable: true, Width: 600, Height: 500, Buttons: ["Execute Matches", "Clear", "Close"], Modal: false, AlwaysOnTop: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"] })
    ui.Update("LogList", "AddItem", "Complex 3 Tool Exit: " res.Button)
}

ShowComplexDialog4(state, ctrl, event) {
    res := XDialog.Show({ Id: "delete_confirm", Title: "Permanent Deletion", Message: "Are you sure you want to permanently delete these 14 files? This action cannot be undone.", DetailText: "C:\projects\ahk\ahk-xaml\v3-generator\example.ahk`nC:\projects\ahk\ahk-xaml\v2-csc\xaml.components.xaml`nC:\projects\ahk\ahk-xaml\v2-csc\XAMLEngine.ahk", DetailRows: 4, Icon: Chr(0xE74D), IconColor: "#FF453A", Buttons: ["Permanently Delete", "Cancel"], Width: 500, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*16" })
    ui.Update("LogList", "AddItem", "Deletion result: " res.Button)
}

ShowTestModal(state, ctrl, event) {
    res := XDialog.Show({ Id: "test_modal", Title: "Modal Dialog Test", Message: "This is a simple modal dialog.", Icon: Chr(0xE814), Owner: ui.wpfHwnd, Modal: true, Theme: state.Has("ComboTheme") ? state["ComboTheme"] : "Dark Mica (Win 11)", Movable: false, ShowCloseBtn: false, DarkenOwner: true })
}

; NEW ADVANCED COMPONENTS TAB
BuildAdvancedUITab(tab) {
    scroll := tab.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled").Padding("0,0,15,0")
    panel := scroll.Add("StackPanel").Margin("0,20,0,20")
    panel.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8" })

    panel.Add("TextBlock").Text("Advanced Component Suite").Use("PageTitle").Margin("0,0,0,5")
    panel.Add("TextBlock").Text("A demonstration of the newly integrated advanced XAML components.").Use("BodyText").Margin("0,0,0,20")

    panel.Add("TextBlock").Text("FILE DROP ZONE")
    panel.FileDropZone("MyDropZone", "Drag & Drop files here", [".txt", ".json", ".ahk"]).Margin("0,0,0,20")

    panel.Add("TextBlock").Text("SLIDER RANGE & DATE PICKER")
    grid := panel.Add("Grid").Margin("0,0,0,20")
    grid.Cols("*", "20", "*")
    grid.Add("Border").Grid_Column(0).Use("CardPanel").Padding("15").SliderRange("Price Filter", 0, 100, 20, 80)
    
    dpBdr := grid.Add("Border").Grid_Column(2).Use("CardPanel").Padding("15")
    dpSp := dpBdr.Add("StackPanel")
    dpSp.Add("TextBlock").Text("EVENT DATES").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10").FontWeight("Bold")
    global myDatePicker := DateRangePickerEx("EventDates", "2026-05-16", "2026-06-16")
    myDatePicker.Build(dpSp)
    panel.Add("TextBlock").Text("BREADCRUMB BAR")
    panel.BreadcrumbBar(["Home", "Projects", "AHK", "XAML_Components.ahk"])

    panel.Add("TextBlock").Text("STEPPER (WIZARD)")
    panel.Stepper(["Configuration", "Authentication", "Deployment", "Verification"], 3)



    panel.Add("TextBlock").Text("STAT CARDS & TIMELINE")
    split := panel.SplitPanel("Horizontal", "1:1")

    leftSp := split.LeftPanel.Add("StackPanel").Margin("0,0,10,0")
    leftSp.StatCard("MONTHLY REVENUE", "$45,231", "12.5% from last month", true).Margin("0,0,0,10")
    leftSp.StatCard("SERVER LOAD", "89%", "2% above threshold", false)

    rightBdr := split.RightPanel.Add("Border").Use("CardPanel").Padding("20").Margin("10,0,0,0")
    rightSp := rightBdr.Add("StackPanel")
    rightSp.Add("TextBlock").Text("SYSTEM TIMELINE").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,0,0,15")
    events := []
    events.Push({ time: "10:45 AM", desc: "System initialized and booted successfully." })
    events.Push({ time: "11:02 AM", desc: "User 'Admin' authenticated via Token." })
    events.Push({ time: "11:15 AM", desc: "Deployment to Production failed. Retrying..." })
    rightSp.Timeline(events)

    panel.Add("TextBlock").Text("OVERLAY COMPONENTS").Margin("0,20,0,10")
    ovSp := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,20")

    ;btnBadge := ovSp.Add("Button").Name("BtnBadge").Content("Notifications").Margin("0,0,15,0").Width(120).Height(35).Use("PrimaryBtn").Cursor("Hand")
    ;btnBadge.AddBadge("3")

    btnCtx := ovSp.Add("Button").Content("Right-Click Me").Margin("0,0,15,0").Width(120).Height(35)
    btnCtx.AddContextMenu(["Edit", "Copy", "-", "Delete"])

    btnPop := ovSp.Add("ToggleButton").Content("Filter Options").Use("PrimaryBtn").Cursor("Hand").Margin("0,0,15,0").Width(120).Height(35)
    pop := btnPop.AddRichPopover()
    pop.Add("TextBlock").Text("Filter Settings").FontWeight("Bold").Margin("0,0,0,10")
    pop.Add("CheckBox").Content("Show Hidden Files").Margin("0,0,0,5")
    pop.Add("CheckBox").Content("Match Case")
    
    ; --- Rating Selectors ---
    panel.Add("TextBlock").Text("RATING SELECTORS").Margin("0,20,0,10")
    
    ratingCard := panel.Add("Border").Use("CardPanel").Padding("20").Margin("0,0,0,15")
    ratingSp := ratingCard.Add("StackPanel")
    
    ratingSp.Add("TextBlock").Text("5-Star Rating").Foreground("{DynamicResource TextMain}").FontWeight("SemiBold").FontSize(13).Margin("0,0,0,8")
    ratingSp.Rating("Rating5", { Max: 5, Default: 3 })
    
    ratingSp.Add("TextBlock").Text("10-Heart Rating").Foreground("{DynamicResource TextMain}").FontWeight("SemiBold").FontSize(13).Margin("0,15,0,8")
    ratingSp.Rating("Rating10", { Max: 10, Default: 7, Icon: Chr(0xEB52), IconEmpty: Chr(0xEB51), Color: "#FF453A", Size: 18 })
    
    ; --- Emoji Picker ---
    panel.Add("TextBlock").Text("EMOJI PICKER").Margin("0,10,0,10")
    emojiCard := panel.Add("Border").Use("CardPanel").Padding("20").Margin("0,0,0,20")
    emojiSp := emojiCard.Add("StackPanel")
    emojiSp.Add("TextBlock").Text("Select an emoji:").Foreground("{DynamicResource TextMain}").FontWeight("SemiBold").FontSize(13).Margin("0,0,0,8")
    emojiSp.EmojiPicker("MyEmoji")
}

app.AddTab("ADVANCED UI", BuildAdvancedUITab)

Persistent()