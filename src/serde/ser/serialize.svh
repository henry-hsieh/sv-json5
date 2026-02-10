`ifndef SV_SERDE_SERIALIZE_SVH
`define SV_SERDE_SERIALIZE_SVH
// serde_serialize.svh - Rust-like Serialize trait for JSON
// Implement this trait to enable serialization to any format
//
// Usage:
//   class MyType implements serde_serialize;
//     function Result#(bit) serialize(serde_serializer ser);
//       // serialize fields using ser
//     endfunction
//   endclass
//
//   MyType obj = new();
//   json_serializer ser = new();
//   void'(obj.serialize(ser));
//   string json_str = ser.get_string();

interface class serde_serialize;
  pure virtual function Result#(bit) serialize(serde_serializer ser);
endclass
`endif
