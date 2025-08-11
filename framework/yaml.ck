public class YamlNode 
{
    // Static type constants (as functions for ChucK compatibility)
    fun static int TYPE_STRING() { return 0; }
    fun static int TYPE_FLOAT() { return 1; }
    fun static int TYPE_INT() { return 2; }
    fun static int TYPE_ARRAY() { return 3; }
    // Note: reference type removed
    fun static int TYPE_MAP() { return 5; }

    // Type discriminator
    int type; // 0=string, 1=float, 2=int, 3=array, 5=map

    // Name of this node (YAML mapping key)
    string name;

    // Value storage for each type
    string stringValue;
    float floatValue;
    int intValue;
    YamlNode@ arrayValue[]; // used for sequence or map children
    // reference support removed

    // Constructors
    fun YamlNode()
    {
        "" => name;
        -1 => type;
        "" => stringValue;
        0.0 => floatValue;
        0 => intValue;
        YamlNode empty[0];
        empty @=> arrayValue;
        // no reference node
    }

    fun YamlNode(string n)
    {
        n => name;
        -1 => type;
        "" => stringValue;
        0.0 => floatValue;
        0 => intValue;
        YamlNode empty[0];
        empty @=> arrayValue;
        // no reference node
    }

    // Name accessors
    fun void SetName(string n) { n => name; }
    fun string GetName() { return name; }

    // Setters (also set the type)
    fun void SetString(string v)
    {
        TYPE_STRING() => type;
        v => stringValue;
    }

    fun void SetFloat(float v)
    {
        TYPE_FLOAT() => type;
        v => floatValue;
    }

    fun void SetInt(int v)
    {
        TYPE_INT() => type;
        v => intValue;
    }

    fun void SetArray(YamlNode nodes[])
    {
        TYPE_ARRAY() => type;
        nodes @=> arrayValue;
    }

    fun void SetMap(YamlNode nodes[])
    {
        TYPE_MAP() => type;
        nodes @=> arrayValue;
    }

    // Reference support removed: SetNode omitted

    // Accessors (type-checked)
    fun string GetString()
    {
        if (type != TYPE_STRING()) { <<< "YamlNode type mismatch in GetString():", type >>>; }
        return stringValue;
    }

    fun float GetFloat()
    {
        if (type != TYPE_FLOAT()) { <<< "YamlNode type mismatch in GetFloat():", type >>>; }
        return floatValue;
    }

    fun int GetInt()
    {
        if (type != TYPE_INT()) { <<< "YamlNode type mismatch in GetInt():", type >>>; }
        return intValue;
    }

    fun YamlNode[] GetArray()
    {
        if (type != TYPE_ARRAY()) { <<< "YamlNode type mismatch in GetArray():", type >>>; }
        return arrayValue;
    }

    fun YamlNode[] GetMap()
    {
        if (type != TYPE_MAP()) { <<< "YamlNode type mismatch in GetMap():", type >>>; }
        return arrayValue;
    }
    fun YamlNode GetValue(string key)
    {
        if (type != 5) { <<< "Warning: YamlNode type mismatch in GetValue(): not a map, type=", type >>>; }
        for (0 => int i; i < arrayValue.cap(); i++)
        {
            if (arrayValue[i].GetName() == key)
            {
                return arrayValue[i];
            }
        }
        // Return an empty YamlNode if not found
        <<< "Warning: Key '" + key + "' not found in YamlNode map." >>>;
        YamlNode none("");
        return none;
    }

    // Reference support removed: GetNode omitted

    fun int GetType()
    {
        return type;
    }

    // ---------------- map utilities ----------------
    // Set or add a string property on a map node
    fun void SetInt(string key, int value)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: MapSetInt called on non-map YamlNode (type=" + type + ")" >>>;
            return;
        }
        // find existing child with name
        -1 => int foundIdx;
        for (0 => int i; i < arrayValue.cap(); i++)
        {
            if (arrayValue[i].GetName() == key) { i => foundIdx; break; }
        }
        if (foundIdx >= 0)
        {
            arrayValue[foundIdx].SetInt(value);
            return;
        }
        // create a new child
        YamlNode child(key);
        child.SetInt(value);
        arrayValue << child;
    }

    fun void SetString(string key, string value)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: SetString(key, value) called on non-map YamlNode (type=" + type + ")" >>>;
            return;
        }
        // find existing child with name
        -1 => int foundIdx;
        for (0 => int i; i < arrayValue.cap(); i++)
        {
            if (arrayValue[i].GetName() == key) { i => foundIdx; break; }
        }
        if (foundIdx >= 0)
        {
            arrayValue[foundIdx].SetString(value);
            return;
        }
        // create a new child
        YamlNode child(key);
        child.SetString(value);
        arrayValue << child;
    }

    fun void SetFloat(string key, float value)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: MapSetFloat called on non-map YamlNode (type=" + type + ")" >>>;
            return;
        }
        // find existing child with name
        -1 => int foundIdx;
        for (0 => int i; i < arrayValue.cap(); i++)
        {
            if (arrayValue[i].GetName() == key) { i => foundIdx; break; }
        }
        if (foundIdx >= 0)
        {
            arrayValue[foundIdx].SetFloat(value);
            return;
        }
        // create a new child
        YamlNode child(key);
        child.SetFloat(value);
        arrayValue << child;
    }

    fun YamlNode@ SetMap(string key)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: SetMap called on non-map YamlNode (type=" + type + ")" >>>;
            return null;
        }
        // find existing child with name
        -1 => int foundIdx;
        for (0 => int i; i < arrayValue.cap(); i++)
        {
            if (arrayValue[i].GetName() == key) { i => foundIdx; break; }
        }
        if (foundIdx >= 0)
        {
            return arrayValue[foundIdx];
        }
        // create a new child
        YamlNode child(key);
        YamlNode none[0];
        child.SetMap(none);
        arrayValue << child;
        return arrayValue[arrayValue.cap() - 1];
    }

    // ---------------- small string helpers ----------------
    fun static string subToEnd(string s, int start)
    {
        if (start < 0) 0 => start;
        if (start > s.length()) s.length() => start; // clamp to end
        return s.substring(start, s.length() - start);
    }

    fun static string subClamp(string s, int start, int len)
    {
        if (start < 0) 0 => start;
        if (len < 0) 0 => len;
        if (start >= s.length()) return "";
        if (start + len > s.length()) (s.length() - start) => len;
        return s.substring(start, len);
    }

    fun static int indentOf(string s)
    {
        0 => int n;
        for (0 => int i; i < s.length(); i++) {
            if (s.charAt(i) == 32 /*space*/) n++;
            else break;
        }
        return n;
    }

    // ---------------- YAML writer helpers (static) ----------------
    fun static void writeIndent(FileIO @ f, int indent)
    {
        for (0 => int i; i < indent; i++) {
            f.write("  ");
        }
    }

    fun static int isScalar(YamlNode n)
    {
        return (n.GetType() == TYPE_STRING() || n.GetType() == TYPE_FLOAT() || n.GetType() == TYPE_INT());
    }

    fun static string escapeString(string s)
    {
        string out;
        "" => out;
        for (0 => int i; i < s.length(); i++) {
            s.charAt(i) => int ch;
            if (ch == "\"".charAt(0)) {
                out + "'" => out;
            } else {
                out + s.substring(i, 1) => out;
            }
        }
        return "\"" + out + "\"";
    }

    fun static void writeNode(FileIO @ f, YamlNode node, int indent)
    {
        node.GetType() => int t;
        node.GetName() => string nm;
        if (t == TYPE_STRING()) // string
        {
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ": " ); }
            f.write(escapeString(node.GetString()) + "\n");
        }
        else if (t == TYPE_FLOAT()) // float
        {
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ": " ); }
            f.write(("" + node.GetFloat()) + "\n");
        }
        else if (t == TYPE_INT()) // int
        {
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ": " ); }
            f.write(("" + node.GetInt()) + "\n");
        }
        else if (t == TYPE_ARRAY()) // array (sequence)
        {
            YamlNode items[0];
            node.GetArray() @=> items;
            if (items == null || items.cap() == 0)
            {
                writeIndent(f, indent);
                if (nm != "") { f.write(nm + ": []\n"); }
                else { f.write("[]\n"); }
                return;
            }
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ":\n"); }
            for (0 => int i; i < items.cap(); i++)
            {
                writeIndent(f, indent + (nm != "" ? 1 : 0));
                f.write("- ");
                if (isScalar(items[i]))
                {
                    if (items[i].GetType() == TYPE_STRING()) {
                        f.write(escapeString(items[i].GetString()) + "\n");
                    } else if (items[i].GetType() == TYPE_FLOAT()) {
                        f.write(("" + items[i].GetFloat()) + "\n");
                    } else { // int
                        f.write(("" + items[i].GetInt()) + "\n");
                    }
                }
                else if (items[i].GetType() == TYPE_MAP())
                {
                    // Try to inline the first property of the map on the same line as the dash
                    YamlNode mapKids[0];
                    items[i].GetMap() @=> mapKids;
                    if (mapKids != null && mapKids.cap() > 0 && mapKids[0].GetName() != "" && (mapKids[0].GetType() == TYPE_STRING() || mapKids[0].GetType() == TYPE_INT() || mapKids[0].GetType() == TYPE_FLOAT()))
                    {
                        // Write "- key: value" inline
                        f.write(mapKids[0].GetName() + ": ");
                        if (mapKids[0].GetType() == TYPE_STRING()) {
                            f.write(escapeString(mapKids[0].GetString()) + "\n");
                        } else if (mapKids[0].GetType() == TYPE_FLOAT()) {
                            f.write(("" + mapKids[0].GetFloat()) + "\n");
                        } else { // int
                            f.write(("" + mapKids[0].GetInt()) + "\n");
                        }
                        // Write the remaining properties as usual, indented under this item
                        int childIndent;
                        indent + (nm != "" ? 2 : 1) => childIndent;
                        for (1 => int mi; mi < mapKids.cap(); mi++)
                        {
                            writeNode(f, mapKids[mi], childIndent);
                        }
                    }
                    else
                    {
                        // Fallback: write map on the next line as before
                        f.write("\n");
                        writeNode(f, items[i], indent + (nm != "" ? 2 : 1));
                    }
                }
                else
                {
                    // Non-scalar, non-map (e.g., nested array): keep previous formatting
                    f.write("\n");
                    writeNode(f, items[i], indent + (nm != "" ? 2 : 1));
                }
            }
        }
        else if (t == TYPE_MAP()) // map (object)
        {
            YamlNode items[0];
            node.GetMap() @=> items;
            if (nm != "") {
                writeIndent(f, indent);
                f.write(nm + ":\n");
            }
            int childIndent;
            indent + (nm != "" ? 1 : 0) => childIndent;
            for (0 => int i; i < items.cap(); i++)
            {
                writeNode(f, items[i], childIndent);
            }
        }
        // reference type removed
        else
        {
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ": null\n"); }
            else { f.write("null\n"); }
        }
    }

    // Instance writer: write this node to file
    fun void WriteFile(string filename)
    {
        FileIO fout;
        fout.open(filename, FileIO.WRITE);
        writeNode(fout, this, 0);
    }

    // ---------------- Minimal YAML reader (static) ----------------
    fun static string trimRight(string s)
    {
        int end;
        s.length() - 1 => end;
        while (end >= 0)
        {
            s.charAt(end) => int ch;
            if (ch == 10 || ch == 13 || ch == 32 || ch == 9) { end--; }
            else { break; }
        }
        if (end < 0) return "";
        return s.substring(0, end+1);
    }

    fun static string trimLeft(string s)
    {
        int i;
        0 => i;
        while (i < s.length())
        {
            s.charAt(i) => int ch;
            if (ch == 32 || ch == 9) { i++; }
            else { break; }
        }
        return subClamp(s, i, s.length() - i);
    }

    fun static string stripOuterQuotes(string s)
    {
        if (s.length() >= 2 && s.charAt(0) == "\"".charAt(0) && s.charAt(s.length()-1) == "\"".charAt(0))
        {
            subClamp(s, 1, s.length()-2) => string inner;
            inner.replace("'", "\"");
            return inner;
        }
        return s;
    }

    fun static int indexOf(string s, string needle)
    {
        for (0 => int i; i <= s.length() - needle.length(); i++)
        {
            if (s.substring(i, needle.length()) == needle) return i;
        }
        return -1;
    }

    // ---- Inline flow sequence support: [1, 2, 3] ----
    fun static int isInlineArrayToken(string token)
    {
        trimLeft(trimRight(token)) => string t;
        if (t.length() >= 2 && t.charAt(0) == "[".charAt(0) && t.charAt(t.length()-1) == "]".charAt(0)) return 1;
        return 0;
    }

    fun static YamlNode[] parseInlineArrayItems(string token)
    {
        YamlNode items[0];
        trimLeft(trimRight(token)) => string t;
        if (t.length() < 2) return items;
        // strip outer brackets
        subClamp(t, 1, t.length()-2) => string inner;
        // split on commas (minimal: no nested arrays or quoted commas)
        string cur;
        "" => cur;
        for (0 => int i; i < inner.length(); i++)
        {
            inner.charAt(i) => int ch;
            if (ch == ",".charAt(0))
            {
                trimLeft(trimRight(cur)) => string tok;
                if (tok.length() > 0 || cur.length() > 0)
                {
                    parseScalarNodeWithName("", tok) @=> YamlNode n;
                    items << n;
                }
                "" => cur;
            }
            else
            {
                cur + inner.substring(i, 1) => cur;
            }
        }
        trimLeft(trimRight(cur)) => string lastTok;
        if (lastTok.length() > 0 || cur.length() > 0)
        {
            parseScalarNodeWithName("", lastTok) @=> YamlNode n2;
            items << n2;
        }
        return items;
    }

    fun static YamlNode parseInlineArrayNodeWithName(string key, string token)
    {
        parseInlineArrayItems(token) @=> YamlNode elems[];
        YamlNode arrNode(key);
        arrNode.SetArray(elems);
        return arrNode;
    }

    // Construct a named scalar node from a token string
    fun static YamlNode parseScalarNodeWithName(string nameToken, string token)
    {
        trimLeft(trimRight(token)) => token;
        YamlNode n(nameToken);
        if (token.length() == 0 || token == "null")
        {
            n.SetString("");
            return n;
        }
        if (token.length() >= 1 && token.charAt(0) == "\"".charAt(0))
        {
            stripOuterQuotes(token) => string sv;
            n.SetString(sv);
            return n;
        }
        Std.atoi(token) => int iv;
        Std.itoa(iv) => string ivs;
        if (ivs == token)
        {
            n.SetInt(iv);
            return n;
        }
        Std.atof(token) => float fv;
        if (token.find(".") >= 0 || token.find("e") >= 0 || token.find("E") >= 0)
        {
            n.SetFloat(fv);
            return n;
        }
        n.SetString(token);
        return n;
    }

    fun static int findNextSiblingIdx(string lines[], int startIdx, int baseIndent)
    {
        for (startIdx => int t; t < lines.cap(); t++)
        {
            trimLeft(lines[t]) => string lt;
            if (lt.length() == 0 || lt.charAt(0) == '#') { continue; }
            indentOf(lines[t]) => int ind;
            if (ind <= baseIndent) return t;
        }
        return lines.cap();
    }

    // Parse map children starting at startIdx with expected indent
    fun static YamlNode[] parseMapChildren(string lines[], int startIdx, int baseIndent)
    {
        YamlNode children[0];
        startIdx => int i;
        0 => int safety;
        while (i < lines.cap())
        {
            if (safety > lines.cap() * 4) { break; }
            safety++;
            trimLeft(lines[i]) => string l;
            if (l.length() == 0 || l.charAt(0) == '#') { i++; continue; }
            indentOf(lines[i]) => int curIndent;
            if (curIndent < baseIndent) break;
            if (curIndent > baseIndent) { i++; continue; }
            indexOf(l, ":") => int colon;
            if (colon < 0) break;
            if (colon + 1 >= l.length())
            {
                trimRight(subClamp(l, 0, colon)) => string key;
                "" => string rest;
                // look ahead to determine sequence or map
                i+1 => int j;
                while (j < lines.cap())
                {
                    trimLeft(lines[j]) => string l2;
                    if (l2.length() == 0 || l2.charAt(0) == '#') { j++; continue; }
                    break;
                }
                if (j >= lines.cap())
                {
                    YamlNode emptyMap(key);
                    YamlNode none[0];
                    emptyMap.SetMap(none);
                    children << emptyMap;
                    break;
                }
                indentOf(lines[j]) => int childIndent;
                subClamp(trimLeft(lines[j]), 0, 1) => string pref;
                if (pref == "-")
                {
                    YamlNode items[0];
                    int k;
                    for (j => k; k < lines.cap(); k++)
                    {
                        trimLeft(lines[k]) => string l3;
                        if (l3.length() == 0 || l3.charAt(0) == '#') { continue; }
                        if (indentOf(lines[k]) != childIndent) { break; }
                        if (subClamp(l3, 0, 1) != "-") { break; }
                        // token after dash (if present)
                        string tok;
                        "" => tok;
                        if (l3.length() >= 2 && subClamp(l3, 0, 2) == "- ") { subToEnd(l3, 2) => tok; }
                        trimLeft(trimRight(tok)) => tok;
                        if (tok.length() == 0)
                        {
                            // parse nested map for this array item
                            int m; int start;
                            k+1 => m; k+1 => start;
                            while (m < lines.cap())
                            {
                                trimLeft(lines[m]) => string l5;
                                if (l5.length() == 0 || l5.charAt(0) == '#') { m++; start++; continue; }
                                break;
                            }
                            if (m < lines.cap())
                            {
                                indentOf(lines[m]) => int nestedIndent;
                                parseMapChildren(lines, m, nestedIndent) @=> YamlNode nestedKids[];
                                YamlNode mapItem("");
                                mapItem.SetMap(nestedKids);
                                items << mapItem;
                                // advance k past this nested block
                                int u;
                                for (m => u; u < lines.cap(); u++)
                                {
                                    trimLeft(lines[u]) => string l6;
                                    if (l6.length() == 0 || l6.charAt(0) == '#') { continue; }
                                    if (indentOf(lines[u]) <= childIndent) { break; }
                                }
                                if (u > k) { u-1 => k; }
                            }
                            else
                            {
                                YamlNode emptyItem("");
                                emptyItem.SetString("");
                                items << emptyItem;
                            }
                        }
                        else
                        {
                            // If the token contains a colon, this item is a map starting inline: "- key: value"
                            if (indexOf(tok, ":") >= 0)
                            {
                                indexOf(tok, ":") => int c2;
                                trimRight(subClamp(tok, 0, c2)) => string ikey;
                                trimLeft(subClamp(tok, c2+1, tok.length() - (c2+1))) => string irest;
                                parseScalarNodeWithName(ikey, irest) @=> YamlNode firstChild;
                                // collect additional map properties indented under this dash item
                                int m; k+1 => m;
                                while (m < lines.cap())
                                {
                                    trimLeft(lines[m]) => string l7;
                                    if (l7.length() == 0 || l7.charAt(0) == '#') { m++; continue; }
                                    break;
                                }
                                YamlNode children[0];
                                children << firstChild;
                                if (m < lines.cap())
                                {
                                    indentOf(lines[m]) => int nestedIndent;
                                    parseMapChildren(lines, m, nestedIndent) @=> YamlNode restKids[];
                                    for (0 => int ri; ri < restKids.cap(); ri++) { children << restKids[ri]; }
                                    // advance k past the nested block belonging to this item
                                    int u;
                                    for (m => u; u < lines.cap(); u++)
                                    {
                                        trimLeft(lines[u]) => string l8;
                                        if (l8.length() == 0 || l8.charAt(0) == '#') { continue; }
                                        if (indentOf(lines[u]) <= childIndent) { break; }
                                    }
                                    if (u > k) { u-1 => k; }
                                }
                                YamlNode mapItem("");
                                mapItem.SetMap(children);
                                items << mapItem;
                            }
                            else
                            {
                                // plain scalar array item
                                YamlNode item("");
                                if (tok == "null") { item.SetString(""); }
                                else if (tok.length() >= 1 && tok.charAt(0) == "\"".charAt(0)) { item.SetString(stripOuterQuotes(tok)); }
                                else {
                                    Std.atoi(tok) => int iv; Std.itoa(iv) => string ivs;
                                    if (ivs == tok) { item.SetInt(iv); }
                                    else { Std.atof(tok) => float fv; if (tok.find(".") >= 0 || tok.find("e") >= 0 || tok.find("E") >= 0) { item.SetFloat(fv); } else { item.SetString(tok); } }
                                }
                                items << item;
                            }
                        }
                    }
                    YamlNode arrNode(key);
                    arrNode.SetArray(items);
                    children << arrNode;
                    // advance to next sibling at indent <= baseIndent
                    int t;
                    for (k => t; t < lines.cap(); t++)
                    {
                        trimLeft(lines[t]) => string l4;
                        if (l4.length() == 0 || l4.charAt(0) == '#') { continue; }
                        if (indentOf(lines[t]) <= baseIndent) { break; }
                    }
                    if (t <= i) { i + 1 => t; }
                    t => i;
                    continue;
                }
                else
                {
                    parseMapChildren(lines, j, childIndent) @=> YamlNode nestedChildren[];
                    YamlNode mapNode(key);
                    mapNode.SetMap(nestedChildren);
                    children << mapNode;
                    // advance to next sibling at indent <= baseIndent
                    int t;
                    for (j => t; t < lines.cap(); t++)
                    {
                        trimLeft(lines[t]) => string l4;
                        if (l4.length() == 0 || l4.charAt(0) == '#') { continue; }
                        if (indentOf(lines[t]) <= baseIndent) { break; }
                    }
                    if (t <= i) { i + 1 => t; }
                    t => i;
                    continue;
                }
            }
            trimRight(subClamp(l, 0, colon)) => string key;
            trimLeft(subClamp(l, colon+1, l.length() - (colon+1))) => string rest;
            if (rest == "[]")
            {
                YamlNode emptyArr(key);
                YamlNode elems[0];
                emptyArr.SetArray(elems);
                children << emptyArr;
                i++;
                continue;
            }
            if (rest.length() > 0)
            {
                // inline value parsing for key: value
                trimLeft(trimRight(rest)) => rest;
                if (isInlineArrayToken(rest))
                {
                    parseInlineArrayNodeWithName(key, rest) @=> YamlNode arrNode;
                    children << arrNode;
                    i++;
                    continue;
                }
                YamlNode scalar(key);
                if (rest.length() == 0 || rest == "null") { scalar.SetString(""); }
                else if (rest.length() >= 1 && rest.charAt(0) == "\"".charAt(0)) { scalar.SetString(stripOuterQuotes(rest)); }
                else {
                    Std.atoi(rest) => int iv; Std.itoa(iv) => string ivs;
                    if (ivs == rest) { scalar.SetInt(iv); }
                    else { Std.atof(rest) => float fv; if (rest.find(".") >= 0 || rest.find("e") >= 0 || rest.find("E") >= 0) { scalar.SetFloat(fv); } else { scalar.SetString(rest); } }
                }
                children << scalar;
                i++;
                continue;
            }
            // rest empty: need to look ahead
            i+1 => int j;
            while (j < lines.cap())
            {
                trimLeft(lines[j]) => string l2;
                if (l2.length() == 0 || l2.charAt(0) == '#') { j++; continue; }
                break;
            }
            if (j >= lines.cap())
            {
                YamlNode emptyMap(key);
                YamlNode none[0];
                emptyMap.SetMap(none);
                children << emptyMap;
                break;
            }
            indentOf(lines[j]) => int childIndent;
            subClamp(trimLeft(lines[j]), 0, 1) => string pref1;
            if (pref1 == "-")
            {
                YamlNode items[0];
                int k;
                for (j => k; k < lines.cap(); k++)
                {
                    trimLeft(lines[k]) => string l3;
                    if (l3.length() == 0 || l3.charAt(0) == '#') { continue; }
                    if (indentOf(lines[k]) != childIndent) { break; }
                    if (subClamp(l3, 0, 1) != "-") { break; }
                    // extract token after dash (support "-" or "- ")
                    trimLeft(l3) => string tl3;
                    "" => string tok;
                    if (tl3.length() >= 2 && subClamp(tl3, 0, 2) == "- ") { subToEnd(tl3, 2) => tok; }
                    else { "" => tok; }
                    trimLeft(trimRight(tok)) => tok;
                    if (tok.length() == 0)
                    {
                        // nested map under this dash item
                        int m; k+1 => m;
                        while (m < lines.cap())
                        {
                            trimLeft(lines[m]) => string l5;
                            if (l5.length() == 0 || l5.charAt(0) == '#') { m++; continue; }
                            break;
                        }
                        if (m < lines.cap())
                        {
                            indentOf(lines[m]) => int nestedIndent;
                            parseMapChildren(lines, m, nestedIndent) @=> YamlNode nestedKids[];
                            YamlNode mapItem("");
                            mapItem.SetMap(nestedKids);
                            items << mapItem;
                            // advance k past nested block
                            int u;
                            for (m => u; u < lines.cap(); u++)
                            {
                                trimLeft(lines[u]) => string l6;
                                if (l6.length() == 0 || l6.charAt(0) == '#') { continue; }
                                if (indentOf(lines[u]) <= childIndent) { break; }
                            }
                            if (u > k) { u-1 => k; }
                        }
                        else
                        {
                            YamlNode emptyItem("");
                            emptyItem.SetString("");
                            items << emptyItem;
                        }
                    }
                    // (duplicate inline map handlers removed)
                    // (duplicate inline map handlers removed)
                    // (duplicate inline map handlers removed)
                    else if (indexOf(tok, ":") >= 0)
                    {
                        // inline key: value on same line as dash
                        indexOf(tok, ":") => int c2;
                        trimRight(subClamp(tok, 0, c2)) => string ikey;
                        trimLeft(subClamp(tok, c2+1, tok.length() - (c2+1))) => string irest;
                        parseScalarNodeWithName(ikey, irest) @=> YamlNode firstChild;
                        // collect additional properties indented under this item
                        int m; k+1 => m;
                        while (m < lines.cap())
                        {
                            trimLeft(lines[m]) => string l7;
                            if (l7.length() == 0 || l7.charAt(0) == '#') { m++; continue; }
                            break;
                        }
                        YamlNode children[0];
                        children << firstChild;
                        if (m < lines.cap())
                        {
                            indentOf(lines[m]) => int nestedIndent;
                            parseMapChildren(lines, m, nestedIndent) @=> YamlNode restKids[];
                            for (0 => int ri; ri < restKids.cap(); ri++) { children << restKids[ri]; }
                            // advance k past this nested block
                            int u;
                            for (m => u; u < lines.cap(); u++)
                            {
                                trimLeft(lines[u]) => string l8;
                                if (l8.length() == 0 || l8.charAt(0) == '#') { continue; }
                                if (indentOf(lines[u]) <= childIndent) { break; }
                            }
                            if (u > k) { u-1 => k; }
                        }
                        YamlNode mapItem("");
                        mapItem.SetMap(children);
                        items << mapItem;
                    }
                    else if (indexOf(tok, ":") >= 0)
                    {
                        // inline key: value on same line as dash
                        indexOf(tok, ":") => int c2;
                        trimRight(subClamp(tok, 0, c2)) => string ikey;
                        trimLeft(subClamp(tok, c2+1, tok.length() - (c2+1))) => string irest;
                        parseScalarNodeWithName(ikey, irest) @=> YamlNode firstChild;
                        // collect additional properties indented under this item
                        int m; k+1 => m;
                        while (m < lines.cap())
                        {
                            trimLeft(lines[m]) => string l7;
                            if (l7.length() == 0 || l7.charAt(0) == '#') { m++; continue; }
                            break;
                        }
                        YamlNode children[0];
                        children << firstChild;
                        if (m < lines.cap())
                        {
                            indentOf(lines[m]) => int nestedIndent;
                            parseMapChildren(lines, m, nestedIndent) @=> YamlNode restKids[];
                            for (0 => int ri; ri < restKids.cap(); ri++) { children << restKids[ri]; }
                            // advance k past this nested block
                            int u;
                            for (m => u; u < lines.cap(); u++)
                            {
                                trimLeft(lines[u]) => string l8;
                                if (l8.length() == 0 || l8.charAt(0) == '#') { continue; }
                                if (indentOf(lines[u]) <= childIndent) { break; }
                            }
                            if (u > k) { u-1 => k; }
                        }
                        YamlNode mapItem("");
                        mapItem.SetMap(children);
                        items << mapItem;
                    }
                    else if (indexOf(tok, ":") >= 0)
                    {
                        indexOf(tok, ":") => int c2;
                        trimRight(subClamp(tok, 0, c2)) => string ikey;
                        trimLeft(subClamp(tok, c2+1, tok.length() - (c2+1))) => string irest;
                        parseScalarNodeWithName(ikey, irest) @=> YamlNode firstChild;
                        int m; k+1 => m;
                        while (m < lines.cap())
                        {
                            trimLeft(lines[m]) => string l7;
                            if (l7.length() == 0 || l7.charAt(0) == '#') { m++; continue; }
                            break;
                        }
                        YamlNode children[0];
                        children << firstChild;
                        if (m < lines.cap())
                        {
                            indentOf(lines[m]) => int nestedIndent;
                            parseMapChildren(lines, m, nestedIndent) @=> YamlNode restKids[];
                            for (0 => int ri; ri < restKids.cap(); ri++) { children << restKids[ri]; }
                            int u;
                            for (m => u; u < lines.cap(); u++)
                            {
                                trimLeft(lines[u]) => string l8;
                                if (l8.length() == 0 || l8.charAt(0) == '#') { continue; }
                                if (indentOf(lines[u]) <= childIndent) { break; }
                            }
                            if (u > k) { u-1 => k; }
                        }
                        YamlNode mapItem("");
                        mapItem.SetMap(children);
                        items << mapItem;
                    }
                    else
                    {
                        YamlNode item("");
                        if (tok == "null") { item.SetString(""); }
                        else if (tok.length() >= 1 && tok.charAt(0) == "\"".charAt(0)) { item.SetString(stripOuterQuotes(tok)); }
                        else {
                            Std.atoi(tok) => int iv; Std.itoa(iv) => string ivs;
                            if (ivs == tok) { item.SetInt(iv); }
                            else { Std.atof(tok) => float fv; if (tok.find(".") >= 0 || tok.find("e") >= 0 || tok.find("E") >= 0) { item.SetFloat(fv); } else { item.SetString(tok); } }
                        }
                        items << item;
                    }
                }
                YamlNode arrNode(key);
                arrNode.SetArray(items);
                children << arrNode;
                int t;
                for (k => t; t < lines.cap(); t++)
                {
                    trimLeft(lines[t]) => string l4;
                    if (l4.length() == 0 || l4.charAt(0) == '#') { continue; }
                    if (indentOf(lines[t]) <= baseIndent) { break; }
                }
                if (t <= i) { i + 1 => t; }
                t => i;
                continue;
            }
            else
            {
                // nested map
                parseMapChildren(lines, j, childIndent) @=> YamlNode nestedChildren[];
                YamlNode mapNode(key);
                mapNode.SetMap(nestedChildren);
                children << mapNode;
                int t;
                for (j => t; t < lines.cap(); t++)
                {
                    trimLeft(lines[t]) => string l4;
                    if (l4.length() == 0 || l4.charAt(0) == '#') { continue; }
                    if (indentOf(lines[t]) <= baseIndent) { break; }
                }
                if (t <= i) { i + 1 => t; }
                t => i;
                continue;
            }
        }
        return children;
    }

    // Static: parse a file into a YamlNode
    fun static YamlNode ParseFile(string filename)
    {
        string lines[0];
        FileIO fin;
        fin.open(filename, FileIO.READ);
        while (fin.more())
        {
            fin.readLine() => string line;
            trimRight(line) => line;
            lines << line;
        }

        -1 => int firstIdx;
        for (0 => int i; i < lines.cap(); i++)
        {
            trimLeft(lines[i]) => string l;
            if (l.length() == 0) continue;
            if (l.charAt(0) == '#') continue;
            i => firstIdx; break;
        }
        if (firstIdx == -1)
        {
            return new YamlNode("");
        }

        trimLeft(lines[firstIdx]) => string first;
        indexOf(first, ":") => int colon;
        if (colon >= 0)
        {
            // Treat the document as a top-level map that may have multiple keys.
            // Parse all mapping entries at the base indentation.
            int baseIndent; indentOf(lines[firstIdx]) => baseIndent;
            parseMapChildren(lines, firstIdx, baseIndent) @=> YamlNode topChildren[];
            if (topChildren.cap() == 1)
            {
                // Single top-level key: return it directly to preserve previous behavior
                return topChildren[0];
            }
            // Multiple top-level keys: return an anonymous map node containing them
            YamlNode root("");
            root.SetMap(topChildren);
            return root;
        }
        // Fallback to unnamed sequence or scalar
        0 => int hasDash;
        for (firstIdx => int i; i < lines.cap(); i++)
        {
            trimLeft(lines[i]) => string l;
            if (l.length() == 0) continue;
            if (l.charAt(0) == '#') continue;
            if (l.length() >= 1 && subClamp(l, 0, 1) == "-") { 1 => hasDash; break; }
            else { break; }
        }
        YamlNode root("");
        if (hasDash)
        {
            YamlNode items[0];
            int baseIndent; indentOf(lines[firstIdx]) => baseIndent;
            for (firstIdx => int i; i < lines.cap(); i++)
            {
                trimLeft(lines[i]) => string l;
                if (l.length() == 0) continue;
                if (l.charAt(0) == '#') continue;
                if (l.length() >= 1 && subClamp(l, 0, 1) == "-")
                {
                    subToEnd(trimLeft(lines[i]), 1) => string itemTokRaw;
                    trimLeft(trimRight(itemTokRaw)) => string itemTok;
                    if (itemTok.length() == 0)
                    {
                        int m; i+1 => m;
                        while (m < lines.cap())
                        {
                            trimLeft(lines[m]) => string l2;
                            if (l2.length() == 0 || l2.charAt(0) == '#') { m++; continue; }
                            break;
                        }
                        if (m < lines.cap())
                        {
                            indentOf(lines[m]) => int nestedIndent;
                            parseMapChildren(lines, m, nestedIndent) @=> YamlNode kids[];
                            YamlNode mapItem("");
                            mapItem.SetMap(kids);
                            items << mapItem;
                            int u;
                            for (m => u; u < lines.cap(); u++)
                            {
                                trimLeft(lines[u]) => string l3;
                                if (l3.length() == 0 || l3.charAt(0) == '#') { continue; }
                                if (indentOf(lines[u]) <= baseIndent) { break; }
                            }
                            if (u > i) { u-1 => i; }
                        }
                        else
                        {
                            YamlNode emptyItem("");
                            emptyItem.SetString("");
                            items << emptyItem;
                        }
                    }
                    else if (indexOf(itemTok, ":") >= 0)
                    {
                        indexOf(itemTok, ":") => int c2;
                        trimRight(subClamp(itemTok, 0, c2)) => string ikey;
                        trimLeft(subClamp(itemTok, c2+1, itemTok.length() - (c2+1))) => string irest;
                        parseScalarNodeWithName(ikey, irest) @=> YamlNode firstChild;
                        int m; i+1 => m;
                        while (m < lines.cap())
                        {
                            trimLeft(lines[m]) => string l2;
                            if (l2.length() == 0 || l2.charAt(0) == '#') { m++; continue; }
                            break;
                        }
                        YamlNode children[0];
                        children << firstChild;
                        if (m < lines.cap())
                        {
                            indentOf(lines[m]) => int nestedIndent;
                            parseMapChildren(lines, m, nestedIndent) @=> YamlNode rest[];
                            for (0 => int ri; ri < rest.cap(); ri++) { children << rest[ri]; }
                            int u;
                            for (m => u; u < lines.cap(); u++)
                            {
                                trimLeft(lines[u]) => string l3;
                                if (l3.length() == 0 || l3.charAt(0) == '#') { continue; }
                                if (indentOf(lines[u]) <= baseIndent) { break; }
                            }
                            if (u > i) { u-1 => i; }
                        }
                        YamlNode mapItem("");
                        mapItem.SetMap(children);
                        items << mapItem;
                    }
                    else if (indexOf(itemTok, ":") >= 0)
                    {
                        indexOf(itemTok, ":") => int c2;
                        trimRight(subClamp(itemTok, 0, c2)) => string ikey;
                        trimLeft(subClamp(itemTok, c2+1, itemTok.length() - (c2+1))) => string irest;
                        parseScalarNodeWithName(ikey, irest) @=> YamlNode firstChild;
                        int m; i+1 => m;
                        while (m < lines.cap())
                        {
                            trimLeft(lines[m]) => string l2;
                            if (l2.length() == 0 || l2.charAt(0) == '#') { m++; continue; }
                            break;
                        }
                        YamlNode children[0];
                        children << firstChild;
                        if (m < lines.cap())
                        {
                            indentOf(lines[m]) => int nestedIndent;
                            parseMapChildren(lines, m, nestedIndent) @=> YamlNode restKids[];
                            for (0 => int ri; ri < restKids.cap(); ri++) { children << restKids[ri]; }
                            int u;
                            for (m => u; u < lines.cap(); u++)
                            {
                                trimLeft(lines[u]) => string l3;
                                if (l3.length() == 0 || l3.charAt(0) == '#') { continue; }
                                if (indentOf(lines[u]) <= baseIndent) { break; }
                            }
                            if (u > i) { u-1 => i; }
                        }
                        YamlNode mapItem("");
                        mapItem.SetMap(children);
                        items << mapItem;
                    }
                    else
                    {
                        YamlNode itemNode("");
                        if (itemTok == "null") { itemNode.SetString(""); }
                        else if (itemTok.length() >= 1 && itemTok.charAt(0) == "\"".charAt(0)) { itemNode.SetString(stripOuterQuotes(itemTok)); }
                        else {
                            Std.atoi(itemTok) => int iv; Std.itoa(iv) => string ivs;
                            if (ivs == itemTok) { itemNode.SetInt(iv); }
                            else { Std.atof(itemTok) => float fv; if (itemTok.find(".") >= 0 || itemTok.find("e") >= 0 || itemTok.find("E") >= 0) { itemNode.SetFloat(fv); } else { itemNode.SetString(itemTok); } }
                        }
                        items << itemNode;
                    }
                }
            }
            root.SetArray(items);
        }
        else
        {
            parseScalarNodeWithName("", trimLeft(lines[firstIdx])) @=> YamlNode n;
            return n;
        }
        return root;
    }
}
