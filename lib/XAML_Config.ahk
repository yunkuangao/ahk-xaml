; ==============================================================================
; AHK-XAML Global Configuration
; ==============================================================================

; --- Engine Compilation ---
; When true, the C# engine (.dll) is recompiled from XAML_AHK_Bridge.cs on every run.
; When false, uses the pre-compiled ahk-xaml.dll from the lib directory.
global XAML_FORCE_DYNAMIC_COMPILE := false

; --- Component Style Loading ---
; "BAML"  → Load pre-compiled binary styles from the embedded BAML resource (fastest).
; "XAML"  → Parse the plain-text xaml.components.xaml at runtime (allows live style editing).
global XAML_COMPONENTS_LOAD_MODE := "BAML"

; --- Developer Diagnostics ---
; When true, crash dialogs show interactive "Skip Property" / "Skip Element" buttons
; for rapid iteration. Disable in production for a cleaner user experience.
global XAML_DIAGNOSTICS_ENABLED := true

; --- XAML Line Tracing ---
; Enable XAML line-number and file tracing comments (<!-- [ahk:File.ahk:LineNumber] -->)
; during generation. Turn off for production or to reduce XAML string size.
global XAML_ENABLE_TRACING := true

; --- WebView2 ---
global XAML_ENABLE_WEBVIEW := false

; --- Backward Compatibility ---
; XAML_DEBUG is derived from the new flags for any scripts that still reference it.
global XAML_DEBUG := XAML_FORCE_DYNAMIC_COMPILE