// json_formatter.svh - Base interface for JSON formatting
// Abstracts the output generation (compact vs pretty)

`ifndef SV_JSON_FORMATTER_SVH
`define SV_JSON_FORMATTER_SVH

virtual class json_formatter;
  // Writer for output
  protected io_writer wr;

  function new(io_writer w = null);
    // Default to string_writer if none provided
    if (w == null) begin
      string_writer default_wr = new();
      wr = default_wr;
    end else begin
      wr = w;
    end
  endfunction

  // Get the writer (for external access if needed)
  function io_writer get_writer();
    return wr;
  endfunction

  // Result retrieval (delegates to writer)
  function string get_result();
    return wr.get_result();
  endfunction

  // Reset formatter state
  pure virtual function void reset();

  // Null handling
  pure virtual function void write_null();

  // Scalar values
  pure virtual function void write_bool(bit val);
  pure virtual function void write_int(longint val);
  pure virtual function void write_real(real val);
  pure virtual function void write_string(string val);

  // Container entry points
  pure virtual function void begin_array();
  pure virtual function void end_array();
  pure virtual function void begin_array_value(bit is_first);

  // Object handling
  pure virtual function void begin_object();
  pure virtual function void end_object();
  pure virtual function void write_key(string key, bit is_first);
  pure virtual function void write_key_value_separator();

  // Write value in object context (after key) - no comma needed
  pure virtual function void write_object_value();
endclass

`endif
