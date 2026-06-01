#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; ==============================================================================
; Styling Shorthands Demo
;
; Showcases:
;   1. Object-style construction: Add("Button", {W: 120, H: 32})
;   2. Shorthand aliases: W, H, Fg, Bg, Size, Bold, Center, etc.
;   3. Tag-aware Text → Content resolution
;   4. Rich queries: >Count, >Items, >SelectedIndex
;   5. Lightweight events + .On() inline events
;   6. Multiple component types with live value readback
; ==============================================================================

app := XAML_GUI("Shorthands Demo")
app.lightweightEvents := true

app.tabs.Visibility("Collapsed")

; Wrap entire main content in a ScrollViewer for scrolling
sv := app.main.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled")
panel := sv.Add("StackPanel").M("40,20,40,30")

; === TITLE (using shorthands) ===
panel.Add("TextBlock").Text("Styling Shorthands").Use("PageTitle").M("0,0,0,5")
panel.Add("TextBlock", { Fg: "{DynamicResource TextSub}", Size: 12, Wrap: true })
    .Text("Object-style construction, aliases, rich queries, and tag-aware property resolution.")
    .M("0,0,0,20")

; === SECTION 1: Chaining vs Object-Style ===
panel.Add("TextBlock").Text("CONSTRUCTION STYLES").Use("SubtitleText")

compGrid := panel.Add("Grid").M("0,0,0,20")
compGrid.Cols("*", "10", "*")

; Left: Chaining style
chainCard := compGrid.Add("Border").Use("CardPanel").Pad("12").Grid_Column(0)
chainSp := chainCard.Add("StackPanel")
chainSp.Add("TextBlock").Text("Chaining Style").Fg("{DynamicResource Accent}").Bold().Size(12).M("0,0,0,8")
chainSp.Add("TextBlock").Fg("{DynamicResource TextSub}").Size(11).Wrap().Mono()
    .Text('panel.Add("Button")'
        . '`n  .Name("Btn")'
        . '`n  .Text("Hello")'
        . '`n  .W(120).H(32)'
        . '`n  .Bold().Center()'
        . '`n  .On("Click", fn)')

; Right: Object style
objCard := compGrid.Add("Border").Use("CardPanel").Pad("12").Grid_Column(2)
objSp := objCard.Add("StackPanel")
objSp.Add("TextBlock").Text("Object Style").Fg("{DynamicResource Accent}").Bold().Size(12).M("0,0,0,8")
objSp.Add("TextBlock").Fg("{DynamicResource TextSub}").Size(11).Wrap().Mono()
    .Text('panel.Add("Button", {'
        . '`n  Name: "Btn",'
        . '`n  Text: "Hello",'
        . '`n  W: 120, H: 32,'
        . '`n  Bold: true, Center: true'
        . '`n}).On("Click", fn)')

; === SECTION 2: Live Demo with Shorthands ===
panel.Add("TextBlock").Text("LIVE DEMO").Use("SubtitleText")

; Input row using object-style
inputGrid := panel.Add("Grid").M("0,0,0,10")
inputGrid.Cols("*", "10", "Auto")

inputGrid.Add("TextBox", { Name: "TxtDemo", Grid_Column: 0 }).Track().On("TextChanged", OnDemoTyped)

; Button using Text() which auto-resolves to Content on Button
inputGrid.Add("Button", { Name: "BtnDemo", W: 100, H: 32, Grid_Column: 2 })
    .Text("Submit ✨")
    .Use("PrimaryBtn")
    .On("Click", OnDemoSubmit)

; === SECTION 3: Multiple Components with Value Readback ===
panel.Add("TextBlock").Text("COMPONENT VALUE EXTRACTION").Use("SubtitleText")

compTestGrid := panel.Add("Grid").M("0,0,0,15")
compTestGrid.Cols("*", "15", "*")

; === Left Column: Controls ===
leftSp := compTestGrid.Add("StackPanel").Grid_Column(0)

; -- Slider --
leftSp.Add("TextBlock").Text("Slider").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,0,0,5")
leftSp.Add("Slider").Name("SldTest").Minimum(0).Maximum(100).Value(42).Tag("Throttle:16")
    .Track()
    .On("ValueChanged", OnComponentChanged)

; -- CheckBox --
leftSp.Add("TextBlock").Text("CheckBox").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,10,0,5")
leftSp.Add("CheckBox").Name("ChkTest").Content("I agree to the terms").Fg("{DynamicResource TextMain}")
    .Track()
    .On("Click", OnComponentChanged)

; -- ComboBox --
leftSp.Add("TextBlock").Text("ComboBox").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,10,0,5")
comboTest := leftSp.Add("ComboBox").Name("CboTest").H(30)
    .Track()
    .On("SelectionChanged", OnComponentChanged)
comboTest.Add("ComboBoxItem").Content("Option A")
comboTest.Add("ComboBoxItem").Content("Option B")
comboTest.Add("ComboBoxItem").Content("Option C")
comboTest.SelectedIndex(0)

; -- ProgressBar --
leftSp.Add("TextBlock").Text("ProgressBar (read-only)").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,10,0,5")
leftSp.Add("ProgressBar").Name("PrgTest").Value(68).H(8).Fg("{DynamicResource Accent}").Bg("{DynamicResource ControlBorder}").BorderThickness(0)

; === Right Column: ListBox + Query Buttons ===
rightSp := compTestGrid.Add("StackPanel").Grid_Column(2)

rightSp.Add("TextBlock").Text("ListBox").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,0,0,5")
lb := rightSp.Add("ListBox", { Name: "LstFruits", H: 120 })
    .Bg("{DynamicResource ControlBg}")
    .BorderBrush("{DynamicResource ControlBorder}")
    .BorderThickness(1)
    .Track()
    .On("SelectionChanged", OnComponentChanged)

fruits := ["🍎 Apple", "🍌 Banana", "🍊 Orange", "🍇 Grape", "🍓 Strawberry", "🥝 Kiwi"]
for f in fruits
    lb.Add("ListBoxItem").Content(f)

; Query buttons
rightSp.Add("TextBlock").Text("Rich Queries").Fg("{DynamicResource TextSub}").Size(11).Bold().M("0,10,0,5")
qBtnRow := rightSp.Add("WrapPanel").M("0,0,0,8")
qBtnRow.Add("Button", { Name: "BtnQCount", W: 70, H: 26, M: "0,0,5,5" }).Text("Count").Use("IconBtn").On("Click", OnQueryCount)
qBtnRow.Add("Button", { Name: "BtnQItems", W: 70, H: 26, M: "0,0,5,5" }).Text("Items").Use("IconBtn").On("Click", OnQueryItems)
qBtnRow.Add("Button", { Name: "BtnQIdx", W: 80, H: 26, M: "0,0,5,5" }).Text("Sel.Index").Use("IconBtn").On("Click", OnQueryIndex)
qBtnRow.Add("Button", { Name: "BtnQAll", W: 80, H: 26, M: "0,0,5,5" }).Text("Query All").Use("IconBtn").On("Click", OnQueryAllComps)

; === RESULTS PANEL ===
panel.Add("TextBlock").Text("RESULTS").Use("SubtitleText")
resCard := panel.Add("Border").Use("CardPanel").Pad("12").M("0,0,0,15")
resCard.Add("TextBlock", { Name: "TxtResults", Size: 12, Wrap: true, Fg: "{DynamicResource TextMain}" })
    .Text("Interact with any component above...")

; === SHORTHAND REFERENCE ===
panel.Add("TextBlock").Text("SHORTHAND REFERENCE").Use("SubtitleText")

refCard := panel.Add("Border").Use("CardPanel").Pad("12")
refSp := refCard.Add("StackPanel")

refSp.Add("TextBlock").Mono().Fg("{DynamicResource TextSub}").Size(11).Wrap()
    .Text(".W(n) → Width       .H(n) → Height"
        . "`n.Fg(v) → Foreground   .Bg(v) → Background"
        . "`n.M(v) → Margin        .Pad(v) → Padding"
        . "`n.Size(n) → FontSize   .Bold() → FontWeight"
        . "`n.Center() / .Left() / .Right() → HAlign"
        . "`n.Wrap() → TextWrapping  .Mono() → Monospace"
        . "`n.Text() → Content (on Button/Label)"
        . "`n.Colour(v) / .Color(v) → Foreground"
        . "`n.Radius(v) → CornerRadius  .Clip() → ClipToBounds")

; === Compile & Show ===
ui := app.Compile()
app.Show()

; ==============================================================================
; Event Callbacks
; ==============================================================================

OnDemoTyped(state, ctrl, event) {
    val := state.Has("TxtDemo") ? state["TxtDemo"] : ""
    if (val != "")
        app.host.Update("TxtResults", "Text", "Typed: " val " (" StrLen(val) " chars)")
}

OnDemoSubmit(state, ctrl, event) {
    val := ui.Query("TxtDemo")
    app.ShowSnackbar("Submitted: " (val != "" ? val : "(empty)"))
}

OnComponentChanged(state, ctrl, event) {
    ; Batch query all components in one IPC call
    result := ui.Query("SldTest", "ChkTest", "CboTest", "LstFruits")
    lines := ""
    lines .= "Slider: " (result.Has("SldTest") ? result["SldTest"] : "?") "`n"
    lines .= "CheckBox: " (result.Has("ChkTest") ? result["ChkTest"] : "?") "`n"
    lines .= "ComboBox: " (result.Has("CboTest") ? result["CboTest"] : "?") "`n"
    lines .= "ListBox: " (result.Has("LstFruits") ? result["LstFruits"] : "?") "`n"
    app.host.Update("TxtResults", "Text", lines)
}

OnQueryCount(state, ctrl, event) {
    count := ui.Query("LstFruits>Count")
    cboCount := ui.Query("CboTest>Count")
    app.host.Update("TxtResults", "Text", 'ListBox>Count = ' count '`nComboBox>Count = ' cboCount)
}

OnQueryItems(state, ctrl, event) {
    items := ui.Query("LstFruits>Items")
    app.host.Update("TxtResults", "Text", 'ListBox>Items:`n' StrReplace(items, "|", "`n"))
}

OnQueryIndex(state, ctrl, event) {
    lbIdx := ui.Query("LstFruits>SelectedIndex")
    cboIdx := ui.Query("CboTest>SelectedIndex")
    app.host.Update("TxtResults", "Text", 'ListBox>SelectedIndex = ' lbIdx '`nComboBox>SelectedIndex = ' cboIdx)
}

OnQueryAllComps(state, ctrl, event) {
    all := ui.Query("*")
    lines := 'ui.Query("*") → ' all.Count " tracked values:`n"
    for k, v in all
        lines .= "  " k ' = "' v '"`n'
    app.host.Update("TxtResults", "Text", lines)
}

Persistent()
