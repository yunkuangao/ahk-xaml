#Requires AutoHotkey v2.0
#Include "../lib/XAML_Host.ahk"
#Include "../lib/XAML_Generator.ahk"

; Create a basic UI
X := XAML_Generator("Grid").Background("#111111")

; Add a button with a fake property that will intentionally crash the WPF XAML parser
btn := X.Add("Button").Content("Crash Me!")
btn.SetProp("TotallyFakeProperty", "ThisWillCrash")

; Compile the XAML
CompiledMarkup := X.Compile()

; Initialize and start the UI
ui := XAMLHost(StrReplace(XAML_TEMPLATE, "%app%", CompiledMarkup))
ui.Show()