// json_value_deserializer.svh - Deserializer that traverses json_value tree
// Implements serde_deserializer interface but instead of parsing from string,
// it traverses an existing json_value tree.
//
// Usage:
//   json_value val = ...;  // Some JSON value
//   json_value_deserializer deser = new(val);
//   my_struct.deserialize(deser);

`ifndef SV_JSON_VALUE_DESERIALIZER_SVH
`define SV_JSON_VALUE_DESERIALIZER_SVH

// Internal state for tracking position in the tree
class json_value_frame;
  json_value container;
  int unsigned index;  // For arrays
  string keys[$];     // For objects (keys remaining)

  function new(json_value c);
    container = c;
    index = 0;
    if (c.is_object()) begin
      keys = c.as_object().unwrap().keys();
    end
  endfunction
endclass

class json_value_deserializer extends serde_deserializer;
  protected json_value root;
  protected json_value current;
  protected json_value_frame stack[$];
  protected bit is_exhausted;

  // For deserialize_key: we need to remember the last key read
  // because after reading key, we need to read value
  protected string pending_key;

  function new(json_value v);
    root = v;
    current = v;
    is_exhausted = 0;
    pending_key = "";
  endfunction

  // Get the underlying json_value (useful for direct field access in deserialize)
  function json_value get_json_value();
    return root;
  endfunction

  // =========================================================================
  // Helper methods
  // =========================================================================

  // Move to next element in current container
  protected function Result#(bit) advance();
    json_value_frame frame;


    if (stack.size() == 0) begin
      is_exhausted = 1;
      return Result#(bit)::Ok(1);
    end

    frame = stack[stack.size()-1];

    if (frame.container.is_array()) begin
      json_array arr = frame.container.as_array().unwrap();
      frame.index++;
      if (frame.index >= arr.size()) begin
        is_exhausted = 1;
      end else begin
        current = arr.get(frame.index);
      end
    end else if (frame.container.is_object()) begin
      // Pop current key (key was already consumed by deserialize_key)
      // Don't pre-fetch next value - deserialize_any will get it when needed
      if (frame.keys.size() == 0) begin
        is_exhausted = 1;
      end else begin
        void'(frame.keys.pop_front());
        if (frame.keys.size() == 0) begin
          is_exhausted = 1;
        end
        // Don't pre-fetch next value - will be fetched by deserialize_any
      end
    end

    // Clear pending_key after advancing (we've consumed key-value pair)
    pending_key = "";

    return Result#(bit)::Ok(1);
  endfunction

  // Get current key (for objects)
  protected function Result#(string) get_current_key();
    json_value_frame frame;

    if (stack.size() == 0) begin
      return Result#(string)::Err("No container for key");
    end

    frame = stack[stack.size()-1];
    if (!frame.container.is_object()) begin
      return Result#(string)::Err("Not in object context");
    end

    if (frame.keys.size() == 0) begin
      return Result#(string)::Err("No more keys");
    end

    return Result#(string)::Ok(frame.keys[0]);
  endfunction

  // Get current value
  protected function Result#(json_value) get_current_value();
    json_value_frame frame;
    json_array arr;
    json_object obj;
    string key;

    if (stack.size() == 0) begin
      // At root level
      if (is_exhausted) return Result#(json_value)::Err("Value exhausted");
      return Result#(json_value)::Ok(current);
    end

    frame = stack[stack.size()-1];

    if (frame.container.is_array()) begin
      arr = frame.container.as_array().unwrap();
      if (frame.index >= arr.size()) begin
        return Result#(json_value)::Err("Array index out of bounds");
      end
      return Result#(json_value)::Ok(arr.get(frame.index));
    end else if (frame.container.is_object()) begin
      // If we just read a key (pending_key is set), use that key to get value
      // Otherwise use the current position in keys list
      if (pending_key != "") begin
        key = pending_key;
      end else begin
        if (frame.keys.size() == 0) begin
          return Result#(json_value)::Err("No more keys");
        end
        key = frame.keys[0];
      end
      obj = frame.container.as_object().unwrap();
      return Result#(json_value)::Ok(obj.get(key));
    end

    return Result#(json_value)::Err("Invalid container type");
  endfunction

  // =========================================================================
  // serde_deserializer implementation
  // =========================================================================

  virtual function Result#(string) deserialize_key();
    Result#(string) key_res = get_current_key();
    if (key_res.is_err()) return key_res;

    pending_key = key_res.unwrap();

    // NOTE: Do NOT advance here - advance only after value is consumed

    return Result#(string)::Ok(pending_key);
  endfunction

  virtual function Result#(bit) check_has_more();
    if (is_exhausted) begin
      // Pull model: automatically clean up exhausted container
      // This mirrors json_deserializer behavior where has_next consumes closing token
      if (stack.size() > 0) begin
        void'(stack.pop_back());
        // After popping, advance in parent context if exists
        if (stack.size() > 0) begin
          void'(advance());
        end
      end
      return Result#(bit)::Ok(0);
    end
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) deserialize_any(serde_visitor visitor);
    Result#(json_value) val_res;
    json_value val;
    Result#(bit) res;

    val_res = get_current_value();
    if (val_res.is_err()) return Result#(bit)::Err(val_res.unwrap_err());

    val = val_res.unwrap();

    // Dispatch to visitor based on type
    if (val.is_null()) begin
      res = visitor.visit_null();
    end else if (val.is_bool()) begin
      res = visitor.visit_bool(val.as_bool().unwrap().value);
    end else if (val.is_int()) begin
      res = visitor.visit_int(val.as_int().unwrap().value);
    end else if (val.is_real()) begin
      res = visitor.visit_real(val.as_real().unwrap().value);
    end else if (val.is_string()) begin
      res = visitor.visit_string(val.as_string().unwrap().value);
    end else if (val.is_array()) begin
      res = deserialize_array_any(visitor);
    end else if (val.is_object()) begin
      res = deserialize_object_any(visitor);
    end else begin
      return Result#(bit)::Err("Unknown JSON type");
    end

    if (res.is_err()) return res;

    // After consuming value with pending_key, advance to next key
    if (pending_key != "") begin
      pending_key = "";
      void'(advance());
    end

    return Result#(bit)::Ok(1);

    return Result#(bit)::Err("Unknown json_value type");
  endfunction

  // =========================================================================
  // Scalar types
  // =========================================================================

  virtual function Result#(longint) deserialize_int();
    Result#(json_value) val_res;
    json_value val;

    val_res = get_current_value();
    if (val_res.is_err()) return Result#(longint)::Err(val_res.unwrap_err());

    val = val_res.unwrap();
    if (!val.is_int()) return Result#(longint)::Err("Expected json_int");

    void'(advance());
    return Result#(longint)::Ok(val.as_int().unwrap().value);
  endfunction

  virtual function Result#(longint unsigned) deserialize_uint();
    Result#(longint) res = deserialize_int();
    if (res.is_err()) return Result#(longint unsigned)::Err(res.unwrap_err());
    return Result#(longint unsigned)::Ok($unsigned(res.unwrap()));
  endfunction

  virtual function Result#(real) deserialize_real();
    Result#(json_value) val_res;
    json_value val;

    val_res = get_current_value();
    if (val_res.is_err()) return Result#(real)::Err(val_res.unwrap_err());

    val = val_res.unwrap();
    if (val.is_int()) begin
      void'(advance());
      return Result#(real)::Ok(val.as_int().unwrap().value);
    end
    if (!val.is_real()) return Result#(real)::Err("Expected json_real or json_int");

    void'(advance());
    return Result#(real)::Ok(val.as_real().unwrap().value);
  endfunction

  virtual function Result#(string) deserialize_string();
    Result#(json_value) val_res;
    json_value val;

    val_res = get_current_value();
    if (val_res.is_err()) return Result#(string)::Err(val_res.unwrap_err());

    val = val_res.unwrap();
    if (!val.is_string()) return Result#(string)::Err("Expected json_string");

    void'(advance());
    return Result#(string)::Ok(val.as_string().unwrap().value);
  endfunction

  virtual function Result#(bit) deserialize_bool();
    Result#(json_value) val_res;
    json_value val;

    val_res = get_current_value();
    if (val_res.is_err()) return Result#(bit)::Err(val_res.unwrap_err());

    val = val_res.unwrap();
    if (!val.is_bool()) return Result#(bit)::Err("Expected json_bool");

    void'(advance());
    return Result#(bit)::Ok(val.as_bool().unwrap().value);
  endfunction

  virtual function Result#(bit) deserialize_null();
    Result#(json_value) val_res;
    json_value val;

    val_res = get_current_value();
    if (val_res.is_err()) return Result#(bit)::Err(val_res.unwrap_err());

    val = val_res.unwrap();
    if (!val.is_null()) return Result#(bit)::Err("Expected json_null");

    void'(advance());
    return Result#(bit)::Ok(1);
  endfunction

  // =========================================================================
  // Composite types
  // =========================================================================

  virtual function Result#(bit) deserialize_sequence_start();
    Result#(json_value) val_res;
    json_value val;
    json_value_frame frame;
    json_array arr;

    val_res = get_current_value();
    if (val_res.is_err()) return Result#(bit)::Err(val_res.unwrap_err());

    val = val_res.unwrap();
    if (!val.is_array()) return Result#(bit)::Err("Expected array");

    // Push current position to stack and reset for new container
    frame = new(val);
    stack.push_back(frame);

    // Set current to first element
    arr = val.as_array().unwrap();
    if (arr.size() > 0) begin
      current = arr.get(0);
    end else begin
      is_exhausted = 1;
    end

    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) deserialize_object_start();
    Result#(json_value) val_res;
    json_value val;
    json_value_frame frame;
    string first_key;
    json_object obj;

    val_res = get_current_value();
    if (val_res.is_err()) return Result#(bit)::Err(val_res.unwrap_err());

    val = val_res.unwrap();
    if (!val.is_object()) return Result#(bit)::Err("Expected object");

    // Push current position to stack and reset for new container
    frame = new(val);
    stack.push_back(frame);

    // Set current to first key's value
    if (frame.keys.size() > 0) begin
      first_key = frame.keys[0];
      obj = val.as_object().unwrap();
      current = obj.get(first_key);
    end else begin
      is_exhausted = 1;
    end

    return Result#(bit)::Ok(1);
  endfunction

  // =========================================================================
  // Private helpers for deserialize_any
  // =========================================================================

  protected function Result#(bit) deserialize_array_any(serde_visitor visitor);
    Result#(bit) res;
    Result#(bit) more_res;
    bit more;

    res = deserialize_sequence_start();
    if (res.is_err()) return res;

    res = visitor.visit_array_start();
    if (res.is_err()) return res;

    more_res = check_has_more();
    if (more_res.is_err()) return more_res;
    more = more_res.unwrap();

    while (more) begin
      res = deserialize_any(visitor);
      if (res.is_err()) return res;

      more_res = check_has_more();
      if (more_res.is_err()) return more_res;
      more = more_res.unwrap();
    end

    return visitor.visit_array_end();
  endfunction

  protected function Result#(bit) deserialize_object_any(serde_visitor visitor);
    Result#(bit) res;
    Result#(bit) more_res;
    Result#(string) key_res;
    bit more;
    string key;

    res = deserialize_object_start();
    if (res.is_err()) return res;

    res = visitor.visit_object_start();
    if (res.is_err()) return res;

    more_res = check_has_more();
    if (more_res.is_err()) return more_res;
    more = more_res.unwrap();

    while (more) begin
      // Let the visitor handle key deserialization naturally
      // visitor.visit_key() will internally call deserialize_key() which advances to value
      key_res = deserialize_key();
      if (key_res.is_err()) return Result#(bit)::Err(key_res.unwrap_err());
      res = visitor.visit_key(key_res.unwrap());
      if (res.is_err()) return res;

      // Now read the value
      res = deserialize_any(visitor);
      if (res.is_err()) return res;

      more_res = check_has_more();
      if (more_res.is_err()) return more_res;
      more = more_res.unwrap();
    end

    return visitor.visit_object_end();
  endfunction

  virtual function bit is_human_readable();
    return 1;
  endfunction

endclass

`endif
