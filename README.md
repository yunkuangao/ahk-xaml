# AHK-XAML Framework

The modern, object-oriented framework for building native WPF (Windows Presentation Foundation) interfaces entirely within AutoHotkey v2.

By combining the speed of AHK with the rendering power of a compiled C# WPF engine, `ahk-xaml` allows you to create incredibly rich, hardware-accelerated, themable UIs without writing a single line of raw XML or dealing with complex thread-blocking UI code.

## Core Features

- **No Raw XAML Strings:** The powerful `XAML_Generator` builds your UI procedurally using a clean, chainable AHK method syntax.
- **Compiled Engine:** Uses a dynamically compiled, standalone C# executable (`ahk-xaml.dll`) to host the UI on a separate thread, ensuring your AHK logic never blocks the UI rendering, and the UI never blocks your AHK scripts.
- **Robust IPC:** Communication between AHK and WPF is handled via low-latency `WM_COPYDATA` messaging. Events (clicks, text input, window dragging) are automatically captured and passed to your AHK callbacks.
- **Pre-Built Component Library:** 50+ modern, Win11-styled components — from simple toggle switches and segmented buttons to full code editors, node graph visual scripters, data grids, and embedded Chromium browsers.
- **Dynamic Theming:** Supports hot-swapping themes by injecting WPF `ResourceDictionaries`. Fully integrates with Windows DWM (Desktop Window Manager) for native Mica/Acrylic effects and rounded corners.
- **Hot Reload:** Automatic state persistence across script restarts — text inputs, toggle states, slider values, and combo selections are saved and restored seamlessly.
- **Crash Diagnostics:** Rich error dialogs that trace WPF parsing errors back to the originating AHK source line, with XAML snippet context.
- **Production Builds:** Export your UI as a compressed `.bin` asset for zero-compilation deployment.

## Quick Start Example

Here is a minimal implementation to show how a UI is constructed and launched.

```ahk
#Requires AutoHotkey v2.0
#Include "lib\XAML_GUI.ahk"

; 1. Initialize the Main App Window
app := XAML_GUI("My Application", 800, 600)

; 2. Build the UI using the generator syntax
app.Add("TextBlock").Text("Hello, World!").FontSize(24).Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,20,0,0")

btn := app.Add("Button").Content("Click Me!").Width(120).Height(40).Margin("0,20,0,0").Cursor("Hand")

; 3. Bind events to AHK callbacks
app.Events.OnEvent("BtnClickMe", "Click", (state, ctrl, event) => MsgBox("Button Clicked!"))
btn.Name("BtnClickMe") ; Assign the name so the engine can track it

; 4. Show the Window
app.Show()
```

## Component Highlights

| Category | Components |
|---|---|
| **Layout** | Grid, StackPanel, DockPanel, WrapPanel, SplitPanel, ScrollViewer |
| **Input** | TextBox, PasswordBox, ComboBox, Slider, SliderRange, NumericUpDown, HotKeyBox, SegmentedNetworkInput, SearchBox |
| **Selection** | CheckBox, RadioButton, ToggleSwitch, SegmentedBtn, Rating, EmojiPicker |
| **Display** | TextBlock, ProgressBar, ProgressRing, SkeletonLoader, SkeletonBlock, Avatar, Badge |
| **Data** | DataTableView, DataGridEx (search/filter/sort/pagination), Tokenizer |
| **Navigation** | TabControl, NavigationView, BreadcrumbBar, Stepper, CommandBar, XRibbon |
| **Visualization** | Sparkline, RadialGauge, StatCard, MetricCard, Timeline, XClock |
| **Advanced** | XNodeGraph, XCodeEditor, XDiffViewer, XPropertyGrid, XMediaPlayerEx, XImageCropper, XSvgViewer, KanbanBoard, MarkdownRenderer |
| **Overlays** | XDialog, XColorPicker, RichPopover, ContextMenu, Snackbar, FileDropZone |
| **Web** | XWebView (Chromium WebView2 with JS↔AHK bridge) |

## Directory Structure

```
ahk-xaml/
├── lib/
│   ├── XAML_Host.ahk             # Core IPC bridge, engine compilation, message dispatch
│   ├── XAML_Generator.ahk        # Chainable AST → XAML compiler
│   ├── XAML_GUI.ahk              # High-level app scaffolding (window, tabs, sidebar, themes)
│   ├── XAML_Config.ahk           # Global flags (XAML_DEBUG, XAML_ENABLE_WEBVIEW)
│   ├── XAML_Components.ahk       # Standard & composite components, data grids, rating, emoji
│   ├── XAML_Adv_Components.ahk   # Advanced components (NodeGraph, CodeEditor, WebView, etc.)
│   ├── XAML_Dialog.ahk           # Modal dialog system (XDialog)
│   ├── XAML_AHK_Bridge.cs        # C# WPF engine source (compiled at runtime)
│   ├── xaml.components.xaml       # WPF ResourceDictionary (all control templates & styles)
│   ├── ahk-xaml.dll              # Compiled WPF engine binary (cached)
│   └── WebView2/                 # WebView2 runtime DLLs (optional)
├── examples/
│   ├── example.ahk               # Full showcase with all component tabs
│   ├── example_advanced.ahk      # NodeGraph, Media, SVG, Code Editor, etc.
│   ├── example_docking.ahk       # Multi-panel docking workspace
│   ├── example_webview.ahk       # WebView2 browser demo
│   ├── example_basic.ahk         # Minimal starter
│   └── ribbon_example.ahk        # Office-style ribbon toolbar
├── README.md
├── Components.md
├── SyntaxAndPrinciples.md
└── ARCHITECTURE.md
```

## Further Reading

This repository has been fully modularized. For deep dives into specific areas, please see the following documentation files:

1. [Components Guide](Components.md) - A definitive list of all 50+ UI components with coding examples.
2. [Syntax & Principles](SyntaxAndPrinciples.md) - Learn how the `XAML_Generator` works, scoped defaults, templates, theming, and the component lifecycle.
3. [Architecture](ARCHITECTURE.md) - Deep-dive into the two-process runtime, IPC bridge, compilation pipeline, state persistence, crash recovery, dynamic mutations, and production builds.
