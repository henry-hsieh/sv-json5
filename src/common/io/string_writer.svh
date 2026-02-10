// string_writer.svh - String-based writer implementation
// Accumulates output into a string (for to_string API)

`ifndef SV_STRING_WRITER_SVH
`define SV_STRING_WRITER_SVH

class string_writer implements io_writer;
  protected string buffer;

  function new();
    buffer = "";
  endfunction

  virtual function void write_fmt(string data);
    buffer = {buffer, data};
  endfunction

  virtual function void write_byte(byte b);
    buffer = {buffer, string'(b)};
  endfunction

  virtual function void flush();
    // No-op for string writer (data is already in memory)
  endfunction

  virtual function string get_result();
    return buffer;
  endfunction

  // Convenience: clear the buffer
  function void reset();
    buffer = "";
  endfunction
endclass

`endif
