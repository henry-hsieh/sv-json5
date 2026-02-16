// test_smoke_msgpack_deserialize.sv
module test_smoke_msgpack_deserialize;
  import common_pkg::*;
  import serde_pkg::*;
  import msgpack_pkg::*;

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

  function void test_deserialize_int();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize int...");
    // positive fixint 42 = 0x2A
    data = '{8'h2A};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize int", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_int());
  endfunction

  function void test_deserialize_uint();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize uint...");
    // uint8 200 = 0xCC 0xC8
    data = '{8'hCC, 8'hC8};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize uint", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_int());
  endfunction

  function void test_deserialize_negative_int();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize negative int...");
    // negative fixint -5 = 0xFB
    data = '{8'hFB};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize negative int", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_int());
  endfunction

  function void test_deserialize_string();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize string...");
    // fixstr "ab" = 0xA2 'a' 'b'
    data = '{8'hA2, 8'h61, 8'h62};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize string", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_string());
  endfunction

  function void test_deserialize_bool_true();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize bool true...");
    // true = 0xC3
    data = '{8'hC3};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize bool true", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_bool());
  endfunction

  function void test_deserialize_bool_false();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize bool false...");
    // false = 0xC2
    data = '{8'hC2};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize bool false", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_bool());
  endfunction

  function void test_deserialize_null();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize null...");
    // nil = 0xC0
    data = '{8'hC0};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize null", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_null());
  endfunction

  function void test_deserialize_array();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize array...");
    // fixarray [1, 2] = 0x92 0x01 0x02
    data = '{8'h92, 8'h01, 8'h02};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize array", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_array());
  endfunction

  function void test_deserialize_object();
    byte data[];
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;
    $display("Testing deserialize object...");
    // fixmap {"a":1} = 0x81 0xA1 'a' 0x01
    data = '{8'h81, 8'hA1, 8'h61, 8'h01};
    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    check("deserialize object", res.is_ok() && builder.get_result().is_ok() && builder.get_result().unwrap().is_map());
  endfunction

  function void test_roundtrip_int();
    msgpack_int mi;
    msgpack_serializer ser;
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) ser_res;
    Result#(bit) deser_res;
    $display("Testing roundtrip int...");
    mi = msgpack_int::from(123);
    ser = new();
    ser_res = mi.serialize(ser);
    if (ser_res.is_err()) begin
      check("roundtrip int", 0);
      return;
    end
    deser = new(ser.get_array());
    builder = new();
    deser_res = deser.deserialize_any(builder);
    check("roundtrip int", deser_res.is_ok() && builder.get_result().is_ok());
  endfunction

  function void test_roundtrip_string();
    msgpack_string ms;
    msgpack_serializer ser;
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) ser_res;
    Result#(bit) deser_res;
    $display("Testing roundtrip string...");
    ms = msgpack_string::from("hello");
    ser = new();
    ser_res = ms.serialize(ser);
    if (ser_res.is_err()) begin
      check("roundtrip string", 0);
      return;
    end
    deser = new(ser.get_array());
    builder = new();
    deser_res = deser.deserialize_any(builder);
    check("roundtrip string", deser_res.is_ok() && builder.get_result().is_ok());
  endfunction

  function void test_roundtrip_object();
    msgpack_map mo;
    msgpack_serializer ser;
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) ser_res;
    Result#(bit) deser_res;
    $display("Testing roundtrip object...");
    mo = msgpack_map::create();
    mo.set("name", msgpack_string::from("test"));
    mo.set("value", msgpack_int::from(42));
    ser = new();
    ser_res = mo.serialize(ser);
    if (ser_res.is_err()) begin
      check("roundtrip object", 0);
      return;
    end
    deser = new(ser.get_array());
    builder = new();
    deser_res = deser.deserialize_any(builder);
    check("roundtrip object", deser_res.is_ok() && builder.get_result().is_ok());
  endfunction

  initial begin
    test_deserialize_int();
    test_deserialize_uint();
    test_deserialize_negative_int();
    test_deserialize_string();
    test_deserialize_bool_true();
    test_deserialize_bool_false();
    test_deserialize_null();
    test_deserialize_array();
    test_deserialize_object();
    test_roundtrip_int();
    test_roundtrip_string();
    test_roundtrip_object();

    $display("Summary: %0d passed, %0d failed", passed, failed);
    if (failed > 0) $finish(1);
    else $finish(0);
  end
endmodule
