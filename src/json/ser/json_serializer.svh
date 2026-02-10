// json_serializer.svh - JSON serializer implementing serde_serializer interface
// Uses a json_formatter for output generation (compact or pretty)

`ifndef SV_JSON_SERIALIZER_SVH
`define SV_JSON_SERIALIZER_SVH

class json_serializer extends serde_serializer;
  `ifndef SV_SERDE_MAX_NEST
  `define SV_SERDE_MAX_NEST 1024
  `endif
  localparam int MAX_NEST = `SV_SERDE_MAX_NEST;

  // Formatter for output generation
  protected json_formatter fmt;

  // Stack-based tracking for first-element detection
  // These replace the complex comma logic in the serializer
  protected bit first_stack[MAX_NEST];
  protected context_t ctx_stack[MAX_NEST];
  protected int stack_ptr;

  function new(json_formatter f = null);
    super.new();
    // Default to compact formatter if none provided
    if (f == null) begin
      json_compact_formatter default_fmt = new();
      fmt = default_fmt;
    end else begin
      fmt = f;
    end

    stack_ptr = 0;
    first_stack[0] = 1;
    ctx_stack[0] = CTX_ROOT;
  endfunction

  function Result#(string) get_string();
    return Result#(string)::Ok(fmt.get_result());
  endfunction

  // Helper: Check if this is the first element in current container
  protected function bit is_first();
    if (stack_ptr < 0) return 1;
    return first_stack[stack_ptr];
  endfunction

  // Helper: Mark current position as not-first (so next element gets comma)
  protected function void mark_not_first();
    if (stack_ptr >= 0) begin
      first_stack[stack_ptr] = 0;
    end
  endfunction

  // Helper: Push new container context onto stack
  protected function void push_context(context_t ctx);
    if (stack_ptr < MAX_NEST - 1) begin
      stack_ptr++;
      first_stack[stack_ptr] = 1;
      ctx_stack[stack_ptr] = ctx;
    end
  endfunction

  // Helper: Pop container context from stack
  protected function void pop_context();
    if (stack_ptr > 0) begin
      stack_ptr--;
    end
  endfunction

  // Static convenience methods
  static function Result#(string) to_string(json_value val);
    json_serializer enc;
    Result#(bit) res;

    enc = new();  // Uses compact formatter by default
    if (val != null)
      res = enc.serialize_value(val);
    else
      res = enc.serialize_null();

    if (res.is_err()) return Result#(string)::Err(res.unwrap_err());
    return enc.get_string();
  endfunction

  // Static method for streaming to a file descriptor
  static function Result#(bit) to_writer(int fd, json_value val);
    json_serializer enc;
    Result#(bit) res;
    file_writer fw;
    json_compact_formatter fmt;

    // Create file writer and formatter
    fw = new(fd);
    fmt = new(fw);
    enc = new(fmt);

    if (val != null)
      res = enc.serialize_value(val);
    else
      res = enc.serialize_null();

    if (res.is_err()) return res;

    // Flush the writer to ensure all data is written
    void'(fw.flush());
    return Result#(bit)::Ok(1);
  endfunction

  // Static method for streaming pretty output to a file descriptor
  static function Result#(bit) to_writer_pretty(int fd, json_value val);
    json_serializer enc;
    Result#(bit) res;
    file_writer fw;
    json_pretty_formatter fmt;

    // Create file writer and pretty formatter
    fw = new(fd);
    fmt = new(fw);
    enc = new(fmt);

    if (val != null)
      res = enc.serialize_value(val);
    else
      res = enc.serialize_null();

    if (res.is_err()) return res;

    // Flush the writer to ensure all data is written
    void'(fw.flush());
    return Result#(bit)::Ok(1);
  endfunction

  // serde_serializer interface implementation
  virtual function Result#(bit) serialize_value(json_value val);
    Result#(bit) res;

    if (val == null) begin
      return serialize_null();
    end

    if (val.is_int()) begin
      res = serialize_int(val.as_int().unwrap().value);
    end
    else if (val.is_real()) begin
      res = serialize_real(val.as_real().unwrap().value);
    end
    else if (val.is_string()) begin
      res = serialize_string(val.as_string().unwrap().value);
    end
    else if (val.is_bool()) begin
      res = serialize_bool(val.as_bool().unwrap().value);
    end
    else if (val.is_null()) begin
      res = serialize_null();
    end
    else if (val.is_array()) begin
      // Don't manually push context here - serialize_array -> serialize_array_start will do it
      res = serialize_array(val.as_array().unwrap());
    end
    else if (val.is_object()) begin
      // Don't manually push context here - serialize_object -> serialize_object_start will do it
      res = serialize_object(val.as_object().unwrap());
    end
    else begin
      res = Result#(bit)::Err("Unknown json_value type");
    end

    return res;
  endfunction

  virtual function Result#(bit) serialize_int(longint val);
    // Check context: arrays need comma before value, objects don't
    if (stack_ptr > 0 && ctx_stack[stack_ptr] == CTX_ARRAY) begin
      fmt.begin_array_value(is_first());
      mark_not_first();
    end else begin
      // Object context or root - no comma needed before value
      fmt.write_object_value();
    end
    fmt.write_int(val);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_real(real val);
    // Check context
    if (stack_ptr > 0 && ctx_stack[stack_ptr] == CTX_ARRAY) begin
      fmt.begin_array_value(is_first());
      mark_not_first();
    end else begin
      fmt.write_object_value();
    end
    fmt.write_real(val);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_string(string val);
    if (stack_ptr > 0 && ctx_stack[stack_ptr] == CTX_ARRAY) begin
      fmt.begin_array_value(is_first());
      mark_not_first();
    end else begin
      fmt.write_object_value();
    end
    fmt.write_string(val);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_bool(bit val);
    if (stack_ptr > 0 && ctx_stack[stack_ptr] == CTX_ARRAY) begin
      fmt.begin_array_value(is_first());
      mark_not_first();
    end else begin
      fmt.write_object_value();
    end
    fmt.write_bool(val);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_null();
    if (stack_ptr > 0 && ctx_stack[stack_ptr] == CTX_ARRAY) begin
      fmt.begin_array_value(is_first());
      mark_not_first();
    end else begin
      fmt.write_object_value();
    end
    fmt.write_null();
    return Result#(bit)::Ok(1);
  endfunction

  // len = -1 means unknown length (optional, like Rust's Option<usize>::None)
  virtual function Result#(bit) serialize_array_start(longint len = -1);
    // Check if we're inside an array (need to add comma/newline before this array)
    if (stack_ptr > 0 && ctx_stack[stack_ptr] == CTX_ARRAY) begin
      fmt.begin_array_value(is_first());
      mark_not_first();
    end

    fmt.begin_array();
    push_context(CTX_ARRAY);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_array_end();
    pop_context();
    fmt.end_array();
    return Result#(bit)::Ok(1);
  endfunction

  // len = -1 means unknown length (optional, like Rust's Option<usize>::None)
  virtual function Result#(bit) serialize_object_start(longint len = -1);
    // Check if we're inside an array (need to add comma/newline before this object)
    if (stack_ptr > 0 && ctx_stack[stack_ptr] == CTX_ARRAY) begin
      fmt.begin_array_value(is_first());
      mark_not_first();
    end

    fmt.begin_object();
    push_context(CTX_OBJECT);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_object_end();
    pop_context();
    fmt.end_object();
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_key(string key);
    // Write key with comma handling (formatter tracks is_first via stack)
    fmt.write_key(key, is_first());
    mark_not_first();
    fmt.write_key_value_separator();
    return Result#(bit)::Ok(1);
  endfunction

  // Legacy helpers - not typically used with formatter pattern
  // These bypass the formatter and are kept for backward compatibility
  local function Result#(bit) serialize_array(json_array arr);
    Result#(bit) res;
    int i;

    // Pass actual array size (or -1 for unknown). Using -1 for simplicity.
    res = serialize_array_start();
    if (res.is_err()) return res;

    for (i = 0; i < arr.items.size(); i++) begin
      res = serialize_value(arr.items[i]);
      if (res.is_err()) return res;
    end

    return serialize_array_end();
  endfunction

  local function Result#(bit) serialize_object(json_object obj);
    Result#(bit) res;

    // Pass actual object size (or -1 for unknown). Using -1 for simplicity.
    res = serialize_object_start();
    if (res.is_err()) return res;

    foreach (obj.items[key]) begin
      res = serialize_key(key);
      if (res.is_err()) return res;
      res = serialize_value(obj.items[key]);
      if (res.is_err()) return res;
    end

    return serialize_object_end();
  endfunction
endclass

`endif
