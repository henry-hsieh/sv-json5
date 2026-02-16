`ifndef SV_MSGPACK_INT_SVH
`define SV_MSGPACK_INT_SVH
class msgpack_int extends msgpack_value;
  longint value;

  function new(longint val = 0);
    this.value = val;
  endfunction

  static function msgpack_int from(longint val);
    msgpack_int m = new(val);
    return m;
  endfunction

  virtual function bit is_int();
    return 1;
  endfunction

  virtual function Option#(msgpack_int) as_int();
    return Option#(msgpack_int)::Some(this);
  endfunction

  virtual function msgpack_value clone();
    return msgpack_int::from(value);
  endfunction

  virtual function bit equals(msgpack_value other);
    msgpack_int other_int;
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
