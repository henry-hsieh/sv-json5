// Queue-based reader for binary data
// Provides io_reader interface using byte queue [$]

class queue_reader implements io_reader;
  byte q[$];
  int idx;

  function new();
    idx = 0;
  endfunction

  function void set_queue(byte data[]);
    byte b;
    q = {};
    for (int i = 0; i < data.size(); i++) begin
      b = data[i];
      q.push_back(b);
    end
    idx = 0;
  endfunction

  // io_reader interface
  virtual function byte peek();
    if (idx >= q.size()) begin
      return 0;
    end
    return q[idx];
  endfunction

  virtual function byte next();
    byte b = peek();
    if (idx < q.size()) begin
      idx++;
    end
    return b;
  endfunction

  virtual function void consume();
    if (idx < q.size()) begin
      idx++;
    end
  endfunction

  virtual function bit is_eof();
    return idx >= q.size();
  endfunction

  virtual function int get_pos();
    return idx;
  endfunction

  virtual function int get_len();
    return q.size();
  endfunction

  // Extended API
  function Result#(byte) read_byte();
    Result#(byte) res;
    if (idx >= q.size()) begin
      return Result#(byte)::Err("EOF");
    end
    res = Result#(byte)::Ok(q[idx]);
    idx++;
    return res;
  endfunction

  function Result#(byte) peek_byte();
    if (idx >= q.size()) begin
      return Result#(byte)::Err("EOF");
    end
    return Result#(byte)::Ok(q[idx]);
  endfunction

  function void skip(int n);
    idx += n;
    if (idx > q.size()) idx = q.size();
  endfunction

  function void reset();
    idx = 0;
  endfunction
endclass
