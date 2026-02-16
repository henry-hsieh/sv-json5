`ifndef SV_MSGPACK_ARRAY_SVH
`define SV_MSGPACK_ARRAY_SVH
class msgpack_array extends msgpack_value;
  msgpack_value items[$];

  function new();
  endfunction

  static function msgpack_array create();
    msgpack_array m = new();
    return m;
  endfunction

  function void add(msgpack_value item);
    items.push_back(item);
  endfunction

  function int size();
    return items.size();
  endfunction

  function msgpack_value get(int idx);
    if (idx < 0 || idx >= items.size()) return null;
    return items[idx];
  endfunction

  virtual function bit is_array();
    return 1;
  endfunction

  virtual function Option#(msgpack_array) as_array();
    return Option#(msgpack_array)::Some(this);
  endfunction

  virtual function msgpack_value clone();
    msgpack_array c = msgpack_array::create();
    foreach (items[i]) begin
      c.add(items[i].clone());
    end
    return c;
  endfunction

  virtual function bit equals(msgpack_value other);
    msgpack_array other_arr;
    if (other == null || !other.is_array() || other.as_array().is_none()) return 0;
    other_arr = other.as_array().unwrap();
    if (items.size() != other_arr.items.size()) return 0;
    foreach (items[i]) begin
      if (!items[i].equals(other_arr.items[i])) return 0;
    end
    return 1;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    Result#(bit) res;
    res = ser.serialize_array_start(items.size());
    if (res.is_err()) return res;
    foreach (items[i]) begin
      res = items[i].serialize(ser);
      if (res.is_err()) return res;
    end
    return ser.serialize_array_end();
  endfunction

  virtual function Result#(bit) deserialize(serde_deserializer deser);
    return Result#(bit)::Err("msgpack_array::deserialize not implemented. Use msgpack_deserializer.");
  endfunction
endclass
`endif
