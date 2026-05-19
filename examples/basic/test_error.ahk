#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Config.ahk"
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"

; Create a basic UI using a StackPanel so child elements stack vertically instead of on top of each other
X := XAML_Generator("StackPanel").Background("#111111").VerticalAlignment("Center").HorizontalAlignment("Center")

; Add buttons with fake properties that will intentionally crash the WPF XAML parser
btn1 := X.Add("Button").Content("Crash Me 1!").Margin("10")
btn1.SetProp("TotallyFakeProperty", "ThisWillCrash")

btn2 := X.Add("Button").Content("Crash Me 2!").Margin("10")
btn2.SetProp("TotallyFakeProperty2", "ThisWillCrash")

btn3 := X.Add("Button").Content("Crash Me 3!").Margin("10")
btn3.SetProp("TotallyFakeProperty3", "ThisWillCrash")

; Compile the XAML
CompiledMarkup := X.Compile()

; Initialize and start the UI
tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", "50")
ui := XAMLHost(StrReplace(tmp, "%app%", CompiledMarkup))
ui.Show()
Persistent()
