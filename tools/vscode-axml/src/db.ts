export interface DbItem {
    name: string;
    description: string;
    snippet?: string;
    hex?: string;
}

export const ELEMENTS: DbItem[] = [
    { name: "Grid", description: "Defines a flexible grid area that consists of columns and rows.", snippet: "Grid:\n  Rows: \"*\"\n  Cols: \"*\"\n  $0" },
    { name: "StackPanel", description: "Arranges child elements into a single line that can be oriented horizontally or vertically.", snippet: "StackPanel:\n  Orientation: \"${1|Vertical,Horizontal|}\"\n  $0" },
    { name: "Border", description: "Draws a border, background, or both around another element.", snippet: "Border:\n  CornerRadius: ${1:8}\n  Background: \"${2:{DynamicResource ControlBg}\\}\"\n  $0" },
    { name: "TextBlock", description: "Provides a lightweight control for displaying small amounts of text.", snippet: "TextBlock:\n  Text: \"$1\"\n  $0" },
    { name: "TextBox", description: "Represents a control that can be used to display or edit unformatted text.", snippet: "TextBox:\n  Text: \"$1\"\n  $0" },
    { name: "Button", description: "Represents a Windows button control, which reacts to the Click event.", snippet: "Button:\n  Content: \"$1\"\n  OnClick: $2\n  $0" },
    { name: "ScrollViewer", description: "Represents a scrollable area that can contain other visible elements." },
    { name: "ComboBox", description: "Represents a selection control with a drop-down list that can be shown or hidden by clicking the arrow on the control." },
    { name: "CheckBox", description: "Represents a control that a user can select and clear." },
    { name: "RadioButton", description: "Represents a button that allows a user to select a single option from a group of options." },
    { name: "Slider", description: "Represents a control that lets the user select from a range of values by moving a Thumb control along a Track." },
    { name: "Image", description: "Represents a control that displays an image." },
    { name: "ListView", description: "Represents a control that displays a list of data items." },
    { name: "TreeView", description: "Represents a control that displays hierarchical data in a tree structure that has items that can expand and collapse." },
    { name: "TabControl", description: "Represents a control that contains multiple items that share the same space on the screen." },
    { name: "TabItem", description: "Represents a selectable item inside a TabControl." },
    { name: "WrapPanel", description: "Positions child elements in sequential position from left to right, breaking content to the next line at the edge of the containing box." },
    { name: "DockPanel", description: "Defines an area where you can arrange child elements either horizontally or vertically, relative to each other." },
    { name: "UniformGrid", description: "Provides a way to arrange content in a grid where all the cells in the grid have the same size." },
    { name: "Canvas", description: "Defines an area within which you can explicitly position child elements by using coordinates that are relative to the Canvas area." },
    { name: "ItemsControl", description: "Represents a control that can be used to present a collection of items." },
    { name: "DataGrid", description: "Represents a control that displays data in a customizable grid." },
    { name: "Expander", description: "Represents the control that displays a header and has a collapsible window that displays content." },
    { name: "ProgressBar", description: "Indicates the progress of an operation." },
    { name: "PasswordBox", description: "Represents a control for entering passwords." }
];

export const PROPERTIES: DbItem[] = [
    { name: "Margin", description: "Gets or sets the outer margin of an element.\n\n`Format: left,top,right,bottom` or `uniform`" },
    { name: "Padding", description: "Gets or sets the padding inside a control.\n\n`Format: left,top,right,bottom` or `uniform`" },
    { name: "Background", description: "Gets or sets a brush that describes the background of a control." },
    { name: "Foreground", description: "Gets or sets a brush that describes the foreground color." },
    { name: "BorderBrush", description: "Gets or sets a brush that describes the border background of a control." },
    { name: "BorderThickness", description: "Gets or sets the border thickness of a control.\n\n`Format: left,top,right,bottom` or `uniform`", snippet: "BorderThickness: \"${1:1}\"" },
    { name: "CornerRadius", description: "Gets or sets the degree to which the corners of a Border are rounded.\n\n`Format: topLeft,topRight,bottomRight,bottomLeft` or `uniform`" },
    { name: "Width", description: "Gets or sets the width of the element." },
    { name: "Height", description: "Gets or sets the suggested height of the element." },
    { name: "MinWidth", description: "Gets or sets the minimum width constraint of the element." },
    { name: "MinHeight", description: "Gets or sets the minimum height constraint of the element." },
    { name: "MaxWidth", description: "Gets or sets the maximum width constraint of the element." },
    { name: "MaxHeight", description: "Gets or sets the maximum height constraint of the element." },
    { name: "HorizontalAlignment", description: "Gets or sets the horizontal alignment characteristics applied to this element when it is composed within a parent element." },
    { name: "VerticalAlignment", description: "Gets or sets the vertical alignment characteristics applied to this element when it is composed within a parent element." },
    { name: "HorizontalContentAlignment", description: "Gets or sets the horizontal alignment of the control's content." },
    { name: "VerticalContentAlignment", description: "Gets or sets the vertical alignment of the control's content." },
    { name: "Visibility", description: "Gets or sets the user interface (UI) visibility of this element.\n\n`Values: Visible, Hidden, Collapsed`" },
    { name: "Opacity", description: "Gets or sets the opacity factor applied to the entire UIElement when it is rendered in the UI. (0.0 to 1.0)" },
    { name: "Panel.ZIndex", description: "Gets or sets a value that represents the order on the z-plane in which an element appears." },
    { name: "Grid_Row", description: "Gets or sets a value that indicates which row child content within a Grid should appear in." },
    { name: "Grid_Column", description: "Gets or sets a value that indicates which column child content within a Grid should appear in." },
    { name: "Grid_RowSpan", description: "Gets or sets a value that indicates the total number of rows that child content spans within a Grid." },
    { name: "Grid_ColumnSpan", description: "Gets or sets a value that indicates the total number of columns that child content spans within a Grid." },
    { name: "Text", description: "Gets or sets the text contents." },
    { name: "TextWrapping", description: "Gets or sets how the TextBlock should wrap text.\n\n`Values: NoWrap, Wrap, WrapWithOverflow`" },
    { name: "TextTrimming", description: "Gets or sets the text trimming behavior to employ when content overflows the content area.\n\n`Values: None, CharacterEllipsis, WordEllipsis`" },
    { name: "FontFamily", description: "Gets or sets the preferred top-level font family for the text." },
    { name: "FontSize", description: "Gets or sets the top-level font size for the text." },
    { name: "FontWeight", description: "Gets or sets the top-level font weight for the text.\n\n`Values: Normal, Bold, SemiBold, etc.`" },
    { name: "FontStyle", description: "Gets or sets the top-level font style for the text.\n\n`Values: Normal, Italic, Oblique`" },
    { name: "Rows", description: "AHK-XAML shortcut to define Grid RowDefinitions." },
    { name: "Cols", description: "AHK-XAML shortcut to define Grid ColumnDefinitions." },
    { name: "Orientation", description: "Gets or sets the dimension by which child elements are stacked.\n\n`Values: Horizontal, Vertical`" },
    { name: "HorizontalScrollBarVisibility", description: "Gets or sets a value that indicates whether a horizontal ScrollBar should be displayed.\n\n`Values: Disabled, Auto, Hidden, Visible`" },
    { name: "VerticalScrollBarVisibility", description: "Gets or sets a value that indicates whether a vertical ScrollBar should be displayed.\n\n`Values: Disabled, Auto, Hidden, Visible`" },
    { name: "Cursor", description: "Gets or sets the cursor that displays when the mouse pointer is over this element.\n\n`Values: Arrow, Hand, IBeam, etc.`" },
    { name: "ToolTip", description: "Gets or sets the tool-tip object that is displayed for this element in the user interface." },
    { name: "Content", description: "Gets or sets the content of a ContentControl." },
    { name: "IsChecked", description: "Gets or sets whether the control is checked." },
    { name: "IsEnabled", description: "Gets or sets a value indicating whether this element is enabled in the user interface." }
];

export const EVENTS: DbItem[] = [
    { name: "OnClick", description: "Occurs when a Button is clicked." },
    { name: "OnEvent", description: "Generic event binding." },
    { name: "OnSelectionChanged", description: "Occurs when the selection of a selector changes." },
    { name: "OnTextChanged", description: "Occurs when content changes in a TextBox." },
    { name: "OnValueChanged", description: "Occurs when the value of a RangeBase control changes." },
    { name: "OnMouseEnter", description: "Occurs when the mouse pointer enters the bounds of this element." },
    { name: "OnMouseLeave", description: "Occurs when the mouse pointer leaves the bounds of this element." },
    { name: "OnPreviewMouseDown", description: "Occurs when any mouse button is pressed while the pointer is over this element." },
    { name: "OnPreviewMouseUp", description: "Occurs when any mouse button is released while the pointer is over this element." },
    { name: "OnKeyDown", description: "Occurs when a key is pressed while focus is on this element." },
    { name: "OnKeyUp", description: "Occurs when a key is released while focus is on this element." },
    { name: "OnLoaded", description: "Occurs when the element is laid out, rendered, and ready for interaction." }
];

export const RESOURCES: DbItem[] = [
    { name: "BgColor", description: "Window background color.", hex: "#90111114" },
    { name: "SidebarColor", description: "Sidebar background color.", hex: "#30000000" },
    { name: "TextMain", description: "Primary text color (usually white/black).", hex: "#FFFFFF" },
    { name: "TextSub", description: "Secondary text color (muted).", hex: "#AAAAAA" },
    { name: "ControlBg", description: "Background for controls (e.g., textboxes, cards).", hex: "#15FFFFFF" },
    { name: "ControlBorder", description: "Border color for controls.", hex: "#20FFFFFF" },
    { name: "DropdownBg", description: "Background for popups and tooltips.", hex: "#1E1E1E" },
    { name: "Accent", description: "Primary accent color (e.g., blue).", hex: "#0A84FF" },
    { name: "ScrollBarHover", description: "Color when hovering over a scrollbar.", hex: "#0A84FF" },
    { name: "ScrollBarWidth", description: "Width of scrollbars." },
    { name: "ScrollBarRadius", description: "Corner radius of scrollbars." },
    { name: "WindowRadius", description: "Corner radius of the main window." },
    { name: "SolidBg", description: "Solid background variation.", hex: "#202020" },
    { name: "SolidControl", description: "Solid control variation.", hex: "#333333" },
    { name: "SolidBorder", description: "Solid border variation.", hex: "#444444" },
    { name: "ErrorColor", description: "Color for errors and destructive actions.", hex: "#FF4444" }
];

export const ICONS: DbItem[] = [
    { name: "", description: "Source Control / Git (E718)" },
    { name: "", description: "Back / Undo (E72D)" },
    { name: "", description: "Error / Warning (EA39)" },
    { name: "", description: "Folder (E83D)" },
    { name: "", description: "Settings / Gear (E814)" },
    { name: "", description: "Sync / Refresh (E711)" },
    { name: "", description: "Star / Favorite (E13D)" },
    { name: "", description: "Menu / Hamburger (E700)" },
    { name: "", description: "Home (E80F)" },
    { name: "", description: "Checkmark (E73E)" },
    { name: "", description: "Cancel / X (E711)" },
    { name: "", description: "Search / Magnify (E721)" }
];
