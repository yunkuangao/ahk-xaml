#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; CHAT APP CLONE - MASSIVE INTERACTIVE DEMO
; ==============================================================================

app := XAML_GUI("Chat Clone", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35, AppIcon: true, Theme: "Dark Mica (Win 11)" })
app.tabs.Visibility("Collapsed")
global chatComponents := []
global msgReactors := []
app.main.Background("{DynamicResource BgColor}")

masterGrid := app.main.Add("Grid")
masterGrid.Cols("Auto", "Auto", "*", "Auto")

; ==============================================================================
; DUMMY STATE MANAGEMENT
; ==============================================================================
global State := {
    ActiveServer: "ahk",
    ActiveChannel: "ahk_general",
    Servers: [{ id: "home", name: "Home", icon: "https://picsum.photos/seed/discord/100/100" }, { id: "gaming", name: "Gaming Hub", icon: "https://picsum.photos/seed/gaming/100/100" }, { id: "ahk", name: "AHK Masters", icon: "https://picsum.photos/seed/ahk/100/100" }
    ],
    Channels: Map(
        "home", [{ id: "home_friends", name: "Friends", icon: "👥" }],
        "gaming", [{ id: "gaming_general", name: "general", icon: "#" }, { id: "gaming_lfg", name: "lfg", icon: "#" }],
        "ahk", [{ id: "ahk_general", name: "general", icon: "#" }, { id: "ahk_help", name: "help", icon: "#" }, { id: "ahk_snippets", name: "snippets", icon: "</>" }, { id: "ahk_voice", name: "Lobby", icon: "🔊" }]
    ),
    Messages: Map(
        "home_friends", [{ author: "Lexi", time: "10:00 AM", text: "Hey let's play something!", avatar: "lexi" }],
        "gaming_general", [{ author: "Player1", time: "11:00 AM", text: "GGs everyone.", avatar: "p1" }],
        "gaming_lfg", [{ author: "NoobMaster", time: "12:00 PM", text: "Need 1 for ranked.", avatar: "p2" }],
        "ahk_general", [{ author: "Lexi", time: "10:23 AM", text: "Hey everyone, welcome to the new server!", avatar: "lexi" }, { author: "VideoFan", time: "11:00 AM", text: "Check out this awesome video I found!", avatar: "videofan", media: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4" }
        ],
        "ahk_help", [{ author: "DevGuy", time: "10:25 AM", text: "Does anyone know how to show a messagebox in AHK v2?", avatar: "devguy" }, { author: "AHK_Bot", time: "10:26 AM", text: "Here is a quick example:", avatar: "bot", code: "MsgBox `"Hello World!`"" }
        ],
        "ahk_snippets", [{ author: "ProCoder", time: "09:00 AM", text: "Here's my beautiful loop snippet:", avatar: "pro", code: "Loop 10 {`n    MsgBox A_Index`n}" }
        ],
        "ahk_voice", []
    ),
    Members: [{ name: "Lexi", status: "#3BA55D", role: "{DynamicResource TextMain}", avatar: "lexi", server: "ahk" }, { name: "DevGuy", status: "#FAA61A", role: "{DynamicResource TextMain}", avatar: "devguy", server: "ahk" }, { name: "AHK_Bot", status: "#747F8D", role: "#3498DB", avatar: "bot", server: "ahk" }, { name: "ProCoder", status: "#3BA55D", role: "#E74C3C", avatar: "pro", server: "ahk" }, { name: "Player1", status: "#3BA55D", role: "{DynamicResource TextMain}", avatar: "p1", server: "gaming" }, { name: "NoobMaster", status: "#747F8D", role: "{DynamicResource TextMain}", avatar: "p2", server: "gaming" }
    ]
}

; ==============================================================================
; 1. SERVER SIDEBAR (Col 0)
; ==============================================================================
serverBdr := masterGrid.Add("Border").Grid_Column(0).Name("ServerListPanel").Width("72").Background("{DynamicResource SidebarColor}")
serverSp := serverBdr.Add("StackPanel").Margin("0,10,0,0").HorizontalAlignment("Center")

for idx, srv in State.Servers {
    isActive := (srv.id == State.ActiveServer)
    bdr := serverSp.Add("Border").Width("48").Height("48").CornerRadius(isActive ? "16" : "24").Margin("0,0,0,8").ClipToBounds("True").Cursor("Hand").Background("{DynamicResource BgColor}").Name("BtnServer_" srv.id)
    grid := bdr.Add("Grid")
    grid.Add("TextBlock").Text(SubStr(srv.name, 1, 1)).Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(20).HorizontalAlignment("Center").VerticalAlignment("Center")
    grid.Add("Image").Source(srv.icon).Stretch("UniformToFill")
    bdr.ToolTip(srv.name)
    if (srv.id == "home")
        serverSp.Add("Border").Width("32").Height("2").Background("{DynamicResource ControlBorder}").Margin("0,0,0,8")
}

; ==============================================================================
; 2. CHANNEL LIST (Col 1)
; ==============================================================================
channelBdr := masterGrid.Add("Border").Grid_Column(1).Name("ChannelListPanel").Background("{DynamicResource DropdownBg}").Tag("Expanded").ClipToBounds("True").BorderThickness("0,0,1,0").BorderBrush("{DynamicResource ControlBorder}")

style := '<Style TargetType="Border"><Setter Property="Width" Value="240"/><Setter Property="Margin" Value="0,0,0,0"/><Setter Property="Panel.ZIndex" Value="10"/><Style.Triggers>'
style .= '<Trigger Property="Tag" Value="Collapsed"><Setter Property="Width" Value="0"/></Trigger>'
style .= '<MultiTrigger><MultiTrigger.Conditions><Condition Property="Tag" Value="Collapsed"/><Condition Property="IsMouseOver" Value="True"/></MultiTrigger.Conditions>'
style .= '<Setter Property="Width" Value="240"/><Setter Property="Margin" Value="0,0,-240,0"/></MultiTrigger>'
style .= '<MultiDataTrigger><MultiDataTrigger.Conditions><Condition Binding="{Binding Tag, RelativeSource={RelativeSource Self}}" Value="Collapsed"/><Condition Binding="{Binding IsMouseOver, ElementName=ServerListPanel}" Value="True"/></MultiDataTrigger.Conditions>'
style .= '<Setter Property="Width" Value="240"/><Setter Property="Margin" Value="0,0,-240,0"/></MultiDataTrigger>'
style .= '</Style.Triggers></Style>'
channelBdr.InjectResources(style)

channelGrid := channelBdr.Add("Grid").Rows("48", "*", "52").Width("240")

; Header
chanHeader := channelGrid.Add("Border").Grid_Row(0).BorderThickness("0,0,0,1").BorderBrush("{DynamicResource ControlBorder}")

btnHeader := chanHeader.Add("ToggleButton").Name("BtnServerHeader").Background("Transparent").BorderThickness("0").Cursor("Hand").Padding("16,0").HorizontalContentAlignment("Stretch")
btnHeader.InjectResources('<Style TargetType="ToggleButton"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ToggleButton"><Border x:Name="bg" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}"><ContentPresenter/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="{DynamicResource ControlBgHover}"/></Trigger><Trigger Property="IsChecked" Value="True"><Setter TargetName="bg" Property="Background" Value="{DynamicResource ControlBgHover}"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')

chanHeaderGrid := btnHeader.Add("Grid").Cols("*", "Auto")
chanHeaderGrid.Add("TextBlock").Text("AHK Masters").Name("ServerNameHeader").Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(15).VerticalAlignment("Center")
chanHeaderGrid.Add("TextBlock").Grid_Column(1).Text(Chr(0xE70D)).FontFamily("Segoe Fluent Icons").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")

pop := chanHeaderGrid.Add("Popup").PlacementTarget("{Binding ElementName=BtnServerHeader}").IsOpen("{Binding ElementName=BtnServerHeader, Path=IsChecked, Mode=TwoWay}").StaysOpen("False").AllowsTransparency("True").PopupAnimation("Fade")
popBdr := pop.Add("Border").Background("{DynamicResource DropdownBg}").CornerRadius("8").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Margin("0,10,0,0").Padding("8").Width("220")
popBdr.Add("Border.Effect").Add("DropShadowEffect").BlurRadius("15").ShadowDepth("4").Opacity("0.3")

popMenu := popBdr.Add("StackPanel")
btnStyle := '<Style TargetType="Button"><Setter Property="Background" Value="Transparent"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="4" Padding="12,8"><ContentPresenter HorizontalAlignment="Stretch" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#15FFFFFF"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
popMenu.InjectResources(btnStyle)

btn1 := popMenu.Add("Button").Cursor("Hand").Margin("0,2").Name("BtnServerBoost")
sp1 := btn1.Add("Grid").Cols("*", "Auto")
sp1.Add("TextBlock").Text("Server Boost").Foreground("#FF73FA").FontWeight("SemiBold")
sp1.Add("TextBlock").Grid_Column(1).Text("💎").Foreground("#FF73FA")

popMenu.Add("Rectangle").Height("1").Fill("{DynamicResource ControlBorder}").Margin("4,4,4,4")

btn2 := popMenu.Add("Button").Cursor("Hand").Margin("0,2")
sp2 := btn2.Add("Grid").Cols("*", "Auto")
sp2.Add("TextBlock").Text("Invite People").Foreground("#0A84FF").FontWeight("SemiBold")
sp2.Add("TextBlock").Grid_Column(1).Text(Chr(0xE8FA)).FontFamily("Segoe Fluent Icons").Foreground("#0A84FF")

btn3 := popMenu.Add("Button").Cursor("Hand").Margin("0,2")
sp3 := btn3.Add("Grid").Cols("*", "Auto")
sp3.Add("TextBlock").Text("Server Settings").Foreground("{DynamicResource TextMain}").FontWeight("SemiBold")
sp3.Add("TextBlock").Grid_Column(1).Text(Chr(0xE713)).FontFamily("Segoe Fluent Icons").Foreground("{DynamicResource TextMain}")

btn4 := popMenu.Add("Button").Cursor("Hand").Margin("0,2")
sp4 := btn4.Add("Grid").Cols("*", "Auto")
sp4.Add("TextBlock").Text("Create Channel").Foreground("{DynamicResource TextMain}").FontWeight("SemiBold")
sp4.Add("TextBlock").Grid_Column(1).Text(Chr(0xE710)).FontFamily("Segoe Fluent Icons").Foreground("{DynamicResource TextMain}")

popMenu.Add("Rectangle").Height("1").Fill("{DynamicResource ControlBorder}").Margin("4,4,4,4")

btn5 := popMenu.Add("Button").Cursor("Hand").Margin("0,2")
sp5 := btn5.Add("Grid").Cols("*", "Auto")
sp5.Add("TextBlock").Text("Leave Server").Foreground("#F04747").FontWeight("SemiBold")
sp5.Add("TextBlock").Grid_Column(1).Text(Chr(0xE8A7)).FontFamily("Segoe Fluent Icons").Foreground("#F04747")

; Channel Lists Container
chanContainer := channelGrid.Add("Grid").Grid_Row(1).Margin("8,16,8,0")

for srv in State.Servers {
    srvSv := chanContainer.Add("ScrollViewer").Name("ChanList_" srv.id).Visibility(srv.id == State.ActiveServer ? "Visible" : "Collapsed")
    srvSp := srvSv.Add("StackPanel")
    srvSp.Add("TextBlock").Text("CHANNELS").Foreground("{DynamicResource TextSub}").FontWeight("Bold").FontSize(12).Margin("8,0,0,4")

    chanStyle := '<Style TargetType="RadioButton"><Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="{DynamicResource TextSub}"/><Setter Property="FontWeight" Value="Normal"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="RadioButton"><Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="4" Padding="8,6"><ContentPresenter/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="{DynamicResource ControlBgHover}"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/></Trigger><Trigger Property="IsChecked" Value="True"><Setter TargetName="bg" Property="Background" Value="{DynamicResource ControlBgHover}"/><Setter Property="Foreground" Value="{DynamicResource TextMain}"/><Setter Property="FontWeight" Value="SemiBold"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>'
    srvSp.InjectResources(chanStyle)

    for ch in State.Channels[srv.id] {
        isActive := (ch.id == State.ActiveChannel)
        btn := srvSp.Add("RadioButton").Name("BtnChan_" ch.id).GroupName("ChanGroup").Margin("0,0,0,2").Cursor("Hand")
        if isActive
            btn.IsChecked("True")

        sp := btn.Add("StackPanel").Orientation("Horizontal").IsHitTestVisible("False")
        sp.Add("TextBlock").Text(ch.icon).FontWeight("Bold").FontSize(16).Margin("0,0,6,0").VerticalAlignment("Center")
        sp.Add("TextBlock").Text(ch.name).FontSize(15).VerticalAlignment("Center").Name("ChanTxt_" ch.id)
    }
}

; User Profile Area
userArea := channelGrid.Add("Border").Grid_Row(2).Background("{DynamicResource SidebarColor}")
userGrid := userArea.Add("Grid").Cols("Auto", "*", "Auto").Margin("8,0")
userBdr := userGrid.Add("Border").Grid_Column(0).Width("32").Height("32").CornerRadius("16").ClipToBounds("True").VerticalAlignment("Center").Margin("0,0,8,0")
userBdrGrid := userBdr.Add("Grid")
userBdrGrid.Add("TextBlock").Text("U").Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(14).HorizontalAlignment("Center").VerticalAlignment("Center")
userBdrGrid.Add("Image").Source("https://picsum.photos/seed/user/100/100").Stretch("UniformToFill")
userInfo := userGrid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
userInfo.Add("TextBlock").Text("User123").Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(14)
userInfo.Add("TextBlock").Text("#1234").Foreground("{DynamicResource TextSub}").FontSize(12)

userControls := userGrid.Add("StackPanel").Grid_Column(2).Orientation("Horizontal").VerticalAlignment("Center")
userControls.Add("TextBlock").Text("🎤").Foreground("{DynamicResource TextSub}").FontSize(14).Margin("0,0,10,0").Cursor("Hand").Name("BtnMic")
userControls.Add("TextBlock").Text("🎧").Foreground("{DynamicResource TextSub}").FontSize(14).Margin("0,0,10,0").Cursor("Hand").Name("BtnDeafen")
userControls.Add("TextBlock").Text("⚙").Foreground("{DynamicResource TextSub}").FontSize(14).Cursor("Hand").Name("BtnSettings")

; ==============================================================================
; 3. MAIN CHAT AREA (Col 2)
; ==============================================================================
chatGrid := masterGrid.Add("Grid").Grid_Column(2).Background("{DynamicResource BgColor}")
chatGrid.Rows("48", "*", "Auto")

; Chat Header
chatHeader := chatGrid.Add("Border").Grid_Row(0).BorderThickness("0,0,0,1").BorderBrush("{DynamicResource ControlBorder}")
chatHeaderGrid := chatHeader.Add("Grid").Cols("Auto", "*", "Auto").Margin("16,0")
leftBtns := chatHeaderGrid.Add("StackPanel").Orientation("Horizontal").VerticalAlignment("Center")
leftBtns.Add("Button").Name("BtnTogglePanes").Content(Chr(0xE89F)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Use("IconBtn").Foreground("{DynamicResource TextSub}").Margin("0,0,16,0").ToolTip("Toggle Sidebar Panes")
leftBtns.Add("TextBlock").Text("# general").Name("ChatHeaderName").Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(15).VerticalAlignment("Center")

; Command Bar
cmdBar := chatHeaderGrid.Add("StackPanel").Grid_Column(2).Orientation("Horizontal").VerticalAlignment("Center")
cb := cmdBar.CommandBar("ChatCmds")
cb.AddButton(Chr(0xEA8F), "Mute", "BtnMute")
cb.AddButton(Chr(0xE840), "Pinned", "BtnPinned")
cb.AddButton(Chr(0xE716), "Members", "BtnToggleMembers")

; Chat Messages Container
msgContainer := chatGrid.Add("Grid").Grid_Row(1)

for srv in State.Servers {
    for ch in State.Channels[srv.id] {
        sv := msgContainer.Add("ScrollViewer").Name("MsgView_" ch.id).Margin("0,0,0,0").Visibility(ch.id == State.ActiveChannel ? "Visible" : "Collapsed")
        sp := sv.Add("StackPanel").Margin("16,16,16,16").Name("MsgSp_" ch.id)

        for msgIndex, msg in State.Messages[ch.id] {
            BuildMessage(sp, msg, ch.id, msgIndex)
        }
    }
}

; Input Area
inputBdr := chatGrid.Add("Border").Grid_Row(2).Background("{DynamicResource ControlBg}").CornerRadius("8").Margin("16,0,16,24")
inputGrid := inputBdr.Add("Grid").Cols("Auto", "*", "Auto").Margin("16,10")
inputGrid.Add("TextBlock").Grid_Column(0).Text("⊕").Foreground("{DynamicResource TextSub}").FontSize(20).VerticalAlignment("Center").Margin("0,0,16,0").Cursor("Hand")
chatInputBox := inputGrid.Add("TextBox").Name("ChatInput").Grid_Column(1).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness("0").FontSize(15).TextWrapping("Wrap").MaxHeight("144")
inputGrid.Add("TextBlock").Grid_Column(1).Text("Message...").Foreground("{DynamicResource TextSub}").FontSize(15).VerticalAlignment("Center").Margin("4,0,0,0").IsHitTestVisible("False").Name("InputPlaceholder")
inputRightSp := inputGrid.Add("StackPanel").Grid_Column(2).Orientation("Horizontal").VerticalAlignment("Center")
inputRightSp.Add("TextBlock").Text("🎁").Foreground("{DynamicResource TextSub}").FontSize(20).Margin("16,0,10,0").Cursor("Hand")
emojiWrap := inputRightSp.Add("Grid").Margin("0,-8,0,-8") ; Offset padding
ep := emojiWrap.EmojiPicker("ChatEmoji", { ButtonText: "😊" })

; ==============================================================================
; 4. MEMBER LIST (Col 3)
; ==============================================================================
memberBdr := masterGrid.Add("Border").Grid_Column(3).Name("MemberListPanel").Width("240").Background("{DynamicResource ControlBg}")
memContainer := memberBdr.Add("Grid").Margin("0,16,0,0")

for srv in State.Servers {
    memSv := memContainer.Add("ScrollViewer").Name("MemView_" srv.id).Visibility(srv.id == State.ActiveServer ? "Visible" : "Collapsed")
    memSp := memSv.Add("StackPanel").Margin("16,0")

    onlineCount := 0
    for mem in State.Members {
        if (mem.server == srv.id && mem.status != "#747F8D")
            onlineCount++
    }
    memSp.Add("TextBlock").Text("ONLINE - " onlineCount).Foreground("{DynamicResource TextSub}").FontWeight("Bold").FontSize(12).Margin("0,0,0,8")

    for mem in State.Members {
        if (mem.server == srv.id && mem.status != "#747F8D") {
            AddMemToSp(memSp, mem)
        }
    }

    memSp.Add("TextBlock").Text("OFFLINE").Foreground("{DynamicResource TextSub}").FontWeight("Bold").FontSize(12).Margin("0,16,0,8")
    for mem in State.Members {
        if (mem.server == srv.id && mem.status == "#747F8D") {
            AddMemToSp(memSp, mem)
        }
    }
}

AddMemToSp(parent, mem) {
    bdr := parent.Add("Border").CornerRadius("4").Padding("8,6").Margin("0,0,0,2").Cursor("Hand").Name("BtnMem_" mem.name)
    bdr.InjectResources('<Style TargetType="Border"><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="{DynamicResource ControlBgHover}"/></Trigger></Style.Triggers></Style>')
    grid := bdr.Add("Grid").Cols("Auto", "*")
    avaGrid := grid.Add("Grid").Grid_Column(0).Width("32").Height("32").Margin("0,0,12,0")
    avaBdr := avaGrid.Add("Border").CornerRadius("16").Background("{DynamicResource SidebarColor}")
    avaInner := avaBdr.Add("Grid")
    avaInner.Add("TextBlock").Text(SubStr(mem.name, 1, 1)).Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(14).HorizontalAlignment("Center").VerticalAlignment("Center")
    avaInner.Add("Ellipse").Add("Ellipse.Fill").Add("ImageBrush").ImageSource("https://picsum.photos/seed/" mem.avatar "/100/100").Stretch("UniformToFill")
    avaGrid.Add("Border").Width("10").Height("10").CornerRadius("5").Background(mem.status).BorderThickness("2").BorderBrush("{DynamicResource ControlBg}").HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("0,0,-2,-2")
    grid.Add("TextBlock").Grid_Column(1).Text(mem.name).Foreground(mem.role).FontWeight("SemiBold").FontSize(15).VerticalAlignment("Center")
}

; ==============================================================================
; FLYOUTS & BINDINGS
; ==============================================================================
switcher := app.overlay.CommandPalette("QuickSwitcher")
switcher.AddCommand("cmd_1", "Switch to General", { Icon: "#", Category: "Channels" })

settingsLayer := masterGrid.Add("Grid").Grid_ColumnSpan(4).Background("{DynamicResource DropdownBg}").Visibility("Collapsed").Name("SettingsLayer").SetProp("Panel.ZIndex", "100")
setNav := settingsLayer.NavigationView("SettingsNav")

closeBtn := settingsLayer.Add("Button").Name("BtnCloseSettings").HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,20,20,0").Cursor("Hand").Background("Transparent").BorderThickness("0")
closeBtn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="Transparent"><ContentPresenter/></Border></ControlTemplate></Setter.Value></Setter></Style>')
closeSp := closeBtn.Add("StackPanel")
closeBdr := closeSp.Add("Border").Width("36").Height("36").CornerRadius("18").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("2").Background("{DynamicResource ControlBgHover}")
closeBdr.Add("TextBlock").Text(Chr(0xE8BB)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(14).HorizontalAlignment("Center").VerticalAlignment("Center").Foreground("{DynamicResource TextMain}")
closeSp.Add("TextBlock").Text("ESC").Foreground("{DynamicResource TextSub}").FontSize(12).FontWeight("Bold").HorizontalAlignment("Center").Margin("0,6,0,0")

accScroll := XAMLElement("ScrollViewer").Margin("0,0,80,0")
app.SetupTemplates(accScroll)
accPage := accScroll.Add("StackPanel").Margin("40")

accPage.Add("TextBlock").Text("My Account").Foreground("{DynamicResource TextMain}").FontSize(20).FontWeight("Bold").Margin("0,0,0,20")

; Profile Card
profCardWrap := accPage.Add("Border").Margin("0,0,0,40")
profCardWrap.Add("Border.Effect").Add("DropShadowEffect").BlurRadius("25").ShadowDepth("10").Opacity("0.15").Direction("270")
profCard := profCardWrap.Add("Border").Background("{DynamicResource ControlBg}").CornerRadius("12").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").ClipToBounds("True")
profGrid := profCard.Add("Grid").Rows("120", "Auto")

bannerBg := profGrid.Add("Border").Grid_Row(0).Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
bannerBg.Add("GradientStop").SetProp('Color', "#5865F2").Offset("0.0")
bannerBg.Add("GradientStop").SetProp('Color', "#ED4245").Offset("1.0")

profDetails := profGrid.Add("Grid").Grid_Row(1).Margin("20,-40,20,20")

avaGrid := profDetails.Add("Grid").HorizontalAlignment("Left").VerticalAlignment("Top")
avaBdr := avaGrid.Add("Border").Width("80").Height("80").CornerRadius("40").BorderThickness("6").BorderBrush("{DynamicResource ControlBg}").Background("{DynamicResource SidebarColor}")
avaInner := avaBdr.Add("Grid")
avaInner.Add("TextBlock").Text("U").Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(32).HorizontalAlignment("Center").VerticalAlignment("Center")
avaInner.Add("Ellipse").Add("Ellipse.Fill").Add("ImageBrush").ImageSource("https://picsum.photos/seed/user/200/200").Stretch("UniformToFill")

userText := profDetails.Add("StackPanel").Margin("100,45,0,0")
userText.Add("TextBlock").Text("User123").Foreground("{DynamicResource TextMain}").FontSize(20).FontWeight("Bold")
userText.Add("TextBlock").Text("user123@email.com").Foreground("{DynamicResource TextSub}").FontSize(14)

profDetails.Add("Button").Content("Edit Profile").HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,50,0,0").Padding("16,8").Cursor("Hand")

; Appearance Section
accPage.Add("Border").Height("1").Background("{DynamicResource ControlBorder}").Margin("0,0,0,20")
accPage.Add("TextBlock").Text("APPEARANCE").Foreground("{DynamicResource TextSub}").FontWeight("Bold").FontSize(12).Margin("0,0,0,10")

themeGrid := accPage.Add("WrapPanel").Margin("0,0,0,30")
themeCards := []

iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
if FileExist(iniPath) {
    themeData := IniRead(iniPath)
    Loop Parse, themeData, "`n", "`r" {
        t := A_LoopField
        if !t
            continue
        themeCards.Push(t)

        bgCol := IniRead(iniPath, t, "Resource_DropdownBg", "#1E1E1E")
        accCol := IniRead(iniPath, t, "Resource_Accent", "#0A84FF")
        txtCol := IniRead(iniPath, t, "Resource_TextMain", "#FFFFFF")

        cleanName := RegExReplace(t, "[^\w]", "_")
        bdr := themeGrid.Add("Border").Width("140").Height("60").Margin("0,0,10,10").CornerRadius("8").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("2").Cursor("Hand").Name("BtnTheme_" cleanName).Background("Transparent")
        inner := bdr.Add("Grid").Background(bgCol)
        inner.Add("Border").Width("6").Height("30").CornerRadius("3").Background(accCol).HorizontalAlignment("Left").Margin("10,0,0,0")
        inner.Add("TextBlock").Text(t).Foreground(txtCol).FontWeight("SemiBold").FontSize(12).HorizontalAlignment("Center").VerticalAlignment("Center").Margin("10,0,0,0").TextTrimming("CharacterEllipsis")
    }
}

; Create Privacy Pane
privScroll := XAMLElement("ScrollViewer").Margin("0,0,80,0")
app.SetupTemplates(privScroll)
privPage := privScroll.Add("StackPanel").Margin("40")
privPage.Add("TextBlock").Text("Privacy & Safety").Foreground("{DynamicResource TextMain}").FontSize(20).FontWeight("Bold").Margin("0,0,0,20")
privPage.Add("TextBlock").Text("SAFE DIRECT MESSAGING").Foreground("{DynamicResource TextSub}").FontWeight("Bold").FontSize(12).Margin("0,0,0,10")

privCard := privPage.Add("Border").Background("{DynamicResource ControlBg}").CornerRadius("8").Padding("16").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Margin("0,0,0,20")
privSp := privCard.Add("StackPanel")
privRow1 := privSp.Add("Grid").Cols("*", "Auto").Margin("0,0,0,16")
privRow1.Add("TextBlock").Text("Filter explicit media from direct messages").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontWeight("SemiBold")
privRow1.Add("CheckBox").Grid_Column(1).IsChecked("True").Style("{StaticResource ToggleSwitch}")
privRow2 := privSp.Add("Grid").Cols("*", "Auto")
privRow2.Add("TextBlock").Text("Allow direct messages from server members").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontWeight("SemiBold")
privRow2.Add("CheckBox").Grid_Column(1).IsChecked("True").Style("{StaticResource ToggleSwitch}")

; Create Notifications Pane
notifScroll := XAMLElement("ScrollViewer").Margin("0,0,80,0")
app.SetupTemplates(notifScroll)
notifPage := notifScroll.Add("StackPanel").Margin("40")
notifPage.Add("TextBlock").Text("Notifications").Foreground("{DynamicResource TextMain}").FontSize(20).FontWeight("Bold").Margin("0,0,0,20")
notifPage.Add("TextBlock").Text("DESKTOP NOTIFICATIONS").Foreground("{DynamicResource TextSub}").FontWeight("Bold").FontSize(12).Margin("0,0,0,10")

notifCard := notifPage.Add("Border").Background("{DynamicResource ControlBg}").CornerRadius("8").Padding("16").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Margin("0,0,0,20")
notifSp := notifCard.Add("StackPanel")
nRow1 := notifSp.Add("Grid").Cols("*", "Auto").Margin("0,0,0,16")
nRow1.Add("TextBlock").Text("Enable Desktop Notifications").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontWeight("SemiBold")
nRow1.Add("CheckBox").Grid_Column(1).IsChecked("True").Style("{StaticResource ToggleSwitch}")
nRow2 := notifSp.Add("Grid").Cols("*", "Auto")
nRow2.Add("TextBlock").Text("Enable Unread Message Badge").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontWeight("SemiBold")
nRow2.Add("CheckBox").Grid_Column(1).IsChecked("True").Style("{StaticResource ToggleSwitch}")

notifPage.Add("TextBlock").Text("SOUNDS").Foreground("{DynamicResource TextSub}").FontWeight("Bold").FontSize(12).Margin("0,0,0,10")
notifPage.Add("Slider").Minimum("0").Maximum("100").Value("50").Width("300").HorizontalAlignment("Left")

; Create Advanced Pane
advScroll := XAMLElement("ScrollViewer").Margin("0,0,80,0")
app.SetupTemplates(advScroll)
advPage := advScroll.Add("StackPanel").Margin("40")
advPage.Add("TextBlock").Text("Advanced").Foreground("{DynamicResource TextMain}").FontSize(20).FontWeight("Bold").Margin("0,0,0,20")
advPage.Add("TextBlock").Text("APP BEHAVIOR").Foreground("{DynamicResource TextSub}").FontWeight("Bold").FontSize(12).Margin("0,0,0,10")

behCard := advPage.Add("Border").Background("{DynamicResource ControlBg}").CornerRadius("8").Padding("16").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}")
behSp := behCard.Add("StackPanel")
sw1 := behSp.Add("Grid").Cols("*", "Auto").Margin("0,0,0,16")
sw1.Add("TextBlock").Text("Hardware Acceleration").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontWeight("SemiBold")
sw1.Add("CheckBox").Grid_Column(1).IsChecked("True").Style("{StaticResource ToggleSwitch}")
sw2 := behSp.Add("Grid").Cols("*", "Auto")
sw2.Add("TextBlock").Text("Developer Mode").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").FontWeight("SemiBold")
sw2.Add("CheckBox").Grid_Column(1).Style("{StaticResource ToggleSwitch}")

setNav.AddPage("My Account", Chr(0xE77B), accScroll)
setNav.AddPage("Privacy & Safety", Chr(0xEA18), privScroll)
setNav.AddPage("Notifications", Chr(0xEA8F), notifScroll)
setNav.AddPage("Advanced", Chr(0xE713), advScroll)

ui := app.Compile()
setNav.Bind(ui)

for t in themeCards {
    cleanName := RegExReplace(t, "[^\w]", "_")
    ui.OnEvent("BtnTheme_" cleanName, "MouseLeftButtonUp", SetAppTheme.Bind(t))
}
for comp in chatComponents
    comp.Bind(ui)
switcher.Bind(ui, "^k")

for reactor in msgReactors {
    ui.OnEvent(reactor.btnId, "Click", ShowReaction.Bind(reactor.pillId, reactor.emoji))
}

ShowReaction(pillId, emoji, state, ctrl, event) {
    ui.Update("PillBdr_" pillId, "Visibility", "Visible")
    ui.Update("PillTxt_" pillId, "Text", emoji)
}

EmojiPickerBind(ui, "ChatEmoji", ep.EmojiList)
for i, emoji in ep.EmojiList {
    ui.OnEvent("ChatEmoji_E_" i, "Click", AppendEmoji.Bind(emoji))
}
AppendEmoji(emoji, state, *) {
    currentText := state.Has("ChatInput") ? state["ChatInput"] : ""
    ui.Update("ChatInput", "Text", currentText emoji)
}

ui.OnEvent("ChatInput", "TextChanged", ChatInputChanged)
ChatInputChanged(state, *) {
    ui.Update("InputPlaceholder", "Visibility", state["ChatInput"] == "" ? "Visible" : "Collapsed")
}

; Chat Submission (Enter key)
ui.OnEvent("ChatInput", "KeyDown:Return", ChatInputSubmit)
ChatInputSubmit(state, *) {
    text := state["ChatInput"]
    if (Trim(text) == "")
        return

    gen := XAML_Generator("Grid")
    static dynMsgCounter := 1000
    dynMsgCounter++
    msgObj := { author: "User123", time: FormatTime(A_Now, "h:mm tt"), text: text }
    BuildMessage(gen, msgObj, State.ActiveChannel, dynMsgCounter)

    xamlStr := gen.Compile()
    ; Unwrap the Grid tags from the generator so we can inject its children directly
    xamlStr := RegExReplace(xamlStr, "^<Grid[^>]*>(.*)</Grid>$", "$1")
    ui.Update("MsgSp_" State.ActiveChannel, "AddXamlItem", xamlStr)
    ui.Update("ChatInput", "Text", "")
    
    for i in [1, 2, 3, 4, 5] {
        idx := msgReactors.Length - 5 + i
        reactor := msgReactors[idx]
        ui.OnEvent(reactor.btnId, "Click", ShowReaction.Bind(reactor.pillId, reactor.emoji))
    }
}

BuildMessage(parent, msg, chId, msgIndex) {
    msgG := parent.Add("Grid").Cols("Auto", "*").Margin("0,0,0,16")
    ava := msgG.Add("Border").Grid_Column(0).Width("40").Height("40").CornerRadius("20").Background("{DynamicResource SidebarColor}").VerticalAlignment("Top").Margin("0,0,16,0")
    aGrid := ava.Add("Grid")
    aGrid.Add("TextBlock").Text(SubStr(msg.author, 1, 1)).Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center")
    if (msg.HasProp("avatar")) {
        aGrid.Add("Ellipse").Add("Ellipse.Fill").Add("ImageBrush").ImageSource("https://picsum.photos/seed/" msg.avatar "/100/100").Stretch("UniformToFill")
    }
    
    cntSp := msgG.Add("StackPanel").Grid_Column(1)
    hdrSp := cntSp.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,4")
    hdrSp.Add("TextBlock").Text(msg.author).Foreground("{DynamicResource TextMain}").FontWeight("SemiBold").FontSize(15).Margin("0,0,8,0").Cursor("Hand")
    hdrSp.Add("TextBlock").Text(msg.time).Foreground("{DynamicResource TextSub}").FontSize(12).VerticalAlignment("Bottom")
    cntSp.Add("TextBlock").Text(msg.text).Foreground("{DynamicResource TextMain}").FontSize(15).TextWrapping("Wrap")
    
    if (msg.HasProp("code")) {
        cdG := cntSp.Add("Grid").Margin("0,8,0,0")
        chatComponents.Push(cdG.CodeEditor(msg.code))
    }
    if (msg.HasProp("media")) {
        mdG := cntSp.Add("Grid").Margin("0,8,0,0").Width("300").Height("200")
        chatComponents.Push(mdG.MediaPlayerEx(msg.media))
    }
    
    reactId := "React_" chId "_" msgIndex
    reactBar := msgG.Add("Border").Name("Bar_" reactId).HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,-10,10,0").Background("{DynamicResource ControlBg}").CornerRadius("16").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").SetProp("Panel.ZIndex", "10")
    reactBar.InjectResources('<Style TargetType="Border"><Setter Property="Opacity" Value="0"/><Style.Triggers><DataTrigger Binding="{Binding IsMouseOver, RelativeSource={RelativeSource AncestorType=Grid}}" Value="True"><Setter Property="Opacity" Value="1"/></DataTrigger></Style.Triggers></Style>')
    
    reactSp := reactBar.Add("StackPanel").Orientation("Horizontal").Margin("4,2")
    reactEmojis := ["👍", "❤️", "😂", "😮", "😢"]
    for i, e in reactEmojis {
        btnId := reactId "_E_" i
        reactSp.Add("Button").Name(btnId).Content(e).FontFamily("Segoe UI Emoji").FontSize("14").Background("Transparent").BorderThickness("0").Cursor("Hand").Padding("4,2").ToolTip(e)
        msgReactors.Push({ btnId: btnId, emoji: e, pillId: reactId })
    }
    
    reactPill := cntSp.Add("Border").HorizontalAlignment("Left").Margin("0,8,0,0").CornerRadius("4").Background("#20FFFFFF").BorderThickness("1").BorderBrush("#30FFFFFF").Padding("6,2").Visibility("Collapsed").Name("PillBdr_" reactId)
    reactPillSp := reactPill.Add("StackPanel").Orientation("Horizontal")
    reactPillSp.Add("TextBlock").Name("PillTxt_" reactId).Text("").FontSize("14").FontFamily("Segoe UI Emoji").VerticalAlignment("Center").Margin("0,0,6,0")
    reactPillSp.Add("TextBlock").Text("1").Foreground("{DynamicResource TextMain}").FontSize("12").FontWeight("SemiBold").VerticalAlignment("Center")
    return msgG
}

; Channel Clicking
for srv in State.Servers {
    for ch in State.Channels[srv.id] {
        ui.OnEvent("BtnChan_" ch.id, "Checked", SwitchChannel.Bind(ch))
    }
}
SwitchChannel(chObj, *) {
    if (chObj.id == State.ActiveChannel)
        return
    ui.Update("MsgView_" State.ActiveChannel, "Visibility", "Collapsed")

    State.ActiveChannel := chObj.id

    ui.Update("MsgView_" State.ActiveChannel, "Visibility", "Visible")
    ui.Update("ChatHeaderName", "Text", "# " chObj.name)
}

; Server Clicking
for srv in State.Servers {
    ui.OnEvent("BtnServer_" srv.id, "MouseLeftButtonDown", SwitchServer.Bind(srv))
}
SwitchServer(srvObj, *) {
    if (srvObj.id == State.ActiveServer)
        return
    ui.Update("BtnServer_" State.ActiveServer, "CornerRadius", "24")
    ui.Update("ChanList_" State.ActiveServer, "Visibility", "Collapsed")
    ui.Update("MemView_" State.ActiveServer, "Visibility", "Collapsed")

    State.ActiveServer := srvObj.id

    ui.Update("BtnServer_" State.ActiveServer, "CornerRadius", "16")
    ui.Update("ChanList_" State.ActiveServer, "Visibility", "Visible")
    ui.Update("MemView_" State.ActiveServer, "Visibility", "Visible")
    ui.Update("ServerNameHeader", "Text", srvObj.name)

    ; Auto-switch to the first channel in the new server
    if (State.Channels[srvObj.id].Length > 0)
        SwitchChannel(State.Channels[srvObj.id][1])
}

; Interactive Toggles
ui.OnEvent("BtnMic", "MouseLeftButtonDown", (*) => ToggleColor("BtnMic", "🎤"))
ui.OnEvent("BtnDeafen", "MouseLeftButtonDown", (*) => ToggleColor("BtnDeafen", "🎧"))
ToggleColor(id, text) {
    static st := Map()
    if !st.Has(id)
        st[id] := false
    st[id] := !st[id]
    ui.Update(id, "Foreground", st[id] ? "#F04747" : "{DynamicResource TextSub}")
    ui.Update(id, "Text", st[id] ? text " (Muted)" : text)
}

ui.OnEvent("BtnSettings", "MouseLeftButtonDown", (*) => ui.Update("SettingsLayer", "Visibility", "Visible"))
ui.OnEvent("BtnCloseSettings", "Click", (*) => ui.Update("SettingsLayer", "Visibility", "Collapsed"))

for mem in State.Members {
    ui.OnEvent("BtnMem_" mem.name, "MouseLeftButtonDown", ShowMemberProfile.Bind(mem))
}

ShowMemberProfile(mem, *) {
    profDialog := XDialog.Show({
        Title: "User Profile",
        Message: mem.name,
        DetailText: "Role Color: " mem.role "`nServer: " mem.server,
        Buttons: ["Close"],
        Icon: "👤",
        Width: 350
    })
}

global currentTheme := "Dark Mica (Win 11)"
SetAppTheme(themeName, *) {
    global currentTheme, themeCards

    for t in themeCards {
        cleanT := RegExReplace(t, "[^\w]", "_")
        try ui.Update("BtnTheme_" cleanT, "BorderBrush", "{DynamicResource ControlBorder}")
    }

    currentTheme := themeName
    app.ThemeChanged(Map("ComboTheme", themeName), "", "")

    cleanTheme := RegExReplace(themeName, "[^\w]", "_")
    try ui.Update("BtnTheme_" cleanTheme, "BorderBrush", "{DynamicResource Accent}")
}

global isPanesVisible := true
ui.OnEvent("BtnTogglePanes", "Click", TogglePanes)
TogglePanes(*) {
    global isPanesVisible
    isPanesVisible := !isPanesVisible
    ui.Update("ChannelListPanel", "Tag", isPanesVisible ? "Expanded" : "Collapsed")
    ui.Update("BtnTogglePanes", "Content", isPanesVisible ? Chr(0xE89F) : Chr(0xE8A0))
}

global isMembersVisible := true
ui.OnEvent("BtnToggleMembers", "Click", ToggleMembers)
ToggleMembers(*) {
    global isMembersVisible
    isMembersVisible := !isMembersVisible
    ui.Update("MemberListPanel", "Visibility", isMembersVisible ? "Visible" : "Collapsed")
}

app.Show()

#HotIf WinActive(app.title)
~Escape:: ui.Update("SettingsLayer", "Visibility", "Collapsed")
#HotIf
