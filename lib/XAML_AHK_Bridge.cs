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
using System.Windows.Documents;
#if ENABLE_WEBVIEW
using Microsoft.Web.WebView2.Wpf;
using Microsoft.Web.WebView2.Core;
#endif

[assembly: AssemblyTitle("ahk-xaml Engine")]
[assembly: AssemblyDescription("WPF Rendering Engine for AutoHotkey")]
[assembly: AssemblyCompany("owhs")]
[assembly: AssemblyProduct("ahk-xaml Shared Engine")]
[assembly: AssemblyCopyright("Copyright © 2026")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

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
    
    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hwProc);
    
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
    System.Collections.Generic.Dictionary<string, string> canvasModes = new System.Collections.Generic.Dictionary<string, string>();
    System.Windows.Shapes.Rectangle selectionBox = null;
    Point selectionStart;
    System.Windows.Shapes.Path tempConnection = null;
    FrameworkElement connectionSourcePort = null;

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
            if (args.Length >= 3 && args[0] == "--compress") {
                try {
                    byte[] data = System.IO.File.ReadAllBytes(args[1]);
                    using (var fs = new System.IO.FileStream(args[2], System.IO.FileMode.Create))
                    using (var gz = new System.IO.Compression.GZipStream(fs, System.IO.Compression.CompressionMode.Compress)) {
                        gz.Write(data, 0, data.Length);
                    }
                } catch (Exception ex) { Console.WriteLine(ex); }
                return;
            }
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
        string eventsContent = "";
        bool isBin = !string.IsNullOrEmpty(xamlFilePath) && xamlFilePath.EndsWith(".bin", StringComparison.OrdinalIgnoreCase);

        if (xamlFilePath == "STREAM") {
            HwndSourceParameters parameters = new HwndSourceParameters("MessageReceiver", 0, 0);
            parameters.WindowStyle = 0;
            HwndSource msgWindow = new HwndSource(parameters);
            
            bool received = false;
            msgWindow.AddHook((IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled) => {
                if (msg == 0x004A) {
                    try {
                        var cds = (COPYDATASTRUCT)Marshal.PtrToStructure(lParam, typeof(COPYDATASTRUCT));
                        byte[] bytes = new byte[cds.cbData];
                        Marshal.Copy(cds.lpData, bytes, 0, cds.cbData);
                        string text = Encoding.UTF8.GetString(bytes).TrimEnd('\0');
                        if (text.StartsWith("XAML_PAYLOAD|")) {
                            string payload = text.Substring(13);
                            string[] p = payload.Split(new[] { "\n---AHK-XAML-EVENTS---\n" }, 2, StringSplitOptions.None);
                            xamlContent = p[0];
                            if (p.Length > 1) {
                                eventsContent = p[1];
                            }
                            received = true;
                        }
                    } catch { }
                    handled = true;
                }
                return IntPtr.Zero;
            });
            
            SendToAhk("EVENT|" + winId + "|Engine|Ready|" + msgWindow.Handle.ToString() + "\n");
            
            DateTime startWait = DateTime.Now;
            while (!received && (DateTime.Now - startWait).TotalSeconds < 10) {
                System.Windows.Threading.Dispatcher.CurrentDispatcher.Invoke(System.Windows.Threading.DispatcherPriority.Background, new Action(delegate { }));
                System.Threading.Thread.Sleep(10);
            }
            msgWindow.Dispose();
            
            if (!received) {
                throw new Exception("Timed out waiting for XAML payload stream from AHK.");
            }
        } else if (!string.IsNullOrEmpty(xamlFilePath) && System.IO.File.Exists(xamlFilePath)) {
            if (isBin) {
                byte[] compressed = System.IO.File.ReadAllBytes(xamlFilePath);
                string payload = "";
                try {
                    using (var ms = new System.IO.MemoryStream(compressed))
                    using (var gz = new System.IO.Compression.GZipStream(ms, System.IO.Compression.CompressionMode.Decompress))
                    using (var reader = new System.IO.StreamReader(gz, Encoding.UTF8)) {
                        payload = reader.ReadToEnd();
                    }
                } catch (Exception dx) {
                    System.IO.File.WriteAllText(System.IO.Path.Combine(System.IO.Path.GetTempPath(), "AhkWpf", "decomp_err.log"), dx.ToString());
                    payload = Encoding.UTF8.GetString(compressed);
                }
                string[] parts = payload.Split(new[] { "\n---AHK-XAML-EVENTS---\n" }, 2, StringSplitOptions.None);
                xamlContent = parts[0];
                if (parts.Length > 1) {
                    eventsContent = parts[1];
                }
            } else {
                xamlContent = System.IO.File.ReadAllText(xamlFilePath, Encoding.UTF8);
            }
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
        
        if (!isBin && xamlFilePath != "STREAM" && !string.IsNullOrEmpty(xamlFilePath) && System.IO.File.Exists(xamlFilePath)) {
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
            xamlContent = null;
            xamlBytes = null;
            GC.Collect();
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
        
        win.Loaded += async (s, e) => {
            IntPtr hwnd = new WindowInteropHelper(win).Handle;
            HwndSource.FromHwnd(hwnd).AddHook(WndProc);
            SendToAhk("EVENT|" + winId + "|Window|LoadedHwnd|" + hwnd.ToString() + "\n");
            UpdateSnapState(win);
            DumpState("Window", "Loaded");
            
#if ENABLE_WEBVIEW
            var webViews = new System.Collections.Generic.List<WebView2>();
            WalkVisualTree(win, (obj) => {
                if (obj is WebView2) {
                    var wv = (WebView2)obj;
                    webViews.Add(wv);
                }
            });
            foreach (var wv in webViews) {
                try {
                    var env = await CoreWebView2Environment.CreateAsync(null, System.IO.Path.Combine(System.IO.Path.GetTempPath(), "AhkWebView2Data"));
                    await wv.EnsureCoreWebView2Async(env);
                    wv.CoreWebView2.WebMessageReceived += (ws, we) => {
                        SendToAhk("EVENT|" + winId + "|" + wv.Name + "|WebMessageReceived|" + Convert.ToBase64String(Encoding.UTF8.GetBytes(we.TryGetWebMessageAsString())) + "\n");
                    };
                    wv.NavigationCompleted += (ws, we) => {
                        SendToAhk("EVENT|" + winId + "|" + wv.Name + "|NavigationCompleted|" + Convert.ToBase64String(Encoding.UTF8.GetBytes(wv.Source != null ? wv.Source.ToString() : "")) + "\n");
                    };
                } catch (Exception ex) {
                    System.Windows.MessageBox.Show("WebView Init Error:\n" + ex.ToString(), "AHK-XAML WebView Error");
                }
            }
#endif
            
            // Aggressively flush the working set from RAM (WPF caches huge amounts of unused startup structures)
            var timer = new System.Windows.Threading.DispatcherTimer { Interval = TimeSpan.FromSeconds(1.5) };
            timer.Tick += (sender, args) => {
                timer.Stop();
                win.Topmost = true;
                win.Topmost = false;
                win.Activate();
                try { System.Runtime.GCSettings.LargeObjectHeapCompactionMode = System.Runtime.GCLargeObjectHeapCompactionMode.CompactOnce; } catch { }
                GC.Collect(GC.MaxGeneration, GCCollectionMode.Forced, true, true);
                GC.WaitForPendingFinalizers();
                GC.Collect();
                try { EmptyWorkingSet(System.Diagnostics.Process.GetCurrentProcess().Handle); } catch { }
            };
            timer.Start();
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

        if (isBin || xamlFilePath == "STREAM") {
            if (!string.IsNullOrEmpty(eventsContent)) {
                string[] pairs = eventsContent.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string p in pairs) {
                    string[] kv = p.Split(':');
                    if (kv.Length == 2) BindEvent(kv[0], kv[1]);
                }
            }
        } else if (!string.IsNullOrEmpty(eventsFilePath) && System.IO.File.Exists(eventsFilePath)) {
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
        
        eventsContent = null;
        
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
            System.Linq.Expressions.MethodCallExpression call;
            
            if (pExprs.Length >= 2) {
                var dumpStateWithArgsMethod = this.GetType().GetMethod("DumpStateWithArgs", BindingFlags.NonPublic | BindingFlags.Instance);
                // Convert pExprs[1] to object to match the method signature
                var objCast = System.Linq.Expressions.Expression.Convert(pExprs[1], typeof(object));
                call = System.Linq.Expressions.Expression.Call(System.Linq.Expressions.Expression.Constant(this), dumpStateWithArgsMethod, System.Linq.Expressions.Expression.Constant(ctrlName), System.Linq.Expressions.Expression.Constant(eventName), objCast);
            } else {
                var dumpStateMethod = this.GetType().GetMethod("DumpState", BindingFlags.NonPublic | BindingFlags.Instance);
                call = System.Linq.Expressions.Expression.Call(System.Linq.Expressions.Expression.Constant(this), dumpStateMethod, System.Linq.Expressions.Expression.Constant(ctrlName), System.Linq.Expressions.Expression.Constant(eventName));
            }
            
            var lambda = System.Linq.Expressions.Expression.Lambda(evt.EventHandlerType, call, pExprs);
            evt.AddEventHandler(ctrl, lambda.Compile());
        } catch { }
    }

    public string CollectState() {
        var sb = new StringBuilder();
        foreach (var t in tracked) {
            string cName = t;
            bool wantsCaret = false;
            if (cName.EndsWith("_CaretIndex")) {
                cName = cName.Substring(0, cName.Length - 11);
                wantsCaret = true;
            }
            
            var c = win.FindName(cName);
            if (c != null) {
                string val = "";
                if (wantsCaret && c is TextBox) val = ((TextBox)c).CaretIndex.ToString();
                else if (c is TextBox) val = ((TextBox)c).Text;
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

    private DateTime lastSendMouseMove = DateTime.MinValue;

    private void DumpStateWithArgs(string cName, string eName, object e) {
        if (e is System.Windows.Input.KeyEventArgs) {
            eName += ":" + ((System.Windows.Input.KeyEventArgs)e).Key.ToString();
        }
        DumpState(cName, eName);
    }

    private void DumpState(string cName, string eName) {
        var ctrl = win.FindName(cName) as FrameworkElement;
        if (ctrl != null) {
            if (eName == "TextChanged" && !ctrl.IsKeyboardFocusWithin) return;
            if (eName == "ValueChanged" && !ctrl.IsMouseOver && !ctrl.IsKeyboardFocusWithin && !ctrl.IsMouseCaptured) return;
        }

        if (eName == "MouseMove" || eName == "PreviewMouseMove") {
            if ((DateTime.Now - lastSendMouseMove).TotalMilliseconds < 16) return;
            lastSendMouseMove = DateTime.Now;
        }
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
                } else if (parts[1] == "AddXamlItem") {
                    try {
                        object element = XamlReader.Parse(parts[2]);
                        
                        // Register names in the current window's NameScope so FindName works for dynamic elements
                        Action<DependencyObject> registerNames = null;
                        registerNames = new Action<DependencyObject>((DependencyObject d) => {
                            if (d is FrameworkElement) {
                                var fe = (FrameworkElement)d;
                                if (!string.IsNullOrEmpty(fe.Name)) {
                                    try { win.RegisterName(fe.Name, fe); } catch { }
                                }
                            }
                            int count = System.Windows.Media.VisualTreeHelper.GetChildrenCount(d);
                            for (int i = 0; i < count; i++) {
                                registerNames(System.Windows.Media.VisualTreeHelper.GetChild(d, i));
                            }
                        });
                        registerNames((DependencyObject)element);

                        if (ctrl is ItemsControl) {
                            ((ItemsControl)ctrl).Items.Add(element);
                        } else if (ctrl is System.Windows.Controls.Panel) {
                            ((System.Windows.Controls.Panel)ctrl).Children.Add((UIElement)element);
                        }
                    } catch (Exception ex) {
                        Console.WriteLine("XamlParse Error: " + ex.Message);
                    }
                } else if (parts[1] == "Document" && ctrl is RichTextBox) {
                    try {
                        FlowDocument doc = (FlowDocument)XamlReader.Parse(parts[2]);
                        ((RichTextBox)ctrl).Document = doc;
                    } catch (Exception ex) {
                        System.IO.File.AppendAllText("xaml_parse_error.log", "Parse Error: " + ex.Message + "\n" + (ex.InnerException != null ? ex.InnerException.Message : "") + "\nString: " + parts[2] + "\n\n");
                    }
                } else if (parts[1] == "Background" && ctrl is System.Windows.Controls.Control) {
                    if (parts[2].StartsWith("{DynamicResource ") && parts[2].EndsWith("}")) ((System.Windows.Controls.Control)ctrl).SetResourceReference(System.Windows.Controls.Control.BackgroundProperty, parts[2].Substring(17, parts[2].Length - 18));
                    else ((System.Windows.Controls.Control)ctrl).Background = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]) as System.Windows.Media.Brush;
                } else if (parts[1] == "Foreground" && ctrl is System.Windows.Controls.Control) {
                    if (parts[2].StartsWith("{DynamicResource ") && parts[2].EndsWith("}")) ((System.Windows.Controls.Control)ctrl).SetResourceReference(System.Windows.Controls.Control.ForegroundProperty, parts[2].Substring(17, parts[2].Length - 18));
                    else ((System.Windows.Controls.Control)ctrl).Foreground = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]) as System.Windows.Media.Brush;
                } else if (parts[1] == "BorderBrush" && ctrl is Border) {
                    if (parts[2].StartsWith("{DynamicResource ") && parts[2].EndsWith("}")) ((Border)ctrl).SetResourceReference(Border.BorderBrushProperty, parts[2].Substring(17, parts[2].Length - 18));
                    else ((Border)ctrl).BorderBrush = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]) as System.Windows.Media.Brush;
                } else if (parts[1] == "Stroke" && ctrl is System.Windows.Shapes.Shape) {
                    if (parts[2].StartsWith("{DynamicResource ") && parts[2].EndsWith("}")) ((System.Windows.Shapes.Shape)ctrl).SetResourceReference(System.Windows.Shapes.Shape.StrokeProperty, parts[2].Substring(17, parts[2].Length - 18));
                    else ((System.Windows.Shapes.Shape)ctrl).Stroke = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]) as System.Windows.Media.Brush;
                } else if (parts[1] == "Fill" && ctrl is System.Windows.Shapes.Shape) {
                    if (parts[2].StartsWith("{DynamicResource ") && parts[2].EndsWith("}")) ((System.Windows.Shapes.Shape)ctrl).SetResourceReference(System.Windows.Shapes.Shape.FillProperty, parts[2].Substring(17, parts[2].Length - 18));
                    else ((System.Windows.Shapes.Shape)ctrl).Fill = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]) as System.Windows.Media.Brush;
                } else if (parts[1] == "StrokeThickness" && ctrl is System.Windows.Shapes.Shape) {
                    ((System.Windows.Shapes.Shape)ctrl).StrokeThickness = double.Parse(parts[2]);
                } else if (parts[1] == "RemoveItem" && ctrl is ItemsControl) {
                    var itemsControl = (ItemsControl)ctrl;
                    object toRemove = null;
                    foreach (var item in itemsControl.Items) {
                        bool match = item.ToString() == parts[2];
                        if (!match && item is System.Windows.Controls.ListBoxItem) {
                            var lbi = (System.Windows.Controls.ListBoxItem)item;
                            match = (lbi.Content != null && lbi.Content.ToString() == parts[2]);
                        }
                        if (match) {
                            toRemove = item;
                            break;
                        }
                    }
                    if (toRemove != null) {
                        itemsControl.Items.Remove(toRemove);
                    }
                } else if (parts[1] == "ClearItems") {
                    if (ctrl is ItemsControl) {
                        ((ItemsControl)ctrl).Items.Clear();
                    } else if (ctrl is System.Windows.Controls.Panel) {
                        ((System.Windows.Controls.Panel)ctrl).Children.Clear();
                    }
                } else if (parts[1] == "Play" && ctrl is MediaElement) {
                    ((MediaElement)ctrl).Play();
                } else if (parts[1] == "Pause" && ctrl is MediaElement) {
                    ((MediaElement)ctrl).Pause();
                } else if (parts[1] == "Stop" && ctrl is MediaElement) {
                    ((MediaElement)ctrl).Stop();
                } else if (parts[1] == "Seek" && ctrl is MediaElement) {
                    double secs;
                    if (double.TryParse(parts[2], out secs)) {
                        ((MediaElement)ctrl).Position = TimeSpan.FromSeconds(secs);
                    }
                } else if (parts[1] == "NavigateToString" && ctrl is System.Windows.Controls.WebBrowser) {
                    try {
                        byte[] htmlBytes = Convert.FromBase64String(parts[2]);
                        string html = Encoding.UTF8.GetString(htmlBytes);
                        ((System.Windows.Controls.WebBrowser)ctrl).NavigateToString(html);
                    } catch (Exception ex) {
                        Console.WriteLine("NavigateToString error: " + ex.Message);
                    }
#if ENABLE_WEBVIEW
                } else if (parts[1] == "Navigate" && ctrl is Microsoft.Web.WebView2.Wpf.WebView2) {
                    try {
                        ((Microsoft.Web.WebView2.Wpf.WebView2)ctrl).CoreWebView2.Navigate(parts[2]);
                    } catch { }
                } else if (parts[1] == "ExecuteScript" && ctrl is Microsoft.Web.WebView2.Wpf.WebView2) {
                    try {
                        ((Microsoft.Web.WebView2.Wpf.WebView2)ctrl).CoreWebView2.ExecuteScriptAsync(Encoding.UTF8.GetString(Convert.FromBase64String(parts[2])));
                    } catch { }
                } else if (parts[1] == "PostWebMessage" && ctrl is Microsoft.Web.WebView2.Wpf.WebView2) {
                    try {
                        ((Microsoft.Web.WebView2.Wpf.WebView2)ctrl).CoreWebView2.PostWebMessageAsString(parts[2]);
                    } catch { }
                } else if (parts[1] == "GoBack" && ctrl is Microsoft.Web.WebView2.Wpf.WebView2) {
                    try { ((Microsoft.Web.WebView2.Wpf.WebView2)ctrl).GoBack(); } catch { }
                } else if (parts[1] == "GoForward" && ctrl is Microsoft.Web.WebView2.Wpf.WebView2) {
                    try { ((Microsoft.Web.WebView2.Wpf.WebView2)ctrl).GoForward(); } catch { }
                } else if (parts[1] == "Refresh" && ctrl is Microsoft.Web.WebView2.Wpf.WebView2) {
                    try { ((Microsoft.Web.WebView2.Wpf.WebView2)ctrl).Reload(); } catch { }
                } else if (parts[1] == "OpenDevTools" && ctrl is Microsoft.Web.WebView2.Wpf.WebView2) {
                    try { ((Microsoft.Web.WebView2.Wpf.WebView2)ctrl).CoreWebView2.OpenDevToolsWindow(); } catch { }
#endif
                } else if (parts[1] == "StartPositionTimer" && ctrl is MediaElement) {
                    // Handle all position tracking and seeking in C# to avoid IPC feedback loops
                    var me = (MediaElement)ctrl;
                    string sliderName = parts.Length > 2 ? parts[2] : "";
                    if (!string.IsNullOrEmpty(sliderName)) {
                        var slider = win.FindName(sliderName) as Slider;
                        if (slider != null) {
                            bool isSeeking = false;
                            bool isUpdating = false;
                            
                            // Detect user drag start/end via Thumb routed events
                            slider.AddHandler(Thumb.DragStartedEvent, new DragStartedEventHandler((ds, de) => {
                                isSeeking = true;
                            }));
                            slider.AddHandler(Thumb.DragCompletedEvent, new DragCompletedEventHandler((dc, dce) => {
                                me.Position = TimeSpan.FromSeconds(slider.Value);
                                isSeeking = false;
                            }));
                            
                            // Also handle click-on-track seeking
                            slider.PreviewMouseLeftButtonUp += (mu, mue) => {
                                if (!isSeeking) {
                                    me.Position = TimeSpan.FromSeconds(slider.Value);
                                }
                            };
                            
                            // Timer syncs slider position (only when user isn't seeking)
                            var posTimer = new System.Windows.Threading.DispatcherTimer { Interval = TimeSpan.FromMilliseconds(250) };
                            posTimer.Tick += (s, e) => {
                                if (me.NaturalDuration.HasTimeSpan && !isSeeking) {
                                    isUpdating = true;
                                    slider.Maximum = me.NaturalDuration.TimeSpan.TotalSeconds;
                                    slider.Value = me.Position.TotalSeconds;
                                    isUpdating = false;
                                }
                            };
                            posTimer.Start();
                        }
                    }
                } else if (parts[1] == "SetPosition" && ctrl is UIElement) {
                    var coords = parts[2].Split(',');
                    if (coords.Length >= 2) {
                        Canvas.SetLeft((UIElement)ctrl, double.Parse(coords[0]));
                        Canvas.SetTop((UIElement)ctrl, double.Parse(coords[1]));
                    }
                } else if (parts[1] == "SetCanvasMode" && ctrl is Canvas) {
                    canvasModes[parts[0]] = parts[2];
                } else if (parts[1] == "EnableZoomPan" && ctrl is Canvas) {
                    EnableCanvasZoomPan((Canvas)ctrl);
                } else if (parts[1] == "ZoomAll" && ctrl is Canvas) {
                    ZoomAllCanvas((Canvas)ctrl);
                } else if (parts[1] == "Zoom" && ctrl is Canvas) {
                    ZoomCanvas((Canvas)ctrl, double.Parse(parts[2], System.Globalization.CultureInfo.InvariantCulture));
                } else if (parts[1] == "EnableDrag" && ctrl is FrameworkElement) {
                    EnableCanvasDrag((FrameworkElement)ctrl, parts[0], parts.Length > 2 ? parts[2] : "");
                } else if (parts[1] == "EnableListBoxDragDrop" && ctrl is ListBox) {
                    EnableListBoxDragDrop((ListBox)ctrl, parts[0]);
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
                } else if (parts[1] == "InsertText" && ctrl is System.Windows.Controls.TextBox) {
                    var tb = (System.Windows.Controls.TextBox)ctrl;
                    int idx = tb.CaretIndex;
                    string pre = tb.Text.Substring(0, idx);
                    string post = tb.Text.Substring(idx);
                    tb.Text = pre + parts[2] + post;
                    tb.CaretIndex = idx + parts[2].Length;
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
                        else if (pt == "GridLength") val = new System.Windows.GridLengthConverter().ConvertFromString(parts[2]);
                        else if (pt == "Object" || pt == "String") val = parts[2];
                        else if (pt == "Uri") val = new Uri(parts[2], UriKind.RelativeOrAbsolute);
                        else if (pt == "Rect") val = System.Windows.Rect.Parse(parts[2]);
                        else if (pt == "Geometry") val = System.Windows.Media.Geometry.Parse(parts[2]);
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

    // Canvas drag infrastructure: enables real-time C#-side mouse tracking that sends events to AHK
    private System.Collections.Generic.Dictionary<string, double> nodeGridSizes = new System.Collections.Generic.Dictionary<string, double>();
    private System.Collections.Generic.Dictionary<FrameworkElement, bool> dragEnabled = new System.Collections.Generic.Dictionary<FrameworkElement, bool>();
    
    private void EnableCanvasDrag(FrameworkElement ctrl, string ctrlName, string mode) {
        if (mode == "crop") {
            EnableCropDrag(ctrl, ctrlName);
            return;
        }
        
        double gridSize = 1;
        if (mode.StartsWith("grid=")) double.TryParse(mode.Substring(5), out gridSize);
        if (gridSize < 1) gridSize = 1;
        
        nodeGridSizes[ctrlName] = gridSize;
        if (dragEnabled.ContainsKey(ctrl) && dragEnabled[ctrl]) return;
        dragEnabled[ctrl] = true;
        
        bool isDragging = false;
        Point dragStart = new Point();
        double startLeft = 0, startTop = 0;
        DateTime lastSend = DateTime.MinValue;
        
        ctrl.MouseLeftButtonDown += (s, e) => {
            isDragging = true;
            dragStart = e.GetPosition((UIElement)ctrl.Parent);
            startLeft = Canvas.GetLeft(ctrl);
            startTop = Canvas.GetTop(ctrl);
            if (double.IsNaN(startLeft)) startLeft = 0;
            if (double.IsNaN(startTop)) startTop = 0;
            System.Windows.Controls.Panel.SetZIndex(ctrl, 999);
            
            bool isCtrl = System.Windows.Input.Keyboard.Modifiers.HasFlag(System.Windows.Input.ModifierKeys.Control);
            string evName = isCtrl ? "CtrlSelectNode" : "SelectNode";
            SendToAhk("EVENT|" + winId + "|" + ctrlName + "|" + evName + "|\n");
            
            ctrl.CaptureMouse();
            e.Handled = true;
        };
        ctrl.MouseMove += (s, e) => {
            if (!isDragging) return;
            var pos = e.GetPosition((UIElement)ctrl.Parent);
            double dx = pos.X - dragStart.X;
            double dy = pos.Y - dragStart.Y;
            double newLeft = startLeft + dx;
            double newTop = startTop + dy;
            
            double currentGridSize = nodeGridSizes.ContainsKey(ctrlName) ? nodeGridSizes[ctrlName] : 1;
            if (currentGridSize > 1) {
                newLeft = Math.Round(newLeft / currentGridSize) * currentGridSize;
                newTop = Math.Round(newTop / currentGridSize) * currentGridSize;
            }
            
            Canvas.SetLeft(ctrl, newLeft);
            Canvas.SetTop(ctrl, newTop);
            // Throttle event sends to every 50ms
            if ((DateTime.Now - lastSend).TotalMilliseconds > 50) {
                lastSend = DateTime.Now;
                SendToAhk("EVENT|" + winId + "|" + ctrlName + "|DragMove|" + 
                    Convert.ToBase64String(Encoding.UTF8.GetBytes(newLeft.ToString("F0") + "," + newTop.ToString("F0"))) + "\n");
            }
            e.Handled = true;
        };
        ctrl.MouseLeftButtonUp += (s, e) => {
            if (!isDragging) return;
            isDragging = false;
            System.Windows.Controls.Panel.SetZIndex(ctrl, 0);
            ctrl.ReleaseMouseCapture();
            // Send final position
            double finalLeft = Canvas.GetLeft(ctrl);
            double finalTop = Canvas.GetTop(ctrl);
            SendToAhk("EVENT|" + winId + "|" + ctrlName + "|DragMove|" + 
                Convert.ToBase64String(Encoding.UTF8.GetBytes(finalLeft.ToString("F0") + "," + finalTop.ToString("F0"))) + "\n");
            DumpState(ctrlName, "DragEnd");
            e.Handled = true;
        };
    }
    
    private void EnableCropDrag(FrameworkElement box, string boxName) {
        // Box drag (move the crop area)
        bool boxDragging = false;
        Point boxDragStart = new Point();
        double boxStartLeft = 0, boxStartTop = 0;
        
        box.MouseLeftButtonDown += (s, e) => {
            boxDragging = true;
            boxDragStart = e.GetPosition((UIElement)box.Parent);
            boxStartLeft = Canvas.GetLeft(box);
            boxStartTop = Canvas.GetTop(box);
            if (double.IsNaN(boxStartLeft)) boxStartLeft = 0;
            if (double.IsNaN(boxStartTop)) boxStartTop = 0;
            box.CaptureMouse();
            e.Handled = true;
        };
        box.MouseMove += (s, e) => {
            if (!boxDragging) return;
            var pos = e.GetPosition((UIElement)box.Parent);
            Canvas.SetLeft(box, boxStartLeft + (pos.X - boxDragStart.X));
            Canvas.SetTop(box, boxStartTop + (pos.Y - boxDragStart.Y));
            e.Handled = true;
        };
        box.MouseLeftButtonUp += (s, e) => {
            if (!boxDragging) return;
            boxDragging = false;
            box.ReleaseMouseCapture();
            e.Handled = true;
        };
        
        // Find handles inside the box by name convention
        string baseName = boxName.Replace("_Box", "");
        var hSE = win.FindName(baseName + "_HSE") as FrameworkElement;
        if (hSE != null) {
            bool seResizing = false;
            Point seStart = new Point();
            double seStartW = 0, seStartH = 0;
            
            hSE.MouseLeftButtonDown += (s, e) => {
                seResizing = true;
                seStart = e.GetPosition((UIElement)box.Parent);
                seStartW = box.Width;
                seStartH = box.Height;
                if (double.IsNaN(seStartW)) seStartW = 100;
                if (double.IsNaN(seStartH)) seStartH = 100;
                hSE.CaptureMouse();
                e.Handled = true;
            };
            hSE.MouseMove += (s, e) => {
                if (!seResizing) return;
                var pos = e.GetPosition((UIElement)box.Parent);
                double nw = Math.Max(50, seStartW + (pos.X - seStart.X));
                double nh = Math.Max(50, seStartH + (pos.Y - seStart.Y));
                box.Width = nw;
                box.Height = nh;
                e.Handled = true;
            };
            hSE.MouseLeftButtonUp += (s, e) => {
                if (!seResizing) return;
                seResizing = false;
                hSE.ReleaseMouseCapture();
                e.Handled = true;
            };
        }
        
        var hNW = win.FindName(baseName + "_HNW") as FrameworkElement;
        if (hNW != null) {
            bool nwResizing = false;
            Point nwStart = new Point();
            double nwStartL = 0, nwStartT = 0, nwStartW = 0, nwStartH = 0;
            
            hNW.MouseLeftButtonDown += (s, e) => {
                nwResizing = true;
                nwStart = e.GetPosition((UIElement)box.Parent);
                nwStartL = Canvas.GetLeft(box);
                nwStartT = Canvas.GetTop(box);
                nwStartW = box.Width;
                nwStartH = box.Height;
                if (double.IsNaN(nwStartL)) nwStartL = 0;
                if (double.IsNaN(nwStartT)) nwStartT = 0;
                if (double.IsNaN(nwStartW)) nwStartW = 100;
                if (double.IsNaN(nwStartH)) nwStartH = 100;
                hNW.CaptureMouse();
                e.Handled = true;
            };
            hNW.MouseMove += (s, e) => {
                if (!nwResizing) return;
                var pos = e.GetPosition((UIElement)box.Parent);
                double dx = pos.X - nwStart.X;
                double dy = pos.Y - nwStart.Y;
                double nw = Math.Max(50, nwStartW - dx);
                double nh = Math.Max(50, nwStartH - dy);
                if (nw > 50) { Canvas.SetLeft(box, nwStartL + dx); box.Width = nw; }
                if (nh > 50) { Canvas.SetTop(box, nwStartT + dy); box.Height = nh; }
                e.Handled = true;
            };
            hNW.MouseLeftButtonUp += (s, e) => {
                if (!nwResizing) return;
                nwResizing = false;
                hNW.ReleaseMouseCapture();
                e.Handled = true;
            };
        }
    }
    
    private void EnableCanvasZoomPan(Canvas canvas) {
        // Apply a TransformGroup to the canvas for zoom + pan
        var scaleTransform = new System.Windows.Media.ScaleTransform(1, 1);
        var translateTransform = new System.Windows.Media.TranslateTransform(0, 0);
        var tg = new System.Windows.Media.TransformGroup();
        tg.Children.Add(scaleTransform);
        tg.Children.Add(translateTransform);
        canvas.RenderTransform = tg;
        canvas.RenderTransformOrigin = new Point(0, 0);
        
        // Zoom via mouse wheel
        var parent = canvas.Parent as FrameworkElement;
        if (parent != null) {
            parent.PreviewMouseWheel += (s, e) => {
                double zoom = e.Delta > 0 ? 1.1 : 0.9;
                double scaleX = scaleTransform.ScaleX;
                double newScale = scaleX * zoom;
                if (newScale < 0.2) newScale = 0.2;
                if (newScale > 5.0) newScale = 5.0;
                
                // Zoom keeping mouse position invariant
                var canvasPos = e.GetPosition(canvas);
                translateTransform.X = translateTransform.X + canvasPos.X * (scaleX - newScale);
                translateTransform.Y = translateTransform.Y + canvasPos.Y * (scaleX - newScale);
                
                scaleTransform.ScaleX = newScale;
                scaleTransform.ScaleY = newScale;
                e.Handled = true;
            };
            
            // Pan via middle-click drag
            bool isPanning = false;
            bool panMoved = false;
            Point panStart = new Point();
            double panStartTX = 0, panStartTY = 0;
            
            bool isKnifing = false;
            System.Windows.Shapes.Path tempKnife = null;
            Point knifeStart = new Point();
            Point lastKnifePos = new Point();
            string lastSelectionSet = "";
            
            parent.MouseDown += (s, e) => {
                if (e.ChangedButton == System.Windows.Input.MouseButton.Middle) {
                    isPanning = true;
                    panMoved = false;
                    panStart = e.GetPosition(parent);
                    panStartTX = translateTransform.X;
                    panStartTY = translateTransform.Y;
                    parent.CaptureMouse();
                    parent.Cursor = System.Windows.Input.Cursors.Hand;
                    e.Handled = true;
                }
            };
            
            parent.PreviewMouseRightButtonDown += (s, e) => {
                var pos = e.GetPosition(canvas);
                string coords = pos.X.ToString(System.Globalization.CultureInfo.InvariantCulture) + "," + pos.Y.ToString(System.Globalization.CultureInfo.InvariantCulture);
                SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ContextMenuOpened|" + Convert.ToBase64String(Encoding.UTF8.GetBytes(coords)) + "\n");
            };
            
            // Mode logic: Left click on empty space (Canvas) triggers Pan or Select
            parent.MouseLeftButtonDown += (s, e) => {
                var el = e.OriginalSource as FrameworkElement;
                if (el != null && el.Name != null && el.Name.StartsWith("Port_")) {
                    connectionSourcePort = el;
                    if (tempConnection == null) {
                        tempConnection = new System.Windows.Shapes.Path {
                            Stroke = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(96, 160, 255)),
                            StrokeThickness = 2.5,
                            Opacity = 0.8,
                            IsHitTestVisible = false
                        };
                        System.Windows.Controls.Panel.SetZIndex(tempConnection, -1);
                        canvas.Children.Add(tempConnection);
                    }
                    tempConnection.Visibility = Visibility.Visible;
                    parent.CaptureMouse();
                    e.Handled = true;
                    return;
                }
                
                string mode = "Pan";
                if (canvasModes.ContainsKey(canvas.Name)) mode = canvasModes[canvas.Name];
                
                if (mode == "Pan") {
                    isPanning = true;
                    panMoved = false;
                    panStart = e.GetPosition(parent);
                    panStartTX = translateTransform.X;
                    panStartTY = translateTransform.Y;
                    parent.CaptureMouse();
                    parent.Cursor = System.Windows.Input.Cursors.Hand;
                    e.Handled = true;
                } else if (mode == "Select") {
                    selectionStart = e.GetPosition(canvas);
                    if (selectionBox == null) {
                        selectionBox = new System.Windows.Shapes.Rectangle {
                            Stroke = System.Windows.Media.Brushes.DodgerBlue,
                            StrokeThickness = 1,
                            Fill = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(50, 30, 144, 255)),
                            IsHitTestVisible = false
                        };
                        System.Windows.Controls.Panel.SetZIndex(selectionBox, 9999);
                        canvas.Children.Add(selectionBox);
                    }
                    Canvas.SetLeft(selectionBox, selectionStart.X);
                    Canvas.SetTop(selectionBox, selectionStart.Y);
                    selectionBox.Width = 0;
                    selectionBox.Height = 0;
                    selectionBox.Visibility = Visibility.Visible;
                    lastSelectionSet = "FORCE_UPDATE";
                    parent.CaptureMouse();
                    e.Handled = true;
                } else if (mode == "Knife") {
                    isKnifing = true;
                    knifeStart = e.GetPosition(canvas);
                    lastKnifePos = knifeStart;
                    if (tempKnife == null) {
                        tempKnife = new System.Windows.Shapes.Path {
                            Stroke = System.Windows.Media.Brushes.Red,
                            StrokeThickness = 2,
                            StrokeDashArray = new System.Windows.Media.DoubleCollection(new double[] { 4, 4 }),
                            IsHitTestVisible = false
                        };
                        System.Windows.Controls.Panel.SetZIndex(tempKnife, 9999);
                        canvas.Children.Add(tempKnife);
                    }
                    tempKnife.Visibility = Visibility.Visible;
                    parent.CaptureMouse();
                    e.Handled = true;
                }
            };
            parent.MouseMove += (s, e) => {
                if (isPanning) {
                    var pos = e.GetPosition(parent);
                    if (Math.Abs(pos.X - panStart.X) > 2 || Math.Abs(pos.Y - panStart.Y) > 2) panMoved = true;
                    translateTransform.X = panStartTX + (pos.X - panStart.X);
                    translateTransform.Y = panStartTY + (pos.Y - panStart.Y);
                    e.Handled = true;
                } else if (selectionBox != null && selectionBox.Visibility == Visibility.Visible) {
                    var pos = e.GetPosition(canvas);
                    double x = Math.Min(pos.X, selectionStart.X);
                    double y = Math.Min(pos.Y, selectionStart.Y);
                    double w = Math.Abs(pos.X - selectionStart.X);
                    double h = Math.Abs(pos.Y - selectionStart.Y);
                    Canvas.SetLeft(selectionBox, x);
                    Canvas.SetTop(selectionBox, y);
                    selectionBox.Width = w;
                    selectionBox.Height = h;
                    
                    var currentSelected = new System.Collections.Generic.List<string>();
                    foreach (UIElement child in canvas.Children) {
                        var fe = child as FrameworkElement;
                        if (fe != null && fe.Name != null && fe.Name.StartsWith("Node_")) {
                            double nx = Canvas.GetLeft(fe);
                            double ny = Canvas.GetTop(fe);
                            if (double.IsNaN(nx)) nx = 0;
                            if (double.IsNaN(ny)) ny = 0;
                            double nw = fe.ActualWidth;
                            double nh = fe.ActualHeight;
                            if (nx < x + w && nx + nw > x && ny < y + h && ny + nh > y) {
                                currentSelected.Add(fe.Name.Substring(5));
                            }
                        }
                    }
                    string newSet = string.Join(",", currentSelected);
                    if (newSet != lastSelectionSet) {
                        lastSelectionSet = newSet;
                        bool isCtrl = System.Windows.Input.Keyboard.Modifiers.HasFlag(System.Windows.Input.ModifierKeys.Control);
                        string evName = isCtrl ? "CtrlSelectionBox" : "SelectionBox";
                        SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|" + evName + "|" + 
                            Convert.ToBase64String(Encoding.UTF8.GetBytes(newSet)) + "\n");
                    }
                    e.Handled = true;
                } else if (connectionSourcePort != null && tempConnection != null && tempConnection.Visibility == Visibility.Visible) {
                    var pos = e.GetPosition(canvas);
                    double startX = Canvas.GetLeft(connectionSourcePort) + connectionSourcePort.Width / 2;
                    double startY = Canvas.GetTop(connectionSourcePort) + connectionSourcePort.Height / 2;
                    if (double.IsNaN(startX)) startX = 0;
                    if (double.IsNaN(startY)) startY = 0;
                    double endX = pos.X;
                    double endY = pos.Y;
                    
                    // Allow dragging from out port to in port
                    double dx = Math.Max(40, Math.Abs(endX - startX) * 0.5);
                    double c1X = startX + dx;
                    double c2X = endX - dx;
                    if (connectionSourcePort.Name.StartsWith("Port_In")) {
                        c1X = startX - dx;
                        c2X = endX + dx;
                    }
                    
                    string geom = string.Format(System.Globalization.CultureInfo.InvariantCulture, "M{0},{1} C{2},{3} {4},{5} {6},{7}", startX, startY, c1X, startY, c2X, endY, endX, endY);
                    try { tempConnection.Data = System.Windows.Media.Geometry.Parse(geom); } catch { }
                    e.Handled = true;
                } else if (isKnifing && tempKnife != null && tempKnife.Visibility == Visibility.Visible) {
                    var pos = e.GetPosition(canvas);
                    string geom = string.Format(System.Globalization.CultureInfo.InvariantCulture, "M{0},{1} L{2},{3}", knifeStart.X, knifeStart.Y, pos.X, pos.Y);
                    try { tempKnife.Data = System.Windows.Media.Geometry.Parse(geom); } catch { }
                    
                    System.Windows.Media.VisualTreeHelper.HitTest(canvas, null,
                        new System.Windows.Media.HitTestResultCallback((result) => {
                            var hitEl = result.VisualHit as FrameworkElement;
                            if (hitEl != null && hitEl.Name != null && hitEl.Name.Contains("_Path_") && hitEl.Visibility == Visibility.Visible) {
                                hitEl.Visibility = Visibility.Collapsed;
                                SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|DeleteConnection|" + 
                                    Convert.ToBase64String(Encoding.UTF8.GetBytes(hitEl.Name)) + "\n");
                            }
                            return System.Windows.Media.HitTestResultBehavior.Continue;
                        }),
                        new System.Windows.Media.GeometryHitTestParameters(new System.Windows.Media.LineGeometry(lastKnifePos, pos))
                    );
                    lastKnifePos = pos;
                    e.Handled = true;
                }
            };
            parent.MouseUp += (s, e) => {
                if (e.ChangedButton == System.Windows.Input.MouseButton.Middle && isPanning) {
                    isPanning = false;
                    parent.ReleaseMouseCapture();
                    parent.Cursor = System.Windows.Input.Cursors.Arrow;
                    e.Handled = true;
                }
            };
            parent.MouseLeftButtonUp += (s, e) => {
                if (isPanning) {
                    isPanning = false;
                    parent.ReleaseMouseCapture();
                    parent.Cursor = System.Windows.Input.Cursors.Arrow;
                    if (!panMoved) {
                        SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ClearSelection|\n");
                    }
                    e.Handled = true;
                } else if (selectionBox != null && selectionBox.Visibility == Visibility.Visible) {
                    selectionBox.Visibility = Visibility.Collapsed;
                    parent.ReleaseMouseCapture();
                    if (lastSelectionSet == "FORCE_UPDATE") {
                        SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ClearSelection|\n");
                    }
                    lastSelectionSet = "";
                    e.Handled = true;
                } else if (connectionSourcePort != null && tempConnection != null && tempConnection.Visibility == Visibility.Visible) {
                    tempConnection.Visibility = Visibility.Collapsed;
                    parent.ReleaseMouseCapture();
                    Point dropPos = e.GetPosition(canvas);
                    
                    // Magnetic search for closest port
                    FrameworkElement closestPort = null;
                    double minDistance = 625; // 25^2
                    
                    foreach (UIElement child in canvas.Children) {
                        var fe = child as FrameworkElement;
                        if (fe != null && fe.Name != null && fe.Name.StartsWith("Port_") && fe != connectionSourcePort) {
                            double px = Canvas.GetLeft(fe) + fe.Width / 2;
                            double py = Canvas.GetTop(fe) + fe.Height / 2;
                            if (double.IsNaN(px) || double.IsNaN(py)) continue;
                            
                            double distSq = (dropPos.X - px) * (dropPos.X - px) + (dropPos.Y - py) * (dropPos.Y - py);
                            if (distSq < minDistance) {
                                minDistance = distSq;
                                closestPort = fe;
                            }
                        }
                    }
                    
                    if (closestPort != null) {
                        SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ConnectPorts|" + 
                            Convert.ToBase64String(Encoding.UTF8.GetBytes(connectionSourcePort.Name + "," + closestPort.Name)) + "\n");
                    }
                    connectionSourcePort = null;
                    e.Handled = true;
                } else if (isKnifing && tempKnife != null && tempKnife.Visibility == Visibility.Visible) {
                    tempKnife.Visibility = Visibility.Collapsed;
                    isKnifing = false;
                    parent.ReleaseMouseCapture();
                    e.Handled = true;
                } else {
                    // Clicked empty space
                    SendToAhk("EVENT|" + winId + "|" + canvas.Name + "|ClearSelection|\n");
                }
            };
        }
    }
        
    private void ZoomAllCanvas(Canvas canvas) {
        var tg = canvas.RenderTransform as System.Windows.Media.TransformGroup;
        if (tg != null && tg.Children.Count >= 2) {
            var scaleTransform = tg.Children[0] as System.Windows.Media.ScaleTransform;
            var translateTransform = tg.Children[1] as System.Windows.Media.TranslateTransform;
            
            if (scaleTransform != null && translateTransform != null) {
                double minX = double.MaxValue, minY = double.MaxValue;
                double maxX = double.MinValue, maxY = double.MinValue;
                
                foreach (UIElement child in canvas.Children) {
                    if (child is System.Windows.Shapes.Path) continue;
                    double left = Canvas.GetLeft(child);
                    double top = Canvas.GetTop(child);
                    if (double.IsNaN(left)) left = 0;
                    if (double.IsNaN(top)) top = 0;
                    
                    var fe = child as FrameworkElement;
                    if (fe != null && fe.ActualWidth > 0 && fe.ActualHeight > 0) {
                        minX = Math.Min(minX, left);
                        minY = Math.Min(minY, top);
                        maxX = Math.Max(maxX, left + fe.ActualWidth);
                        maxY = Math.Max(maxY, top + fe.ActualHeight);
                    }
                }
                
                if (minX <= maxX && minY <= maxY) {
                    double contentWidth = maxX - minX;
                    double contentHeight = maxY - minY;
                    
                    var parent = canvas.Parent as FrameworkElement;
                    if (parent != null && parent.ActualWidth > 0 && parent.ActualHeight > 0) {
                        double viewportWidth = parent.ActualWidth;
                        double viewportHeight = parent.ActualHeight;
                        
                        // Add 250px total padding (125px per side)
                        double scaleX = viewportWidth / (contentWidth + 250);
                        double scaleY = viewportHeight / (contentHeight + 250);
                        double scale = Math.Min(scaleX, scaleY);
                        if (scale > 2.0) scale = 2.0;
                        if (scale < 0.2) scale = 0.2;
                        
                        scaleTransform.CenterX = 0;
                        scaleTransform.CenterY = 0;
                        scaleTransform.ScaleX = scale;
                        scaleTransform.ScaleY = scale;
                        
                        translateTransform.X = (viewportWidth - contentWidth * scale) / 2 - minX * scale - canvas.Margin.Left;
                        translateTransform.Y = (viewportHeight - contentHeight * scale) / 2 - minY * scale - canvas.Margin.Top;
                    }
                }
            }
        }
    }
    
    private void ZoomCanvas(Canvas canvas, double zoomFactor) {
        var tg = canvas.RenderTransform as System.Windows.Media.TransformGroup;
        if (tg != null && tg.Children.Count >= 2) {
            var scaleTransform = tg.Children[0] as System.Windows.Media.ScaleTransform;
            var translateTransform = tg.Children[1] as System.Windows.Media.TranslateTransform;
            
            if (scaleTransform != null && translateTransform != null) {
                var parent = canvas.Parent as FrameworkElement;
                if (parent != null) {
                    double centerX = parent.ActualWidth / 2;
                    double centerY = parent.ActualHeight / 2;
                    var parentCenter = new Point(centerX, centerY);
                    var canvasPos = parent.TranslatePoint(parentCenter, canvas);
                    
                    double newScale = scaleTransform.ScaleX * zoomFactor;
                    if (newScale > 5.0) newScale = 5.0;
                    if (newScale < 0.1) newScale = 0.1;
                    
                    double scaleX = scaleTransform.ScaleX;
                    translateTransform.X = translateTransform.X + canvasPos.X * (scaleX - newScale);
                    translateTransform.Y = translateTransform.Y + canvasPos.Y * (scaleX - newScale);
                    
                    scaleTransform.ScaleX = newScale;
                    scaleTransform.ScaleY = newScale;
                }
            }
        }
    }
    
    private void EnableListBoxDragDrop(ListBox listBox, string ctrlName) {
        listBox.AllowDrop = true;
        Point dragStart = new Point();
        bool isDragging = false;

        listBox.PreviewMouseLeftButtonDown += (s, e) => {
            dragStart = e.GetPosition(null);
            isDragging = true;
        };

        listBox.PreviewMouseMove += (s, e) => {
            if (e.LeftButton == System.Windows.Input.MouseButtonState.Pressed && isDragging) {
                Point pos = e.GetPosition(null);
                if (Math.Abs(pos.X - dragStart.X) > SystemParameters.MinimumHorizontalDragDistance ||
                    Math.Abs(pos.Y - dragStart.Y) > SystemParameters.MinimumVerticalDragDistance) {
                    
                    var item = GetListBoxItemUnderMouse(listBox, e.GetPosition(listBox));
                    if (item != null) {
                        string content = "";
                        if (item.Content is string) {
                            content = (string)item.Content;
                        } else if (item.Content is System.Windows.Controls.TextBlock) {
                            content = ((System.Windows.Controls.TextBlock)item.Content).Text;
                        } else {
                            content = item.Content != null ? item.Content.ToString() : "";
                        }
                        
                        DataObject dragData = new DataObject("KanbanItem", content);
                        dragData.SetData("SourceBox", ctrlName);
                        
                        DragDrop.DoDragDrop(listBox, dragData, DragDropEffects.Move);
                    }
                    isDragging = false;
                }
            }
        };

        listBox.Drop += (s, e) => {
            if (e.Data.GetDataPresent("KanbanItem")) {
                string content = (string)e.Data.GetData("KanbanItem");
                string sourceBox = (string)e.Data.GetData("SourceBox");
                
                if (sourceBox != ctrlName) {
                    SendToAhk("EVENT|" + winId + "|" + ctrlName + "|ItemDropped|" + 
                        Convert.ToBase64String(Encoding.UTF8.GetBytes(sourceBox + "|" + content)) + "\n");
                }
            }
        };
    }

    private ListBoxItem GetListBoxItemUnderMouse(ListBox lb, Point p) {
        System.Windows.Media.HitTestResult hit = System.Windows.Media.VisualTreeHelper.HitTest(lb, p);
        if (hit != null) {
            DependencyObject depObj = hit.VisualHit;
            while (depObj != null && !(depObj is ListBoxItem)) {
                depObj = System.Windows.Media.VisualTreeHelper.GetParent(depObj);
            }
            return depObj as ListBoxItem;
        }
        return null;
    }
}