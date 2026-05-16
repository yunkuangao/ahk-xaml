#Requires AutoHotkey v2.0
#Include "XAML_Host.ahk"
#Include "XAML_Generator.ahk"

; ==============================================================================
; SIMPLE COMPONENTS (Prototype Extensions)
; ==============================================================================

XAMLElement.Prototype.DefineProp("TelemetryRow", { Call: _TelemetryRow })
_TelemetryRow(this, id, location, latencyMs, status, statusColor) {
    rowGrid := this.Add("ListBoxItem").Add("Grid")
    rowGrid.Cols("120", "170", "80", "*")
    rowGrid.Add("TextBlock").Grid_Column(0).Text(id).Foreground("{DynamicResource TextMain}").Margin("10,0,0,0").VerticalAlignment("Center")
    rowGrid.Add("TextBlock").Grid_Column(1).Text(location).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")
    rowGrid.Add("TextBlock").Grid_Column(2).Text(latencyMs).Foreground(statusColor).VerticalAlignment("Center")

    border := rowGrid.Add("Border").Grid_Column(3).Background("#20" StrReplace(statusColor, "#", "")).HorizontalAlignment("Left").Padding("8,3").CornerRadius(4)
    border.Add("TextBlock").Text(status).Foreground(statusColor).FontSize(10).FontWeight("Bold")
    return this
}

XAMLElement.Prototype.DefineProp("Toggle", { Call: _Toggle })
_Toggle(this, name, label, isChecked := false, tooltip := "") {
    grid := this.Add("Grid").Margin("0,0,0,15")
    grid.Add("TextBlock").Text(label).Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")
    chk := grid.Add("CheckBox").Name(name).Style("{StaticResource ToggleSwitch}").HorizontalAlignment("Right")
    if (isChecked)
        chk.IsChecked()
    if (tooltip != "")
        chk.ToolTip(tooltip)
    return this
}

XAMLElement.Prototype.DefineProp("SegmentGroup", { Call: _SegmentGroup })
_SegmentGroup(this, groupName, options, selectedIndex := 1) {
    border := this.Add("Border").Use("CardPanel").HorizontalAlignment("Left").Margin("0,0,0,25")
    sp := border.Add("StackPanel").Orientation("Horizontal")
    for index, opt in options {
        rb := sp.Add("RadioButton").Style("{StaticResource SegmentedBtn}").Content(opt).GroupName(groupName)
        if (index == selectedIndex)
            rb.IsChecked()
        if (index < options.Length)
            rb.BorderThickness("0,0,1,0")
        else
            rb.BorderThickness("0")
    }
    return this
}

XAMLElement.Prototype.DefineProp("MetricCard", { Call: _MetricCard })
_MetricCard(this, title, mainValue, subValue, subColor := "#32D74B", progressValue := -1) {
    card := this.Add("Border").Use("CardPanel").Padding("15")
    sp := card.Add("StackPanel")
    sp.Add("TextBlock").Text(title).Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold")
    sp.Add("TextBlock").Text(mainValue).Foreground("{DynamicResource TextMain}").FontSize(24).FontWeight("Light").Margin("0,10,0,0")

    if (progressValue != -1) {
        sp.Add("ProgressBar").Value(progressValue).Maximum(100).Height(4).Margin("0,10,0,0").Foreground("{DynamicResource Accent}").Background("{DynamicResource ControlBorder}").BorderThickness(0)
    } else {
        sp.Add("TextBlock").Text(subValue).Foreground(subColor).FontSize(11).Margin("0,5,0,0")
    }
    return card
}

XAMLElement.Prototype.DefineProp("CodeEditor", { Call: _CodeEditor })
_CodeEditor(this, filename) {
    ideBdr := this.Add("Border").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).CornerRadius(6).Margin("0,0,0,20")
    ideGrid := ideBdr.Add("Grid")
    ideGrid.Rows("30", "*")

    ideHeader := ideGrid.Add("Border").Grid_Row(0).Background("{DynamicResource ControlBorder}").CornerRadius("5,5,0,0")
    headerInner := ideHeader.Add("Grid")
    headerInner.Add("TextBlock").Text(filename).Foreground("{DynamicResource TextMain}").FontSize(11).HorizontalAlignment("Left").VerticalAlignment("Center").Margin("15,0,0,0")

    btns := headerInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right").Margin("0,0,10,0")
    btns.SetDefaults("Button", { Background: "Transparent", BorderThickness: 0, Foreground: "{DynamicResource TextSub}", FontSize: 10, Padding: "8,2", Margin: "2,0", Cursor: "Hand" })
    btns.Add("Button").Content("Save")
    btns.Add("Button").Content("Select All")
    btns.Add("Button").Content("Run").Foreground("{DynamicResource Accent}").FontWeight("Bold")

    editorBorder := ideGrid.Add("Border").Grid_Row(1).Background("{DynamicResource ControlBg}").CornerRadius("0,0,5,5")
    editor := editorBorder.Add("RichTextBox").FontFamily("Consolas, Courier New").Background("Transparent").BorderThickness(0).Padding("15").Height(130).Foreground("{DynamicResource TextMain}").CaretBrush("{DynamicResource TextMain}")

    return editor
}

; ==============================================================================
; COMPLEX COMPONENTS (Stateful Classes)
; ==============================================================================

class XColorPicker {
    static Show(options) {
        title := options.HasProp("Title") ? options.Title : "Select Color"
        defaultColor := options.HasProp("DefaultColor") ? options.DefaultColor : "#FF0A84FF"
        owner := options.HasProp("Owner") ? options.Owner : 0
        modal := options.HasProp("Modal") ? options.Modal : false
        themeName := options.HasProp("Theme") ? options.Theme : "Dark Mica (Win 11)"
        iniPath := options.HasProp("IniPath") ? options.IniPath : "themes.ini"

        bgRes := "DropdownBg"
        if FileExist(iniPath) {
            try {
                themeData := IniRead(iniPath, themeName)
                Loop Parse, themeData, "`n", "`r" {
                    parts := StrSplit(A_LoopField, "=", " `t", 2)
                    if (parts.Length == 2 && parts[1] == "Window_DWM") {
                        if (SubStr(parts[2], 1, 1) == "2" || SubStr(parts[2], 1, 1) == "3")
                            bgRes := "BgColor"
                        break
                    }
                }
            }
        }

        main := XAML_Generator("Grid").Background("{DynamicResource " bgRes "}")
        main.Rows("Auto", "10", "*", "15", "Auto")

        tb := main.Add("Grid").Grid_Row(0).Background("Transparent").Name("DragArea").Margin("15,15,15,0")
        tb.Add("TextBlock").Text(title).Foreground("{DynamicResource TextMain}").FontSize(14).FontWeight("Bold").VerticalAlignment("Center")
        
        CloseBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#E0FF3333"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        closeBtn := tb.Add("Button").Name("BtnClose").WindowChrome_IsHitTestVisibleInChrome("True").Width(30).Height(30).HorizontalAlignment("Right").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0)
        closeBtn.InjectResources(CloseBtnTemplate)
        closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

        cpGrid := main.Add("Grid").Grid_Row(2).Margin("15,10,15,0")
        cpGrid.Cols("Auto", "20", "*")
        cpGrid.Rows("Auto", "15", "Auto", "15", "Auto")

        cpGrid.Add("Border").Name("ColorPreview").Grid_Column(0).Grid_RowSpan(5).Width("70").Height("70").CornerRadius("35").Background(defaultColor).BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")

        hueGrid := cpGrid.Add("Grid").Grid_Column(2).Grid_Row(0)
        hueBg := hueGrid.Add("Border").Height("8").CornerRadius("4").Margin("0,10,0,0").Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,0")
        hueBg.Add("GradientStop").Color("#FFFF0000").Offset("0")
        hueBg.Add("GradientStop").Color("#FFFFFF00").Offset("0.16")
        hueBg.Add("GradientStop").Color("#FF00FF00").Offset("0.33")
        hueBg.Add("GradientStop").Color("#FF00FFFF").Offset("0.5")
        hueBg.Add("GradientStop").Color("#FF0000FF").Offset("0.66")
        hueBg.Add("GradientStop").Color("#FFFF00FF").Offset("0.83")
        hueBg.Add("GradientStop").Color("#FFFF0000").Offset("1")
        hueGrid.Add("Slider").Name("HueSlider").Minimum("0").Maximum("360").Value("210")

        alphaGrid := cpGrid.Add("Grid").Grid_Column(2).Grid_Row(2)
        alphaBg := alphaGrid.Add("Border").Height("8").CornerRadius("4").Margin("0,10,0,0").Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,0")
        alphaBg.Add("GradientStop").Color("Transparent").Offset("0")
        alphaBg.Add("GradientStop").Color("White").Offset("1")
        alphaGrid.Add("Slider").Name("AlphaSlider").Minimum("0").Maximum("255").Value("255")

        rgbGrid := cpGrid.Add("Grid").Grid_Column(2).Grid_Row(4)
        rgbGrid.Cols("Auto", "5", "40", "10", "Auto", "5", "40", "10", "Auto", "5", "40", "*", "Auto", "5", "70")
        rgbGrid.Add("TextBlock").Text("R").Grid_Column(0).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").FontSize(11).FontWeight("Bold")
        rgbGrid.Add("TextBox").Name("RInput").Text("10").Grid_Column(2).Height("24").Padding("4,2").HorizontalContentAlignment("Center")
        rgbGrid.Add("TextBlock").Text("G").Grid_Column(4).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").FontSize(11).FontWeight("Bold")
        rgbGrid.Add("TextBox").Name("GInput").Text("132").Grid_Column(6).Height("24").Padding("4,2").HorizontalContentAlignment("Center")
        rgbGrid.Add("TextBlock").Text("B").Grid_Column(8).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").FontSize(11).FontWeight("Bold")
        rgbGrid.Add("TextBox").Name("BInput").Text("255").Grid_Column(10).Height("24").Padding("4,2").HorizontalContentAlignment("Center")

        rgbGrid.Add("TextBlock").Text("HEX").Grid_Column(12).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").FontSize(11).FontWeight("Bold")
        rgbGrid.Add("TextBox").Name("HexInput").Text(defaultColor).Grid_Column(14).Height("24").Padding("4,2").HorizontalContentAlignment("Center")

        btnSp := main.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right").Grid_Row(4).Margin("0,0,15,15")
        
        main.InjectResources('<Style x:Key="DialogBtn" TargetType="Button"><Setter Property="Background" Value="#10FFFFFF"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/><Setter Property="BorderBrush" Value="{DynamicResource ControlBorder}"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,6"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#20FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style><Style x:Key="DialogPrimaryBtn" TargetType="Button"><Setter Property="Background" Value="{DynamicResource Accent}"/><Setter Property="Foreground" Value="White"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,6"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.85"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
        
        btnSp.Add("Button").Name("BtnCancel").Content("Cancel").Style("{StaticResource DialogBtn}").Width("100").Height("32").Cursor("Hand").Margin("0,0,10,0")
        btnSp.Add("Button").Name("BtnConfirm").Content("Confirm").Style("{StaticResource DialogPrimaryBtn}").Width("100").Height("32").Cursor("Hand")

        ui := XAMLHost(StrReplace(XAML_TEMPLATE, "%app%", main.ToString()), "", owner)
        ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Width="450" SizeToContent="Height" ResizeMode="NoResize" Topmost="True"')
        
        resultObj := { Color: "", Status: "Cancel", Instance: ui }
        
        if (modal && owner)
            WinSetEnabled(0, "ahk_id " owner)

        ui.OnEvent("Window", "LoadedHwnd", (state, ctrl, event) => XColorPicker.OnLoad(ui, owner, themeName, iniPath, defaultColor))
        ui.OnEvent("Window", "Closing", (state, ctrl, event) => XColorPicker.OnClose(resultObj, owner, modal))
        
        ui.OnEvent("HueSlider", "ValueChanged", ObjBindMethod(XColorPicker, "UpdateFromSliders", ui))
        ui.OnEvent("AlphaSlider", "ValueChanged", ObjBindMethod(XColorPicker, "UpdateFromSliders", ui))
        ui.OnEvent("RInput", "TextChanged", ObjBindMethod(XColorPicker, "UpdateFromRGB", ui))
        ui.OnEvent("GInput", "TextChanged", ObjBindMethod(XColorPicker, "UpdateFromRGB", ui))
        ui.OnEvent("BInput", "TextChanged", ObjBindMethod(XColorPicker, "UpdateFromRGB", ui))

        ui.OnEvent("BtnClose", "Click", (state, ctrl, event) => ui.Update("Window", "Close", ""))
        ui.OnEvent("BtnCancel", "Click", (state, ctrl, event) => ui.Update("Window", "Close", ""))
        ui.OnEvent("BtnConfirm", "Click", (state, ctrl, event) => XColorPicker.ConfirmSelection(ui, resultObj, state))

        ui.Track("HueSlider")
        ui.Track("AlphaSlider")
        ui.Track("RInput")
        ui.Track("GInput")
        ui.Track("BInput")
        ui.Track("HexInput")

        ui.Show()

        while (resultObj.Status == "Cancel" && ProcessExist(ui.pid)) {
            Sleep(50)
        }
        
        if (modal && owner)
            WinSetEnabled(1, "ahk_id " owner)

        return resultObj
    }

    static OnLoad(ui, owner, themeName, iniPath, defaultColor, state := "", ctrl := "", event := "") {
        if owner
            ui.Update("Window", "NativeOwner", owner)
        if FileExist(iniPath) {
            try {
                themeData := IniRead(iniPath, themeName)
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
        }
        
        ; Parse defaultColor to set RGB and sliders
        if (RegExMatch(defaultColor, "^#?([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})$", &m)) {
            ui.Update("AlphaSlider", "Value", String(Integer("0x" m[1])))
            ui.Update("RInput", "Text", String(Integer("0x" m[2])))
            ui.Update("GInput", "Text", String(Integer("0x" m[3])))
            ui.Update("BInput", "Text", String(Integer("0x" m[4])))
        } else if (RegExMatch(defaultColor, "^#?([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})$", &m)) {
            ui.Update("AlphaSlider", "Value", "255")
            ui.Update("RInput", "Text", String(Integer("0x" m[1])))
            ui.Update("GInput", "Text", String(Integer("0x" m[2])))
            ui.Update("BInput", "Text", String(Integer("0x" m[3])))
        }
    }

    static OnClose(resultObj, owner, modal, state := "", ctrl := "", event := "") {
        if owner && modal
            WinSetEnabled(1, "ahk_id " owner)
    }

    static ConfirmSelection(ui, resultObj, state) {
        if state.Has("HexInput")
            resultObj.Color := state["HexInput"]
        resultObj.Status := "OK"
        ui.Update("Window", "Close", "")
    }

    static UpdateFromSliders(ui, state, ctrl, event) {
        hue := state["HueSlider"] != "" ? Float(state["HueSlider"]) : 0
        alpha := state["AlphaSlider"] != "" ? Integer(state["AlphaSlider"]) : 255

        c := 1.0
        x := c * (1.0 - Abs(Mod(hue / 60.0, 2) - 1.0))
        r := 0.0, g := 0.0, b := 0.0
        if (0 <= hue && hue < 60) {
            r := c, g := x, b := 0
        } else if (60 <= hue && hue < 120) {
            r := x, g := c, b := 0
        } else if (120 <= hue && hue < 180) {
            r := 0, g := c, b := x
        } else if (180 <= hue && hue < 240) {
            r := 0, g := x, b := c
        } else if (240 <= hue && hue < 300) {
            r := x, g := 0, b := c
        } else if (300 <= hue && hue <= 360) {
            r := c, g := 0, b := x
        }

        rInt := Round(r * 255)
        gInt := Round(g * 255)
        bInt := Round(b * 255)

        hex := Format("#{:02X}{:02X}{:02X}{:02X}", alpha, rInt, gInt, bInt)

        ui.Update("ColorPreview", "Background", hex)
        ui.Update("HexInput", "Text", hex)
        ui.Update("RInput", "Text", String(rInt))
        ui.Update("GInput", "Text", String(gInt))
        ui.Update("BInput", "Text", String(bInt))
    }

    static UpdateFromRGB(ui, state, ctrl, event) {
        try {
            r := state["RInput"] != "" ? Integer(state["RInput"]) : 0
            g := state["GInput"] != "" ? Integer(state["GInput"]) : 0
            b := state["BInput"] != "" ? Integer(state["BInput"]) : 0

            r := Min(Max(r, 0), 255)
            g := Min(Max(g, 0), 255)
            b := Min(Max(b, 0), 255)

            alpha := state["AlphaSlider"] != "" ? Integer(state["AlphaSlider"]) : 255
            hex := Format("#{:02X}{:02X}{:02X}{:02X}", alpha, r, g, b)

            ui.Update("HexInput", "Text", hex)
            ui.Update("ColorPreview", "Background", hex)
        }
    }
}

class XTokenizer {
    __New(ui, parentXAML, options := {}) {
        this.ui := ui
        this.tags := options.HasProp("InitialTags") ? options.InitialTags : []
        this.logOutput := options.HasProp("LogTarget") ? options.LogTarget : ""
        
        id := XTokenizer.Count() + 1
        this.wpName := "TokenWrapPanel_" id
        this.inputName := "TxtTokenInput_" id
        this.comboName := "ComboTokenSplit_" id
        this.chkConfirmName := "ChkConfirmDelete_" id
        this.baseId := id
        this.currentText := ""

        tokHeaderSp := parentXAML.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,8")
        tokHeaderSp.Add("TextBlock").Text("TOKENIZING SEARCH (TAGS)").VerticalAlignment("Center").Margin("0,0,15,0").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold")
        tokCombo := tokHeaderSp.Add("ComboBox").Name(this.comboName).Width(180).Height(35).SelectedIndex(0)
        tokCombo.Add("ComboBoxItem").Content("Comma (,)")
        tokCombo.Add("ComboBoxItem").Content("Space ( )")
        tokHeaderSp.Add("CheckBox").Name(this.chkConfirmName).Content("Confirm Deletion").VerticalAlignment("Center").Margin("15,0,0,0").IsChecked("True")

        tokBorder := parentXAML.Add("Border").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("6").Padding("6,6,0,0").Margin("0,0,0,20")
        tokWp := tokBorder.Add("WrapPanel").Name(this.wpName).Orientation("Horizontal").Background("Transparent").Cursor("IBeam")

        ; Pre-allocate max 15 tags
        Loop 15 {
            tagName := "TagBorder_" this.baseId "_" A_Index
            tagTxtName := "TagText_" this.baseId "_" A_Index
            tagBtnName := "BtnDeleteTag_" this.baseId "_" A_Index
            
            tag := tokWp.Add("Border").Name(tagName).Style("{StaticResource TagToken}").Visibility("Collapsed")
            tagSp := tag.Add("StackPanel").Orientation("Horizontal")
            tagSp.Add("TextBlock").Name(tagTxtName).Text("").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontSize(12)
            tagSp.Add("Button").Name(tagBtnName).Style("{StaticResource TagTokenCloseBtn}")
        }

        tokWp.Add("TextBox").Name(this.inputName).Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").MinWidth("100").Tag("Add filter...").Margin("0,0,0,6")
    }

    Bind() {
        this.ui.host.Track(this.comboName)
        this.ui.host.Track(this.chkConfirmName)
        this.ui.host.Track(this.inputName)

        this.ui.host.OnEvent(this.inputName, "TextChanged", ObjBindMethod(this, "OnTextChanged"))
        this.ui.host.OnEvent(this.wpName, "PreviewMouseLeftButtonDown", ObjBindMethod(this, "FocusInput"))

        Loop 15 {
            this.ui.host.OnEvent("BtnDeleteTag_" this.baseId "_" A_Index, "Click", ObjBindMethod(this, "OnDeleteClick"))
        }

        this.RenderTags()

        ; Note: Enter validation is handled by keyboard hook in XAML_GUI for simplicity 
        ; due to lack of direct KeyDown events in XAMLHost right now.
    }

    RenderTags() {
        Loop 15 {
            tagName := "TagBorder_" this.baseId "_" A_Index
            tagTxtName := "TagText_" this.baseId "_" A_Index
            if (A_Index <= this.tags.Length) {
                this.ui.host.Update(tagTxtName, "Text", this.tags[A_Index])
                this.ui.host.Update(tagName, "Visibility", "Visible")
            } else {
                this.ui.host.Update(tagName, "Visibility", "Collapsed")
                this.ui.host.Update(tagTxtName, "Text", "")
            }
        }
    }

    OnTextChanged(state, ctrl, event) {
        if (!state.Has(this.inputName) || !state.Has(this.comboName))
            return
            
        this.currentText := state[this.inputName]
        text := state[this.inputName]
        splitMode := state[this.comboName]
        splitChar := (splitMode == "Space ( )") ? " " : ","

        if (InStr(text, splitChar) || InStr(text, "`n")) {
            text := StrReplace(text, "`n", splitChar)
            text := StrReplace(text, "`r", "")
            parts := StrSplit(text, splitChar)

            for part in parts {
                trimmed := Trim(part)
                if (trimmed != "" && this.tags.Length < 15) {
                    this.tags.Push(trimmed)
                    if (this.logOutput != "")
                        this.ui.host.Update(this.logOutput, "AddItem", "Captured Tag: " trimmed)
                }
            }
            this.ui.host.Update(this.inputName, "Text", "")
            this.RenderTags()
        }
    }

    OnDeleteClick(state, ctrl, event) {
        idx := Integer(RegExReplace(ctrl, "\D"))
        if (state.Has(this.chkConfirmName) && state[this.chkConfirmName] == "True") {
            theme := state.Has("ComboTheme") ? state["ComboTheme"] : "Dark Mica (Win 11)"
            res := XDialog.Show({
                Title: "Delete Tag?",
                Message: "Are you sure you want to remove this tag?",
                Icon: Chr(0xE74D),
                IconColor: "#FF453A",
                Buttons: ["Delete", "Cancel"],
                Width: 350,
                Modal: true,
                Owner: this.ui.host.wpfHwnd,
                Theme: theme
            })
            if (res.Button == "Delete") {
                this.tags.RemoveAt(idx)
                this.RenderTags()
            }
        } else {
            this.tags.RemoveAt(idx)
            this.RenderTags()
        }
    }

    FocusInput(state, ctrl, event) {
        this.ui.host.Update(this.inputName, "Focus", "True")
    }

    ValidateCurrentInput() {
        token := Trim(this.currentText)
        if (token != "" && this.tags.Length < 15) {
            this.tags.Push(token)
            this.ui.host.Update(this.inputName, "Text", "")
            this.currentText := ""
            if (this.logOutput != "")
                this.ui.host.Update(this.logOutput, "AddItem", "Captured Tag: " token)
            this.RenderTags()
        }
    }

    static Count() {
        static counter := 0
        return ++counter
    }
}

class XNumericUpDown {
    __New(ui, parentXAML, isDecimal := false, options := {}) {
        this.ui := ui
        this.isDecimal := isDecimal
        this.val := options.HasProp("Default") ? options.Default : (isDecimal ? 3.14 : 42)
        this.id := "NumInput_" XNumericUpDown.Count()
        
        parentXAML.Add("TextBox").Name(this.id).Style("{StaticResource NumericUpDown}").Text(String(this.val)).HorizontalContentAlignment("Center")
    }

    Bind() {
        this.ui.host.Track(this.id)
        this.ui.host.OnEvent(this.id, "TextChanged", ObjBindMethod(this, "OnTextChanged"))
        ; Up/Down arrows are usually hooked via global hotkeys in the app, but XNumericUpDown exposes Increment/Decrement
    }

    OnTextChanged(state, ctrl, event) {
        valStr := state[this.id]
        if (!this.isDecimal) {
            clean := RegExReplace(valStr, "[^\d\-]")
            if (clean != valStr) {
                this.ui.host.Update(this.id, "Text", clean)
                this.val := (clean != "" && clean != "-") ? Integer(clean) : 0
            } else {
                this.val := (valStr != "" && valStr != "-") ? Integer(valStr) : 0
            }
        } else {
            clean := RegExReplace(valStr, "[^\d\.\-]")
            StrReplace(clean, ".", ".", , &dotCount)
            if (dotCount > 1) {
                clean := SubStr(clean, 1, InStr(clean, ".", , , 2) - 1)
            }
            if (clean != valStr) {
                this.ui.host.Update(this.id, "Text", clean)
            }
            if (clean != "" && clean != "-" && clean != "." && !RegExMatch(clean, "\.$")) {
                this.val := Float(clean)
            }
        }
    }

    Increment(shiftPressed := false) {
        step := shiftPressed ? (this.isDecimal ? 1.0 : 10) : (this.isDecimal ? 0.1 : 1)
        if (this.val + step <= 100) {
            this.val += step
            this.ui.host.Update(this.id, "Text", this.isDecimal ? String(Round(this.val, 2)) : String(this.val))
        }
    }

    Decrement(shiftPressed := false) {
        step := shiftPressed ? (this.isDecimal ? 1.0 : 10) : (this.isDecimal ? 0.1 : 1)
        if (this.val - step >= 0) {
            this.val -= step
            this.ui.host.Update(this.id, "Text", this.isDecimal ? String(Round(this.val, 2)) : String(this.val))
        }
    }

    static Count() {
        static counter := 0
        return ++counter
    }
}

; ==============================================================================
; XRibbon Component System
; ==============================================================================

class XRibbon {
    __New(parentXAML) {
        this.container := parentXAML.Name("RibbonMainContainer")
        this.tabCtrl := parentXAML.Add("TabControl").Name("RibbonTabs").Style("{StaticResource RibbonTabControl}")
        this.tabs := []
        this.isPinned := true
        this.container.ClipToBounds("False")
    }

    AddTab(title) {
        tabItem := this.tabCtrl.Add("TabItem").Header(title).Style("{StaticResource RibbonTabItem}")
        wrapPanel := tabItem.Add("WrapPanel").Margin("0").Orientation("Horizontal")
        tab := XRibbonTab(wrapPanel)
        this.tabs.Push(tab)
        return tab
    }

    BindEvents(ui) {
        this.ui := ui
        ui.OnEvent("RibbonTabs", "MouseDoubleClick", this.OnDoubleClick.Bind(this))
        ui.OnEvent("RibbonTabs", "PreviewMouseLeftButtonDown", this.OnTabClick.Bind(this))
    }

    OnDoubleClick(state, ctrl, event) {
        if (this.isPinned) {
            this.Collapse()
        } else {
            this.Pin()
        }
        this.UpdateHost()
    }

    OnTabClick(state, ctrl, event) {
        if (!this.isPinned) {
            this.ExpandOverlay()
            this.UpdateHost()
        }
    }

    Pin() {
        this.isPinned := true
        this.container.Height("NaN")
        this.container.Margin("0")
        this.container.ClipToBounds("False")
        this.container.SetProp("Panel.ZIndex", "1")
    }

    Collapse() {
        this.isPinned := false
        this.container.Height(50)
        this.container.Margin("0")
        this.container.ClipToBounds("True")
        this.container.SetProp("Panel.ZIndex", "1")
    }

    ExpandOverlay() {
        this.container.Height("NaN")
        this.container.Margin("0,0,0,-92")
        this.container.ClipToBounds("False")
        this.container.SetProp("Panel.ZIndex", "100")
    }

    UpdateHost() {
        this.ui.Update("RibbonMainContainer", "Height", this.container._Props.Has("Height") ? this.container._Props["Height"] : "NaN")
        this.ui.Update("RibbonMainContainer", "Margin", this.container._Props.Has("Margin") ? this.container._Props["Margin"] : "0")
        this.ui.Update("RibbonMainContainer", "ClipToBounds", this.container._Props.Has("ClipToBounds") ? this.container._Props["ClipToBounds"] : "False")
        this.ui.Update("RibbonMainContainer", "Panel.ZIndex", this.container._Props.Has("Panel.ZIndex") ? this.container._Props["Panel.ZIndex"] : "0")
    }
}

class XRibbonTab {
    __New(wrapPanel) {
        this.panel := wrapPanel
    }

    AddGroup(title) {
        border := this.panel.Add("Border").Style("{StaticResource RibbonGroupBorder}")
        grid := border.Add("Grid")
        grid.Rows("*", "Auto")
        
        contentPanel := grid.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,2")
        
        titleTxt := grid.Add("TextBlock").Grid_Row(1).Text(title).Style("{StaticResource RibbonGroupTitle}")
        
        return XRibbonGroup(contentPanel)
    }
}

class XRibbonGroup {
    __New(stackPanel) {
        this.panel := stackPanel
    }

    AddLargeBtn(name, text, iconHex) {
        return this.panel.Add("Button").Name(name).Tag(Chr(iconHex)).Content(text).Style("{StaticResource RibbonButtonLarge}")
    }

    AddSmallBtn(name, text, iconHex) {
        return this.panel.Add("Button").Name(name).Tag(Chr(iconHex)).Content(text).Style("{StaticResource RibbonButtonSmall}").Margin("0,0,0,2")
    }

    AddSeparator() {
        return this.panel.Add("Rectangle").Width(1).Fill("{DynamicResource ControlBorder}").Margin("4,2,4,2")
    }

    AddVerticalStack() {
        stack := this.panel.Add("StackPanel").Orientation("Vertical").VerticalAlignment("Center").Margin("2,0")
        return XRibbonGroup(stack)
    }
}
