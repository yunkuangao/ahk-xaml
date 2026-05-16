# Production Asset Workflow (`gui.bin`)

I have successfully refactored the engine to support a true "compiled" production asset workflow. You can now bundle all of your dynamic XAML and event bindings into a static `.bin` file, completely eliminating the need for `%TEMP%` file extraction in production!

## Implementation Details

### 1. Unified Asset Exporter (`XAML_Host.ahk`)
I added an `Export(filePath)` method to the `XAML_GUI` and `XAML_Host` classes. This method takes the final, computed XAML string and the event bindings, joins them using a custom `---AHK-XAML-EVENTS---` delimiter, and writes them to a single bundled `.bin` asset on disk.

### 2. Zero-Overhead Asset Ingestion (`XAML_AHK_Bridge.cs`)
I updated the C# `ahk-xaml.dll` engine so that if the passed `xamlFilePath` ends in `.bin`, it recognizes it as a production asset bundle. The C# engine ingests the file directly into memory, splits the payload back into XAML and Events, and completely skips the `%TEMP%` file deletion steps, safely parsing the UI instantly.

### 3. Side-by-Side Distribution Support
I updated the `A_IsCompiled` routing logic in `XAML_Host.ahk`. 
- **Priority 1**: When you run your compiled `.exe`, it will now check if `ahk-xaml.dll` exists in `A_ScriptDir` (the same folder as the `.exe`). If it does, it uses it directly.
- **Fallback**: If `ahk-xaml.dll` is missing, it behaves identically to before and extracts it to `%TEMP%` via `FileInstall`.

## How to use in Production

In your production build script, simply change your `app.Show()` call to:

```ahk
; Generate the static production asset
app.Export("gui.bin")

; Load the engine entirely from the static asset
app.Show("gui.bin")
```

When you distribute your final application, you can simply zip up your folder as:
- `MyApplication.exe`
- `ahk-xaml.dll`
- `gui.bin`

When users run `MyApplication.exe`, it will instantly launch `ahk-xaml.dll gui.bin` with absolutely zero disk I/O string generation, ensuring the fastest, most robust startup time possible!
