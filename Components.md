# AHK-XAML Component Reference

> The `ahk-xaml` framework bridges AutoHotkey v2 directly to the WPF runtime.  
> **Any valid WPF UIElement** can be instantiated via `.Add("TypeName")` — the components below are the **themed, pre-styled, and abstracted** building blocks optimized for rapid UI development.

---

## Table of Contents

1. [XAML_GUI Application Wrapper](#i-xaml_gui-application-wrapper)
2. [Standard WPF Controls (Themed)](#ii-standard-wpf-controls-themed)
3. [Custom Composites](#iii-custom-composites)
4. [Advanced Components](#iv-advanced-components)
5. [Data & Tables](#v-data--tables)
6. [Overlays & Contexts](#vi-overlays--contexts)
7. [Event System](#vii-event-system)

---

## I. XAML_GUI Application Wrapper

The `XAML_GUI` class scaffolds a complete, modern application window with DWM Mica integration, a custom titlebar, optional sidebar, tab navigation, and theme management.

### Constructor

```ahk
options := Map(
    "Sidebar", true,         ; Show/hide left sidebar
    "BurgerMenu", true,      ; Show/hide hamburger toggle in titlebar
    "MinMaxButtons", true,   ; Show/hide minimize/maximize buttons
    "AppIcon", true          ; Show/hide app icon in titlebar
)

app := XAML_GUI("My Application", options)
```

### Key Methods

| Method | Description |
|---|---|
| `app.AddTab(title, builderFn)` | Register a tab; `builderFn(tab)` receives the tab content panel |
| `app.Show()` | Compile and display the window |
| `app.ShowSnackbar(msg, action?)` | Display a toast notification at the bottom |
| `app.main` | Direct reference to the main content area |

### Sidebar Settings

```ahk
; Add settings to the sidebar
app.sidebar.SettingItem("Dark Mode", "Enable dark theme", "ToggleSwitch", "True")
app.sidebar.SettingItem("Scale", "Interface density", "ComboBox", "Balanced")
```

---

## II. Standard WPF Controls (Themed)

All standard WPF controls are automatically styled by `xaml.components.xaml` to match the active theme (Dark Mica, Light Frosted, etc.).

### Layout Containers

| Type | Usage |
|---|---|
| `Grid` | Row/column layouts with `.Rows()` and `.Cols()` |
| `StackPanel` | Linear stacking with `.Orientation("Horizontal")` |
| `DockPanel` | Dock children to edges |
| `WrapPanel` | Auto-wrapping flow layout |
| `ScrollViewer` | Scrollable container |
| `Border` | Rounded containers with `.Use("CardPanel")` |
| `Expander` | Collapsible sections |

```ahk
; Grid with rows and columns
grid := parent.Add("Grid").Margin("10")
grid.Rows("Auto", "*", "Auto")
grid.Cols("200", "*")

; Card Panel (rounded, themed background)
card := parent.Add("Border").Use("CardPanel").Padding("20")

; Expander
exp := parent.Add("Expander").Header("Advanced Settings")
exp.Add("StackPanel").Add("TextBlock").Text("IP: 192.168.1.1")
```

### Buttons

| Style | Usage |
|---|---|
| Default | `parent.Add("Button").Content("Cancel")` |
| Primary | `.Use("PrimaryBtn")` — accent-colored |
| Icon | `.Use("IconBtn")` — compact, subtle |
| Hamburger | `.Style("{StaticResource HamburgerButton}")` |
| ToggleButton | `.Add("ToggleButton").Content("Toggle")` |
| RepeatButton | `.Add("RepeatButton")` — fires while held |

```ahk
; Primary accent button
parent.Add("Button").Content("Save").Use("PrimaryBtn").Cursor("Hand")

; Icon button with Segoe Fluent Icons
parent.Add("Button").Content(Chr(0xE74D)).FontFamily("Segoe Fluent Icons").Use("IconBtn")
```

### CheckBox, RadioButton, ToggleSwitch

```ahk
; Standard checkbox
parent.Add("CheckBox").Content("Remember me").IsChecked("True")

; Toggle Switch (Win11 style)
parent.Add("CheckBox").Content("Wi-Fi").Style("{StaticResource ToggleSwitch}")

; Radio buttons
parent.Add("RadioButton").Content("Option A").GroupName("G1").IsChecked("True")
parent.Add("RadioButton").Content("Option B").GroupName("G1")

; Segmented buttons
parent.Add("RadioButton").Content("Map").Style("{StaticResource SegmentedBtn}").IsChecked("True")
parent.Add("RadioButton").Content("Satellite").Style("{StaticResource SegmentedBtn}")
```

### Text Inputs

```ahk
; Single-line
parent.Add("TextBox").Text("Hello").Name("MyInput")

; Password
parent.Add("PasswordBox").Width(200)

; Multi-line
parent.Add("TextBox").TextWrapping("Wrap").AcceptsReturn("True").Height(100)
```

### Progress Indicators

```ahk
; Linear progress bar
parent.Add("ProgressBar").Value(75).Maximum(100).Height(20)

; Indeterminate
parent.Add("ProgressBar").IsIndeterminate("True").Height(4)

; Circular spinner (progress ring)
parent.Add("ProgressBar").Style("{StaticResource ProgressRing}").Width(40).Height(40)

; Glowing pulsing ring
parent.Add("ProgressBar").Style("{StaticResource PulsingRing}")
```

### ComboBox, ListBox, TabControl

```ahk
; ComboBox with items
combo := parent.Add("ComboBox").Width(200).Name("MyCombo")
combo.Add("ComboBoxItem").Content("Option 1").IsSelected("True")
combo.Add("ComboBoxItem").Content("Option 2")

; Tab Control
tabs := parent.Add("TabControl")
tabs.Add("TabItem").Header("General").Add("TextBlock").Text("Content")
```

### Slider

```ahk
parent.Add("Slider").Minimum(0).Maximum(100).Value(50).Name("MySlider")
```

---

## III. Custom Composites

High-level components that inject complex XAML trees automatically.

### CodeEditor

A syntax-highlighted code editing panel wrapping `RichTextBox` + `FlowDocument`.

```ahk
editor := parent.CodeEditor("script.ahk")

flow := editor.Add("FlowDocument").LineHeight(20)
flow.Add("Paragraph").Margin("0").Add("Run").Text("; Comment").Foreground("#6A9955")
flow.Add("Paragraph").Margin("0").Add("Run").Text('MsgBox("Hello")')
```

### XColorPicker

A modal color picker dialog with hex input, hue slider, and saturation/brightness plane.

```ahk
result := XColorPicker.Show({
    Title: "Choose Color",
    DefaultColor: "#FF0A84FF",
    Owner: ui.wpfHwnd,
    Modal: true,
    Theme: "Dark Mica (Win 11)"
})

if (result.Status == "OK")
    ui.Update("Preview", "Background", result.Color)
```

### XDialog

A full-featured modal dialog replacement for `MsgBox`.

```ahk
result := XDialog.Show({
    Title: "Error",
    Message: "Parse failed.",
    Icon: Chr(0xE783),
    IconColor: "#FFCC00",
    DetailText: "Line 42: Unexpected identifier",
    Buttons: ["Retry", "Abort"],
    Modal: true,
    Owner: ui.wpfHwnd,
    DarkenOwner: true
})

if (result.Button == "Abort")
    ExitApp()
```

### SettingItem

A pre-formatted row for settings panels: title, description, and an interactive control.

```ahk
; Toggle switch
panel.SettingItem("Hardware Accel", "Use GPU rendering", "ToggleSwitch", "True")

; Button
panel.SettingItem("Clear Cache", "Delete temp files", "Button", "Clear Now")

; ComboBox
panel.SettingItem("Theme", "Visual theme", "ComboBox", "Dark", ["Dark", "Light", "Auto"])
```

### Tokenizer

A tag/pill manager — type and press Enter to add tokens, click X to remove.

```ahk
tok := panel.Tokenizer("Categories", ["AutoHotkey", "WPF", "Design"])
app.RegisterTokenizer(tok)
```

### NumericUpDown

A spinner input with up/down buttons and keyboard arrow support.

```ahk
num := panel.NumericUpDown("FontSize", 8, 72, 14)
app.RegisterNumericInput(num)
```

### SearchBox

A styled text input with a magnifying glass icon and placeholder watermark.

```ahk
panel.SearchBox("Search documentation...")
```

---

## IV. Advanced Components

Abstracted, self-contained components with rich configuration options.

### SliderRange

A dual-thumb range slider for selecting min/max values.

```ahk
; Parameters: Title, Min, Max, DefaultStart, DefaultEnd
slider := panel.SliderRange("Price Filter", 0, 100, 20, 80)
```

**Properties** (on returned grid element):
- `.MinSliderName` — Name of the min slider element
- `.MaxSliderName` — Name of the max slider element

**Clamping** (prevent crossing):
```ahk
ui.OnEvent(slider.MinSliderName, "ValueChanged", ClampMin)
ui.OnEvent(slider.MaxSliderName, "ValueChanged", ClampMax)
ui.Track(slider.MinSliderName)
ui.Track(slider.MaxSliderName)

ClampMin(state, ctrl, ev) {
    if (Number(state["MyMin"]) > Number(state["MyMax"]))
        ui.Update("MyMin", "Value", state["MyMax"])
}
```

### DateRangePickerEx

A highly customized, fully themed date range selector replacing the native WPF calendar. Provides a popover with an interactive calendar grid built entirely using XAML primitives and AHK date logic.

```ahk
; Create the instance
myDatePicker := DateRangePickerEx("EventDates", "2026-05-16", "2026-06-16")

; Build the UI into a parent container
myDatePicker.Build(panel)

; Wire up events (do this globally)
myDatePicker.Bind(ui)
```

**Selection Logic**:
- Click 1: Sets Start Date
- Click 2: Sets End Date (if before start date, they swap automatically)
- Selected days are styled with `{DynamicResource Accent}`
- Days within the range are styled with `{DynamicResource ControlBgHover}`

### BreadcrumbBar

Horizontal path navigation with clickable segments and child popovers.

```ahk
panel.BreadcrumbBar(["Home", "Projects", "AHK", "XAML_Components.ahk"])
```

### Stepper (Wizard)

A multi-step progress indicator for forms and workflows.

```ahk
; Parameters: Array of Step Names, Current Step (1-based)
panel.Stepper(["Config", "Auth", "Deploy", "Verify"], 3)
```

### Carousel

A horizontal scrolling container for cards or images with left/right navigation and pagination dots.

```ahk
panel.Carousel(["#FF453A", "#FF9F0A", "#FFD60A", "#32D74B", "#0A84FF", "#5E5CE6"])
```

**Event Wiring** (for scroll buttons):
```ahk
ui.OnEvent("MyCarousel_BtnL", "Click", (*) => ui.Update("MyCarousel_Scroll", "LineLeft", ""))
ui.OnEvent("MyCarousel_BtnR", "Click", (*) => ui.Update("MyCarousel_Scroll", "LineRight", ""))
```

### Timeline

A vertical event log with timestamps, dots, and description boxes.

```ahk
events := [
    { time: "10:00 AM", desc: "System booted." },
    { time: "10:05 AM", desc: "User authenticated." }
]
panel.Timeline(events)
```

### StatCard

A dashboard KPI card with title, large metric, and color-coded trend.

```ahk
; Parameters: Title, Metric, TrendText, IsTrendUp
panel.StatCard("REVENUE", "$45,231", "12.5% increase", true)
panel.StatCard("SERVER LOAD", "89%", "2% above threshold", false)
```

### SplitPanel

A resizable two-pane layout with a draggable `GridSplitter`.

```ahk
; Parameters: Orientation, Ratio
split := panel.SplitPanel("Horizontal", "1:1")
split.LeftPanel.Add("TextBlock").Text("Left")
split.RightPanel.Add("TextBlock").Text("Right")
```

### FileDropZone

A drag-and-drop file target with visual feedback icons.

```ahk
panel.FileDropZone("MyDropZone", "Drop files here", [".txt", ".json"])
```

### Rating

A configurable star/icon rating selector. Supports any number of items, custom icons, and half-step values.

**Options**:

| Option | Type | Default | Description |
|---|---|---|---|
| `Max` | Integer | `5` | Number of rating positions |
| `Default` | Number | `0` | Initial filled value |
| `Icon` | String | `★` (Segoe E735) | Filled icon character |
| `IconEmpty` | String | `☆` (Segoe E734) | Empty icon character |
| `Size` | Integer | `22` | Icon font size (px) |
| `AllowHalf` | Boolean | `false` | Enable half-step selection |
| `Color` | String | `#FFD700` | Filled icon color |
| `EmptyColor` | String | `{DynamicResource TextSub}` | Empty icon color |
| `IconFont` | String | `Segoe Fluent Icons` | Font family |

```ahk
; 5-star rating with default of 3
panel.Rating("MyRating", { Max: 5, Default: 3 })

; 10-heart rating
panel.Rating("Hearts", {
    Max: 10,
    Default: 7,
    Icon: Chr(0xEB52),
    IconEmpty: Chr(0xEB51),
    Color: "#FF453A",
    Size: 18
})
```

**Event Wiring**:
```ahk
RatingBind(ui, "MyRating", 5, false, Chr(0xE735), Chr(0xE734), "#FFD700", "{DynamicResource TextSub}")
```

### EmojiPicker

A popover grid of clickable emoji with categories (Smileys, Gestures, Hearts, Objects).

**Options**:

| Option | Type | Default | Description |
|---|---|---|---|
| `ButtonText` | String | `😀` | Text shown on toggle button |
| `Target` | String | `""` | Name of target element to receive emoji |

```ahk
; Basic picker
panel.EmojiPicker("MyEmoji")

; Picker that inserts into a TextBox
panel.EmojiPicker("MyEmoji", { Target: "TxtComment" })
```

**Event Wiring**:
```ahk
; Get emoji list from the component or define inline
emojiList := ["😀","😁","😂", ...]  ; 90 emoji
EmojiPickerBind(ui, "MyEmoji", emojiList)
```

### SkeletonLoader

A pulsing placeholder that mimics content shape during loading.

```ahk
; Parameters: Width, Height, IsCircle (optional)
panel.SkeletonLoader(200, 20)
panel.SkeletonLoader(40, 40, true)  ; Circular
```

---

## V. Data & Tables

### DataTableView

A simple sortable table with alternating rows, header sort buttons, resizable columns, and text trimming.

```ahk
data := [
    { Name: "Alice", Role: "Admin", Status: "Active" },
    { Name: "Bob", Role: "Dev", Status: "Offline" }
]

parent.DataTableView("MyTable", data)
```

**Element Names Generated**:
- `MyTable_Header_{ColumnName}` — Clickable sort buttons
- `MyTable_List` — The row container (ListBox)

### DataGridEx (Class)

A comprehensive, self-contained data grid with search, filter, sort, pagination, and dynamic row injection. All state management is encapsulated — no global variables needed.

**Constructor Options**:

| Option | Type | Default | Description |
|---|---|---|---|
| `PageSize` | Integer | `50` | Rows per page |
| `ShowSearch` | Boolean | `true` | Show search textbox |
| `ShowFilters` | Boolean | `false` | Show filter popover |
| `ShowPagination` | Boolean | `true` | Show prev/next + page status |
| `ShowReset` | Boolean | `true` | Show reset button |
| `ShowRowCount` | Boolean | `true` | Show filtered row count |
| `FilterColumn` | String | `""` | Column name to filter by |
| `FilterValues` | Array | `[]` | Possible values for filter checkboxes |
| `ColumnWidths` | Object | `{}` | Column width overrides |

**Column Width Formats**:
- `"150"` — Fixed pixel width
- `"2*"` — Star proportional
- `"30%"` — Percentage (converted to star ratio)

```ahk
; Generate data
data := []
loop 200
    data.Push({ Name: "User " A_Index, Role: "Dev", Status: "Active" })

; Create the grid
myGrid := DataGridEx("DGX", data, {
    PageSize: 50,
    ShowSearch: true,
    ShowFilters: true,
    ShowPagination: true,
    FilterColumn: "Status",
    FilterValues: ["Active", "Offline", "Pending"],
    ColumnWidths: { Name: "40%", Role: "30%", Status: "30%" }
})

; Build UI
myGrid.Build(parent)

; Wire events (single call!)
myGrid.Bind(ui)
```

**Methods**:

| Method | Description |
|---|---|
| `.Build(parent)` | Generate the XAML UI into a parent element |
| `.Bind(uiHost)` | Register all events (sort, filter, search, paginate, reset) |
| `.Render(state)` | Force re-render (called automatically by events) |
| `.Sort(state, col)` | Sort by column |
| `.Reset(state)` | Reset all filters, search, and pagination |
| `.SetColumnWidth(col, width)` | Set column width after construction |

---

## VI. Overlays & Contexts

### RichPopover

An interactive dropdown panel anchored to a `ToggleButton`. Closes when clicking outside.

```ahk
btn := parent.Add("ToggleButton").Content("Options")
pop := btn.AddRichPopover()
pop.Add("TextBlock").Text("Settings").FontWeight("Bold")
pop.Add("CheckBox").Content("Show Hidden").Margin("0,5,0,0")
pop.Add("CheckBox").Content("Match Case")
```

### Badge

A small notification counter attached to any element.

```ahk
btn := parent.Add("Button").Content("Notifications")
btn.AddBadge("3")         ; Default red
btn.AddBadge("!", "#FF9F0A")  ; Custom color
```

### ContextMenu

A native right-click menu. Use `"-"` for separators.

```ahk
btn := parent.Add("Button").Content("Right-Click Me")
btn.AddContextMenu(["Edit", "Copy", "-", "Delete"])
```

### Snackbar

A non-blocking toast notification at the bottom of a panel.

```ahk
; Via XAML_GUI
app.ShowSnackbar("Saved!", "UNDO")

; Via direct element
panel.Snackbar("Settings applied.", "DISMISS")
```

---

## VII. Event System

All interactivity is managed through the `XAML_Host` event system.

### Registering Events

```ahk
; Click events
ui.OnEvent("BtnSave", "Click", (state, ctrl, ev) => SaveData(state))

; Text changed (live typing)
ui.OnEvent("TxtSearch", "TextChanged", (state, ctrl, ev) => Search(state))

; Toggle
ui.OnEvent("TglDarkMode", "Click", (state, ctrl, ev) => ToggleTheme(state))
```

### Tracking State

Track control values so they appear in the `state` map passed to event handlers:

```ahk
ui.Track("TxtUsername")
ui.Track("ComboRegion")
ui.Track("TglProxy")
```

### Updating Controls

```ahk
; Set property
ui.Update("TxtStatus", "Text", "Connected")
ui.Update("BtnSave", "IsEnabled", "False")
ui.Update("MyPanel", "Background", "#FF0000")

; Collection operations
ui.Update("MyList", "ClearItems", "")
ui.Update("MyList", "AddItem", "New entry")
ui.Update("MyList", "AddXamlItem", '<TextBlock xmlns="..." Text="Rich"/>')

; Scroll commands
ui.Update("MyScroll", "LineLeft", "")
ui.Update("MyScroll", "LineRight", "")

; Dynamic resources
ui.Update("Resource", "Accent", "#0A84FF")
```

### State Map

Every event handler receives a `state` Map containing tracked values:

```ahk
HandleClick(state, ctrl, event) {
    username := state["TxtUsername"]       ; Current text
    region := state["ComboRegion"]         ; Selected combo value
    proxyOn := state["TglProxy"] == "True" ; Toggle state
}
```
