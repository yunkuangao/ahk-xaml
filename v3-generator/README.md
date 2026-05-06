# ahk-xaml: v3-generator

This is the modern, cutting-edge version of `ahk-xaml`. It completely eliminates the need to write raw XML/XAML strings by introducing the powerful `XAML_Generator` class. 

## The Object-Oriented Builder Engine

`XAML_Generator.ahk` provides a powerful, chainable builder pattern that lets you construct comprehensive, beautiful WPF UIs natively in AutoHotkey v2. The engine translates your AHK method chains into raw XAML automatically.

### 1. Chainable Properties
Instead of messy string manipulation (`X.Tag("Grid", 'Width="100" Margin="10"')`), any method you call dynamically generates a XAML property.

```ahk
btn := X.Add("Button").Width(100).Margin("0,10,0,0").Content("Click Me")
```

### 2. Attached Properties (Underscores to Dots)
Since AutoHotkey v2 does not allow dots in method names, the generator seamlessly converts underscores to dots for you.

```ahk
; Automatically generates Grid.Row="1" and Grid.Column="0"
btn.Grid_Row(1).Grid_Column(0)
```

### 3. Tree Navigation
The `.Add("Tag")` method creates a new child element and **returns the child** so you can chain properties onto it. If you need to step back up the hierarchy to add siblings, you can use `.Parent()`.

```ahk
grid := X.Add("Grid")

; Use .Parent() to navigate back up to the grid after defining the first child!
grid.Add("TextBlock").Text("Row 1").Parent()
    .Add("TextBlock").Text("Row 2")
```

### 4. Cascading Scope Defaults (CSS-style)
Tired of endlessly repeating `.Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold")`? The generator supports full CSS-like cascading defaults! 

When you set a default on an element, all children added inside that scope will automatically inherit those properties.

```ahk
; Apply a default style to all TextBlocks inside this panel and its descendants
panel1.SetDefaults("TextBlock", {Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold", Margin: "0,0,0,8"})

; These inherit the default properties automatically!
panel1.Add("TextBlock").Text("USERNAME")
panel1.Add("TextBlock").Text("PASSWORD")

; You can cleanly override specific defaults dynamically:
panel1.Add("TextBlock").Text("HEADER").FontSize(22) ; Overrides the 11pt font size!
```

> **Note:** Defaults are strictly scoped! When you stop adding children to `panel1` and move to `panel2`, the defaults reset automatically.

### 5. Reusable Templates (Theming Components)
If you want to apply a specific style *anywhere* without relying on scoped defaults, you can define **Global Templates**. These let you store object maps or complex callbacks and chain them onto any element using `.Use()`.

```ahk
X := XAML_Generator("Grid")

; Define a template using a simple properties object
X.DefineTemplate("SubtitleText", { Foreground: "{DynamicResource TextSub}", FontSize: 11, FontWeight: "Bold" })

; Define a template using a callback function for complex logic
PrimaryButtonTemplate(el) {
    el.Background("{DynamicResource Accent}").Foreground("White").FontWeight("Bold").BorderThickness(0)
    ; You can even inject XAML resources or append child elements inside a template!
    el.InjectResources('<Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style>')
}
X.DefineTemplate("PrimaryBtn", PrimaryButtonTemplate)

; --- Using them anywhere ---
sp.Add("TextBlock").Text("A styled label!").Use("SubtitleText")
btn := X.Add("Button").Content("Submit").Use("PrimaryBtn")
```

### 6. Custom Power-Tools (Component Injection)
You can build highly complex, reusable components and inject them globally into the `XAMLElement` prototype. This lets you call your custom shorthand methods natively anywhere in your UI tree!

```ahk
; 1. Define your custom component
XAMLElement.Prototype.DefineProp("LabeledInput", {Call: LabeledInput})

LabeledInput(this, labelText, placeholder := "") {
    sp := this.Add("StackPanel").Margin("0,0,0,15")
    sp.Add("TextBlock").Text(labelText).FontWeight("Bold")
    sp.Add("TextBox").Text(placeholder)
    return this ; Return the parent to continue chaining siblings
}

; 2. Use it natively anywhere!
panel := X.Add("StackPanel")
panel.LabeledInput("Username", "admin")
     .LabeledInput("Password")
```

## Quick Start Example

Look at `example.ahk` in this directory to see how a massively complex UI is constructed without any raw XAML strings. Here is a minimal implementation:

```ahk
#Requires AutoHotkey v2.0
#Include "../v2-csc/xaml.ahk"
#Include "XAML_Generator.ahk"

; 1. Build your UI procedurally
X := XAML_Generator("Grid").Background("{DynamicResource BgColor}")
X.Add("TextBlock").Text("Hello, World!").HorizontalAlignment("Center")

; Generate the compiled XAML string
CompiledMarkup := X.Compile()

; 2. Initialize the GUI engine
ui := XAMLGUI(StrReplace(XAML_TEMPLATE, "%app%", CompiledMarkup))
ui.Show()
```
