module test_smoke_json_types;
  import common_pkg::*;
  import json_pkg::*;

  initial begin
    test_int();
    test_real();
    test_string();
    test_bool();
    test_null();
    test_array();
    test_object();
    $display("All json types smoke tests passed!");
    $finish;
  end

  task automatic test_int();
    json_int i1 = new(42);
    json_int i2 = new(42);
    json_int i3 = new(100);
    json_value v;
    Option#(json_int) opt_int;

    // Test value access
    if (i1.value != 42) begin $display("i1.value failed"); $fatal(1); end

    // Test equals
    if (!i1.equals(i2)) begin $display("i1.equals(i2) failed"); $fatal(1); end
    if (i1.equals(i3)) begin $display("i1.equals(i3) should fail"); $fatal(1); end

    // Test is_* methods
    if (!i1.is_int()) begin $display("i1.is_int() failed"); $fatal(1); end
    if (i1.is_real()) begin $display("i1.is_real() should be false"); $fatal(1); end
    if (i1.is_string()) begin $display("i1.is_string() should be false"); $fatal(1); end
    if (i1.is_bool()) begin $display("i1.is_bool() should be false"); $fatal(1); end
    if (i1.is_null()) begin $display("i1.is_null() should be false"); $fatal(1); end
    if (i1.is_array()) begin $display("i1.is_array() should be false"); $fatal(1); end
    if (i1.is_object()) begin $display("i1.is_object() should be false"); $fatal(1); end

    // Test as_* methods
    opt_int = i1.as_int();
    if (opt_int.is_none()) begin $display("i1.as_int() should return Some"); $fatal(1); end
    if (opt_int.unwrap().value != 42) begin $display("i1.as_int().unwrap() failed"); $fatal(1); end
    if (!i1.as_string().is_none()) begin $display("i1.as_string() should be None"); $fatal(1); end
    if (!i1.as_real().is_none()) begin $display("i1.as_real() should be None"); $fatal(1); end
    if (!i1.as_bool().is_none()) begin $display("i1.as_bool() should be None"); $fatal(1); end
    if (!i1.as_null().is_none()) begin $display("i1.as_null() should be None"); $fatal(1); end
    if (!i1.as_array().is_none()) begin $display("i1.as_array() should be None"); $fatal(1); end
    if (!i1.as_object().is_none()) begin $display("i1.as_object() should be None"); $fatal(1); end

    // Test clone
    v = i1.clone();
    if (!v.is_int()) begin $display("clone should be json_int"); $fatal(1); end
    if (!v.equals(i1)) begin $display("clone should equal original"); $fatal(1); end

    // Test static from method
    i3 = json_int::from(200);
    if (i3.value != 200) begin $display("json_int::from() failed"); $fatal(1); end

    $display("test_int passed");
  endtask

  task automatic test_real();
    json_real r1 = new(3.14);
    json_real r2 = new(3.14);
    json_real r3 = new(1.23);
    json_value v;
    Option#(json_real) opt_real;

    // Test value access
    if (r1.value != 3.14) begin $display("r1.value failed"); $fatal(1); end

    // Test equals
    if (!r1.equals(r2)) begin $display("r1.equals(r2) failed"); $fatal(1); end
    if (r1.equals(r3)) begin $display("r1.equals(r3) should fail"); $fatal(1); end

    // Test is_* methods
    if (!r1.is_real()) begin $display("r1.is_real() failed"); $fatal(1); end
    if (r1.is_int()) begin $display("r1.is_int() should be false"); $fatal(1); end
    if (r1.is_string()) begin $display("r1.is_string() should be false"); $fatal(1); end
    if (r1.is_bool()) begin $display("r1.is_bool() should be false"); $fatal(1); end

    // Test as_* methods
    opt_real = r1.as_real();
    if (opt_real.is_none()) begin $display("r1.as_real() should return Some"); $fatal(1); end
    if (opt_real.unwrap().value != 3.14) begin $display("r1.as_real().unwrap() failed"); $fatal(1); end
    if (!r1.as_int().is_none()) begin $display("r1.as_int() should be None"); $fatal(1); end
    if (!r1.as_string().is_none()) begin $display("r1.as_string() should be None"); $fatal(1); end

    // Test clone
    v = r1.clone();
    if (!v.is_real()) begin $display("clone should be json_real"); $fatal(1); end
    if (!v.equals(r1)) begin $display("clone should equal original"); $fatal(1); end

    // Test static from method
    r3 = json_real::from(2.718);
    if (r3.value != 2.718) begin $display("json_real::from() failed"); $fatal(1); end

    $display("test_real passed");
  endtask

  task automatic test_string();
    json_string s1 = new("hello");
    json_string s2 = new("hello");
    json_string s3 = new("world");
    json_value v;
    Option#(json_string) opt_str;

    // Test value access
    if (s1.value != "hello") begin $display("s1.value failed"); $fatal(1); end

    // Test equals
    if (!s1.equals(s2)) begin $display("s1.equals(s2) failed"); $fatal(1); end
    if (s1.equals(s3)) begin $display("s1.equals(s3) should fail"); $fatal(1); end

    // Test is_* methods
    if (!s1.is_string()) begin $display("s1.is_string() failed"); $fatal(1); end
    if (s1.is_int()) begin $display("s1.is_int() should be false"); $fatal(1); end
    if (s1.is_real()) begin $display("s1.is_real() should be false"); $fatal(1); end

    // Test as_* methods
    opt_str = s1.as_string();
    if (opt_str.is_none()) begin $display("s1.as_string() should return Some"); $fatal(1); end
    if (opt_str.unwrap().value != "hello") begin $display("s1.as_string().unwrap() failed"); $fatal(1); end
    if (!s1.as_int().is_none()) begin $display("s1.as_int() should be None"); $fatal(1); end

    // Test clone
    v = s1.clone();
    if (!v.is_string()) begin $display("clone should be json_string"); $fatal(1); end
    if (!v.equals(s1)) begin $display("clone should equal original"); $fatal(1); end

    // Test static from method
    s3 = json_string::from("test");
    if (s3.value != "test") begin $display("json_string::from() failed"); $fatal(1); end

    $display("test_string passed");
  endtask

  task automatic test_bool();
    json_bool b1 = new(1);
    json_bool b2 = new(1);
    json_bool b3 = new(0);
    json_value v;
    Option#(json_bool) opt_bool;

    // Test value access
    if (b1.value != 1) begin $display("b1.value failed"); $fatal(1); end
    if (b3.value != 0) begin $display("b3.value failed"); $fatal(1); end

    // Test equals
    if (!b1.equals(b2)) begin $display("b1.equals(b2) failed"); $fatal(1); end
    if (b1.equals(b3)) begin $display("b1.equals(b3) should fail"); $fatal(1); end

    // Test is_* methods
    if (!b1.is_bool()) begin $display("b1.is_bool() failed"); $fatal(1); end
    if (b1.is_int()) begin $display("b1.is_int() should be false"); $fatal(1); end
    if (b1.is_null()) begin $display("b1.is_null() should be false"); $fatal(1); end

    // Test as_* methods
    opt_bool = b1.as_bool();
    if (opt_bool.is_none()) begin $display("b1.as_bool() should return Some"); $fatal(1); end
    if (opt_bool.unwrap().value != 1) begin $display("b1.as_bool().unwrap() failed"); $fatal(1); end
    if (!b1.as_int().is_none()) begin $display("b1.as_int() should be None"); $fatal(1); end

    // Test clone
    v = b1.clone();
    if (!v.is_bool()) begin $display("clone should be json_bool"); $fatal(1); end
    if (!v.equals(b1)) begin $display("clone should equal original"); $fatal(1); end

    // Test static from method
    b3 = json_bool::from(0);
    if (b3.value != 0) begin $display("json_bool::from() failed"); $fatal(1); end

    $display("test_bool passed");
  endtask

  task automatic test_null();
    json_null n1 = new();
    json_null n2 = new();
    json_int i1 = new(0);
    json_value v;
    Option#(json_null) opt_null;

    // Test equals
    if (!n1.equals(n2)) begin $display("n1.equals(n2) failed"); $fatal(1); end
    if (n1.equals(i1)) begin $display("n1.equals(i1) should fail"); $fatal(1); end

    // Test is_* methods
    if (!n1.is_null()) begin $display("n1.is_null() failed"); $fatal(1); end
    if (n1.is_int()) begin $display("n1.is_int() should be false"); $fatal(1); end
    if (n1.is_bool()) begin $display("n1.is_bool() should be false"); $fatal(1); end
    if (n1.is_string()) begin $display("n1.is_string() should be false"); $fatal(1); end

    // Test as_* methods
    opt_null = n1.as_null();
    if (opt_null.is_none()) begin $display("n1.as_null() should return Some"); $fatal(1); end
    if (!n1.as_int().is_none()) begin $display("n1.as_int() should be None"); $fatal(1); end

    // Test clone
    v = n1.clone();
    if (!v.is_null()) begin $display("clone should be json_null"); $fatal(1); end
    if (!v.equals(n1)) begin $display("clone should equal original"); $fatal(1); end

    // Test static from method
    n2 = json_null::from();
    if (!n2.is_null()) begin $display("json_null::from() failed"); $fatal(1); end

    $display("test_null passed");
  endtask

  task automatic test_array();
    json_array a1 = json_array::create();
    json_array a2 = json_array::create();
    json_int i1 = new(1);
    json_int i2 = new(2);
    json_string s1 = new("test");
    json_value v;
    Option#(json_array) opt_arr;

    // Test add and size
    a1.add(i1);
    a1.add(i2);
    a1.add(s1);
    if (a1.size() != 3) begin $display("a1.size() should be 3"); $fatal(1); end

    // Test get
    if (!a1.get(0).equals(i1)) begin $display("a1.get(0) failed"); $fatal(1); end
    if (!a1.get(1).equals(i2)) begin $display("a1.get(1) failed"); $fatal(1); end
    if (!a1.get(2).equals(s1)) begin $display("a1.get(2) failed"); $fatal(1); end

    // Test push_front, push_back
    a2.push_back(i1);
    a2.push_front(i2);
    if (a2.size() != 2) begin $display("a2.size() should be 2"); $fatal(1); end
    if (!a2.get(0).equals(i2)) begin $display("a2.get(0) should be i2 after push_front"); $fatal(1); end

    // Test set
    a2.set(0, s1);
    if (!a2.get(0).equals(s1)) begin $display("a2.set() failed"); $fatal(1); end

    // Test insert, delete_item
    a2.insert(1, i1);
    if (a2.size() != 3) begin $display("a2.size() should be 3 after insert"); $fatal(1); end
    a2.delete_item(1);
    if (a2.size() != 2) begin $display("a2.size() should be 2 after delete"); $fatal(1); end

    // Test is_empty, clear
    if (a2.is_empty()) begin $display("a2 should not be empty"); $fatal(1); end
    a2.clear();
    if (!a2.is_empty()) begin $display("a2 should be empty after clear"); $fatal(1); end

    // Test is_* methods
    if (!a1.is_array()) begin $display("a1.is_array() failed"); $fatal(1); end
    if (a1.is_object()) begin $display("a1.is_object() should be false"); $fatal(1); end

    // Test as_* methods
    opt_arr = a1.as_array();
    if (opt_arr.is_none()) begin $display("a1.as_array() should return Some"); $fatal(1); end
    if (!a1.as_object().is_none()) begin $display("a1.as_object() should be None"); $fatal(1); end

    // Test equals
    a2.add(i1.clone());
    a2.add(i2.clone());
    a2.add(s1.clone());
    if (!a1.equals(a2)) begin $display("a1.equals(a2) failed"); $fatal(1); end

    // Test clone
    v = a1.clone();
    if (!v.is_array()) begin $display("clone should be json_array"); $fatal(1); end
    if (!v.equals(a1)) begin $display("clone should equal original"); $fatal(1); end

    // Test pop_front, pop_back
    v = a1.pop_front();
    if (!v.equals(i1)) begin $display("pop_front failed"); $fatal(1); end
    v = a1.pop_back();
    if (!v.equals(s1)) begin $display("pop_back failed"); $fatal(1); end
    if (a1.size() != 1) begin $display("a1.size() should be 1 after pops"); $fatal(1); end

    $display("test_array passed");
  endtask

  task automatic test_object();
    json_object o1 = json_object::create();
    json_object o2 = json_object::create();
    json_int i1 = new(42);
    json_string s1 = new("value");
    json_value v;
    Option#(json_object) opt_obj;
    string_queue_t keys;
    json_value_queue_t vals;

    // Test set, get, has
    o1.set("num", i1);
    o1.set("str", s1);
    if (!o1.has("num")) begin $display("o1.has('num') failed"); $fatal(1); end
    if (!o1.has("str")) begin $display("o1.has('str') failed"); $fatal(1); end
    if (o1.has("missing")) begin $display("o1.has('missing') should be false"); $fatal(1); end
    if (!o1.get("num").equals(i1)) begin $display("o1.get('num') failed"); $fatal(1); end
    if (!o1.get("str").equals(s1)) begin $display("o1.get('str') failed"); $fatal(1); end

    // Test size
    if (o1.size() != 2) begin $display("o1.size() should be 2"); $fatal(1); end

    // Test keys, values
    keys = o1.keys();
    vals = o1.values();
    if (keys.size() != 2) begin $display("keys.size() should be 2"); $fatal(1); end
    if (vals.size() != 2) begin $display("values.size() should be 2"); $fatal(1); end

    // Test is_empty, clear
    if (o1.is_empty()) begin $display("o1 should not be empty"); $fatal(1); end
    o2.set("temp", i1);
    o2.clear();
    if (!o2.is_empty()) begin $display("o2 should be empty after clear"); $fatal(1); end

    // Test remove
    o2.set("a", i1);
    o2.set("b", s1);
    o2.remove("a");
    if (o2.has("a")) begin $display("o2.remove('a') failed"); $fatal(1); end
    if (!o2.has("b")) begin $display("o2 should still have 'b'"); $fatal(1); end

    // Test is_* methods
    if (!o1.is_object()) begin $display("o1.is_object() failed"); $fatal(1); end
    if (o1.is_array()) begin $display("o1.is_array() should be false"); $fatal(1); end

    // Test as_* methods
    opt_obj = o1.as_object();
    if (opt_obj.is_none()) begin $display("o1.as_object() should return Some"); $fatal(1); end
    if (!o1.as_array().is_none()) begin $display("o1.as_array() should be None"); $fatal(1); end

    // Test equals
    o2.clear();
    o2.set("num", i1.clone());
    o2.set("str", s1.clone());
    if (!o1.equals(o2)) begin $display("o1.equals(o2) failed"); $fatal(1); end

    // Test clone
    v = o1.clone();
    if (!v.is_object()) begin $display("clone should be json_object"); $fatal(1); end
    if (!v.equals(o1)) begin $display("clone should equal original"); $fatal(1); end

    // Test null return for missing key
    if (o1.get("nonexistent") != null) begin $display("get('nonexistent') should return null"); $fatal(1); end

    $display("test_object passed");
  endtask

endmodule
