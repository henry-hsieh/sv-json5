// test_smoke_msgpack_serialize.sv
module test_smoke_msgpack_serialize;
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

  // Helper to convert byte array to hex string for display
  function automatic string bytes_to_hex(byte data[]);
    string s = "";
    for (int i = 0; i < data.size(); i++) begin
      if (i > 0) s = {s, " "};
      s = {s, $sformatf("%02h", unsigned'(data[i]))};
    end
    return s;
  endfunction

  function void test_msgpack_int();
    msgpack_int ji;
    Result#(byte_array_t) res;
    $display("Testing msgpack_int...");
    ji = msgpack_int::from(42);
    res = serde_msgpack::to_array(ji);
    check("serialize msgpack_int", res.is_ok() && res.unwrap().size() == 1 && res.unwrap()[0] == 8'h2A);
  endfunction

  function void test_msgpack_uint();
    msgpack_int ju;
    Result#(byte_array_t) res;
    $display("Testing msgpack_uint...");
    ju = msgpack_int::from(200);
    res = serde_msgpack::to_array(ju);
    // uint 200 = 0xCC 0xC8
    check("serialize msgpack_uint", res.is_ok() && res.unwrap().size() == 2 && res.unwrap()[0] == 8'hCC && res.unwrap()[1] == 8'hC8);
  endfunction

  function void test_msgpack_negative_int();
    msgpack_int ji;
    Result#(byte_array_t) res;
    $display("Testing msgpack_negative_int...");
    ji = msgpack_int::from(-5);
    res = serde_msgpack::to_array(ji);
    // negative fixint -5 = 0xFB
    check("serialize msgpack_negative_int", res.is_ok() && res.unwrap().size() == 1 && res.unwrap()[0] == 8'hFB);
  endfunction

  function void test_msgpack_string();
    msgpack_string js;
    Result#(byte_array_t) res;
    $display("Testing msgpack_string...");
    js = msgpack_string::from("hi");
    res = serde_msgpack::to_array(js);
    // fixstr length 2 = 0xA2, then 'h' = 0x68, 'i' = 0x69
    check("serialize msgpack_string", res.is_ok() && res.unwrap().size() == 3 && res.unwrap()[0] == 8'hA2);
  endfunction

  function void test_msgpack_bool_true();
    msgpack_bool jb;
    Result#(byte_array_t) res;
    $display("Testing msgpack_bool_true...");
    jb = msgpack_bool::from(1);
    res = serde_msgpack::to_array(jb);
    // true = 0xC3
    check("serialize msgpack_bool_true", res.is_ok() && res.unwrap().size() == 1 && res.unwrap()[0] == 8'hC3);
  endfunction

  function void test_msgpack_bool_false();
    msgpack_bool jb;
    Result#(byte_array_t) res;
    $display("Testing msgpack_bool_false...");
    jb = msgpack_bool::from(0);
    res = serde_msgpack::to_array(jb);
    // false = 0xC2
    check("serialize msgpack_bool_false", res.is_ok() && res.unwrap().size() == 1 && res.unwrap()[0] == 8'hC2);
  endfunction

  function void test_msgpack_null();
    msgpack_null jn;
    Result#(byte_array_t) res;
    $display("Testing msgpack_null...");
    jn = msgpack_null::from();
    res = serde_msgpack::to_array(jn);
    // nil = 0xC0
    check("serialize msgpack_null", res.is_ok() && res.unwrap().size() == 1 && res.unwrap()[0] == 8'hC0);
  endfunction

  function void test_msgpack_array();
    msgpack_array ja;
    Result#(byte_array_t) res;
    $display("Testing msgpack_array...");
    ja = msgpack_array::create();
    ja.add(msgpack_int::from(1));
    ja.add(msgpack_int::from(2));
    res = serde_msgpack::to_array(ja);
    // fixarray size 2 = 0x92, then 0x01, 0x02
    $display("  res.is_ok()=%b", res.is_ok());
    if (res.is_ok()) begin
      $display("  array bytes: %s", bytes_to_hex(res.unwrap()));
    end else begin
      $display("  error: %s", res.unwrap_err());
    end
    check("serialize msgpack_array", res.is_ok() && res.unwrap().size() == 3 && res.unwrap()[0] == 8'h92);
  endfunction

  function void test_msgpack_object();
    msgpack_map jo;
    Result#(byte_array_t) res;
    $display("Testing msgpack_object...");
    jo = msgpack_map::create();
    jo.set("a", msgpack_int::from(1));
    res = serde_msgpack::to_array(jo);
    // fixmap size 1 = 0x81, fixstr len 1 = 0xA1, 'a' = 0x61, then 0x01
    $display("  res.is_ok()=%b", res.is_ok());
    if (res.is_ok()) begin
      $display("  object bytes: %s", bytes_to_hex(res.unwrap()));
    end else begin
      $display("  error: %s", res.unwrap_err());
    end
    check("serialize msgpack_object", res.is_ok() && res.unwrap().size() >= 4 && res.unwrap()[0] == 8'h81);
  endfunction

  function void test_msgpack_real();
    msgpack_real jr;
    Result#(byte_array_t) res;
    $display("Testing msgpack_real...");
    jr = msgpack_real::from(1.5);
    res = serde_msgpack::to_array(jr);
    // float64 = 0xCB
    check("serialize msgpack_real", res.is_ok() && res.unwrap().size() == 9 && res.unwrap()[0] == 8'hCB);
  endfunction

  function void test_msgpack_nested();
    msgpack_array ja;
    msgpack_map jo;
    Result#(byte_array_t) res;
    $display("Testing msgpack_nested...");
    ja = msgpack_array::create();
    jo = msgpack_map::create();
    jo.set("x", msgpack_int::from(10));
    ja.add(jo);
    res = serde_msgpack::to_array(ja);
    // fixarray size 1 = 0x91, fixmap = 0x81
    check("serialize msgpack_nested", res.is_ok() && res.unwrap().size() >= 4);
  endfunction

  initial begin
    test_msgpack_int();
    test_msgpack_uint();
    test_msgpack_negative_int();
    test_msgpack_string();
    test_msgpack_bool_true();
    test_msgpack_bool_false();
    test_msgpack_null();
    test_msgpack_array();
    test_msgpack_object();
    test_msgpack_real();
    test_msgpack_nested();

    $display("Summary: %0d passed, %0d failed", passed, failed);
    if (failed > 0) $finish(1);
    else $finish(0);
  end
endmodule
