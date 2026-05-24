#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"

; ==============================================================================
; SPOTIFY CLONE - ADVANCED DEMO
; ==============================================================================

app := XAML_GUI("Spotify Clone", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35, AppIcon: false, Theme: "Dark Mica (Win 11)" })
app.tabs.Visibility("Collapsed")
app.main.Background("#000000") ; Dark base for Spotify vibe

; Custom Master Layout
masterGrid := app.main.Add("Grid").Grid_Row(1)
masterGrid.Rows("*", "90") ; Content, Player Bar

; Top Area
topArea := masterGrid.Add("Grid").Grid_Row(0)
topArea.Cols("250", "*", "Auto") ; Sidebar, Main, Right Sidebar (Friend Activity)

; ==============================================================================
; 1. LEFT SIDEBAR
; ==============================================================================
sidebarBg := topArea.Add("Border").Grid_Column(0).Background("#121212").CornerRadius("8").Margin("8,0,0,8")
sidebar := sidebarBg.Add("Grid")
sidebar.Rows("Auto", "*")

; Top Navigation
navSp := sidebar.Add("StackPanel").Grid_Row(0).Margin("12,20,12,10")

AddNavBtn(parent, iconHex, text, active := false) {
    btn := parent.Add("Button").Background("Transparent").BorderThickness("0").HorizontalContentAlignment("Left").Cursor("Hand").Margin("0,4")
    btn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="Transparent" CornerRadius="4" Padding="12,10"><ContentPresenter/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#1AFFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
    
    sp := btn.Add("StackPanel").Orientation("Horizontal")
    iconColor := active ? "White" : "{DynamicResource TextSub}"
    textColor := active ? "White" : "{DynamicResource TextSub}"
    fontWeight := active ? "SemiBold" : "Normal"

    sp.Add("TextBlock").Text(iconHex).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(20).Foreground(iconColor).VerticalAlignment("Center").Margin("0,0,15,0")
    sp.Add("TextBlock").Text(text).FontSize(14).FontWeight(fontWeight).Foreground(textColor).VerticalAlignment("Center")
    
    return btn
}

btnHome := AddNavBtn(navSp, Chr(0xE80F), "Home", true)
btnHome.Name("BtnHome")
btnSearch := AddNavBtn(navSp, Chr(0xE721), "Search")
btnSearch.Name("BtnSearch")
btnLibrary := AddNavBtn(navSp, Chr(0xE838), "Your Library")
btnLibrary.Name("BtnLibrary")

; Playlists
playlistSv := sidebar.Add("ScrollViewer").Grid_Row(1).Margin("12,10,12,10").VerticalScrollBarVisibility("Auto")
playlistSp := playlistSv.Add("StackPanel")

playlistSp.Add("TextBlock").Text("PLAYLISTS").FontSize(11).FontWeight("SemiBold").Foreground("{DynamicResource TextSub}").Margin("12,10,0,10")

playlists := ["Chill Vibes", "Coding Focus", "Top 50 - Global", "Discover Weekly", "Release Radar", "Synthwave Essentials", "Late Night Drives", "Focus Flow", "Deep Focus", "Lo-Fi Beats", "Workout Hype"]
for i, p in playlists {
    btn := playlistSp.Add("Button").Name("Sidebar_Playlist_" i).Content(p).Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextSub}").HorizontalContentAlignment("Left").Padding("12,8").Cursor("Hand")
    btn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="Transparent" CornerRadius="4"><ContentPresenter Margin="{TemplateBinding Padding}"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Foreground" Value="{DynamicResource TextMain}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
}


; ==============================================================================
; SEARCH COMMAND PALETTE
; ==============================================================================
searchPalette := app.overlay.CommandPalette("SpotifySearch")
searchPalette.AddCommand("song_1", "Starboy", {Icon: Chr(0xE8D6), Category: "Songs", Callback: (*) => PlaySong("Starboy", "The Weeknd")})
searchPalette.AddCommand("song_2", "Blinding Lights", {Icon: Chr(0xE8D6), Category: "Songs", Callback: (*) => PlaySong("Blinding Lights", "The Weeknd")})
searchPalette.AddCommand("song_3", "Midnight City", {Icon: Chr(0xE8D6), Category: "Songs", Callback: (*) => PlaySong("Midnight City", "M83")})
searchPalette.AddCommand("song_4", "Levitating", {Icon: Chr(0xE8D6), Category: "Songs", Callback: (*) => PlaySong("Levitating", "Dua Lipa")})
searchPalette.AddCommand("song_5", "Save Your Tears", {Icon: Chr(0xE8D6), Category: "Songs", Callback: (*) => PlaySong("Save Your Tears", "The Weeknd")})
searchPalette.AddCommand("song_6", "Cruel Summer", {Icon: Chr(0xE8D6), Category: "Songs", Callback: (*) => PlaySong("Cruel Summer", "Taylor Swift")})
searchPalette.AddCommand("song_7", "As It Was", {Icon: Chr(0xE8D6), Category: "Songs", Callback: (*) => PlaySong("As It Was", "Harry Styles")})
searchPalette.AddCommand("song_8", "Kill Bill", {Icon: Chr(0xE8D6), Category: "Songs", Callback: (*) => PlaySong("Kill Bill", "SZA")})


; ==============================================================================
; 2. MAIN CONTENT AREA
; ==============================================================================
mainBg := topArea.Add("Border").Grid_Column(1).Background("#121212").CornerRadius("8").Margin("8,0,8,8").ClipToBounds("True")

mainContainer := mainBg.Add("Grid")

; Dynamic Background Overlay
bgOverlay := mainContainer.Add("Border").Name("BgOverlay").Background("#422556").Opacity("0.6")
bgOverlay.Add("Border.Effect").Add("BlurEffect").Radius("150")

mainGrid := mainContainer.Add("Grid")
mainGrid.Rows("60", "*")

; Header
header := mainGrid.Add("Grid").Grid_Row(0).Margin("20,10,20,0")
header.Cols("Auto", "*", "Auto")

navBtns := header.Add("StackPanel").Grid_Column(0).Orientation("Horizontal").VerticalAlignment("Center")
btn1 := navBtns.Add("Button").Content(Chr(0xE72B)).FontFamily("Segoe Fluent Icons").Background("#20000000").Foreground("White").BorderThickness(0).Width("32").Height("32").Margin("0,0,8,0").FontSize(12).Cursor("Hand")
btn1.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="16"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#40FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')

btn2 := navBtns.Add("Button").Content(Chr(0xE72A)).FontFamily("Segoe Fluent Icons").Background("#20000000").Foreground("White").BorderThickness(0).Width("32").Height("32").FontSize(12).Cursor("Hand")
btn2.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="16"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#40FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')

profileSp := header.Add("StackPanel").Grid_Column(2).Orientation("Horizontal").VerticalAlignment("Center")
profileBtn := profileSp.Add("Button").Background("#20000000").Foreground("White").BorderThickness(0).Height("32").Padding("2,2,12,2").Cursor("Hand")
profileBtn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="16"><ContentPresenter Margin="{TemplateBinding Padding}" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#40FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
profileGrid := profileBtn.Add("Grid")
profileGrid.Cols("Auto", "Auto", "Auto")
imgBdrProfile := profileGrid.Add("Border").Grid_Column(0).Width("28").Height("28").CornerRadius("14").Background("#555").Margin("0,0,8,0").ClipToBounds("True")
imgBdrProfile.Add("Image").Source("https://picsum.photos/seed/user/100/100").Stretch("UniformToFill")
profileGrid.Add("TextBlock").Grid_Column(1).Text("User Name").FontWeight("SemiBold").FontSize(13).VerticalAlignment("Center").Margin("0,0,8,0")
profileGrid.Add("TextBlock").Grid_Column(2).Text(Chr(0xE70D)).FontFamily("Segoe Fluent Icons").FontSize(10).VerticalAlignment("Center")

; --- Views Container ---
viewsGrid := mainGrid.Add("Grid").Grid_Row(1)

; --- A. HOME VIEW ---
homeView := viewsGrid.Add("ScrollViewer").Name("HomeView").Padding("20,10,20,20").Visibility("Visible")
homeSp := homeView.Add("StackPanel")

homeSp.Add("TextBlock").Name("MainGreeting").Text("Good evening").FontSize(28).FontWeight("Bold").Foreground("White").Margin("0,10,0,20")

; Top Grid (6 items)
topCardsGrid := homeSp.Add("Grid").Margin("0,0,0,30")
topCardsGrid.Cols("*", "*", "*")
topCardsGrid.Rows("Auto", "Auto")

AddTopCard(grid, row, col, text, color, id) {
    bdr := grid.Add("Button").Name(id).Grid_Row(row).Grid_Column(col).Background("#2A2A2A").Margin("0,0,12,12").Cursor("Hand").Height("64").BorderThickness(0)
    bdr.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="#2A2A2A" CornerRadius="4"><ContentPresenter/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#3A3A3A"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
    
    g := bdr.Add("Grid")
    g.Cols("64", "*")
    imgBdr := g.Add("Border").Grid_Column(0).Background(color).CornerRadius("4,0,0,4").ClipToBounds("True")
    imgBdr.Add("Image").Source("https://picsum.photos/seed/" StrReplace(text, " ", "") "/128/128").Stretch("UniformToFill")
    
    g.Add("TextBlock").Grid_Column(1).Text(text).FontWeight("SemiBold").Foreground("White").VerticalAlignment("Center").Margin("12,0")
    return bdr
}

AddTopCard(topCardsGrid, 0, 0, "Liked Songs", "#4527A0", "Card_LikedSongs")
AddTopCard(topCardsGrid, 0, 1, "Discover Weekly", "#2E7D32", "Card_DiscoverWeekly")
AddTopCard(topCardsGrid, 0, 2, "Daily Mix 1", "#1565C0", "Card_DailyMix1")
AddTopCard(topCardsGrid, 1, 0, "Coding Focus", "#424242", "Card_CodingFocus")
AddTopCard(topCardsGrid, 1, 1, "Synthwave Essentials", "#C2185B", "Card_Synthwave")
AddTopCard(topCardsGrid, 1, 2, "Chill Vibes", "#00838F", "Card_ChillVibes")

; Jump Back In (Carousel)
homeSp.Add("TextBlock").Text("Jump back in").FontSize(22).FontWeight("Bold").Foreground("White").Margin("0,0,0,15")
jumpCarousel := homeSp.Carousel("JumpCarousel")
jumpCarousel.AddCard("Daily Mix 2", "Made for User", "https://picsum.photos/seed/daily2/200/200", 160, 220)
jumpCarousel.AddCard("Release Radar", "Catch up on the latest", "https://picsum.photos/seed/radar/200/200", 160, 220)
jumpCarousel.AddCard("Top Gaming Tracks", "Epic gaming music", "https://picsum.photos/seed/gaming/200/200", 160, 220)
jumpCarousel.AddCard("Lofi Beats", "Beats to relax/study to", "https://picsum.photos/seed/lofi/200/200", 160, 220)
jumpCarousel.AddCard("Mega Hit Mix", "A mega mix of 75 favorites", "https://picsum.photos/seed/mega/200/200", 160, 220)
jumpCarousel.AddCard("All Out 80s", "The biggest songs of the 1980s", "https://picsum.photos/seed/80s/200/200", 160, 220)

; Popular playlists
homeSp.Add("TextBlock").Text("Popular playlists").FontSize(22).FontWeight("Bold").Foreground("White").Margin("0,20,0,15")
popCarousel := homeSp.Carousel("PopCarousel")
popCarousel.AddCard("Today`'s Top Hits", "Jung Kook is on top of the...", "https://picsum.photos/seed/tth/200/200", 160, 220)
popCarousel.AddCard("RapCaviar", "New music from Drake", "https://picsum.photos/seed/rap/200/200", 160, 220)
popCarousel.AddCard("All Out 2010s", "The biggest songs of the 2010s", "https://picsum.photos/seed/2010s/200/200", 160, 220)
popCarousel.AddCard("Rock Classics", "Rock legends & epic songs", "https://picsum.photos/seed/rock/200/200", 160, 220)
popCarousel.AddCard("Chill Hits", "Kick back to the best new...", "https://picsum.photos/seed/chill/200/200", 160, 220)

; --- B. LIBRARY VIEW ---
libraryView := viewsGrid.Add("ScrollViewer").Name("LibraryView").Padding("20,10,20,20").Visibility("Collapsed")
libSp := libraryView.Add("StackPanel")
libSp.Add("TextBlock").Text("Your Library").FontSize(28).FontWeight("Bold").Foreground("White").Margin("0,10,0,20")

libWrap := libSp.Add("WrapPanel").Margin("0,10,0,0")

AddLibraryItem(wrapPanel, title, subtitle, seed, id) {
    bdr := wrapPanel.Add("Button").Name(id).Width("160").Height("220").Margin("0,0,20,20").Cursor("Hand").Background("#181818").BorderThickness("0").HorizontalContentAlignment("Stretch").VerticalContentAlignment("Stretch")
    bdr.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="#181818" CornerRadius="8"><ContentPresenter/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#282828"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
    
    grid := bdr.Add("Grid")
    grid.Rows("*", "Auto")
    imgBdr := grid.Add("Border").Grid_Row(0).CornerRadius("8").Margin("15,15,15,0").ClipToBounds("True")
    imgBdr.Add("Image").Source("https://picsum.photos/seed/" seed "/200/200").Stretch("UniformToFill")
    
    sp := grid.Add("StackPanel").Grid_Row(1).Margin("15,10,15,15")
    sp.Add("TextBlock").Text(title).Foreground("White").FontWeight("SemiBold").FontSize("14").TextTrimming("CharacterEllipsis").Margin("0,0,0,4")
    sp.Add("TextBlock").Text(subtitle).Foreground("{DynamicResource TextSub}").FontSize("12").TextTrimming("CharacterEllipsis")
}

AddLibraryItem(libWrap, "Liked Songs", "Playlist • 1,204 songs", "liked", "Lib_Liked")
AddLibraryItem(libWrap, "Albums", "Collection", "albums", "Lib_Albums")
AddLibraryItem(libWrap, "Podcasts", "Shows you follow", "pods", "Lib_Pods")
AddLibraryItem(libWrap, "Starboy", "The Weeknd", "Starboy", "Lib_Starboy")
AddLibraryItem(libWrap, "1989", "Taylor Swift", "1989", "Lib_1989")
AddLibraryItem(libWrap, "Currents", "Tame Impala", "currents", "Lib_Currents")


; ==============================================================================
; RIGHT SIDEBAR (FRIEND ACTIVITY)
; ==============================================================================
friendBg := topArea.Add("Border").Name("FriendSidebar").Grid_Column(2).Width("250").Background("#121212").CornerRadius("8").Margin("0,0,8,8").Visibility("Visible")
friendGrid := friendBg.Add("Grid").Rows("Auto", "*")

friendHeader := friendGrid.Add("Grid").Grid_Row(0).Margin("20,20,20,20")
friendHeader.Cols("*", "Auto")
friendHeader.Add("TextBlock").Grid_Column(0).Text("Friend Activity").Foreground("White").FontWeight("Bold").FontSize("14").VerticalAlignment("Center")
friendHeader.Add("Button").Grid_Column(1).Content(Chr(0xE814)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness("0").Cursor("Hand").Name("BtnCloseFriends")

friendSv := friendGrid.Add("ScrollViewer").Grid_Row(1).VerticalScrollBarVisibility("Auto").Margin("0,0,0,10")
friendSp := friendSv.Add("StackPanel")

AddFriend(sp, name, song, artist, albumSeed, timeAgo) {
    g := sp.Add("Grid").Margin("20,0,20,15").Cols("Auto", "*")
    img := g.Add("Border").Grid_Column(0).Width("40").Height("40").CornerRadius("20").ClipToBounds("True").Margin("0,0,12,0")
    img.Add("Image").Source("https://picsum.photos/seed/" name "/100/100").Stretch("UniformToFill")
    
    infoSp := g.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
    infoSp.Add("TextBlock").Text(name).Foreground("White").FontSize("13").FontWeight("SemiBold").Margin("0,0,0,2")
    infoSp.Add("TextBlock").Text(song " • " artist).Foreground("{DynamicResource TextSub}").FontSize("11").TextTrimming("CharacterEllipsis").Margin("0,0,0,2")
    infoSp.Add("TextBlock").Text(Chr(0xE8D6) " " timeAgo).FontFamily("Segoe Fluent Icons, Segoe UI").Foreground("{DynamicResource TextSub}").FontSize("10")
}

AddFriend(friendSp, "Alex Johnson", "Blinding Lights", "The Weeknd", "blinding", "2 hr")
AddFriend(friendSp, "Sam Smith", "As It Was", "Harry Styles", "asitwas", "4 hr")
AddFriend(friendSp, "Jessica Doe", "Cruel Summer", "Taylor Swift", "cruel", "1 day")
AddFriend(friendSp, "Michael T", "Midnight City", "M83", "midnight", "2 days")


; ==============================================================================
; 3. PLAYER BAR
; ==============================================================================
playerBg := masterGrid.Add("Border").Grid_Row(1).Background("#181818").BorderBrush("#282828").BorderThickness("0,1,0,0").Padding("15,0")
playerGrid := playerBg.Add("Grid")
playerGrid.Cols("300", "*", "300")

; Left: Now Playing
nowPlaying := playerGrid.Add("StackPanel").Grid_Column(0).Orientation("Horizontal").VerticalAlignment("Center")
imgBdr := nowPlaying.Add("Border").Width("56").Height("56").Background("#555").CornerRadius("4").Margin("0,0,15,0").ClipToBounds("True")
imgBdr.Add("Image").Name("NowPlayingImg").Source("https://picsum.photos/seed/Starboy/200/200").Stretch("UniformToFill")

titleSp := nowPlaying.Add("StackPanel").VerticalAlignment("Center").Margin("0,0,15,0")
titleSp.Add("TextBlock").Name("TrackTitle").Text("Starboy").Foreground("White").FontSize(14).FontWeight("SemiBold").Cursor("Hand")
titleSp.Add("TextBlock").Name("TrackArtist").Text("The Weeknd, Daft Punk").Foreground("{DynamicResource TextSub}").FontSize(12).Cursor("Hand")
nowPlaying.Add("Button").Name("LikeBtn").Content(Chr(0xEB51)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("White").BorderThickness(0).FontSize(16).VerticalAlignment("Center").Cursor("Hand")

; Center: Controls
controlsCenter := playerGrid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center").HorizontalAlignment("Center")

ctrlBtns := controlsCenter.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center").Margin("0,0,0,8")

ctrlBtns.Add("Button").Name("ShuffleBtn").Content(Chr(0xE8B1)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).FontSize(14).Margin("0,0,15,0").Cursor("Hand")
ctrlBtns.Add("Button").Content(Chr(0xE892)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).FontSize(16).Margin("0,0,15,0").Cursor("Hand")
playBtn := ctrlBtns.Add("Button").Name("PlayBtn").Content(Chr(0xE768)).FontFamily("Segoe Fluent Icons").Background("White").Foreground("Black").BorderThickness(0).Width("32").Height("32").FontSize(16).Margin("0,0,15,0").Cursor("Hand")
playBtn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="16"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#E0E0E0"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')
ctrlBtns.Add("Button").Content(Chr(0xE893)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).FontSize(16).Margin("0,0,15,0").Cursor("Hand")
ctrlBtns.Add("Button").Name("RepeatBtn").Content(Chr(0xE8EE)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).FontSize(14).Cursor("Hand")

progressGrid := controlsCenter.Add("Grid").Width("400")
progressGrid.Cols("Auto", "*", "Auto")
progressGrid.Add("TextBlock").Name("CurrentTime").Grid_Column(0).Text("1:24").Foreground("{DynamicResource TextSub}").FontSize(11).VerticalAlignment("Center").Margin("0,0,10,0")

; Custom Slider Style
progressSlider := progressGrid.Add("Slider").Name("ProgressSlider").Grid_Column(1).Value("30").Maximum("100").VerticalAlignment("Center")
progressGrid.Add("TextBlock").Name("TotalTime").Grid_Column(2).Text("3:50").Foreground("{DynamicResource TextSub}").FontSize(11).VerticalAlignment("Center").Margin("10,0,0,0")

; Right: Extra Controls
extraSp := playerGrid.Add("StackPanel").Grid_Column(2).Orientation("Horizontal").HorizontalAlignment("Right").VerticalAlignment("Center")
extraSp.Add("Button").Name("LyricsBtn").Content(Chr(0xE836)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).FontSize(14).Margin("0,0,10,0").Cursor("Hand")
extraSp.Add("Button").Name("QueueBtn").Content(Chr(0xE9E9)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).FontSize(14).Margin("0,0,10,0").Cursor("Hand")
extraSp.Add("Button").Name("MuteBtn").Content(Chr(0xE995)).FontFamily("Segoe Fluent Icons").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).FontSize(14).Margin("0,0,10,0").Cursor("Hand")

volSlider := extraSp.Add("Slider").Name("VolumeSlider").Width("80").Value("70").Maximum("100").VerticalAlignment("Center").Margin("0,0,10,0")

; ==============================================================================
; FLYOUTS (LYRICS & QUEUE)
; ==============================================================================
queueFlyout := XFlyout("Queue", "Right", "Overlay", 350, true)
queueFlyout.Build(app.main)
queueBdr := queueFlyout.container.Background("#202020").BorderThickness("1,0,0,0").BorderBrush("#333")
queueSp := queueBdr.Add("StackPanel").Margin("20")
queueSp.Add("TextBlock").Text("Queue").FontSize(24).FontWeight("Bold").Foreground("White").Margin("0,0,0,20")
queueSp.Add("TextBlock").Text("Now Playing").FontSize(14).FontWeight("SemiBold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,10")
queueNp := queueSp.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,20")
queueNp.Add("Border").Width("40").Height("40").CornerRadius("4").ClipToBounds("True").Margin("0,0,10,0").Add("Image").Source("https://picsum.photos/seed/Starboy/100/100").Stretch("UniformToFill")
queueNp.Add("StackPanel").VerticalAlignment("Center").Add("TextBlock").Text("Starboy").Foreground("#1DB954").FontWeight("SemiBold").Add("TextBlock").Text("The Weeknd").Foreground("{DynamicResource TextSub}")
queueSp.Add("TextBlock").Text("Next Up").FontSize(14).FontWeight("SemiBold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,10")
queueNext := queueSp.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,10")
queueNext.Add("Border").Width("40").Height("40").CornerRadius("4").ClipToBounds("True").Margin("0,0,10,0").Add("Image").Source("https://picsum.photos/seed/blinding/100/100").Stretch("UniformToFill")
queueNext.Add("StackPanel").VerticalAlignment("Center").Add("TextBlock").Text("Blinding Lights").Foreground("White").FontWeight("SemiBold").Add("TextBlock").Text("The Weeknd").Foreground("{DynamicResource TextSub}")


; ==============================================================================
; STATE & LOGIC
; ==============================================================================
global isPlaying := false
global isLiked := false
global isShuffle := false
global isRepeat := false
global isMuted := false
global currentProgress := 84 ; 1:24 in seconds
global friendsVisible := true

TogglePlay(*) {
    global ui, isPlaying
    isPlaying := !isPlaying
    icon := isPlaying ? Chr(0xE769) : Chr(0xE768) ; Pause : Play
    ui.Update("PlayBtn", "Content", icon)
}

ToggleLike(*) {
    global ui, isLiked
    isLiked := !isLiked
    icon := isLiked ? Chr(0xEB52) : Chr(0xEB51) ; Filled Heart : Empty Heart
    color := isLiked ? "#1DB954" : "White"
    ui.Update("LikeBtn", "Content", icon)
    ui.Update("LikeBtn", "Foreground", color)
}

ToggleShuffle(*) {
    global ui, isShuffle
    isShuffle := !isShuffle
    color := isShuffle ? "#1DB954" : "{DynamicResource TextSub}"
    ui.Update("ShuffleBtn", "Foreground", color)
}

ToggleRepeat(*) {
    global ui, isRepeat
    isRepeat := !isRepeat
    color := isRepeat ? "#1DB954" : "{DynamicResource TextSub}"
    ui.Update("RepeatBtn", "Foreground", color)
}

ToggleMute(*) {
    global ui, isMuted
    isMuted := !isMuted
    icon := isMuted ? Chr(0xE992) : Chr(0xE995) ; Muted : Volume
    color := isMuted ? "White" : "{DynamicResource TextSub}"
    ui.Update("MuteBtn", "Content", icon)
    ui.Update("MuteBtn", "Foreground", color)
    if (isMuted)
        ui.Update("VolumeSlider", "Value", "0")
    else
        ui.Update("VolumeSlider", "Value", "70")
}

ToggleFriends(*) {
    global ui, friendsVisible
    friendsVisible := !friendsVisible
    vis := friendsVisible ? "Visible" : "Collapsed"
    ui.Update("FriendSidebar", "Visibility", vis)
}

ShowHomeView(*) {
    global ui
    ui.Update("HomeView", "Visibility", "Visible")
    ui.Update("LibraryView", "Visibility", "Collapsed")
}

ShowLibraryView(*) {
    global ui
    ui.Update("HomeView", "Visibility", "Collapsed")
    ui.Update("LibraryView", "Visibility", "Visible")
}

PlaySong(title, artist, imgUrl := "", colorHex := "") {
    global ui, isPlaying, currentProgress
    ui.Update("TrackTitle", "Text", title)
    ui.Update("TrackArtist", "Text", artist)
    
    if (imgUrl == "")
        imgUrl := "https://picsum.photos/seed/" StrReplace(title, " ", "") "/200/200"
        
    ui.Update("NowPlayingImg", "Source", imgUrl)
    
    ; Simulate dynamic accent color
    if (colorHex == "") {
        ; Generate pseudo-random color based on title length
        colors := ["#4527A0", "#2E7D32", "#1565C0", "#C2185B", "#00838F", "#D84315"]
        idx := Mod(StrLen(title), colors.Length) + 1
        colorHex := colors[idx]
    }
    ui.Update("BgOverlay", "Background", colorHex)
    
    isPlaying := true
    ui.Update("PlayBtn", "Content", Chr(0xE769))
    currentProgress := 0
    ui.Update("ProgressSlider", "Value", "0")
    ui.Update("CurrentTime", "Text", "0:00")
}

UpdateProgress() {
    global ui, isPlaying, currentProgress
    if (!isPlaying)
        return
        
    currentProgress += 1
    if (currentProgress > 230) { ; mock 3:50 total time
        currentProgress := 0
    }
    
    progressPercent := (currentProgress / 230) * 100
    ui.Update("ProgressSlider", "Value", String(progressPercent))
    
    mins := Floor(currentProgress / 60)
    secs := Mod(currentProgress, 60)
    timeStr := mins ":" Format("{:02}", secs)
    ui.Update("CurrentTime", "Text", timeStr)
}

SetTimer(UpdateProgress, 1000)

; ==============================================================================
; COMPILE & BIND
; ==============================================================================
ui := app.Compile()
jumpCarousel.Bind(ui)
popCarousel.Bind(ui)
searchPalette.Bind(ui, "^f")
queueFlyout.Bind(ui)

; Player Controls
ui.OnEvent("PlayBtn", "Click", TogglePlay)
ui.OnEvent("LikeBtn", "Click", ToggleLike)
ui.OnEvent("ShuffleBtn", "Click", ToggleShuffle)
ui.OnEvent("RepeatBtn", "Click", ToggleRepeat)
ui.OnEvent("MuteBtn", "Click", ToggleMute)
ui.OnEvent("QueueBtn", "Click", (*) => queueFlyout.Toggle())
ui.OnEvent("LyricsBtn", "Click", (*) => app.dialogs.Show("Feature Not Available", "Lyrics are not available for this track yet.", "OK", "Info"))

; Sidebar Nav
ui.OnEvent("BtnSearch", "Click", (*) => searchPalette.Open())
ui.OnEvent("BtnHome", "Click", ShowHomeView)
ui.OnEvent("BtnLibrary", "Click", ShowLibraryView)

; Friend Activity
ui.OnEvent("BtnCloseFriends", "Click", ToggleFriends)

; Carousel & Card Clicks
jumpCarousel.OnCardSelected := (this, id, title) => PlaySong(title, "Jump Back In")
popCarousel.OnCardSelected := (this, id, title) => PlaySong(title, "Popular Playlists")

ui.OnEvent("Card_LikedSongs", "Click", (*) => PlaySong("Liked Songs", "Playlist", "", "#4527A0"))
ui.OnEvent("Card_DiscoverWeekly", "Click", (*) => PlaySong("Discover Weekly", "Playlist", "", "#2E7D32"))
ui.OnEvent("Card_DailyMix1", "Click", (*) => PlaySong("Daily Mix 1", "Playlist", "", "#1565C0"))
ui.OnEvent("Card_CodingFocus", "Click", (*) => PlaySong("Coding Focus", "Playlist", "", "#424242"))
ui.OnEvent("Card_Synthwave", "Click", (*) => PlaySong("Synthwave Essentials", "Playlist", "", "#C2185B"))
ui.OnEvent("Card_ChillVibes", "Click", (*) => PlaySong("Chill Vibes", "Playlist", "", "#00838F"))

; Library Item Clicks
ui.OnEvent("Lib_Liked", "Click", (*) => PlaySong("Liked Songs", "Playlist"))
ui.OnEvent("Lib_Albums", "Click", (*) => PlaySong("Your Albums", "Collection"))
ui.OnEvent("Lib_Pods", "Click", (*) => PlaySong("Podcasts", "Shows"))
ui.OnEvent("Lib_Starboy", "Click", (*) => PlaySong("Starboy", "The Weeknd"))
ui.OnEvent("Lib_1989", "Click", (*) => PlaySong("1989", "Taylor Swift"))
ui.OnEvent("Lib_Currents", "Click", (*) => PlaySong("Currents", "Tame Impala"))

for i, p in playlists {
    boundName := p
    ui.OnEvent("Sidebar_Playlist_" i, "Click", ((name, *) => (
        ui.Update("MainGreeting", "Text", name),
        PlaySong(name, "Playlist")
    )).Bind(boundName))
}

app.Show()
