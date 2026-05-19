#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; STEAM LAUNCHER CLONE PRO
; Demonstrates heavy media layouts, wrap panels, dark gaming UI, Kanban boards,
; media players, and profile metric cards using the XAML component library.
; ==============================================================================

globalAccentColor := "#1A9FFF"
app := XAML_GUI("Steam Clone Pro", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35, AppIcon: false })

app.tabs.Visibility("Collapsed")
app.main.Background("#1A1D24") ; Steam dark blue-gray

layout := app.main.Add("Grid").Grid_Row(1)
layout.Rows("Auto", "*")

; ==============================================================================
; TOP NAVIGATION
; ==============================================================================
navBar := layout.Add("Border").Grid_Row(0).Background("#171A21").Padding("30,15,30,15")
navGrid := navBar.Add("Grid")
navGrid.Cols("Auto", "*", "Auto")

; Logo (mocked with text)
navGrid.Add("TextBlock").Text(Chr(0xE7FC) " STEAM").FontFamily("Segoe Fluent Icons").FontSize(24).FontWeight("Bold").Foreground("#C6D4DF").VerticalAlignment("Center").Grid_Column(0).Margin("0,0,40,0")

; Menu Links (Now functional Tabs)
menuSp := navGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")
menuSp.Add("Button").Name("NavStore").Content("STORE").Style("{DynamicResource TabBtnActive}").Cursor("Hand").Margin("0,0,10,0")
menuSp.Add("Button").Name("NavLibrary").Content("LIBRARY").Style("{DynamicResource TabBtnInactive}").Cursor("Hand").Margin("0,0,10,0")
menuSp.Add("Button").Name("NavCommunity").Content("COMMUNITY").Style("{DynamicResource TabBtnInactive}").Cursor("Hand").Margin("0,0,10,0")
menuSp.Add("Button").Name("NavProfile").Content("PROFILE").Style("{DynamicResource TabBtnInactive}").Cursor("Hand").Margin("0,0,10,0")

; Search and Profile
rightSp := navGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(2).VerticalAlignment("Center")
searchBorder := rightSp.Add("Border").CornerRadius("2").Margin("0,0,20,0")
searchBorder.Add("TextBox").Text("Search...").Width("200").Background("#3D4450").Foreground("#C6D4DF").BorderThickness("0").Padding("10,6,10,6")
rightSp.Add("Ellipse").Name("SearchIcon").Width(35).Height(35).SetProp("Fill", "#1A9FFF").Cursor("Hand")

; Define button styles globally to inject
btnStyles := '<Style x:Key="TabBtnActive" TargetType="Button"><Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#1A9FFF"/><Setter Property="FontSize" Value="16"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Padding" Value="10,5"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter></Style>'
btnStyles .= '<Style x:Key="TabBtnInactive" TargetType="Button"><Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#C6D4DF"/><Setter Property="FontSize" Value="16"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Padding" Value="10,5"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Foreground" Value="White"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'

; ==============================================================================
; CONTENT PAGES CONTAINER
; ==============================================================================
pagesGrid := layout.Add("Grid").Grid_Row(1)

; ------------------------------------------------------------------------------
; PAGE: STORE
; ------------------------------------------------------------------------------
pageStore := pagesGrid.Add("Grid").Name("PageStore").Visibility("Visible")
storeScroller := pageStore.Add("ScrollViewer")
storeContentSp := storeScroller.Add("StackPanel")

; Command Bar
storeCmd := storeContentSp.CommandBar("StoreCmdBar")
storeCmd.AddButton(Chr(0xE7BF), "Your Store")
storeCmd.AddButton(Chr(0xE710), "New & Noteworthy")
storeCmd.AddButton(Chr(0xE8CB), "Categories")
storeCmd.AddSeparator()
storeCmd.AddButton(Chr(0xE728), "Points Shop")
storeCmd.AddButton(Chr(0xE77F), "News")
storeCmd.AddButton(Chr(0xE814), "Labs")
storeCmd.container.Margin("40,20,40,20").Background("#171A21").BorderThickness("0")

; HERO BANNER
heroBanner := storeContentSp.Add("Border").Height(400).Background("#2A3F54").Margin("0,0,0,30")
heroGrid := heroBanner.Add("Grid")

heroOverlay := heroGrid.Add("Border").Name("HeroOverlay")
gradient := '<Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,1">'
gradient .= '<GradientStop Color="#001A9FFF" Offset="0.0" />'
gradient .= '<GradientStop Color="#FF0B0E14" Offset="1.0" />'
gradient .= '</LinearGradientBrush></Border.Background>'

heroInfo := heroGrid.Add("StackPanel").VerticalAlignment("Bottom").HorizontalAlignment("Left").Margin("40")
heroInfo.Add("TextBlock").Text("FEATURED & RECOMMENDED").FontSize(14).Foreground("#C6D4DF").Margin("0,0,0,10")
heroInfo.Add("TextBlock").Text("Cyber-AHK 2077").FontSize(48).FontWeight("Bold").Foreground("White").Margin("0,0,0,10")
heroInfo.Add("TextBlock").Text("Now Available").FontSize(20).Foreground("#1A9FFF").Margin("0,0,0,20")
btnBorder := heroInfo.Add("Border").Name("BtnPlayNowBorder").CornerRadius("2").Background("#1A9FFF")
btnBorder.Add("Button").Content("PLAY NOW").Background("Transparent").Foreground("White").BorderThickness("0").Padding("30,10,30,10").FontSize(16).FontWeight("Bold").Cursor("Hand")

; GAMES GRID (WRAP PANEL)
storeContentSp.Add("TextBlock").Text("SPECIAL OFFERS").FontSize(18).Foreground("White").Margin("40,0,40,20").FontWeight("SemiBold")
gamesWrap := storeContentSp.Add("WrapPanel").Margin("40,0,40,40").SetProp("ItemWidth", "280").SetProp("ItemHeight", "180")

global gameCards := []

AddGameCard(parent, title, discount, price, color) {
    global gameCards
    cardName := "GameCard_" gameCards.Length
    card := parent.Add("Border").Name(cardName).Margin("0,0,20,20").Background(color).Cursor("Hand").CornerRadius("2")
    gameCards.Push({ Name: cardName, Title: title })

    grid := card.Add("Grid")
    grid.Add("TextBlock").Text(title).FontSize(24).FontWeight("Bold").Foreground("White").VerticalAlignment("Center").HorizontalAlignment("Center").Opacity("0.8")
    priceSp := grid.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Bottom").HorizontalAlignment("Right").Margin("10")
    if (discount != "") {
        priceSp.Add("Border").Background("#4C6B22").Padding("5").Add("TextBlock").Text(discount).Foreground("#A4D007").FontWeight("Bold")
    }
    priceSp.Add("Border").Background("#344654").Padding("8,5,8,5").Add("TextBlock").Text(price).Foreground("#67C1F5")
}

AddGameCard(gamesWrap, "AHK: Source", "-50%", "$9.99", "#5A3A31")
AddGameCard(gamesWrap, "WPF Simulator", "-75%", "$4.99", "#2D4259")
AddGameCard(gamesWrap, "CodeBox Pro", "", "$19.99", "#3A4D39")
AddGameCard(gamesWrap, "Script Valley", "-20%", "$11.99", "#594A2D")
AddGameCard(gamesWrap, "Grand Theft AutoHotkey", "-33%", "$19.99", "#2D2D59")

; ------------------------------------------------------------------------------
; PAGE: LIBRARY
; ------------------------------------------------------------------------------
pageLibrary := pagesGrid.Add("Grid").Name("PageLibrary").Visibility("Collapsed").Margin("20")
pageLibrary.Cols("250", "*")

; Library Sidebar (List)
libSidebar := pageLibrary.Add("Border").Grid_Column(0).Background("#1A1D24").Margin("0,0,20,0")
libScroller := libSidebar.Add("ScrollViewer")
libSp := libScroller.Add("StackPanel")
libSp.Add("TextBlock").Text("GAMES").FontSize(14).Foreground("#C6D4DF").Margin("10,10,10,20").FontWeight("Bold")

libList := ["AHK: Source", "WPF Simulator", "CodeBox Pro", "Script Valley", "Grand Theft AutoHotkey", "Half-Life 3 (Beta)"]
For game in libList {
    itemSp := libSp.Add("StackPanel").Orientation("Horizontal").Margin("10,5,10,5").Cursor("Hand")
    itemSp.Add("TextBlock").Text(Chr(0xE7FC)).FontFamily("Segoe Fluent Icons").FontSize(14).Foreground("#67C1F5").VerticalAlignment("Center").Margin("0,0,10,0")
    itemSp.Add("TextBlock").Text(game).FontSize(14).Foreground("#C6D4DF").VerticalAlignment("Center")
}

; Library Main Content (Kanban + Media)
libMain := pageLibrary.Add("Grid").Grid_Column(1)
libMain.Rows("Auto", "*")

libMain.Add("TextBlock").Text("LIBRARY MANAGER").Grid_Row(0).FontSize(24).Foreground("White").FontWeight("Bold").Margin("0,0,0,20")

libContent := libMain.Add("Grid").Grid_Row(1)
libContent.Cols("2*", "3*")

; Kanban on Left
kbBorder := libContent.Add("Border").Grid_Column(0).Margin("0,0,20,0")
kb := kbBorder.KanbanBoard("LibKanban")
kb.AddColumn("Backlog", "#5A3A31")
kb.AddColumn("Playing", "#2D4259")
kb.AddColumn("Completed", "#4C6B22")
kb.AddCard(1, "Half-Life 3 (Beta)")
kb.AddCard(1, "WPF Simulator")
kb.AddCard(2, "AHK: Source")
kb.AddCard(2, "Script Valley")
kb.AddCard(3, "CodeBox Pro")
kb.AddCard(3, "Grand Theft AutoHotkey")

; Trailer/Media on Right
mediaBorder := libContent.Add("Border").Grid_Column(1).Background("#171A21").CornerRadius("6").Padding("20")
mediaSp := mediaBorder.Add("StackPanel")
mediaSp.Add("TextBlock").Text("GAME TRAILER").FontSize(16).Foreground("#C6D4DF").FontWeight("Bold").Margin("0,0,0,15")

; Create XMediaPlayerEx
player := mediaSp.MediaPlayerEx("", "GameTrailer")
player.grid.Height(300)

; ------------------------------------------------------------------------------
; PAGE: COMMUNITY
; ------------------------------------------------------------------------------
pageCommunity := pagesGrid.Add("Grid").Name("PageCommunity").Visibility("Collapsed")
pageCommunity.Add("TextBlock").Text("Community Feed (Coming Soon)").FontSize(24).Foreground("#666").HorizontalAlignment("Center").VerticalAlignment("Center")

; ------------------------------------------------------------------------------
; PAGE: PROFILE
; ------------------------------------------------------------------------------
pageProfile := pagesGrid.Add("Grid").Name("PageProfile").Visibility("Collapsed").Margin("40")
pageProfile.Rows("Auto", "Auto", "*")

; Profile Header
profHeader := pageProfile.Add("Grid").Grid_Row(0).Margin("0,0,0,40")
profHeader.Cols("Auto", "*", "Auto")

profHeader.Add("Border").Name("ProfAvatar").Grid_Column(0).Width(120).Height(120).CornerRadius("8").Background("#1A9FFF").Margin("0,0,30,0")
profInfo := profHeader.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
profInfo.Add("TextBlock").Text("USER_1337").FontSize(36).FontWeight("Bold").Foreground("White")
profInfo.Add("TextBlock").Text("Level 42  |  United Kingdom").FontSize(16).Foreground("#C6D4DF").Margin("0,5,0,0")

; Theme Color Button
profThemeBtn := profHeader.Add("Button").Name("BtnEditTheme").Grid_Column(2).VerticalAlignment("Center").Content("Edit Profile Theme").Background("#171A21").Foreground("White").BorderThickness("1").BorderBrush("#3D4450").Padding("20,10").Cursor("Hand")

; Metrics Grid
metricsGrid := pageProfile.Add("Grid").Grid_Row(1).Margin("0,0,0,40")
metricsGrid.Cols("*", "*", "*")

m1 := metricsGrid.Add("Border").Grid_Column(0).Margin("0,0,20,0")
m1.MetricCard("TOTAL PLAYTIME", "1,337", "Hours on record", "#1A9FFF")

m2 := metricsGrid.Add("Border").Grid_Column(1).Margin("0,0,20,0")
m2.MetricCard("ACHIEVEMENTS", "420", "69% Completion Rate", "#4C6B22")

m3 := metricsGrid.Add("Border").Grid_Column(2).Margin("0,0,0,0")
m3.MetricCard("GAMES OWNED", "6", "In your library", "#67C1F5")

; Activity
pageProfile.Add("TextBlock").Text("RECENT ACTIVITY").Grid_Row(2).FontSize(18).Foreground("White").FontWeight("Bold").Margin("0,0,0,20")

; ==============================================================================
; COMPILE AND BIND
; ==============================================================================

app.main.InjectResources(btnStyles)
ui := app.Compile()
ui.Update("HeroOverlay", "AddXamlItem", gradient)

; Init Kanban and Player
kb.Bind(ui)
kb.EnableDrag(ui)
player.Bind(ui)

; Navigation Logic
NavTo(pageName, btnName) {
    global globalAccentColor
    ; Reset all buttons
    ui.Update("NavStore", "Foreground", "#C6D4DF")
    ui.Update("NavLibrary", "Foreground", "#C6D4DF")
    ui.Update("NavCommunity", "Foreground", "#C6D4DF")
    ui.Update("NavProfile", "Foreground", "#C6D4DF")

    ; Hide all pages
    ui.Update("PageStore", "Visibility", "Collapsed")
    ui.Update("PageLibrary", "Visibility", "Collapsed")
    ui.Update("PageCommunity", "Visibility", "Collapsed")
    ui.Update("PageProfile", "Visibility", "Collapsed")

    ; Activate target
    ui.Update(btnName, "Foreground", globalAccentColor)
    ui.Update(pageName, "Visibility", "Visible")
}

ui.OnEvent("NavStore", "Click", (state, ctrl, event) => NavTo("PageStore", "NavStore"))
ui.OnEvent("NavLibrary", "Click", (state, ctrl, event) => NavTo("PageLibrary", "NavLibrary"))
ui.OnEvent("NavCommunity", "Click", (state, ctrl, event) => NavTo("PageCommunity", "NavCommunity"))
ui.OnEvent("NavProfile", "Click", (state, ctrl, event) => NavTo("PageProfile", "NavProfile"))

; Profile Color Picker Logic
ui.OnEvent("BtnEditTheme", "Click", OpenColorPicker)
OpenColorPicker(state, ctrl, event) {
    global globalAccentColor
    opts := {
        Title: "Profile Accent Color",
        DefaultColor: globalAccentColor,
        Modal: true,
        Owner: ui.wpfHwnd
    }
    res := XColorPicker.Show(opts)
    if (res.Status == "OK" && res.Color != "") {
        globalAccentColor := res.Color
        ; Apply globally
        ui.Update("ProfAvatar", "Background", res.Color)
        ui.Update("SearchIcon", "Fill", res.Color)
        ui.Update("BtnPlayNowBorder", "Background", res.Color)
        ui.Update("NavProfile", "Foreground", res.Color) ; Because it's currently active
    }
}

; Bind Game Cards
for gc in gameCards {
    ui.OnEvent(gc.Name, "MouseLeftButtonUp", LaunchGame.Bind(gc.Title))
}

LaunchGame(title, state, ctrl, event) {
    XDialog.Show({
        Title: "Game Launch",
        Message: "Preparing to launch " title "...",
        Icon: Chr(0xE7FC),
        IconColor: globalAccentColor,
        Owner: ui.wpfHwnd,
        Modal: true
    })
}

app.Show()