#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "..\lib\XAML_GUI.ahk"
#Include "..\lib\XAML_Generator.ahk"
#Include "..\lib\XAML_Host.ahk"
#Include "..\lib\XAML_Components.ahk"
#Include "..\lib\XAML_Dialog.ahk"

; --- Docking Manager Example ---
; Demonstrates how to create a multi-window IDE-like environment
; with floating "tear-off" panels that remember their size, position, and visibility across sessions.

INI_FILE := A_ScriptDir "\docking_layout.ini"

class PanelManager {
    static Panels := Map()
    static MainWindow := ""
    static CurrentTheme := "Dark Mica (Win 11)"

    static Init(mainHwnd) {
        this.MainWindow := mainHwnd
        
        ; Register known panels (IDs, Titles, initial bounds)
        this.RegisterPanel("Terminal", "Terminal Output", 100, 100, 600, 300)
        this.RegisterPanel("Properties", "Object Properties", 750, 100, 300, 500)
        this.RegisterPanel("Toolbox", "Component Toolbox", 100, 450, 250, 400)
        
        SetTimer(() => this.Magnetize(), 30)
        SetTimer(() => this.UpdateGlobalSnappedState(), 200)

        ; Show panels that were open last time
        for id, p in this.Panels {
            if (this.GetSavedState(id, "Visible", "0") == "1") {
                this.ShowPanel(id)
            }
        }
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
                        SetTimer(() => WinMove(finalX, finalY, finalW, finalH, "ahk_id " hwnd), -50)
                    }
                }
                this.dragStates := Map()
                wasDown := false
            }
            return
        }
        wasDown := true
            
        activeHwnd := WinGetID("A")
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
            this.dragStates[activeId] := {x: aX, y: aY, w: aW, h: aH}
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
            
        this.dragStates[activeId] := {x: aX, y: aY, w: aW, h: aH}
            
        rects := []
        if (activeId != "Main" && WinExist("ahk_id " this.MainWindow)) {
            WinGetPos(&x, &y, &w, &h, "ahk_id " this.MainWindow)
            if (x > -10000)
                rects.Push({x: x, y: y, w: w, h: h, hwnd: this.MainWindow})
        }
        for id, pInfo in this.Panels {
            if (activeId != id && pInfo.GuiHwnd && WinExist("ahk_id " pInfo.GuiHwnd)) {
                WinGetPos(&x, &y, &w, &h, "ahk_id " pInfo.GuiHwnd)
                if (x > -10000)
                    rects.Push({x: x, y: y, w: w, h: h, hwnd: pInfo.GuiHwnd})
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
            rects.Push({x: x, y: y, w: w, h: h})
        }
        for otherId, pInfo in this.Panels {
            if (otherId != id && pInfo.GuiHwnd && WinExist("ahk_id " pInfo.GuiHwnd)) {
                WinGetPos(&x, &y, &w, &h, "ahk_id " pInfo.GuiHwnd)
                rects.Push({x: x, y: y, w: w, h: h})
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
                allRects.Push({x: x, y: y, w: w, h: h, id: "Main"})
        }
        for id, pInfo in this.Panels {
            if (pInfo.GuiHwnd && WinExist("ahk_id " pInfo.GuiHwnd)) {
                WinGetPos(&x, &y, &w, &h, "ahk_id " pInfo.GuiHwnd)
                if (x > -10000)
                    allRects.Push({x: x, y: y, w: w, h: h, id: id})
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
                
                forceSquare := this.GetSavedState("Global", "SquarePanes", "0") == "1"
                isSquare := forceSquare || isSnapped
                
                cornerPref := isSquare ? 1 : 0
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", pInfo.GuiHwnd, "UInt", 33, "Int*", cornerPref, "UInt", 4)
                pInfo.Instance.Update("Resource", "PanelRadius", isSquare ? "0" : "8")
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
        main.Rows(titleHeight, "*")

        ; Titlebar (Must be a Border for XAML_Host DragArea logic)
        tb := main.Add("Border").Grid_Row(0).Background("Transparent").Name("DragArea")
        tbInner := tb.Add("Grid")
        tbInner.Add("TextBlock").Text(pInfo.Title).Foreground("{DynamicResource TextMain}").FontSize(titleFont).FontWeight("SemiBold").VerticalAlignment("Center").Margin("15,0,0,0")
        
        BtnGroup := tbInner.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Right")
        
        BtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="{DynamicResource ControlBgHover}"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        CloseBtnTemplate := '<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="{DynamicResource CloseBtnRadius}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="border" Property="Background" Value="#E0FF3333"/><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
        
        fillBtn := BtnGroup.Add("Button").Name("BtnFill").WindowChrome_IsHitTestVisibleInChrome("True").Width(btnWidth).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0)
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

        ; Initialize XAML Host for this panel
        ui := XAMLHost(StrReplace(XAML_TEMPLATE, "%app%", main.ToString()), "", this.MainWindow)
        
        ; Replace template dimensions, add title/taskbar visibility, remove CenterScreen, and use dynamic PanelRadius
        ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Title="' pInfo.Title '" ShowInTaskbar="False" Width="' w '" Height="' h '" Left="' x '" Top="' y '"')
        ui.xaml := StrReplace(ui.xaml, 'WindowStartupLocation="CenterScreen"', 'WindowStartupLocation="Manual"')
        ui.xaml := StrReplace(ui.xaml, 'CornerRadius="{DynamicResource WindowRadius}"', 'CornerRadius="{DynamicResource PanelRadius}"')
        
        ; Callbacks
        ui.OnEvent("BtnFill", "Click", (state, ctrl, event) => this.AutoFillSpace(id))
        ui.OnEvent("Window", "LoadedHwnd", (state, ctrl, event) => this.OnPanelLoaded(id, ui))
        ui.OnEvent("Window", "Closing", (state, ctrl, event) => this.OnPanelClosing(id))

        ui.Show()
        
        this.Panels[id].Instance := ui
        this.SaveState(id, "Visible", "1")
    }

    static ApplyThemeToPanel(pInfo, themeName) {
        if (pInfo.Instance == "" || !pInfo.Instance.wpfHwnd)
            return
        
        try {
            themeData := IniRead("themes.ini", themeName)
            Loop Parse, themeData, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=", " `t", 2)
                if (parts.Length == 2) {
                    key := parts[1]
                    val := parts[2]
                    if (key == "Window_DWM")
                        pInfo.Instance.Update("Window", "DWM", val)
                    else if (InStr(key, "Resource_") == 1)
                        pInfo.Instance.Update("Resource", SubStr(key, 10), val)
                }
            }
        }
        
        ; Apply Snapped/Square Radius
        forceSquare := this.GetSavedState("Global", "SquarePanes", "0") == "1"
        isSquare := forceSquare || pInfo.Snapped
        
        radius := isSquare ? "0" : "8"
        pInfo.Instance.Update("Resource", "PanelRadius", radius)
        
        if (pInfo.GuiHwnd) {
            cornerPref := isSquare ? 1 : 0
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", pInfo.GuiHwnd, "UInt", 33, "Int*", cornerPref, "UInt", 4)
        }
    }

    static UpdateTheme(themeName) {
        this.CurrentTheme := themeName
        for id, pInfo in this.Panels {
            this.ApplyThemeToPanel(pInfo, themeName)
        }
    }

    static OnPanelLoaded(id, ui) {
        this.Panels[id].GuiHwnd := ui.wpfHwnd
        this.ApplyThemeToPanel(this.Panels[id], this.CurrentTheme)
        
        ; Hook the exit size move to save coordinates
        SetTimer(() => this.CheckPanelMoved(id), 1000)
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

    static OnPanelClosing(id) {
        this.Panels[id].Instance := ""
        this.Panels[id].GuiHwnd := 0
        this.SaveState(id, "Visible", "0")
    }
}


; --- Main Application ---
app := XAML_GUI("IDE Docking Manager Example")

contentPanel := app.main.Add("StackPanel").Grid_Row(1).Margin("40")

contentPanel.Add("TextBlock").Text("IDE WORKBENCH").Foreground("{DynamicResource TextMain}").FontSize(24).FontWeight("Bold").Margin("0,0,0,5")
contentPanel.Add("TextBlock").Text("Use the buttons below to tear off and spawn floating tool panels. Their state will be remembered.").Foreground("{DynamicResource TextSub}").Margin("0,0,0,30").TextWrapping("Wrap")

btnSp := contentPanel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,30")
btnSp.Add("Button").Name("BtnOpenTerminal").Content("Toggle Terminal").Margin("0,0,10,0")
btnSp.Add("Button").Name("BtnOpenProperties").Content("Toggle Properties").Margin("0,0,10,0")
btnSp.Add("Button").Name("BtnOpenToolbox").Content("Toggle Toolbox")

editor := contentPanel.CodeEditor("main.ahk")
flow := editor.Add("FlowDocument").LineHeight(20)
flow.Add("Paragraph").Margin("0").Add("Run").Text("; Write your code here").Foreground("#6A9955")
flow.Add("Paragraph").Margin("0").Add("Run").Text("MsgBox(`"Hello World`")").Foreground("#DCDCAA")

ui := app.Compile()
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
ui.OnEvent("Window", "LoadedHwnd", (state, ctrl, event) => OnMainLoaded())
ui.OnEvent("BtnAppMaximize", "Click", (*) => PanelManager.AutoFillSpace("Main"))
ui.OnEvent("BtnOpenTerminal", "Click", (*) => PanelManager.ShowPanel("Terminal"))
ui.OnEvent("BtnOpenProperties", "Click", (*) => PanelManager.ShowPanel("Properties"))
ui.OnEvent("BtnOpenToolbox", "Click", (*) => PanelManager.ShowPanel("Toolbox"))
ui.OnEvent("ComboTheme", "SelectionChanged", (state, ctrl, event) => (
    app.ThemeChanged(state, ctrl, event),
    PanelManager.UpdateTheme(state["ComboTheme"])
))
ui.OnEvent("Window", "Closing", (*) => ExitApp())

app.Show()

OnMainLoaded() {
    PanelManager.Init(ui.wpfHwnd)
    SetTimer(CheckMainMoved, 1000)
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
