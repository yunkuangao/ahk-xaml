class XAMLElement {
    __New(tag, textContent := "") {
        this._Tag := tag
        this._Props := Map()
        this._Children := []
        this._TextContent := textContent
        this._Parent := ""
        this._Defaults := Map()
    }

    ; Sets default properties for a specific tag within this element's scope.
    ; Children added to this element (or its descendants) will inherit these cascading properties.
    SetDefaults(tag, propsObj) {
        this._Defaults[tag] := propsObj
        return this
    }

    ; Instantly apply a map or object of properties to this specific element
    Apply(propsObj) {
        for k, v in (Type(propsObj) == "Map" ? propsObj : propsObj.OwnProps())
            this._Props[k] := v
        return this
    }

    ; Add a child element and return the child for chaining
    Add(tag, textContent := "") {
        child := XAMLElement(tag, textContent)
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
                    for k, v in (Type(defObj) == "Map" ? defObj : defObj.OwnProps())
                        child._Props[k] := v
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
        
        if (this._Children.Length == 0 && this._TextContent == "")
            return indent "<" this._Tag attrStr " />`n"
        
        out := indent "<" this._Tag attrStr ">"
        
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
    }

    Compile() {
        return this.ToString("")
    }
}
