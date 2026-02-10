`ifndef SV_JSON_BOOL_SVH
`define SV_JSON_BOOL_SVH
class json_bool extends json_value;
  bit value;

  function new(bit val = 0);
    this.value = val;
  endfunction

  static function json_bool from(bit val);
    json_bool j = new(val);
    return j;
  endfunction

  virtual function bit is_bool(); return 1; endfunction

  virtual function Option#(json_bool) as_bool();
    return Option#(json_bool)::Some(this);
  endfunction

  virtual function json_value clone();
    return json_bool::from(value);
  endfunction

  virtual function bit equals(json_value other);
    json_bool other_bool;
    if (other == null || !other.is_bool() || other.as_bool().is_none()) return 0;
    other_bool = other.as_bool().unwrap();
    return value == other_bool.value;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_bool(value);
  endfunction

  // Implement serde_deserialize - read bool from deserializer
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(bit) res = deser.deserialize_bool();
    if (res.is_err()) return res;
    value = res.unwrap();
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
