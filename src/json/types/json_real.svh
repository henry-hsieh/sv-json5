`ifndef SV_JSON_REAL_SVH
`define SV_JSON_REAL_SVH
class json_real extends json_value;
  real value;

  function new(real val = 0.0);
    this.value = val;
  endfunction

  static function json_real from(real val);
    json_real j = new(val);
    return j;
  endfunction

  virtual function bit is_real(); return 1; endfunction

  virtual function Option#(json_real) as_real();
    return Option#(json_real)::Some(this);
  endfunction

  virtual function json_value clone();
    return json_real::from(value);
  endfunction

  virtual function bit equals(json_value other);
    json_real other_real;
    if (other == null || !other.is_real() || other.as_real().is_none()) return 0;
    other_real = other.as_real().unwrap();
    return value == other_real.value;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_real(value);
  endfunction

  // Implement serde_deserialize - read real from deserializer
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(real) res = deser.deserialize_real();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    value = res.unwrap();
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
