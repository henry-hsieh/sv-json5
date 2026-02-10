`ifndef SV_JSON_NULL_SVH
`define SV_JSON_NULL_SVH
class json_null extends json_value;
  function new();
  endfunction

  static function json_null from();
    json_null j = new();
    return j;
  endfunction

  virtual function bit is_null(); return 1; endfunction

  virtual function Option#(json_null) as_null();
    return Option#(json_null)::Some(this);
  endfunction

  virtual function json_value clone();
    return json_null::from();
  endfunction

  virtual function bit equals(json_value other);
    json_null other_null;
    if (other == null || !other.is_null() || other.as_null().is_none()) return 0;
    return 1;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_null();
  endfunction

  // Implement serde_deserialize - read null from deserializer
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    return deser.deserialize_null();
  endfunction
endclass
`endif
