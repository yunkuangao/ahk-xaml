#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; 1. Initialize the App Engine
app := XAML_GUI("Minimal AHK GUI")

; 2. Define the Main Content Area
panel := app.main.Add("StackPanel").Grid_Row(1).Margin("40,20,40,20")

panel.Add("TextBlock").Name("TxtTitle").Text("Welcome to the Minimal UI!").Use("PageTitle").Margin("0,0,0,10")

panel.Add("Button").Name("BtnSubmit").Content("Say Hello").Use("PrimaryBtn").Width(120).Height(32).HorizontalAlignment("Left")
    .On("Click", OnSubmitClick)

; 3. Compile the UI (Generates the WPF window)
ui := app.Compile()

; 4. Show the Window!
app.Show()

; Event Callbacks
OnSubmitClick(state, ctrl, event) {
    app.ShowSnackbar("Hello there!")
    XDialog.Show({ Title: "Hello!", Message: "Message content here" })
}

; Keep the script alive
Persistent()