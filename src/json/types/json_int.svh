`ifndef SV_JSON_INT_SVH
`define SV_JSON_INT_SVH
class json_int extends json_value;
  logic signed [63:0] value;

  function new(logic signed [63:0] val = 0);
    this.value = val;
  endfunction

  static function json_int from(logic signed [63:0] val);
    json_int j = new(val);
    return j;
  endfunction

  virtual function bit is_int();
    return 1;
  endfunction

  virtual function Option#(json_int) as_int();
    return Option#(json_int)::Some(this);
  endfunction

  virtual function json_value clone();
    return json_int::from(value);
  endfunction

virtual function bit equals(json_value other);
    json_int other_int;
    if (other == null || !other.is_int() || other.as_int().is_none()) return 0;
    other_int = other.as_int().unwrap();
    return value == other_int.value;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_int(value);
  endfunction

  // Implement serde_deserialize - read int from deserializer
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(longint) res = deser.deserialize_int();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    value = res.unwrap();
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
