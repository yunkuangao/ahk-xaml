#Requires AutoHotkey v2.0
; ==============================================================================
; FLUID UI WORKBENCH — basic_components.ahk
; ==============================================================================
;
; HOW TO SWITCH TO PRODUCTION:
;   1. Run once with the DEV section active to generate the .baml
;   2. Comment out the ~~~ DEV ONLY ~~~ block
;   3. Uncomment the ~~~ PRODUCTION ONLY ~~~ block
;   4. Done — the app now loads from precompiled BAML (instant startup)
;
; ==============================================================================

; --- Core Libraries (always needed) ---
#Include "../../lib/XAML_Host.ahk"
#Include "../data/MockData.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_Components.ahk"
#Include "../../lib/XAML_Adv_Components.ahk"

; --- Shared globals (needed in both modes) ---
global myGrid := ""
global myDatePicker := ""
global tabList := ["DEPLOYMENT", "DATA GRID", "DATAGRID EX", "UI COMPONENTS", "ADVANCED INPUTS", "FLUID DIALOGS", "RICH COMPONENTS", "ADVANCED UI"]

app := XAML_GUI("Fluid UI")

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~ DEV ONLY — Comment out this entire block for production ~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Include "../../lib/XAML_Generator.ahk"
#Include "basic_components/basic_components_gui.ahk"
BuildFullGUI(app)

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~ PRODUCTION RUN — Uncomment this line for production, run once, ~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~ then comment out "DEV ONLY" and "PRODUCTION RUN" ~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~ For more control, control the flags in XAML_Config.ahk ~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;app.ExportBAML()
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


ui := app.Compile()

; --- Event Handlers (always needed) ---
#Include "basic_components/basic_components_events.ahk"

; --- Launch ---
app.Show()
ui.Update("MyEmoji_EmojiScroll", "TrapScroll", "")