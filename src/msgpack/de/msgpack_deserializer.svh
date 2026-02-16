// msgpack_deserializer.svh - MessagePack deserializer implementing serde_deserializer

`ifndef MSGPACK_DESERIALIZER_SVH
`define MSGPACK_DESERIALIZER_SVH

class msgpack_deserializer extends serde_deserializer implements serde_seq_access, serde_map_access;
  byte_queue_t queue;

  // State for seq/map iteration
  longint unsigned seq_remaining;
  longint unsigned map_remaining;
  typedef enum { STATE_NONE, STATE_SEQ, STATE_MAP } iter_state_t;
  iter_state_t iter_state;

  // State stack for nested collections
  typedef struct {
    iter_state_t iter_state;
    longint unsigned seq_remaining;
    longint unsigned map_remaining;
  } iter_stack_item_t;
  iter_stack_item_t state_stack[$];

  function void push_state();
    iter_stack_item_t item;
    item.iter_state = iter_state;
    item.seq_remaining = seq_remaining;
    item.map_remaining = map_remaining;
    state_stack.push_back(item);
  endfunction

  function void pop_state();
    iter_stack_item_t item;
    if (state_stack.size() > 0) begin
      item = state_stack.pop_back();
      iter_state = item.iter_state;
      seq_remaining = item.seq_remaining;
      map_remaining = item.map_remaining;
    end
  endfunction

  function new(byte_array_t data);
    // Array to queue conversion - iterate manually
    for (int i = 0; i < data.size(); i++) begin
      queue.push_back(data[i]);
    end
    iter_state = STATE_NONE;
  endfunction

  // Helper: Peek at next byte without consuming
  function byte peek_byte();
    if (queue.size() == 0) begin
      return 0;
    end
    return queue[0];
  endfunction

  // Helper: Get next byte
  function byte next_byte();
    byte b;
    if (queue.size() == 0) begin
      return 0;
    end
    b = queue.pop_front();
    return b;
  endfunction

  //----------------------------------------------------------------
  // Deserialize Any - Peek and dispatch to visitor
  //----------------------------------------------------------------
  virtual function Result#(bit) deserialize_any(serde_visitor visitor);
    byte b;
    longint val;
    longint unsigned uval;
    real rval;
    string s;
    int len;
    longint unsigned count;

    b = peek_byte();

    // Fixnum positive (0x00 - 0x7F)
    if (b <= 'h7F) begin
      next_byte();
      if (visitor != null) begin
        uval = b;
        return visitor.visit_uint(uval);
      end
      return Result#(bit)::Ok(1);
    end

    // Fixnum negative (0xE0 - 0xFF)
    if (b >= 'hE0) begin
      next_byte();
      val = longint'(b);
      if (visitor != null) begin
        return visitor.visit_int(val);
      end
      return Result#(bit)::Ok(1);
    end

    // nil
    if (b == 'hC0) begin
      next_byte();
      if (visitor != null) begin
        return visitor.visit_null();
      end
      return Result#(bit)::Ok(1);
    end

    // bool
    if (b == 'hC2 || b == 'hC3) begin
      next_byte();
      if (visitor != null) begin
        return visitor.visit_bool(b == 'hC3);
      end
      return Result#(bit)::Ok(1);
    end

    // float
    if (b == 'hCB) begin
      next_byte();
      uval = 0;
      for (int i = 0; i < 8; i++) begin
        uval = (uval << 8) | next_byte();
      end
      rval = $bitstoreal(uval);
      if (visitor != null) begin
        return visitor.visit_real(rval);
      end
      return Result#(bit)::Ok(1);
    end

    // uint8
    if (b == 'hCC) begin
      next_byte();
      uval = next_byte();
      if (visitor != null) begin
        return visitor.visit_uint(uval);
      end
      return Result#(bit)::Ok(1);
    end

    // uint16
    if (b == 'hCD) begin
      next_byte();
      uval = (next_byte() << 8) | next_byte();
      if (visitor != null) begin
        return visitor.visit_uint(uval);
      end
      return Result#(bit)::Ok(1);
    end

    // uint32
    if (b == 'hCE) begin
      next_byte();
      uval = 0;
      for (int i = 0; i < 4; i++) begin
        uval = (uval << 8) | next_byte();
      end
      if (visitor != null) begin
        return visitor.visit_uint(uval);
      end
      return Result#(bit)::Ok(1);
    end

    // uint64
    if (b == 'hCF) begin
      next_byte();
      uval = 0;
      for (int i = 0; i < 8; i++) begin
        uval = (uval << 8) | next_byte();
      end
      if (visitor != null) begin
        return visitor.visit_uint(uval);
      end
      return Result#(bit)::Ok(1);
    end

    // int8
    if (b == 'hD0) begin
      next_byte();
      val = longint'(next_byte());
      if (visitor != null) begin
        return visitor.visit_int(val);
      end
      return Result#(bit)::Ok(1);
    end

    // int16
    if (b == 'hD1) begin
      next_byte();
      val = (next_byte() << 8) | next_byte();
      // Sign extend
      if (val & 'h8000) begin
        val = val | 'hFFFF_0000;
      end
      if (visitor != null) begin
        return visitor.visit_int(val);
      end
      return Result#(bit)::Ok(1);
    end

    // int32
    if (b == 'hD2) begin
      next_byte();
      val = 0;
      for (int i = 0; i < 4; i++) begin
        val = (val << 8) | next_byte();
      end
      if (val & 'h8000_0000) begin
        val = val | 'hFFFF_FFFF_0000_0000;
      end
      if (visitor != null) begin
        return visitor.visit_int(val);
      end
      return Result#(bit)::Ok(1);
    end

    // int64
    if (b == 'hD3) begin
      next_byte();
      val = 0;
      for (int i = 0; i < 8; i++) begin
        val = (val << 8) | next_byte();
      end
      if (visitor != null) begin
        return visitor.visit_int(val);
      end
      return Result#(bit)::Ok(1);
    end

    // str8, str16, str32
    if ((b & 'hE0) == 'hA0) begin
      return deserialize_string_visitor(visitor);
    end
    if (b == 'hD9) begin
      next_byte();
      len = next_byte();
      s = "";
      for (int i = 0; i < len; i++) begin
        s = {s, string'(next_byte())};
      end
      if (visitor != null) begin
        return visitor.visit_string(s);
      end
      return Result#(bit)::Ok(1);
    end
    if (b == 'hDA) begin
      next_byte();
      len = (next_byte() << 8) | next_byte();
      s = "";
      for (int i = 0; i < len; i++) begin
        s = {s, string'(next_byte())};
      end
      if (visitor != null) begin
        return visitor.visit_string(s);
      end
      return Result#(bit)::Ok(1);
    end
    if (b == 'hDB) begin
      next_byte();
      len = 0;
      for (int i = 0; i < 4; i++) begin
        len = (len << 8) | next_byte();
      end
      s = "";
      for (int i = 0; i < len; i++) begin
        s = {s, string'(next_byte())};
      end
      if (visitor != null) begin
        return visitor.visit_string(s);
      end
      return Result#(bit)::Ok(1);
    end

    // fixarray (0x90 - 0x9F)
    if ((b & 'hF0) == 'h90) begin
      return deserialize_seq_visitor(visitor);
    end
    // array16, array32
    if (b == 'hDC || b == 'hDD) begin
      return deserialize_seq_visitor(visitor);
    end

    // fixmap (0x80 - 0x8F)
    if ((b & 'hF0) == 'h80) begin
      return deserialize_map_visitor(visitor);
    end
    // map16, map32
    if (b == 'hDE || b == 'hDF) begin
      return deserialize_map_visitor(visitor);
    end

    return Result#(bit)::Err($sformatf("Unknown msgpack byte: 0x%02h", b));
  endfunction

  // Helper for string deserialization with visitor
  function Result#(bit) deserialize_string_visitor(serde_visitor visitor);
    byte b;
    string s;
    int len;
    b = peek_byte();
    // fixstr
    if ((b & 'hE0) == 'hA0) begin
      next_byte();
      len = b & 'h1F;
      s = "";
      for (int i = 0; i < len; i++) begin
        s = {s, string'(next_byte())};
      end
      if (visitor != null) begin
        return visitor.visit_string(s);
      end
      return Result#(bit)::Ok(1);
    end
    return Result#(bit)::Err("Not a string");
  endfunction

  // Helper for seq deserialization with visitor
  function Result#(bit) deserialize_seq_visitor(serde_visitor visitor);
    byte b;
    longint unsigned count;
    Result#(bit) res;

    b = peek_byte();

    // fixarray
    if ((b & 'hF0) == 'h90) begin
      next_byte();
      count = b & 'h0F;
    end
    // array16
    else if (b == 'hDC) begin
      next_byte();
      count = (next_byte() << 8) | next_byte();
    end
    // array32
    else if (b == 'hDD) begin
      next_byte();
      count = 0;
      for (int i = 0; i < 4; i++) begin
        count = (count << 8) | next_byte();
      end
    end
    else begin
      return Result#(bit)::Err("Not an array");
    end

    if (visitor != null) begin
      push_state();
      iter_state = STATE_SEQ;
      seq_remaining = count;
      res = visitor.visit_seq(this);
      pop_state();
      return res;
    end

    iter_state = STATE_SEQ;
    seq_remaining = count;
    return Result#(bit)::Ok(1);
  endfunction

  // Helper for map deserialization with visitor
  function Result#(bit) deserialize_map_visitor(serde_visitor visitor);
    byte b;
    longint unsigned count;
    Result#(bit) res;

    b = peek_byte();

    // fixmap
    if ((b & 'hF0) == 'h80) begin
      next_byte();
      count = b & 'h0F;
    end
    // map16
    else if (b == 'hDE) begin
      next_byte();
      count = (next_byte() << 8) | next_byte();
    end
    // map32
    else if (b == 'hDF) begin
      next_byte();
      count = 0;
      for (int i = 0; i < 4; i++) begin
        count = (count << 8) | next_byte();
      end
    end
    else begin
      return Result#(bit)::Err("Not a map");
    end

    if (visitor != null) begin
      push_state();
      iter_state = STATE_MAP;
      map_remaining = count;
      res = visitor.visit_map(this);
      pop_state();
      return res;
    end

    iter_state = STATE_MAP;
    map_remaining = count;
    return Result#(bit)::Ok(1);
  endfunction

  //----------------------------------------------------------------
  // serde_seq_access implementation
  //----------------------------------------------------------------
  virtual function Result#(bit) has_next();
    if (iter_state == STATE_SEQ) begin
      return Result#(bit)::Ok(seq_remaining > 0);
    end
    if (iter_state == STATE_MAP) begin
      return Result#(bit)::Ok(map_remaining > 0);
    end
    return Result#(bit)::Err("Not in sequence or map iteration");
  endfunction

  virtual function Result#(bit) next_element(serde_visitor visitor);
    if (iter_state != STATE_SEQ) begin
      return Result#(bit)::Err("Not in sequence iteration");
    end
    if (seq_remaining == 0) begin
      return Result#(bit)::Err("No more elements in array");
    end
    seq_remaining--;
    return this.deserialize_any(visitor);
  endfunction

  //----------------------------------------------------------------
  // serde_map_access implementation
  //----------------------------------------------------------------
  virtual function Result#(string) next_key();
    if (iter_state != STATE_MAP) begin
      return Result#(string)::Err("Not in map iteration");
    end
    if (map_remaining == 0) begin
      return Result#(string)::Err("No more keys in map");
    end
    map_remaining--;
    return deserialize_key();
  endfunction

  virtual function Result#(bit) next_value(serde_deserializer d);
    if (iter_state != STATE_MAP) begin
      return Result#(bit)::Err("Not in map iteration");
    end
    return d.deserialize_any(null);
  endfunction

  // Implementation of serde_map_access interface
  virtual function Result#(bit) next_entry(serde_visitor visitor);
    Result#(string) key_res;
    string key_str;
    Result#(bit) key_res_ok;
    Result#(bit) val_res;

    // First deserialize the key as a string
    key_res = deserialize_key();
    if (key_res.is_err()) begin
      return Result#(bit)::Err(key_res.unwrap_err());
    end
    key_str = key_res.unwrap();

    // Tell the visitor about the key
    if (visitor != null) begin
      key_res_ok = visitor.visit_key(key_str);
      if (key_res_ok.is_err()) return key_res_ok;
    end

    // Then deserialize the value
    val_res = this.deserialize_any(visitor);
    if (val_res.is_ok()) begin
      map_remaining--;
    end
    return val_res;
  endfunction

  //----------------------------------------------------------------
  // Scalar Deserialization
  //----------------------------------------------------------------
  virtual function Result#(longint) deserialize_int();
    byte b;
    b = peek_byte();

    // Fixnum positive
    if (b <= 'h7F) begin
      next_byte();
      return Result#(longint)::Ok(b);
    end

    // Fixnum negative
    if (b >= 'hE0) begin
      next_byte();
      return Result#(longint)::Ok(longint'(b));
    end

    // int8
    if (b == 'hD0) begin
      next_byte();
      return Result#(longint)::Ok(longint'(next_byte()));
    end

    // int16
    if (b == 'hD1) begin
      next_byte();
      return Result#(longint)::Ok((next_byte() << 8) | next_byte());
    end

    // int32
    if (b == 'hD2) begin
      longint v;
      next_byte();
      v = 0;
      for (int i = 0; i < 4; i++) begin
        v = (v << 8) | next_byte();
      end
      return Result#(longint)::Ok(v);
    end

    // int64
    if (b == 'hD3) begin
      longint v;
      next_byte();
      v = 0;
      for (int i = 0; i < 8; i++) begin
        v = (v << 8) | next_byte();
      end
      return Result#(longint)::Ok(v);
    end

    return Result#(longint)::Err("Not an integer");
  endfunction

  virtual function Result#(longint unsigned) deserialize_uint();
    byte b;
    b = peek_byte();

    // Fixnum positive
    if (b <= 'h7F) begin
      next_byte();
      return Result#(longint unsigned)::Ok(b);
    end

    // uint8
    if (b == 'hCC) begin
      next_byte();
      return Result#(longint unsigned)::Ok(next_byte());
    end

    // uint16
    if (b == 'hCD) begin
      longint unsigned v;
      next_byte();
      v = (next_byte() << 8) | next_byte();
      return Result#(longint unsigned)::Ok(v);
    end

    // uint32
    if (b == 'hCE) begin
      longint unsigned v;
      next_byte();
      v = 0;
      for (int i = 0; i < 4; i++) begin
        v = (v << 8) | next_byte();
      end
      return Result#(longint unsigned)::Ok(v);
    end

    // uint64
    if (b == 'hCF) begin
      longint unsigned v;
      next_byte();
      v = 0;
      for (int i = 0; i < 8; i++) begin
        v = (v << 8) | next_byte();
      end
      return Result#(longint unsigned)::Ok(v);
    end

    return Result#(longint unsigned)::Err("Not an unsigned integer");
  endfunction

  virtual function Result#(real) deserialize_real();
    byte b;
    longint unsigned bits;
    b = peek_byte();

    if (b == 'hCB) begin
      next_byte();
      bits = 0;
      for (int i = 0; i < 8; i++) begin
        bits = (bits << 8) | next_byte();
      end
      return Result#(real)::Ok($bitstoreal(bits));
    end

    return Result#(real)::Err("Not a real/float");
  endfunction

  virtual function Result#(string) deserialize_string();
    byte b;
    b = peek_byte();

    // fixstr
    if ((b & 'hE0) == 'hA0) begin
      string s;
      int len;
      next_byte();
      len = b & 'h1F;
      s = "";
      for (int i = 0; i < len; i++) begin
        s = {s, string'(next_byte())};
      end
      return Result#(string)::Ok(s);
    end

    // str8
    if (b == 'hD9) begin
      string s;
      int len;
      next_byte();
      len = next_byte();
      s = "";
      for (int i = 0; i < len; i++) begin
        s = {s, string'(next_byte())};
      end
      return Result#(string)::Ok(s);
    end

    // str16
    if (b == 'hDA) begin
      string s;
      int len;
      next_byte();
      len = (next_byte() << 8) | next_byte();
      s = "";
      for (int i = 0; i < len; i++) begin
        s = {s, string'(next_byte())};
      end
      return Result#(string)::Ok(s);
    end

    // str32
    if (b == 'hDB) begin
      string s;
      int len;
      next_byte();
      len = 0;
      for (int i = 0; i < 4; i++) begin
        len = (len << 8) | next_byte();
      end
      s = "";
      for (int i = 0; i < len; i++) begin
        s = {s, string'(next_byte())};
      end
      return Result#(string)::Ok(s);
    end

    return Result#(string)::Err("Not a string");
  endfunction

  virtual function Result#(bit) deserialize_bool();
    byte b;
    b = peek_byte();
    if (b == 'hC2) begin
      next_byte();
      return Result#(bit)::Ok(0);
    end
    if (b == 'hC3) begin
      next_byte();
      return Result#(bit)::Ok(1);
    end
    return Result#(bit)::Err("Not a boolean");
  endfunction

  virtual function Result#(bit) deserialize_null();
    byte b;
    b = peek_byte();
    if (b == 'hC0) begin
      next_byte();
      return Result#(bit)::Ok(1);
    end
    return Result#(bit)::Err("Not null");
  endfunction

  //----------------------------------------------------------------
  // Composite Deserialization
  //----------------------------------------------------------------
  virtual function Result#(bit) deserialize_sequence_start();
    Result#(serde_seq_access) res = deserialize_seq();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) deserialize_object_start();
    Result#(serde_map_access) res = deserialize_map();
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(serde_seq_access) deserialize_seq();
    byte b;
    longint unsigned count;

    b = peek_byte();

    // fixarray
    if ((b & 'hF0) == 'h90) begin
      next_byte();
      count = b & 'h0F;
      iter_state = STATE_SEQ;
      seq_remaining = count;
      return Result#(serde_seq_access)::Ok(this);
    end

    // array16
    if (b == 'hDC) begin
      next_byte();
      count = (next_byte() << 8) | next_byte();
      iter_state = STATE_SEQ;
      seq_remaining = count;
      return Result#(serde_seq_access)::Ok(this);
    end

    // array32
    if (b == 'hDD) begin
      next_byte();
      count = 0;
      for (int i = 0; i < 4; i++) begin
        count = (count << 8) | next_byte();
      end
      iter_state = STATE_SEQ;
      seq_remaining = count;
      return Result#(serde_seq_access)::Ok(this);
    end

    return Result#(serde_seq_access)::Err("Not an array");
  endfunction

  virtual function Result#(serde_map_access) deserialize_map();
    byte b;
    longint unsigned count;

    b = peek_byte();

    // fixmap
    if ((b & 'hF0) == 'h80) begin
      next_byte();
      count = b & 'h0F;
      iter_state = STATE_MAP;
      map_remaining = count;
      return Result#(serde_map_access)::Ok(this);
    end

    // map16
    if (b == 'hDE) begin
      next_byte();
      count = (next_byte() << 8) | next_byte();
      iter_state = STATE_MAP;
      map_remaining = count;
      return Result#(serde_map_access)::Ok(this);
    end

    // map32
    if (b == 'hDF) begin
      next_byte();
      count = 0;
      for (int i = 0; i < 4; i++) begin
        count = (count << 8) | next_byte();
      end
      iter_state = STATE_MAP;
      map_remaining = count;
      return Result#(serde_map_access)::Ok(this);
    end

    return Result#(serde_map_access)::Err("Not a map");
  endfunction

  virtual function Result#(string) deserialize_key();
    return deserialize_string();
  endfunction

  virtual function bit is_human_readable();
    return 0;  // Binary format
  endfunction
endclass

`endif
