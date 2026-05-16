#Requires AutoHotkey v2.0
#SingleInstance Force

class XAMLHost {
    static _instances := Map()
    static _msgHooked := false

    __New(xaml := "", exePath := "", ownerHwnd := 0) {
        this.id := "WPF_" A_TickCount "_" Random(1000, 9999)
        XAMLHost._instances[this.id] := this
        this.xaml := xaml
        this.exePath := exePath
        this.ownerHwnd := ownerHwnd
        this.events := Map()
        this.tracked := Map()
        this.wpfHwnd := 0
        this.pid := 0
        if !DirExist(A_Temp "\AhkWpf")
            DirCreate(A_Temp "\AhkWpf")
        this.errLog := A_Temp "\AhkWpf\AhkWpfError.log"


        this.receiver := Gui()
        DllCall("user32\ChangeWindowMessageFilterEx", "Ptr", this.receiver.Hwnd, "UInt", 0x004A, "UInt", 1, "Ptr", 0)

        if (!XAMLHost._msgHooked) {
            OnMessage(0x004A, ObjBindMethod(XAMLHost, "OnCopyData"))
            XAMLHost._msgHooked := true
        }
    }

    OnEvent(controlName, eventName, callback, priority := 0) {
        if !this.events.Has(controlName)
            this.events[controlName] := Map()
        this.events[controlName][eventName] := { Callback: callback, Priority: priority }
    }

    Track(controlName) {
        this.tracked[controlName] := true
    }

    Update(controlName, propertyName, valueStr) {
        if !this.wpfHwnd
            return
        payload := controlName "|" propertyName "|" valueStr
        buf := Buffer(StrPut(payload, "UTF-8"))
        StrPut(payload, buf, "UTF-8")

        cds := Buffer(A_PtrSize * 3)
        NumPut("Ptr", 0, cds, 0)
        NumPut("UInt", buf.Size, cds, A_PtrSize)
        NumPut("Ptr", buf.Ptr, cds, A_PtrSize * 2)

        DllCall("user32\SendMessageW", "Ptr", this.wpfHwnd, "UInt", 0x004A, "Ptr", 0, "Ptr", cds.Ptr)
    }

    CheckForCrashes() {
        if (this.wpfHwnd != 0) {
            SetTimer(ObjBindMethod(this, "CheckForCrashes"), 0)
            return
        }
        if FileExist(this.errLog) {
            SetTimer(ObjBindMethod(this, "CheckForCrashes"), 0)
            err := FileRead(this.errLog)
            FileDelete(this.errLog)

            ahkLine := "Unknown"
            snippet := ""
            if RegExMatch(err, "s)AHK_LINE:(.*?)\nXAML_SNIPPET:(.*?)\n\n(.*)", &m) {
                ahkLine := m[1]
                snippet := m[2]
                err := m[3]
            }

            header := "The Background Engine crashed! Details below:"
            if (ahkLine != "Unknown") {
                header := "Engine crashed while rendering AHK Line " ahkLine "!"
            }

            XAMLHost.ShowErrorDialog("Engine Crash", header, snippet, err)
            ExitApp()
        }
    }

    static ShowErrorDialog(title, header, snippet, details) {
        ; Pre-format the error text for better readability
        details := StrReplace(details, " ---> ", "`r`n`r`n---> ")
        details := StrReplace(details, "`r`n", "`n")
        details := StrReplace(details, "`n", "`r`n")

        ; Add an extra break before the first stack trace line to separate the error message
        details := StrReplace(details, "`r`n   at ", "`r`n`r`n   at ", , &_, 1)

        errGui := Gui("", title)
        errGui.MarginX := 20
        errGui.MarginY := 20

        errGui.SetFont("s12 bold cMaroon", "Segoe UI")
        errGui.Add("Text", "w720", header)

        if (snippet != "") {
            errGui.SetFont("s10 bold cBlack", "Segoe UI")
            errGui.Add("Text", "y+10", "Generated XAML Snippet:")
            errGui.SetFont("s10 norm cBlack", "Consolas")
            errGui.Add("Edit", "y+5 w720 h60 ReadOnly +VScroll", snippet)

            errGui.SetFont("s10 bold cBlack", "Segoe UI")
            errGui.Add("Text", "y+15", "Full Exception Trace:")
            errGui.SetFont("s10 norm cBlack", "Consolas")
            errGui.Add("Edit", "y+5 w720 h260 ReadOnly +VScroll", details)
        } else {
            errGui.SetFont("s10 norm cBlack", "Consolas")
            ; Word wrap is enabled by default. +VScroll ensures vertical scrolling.
            errGui.Add("Edit", "y+15 w720 h380 ReadOnly +VScroll", details)
        }

        errGui.SetFont("s10 norm cBlack", "Segoe UI")
        btn := errGui.Add("Button", "w120 x320 y+20 Default", "Close")
        btn.OnEvent("Click", (*) => errGui.Destroy())

        errGui.Show()
        WinWaitClose(errGui)
    }

    Export(filePath) {
        eventBindings := ""
        for ctrlName, events in this.events {
            for eventName, evtObj in events {
                eventBindings .= ctrlName ":" eventName ","
            }
        }
        eventBindings := RTrim(eventBindings, ",")

        payload := this.xaml "`n---AHK-XAML-EVENTS---`n" eventBindings

        tempTxt := A_Temp "\AhkWpf\gui_temp.txt"
        if !DirExist(A_Temp "\AhkWpf")
            DirCreate(A_Temp "\AhkWpf")

        if FileExist(tempTxt)
            FileDelete(tempTxt)
        FileAppend(payload, tempTxt, "UTF-8")

        targetExe := (this.exePath != "") ? this.exePath : A_Temp "\AhkWpf\ahk-xaml.dll"
        SplitPath(A_LineFile, , &libDir)
        sharedExe := libDir "\ahk-xaml.dll"

        if (A_IsCompiled && FileExist(A_ScriptDir "\ahk-xaml.dll")) {
            targetExe := A_ScriptDir "\ahk-xaml.dll"
        } else if (!A_IsCompiled) {
            if !FileExist(sharedExe) {
                if !this.CompileEngine(libDir, sharedExe)
                    return
            }
            targetExe := sharedExe
        }

        if !FileExist(targetExe) {
            MsgBox("Fatal Error: Could not locate ahk-xaml.dll to perform compilation.", "AHK-XAML", "Iconx")
            return
        }

        RunWait('"' targetExe '" --compress "' tempTxt '" "' filePath '"', "", "Hide")

        if FileExist(tempTxt)
            FileDelete(tempTxt)
    }

    CompileEngine(libDir, sharedExe) {
        sourceCs := libDir "\XAML_AHK_Bridge.cs"
        if !FileExist(sourceCs) {
            MsgBox("XAML_AHK_Bridge.cs not found in lib directory!`nCannot compile shared engine.", "AHK-XAML", "Iconx")
            return false
        }

        cscPath := "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
        if !FileExist(cscPath)
            cscPath := "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"

        SplitPath(cscPath, , &cscDir)
        wpfDir := cscDir "\WPF"

        cmd := A_ComSpec ' /c ""' cscPath '" /nologo /target:winexe /out:"' sharedExe '" /lib:"' wpfDir '" /reference:System.dll /reference:System.Core.dll /reference:System.Xml.dll /reference:PresentationFramework.dll /reference:PresentationCore.dll /reference:WindowsBase.dll /reference:System.Xaml.dll /reference:UIAutomationProvider.dll /reference:UIAutomationTypes.dll "' sourceCs '" > "' this.errLog '" 2>&1"'
        RunWait(cmd, "", "Hide")

        if !FileExist(sharedExe) {
            errOut := FileExist(this.errLog) ? FileRead(this.errLog) : "Unknown compilation error."
            XAMLHost.ShowErrorDialog("Engine Compile Error", "Failed to compile background engine.", "", errOut)
            return false
        }
        return true
    }

    Show(assetPath := "") {
        if !DirExist(A_Temp "\AhkWpf")
            DirCreate(A_Temp "\AhkWpf")
        if FileExist(this.errLog)
            FileDelete(this.errLog)

        targetExe := (this.exePath != "") ? this.exePath : A_Temp "\AhkWpf\ahk-xaml.dll"
        trackedCsv := ""

        uniqueCsv := Map()
        for ctrlName in this.events
            uniqueCsv[ctrlName] := true
        for ctrlName in this.tracked
            uniqueCsv[ctrlName] := true

        for name in uniqueCsv
            trackedCsv .= name ","
        trackedCsv := RTrim(trackedCsv, ",")

        if (assetPath != "") {
            xamlFile := assetPath
            eventsFile := "none"
        } else {
            eventBindings := ""
            for ctrlName, events in this.events {
                for eventName, evtObj in events {
                    eventBindings .= ctrlName ":" eventName ","
                }
            }
            eventBindings := RTrim(eventBindings, ",")

            xamlFile := ""
            if (this.xaml != "") {
                xamlFile := A_Temp "\AhkWpf\AhkWpf_" this.id ".xaml"
                if FileExist(xamlFile)
                    FileDelete(xamlFile)
                FileAppend(this.xaml, xamlFile, "UTF-8")
            }

            eventsFile := A_Temp "\AhkWpf\AhkWpf_" this.id ".events.txt"
            if FileExist(eventsFile)
                FileDelete(eventsFile)
            FileAppend(eventBindings, eventsFile, "UTF-8")
        }

        SplitPath(A_LineFile, , &libDir)
        sharedExe := libDir "\ahk-xaml.dll"

        if (A_IsCompiled && FileExist(A_ScriptDir "\ahk-xaml.dll")) {
            targetExe := A_ScriptDir "\ahk-xaml.dll"
        } else if (!A_IsCompiled) {
            ; Development Mode: Compile generic engine once to the lib directory if it doesn't exist
            if !FileExist(sharedExe) {
                if !this.CompileEngine(libDir, sharedExe)
                    return
            }

            ; Copy generic engine to Temp for isolated execution if missing
            if !FileExist(targetExe)
                FileCopy(sharedExe, targetExe, 1)
        } else {
            ; Production Mode: Extract the embedded, pre-compiled generic engine directly.
            ; No C# compiler or source code is required on the user's machine.
            if !FileExist(targetExe)
                FileInstall("ahk-xaml.dll", targetExe, 1)
        }

        if FileExist(this.errLog)
            FileDelete(this.errLog)

        Run('"' targetExe '" "' this.id '" "' String(this.receiver.Hwnd) '" "' trackedCsv '" "' ProcessExist() '" "' A_ScriptName '" "' xamlFile '" "' eventsFile '" "' String(this.ownerHwnd) '"', "", "Hide", &pid)
        this.pid := pid

        SetTimer(ObjBindMethod(this, "CheckForCrashes"), 500)
    }

    static OnCopyData(wParam, lParam, msg, hwnd) {
        if (msg != 0x004A)
            return 0

        lpData := NumGet(lParam, A_PtrSize * 2, "Ptr")
        payload := StrGet(lpData, "UTF-8")
        if !InStr(payload, "EVENT|")
            return 0

        lines := StrSplit(payload, "`n", "`r")
        parts := StrSplit(lines[1], "|")
        if (parts.Length < 4)
            return 0

        winId := parts[2], ctrlName := parts[3], eventName := parts[4]
        if !XAMLHost._instances.Has(winId)
            return 0

        instance := XAMLHost._instances[winId]

        if (ctrlName == "Window" && eventName == "LoadedHwnd") {
            instance.wpfHwnd := Integer(parts[5])
        }
        if (ctrlName == "Window" && eventName == "Closed") {
            instance.wpfHwnd := 0
        }

        stateMap := Map()
        if (eventName == "Drop" && parts.Length >= 5) {
            stateMap["DropFiles"] := StrSplit(XAMLHost.Base64Decode(parts[5]), "|")
        }

        Loop lines.Length {
            if (A_Index == 1 || lines[A_Index] == "")
                continue
            pos := InStr(lines[A_Index], "=")
            if pos {
                k := SubStr(lines[A_Index], 1, pos - 1)
                stateMap[k] := XAMLHost.Base64Decode(SubStr(lines[A_Index], pos + 1))
            }
        }

        if (instance.events.Has(ctrlName) && instance.events[ctrlName].Has(eventName)) {
            evtObj := instance.events[ctrlName][eventName]
            cb := evtObj.Callback
            SetTimer(() => cb(stateMap, ctrlName, eventName), -1, evtObj.Priority)
        }
        return 1
    }

    static Base64Encode(str) {
        if (str == "")
            return ""
        buf := Buffer(StrPut(str, "UTF-8"))
        StrPut(str, buf, "UTF-8")
        DllCall("crypt32\CryptBinaryToStringW", "Ptr", buf, "UInt", buf.Size - 1, "UInt", 0x00000001, "Ptr", 0, "UInt*", &size := 0)
        b64 := Buffer(size * 2)
        DllCall("crypt32\CryptBinaryToStringW", "Ptr", buf, "UInt", buf.Size - 1, "UInt", 0x00000001, "Ptr", b64, "UInt*", &size)
        return StrReplace(StrReplace(StrGet(b64, "UTF-16"), "`r", ""), "`n", "")
    }

    static Base64Decode(b64) {
        if (b64 == "")
            return ""
        size := 0
        DllCall("crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", 0, "UInt*", &size, "Ptr", 0, "Ptr", 0)
        buf := Buffer(size)
        DllCall("crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", buf, "UInt*", &size, "Ptr", 0, "Ptr", 0)
        return StrGet(buf, "UTF-8")
    }
}

XAML_TEMPLATE := '
(
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:sys="clr-namespace:System;assembly=mscorlib"
            xmlns:primitives="clr-namespace:System.Windows.Controls.Primitives;assembly=PresentationFramework"
            Width="940" Height="700"
            WindowStyle="None" AllowsTransparency="False" Background="Transparent"
            WindowStartupLocation="CenterScreen"
            TextElement.Foreground="{DynamicResource TextMain}" FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif">
        
        <WindowChrome.WindowChrome>
            <WindowChrome GlassFrameThickness="-1" CaptionHeight="50" CornerRadius="{DynamicResource WindowRadius}" />
        </WindowChrome.WindowChrome>
    
        %components%
    
        %app%
    </Window>
)'

SplitPath(A_LineFile, , &_thisDir)
if FileExist(_thisDir "/xaml.components.xaml")
    XAML_TEMPLATE := StrReplace(XAML_TEMPLATE, "%components%", FileRead(_thisDir "/xaml.components.xaml", "UTF-8"))
else
    XAML_TEMPLATE := StrReplace(XAML_TEMPLATE, "%components%", "")