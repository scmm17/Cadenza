@import "../framework/yaml.ck"

// Global flag indicating whether fallback path was used in last parse
0 => int gYamlParseUsedFallback;

fun void assertEqualInt(string name, int a, int b)
{
    if (a != b) {
        <<< "ASSERT FAIL (", name, "):", a, "!=", b >>>;
    } else {
        <<< "PASS", name >>>;
    }
}

// Try to parse from a preferred path; if the parsed node is empty, try fallback
fun YamlNode parseYamlWithFallback(string preferred, string fallback)
{
    0 => gYamlParseUsedFallback;
    YamlNode.ParseFile(preferred) @=> YamlNode n;
    if (n.GetType() == -1 && n.GetName() == "")
    {
        1 => gYamlParseUsedFallback;
        YamlNode.ParseFile(fallback) @=> n;
    }
    return n;
}

fun void assertEqualFloat(string name, float a, float b)
{
    (a - b) => float d;
    if (d < 0) { -d => d; }
    if (d > 1e-6) {
        <<< "ASSERT FAIL (", name, "):", a, "!=", b >>>;
    } else {
        <<< "PASS", name >>>;
    }
}

fun void assertEqualString(string name, string a, string b)
{
    if (a != b) {
        <<< "ASSERT FAIL (", name, "):", a, "!=", b >>>;
    } else {
        <<< "PASS", name >>>;
    }
}

// Deep equality check for YamlNode trees
fun int nodesDeepEqual(YamlNode a, YamlNode b)
{
    a.GetType() => int ta;
    b.GetType() => int tb;
    if (ta != tb) return 0;
    if (a.GetName() != b.GetName()) return 0;

    if (ta == 0) { // string
        return a.GetString() == b.GetString();
    }
    else if (ta == 1) { // float
        a.GetFloat() => float af;
        b.GetFloat() => float bf;
        (af - bf) => float d;
        if (d < 0) { -d => d; }
        return d <= 1e-6;
    }
    else if (ta == 2) { // int
        return a.GetInt() == b.GetInt();
    }
    else if (ta == 3) { // array
        a.GetArray() @=> YamlNode aa[];
        b.GetArray() @=> YamlNode bb[];
        if (aa.cap() != bb.cap()) return 0;
        for (0 => int i; i < aa.cap(); i++) {
            if (nodesDeepEqual(aa[i], bb[i]) == 0) return 0;
        }
        return 1;
    }
    else if (ta == 5) { // map
        a.GetMap() @=> YamlNode am[];
        b.GetMap() @=> YamlNode bm[];
        if (am.cap() != bm.cap()) return 0;
        for (0 => int i; i < am.cap(); i++) {
            b.GetValue(am[i].GetName()) @=> YamlNode other;
            if (nodesDeepEqual(am[i], other) == 0) return 0;
        }
        return 1;
    }
    // type 4 (ref) removed
    return 0;
}

fun void assertNodesEqual(string name, YamlNode a, YamlNode b)
{
    nodesDeepEqual(a, b) => int ok;
    if (ok == 1) {
        <<< "PASS", name >>>;
    } else {
        <<< "ASSERT FAIL (", name, "): nodes not equal" >>>;
    }
}

fun void testScalarString()
{
    YamlNode n("greeting");
    n.SetString("hello \"world\"");
    string file;
    "test-yaml-string.yaml" => file;
    n.WriteFile(file);
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("string name", m.GetName(), "greeting");
    assertEqualInt("string type", m.GetType(), YamlNode.TYPE_STRING());
    assertEqualString("string value", m.GetString(), "hello \"world\"");
}

fun void testScalarInt()
{
    YamlNode n("answer");
    n.SetInt(12345);
    string file;
    "test-yaml-int.yaml" => file;
    n.WriteFile(file);
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("int name", m.GetName(), "answer");
    assertEqualInt("int type", m.GetType(), YamlNode.TYPE_INT());
    assertEqualInt("int value", m.GetInt(), 12345);
}

fun void testScalarFloat()
{
    YamlNode n("pi");
    n.SetFloat(3.14159);
    string file;
    "test-yaml-float.yaml" => file;
    n.WriteFile(file);
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("float name", m.GetName(), "pi");
    assertEqualInt("float type", m.GetType(), YamlNode.TYPE_FLOAT());
    assertEqualFloat("float value", m.GetFloat(), 3.14159);
}

fun void testArrayScalars()
{
    YamlNode s(""); s.SetString("alpha");
    YamlNode i(""); i.SetInt(7);
    YamlNode f(""); f.SetFloat(2.5);
    YamlNode nodes[0];
    nodes << s; nodes << i; nodes << f;
    YamlNode arr("items"); arr.SetArray(nodes);
    string file;
    "test-yaml-array.yaml" => file;
    arr.WriteFile(file);
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("array name", m.GetName(), "items");
    assertEqualInt("array type", m.GetType(), YamlNode.TYPE_ARRAY());
    m.GetArray() @=> YamlNode back[];
    assertEqualInt("array size", back.cap(), 3);
    assertEqualInt("array[0] type", back[0].GetType(), YamlNode.TYPE_STRING());
    assertEqualString("array[0] value", back[0].GetString(), "alpha");
    assertEqualInt("array[1] type", back[1].GetType(), YamlNode.TYPE_INT());
    assertEqualInt("array[1] value", back[1].GetInt(), 7);
    assertEqualInt("array[2] type", back[2].GetType(), YamlNode.TYPE_FLOAT());
    assertEqualFloat("array[2] value", back[2].GetFloat(), 2.5);
}

fun void testEmptyArray()
{
    YamlNode emptyItems[0];
    YamlNode arr("empty"); arr.SetArray(emptyItems);
    string file;
    "test-yaml-empty-array.yaml" => file;
    arr.WriteFile(file);
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("empty array name", m.GetName(), "empty");
    assertEqualInt("empty array type", m.GetType(), YamlNode.TYPE_ARRAY());
    m.GetArray() @=> YamlNode back[];
    assertEqualInt("empty array size", back.cap(), 0);
}

fun void testMapSetters()
{
    YamlNode root("root");
    YamlNode empty[0];
    root.SetMap(empty);

    root.SetString("title", "hello");
    root.SetInt("count", 42);
    root.SetFloat("ratio", 2.5);

    // overwrite
    root.SetString("title", "world");
    root.SetInt("count", 7);
    root.SetFloat("ratio", 3.25);

    assertEqualInt("map setters: type", root.GetType(), YamlNode.TYPE_MAP());
    root.GetMap() @=> YamlNode kids[];
    -1 => int it; -1 => int ic; -1 => int ir;
    for (0 => int i; i < kids.cap(); i++)
    {
        if (kids[i].GetName() == "title") { i => it; }
        else if (kids[i].GetName() == "count") { i => ic; }
        else if (kids[i].GetName() == "ratio") { i => ir; }
    }
    assertEqualInt("map has title", it >= 0, 1);
    assertEqualInt("map has count", ic >= 0, 1);
    assertEqualInt("map has ratio", ir >= 0, 1);
    if (it >= 0) { assertEqualInt("title type", kids[it].GetType(), YamlNode.TYPE_STRING()); assertEqualString("title value", kids[it].GetString(), "world"); }
    if (ic >= 0) { assertEqualInt("count type", kids[ic].GetType(), YamlNode.TYPE_INT()); assertEqualInt("count value", kids[ic].GetInt(), 7); }
    if (ir >= 0) { assertEqualInt("ratio type", kids[ir].GetType(), YamlNode.TYPE_FLOAT()); assertEqualFloat("ratio value", kids[ir].GetFloat(), 3.25); }

    string f; "test-map-setters.yaml" => f;
    root.WriteFile(f);
    parseYamlWithFallback("test/" + f, f) @=> YamlNode again;
    assertEqualInt("map rt type", again.GetType(), YamlNode.TYPE_MAP());
    again.GetMap() @=> YamlNode againKids[];
    -1 => it; -1 => ic; -1 => ir;
    for (0 => int i; i < againKids.cap(); i++)
    {
        if (againKids[i].GetName() == "title") { i => it; }
        else if (againKids[i].GetName() == "count") { i => ic; }
        else if (againKids[i].GetName() == "ratio") { i => ir; }
    }
    assertEqualInt("map rt has title", it >= 0, 1);
    assertEqualInt("map rt has count", ic >= 0, 1);
    assertEqualInt("map rt has ratio", ir >= 0, 1);
    if (it >= 0) { assertEqualString("rt title value", againKids[it].GetString(), "world"); }
    if (ic >= 0) { assertEqualInt("rt count value", againKids[ic].GetInt(), 7); }
    if (ir >= 0) { assertEqualFloat("rt ratio value", againKids[ir].GetFloat(), 3.25); }
}

// Reference node type removed: drop ref tests

// Reference node type removed: drop ref tests

// Reference node type removed: drop nested ref tests

// Reference node type removed: drop nested ref tests

// Round-trip test for nested mapping file
fun void testReadWriteNesting()
{
    // Read existing YAML
    parseYamlWithFallback("test/test-yaml-nesting.yaml", "test-yaml-nesting.yaml") @=> YamlNode root;
    // Expect a map named level1
    assertEqualString("nesting root name", root.GetName(), "level1");
    assertEqualInt("nesting root type(map)", root.GetType(), YamlNode.TYPE_MAP());
    root.GetMap() @=> YamlNode kids[];
    // Write to a new file
    string outFile;
    if (gYamlParseUsedFallback == 1) { "test-yaml-nesting-out.yaml" => outFile; }
    else { "test/test-yaml-nesting-out.yaml" => outFile; }
    root.WriteFile(outFile);
    // Read back the written file
    YamlNode.ParseFile(outFile) @=> YamlNode again;
    assertEqualString("nesting again name", again.GetName(), "level1");
    assertEqualInt("nesting again type(map)", again.GetType(), YamlNode.TYPE_MAP());
    again.GetMap() @=> YamlNode againKids[];
    // Validate known keys and types/values
    -1 => int ia; -1 => int ib; -1 => int ic; -1 => int id;
    for (0 => int i; i < againKids.cap(); i++)
    {
        if (againKids[i].GetName() == "a") { i => ia; }
        else if (againKids[i].GetName() == "b") { i => ib; }
        else if (againKids[i].GetName() == "c") { i => ic; }
        else if (againKids[i].GetName() == "d") { i => id; }
    }
    assertEqualInt("have a", ia >= 0, 1);
    assertEqualInt("have b", ib >= 0, 1);
    assertEqualInt("have c", ic >= 0, 1);
    assertEqualInt("have d", id >= 0, 1);
    if (ia >= 0) { assertEqualInt("a type", againKids[ia].GetType(), 1); assertEqualFloat("a value", againKids[ia].GetFloat(), 1.0); }
    if (ib >= 0) { assertEqualInt("b type", againKids[ib].GetType(), 2); assertEqualInt("b value", againKids[ib].GetInt(), 2); }
    if (ic >= 0) {
        assertEqualInt("c type", againKids[ic].GetType(), YamlNode.TYPE_ARRAY());
        againKids[ic].GetArray() @=> YamlNode arr[];
        assertEqualInt("c len", arr.cap(), 4);
        assertEqualInt("c[0]", arr[0].GetInt(), 3);
        assertEqualInt("c[1]", arr[1].GetInt(), 4);
        assertEqualInt("c[2]", arr[2].GetInt(), 5);
        assertEqualInt("c[3]", arr[3].GetInt(), 6);
    }
    if (id >= 0) {
        assertEqualInt("d type", againKids[id].GetType(), YamlNode.TYPE_MAP());
        againKids[id].GetMap() @=> YamlNode dKids[];
        -1 => int ix; -1 => int iy; -1 => int inz; -1 => int inn;
        for (0 => int i; i < dKids.cap(); i++)
        {
            if (dKids[i].GetName() == "x") { i => ix; }
            else if (dKids[i].GetName() == "y") { i => iy; }
            else if (dKids[i].GetName() == "z") { i => inz; }
            else if (dKids[i].GetName() == "nested") { i => inn; }
        }
        assertEqualInt("d has x", ix >= 0, 1);
        assertEqualInt("d has y", iy >= 0, 1);
        assertEqualInt("d has z", inz >= 0, 1);
        assertEqualInt("d has nested", inn >= 0, 1);
        if (ix >= 0) { assertEqualInt("d.x type", dKids[ix].GetType(), YamlNode.TYPE_INT()); assertEqualInt("d.x val", dKids[ix].GetInt(), 4); }
        if (iy >= 0) { assertEqualInt("d.y type", dKids[iy].GetType(), YamlNode.TYPE_STRING()); assertEqualString("d.y val", dKids[iy].GetString(), "234"); }
        if (inz >= 0) { assertEqualInt("d.z type", dKids[inz].GetType(), YamlNode.TYPE_INT()); assertEqualInt("d.z val", dKids[inz].GetInt(), 15); }
        if (inn >= 0) {
            assertEqualInt("d.nested type", dKids[inn].GetType(), YamlNode.TYPE_MAP());
            dKids[inn].GetMap() @=> YamlNode nKids[];
            -1 => int iw; -1 => int is;
            for (0 => int i; i < nKids.cap(); i++)
            {
                if (nKids[i].GetName() == "w") { i => iw; }
                else if (nKids[i].GetName() == "s") { i => is; }
            }
            assertEqualInt("nested has w", iw >= 0, 1);
            assertEqualInt("nested has s", is >= 0, 1);
            if (iw >= 0) { assertEqualInt("nested.w type", nKids[iw].GetType(), YamlNode.TYPE_INT()); assertEqualInt("nested.w val", nKids[iw].GetInt(), 5); }
            if (is >= 0) { assertEqualInt("nested.s type", nKids[is].GetType(), YamlNode.TYPE_STRING()); assertEqualString("nested.s val", nKids[is].GetString(), "asdf"); }
        }
    }
}

// Round-trip test for multi-sibling top-level file
fun void testReadWriteNesting2()
{
    parseYamlWithFallback("test/test-yaml-nesting-2.yaml", "test-yaml-nesting-2.yaml") @=> YamlNode root;
    string outFile;
    if (gYamlParseUsedFallback == 1) { "test-yaml-nesting-2-out.yaml" => outFile; }
    else { "test/test-yaml-nesting-2-out.yaml" => outFile; }
    root.WriteFile(outFile);
    YamlNode.ParseFile(outFile) @=> YamlNode again;
    assertNodesEqual("nesting-2 roundtrip", root, again);
}

// Round-trip test for object arrays file
fun void testObjectArraysRoundtrip()
{
    parseYamlWithFallback("test/test-object-arrays.yaml", "test-object-arrays.yaml") @=> YamlNode root;
    // Verify structure: root is array named test-array with 3 map items
    assertEqualString("objarr root name", root.GetName(), "test-array");
    assertEqualInt("objarr root type", root.GetType(), YamlNode.TYPE_ARRAY());
    root.GetArray() @=> YamlNode objs[];
    assertEqualInt("objarr len", objs.cap(), 3);
    // check item 0
    if (objs.cap() >= 1) {
        assertEqualInt("objarr[0] type", objs[0].GetType(), YamlNode.TYPE_MAP());
        objs[0].GetMap() @=> YamlNode m0[];
        objs[0].GetValue("name") @=> YamlNode m0n;
        objs[0].GetValue("value") @=> YamlNode m0v;
        assertEqualString("objarr[0].name", m0n.GetString(), "test1");
        assertEqualInt("objarr[0].value", m0v.GetInt(), 1);
    }
    // check item 1
    if (objs.cap() >= 2) {
        assertEqualInt("objarr[1] type", objs[1].GetType(), YamlNode.TYPE_MAP());
        objs[1].GetValue("name") @=> YamlNode m1n;
        objs[1].GetValue("value") @=> YamlNode m1v;
        assertEqualString("objarr[1].name", m1n.GetString(), "test2");
        assertEqualInt("objarr[1].value", m1v.GetInt(), 2);
    }
    // check item 2
    if (objs.cap() >= 3) {
        assertEqualInt("objarr[2] type", objs[2].GetType(), YamlNode.TYPE_MAP());
        objs[2].GetValue("name") @=> YamlNode m2n;
        objs[2].GetValue("value") @=> YamlNode m2v;
        assertEqualString("objarr[2].name", m2n.GetString(), "test3");
        assertEqualInt("objarr[2].value", m2v.GetInt(), 3);
    }
    string outFile;
    if (gYamlParseUsedFallback == 1) { "test-object-arrays-out.yaml" => outFile; }
    else { "test/test-object-arrays-out.yaml" => outFile; }
    root.WriteFile(outFile);
    YamlNode.ParseFile(outFile) @=> YamlNode again;
    assertNodesEqual("object-arrays roundtrip", root, again);
}

fun void main()
{
    testScalarString();
    testScalarInt();
    testScalarFloat();
    testArrayScalars();
    testEmptyArray();
    testMapSetters();
    // reference tests removed
    testReadWriteNesting();
    testReadWriteNesting2();
    testObjectArraysRoundtrip();
}

main();
