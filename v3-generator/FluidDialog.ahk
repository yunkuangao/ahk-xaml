#Requires AutoHotkey v2.0
#Include "..\v2-csc\xaml.ahk"

class FluidDialog {
    static Show(options) {
        ; --- CONFIGURATION ---
        title := options.HasProp("Title") ? options.Title : "Dialog"
        msg := options.HasProp("Message") ? options.Message : ""
        iconChar := options.HasProp("Icon") ? options.Icon : ""
        iconColor := options.HasProp("IconColor") ? options.IconColor : "{DynamicResource TextMain}"
        detail := options.HasProp("DetailText") ? options.DetailText : ""
        detailRows := options.HasProp("DetailRows") ? options.DetailRows : 4
        inputText := options.HasProp("InputText") ? options.InputText : ""
        hasProgress := options.HasProp("Progress") ? options.Progress : false
        buttons := options.HasProp("Buttons") ? options.Buttons : ["OK"]
        width := options.HasProp("Width") ? options.Width : 450
        height := options.HasProp("Height") ? options.Height : "Auto"
        resizable := options.HasProp("Resizable") ? options.Resizable : false
        modal := options.HasProp("Modal") ? options.Modal : false
        owner := options.HasProp("Owner") ? options.Owner : 0
        alwaysOnTop := options.HasProp("AlwaysOnTop") ? options.AlwaysOnTop : false
        waitForResponse := options.HasProp("WaitForResponse") ? options.WaitForResponse : true
        themeName := options.HasProp("Theme") ? options.Theme : "Dark Mica (Win 11)"
        iniPath := options.HasProp("IniPath") ? options.IniPath : "themes.ini"
        soundFx := options.HasProp("Sound") ? options.Sound : ""
        disableAltF4 := options.HasProp("DisableAltF4") ? options.DisableAltF4 : false

        ; --- BUILD LAYOUT ---
        main := XAML_Generator("Grid").Background("Transparent")
        main.Rows("40", "*", "Auto")

        ; Titlebar (draggable)
        tb := main.Add("Grid").Grid_Row(0).Background("Transparent").Name("DragArea")
        tb.Add("TextBlock").Text(title).Foreground("{DynamicResource TextMain}").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")

        CloseBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#E0FF3333"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        closeBtn := tb.Add("Button").Name("BtnClose").WindowChrome_IsHitTestVisibleInChrome("True").Width(45).HorizontalAlignment("Right").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0)
        closeBtn.InjectResources(CloseBtnTemplate)
        closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

        ; Content Body
        body := main.Add("StackPanel").Grid_Row(1).Margin("20,10,20,20")

        ; Message & Icon row
        msgRow := body.Add("Grid").Margin("0,0,0,15")
        if (iconChar != "") {
            msgRow.Cols("40", "*")
            msgRow.Add("TextBlock").Text(iconChar).Foreground(iconColor).FontSize(18).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").VerticalAlignment("Top").Margin("0,2,0,0").Grid_Column(0)
            msgRow.Add("TextBlock").Text(msg).Foreground("{DynamicResource TextMain}").TextWrapping("Wrap").VerticalAlignment("Top").Grid_Column(1)
        } else {
            msgRow.Add("TextBlock").Text(msg).Foreground("{DynamicResource TextMain}").TextWrapping("Wrap").VerticalAlignment("Top")
        }

        ; Detail Textbox
        if (detail != "") {
            body.Add("TextBox").Text(detail).IsReadOnly("True").Foreground("{DynamicResource TextSub}").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Padding("10").Margin("0,0,0,15").Height(detailRows * 20).TextWrapping("Wrap").VerticalScrollBarVisibility("Auto")
        }

        ; Input field
        if (inputText != "") {
            body.Add("TextBox").Name("DialogInput").Text("").Foreground("{DynamicResource TextMain}").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource Accent}").BorderThickness(1).Padding("10").Margin("0,0,0,15").Tag(inputText)
        }

        ; Progress bars
        if (hasProgress) {
            body.Add("TextBlock").Name("DialogProgText1").Text("Processing...").Foreground("{DynamicResource TextMain}").Margin("0,0,0,5")
            body.Add("TextBlock").Name("DialogProgSub1").Text("Please wait...").Foreground("{DynamicResource TextSub}").FontSize(11).Margin("0,0,0,5")
            body.Add("ProgressBar").Name("DialogProg1").Value(0).Maximum(100).Height(6).Margin("0,0,0,20").Foreground("{DynamicResource Accent}").Background("{DynamicResource ControlBorder}").BorderThickness(0)

            body.Add("TextBlock").Name("DialogProgText2").Text("Overall Task").Foreground("{DynamicResource TextMain}").Margin("0,0,0,5")
            body.Add("TextBlock").Name("DialogProgSub2").Text("Step 1").Foreground("{DynamicResource TextSub}").FontSize(11).Margin("0,0,0,5")
            body.Add("ProgressBar").Name("DialogProg2").Value(0).Maximum(100).Height(6).Margin("0,0,0,15").Foreground("{DynamicResource TextSub}").Background("{DynamicResource ControlBorder}").BorderThickness(0)
        }

        ; Buttons Footer
        footer := main.Add("Border").Grid_Row(2).Background("{DynamicResource ControlBg}").Padding("15").CornerRadius("0,0,8,8")
        btnSp := footer.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center")

        for index, btnText in buttons {
            btnEl := btnSp.Add("Button").Name("Btn" index).Content(btnText).Width(120).Padding("8,6").Margin("5,0").Background("{DynamicResource ControlBg}").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Cursor("Hand")
            if (btnText == "OK" || btnText == "Confirm")
                btnEl.IsDefault("True")
        }

        ; --- INIT LOGIC ---
        ui := XAMLGUI(StrReplace(XAML_TEMPLATE, "%app%", main.ToString()))

        ; Replace some default xaml.ahk window stuff to match the dialog needs
        heightAttr := (height == "Auto") ? 'SizeToContent="Height"' : 'Height="' height '"'
        resizeAttr := resizable ? 'ResizeMode="CanResize"' : 'ResizeMode="NoResize"'
        
        ; Auto Focus Logic
        focusAttr := inputText != "" ? 'FocusManager.FocusedElement="{Binding ElementName=DialogInput}"' : 'FocusManager.FocusedElement="{Binding ElementName=Btn1}"'

        ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Width="' width '" ' heightAttr ' ' resizeAttr ' ' focusAttr (alwaysOnTop ? ' Topmost="True"' : ''))

        resultObj := { Button: "", Input: "", Instance: ui }

        ; Sound
        if (soundFx != "") {
            SoundPlay(soundFx)
        }

        ; Modal logic
        if (modal && owner) {
            WinSetEnabled(0, "ahk_id " owner)
        }

        ; Callbacks
        ui.OnEvent("Window", "LoadedHwnd", (state, ctrl, event) => FluidDialog.OnDialogLoad(ui, owner, modal, themeName, iniPath, buttons, resultObj), 255)
        ui.OnEvent("Window", "Closed", (state, ctrl, event) => FluidDialog.OnDialogClose(ui, resultObj, owner, modal), 255)

        for index, btnText in buttons {
            ui.OnEvent("Btn" index, "Click", ObjBindMethod(FluidDialog, "OnButtonClick", ui, resultObj, btnText, owner, modal), 255)
        }

        if (inputText != "") {
            ui.Track("DialogInput")
        }

        ui.Show()

        if (waitForResponse) {
            ; Wait for dialog to close
            while (resultObj.Button == "" && ProcessExist(ui.pid)) {
                Sleep(50)
            }
            if (resultObj.Button == "") {
                resultObj.Button := "Closed"
            }
            if (modal && owner) {
                WinSetEnabled(1, "ahk_id " owner)
                WinActivate("ahk_id " owner)
            }
            return resultObj
        } else {
            return resultObj
        }
    }

    static ApplyTheme(ui, themeName, iniPath) {
        if !FileExist(iniPath)
            return
        themeData := ""
        try themeData := IniRead(iniPath, themeName)
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2) {
                key := parts[1]
                val := parts[2]
                if (key == "Window_DWM")
                    ui.Update("Window", "DWM", val)
                else if (InStr(key, "Resource_") == 1)
                    ui.Update("Resource", SubStr(key, 10), val)
            }
        }
    }

    static OnDialogLoad(ui, owner, modal, themeName, iniPath, buttons, resultObj, state := "", ctrl := "", event := "") {
        if (owner) {
            ; We can use AHK's WinSetOwner if we have the WPF hwnd
            try {
                DllCall("user32\SetWindowLongPtrW", "Ptr", ui.wpfHwnd, "Int", -8, "Ptr", owner)
            }
        }
        FluidDialog.ApplyTheme(ui, themeName, iniPath)
        
        ; Setup Escape Hotkey for Cancel
        cancelBtn := ""
        for index, btnText in buttons {
            if (btnText == "Cancel" || btnText == "Close") {
                cancelBtn := btnText
                break
            }
        }
        
        if (cancelBtn != "") {
            HotIf (*) => WinActive("ahk_id " ui.wpfHwnd)
            Hotkey "Escape", (hk) => FluidDialog.OnButtonClick(ui, resultObj, cancelBtn, owner, modal, Map(), "", ""), "On"
            HotIf
        }
    }

    static OnDialogClose(ui, resultObj, owner, modal, state := "", ctrl := "", event := "") {
        if (resultObj.Button == "") {
            resultObj.Button := "Closed"
        }
        
        ; Clean up dynamic hotkey
        try {
            HotIf (*) => WinActive("ahk_id " ui.wpfHwnd)
            Hotkey "Escape", "Off"
            HotIf
        }
        
        if (modal && owner) {
            WinSetEnabled(1, "ahk_id " owner)
            WinActivate("ahk_id " owner)
        }
    }

    static OnButtonClick(ui, resultObj, btnText, owner, modal, state, ctrl, event) {
        resultObj.Button := btnText
        if state.Has("DialogInput") {
            resultObj.Input := state["DialogInput"]
        }
        
        if (modal && owner) {
            WinSetEnabled(1, "ahk_id " owner)
            WinActivate("ahk_id " owner)
        }
        
        ; Clean up dynamic hotkey
        try {
            HotIf (*) => WinActive("ahk_id " ui.wpfHwnd)
            Hotkey "Escape", "Off"
            HotIf
        }
        
        ; Close the window
        ui.Update("Window", "Close", "")
    }
}