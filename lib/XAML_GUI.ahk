#Requires AutoHotkey v2.0
#Include "XAML_Host.ahk"
#Include "XAML_Config.ahk"
#Include "XAML_Generator.ahk"

class XAML_GUI {
    __New(title := "Fluid UI", options := {}) {
        this.title := title
        this.sidebarVisible := false
        this.focusedInput := ""
        this.numericInputs := Map()
        this.tokenizers := Map()
        this.hotkeyBoxes := Map()
        this.segmentedInputs := Map()

        hasOpt(key) => Type(options) == "Map" ? options.Has(key) : options.HasOwnProp(key)
        getOpt(key) => Type(options) == "Map" ? options[key] : options.%key%

        this.showSidebar := hasOpt("Sidebar") ? getOpt("Sidebar") : true
        this.showBurger := hasOpt("BurgerMenu") ? getOpt("BurgerMenu") : true
        this.showMinMax := hasOpt("MinMaxButtons") ? getOpt("MinMaxButtons") : true
        this.showIcon := hasOpt("AppIcon") ? getOpt("AppIcon") : true
        this.titleBarHeight := hasOpt("TitleBarHeight") ? getOpt("TitleBarHeight") : 50

        ; Expose the root generator for customization
        this.X := XAML_Generator("Grid").Name("AppGrid").Background("{DynamicResource BgColor}").Focusable("True")
        this.X.Add("Grid.LayoutTransform").Add("ScaleTransform").SetProp("x:Name", "AppScale").ScaleX(1).ScaleY(1)
        this.X.Cols("Auto", "*")

        this.SetupTemplates(this.X)

        if (this.showSidebar) {
            this.sidebar := this.X.Add("Border").Name("SidebarBorder").Style("{StaticResource SidebarAnimStyle}").Grid_Column(0).Background("{DynamicResource SidebarColor}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0").ClipToBounds("True")
            this.BuildSidebar(this.sidebar)
        } else {
            this.sidebar := this.X.Add("Border").Name("SidebarBorder").Grid_Column(0).Visibility("Collapsed")
        }

        this.main := this.X.Add("Grid").Grid_Column(1)
        this.main.Rows(String(this.titleBarHeight), "*", "Auto")

        dragArea := this.main.Add("Border").Name("DragArea").Grid_Row(0).Background("{x:Null}").Cursor("Arrow").SetProp("Panel.ZIndex", "100")
        this.BuildWindowControls(dragArea)

        this.tabs := this.main.Add("TabControl").Name("MainTabs").Grid_Row(1).Margin("40,0,40,10")

        this.bottomBar := this.main.Add("Grid").Grid_Row(2).Background("{DynamicResource SidebarColor}").Visibility("Collapsed")

        ; Built-in overlays
        this.overlay := this.X.Add("Grid").Name("AppOverlay").Grid_ColumnSpan(2)
        this.modalOverlay := this.overlay.Add("Border").Name("ModalOverlay").Style("{StaticResource OverlayDialogLayer}")

        ; Snackbar
        snackbar := this.overlay.Add("Border").Name("SnackbarContainer").Style("{StaticResource SnackbarNotification}").Visibility("Collapsed")
        snackSp := snackbar.Add("StackPanel").Orientation("Horizontal")
        snackSp.Add("TextBlock").Text(Chr(0xE73E)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("{DynamicResource Accent}").FontSize("16").VerticalAlignment("Center").Margin("0,0,10,0")
        snackSp.Add("TextBlock").Name("SnackbarText").Text("Action completed successfully.").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")
    }

    SetupTemplates(X) {
        PrimaryButtonTemplate(el) {
            el.Background("{DynamicResource Accent}").Foreground("White").FontWeight("Bold").BorderThickness(0).FontSize(13).Cursor("Hand")
            el.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.85"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
        }
        X.DefineTemplate("PrimaryBtn", PrimaryButtonTemplate)
        X.DefineTemplate("SubtitleText", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,12" })
        X.DefineTemplate("PageTitle", { FontSize: 28, FontWeight: "SemiBold", Foreground: "{DynamicResource TextMain}", Margin: "0" })
        X.DefineTemplate("BodyText", { FontSize: 13, FontWeight: "Normal", TextWrapping: "Wrap" })
        X.DefineTemplate("CardPanel", { BorderBrush: "{DynamicResource ControlBorder}", BorderThickness: 1, CornerRadius: 6, Background: "{DynamicResource ControlBg}" })

        IconButtonTemplate(el) {
            el.Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Cursor("Hand").FontWeight("Bold")
            el.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="15"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="{DynamicResource ControlBgHover}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style><Style TargetType="RepeatButton"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="RepeatButton"><Border Background="{TemplateBinding Background}" CornerRadius="15"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="{DynamicResource ControlBgHover}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style><Style TargetType="ToggleButton"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ToggleButton"><Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="15" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" Padding="8,4"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ControlBgHover}"/></Trigger><Trigger Property="IsChecked" Value="True"><Setter TargetName="Bd" Property="Background" Value="{DynamicResource ControlBgHover}"/><Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource Accent}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
        }
        X.DefineTemplate("IconBtn", IconButtonTemplate)
        X.SetDefaults("ListBox", { Background: "Transparent", BorderThickness: 0, ScrollViewer_HorizontalScrollBarVisibility: "Disabled" })
    }

    BuildSidebar(container) {
        sp := container.Add("StackPanel").Margin("25,35,25,25")
        sp.SetDefaults("TextBlock", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,12" })

        sp.Add("TextBlock").Name("TxtLogo").Text("SETTINGS").FontSize(22).FontWeight("Black").Foreground("{DynamicResource TextMain}").Margin("0,0,0,40")

        sp.Add("TextBlock").Text("THEME ENGINE").Margin("0,0,0,5")
        themeCombo := sp.Add("ComboBox").Name("ComboTheme").Height(35).Margin("0,0,0,15")
        try {
            iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
            Loop Parse, IniRead(iniPath), "`n", "`r"
                themeCombo.Add("ComboBoxItem").Content(A_LoopField)
        }
        themeCombo.SelectedIndex(0)

        sp.Add("TextBlock").Text("INTERFACE SCALE").Margin("0,15,0,5")
        scaleCombo := sp.Add("ComboBox").Name("ComboScale").SelectedIndex(1).Height(35).Margin("0,0,0,15")
        scaleCombo.Add("ComboBoxItem").Content("Thin")
        scaleCombo.Add("ComboBoxItem").Content("Balanced")
        scaleCombo.Add("ComboBoxItem").Content("Chunky")

        ; Expose for customization
        this.sidebarPanel := sp
    }

    BuildWindowControls(container) {
        grid := container.Add("Grid")

        leftSp := grid.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Center").Margin("15,0,0,0")

        if (this.showBurger) {
            leftSp.Add("ToggleButton").Name("BtnToggleSidebar").Style("{StaticResource HamburgerButton}").WindowChrome_IsHitTestVisibleInChrome("True").ToolTip("Toggle Sidebar (Ctrl+B)").Margin("0,0,10,0")
        }

        titleSp := leftSp.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Center").IsHitTestVisible("False")

        if (this.showIcon) {
            titleSp.Add("Image").Name("AppIcon").Width(16).Height(16).Margin("0,0,10,0")
        }

        titleSp.Add("TextBlock").Name("AppTitle").Text(this.title).Foreground("{DynamicResource TextMain}").FontSize(12).FontWeight("SemiBold")

        winBtns := grid.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right").VerticalAlignment("Top")

        ChromeBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#20FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        CloseBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#E0FF3333"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'

        if (this.showMinMax) {
            minBtn := winBtns.Add("Button").Name("BtnMinimize").WindowChrome_IsHitTestVisibleInChrome("True").Width(45).Height(String(this.titleBarHeight)).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Cursor("Hand").ToolTip("Minimize")
            minBtn.InjectResources(ChromeBtnTemplate)
            minBtn.Add("TextBlock").Text(Chr(0xE921)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

            maxBtn := winBtns.Add("Button").Name("BtnMaximize").WindowChrome_IsHitTestVisibleInChrome("True").Width(45).Height(String(this.titleBarHeight)).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Cursor("Hand").ToolTip("Maximize")
            maxBtn.InjectResources(ChromeBtnTemplate)
            maxBtn.Add("TextBlock").Name("BtnMaximizeTxt").Text(Chr(0xE922)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")
        }

        closeBtn := winBtns.Add("Button").Name("BtnClose").WindowChrome_IsHitTestVisibleInChrome("True").Width(45).Height(String(this.titleBarHeight)).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Cursor("Hand").ToolTip("Close Application")
        closeBtn.InjectResources(CloseBtnTemplate)
        closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")
    }

    AddTab(title, callback) {
        tabItem := this.tabs.Add("TabItem").Header(title)
        callback(tabItem)
    }

    SetBottomBar(callback) {
        this.bottomBar.Visibility("Visible")
        callback(this.bottomBar)
    }

    Compile(outFile := "", options*) {
        if (outFile != "" && FileExist(outFile)) {
            this.xamlString := ""
            this.host := XAMLHost("", outFile, options*)
        } else {
            this.xamlString := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", this.titleBarHeight)
            this.xamlString := StrReplace(this.xamlString, "%app%", this.X.Compile())
            this.host := XAMLHost(this.xamlString, outFile, options*)
        }
        this.BindBaseEvents()

        for k, v in this.tokenizers {
            this.host.OnEvent(v.inputName, "GotFocus", ObjBindMethod(this, "OnInputFocus"))
            this.host.OnEvent(v.inputName, "LostFocus", ObjBindMethod(this, "OnInputBlur"))
            v.Bind()
        }
        for k, v in this.numericInputs {
            this.host.OnEvent(v.id, "GotFocus", ObjBindMethod(this, "OnInputFocus"))
            this.host.OnEvent(v.id, "LostFocus", ObjBindMethod(this, "OnInputBlur"))
            this.host.OnEvent("PART_UpButton", "Click", (s, c, e) => this.HandleSpinnerButton(v, true))
            this.host.OnEvent("PART_DownButton", "Click", (s, c, e) => this.HandleSpinnerButton(v, false))
            v.Bind()
        }
        for k, v in this.hotkeyBoxes {
            this.host.OnEvent(k, "GotFocus", ObjBindMethod(this, "OnInputFocus"))
            this.host.OnEvent(k, "LostFocus", ObjBindMethod(this, "OnInputBlur"))
        }
        for k, v in this.segmentedInputs {
            v.Bind(this.host)
        }
        if (this.HasProp("sliderRanges")) {
            for _, sr in this.sliderRanges {
                sr.Bind(this.host)
            }
        }

        return this.host
    }

    BindBaseEvents() {
        this.host.OnEvent("Window", "Loaded", ObjBindMethod(this, "OnUIReady"))
        this.host.OnEvent("Window", "Closed", (*) => ExitApp())

        this.host.OnEvent("ComboTheme", "SelectionChanged", ObjBindMethod(this, "ThemeChanged"))
        this.host.OnEvent("ComboScale", "SelectionChanged", ObjBindMethod(this, "ScaleChanged"))

        if (this.showBurger) {
            this.host.OnEvent("BtnToggleSidebar", "Click", ObjBindMethod(this, "OnSidebarClick"))
            this.host.Track("BtnToggleSidebar")
        }

        this.host.Track("ComboTheme")
        this.host.Track("ComboScale")

        ; Keyboard hooks for bound components
        this.InitKeyboardHooks()
    }

    Export(filePath) {
        if (!this.HasProp("host"))
            this.Compile()
        this.host.Export(filePath)
    }

    Show(assetPath := "") {
        if (!this.HasProp("host"))
            this.Compile()
        this.host.Show(assetPath)
    }

    ; ==============================================================================
    ; Built-in Core Handlers
    ; ==============================================================================

    OnUIReady(state, ctrl, event) {
        this.host.Update("Window", "DWM", "2,1")
        this.host.Update("Window", "Title", this.title)

        hIcon := LoadPicture("shell32.dll", "Icon26", &ImageType := 1)
        this.host.Update("Window", "Icon", "HICON:" hIcon)
        TraySetIcon("shell32.dll", 26)

        this.host.Update("AppTitle", "Text", this.title)

        if (this.showIcon) {
            this.host.Update("AppIcon", "Source", "HICON:" hIcon)
        }

        this.ThemeChanged(state, ctrl, event)
        this.ScaleChanged(state, ctrl, event)

        for _, tok in this.tokenizers {
            tok.RenderTags()
        }

        ; Force window to foreground on load
        if (this.host.wpfHwnd) {
            try WinActivate("ahk_id " this.host.wpfHwnd)
        }
    }

    ThemeChanged(state, ctrl, event) {
        if !state.Has("ComboTheme")
            return
        theme := state["ComboTheme"]
        try {
            iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
            themeData := IniRead(iniPath, theme)
            Loop Parse, themeData, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=", " `t", 2)
                if (parts.Length == 2) {
                    key := parts[1]
                    val := parts[2]
                    if (key == "Window_DWM")
                        this.host.Update("Window", "DWM", val)
                    else if (InStr(key, "Resource_") == 1)
                        this.host.Update("Resource", SubStr(key, 10), val)
                    else if (InStr(key, "LogList_") == 1)
                        this.host.Update("LogList", SubStr(key, 9), val)
                }
            }
        } catch {
            ; Do nothing
        }
    }

    ScaleChanged(state, ctrl, event) {
        if !state.Has("ComboScale")
            return
        scale := state["ComboScale"]
        if (scale == "Thin") {
            this.host.Update("AppScale", "ScaleX", "0.9")
            this.host.Update("AppScale", "ScaleY", "0.9")
        } else if (scale == "Balanced") {
            this.host.Update("AppScale", "ScaleX", "1.0")
            this.host.Update("AppScale", "ScaleY", "1.0")
        } else if (scale == "Chunky") {
            this.host.Update("AppScale", "ScaleX", "1.15")
            this.host.Update("AppScale", "ScaleY", "1.15")
        }
    }

    OnSidebarClick(state, ctrl, event) {
        this.sidebarVisible := !this.sidebarVisible
    }

    ShowSnackbar(message, duration := 3000) {
        this.host.Update("SnackbarText", "Text", message)
        this.host.Update("SnackbarContainer", "Visibility", "Visible")
        SetTimer(ObjBindMethod(this, "HideSnackbar"), -duration)
    }

    HideSnackbar() {
        this.host.Update("SnackbarContainer", "Visibility", "Collapsed")
    }

    ; ==============================================================================
    ; Keyboard hooks for Inputs
    ; ==============================================================================

    RegisterTokenizer(tok) {
        this.tokenizers[tok.inputName] := tok
    }

    RegisterNumericInput(num) {
        this.numericInputs[num.id] := num
    }

    RegisterHotKeyChange(element, callback) {
        id := element._Props["Name"]
        this.hotkeyBoxes[id] := { id: id, onChange: callback }
    }

    RegisterSegmentedInput(seg) {
        this.segmentedInputs[seg.id] := seg
    }

    RegisterSliderRange(sr) {
        if (!this.HasProp("sliderRanges"))
            this.sliderRanges := []
        this.sliderRanges.Push(sr)
    }

    HandleSpinnerButton(num, isUp) {
        ; When the user clicks the spin buttons, WPF triggers PART_UpButton
        ; but XAMLHost doesn't easily let us know *which* control's spin button it was
        ; unless we extract parents. For now, if there's a focused numeric input, use it.
        ; Alternatively, we'd need a more robust binding. Let's just use focusedInput.
        if (this.focusedInput && this.numericInputs.Has(this.focusedInput)) {
            if isUp
                this.numericInputs[this.focusedInput].Increment(GetKeyState("Shift", "P"))
            else
                this.numericInputs[this.focusedInput].Decrement(GetKeyState("Shift", "P"))
        }
    }

    OnInputFocus(state, ctrl, event) {
        this.focusedInput := ctrl
        if (this.hotkeyBoxes.Has(ctrl)) {
            SetTimer(ObjBindMethod(this, "StartHotKeyCapture", ctrl), -1)
        }
    }

    OnInputBlur(state, ctrl, event) {
        this.focusedInput := ""
        if (this.HasProp("ih") && this.ih) {
            this.ih.Stop()
            this.ih := ""
        }
    }

    StartHotKeyCapture(ctrl) {
        this.host.Update(ctrl, "Text", "Listening...")
        this.ih := InputHook("L1 M")
        this.ih.KeyOpt("{All}", "E")
        this.ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
        this.ih.Start()
        this.ih.Wait()

        if (this.focusedInput != ctrl || !this.ih)
            return

        key := this.ih.EndKey != "" ? this.ih.EndKey : this.ih.Input
        this.ih := ""

        if (key == "Escape") {
            this.host.Update("AppGrid", "Focus", "True")
            return
        }

        mods := ""
        if GetKeyState("Ctrl", "P")
            mods .= "^"
        if GetKeyState("Shift", "P")
            mods .= "+"
        if GetKeyState("Alt", "P")
            mods .= "!"
        if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
            mods .= "#"

        if (key == "Backspace") {
            newBind := ""
        } else if (key != "") {
            newBind := mods key
        } else {
            newBind := ""
        }

        this.host.Update(ctrl, "Text", newBind)
        if (this.hotkeyBoxes[ctrl].onChange)
            this.hotkeyBoxes[ctrl].onChange.Call(newBind)

        this.host.Update("AppGrid", "Focus", "True")
    }

    InitKeyboardHooks() {
        HotIf (*) => (WinActive("ahk_id " this.host.wpfHwnd) && this.focusedInput != "")
        Hotkey "Up", (*) => this.HandleUpKey(), "On"
        Hotkey "Down", (*) => this.HandleDownKey(), "On"
        Hotkey "+Up", (*) => this.HandleUpKey(true), "On"
        Hotkey "+Down", (*) => this.HandleDownKey(true), "On"
        Hotkey "Escape", (*) => this.HandleEscapeKey(), "On"
        HotIf

        HotIf (*) => WinActive("ahk_id " this.host.wpfHwnd)
        if (this.showBurger)
            Hotkey "^b", (*) => this.host.Update("BtnToggleSidebar", "Invoke", "1"), "On"
        HotIf
    }

    HandleUpKey(shift := false) {
        if this.numericInputs.Has(this.focusedInput)
            this.numericInputs[this.focusedInput].Increment(shift)
    }

    HandleDownKey(shift := false) {
        if this.numericInputs.Has(this.focusedInput)
            this.numericInputs[this.focusedInput].Decrement(shift)
    }

    HandleEscapeKey() {
        if this.focusedInput != "" {
            this.host.Update(this.focusedInput, "Text", "")
            this.host.Update("AppGrid", "Focus", "True")
        }
    }
}