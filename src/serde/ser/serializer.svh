`ifndef SV_SERDE_SERIALIZER_SVH
`define SV_SERDE_SERIALIZER_SVH
// serde_serializer.svh - Serializer interface for format-agnostic serialization
// Implement this trait to support serializing to different formats (JSON, JSON5, CBOR, etc.)
//
// Usage:
//   class json_serializer implements serde_serializer;
//     string output;
//
//     function new();
//       output = "";
//     endfunction
//
//     function Result#(string) get_string();
//       return Result#(string)::ok(output);
//     endfunction
//
//     function Result#(bit) serialize_int(longint val);
//       output = $sformatf("%s%0d", output, val);
//       return Result#(bit)::ok(1);
//     endfunction
//     // ... implement other methods
//   endclass

virtual class serde_serializer;
  // Scalar types
  virtual function Result#(bit) serialize_int(longint val);
    return Result#(bit)::Err("serialize_int not supported");
  endfunction

  virtual function Result#(bit) serialize_uint(longint unsigned val);
    return Result#(bit)::Err("serialize_uint not supported");
  endfunction

  virtual function Result#(bit) serialize_real(real val);
    return Result#(bit)::Err("serialize_real not supported");
  endfunction

  virtual function Result#(bit) serialize_string(string val);
    return Result#(bit)::Err("serialize_string not supported");
  endfunction

  virtual function Result#(bit) serialize_bool(bit val);
    return Result#(bit)::Err("serialize_bool not supported");
  endfunction

  virtual function Result#(bit) serialize_null();
    return Result#(bit)::Err("serialize_null not supported");
  endfunction

  // Composite types
  // len = -1 means unknown length (optional, like Rust's Option<usize>::None)
  virtual function Result#(bit) serialize_array_start(longint len = -1);
    return Result#(bit)::Err("serialize_array_start not supported");
  endfunction

  virtual function Result#(bit) serialize_array_end();
    return Result#(bit)::Err("serialize_array_end not supported");
  endfunction

  // len = -1 means unknown length (optional, like Rust's Option<usize>::None)
  virtual function Result#(bit) serialize_object_start(longint len = -1);
    return Result#(bit)::Err("serialize_object_start not supported");
  endfunction

  virtual function Result#(bit) serialize_object_end();
    return Result#(bit)::Err("serialize_object_end not supported");
  endfunction

  virtual function Result#(bit) serialize_key(string key);
    return Result#(bit)::Err("serialize_key not supported");
  endfunction

  // Utility method
  virtual function bit is_human_readable();
    return 1;
  endfunction
endclass
`endif
