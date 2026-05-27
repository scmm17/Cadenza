// YamlNode is a class that represents a node in a YAML document.
// It contains the name, type, and value of the node.
// It can read and write YAML files for configuration and data storage.
//
// This class is used to create YAML nodes for YAML documents.
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
        if (type != TYPE_MAP()) { <<< "Warning: YamlNode type mismatch in GetValue(): not a map, type=", type >>>; }
        findChild(key) => int foundIdx;
        if (foundIdx >= 0)
        {
            return arrayValue[foundIdx];
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

    // Find the index of a child node by name, or -1 if not found.
    fun int findChild(string key)
    {
        for (0 => int i; i < arrayValue.cap(); i++)
        {
            if (arrayValue[i].GetName() == key) { return i; }
        }
        return -1;
    }

    // ---------------- map utilities ----------------
    // Set or add a string property on a map node
    fun void SetInt(string key, int value)
    {
        if (type != TYPE_MAP())
        {
            return;
        }
        // find existing child with name
        findChild(key) => int foundIdx;
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

    fun int GetInt(string key)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: MapGetInt called on non-map YamlNode (type=" + type + ")" >>>;
            return 0;
        }
        // find existing child with name
        findChild(key) => int foundIdx;

        if (foundIdx < 0) {
            <<< "Warning: Key '" + key + "' not found in YamlNode map." >>>;
            return 0;
        }

        return arrayValue[foundIdx].GetInt();
    }

    fun void SetString(string key, string value)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: SetString(key, value) called on non-map YamlNode (type=" + type + ")" >>>;
            return;
        }
        // find existing child with name
        findChild(key) => int foundIdx;
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

    fun string GetString(string key)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: MapGetString called on non-map YamlNode (type=" + type + ")" >>>;
            return "";
        }
        // find existing child with name
        findChild(key) => int foundIdx;

        if (foundIdx < 0) {
            <<< "Warning: Key '" + key + "' not found in YamlNode map." >>>;
            return "";
        }

        return arrayValue[foundIdx].GetString();
    }


    fun void SetFloat(string key, float value)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: MapSetFloat called on non-map YamlNode (type=" + type + ")" >>>;
            return;
        }
        // find existing child with name
        findChild(key) => int foundIdx;
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

    fun float GetFloat(string key)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: MapGetFloat called on non-map YamlNode (type=" + type + ")" >>>;
            return 0.0;
        }
        // find existing child with name
        findChild(key) => int foundIdx;
        if (foundIdx < 0) {
                <<< "Warning: Key '" + key + "' not found in YamlNode map." >>>;
                return 0.0;
            }

        return arrayValue[foundIdx].GetFloat();
    }

    fun YamlNode@ SetMap(string key)
    {
        if (type != TYPE_MAP())
        {
            YamlNode empty[0];
            SetMap(empty);
        }
        // find existing child with name
        findChild(key) => int foundIdx;
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

    fun YamlNode@ GetMap(string key)
    {
        if (type != TYPE_MAP())
        {
            <<< "Warning: GetMap called on non-map YamlNode (type=" + type + ")" >>>;
            return null;
        }
        // find existing child with name
        findChild(key) => int foundIdx;
        if (foundIdx < 0) {
            <<< "Warning: Key '" + key + "' not found in YamlNode map." >>>;
            return null;
        }
        arrayValue[foundIdx] @=> YamlNode@ map;
        if (map.GetType() != TYPE_MAP())
        {
            <<< "Warning: GetMap called on non-map YamlNode (type=" + map.GetType() + ")" >>>;
            return null;
        }

        return map;
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

    // ---------------- Top-level YAML reader ----------------
    // Parses a YAML document from a file. Supports:
    //   - Block maps and nested maps
    //   - Block sequences ("- item", "- key: value")
    //   - Flow sequences ("[1, 2, 3]"), empty arrays ("[]")
    //   - Quoted strings, ints, floats, null
    //   - Comments ("#") and blank lines
    // If the document has a single top-level key the keyed child is returned
    // directly; multiple top-level keys yield an anonymous wrapper map node.
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

        YamlParser p;
        p.init(lines);
        p.skipBlank();
        if (p.idx >= lines.cap())
        {
            return new YamlNode("");
        }

        indentOf(lines[p.idx]) => int baseIndent;
        trimLeft(lines[p.idx]) => string first;

        if (first.charAt(0) == '-')
        {
            p.parseSequence(baseIndent) @=> YamlNode items[];
            YamlNode root("");
            root.SetArray(items);
            return root;
        }
        if (indexOf(first, ":") >= 0)
        {
            p.parseMap(baseIndent) @=> YamlNode kids[];
            if (kids.cap() == 1) return kids[0];
            YamlNode root("");
            root.SetMap(kids);
            return root;
        }
        return parseScalarNodeWithName("", first);
    }
}

// YamlParser is a small cursor-based recursive parser for the YAML subset
// supported by Cadenza. It tracks a mutable line index over a buffer of
// pre-trimmed lines and recurses into nested maps and sequences via indent.
public class YamlParser
{
    string lines[];
    int idx;

    fun void init(string l[])
    {
        l @=> lines;
        0 => idx;
    }

    // Advance past blank or comment lines.
    fun void skipBlank()
    {
        while (idx < lines.cap())
        {
            YamlNode.trimLeft(lines[idx]) => string l;
            if (l.length() == 0) { idx++; continue; }
            if (l.charAt(0) == '#') { idx++; continue; }
            break;
        }
    }

    // Indent of the current non-blank line, or -1 at EOF.
    // Caller must have invoked skipBlank() first.
    fun int peekIndent()
    {
        if (idx >= lines.cap()) return -1;
        return YamlNode.indentOf(lines[idx]);
    }

    // Left-trimmed text of the current non-blank line, or "" at EOF.
    fun string peekText()
    {
        if (idx >= lines.cap()) return "";
        return YamlNode.trimLeft(lines[idx]);
    }

    // Parse mapping entries while the current line indent equals mapIndent.
    fun YamlNode[] parseMap(int mapIndent)
    {
        YamlNode children[0];
        while (true)
        {
            skipBlank();
            if (idx >= lines.cap()) break;
            peekIndent() => int ind;
            if (ind < mapIndent) break;
            peekText() => string l;
            // A '-' line at this indent is a sequence sibling, not a map entry.
            if (l.charAt(0) == '-') break;
            // Defensive: deeper-indented stray lines are skipped.
            if (ind > mapIndent) { idx++; continue; }

            YamlNode.indexOf(l, ":") => int colon;
            if (colon < 0) break;
            YamlNode.trimRight(YamlNode.subClamp(l, 0, colon)) => string key;
            YamlNode.trimLeft(YamlNode.subClamp(l, colon+1, l.length() - (colon+1))) => string rest;
            idx++;

            children << buildValueNode(key, rest, mapIndent);
        }
        return children;
    }

    // Parse "- ..." block sequence items at indent == seqIndent.
    fun YamlNode[] parseSequence(int seqIndent)
    {
        YamlNode items[0];
        while (true)
        {
            skipBlank();
            if (idx >= lines.cap()) break;
            if (peekIndent() != seqIndent) break;
            peekText() => string l;
            if (l.charAt(0) != '-') break;

            // Token after the dash: "- foo" -> "foo"; lone "-" -> "".
            "" => string tok;
            if (l.length() >= 2 && YamlNode.subClamp(l, 0, 2) == "- ")
            {
                YamlNode.trimLeft(YamlNode.trimRight(YamlNode.subToEnd(l, 2))) => tok;
            }
            idx++;

            if (tok.length() == 0)
            {
                items << parseDashChild(seqIndent);
                continue;
            }

            if (YamlNode.indexOf(tok, ":") >= 0)
            {
                items << parseInlineMapItem(tok, seqIndent);
                continue;
            }

            // Plain scalar (or nested flow array) item.
            if (YamlNode.isInlineArrayToken(tok))
            {
                items << YamlNode.parseInlineArrayNodeWithName("", tok);
            }
            else
            {
                items << YamlNode.parseScalarNodeWithName("", tok);
            }
        }
        return items;
    }

    // Build the YamlNode for a `key: rest` map entry.
    // The cursor is already past the key line; nested values are read on demand.
    fun YamlNode buildValueNode(string key, string rest, int parentIndent)
    {
        if (rest.length() == 0)
        {
            return parseChildValue(key, parentIndent);
        }
        if (rest == "[]")
        {
            YamlNode arr(key);
            YamlNode empty[0];
            arr.SetArray(empty);
            return arr;
        }
        if (YamlNode.isInlineArrayToken(rest))
        {
            return YamlNode.parseInlineArrayNodeWithName(key, rest);
        }
        return YamlNode.parseScalarNodeWithName(key, rest);
    }

    // Resolve the value attached to `key:` whose inline RHS was empty by
    // looking ahead. If the next non-blank line is more indented, dispatch to
    // parseSequence or parseMap; otherwise emit an empty map.
    fun YamlNode parseChildValue(string key, int parentIndent)
    {
        skipBlank();
        if (idx >= lines.cap() || peekIndent() <= parentIndent)
        {
            YamlNode emptyMap(key);
            YamlNode none[0];
            emptyMap.SetMap(none);
            return emptyMap;
        }
        peekIndent() => int childIndent;
        peekText() => string l;
        if (l.charAt(0) == '-')
        {
            parseSequence(childIndent) @=> YamlNode items[];
            YamlNode arr(key);
            arr.SetArray(items);
            return arr;
        }
        parseMap(childIndent) @=> YamlNode kids[];
        YamlNode mapNode(key);
        mapNode.SetMap(kids);
        return mapNode;
    }

    // Handle a bare "-" (no inline content) by parsing the indented body
    // beneath it as a nested map, sequence, or empty scalar item.
    fun YamlNode parseDashChild(int seqIndent)
    {
        skipBlank();
        if (idx < lines.cap() && peekIndent() > seqIndent)
        {
            peekIndent() => int childIndent;
            peekText() => string l;
            if (l.charAt(0) == '-')
            {
                parseSequence(childIndent) @=> YamlNode kids[];
                YamlNode item("");
                item.SetArray(kids);
                return item;
            }
            parseMap(childIndent) @=> YamlNode kids[];
            YamlNode item("");
            item.SetMap(kids);
            return item;
        }
        YamlNode item("");
        item.SetString("");
        return item;
    }

    // Handle "- key: value" items, optionally followed by additional indented
    // map properties belonging to the same dash item.
    fun YamlNode parseInlineMapItem(string tok, int seqIndent)
    {
        YamlNode.indexOf(tok, ":") => int c2;
        YamlNode.trimRight(YamlNode.subClamp(tok, 0, c2)) => string ikey;
        YamlNode.trimLeft(YamlNode.subClamp(tok, c2+1, tok.length() - (c2+1))) => string irest;

        YamlNode mapKids[0];
        mapKids << buildValueNode(ikey, irest, seqIndent);

        // Continuation properties of this dash item live at indent > seqIndent
        // and are formatted as a regular block map.
        skipBlank();
        if (idx < lines.cap() && peekIndent() > seqIndent)
        {
            peekIndent() => int restIndent;
            peekText() => string nl;
            if (nl.charAt(0) != '-')
            {
                parseMap(restIndent) @=> YamlNode rest[];
                for (0 => int r; r < rest.cap(); r++) mapKids << rest[r];
            }
        }
        YamlNode mapItem("");
        mapItem.SetMap(mapKids);
        return mapItem;
    }
}
