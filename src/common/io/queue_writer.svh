// Queue-based writer for binary data
// Provides io_writer interface using byte queue [$]

class queue_writer implements io_writer;
  byte q[$];

  function new();
    q = {};
  endfunction

  // io_writer interface
  virtual function void write_fmt(string data);
    // Use streaming to convert string to byte queue
    byte b;
    for (int i = 0; i < data.len(); i++) begin
      b = byte'(data[i]);
      q.push_back(b);
    end
  endfunction

  virtual function void write_byte(byte b);
    q.push_back(b);
  endfunction

  function void write_bytes(byte data[]);
    for (int i = 0; i < data.size(); i++) begin
      q.push_back(data[i]);
    end
  endfunction

  virtual function void flush();
    // No-op for queue-based writer
  endfunction

  virtual function string get_result();
    // Convert queue to string for compatibility
    string s = "";
    foreach (q[i]) begin
      s = {s, string'(q[i])};
    end
    return s;
  endfunction

  function int size();
    return q.size();
  endfunction

  function void clear();
    q = {};
  endfunction
endclass
