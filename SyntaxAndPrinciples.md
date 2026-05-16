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

---

## 2. The Background Engine Architecture

### Why a C# Engine?
AutoHotkey is single-threaded. Rendering complex, hardware-accelerated UIs on the main AHK thread causes massive latency, message blockages, and instability during heavy processing (like I/O or loops). 

To solve this, `ahk-xaml` dynamically compiles a lightweight C# WPF application (`AhkWpf_SharedEngine_v7.exe`) to a temporary directory. 

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

If you need to change a theme programmatically, you can send a Resource update to the engine:
```ahk
; Change the main text color to Red on the fly
app.Events.Update("Resource", "Brush:TextMain", "#FF0000")
```
