#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; ==============================================================================
; Rich Query Playground
;
; An interactive sandbox to explore the > query delimiter.
; Type a query like "MyList>Count" and see the live result.
;
; Supports:
;   ControlName           — default value (Text, IsChecked, Value, etc.)
;   ControlName>Count     — item count for ListBox/ComboBox
;   ControlName>Items     — all items, pipe-delimited
;   ControlName>SelectedIndex — selected index (-1 if none)
;   ControlName>PropertyName  — any .NET property by name
;   *                     — all tracked controls
; ==============================================================================

app := XAML_GUI("Rich Query Playground")
app.lightweightEvents := true
app.tabs.Visibility("Collapsed")

sv := app.main.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled")
panel := sv.Add("StackPanel").M("40,20,40,30")

; === Header ===
panel.Add("TextBlock").Text("Rich Query Playground").Use("PageTitle").M("0,0,0,5")
panel.Add("TextBlock").Text("Type any query below and hit Enter or click Run. Try: MyList>Count, MySlider, ChkAgree>IsChecked, *").Use("BodyText").Fg("{DynamicResource TextSub}").M("0,0,0,20")

; =============================================
; QUERY INPUT BAR
; =============================================
panel.Add("TextBlock").Text("QUERY").Use("SubtitleText")

queryGrid := panel.Add("Grid").M("0,0,0,15")
queryGrid.Cols("*", "8", "Auto", "8", "Auto")

queryGrid.Add("TextBox").Name("TxtQuery").Grid_Column(0).FontFamily("Cascadia Code, Consolas").FontSize(13)
    .On("KeyDown", OnQueryKeyDown)

queryGrid.Add("Button", { Name: "BtnRun", W: 90, H: 32, Grid_Column: 2 })
    .Text("▶ Run")
    .Use("PrimaryBtn")
    .On("Click", OnRunQuery)

queryGrid.Add("Button", { Name: "BtnClear", W: 70, H: 32, Grid_Column: 4 })
    .Text("Clear")
    .Use("IconBtn")
    .On("Click", OnClear)

; === Result Box ===
panel.Add("TextBlock").Text("RESULT").Use("SubtitleText")
resBorder := panel.Add("Border").Use("CardPanel").Pad("15").M("0,0,0,15").MinHeight(60)
resBorder.Add("TextBlock").Name("TxtResult").Fg("{DynamicResource TextMain}").Size(13).Wrap().Mono()
    .Text("Enter a query above...")

; === Quick Query Buttons ===
panel.Add("TextBlock").Text("QUICK QUERIES").Use("SubtitleText")

qRow1 := panel.Add("WrapPanel").M("0,0,0,5")
qRow1.Add("Button", { Name: "Q1", W: 120, H: 28, M: "0,0,6,6" }).Text("MyList").Use("IconBtn").On("Click", OnQuickQuery)
qRow1.Add("Button", { Name: "Q2", W: 130, H: 28, M: "0,0,6,6" }).Text("MyList>Count").Use("IconBtn").On("Click", OnQuickQuery)
qRow1.Add("Button", { Name: "Q3", W: 130, H: 28, M: "0,0,6,6" }).Text("MyList>Items").Use("IconBtn").On("Click", OnQuickQuery)
qRow1.Add("Button", { Name: "Q4", W: 155, H: 28, M: "0,0,6,6" }).Text("MyList>SelectedIndex").Use("IconBtn").On("Click", OnQuickQuery)

qRow2 := panel.Add("WrapPanel").M("0,0,0,5")
qRow2.Add("Button", { Name: "Q5", W: 110, H: 28, M: "0,0,6,6" }).Text("MySlider").Use("IconBtn").On("Click", OnQuickQuery)
qRow2.Add("Button", { Name: "Q6", W: 120, H: 28, M: "0,0,6,6" }).Text("ChkAgree").Use("IconBtn").On("Click", OnQuickQuery)
qRow2.Add("Button", { Name: "Q7", W: 130, H: 28, M: "0,0,6,6" }).Text("CboRegion").Use("IconBtn").On("Click", OnQuickQuery)
qRow2.Add("Button", { Name: "Q8", W: 160, H: 28, M: "0,0,6,6" }).Text("CboRegion>Count").Use("IconBtn").On("Click", OnQuickQuery)

qRow3 := panel.Add("WrapPanel").M("0,0,0,5")
qRow3.Add("Button", { Name: "Q9", W: 120, H: 28, M: "0,0,6,6" }).Text("TxtInput").Use("IconBtn").On("Click", OnQuickQuery)
qRow3.Add("Button", { Name: "Q10", W: 110, H: 28, M: "0,0,6,6" }).Text("PrgBar").Use("IconBtn").On("Click", OnQuickQuery)
qRow3.Add("Button", { Name: "Q11", W: 160, H: 28, M: "0,0,6,6" }).Text("MyTabs>SelectedIndex").Use("IconBtn").On("Click", OnQuickQuery)
qRow3.Add("Button", { Name: "Q12", W: 170, H: 28, M: "0,0,6,6" }).Text("MyTabs>SelectedHeader").Use("IconBtn").On("Click", OnQuickQuery)

qRow4 := panel.Add("WrapPanel").M("0,0,0,15")
qRow4.Add("Button", { Name: "Q13", W: 160, H: 28, M: "0,0,6,6" }).Text("Multi: 3 controls").Use("IconBtn").On("Click", OnMultiQuery)
qRow4.Add("Button", { Name: "Q14", W: 100, H: 28, M: "0,0,6,6" }).Text("Query (*)").Use("PrimaryBtn").On("Click", OnQueryAll)

; =============================================
; COMPONENT SANDBOX
; =============================================
panel.Add("TextBlock").Text("COMPONENT SANDBOX").Use("SubtitleText")
panel.Add("TextBlock").Text("Interact with these controls, then query their values above.").Fg("{DynamicResource TextSub}").Size(11).M("0,0,0,10")

sandboxGrid := panel.Add("Grid").M("0,0,0,15")
sandboxGrid.Cols("*", "15", "*")

; === Left Column ===
leftSp := sandboxGrid.Add("StackPanel").Grid_Column(0)

; TextBox
leftSp.Add("TextBlock").Text("TextBox — TxtInput").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,0,0,5")
leftSp.Add("TextBox").Name("TxtInput").Track()

; Slider
leftSp.Add("TextBlock").Text("Slider — MySlider").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,12,0,5")
sldGrid := leftSp.Add("Grid")
sldGrid.Add("Slider").Name("MySlider").Minimum(0).Maximum(100).Value(42).M("0,0,60,0").Tag("Throttle:16").Track()
    .On("ValueChanged", OnSliderMoved)
sldGrid.Add("TextBlock").Name("TxtSldVal").Text("42").Fg("{DynamicResource Accent}").Size(16).Bold().HorizontalAlignment("Right").VerticalAlignment("Center")

; CheckBox
leftSp.Add("TextBlock").Text("CheckBox — ChkAgree").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,12,0,5")
leftSp.Add("CheckBox").Name("ChkAgree").Content("I agree to terms").Track()

; ProgressBar (read-only display)
leftSp.Add("TextBlock").Text("ProgressBar — PrgBar (value: 73)").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,12,0,5")
leftSp.Add("ProgressBar").Name("PrgBar").Value(73).H(8).Fg("{DynamicResource Accent}").Bg("{DynamicResource ControlBorder}").BorderThickness(0)

; === Right Column ===
rightSp := sandboxGrid.Add("StackPanel").Grid_Column(2)

; ListBox
rightSp.Add("TextBlock").Text("ListBox — MyList").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,0,0,5")
lb := rightSp.Add("ListBox").Name("MyList").H(100)
    .Bg("{DynamicResource ControlBg}")
    .BorderBrush("{DynamicResource ControlBorder}")
    .BorderThickness(1)
    .Track()

items := ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot"]
for item in items
    lb.Add("ListBoxItem").Content(item)

; ComboBox
rightSp.Add("TextBlock").Text("ComboBox — CboRegion").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,12,0,5")
combo := rightSp.Add("ComboBox").Name("CboRegion").H(30).Track()
combo.Add("ComboBoxItem").Content("US-East-1")
combo.Add("ComboBoxItem").Content("EU-West-2")
combo.Add("ComboBoxItem").Content("AP-Southeast-1")
combo.SelectedIndex(0)

; TabControl
rightSp.Add("TextBlock").Text("TabControl — MyTabs").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,12,0,5")
tabs := rightSp.Add("TabControl").Name("MyTabs").H(80).Track()
tab1 := tabs.Add("TabItem").Header("Settings")
tab1.Add("TextBlock").Text("Tab 1 content").Fg("{DynamicResource TextSub}").M("10")
tab2 := tabs.Add("TabItem").Header("Advanced")
tab2.Add("TextBlock").Text("Tab 2 content").Fg("{DynamicResource TextSub}").M("10")
tab3 := tabs.Add("TabItem").Header("About")
tab3.Add("TextBlock").Text("Tab 3 content").Fg("{DynamicResource TextSub}").M("10")

; =============================================
; REFERENCE CARD
; =============================================
panel.Add("TextBlock").Text("QUERY SYNTAX REFERENCE").Use("SubtitleText")
refCard := panel.Add("Border").Use("CardPanel").Pad("12")
refSp := refCard.Add("StackPanel")
refSp.Add("TextBlock").Mono().Fg("{DynamicResource TextSub}").Size(11).Wrap()
    .Text('ui.Query("ControlName")            → default value'
        . '`nui.Query("Name>Count")             → item count'
        . '`nui.Query("Name>Items")             → pipe-delimited items'
        . '`nui.Query("Name>SelectedIndex")     → selected index'
        . '`nui.Query("Name>SelectedHeader")    → tab header text'
        . '`nui.Query("Name>SelectedRow")       → DataGrid row cells'
        . '`nui.Query("Name>FilteredCount")     → DataGrid visible rows'
        . '`nui.Query("Name>PropertyName")      → any .NET property'
        . '`nui.Query("A", "B", "C")            → batch → Map'
        . '`nui.Query("*")                      → all tracked → Map')

; === Compile & Show ===
ui := app.Compile()

app.Show()

; ==============================================================================
; Callbacks
; ==============================================================================

; Execute query from the text input
RunQueryFromInput() {
    queryText := ui.Query("TxtQuery")
    if (queryText == "") {
        app.host.Update("TxtResult", "Text", "Enter a query above...")
        return
    }

    ; Check for wildcard
    if (queryText == "*") {
        OnQueryAll("", "", "")
        return
    }

    ; Run the query
    result := ui.Query(queryText)
    if (result == "")
        result := "(empty string or control not found)"

    display := 'ui.Query("' queryText '")' "`n`n→  " result
    app.host.Update("TxtResult", "Text", display)
}

OnRunQuery(state, ctrl, event) {
    RunQueryFromInput()
}

OnQueryKeyDown(state, ctrl, event) {
    ; Fire on Enter key
    if (InStr(event, "Return"))
        RunQueryFromInput()
}

OnClear(state, ctrl, event) {
    app.host.Update("TxtQuery", "Text", "")
    app.host.Update("TxtResult", "Text", "Enter a query above...")
}

; Quick query buttons — the button's Content IS the query string
OnQuickQuery(state, ctrl, event) {
    ; The button name tells us which query: Q1="MyList", Q2="MyList>Count", etc.
    queryMap := Map(
        "Q1", "MyList",
        "Q2", "MyList>Count",
        "Q3", "MyList>Items",
        "Q4", "MyList>SelectedIndex",
        "Q5", "MySlider",
        "Q6", "ChkAgree",
        "Q7", "CboRegion",
        "Q8", "CboRegion>Count",
        "Q9", "TxtInput",
        "Q10", "PrgBar",
        "Q11", "MyTabs>SelectedIndex",
        "Q12", "MyTabs>SelectedHeader"
    )

    if (!queryMap.Has(ctrl))
        return

    q := queryMap[ctrl]
    result := ui.Query(q)
    if (result == "")
        result := "(empty)"

    ; Also set the query bar
    app.host.Update("TxtQuery", "Text", q)
    display := 'ui.Query("' q '")' "`n`n→  " result
    app.host.Update("TxtResult", "Text", display)
}

OnMultiQuery(state, ctrl, event) {
    result := ui.Query("MySlider", "ChkAgree", "CboRegion")
    lines := 'ui.Query("MySlider", "ChkAgree", "CboRegion")  → Map:`n`n'
    for k, v in result
        lines .= "  " k ' = "' v '"`n'
    app.host.Update("TxtQuery", "Text", 'MySlider, ChkAgree, CboRegion')
    app.host.Update("TxtResult", "Text", lines)
}

OnQueryAll(state, ctrl, event) {
    all := ui.Query("*")
    lines := 'ui.Query("*") → ' all.Count " tracked values:`n`n"
    for k, v in all
        lines .= "  " k ' = "' v '"`n'
    app.host.Update("TxtQuery", "Text", "*")
    app.host.Update("TxtResult", "Text", lines)
}

OnSliderMoved(state, ctrl, event) {
    val := state.Has("MySlider") ? state["MySlider"] : "0"
    intVal := Integer(Round(Number(val)))
    app.host.Update("TxtSldVal", "Text", String(intVal))
}

Persistent()
