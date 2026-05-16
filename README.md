# AHK-XAML Framework

The modern, object-oriented framework for building native WPF (Windows Presentation Foundation) interfaces entirely within AutoHotkey v2.

By combining the speed of AHK with the rendering power of a compiled C# WPF engine, `ahk-xaml` allows you to create incredibly rich, hardware-accelerated, themable UIs without writing a single line of raw XML or dealing with complex thread-blocking UI code.

## Core Features

- **No Raw XAML Strings:** The powerful `XAML_Generator` builds your UI procedurally using a clean, chainable AHK method syntax.
- **Compiled Engine:** Uses a dynamically compiled, standalone C# executable (`AhkWpfEngine`) to host the UI on a separate thread, ensuring your AHK logic never blocks the UI rendering, and the UI never blocks your AHK scripts.
- **Robust IPC:** Communication between AHK and WPF is handled via low-latency `WM_COPYDATA` messaging. Events (clicks, text input, window dragging) are automatically captured and passed to your AHK callbacks.
- **Pre-Built Component Library:** Comes with a comprehensive set of modern, Win11-styled components (ColorPickers, Tokenizers, Code Editors, Toggle Switches) ready to drop into your app.
- **Dynamic Theming:** Supports hot-swapping themes by injecting WPF `ResourceDictionaries`. It fully integrates with Windows DWM (Desktop Window Manager) for native Mica/Acrylic effects and rounded corners.

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

## Directory Structure

- `lib/XAML_Host.ahk`: The core bridge that compiles the background engine and handles the IPC messaging.
- `lib/XAML_Generator.ahk`: The class that converts your chained method calls into an AST, then compiles it to XAML markup.
- `lib/XAML_GUI.ahk`: A high-level wrapper to easily scaffold main application windows with standard layouts and sidebars.
- `lib/XAML_Components.ahk`: A massive library of complex custom components extending `XAMLElement.Prototype`.
- `lib/XAML_Dialog.ahk`: A robust dialog system for modal alerts, inputs, and confirmations.
- `lib/xaml.components.xaml`: The core WPF `ResourceDictionary` containing all the visual styles, templates, and triggers for the components.

## Further Reading

This repository has been fully modularized. For deep dives into specific areas, please see the following documentation files:

1. [Components Guide](Components.md) - A definitive list of all available UI components, from simple toggle switches to complex code editors, with coding examples.
2. [Syntax & Principles](SyntaxAndPrinciples.md) - Learn how the `XAML_Generator` works, how scoped defaults operate, and the internal architecture of the compiled C# engine.
