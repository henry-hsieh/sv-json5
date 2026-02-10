import json_pkg::*;
import common_pkg::*;
import json5_pkg::*;

module test_smoke_json5_deserialize;
  initial begin
    Result#(json_value) result;
    json_value val;
    json_object obj;
    json_array arr;

    $display("Starting JSON5 decoder tests...");

    // Test 1: Comments and trailing commas
    result = json5_deserializer::from_string("{ // single line comment\n \"a\": 1, /* multi \n line */ \"b\": 2, }");
    if (result.is_err()) begin
      $display("TEST FAILED: Comments/Trailing comma - %s", result.unwrap_err());
    end else begin
      val = result.unwrap();
      if (val.as_object().is_none()) begin
        $display("TEST FAILED: Comments/Trailing comma - not an object");
      end else begin
        obj = val.as_object().unwrap();
        if (obj.get("a").as_int().unwrap().value == 1 && obj.get("b").as_int().unwrap().value == 2) begin
          $display("TEST PASSED: Comments and trailing commas");
        end else begin
          $display("TEST FAILED: Comments/Trailing comma data mismatch");
        end
      end
    end

    // Test 2: Hex numbers and flexible decimals
    result = json5_deserializer::from_string("[0x10, .5, 5.]");
    if (result.is_err()) begin
      $display("TEST FAILED: Hex/Decimals - %s", result.unwrap_err());
    end else begin
      val = result.unwrap();
      if (val.as_array().is_none()) begin
        $display("TEST FAILED: Hex/Decimals - not an array");
      end else begin
        arr = val.as_array().unwrap();
        if (arr.get(0).as_int().unwrap().value == 16 &&
            arr.get(1).as_real().unwrap().value == 0.5 &&
            arr.get(2).as_real().unwrap().value == 5.0) begin
          $display("TEST PASSED: Hex numbers and flexible decimals");
        end else begin
          $display("TEST FAILED: Hex/Decimals data mismatch");
        end
      end
    end

    // Test 3: Single-quoted strings and unquoted keys
    result = json5_deserializer::from_string("{ unquoted_key: 'single quoted string' }");
    if (result.is_err()) begin
      $display("TEST FAILED: Unquoted keys/Single quotes - %s", result.unwrap_err());
    end else begin
      val = result.unwrap();
      if (val.as_object().is_none()) begin
        $display("TEST FAILED: Unquoted keys/Single quotes - not an object");
      end else begin
        obj = val.as_object().unwrap();
        if (obj.get("unquoted_key").as_string().unwrap().value == "single quoted string") begin
          $display("TEST PASSED: Unquoted keys and single-quoted strings");
        end else begin
          $display("TEST FAILED: Unquoted keys/Single quotes data mismatch");
        end
      end
    end

    // Test 4: Nested JSON5
    result = json5_deserializer::from_string("{ outer: { inner: [0xFF,], }, }");
    if (result.is_err()) begin
      $display("TEST FAILED: Nested JSON5 - %s", result.unwrap_err());
    end else begin
      $display("TEST PASSED: Nested JSON5");
    end

    // Test 5: Multi-line comment with special characters: , [ ] { }
    result = json5_deserializer::from_string("{a: /* , [ ] { } */ 1}");
    if (result.is_err()) begin
      $display("TEST FAILED: Multi-line comment special chars - %s", result.unwrap_err());
    end else begin
      val = result.unwrap();
      if (val.as_object().is_none()) begin
        $display("TEST FAILED: Multi-line comment special chars - not an object");
      end else begin
        obj = val.as_object().unwrap();
        if (obj.get("a").as_int().unwrap().value == 1) begin
          $display("TEST PASSED: Multi-line comment with special chars");
        end else begin
          $display("TEST FAILED: Multi-line comment special chars data mismatch");
        end
      end
    end

    // Test 6: Multi-line comment inside array
    result = json5_deserializer::from_string("[1, /* , [ ] { } */ 2, 3]");
    if (result.is_err()) begin
      $display("TEST FAILED: Multi-line comment in array - %s", result.unwrap_err());
    end else begin
      val = result.unwrap();
      if (val.as_array().is_none()) begin
        $display("TEST FAILED: Multi-line comment in array - not an array");
      end else begin
        arr = val.as_array().unwrap();
        if (arr.get(0).as_int().unwrap().value == 1 &&
            arr.get(1).as_int().unwrap().value == 2 &&
            arr.get(2).as_int().unwrap().value == 3) begin
          $display("TEST PASSED: Multi-line comment in array");
        end else begin
          $display("TEST FAILED: Multi-line comment in array data mismatch");
        end
      end
    end

    // Test 7: Multi-line comment inside object
    result = json5_deserializer::from_string("{\"a\": 1, /* , [ ] { } */ \"b\": 2}");
    if (result.is_err()) begin
      $display("TEST FAILED: Multi-line comment in object - %s", result.unwrap_err());
    end else begin
      val = result.unwrap();
      if (val.as_object().is_none()) begin
        $display("TEST FAILED: Multi-line comment in object - not an object");
      end else begin
        obj = val.as_object().unwrap();
        if (obj.get("a").as_int().unwrap().value == 1 && obj.get("b").as_int().unwrap().value == 2) begin
          $display("TEST PASSED: Multi-line comment in object");
        end else begin
          $display("TEST FAILED: Multi-line comment in object data mismatch");
        end
      end
    end

    // Test 8: Multiple special characters in comment
    result = json5_deserializer::from_string("{a: /* comment with ,[{}] */ 1, b: /* another */ 2,}");
    if (result.is_err()) begin
      $display("TEST FAILED: Multiple special chars in comments - %s", result.unwrap_err());
    end else begin
      val = result.unwrap();
      if (val.as_object().is_none()) begin
        $display("TEST FAILED: Multiple special chars in comments - not an object");
      end else begin
        obj = val.as_object().unwrap();
        if (obj.get("a").as_int().unwrap().value == 1 && obj.get("b").as_int().unwrap().value == 2) begin
          $display("TEST PASSED: Multiple special chars in comments");
        end else begin
          $display("TEST FAILED: Multiple special chars in comments data mismatch");
        end
      end
    end

    // Test 9: to_value - serialize json_value -> json_value (DOM clone) for JSON5
    begin
      json_value original;
      json_value cloned;
      Result#(json_value) res;
      json_object obj;

      $display("Testing JSON5 to_value...");

      // Parse a JSON5 value with comments and trailing commas
      result = json5_deserializer::from_string("{ a: 1, b: 2, }");
      if (result.is_err()) begin
        $display("TEST FAILED: JSON5 to_value parse - %s", result.unwrap_err());
      end else begin
        original = result.unwrap();

        // to_value: clone the json_value
        res = serde_json5::to_value(original);
        if (res.is_err()) begin
          $display("TEST FAILED: JSON5 to_value - %s", res.unwrap_err());
        end else begin
          cloned = res.unwrap();

          // Both should be objects with same size
          if (!cloned.is_object()) begin
            $display("TEST FAILED: JSON5 to_value - not a valid value");
          end else if (!cloned.is_object()) begin
            $display("TEST FAILED: JSON5 to_value - not an object");
          end else begin
            obj = cloned.as_object().unwrap();
            if (obj.size() == 2) begin
              $display("TEST PASSED: JSON5 to_value");
            end else begin
              $display("TEST FAILED: JSON5 to_value size mismatch, expected 2, got %0d", obj.size());
            end
          end
        end
      end
    end

    $display("JSON5 decoder tests completed!");
    $finish;
  end
endmodule
