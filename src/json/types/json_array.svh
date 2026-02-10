`ifndef SV_JSON_ARRAY_SVH
`define SV_JSON_ARRAY_SVH
class json_array extends json_value;
  json_value items[$];

  function new();
  endfunction

  static function json_array create();
    json_array j = new();
    return j;
  endfunction

  function void add(json_value val);
    items.push_back(val);
  endfunction

  function json_value get(int index);
    if (index >= 0 && index < items.size())
      return items[index];
    return null;
  endfunction

  function int size();
    return items.size();
  endfunction

  virtual function bit is_array();
    return 1;
  endfunction

  virtual function Option#(json_array) as_array();
    return Option#(json_array)::Some(this);
  endfunction

  virtual function json_value clone();
    json_array j = json_array::create();
    foreach (items[i]) begin
      j.add(items[i].clone());
    end
    return j;
  endfunction

  virtual function bit equals(json_value other);
    json_array other_arr;
    if (other == null || !other.is_array() || other.as_array().is_none()) return 0;
    other_arr = other.as_array().unwrap();
    if (items.size() != other_arr.items.size()) return 0;
    foreach (items[i]) begin
      if (!items[i].equals(other_arr.items[i])) return 0;
    end
    return 1;
  endfunction

  function void set(int index, json_value val);
    if (index >= 0 && index < items.size())
      items[index] = val;
  endfunction

  function void push_front(json_value val);
    items.push_front(val);
  endfunction

  function void push_back(json_value val);
    items.push_back(val);
  endfunction

  function json_value pop_front();
    return items.pop_front();
  endfunction

  function json_value pop_back();
    return items.pop_back();
  endfunction

  function void insert(int index, json_value val);
    items.insert(index, val);
  endfunction

  function void delete_item(int index);
    items.delete(index);
  endfunction

  function bit is_empty();
    return (items.size() == 0);
  endfunction

  function void clear();
    items.delete();
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

  // Implement serde_deserialize - read array from deserializer
  virtual function Result#(bit) deserialize(serde_deserializer deser);
    Result#(bit) res;
    Result#(bit) more_res;
    bit more;

    res = deser.deserialize_sequence_start();
    if (res.is_err()) return res;

    more_res = deser.check_has_more();
    if (more_res.is_err()) return more_res;
    more = more_res.unwrap();

    while (more) begin
      // We don't know the type of the next element, so we must use deserialize_any
      // with a builder to get a json_value.
      json_value_builder builder = new();
      res = deser.deserialize_any(builder);
      if (res.is_err()) return res;

      this.add(builder.get_result().unwrap());

      more_res = deser.check_has_more();
      if (more_res.is_err()) return more_res;
      more = more_res.unwrap();
    end

    // Pull model: check_has_more() handles cleanup when exhausted
    return Result#(bit)::Ok(1);
  endfunction
endclass
`endif
