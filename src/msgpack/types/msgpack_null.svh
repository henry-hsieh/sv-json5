`ifndef SV_MSGPACK_NULL_SVH
`define SV_MSGPACK_NULL_SVH
class msgpack_null extends msgpack_value;

  function new();
  endfunction

  static function msgpack_null from();
    msgpack_null m = new();
    return m;
  endfunction

  virtual function bit is_null();
    return 1;
  endfunction

  virtual function Option#(msgpack_null) as_null();
    return Option#(msgpack_null)::Some(this);
  endfunction

  virtual function msgpack_value clone();
    return msgpack_null::from();
  endfunction

  virtual function bit equals(msgpack_value other);
    if (other == null || !other.is_null()) return 0;
    return 1;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_null();
  endfunction

  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(bit) res = deser.deserialize_null();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
