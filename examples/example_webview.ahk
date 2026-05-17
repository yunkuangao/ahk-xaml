#Requires AutoHotkey v2.0
#Include "..\lib\XAML_Host.ahk"
#Include "..\lib\XAML_Dialog.ahk"
#Include "..\lib\XAML_Components.ahk"
#Include "..\lib\XAML_Adv_Components.ahk"
#Include "..\lib\XAML_GUI.ahk"

global XAML_ENABLE_WEBVIEW := true

; Ensure WebView is enabled before running the example
if (!XAML_ENABLE_WEBVIEW) {
    MsgBox("WebView is disabled. Please set XAML_ENABLE_WEBVIEW := true in XAML_Config.ahk to use this example.", "WebView Disabled", "Iconi")
    ExitApp()
}

; Setup a simple UI
options := Map("Sidebar", false, "BurgerMenu", false)
app := XAML_GUI("WebView Showcase", options)
app.tabs.Visibility("Collapsed")

root := app.main.Add("Grid").Grid_Row(1)
root.Rows("Auto", "*")

; Header
header := root.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("20")
header.Add("TextBlock").Text(Chr(0xE774)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("24").Foreground("{DynamicResource Accent}").Margin("0,0,15,0").VerticalAlignment("Center")
header.Add("TextBlock").Text("WebView2 Native Integration").FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,20,0").VerticalAlignment("Center")
header.Add("TextBlock").Text("A lightweight, completely native web browser component for AHK-XAML.").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")

; Browser Component
bdr := root.Add("Border").Grid_Row(1).Margin("20,0,20,20").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("8")

myBrowser := bdr.WebView("MyBrowser")

; Setup JS to AHK Bridge
myBrowser.OnMessage((msg) => MsgBox("Received message from JavaScript:`n`n" msg, "IPC Bridge", "Iconi"))

; Compile and Launch
ui := app.Compile()
myBrowser.Bind(ui)

app.Show()