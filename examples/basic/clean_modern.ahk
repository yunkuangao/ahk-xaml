#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; --- Super Basic Example ---
; Here we pass options to the XAML_GUI constructor to disable the sidebar,
; the hamburger menu button, and the app icon, resulting in a clean, minimal interface.
options := Map("Sidebar", false, "BurgerMenu", false, "AppIcon", false)

app := XAML_GUI("Minimalist Data Entry", options)
app.tabs.Visibility("Collapsed")

; Add a simple Card Panel to the center
card := app.main.Add("Border").Use("CardPanel").Grid_Row(1).Padding("30").Margin("30").VerticalAlignment("Center").HorizontalAlignment("Center")

sp := card.Add("StackPanel").Width(300)

sp.Add("TextBlock").Text("Welcome Back").FontSize(24).FontWeight("Bold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,5").HorizontalAlignment("Center")
sp.Add("TextBlock").Text("Please log in to continue.").Foreground("{DynamicResource TextSub}").Margin("0,0,0,20").HorizontalAlignment("Center")

sp.Add("TextBlock").Text("USERNAME").Use("SubtitleText")
sp.Add("TextBox").Name("InputUser").Height(32).Margin("0,0,0,15")

sp.Add("TextBlock").Text("PASSWORD").Use("SubtitleText")
sp.Add("PasswordBox").Name("InputPass").Height(32).Margin("0,0,0,25")

btn := sp.Add("Button").Name("BtnLogin").Content("Login").Use("PrimaryBtn").Height(36)

ui := app.Compile()

; Register the click event
ui.OnEvent("BtnLogin", "Click", (state, ctrl, event) => OnLoginClick(state))

; Track inputs so their values are sent when the button is clicked
ui.Track("InputUser")
ui.Track("InputPass")

app.Show()

OnLoginClick(state) {
    user := state["InputUser"]
    pass := state["InputPass"]

    if (user == "" || pass == "") {
        app.ShowSnackbar("Please fill in all fields.")
        return
    }

    MsgBox("Logged in as " user)
}