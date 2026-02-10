`ifndef SV_SERDE_DESERIALIZER_SVH
`define SV_SERDE_DESERIALIZER_SVH

// serde_deserializer.svh - Rust-like Deserializer trait
// Format-specific deserializers implement this interface to provide
// a common API for deserializing values from different formats (JSON, CBOR, etc.)
//
// Usage:
//   class json_deserializer extends serde_deserializer;
//     virtual function Result#(longint) deserialize_int();
//       // parse integer from JSON and return Ok(val) or Err(msg)
//     endfunction
//     // ... implement other deserialize methods
//   endclass
//
//   class MyType implements serde_deserialize;
//     function Result#(bit) deserialize(serde_deserializer deser);
//       Result#(longint) i = deser.deserialize_int();
//       // construct MyType from deserialized values
//     endfunction
//   endclass

virtual class serde_deserializer;

  virtual function Result#(string) deserialize_key();
    return Result#(string)::Err("deserialize_key not implemented");
  endfunction

  // Check if there are more elements in the current sequence/map
  // Returns Ok(1) if more elements exist, Ok(0) if at end, Err on failure
  virtual function Result#(bit) check_has_more();
    return Result#(bit)::Ok(1);
  endfunction

  // Deserialize any value by delegating to the visitor
  // The deserializer peeks at the input and calls the appropriate visitor method
  // Essential for deserializing into json_value (where type is unknown)
  virtual function Result#(bit) deserialize_any(serde_visitor visitor);
    return Result#(bit)::Err("deserialize_any not implemented");
  endfunction

  // Scalar types
  // Returns Ok(T) on success, Err on failure
  virtual function Result#(longint) deserialize_int();
    return Result#(longint)::Err("deserialize_int not implemented");
  endfunction

  virtual function Result#(longint unsigned) deserialize_uint();
    return Result#(longint unsigned)::Err("deserialize_uint not implemented");
  endfunction

  virtual function Result#(real) deserialize_real();
    return Result#(real)::Err("deserialize_real not implemented");
  endfunction

  virtual function Result#(string) deserialize_string();
    return Result#(string)::Err("deserialize_string not implemented");
  endfunction

  virtual function Result#(bit) deserialize_bool();
    return Result#(bit)::Err("deserialize_bool not implemented");
  endfunction

  virtual function Result#(bit) deserialize_null();
    return Result#(bit)::Err("deserialize_null not implemented");
  endfunction

  // Composite types - for recursive deserialization
  // These methods control the deserialization flow for arrays/objects
  virtual function Result#(bit) deserialize_sequence_start();
    return Result#(bit)::Err("deserialize_sequence_start not implemented");
  endfunction

  virtual function Result#(bit) deserialize_object_start();
    return Result#(bit)::Err("deserialize_object_start not implemented");
  endfunction

  // Pull-based deserialization methods
  // Return a seq_access that the visitor can use to pull elements
  virtual function Result#(serde_seq_access) deserialize_seq();
    return Result#(serde_seq_access)::Err("deserialize_seq not implemented");
  endfunction

  virtual function Result#(serde_map_access) deserialize_map();
    return Result#(serde_map_access)::Err("deserialize_map not implemented");
  endfunction

  virtual function Result#(bit) deserialize_option();
    return Result#(bit)::Err("deserialize_option not implemented");
  endfunction

  // Returns 1 if the format is human-readable (JSON, TOML, etc.), 0 otherwise
  virtual function bit is_human_readable();
    return 1;
  endfunction
endclass
`endif
