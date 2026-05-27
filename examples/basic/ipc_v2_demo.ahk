#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; ==============================================================================
; IPC V2 Demo — Showcasing the new API features:
;   1. .On()   — Inline event registration (no separate ui.OnEvent calls)
;   2. .Track() — Inline state tracking
;   3. ui.Query() — On-demand targeted value reads
;   4. Rich queries with > delimiter (Count, Items, SelectedIndex)
;   5. Length-prefixed encoding (automatic — emojis/pipes just work)
; ==============================================================================

; --- 1. Initialize the App ---
app := XAML_GUI("IPC V2 Demo")
app.lightweightEvents := true

; Sidebar
app.sidebarPanel.Add("TextBlock").Text("DEMO OPTIONS").Margin("0,15,0,15").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold")
app.sidebarPanel.Toggle("TglLiveMode", "Live Query Mode", false).Track().On("Click", OnToggleLive)

; --- 2. Build the UI ---
app.tabs.Visibility("Collapsed")

; Wrap in ScrollViewer for scrollable content
sv := app.main.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled")
panel := sv.Add("StackPanel").Margin("40,20,40,30")

; Title
panel.Add("TextBlock").Text("IPC V2 — New API Demo").Use("PageTitle").Margin("0,0,0,5")
panel.Add("TextBlock").Text("Inline .On() events, .Track(), and ui.Query() — type anything (emojis, pipes, etc.)").Use("BodyText").Foreground("{DynamicResource TextSub}").Margin("0,0,0,20")

; --- Input Section ---
panel.Add("TextBlock").Text("INPUT").Use("SubtitleText")
panel.Add("TextBox").Name("TxtInput").Width(400).HorizontalAlignment("Left").Margin("0,0,0,12")
    .Track()
    .On("TextChanged", OnInputChanged)

; Slider with Throttle for smooth tracking
panel.Add("TextBlock").Text("SLIDER").Use("SubtitleText")
sliderGrid := panel.Add("Grid").Margin("0,0,0,12")
sliderGrid.Add("Slider").Name("SldValue").Minimum(0).Maximum(100).Value(50).Margin("0,0,70,0").Tag("Throttle:16")
    .Track()
    .On("ValueChanged", OnSliderChanged)
sliderGrid.Add("TextBlock").Name("TxtSliderVal").Text("50").Foreground("{DynamicResource Accent}").FontSize(18).FontWeight("SemiBold").HorizontalAlignment("Right").VerticalAlignment("Center")

; --- More Components ---
panel.Add("TextBlock").Text("MORE CONTROLS").Use("SubtitleText")

moreGrid := panel.Add("Grid").Margin("0,0,0,15")
moreGrid.Cols("*", "15", "*")

; Left: CheckBox + ComboBox
leftSp := moreGrid.Add("StackPanel").Grid_Column(0)

leftSp.Add("TextBlock").Text("CheckBox").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,0,0,5")
leftSp.Add("CheckBox").Name("ChkAgree").Content("Enable notifications").Foreground("{DynamicResource TextMain}")
    .Track()
    .On("Click", OnCheckChanged)

leftSp.Add("TextBlock").Text("ComboBox").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,10,0,5")
combo := leftSp.Add("ComboBox").Name("CboRegion").Height(30)
    .Track()
    .On("SelectionChanged", OnComboChanged)
combo.Add("ComboBoxItem").Content("US-East-1")
combo.Add("ComboBoxItem").Content("EU-West-2")
combo.Add("ComboBoxItem").Content("AP-Southeast-1")
combo.SelectedIndex(0)

; Right: ListBox with Rich Queries
rightSp := moreGrid.Add("StackPanel").Grid_Column(2)

rightSp.Add("TextBlock").Text("ListBox (rich queries)").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,0,0,5")
lb := rightSp.Add("ListBox").Name("LstItems").Height(100)
    .Background("{DynamicResource ControlBg}")
    .BorderBrush("{DynamicResource ControlBorder}")
    .BorderThickness(1)
    .Track()
    .On("SelectionChanged", OnListSelected)

items := ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot"]
for item in items
    lb.Add("ListBoxItem").Content(item)

; --- Rich Query Buttons ---
panel.Add("TextBlock").Text("RICH QUERIES (> DELIMITER)").Use("SubtitleText")
qRow := panel.Add("WrapPanel").Margin("0,0,0,10")
qRow.Add("Button").Name("BtnQCount").Content("List>Count").Use("PrimaryBtn").Width(120).Height(32).Margin("0,0,8,5")
    .On("Click", OnQCount)
qRow.Add("Button").Name("BtnQItems").Content("List>Items").Use("PrimaryBtn").Width(120).Height(32).Margin("0,0,8,5")
    .On("Click", OnQItems)
qRow.Add("Button").Name("BtnQIdx").Content("List>SelIndex").Use("PrimaryBtn").Width(120).Height(32).Margin("0,0,8,5")
    .On("Click", OnQIndex)
qRow.Add("Button").Name("BtnQCombo").Content("Combo>Count").Use("PrimaryBtn").Width(120).Height(32).Margin("0,0,8,5")
    .On("Click", OnQComboCount)

; --- Action Buttons ---
panel.Add("TextBlock").Text("QUERY ACTIONS").Use("SubtitleText")
btnRow := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,15")
btnRow.Add("Button").Name("BtnSubmit").Content("Say Hello 🎉").Use("PrimaryBtn").Width(130).Height(32).Margin("0,0,10,0")
    .On("Click", OnSubmitClick)
btnRow.Add("Button").Name("BtnQueryAll").Content("Query All (*)").Use("PrimaryBtn").Width(140).Height(32).Margin("0,0,10,0")
    .On("Click", OnQueryAll)
btnRow.Add("Button").Name("BtnQueryOne").Content("Query Input Only").Use("PrimaryBtn").Width(140).Height(32)
    .On("Click", OnQuerySingle)

; --- Results Display ---
panel.Add("TextBlock").Text("RESULTS").Use("SubtitleText")
resBorder := panel.Add("Border").Use("CardPanel").Padding("15").Margin("0,0,0,15")
resBorder.Add("TextBlock").Name("TxtResults").Text("Waiting for interaction...").Foreground("{DynamicResource TextMain}").TextWrapping("Wrap").FontSize(13)

; --- Legacy vs New Comparison ---
panel.Add("TextBlock").Text("NEW vs LEGACY API").Use("SubtitleText")

compGrid := panel.Add("Grid")
compGrid.Cols("*", "10", "*")

; Left column: NEW API
newCard := compGrid.Add("Border").Use("CardPanel").Padding("12").Grid_Column(0)
newSp := newCard.Add("StackPanel")
newSp.Add("TextBlock").Text("✅ New API (.On / .Track)").Foreground("{DynamicResource Accent}").FontSize(12).FontWeight("Bold").Margin("0,0,0,8")
newSp.Add("TextBlock").Foreground("{DynamicResource TextSub}").FontSize(11).TextWrapping("Wrap")
    .Text('panel.Add("TextBox")'
        . '`n  .Name("TxtName")'
        . '`n  .Track()'
        . '`n  .On("TextChanged", OnChanged)'
        . '`n`npanel.Add("Button")'
        . '`n  .Name("BtnSubmit")'
        . '`n  .On("Click", OnClick)'
        . '`n`nui := app.Compile()'
        . '`n; Done! Events auto-collected.')

; Right column: LEGACY API
oldCard := compGrid.Add("Border").Use("CardPanel").Padding("12").Grid_Column(2)
oldSp := oldCard.Add("StackPanel")
oldSp.Add("TextBlock").Text("⬜ Legacy API (manual)").Foreground("{DynamicResource TextSub}").FontSize(12).FontWeight("Bold").Margin("0,0,0,8")
oldSp.Add("TextBlock").Foreground("{DynamicResource TextSub}").FontSize(11).TextWrapping("Wrap")
    .Text('panel.Add("TextBox")'
        . '`n  .Name("TxtName")'
        . '`n`npanel.Add("Button")'
        . '`n  .Name("BtnSubmit")'
        . '`n`nui := app.Compile()'
        . '`nui.Track("TxtName")'
        . '`nui.OnEvent("TxtName",'
        . '`n  "TextChanged", OnChanged)'
        . '`nui.OnEvent("BtnSubmit",'
        . '`n  "Click", OnClick)')

; --- 3. Compile ---
ui := app.Compile()

; 4. Show!
app.Show()

; ==============================================================================
; Event Callbacks
; ==============================================================================

OnInputChanged(state, ctrl, event) {
    val := state.Has("TxtInput") ? state["TxtInput"] : ""
    byteCount := StrPut(val, "UTF-8") - 1
    app.host.Update("TxtResults", "Text", "Input: " val "`nLength: " StrLen(val) " chars, " byteCount " UTF-8 bytes")
}

OnSliderChanged(state, ctrl, event) {
    val := state.Has("SldValue") ? state["SldValue"] : "0"
    intVal := Integer(Round(Number(val)))
    app.host.Update("TxtSliderVal", "Text", String(intVal))
    app.host.Update("TxtResults", "Text", "Slider moved to: " intVal)
}

OnCheckChanged(state, ctrl, event) {
    val := state.Has("ChkAgree") ? state["ChkAgree"] : "?"
    app.host.Update("TxtResults", "Text", "CheckBox: " val)
}

OnComboChanged(state, ctrl, event) {
    val := state.Has("CboRegion") ? state["CboRegion"] : "?"
    app.host.Update("TxtResults", "Text", "ComboBox selected: " val)
}

OnListSelected(state, ctrl, event) {
    val := state.Has("LstItems") ? state["LstItems"] : "?"
    app.host.Update("TxtResults", "Text", "ListBox selected: " val)
}

OnSubmitClick(state, ctrl, event) {
    name := ui.Query("TxtInput")
    if (name == "")
        name := "World"
    app.ShowSnackbar("Hello, " name "! 🎉")
}

OnQueryAll(state, ctrl, event) {
    allState := ui.Query("*")
    result := 'ui.Query("*") returned ' allState.Count " values:`n"
    for k, v in allState {
        result .= "  " k ' = "' v '"`n'
    }
    app.host.Update("TxtResults", "Text", result)
}

OnQuerySingle(state, ctrl, event) {
    val := ui.Query("TxtInput")
    byteCount := StrPut(val, "UTF-8") - 1
    app.host.Update("TxtResults", "Text", 'ui.Query("TxtInput") returned:`n"' val '"`n' StrLen(val) " chars, " byteCount " UTF-8 bytes")
}

; --- Rich Query Handlers ---
OnQCount(state, ctrl, event) {
    count := ui.Query("LstItems>Count")
    app.host.Update("TxtResults", "Text", 'ui.Query("LstItems>Count") = ' count)
}

OnQItems(state, ctrl, event) {
    items := ui.Query("LstItems>Items")
    app.host.Update("TxtResults", "Text", 'ui.Query("LstItems>Items"):`n' StrReplace(items, "|", "`n"))
}

OnQIndex(state, ctrl, event) {
    idx := ui.Query("LstItems>SelectedIndex")
    app.host.Update("TxtResults", "Text", 'ui.Query("LstItems>SelectedIndex") = ' idx)
}

OnQComboCount(state, ctrl, event) {
    count := ui.Query("CboRegion>Count")
    idx := ui.Query("CboRegion>SelectedIndex")
    app.host.Update("TxtResults", "Text", 'ComboBox>Count = ' count '`nComboBox>SelectedIndex = ' idx)
}

OnToggleLive(state, ctrl, event) {
    isLive := state.Has("TglLiveMode") && state["TglLiveMode"] == "True"
    app.host.Update("TxtResults", "Text", "Live Query Mode: " (isLive ? "ON — queries fire on every change" : "OFF — use buttons to query"))
}

Persistent()
