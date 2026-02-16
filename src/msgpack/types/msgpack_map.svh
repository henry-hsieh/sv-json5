`ifndef SV_MSGPACK_MAP_SVH
`define SV_MSGPACK_MAP_SVH
class msgpack_map extends msgpack_value;
  msgpack_value items[string];

  function new();
  endfunction

  static function msgpack_map create();
    msgpack_map m = new();
    return m;
  endfunction

  function void set(string key, msgpack_value item);
    items[key] = item;
  endfunction

  function msgpack_value get(string key);
    if (!items.exists(key)) return null;
    return items[key];
  endfunction

  function int size();
    return items.num();
  endfunction

  // Note: Returning queue of strings
  function void get_keys(output string k[$]);
    foreach (items[key]) begin
      k.push_back(key);
    end
  endfunction

  virtual function bit is_map();
    return 1;
  endfunction

  virtual function Option#(msgpack_map) as_map();
    return Option#(msgpack_map)::Some(this);
  endfunction

  virtual function msgpack_value clone();
    msgpack_map c = msgpack_map::create();
    foreach (items[key]) begin
      c.set(key, items[key].clone());
    end
    return c;
  endfunction

  virtual function bit equals(msgpack_value other);
    msgpack_map other_map;
    if (other == null || !other.is_map() || other.as_map().is_none()) return 0;
    other_map = other.as_map().unwrap();
    if (items.num() != other_map.items.num()) return 0;
    foreach (items[key]) begin
      if (!other_map.items.exists(key)) return 0;
      if (!items[key].equals(other_map.items[key])) return 0;
    end
    return 1;
  endfunction

  virtual function Result#(bit) serialize(serde_serializer ser);
    Result#(bit) res;
    res = ser.serialize_object_start(items.size());
    if (res.is_err()) return res;
    foreach (items[key]) begin
      res = ser.serialize_key(key);
      if (res.is_err()) return res;
      res = items[key].serialize(ser);
      if (res.is_err()) return res;
    end
    return ser.serialize_object_end();
  endfunction

  virtual function Result#(bit) deserialize(serde_deserializer deser);
    return Result#(bit)::Err("msgpack_map::deserialize not implemented. Use msgpack_deserializer.");
  endfunction
endclass
`endif
