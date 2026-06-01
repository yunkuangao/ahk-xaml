#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Generator.ahk"
#Include "..\..\lib\XAML_Host.ahk"
XAMLHost.Prewarm()
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; --- Docking Manager Example ---
; Demonstrates how to create a multi-window IDE-like environment
; with floating "tear-off" panels that remember their size, position, and visibility across sessions.

global INI_FILE := A_ScriptDir "\docking_layout.ini"
global isAppReady := false
global isInitializing := true

Trace(msg) {
    try FileAppend(msg "`n", A_Temp "\AhkWpf\AhkTrace.log", "UTF-8")
}

try FileDelete(A_Temp "\AhkWpf\AhkTrace.log")
Trace("1. Global Script Start")
PanelManager.RegisterAll()

class PanelManager {
    static Panels := Map()
    static MainWindow := ""
    static CurrentTheme := "Dark Mica (Win 11)"

    static RegisterAll() {
        this.RegisterPanel("Terminal", "Terminal Output", 100, 100, 600, 300)
        this.RegisterPanel("Properties", "Object Properties", 750, 100, 300, 500)
        this.RegisterPanel("Toolbox", "Component Toolbox", 100, 450, 250, 400)
    }

    static Init(mainInstance) {
        Trace("6. PanelManager.Init Start Hwnd: " mainInstance.wpfHwnd)
        this.MainInstance := mainInstance
        this.MainWindow := mainInstance.wpfHwnd

        SetTimer(ObjBindMethod(this, "Magnetize"), 30)
        SetTimer(ObjBindMethod(this, "UpdateGlobalSnappedState"), 200)
        SetTimer(ObjBindMethod(this, "Watchdog"), 250)

        ; Show panels that were open last time
        Trace("7. PanelManager.Init before ShowPanel loop")
        for id, p in this.Panels {
            if (this.GetSavedState(id, "Visible", "0") == "1") {
                this.ShowPanel(id)
            }
        }
        Trace("7b. PanelManager.Init end")
    }

    static RegisterPanel(id, title, defaultX, defaultY, defaultW, defaultH) {
        this.Panels[id] := {
            Title: title,
            X: defaultX, Y: defaultY, W: defaultW, H: defaultH,
            Instance: "",
            GuiHwnd: 0,
            Snapped: this.GetSavedState(id, "Snapped", "0") == "1"
        }
    }

    static GetSavedState(id, key, defaultVal := "") {
        return IniRead(INI_FILE, id, key, defaultVal)
    }

    static SaveState(id, key, val) {
        IniWrite(val, INI_FILE, id, key)
    }

    static Magnetize() {
        static wasDown := false
        isDown := GetKeyState("LButton", "P")

        if (!isDown) {
            if (wasDown && this.HasProp("dragStates") && this.dragStates.Has("LastActive")) {
                ; The mouse was just released. Apply the final snapped state after DragMove completes.
                lastId := this.dragStates["LastActive"]
                if (this.dragStates.Has(lastId)) {
                    finalX := this.dragStates[lastId].x
                    finalY := this.dragStates[lastId].y
                    finalW := this.dragStates[lastId].w
                    finalH := this.dragStates[lastId].h
                    hwnd := lastId == "Main" ? this.MainWindow : this.Panels[lastId].GuiHwnd

                    if (hwnd) {
                        ; Delayed lock to override WPF DragMove
                        SetTimer(WinMove.Bind(finalX, finalY, finalW, finalH, "ahk_id " hwnd), -50)
                    }
                }
                this.dragStates := Map()
                wasDown := false
            }
            return
        }
        wasDown := true

        activeHwnd := WinExist("A")
        if !activeHwnd
            return

        isOurs := false
        activeId := ""
        if (activeHwnd == this.MainWindow) {
            isOurs := true
            activeId := "Main"
        } else {
            for id, pInfo in this.Panels {
                if (pInfo.GuiHwnd == activeHwnd) {
                    isOurs := true
                    activeId := id
                    break
                }
            }
        }

        if (!isOurs)
            return

        WinGetPos(&aX, &aY, &aW, &aH, "ahk_id " activeHwnd)
        if (aX < -10000 || aY < -10000)
            return

        if (!this.HasProp("dragStates"))
            this.dragStates := Map()

        if (!this.dragStates.Has(activeId)) {
            this.dragStates[activeId] := { x: aX, y: aY, w: aW, h: aH }
            return
        }

        lastX := this.dragStates[activeId].x
        lastY := this.dragStates[activeId].y
        lastW := this.dragStates[activeId].w
        lastH := this.dragStates[activeId].h

        dx := aX - lastX
        dy := aY - lastY
        dw := aW - lastW
        dh := aH - lastH

        if (dx == 0 && dy == 0 && dw == 0 && dh == 0)
            return

        this.dragStates[activeId] := { x: aX, y: aY, w: aW, h: aH }

        rects := []
        if (activeId != "Main" && WinExist("ahk_id " this.MainWindow)) {
            WinGetPos(&x, &y, &w, &h, "ahk_id " this.MainWindow)
            if (x > -10000)
                rects.Push({ x: x, y: y, w: w, h: h, hwnd: this.MainWindow })
        }
        for id, pInfo in this.Panels {
            if (activeId != id && pInfo.GuiHwnd && WinExist("ahk_id " pInfo.GuiHwnd)) {
                WinGetPos(&x, &y, &w, &h, "ahk_id " pInfo.GuiHwnd)
                if (x > -10000)
                    rects.Push({ x: x, y: y, w: w, h: h, hwnd: pInfo.GuiHwnd })
            }
        }

        threshold := 30
        snappedX := aX
        snappedY := aY
        snappedW := aW
        snappedH := aH

        isMoving := (dx != 0 || dy != 0) && (dw == 0 && dh == 0)
        isResizingRight := (dw != 0 && dx == 0)
        isResizingLeft := (dw != 0 && dx != 0)
        isResizingBottom := (dh != 0 && dy == 0)
        isResizingTop := (dh != 0 && dy != 0)

        for r in rects {
            vOverlap := (aY < r.y + r.h) && (aY + aH > r.y)
            hOverlap := (aX < r.x + r.w) && (aX + aW > r.x)

            if (isMoving) {
                if (vOverlap) {
                    if (Abs(aX - (r.x + r.w)) < threshold)
                        snappedX := r.x + r.w
                    else if (Abs((aX + aW) - r.x) < threshold)
                        snappedX := r.x - aW
                    else if (Abs(aX - r.x) < threshold)
                        snappedX := r.x
                    else if (Abs((aX + aW) - (r.x + r.w)) < threshold)
                        snappedX := r.x + r.w - aW
                }

                if (hOverlap) {
                    if (Abs(aY - (r.y + r.h)) < threshold)
                        snappedY := r.y + r.h
                    else if (Abs((aY + aH) - r.y) < threshold)
                        snappedY := r.y - aH
                    else if (Abs(aY - r.y) < threshold)
                        snappedY := r.y
                    else if (Abs((aY + aH) - (r.y + r.h)) < threshold)
                        snappedY := r.y + r.h - aH
                }
            } else {
                ; Resizing
                if (vOverlap) {
                    if (isResizingRight && Abs((aX + aW) - r.x) < threshold) {
                        snappedW := r.x - aX
                    } else if (isResizingRight && Abs((aX + aW) - (r.x + r.w)) < threshold) {
                        snappedW := r.x + r.w - aX
                    } else if (isResizingLeft && Abs(aX - (r.x + r.w)) < threshold) {
                        snappedX := r.x + r.w
                        snappedW := aW + (aX - snappedX)
                    } else if (isResizingLeft && Abs(aX - r.x) < threshold) {
                        snappedX := r.x
                        snappedW := aW + (aX - snappedX)
                    }
                }

                if (hOverlap) {
                    if (isResizingBottom && Abs((aY + aH) - r.y) < threshold) {
                        snappedH := r.y - aY
                    } else if (isResizingBottom && Abs((aY + aH) - (r.y + r.h)) < threshold) {
                        snappedH := r.y + r.h - aY
                    } else if (isResizingTop && Abs(aY - (r.y + r.h)) < threshold) {
                        snappedY := r.y + r.h
                        snappedH := aH + (aY - snappedY)
                    } else if (isResizingTop && Abs(aY - r.y) < threshold) {
                        snappedY := r.y
                        snappedH := aH + (aY - snappedY)
                    }
                }
            }
        }

        if (isMoving && (snappedX != aX || snappedY != aY)) {
            WinMove(snappedX, snappedY, , , "ahk_id " activeHwnd)
            this.dragStates[activeId].x := snappedX
            this.dragStates[activeId].y := snappedY
        } else if (!isMoving && (snappedX != aX || snappedY != aY || snappedW != aW || snappedH != aH)) {
            WinMove(snappedX, snappedY, snappedW, snappedH, "ahk_id " activeHwnd)
            this.dragStates[activeId].x := snappedX
            this.dragStates[activeId].y := snappedY
            this.dragStates[activeId].w := snappedW
            this.dragStates[activeId].h := snappedH
        }

        this.dragStates["LastActive"] := activeId
    }

    static AutoFillSpace(id) {
        if (id == "Main") {
            hwnd := this.MainWindow
        } else {
            if (!this.Panels.Has(id) || !this.Panels[id].GuiHwnd)
                return
            hwnd := this.Panels[id].GuiHwnd
        }

        if (!hwnd)
            return
        WinGetPos(&aX, &aY, &aW, &aH, "ahk_id " hwnd)

        rects := []
        if (id != "Main" && WinExist("ahk_id " this.MainWindow)) {
            WinGetPos(&x, &y, &w, &h, "ahk_id " this.MainWindow)
            rects.Push({ x: x, y: y, w: w, h: h })
        }
        for otherId, pInfo in this.Panels {
            if (otherId != id && pInfo.GuiHwnd && WinExist("ahk_id " pInfo.GuiHwnd)) {
                WinGetPos(&x, &y, &w, &h, "ahk_id " pInfo.GuiHwnd)
                rects.Push({ x: x, y: y, w: w, h: h })
            }
        }

        MonitorGetWorkArea(1, &mLeft, &mTop, &mRight, &mBottom)

        newLeft := mLeft
        newRight := mRight
        newTop := mTop
        newBottom := mBottom

        for r in rects {
            if (r.x + r.w <= aX && r.y < aY + aH && r.y + r.h > aY) {
                if (r.x + r.w > newLeft)
                    newLeft := r.x + r.w
            }
            if (r.x >= aX + aW && r.y < aY + aH && r.y + r.h > aY) {
                if (r.x < newRight)
                    newRight := r.x
            }
            if (r.y + r.h <= aY && r.x < aX + aW && r.x + r.w > aX) {
                if (r.y + r.h > newTop)
                    newTop := r.y + r.h
            }
            if (r.y >= aY + aH && r.x < aX + aW && r.x + r.w > aX) {
                if (r.y < newBottom)
                    newBottom := r.y
            }
        }

        WinMove(newLeft, newTop, newRight - newLeft, newBottom - newTop, "ahk_id " hwnd)
    }

    static UpdateGlobalSnappedState() {
        allRects := []
        if (WinExist("ahk_id " this.MainWindow)) {
            WinGetPos(&x, &y, &w, &h, "ahk_id " this.MainWindow)
            if (x > -10000)
                allRects.Push({ x: x, y: y, w: w, h: h, id: "Main" })
        }
        for id, pInfo in this.Panels {
            if (pInfo.GuiHwnd && WinExist("ahk_id " pInfo.GuiHwnd)) {
                WinGetPos(&x, &y, &w, &h, "ahk_id " pInfo.GuiHwnd)
                if (x > -10000)
                    allRects.Push({ x: x, y: y, w: w, h: h, id: id })
            }
        }

        for id, pInfo in this.Panels {
            if (!pInfo.GuiHwnd || !WinExist("ahk_id " pInfo.GuiHwnd))
                continue

            WinGetPos(&px, &py, &pw, &ph, "ahk_id " pInfo.GuiHwnd)
            if (px < -10000)
                continue

            isSnapped := false
            for r in allRects {
                if (r.id == id)
                    continue

                hOverlap := (px < r.x + r.w) && (px + pw > r.x)
                vOverlap := (py < r.y + r.h) && (py + ph > r.y)

                if (vOverlap && (Abs(px - (r.x + r.w)) <= 5 || Abs((px + pw) - r.x) <= 5 || Abs(px - r.x) <= 5 || Abs((px + pw) - (r.x + r.w)) <= 5)) {
                    isSnapped := true
                    break
                }
                if (hOverlap && (Abs(py - (r.y + r.h)) <= 5 || Abs((py + ph) - r.y) <= 5 || Abs(py - r.y) <= 5 || Abs((py + ph) - (r.y + r.h)) <= 5)) {
                    isSnapped := true
                    break
                }
            }

            if (pInfo.Snapped != isSnapped) {
                pInfo.Snapped := isSnapped
                this.SaveState(id, "Snapped", isSnapped ? "1" : "0")

                radius := isSnapped ? "0" : IniRead(INI_FILE, "Global", "PanelRadius", "0")
                if (pInfo.GuiHwnd) {
                    cornerPref := Buffer(4)
                    NumPut("Int", radius == "0" ? 1 : 0, cornerPref)
                    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", pInfo.GuiHwnd, "UInt", 33, "Ptr", cornerPref.Ptr, "UInt", 4)
                }
                pInfo.Instance.Update("Resource", "PanelRadius", "CornerRadius:" radius)
            }
        }
    }

    static ShowPanel(id) {
        if (this.Panels[id].Instance != "") {
            ; Already open, just bring to front
            WinActivate("ahk_id " this.Panels[id].GuiHwnd)
            return
        }

        pInfo := this.Panels[id]

        ; Load saved bounds
        w := this.GetSavedState(id, "W", pInfo.W)
        h := this.GetSavedState(id, "H", pInfo.H)
        x := this.GetSavedState(id, "X", pInfo.X)
        y := this.GetSavedState(id, "Y", pInfo.Y)

        ; Layout configuration
        thinMode := this.GetSavedState("Global", "ThinTitlebars", "0") == "1"
        titleHeight := thinMode ? "28" : "40"
        titleFont := thinMode ? "10" : "12"
        btnWidth := thinMode ? "35" : "45"

        ; Build the panel UI with theme support
        main := XAML_Generator("Grid").Background("{DynamicResource BgColor}")
        savedScale := IniRead(INI_FILE, "Global", "Scale", "Balanced")
        scaleVal := "1.0"
        if (savedScale == "Thin")
            scaleVal := "0.9"
        else if (savedScale == "Chunky") scaleVal := "1.15"
        main.Add("Grid.LayoutTransform").Add("ScaleTransform").SetProp("x:Name", "AppScale").ScaleX(scaleVal).ScaleY(scaleVal)
        main.Rows(titleHeight, "*")

        ; Titlebar (Must be a Border for XAML_Host DragArea logic)
        tb := main.Add("Border").Grid_Row(0).Background("Transparent").Name("DragArea")
        tbInner := tb.Add("Grid")
        tbInner.Add("TextBlock").Text(pInfo.Title).Foreground("{DynamicResource TextMain}").FontSize(titleFont).FontWeight("SemiBold").VerticalAlignment("Center").Margin("15,0,0,0")

        BtnGroup := tbInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right")

        BtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="{DynamicResource ControlBgHover}"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        CloseBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#E0FF3333"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'

        fillBtn := BtnGroup.Add("Button").Name("BtnFill").WindowChrome_IsHitTestVisibleInChrome("True").Width(btnWidth).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0)
    .On("Click", (state, ctrl, event) => this.AutoFillSpace(id))
        fillBtn.InjectResources(BtnTemplate)
        fillBtn.Add("TextBlock").Text(Chr(0xE922)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

        closeBtn := BtnGroup.Add("Button").Name("BtnClose").WindowChrome_IsHitTestVisibleInChrome("True").Width(btnWidth).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0)
        closeBtn.InjectResources(CloseBtnTemplate)
        closeBtn.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(10).VerticalAlignment("Center").HorizontalAlignment("Center")

        ; Body content based on panel type
        body := main.Add("Border").Grid_Row(1).Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,1,0,0")

        if (id == "Terminal") {
            body.Add("ListBox").Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextSub}").FontFamily("Consolas")
                .Add("ListBoxItem").Content("> System Initialized").Parent()
                .Add("ListBoxItem").Content("> Ready for commands...").Parent()
        } else if (id == "Properties") {
            sp := body.Add("StackPanel").Margin("15")
            sp.Add("TextBlock").Text("Name:").Foreground("{DynamicResource TextSub}").Margin("0,0,0,5")
            sp.Add("TextBox").Text("Element1").Margin("0,0,0,15")
            sp.Add("TextBlock").Text("Color:").Foreground("{DynamicResource TextSub}").Margin("0,0,0,5")
            sp.Add("TextBox").Text("#FF0000").Margin("0,0,0,15")
            sp.Add("CheckBox").Content("Is Visible").Foreground("{DynamicResource TextMain}").IsChecked("True")
        } else if (id == "Toolbox") {
            tv := body.Add("TreeView").Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextMain}").Margin("5")
            n1 := tv.Add("TreeViewItem").Header("Controls").IsExpanded("True")
            n1.Add("TreeViewItem").Header("Button")
            n1.Add("TreeViewItem").Header("TextBox")
            n1.Add("TreeViewItem").Header("CheckBox")
            n2 := tv.Add("TreeViewItem").Header("Layout").IsExpanded("True")
            n2.Add("TreeViewItem").Header("Grid")
            n2.Add("TreeViewItem").Header("StackPanel")
        }

        ; Initialize XAML Host for this panel (No owner at creation to allow fully dynamic ownership via Win32)
        tmp := StrReplace(XAML_TEMPLATE, "%CaptionHeight%", titleHeight)
        Trace("8. Creating XAMLHost for panel: " id)
        ui := XAMLHost(StrReplace(tmp, "%app%", main.ToString()), "", "")
        Trace("8b. Created XAMLHost for panel: " id)

        showInTaskbar := IniRead(INI_FILE, "Global", "ShowInTaskbar", "0") == "1"
        initShowInTaskbar := showInTaskbar ? "True" : "False"

        ; Replace template dimensions, add title/taskbar visibility, remove CenterScreen, and use dynamic PanelRadius
        ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Title="' pInfo.Title '" ShowInTaskbar="' initShowInTaskbar '" Width="' w '" Height="' h '" Left="' x '" Top="' y '"')
        ui.xaml := StrReplace(ui.xaml, 'WindowStartupLocation="CenterScreen"', 'WindowStartupLocation="Manual"')
        ui.xaml := StrReplace(ui.xaml, 'CornerRadius="{DynamicResource WindowRadius}"', 'CornerRadius="{DynamicResource PanelRadius}"')
        initialRadius := pInfo.Snapped ? "0" : IniRead(INI_FILE, "Global", "PanelRadius", "0")
        ; Inject initial theme resources to prevent load flickering
        pTheme := IniRead(INI_FILE, id, "Theme", "Inherit")
        resolvedTheme := (pTheme == "Inherit") ? this.CurrentTheme : pTheme
        iniPath := FindThemesIni()
        themeData := ""
        try themeData := IniRead(iniPath, resolvedTheme)
        
        resourceInject := '<CornerRadius x:Key="PanelRadius">' initialRadius '</CornerRadius>'
        if (themeData != "") {
            Loop Parse, themeData, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=", " `t", 2)
                if (parts.Length == 2 && InStr(parts[1], "Resource_") == 1) {
                    key := SubStr(parts[1], 10)
                    val := parts[2]
                    if (InStr(val, "#") == 1) {
                        resourceInject .= '<SolidColorBrush x:Key="' key '" Color="' val '"/>'
                    }
                }
            }
        }
        ui.xaml := StrReplace(ui.xaml, '%resources%', resourceInject)

        noShadows := this.GetSavedState("Global", "NoShadows", "0") == "1"
        if (noShadows) {
            ui.xaml := StrReplace(ui.xaml, 'GlassFrameThickness="-1"', 'GlassFrameThickness="0" ResizeBorderThickness="6"')
        }

        ; Callbacks
        ui.OnEvent("Window", "LoadedHwnd", (state, ctrl, event) => this.OnPanelLoaded(id, ui))
        ui.OnEvent("Window", "Closing", (state, ctrl, event) => this.OnPanelClosing(id))

        Trace("8c. Showing panel: " id)
        ui.Show()
        Trace("8d. Panel shown: " id)

        this.Panels[id].Instance := ui
        this.SaveState(id, "Visible", "1")
    }

    static ApplyThemeToPanel(pInfo, themeName) {
        panelId := ""
        for id, p in this.Panels {
            if (p == pInfo) {
                panelId := id
                break
            }
        }
        pTheme := "Inherit"
        if (panelId != "") {
            pTheme := IniRead(INI_FILE, panelId, "Theme", "Inherit")
        }
        resolvedTheme := (pTheme == "Inherit") ? themeName : pTheme

        if (pInfo.Instance == "" || !pInfo.Instance.wpfHwnd)
            return

        try {
            ; Build all theme updates into a single batch for atomic IPC delivery
            updates := []

            iniPath := FindThemesIni()
            themeData := IniRead(iniPath, resolvedTheme)
            Loop Parse, themeData, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=", " `t", 2)
                if (parts.Length == 2) {
                    key := parts[1]
                    val := parts[2]
                    if (key == "Window_DWM")
                        updates.Push({ ControlName: "Window", PropertyName: "DWM", Value: val })
                    else if (InStr(key, "Resource_") == 1)
                        updates.Push({ ControlName: "Resource", PropertyName: SubStr(key, 10), Value: val })
                }
            }

            ; Append PanelRadius to the same batch
            radius := pInfo.Snapped ? "0" : IniRead(INI_FILE, "Global", "PanelRadius", "0")
            updates.Push({ ControlName: "Resource", PropertyName: "PanelRadius", Value: "CornerRadius:" radius })

            ; Send everything in one atomic IPC message
            if (updates.Length > 0)
                pInfo.Instance.BatchUpdate(updates)

            ; Only mark as applied AFTER the BatchUpdate succeeds
            pInfo.LastThemeApplied := resolvedTheme
        } catch as err {
            pInfo.LastThemeApplied := ""
            Trace("ApplyThemeToPanel failed for " (pInfo.HasProp("Title") ? pInfo.Title : "?") ": " err.Message)
        }

        ; DWM corner preference via Win32 API
        radius := pInfo.Snapped ? "0" : IniRead(INI_FILE, "Global", "PanelRadius", "0")
        if (pInfo.GuiHwnd) {
            cornerPref := Buffer(4)
            NumPut("Int", radius == "0" ? 1 : 0, cornerPref)
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", pInfo.GuiHwnd, "UInt", 33, "Ptr", cornerPref.Ptr, "UInt", 4)
        }
    }

    static UpdateTheme(themeName) {
        this.CurrentTheme := themeName
        for id, pInfo in this.Panels {
            this.ApplyThemeToPanel(pInfo, themeName)
        }
    }

    static UpdateRadius(radius) {
        for id, pInfo in this.Panels {
            if (pInfo.Instance != "" && pInfo.GuiHwnd) {
                effectiveRadius := pInfo.Snapped ? "0" : radius
                pInfo.Instance.Update("Resource", "PanelRadius", "CornerRadius:" effectiveRadius)
                cornerPref := Buffer(4)
                NumPut("Int", effectiveRadius == "0" ? 1 : 0, cornerPref)
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", pInfo.GuiHwnd, "UInt", 33, "Ptr", cornerPref.Ptr, "UInt", 4)
            }
        }
    }

    static UpdateScale(scale) {
        scaleVal := "1.0"
        if (scale == "Thin")
            scaleVal := "0.9"
        else if (scale == "Chunky") scaleVal := "1.15"

        for id, pInfo in this.Panels {
            if (pInfo.Instance != "" && pInfo.GuiHwnd) {
                try {
                    pInfo.Instance.Update("AppScale", "ScaleX", scaleVal)
                    pInfo.Instance.Update("AppScale", "ScaleY", scaleVal)
                }
            }
        }
    }

    static UpdateShadows(enabled) {
        valStr := enabled ? "-1" : "0"
        if (this.MainInstance) {
            try this.MainInstance.Update("Window", "GlassFrameThickness", valStr)
        }
        for id, pInfo in this.Panels {
            if (pInfo.Instance != "" && pInfo.GuiHwnd) {
                try pInfo.Instance.Update("Window", "GlassFrameThickness", valStr)
            }
        }
    }

    static ApplyPanelVisibility(id) {
        pInfo := this.Panels[id]
        if (pInfo.Instance == "" || !pInfo.GuiHwnd)
            return

        showInAltTab := IniRead(INI_FILE, "Global", "ShowInAltTab", "0") == "1"
        showInTaskbar := IniRead(INI_FILE, "Global", "ShowInTaskbar", "0") == "1"

        try {
            valStr := (showInAltTab ? "1" : "0") "," (showInTaskbar ? "1" : "0")
            pInfo.Instance.Update("Window", "ApplyVisibilityStyles", valStr)
        }
    }

    static ApplyVisibilityStyles() {
        for id, pInfo in this.Panels {
            if (pInfo.Instance != "" && pInfo.GuiHwnd) {
                this.ApplyPanelVisibility(id)
            }
        }
    }

    static OnPanelLoaded(id, ui) {
        Trace("OnPanelLoaded Start for: " id)
        try {
            ; Ensure instance and HWND are immediately populated for ApplyThemeToPanel calls
            this.Panels[id].Instance := ui
            this.Panels[id].GuiHwnd := ui.wpfHwnd

            ; Set native owner to prevent orphaned panels
            showInAltTab := IniRead(INI_FILE, "Global", "ShowInAltTab", "0") == "1"
            expectedOwner := showInAltTab ? 0 : this.MainWindow
            try ui.Update("Window", "NativeOwner", String(expectedOwner))

            ; Robustly inherit parent window icon
            try {
                hIcon := DllCall("user32\SendMessage", "Ptr", this.MainWindow, "UInt", 0x007F, "Ptr", 1, "Ptr", 0, "Ptr") ; WM_GETICON (ICON_BIG)
                if (!hIcon)
                    hIcon := DllCall("user32\SendMessage", "Ptr", this.MainWindow, "UInt", 0x007F, "Ptr", 0, "Ptr", 0, "Ptr") ; WM_GETICON (ICON_SMALL)
                if (!hIcon) {
                    if (A_PtrSize == 8)
                        hIcon := DllCall("user32\GetClassLongPtr", "Ptr", this.MainWindow, "Int", -14, "Ptr") ; GCLP_HICON
                    else
                        hIcon := DllCall("user32\GetClassLong", "Ptr", this.MainWindow, "Int", -14, "Ptr")
                }
                if (hIcon)
                    ui.Update("Window", "Icon", "HICON:" hIcon)
            } catch as errIcon {
                Trace("Icon inheritance failed for " id ": " errIcon.Message)
            }

            ; Robustly set title
            try {
                ui.Update("Window", "Title", this.Panels[id].Title)
            } catch as errTitle {
                Trace("Title set failed for " id ": " errTitle.Message)
            }

            ; Apply shadows
            try {
                noShadows := IniRead(INI_FILE, "Global", "NoShadows", "0") == "1"
                valStr := noShadows ? "0" : "-1"
                ui.Update("Window", "GlassFrameThickness", valStr)
            } catch as errShadows {
                Trace("Shadows update failed for " id ": " errShadows.Message)
            }

            ; Apply dynamic visibility styles (Alt-Tab style & frame change)
            try {
                this.ApplyPanelVisibility(id)
            } catch as errVis {
                Trace("Visibility styles failed for " id ": " errVis.Message)
            }

            try {
                this.ApplyThemeToPanel(this.Panels[id], this.CurrentTheme)
            } catch as errTheme {
                Trace("ApplyThemeToPanel failed for " id ": " errTheme.Message)
            }

            try {
                UpdateBackdropEffects()
            } catch as errBackdrop {
                Trace("Apply backdrop effects failed for " id ": " errBackdrop.Message)
            }

            ; Hook the exit size move to save coordinates
            SetTimer(ObjBindMethod(this, "CheckPanelMoved", id), 1000)
            Trace("OnPanelLoaded End for: " id " successfully finished")
        } catch as errOuter {
            Trace("OnPanelLoaded CRITICAL ERROR for " id ": " errOuter.Message " at line " errOuter.Line)
        }
    }

    static CheckPanelMoved(id) {
        if (!this.Panels.Has(id) || this.Panels[id].Instance == "")
            return

        hwnd := this.Panels[id].GuiHwnd
        if (hwnd && WinExist("ahk_id " hwnd)) {
            WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
            if (x != this.Panels[id].X || y != this.Panels[id].Y || w != this.Panels[id].W || h != this.Panels[id].H) {
                this.Panels[id].X := x
                this.Panels[id].Y := y
                this.Panels[id].W := w
                this.Panels[id].H := h
                this.SaveState(id, "X", x)
                this.SaveState(id, "Y", y)
                this.SaveState(id, "W", w)
                this.SaveState(id, "H", h)
            }
        }
    }

    static Watchdog() {
        global INI_FILE, isAppReady
        if (!isAppReady || !this.MainWindow || !WinExist("ahk_id " this.MainWindow))
            return

        showInAltTab := IniRead(INI_FILE, "Global", "ShowInAltTab", "0") == "1"
        expectedOwner := showInAltTab ? 0 : this.MainWindow

        for id, pInfo in this.Panels {
            if (pInfo.Instance != "") {
                ; 1. Sync HWND if it was 0 or changed
                if (!pInfo.GuiHwnd && pInfo.Instance.wpfHwnd) {
                    pInfo.GuiHwnd := pInfo.Instance.wpfHwnd
                }
                
                if (pInfo.GuiHwnd && WinExist("ahk_id " pInfo.GuiHwnd)) {
                    ; 2. Verify and enforce Native Owner connection
                    try {
                        currentOwner := DllCall("user32\GetWindow", "Ptr", pInfo.GuiHwnd, "UInt", 4, "Ptr") ; GW_OWNER = 4
                        if (currentOwner != expectedOwner) {
                            Trace("Watchdog: Reconnecting panel " id " (current owner: " currentOwner ", expected: " expectedOwner ")")
                            pInfo.Instance.Update("Window", "NativeOwner", String(expectedOwner))
                            this.ApplyPanelVisibility(id)
                        }
                    } catch {
                    }
                    
                    ; 3. Enforce theme consistency (lightweight safety net)
                    pTheme := IniRead(INI_FILE, id, "Theme", "Inherit")
                    resolvedTheme := (pTheme == "Inherit") ? this.CurrentTheme : pTheme

                    if (!pInfo.HasProp("LastThemeApplied") || pInfo.LastThemeApplied != resolvedTheme) {
                        Trace("Watchdog: Syncing theme for panel " id " to " resolvedTheme)
                        this.ApplyThemeToPanel(pInfo, this.CurrentTheme)
                    }
                }
            }
        }
    }

    static OnPanelClosing(id) {
        this.Panels[id].Instance := ""
        this.Panels[id].GuiHwnd := 0
        this.SaveState(id, "Visible", "0")
    }
}


; --- Main Application ---
app := XAML_GUI("IDE Docking Manager Example", { Sidebar: true, BurgerMenu: true, TitleBarHeight: 28, AppIcon: true })

; Load saved settings
savedRadius := IniRead(INI_FILE, "Global", "PanelRadius", "0")
savedShowInAltTab := IniRead(INI_FILE, "Global", "ShowInAltTab", "0")
savedShowInTaskbar := IniRead(INI_FILE, "Global", "ShowInTaskbar", "0")
savedNoShadows := IniRead(INI_FILE, "Global", "NoShadows", "0")
savedTransparency := IniRead(INI_FILE, "Global", "Transparency", "1")
savedBackdrop := IniRead(INI_FILE, "Global", "Backdrop", "Mica")

; Add settings directly to sidebar
app.sidebarPanel.Add("TextBlock").Text("WINDOW OPTIONS").Margin("0,15,0,5")

app.sidebarPanel.Add("TextBlock").Text("Panel Visibility:").Foreground("{DynamicResource TextSub}").Margin("0,5,0,2")
cbVisibility := app.sidebarPanel.Add("ComboBox").Name("ComboVisibility").Height(30).Margin("0,0,0,10")
    .On("SelectionChanged", (state, ctrl, event) => OnVisibilityChanged(state))
    .Track()
cbVisibility.Add("ComboBoxItem").Content("Hidden in taskbar & alt tab")
cbVisibility.Add("ComboBoxItem").Content("Taskbar + Alt Tab")
cbVisibility.Add("ComboBoxItem").Content("ONLY Alt tab")

chkShadows := app.sidebarPanel.Add("CheckBox").Name("ChkEnableShadows").Content("Enable window shadows").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")
    .On("Click", (state, ctrl, event) => OnShadowsToggle(state))
    .Track()

app.sidebarPanel.Add("TextBlock").Text("TRANSPARENCY & BLUR").Margin("0,15,0,5")
chkTrans := app.sidebarPanel.Add("CheckBox").Name("ChkTransparency").Content("Transparency effects").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")
    .On("Click", (state, ctrl, event) => OnTransparencyToggle(state))
    .Track()
app.sidebarPanel.Add("TextBlock").Text("Material Blur Effect:").Foreground("{DynamicResource TextSub}").Margin("0,5,0,2")
cbBlur := app.sidebarPanel.Add("ComboBox").Name("ComboBlurEffect").Height(30).Margin("0,0,0,10")
    .On("SelectionChanged", (state, ctrl, event) => OnBlurEffectChanged(state))
    .Track()
cbBlur.Add("ComboBoxItem").Content("Mica (High Fidelity)")
cbBlur.Add("ComboBoxItem").Content("Acrylic (Frosted Glass)")
cbBlur.Add("ComboBoxItem").Content("Aero (Classic Glass)")

initVisIdx := 0
if (savedShowInAltTab == "1" && savedShowInTaskbar == "1") {
    initVisIdx := 1
} else if (savedShowInAltTab == "1" && savedShowInTaskbar == "0") {
    initVisIdx := 2
} else {
    initVisIdx := 0
}
cbVisibility.SelectedIndex(initVisIdx)

chkShadows.IsChecked(savedNoShadows == "0" ? "True" : "False")
chkTrans.IsChecked(savedTransparency == "1" ? "True" : "False")
initBlurIdx := savedBackdrop == "Acrylic" ? 1 : (savedBackdrop == "Aero" ? 2 : 0)
cbBlur.SelectedIndex(initBlurIdx)

app.sidebarPanel.Add("TextBlock").Text("PANEL THEMES").Margin("0,15,0,5")
for id, pInfo in PanelManager.Panels {
    app.sidebarPanel.Add("TextBlock").Text(pInfo.Title ":").Foreground("{DynamicResource TextSub}").Margin("0,5,0,2")
    cb := app.sidebarPanel.Add("ComboBox").Name("ComboTheme_" id).Height(30).Margin("0,0,0,10")
    cb.Add("ComboBoxItem").Content("Inherit")
    try {
        iniPath := FindThemesIni()
        Loop Parse, IniRead(iniPath), "`n", "`r" {
            cb.Add("ComboBoxItem").Content(A_LoopField)
        }
    } catch {
    }
    cb.SelectedIndex(0)
}

contentPanel := app.main.Add("StackPanel").Grid_Row(1).Margin("40")

contentPanel.Add("TextBlock").Text("IDE WORKBENCH").Foreground("{DynamicResource TextMain}").FontSize(24).FontWeight("Bold").Margin("0,0,0,5")
contentPanel.Add("TextBlock").Text("Use the buttons below to tear off and spawn floating tool panels. Their state will be remembered.").Foreground("{DynamicResource TextSub}").Margin("0,0,0,30").TextWrapping("Wrap")

btnSp := contentPanel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,30")
btnSp.Add("Button").Name("BtnOpenTerminal").Content("Toggle Terminal").Margin("0,0,10,0")
    .On("Click", (*) => PanelManager.ShowPanel("Terminal"))
btnSp.Add("Button").Name("BtnOpenProperties").Content("Toggle Properties").Margin("0,0,10,0")
    .On("Click", (*) => PanelManager.ShowPanel("Properties"))
btnSp.Add("Button").Name("BtnOpenToolbox").Content("Toggle Toolbox")
    .On("Click", (*) => PanelManager.ShowPanel("Toolbox"))

ui := app.Compile()
for id, pInfo in PanelManager.Panels {
    ui.Track("ComboTheme_" id)
}
ui.xaml := StrReplace(ui.xaml, 'Name="BtnMaximize"', 'Name="BtnAppMaximize"')

; Restore Main Window Position
mainX := IniRead("docking_layout.ini", "MainWindow", "X", "")
mainY := IniRead("docking_layout.ini", "MainWindow", "Y", "")
mainW := IniRead("docking_layout.ini", "MainWindow", "W", "940")
mainH := IniRead("docking_layout.ini", "MainWindow", "H", "700")

if (mainX != "" && mainY != "") {
    ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Width="' mainW '" Height="' mainH '" Left="' mainX '" Top="' mainY '"')
    ui.xaml := StrReplace(ui.xaml, 'WindowStartupLocation="CenterScreen"', 'WindowStartupLocation="Manual"')
}
if (IniRead("docking_layout.ini", "Global", "NoShadows", "0") == "1") {
    ui.xaml := StrReplace(ui.xaml, 'GlassFrameThickness="-1"', 'GlassFrameThickness="0" ResizeBorderThickness="6"')
}
ui.OnEvent("Window", "LoadedHwnd", (state, ctrl, event) => OnMainLoaded())
ui.OnEvent("BtnAppMaximize", "Click", (*) => PanelManager.AutoFillSpace("Main"))
ui.OnEvent("ComboTheme", "SelectionChanged", (state, ctrl, event) => (
    OnThemeEngineChanged(state["ComboTheme"])
))
for id, pInfo in PanelManager.Panels {
    ui.OnEvent("ComboTheme_" id, "SelectionChanged", OnPanelThemeChanged.Bind(id))
}
ui.OnEvent("ComboScale", "SelectionChanged", (state, ctrl, event) => (
    app.ScaleChanged(state, ctrl, event),
    IniWrite(state["ComboScale"], INI_FILE, "Global", "Scale"),
    PanelManager.UpdateScale(state["ComboScale"])
))
ui.OnEvent("ComboRadius", "SelectionChanged", (state, ctrl, event) => OnRadiusChanged(state))
ui.OnEvent("Window", "Closing", (*) => OnMainClosing())

app.Show()

OnMainLoaded() {
    global INI_FILE, isAppReady
    savedTheme := IniRead(INI_FILE, "Global", "Theme", "Dark Mica (Win 11)")
    PanelManager.CurrentTheme := savedTheme
    savedScale := IniRead(INI_FILE, "Global", "Scale", "Balanced")
    savedRadius := IniRead(INI_FILE, "Global", "PanelRadius", "0")

    radiusIdx := 0
    switch savedRadius {
        case "0": radiusIdx := 0
        case "4": radiusIdx := 1
        case "8": radiusIdx := 2
        case "12": radiusIdx := 3
        case "16": radiusIdx := 4
        default: radiusIdx := 2
    }

    themeIdx := 0
    try {
        iniPath := FindThemesIni()
        Loop Parse, IniRead(iniPath), "`n", "`r" {
            if (A_LoopField == savedTheme) {
                break
            }
            themeIdx++
        }
    } catch {
        themeIdx := 0
    }

    scaleIdx := savedScale == "Thin" ? 0 : (savedScale == "Balanced" ? 1 : 2)

    PanelManager.Init(ui)

    SetTimer(ApplyInitialSelections.Bind(radiusIdx, themeIdx, scaleIdx, savedRadius, savedTheme, savedScale), -50)
    SetTimer(CheckMainMoved, 1000)
}

ApplyInitialSelections(rIdx, tIdx, sIdx, savedRadius, savedTheme, savedScale) {
    global isAppReady, ui, app, isInitializing
    isAppReady := true
    try {
        ui.Update("ComboRadius", "SelectedIndex", String(rIdx))
    } catch {
    }
    try {
        ui.Update("ComboTheme", "SelectedIndex", String(tIdx))
    } catch {
    }
    try {
        ui.Update("ComboScale", "SelectedIndex", String(sIdx))
    } catch {
    }

    for id, pInfo in PanelManager.Panels {
        savedPTheme := IniRead(INI_FILE, id, "Theme", "Inherit")
        pThemeIdx := 0
        if (savedPTheme != "Inherit") {
            try {
                iniPath := FindThemesIni()
                idx := 1
                Loop Parse, IniRead(iniPath), "`n", "`r" {
                    if (A_LoopField == savedPTheme) {
                        pThemeIdx := idx
                        break
                    }
                    idx++
                }
            } catch {
                pThemeIdx := 0
            }
        }
        try {
            ui.Update("ComboTheme_" id, "SelectedIndex", String(pThemeIdx))
        } catch {
        }
    }

    ; Force-sync all loaded settings to main window and panels at startup,
    ; ensuring everything perfectly matches regardless of whether ComboBox SelectionChanged fired.
    Trace("ApplyInitialSelections: Force-syncing theme '" savedTheme "', scale '" savedScale "', radius '" savedRadius "' to all windows")
    try {
        app.ThemeChanged(Map("ComboTheme", savedTheme), "", "")
    } catch as eTheme {
        Trace("ApplyInitialSelections ThemeChanged failed: " eTheme.Message)
    }
    try {
        PanelManager.UpdateTheme(savedTheme)
    } catch as eThemePanels {
        Trace("ApplyInitialSelections UpdateTheme failed: " eThemePanels.Message)
    }

    try {
        app.ScaleChanged(Map("ComboScale", savedScale), "", "")
    } catch as eScale {
        Trace("ApplyInitialSelections ScaleChanged failed: " eScale.Message)
    }
    try {
        PanelManager.UpdateScale(savedScale)
    } catch as eScalePanels {
        Trace("ApplyInitialSelections UpdateScale failed: " eScalePanels.Message)
    }

    try {
        radStr := ""
        switch savedRadius {
            case "0": radStr := "Sharp (0)"
            case "4": radStr := "Rounded (4)"
            case "8": radStr := "Smooth (8)"
            case "12": radStr := "Extra Smooth (12)"
            case "16": radStr := "Fluid (16)"
            default: radStr := "Smooth (8)"
        }
        OnRadiusChanged(Map("ComboRadius", radStr))
    } catch as eRad {
        Trace("ApplyInitialSelections OnRadiusChanged failed: " eRad.Message)
    }

    try {
        UpdateBackdropEffects()
    } catch as eBackdrop {
        Trace("ApplyInitialSelections UpdateBackdropEffects failed: " eBackdrop.Message)
    }

    ; Done initializing!
    isInitializing := false
}

CheckMainMoved() {
    if (ui.wpfHwnd && WinExist("ahk_id " ui.wpfHwnd)) {
        WinGetPos(&x, &y, &w, &h, "ahk_id " ui.wpfHwnd)
        if (x < -10000 || y < -10000) ; Ignore minimized state
            return

        static lastX := "", lastY := "", lastW := "", lastH := ""
        if (x != lastX || y != lastY || w != lastW || h != lastH) {
            lastX := x, lastY := y, lastW := w, lastH := h
            IniWrite(x, "docking_layout.ini", "MainWindow", "X")
            IniWrite(y, "docking_layout.ini", "MainWindow", "Y")
            IniWrite(w, "docking_layout.ini", "MainWindow", "W")
            IniWrite(h, "docking_layout.ini", "MainWindow", "H")
        }
    }
}

OnThemeEngineChanged(themeName) {
    global INI_FILE, ui, app, isAppReady, isInitializing
    if (!isAppReady)
        return

    IniWrite(themeName, INI_FILE, "Global", "Theme")
    PanelManager.CurrentTheme := themeName
    
    iniPath := FindThemesIni()
    try {
        themeData := IniRead(iniPath, themeName)
    } catch {
        themeData := ""
    }
    
    ; 1. Parse Window_DWM to update Transparency & Blur Effect
    backdrop := "2" ; Default to Mica
    darkMode := "1" ; Default to Dark Mode
    
    if (themeData != "") {
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2 && parts[1] == "Window_DWM") {
                dwmParts := StrSplit(parts[2], ",")
                if (dwmParts.Length >= 2) {
                    backdrop := dwmParts[1]
                    darkMode := dwmParts[2]
                }
                break
            }
        }
    }
    
    ; Determine Transparency and Backdrop based on theme's Window_DWM
    transVal := (backdrop != "0") ? "1" : "0"
    blurVal := "Mica"
    if (backdrop == "3")
        blurVal := "Acrylic"
    else if (backdrop == "1")
        blurVal := "Aero"
        
    ; If NOT initializing, we update the saved settings and UI controls to match the theme defaults
    if (!isInitializing) {
        IniWrite(transVal, INI_FILE, "Global", "Transparency")
        IniWrite(blurVal, INI_FILE, "Global", "Backdrop")
        
        ; Update Sidebar UI controls programmatically
        if (ui.wpfHwnd) {
            try ui.Update("ChkTransparency", "IsChecked", (transVal == "1" ? "True" : "False"))
            blurIdx := (blurVal == "Acrylic" ? 1 : (blurVal == "Aero" ? 2 : 0))
            try ui.Update("ComboBlurEffect", "SelectedIndex", String(blurIdx))
        }
    }
    
    ; 2. Parse Resource_WindowRadius to update Border Radius
    radius := "12" ; Default from themes.ini
    if (themeData != "") {
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2 && parts[1] == "Resource_WindowRadius") {
                radiusVal := parts[2]
                if (InStr(radiusVal, "CornerRadius:") == 1) {
                    radius := SubStr(radiusVal, 14)
                }
                break
            }
        }
    }
    
    if (!isInitializing) {
        IniWrite(radius, INI_FILE, "Global", "PanelRadius")
        if (ui.wpfHwnd) {
            radIdx := 2 ; Default to Smooth (8)
            switch radius {
                case "0": radIdx := 0
                case "4": radIdx := 1
                case "8": radIdx := 2
                case "12": radIdx := 3
                case "16": radIdx := 4
            }
            try ui.Update("ComboRadius", "SelectedIndex", String(radIdx))
        }
    }
    
    ; Apply to main window radius and update panel radii
    try app.ThemeChanged(Map("ComboTheme", themeName), "", "")
    
    activeRadius := isInitializing ? IniRead(INI_FILE, "Global", "PanelRadius", "0") : radius
    
    radStr := ""
    switch activeRadius {
        case "0": radStr := "Sharp (0)"
        case "4": radStr := "Rounded (4)"
        case "8": radStr := "Smooth (8)"
        case "12": radStr := "Extra Smooth (12)"
        case "16": radStr := "Fluid (16)"
        default: radStr := "Smooth (8)"
    }
    try app.RadiusChanged(Map("ComboRadius", radStr), "", "")
    PanelManager.UpdateRadius(activeRadius)

    ; Apply shadows from docking_layout.ini (dynamic persistence)
    noShadows := IniRead(INI_FILE, "Global", "NoShadows", "0")
    PanelManager.UpdateShadows(noShadows == "0")
    
    ; Update theme on all panels
    PanelManager.UpdateTheme(themeName)
    
    ; Update backdrop effects (combines transparency, backdrop style, dark mode)
    UpdateBackdropEffects()
}

OnRadiusChanged(state) {
    global INI_FILE, isAppReady, app
    if (!isAppReady || !state.Has("ComboRadius"))
        return
    radText := state["ComboRadius"]
    RegExMatch(radText, "\((\d+)\)", &match)
    radius := match ? match[1] : "0"
    
    IniWrite(radius, INI_FILE, "Global", "PanelRadius")
    
    ; Apply to main window
    try app.RadiusChanged(state, "", "")
    
    ; Apply to panels
    PanelManager.UpdateRadius(radius)
}

OnPanelThemeChanged(id, state, ctrl, event) {
    global INI_FILE, isAppReady
    if (!isAppReady || !state.Has("ComboTheme_" id))
        return
    chosenTheme := state["ComboTheme_" id]
    IniWrite(chosenTheme, INI_FILE, id, "Theme")
    
    ; Apply theme to that specific panel
    if (PanelManager.Panels.Has(id)) {
        pInfo := PanelManager.Panels[id]
        PanelManager.ApplyThemeToPanel(pInfo, PanelManager.CurrentTheme)
    }
}

OnVisibilityChanged(state) {
    global INI_FILE, isAppReady
    if (!isAppReady)
        return
    
    selected := state["ComboVisibility"]
    
    showInAltTab := "0"
    showInTaskbar := "0"
    
    if (selected == "Taskbar + Alt Tab") {
        showInAltTab := "1"
        showInTaskbar := "1"
    } else if (selected == "ONLY Alt tab") {
        showInAltTab := "1"
        showInTaskbar := "0"
    } else {
        ; Hidden in taskbar & alt tab
        showInAltTab := "0"
        showInTaskbar := "0"
    }
    
    IniWrite(showInAltTab, INI_FILE, "Global", "ShowInAltTab")
    IniWrite(showInTaskbar, INI_FILE, "Global", "ShowInTaskbar")
    
    PanelManager.ApplyVisibilityStyles()
}
OnTransparencyToggle(state) {
    global INI_FILE, isAppReady
    if (!isAppReady)
        return
    val := state["ChkTransparency"] == "True" ? "1" : "0"
    IniWrite(val, INI_FILE, "Global", "Transparency")
    UpdateBackdropEffects()
}

OnBlurEffectChanged(state) {
    global INI_FILE, isAppReady
    if (!isAppReady || !state.Has("ComboBlurEffect"))
        return
    selected := state["ComboBlurEffect"]
    blur := selected == "Acrylic (Frosted Glass)" ? "Acrylic" : (selected == "Aero (Classic Glass)" ? "Aero" : "Mica")
    IniWrite(blur, INI_FILE, "Global", "Backdrop")
    UpdateBackdropEffects()
}

UpdateBackdropEffects() {
    global INI_FILE, ui
    trans := IniRead(INI_FILE, "Global", "Transparency", "1")
    blur := IniRead(INI_FILE, "Global", "Backdrop", "Mica")
    
    effectNum := 0
    if (trans == "1") {
        if (blur == "Mica")
            effectNum := 2
        else if (blur == "Acrylic")
            effectNum := 3
        else if (blur == "Aero")
            effectNum := 1
    }
    
    modeNum := InStr(PanelManager.CurrentTheme, "Light") || InStr(PanelManager.CurrentTheme, "Sakura") ? 0 : 1
    valStr := effectNum "," modeNum
    
    if (ui.wpfHwnd) {
        try ui.Update("Window", "DWM", valStr)
    }
    for id, pInfo in PanelManager.Panels {
        if (pInfo.Instance != "" && pInfo.GuiHwnd) {
            try pInfo.Instance.Update("Window", "DWM", valStr)
        }
    }
}


OnShadowsToggle(state) {
    global INI_FILE, isAppReady
    if (!isAppReady)
        return
    val := state["ChkEnableShadows"] == "True" ? "0" : "1"
    IniWrite(val, INI_FILE, "Global", "NoShadows")
    PanelManager.UpdateShadows(val == "0")
}

OnMainClosing() {
    for id, pInfo in PanelManager.Panels {
        if (pInfo.Instance != "") {
            try pInfo.Instance.Update("Window", "Close", "")
        }
    }
    ExitApp()
}