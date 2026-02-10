`ifndef SV_JSON_OBJECT_SVH
`define SV_JSON_OBJECT_SVH
class json_object extends json_value;
  json_value items[string];

  function new();
  endfunction

  static function json_object create();
    json_object j = new();
    return j;
  endfunction

  function void set(string key, json_value val);
    items[key] = val;
  endfunction

  function json_value get(string key);
    if (items.exists(key) != 0)
      return items[key];
    return null;
  endfunction

  function bit has(string key);
    return (items.exists(key) != 0);
  endfunction

  virtual function bit is_object();
    return 1;
  endfunction

  virtual function Option#(json_object) as_object();
    return Option#(json_object)::Some(this);
  endfunction

  virtual function json_value clone();
    json_object j = json_object::create();
    foreach (items[key]) begin
      j.set(key, items[key].clone());
    end
    return j;
  endfunction

  virtual function bit equals(json_value other);
    json_object other_obj;
    if (other == null || !other.is_object() || other.as_object().is_none()) return 0;
    other_obj = other.as_object().unwrap();
    if (items.size() != other_obj.items.size()) return 0;
    foreach (items[key]) begin
      if (!other_obj.items.exists(key)) return 0;
      if (!items[key].equals(other_obj.items[key])) return 0;
    end
    return 1;
  endfunction

  function string_queue_t keys();
    string_queue_t q;
    foreach (items[k]) q.push_back(k);
    return q;
  endfunction

  function json_value_queue_t values();
    json_value_queue_t q;
    foreach (items[k]) q.push_back(items[k]);
    return q;
  endfunction

  function int size();
    return items.size();
  endfunction

  function bit is_empty();
    return (items.size() == 0);
  endfunction

  function void remove(string key);
    if (items.exists(key) != 0)
      items.delete(key);
  endfunction

  function void clear();
    items.delete();
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

  // Implement serde_deserialize - read object from deserializer
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(bit) res;
    Result#(bit) more_res;
    Result#(string) key_res;
    bit more;
    string key;
    json_value_builder builder;

    res = deser.deserialize_object_start();
    if (res.is_err()) return res;

    more_res = deser.check_has_more();
    if (more_res.is_err()) return more_res;
    more = more_res.unwrap();

    while (more) begin
      key_res = deser.deserialize_key();
      if (key_res.is_err()) return Result#(bit)::Err(key_res.unwrap_err());
      key = key_res.unwrap();

      // Use a builder to deserialize the value of unknown type
      builder = new();
      res = deser.deserialize_any(builder);
      if (res.is_err()) return res;

      this.set(key, builder.get_result().unwrap());

      more_res = deser.check_has_more();
      if (more_res.is_err()) return more_res;
      more = more_res.unwrap();
    end

    // Pull model: check_has_more() handles cleanup when exhausted
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
