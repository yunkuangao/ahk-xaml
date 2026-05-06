#Requires AutoHotkey v2.0
#Include "../v2-csc/xaml.ahk"
#Include "XAML_Generator.ahk"

; Create a basic UI
X := XAML_Generator("Grid").Background("#111111")

; Add a button with a fake property that will intentionally crash the WPF XAML parser
btn := X.Add("Button").Content("Crash Me!")
btn.SetProp("TotallyFakeProperty", "ThisWillCrash") 

; Compile the XAML
CompiledMarkup := X.Compile()

; Initialize and start the UI
ui := XAMLGUI(StrReplace(XAML_TEMPLATE, "%app%", CompiledMarkup))
ui.Show()
