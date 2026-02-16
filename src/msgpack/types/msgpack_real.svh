`ifndef SV_MSGPACK_REAL_SVH
`define SV_MSGPACK_REAL_SVH
class msgpack_real extends msgpack_value;
  real value;

  function new(real val = 0.0);
    this.value = val;
  endfunction

  static function msgpack_real from(real val);
    msgpack_real m = new(val);
    return m;
  endfunction

  virtual function bit is_real();
    return 1;
  endfunction

  virtual function Option#(msgpack_real) as_real();
    return Option#(msgpack_real)::Some(this);
  endfunction

  virtual function msgpack_value clone();
    return msgpack_real::from(value);
  endfunction

  virtual function bit equals(msgpack_value other);
    msgpack_real other_real;
    if (other == null || !other.is_real() || other.as_real().is_none()) return 0;
    other_real = other.as_real().unwrap();
    return value == other_real.value;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_real(value);
  endfunction

  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(real) res = deser.deserialize_real();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    value = res.unwrap();
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
