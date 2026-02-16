`ifndef SV_MSGPACK_VALUE_SVH
`define SV_MSGPACK_VALUE_SVH
virtual class msgpack_value implements serde_serialize, serde_deserialize;

  // Each subtype must implement serialize
  // msgpack_int: ser.serialize_int(value)
  // msgpack_string: ser.serialize_string(value)
  // etc.
  pure virtual function Result#(bit) serialize(serde_serializer ser);

  // Deserialize - each subtype implements this to deserialize itself
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    return Result#(bit)::Err("Base msgpack_value cannot be deserialized directly. Use msgpack_deserializer::deserialize_any with a builder.");
  endfunction

  virtual function bit is_map(); return 0; endfunction
  virtual function bit is_array(); return 0; endfunction
  virtual function bit is_string(); return 0; endfunction
  virtual function bit is_int(); return 0; endfunction
  virtual function bit is_real(); return 0; endfunction
  virtual function bit is_bool(); return 0; endfunction
  virtual function bit is_null(); return 0; endfunction

  // Type casting methods
  virtual function Option#(msgpack_map) as_map(); return Option#(msgpack_map)::None(); endfunction
  virtual function Option#(msgpack_array) as_array(); return Option#(msgpack_array)::None(); endfunction
  virtual function Option#(msgpack_string) as_string(); return Option#(msgpack_string)::None(); endfunction
  virtual function Option#(msgpack_int) as_int(); return Option#(msgpack_int)::None(); endfunction
  virtual function Option#(msgpack_real) as_real(); return Option#(msgpack_real)::None(); endfunction
  virtual function Option#(msgpack_bool) as_bool(); return Option#(msgpack_bool)::None(); endfunction
  virtual function Option#(msgpack_null) as_null(); return Option#(msgpack_null)::None(); endfunction

  pure virtual function msgpack_value clone();

  pure virtual function bit equals(msgpack_value other);
endclass
`endif
