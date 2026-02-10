// json_pretty_formatter.svh - Pretty JSON formatter with customizable indentation

`ifndef SV_JSON_PRETTY_FORMATTER_SVH
`define SV_JSON_PRETTY_FORMATTER_SVH

class json_pretty_formatter extends json_formatter;
  `ifndef SV_SERDE_MAX_NEST
  `define SV_SERDE_MAX_NEST 1024
  `endif
  localparam int MAX_NEST = `SV_SERDE_MAX_NEST;

  protected string indent_str;        // String used for one level of indentation (e.g., "  " or "\t")
  protected int depth;                // Current nesting depth

  // Track if container has any content (for closing newline logic)
  // Stack-based to handle nesting correctly
  protected int has_content_stack[MAX_NEST];

  function new(io_writer w = null);
    super.new(w);
    indent_str = "  ";  // Default 2 spaces
    depth = 0;
    for (int i=0; i<MAX_NEST; i++) has_content_stack[i] = 0;
  endfunction

  // Fluent configuration: set indent string and enable pretty printing
  function json_pretty_formatter with_indent(string indent);
    this.indent_str = indent;
    return this;
  endfunction

  virtual function void reset();
    // Reset the writer
    string_writer s_wr;
    if ($cast(s_wr, wr)) begin
      s_wr.reset();
    end
    depth = 0;
    for (int i=0; i<MAX_NEST; i++) has_content_stack[i] = 0;
  endfunction

  // Helper: generate indentation string for specific depth level
  protected function string get_indent_at(int lvl);
    string s = "";
    for (int i = 0; i < lvl; i++) begin
      s = {s, indent_str};
    end
    return s;
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
    depth++;
    has_content_stack[depth] = 0;
  endfunction

  virtual function void end_array();
    // Add newline before closing bracket if array has content
    // Use depth-1 to get parent level indentation
    if (has_content_stack[depth]) begin
      wr.write_fmt("\n");
      wr.write_fmt(get_indent_at(depth - 1));
    end
    depth--;
    wr.write_fmt("]");
  endfunction

  virtual function void begin_array_value(bit is_first);
    // Pretty: add comma and newline + indent if not first
    if (!is_first) begin
      wr.write_fmt(",");
    end
    wr.write_fmt("\n");
    wr.write_fmt(get_indent_at(depth));
    has_content_stack[depth] = 1;
  endfunction

  virtual function void begin_object();
    wr.write_fmt("{");
    depth++;
    has_content_stack[depth] = 0;
  endfunction

  virtual function void end_object();
    // Add newline before closing bracket if object has content
    // Use depth-1 to get parent level indentation
    if (has_content_stack[depth]) begin
      wr.write_fmt("\n");
      wr.write_fmt(get_indent_at(depth - 1));
    end
    depth--;
    wr.write_fmt("}");
  endfunction

  virtual function void write_key(string key, bit is_first);
    // Pretty: add comma and newline + indent if not first
    if (!is_first) begin
      wr.write_fmt(",");
    end
    wr.write_fmt("\n");
    wr.write_fmt(get_indent_at(depth));

    wr.write_fmt("\"");
    wr.write_fmt(key);
    wr.write_fmt("\"");

    has_content_stack[depth] = 1;
  endfunction

  virtual function void write_key_value_separator();
    // Pretty: use ": " (colon + space)
    wr.write_fmt(": ");
  endfunction

  // Write value in object context - no comma needed
  virtual function void write_object_value();
    // Pretty: nothing extra to do
  endfunction

endclass

`endif
