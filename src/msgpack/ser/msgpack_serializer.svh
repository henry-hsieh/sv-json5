// msgpack_serializer.svh - MessagePack serializer implementing serde_serializer

`ifndef MSGPACK_SERIALIZER_SVH
`define MSGPACK_SERIALIZER_SVH

class msgpack_serializer extends serde_serializer;
  byte_queue_t queue;  // Use queue for proper byte handling

  function new();
    byte_queue_t empty_queue = {};  // Create fresh empty queue
    queue = empty_queue;
  endfunction

  // Get the result as a string
  function string get_string();
    string result;
    for (int i = 0; i < queue.size(); i++) begin
      byte unsigned ub = unsigned'(queue[i]);  // Cast to unsigned first
      string hex_str;
      $sformat(hex_str, "%02x", ub);
      result = {result, hex_str};
    end
    return result;
  endfunction

  // Get the result as a dynamic byte array (for Rust/Python interop)
  function byte_array_t get_array();
    byte_array_t result;
    result = new[queue.size()];
    for (int i = 0; i < queue.size(); i++) begin
      result[i] = queue[i];
    end
    return result;
  endfunction

  //----------------------------------------------------------------
  // Scalar Serialization
  //----------------------------------------------------------------
  virtual function Result#(bit) serialize_int(longint val);
    if (val >= 0) begin
      return serialize_uint(val);
    end

    // Negative integers
    if (val >= -32) begin
      queue.push_back(byte'(val));  // fixint negative
      return Result#(bit)::Ok(1);
    end
    if (val >= -128) begin
      queue.push_back('hD0);
      queue.push_back(byte'(val));
      return Result#(bit)::Ok(1);
    end
    if (val >= -32768) begin
      queue.push_back('hD1);
      queue.push_back(byte'(val >> 8));
      queue.push_back(byte'(val));
      return Result#(bit)::Ok(1);
    end
    // int64
    begin
      longint v = val;
      queue.push_back('hD3);
      for (int i = 56; i >= 0; i -= 8) begin
        queue.push_back(byte'(v >> i));
      end
    end
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_uint(longint unsigned val);
    if (val <= 127) begin
      queue.push_back(byte'(val));  // fixnum positive
      return Result#(bit)::Ok(1);
    end
    if (val <= 255) begin
      queue.push_back('hCC);
      queue.push_back(byte'(val));
      return Result#(bit)::Ok(1);
    end
    if (val <= 65535) begin
      queue.push_back('hCD);
      queue.push_back(byte'(val >> 8));
      queue.push_back(byte'(val));
      return Result#(bit)::Ok(1);
    end
    if (val <= 4294967295) begin
      queue.push_back('hCE);
      queue.push_back(byte'(val >> 24));
      queue.push_back(byte'(val >> 16));
      queue.push_back(byte'(val >> 8));
      queue.push_back(byte'(val));
      return Result#(bit)::Ok(1);
    end
    // uint64
    begin
      queue.push_back('hCF);
      for (int i = 56; i >= 0; i -= 8) begin
        queue.push_back(byte'(val >> i));
      end
    end
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_real(real val);
    longint unsigned bits;
    // Float64: 0xCB
    queue.push_back('hCB);
    // Reinterpret real as unsigned longint bits
    bits = $realtobits(val);
    for (int i = 56; i >= 0; i -= 8) begin
      queue.push_back(byte'(bits >> i));
    end
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_string(string val);
    byte len;
    longint unsigned len2;
    len = val.len();
    if (len <= 31) begin
      queue.push_back('hA0 | byte'(len));  // fixstr
    end else if (len <= 255) begin
      queue.push_back('hB9);
      queue.push_back(byte'(len));
    end else if (len <= 65535) begin
      queue.push_back('hBA);
      len2 = len;
      queue.push_back(byte'(len2 >> 8));
      queue.push_back(byte'(len2));
    end else begin
      queue.push_back('hBB);
      len2 = len;
      queue.push_back(byte'(len2 >> 24));
      queue.push_back(byte'(len2 >> 16));
      queue.push_back(byte'(len2 >> 8));
      queue.push_back(byte'(len2));
    end
    // Push string bytes
    for (int i = 0; i < val.len(); i++) begin
      queue.push_back(byte'(val[i]));
    end
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_bool(bit val);
    queue.push_back(val ? 'hC3 : 'hC2);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_null();
    queue.push_back('hC0);  // nil
    return Result#(bit)::Ok(1);
  endfunction

  //----------------------------------------------------------------
  // Composite Serialization
  //----------------------------------------------------------------
  virtual function Result#(bit) serialize_array_start(longint len = -1);
    longint unsigned ulen;
    if (len < 0) begin
      return Result#(bit)::Err("serialize_array_start requires explicit length");
    end
    ulen = len;
    if (ulen <= 15) begin
      queue.push_back('h90 | byte'(ulen));  // fixarray
    end else if (ulen <= 65535) begin
      queue.push_back('hDC);
      queue.push_back(byte'(ulen >> 8));
      queue.push_back(byte'(ulen));
    end else begin
      queue.push_back('hDD);
      queue.push_back(byte'(ulen >> 24));
      queue.push_back(byte'(ulen >> 16));
      queue.push_back(byte'(ulen >> 8));
      queue.push_back(byte'(ulen));
    end
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) serialize_object_start(longint len = -1);
    longint unsigned ulen;
    if (len < 0) begin
      return Result#(bit)::Err("serialize_object_start requires explicit length");
    end
    ulen = len;
    if (ulen <= 15) begin
      queue.push_back('h80 | byte'(ulen));  // fixmap
    end else if (ulen <= 65535) begin
      queue.push_back('hDE);
      queue.push_back(byte'(ulen >> 8));
      queue.push_back(byte'(ulen));
    end else begin
      queue.push_back('hDF);
      queue.push_back(byte'(ulen >> 24));
      queue.push_back(byte'(ulen >> 16));
      queue.push_back(byte'(ulen >> 8));
      queue.push_back(byte'(ulen));
    end
    return Result#(bit)::Ok(1);
  endfunction

  // MessagePack doesn't have array end markers - no-op
  virtual function Result#(bit) serialize_array_end();
    return Result#(bit)::Ok(1);
  endfunction

  // MessagePack doesn't have object end markers - no-op
  virtual function Result#(bit) serialize_object_end();
    return Result#(bit)::Ok(1);
  endfunction

  // Keys in MessagePack maps are serialized as strings
  virtual function Result#(bit) serialize_key(string key);
    return serialize_string(key);
  endfunction
endclass

`endif // MSGPACK_SERIALIZER_SVH
