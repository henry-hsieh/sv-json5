`ifndef SV_JSON_VALUE_SVH
`define SV_JSON_VALUE_SVH
virtual class json_value implements serde_serialize, serde_deserialize;

  // Each subtype must implement serialize
  // json_int: ser.serialize_int(value)
  // json_string: ser.serialize_string(value)
  // etc.
  pure virtual function Result#(bit) serialize(serde_serializer ser);

  // Deserialize - each subtype implements this to deserialize itself
  // For the base class, we use a builder to determine the type
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    return Result#(bit)::Err("Base json_value cannot be deserialized directly. Use json_deserializer::deserialize_any with a builder.");
  endfunction

  virtual function bit is_object(); return 0; endfunction
  virtual function bit is_array(); return 0; endfunction
  virtual function bit is_string(); return 0; endfunction
  virtual function bit is_int(); return 0; endfunction
  virtual function bit is_real(); return 0; endfunction
  virtual function bit is_bool(); return 0; endfunction
  virtual function bit is_null(); return 0; endfunction

  // Type casting methods
  virtual function Option#(json_object) as_object(); return Option#(json_object)::None(); endfunction
  virtual function Option#(json_array) as_array(); return Option#(json_array)::None(); endfunction
  virtual function Option#(json_string) as_string(); return Option#(json_string)::None(); endfunction
  virtual function Option#(json_int) as_int(); return Option#(json_int)::None(); endfunction
  virtual function Option#(json_real) as_real(); return Option#(json_real)::None(); endfunction
  virtual function Option#(json_bool) as_bool(); return Option#(json_bool)::None(); endfunction
  virtual function Option#(json_null) as_null(); return Option#(json_null)::None(); endfunction

  pure virtual function json_value clone();

  pure virtual function bit equals(json_value other);
endclass
`endif
