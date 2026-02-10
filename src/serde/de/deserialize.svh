`ifndef SV_SERDE_DESERIALIZE_SVH
`define SV_SERDE_DESERIALIZE_SVH
// serde_deserialize.svh - Rust-like Deserialize trait
// Implement this trait on your type to enable deserialization from any format
// (JSON, CBOR, MessagePack, etc.)
//
// This matches Rust's serde::Deserialize trait:
//   impl<'de> Deserialize<'de> for MyType {
//       fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
//       where
//           D: Deserializer<'de>,
//       { ... }
//   }
//
// Usage:
//   class MyType implements serde_deserialize;
//     function Result#(bit) deserialize(serde_deserializer deser);
//       string name;
//       longint age;
//
//       deser.deserialize_string(name);  // extract field
//       deser.deserialize_int(age);       // extract field
//       // construct and return Self
//     endfunction
//   endclass
//
// Note: This is the DOM-style deserialization where types directly
// deserialize themselves. For SAX/streaming style, use
// serde_deserialize_handler instead.

interface class serde_deserialize;
  // Main deserialize method - implement this to define how your type
  // deserializes itself from a deserializer
  pure virtual function Result#(bit) deserialize(serde_deserializer deser);
endclass : serde_deserialize
`endif
