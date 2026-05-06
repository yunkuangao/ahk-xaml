class XAMLElement {
    __New(tag, textContent := "") {
        this._Tag := tag
        this._Props := Map()
        this._Children := []
        this._TextContent := textContent
        this._Parent := ""
        this._Defaults := Map()
        try this._AhkLine := Error("", -1).Line
    }

    ; Sets default properties for a specific tag within this element's scope.
    ; Children added to this element (or its descendants) will inherit these cascading properties.
    SetDefaults(tag, propsObj) {
        this._Defaults[tag] := propsObj
        return this
    }

    ; Instantly apply a map or object of properties to this specific element
    Apply(propsObj) {
        try this._AhkLine := Error("", -1).Line
        for k, v in (Type(propsObj) == "Map" ? propsObj : propsObj.OwnProps()) {
            propName := StrReplace(k, "_", ".")
            this._Props[propName] := v
        }
        return this
    }

    ; Define a named template at the root level so it can be reused anywhere
    DefineTemplate(name, templateObjOrFunc) {
        root := this
        while root._Parent
            root := root._Parent
        
        if !root.HasProp("_Templates")
            root._Templates := Map()
            
        root._Templates[name] := templateObjOrFunc
        return this
    }

    ; Apply a template. Can be a string (named template), an object of properties, or a callback function.
    Use(template) {
        try this._AhkLine := Error("", -1).Line
        if (Type(template) == "String") {
            root := this
            while root._Parent
                root := root._Parent
                
            if (root.HasProp("_Templates") && root._Templates.Has(template)) {
                template := root._Templates[template]
            } else {
                throw Error("Template not found: " template)
            }
        }
        
        if HasMethod(template) {
            template(this)
        } else {
            this.Apply(template)
        }
        return this
    }

    ; Add a child element and return the child for chaining
    Add(tag, textContent := "") {
        child := XAMLElement(tag, textContent)
        try child._AhkLine := Error("", -1).Line
        child._Parent := this
        
        ; Collect inheritance path (from Root down to this node)
        parents := []
        curr := this
        while curr {
            parents.InsertAt(1, curr)
            curr := curr._Parent
        }
        
        ; Apply defaults top-down (CSS-style cascading)
        for p in parents {
            if p._Defaults.Has(tag) {
                defObj := p._Defaults[tag]
                if (defObj == "" || defObj == false) {
                    child._Props.Clear() ; Firewall: reset accumulated defaults
                } else {
                    for k, v in (Type(defObj) == "Map" ? defObj : defObj.OwnProps()) {
                        propName := StrReplace(k, "_", ".")
                        child._Props[propName] := v
                    }
                }
            }
        }
        
        this._Children.Push(child)
        return child
    }

    ; Navigate back to the parent element
    Parent() {
        return this._Parent
    }

    ; Intercept unknown methods to dynamically set properties
    __Call(name, params) {
        try this._AhkLine := Error("", -1).Line
        ; Convert underscores in method names to dots (e.g. Grid_Column -> Grid.Column)
        propName := StrReplace(name, "_", ".")
        
        if (params.Length == 1) {
            this._Props[propName] := params[1]
            return this
        } else if (params.Length == 0) {
            ; For booleans without parameters, default to "True"
            this._Props[propName] := "True"
            return this
        }
        throw Error("Method " name " requires 0 or 1 parameters.")
    }

    ; Explicitly set a property if method interception isn't ideal
    SetProp(name, value) {
        try this._AhkLine := Error("", -1).Line
        this._Props[name] := value
        return this
    }

    ; ==========================================
    ; SHORTHAND BUILDERS
    ; ==========================================

    Cols(widths*) {
        cols := XAMLElement("Grid.ColumnDefinitions")
        for w in widths
            cols.Add("ColumnDefinition").Width(w)
        this._Children.InsertAt(1, cols) ; Insert layout definitions at the top
        return this
    }

    Rows(heights*) {
        rows := XAMLElement("Grid.RowDefinitions")
        for h in heights
            rows.Add("RowDefinition").Height(h)
        this._Children.InsertAt(1, rows)
        return this
    }

    ; Inject raw XAML resources into this element
    InjectResources(rawXamlString) {
        res := XAMLElement(this._Tag ".Resources")
        res._TextContent := rawXamlString
        this._Children.InsertAt(1, res)
        return this
    }

    ; Generate XAML string recursively
    ToString(indent := "") {
        attrStr := ""
        for k, v in this._Props
            attrStr .= ' ' k '="' v '"'
        
        tracker := (this.HasProp("_AhkLine") && this._AhkLine != "") ? "<!-- [ahk:" this._AhkLine "] -->" : ""
        
        if (this._Children.Length == 0 && this._TextContent == "")
            return indent tracker "<" this._Tag attrStr " />`n"
        
        out := indent tracker "<" this._Tag attrStr ">"
        
        if (this._TextContent != "") {
            out .= this._TextContent
        } else {
            out .= "`n"
            for child in this._Children
                out .= child.ToString(indent "    ")
            out .= indent
        }
        out .= "</" this._Tag ">`n"
        return out
    }
}

class XAML_Generator extends XAMLElement {
    __New(tag := "Grid") {
        super.__New(tag)
        try this._AhkLine := Error("", -1).Line
    }

    Compile() {
        return this.ToString("")
    }
}
