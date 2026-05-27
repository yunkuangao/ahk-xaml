#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; 1. Initialize the App Engine
app := XAML_GUI("Minimal AHK GUI")

; 2. (Optional) Add items to the Sidebar
app.sidebarPanel.Add("TextBlock").Text("QUICK SETTINGS").Margin("0,15,0,15").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold")
app.sidebarPanel.Toggle("TglCenter", "Center Align", false)
    .Track()
    .On("Click", OnToggleCenter)

; 3. Define the Main Content Area
app.tabs.Visibility("Collapsed") ; Hide the default tab control
panel := app.main.Add("StackPanel").Grid_Row(1).Margin("40,20,40,20")

; Title & Description
panel.Add("TextBlock").Name("TxtTitle").Text("Welcome to the Minimal UI!").Use("PageTitle").Margin("0,0,0,10")
panel.Add("TextBlock").Name("TxtDesc").Text("Notice how much heavy lifting is done for you. No DllCalls, no manual rendering, just clean, object-oriented UI building.").Use("BodyText").Margin("0,0,0,25")

; Input Field
panel.Add("TextBlock").Name("TxtLabel").Text("ENTER YOUR NAME").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,0,0,8").HorizontalAlignment("Left")
panel.Add("TextBox").Name("TxtName").Width(300).HorizontalAlignment("Left").Margin("0,0,0,15").Track()

; Action Button
panel.Add("Button").Name("BtnSubmit").Content("Say Hello").Use("PrimaryBtn").Width(120).Height(32).HorizontalAlignment("Left")
    .On("Click", OnSubmitClick)

; 5. Compile the UI (Generates the WPF window)
ui := app.Compile()
ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Width="600" Height="420"')

; 6. Show the Window!
app.Show()

; --- Event Callbacks ---
OnToggleCenter(state, ctrl, event) {
    isCenter := state.Has("TglCenter") && state["TglCenter"] == "True"
    align := isCenter ? "Center" : "Left"

    app.host.Update("TxtTitle", "TextAlignment", align)
    app.host.Update("TxtDesc", "TextAlignment", align)
    app.host.Update("TxtLabel", "HorizontalAlignment", align)
    app.host.Update("TxtName", "HorizontalAlignment", align)
    app.host.Update("BtnSubmit", "HorizontalAlignment", align)
}
OnSubmitClick(state, ctrl, event) {
    name := state.Has("TxtName") && state["TxtName"] != "" ? state["TxtName"] : "Stranger"

    ; Trigger a beautiful built-in Snackbar notification effortlessly
    app.ShowSnackbar("Hello there, " name "!")
}

; Keep the script alive
Persistent()