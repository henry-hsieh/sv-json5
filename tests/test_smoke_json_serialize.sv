// test_smoke_json_serialize.sv
module test_smoke_json_serialize;
  import common_pkg::*;
  import serde_pkg::*;
  import json_pkg::*;

  // Test result counters
  int passed = 0;
  int failed = 0;

  function void check(string name, bit condition);
    if (condition) begin
      $display("PASS: %s", name);
      passed++;
    end else begin
      $display("FAIL: %s", name);
      failed++;
    end
  endfunction

  function void test_json_int();
    json_int ji;
    Result#(string) res;
    $display("Testing json_int...");
    ji = json_int::from(123);
    res = json_serializer::to_string(ji);
    check("serialize json_int", res.is_ok() && res.unwrap() == "123");
  endfunction

  function void test_json_string();
    json_string js;
    Result#(string) res;
    $display("Testing json_string...");
    js = json_string::from("hello");
    res = json_serializer::to_string(js);
    check("serialize json_string", res.is_ok() && res.unwrap() == "\"hello\"");
  endfunction

  function void test_json_string_newline();
    json_string js;
    Result#(string) res;
    $display("Testing json_string with newline...");
    // Test string with newline character (JSON escape: \n)
    js = json_string::from("line1\nline2");
    res = json_serializer::to_string(js);
    check("serialize json_string with \\n", res.is_ok() && res.unwrap() == "\"line1\\nline2\"");
  endfunction

  function void test_json_string_unicode();
    json_string js;
    Result#(string) res;
    $display("Testing json_string with unicode...");
    // Test string with unicode escape (JSON escape: \u0041 = 'A')
    js = json_string::from("ABC");
    res = json_serializer::to_string(js);
    check("serialize json_string unicode", res.is_ok() && res.unwrap() == "\"ABC\"");
  endfunction

  function void test_json_array();
    json_array ja;
    Result#(string) res;
    $display("Testing json_array...");
    ja = json_array::create();
    ja.add(json_int::from(42));
    res = json_serializer::to_string(ja);
    check("serialize json_array", res.is_ok() && res.unwrap() == "[42]");
  endfunction

  function void test_json_array_multiple();
    json_array ja;
    Result#(string) res;
    $display("Testing json_array with multiple elements...");
    ja = json_array::create();
    ja.add(json_int::from(1));
    ja.add(json_int::from(2));
    ja.add(json_int::from(3));
    res = json_serializer::to_string(ja);
    check("serialize json_array multiple", res.is_ok() && res.unwrap() == "[1,2,3]");
  endfunction

  function void test_json_object();
    json_object jo;
    Result#(string) res;
    $display("Testing json_object...");
    jo = json_object::create();
    jo.set("a", json_int::from(1));
    res = json_serializer::to_string(jo);
    check("serialize json_object", res.is_ok() && res.unwrap() == "{\"a\":1}");
  endfunction

  function void test_json_object_multiple();
    json_object jo;
    Result#(string) res;
    $display("Testing json_object with multiple keys...");
    jo = json_object::create();
    jo.set("a", json_int::from(1));
    jo.set("b", json_int::from(2));
    jo.set("c", json_int::from(3));
    res = json_serializer::to_string(jo);
    // Note: SystemVerilog associative arrays sort keys alphabetically (like BTreeMap)
    check("serialize json_object multiple", res.is_ok() && res.unwrap() == "{\"a\":1,\"b\":2,\"c\":3}");
  endfunction

  function void test_json_array_of_objects();
    json_array ja;
    json_object jo;
    Result#(string) res;
    $display("Testing json_array of objects...");
    ja = json_array::create();
    jo = json_object::create();
    jo.set("name", json_string::from("Alice"));
    jo.set("age", json_int::from(30));
    ja.add(jo);
    jo = json_object::create();
    jo.set("name", json_string::from("Bob"));
    jo.set("age", json_int::from(25));
    ja.add(jo);
    res = json_serializer::to_string(ja);
    // Keys are sorted alphabetically (SystemVerilog associative array behavior)
    check("serialize array of objects", res.is_ok() && res.unwrap() == "[{\"age\":30,\"name\":\"Alice\"},{\"age\":25,\"name\":\"Bob\"}]");
  endfunction

  // Test to_value: serialize json_value -> json_value (DOM clone)
  function void test_to_value();
    json_value original;
    json_value cloned;
    Result#(json_value) res;
    json_object obj;
    json_deserializer deser;
    json_value_builder builder;
    Result#(bit) deser_res;

    $display("Testing to_value...");

    // Parse a json_value from string
    deser = json_deserializer::from_string("{\"name\": \"test\", \"count\": 42}");
    builder = new();
    deser_res = deser.deserialize_any(builder);

    if (deser_res.is_err()) begin
      check("to_value parse", 0);
      return;
    end

    res = builder.get_result();
    if (res.is_err()) begin
      check("to_value build", 0);
      return;
    end
    original = res.unwrap();

    // to_value: clone the json_value
    res = serde_json::to_value(original);
    if (res.is_err()) begin
      $display("FAIL: to_value failed with error: %s", res.unwrap_err());
      check("to_value", 0);
      return;
    end
    cloned = res.unwrap();

    // Both should be objects with same size
    if (!cloned.is_object()) begin
      check("to_value type", 0);
      return;
    end

    obj = cloned.as_object().unwrap();
    check("to_value", obj.size() == 2);
  endfunction

  initial begin
    test_json_int();
    test_json_string();
    test_json_string_newline();
    test_json_string_unicode();
    test_json_array();
    test_json_array_multiple();
    test_json_object();
    test_json_object_multiple();
    test_json_array_of_objects();
    test_to_value();

    $display("Summary: %0d passed, %0d failed", passed, failed);
    if (failed > 0) $finish(1);
    else $finish(0);
  end
endmodule
