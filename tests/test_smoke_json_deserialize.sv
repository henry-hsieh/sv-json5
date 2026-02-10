module test_smoke_json_deserialize;
  import common_pkg::*;
  import serde_pkg::*;
  import json_pkg::*;

  initial begin
    Result#(json_value) result;
    Result#(bit) res;
    json_value val;
    json_object obj;
    json_array arr;
    json_int jint;
    json_value inner_val;
    json_object inner_obj;
    json_value final_val;
    json_deserializer deser;
    json_value_builder builder;
    bit all_passed = 1;

    $display("Starting JSON deserializer smoke tests...");
    $display("==========================================");

    // Test 1: Parse simple object
    deser = json_deserializer::from_string("{\"name\": \"test\", \"value\": 42}");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Simple object parsing - deserialization error");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_object()) begin
          $display("TEST FAILED: Expected object");
          all_passed = 0;
        end else begin
          if (val.as_object().is_none()) begin
            $display("TEST FAILED: as_object returned None");
            all_passed = 0;
          end else begin
            obj = val.as_object().unwrap();
            if (obj.get("name") == null) begin
              $display("TEST FAILED: name field not found");
              all_passed = 0;
            end else if (!obj.get("name").is_string()) begin
              $display("TEST FAILED: name field is not string");
              all_passed = 0;
            end else if (obj.get("name").as_string().unwrap().value != "test") begin
              $display("TEST FAILED: name field mismatch");
              all_passed = 0;
            end else if (obj.get("value") == null) begin
              $display("TEST FAILED: value field not found");
              all_passed = 0;
            end else if (!obj.get("value").is_int()) begin
              $display("TEST FAILED: value field is not int");
              all_passed = 0;
            end else if (obj.get("value").as_int().unwrap().value != 42) begin
              $display("TEST FAILED: value field mismatch");
              all_passed = 0;
            end else begin
              $display("TEST PASSED: Simple object");
            end
          end
        end
      end
    end

    // Test 2: Parse array
    deser = json_deserializer::from_string("[1, 2, 3]");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Array parsing");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for array");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_array()) begin
          $display("TEST FAILED: Expected array");
          all_passed = 0;
        end else begin
          if (val.as_array().is_none()) begin
            $display("TEST FAILED: as_array returned None");
            all_passed = 0;
          end else begin
            arr = val.as_array().unwrap();
            if (arr.size() != 3) begin
              $display("TEST FAILED: Array size mismatch, expected 3, got %0d", arr.size());
              all_passed = 0;
            end else if (arr.get(0) == null || !arr.get(0).is_int()) begin
              $display("TEST FAILED: First element should be int");
              all_passed = 0;
            end else if (arr.get(0).as_int().unwrap().value != 1) begin
              $display("TEST FAILED: First element value mismatch");
              all_passed = 0;
            end else begin
              $display("TEST PASSED: Array");
            end
          end
        end
      end
    end

    // Test 3: Parse string
    deser = json_deserializer::from_string("\"hello world\"");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: String parsing");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for string");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_string()) begin
          $display("TEST FAILED: Expected string");
          all_passed = 0;
        end else begin
          $display("TEST PASSED: String");
        end
      end
    end

    // Test 4: Parse number
    deser = json_deserializer::from_string("123");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Number parsing");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for number");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_int()) begin
          $display("TEST FAILED: Expected int");
          all_passed = 0;
        end else begin
          if (val.as_int().is_none()) begin
            $display("TEST FAILED: as_int returned None");
            all_passed = 0;
          end else begin
            jint = val.as_int().unwrap();
            if (jint.value != 123) begin
              $display("TEST FAILED: Number value mismatch");
              all_passed = 0;
            end else begin
              $display("TEST PASSED: Number");
            end
          end
        end
      end
    end

    // Test 5: Parse true
    deser = json_deserializer::from_string("true");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: True parsing");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for true");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_bool()) begin
          $display("TEST FAILED: Expected bool");
          all_passed = 0;
        end else begin
          $display("TEST PASSED: True");
        end
      end
    end

    // Test 6: Parse false
    deser = json_deserializer::from_string("false");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: False parsing");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for false");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_bool()) begin
          $display("TEST FAILED: Expected bool");
          all_passed = 0;
        end else begin
          $display("TEST PASSED: False");
        end
      end
    end

    // Test 7: Parse null
    deser = json_deserializer::from_string("null");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Null parsing");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for null");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_null()) begin
          $display("TEST FAILED: Expected null");
          all_passed = 0;
        end else begin
          $display("TEST PASSED: Null");
        end
      end
    end

    // Test 8: Nested object
    deser = json_deserializer::from_string("{\"outer\": {\"inner\": \"value\"}}");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Nested object - deserialization error");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for nested object");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_object()) begin
          $display("TEST FAILED: Expected outer object");
          all_passed = 0;
        end else begin
          if (val.as_object().is_none()) begin
            $display("TEST FAILED: as_object returned None for outer");
            all_passed = 0;
          end else begin
            obj = val.as_object().unwrap();
            if (obj.get("outer") == null) begin
              $display("TEST FAILED: outer field not found");
              all_passed = 0;
            end else begin
              inner_val = obj.get("outer");
              if (!inner_val.is_object()) begin
                $display("TEST FAILED: inner is not object, type check");
                all_passed = 0;
              end else begin
                if (inner_val.as_object().is_none()) begin
                  $display("TEST FAILED: as_object returned None for inner");
                  all_passed = 0;
                end else begin
                  inner_obj = inner_val.as_object().unwrap();
                  if (inner_obj.get("inner") == null) begin
                    $display("TEST FAILED: inner field not found");
                    all_passed = 0;
                  end else begin
                    final_val = inner_obj.get("inner");
                    if (!final_val.is_string()) begin
                      $display("TEST FAILED: final is not string");
                      all_passed = 0;
                    end else if (final_val.as_string().is_none()) begin
                      $display("TEST FAILED: as_string returned None");
                      all_passed = 0;
                    end else if (final_val.as_string().unwrap().value != "value") begin
                      $display("TEST FAILED: Value mismatch");
                      all_passed = 0;
                    end else begin
                      $display("TEST PASSED: Nested object");
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    // Test 9: Mixed array
    deser = json_deserializer::from_string("[1, \"two\", true, null]");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Mixed array");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for mixed array");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_array()) begin
          $display("TEST FAILED: Expected array");
          all_passed = 0;
        end else begin
          if (val.as_array().is_none()) begin
            $display("TEST FAILED: as_array returned None");
            all_passed = 0;
          end else begin
            arr = val.as_array().unwrap();
            if (arr.size() != 4) begin
              $display("TEST FAILED: Mixed array size mismatch, expected 4, got %0d", arr.size());
              all_passed = 0;
            end else if (arr.get(0) == null || !arr.get(0).is_int()) begin
              $display("TEST FAILED: First element should be int");
              all_passed = 0;
            end else if (arr.get(1) == null || !arr.get(1).is_string()) begin
              $display("TEST FAILED: Second element should be string");
              all_passed = 0;
            end else if (arr.get(2) == null || !arr.get(2).is_bool()) begin
              $display("TEST FAILED: Third element should be bool");
              all_passed = 0;
            end else if (arr.get(3) == null || !arr.get(3).is_null()) begin
              $display("TEST FAILED: Fourth element should be null");
              all_passed = 0;
            end else begin
              $display("TEST PASSED: Mixed array");
            end
          end
        end
      end
    end

    // Test 10: Empty object
    deser = json_deserializer::from_string("{}");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Empty object");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for empty object");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_object()) begin
          $display("TEST FAILED: Expected object");
          all_passed = 0;
        end else begin
          if (val.as_object().is_none()) begin
            $display("TEST FAILED: as_object returned None");
            all_passed = 0;
          end else begin
            obj = val.as_object().unwrap();
            if (!obj.is_empty()) begin
              $display("TEST FAILED: Expected empty object");
              all_passed = 0;
            end else begin
              $display("TEST PASSED: Empty object");
            end
          end
        end
      end
    end

    // Test 11: Empty array
    deser = json_deserializer::from_string("[]");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Empty array");
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder get_result failed for empty array");
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_array()) begin
          $display("TEST FAILED: Expected array");
          all_passed = 0;
        end else begin
          if (val.as_array().is_none()) begin
            $display("TEST FAILED: as_array returned None");
            all_passed = 0;
          end else begin
            arr = val.as_array().unwrap();
            if (!arr.is_empty()) begin
              $display("TEST FAILED: Expected empty array, got size %0d", arr.size());
              all_passed = 0;
            end else begin
              $display("TEST PASSED: Empty array");
            end
          end
        end
      end
    end

    // Test 12: Builder integration test
    deser = json_deserializer::from_string("[123]");
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      $display("TEST FAILED: Builder integration - deserialize_any: %s", res.unwrap_err());
      all_passed = 0;
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("TEST FAILED: Builder integration - get_result: %s", result.unwrap_err());
        all_passed = 0;
      end else begin
        val = result.unwrap();
        if (!val.is_array()) begin
          $display("TEST FAILED: Builder integration - Expected array");
          all_passed = 0;
        end else begin
          arr = val.as_array().unwrap();
          if (arr.size() != 1) begin
            $display("TEST FAILED: Builder integration - Expected array size 1, got %0d", arr.size());
            all_passed = 0;
          end else begin
            json_value first = arr.get(0);
            if (!first.is_int()) begin
              $display("TEST FAILED: Builder integration - Expected int");
              all_passed = 0;
            end else begin
              jint = first.as_int().unwrap();
              if (jint.value != 123) begin
                $display("TEST FAILED: Builder integration - Expected value 123, got %0d", jint.value);
                all_passed = 0;
              end else begin
                $display("TEST PASSED: Builder integration");
              end
            end
          end
        end
      end
    end

    // Test 13: from_value - deserialize json_value -> json_value
    begin
      json_value source;
      json_value target;
      Result#(json_value) res;
      Result#(bit) from_res;
      json_object obj_src;
      json_object obj_targ;

      $display("Testing from_value...");

      // Create a source json_value programmatically
      source = json_object::create();
      obj_src = source.as_object().unwrap();
      obj_src.set("name", json_string::from("test"));
      obj_src.set("count", json_int::from(42));

      // Deserialize to a new json_value using from_value
      target = json_object::create();
      from_res = serde_json::from_value(source, target);

      if (from_res.is_err()) begin
        $display("TEST FAILED: from_value deserialization error");
        all_passed = 0;
      end else begin
        if (!target.is_object()) begin
          $display("TEST FAILED: from_value expected object");
          all_passed = 0;
        end else begin
          obj_targ = target.as_object().unwrap();
          if (obj_targ.size() != obj_src.size()) begin
            $display("TEST FAILED: from_value size mismatch");
            all_passed = 0;
          end else begin
            $display("TEST PASSED: from_value");
          end
        end
      end
    end

    if (all_passed) begin
      $display("\n=== ALL TESTS PASSED ===");
    end else begin
      $display("\n=== SOME TESTS FAILED ===");
    end

    $display("All JSON deserializer smoke tests completed!");
    $finish;
  end
endmodule
