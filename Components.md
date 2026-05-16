# Comprehensive Component Reference

The `ahk-xaml` framework supports the entire spectrum of standard WPF components natively, while introducing a suite of highly-stylized custom composites designed specifically for modern, data-driven applications. 

## Component Quick List

### Standard WPF Elements (Themed)
1. **Layouts**: `Grid`, `StackPanel`, `DockPanel`, `WrapPanel`, `UniformGrid`, `Border`, `ScrollViewer`, `Viewbox`
2. **Text**: `TextBlock`, `TextBox`, `PasswordBox`, `RichTextBox`, `FlowDocument`
3. **Buttons**: `Button`, `ToggleButton`, `RepeatButton`, `RadioButton`, `CheckBox`
4. **Lists & Collections**: `ComboBox`, `ListBox`, `ListView`, `TreeView`, `TabControl`, `Ribbon`, `Expander`
5. **Data & Status**: `ProgressBar`, `Slider`, `Image`

> **Note on WPF Breadth:** `ahk-xaml` acts as a direct bridge to the WPF runtime. This means **any valid WPF UIElement** (like `Canvas`, `Ellipse`, `DataGrid`, or `RibbonTab`) is technically supported if you know its XAML properties, though complex items like `DataGrid` may require advanced bindings.

### Custom AHK-XAML Composites
1. **`CodeEditor`**: A fully functional syntax-highlighted editor pane.
2. **`ColorPicker` (`XColorPicker`)**: A robust RGB/HEX color selection modal.
3. **`NumericUpDown`**: A spinner for exact numerical values.
4. **`SearchBox`**: A stylish search input with icons and placeholders.
5. **`SettingItem`**: A complete layout row for application settings.
6. **`Tokenizer`**: A tag/pill input array manager.
7. **`XDialog`**: A native modal system for alerts, prompts, and progress.

---

## I. The XAML_GUI Application Wrapper

Before placing components, you usually initialize an application window. The `XAML_GUI` class is a high-level wrapper that scaffolds a modern, responsive window complete with a custom titlebar, DWM Mica integration, and an optional sliding Sidebar.

```ahk
; You can control the visibility of built-in layout features via an options map:
options := Map(
    "Sidebar", false,       ; Hides the left-hand sidebar
    "BurgerMenu", false,    ; Hides the hamburger toggle button in the titlebar
    "MinMaxButtons", true,  ; Shows/Hides minimize and maximize buttons
    "AppIcon", false        ; Hides the application icon in the titlebar
)

app := XAML_GUI("Minimal App Title", options)

; To add components directly to the center area:
app.main.Add("TextBlock").Text("Hello World!")
```

---

## II. Native WPF Controls (Detailed Examples)

Because `ahk-xaml` passes markup directly to the WPF engine, any valid WPF `Type` can be instantiated using `.Add("TypeName")`. They automatically adopt the dark/light Mica themes defined in `xaml.components.xaml`.

### 1. Buttons
```ahk
; Standard minimal button
app.Add("Button").Content("Cancel").Style("{StaticResource DialogBtn}")

; Primary/Accent button (colored)
app.Add("Button").Content("Save").Style("{StaticResource DialogPrimaryBtn}")

; Hamburger/Icon Button (using Segoe Fluent Icons)
btn := app.Add("ToggleButton").Style("{StaticResource HamburgerButton}")
btn.Add("TextBlock").Text(Chr(0xE700)).FontFamily("Segoe Fluent Icons")
```

### 2. CheckBoxes & RadioButtons
```ahk
; Standard checkbox
app.Add("CheckBox").Content("Remember me").IsChecked("True")

; Toggle Switch (Win11 Style)
app.Add("CheckBox").Content("Enable Wi-Fi").Style("{StaticResource ToggleSwitch}")

; Radio Buttons
app.Add("RadioButton").Content("Option A").GroupName("Group1")
app.Add("RadioButton").Content("Option B").GroupName("Group1")

; Segmented Button (Connected Tabs)
app.Add("RadioButton").Content("Map").Style("{StaticResource SegmentedBtn}").IsChecked("True")
app.Add("RadioButton").Content("Satellite").Style("{StaticResource SegmentedBtn}")
```

### 3. Text Inputs
```ahk
; Standard Single-Line
app.Add("TextBox").Text("Initial String").Width(250)

; Password Input
app.Add("PasswordBox").Width(250)

; Multi-line Text Area
app.Add("TextBox").TextWrapping("Wrap").AcceptsReturn("True").Height(100)
```

### 4. Layouts & Containers
```ahk
; Card Panel (Rounded rectangle with subtle background)
card := app.Add("Border").Use("CardPanel").Padding("15")

; Expander (Collapsible dropdown section)
exp := app.Add("Expander").Header("Advanced Network Settings")
exp.Add("StackPanel").Add("TextBlock").Text("IP Address: 192.168.1.1")

; Tab Control
tabs := app.Add("TabControl")
tabs.Add("TabItem").Header("General").Add("TextBlock").Text("Tab 1 Content")
tabs.Add("TabItem").Header("Security").Add("TextBlock").Text("Tab 2 Content")
```

### 5. Progress Indicators
```ahk
; Standard Linear Progress
app.Add("ProgressBar").Value(75).Maximum(100).Height(20)

; Infinite Indeterminate Progress
app.Add("ProgressBar").IsIndeterminate("True").Height(4)

; Circular Spinner (Progress Ring)
app.Add("ProgressBar").Style("{StaticResource ProgressRing}").Width(40).Height(40)

; Glowing Pulsing Ring (For 'Listening' or 'Active' states)
app.Add("ProgressBar").Style("{StaticResource PulsingRing}")
```

---

## II. Custom Composites (Detailed Examples)

The custom composites are AHK classes/methods that inject huge blocks of XAML and C# event bindings automatically. They are the power-user tools of the `ahk-xaml` framework.

### 1. `CodeEditor`
Creates a dedicated coding environment. It wraps a `RichTextBox` and automatically manages the `FlowDocument` structure.

```ahk
; Instantiate the editor with a mock filename header
editor := parentGrid.CodeEditor("script.ahk")

; Add content to the editor
flow := editor.Add("FlowDocument").LineHeight(20)
flow.Add("Paragraph").Margin("0").Add("Run").Text("; Initial Code").Foreground("#6A9955")
flow.Add("Paragraph").Margin("0").Add("Run").Text("MsgBox(`"Hello World`")")
```

### 2. `XColorPicker`
A fully-featured color selection dialog. It pauses AHK execution (modal) until the user confirms a color.

```ahk
; Spawns the picker anchored to the main window
result := XColorPicker.Show(app.Events.wpfHwnd, "#FF0000", "Choose Theme Color")

if (result.Status == "Confirm") {
    MsgBox("You selected: " result.Color)
    ; You can inject this dynamically into the UI:
    app.Events.Update("Resource", "Brush:Accent", result.Color)
}
```

### 3. `SettingItem`
A perfectly aligned grid row used to build settings pages. It expects a Title, Description, a control type (like "ToggleSwitch", "Button", or "ComboBox"), and a default value.

```ahk
; Adds a row with a toggle switch on the far right
panel.SettingItem("Hardware Acceleration", "Use GPU to render complex scenes", "ToggleSwitch", "True")

; Adds a row with a standard button
panel.SettingItem("Clear Cache", "Delete all temporary files", "Button", "Clear Now")
```

### 4. `Tokenizer`
Creates a container of "tags" or "pills". The user can type into an input box and press Enter to spawn a new token. Tokens have an 'X' button to delete themselves.

```ahk
; Parameters: Title, Array of Default Tokens
tok := panel.Tokenizer("Categories", ["AutoHotkey", "WPF", "UI Design"])

; The backend C# engine tracks the add/delete events automatically, 
; but you must register the tokenizer with your main app to handle 'Enter' key presses:
app.RegisterTokenizer(tok)
```

### 5. `NumericUpDown`
A highly stylized input box flanked by subtle Up and Down chevron buttons. It enforces numeric validation.

```ahk
; Parameters: ID Name, Min Value, Max Value, Default Value
numInput := panel.NumericUpDown("FontSize", 8, 72, 14)

; Register it so the Up/Down arrow keys on the keyboard also increment the value!
app.RegisterNumericInput(numInput)
```

### 6. `SearchBox`
A pre-styled `TextBox` featuring a placeholder watermark and a magnifying glass icon seamlessly integrated into the background.

```ahk
panel.SearchBox("Search documentation...")
```

### 7. `XDialog`
The ultimate replacement for standard AHK `MsgBox`. It supports asynchronous, non-blocking modals, dark themes, and icon injections.

```ahk
result := XDialog.Show({
    Title: "Critical Error",
    Message: "The compiler failed to parse the syntax tree.",
    Icon: Chr(0xE783), ; Warning Icon
    IconColor: "#FFCC00",
    DetailText: "Line 42: Unexpected identifier 'foo'",
    Buttons: ["Retry", "Abort", "Ignore"],
    Modal: true,
    Owner: app.Events.wpfHwnd,
    DarkenOwner: true ; Apples a stylish black semi-transparent overlay to the main app
})

if (result.Button == "Abort") {
    ExitApp()
}
```
