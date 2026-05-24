# AHK-XAML (AXML) VS Code Extension

This extension provides rich language support for the AXML format, which is the declarative UI markup language used by the `ahk-xaml` framework.

## Features

- **Syntax Highlighting**: Beautiful and robust YAML-like highlighting for AXML files (`.axml`), including inline AHK2 callbacks (`=> ...`).
- **IntelliSense & Autocomplete**: Start typing an element (e.g. `Grid`) or property (e.g. `Margin`, `Background`) and get intelligent suggestions.
- **Vibe Coding "Common Fixes"**: Analyzes your AXML in real-time and provides a yellow lightbulb (Quick Fix) when it detects a common typo (like using `BackgroundColor` instead of `Background`).
- **Hover Information**: Hover over elements, properties, or events to see descriptions.
- **Customizable Database**: Define your own properties and common typo fixes in your VS Code User Settings!

## Customization

Go to **File > Preferences > Settings** and search for `axml`.

You will find two powerful settings:
1. `axml.customProperties`: An array of custom strings to inject into the autocomplete engine.
2. `axml.commonFixes`: A key-value object linking "incorrect/typo" property names to their correct XAML equivalent. The extension uses this dictionary to provide real-time linter warnings and Quick Fixes.
