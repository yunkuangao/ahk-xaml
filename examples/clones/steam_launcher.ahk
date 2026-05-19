#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"

; ==============================================================================
; STEAM LAUNCHER CLONE
; Demonstrates heavy media layouts, wrap panels, and dark gaming UI
; ==============================================================================

app := XAML_GUI("Steam Clone", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35, AppIcon: false })

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

; Menu Links
menuSp := navGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")
menuSp.Add("TextBlock").Text("STORE").FontSize(16).FontWeight("SemiBold").Foreground("#1A9FFF").Margin("0,0,30,0").Cursor("Hand") ; Active
menuSp.Add("TextBlock").Text("LIBRARY").FontSize(16).FontWeight("SemiBold").Foreground("#C6D4DF").Margin("0,0,30,0").Cursor("Hand")
menuSp.Add("TextBlock").Text("COMMUNITY").FontSize(16).FontWeight("SemiBold").Foreground("#C6D4DF").Margin("0,0,30,0").Cursor("Hand")
menuSp.Add("TextBlock").Text("PROFILE").FontSize(16).FontWeight("SemiBold").Foreground("#C6D4DF").Margin("0,0,30,0").Cursor("Hand")

; Search and Profile
rightSp := navGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(2).VerticalAlignment("Center")
searchBorder := rightSp.Add("Border").CornerRadius("2").Margin("0,0,20,0")
searchBorder.Add("TextBox").Text("Search...").Width("200").Background("#3D4450").Foreground("#C6D4DF").BorderThickness("0").Padding("10,6,10,6")
rightSp.Add("Ellipse").Width(35).Height(35).SetProp("Fill", "#1A9FFF").Cursor("Hand")

; ==============================================================================
; MAIN SCROLLABLE CONTENT
; ==============================================================================
scroller := layout.Add("ScrollViewer").Grid_Row(1)
contentSp := scroller.Add("StackPanel")

; HERO BANNER
heroBanner := contentSp.Add("Border").Height(400).Background("#2A3F54").Margin("0,0,0,30")
heroGrid := heroBanner.Add("Grid")

; Hero Overlay (Linear Gradient simulating an image fade)
heroOverlay := heroGrid.Add("Border").Name("HeroOverlay")
gradient := '<Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,1">'
gradient .= '<GradientStop Color="#001A9FFF" Offset="0.0" />'
gradient .= '<GradientStop Color="#FF0B0E14" Offset="1.0" />'
gradient .= '</LinearGradientBrush></Border.Background>'

heroInfo := heroGrid.Add("StackPanel").VerticalAlignment("Bottom").HorizontalAlignment("Left").Margin("40")
heroInfo.Add("TextBlock").Text("FEATURED & RECOMMENDED").FontSize(14).Foreground("#C6D4DF").Margin("0,0,0,10")
heroInfo.Add("TextBlock").Text("Cyber-AHK 2077").FontSize(48).FontWeight("Bold").Foreground("White").Margin("0,0,0,10")
heroInfo.Add("TextBlock").Text("Now Available").FontSize(20).Foreground("#1A9FFF").Margin("0,0,0,20")
btnBorder := heroInfo.Add("Border").CornerRadius("2").Background("#67C1F5")
btnBorder.Add("Button").Content("PLAY NOW").Background("Transparent").Foreground("White").BorderThickness("0").Padding("30,10,30,10").FontSize(16).FontWeight("Bold").Cursor("Hand")

; ==============================================================================
; GAMES GRID (WRAP PANEL)
; ==============================================================================
contentSp.Add("TextBlock").Text("SPECIAL OFFERS").FontSize(18).Foreground("White").Margin("40,0,40,20").FontWeight("SemiBold")

gamesWrap := contentSp.Add("WrapPanel").Margin("40,0,40,40").SetProp("ItemWidth", "280").SetProp("ItemHeight", "180")

AddGameCard(parent, title, discount, price, color) {
    card := parent.Add("Border").Margin("0,0,20,20").Background(color).Cursor("Hand").CornerRadius("2")
    grid := card.Add("Grid")
    
    ; Title
    grid.Add("TextBlock").Text(title).FontSize(24).FontWeight("Bold").Foreground("White").VerticalAlignment("Center").HorizontalAlignment("Center").Opacity("0.8")
    
    ; Price Tag
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

ui := app.Compile()
ui.Update("HeroOverlay", "AddXamlItem", gradient)
app.Show()
