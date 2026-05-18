; ==============================================================================
; AHK-XAML Global Configuration
; ==============================================================================

; Set to true for Development Mode (generates UI dynamically on every run).
; Set to false for Production Mode (compiles UI into a standalone DLL/EXE and loads it instantly).
global XAML_DEBUG := true
global XAML_ENABLE_WEBVIEW := false

; Enable XAML line-number and file tracing comments (<!-- [ahk:File.ahk:LineNumber] -->) during generation.
; Turn off for production or to reduce XAML string size.
global XAML_ENABLE_TRACING := true