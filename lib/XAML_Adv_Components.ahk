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

        bdr := this.boardSp.Add("Border").Background("{DynamicResource SidebarColor}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("12").Width("280").Margin("0,0,12,0")
        grid := bdr.Add("Grid").Margin("14")
        grid.Rows("Auto", "*", "Auto")

        headerGrid := grid.Add("Grid").Grid_Row(0).Margin("0,0,0,14")
        headerGrid.Cols("Auto", "*", "Auto")
        headerGrid.Add("Border").Width("8").Height("8").CornerRadius("4").Background(accentColor).Margin("0,0,10,0").VerticalAlignment("Center")
        headerGrid.Add("TextBlock").Text(title).Grid_Column(1).FontWeight("SemiBold").FontSize("13").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")
        countBdr := headerGrid.Add("Border").Grid_Column(2).Background("{DynamicResource DropdownBg}").CornerRadius("10").Padding("8,2")
        countBdr.Add("TextBlock").Name(countId).Text("0").Foreground("{DynamicResource TextSub}").FontSize("11")

        lb := grid.Add("ListBox").Name(colId).Grid_Row(1).Background("Transparent").BorderThickness("0").ScrollViewer_HorizontalScrollBarVisibility("Disabled").Padding("0").Foreground("{DynamicResource TextMain}")

        lb.InjectResources('<Style TargetType="ListBoxItem"><Setter Property="Margin" Value="0,0,0,6"/><Setter Property="Padding" Value="0"/><Setter Property="HorizontalContentAlignment" Value="Stretch"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ListBoxItem"><Border x:Name="bd" Background="{DynamicResource DropdownBg}" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" CornerRadius="6" Padding="12,10" Cursor="Hand"><Border.Effect><DropShadowEffect BlurRadius="4" ShadowDepth="1" Opacity="0.2" Direction="270" Color="Black"/></Border.Effect><ContentPresenter TextElement.Foreground="{DynamicResource TextMain}"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="{DynamicResource Accent}"/><Setter TargetName="bd" Property="Background" Value="{DynamicResource ControlBg}"/></Trigger><Trigger Property="IsSelected" Value="True"><Setter TargetName="bd" Property="BorderBrush" Value="' accentColor '"/><Setter TargetName="bd" Property="Background" Value="{DynamicResource ControlBg}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')

        ; Add Card button
        addBtn := grid.Add("Button").Name(addBtnId).Grid_Row(2).Margin("0,8,0,0").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness("0").Cursor("Hand").HorizontalAlignment("Stretch")
        addBtn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="Transparent" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" CornerRadius="6" Padding="8,7"><TextBlock Text="+ Add Card" HorizontalAlignment="Center" Foreground="{DynamicResource TextSub}" FontSize="12"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="{DynamicResource ControlBg}"/><Setter TargetName="bg" Property="BorderBrush" Value="' accentColor '"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')

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
        if !state.Has("ItemDropped")
            return
        parts := StrSplit(state["ItemDropped"], "|")
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

        this.bdr := parentXAML.Add("Border").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("8").ClipToBounds("True")

        this.bdr.InjectResources('<DrawingBrush x:Key="GridPattern" Viewport="0,0,100,100" ViewportUnits="Absolute" TileMode="Tile"><DrawingBrush.Drawing><DrawingGroup><GeometryDrawing Geometry="M0,20 L100,20 M0,40 L100,40 M0,60 L100,60 M0,80 L100,80 M20,0 L20,100 M40,0 L40,100 M60,0 L60,100 M80,0 L80,100"><GeometryDrawing.Pen><Pen Brush="{DynamicResource ControlBorder}" Thickness="0.3"/></GeometryDrawing.Pen></GeometryDrawing><GeometryDrawing Geometry="M0,100 L100,100 M100,0 L100,100"><GeometryDrawing.Pen><Pen Brush="{DynamicResource ControlBorder}" Thickness="1.5"/></GeometryDrawing.Pen></GeometryDrawing></DrawingGroup></DrawingBrush.Drawing></DrawingBrush>')

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
        headerGrid.Add("TextBlock").Text(title).Foreground("White").FontWeight("Bold").FontSize("11").VerticalAlignment("Center").Margin("10,0")
        headerGrid.Add("TextBlock").Text(nodeType).Grid_Column(1).Foreground("#DDDDDD").FontSize("9").VerticalAlignment("Center").Margin("0,0,8,0")

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
        
        ; Prevent duplicate links visually
        for conn in this.connections {
            if (conn.From == fromId && conn.To == toId) {
                if (this.ui) {
                    this.ui.Update(pathId, "Visibility", "Visible")
                    this.UpdatePath(fromId, toId, pathId)
                }
                return
            }
        }

        pathEl := this.canvas.Add("Path").Name(pathId).Stroke("#60A0FF").StrokeThickness("2.5").Opacity("0.8").SetProp("Panel.ZIndex", "-1")
        conn := { From: fromId, To: toId, PathId: pathId, PathEl: pathEl, Selected: false }
        this.connections.Push(conn)
        
        if (this.ui) {
            ; UI is already loaded, we must push this new element to WPF dynamically
            xamlStr := pathEl.ToString()
            xamlStr := StrReplace(xamlStr, "<Path ", "<Path xmlns=`"http://schemas.microsoft.com/winfx/2006/xaml/presentation`" ")
            this.ui.Update(this.id, "AddXamlItem", xamlStr)
            this.ui.Update(pathId, "Visibility", "Visible")
            this.UpdatePath(fromId, toId, pathId)
            this.ui.OnEvent(pathId, "MouseLeftButtonDown", ObjBindMethod(this, "OnPathClicked", pathId))
        } else {
            ; UI is building, just push the initial data directly
            this.UpdatePath(fromId, toId, pathId, true, pathEl)
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
            ui.OnEvent("Node_" node.Id, "SelectNode", ObjBindMethod(this, "OnSelectNode", node.Id))
            ui.OnEvent("Node_" node.Id, "CtrlSelectNode", ObjBindMethod(this, "OnCtrlSelectNode", node.Id))
        }

        ; Canvas events for Selection and Connection
        ui.OnEvent(this.id, "SelectionBox", ObjBindMethod(this, "OnSelectionBox"))
        ui.OnEvent(this.id, "CtrlSelectionBox", ObjBindMethod(this, "OnCtrlSelectionBox"))
        ui.OnEvent(this.id, "ClearSelection", ObjBindMethod(this, "OnClearSelection"))
        ui.OnEvent(this.id, "ConnectPorts", ObjBindMethod(this, "OnConnectPorts"))
        ui.OnEvent(this.id, "DeleteConnection", ObjBindMethod(this, "OnDeleteConnection"))
        ui.OnEvent(this.id, "ContextMenuOpened", ObjBindMethod(this, "OnContextMenuOpened"))

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

    OnContextMenuOpened(state, ctrl, event) {
        if !state.Has("ContextMenuOpened")
            return
        parts := StrSplit(state["ContextMenuOpened"], ",")
        if (parts.Length == 2) {
            this.lastRightClickX := Number(parts[1])
            this.lastRightClickY := Number(parts[2])
        }
    }

    OnNewNode(nodeType, state, ctrl, event) {
        idx := this.nodes.Length + 1
        newId := "Node" idx
        headerBg := nodeType == "Input" ? "#2E5A2E" : (nodeType == "Output" ? "#5A2E2E" : (nodeType == "MultiProcess" ? "#8A2BE2" : "#3E3E50"))
        label := nodeType == "Input" ? "Source" : (nodeType == "Output" ? "Sink" : "Transform")

        x := this.HasProp("lastRightClickX") ? this.lastRightClickX : this.offsetX + 200
        y := this.HasProp("lastRightClickY") ? this.lastRightClickY : this.offsetY + 200

        ; Port visual logic
        inPortXAML := ""
        outPortXAML := ""
        if (nodeType != "Input") {
            if (nodeType == "MultiProcess") {
                inPortXAML := '<Ellipse Name="Port_In_' newId '" Width="10" Height="10" Fill="#4CAF50" Stroke="#333" StrokeThickness="1" Canvas.Left="' (x - 5) '" Canvas.Top="' (y + 20) '" IsHitTestVisible="True" Cursor="Hand"/><Ellipse Name="Port_In2_' newId '" Width="10" Height="10" Fill="#4CAF50" Stroke="#333" StrokeThickness="1" Canvas.Left="' (x - 5) '" Canvas.Top="' (y + 40) '" IsHitTestVisible="True" Cursor="Hand"/>'
            } else {
                inPortXAML := '<Ellipse Name="Port_In_' newId '" Width="10" Height="10" Fill="#4CAF50" Stroke="#333" StrokeThickness="1" Canvas.Left="' (x - 5) '" Canvas.Top="' (y + 30) '" IsHitTestVisible="True" Cursor="Hand"/>'
            }
        }
        if (nodeType != "Output") {
            if (nodeType == "MultiProcess") {
                outPortXAML := '<Ellipse Name="Port_Out_' newId '" Width="10" Height="10" Fill="#FF5722" Stroke="#333" StrokeThickness="1" Canvas.Left="' (x + 155) '" Canvas.Top="' (y + 20) '" IsHitTestVisible="True" Cursor="Hand"/><Ellipse Name="Port_Out2_' newId '" Width="10" Height="10" Fill="#FF5722" Stroke="#333" StrokeThickness="1" Canvas.Left="' (x + 155) '" Canvas.Top="' (y + 40) '" IsHitTestVisible="True" Cursor="Hand"/>'
            } else {
                outPortXAML := '<Ellipse Name="Port_Out_' newId '" Width="10" Height="10" Fill="#FF5722" Stroke="#333" StrokeThickness="1" Canvas.Left="' (x + 155) '" Canvas.Top="' (y + 30) '" IsHitTestVisible="True" Cursor="Hand"/>'
            }
        }

        ; Build raw XAML string with proper namespace for injection
        xamlStr := '<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="Node_' newId '" Background="{DynamicResource DropdownBg}" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" CornerRadius="6" Width="160" Canvas.Left="' x '" Canvas.Top="' y '"><Border.Effect><DropShadowEffect BlurRadius="8" ShadowDepth="2" Opacity="0.4" Direction="270" Color="Black"/></Border.Effect><Grid><Grid.RowDefinitions><RowDefinition Height="30"/><RowDefinition Height="*"/></Grid.RowDefinitions><Border Grid.Row="0" Background="' headerBg '" CornerRadius="5,5,0,0" Cursor="SizeAll"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock Text="' nodeType ' ' idx '" Foreground="White" FontWeight="Bold" FontSize="11" VerticalAlignment="Center" Margin="10,0"/><TextBlock Grid.Column="1" Text="' nodeType '" Foreground="#DDDDDD" FontSize="9" VerticalAlignment="Center" Margin="0,0,8,0"/></Grid></Border><StackPanel Grid.Row="1" Margin="10,6,10,8"><TextBlock Text="' label '" Foreground="{DynamicResource TextSub}" FontSize="10"/></StackPanel></Grid></Border>'
        this.ui.Update(this.id, "AddXamlItem", xamlStr)
        if (inPortXAML != "")
            this.ui.Update(this.id, "AddXamlItem", '<Canvas xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">' inPortXAML '</Canvas>')
        if (outPortXAML != "")
            this.ui.Update(this.id, "AddXamlItem", '<Canvas xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">' outPortXAML '</Canvas>')

        nodeObj := { Id: newId, Title: nodeType " " idx, X: x, Y: y, W: 160, H: 60, Type: nodeType }
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
        if (this.selectedNodes.Has(nodeId) && this.selectedNodes.Count > 1) {
            ; keep selection for dragging
            return
        }
        this.selectedNodes.Clear()
        for node in this.nodes
            this.ui.Update("Node_" node.Id, "BorderBrush", "{DynamicResource ControlBorder}")
        this.selectedNodes[nodeId] := true
        this.ui.Update("Node_" nodeId, "BorderBrush", "#60A0FF")
    }

    OnCtrlSelectNode(nodeId, state, ctrl, event) {
        if (this.selectedNodes.Has(nodeId)) {
            this.selectedNodes.Delete(nodeId)
            this.ui.Update("Node_" nodeId, "BorderBrush", "{DynamicResource ControlBorder}")
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
            this.ui.Update("Node_" node.Id, "BorderBrush", "{DynamicResource ControlBorder}")

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
            this.ui.Update("Node_" node.Id, "BorderBrush", "{DynamicResource ControlBorder}")

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

    SaveState(filename) {
        if FileExist(filename)
            FileDelete(filename)
        FileAppend("[Nodes]`n", filename)
        for node in this.nodes {
            FileAppend(node.Id "=" node.X "," node.Y "`n", filename)
        }
        FileAppend("`n[Links]`n", filename)
        for conn in this.connections {
            FileAppend(conn.From "->" conn.To "`n", filename)
        }
        MsgBox("Node graph state saved!", "Saved", "Iconi T2")
    }

    LoadState(filename, ui) {
        if !FileExist(filename) {
            MsgBox("No saved state found.", "Load Error", "Iconx")
            return
        }
        
        ; Mark all current connections as inactive
        for conn in this.connections {
            conn.Active := false
        }

        stateText := FileRead(filename)
        mode := "Nodes"
        
        Loop Parse, stateText, "`n", "`r" {
            line := Trim(A_LoopField)
            if (line == "")
                continue
            if (SubStr(line, 1, 1) == "[" && SubStr(line, -1) == "]") {
                mode := SubStr(line, 2, StrLen(line) - 2)
                continue
            }
            
            if (mode == "Nodes" || mode == "") {
                parts := StrSplit(line, "=")
                if (parts.Length == 2) {
                    nodeId := Trim(parts[1])
                    coords := StrSplit(parts[2], ",")
                    if (coords.Length == 2) {
                        node := this.GetNode(nodeId)
                        if (node) {
                            node.X := Number(coords[1])
                            node.Y := Number(coords[2])
                            ui.Update("Node_" nodeId, "SetPosition", String(node.X) "," String(node.Y))
                            this.UpdateNodePorts(node)
                        }
                    }
                }
            } else if (mode == "Links") {
                parts := StrSplit(line, "->")
                if (parts.Length == 2) {
                    fromId := Trim(parts[1])
                    toId := Trim(parts[2])
                    this.AddConnection(fromId, toId)
                    
                    ; Ensure it's marked active
                    for conn in this.connections {
                        if (conn.From == fromId && conn.To == toId) {
                            conn.Active := true
                        }
                    }
                }
            }
        }

        ; Collapse inactive connections and clean up array
        newConns := []
        for conn in this.connections {
            if (conn.HasOwnProp("Active") && !conn.Active) {
                ui.Update(conn.PathId, "Visibility", "Collapsed")
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

; ==============================================================================
; SVG VIEWER
; ==============================================================================

class XSvgViewer {
    __New(parentXAML, name := "") {
        this.id := name != "" ? name : "SvgViewer_" XSvgViewer.Count()

        this.bgColor := "transparent"
        this.gridType := "None"
        this.currentFile := ""

        this.grid := parentXAML.Add("Grid").ClipToBounds("True")

        this.bdr := this.grid.Add("Border").Background("{DynamicResource DropdownBg}").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").CornerRadius("8").ClipToBounds("True")

        this.innerGrid := this.bdr.Add("Grid")

        this.browser := this.innerGrid.Add("WebBrowser").Name(this.id).Visibility("Collapsed")

        this.dropZone := this.innerGrid.Add("Border").Name(this.id "_Drop").Background("Transparent").AllowDrop("True").Cursor("Hand")

        this.sp := this.dropZone.Add("StackPanel").VerticalAlignment("Center").HorizontalAlignment("Center").IsHitTestVisible("False")
        this.sp.Add("TextBlock").Text(Chr(0xEB9F)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("48").Foreground("{DynamicResource Accent}").HorizontalAlignment("Center").Margin("0,0,0,10")
        this.sp.Add("TextBlock").Name(this.id "_DropText").Text("Drag & Drop or Click to Load SVG").Foreground("{DynamicResource TextSub}").FontSize("14").HorizontalAlignment("Center")

        this.fileCache := Map()
    }

    Bind(ui) {
        this.ui := ui
        ui.OnEvent(this.id "_Drop", "Drop", ObjBindMethod(this, "OnDrop"))
        ui.OnEvent(this.id "_Drop", "MouseLeftButtonDown", ObjBindMethod(this, "OnClick"))
    }

    OnClick(state, ctrl, event) {
        file := FileSelect(3, "", "Select SVG", "SVG Files (*.svg)")
        if (file) {
            this.LoadSvg(file)
        }
    }

    _B64Decode(str) {
        DllCall("crypt32\CryptStringToBinary", "str", str, "uint", 0, "uint", 1, "ptr", 0, "uint*", &size := 0, "ptr", 0, "ptr", 0)
        buf := Buffer(size)
        DllCall("crypt32\CryptStringToBinary", "str", str, "uint", 0, "uint", 1, "ptr", buf, "uint*", &size, "ptr", 0, "ptr", 0)
        return StrGet(buf, "UTF-8")
    }

    _B64Encode(str) {
        buf := Buffer(StrPut(str, "UTF-8"))
        StrPut(str, buf, "UTF-8")
        size := buf.Size - 1 ; exclude null terminator
        DllCall("crypt32\CryptBinaryToString", "ptr", buf, "uint", size, "uint", 0x40000001, "ptr", 0, "uint*", &req := 0) ; CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF
        strBuf := Buffer(req * 2)
        DllCall("crypt32\CryptBinaryToString", "ptr", buf, "uint", size, "uint", 0x40000001, "ptr", strBuf, "uint*", &req)
        return StrGet(strBuf, "UTF-16")
    }

    OnDrop(state, ctrl, event) {
        if !state.Has("Drop")
            return

        fileList := this._B64Decode(state["Drop"])
        files := StrSplit(fileList, "|")
        if (files.Length == 0)
            return

        file := files[1]
        SplitPath(file, , , &ext)
        if (StrLower(ext) != "svg") {
            MsgBox("Please drop a valid SVG file.", "Invalid File", "Iconx")
            return
        }

        this.LoadSvg(file)
    }

    LoadSvg(file) {
        this.currentFile := file
        if (!this.fileCache.Has(file)) {
            svgContent := FileRead(file, "UTF-8")
            this.fileCache[file] := svgContent
        }

        this.ui.Update(this.id "_Drop", "Visibility", "Collapsed")
        this.ui.Update(this.id, "Visibility", "Visible")
        this.ui.Update("BtnSvgReplace", "Visibility", "Visible")

        this.Render()
    }

    SetBackground(color, baseColor := "") {
        cssColor := color
        if (StrLen(color) == 9) {
            a := Format("{:i}", "0x" SubStr(color, 2, 2)) / 255
            r := Format("{:i}", "0x" SubStr(color, 4, 2))
            g := Format("{:i}", "0x" SubStr(color, 6, 2))
            b := Format("{:i}", "0x" SubStr(color, 8, 2))
            cssColor := "rgba(" r "," g "," b "," a ")"
        }
        this.bgColor := cssColor
        if (baseColor != "")
            this.baseColor := baseColor
        if (this.currentFile != "")
            this.Render()
    }

    SetGrid(type) {
        this.gridType := type
        if (this.currentFile != "")
            this.Render()
    }

    Render() {
        if (this.currentFile == "")
            return

        svgContent := this.fileCache[this.currentFile]

        bgBase := this.HasProp("baseColor") && this.baseColor != "" ? this.baseColor : "#1E1E1E"
        bgStyle := "background-color: " bgBase ";"

        bgImg := ""
        bgSize := ""

        if (this.gridType == "Light") {
            bgImg .= "linear-gradient(to right, rgba(0,0,0,0.1) 1px, transparent 1px), linear-gradient(to bottom, rgba(0,0,0,0.1) 1px, transparent 1px), "
            bgSize .= "20px 20px, 20px 20px, "
        } else if (this.gridType == "Dark") {
            bgImg .= "linear-gradient(to right, rgba(255,255,255,0.15) 1px, transparent 1px), linear-gradient(to bottom, rgba(255,255,255,0.15) 1px, transparent 1px), "
            bgSize .= "20px 20px, 20px 20px, "
        }

        bgImg .= "linear-gradient(" this.bgColor ", " this.bgColor ")"
        bgSize .= "auto"

        bgStyle .= " background-image: " bgImg "; background-size: " bgSize ";"

        html := "<!DOCTYPE html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'/><style>body { margin: 0; overflow: hidden; display: flex; align-items: center; justify-content: center; height: 100vh; " bgStyle " } svg { max-width: 100%; max-height: 100%; }</style></head><body>" svgContent "</body></html>"

        b64Html := this._B64Encode(html)
        this.ui.Update(this.id, "NavigateToString", b64Html)
    }

    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("SvgViewer", { Call: _SvgViewer })
_SvgViewer(this, name := "") {
    return XSvgViewer(this, name)
}

; ==============================================================================
; XClock Component
; ==============================================================================

class XClock {
    __New(parentXAML, id) {
        this.parent := parentXAML
        this.id := id

        this.isEditMode := false
        this.timerFn := ObjBindMethod(this, "Tick")

        ; Main glassmorphic container
        this.grid := parentXAML.Add("Grid").Name(this.id "_Grid").Margin("0")
        this.grid.ClipToBounds("True")

        ; Background glow effect
        glowCanvas := this.grid.Add("Canvas")
        glowCanvas.Add("Ellipse").Width("300").Height("300").Fill("{DynamicResource Accent}").Opacity("0.1").Margin("-50,-50,0,0").Add("Ellipse.Effect").Add("BlurEffect").Radius("80")

        ; Main Card
        card := this.grid.Add("Border").Use("CardPanel").Padding("30").Background("#10FFFFFF")

        this.contentGrid := card.Add("Grid")

        ; Live Mode UI
        this.liveUi := this.contentGrid.Add("StackPanel").Name(this.id "_LiveUI").Orientation("Horizontal").HorizontalAlignment("Center").VerticalAlignment("Center")

        this.hourTxt := this.liveUi.Add("TextBlock").Name(this.id "_Hour").Text("00").FontSize("72").FontWeight("Light").Foreground("{DynamicResource TextMain}")
        this.liveUi.Add("TextBlock").Text(":").FontSize("72").FontWeight("Light").Foreground("{DynamicResource Accent}").Margin("5,-5,5,0")
        this.minTxt := this.liveUi.Add("TextBlock").Name(this.id "_Min").Text("00").FontSize("72").FontWeight("Light").Foreground("{DynamicResource TextMain}")
        this.liveUi.Add("TextBlock").Text(":").FontSize("72").FontWeight("Light").Foreground("{DynamicResource Accent}").Margin("5,-5,5,0").Opacity("0.5")
        this.secTxt := this.liveUi.Add("TextBlock").Name(this.id "_Sec").Text("00").FontSize("72").FontWeight("Light").Foreground("{DynamicResource TextSub}")

        this.amPmTxt := this.liveUi.Add("TextBlock").Name(this.id "_AmPm").Text("AM").FontSize("24").FontWeight("Bold").Foreground("{DynamicResource TextSub}").VerticalAlignment("Bottom").Margin("15,0,0,15")

        ; Edit Mode UI
        this.editUi := this.contentGrid.Add("Grid").Name(this.id "_EditUI").Visibility("Collapsed").HorizontalAlignment("Center").VerticalAlignment("Center")
        this.editUi.Cols("Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto")

        this.hourCombo := this.editUi.Add("ComboBox").Name(this.id "_HourEdit").Width("80").Height("60").FontSize("32").Grid_Column(0).VerticalAlignment("Center")
        Loop 12
            this.hourCombo.Add("ComboBoxItem").Content(Format("{:02}", A_Index))

        this.editUi.Add("TextBlock").Text(":").FontSize("48").FontWeight("Light").Foreground("{DynamicResource TextSub}").Margin("10,0,10,0").Grid_Column(1).VerticalAlignment("Center")

        this.minCombo := this.editUi.Add("ComboBox").Name(this.id "_MinEdit").Width("80").Height("60").FontSize("32").Grid_Column(2).VerticalAlignment("Center")
        Loop 60
            this.minCombo.Add("ComboBoxItem").Content(Format("{:02}", A_Index - 1))

        this.editUi.Add("TextBlock").Text(":").FontSize("48").FontWeight("Light").Foreground("{DynamicResource TextSub}").Margin("10,0,10,0").Grid_Column(3).VerticalAlignment("Center")

        this.secCombo := this.editUi.Add("ComboBox").Name(this.id "_SecEdit").Width("80").Height("60").FontSize("32").Grid_Column(4).VerticalAlignment("Center")
        Loop 60
            this.secCombo.Add("ComboBoxItem").Content(Format("{:02}", A_Index - 1))

        this.amPmCombo := this.editUi.Add("ComboBox").Name(this.id "_AmPmEdit").Width("80").Height("60").FontSize("24").Margin("20,0,0,0").Grid_Column(5).VerticalAlignment("Center")
        this.amPmCombo.Add("ComboBoxItem").Content("AM")
        this.amPmCombo.Add("ComboBoxItem").Content("PM")
    }

    Bind(ui) {
        this.ui := ui
        ui.Track(this.id "_HourEdit")
        ui.Track(this.id "_MinEdit")
        ui.Track(this.id "_SecEdit")
        ui.Track(this.id "_AmPmEdit")
    }

    Start() {
        SetTimer(this.timerFn, 1000)
        this.Tick()
    }

    Stop() {
        SetTimer(this.timerFn, 0)
    }

    Tick() {
        if (this.isEditMode)
            return

        timeStr := ""
        if (this.HasProp("baseTime") && this.baseTime != "") {
            this.baseTime := DateAdd(this.baseTime, 1, "Seconds")
            timeStr := FormatTime(this.baseTime, "h:mm:ss:tt")
        } else {
            timeStr := FormatTime(, "h:mm:ss:tt")
        }
        
        parts := StrSplit(timeStr, ":")

        this.ui.Update(this.id "_Hour", "Text", Format("{:02}", parts[1]))
        this.ui.Update(this.id "_Min", "Text", parts[2])
        this.ui.Update(this.id "_Sec", "Text", parts[3])
        this.ui.Update(this.id "_AmPm", "Text", parts[4])
    }

    SetEditMode(enable, state := "") {
        this.isEditMode := enable
        if (enable) {
            this.Stop()
            this.ui.Update(this.id "_LiveUI", "Visibility", "Collapsed")
            this.ui.Update(this.id "_EditUI", "Visibility", "Visible")

            timeStr := ""
            if (this.HasProp("baseTime") && this.baseTime != "")
                timeStr := FormatTime(this.baseTime, "h:mm:ss:tt")
            else
                timeStr := FormatTime(, "h:mm:ss:tt")
                
            parts := StrSplit(timeStr, ":")
            this.ui.Update(this.id "_HourEdit", "SelectedIndex", String(parts[1] - 1))
            this.ui.Update(this.id "_MinEdit", "SelectedIndex", String(parts[2]))
            this.ui.Update(this.id "_SecEdit", "SelectedIndex", String(parts[3]))
            this.ui.Update(this.id "_AmPmEdit", "SelectedIndex", parts[4] == "AM" ? "0" : "1")
        } else {
            if (state != "" && state.Has(this.id "_HourEdit")) {
                hStr := state[this.id "_HourEdit"]
                mStr := state[this.id "_MinEdit"]
                sStr := state[this.id "_SecEdit"]
                ap := state[this.id "_AmPmEdit"]
                
                if (hStr != "" && mStr != "" && sStr != "" && ap != "") {
                    h := Integer(hStr)
                    m := Integer(mStr)
                    s := Integer(sStr)
                    
                    ; Convert to 24h format for AHK timestamp
                    h24 := h
                    if (ap == "PM" && h24 < 12)
                        h24 += 12
                    if (ap == "AM" && h24 == 12)
                        h24 := 0
                        
                    curDate := FormatTime(, "yyyyMMdd")
                    this.baseTime := curDate Format("{:02}{:02}{:02}", h24, m, s)
                }
            }
            
            this.ui.Update(this.id "_EditUI", "Visibility", "Collapsed")
            this.ui.Update(this.id "_LiveUI", "Visibility", "Visible")
            this.Start()
        }
    }
}

XAMLElement.Prototype.DefineProp("Clock", { Call: _Clock })
_Clock(this, name := "") {
    return XClock(this, name)
}

; ==============================================================================
; CODE EDITOR (Layered Syntax Highlighter)
; ==============================================================================

class XCodeEditor {
    static Count := 0

    __New(parentXAML, initialCode := "") {
        XCodeEditor.Count++
        this.id := "CodeEditor_" XCodeEditor.Count
        this.parent := parentXAML
        
        ; Main container
        this.bdr := parentXAML.Add("Border").Name(this.id "_Bdr").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).CornerRadius(6).Background("{DynamicResource ControlBg}")
        
        ; Layer grid
        this.grid := this.bdr.Add("Grid").Margin("0")
        
        ; Inner grid to handle universal padding, bypassing template discrepancies
        this.gridInner := this.grid.Add("Grid").Margin("15")
        
        ; Background layer: RichTextBox for syntax highlighting (Read-Only)
        this.rtb := this.gridInner.Add("RichTextBox").Name(this.id "_RTB").IsReadOnly("True").Focusable("False")
            .FontFamily("Consolas").FontSize("14").Background("Transparent").BorderThickness("0").Padding("0").Foreground("{DynamicResource TextMain}")
            
        ; Foreground layer: TextBox for typing (Transparent text/bg)
        this.tb := this.gridInner.Add("TextBox").Name(this.id).AcceptsReturn("True").AcceptsTab("True")
            .FontFamily("Consolas").FontSize("14").Background("Transparent").Foreground("Transparent").CaretBrush("{DynamicResource Accent}").BorderThickness("0").Padding("0").VerticalContentAlignment("Top")
            
        ; Suggestion popup (docked at bottom right)
        this.suggestBdr := this.grid.Add("Border").Name(this.id "_SuggestUI").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).CornerRadius(6).HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("20").Visibility("Collapsed").Padding("10,5")
        sSp := this.suggestBdr.Add("StackPanel").Orientation("Horizontal")
        sSp.Add("TextBlock").Text("💡").Margin("0,0,8,0").VerticalAlignment("Center")
        sSp.Add("TextBlock").Name(this.id "_SuggestTxt").Foreground("{DynamicResource TextMain}").FontFamily("Consolas").FontWeight("Bold").VerticalAlignment("Center")
        sSp.Add("TextBlock").Text("[Tab]").Foreground("{DynamicResource TextSub}").FontSize("11").Margin("15,0,0,0").VerticalAlignment("Center")
        
        if (initialCode != "")
            this.tb.Text(initialCode)
            
        this.suggestDict := ["MsgBox", "FormatTime", "StrSplit", "DllCall", "RegExMatch", "SetTimer", "FileSelect", "WinActivate"]
        this.currentSuggestion := ""
        this.currentWordLen := 0
        this.initialCode := initialCode
        this.isTyping := false
        
        this.ui := ""
        this.parseTimer := ObjBindMethod(this, "ExecuteParse")
    }
    
    Bind(ui) {
        this.ui := ui
        ui.Track(this.id)
        ui.Track(this.id "_CaretIndex") ; Uses the new bridge tracker
        
        ui.OnEvent(this.id, "TextChanged", ObjBindMethod(this, "OnTextChanged"))
        ui.OnEvent(this.id, "PreviewKeyDown", ObjBindMethod(this, "OnKeyDown"))
        
        ; Initial parse
        this.lastRaw := ""
        this.lastState := Map(this.id, this.initialCode, this.id "_CaretIndex", "0")
        
        ; Initial boot timer
        SetTimer(this.parseTimer, -50)
    }
    
    OnTextChanged(state, ctrl, event) {
        this.lastState := state
        
        if (!this.isTyping) {
            this.isTyping := true
            this.ui.Update(this.id, "Foreground", "{DynamicResource TextMain}")
        }
        
        ; Debounce rendering by 250ms to completely eliminate typing lag
        SetTimer(this.parseTimer, -250)
    }
    
    OnKeyDown(state, ctrl, event) {
        if (!IsObject(event) || !event.HasProp("Key"))
            return
            
        key := event.Key
        
        if (!this.isTyping) {
            this.isTyping := true
            this.ui.Update(this.id, "Foreground", "{DynamicResource TextMain}")
        }
        
        ; Delay parsing if they are actively typing keys
        SetTimer(this.parseTimer, -250)
    }
    
    ExecuteParse() {
        if (!this.ui || !this.lastState.Has(this.id) || !this.lastState.Has(this.id "_CaretIndex")) {
            return
        }
        
        ; Asynchronous boot check: WPF initializes asynchronously, so we must wait for the handle.
        if (!this.ui.HasProp("wpfHwnd") || !this.ui.wpfHwnd) {
            return
        }
            
        ; Request the latest tracked state synchronously
        text := this.lastState[this.id]
        
        ; Evaluate Auto-Suggest
        caret := Integer(this.lastState[this.id "_CaretIndex"])
        leftPart := SubStr(text, 1, caret)
        if (RegExMatch(leftPart, "([a-zA-Z_]\w*)$", &match)) {
            word := match[1]
            found := ""
            if (StrLen(word) >= 2) {
                for sugg in this.suggestDict {
                    if (SubStr(sugg, 1, StrLen(word)) == word && StrLen(sugg) > StrLen(word)) {
                        found := sugg
                        break
                    }
                }
            }
            
            if (found != "") {
                this.currentSuggestion := found
                this.currentWordLen := StrLen(word)
                this.ui.Update(this.id "_SuggestTxt", "Text", found)
                this.ui.Update(this.id "_SuggestUI", "Visibility", "Visible")
            } else {
                this.HideSuggestion()
            }
        } else {
            this.HideSuggestion()
        }
        
        if (text == this.lastRaw && this.lastRaw != "")
            return
            
        this.lastRaw := text
        
        ; Start building FlowDocument
        doc := "<FlowDocument Foreground=`"#E0E0E0`" xml:space=`"preserve`" xmlns=`"http://schemas.microsoft.com/winfx/2006/xaml/presentation`" PagePadding=`"0`" LineHeight=`"16.296875`">"
        doc .= "<Paragraph Margin=`"0`">"
        
        ; Define basic AHK/JS regex syntax rules
        pos := 1
        len := StrLen(text)
        
        while (pos <= len) {
            ; Find next token
            nextType := ""
            nextMatch := ""
            nextPos := len + 1
            
            ; Comment //
            if (RegExMatch(text, "(?m)//.*$", &m, pos) && m.Pos(0) < nextPos) {
                nextPos := m.Pos(0), nextMatch := m[0], nextType := "Comment"
            }
            ; Comment ;
            if (RegExMatch(text, "(?m);.*$", &m, pos) && m.Pos(0) < nextPos) {
                nextPos := m.Pos(0), nextMatch := m[0], nextType := "Comment"
            }
            ; String "..." or '...'
            quotePattern := "([" Chr(34) Chr(39) "]).*?\1"
            if (RegExMatch(text, quotePattern, &m, pos) && m.Pos(0) < nextPos) {
                nextPos := m.Pos(0), nextMatch := m[0], nextType := "String"
            }
            ; Number
            if (RegExMatch(text, "\b\d+(\.\d+)?\b", &m, pos) && m.Pos(0) < nextPos) {
                nextPos := m.Pos(0), nextMatch := m[0], nextType := "Number"
            }
            ; Keywords
            if (RegExMatch(text, "\b(if|else|return|function|class|while|for|loop|global|static|var|let|const|true|false)\b", &m, pos) && m.Pos(0) < nextPos) {
                nextPos := m.Pos(0), nextMatch := m[0], nextType := "Keyword"
            }
            ; Functions
            if (RegExMatch(text, "\b[a-zA-Z_]\w*(?=\()", &m, pos) && m.Pos(0) < nextPos) {
                nextPos := m.Pos(0), nextMatch := m[0], nextType := "Function"
            }
            
            if (nextPos > pos) {
                ; Add unformatted text before the match (or the entire remainder if no match)
                unformatted := SubStr(text, pos, nextPos - pos)
                doc .= this.EscapeRun(unformatted, "")
            }
            
            if (nextMatch != "") {
                color := ""
                fontWeight := "Normal"
                if (nextType == "Comment")
                    color := "#40A84F" ; Green
                else if (nextType == "String")
                    color := "#FF9F0A" ; Orange
                else if (nextType == "Number")
                    color := "#32D74B" ; Light Green
                else if (nextType == "Keyword") {
                    color := "#BF5AF2" ; Purple
                    fontWeight := "Bold"
                } else if (nextType == "Function") {
                    color := "#0A84FF" ; Blue
                }
                    
                doc .= this.EscapeRun(nextMatch, color, fontWeight)
                pos := nextPos + StrLen(nextMatch)
            } else {
                ; We already appended the remainder in the (nextPos > pos) block above
                break
            }
        }
        
        doc .= "</Paragraph></FlowDocument>"
        
        ; Inject the document
        this.ui.Update(this.id "_RTB", "Document", doc)
        
        ; Reveal the syntax highlighting
        if (this.isTyping) {
            this.isTyping := false
            this.ui.Update(this.id, "Foreground", "Transparent")
        }
    }
    
    HideSuggestion() {
        this.currentSuggestion := ""
        this.currentWordLen := 0
        this.ui.Update(this.id "_SuggestUI", "Visibility", "Collapsed")
    }
    
    EscapeRun(txt, colorBrush, weight := "Normal") {
        if (txt == "")
            return ""
            
        ; Replace literal newlines with <LineBreak/>
        txt := StrReplace(txt, "&", "&amp;")
        txt := StrReplace(txt, "<", "&lt;")
        txt := StrReplace(txt, ">", "&gt;")
        
        parts := StrSplit(txt, "`n", "`r")
        out := ""
        Loop parts.Length {
            if (parts[A_Index] != "") {
                run := "<Run FontWeight=`"" weight "`""
                if (colorBrush != "") {
                    if (SubStr(colorBrush, 1, 1) == "{")
                        run .= " Foreground=`"" colorBrush "`""
                    else
                        run .= " Foreground=`"" colorBrush "`""
                }
                run .= ">" parts[A_Index] "</Run>"
                out .= run
            }
            if (A_Index < parts.Length)
                out .= "<LineBreak/>"
        }
        return out
    }
}

XAMLElement.Prototype.DefineProp("CodeEditor", { Call: _CodeEditorAdvanced })
_CodeEditorAdvanced(this, initialCode := "") {
    return XCodeEditor(this, initialCode)
}

; ==============================================================================
; PROPERTY GRID / INSPECTOR
; ==============================================================================

class XPropertyGrid {
    __New(parentXAML, dataObj, name := "") {
        this.id := name != "" ? name : "PropGrid_" XPropertyGrid.Count()
        this.dataObj := dataObj
        this.bindings := Map()
        
        this.bdr := parentXAML.Add("Border").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("6")
        this.sv := this.bdr.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Padding("10")
        this.sp := this.sv.Add("StackPanel").Name(this.id)
        
        this.Render()
    }
    
    Render() {
        this.RenderItems(this.dataObj, this.sp, "")
    }
    
    RenderItems(obj, parentSp, prefix) {
        isMap := (Type(obj) == "Map")
        
        if (isMap) {
            for key, val in obj {
                this.RenderSingleItem(key, val, parentSp, prefix)
            }
        } else {
            for key, val in obj.OwnProps() {
                this.RenderSingleItem(key, val, parentSp, prefix)
            }
        }
    }
    
    RenderSingleItem(key, val, parentSp, prefix) {
        fullKey := prefix == "" ? String(key) : prefix "." String(key)
        valType := Type(val)
        
        if (valType == "Map" || valType == "Object") {
            catBorder := parentSp.Add("Border").Background("#10FFFFFF").CornerRadius("4").Padding("8,4").Margin("0,10,0,5")
            catBorder.Add("TextBlock").Text(String(key)).Foreground("{DynamicResource Accent}").FontWeight("Bold").FontSize("12")
            
            subSp := parentSp.Add("StackPanel").Margin("10,0,0,0")
            this.RenderItems(val, subSp, fullKey)
            return
        }
        
        itemGrid := parentSp.Add("Grid").Margin("0,4,0,4")
        itemGrid.Cols("2*", "3*")
        
        itemGrid.Add("TextBlock").Text(String(key)).Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").Grid_Column(0).Margin("0,0,10,0").TextWrapping("Wrap")
        
        ctrlId := this.id "_" StrReplace(fullKey, ".", "_")
        this.bindings[ctrlId] := { Key: fullKey, Type: valType, Original: val }
        
        if (valType == "Integer" && (val == 0 || val == 1) && (String(key) ~= "i)^(is|has|enable|show|use|allow)")) {
            valType := "Boolean"
            this.bindings[ctrlId].Type := "Boolean"
        }
        
        if (valType == "Boolean" || (valType == "Integer" && (val == 0 || val == 1) && (valType != "String"))) {
            chk := itemGrid.Add("CheckBox").Name(ctrlId).Style("{StaticResource ToggleSwitch}").Grid_Column(1).HorizontalAlignment("Right")
            if (val)
                chk.IsChecked("True")
            this.bindings[ctrlId].Type := "Boolean"
        } else if (valType == "Integer" || valType == "Float") {
            itemGrid.Add("TextBox").Name(ctrlId).Text(String(val)).Grid_Column(1).VerticalAlignment("Center").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").HorizontalContentAlignment("Right")
        } else {
            itemGrid.Add("TextBox").Name(ctrlId).Text(String(val)).Grid_Column(1).VerticalAlignment("Center").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}")
        }
    }
    
    Bind(ui) {
        this.ui := ui
        for ctrlId, info in this.bindings {
            ui.Track(ctrlId)
            
            if (info.Type == "Boolean") {
                ui.OnEvent(ctrlId, "Checked", ObjBindMethod(this, "OnValueChanged", ctrlId))
                ui.OnEvent(ctrlId, "Unchecked", ObjBindMethod(this, "OnValueChanged", ctrlId))
            } else {
                ui.OnEvent(ctrlId, "TextChanged", ObjBindMethod(this, "OnValueChanged", ctrlId))
            }
        }
    }
    
    OnValueChanged(ctrlId, state, ctrl, event) {
        if !state.Has(ctrlId)
            return
            
        info := this.bindings[ctrlId]
        newVal := state[ctrlId]
        
        if (info.Type == "Integer") {
            newVal := IsInteger(newVal) ? Integer(newVal) : (newVal == "True" ? 1 : (newVal == "False" ? 0 : 0))
        } else if (info.Type == "Float") {
            newVal := IsFloat(newVal) ? Float(newVal) : 0.0
        } else if (info.Type == "Boolean") {
            newVal := (newVal == "True" || newVal == "1")
        }
        
        this.UpdateObjectValue(this.dataObj, info.Key, newVal)
    }
    
    UpdateObjectValue(obj, fullKey, val) {
        parts := StrSplit(fullKey, ".")
        current := obj
        Loop parts.Length - 1 {
            k := parts[A_Index]
            isMap := (Type(current) == "Map")
            if (isMap)
                current := current[k]
            else
                current := current.%k%
        }
        
        lastK := parts[parts.Length]
        if (Type(current) == "Map")
            current[lastK] := val
        else
            current.%lastK% := val
    }
    
    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("PropertyGrid", { Call: _PropertyGrid })
_PropertyGrid(this, dataObj, name := "") {
    return XPropertyGrid(this, dataObj, name)
}

; ==============================================================================
; DIFF VIEWER
; ==============================================================================

class XDiffViewer {
    __New(parentXAML, name := "") {
        this.id := name != "" ? name : "DiffViewer_" XDiffViewer.Count()
        this.ui := ""
        
        this.bdr := parentXAML.Add("Border").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("6").ClipToBounds("True")
        this.grid := this.bdr.Add("Grid")
        this.grid.Rows("Auto", "*")
        
        ; Header / Toolbar
        header := this.grid.Add("Border").Grid_Row(0).Background("#10FFFFFF").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,0,1").Padding("8")
        hSp := header.Add("StackPanel").Orientation("Horizontal")
        
        this.btnInline := hSp.Add("RadioButton").Name(this.id "_BtnInline").Content("Inline").Style("{StaticResource SegmentedBtn}").IsChecked("True").GroupName(this.id "_ViewMode").BorderThickness("0,0,1,0")
        this.btnSide := hSp.Add("RadioButton").Name(this.id "_BtnSide").Content("Side-by-Side").Style("{StaticResource SegmentedBtn}").GroupName(this.id "_ViewMode").BorderThickness("0")
        
        ; Content Area
        this.sv := this.grid.Add("ScrollViewer").Grid_Row(1).HorizontalScrollBarVisibility("Auto").VerticalScrollBarVisibility("Auto").Padding("0,5,0,5")
        this.contentGrid := this.sv.Add("Grid").Name(this.id "_Content")
    }
    
    Bind(ui) {
        this.ui := ui
        ui.OnEvent(this.id "_BtnInline", "Checked", ObjBindMethod(this, "RenderInline"))
        ui.OnEvent(this.id "_BtnSide", "Checked", ObjBindMethod(this, "RenderSideBySide"))
        ui.OnEvent("Window", "LoadedHwnd", ObjBindMethod(this, "OnLoad"))
    }
    
    OnLoad(state := "", ctrl := "", event := "") {
        if (this.HasProp("diffData") && this.diffData) {
            ; Check which toggle is active to render correctly
            if (state.Has(this.id "_BtnSide") && state[this.id "_BtnSide"] == "True")
                this.RenderSideBySide()
            else
                this.RenderInline()
        }
    }
    
    SetDiff(text1, text2) {
        this.text1 := text1
        this.text2 := text2
        this.diffData := this.ComputeDiff(text1, text2)
        
        if (this.HasProp("ui") && this.ui) {
            this.RenderInline()
        }
    }
    
    ComputeDiff(text1, text2) {
        lines1 := StrSplit(StrReplace(text1, "`r"), "`n")
        lines2 := StrSplit(StrReplace(text2, "`r"), "`n")
        
        diff := []
        i := 1, j := 1
        
        while (i <= lines1.Length || j <= lines2.Length) {
            if (i > lines1.Length) {
                diff.Push({Type: "+", Text: lines2[j], L1: "", L2: j})
                j++
                continue
            }
            if (j > lines2.Length) {
                diff.Push({Type: "-", Text: lines1[i], L1: i, L2: ""})
                i++
                continue
            }
            if (lines1[i] == lines2[j]) {
                diff.Push({Type: "=", Text: lines1[i], L1: i, L2: j})
                i++
                j++
                continue
            }
            
            resynced := false
            Loop 10 {
                k := A_Index
                if (i + k <= lines1.Length && lines1[i+k] == lines2[j]) {
                    Loop k {
                        diff.Push({Type: "-", Text: lines1[i], L1: i, L2: ""})
                        i++
                    }
                    resynced := true
                    break
                }
                if (j + k <= lines2.Length && lines1[i] == lines2[j+k]) {
                    Loop k {
                        diff.Push({Type: "+", Text: lines2[j], L1: "", L2: j})
                        j++
                    }
                    resynced := true
                    break
                }
            }
            
            if (!resynced) {
                diff.Push({Type: "-", Text: lines1[i], L1: i, L2: ""})
                i++
                diff.Push({Type: "+", Text: lines2[j], L1: "", L2: j})
                j++
            }
        }
        return diff
    }
    
    EscapeXml(txt) {
        txt := StrReplace(txt, "&", "&amp;")
        txt := StrReplace(txt, "<", "&lt;")
        txt := StrReplace(txt, ">", "&gt;")
        return txt == "" ? " " : txt
    }
    
    RenderInline(state := "", ctrl := "", event := "") {
        if (!this.HasProp("diffData") || !this.diffData)
            return
            
        xaml := '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">'
        for d in this.diffData {
            bg := d.Type == "+" ? "#2032D74B" : (d.Type == "-" ? "#20FF3333" : "Transparent")
            fg := d.Type == "+" ? "#32D74B" : (d.Type == "-" ? "#FF3333" : "{DynamicResource TextMain}")
            sign := d.Type == "=" ? " " : d.Type
            
            lineXaml := '<Border Background="' bg '" BorderBrush="Transparent" BorderThickness="0"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="40"/><ColumnDefinition Width="20"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>'
            lineXaml .= '<TextBlock Grid.Column="0" Text="' d.L1 '" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/>'
            lineXaml .= '<TextBlock Grid.Column="1" Text="' d.L2 '" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/>'
            lineXaml .= '<TextBlock Grid.Column="2" Text="' sign '" Foreground="' fg '" FontSize="12" FontFamily="Consolas" FontWeight="Bold" TextAlignment="Center"/>'
            
            txt := this.EscapeXml(d.Text)
            lineXaml .= '<TextBlock Grid.Column="3" Text="' txt '" Foreground="' fg '" FontSize="12" FontFamily="Consolas" TextWrapping="NoWrap"/></Grid></Border>'
            xaml .= lineXaml
        }
        xaml .= '</StackPanel>'
        
        if (this.HasProp("ui") && this.ui) {
            this.ui.Update(this.id "_Content", "ClearItems", "")
            this.ui.Update(this.id "_Content", "AddXamlItem", xaml)
        }
    }
    
    RenderSideBySide(state := "", ctrl := "", event := "") {
        if (!this.HasProp("diffData") || !this.diffData)
            return
            
        xaml := '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="1"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><StackPanel Grid.Column="0">'
        
        leftSp := ""
        rightSp := ""
        
        i := 1
        while (i <= this.diffData.Length) {
            d := this.diffData[i]
            txt := this.EscapeXml(d.Text)
                
            if (d.Type == "=") {
                leftSp .= '<Border Background="Transparent"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="' d.L1 '" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/><TextBlock Grid.Column="1" Text="' txt '" Foreground="{DynamicResource TextMain}" FontSize="12" FontFamily="Consolas" TextWrapping="NoWrap"/></Grid></Border>'
                
                rightSp .= '<Border Background="Transparent"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="' d.L2 '" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/><TextBlock Grid.Column="1" Text="' txt '" Foreground="{DynamicResource TextMain}" FontSize="12" FontFamily="Consolas" TextWrapping="NoWrap"/></Grid></Border>'
                i++
            } else if (d.Type == "-") {
                if (i < this.diffData.Length && this.diffData[i+1].Type == "+") {
                    d2 := this.diffData[i+1]
                    txt2 := this.EscapeXml(d2.Text)
                    
                    leftSp .= '<Border Background="#20FF3333"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="' d.L1 '" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/><TextBlock Grid.Column="1" Text="' txt '" Foreground="#FF3333" FontSize="12" FontFamily="Consolas" TextWrapping="NoWrap"/></Grid></Border>'
                    
                    rightSp .= '<Border Background="#2032D74B"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="' d2.L2 '" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/><TextBlock Grid.Column="1" Text="' txt2 '" Foreground="#32D74B" FontSize="12" FontFamily="Consolas" TextWrapping="NoWrap"/></Grid></Border>'
                    i += 2
                } else {
                    leftSp .= '<Border Background="#20FF3333"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="' d.L1 '" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/><TextBlock Grid.Column="1" Text="' txt '" Foreground="#FF3333" FontSize="12" FontFamily="Consolas" TextWrapping="NoWrap"/></Grid></Border>'
                    
                    rightSp .= '<Border Background="#10FF3333"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/><TextBlock Grid.Column="1" Text=" " FontSize="12" FontFamily="Consolas"/></Grid></Border>'
                    i++
                }
            } else if (d.Type == "+") {
                leftSp .= '<Border Background="#1032D74B"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/><TextBlock Grid.Column="1" Text=" " FontSize="12" FontFamily="Consolas"/></Grid></Border>'
                
                rightSp .= '<Border Background="#2032D74B"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="40"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><TextBlock Text="' d.L2 '" Foreground="{DynamicResource TextSub}" FontSize="12" FontFamily="Consolas" TextAlignment="Right" Margin="0,0,10,0"/><TextBlock Grid.Column="1" Text="' txt '" Foreground="#32D74B" FontSize="12" FontFamily="Consolas" TextWrapping="NoWrap"/></Grid></Border>'
                i++
            }
        }
        
        xaml .= leftSp '</StackPanel><Rectangle Grid.Column="1" Fill="{DynamicResource ControlBorder}"/><StackPanel Grid.Column="2">' rightSp '</StackPanel></Grid>'
        
        if (this.HasProp("ui") && this.ui) {
            this.ui.Update(this.id "_Content", "ClearItems", "")
            this.ui.Update(this.id "_Content", "AddXamlItem", xaml)
        }
    }
    
    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("DiffViewer", { Call: _DiffViewer })
_DiffViewer(this, name := "") {
    return XDiffViewer(this, name)
}

class XWebView extends XAMLElement {
    __New(parent, id := "") {
        if (!XAML_ENABLE_WEBVIEW)
            throw Error("WebView is disabled. Set XAML_ENABLE_WEBVIEW := true in XAML_Config.ahk to use it.")
            
        if (id == "")
            id := "WebView_" XWebView.Count()
        super.__New("Grid")
        this.SetProp("xmlns:wv2", "clr-namespace:Microsoft.Web.WebView2.Wpf;assembly=Microsoft.Web.WebView2.Wpf")
        this.Name(id)
        this.id := id
        this._Parent := parent
        parent._Children.Push(this)
        
        this.Rows("Auto", "*")
        
        tb := this.Add("Border").Grid_Row(0).Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,0,1").Padding("10")
        sp := tb.Add("StackPanel").Orientation("Horizontal")
        
        this.btnBackId := this.id "_BtnBack"
        this.btnBack := sp.Add("Button").Name(this.btnBackId).Style("{StaticResource IconButton}").Width("32").Height("32").Margin("0,0,5,0").ToolTip("Back")
        this.btnBack.Add("TextBlock").Text(Chr(0xE72B)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")
        
        this.btnFwdId := this.id "_BtnFwd"
        this.btnFwd := sp.Add("Button").Name(this.btnFwdId).Style("{StaticResource IconButton}").Width("32").Height("32").Margin("0,0,10,0").ToolTip("Forward")
        this.btnFwd.Add("TextBlock").Text(Chr(0xE72A)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")
        
        this.btnRefreshId := this.id "_BtnRefresh"
        this.btnRefresh := sp.Add("Button").Name(this.btnRefreshId).Style("{StaticResource IconButton}").Width("32").Height("32").Margin("0,0,10,0").ToolTip("Refresh")
        this.btnRefresh.Add("TextBlock").Text(Chr(0xE72C)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")
        
        this.txtUrlId := this.id "_TxtUrl"
        this.txtUrl := sp.Add("TextBox").Name(this.txtUrlId).Width("400").Margin("0,0,10,0").VerticalAlignment("Center").Text("https://google.com/")
        
        this.btnGoId := this.id "_BtnGo"
        this.btnGo := sp.Add("Button").Name(this.btnGoId).Background("{DynamicResource Accent}").Foreground("White").BorderThickness("0").Padding("15,6").Content("Go").Margin("0,0,10,0")
        
        this.btnDevToolsId := this.id "_BtnDevTools"
        this.btnDevTools := sp.Add("Button").Name(this.btnDevToolsId).Background("#10FFFFFF").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,6").Content("DevTools").Margin("0,0,10,0")
        
        this.btnAddJsBtnId := this.id "_BtnAddJsBtn"
        this.btnAddJsBtn := sp.Add("Button").Name(this.btnAddJsBtnId).Background("#10FFFFFF").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,6").Content("Add JS Button").Margin("0,0,10,0")
        
        this.btnInjectId := this.id "_BtnInject"
        this.btnInject := sp.Add("Button").Name(this.btnInjectId).Background("#10FFFFFF").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,6").Content("Inject JS")
        
        this.wvName := this.id "_WV"
        wv := this.Add("wv2:WebView2").Name(this.wvName).Grid_Row(1).SetProp("Source", "https://google.com/")
        
        this.OnMessageCallback := ""
    }

    Bind(ui) {
        this.ui := ui
        ui.Track(this.txtUrlId)
        ui.OnEvent(this.btnGoId, "Click", ObjBindMethod(this, "OnGoClick"))
        ui.OnEvent(this.btnBackId, "Click", (*) => ui.Update(this.wvName, "GoBack", ""))
        ui.OnEvent(this.btnFwdId, "Click", (*) => ui.Update(this.wvName, "GoForward", ""))
        ui.OnEvent(this.btnRefreshId, "Click", (*) => ui.Update(this.wvName, "Refresh", ""))
        ui.OnEvent(this.btnDevToolsId, "Click", (*) => ui.Update(this.wvName, "OpenDevTools", ""))
        ui.OnEvent(this.btnAddJsBtnId, "Click", ObjBindMethod(this, "OnAddJsBtnClick"))
        ui.OnEvent(this.btnInjectId, "Click", ObjBindMethod(this, "OnInjectClick"))
        
        ui.OnEvent(this.wvName, "NavigationCompleted", ObjBindMethod(this, "OnNavCompleted"))
        ui.OnEvent(this.wvName, "WebMessageReceived", ObjBindMethod(this, "OnWebMessage"))
        
        ; Enable Return key to trigger Go
        ui.OnEvent(this.txtUrlId, "KeyDown:Return", ObjBindMethod(this, "OnGoClick"))
    }

    OnGoClick(state, ctrl, event) {
        url := state.Has(this.txtUrlId) ? state[this.txtUrlId] : ""
        if (url != "") {
            if (!InStr(url, "http://") && !InStr(url, "https://") && !InStr(url, "file://"))
                url := "https://" url
            this.Navigate(url)
        }
    }

    OnInjectClick(state, ctrl, event) {
        js := "console.log('Inject JS triggered!'); alert('hello world');"
        this.ExecuteJS(js)
    }
    
    OnAddJsBtnClick(state, ctrl, event) {
        js := "let btn = document.createElement('button'); btn.innerText = 'Send Message to AHK'; btn.style.position = 'fixed'; btn.style.top = '20px'; btn.style.right = '20px'; btn.style.zIndex = 999999; btn.style.padding = '15px'; btn.style.fontSize = '16px'; btn.style.background = '#0078D7'; btn.style.color = 'white'; btn.style.border = 'none'; btn.style.borderRadius = '5px'; btn.style.cursor = 'pointer'; btn.onclick = () => window.chrome.webview.postMessage('Button clicked from inside the webpage!'); document.body.appendChild(btn);"
        this.ExecuteJS(js)
    }

    OnNavCompleted(state, ctrl, event) {
        if (state.Has("NavigationCompleted")) {
            url := state["NavigationCompleted"]
            if (url != "")
                this.ui.Update(this.txtUrlId, "Text", url)
        }
    }

    OnWebMessage(state, ctrl, event) {
        if (state.Has("WebMessageReceived")) {
            msg := state["WebMessageReceived"]
            if (this.OnMessageCallback != "") {
                cb := this.OnMessageCallback
                cb(msg)
            }
        }
    }

    Navigate(url) {
        if (this.HasProp("ui") && this.ui)
            this.ui.Update(this.wvName, "Navigate", url)
    }

    ExecuteJS(js) {
        if (this.HasProp("ui") && this.ui)
            this.ui.Update(this.wvName, "ExecuteScript", XAMLHost.Base64Encode(js))
    }

    PostMessage(msg) {
        if (this.HasProp("ui") && this.ui)
            this.ui.Update(this.wvName, "PostWebMessage", msg)
    }
    
    OnMessage(callback) {
        this.OnMessageCallback := callback
        return this
    }
    
    static Count() {
        static counter := 0
        return ++counter
    }
}

XAMLElement.Prototype.DefineProp("WebView", { Call: _WebView })
_WebView(this, name := "") {
    return XWebView(this, name)
}