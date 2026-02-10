// json_compact_formatter.svh - Compact JSON formatter (no whitespace)

`ifndef SV_JSON_COMPACT_FORMATTER_SVH
`define SV_JSON_COMPACT_FORMATTER_SVH

class json_compact_formatter extends json_formatter;

  function new(io_writer w = null);
    super.new(w);
  endfunction

  virtual function void reset();
    // For string_writer, reset the buffer
    string_writer s_wr;
    if ($cast(s_wr, wr)) begin
      s_wr.reset();
    end
  endfunction

  virtual function void write_null();
    wr.write_fmt("null");
  endfunction

  virtual function void write_bool(bit val);
    wr.write_fmt(val ? "true" : "false");
  endfunction

  virtual function void write_int(longint val);
    wr.write_fmt($sformatf("%0d", val));
  endfunction

  virtual function void write_real(real val);
    wr.write_fmt($sformatf("%0g", val));
  endfunction

  virtual function void write_string(string val);
    wr.write_fmt("\"");
    for (int i=0; i < val.len(); i++) begin
      byte c = val[i];
      case (c)
        "\"": wr.write_fmt("\\\"");
        "\\": wr.write_fmt("\\\\");
        "\n": wr.write_fmt("\\n");
        "\x0D": wr.write_fmt("\\r");
        "\t": wr.write_fmt("\\t");
        default: wr.write_byte(c);
      endcase
    end
    wr.write_fmt("\"");
  endfunction

  virtual function void begin_array();
    wr.write_fmt("[");
  endfunction

  virtual function void end_array();
    wr.write_fmt("]");
  endfunction

  virtual function void begin_array_value(bit is_first);
    // Compact: just add comma if not first
    if (!is_first) begin
      wr.write_fmt(",");
    end
  endfunction

  virtual function void begin_object();
    wr.write_fmt("{");
  endfunction

  virtual function void end_object();
    wr.write_fmt("}");
  endfunction

  virtual function void write_key(string key, bit is_first);
    // Compact: add comma if not first
    if (!is_first) begin
      wr.write_fmt(",");
    end
    wr.write_fmt("\"");
    wr.write_fmt(key);
    wr.write_fmt("\"");
  endfunction

  virtual function void write_key_value_separator();
    wr.write_fmt(":");
  endfunction

  // Write value in object context - no comma needed
  virtual function void write_object_value();
    // Compact: nothing to do
  endfunction

endclass

`endif
