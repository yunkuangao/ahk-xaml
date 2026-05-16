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

    Show() {
        if !DirExist(A_Temp "\AhkWpf")
            DirCreate(A_Temp "\AhkWpf")
        if FileExist(this.errLog)
            FileDelete(this.errLog)

        targetExe := (this.exePath != "") ? this.exePath : A_Temp "\AhkWpf\AhkWpf_SharedEngine_v8.exe"
        trackedCsv := ""

        uniqueCsv := Map()
        for ctrlName in this.events
            uniqueCsv[ctrlName] := true
        for ctrlName in this.tracked
            uniqueCsv[ctrlName] := true

        for name in uniqueCsv
            trackedCsv .= name ","
        trackedCsv := RTrim(trackedCsv, ",")

        eventBindings := ""
        for ctrlName, events in this.events {
            for eventName, evtObj in events {
                eventBindings .= ctrlName ":" eventName ","
            }
        }
        eventBindings := RTrim(eventBindings, ",")

        eventBindings := RTrim(eventBindings, ",")
        if !FileExist(targetExe) {
            csCode := '
            (
                using System;
                using System.Linq;
                using System.Windows;
                using System.Windows.Markup;
                using System.Windows.Controls;
                using System.Windows.Controls.Primitives;
                using System.Windows.Interop;
                using System.Runtime.InteropServices;
                using System.Text;
                using System.Xml;
                using System.Reflection;
                
                public class AhkWpfEngine : Application {
                    [StructLayout(LayoutKind.Sequential)]
                    public struct COPYDATASTRUCT {
                        public IntPtr dwData; public int cbData; public IntPtr lpData;
                    }
                    [DllImport("user32.dll", CharSet = CharSet.Auto)]
                    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, ref COPYDATASTRUCT lParam);
                    [DllImport("user32.dll")]
                    public static extern bool SetForegroundWindow(IntPtr hWnd);
                    [DllImport("user32.dll")]
                    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
                    [DllImport("dwmapi.dll")]
                    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
                    
                    [StructLayout(LayoutKind.Sequential)]
                    public struct MINMAXINFO { public POINT ptReserved; public POINT ptMaxSize; public POINT ptMaxPosition; public POINT ptMinTrackSize; public POINT ptMaxTrackSize; }
                    [StructLayout(LayoutKind.Sequential)]
                    public struct POINT { public int x; public int y; }
                    [StructLayout(LayoutKind.Sequential)]
                    public struct MONITORINFO { public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags; }
                    [StructLayout(LayoutKind.Sequential)]
                    public struct RECT { public int left, top, right, bottom; }
                    [DllImport("user32.dll")]
                    public static extern IntPtr MonitorFromWindow(IntPtr handle, int flags);
                    [DllImport("user32.dll", CharSet = CharSet.Auto)]
                    public static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFO lpmi);
                
                    string winId; IntPtr ahkHwnd; string[] tracked; Window win;
                
                    static AhkWpfEngine() {
                        EventManager.RegisterClassHandler(typeof(TreeView), UIElement.PreviewMouseWheelEvent, new System.Windows.Input.MouseWheelEventHandler(OnPreviewMouseWheel), false);
                        EventManager.RegisterClassHandler(typeof(ScrollViewer), UIElement.PreviewMouseWheelEvent, new System.Windows.Input.MouseWheelEventHandler(OnPreviewMouseWheel), false);
                    }
                    
                    private static void OnPreviewMouseWheel(object sender, System.Windows.Input.MouseWheelEventArgs args) {
                        if (!args.Handled) {
                            ScrollViewer sv = null;
                            if (sender is ScrollViewer) sv = (ScrollViewer)sender;
                            else sv = FindVisualChild<ScrollViewer>(sender as DependencyObject);
                            
                            bool canScroll = false;
                            if (sv != null && sv.ComputedVerticalScrollBarVisibility == Visibility.Visible) {
                                if (args.Delta > 0 && sv.VerticalOffset > 0) canScroll = true;
                                else if (args.Delta < 0 && sv.VerticalOffset < sv.ScrollableHeight) canScroll = true;
                            }
                            
                            if (!canScroll) {
                                args.Handled = true;
                                var eventArg = new System.Windows.Input.MouseWheelEventArgs(args.MouseDevice, args.Timestamp, args.Delta) { RoutedEvent = UIElement.MouseWheelEvent, Source = sender };
                                var parent = System.Windows.Media.VisualTreeHelper.GetParent(sender as DependencyObject) as UIElement;
                                if (parent != null) parent.RaiseEvent(eventArg);
                            }
                        }
                    }
                    
                    private static T FindVisualChild<T>(DependencyObject obj) where T : DependencyObject {
                        if (obj != null) {
                            for (int i = 0; i < System.Windows.Media.VisualTreeHelper.GetChildrenCount(obj); i++) {
                                var child = System.Windows.Media.VisualTreeHelper.GetChild(obj, i);
                                if (child is T) return (T)child;
                                T childItem = FindVisualChild<T>(child);
                                if (childItem != null) return childItem;
                            }
                        }
                        return null;
                    }
                
                    [STAThread]
                    public static void Main(string[] args) {
                        try {
                            if (args.Length < 3) return;
                            AhkWpfEngine engine = new AhkWpfEngine();
                            if (args.Length >= 5) {
                                int ahkPid = int.Parse(args[3]);
                                string scriptName = args[4];
                                System.Threading.Thread t = new System.Threading.Thread(() => {
                                    try {
                                        System.Diagnostics.Process p = System.Diagnostics.Process.GetProcessById(ahkPid);
                                        p.WaitForExit();
                                        Application.Current.Dispatcher.Invoke(() => {
                                            try {
                                                string state = engine.CollectState();
                                                string dir = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "AhkWpf");
                                                if (!System.IO.Directory.Exists(dir)) System.IO.Directory.CreateDirectory(dir);
                                                System.IO.File.WriteAllText(System.IO.Path.Combine(dir, "AhkWpf_StateDump_" + scriptName + ".ini"), state);
                                            } catch { }
                                            Environment.Exit(0);
                                        });
                                    } catch { Environment.Exit(0); }
                                });
                                t.IsBackground = true;
                                t.Start();
                            }
                            engine.RunEngine(args[0], args[1], args[2], args.Length >= 5 ? args[4] : "", args.Length >= 6 ? args[5] : "", args.Length >= 7 ? args[6] : "", args.Length >= 8 ? args[7] : "0");
                        } catch (Exception ex) {
                            try {
                                string dir = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "AhkWpf");
                                if (!System.IO.Directory.Exists(dir)) System.IO.Directory.CreateDirectory(dir);
                                System.IO.File.WriteAllText(System.IO.Path.Combine(dir, "AhkWpfError.log"), ex.ToString());
                            } catch { }
                        }
                    }
                
                    public void RunEngine(string id, string hwndStr, string trackedCsv, string scriptName, string xamlFilePath, string eventsFilePath, string ownerHwndStr = "0") {
                        winId = id; ahkHwnd = (IntPtr)long.Parse(hwndStr);
                        tracked = trackedCsv.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                        
                        string xamlContent = "";
                        if (!string.IsNullOrEmpty(xamlFilePath) && System.IO.File.Exists(xamlFilePath)) {
                            xamlContent = System.IO.File.ReadAllText(xamlFilePath, Encoding.UTF8);
                        } else {
                            try {
                                using (var stream = System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream("AppXaml")) {
                                    if (stream != null) {
                                        using (var reader = new System.IO.StreamReader(stream, Encoding.UTF8)) {
                                            xamlContent = reader.ReadToEnd();
                                        }
                                    }
                                }
                            } catch { }
                        }
                        
                        if (!string.IsNullOrEmpty(xamlFilePath) && System.IO.File.Exists(xamlFilePath)) {
                            try { System.IO.File.Delete(xamlFilePath); } catch { }
                        }
                        
                        byte[] xamlBytes;
                        if (string.IsNullOrWhiteSpace(xamlContent)) {
                            xamlBytes = Encoding.UTF8.GetBytes("<Window xmlns=\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\" />");
                        } else {
                            xamlBytes = Encoding.UTF8.GetBytes(xamlContent);
                        }
                        if (Application.Current == null) new Application();
                        try {
                            using (var stream = new System.IO.MemoryStream(xamlBytes)) {
                                win = (Window)XamlReader.Load(stream);
                            }
                            foreach (System.Collections.DictionaryEntry entry in win.Resources) {
                                Application.Current.Resources[entry.Key] = entry.Value;
                            }
                        } catch (XamlParseException ex) {
                            string[] xamlLines = Encoding.UTF8.GetString(xamlBytes).Replace("\r\n", "\n").Split('\n');
                            string snippet = "Unknown";
                            string ahkLine = "Unknown";
                            if (ex.LineNumber > 0 && ex.LineNumber <= xamlLines.Length) {
                                int startLine = Math.Max(0, ex.LineNumber - 8);
                                int endLine = Math.Min(xamlLines.Length - 1, ex.LineNumber + 8);
                                StringBuilder sb = new StringBuilder();
                                for (int i = startLine; i <= endLine; i++) {
                                    string prefix = (i == ex.LineNumber - 1) ? ">> " : "   ";
                                    sb.AppendLine(prefix + (i+1) + "| " + xamlLines[i].TrimEnd());
                                }
                                snippet = sb.ToString().TrimEnd();
                
                                string errLine = xamlLines[ex.LineNumber - 1];
                                int idx1 = errLine.IndexOf("<!-- [ahk:");
                                if (idx1 != -1) {
                                    int idx2 = errLine.IndexOf("] -->", idx1);
                                    if (idx2 != -1) ahkLine = errLine.Substring(idx1 + 10, idx2 - (idx1 + 10));
                                } else {
                                    for(int i = ex.LineNumber - 1; i >= 0; i--) {
                                        int i1 = xamlLines[i].IndexOf("<!-- [ahk:");
                                        if (i1 != -1) {
                                            int i2 = xamlLines[i].IndexOf("] -->", i1);
                                            if (i2 != -1) {
                                                ahkLine = "~" + xamlLines[i].Substring(i1 + 10, i2 - (i1 + 10));
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            throw new Exception("AHK_LINE:" + ahkLine + "\nXAML_SNIPPET:\n" + snippet + "\n\n" + ex.ToString());
                        }
                
                        if (!string.IsNullOrEmpty(scriptName)) {
                            string dumpPath = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "AhkWpf", "AhkWpf_StateDump_" + scriptName + ".ini");
                            if (System.IO.File.Exists(dumpPath)) {
                                try {
                                    string[] lines = System.IO.File.ReadAllLines(dumpPath);
                                    System.IO.File.Delete(dumpPath);
                                    foreach (string line in lines) {
                                        string[] p = line.Split(new[] { '=' }, 2);
                                        if (p.Length == 2) {
                                            var ctrl = win.FindName(p[0]);
                                            if (ctrl != null) {
                                                string val = Encoding.UTF8.GetString(Convert.FromBase64String(p[1]));
                                                if (ctrl is TextBox) ((TextBox)ctrl).Text = val;
                                                else if (ctrl is PasswordBox) ((PasswordBox)ctrl).Password = val;
                                                else if (ctrl is ToggleButton) { bool b; if (bool.TryParse(val, out b)) ((ToggleButton)ctrl).IsChecked = b; }
                                                else if (ctrl is RangeBase) { double d; if (double.TryParse(val, out d)) ((RangeBase)ctrl).Value = d; }
                                                else if (ctrl is ComboBox) {
                                                    ComboBox cb = (ComboBox)ctrl;
                                                    bool found = false;
                                                    foreach (var item in cb.Items) {
                                                        ComboBoxItem cbi = item as ComboBoxItem;
                                                        if (cbi != null && cbi.Content != null && cbi.Content.ToString() == val) { cb.SelectedItem = item; found = true; break; }
                                                    }
                                                    if (!found) cb.Text = val;
                                                }
                                            }
                                        }
                                    }
                                } catch { }
                            }
                        }
                
                        var dragArea = win.FindName("DragArea") as UIElement;
                        if (dragArea != null) dragArea.MouseLeftButtonDown += (s, e) => { try { win.DragMove(); } catch { } };
                        
                        var txtLogo = win.FindName("TxtLogo") as UIElement;
                        if (txtLogo != null) txtLogo.MouseLeftButtonDown += (s, e) => { try { win.DragMove(); } catch { } };
                        
                        var btnClose = win.FindName("BtnClose") as ButtonBase;
                        if (btnClose != null) btnClose.Click += (s, e) => { try { win.Close(); } catch { } };
                        
                        var btnMaximize = win.FindName("BtnMaximize") as ButtonBase;
                        if (btnMaximize != null) btnMaximize.Click += (s, e) => { win.WindowState = win.WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized; };
                        
                        var btnMinimize = win.FindName("BtnMinimize") as ButtonBase;
                        if (btnMinimize != null) btnMinimize.Click += (s, e) => { win.WindowState = WindowState.Minimized; };
                
                        win.Resources["BaseWindowRadius"] = new CornerRadius(12);
                        if (Application.Current != null) Application.Current.Resources["BaseWindowRadius"] = win.Resources["BaseWindowRadius"];
                        
                        win.StateChanged += (s, e) => UpdateSnapState(win);
                        win.LocationChanged += (s, e) => UpdateSnapState(win);
                        win.SizeChanged += (s, e) => UpdateSnapState(win);
                        
                        win.Loaded += (s, e) => {
                            IntPtr hwnd = new WindowInteropHelper(win).Handle;
                            HwndSource.FromHwnd(hwnd).AddHook(WndProc);
                            SendToAhk("EVENT|" + winId + "|Window|LoadedHwnd|" + hwnd.ToString() + "\n");
                            UpdateSnapState(win);
                            DumpState("Window", "Loaded");
                        };
                        win.Closing += (s, e) => { 
                            var ownerHwnd = new System.Windows.Interop.WindowInteropHelper(win).Owner;
                            if (ownerHwnd != IntPtr.Zero) {
                                SetWindowPos(ownerHwnd, IntPtr.Zero, 0, 0, 0, 0, 0x0003);
                                SetForegroundWindow(ownerHwnd);
                            }
                            SendToAhk("EVENT|" + winId + "|Window|Closing\n"); 
                        };
                        win.Closed += (s, e) => { SendToAhk("EVENT|" + winId + "|Window|Closed\n"); };
                
                        if (!string.IsNullOrEmpty(eventsFilePath) && System.IO.File.Exists(eventsFilePath)) {
                            string bindingsStr = System.IO.File.ReadAllText(eventsFilePath);
                            try { System.IO.File.Delete(eventsFilePath); } catch { }
                            string[] pairs = bindingsStr.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                            foreach (string p in pairs) {
                                string[] kv = p.Split(':');
                                if (kv.Length == 2) BindEvent(kv[0], kv[1]);
                            }
                        }
                
                        if (ownerHwndStr != "0") {
                            try {
                                IntPtr oHwnd = new IntPtr(long.Parse(ownerHwndStr));
                                if (oHwnd != IntPtr.Zero) {
                                    new System.Windows.Interop.WindowInteropHelper(win).Owner = oHwnd;
                                }
                            } catch { }
                        }
                        win.ShowDialog();
                    }
                
                    private void UpdateSnapState(Window win) {
                        CornerRadius baseRad = new CornerRadius(0);
                        if (win.Resources.Contains("BaseWindowRadius")) {
                            baseRad = (CornerRadius)win.Resources["BaseWindowRadius"];
                        }
                        bool wantsRound = baseRad.TopLeft > 0;
                        
                        bool isSnappedOrMax = win.WindowState == WindowState.Maximized;
                        if (!isSnappedOrMax) {
                            var workArea = System.Windows.SystemParameters.WorkArea;
                            isSnappedOrMax = (win.Top <= workArea.Top && win.Height >= workArea.Height) || 
                                             (win.Left <= workArea.Left && win.Width >= workArea.Width);
                        }
                
                        int cornerPref = wantsRound ? 2 : 1; // 1 = DoNotRound, 2 = Round
                        int hr = -1;
                        try {
                            IntPtr hwnd = new WindowInteropHelper(win).Handle;
                            if (hwnd != IntPtr.Zero) {
                                hr = DwmSetWindowAttribute(hwnd, 33, ref cornerPref, 4);
                            }
                        } catch { }
                
                        // On Windows 11, if DwmSetWindowAttribute(33) succeeds, DWM rounds the physical window to exactly 8px.
                        // On Windows 10, it fails, and the physical window remains square (0px).
                        double actualRadius = (!isSnappedOrMax && wantsRound && hr == 0) ? 8 : 0;
                
                        win.Resources["WindowRadius"] = new CornerRadius(actualRadius);
                        win.Resources["CloseBtnRadius"] = new CornerRadius(0, actualRadius, 0, 0);
                        
                        var chrome = System.Windows.Shell.WindowChrome.GetWindowChrome(win);
                        if (chrome != null) {
                            chrome.CornerRadius = (CornerRadius)win.Resources["WindowRadius"];
                        }
                        
                        if (Application.Current != null) {
                            Application.Current.Resources["WindowRadius"] = win.Resources["WindowRadius"];
                            Application.Current.Resources["CloseBtnRadius"] = win.Resources["CloseBtnRadius"];
                        }
                        
                        var btnMaximizeTxt = win.FindName("BtnMaximizeTxt") as TextBlock;
                        if (btnMaximizeTxt != null) {
                            btnMaximizeTxt.Text = win.WindowState == WindowState.Maximized ? "\uE923" : "\uE922";
                        }
                    }
                
                    private void BindEvent(string ctrlName, string eventName) {
                        try {
                            var ctrl = win.FindName(ctrlName);
                            if (ctrl == null) return;
                            var evt = ctrl.GetType().GetEvent(eventName);
                            if (evt == null) return;
                
                            var parameters = evt.EventHandlerType.GetMethod("Invoke").GetParameters();
                            
                            if (eventName == "Drop") {
                                if (ctrl is UIElement) {
                                    ((UIElement)ctrl).AllowDrop = true;
                                    ((UIElement)ctrl).Drop += (s, e) => {
                                        if (e.Data.GetDataPresent(DataFormats.FileDrop)) {
                                            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
                                            string fileList = Convert.ToBase64String(Encoding.UTF8.GetBytes(string.Join("|", files)));
                                            SendToAhk("EVENT|" + winId + "|" + ctrlName + "|Drop|" + fileList + "\n");
                                        }
                                    };
                                }
                                return;
                            }
                            
                            var pExprs = parameters.Select(p => System.Linq.Expressions.Expression.Parameter(p.ParameterType, p.Name)).ToArray();
                            var dumpStateMethod = this.GetType().GetMethod("DumpState", BindingFlags.NonPublic | BindingFlags.Instance);
                            var call = System.Linq.Expressions.Expression.Call(System.Linq.Expressions.Expression.Constant(this), dumpStateMethod, System.Linq.Expressions.Expression.Constant(ctrlName), System.Linq.Expressions.Expression.Constant(eventName));
                            var lambda = System.Linq.Expressions.Expression.Lambda(evt.EventHandlerType, call, pExprs);
                            evt.AddEventHandler(ctrl, lambda.Compile());
                        } catch { }
                    }
                
                    public string CollectState() {
                        var sb = new StringBuilder();
                        foreach (var t in tracked) {
                            var c = win.FindName(t);
                            if (c != null) {
                                string val = "";
                                if (c is TextBox) val = ((TextBox)c).Text;
                                else if (c is PasswordBox) val = ((PasswordBox)c).Password;
                                else if (c is ToggleButton) { bool? isChecked = ((ToggleButton)c).IsChecked; val = isChecked.HasValue ? isChecked.Value.ToString() : "False"; }
                                else if (c is RangeBase) val = ((RangeBase)c).Value.ToString();
                                else if (c is ComboBox) {
                                    ComboBox cb = (ComboBox)c;
                                    if (cb.SelectedItem is ComboBoxItem) {
                                        object content = ((ComboBoxItem)cb.SelectedItem).Content;
                                        val = content != null ? content.ToString() : "";
                                    }
                                    else val = cb.Text;
                                }
                                else if (c is TreeView) {
                                    TreeView tv = (TreeView)c;
                                    if (tv.SelectedItem is TreeViewItem) {
                                        object tag = ((TreeViewItem)tv.SelectedItem).Tag;
                                        val = tag != null ? tag.ToString() : "";
                                    }
                                }
                                if (val == null) val = "";
                                sb.Append(t + "=" + Convert.ToBase64String(Encoding.UTF8.GetBytes(val)) + "\n");
                            }
                        }
                        return sb.ToString();
                    }
                
                    private void DumpState(string cName, string eName) {
                        var sb = new StringBuilder("EVENT|" + winId + "|" + cName + "|" + eName + "\n");
                        sb.Append(CollectState());
                        SendToAhk(sb.ToString());
                    }
                
                    private void SendToAhk(string text) {
                        byte[] bytes = Encoding.UTF8.GetBytes(text);
                        var cds = new COPYDATASTRUCT { cbData = bytes.Length + 1, lpData = Marshal.AllocHGlobal(bytes.Length + 1) };
                        Marshal.Copy(bytes, 0, cds.lpData, bytes.Length);
                        Marshal.WriteByte(cds.lpData, bytes.Length, 0);
                        SendMessage(ahkHwnd, 0x004A, IntPtr.Zero, ref cds);
                        Marshal.FreeHGlobal(cds.lpData);
                    }
                
                    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled) {
                        if (msg == 0x004A) {
                            try {
                                var cds = (COPYDATASTRUCT)Marshal.PtrToStructure(lParam, typeof(COPYDATASTRUCT));
                                byte[] bytes = new byte[cds.cbData];
                                Marshal.Copy(cds.lpData, bytes, 0, cds.cbData);
                                ProcessMessage(hwnd, Encoding.UTF8.GetString(bytes).TrimEnd('\0'));
                            } catch { }
                            handled = true;
                        } else if (msg == 0x0024) { // WM_GETMINMAXINFO
                            try {
                                MINMAXINFO mmi = (MINMAXINFO)Marshal.PtrToStructure(lParam, typeof(MINMAXINFO));
                                IntPtr monitor = MonitorFromWindow(hwnd, 2); // MONITOR_DEFAULTTONEAREST
                                if (monitor != IntPtr.Zero) {
                                    MONITORINFO monitorInfo = new MONITORINFO();
                                    monitorInfo.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
                                    GetMonitorInfo(monitor, ref monitorInfo);
                                    RECT rcWorkArea = monitorInfo.rcWork;
                                    RECT rcMonitorArea = monitorInfo.rcMonitor;
                                    mmi.ptMaxPosition.x = Math.Abs(rcWorkArea.left - rcMonitorArea.left);
                                    mmi.ptMaxPosition.y = Math.Abs(rcWorkArea.top - rcMonitorArea.top);
                                    mmi.ptMaxSize.x = Math.Abs(rcWorkArea.right - rcWorkArea.left);
                                    mmi.ptMaxSize.y = Math.Abs(rcWorkArea.bottom - rcWorkArea.top);
                                }
                                Marshal.StructureToPtr(mmi, lParam, true);
                            } catch { }
                        }
                        return IntPtr.Zero;
                    }
                
                    private void ProcessMessage(IntPtr hwnd, string text) {
                        string[] parts = text.Split(new[] { '|' }, 3);
                        if (parts.Length < 3) return;
                        if (parts[0] == "Window" && parts[1] == "DWM") {
                            string[] p = parts[2].Split(',');
                            int backdrop = int.Parse(p[0]), dark = int.Parse(p[1]);
                            DwmSetWindowAttribute(hwnd, 20, ref dark, 4);
                            DwmSetWindowAttribute(hwnd, 38, ref backdrop, 4);
                            int borderColor = -2; // DWMWA_COLOR_NONE (0xFFFFFFFE)
                            DwmSetWindowAttribute(hwnd, 34, ref borderColor, 4);
                        } else if (parts[0] == "Resource") {
                            string[] rParts = parts[2].Split(new[] { ':' }, 2);
                            if (rParts.Length == 2 && (rParts[0] == "Brush" || rParts[0] == "Thickness" || rParts[0] == "CornerRadius" || rParts[0] == "Double")) {
                                string type = rParts[0];
                                string val = rParts[1];
                                if (type == "Brush") win.Resources[parts[1]] = new System.Windows.Media.BrushConverter().ConvertFromString(val);
                                else if (type == "Thickness") win.Resources[parts[1]] = new System.Windows.ThicknessConverter().ConvertFromString(val);
                                else if (type == "CornerRadius") {
                                    if (parts[1] == "WindowRadius") {
                                        win.Resources["BaseWindowRadius"] = new System.Windows.CornerRadiusConverter().ConvertFromString(val);
                                        if (Application.Current != null) Application.Current.Resources["BaseWindowRadius"] = win.Resources["BaseWindowRadius"];
                                        UpdateSnapState(win);
                                    } else {
                                        win.Resources[parts[1]] = new System.Windows.CornerRadiusConverter().ConvertFromString(val);
                                    }
                                }
                                else if (type == "Double") win.Resources[parts[1]] = double.Parse(val);
                            } else {
                                win.Resources[parts[1]] = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]);
                            }
                            if (Application.Current != null) Application.Current.Resources[parts[1]] = win.Resources[parts[1]];
                            // Force-apply ScrollBarWidth to all ScrollBar elements in the visual tree
                            if (parts[1] == "ScrollBarWidth" && win.Resources[parts[1]] is double) {
                                double sz = (double)win.Resources[parts[1]];
                                WalkVisualTree(win, (obj) => {
                                    if (obj is ScrollBar) {
                                        ScrollBar sb = (ScrollBar)obj;
                                        if (sb.Orientation == System.Windows.Controls.Orientation.Vertical) sb.Width = sz;
                                        else sb.Height = sz;
                                    }
                                });
                            }
                        } else {
                            object ctrl = parts[0] == "Window" ? win : win.FindName(parts[0]);
                            if (ctrl != null) {
                                if (parts[1] == "AddItem" && ctrl is ItemsControl) {
                                    ((ItemsControl)ctrl).Items.Add(parts[2]);
                                    if (ctrl is ListBox) {
                                        ListBox lb = (ListBox)ctrl;
                                        lb.SelectedIndex = lb.Items.Count - 1;
                                        lb.ScrollIntoView(lb.SelectedItem);
                                    }
                                } else if (parts[1] == "AddXamlItem" && ctrl is ItemsControl) {
                                    try {
                                        object element = XamlReader.Parse(parts[2]);
                                        ((ItemsControl)ctrl).Items.Add(element);
                                    } catch (Exception ex) {
                                        Console.WriteLine("XamlParse Error: " + ex.Message);
                                    }
                                } else if (parts[1] == "ClearItems" && ctrl is ItemsControl) {
                                    ((ItemsControl)ctrl).Items.Clear();
                                } else if (parts[1] == "Close" && ctrl is Window) {
                                    var ownerHwnd = new System.Windows.Interop.WindowInteropHelper((Window)ctrl).Owner;
                                    if (ownerHwnd != IntPtr.Zero) {
                                        SetForegroundWindow(ownerHwnd);
                                    }
                                    win.Dispatcher.BeginInvoke(new Action(() => ((Window)ctrl).Close()));
                                } else if (parts[1] == "AppendText" && ctrl is System.Windows.Controls.TextBox) {
                                    var tb = (System.Windows.Controls.TextBox)ctrl;
                                    tb.AppendText(parts[2]);
                                    tb.ScrollToEnd();
                                } else if (parts[1] == "NativeOwner" && ctrl is Window) {
                                    new System.Windows.Interop.WindowInteropHelper((Window)ctrl).Owner = new IntPtr(long.Parse(parts[2]));
                                } else if (parts[1] == "Focus" && ctrl is UIElement) {
                                    if (parts[2].ToLower() == "true") ((UIElement)ctrl).Focus();
                                    else System.Windows.Input.Keyboard.ClearFocus();
                                } else if (parts[1] == "Invoke" && ctrl is System.Windows.Controls.Primitives.ButtonBase) {
                                    if (ctrl is System.Windows.Controls.Primitives.ToggleButton) {
                                        var tPeer = new System.Windows.Automation.Peers.ToggleButtonAutomationPeer((System.Windows.Controls.Primitives.ToggleButton)ctrl);
                                        var toggleProv = tPeer.GetPattern(System.Windows.Automation.Peers.PatternInterface.Toggle) as System.Windows.Automation.Provider.IToggleProvider;
                                        if (toggleProv != null) toggleProv.Toggle();
                                    } else if (ctrl is System.Windows.Controls.Button) {
                                        var peer = new System.Windows.Automation.Peers.ButtonAutomationPeer((System.Windows.Controls.Button)ctrl);
                                        var invokeProv = peer.GetPattern(System.Windows.Automation.Peers.PatternInterface.Invoke) as System.Windows.Automation.Provider.IInvokeProvider;
                                        if (invokeProv != null) invokeProv.Invoke();
                                    }
                                } else if (parts[1] == "TrapScroll" && ctrl is ScrollViewer) {
                                    var sv = (ScrollViewer)ctrl;
                                    System.Windows.Input.MouseWheelEventHandler handler = (s, e) => {
                                        sv.ScrollToVerticalOffset(sv.VerticalOffset - e.Delta / 3.0);
                                        e.Handled = true;
                                    };
                                    sv.PreviewMouseWheel -= handler;
                                    sv.PreviewMouseWheel += handler;
                                    sv.MouseWheel -= handler;
                                    sv.MouseWheel += handler;
                                } else {
                                    var prop = ctrl.GetType().GetProperty(parts[1]);
                                    if (prop != null) {
                                        object val = null;
                                        string pt = prop.PropertyType.Name;
                                        if (pt == "Brush") val = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]);
                                        else if (prop.PropertyType.IsEnum) val = Enum.Parse(prop.PropertyType, parts[2], true);
                                        else if (pt == "Double") val = double.Parse(parts[2]);
                                        else if (pt == "Boolean" || pt == "Nullable`1") val = Convert.ToBoolean(parts[2]);
                                        else if (pt == "Thickness") val = new System.Windows.ThicknessConverter().ConvertFromString(parts[2]);
                                        else if (pt == "CornerRadius") val = new System.Windows.CornerRadiusConverter().ConvertFromString(parts[2]);
                                        else if (pt == "ImageSource") {
                                            if (parts[2].StartsWith("HICON:")) {
                                                IntPtr hIcon = new IntPtr(long.Parse(parts[2].Substring(6)));
                                                val = System.Windows.Interop.Imaging.CreateBitmapSourceFromHIcon(hIcon, System.Windows.Int32Rect.Empty, System.Windows.Media.Imaging.BitmapSizeOptions.FromEmptyOptions());
                                            } else {
                                                val = new System.Windows.Media.ImageSourceConverter().ConvertFromString(parts[2]);
                                            }
                                        }
                                        else if (pt == "Object" || pt == "String") val = parts[2];
                                        else val = Convert.ChangeType(parts[2], prop.PropertyType);
                                        prop.SetValue(ctrl, val, null);
                                    }
                                }
                            }
                        }
                    }
                
                    private void WalkVisualTree(System.Windows.DependencyObject parent, Action<System.Windows.DependencyObject> callback) {
                        int count = System.Windows.Media.VisualTreeHelper.GetChildrenCount(parent);
                        for (int i = 0; i < count; i++) {
                            var child = System.Windows.Media.VisualTreeHelper.GetChild(parent, i);
                            callback(child);
                            WalkVisualTree(child, callback);
                        }
                    }
                }
            )'
        }

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

        if !FileExist(targetExe) {
            csPath := A_Temp "\AhkWpf\AhkWpf_SharedEngine_v4.cs"
            if FileExist(csPath)
                FileDelete(csPath)
            FileAppend(csCode, csPath, "UTF-8")

            cscPath := "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
            if !FileExist(cscPath)
                cscPath := "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"

            SplitPath(cscPath, , &cscDir)
            wpfDir := cscDir "\WPF"

            resArg := (xamlFile != "") ? ' /resource:"' xamlFile '",AppXaml' : ""

            cmd := A_ComSpec ' /c ""' cscPath '" /nologo /target:winexe /out:"' targetExe '" /lib:"' wpfDir '" /reference:System.dll /reference:System.Core.dll /reference:System.Xml.dll /reference:PresentationFramework.dll /reference:PresentationCore.dll /reference:WindowsBase.dll /reference:System.Xaml.dll /reference:UIAutomationProvider.dll /reference:UIAutomationTypes.dll' resArg ' "' csPath '" > "' this.errLog '" 2>&1"'
            RunWait(cmd, "", "Hide")
            FileDelete(csPath)

            if !FileExist(targetExe) {
                errOut := FileExist(this.errLog) ? FileRead(this.errLog) : "Unknown compilation error."
                XAMLHost.ShowErrorDialog("Engine Compile Error", "Failed to compile background engine.", "", errOut)
                return
            }
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