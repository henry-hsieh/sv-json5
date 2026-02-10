// test_smoke_serde.sv - Smoke tests for serde traits (independent of JSON implementation)
module test_smoke_serde;
  import common_pkg::*;
  import serde_pkg::*;

  // === Section 1: Mock classes ===

  // Simple integer wrapper
  class my_int;
    longint value;

    function new(longint v = 0);
      value = v;
    endfunction
  endclass

  // Mock serializer
  class tracking_serializer extends serde_serializer;
    string result = "";
    int call_count = 0;

    virtual function Result#(bit) serialize_int(longint val);
      result = {result, $sformatf("%0d", val)};
      call_count++;
      return Result#(bit)::Ok(1);
    endfunction

    virtual function Result#(bit) serialize_string(string val);
      result = {result, "\"", val, "\""};
      call_count++;
      return Result#(bit)::Ok(1);
    endfunction

    virtual function Result#(bit) serialize_bool(bit val);
      result = {result, val ? "true" : "false"};
      call_count++;
      return Result#(bit)::Ok(1);
    endfunction
  endclass

  // Mock deserializer
  class mock_deserializer extends serde_deserializer;
    virtual function Result#(longint) deserialize_int();
      return Result#(longint)::Ok(42);
    endfunction

    virtual function Result#(string) deserialize_string();
      return Result#(string)::Ok("hello");
    endfunction

    virtual function Result#(bit) deserialize_bool();
      return Result#(bit)::Ok(1);
    endfunction
  endclass

  // Simple mock visitor
  class mock_visitor extends serde_visitor;
    string visited = "";
    virtual function Result#(bit) visit_int(longint v);
      visited = {visited, "int:", $sformatf("%0d", v)};
      return Result#(bit)::Ok(1);
    endfunction
    virtual function Result#(bit) visit_string(string v);
      visited = {visited, "str:", v};
      return Result#(bit)::Ok(1);
    endfunction
  endclass

  // Test class extending the virtual base class
  class test_deserializer extends serde_deserializer;
    // No implementation needed, just verifying base class methods
  endclass

  // === Section 2 & 3: Tests ===
  initial begin
    // Variable declarations (must be at beginning of block)
    Result#(bit) res;
    Result#(longint) int_res;
    Result#(bit) more_res;
    tracking_serializer ser;
    mock_deserializer deser;
    test_deserializer t_deser;
    serde_visitor v;
    mock_visitor vis;
    int passed;
    int failed;

    // Initialize
    passed = 0;
    failed = 0;

    $display("=== Section 2: Serde Trait Tests ===");

    // Test 1: Default error implementations
    ser = new();
    res = ser.serialize_real(3.14);
    if (res.is_err()) begin
      $display("PASS: Default error - serialize_real");
      passed++;
    end else begin
      $display("FAIL: Default error - serialize_real should fail");
      failed++;
    end

    // Test 2: Successful serialization
    ser = new();
    res = ser.serialize_int(42);
    if (res.is_ok() && ser.result == "42") begin
      $display("PASS: Serialize int");
      passed++;
    end else begin
      $display("FAIL: Serialize int");
      failed++;
    end

    // Test 3: Successful deserialization
    deser = new();
    int_res = deser.deserialize_int();
    if (int_res.is_ok() && int_res.unwrap() == 42) begin
      $display("PASS: Deserialize int");
      passed++;
    end else begin
      $display("FAIL: Deserialize int");
      failed++;
    end

    // Test 4: is_human_readable default
    if (ser.is_human_readable() == 1) begin
      $display("PASS: is_human_readable defaults to 1");
      passed++;
    end else begin
      $display("FAIL: is_human_readable default");
      failed++;
    end

    // Test 5: Base serde_deserializer default implementations
    t_deser = new();
    v = null;

    // check_has_more default should return 1 (has more)
    more_res = t_deser.check_has_more();
    if (more_res.is_ok() && more_res.unwrap() === 1) begin
      $display("PASS: check_has_more default is 1");
      passed++;
    end else begin
      $display("FAIL: check_has_more default");
      failed++;
    end

    // deserialize_any default should return error
    res = t_deser.deserialize_any(v);
    if (res.is_err() && res.unwrap_err() == "deserialize_any not implemented") begin
      $display("PASS: deserialize_any default returns error");
      passed++;
    end else begin
      $display("FAIL: deserialize_any default");
      failed++;
    end

    // Test 6: Visitor pattern
    vis = new();
    res = vis.visit_int(100);
    if (res.is_ok()) begin
      $display("PASS: Visitor pattern works");
      passed++;
    end else begin
      $display("FAIL: Visitor pattern");
      failed++;
    end

    // Summary
    $display("");
    $display("Results: %0d passed, %0d failed", passed, failed);
    if (failed == 0) begin
      $display("=== ALL TESTS PASSED ===");
    end else begin
      $display("=== SOME TESTS FAILED ===");
    end
    $finish(failed > 0 ? 1 : 0);
  end
endmodule
