public class YamlNode 
{
    // Type discriminator
    int type; // 0=string, 1=float, 2=int, 3=array, 4=ref, 5=map

    // Name of this node (YAML mapping key)
    string name;

    // Value storage for each type
    string stringValue;
    float floatValue;
    int intValue;
    YamlNode@ arrayValue[]; // used for sequence or map children
    YamlNode @ nodeRef;

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
        null @=> nodeRef;
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
        null @=> nodeRef;
    }

    // Name accessors
    fun void SetName(string n) { n => name; }
    fun string GetName() { return name; }

    // Setters (also set the type)
    fun void SetString(string v)
    {
        0 => type;
        v => stringValue;
    }

    fun void SetFloat(float v)
    {
        1 => type;
        v => floatValue;
    }

    fun void SetInt(int v)
    {
        2 => type;
        v => intValue;
    }

    fun void SetArray(YamlNode nodes[])
    {
        3 => type;
        nodes @=> arrayValue;
    }

    fun void SetMap(YamlNode nodes[])
    {
        5 => type;
        nodes @=> arrayValue;
    }

    fun void SetNode(YamlNode node)
    {
        4 => type;
        node @=> nodeRef;
    }

    // Accessors (type-checked)
    fun string GetString()
    {
        if (type != 0) { <<< "YamlNode type mismatch in GetString():", type >>>; }
        return stringValue;
    }

    fun float GetFloat()
    {
        if (type != 1) { <<< "YamlNode type mismatch in GetFloat():", type >>>; }
        return floatValue;
    }

    fun int GetInt()
    {
        if (type != 2) { <<< "YamlNode type mismatch in GetInt():", type >>>; }
        return intValue;
    }

    fun YamlNode[] GetArray()
    {
        if (type != 3) { <<< "YamlNode type mismatch in GetArray():", type >>>; }
        return arrayValue;
    }

    fun YamlNode[] GetMap()
    {
        if (type != 5) { <<< "YamlNode type mismatch in GetMap():", type >>>; }
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

    fun YamlNode GetNode()
    {
        if (type != 4) { <<< "YamlNode type mismatch in GetNode():", type >>>; }
        return nodeRef;
    }

    fun int GetType()
    {
        return type;
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
        if (start > s.length()) return "";
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
        return (n.GetType() == 0 || n.GetType() == 1 || n.GetType() == 2);
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
        if (t == 0) // string
        {
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ": " ); }
            f.write(escapeString(node.GetString()) + "\n");
        }
        else if (t == 1) // float
        {
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ": " ); }
            f.write(("" + node.GetFloat()) + "\n");
        }
        else if (t == 2) // int
        {
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ": " ); }
            f.write(("" + node.GetInt()) + "\n");
        }
        else if (t == 3) // array (sequence)
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
                    if (items[i].GetType() == 0) {
                        f.write(escapeString(items[i].GetString()) + "\n");
                    } else if (items[i].GetType() == 1) {
                        f.write(("" + items[i].GetFloat()) + "\n");
                    } else { // int
                        f.write(("" + items[i].GetInt()) + "\n");
                    }
                }
                else
                {
                    f.write("\n");
                    writeNode(f, items[i], indent + (nm != "" ? 2 : 1));
                }
            }
        }
        else if (t == 5) // map (object)
        {
            YamlNode items[0];
            node.GetMap() @=> items;
            writeIndent(f, indent);
            if (nm != "") { f.write(nm + ":\n"); }
            for (0 => int i; i < items.cap(); i++)
            {
                writeNode(f, items[i], indent + 1);
            }
        }
        else if (t == 4) // reference: inline the referenced node, preserving this node's name
        {
            YamlNode ref;
            node.GetNode() @=> ref;
            if (ref != null)
            {
                string saved;
                ref.GetName() => saved;
                nm => ref.name;
                writeNode(f, ref, indent);
                saved => ref.name;
            }
            else
            {
                writeIndent(f, indent);
                if (nm != "") { f.write(nm + ": null\n"); }
                else { f.write("null\n"); }
            }
        }
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
            if (safety > lines.cap() * 4) { <<< "PMC safety break at i=", i >>>; break; }
            safety++;
            <<< "PMC i=", i, " line=", lines[i] >>>;
            trimLeft(lines[i]) => string l;
            if (l.length() == 0 || l.charAt(0) == '#') { i++; continue; }
            indentOf(lines[i]) => int curIndent;
            <<< "PMC curIndent=", curIndent, " base=", baseIndent >>>;
            if (curIndent < baseIndent) break;
            if (curIndent > baseIndent) { i++; continue; }
            indexOf(l, ":") => int colon;
            <<< "PMC colon=", colon, " trimmed=", l >>>;
            if (colon < 0) break;
            if (colon + 1 >= l.length())
            {
                trimRight(subClamp(l, 0, colon)) => string key;
                "" => string rest;
                <<< "PMC key=", key, " rest=(empty)" >>>;
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
                subClamp(trimLeft(lines[j]), 0, 2) => string pref;
                <<< "PMC childIndent=", childIndent, " pref=", pref, " j=", j, " line=", lines[j] >>>;
                if (pref == "- ")
                {
                    YamlNode items[0];
                    int k;
                    for (j => k; k < lines.cap(); k++)
                    {
                        trimLeft(lines[k]) => string l3;
                        if (l3.length() == 0 || l3.charAt(0) == '#') { continue; }
                        if (indentOf(lines[k]) != childIndent) { break; }
                        if (subClamp(l3, 0, 2) != "- ") { break; }
                        subToEnd(l3, 2) => string tok;
                        // inline scalar parse with empty name
                        trimLeft(trimRight(tok)) => tok;
                        YamlNode item("");
                        if (tok.length() == 0 || tok == "null") { item.SetString(""); }
                        else if (tok.length() >= 1 && tok.charAt(0) == "\"".charAt(0)) { item.SetString(stripOuterQuotes(tok)); }
                        else {
                            Std.atoi(tok) => int iv; Std.itoa(iv) => string ivs;
                            if (ivs == tok) { item.SetInt(iv); }
                            else { Std.atof(tok) => float fv; if (tok.find(".") >= 0 || tok.find("e") >= 0 || tok.find("E") >= 0) { item.SetFloat(fv); } else { item.SetString(tok); } }
                        }
                        items << item;
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
            <<< "PMC key=", key, " rest=", rest >>>;
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
                // inline scalar parsing for key: value
                trimLeft(trimRight(rest)) => rest;
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
            subClamp(trimLeft(lines[j]), 0, 2) => string pref;
            <<< "PMC childIndent=", childIndent, " pref=", pref, " j=", j, " line=", lines[j] >>>;
            if (pref == "- ")
            {
                YamlNode items[0];
                int k;
                for (j => k; k < lines.cap(); k++)
                {
                    trimLeft(lines[k]) => string l3;
                    if (l3.length() == 0 || l3.charAt(0) == '#') { continue; }
                    if (indentOf(lines[k]) != childIndent) { break; }
                    if (subClamp(l3, 0, 2) != "- ") { break; }
                    subToEnd(l3, 2) => string tok;
                    // inline scalar parse with empty name
                    trimLeft(trimRight(tok)) => tok;
                    YamlNode item("");
                    if (tok.length() == 0 || tok == "null") { item.SetString(""); }
                    else if (tok.length() >= 1 && tok.charAt(0) == "\"".charAt(0)) { item.SetString(stripOuterQuotes(tok)); }
                    else {
                        Std.atoi(tok) => int iv; Std.itoa(iv) => string ivs;
                        if (ivs == tok) { item.SetInt(iv); }
                        else { Std.atof(tok) => float fv; if (tok.find(".") >= 0 || tok.find("e") >= 0 || tok.find("E") >= 0) { item.SetFloat(fv); } else { item.SetString(tok); } }
                    }
                    items << item;
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
            <<< "DEBUG first=", first, " len=", first.length(), " colon=", colon >>>;
            trimRight(subClamp(first, 0, colon)) => string key;
            if (colon+1 >= first.length())
            {
                // No inline rest; determine sequence or map from following lines
                <<< "DEBUG key=", key, " rest=(empty)" >>>;
                // decide if sequence or map
                firstIdx+1 => int j;
                while (j < lines.cap())
                {
                    trimLeft(lines[j]) => string l;
                    if (l.length() == 0 || l.charAt(0) == '#') { j++; continue; }
                    break;
                }
                if (j >= lines.cap())
                {
                    YamlNode m(key);
                    YamlNode none[0];
                    m.SetMap(none);
                    return m;
                }
                <<< "DEBUG after key, candidate line=", trimLeft(lines[j]) >>>;
                if (subClamp(trimLeft(lines[j]), 0, 2) == "- ")
                {
                    // sequence
                    int childIndent; indentOf(lines[j]) => childIndent;
                    YamlNode items[0];
                    for (j => int k; k < lines.cap(); k++)
                    {
                        trimLeft(lines[k]) => string l2;
                        if (l2.length() == 0 || l2.charAt(0) == '#') { continue; }
                        if (indentOf(lines[k]) != childIndent) break;
                        if (subClamp(l2, 0, 2) != "- ") break;
                        subToEnd(l2, 2) => string tok;
                        <<< "DEBUG seq tok=", tok >>>;
                        parseScalarNodeWithName("", tok) @=> YamlNode item;
                        items << item;
                    }
                    YamlNode arrNode(key);
                    arrNode.SetArray(items);
                    return arrNode;
                }
                else
                {
                    // map
                    int childIndent; indentOf(lines[j]) => childIndent;
                    parseMapChildren(lines, j, childIndent) @=> YamlNode kids[];
                    YamlNode mapNode(key);
                    mapNode.SetMap(kids);
                    return mapNode;
                }
            }
            trimLeft(subClamp(first, colon+1, first.length() - (colon+1))) => string rest;
            <<< "DEBUG key=", key, " rest=", rest, " rest.len=", rest.length() >>>;
            if (rest == "[]")
            {
                YamlNode emptyArr(key);
                YamlNode elems[0];
                emptyArr.SetArray(elems);
                return emptyArr;
            }
            if (rest.length() > 0)
            {
                return parseScalarNodeWithName(key, rest);
            }
            // decide if sequence or map
            firstIdx+1 => int j;
            while (j < lines.cap())
            {
                trimLeft(lines[j]) => string l;
                if (l.length() == 0 || l.charAt(0) == '#') { j++; continue; }
                break;
            }
            if (j >= lines.cap())
            {
                YamlNode m(key);
                YamlNode none[0];
                m.SetMap(none);
                return m;
            }
            <<< "DEBUG after key, candidate line=", trimLeft(lines[j]) >>>;
            if (subClamp(trimLeft(lines[j]), 0, 2) == "- ")
            {
                // sequence
                int childIndent; indentOf(lines[j]) => childIndent;
                YamlNode items[0];
                for (j => int k; k < lines.cap(); k++)
                {
                    trimLeft(lines[k]) => string l2;
                    if (l2.length() == 0 || l2.charAt(0) == '#') { continue; }
                    if (indentOf(lines[k]) != childIndent) break;
                    if (subClamp(l2, 0, 2) != "- ") break;
                    subToEnd(l2, 2) => string tok;
                    // inline scalar parse with empty name
                    trimLeft(trimRight(tok)) => tok;
                    YamlNode item("");
                    if (tok.length() == 0 || tok == "null") { item.SetString(""); }
                    else if (tok.length() >= 1 && tok.charAt(0) == "\"".charAt(0)) { item.SetString(stripOuterQuotes(tok)); }
                    else {
                        Std.atoi(tok) => int iv; Std.itoa(iv) => string ivs;
                        if (ivs == tok) { item.SetInt(iv); }
                        else { Std.atof(tok) => float fv; if (tok.find(".") >= 0 || tok.find("e") >= 0 || tok.find("E") >= 0) { item.SetFloat(fv); } else { item.SetString(tok); } }
                    }
                    items << item;
                }
                YamlNode arrNode(key);
                arrNode.SetArray(items);
                return arrNode;
            }
            else
            {
                // map
                int childIndent; indentOf(lines[j]) => childIndent;
                parseMapChildren(lines, j, childIndent) @=> YamlNode kids[];
                YamlNode mapNode(key);
                mapNode.SetMap(kids);
                return mapNode;
            }
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
            for (firstIdx => int i; i < lines.cap(); i++)
            {
                trimLeft(lines[i]) => string l;
                if (l.length() == 0) continue;
                if (l.charAt(0) == '#') continue;
                if (l.length() >= 2 && subClamp(l, 0, 2) == "- ")
                {
                    subToEnd(l, 2) => string itemTok;
                    // inline scalar parse with empty name
                    trimLeft(trimRight(itemTok)) => itemTok;
                    YamlNode itemNode("");
                    if (itemTok.length() == 0 || itemTok == "null") { itemNode.SetString(""); }
                    else if (itemTok.length() >= 1 && itemTok.charAt(0) == "\"".charAt(0)) { itemNode.SetString(stripOuterQuotes(itemTok)); }
                    else {
                        Std.atoi(itemTok) => int iv; Std.itoa(iv) => string ivs;
                        if (ivs == itemTok) { itemNode.SetInt(iv); }
                        else { Std.atof(itemTok) => float fv; if (itemTok.find(".") >= 0 || itemTok.find("e") >= 0 || itemTok.find("E") >= 0) { itemNode.SetFloat(fv); } else { itemNode.SetString(itemTok); } }
                    }
                    items << itemNode;
                }
                else if (l == "-")
                {
                    YamlNode empty("");
                    empty.SetString("");
                    items << empty;
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
