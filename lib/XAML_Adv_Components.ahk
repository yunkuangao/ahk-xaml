#Requires AutoHotkey v2.0
#Include "XAML_Host.ahk"
#Include "XAML_Generator.ahk"

; ==============================================================================
; COMMAND BAR
; ==============================================================================

class XCommandBar {
    __New(parentXAML, name := "") {
        this.id := name != "" ? name : "CmdBar_" XCommandBar.Count()
        
        this.container := parentXAML.Add("Border").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("6").Padding("4")
        this.sp := this.container.Add("StackPanel").Orientation("Horizontal").Name(this.id)
    }

    AddButton(iconHex, text, callbackName := "", tooltip := "") {
        btn := this.sp.Add("Button").Margin("2,0").Padding("8,4")
        btn.InjectResources('<Style TargetType="Button"><Setter Property="Background" Value="Transparent"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="4"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#15FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
        if (tooltip != "")
            btn.ToolTip(tooltip)
        
        sp := btn.Add("StackPanel").Orientation("Horizontal").Margin("4,2")
        sp.Add("TextBlock").Text(iconHex).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(14).VerticalAlignment("Center").Margin("0,0,6,0")
        sp.Add("TextBlock").Text(text).VerticalAlignment("Center").FontSize(12)
        
        if (callbackName != "")
            btn.Name(callbackName)
        
        return btn
    }

    AddSeparator() {
        this.sp.Add("Rectangle").Width(1).Fill("{DynamicResource ControlBorder}").Margin("4,4,4,4").VerticalAlignment("Stretch")
    }

    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("CommandBar", { Call: _CommandBar })
_CommandBar(this, name := "") {
    return XCommandBar(this, name)
}

; ==============================================================================
; NAVIGATION VIEW (Sidebar Router)
; ==============================================================================

class XNavigationView {
    __New(parentXAML, name := "") {
        this.id := name != "" ? name : "NavView_" XNavigationView.Count()
        this.pages := []
        this.ui := ""
        
        this.grid := parentXAML.Add("Grid").Name(this.id)
        this.grid.Cols("250", "*")
        
        ; Sidebar
        this.sidebarBorder := this.grid.Add("Border").Grid_Column(0).Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0")
        this.sidebarGrid := this.sidebarBorder.Add("Grid")
        this.sidebarGrid.Rows("Auto", "*", "Auto")
        
        ; Header (Logo/Title) - Optional placeholder
        this.header := this.sidebarGrid.Add("StackPanel").Grid_Row(0).Margin("15,20,15,10")
        
        ; Top Items
        this.topList := this.sidebarGrid.Add("StackPanel").Grid_Row(1).Margin("10,0")
        
        ; Bottom Items
        this.bottomList := this.sidebarGrid.Add("StackPanel").Grid_Row(2).Margin("10,0,10,15")
        
        ; Main Content Area
        this.contentBorder := this.grid.Add("Border").Grid_Column(1).Background("Transparent").Padding("20")
        this.contentGrid := this.contentBorder.Add("Grid").Name(this.id "_Content")
    }

    AddPage(title, iconHex, contentXAMLObj, isBottom := false) {
        idx := this.pages.Length + 1
        pageId := this.id "_Page_" idx
        btnId := this.id "_Btn_" idx
        
        contentXAMLObj.Grid_Column(0).Grid_Row(0).Name(pageId).Visibility("Collapsed")
        contentXAMLObj._Parent := this.contentGrid
        this.contentGrid._Children.Push(contentXAMLObj)
        
        targetList := isBottom ? this.bottomList : this.topList
        btn := targetList.Add("RadioButton").Name(btnId).GroupName(this.id "_NavGroup").Margin("0,2").Cursor("Hand")
        
        btn.InjectResources('<Style TargetType="RadioButton"><Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="RadioButton"><Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="4"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Border x:Name="indicator" Width="3" Height="16" CornerRadius="1.5" Background="{DynamicResource Accent}" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="2,0,0,0" Opacity="0"/><ContentPresenter Grid.Column="1" Margin="12,10"/></Grid></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#10FFFFFF"/></Trigger><Trigger Property="IsChecked" Value="True"><Setter TargetName="bg" Property="Background" Value="#1AFFFFFF"/><Setter TargetName="indicator" Property="Opacity" Value="1"/><Setter Property="FontWeight" Value="SemiBold"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
        
        sp := btn.Add("StackPanel").Orientation("Horizontal")
        sp.Add("TextBlock").Text(iconHex).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).VerticalAlignment("Center").Margin("0,0,15,0").Width("20").TextAlignment("Center")
        sp.Add("TextBlock").Text(title).VerticalAlignment("Center").FontSize(14)
        
        pageObj := { Title: title, PageId: pageId, BtnId: btnId }
        this.pages.Push(pageObj)
        
        if (idx == 1) {
            btn.IsChecked("True")
            contentXAMLObj.Visibility("Visible")
        }
        
        return pageObj
    }

    Bind(ui) {
        this.ui := ui
        for page in this.pages {
            ui.OnEvent(page.BtnId, "Checked", ObjBindMethod(this, "OnNavChange", page.PageId))
        }
    }

    OnNavChange(pageId, state, ctrl, event) {
        for page in this.pages {
            if (page.PageId == pageId)
                this.ui.Update(page.PageId, "Visibility", "Visible")
            else
                this.ui.Update(page.PageId, "Visibility", "Collapsed")
        }
    }

    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("NavigationView", { Call: _NavigationView })
_NavigationView(this, name := "") {
    return XNavigationView(this, name)
}

; ==============================================================================
; KANBAN BOARD
; ==============================================================================

class XKanbanBoard {
    __New(parentXAML, name := "") {
        this.id := name != "" ? name : "Kanban_" XKanbanBoard.Count()
        this.columns := []
        this.ui := ""
        
        this.sv := parentXAML.Add("ScrollViewer").HorizontalScrollBarVisibility("Auto").VerticalScrollBarVisibility("Disabled")
        this.boardSp := this.sv.Add("StackPanel").Orientation("Horizontal").Name(this.id)
    }

    AddColumn(title, accentColor := "#0078D7") {
        colIdx := this.columns.Length + 1
        colId := this.id "_Col_" colIdx
        addBtnId := this.id "_Add_" colIdx
        countId := this.id "_Count_" colIdx
        
        bdr := this.boardSp.Add("Border").Background("#08FFFFFF").BorderBrush("#30FFFFFF").BorderThickness("1").CornerRadius("12").Width("280").Margin("0,0,12,0")
        grid := bdr.Add("Grid").Margin("14")
        grid.Rows("Auto", "*", "Auto")
        
        headerGrid := grid.Add("Grid").Grid_Row(0).Margin("0,0,0,14")
        headerGrid.Cols("Auto", "*", "Auto")
        headerGrid.Add("Border").Width("8").Height("8").CornerRadius("4").Background(accentColor).Margin("0,0,10,0").VerticalAlignment("Center")
        headerGrid.Add("TextBlock").Text(title).Grid_Column(1).FontWeight("SemiBold").FontSize("13").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")
        countBdr := headerGrid.Add("Border").Grid_Column(2).Background("#15FFFFFF").CornerRadius("10").Padding("8,2")
        countBdr.Add("TextBlock").Name(countId).Text("0").Foreground("{DynamicResource TextSub}").FontSize("11")
        
        lb := grid.Add("ListBox").Name(colId).Grid_Row(1).Background("Transparent").BorderThickness("0").ScrollViewer_HorizontalScrollBarVisibility("Disabled").Padding("0")
        
        lb.InjectResources('<Style TargetType="ListBoxItem"><Setter Property="Margin" Value="0,0,0,6"/><Setter Property="Padding" Value="0"/><Setter Property="HorizontalContentAlignment" Value="Stretch"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ListBoxItem"><Border x:Name="bd" Background="{DynamicResource DropdownBg}" BorderBrush="Transparent" BorderThickness="3,0,0,0" CornerRadius="6" Padding="12,10" Cursor="Hand"><Border.Effect><DropShadowEffect BlurRadius="4" ShadowDepth="1" Opacity="0.2" Direction="270" Color="Black"/></Border.Effect><ContentPresenter/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="' accentColor '"/><Setter TargetName="bd" Property="Background" Value="#12FFFFFF"/></Trigger><Trigger Property="IsSelected" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="' accentColor '"/><Setter TargetName="bd" Property="Background" Value="#18FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
        
        ; Add Card button
        addBtn := grid.Add("Button").Name(addBtnId).Grid_Row(2).Margin("0,8,0,0").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness("0").Cursor("Hand").HorizontalAlignment("Stretch")
        addBtn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="Transparent" BorderBrush="#20FFFFFF" BorderThickness="1" CornerRadius="6" Padding="8,7"><TextBlock Text="+ Add Card" HorizontalAlignment="Center" Foreground="{DynamicResource TextSub}" FontSize="12"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#08FFFFFF"/><Setter TargetName="bg" Property="BorderBrush" Value="' accentColor '"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
        
        colObj := { Title: title, Id: colId, AddBtnId: addBtnId, CountId: countId, ListBox: lb, Data: [], Color: accentColor, Index: colIdx }
        this.columns.Push(colObj)
        return colObj
    }
    
    AddCard(colIndex, cardText) {
        if (colIndex > 0 && colIndex <= this.columns.Length) {
            col := this.columns[colIndex]
            col.ListBox.Add("ListBoxItem").Content(cardText)
            col.Data.Push(cardText)
        }
    }

    Bind(ui) {
        this.ui := ui
        for col in this.columns {
            ui.Track(col.Id)
            ui.OnEvent(col.Id, "SelectionChanged", ObjBindMethod(this, "OnCardSelected", col.Id))
            ui.OnEvent(col.AddBtnId, "Click", ObjBindMethod(this, "OnAddCard", A_Index))
            ui.OnEvent(col.Id, "ItemDropped", ObjBindMethod(this, "OnItemDropped", A_Index))
        }
        ; Delay count update to ensure WPF names are registered
        SetTimer(ObjBindMethod(this, "UpdateCounts"), -300)
    }
    
    UpdateCounts() {
        for col in this.columns {
            if (this.ui != "")
                this.ui.Update(col.CountId, "Text", String(col.Data.Length))
        }
    }
    
    OnCardSelected(colId, state, ctrl, event) {
        if !state.Has(colId)
            return
        this.selectedCard := state[colId]
        this.selectedCol := colId
        this.selectedColIdx := 0
        for col in this.columns {
            if (col.Id == colId) {
                this.selectedColIdx := A_Index
                break
            }
        }
    }
    
    OnAddCard(colIdx, state, ctrl, event) {
        col := this.columns[colIdx]
        ib := InputBox("Enter card text:", "Add Card to " col.Title, "w300 h130")
        if (ib.Result == "OK" && ib.Value != "") {
            this.ui.Update(col.Id, "AddItem", ib.Value)
            col.Data.Push(ib.Value)
            this.UpdateCounts()
        }
    }
    
    MoveSelectedTo(targetIdx) {
        if (!this.HasProp("selectedCard") || this.selectedCard == "" || !this.HasProp("selectedColIdx") || this.selectedColIdx == 0)
            return
        if (this.selectedColIdx == targetIdx)
            return
        cardText := this.selectedCard
        dstCol := this.columns[targetIdx]
        srcCol := this.columns[this.selectedColIdx]
        
        removed := false
        newData := []
        for item in srcCol.Data {
            if (!removed && item == cardText) {
                removed := true
                continue
            }
            newData.Push(item)
        }
        srcCol.Data := newData
        dstCol.Data.Push(cardText)
        
        this.ui.Update(srcCol.Id, "ClearItems", "")
        for item in srcCol.Data
            this.ui.Update(srcCol.Id, "AddItem", item)
            
        this.ui.Update(dstCol.Id, "ClearItems", "")
        for item in dstCol.Data
            this.ui.Update(dstCol.Id, "AddItem", item)
            
        this.selectedCard := ""
        this.selectedColIdx := 0
        this.UpdateCounts()
    }

    OnItemDropped(dstColIdx, state, ctrl, event) {
        if !state.Has("DragCoords")
            return
        parts := StrSplit(state["DragCoords"], "|")
        if (parts.Length < 2)
            return
            
        srcColId := parts[1]
        cardText := parts[2]
        
        srcColIdx := 0
        for col in this.columns {
            if (col.Id == srcColId) {
                srcColIdx := A_Index
                break
            }
        }
        
        if (srcColIdx == 0 || srcColIdx == dstColIdx)
            return
            
        srcCol := this.columns[srcColIdx]
        dstCol := this.columns[dstColIdx]
        
        ; Find the exact index to remove to avoid removing duplicates
        removed := false
        newData := []
        for item in srcCol.Data {
            if (!removed && item == cardText) {
                removed := true
                continue
            }
            newData.Push(item)
        }
        srcCol.Data := newData
        
        ; Add to destination data
        dstCol.Data.Push(cardText)
        
        ; Rebuild UI completely to ensure sync
        this.ui.Update(srcCol.Id, "ClearItems", "")
        for item in srcCol.Data
            this.ui.Update(srcCol.Id, "AddItem", item)
            
        this.ui.Update(dstCol.Id, "ClearItems", "")
        for item in dstCol.Data
            this.ui.Update(dstCol.Id, "AddItem", item)
        
        this.UpdateCounts()
    }
    
    EnableDrag(ui) {
        for col in this.columns {
            ui.Update(col.Id, "EnableListBoxDragDrop", "")
        }
    }
    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("KanbanBoard", { Call: _KanbanBoard })
_KanbanBoard(this, name := "") {
    return XKanbanBoard(this, name)
}


; ==============================================================================
; NODE GRAPH / VISUAL SCRIPTER
; ==============================================================================

class XNodeGraph {
    __New(parentXAML, name := "") {
        this.id := name != "" ? name : "NodeGraph_" XNodeGraph.Count()
        this.ui := ""
        this.nodes := []
        this.connections := []
        this.selectedNodes := Map()
        
        this.bdr := parentXAML.Add("Border").Background("#1E1E1E").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("8").ClipToBounds("True")
        
        this.bdr.InjectResources('<DrawingBrush x:Key="GridPattern" Viewport="0,0,20,20" ViewportUnits="Absolute" TileMode="Tile"><DrawingBrush.Drawing><DrawingGroup><GeometryDrawing Geometry="M0,20 L20,20 M20,0 L20,20"><GeometryDrawing.Pen><Pen Brush="#2A2A2A" Thickness="1"/></GeometryDrawing.Pen></GeometryDrawing></DrawingGroup></DrawingBrush.Drawing></DrawingBrush>')
        
        cm := this.bdr.Add("FrameworkElement.ContextMenu").Add("ContextMenu").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}")
        cm.Add("MenuItem").Name(this.id "_BtnNewNode").Header("Add Process Node")
        cm.Add("MenuItem").Name(this.id "_BtnNewInput").Header("Add Input Node")
        cm.Add("MenuItem").Name(this.id "_BtnNewOutput").Header("Add Output Node")
        cm.Add("MenuItem").Name(this.id "_BtnNewMultiProcess").Header("Add Multi-Port Process Node")
        
        this.offsetX := 10000
        this.offsetY := 10000
        this.canvas := this.bdr.Add("Canvas").Name(this.id).Background("{DynamicResource GridPattern}").Width("20000").Height("20000").Margin("-" this.offsetX ",-" this.offsetY ",0,0")
    }

    AddNode(id, title, x, y, nodeType := "Process") {
        x += this.offsetX
        y += this.offsetY
        node := this.canvas.Add("Border").Name("Node_" id).Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("6").Width("160").SetProp("Canvas.Left", String(x)).SetProp("Canvas.Top", String(y))
        node.Add("Border.Effect").Add("DropShadowEffect").BlurRadius("8").ShadowDepth("2").Opacity("0.4").Direction("270").Color("Black")
        
        grid := node.Add("Grid")
        grid.Rows("30", "*")
        
        ; Color-coded header by type
        headerColor := nodeType == "Input" ? "#2E5A2E" : (nodeType == "Output" ? "#5A2E2E" : "#3E3E50")
        header := grid.Add("Border").Name(this.id "_Header_" id).Grid_Row(0).Cursor("SizeAll").Background(headerColor).CornerRadius("5,5,0,0")
        headerGrid := header.Add("Grid")
        headerGrid.Cols("*", "Auto")
        headerGrid.Add("TextBlock").Text(title).Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize("11").VerticalAlignment("Center").Margin("10,0")
        headerGrid.Add("TextBlock").Text(nodeType).Grid_Column(1).Foreground("#888").FontSize("9").VerticalAlignment("Center").Margin("0,0,8,0")
        
        body := grid.Add("StackPanel").Grid_Row(1).Margin("10,6,10,8")
        bodyTb := body.Add("TextBlock").Foreground("#999").FontSize("10")
        if (nodeType == "Input") {
            bodyTb.Add("Run").Text(Chr(0xE8B5)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets")
            bodyTb.Add("Run").Text("  Source")
        } else if (nodeType == "Output") {
            bodyTb.Add("Run").Text(Chr(0xE898)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets")
            bodyTb.Add("Run").Text("  Sink")
        } else {
            bodyTb.Add("Run").Text(Chr(0xE943)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets")
            bodyTb.Add("Run").Text("  Transform")
        }
        
        ; Port indicators - Input port (left side)
        if (nodeType != "Input") {
            inPort := this.canvas.Add("Ellipse").Width("10").Height("10").Fill("#4CAF50").Stroke("#333").StrokeThickness("1").SetProp("Canvas.Left", String(x - 5)).SetProp("Canvas.Top", String(y + 30)).Name("Port_In_" id).IsHitTestVisible("True").Cursor("Hand")
        }
        ; Output port (right side)
        if (nodeType != "Output") {
            outPort := this.canvas.Add("Ellipse").Width("10").Height("10").Fill("#FF5722").Stroke("#333").StrokeThickness("1").SetProp("Canvas.Left", String(x + 155)).SetProp("Canvas.Top", String(y + 30)).Name("Port_Out_" id).IsHitTestVisible("True").Cursor("Hand")
        }
        
        nodeObj := { Id: id, Title: title, X: x, Y: y, UI: node, Body: body, W: 160, H: 60, Type: nodeType }
        this.nodes.Push(nodeObj)
        return nodeObj
    }
    
    GetNode(id) {
        for n in this.nodes {
            if (n.Id == id)
                return n
        }
        return ""
    }
    
    AddConnection(fromId, toId) {
        pathId := this.id "_Path_" fromId "_" toId
        pathEl := this.canvas.Add("Path").Name(pathId).Stroke("#60A0FF").StrokeThickness("2.5").Opacity("0.8").SetProp("Panel.ZIndex", "-1")
        conn := { From: fromId, To: toId, PathId: pathId, PathEl: pathEl, Selected: false }
        this.connections.Push(conn)
        this.UpdatePath(fromId, toId, pathId, true, pathEl)
        if (this.ui) {
            this.ui.OnEvent(pathId, "MouseLeftButtonDown", ObjBindMethod(this, "OnPathClicked", pathId))
        }
    }
    
    UpdatePath(fromId, toId, pathId, initial := false, pathEl := "") {
        n1 := this.GetNode(fromId)
        n2 := this.GetNode(toId)
        if (!n1 || !n2)
            return
        
        ; Connect from output port (right) to input port (left)
        startX := n1.X + n1.W + 5
        startY := n1.Y + 35
        endX := n2.X - 5
        endY := n2.Y + 35
        
        ; Bezier control point offset scales with distance
        dx := Abs(endX - startX) * 0.5
        if (dx < 40)
            dx := 40
        ctrl1X := startX + dx
        ctrl1Y := startY
        ctrl2X := endX - dx
        ctrl2Y := endY
        
        geom := Format("M{},{} C{},{} {},{} {},{}", startX, startY, ctrl1X, ctrl1Y, ctrl2X, ctrl2Y, endX, endY)
        if (initial && pathEl != "") {
            ; Set initial Data string on the Path element directly at XAML build time
            pathEl.SetProp("Data", geom)
        } else if (this.ui != "")
            this.ui.Update(pathId, "Data", geom)
    }

    Bind(ui) {
        this.ui := ui
        ui.OnEvent(this.id "_BtnNewNode", "Click", ObjBindMethod(this, "OnNewNode", "Process"))
        ui.OnEvent(this.id "_BtnNewInput", "Click", ObjBindMethod(this, "OnNewNode", "Input"))
        ui.OnEvent(this.id "_BtnNewOutput", "Click", ObjBindMethod(this, "OnNewNode", "Output"))
        ui.OnEvent(this.id "_BtnNewMultiProcess", "Click", ObjBindMethod(this, "OnNewNode", "MultiProcess"))
        
        ; Enable C#-side drag on each node border, listen for DragMove events
        for node in this.nodes {
            ui.OnEvent("Node_" node.Id, "DragMove", ObjBindMethod(this, "OnNodeMoved", node.Id))
        }
        
        ; Canvas events for Selection and Connection
        ui.OnEvent(this.id, "SelectionBox", ObjBindMethod(this, "OnSelectionBox"))
        ui.OnEvent(this.id, "CtrlSelectionBox", ObjBindMethod(this, "OnCtrlSelectionBox"))
        ui.OnEvent(this.id, "ClearSelection", ObjBindMethod(this, "OnClearSelection"))
        ui.OnEvent(this.id, "ConnectPorts", ObjBindMethod(this, "OnConnectPorts"))
        ui.OnEvent(this.id, "DeleteConnection", ObjBindMethod(this, "OnDeleteConnection"))
        
        ; Initial draw of connections
        for conn in this.connections
            this.UpdatePath(conn.From, conn.To, conn.PathId)
    }
    
    ; Called after UI is ready to enable drag on each node
    EnableDrag(ui, snap := true) {
        ; Enable zoom and pan on the canvas
        ui.Update(this.id, "EnableZoomPan", "")
        mode := snap ? "grid=20" : ""
        for node in this.nodes {
            ui.Update("Node_" node.Id, "EnableDrag", mode)
        }
    }
    
    SetGridSnap(ui, enable) {
        mode := enable ? "grid=20" : ""
        for node in this.nodes {
            ui.Update("Node_" node.Id, "EnableDrag", mode)
        }
    }
    
    OnNewNode(nodeType, state, ctrl, event) {
        idx := this.nodes.Length + 1
        newId := "Node" idx
        headerBg := nodeType == "Input" ? "#2E5A2E" : (nodeType == "Output" ? "#5A2E2E" : (nodeType == "MultiProcess" ? "#8A2BE2" : "#3E3E50"))
        label := nodeType == "Input" ? "Source" : (nodeType == "Output" ? "Sink" : "Transform")
        
        ; Port visual logic
        inPortXAML := ""
        outPortXAML := ""
        if (nodeType != "Input") {
            if (nodeType == "MultiProcess") {
                inPortXAML := '<Ellipse Name="Port_In_' newId '" Width="10" Height="10" Fill="#4CAF50" Stroke="#333" StrokeThickness="1" Canvas.Left="195" Canvas.Top="220" IsHitTestVisible="True" Cursor="Hand"/><Ellipse Name="Port_In2_' newId '" Width="10" Height="10" Fill="#4CAF50" Stroke="#333" StrokeThickness="1" Canvas.Left="195" Canvas.Top="240" IsHitTestVisible="True" Cursor="Hand"/>'
            } else {
                inPortXAML := '<Ellipse Name="Port_In_' newId '" Width="10" Height="10" Fill="#4CAF50" Stroke="#333" StrokeThickness="1" Canvas.Left="195" Canvas.Top="230" IsHitTestVisible="True" Cursor="Hand"/>'
            }
        }
        if (nodeType != "Output") {
            if (nodeType == "MultiProcess") {
                outPortXAML := '<Ellipse Name="Port_Out_' newId '" Width="10" Height="10" Fill="#FF5722" Stroke="#333" StrokeThickness="1" Canvas.Left="355" Canvas.Top="220" IsHitTestVisible="True" Cursor="Hand"/><Ellipse Name="Port_Out2_' newId '" Width="10" Height="10" Fill="#FF5722" Stroke="#333" StrokeThickness="1" Canvas.Left="355" Canvas.Top="240" IsHitTestVisible="True" Cursor="Hand"/>'
            } else {
                outPortXAML := '<Ellipse Name="Port_Out_' newId '" Width="10" Height="10" Fill="#FF5722" Stroke="#333" StrokeThickness="1" Canvas.Left="355" Canvas.Top="230" IsHitTestVisible="True" Cursor="Hand"/>'
            }
        }
        
        ; Build raw XAML string with proper namespace for injection
        xamlStr := '<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Node_' newId '" Background="#2D2D30" BorderBrush="#3F3F46" BorderThickness="1" CornerRadius="6" Width="160" Canvas.Left="200" Canvas.Top="200"><Border.Effect><DropShadowEffect BlurRadius="8" ShadowDepth="2" Opacity="0.4" Direction="270" Color="Black"/></Border.Effect><Grid><Grid.RowDefinitions><RowDefinition Height="30"/><RowDefinition Height="*"/></Grid.RowDefinitions><Border Grid.Row="0" Background="' headerBg '" CornerRadius="5,5,0,0" Cursor="SizeAll"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock Text="' nodeType ' ' idx '" Foreground="White" FontWeight="Bold" FontSize="11" VerticalAlignment="Center" Margin="10,0"/><TextBlock Grid.Column="1" Text="' nodeType '" Foreground="#888" FontSize="9" VerticalAlignment="Center" Margin="0,0,8,0"/></Grid></Border><StackPanel Grid.Row="1" Margin="10,6,10,8"><TextBlock Text="' label '" Foreground="#999" FontSize="10"/></StackPanel></Grid></Border>'
        this.ui.Update(this.id, "AddXamlItem", xamlStr)
        if (inPortXAML != "")
            this.ui.Update(this.id, "AddXamlItem", '<Canvas xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">' inPortXAML '</Canvas>')
        if (outPortXAML != "")
            this.ui.Update(this.id, "AddXamlItem", '<Canvas xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">' outPortXAML '</Canvas>')
        
        nodeObj := { Id: newId, Title: nodeType " " idx, X: 200, Y: 200, W: 160, H: 60, Type: nodeType }
        this.nodes.Push(nodeObj)
        
        SetTimer(() => this.ui.Update("Node_" newId, "EnableDrag", "grid=20"), -200)
        this.ui.OnEvent("Node_" newId, "DragMove", ObjBindMethod(this, "OnNodeMoved", newId))
        this.ui.OnEvent("Node_" newId, "SelectNode", ObjBindMethod(this, "OnSelectNode", newId))
        this.ui.OnEvent("Node_" newId, "CtrlSelectNode", ObjBindMethod(this, "OnCtrlSelectNode", newId))
    }

    OnNodeMoved(nodeId, state, ctrl, event) {
        if !state.Has("DragCoords")
            return
        parts := StrSplit(state["DragCoords"], ",")
        if (parts.Length >= 2) {
            node := this.GetNode(nodeId)
            if (node) {
                dx := Number(parts[1]) - node.X
                dy := Number(parts[2]) - node.Y
                
                ; If this node is part of a selection, move all selected nodes together
                if (this.selectedNodes.Has(nodeId)) {
                    for sid in this.selectedNodes {
                        snode := this.GetNode(sid)
                        if (snode && sid != nodeId) {
                            snode.X += dx
                            snode.Y += dy
                            this.ui.Update("Node_" sid, "SetPosition", String(snode.X) "," String(snode.Y))
                            this.UpdateNodePorts(snode)
                        }
                    }
                }
                
                node.X := Number(parts[1])
                node.Y := Number(parts[2])
                this.UpdateNodePorts(node)
            }
        }
    }
    
    UpdateNodePorts(node) {
        nodeId := node.Id
        ; Move port indicators
        if (node.Type != "Input") {
            if (node.Type == "MultiProcess") {
                this.ui.Update("Port_In_" nodeId, "SetPosition", String(node.X - 5) "," String(node.Y + 20))
                this.ui.Update("Port_In2_" nodeId, "SetPosition", String(node.X - 5) "," String(node.Y + 40))
            } else {
                this.ui.Update("Port_In_" nodeId, "SetPosition", String(node.X - 5) "," String(node.Y + 30))
            }
        }
        if (node.Type != "Output") {
            if (node.Type == "MultiProcess") {
                this.ui.Update("Port_Out_" nodeId, "SetPosition", String(node.X + 155) "," String(node.Y + 20))
                this.ui.Update("Port_Out2_" nodeId, "SetPosition", String(node.X + 155) "," String(node.Y + 40))
            } else {
                this.ui.Update("Port_Out_" nodeId, "SetPosition", String(node.X + 155) "," String(node.Y + 30))
            }
        }
        ; Update connection paths
        for conn in this.connections {
            if (conn.From == nodeId || conn.To == nodeId)
                this.UpdatePath(conn.From, conn.To, conn.PathId)
        }
    }
    
    OnSelectNode(nodeId, state, ctrl, event) {
        this.selectedNodes.Clear()
        for node in this.nodes
            this.ui.Update("Node_" node.Id, "BorderBrush", "#3F3F46")
        this.selectedNodes[nodeId] := true
        this.ui.Update("Node_" nodeId, "BorderBrush", "#60A0FF")
    }
    
    OnCtrlSelectNode(nodeId, state, ctrl, event) {
        if (this.selectedNodes.Has(nodeId)) {
            this.selectedNodes.Delete(nodeId)
            this.ui.Update("Node_" nodeId, "BorderBrush", "#3F3F46")
        } else {
            this.selectedNodes[nodeId] := true
            this.ui.Update("Node_" nodeId, "BorderBrush", "#60A0FF")
        }
    }
    
    OnSelectionBox(state, ctrl, event) {
        if !state.Has("SelectionBox")
            return
        selectedStr := state["SelectionBox"]
        this.selectedNodes.Clear()
        
        ; Reset all borders
        for node in this.nodes
            this.ui.Update("Node_" node.Id, "BorderBrush", "#3F3F46")
            
        ; Set highlighted borders
        if (selectedStr != "") {
            for selId in StrSplit(selectedStr, ",") {
                this.selectedNodes[selId] := true
                this.ui.Update("Node_" selId, "BorderBrush", "#60A0FF")
            }
        }
    }
    
    OnCtrlSelectionBox(state, ctrl, event) {
        if !state.Has("CtrlSelectionBox")
            return
        selectedStr := state["CtrlSelectionBox"]
        if (selectedStr != "") {
            for selId in StrSplit(selectedStr, ",") {
                this.selectedNodes[selId] := true
                this.ui.Update("Node_" selId, "BorderBrush", "#60A0FF")
            }
        }
    }
    
    OnDeleteConnection(state, ctrl, event) {
        if !state.Has("DeleteConnection")
            return
        pathId := state["DeleteConnection"]
        ; Remove from tracking and UI
        for i, conn in this.connections {
            if (conn.PathId == pathId) {
                this.connections.RemoveAt(i)
                this.ui.Update(pathId, "Visibility", "Collapsed")
                break
            }
        }
    }
    
    OnClearSelection(state, ctrl, event) {
        this.selectedNodes.Clear()
        for node in this.nodes
            this.ui.Update("Node_" node.Id, "BorderBrush", "#3F3F46")
        
        ; Clear connection path selections
        for conn in this.connections {
            if (conn.Selected) {
                conn.Selected := false
                this.ui.Update(conn.PathId, "Stroke", "#60A0FF")
            }
        }
    }
    
    OnConnectPorts(state, ctrl, event) {
        if !state.Has("ConnectPorts")
            return
        parts := StrSplit(state["ConnectPorts"], ",")
        if (parts.Length == 2) {
            ; Parse port names like Port_Out_Node1, Port_In_Node2
            fromPort := parts[1]
            toPort := parts[2]
            
            ; Ensure we are connecting an Out to an In
            if (InStr(fromPort, "Port_In") && InStr(toPort, "Port_Out")) {
                temp := fromPort
                fromPort := toPort
                toPort := temp
            }
            
            if (InStr(fromPort, "Port_Out") && InStr(toPort, "Port_In")) {
                ; Extract node IDs (assuming ID follows the last underscore)
                fromArr := StrSplit(fromPort, "_")
                fromId := fromArr[fromArr.Length]
                
                toArr := StrSplit(toPort, "_")
                toId := toArr[toArr.Length]
                
                if (fromId != toId) {
                    this.AddConnection(fromId, toId)
                    if (this.ui) {
                        pathId := this.id "_Path_" fromId "_" toId
                        this.ui.OnEvent(pathId, "MouseLeftButtonDown", ObjBindMethod(this, "OnPathClicked", pathId))
                    }
                }
            }
        }
    }
    
    OnPathClicked(pathId, state, ctrl, event) {
        for conn in this.connections {
            if (conn.PathId == pathId) {
                conn.Selected := true
                this.ui.Update(pathId, "Stroke", "White")
            } else {
                conn.Selected := false
                this.ui.Update(conn.PathId, "Stroke", "#60A0FF")
            }
        }
    }
    
    DeleteSelectedConnections() {
        newConns := []
        for conn in this.connections {
            if (conn.Selected) {
                this.ui.Update(conn.PathId, "Visibility", "Collapsed")
            } else {
                newConns.Push(conn)
            }
        }
        this.connections := newConns
    }
    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("NodeGraph", { Call: _NodeGraph })
_NodeGraph(this, name := "") {
    return XNodeGraph(this, name)
}


; ==============================================================================
; MARKDOWN RENDERER
; ==============================================================================

XAMLElement.Prototype.DefineProp("MarkdownRenderer", { Call: _MarkdownRenderer })
_MarkdownRenderer(this, markdownText) {
    sp := this.Add("StackPanel")
    
    Loop Parse, markdownText, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line == "") {
            sp.Add("TextBlock").Height("10")
            continue
        }
            
        if (SubStr(line, 1, 3) == "###") {
            sp.Add("TextBlock").Text(Trim(SubStr(line, 4))).FontSize("16").FontWeight("Bold").Foreground("{DynamicResource TextMain}").Margin("0,15,0,5")
        } else if (SubStr(line, 1, 2) == "##") {
            sp.Add("TextBlock").Text(Trim(SubStr(line, 3))).FontSize("20").FontWeight("Bold").Foreground("{DynamicResource TextMain}").Margin("0,20,0,5")
        } else if (SubStr(line, 1, 1) == "#") {
            sp.Add("TextBlock").Text(Trim(SubStr(line, 2))).FontSize("26").FontWeight("Bold").Foreground("{DynamicResource TextMain}").Margin("0,25,0,10")
        } else if (SubStr(line, 1, 2) == "- ") {
            bull := sp.Add("StackPanel").Orientation("Horizontal").Margin("15,2,0,2")
            bull.Add("TextBlock").Text("•").Foreground("{DynamicResource Accent}").Margin("0,0,8,0")
            bull.Add("TextBlock").Text(Trim(SubStr(line, 3))).Foreground("{DynamicResource TextSub}").TextWrapping("Wrap")
        } else {
            if (InStr(line, "**")) {
                tb := sp.Add("TextBlock").TextWrapping("Wrap").Foreground("{DynamicResource TextSub}").Margin("0,0,0,10")
                parts := StrSplit(line, "**")
                for idx, part in parts {
                    if (Mod(idx, 2) == 0) {
                        tb.Add("Run").Text(part).FontWeight("Bold").Foreground("{DynamicResource TextMain}")
                    } else {
                        tb.Add("Run").Text(part)
                    }
                }
            } else {
                sp.Add("TextBlock").Text(line).TextWrapping("Wrap").Foreground("{DynamicResource TextSub}").Margin("0,0,0,10")
            }
        }
    }
    return sp
}


; ==============================================================================
; SPARKLINE
; ==============================================================================

XAMLElement.Prototype.DefineProp("Sparkline", { Call: _Sparkline })
_Sparkline(this, dataPoints, width := 100, height := 30, color := "#32D74B", type := "Line") {
    maxVal := -999999
    minVal := 999999
    for pt in dataPoints {
        if (pt > maxVal)
            maxVal := pt
        if (pt < minVal)
            minVal := pt
    }
    
    range := maxVal - minVal
    if (range == 0)
        range := 1
        
    count := dataPoints.Length
    
    if (type == "Bar") {
        cv := this.Add("Canvas").Width(String(width)).Height(String(height)).ClipToBounds("True")
        barW := (width / count) * 0.8
        for idx, pt in dataPoints {
            barH := ((pt - minVal) / range) * height
            if (barH < 1)
                barH := 1
            x := (idx - 1) * (width / count) + ((width / count) * 0.1)
            y := height - barH
            cv.Add("Border").Background(color).Width(String(barW)).Height(String(barH)).SetProp("Canvas.Left", String(x)).SetProp("Canvas.Top", String(y)).CornerRadius("2")
        }
        return cv
    }
    
    ptsStr := ""
    for idx, pt in dataPoints {
        x := (idx - 1) * (width / (count - 1))
        y := height - (((pt - minVal) / range) * height)
        ptsStr .= Round(x, 2) "," Round(y, 2) " "
    }
    
    if (type == "Area") {
        ptsStr := "0," height " " ptsStr " " width "," height
        return this.Add("Polygon").Points(Trim(ptsStr)).Fill(color).Opacity("0.5").Stroke(color).StrokeThickness("1").Width(String(width)).Height(String(height))
    }
    
    poly := this.Add("Polyline").Points(Trim(ptsStr)).Stroke(color).StrokeThickness("2").Width(String(width)).Height(String(height))
    return poly
}


; ==============================================================================
; MEDIA PLAYER WRAPPER
; ==============================================================================

class XMediaPlayerEx {
    __New(parentXAML, videoUri := "", name := "") {
        this.id := name != "" ? name : "Media_" XMediaPlayerEx.Count()
        
        this.grid := parentXAML.Add("Grid").Name(this.id "_MainGrid").Background("Black").ClipToBounds("True")
        
        this.media := this.grid.Add("MediaElement").Name(this.id).LoadedBehavior("Manual").UnloadedBehavior("Stop").Stretch("Uniform")
        if (videoUri != "")
            this.media.Source(videoUri)
            
        this.spinner := this.grid.Add("ProgressBar").Name(this.id "_Spinner").Style("{StaticResource ProgressRing}").Width("40").Height("40").IsIndeterminate("True").Visibility("Collapsed")
        
        ; No-media label
        this.grid.Add("TextBlock").Name(this.id "_NoMedia").Text("Drop or load media to play").Foreground("#666").FontSize("12").HorizontalAlignment("Center").VerticalAlignment("Center")
            
        this.controlsOverlay := this.grid.Add("Grid").VerticalAlignment("Bottom").Background("#CC000000").Height("60")
        this.controlsOverlay.Name(this.id "_Controls")
        
        this.controlsOverlay.Rows("*", "Auto")
        
        ; Timeline slider on top row
        this.timeline := this.controlsOverlay.Add("Slider").Name(this.id "_Timeline").Grid_Row(0).VerticalAlignment("Center").Margin("10,0").Maximum("100")
        
        ; Button row
        btnGrid := this.controlsOverlay.Add("Grid").Grid_Row(1).Margin("5,0,5,5")
        btnGrid.Cols("Auto", "Auto", "Auto", "Auto", "*", "Auto", "80")
        
        this.btnPlay := btnGrid.Add("Button").Name(this.id "_BtnPlay").Grid_Column(0).Background("Transparent").Foreground("White").BorderThickness("0").Cursor("Hand").Width("30").Height("30")
        this.btnPlay.Add("TextBlock").Text(Chr(0xE768)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("14").VerticalAlignment("Center").HorizontalAlignment("Center")
        
        btnStop := btnGrid.Add("Button").Name(this.id "_BtnStop").Grid_Column(1).Background("Transparent").Foreground("White").BorderThickness("0").Cursor("Hand").Width("30").Height("30")
        btnStop.Add("TextBlock").Text(Chr(0xE71A)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("12").VerticalAlignment("Center").HorizontalAlignment("Center")
        
        this.btnLoad := btnGrid.Add("Button").Name(this.id "_BtnLoad").Grid_Column(2).Background("Transparent").Foreground("White").BorderThickness("0").Cursor("Hand").Width("30").Height("30").ToolTip("Load File")
        this.btnLoad.Add("TextBlock").Text(Chr(0xE8E5)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("12").VerticalAlignment("Center").HorizontalAlignment("Center")
        
        btnUrl := btnGrid.Add("Button").Name(this.id "_BtnUrl").Grid_Column(3).Background("Transparent").Foreground("White").BorderThickness("0").Cursor("Hand").Width("30").Height("30").ToolTip("Open URL")
        btnUrl.Add("TextBlock").Text(Chr(0xE774)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("12").VerticalAlignment("Center").HorizontalAlignment("Center")
        
        ; Volume
        volSp := btnGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(5).VerticalAlignment("Center")
        volSp.Add("TextBlock").Text(Chr(0xE767)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("White").VerticalAlignment("Center").Margin("0,0,5,0").FontSize("12")
        this.volume := volSp.Add("Slider").Name(this.id "_Volume").Width("60").Value("50").Maximum("100")
    }
    
    Bind(ui) {
        this.ui := ui
        this.isPlaying := false
        ui.OnEvent(this.id "_BtnPlay", "Click", ObjBindMethod(this, "TogglePlay"))
        ui.OnEvent(this.id "_BtnStop", "Click", ObjBindMethod(this, "StopMedia"))
        ui.OnEvent(this.id "_BtnLoad", "Click", ObjBindMethod(this, "LoadMedia"))
        ui.OnEvent(this.id "_BtnUrl", "Click", ObjBindMethod(this, "LoadUrl"))
        ui.OnEvent(this.id "_Volume", "ValueChanged", ObjBindMethod(this, "ChangeVolume"))
        ; NOTE: Timeline seeking is handled entirely in C# via StartPositionTimer to avoid IPC loops
    }
    
    ChangeVolume(state, ctrl, event) {
        if state.Has(this.id "_Volume") {
            vol := Number(state[this.id "_Volume"]) / 100
            this.ui.Update(this.id, "Volume", String(vol))
        }
    }
    
    StartPlaying(source) {
        this.ui.Update(this.id "_Spinner", "Visibility", "Visible")
        this.ui.Update(this.id "_NoMedia", "Visibility", "Collapsed")
        this.ui.Update(this.id, "Source", source)
        this.ui.Update(this.id, "Play", "")
        ; Start position tracking timer on C# side
        this.ui.Update(this.id, "StartPositionTimer", this.id "_Timeline")
        this.isPlaying := true
        this.ui.Update(this.id "_BtnPlay", "Content", Chr(0xE769))
        SetTimer(() => this.ui.Update(this.id "_Spinner", "Visibility", "Collapsed"), -2000)
    }
    
    LoadMedia(state, ctrl, event) {
        file := FileSelect(3, "", "Select Media", "Media Files (*.mp4; *.avi; *.mkv; *.wmv; *.webm; *.mp3; *.wav; *.flac)")
        if (file)
            this.StartPlaying(file)
    }
    
    LoadUrl(state, ctrl, event) {
        ib := InputBox("Enter media URL (http/https/rtsp):", "Open URL Stream", "w400 h130")
        if (ib.Result == "OK" && ib.Value != "")
            this.StartPlaying(ib.Value)
    }
    
    TogglePlay(state, ctrl, event) {
        this.isPlaying := !this.isPlaying
        if (this.isPlaying) {
            this.ui.Update(this.id, "Play", "")
            this.ui.Update(this.id "_BtnPlay", "Content", Chr(0xE769))
        } else {
            this.ui.Update(this.id, "Pause", "")
            this.ui.Update(this.id "_BtnPlay", "Content", Chr(0xE768))
        }
    }
    
    StopMedia(state, ctrl, event) {
        this.ui.Update(this.id, "Stop", "")
        this.isPlaying := false
        this.ui.Update(this.id "_BtnPlay", "Content", Chr(0xE768))
    }
    
    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("MediaPlayerEx", { Call: _MediaPlayerEx })
_MediaPlayerEx(this, videoUri := "", name := "") {
    return XMediaPlayerEx(this, videoUri, name)
}


; ==============================================================================
; IMAGE CROPPER
; ==============================================================================

class XImageCropper {
    __New(parentXAML, imageUri := "", name := "") {
        this.id := name != "" ? name : "Cropper_" XImageCropper.Count()
        
        this.grid := parentXAML.Add("Grid").ClipToBounds("True")
        
        this.img := this.grid.Add("Image").Name(this.id "_Img").Stretch("Uniform")
        if (imageUri != "")
            this.img.Source(imageUri)
        
        ; Semi-transparent overlay
        this.grid.Add("Border").Name(this.id "_Overlay").Background("#80000000").IsHitTestVisible("False")
        
        ; Crop selection canvas
        this.canvas := this.grid.Add("Canvas").Name(this.id "_Canvas").Background("Transparent").ClipToBounds("True")
        
        ; Crop box (draggable via C# EnableDrag)
        this.cropBox := this.canvas.Add("Border").Name(this.id "_Box").BorderBrush("{DynamicResource Accent}").BorderThickness("2").Background("#01FFFFFF").Width("150").Height("150").SetProp("Canvas.Left", "30").SetProp("Canvas.Top", "20").Cursor("SizeAll")
        
        ; Corner handles
        cropGrid := this.cropBox.Add("Grid")
        this.hNW := cropGrid.Add("Border").Name(this.id "_HNW").Width("12").Height("12").Background("White").HorizontalAlignment("Left").VerticalAlignment("Top").Margin("-6,-6,0,0").Cursor("SizeNWSE").CornerRadius("6")
        this.hSE := cropGrid.Add("Border").Name(this.id "_HSE").Width("12").Height("12").Background("White").HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("0,0,-6,-6").Cursor("SizeNWSE").CornerRadius("6")
        
        ; Load button overlay
        loadBtn := this.canvas.Add("Button").Name(this.id "_BtnLoad").Content("Load Image").SetProp("Canvas.Left", "75").SetProp("Canvas.Top", "85").Background("{DynamicResource ControlBg}").Foreground("{DynamicResource TextMain}").Padding("10,5").Cursor("Hand").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}")
    }
    
    Bind(ui) {
        this.ui := ui
        ; Enable C#-side drag on the crop box
        ui.OnEvent(this.id "_Box", "DragMove", ObjBindMethod(this, "OnBoxMoved"))
        ui.OnEvent(this.id "_BtnLoad", "Click", ObjBindMethod(this, "OnLoadImage"))
    }
    
    ; Called after Window is Loaded to enable drag + resize
    EnableDrag(ui) {
        ui.Update(this.id "_Box", "EnableDrag", "crop")
    }
    
    OnBoxMoved(state, ctrl, event) {
        ; DragMove sends coordinates; we just let C# handle the visual
    }
    
    OnLoadImage(state, ctrl, event) {
        file := FileSelect(3, "", "Select Image", "Image Files (*.png; *.jpg; *.jpeg; *.bmp; *.gif)")
        if (file) {
            this.ui.Update(this.id "_Img", "Source", file)
        }
    }
    
    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("ImageCropper", { Call: _ImageCropper })
_ImageCropper(this, imageUri := "", name := "") {
    return XImageCropper(this, imageUri, name)
}
