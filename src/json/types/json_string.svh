`ifndef SV_JSON_STRING_SVH
`define SV_JSON_STRING_SVH
class json_string extends json_value;
  string value;

  function new(string val = "");
    this.value = val;
  endfunction

  static function json_string from(string val);
    json_string j = new(val);
    return j;
  endfunction

  virtual function bit is_string(); return 1; endfunction

  virtual function Option#(json_string) as_string();
    return Option#(json_string)::Some(this);
  endfunction

  virtual function json_value clone();
    return json_string::from(value);
  endfunction

  virtual function bit equals(json_value other);
    json_string other_str;
    if (other == null || !other.is_string() || other.as_string().is_none()) return 0;
    other_str = other.as_string().unwrap();
    return value == other_str.value;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_string(value);
  endfunction

  // Implement serde_deserialize - read string from deserializer
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(string) res = deser.deserialize_string();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    value = res.unwrap();
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
