#Requires AutoHotkey v2.0

class Example_MockData {
    
    ; -------------------------------------------------------------------------
    ; DataGridEx Mock Data Generator
    ; -------------------------------------------------------------------------
    static GenerateDataGridExData() {
        testData := []
        roles := ["Administrator", "Developer", "Guest", "Manager", "Analyst"]
        statuses := ["Active", "Offline", "Pending"]
        names := ["John", "Jane", "Bob", "Alice", "Charlie", "Diana", "Eve", "Frank"]
        lasts := ["Doe", "Smith", "Wilson", "Johnson", "Brown", "Taylor", "Anderson"]
        
        loop 200 {
            n := names[Random(1, names.Length)] " " lasts[Random(1, lasts.Length)]
            r := roles[Random(1, roles.Length)]
            s := statuses[Random(1, statuses.Length)]
            testData.Push({ Id: A_Index, Name: n, Role: r, Status: s })
        }

        ; Scramble the data to prove "random order"
        scrambled := []
        while (testData.Length > 0) {
            idx := Random(1, testData.Length)
            scrambled.Push(testData[idx])
            testData.RemoveAt(idx)
        }
        
        return scrambled
    }

    ; -------------------------------------------------------------------------
    ; Emojis
    ; -------------------------------------------------------------------------
    static GetEmojiList() {
        return ["😀", "😁", "😂", "🤣", "😃", "😄", "😅", "😆", "😉", "😊", "😋", "😎", "😍", "🥰", "😘", "😗", "😙", "🤗", "🤩", "🤔", "🤨", "😐", "😑", "😶", "🙄", "😏", "😣", "😥", "😮", "🤐", "😯", "😪", "😫", "🥱", "😴", "😌", "👍", "👎", "👏", "🙌", "🤝", "👋", "✌️", "🤞", "🤟", "🤘", "👌", "🤌", "👈", "👉", "👆", "👇", "☝️", "✋", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "🔥", "⭐", "🌟", "✨", "💫", "🎉", "🎊", "🏆", "🥇", "🎯", "💡", "📌", "📎", "🔑", "🔒", "💬", "💭", "🗨️"]
    }

    ; -------------------------------------------------------------------------
    ; PropertyGrid Settings Map
    ; -------------------------------------------------------------------------
    static GetMockSettingsMap() {
        return Map(
            "General", Map(
                "AppName", "AHK Studio",
                "Version", 2.1,
                "IsPortable", true,
                "MaxRecentFiles", 10
            ),
            "Editor", Map(
                "FontFamily", "Consolas",
                "FontSize", 14,
                "WordWrap", false,
                "ShowLineNumbers", true,
                "TabSize", 4
            ),
            "Advanced", Map(
                "EnableTelemetry", false,
                "DebugLevel", 3,
                "CustomArgs", "--verbose"
            )
        )
    }

    ; -------------------------------------------------------------------------
    ; Markdown Test Content
    ; -------------------------------------------------------------------------
    static GetMockMarkdownText() {
        return "
        (
            # Project Documentation
            ## Overview
            This is a demonstration of the dynamic MarkdownRenderer control.
            
            ### Features
            - Native WPF Runs and Blocks
            - Dynamic style mapping
            - No HTML rendering overhead
            - Supports **bold text** dynamically!
        )"
    }

    ; -------------------------------------------------------------------------
    ; Kanban Board
    ; -------------------------------------------------------------------------
    static PopulateKanbanBoard(kb) {
        kb.AddColumn("To Do", "#FF3333")
        kb.AddColumn("In Progress", "#FFCC00")
        kb.AddColumn("Done", "#32D74B")

        kb.AddCard(1, "Design mockups")
        kb.AddCard(1, "Fix memory leak")
        kb.AddCard(2, "Implement CommandBar")
        kb.AddCard(2, "Refactor XAML Engine")
        kb.AddCard(3, "Write unit tests")
    }

    ; -------------------------------------------------------------------------
    ; Node Graph
    ; -------------------------------------------------------------------------
    static PopulateNodeGraph(ng) {
        ng.AddNode("Input1", "REST API Source", 40, 60, "Input")
        ng.AddNode("Input2", "Database Polling", 40, 200, "Input")
        ng.AddNode("Filter", "Filter Records", 240, 40, "Process")
        ng.AddNode("Transform", "Transform Data", 240, 160, "Process")
        ng.AddNode("Merge", "Merge Results", 460, 100, "Process")
        ng.AddNode("Output", "Export JSON", 680, 100, "Output")

        ng.AddConnection("Input1", "Filter")
        ng.AddConnection("Input2", "Transform")
        ng.AddConnection("Filter", "Merge")
        ng.AddConnection("Transform", "Merge")
        ng.AddConnection("Merge", "Output")
    }

    ; -------------------------------------------------------------------------
    ; VS Code Clone Data
    ; -------------------------------------------------------------------------
    static GetVSCodeFilesData() {
        return Map(
            "Main", { text: "#Requires AutoHotkey v2.0`nMsgBox `"Welcome to VS Code Clone!`"`n`n; Press Ctrl+Shift+P to open Command Palette!`n", type: "code" },
            "XAML_GUI", { text: "class XAML_GUI {`n    __New(title, config) {`n        this.title := title`n    }`n}", type: "code" },
            "README", { text: "# AHK-XAML`n`nA modern UI framework for AutoHotkey.`n", type: "code" },
            "XAML_Components", { text: "", type: "error" },
            "Chat", { text: "; example_clone_chat.ahk`n; Chat clone implementation coming soon!`n", type: "code" },
            "Settings_Ini", { text: "", type: "ini" },
            "Settings", { text: "", type: "settings" }
        )
    }

    static PopulateVSCodeCommandPalette(cmdPalette) {
        cmdPalette.AddCommand("reload", "Developer: Reload Window", { Icon: Chr(0xE72C), Shortcut: "Ctrl+Shift+F5", Category: "Developer" })
        cmdPalette.AddCommand("terminal", "Terminal: Create New Terminal", { Icon: Chr(0xE756), Shortcut: "Ctrl+``", Category: "Terminal" })
        cmdPalette.AddCommand("settings", "Preferences: Open Settings", { Icon: Chr(0xE713), Shortcut: "Ctrl+,", Category: "Preferences" })
        cmdPalette.AddCommand("file_new", "File: New File", { Icon: Chr(0xE8A5), Shortcut: "Ctrl+N", Category: "File" })
        cmdPalette.AddCommand("file_save", "File: Save", { Icon: Chr(0xE74E), Shortcut: "Ctrl+S", Category: "File" })
        cmdPalette.AddCommand("file_saveas", "File: Save As...", { Icon: Chr(0xE792), Shortcut: "Ctrl+Shift+S", Category: "File" })
        cmdPalette.AddCommand("toggle_sidebar", "View: Toggle Sidebar", { Icon: Chr(0xE700), Shortcut: "Ctrl+B", Category: "View" })
        cmdPalette.AddCommand("theme_dark", "Preferences: Color Theme (Dark)", { Icon: Chr(0xE793), Category: "Preferences" })
        cmdPalette.AddCommand("theme_light", "Preferences: Color Theme (Light)", { Icon: Chr(0xE706), Category: "Preferences" })
        cmdPalette.AddCommand("goto_line", "Go to Line...", { Icon: Chr(0xE8A1), Shortcut: "Ctrl+G", Category: "Navigation" })
        cmdPalette.AddCommand("find_replace", "Edit: Find and Replace", { Icon: Chr(0xE721), Shortcut: "Ctrl+H", Category: "Edit" })
        cmdPalette.AddCommand("format_doc", "Format Document", { Icon: Chr(0xE943), Shortcut: "Shift+Alt+F", Category: "Edit" })
        cmdPalette.AddCommand("toggle_wrap", "View: Toggle Word Wrap", { Icon: Chr(0xE8B3), Shortcut: "Alt+Z", Category: "View" })
        cmdPalette.AddCommand("help_welcome", "Help: Welcome", { Icon: Chr(0xE897), Category: "Help" })
        cmdPalette.AddCommand("help_docs", "Help: Documentation", { Icon: Chr(0xE736), Category: "Help" })
        cmdPalette.AddCommand("help_about", "Help: About", { Icon: Chr(0xE946), Category: "Help" })

        cmdPalette.SetHomeCommands(["settings", "terminal", "reload", "file_new", "toggle_sidebar"])
    }
    
    ; -------------------------------------------------------------------------
    ; VS Code Clone UI Generators
    ; -------------------------------------------------------------------------
    static AddTab(container, icon, color, text, name, isSelected := false, isVisible := false) {
        bdr := container.Add("Border").Name("BtnTab_" name).Background(isSelected ? "{DynamicResource SolidBg}" : "{DynamicResource SolidControl}").BorderBrush(isSelected ? "{DynamicResource Accent}" : "Transparent").BorderThickness("0,2,0,0").Padding("15,0").Height("35").VerticalAlignment("Top").Cursor("Hand")
        bdr.Visibility(isVisible ? "Visible" : "Collapsed")
    
        sp := bdr.Add("StackPanel").Orientation("Horizontal")
        sp.Add("TextBlock").Text(Chr(icon)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground(color).FontSize(14).Margin("0,0,8,0").VerticalAlignment("Center")
        sp.Add("TextBlock").Name("TxtTab_" name).Text(text).Foreground(isSelected ? "{DynamicResource TextMain}" : "{DynamicResource TextSub}").VerticalAlignment("Center").IsHitTestVisible("False")
    
        closeBtn := sp.Add("Button").Name("BtnCloseTab_" name).Content(Chr(0xE711)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextSub}").FontSize(10).Margin("10,0,0,0").VerticalAlignment("Center").Cursor("Hand")
    
        ctpl := closeBtn.Add("Button.Template").Add("ControlTemplate").TargetType("Button")
        cbdr := ctpl.Add("Border").Background("{TemplateBinding Background}").Padding("2").CornerRadius("2")
        cbdr.Add("ContentPresenter").HorizontalAlignment("Center").VerticalAlignment("Center")
    
        cstyle := closeBtn.Add("Button.Style").Add("Style").TargetType("Button")
        ct := cstyle.Add("Style.Triggers").Add("Trigger").Property("IsMouseOver").Value("True")
        ct.Add("Setter").Property("Background").Value("{DynamicResource ControlBgHover}")
    }

    static AddIniField(sp, label, value) {
        p := sp.Add("StackPanel").Margin("0,0,0,20")
        p.Add("TextBlock").Text(label).Foreground("{DynamicResource TextSub}").FontSize(12).FontWeight("SemiBold").Margin("0,0,0,8")
        p.Add("TextBox").Text(value).Background("{DynamicResource SolidControl}").Foreground("{DynamicResource TextMain}").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Padding("10")
    }

    static AddActivityIcon(sp, iconHex, name, isActive := false) {
        btn := sp.Add("Button").Name(name).Content(Chr(iconHex)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(24).Margin("0,10")
        btn.Background("Transparent").BorderThickness("2,0,0,0").Foreground(isActive ? "{DynamicResource TextMain}" : "{DynamicResource TextSub}")
        btn.BorderBrush(isActive ? "{DynamicResource TextMain}" : "Transparent")
        btn.Cursor("Hand")
    
        ; Define Template
        tpl := btn.Add("Button.Template").Add("ControlTemplate").TargetType("Button")
        bdr := tpl.Add("Border").Background("{TemplateBinding Background}").BorderBrush("{TemplateBinding BorderBrush}").BorderThickness("{TemplateBinding BorderThickness}")
        bdr.Add("ContentPresenter").HorizontalAlignment("Center").VerticalAlignment("Center")
    
        ; Hover style
        style := btn.Add("Button.Style").Add("Style").TargetType("Button")
        t := style.Add("Style.Triggers").Add("Trigger").Property("IsMouseOver").Value("True")
        t.Add("Setter").Property("Foreground").Value("{DynamicResource TextMain}")
        return btn
    }

    static AddFileNode(sp, indent, iconHex, color, text, name, isSelected := false, isError := false) {
        btn := sp.Add("Button").Name("BtnNode_" name).Background(isSelected ? "{DynamicResource SolidBorder}" : "Transparent").BorderThickness("0").HorizontalContentAlignment("Left").Padding(String(indent) ",4,0,4").Cursor("Hand")
    
        tpl := btn.Add("Button.Template").Add("ControlTemplate").TargetType("Button")
        tpl.Add("Border").Background("{TemplateBinding Background}").Padding("{TemplateBinding Padding}").Add("ContentPresenter")
    
        style := btn.Add("Button.Style").Add("Style").TargetType("Button")
        t := style.Add("Style.Triggers").Add("Trigger").Property("IsMouseOver").Value("True")
        t.Add("Setter").Property("Background").Value("{DynamicResource ControlBgHover}")
    
        panel := btn.Add("StackPanel").Orientation("Horizontal")
        panel.Add("TextBlock").Text(Chr(iconHex)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground(isError ? "{DynamicResource ErrorColor}" : color).FontSize(14).Margin("0,0,8,0").VerticalAlignment("Center")
    
        textColor := isError ? "{DynamicResource ErrorColor}" : (isSelected ? "{DynamicResource TextMain}" : "{DynamicResource TextSub}")
        panel.Add("TextBlock").Name("TxtNode_" name).Text(text).Foreground(textColor).TextDecorations(isError ? "Strikethrough" : "None").VerticalAlignment("Center")
    }
}
