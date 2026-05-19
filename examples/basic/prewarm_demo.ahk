#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Dialog.ahk"

guiObj := Gui(, "AHK-XAML Prewarm Demo")
guiObj.BackColor := "White"
guiObj.MarginX := 20
guiObj.MarginY := 20
guiObj.SetFont("s11 c333333", "Segoe UI")

guiObj.Add("Text", "w350", "The first time a XAML UI is loaded, the OS must load the .NET Framework and WPF engine into memory, causing a slight delay.`n`nTo test this, run this script and immediately click 'Show Dialog'. Notice the delay.`n`nThen, restart this script and click 'Prewarm Engine' first. Notice how the dialog loads instantly!")

btnPrewarm := guiObj.Add("Button", "w350 h40 y+20", "1. Prewarm Engine in Background")
btnPrewarm.OnEvent("Click", (*) => DoPrewarm())

btnDialog := guiObj.Add("Button", "w350 h40 y+10", "2. Show Dialog")
btnDialog.OnEvent("Click", (*) => DoDialog())

txtTiming := guiObj.Add("Text", "w350 y+15 cGray", "")

DoPrewarm() {
    btnPrewarm.Enabled := false
    btnPrewarm.Text := "Prewarming..."
    start := A_TickCount

    ; Preload boots up the background engine immediately
    XDialog.Preload()

    btnPrewarm.Text := "Engine Prewarmed (" (A_TickCount - start) " ms)"
}

DoDialog() {
    start := A_TickCount

    result := XDialog.Show({
        Title: "Speed Test",
        Message: "This dialog loaded in " (A_TickCount - start) " ms!",
        Icon: Chr(0xE916), ; Stopwatch icon
        IconColor: "#228B22",
        Buttons: ["Awesome"]
    })

    elapsed := A_TickCount - start
    txtTiming.Text := "Last dialog: ~" elapsed " ms total (including wait for close)"
}

guiObj.Show()