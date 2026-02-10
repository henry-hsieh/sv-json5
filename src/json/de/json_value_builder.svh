class json_value_builder extends serde_visitor;
  local json_value root;
  local json_value stack[$];
  local string keys[$];

  function new();
  endfunction

  function Result#(json_value) get_result();
    if (root == null) return Result#(json_value)::Err("No root value created");
    return Result#(json_value)::Ok(root);
  endfunction

  virtual function Result#(bit) visit_object_start();
    Result#(bit) res;
    json_object obj = json_object::create();
    res = push_value(obj);
    if (res.is_err()) return res;
    stack.push_back(obj);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_object_end();
    if (stack.size() == 0) return Result#(bit)::Err("Stack underflow in visit_object_end");
    void'(stack.pop_back());
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_array_start();
    Result#(bit) res;
    json_array arr = json_array::create();
    res = push_value(arr);
    if (res.is_err()) return res;
    stack.push_back(arr);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_array_end();
    if (stack.size() == 0) return Result#(bit)::Err("Stack underflow in visit_array_end");
    void'(stack.pop_back());
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_key(string key);
    keys.push_back(key);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_int(longint val);
    Result#(bit) res;
    json_int j = json_int::from(val);
    res = push_value(j);
    if (res.is_err()) return res;
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_real(real val);
    Result#(bit) res;
    json_real j = json_real::from(val);
    res = push_value(j);
    if (res.is_err()) return res;
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_string(string val);
    Result#(bit) res;
    json_string j = json_string::from(val);
    res = push_value(j);
    if (res.is_err()) return res;
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_bool(bit val);
    Result#(bit) res;
    json_bool j = json_bool::from(val);
    res = push_value(j);
    if (res.is_err()) return res;
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_null();
    Result#(bit) res;
    json_null j = json_null::from();
    res = push_value(j);
    if (res.is_err()) return res;
    return Result#(bit)::Ok(1);
  endfunction

  local function Result#(bit) push_value(json_value val);
    if (stack.size() == 0) begin
      root = val;
    end else begin
      json_value top = stack[stack.size()-1];
      if (top.is_object()) begin
        json_object obj = top.as_object().unwrap();
        if (keys.size() > 0) begin
          string key = keys.pop_back();
          obj.set(key, val);
        end else begin
          return Result#(bit)::Err("No key available for json_object");
        end
      end else if (top.is_array()) begin
        json_array arr = top.as_array().unwrap();
        arr.add(val);
      end
    end
    return Result#(bit)::Ok(1);
  endfunction

  // Pull-based visitor methods implemented using push-based stack methods
  virtual function Result#(bit) visit_seq(serde_seq_access seq);
    Result#(bit) res;
    json_array arr = json_array::create();

    // 1. Attach array to parent (or set as root)
    res = push_value(arr);
    if (res.is_err()) return res;

    // 2. Push array to stack so children can find it
    stack.push_back(arr);

    // 3. Process elements
    // has_next() now consumes the closing ']' when it returns 0
    while (1) begin
      Result#(bit) has_next_res = seq.has_next();
      if (has_next_res.is_err()) begin
        void'(stack.pop_back());
        return has_next_res;
      end
      if (!has_next_res.unwrap()) break;

      // next_element calls visitor methods which call push_value
      res = seq.next_element(this);
      if (res.is_err()) begin
        void'(stack.pop_back());
        return res;
      end
    end

    // 4. Restore stack
    void'(stack.pop_back());
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) visit_map(serde_map_access map);
    Result#(bit) res;
    json_object obj = json_object::create();

    // 1. Attach object to parent (or set as root)
    res = push_value(obj);
    if (res.is_err()) return res;

    // 2. Push object to stack so children can find it
    stack.push_back(obj);

    // 3. Process entries
    // has_next() now consumes the closing '}' when it returns 0
    while (1) begin
      Result#(bit) has_next_res;
      bit has_next;

      has_next_res = map.has_next();
      if (has_next_res.is_err()) begin
        void'(stack.pop_back());
        return has_next_res;
      end

      has_next = has_next_res.unwrap();
      if (!has_next) break;

      // next_entry calls visitor methods which call push_value
      res = map.next_entry(this);
      if (res.is_err()) begin
        void'(stack.pop_back());
        return res;
      end
    end

    // 4. Restore stack
    void'(stack.pop_back());
    return Result#(bit)::Ok(1);
  endfunction

endclass
