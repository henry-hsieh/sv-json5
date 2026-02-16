`ifndef SV_MSGPACK_BOOL_SVH
`define SV_MSGPACK_BOOL_SVH
class msgpack_bool extends msgpack_value;
  bit value;

  function new(bit val = 0);
    this.value = val;
  endfunction

  static function msgpack_bool from(bit val);
    msgpack_bool m = new(val);
    return m;
  endfunction

  virtual function bit is_bool();
    return 1;
  endfunction

  virtual function Option#(msgpack_bool) as_bool();
    return Option#(msgpack_bool)::Some(this);
  endfunction

  virtual function msgpack_value clone();
    return msgpack_bool::from(value);
  endfunction

  virtual function bit equals(msgpack_value other);
    msgpack_bool other_bool;
    if (other == null || !other.is_bool() || other.as_bool().is_none()) return 0;
    other_bool = other.as_bool().unwrap();
    return value == other_bool.value;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_bool(value);
  endfunction

  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(bit) res = deser.deserialize_bool();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    value = res.unwrap();
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
