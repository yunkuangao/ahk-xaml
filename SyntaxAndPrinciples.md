# Syntax & Architectural Principles

To master the `ahk-xaml` framework, it is crucial to understand both the surface-level AHK syntax and the underlying engine architecture. 

## 1. The XAML_Generator Syntax

The `XAML_Generator` class is an Object-Oriented wrapper around XML tree construction. It ensures you never have to deal with mismatched tags, complex string escaping, or XML verbosity.

### The Chainable API
Every element added to the UI returns an instance of `XAMLElement`. When you call a method that doesn't exist on `XAMLElement`, `ahk-xaml` intercepts the call dynamically and creates a XAML attribute.

```ahk
; This:
btn := panel.Add("Button").Width(100).HorizontalAlignment("Center")

; Generates this:
; <Button Width="100" HorizontalAlignment="Center" />
```

### Navigating the Hierarchy
The `.Add()` method always returns the **newly created child**. To add siblings, you must traverse back up the tree using `.Parent()`.

```ahk
grid := X.Add("Grid")

; Incorrect: TextBlock2 becomes a child of TextBlock1! (XAML Error)
grid.Add("TextBlock").Text("1").Add("TextBlock").Text("2") 

; Correct: 
grid.Add("TextBlock").Text("1").Parent()
    .Add("TextBlock").Text("2")
```

### Property Name Translations
AutoHotkey v2 does not allow dots (`.`) in method names. In XAML, attached properties (like `Grid.Row`) require dots. The generator automatically translates underscores (`_`) into dots (`.`).

```ahk
element.Grid_Row(1).Grid_Column(2).ScrollViewer_VerticalScrollBarVisibility("Auto")
; Generates: Grid.Row="1" Grid.Column="2" ScrollViewer.VerticalScrollBarVisibility="Auto"
```

### Special Methods

| Method | Purpose |
|---|---|
| `.Add("Type")` | Create a child element |
| `.Parent()` | Return to parent element |
| `.Name("id")` | Set `x:Name` for event binding and tracking |
| `.Use("Template")` | Apply a pre-defined template |
| `.SetProp("key", "val")` | Set an attribute with special characters |
| `.InjectResources(xaml)` | Inject raw XAML into element's `Resources` |
| `.SetDefaults("Type", map)` | Apply cascading defaults to children |
| `.Compile()` | Serialize the AST to XAML markup |

### Naming Elements
The `.Name()` method assigns an `x:Name` attribute, which is required for:
- **Event binding:** `ui.OnEvent("BtnSave", "Click", callback)`
- **State tracking:** `ui.Track("TxtUsername")`
- **Dynamic updates:** `ui.Update("BtnSave", "Text", "Saved!")`

```ahk
; Named element — can be interacted with
parent.Add("TextBox").Name("TxtEmail").Text("user@example.com")

; Unnamed element — static display only
parent.Add("TextBlock").Text("Email:")
```

---

## 2. The Background Engine Architecture

### Why a C# Engine?
AutoHotkey is single-threaded. Rendering complex, hardware-accelerated UIs on the main AHK thread causes massive latency, message blockages, and instability during heavy processing (like I/O or loops). 

To solve this, `ahk-xaml` dynamically compiles a lightweight C# WPF application (`ahk-xaml.dll`) to a temporary directory. 

1. Your AHK script generates the XAML markup string.
2. AHK launches the C# engine and passes the XAML to it.
3. The C# engine parses the XAML and displays the Window on its own dedicated thread.
4. The C# engine handles all Windows DWM rendering, native rounded corners, and complex animations independently of AHK.

### The IPC Bridge (WM_COPYDATA)
AHK and the C# engine communicate synchronously via Win32 `WM_COPYDATA` messages. 
- When the user clicks a button, the C# engine captures the UI state and fires a `WM_COPYDATA` payload to the AHK script.
- AHK parses the payload and triggers your registered `.OnEvent()` callbacks.
- When AHK needs to update the UI (e.g., change text, toggle a checkbox), it sends a payload back to the C# engine.

This complete separation of concerns ensures that your AHK business logic never freezes the UI, and the UI never bottlenecks your scripts.

### Payload Streaming
For large UIs, the XAML is too big for a single `WM_COPYDATA` message. Instead, the framework uses a two-step handshake:

1. Engine starts → sends `Ready` event with a temporary message window handle.
2. AHK sends `XAML_PAYLOAD|<xaml>\n---AHK-XAML-EVENTS---\n<bindings>` to that handle.
3. Engine parses → displays window → sends `LoadedHwnd` event.

### Dynamic Element Injection
After the window is loaded, new elements can be injected at runtime using `AddXamlItem`. The XAML string **must** include the full WPF namespace:

```ahk
xaml := '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Text="Dynamic!" />'
ui.Update("MyPanel", "AddXamlItem", xaml)
```

The C# engine parses the string via `XamlReader.Parse()`, registers any `x:Name` attributes in the window's `NameScope`, and adds the element to the target container.

---

## 3. Scoped Defaults & Templates

### SetDefaults (CSS-Like Cascading)
To avoid massive chains of redundant properties, you can apply defaults to a parent container. All children of that container (and their descendants) will automatically inherit the properties unless explicitly overridden.

```ahk
panel.SetDefaults("TextBlock", { Foreground: "White", FontSize: 14 })

panel.Add("TextBlock").Text("I am white and 14pt!")
panel.Add("TextBlock").Text("I am red and 14pt!").Foreground("Red") ; Override
```
*Note: Defaults are strictly scoped. They expire the moment you navigate away from `panel`.*

### .Use() Templates
Templates are reusable sets of properties that can be applied to any element, regardless of its parent container. You define them globally on the Generator instance.

```ahk
X.DefineTemplate("CardPanel", { Background: "{DynamicResource ControlBg}", BorderThickness: 1, CornerRadius: 8 })

; Apply it anywhere
app.Add("Border").Use("CardPanel")
```

### Built-in Templates

| Template | Description |
|---|---|
| `PrimaryBtn` | Accent-colored button with hover opacity |
| `IconBtn` | Compact transparent button with rounded hover |
| `CardPanel` | Rounded border with themed background |
| `SubtitleText` | Small, bold, muted text |
| `PageTitle` | Large, semi-bold heading |
| `BodyText` | 13pt wrapping body text |

---

## 4. Theming & ResourceDictionaries

`ahk-xaml` relies heavily on `DynamicResource` bindings to support hot-swapping themes. 
The base resources are defined in `lib\xaml.components.xaml`. 

When applying colors, **never hardcode them** if you want theming to work.
```ahk
; ❌ BAD: Hardcoded color
btn.Foreground("#FFFFFF").Background("#333333")

; ✅ GOOD: Dynamic bindings
btn.Foreground("{DynamicResource TextMain}").Background("{DynamicResource ControlBg}")
```

### Core Theme Resources

| Resource Key | Purpose |
|---|---|
| `BgColor` | Window background |
| `SidebarColor` | Sidebar background |
| `Accent` | Primary accent color |
| `TextMain` | Primary text color |
| `TextSub` | Secondary/muted text |
| `ControlBg` | Control/card background |
| `ControlBgHover` | Control hover state |
| `ControlBorder` | Border color |
| `DropdownBg` | Popup/dropdown background |
| `WindowRadius` | Window corner radius |
| `ScrollBarWidth` | Scrollbar width |

### Runtime Theme Changes

```ahk
; Change the main text color to Red on the fly
ui.Update("Resource", "Brush:TextMain", "#FF0000")

; Change corner radius
ui.Update("Resource", "CornerRadius:WindowRadius", "12")

; Change DWM backdrop
ui.Update("Window", "DWM", "3,1")  ; MicaAlt + Dark Mode
```

### Theme INI Format

```ini
[Dark Mica (Win 11)]
Window_DWM=2,1
Resource_Brush:BgColor=#01000000
Resource_Brush:Accent=#0A84FF
Resource_Brush:TextMain=#FFFFFF
Resource_Brush:TextSub=#A0FFFFFF
Resource_Brush:ControlBg=#15FFFFFF
Resource_Brush:ControlBgHover=#20FFFFFF
Resource_Brush:ControlBorder=#25FFFFFF
```

---

## 5. Component Lifecycle

### Build → Compile → Bind → Show

Most advanced components follow a consistent lifecycle:

```ahk
; 1. BUILD: Construct the XAML AST
myGrid := DataGridEx("DGX", data, { PageSize: 50 })
myGrid.Build(parent)

; 2. COMPILE: Generate the XAML and create the IPC host
ui := app.Compile()

; 3. BIND: Register all events and state tracking
myGrid.Bind(ui)

; 4. SHOW: Launch the WPF engine
app.Show()
```

### Class-Based vs Prototype Components

**Class-based** (standalone instances with internal state):
```ahk
; Create → Build → Bind
picker := DateRangePickerEx("Dates", "2026-01-01", "2026-12-31")
picker.Build(panel)
picker.Bind(ui)
```

**Prototype extensions** (chainable, inline):
```ahk
; Just call directly on any element
panel.Toggle("MySwitch", "Dark Mode", true)
panel.StatCard("REVENUE", "$45K", "+12%", true)
panel.SkeletonLoader(200, 20)
```

---

## 6. Error Handling

### AHK Line Tracking

Every element generated by `XAML_Generator` automatically records the AHK source line:
```xml
<!-- [ahk:42] --><Button Width="100" />
```

When the C# engine encounters a parsing error, it traces back to the nearest AHK line marker and reports:
```
Engine crashed while rendering AHK Line 42!
```

### Common Pitfalls

| Error | Cause | Fix |
|---|---|---|
| `Cannot create unknown type` | Missing xmlns on dynamic XAML | Add `xmlns="http://schemas.microsoft.com/..."` |
| `Name already registered` | Duplicate `x:Name` values | Use unique names per element |
| `XamlParseException` | Invalid property or typo | Check the XAML snippet in the error dialog |
| `Timed out waiting for payload` | AHK message queue full | Increase `OnMessage` MaxThreads |
