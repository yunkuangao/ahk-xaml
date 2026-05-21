#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_Host.ahk"
#Include "..\..\lib\XAML_Generator.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"
#Include "..\..\lib\AXML.ahk"
#Include "..\..\lib\XAML_Config.ahk"

; Enable Diagnostics to test the Engine Crash UI!
global XAML_DIAGNOSTICS_ENABLED := true
global XAML_ENABLE_TRACING := true

; 1. Setup the App Layout
app := XAML_Generator("Grid")
axmlObj := AXML.ParseFile("axml_error_test.axml", app)

; 2. Initialize XAML Host and Render
guiObj := XAMLHost(XAML_TEMPLATE)
guiObj.xaml := StrReplace(guiObj.xaml, "%app%", app.Compile())

; Bind events
AXML.BindAll(guiObj, axmlObj)

guiObj.Show()
