`ifndef SV_MSGPACK_STRING_SVH
`define SV_MSGPACK_STRING_SVH
class msgpack_string extends msgpack_value;
  string value;

  function new(string val = "");
    this.value = val;
  endfunction

  static function msgpack_string from(string val);
    msgpack_string m = new(val);
    return m;
  endfunction

  virtual function bit is_string();
    return 1;
  endfunction

  virtual function Option#(msgpack_string) as_string();
    return Option#(msgpack_string)::Some(this);
  endfunction

  virtual function msgpack_value clone();
    return msgpack_string::from(value);
  endfunction

  virtual function bit equals(msgpack_value other);
    msgpack_string other_str;
    if (other == null || !other.is_string() || other.as_string().is_none()) return 0;
    other_str = other.as_string().unwrap();
    return value == other_str.value;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_string(value);
  endfunction

  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(string) res = deser.deserialize_string();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    value = res.unwrap();
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
