// test_app_json_value.sv - Demonstration of to_value/from_value patterns for structs
//
// In SystemVerilog, structs are value types and cannot implement interfaces.
// To convert between structs and json_value, you need wrapper classes.
//
// This file demonstrates:
//   1. struct -> json_value: Use a wrapper that implements serde_serialize
//   2. json_value -> struct: Use a wrapper that implements serde_deserialize
//   3. json_value -> json_value: Clone via to_value

package json_test_pkg;

  import common_pkg::*;
  import serde_pkg::*;
  import json_pkg::*;

  // ==========================================================
  // Section 1: Define your struct
  // ==========================================================

  typedef struct {
    string name;
    longint age;
    bit   active;
  } person_t;

  // ==========================================================
  // Section 2: Wrapper for serialization (struct -> json_value)
  // ==========================================================

  // This wrapper takes a struct and serializes it to json_value
  class person_serializer implements serde_serialize;
    person_t data;

    function new(person_t p);
      this.data = p;
    endfunction

    // Implement the serialize method - manually map struct fields to JSON
    virtual function Result#(bit) serialize(serde_serializer ser);
      Result#(bit) res;

      // Start object with 3 fields
      res = ser.serialize_object_start(3);
      if (res.is_err()) return res;

      // Field: name (string)
      res = ser.serialize_key("name");
      if (res.is_err()) return res;
      res = ser.serialize_string(data.name);
      if (res.is_err()) return res;

      // Field: age (longint)
      res = ser.serialize_key("age");
      if (res.is_err()) return res;
      res = ser.serialize_int(data.age);
      if (res.is_err()) return res;

      // Field: active (bool)
      res = ser.serialize_key("active");
      if (res.is_err()) return res;
      res = ser.serialize_bool(data.active);
      if (res.is_err()) return res;

      // End object
      res = ser.serialize_object_end();
      return res;
    endfunction
  endclass

  // ==========================================================
  // Section 3: Wrapper for deserialization (json_value -> struct)
  // ==========================================================

  // This wrapper takes a json_value and deserializes it into a struct
  // Strategy: Use the deserializer API to traverse the DOM (works with any deserializer)
  class person_deserializer implements serde_deserialize;
    person_t data;

    function new();
      // Initialize struct to default values
      data = '{
        name:   "",
        age:    0,
        active: 0
      };
    endfunction

    // Getters for the deserialized data
    function person_t get_data();
      return data;
    endfunction

    // Implement the deserialize method using the Serde API
    // This approach works with any deserializer (JSON string, file stream, DOM, etc.)
    virtual function Result#(bit) deserialize(serde_deserializer deser);
      Result#(bit) res;
      Result#(bit) more_res;
      Result#(string) key_res;
      Result#(longint) int_res;
      Result#(string) str_res;
      Result#(bit) bool_res;
      bit more;
      string key;

      // Start object - tells deserializer to enter object context
      res = deser.deserialize_object_start();
      if (res.is_err()) return res;

      // Loop through all fields
      more_res = deser.check_has_more();
      if (more_res.is_err()) return more_res;
      more = more_res.unwrap();

      while (more) begin
        // Get the field name
        key_res = deser.deserialize_key();
        if (key_res.is_err()) return Result#(bit)::Err(key_res.unwrap_err());
        key = key_res.unwrap();

        // Deserialize field based on key name
        case (key)
          "name": begin
            str_res = deser.deserialize_string();
            if (str_res.is_err()) return Result#(bit)::Err(str_res.unwrap_err());
            data.name = str_res.unwrap();
          end

          "age": begin
            int_res = deser.deserialize_int();
            if (int_res.is_err()) return Result#(bit)::Err(int_res.unwrap_err());
            data.age = int_res.unwrap();
          end

          "active": begin
            bool_res = deser.deserialize_bool();
            if (bool_res.is_err()) return Result#(bit)::Err(bool_res.unwrap_err());
            data.active = bool_res.unwrap();
          end

          default: begin
            return Result#(bit)::Err($sformatf("Unknown field: %s", key));
          end
        endcase

        // Check for more fields
        more_res = deser.check_has_more();
        if (more_res.is_err()) return more_res;
        more = more_res.unwrap();
      end

      // Pull model: check_has_more() handles cleanup when exhausted
      return Result#(bit)::Ok(1);
    endfunction
  endclass

endpackage

module test_app_json_value;
  import json_test_pkg::*;
  import common_pkg::*;
  import serde_pkg::*;
  import json_pkg::*;

  // ==========================================================
  // Section 4: Tests
  // ==========================================================

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

  function void test_struct_to_value();
    person_t p;
    person_serializer wrapper;
    Result#(json_value) res;
    json_value val;
    Option#(json_object) opt_obj;
    json_object obj;

    $display("Testing struct -> json_value...");

    // Create struct
    p = '{
      name:   "Alice",
      age:    30,
      active: 1
    };

    // Wrap in serializer
    wrapper = new(p);

    // Convert to json_value
    res = serde_json::to_value(wrapper);
    check("to_value returns ok", res.is_ok());
    if (res.is_err()) return;

    val = res.unwrap();

    // Verify the json_value
    check("json_value is object", val.is_object());
    if (!val.is_object()) return;

    opt_obj = val.as_object();
    if (opt_obj.is_none()) begin
      check("got object", 0);
      return;
    end
    obj = opt_obj.unwrap();

    // Note: SystemVerilog associative arrays sort keys alphabetically
    // So keys come out as ["active", "age", "name"]
    check("object has 3 fields", obj.size() == 3);
    check("name field", obj.get("name").as_string().unwrap().value == "Alice");
    check("age field", obj.get("age").as_int().unwrap().value == 30);
    check("active field", obj.get("active").as_bool().unwrap().value == 1);
  endfunction

  function void test_value_to_struct();
    json_value val;
    person_deserializer deser;
    Result#(bit) res;
    person_t p;

    $display("Testing json_value -> struct...");

    // Build json_value manually
    val = json_object::create();
    val.as_object().unwrap().set("name", json_string::from("Bob"));
    val.as_object().unwrap().set("age", json_int::from(25));
    val.as_object().unwrap().set("active", json_bool::from(0));

    // Use wrapper to deserialize
    deser = new();
    res = serde_json::from_value(val, deser);
    check("from_value returns ok", res.is_ok());
    if (res.is_err()) return;

    // Get the deserialized struct
    p = deser.get_data();
    check("struct name is Bob", p.name == "Bob");
    check("struct age is 25", p.age == 25);
    check("struct active is 0", p.active == 0);
  endfunction

  function void test_roundtrip();
    person_t original;
    person_serializer ser_wrapper;
    person_deserializer deser_wrapper;
    Result#(json_value) to_res;
    Result#(bit) from_res;
    person_t result;

    $display("Testing struct -> json_value -> struct roundtrip...");

    // Original struct
    original = '{
      name:   "Charlie",
      age:    40,
      active: 1
    };

    // Step 1: struct -> json_value
    ser_wrapper = new(original);
    to_res = serde_json::to_value(ser_wrapper);
    check("roundtrip: to_value ok", to_res.is_ok());
    if (to_res.is_err()) return;

    // Step 2: json_value -> struct
    deser_wrapper = new();
    from_res = serde_json::from_value(to_res.unwrap(), deser_wrapper);
    check("roundtrip: from_value ok", from_res.is_ok());
    if (from_res.is_err()) return;

    // Step 3: Verify
    result = deser_wrapper.get_data();
    check("roundtrip: name matches", result.name == original.name);
    check("roundtrip: age matches", result.age == original.age);
    check("roundtrip: active matches", result.active == original.active);
  endfunction

  function void test_value_clone();
    json_value original;
    json_value cloned;
    Result#(json_value) res;

    $display("Testing json_value -> json_value clone...");

    // Create original json_value
    original = json_object::create();
    original.as_object().unwrap().set("x", json_int::from(100));

    // Clone via to_value (pass json_value directly since it implements serde_serialize)
    res = serde_json::to_value(original);
    check("clone to_value ok", res.is_ok());
    if (res.is_err()) return;

    cloned = res.unwrap();
    check("clone has same data", cloned.as_object().unwrap().get("x").as_int().unwrap().value == 100);
  endfunction

  initial begin
    $display("=== JSON Value Pattern Demo ===");
    $display("");

    test_struct_to_value();
    test_value_to_struct();
    test_roundtrip();
    test_value_clone();

    $display("");
    $display("Summary: %0d passed, %0d failed", passed, failed);
    if (failed > 0) $finish(1);
    else $finish(0);
  end

endmodule
