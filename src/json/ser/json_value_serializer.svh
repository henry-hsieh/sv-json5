// json_value_serializer.svh - Serializer that builds json_value tree
// Implements serde_serializer interface but instead of writing to string,
// it constructs a json_value AST using json_value_builder.
//
// Usage:
//   json_value_serializer ser = new();
//   my_struct.serialize(ser);
//   json_value val = ser.get_value().unwrap();

`ifndef SV_JSON_VALUE_SERIALIZER_SVH
`define SV_JSON_VALUE_SERIALIZER_SVH

class json_value_serializer extends serde_serializer;
  protected json_value_builder builder;

  function new();
    builder = new();
  endfunction

  // Get the constructed json_value tree
  function Result#(json_value) get_value();
    return builder.get_result();
  endfunction

  // =========================================================================
  // Scalar types
  // =========================================================================

  virtual function Result#(bit) serialize_int(longint val);
    return builder.visit_int(val);
  endfunction

  virtual function Result#(bit) serialize_uint(longint unsigned val);
    return builder.visit_uint(val);
  endfunction

  virtual function Result#(bit) serialize_real(real val);
    return builder.visit_real(val);
  endfunction

  virtual function Result#(bit) serialize_string(string val);
    return builder.visit_string(val);
  endfunction

  virtual function Result#(bit) serialize_bool(bit val);
    return builder.visit_bool(val);
  endfunction

  virtual function Result#(bit) serialize_null();
    return builder.visit_null();
  endfunction

  // =========================================================================
  // Composite types
  // =========================================================================

  // len = -1 means unknown length (optional, like Rust's Option<usize>::None)
  virtual function Result#(bit) serialize_array_start(longint len = -1);
    return builder.visit_array_start();
  endfunction

  virtual function Result#(bit) serialize_array_end();
    return builder.visit_array_end();
  endfunction

  // len = -1 means unknown length (optional, like Rust's Option<usize>::None)
  virtual function Result#(bit) serialize_object_start(longint len = -1);
    return builder.visit_object_start();
  endfunction

  virtual function Result#(bit) serialize_object_end();
    return builder.visit_object_end();
  endfunction

  virtual function Result#(bit) serialize_key(string key);
    return builder.visit_key(key);
  endfunction

  // Always human-readable since we're building a DOM
  virtual function bit is_human_readable();
    return 1;
  endfunction
endclass

`endif
