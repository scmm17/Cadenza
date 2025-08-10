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
    else if (ta == 4) { // ref
        a.GetNode() @=> YamlNode ar;
        b.GetNode() @=> YamlNode br;
        if (ar == null && br == null) return 1;
        if (ar == null || br == null) return 0;
        return nodesDeepEqual(ar, br);
    }
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

// Test a node of type ref (4) that references a scalar
fun void testRefToScalar()
{
    YamlNode target(""); target.SetString("ref-value");
    YamlNode refNode("myref"); refNode.SetNode(target);
    string file;
    "test-yaml-ref-scalar.yaml" => file;
    refNode.WriteFile(file);
    // On read, ref is inlined, so we expect the scalar value under the ref name
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("ref->scalar name", m.GetName(), "myref");
    assertEqualInt("ref->scalar parsed type", m.GetType(), YamlNode.TYPE_STRING());
    assertEqualString("ref->scalar parsed value", m.GetString(), "ref-value");
}

// Test a node of type ref (4) that references an array of scalars
fun void testRefToArray()
{
    YamlNode a(""); a.SetString("a");
    YamlNode b(""); b.SetInt(2);
    YamlNode c(""); c.SetFloat(3.0);
    YamlNode items[0]; items << a; items << b; items << c;
    YamlNode arr(""); arr.SetArray(items);

    YamlNode refNode("refarray"); refNode.SetNode(arr);
    string file;
    "test-yaml-ref-array.yaml" => file;
    refNode.WriteFile(file);

    // On read, ref is inlined, so we expect the array content under the ref name
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("ref->array name", m.GetName(), "refarray");
    assertEqualInt("ref->array parsed type", m.GetType(), YamlNode.TYPE_ARRAY());
    m.GetArray() @=> YamlNode back[];
    assertEqualInt("ref->array size", back.cap(), 3);
    assertEqualString("ref->array[0]", back[0].GetString(), "a");
    assertEqualInt("ref->array[1]", back[1].GetInt(), 2);
    assertEqualFloat("ref->array[2]", back[2].GetFloat(), 3.0);
}

// Nested: ref to ref to scalar
fun void testNestedRefToScalar()
{
    YamlNode leaf(""); leaf.SetString("nested-s");
    YamlNode innerRef(""); innerRef.SetNode(leaf);
    YamlNode outerRef("outerScalar"); outerRef.SetNode(innerRef);
    string file;
    "test-yaml-nested-ref-scalar.yaml" => file;
    outerRef.WriteFile(file);
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("nested scalar name", m.GetName(), "outerScalar");
    assertEqualInt("nested scalar type", m.GetType(), YamlNode.TYPE_STRING());
    assertEqualString("nested scalar value", m.GetString(), "nested-s");
}

// Nested: ref to ref to array
fun void testNestedRefToArray()
{
    YamlNode x(""); x.SetString("x");
    YamlNode y(""); y.SetInt(9);
    YamlNode z(""); z.SetFloat(1.25);
    YamlNode arrItems[0]; arrItems << x; arrItems << y; arrItems << z;
    YamlNode arrNode(""); arrNode.SetArray(arrItems);
    YamlNode innerRef(""); innerRef.SetNode(arrNode);
    YamlNode outerRef("outerArray"); outerRef.SetNode(innerRef);
    string file;
    "test-yaml-nested-ref-array.yaml" => file;
    outerRef.WriteFile(file);
    YamlNode.ParseFile(file) @=> YamlNode m;
    assertEqualString("nested array name", m.GetName(), "outerArray");
    assertEqualInt("nested array type", m.GetType(), YamlNode.TYPE_ARRAY());
    m.GetArray() @=> YamlNode back[];
    assertEqualInt("nested array size", back.cap(), 3);
    assertEqualString("nested array [0]", back[0].GetString(), "x");
    assertEqualInt("nested array [1]", back[1].GetInt(), 9);
    assertEqualFloat("nested array [2]", back[2].GetFloat(), 1.25);
}

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

fun void main()
{
    testScalarString();
    testScalarInt();
    testScalarFloat();
    testArrayScalars();
    testEmptyArray();
    testRefToScalar();
    testRefToArray();
    testNestedRefToScalar();
    testNestedRefToArray();
    testReadWriteNesting();
    testReadWriteNesting2();
}

main();
