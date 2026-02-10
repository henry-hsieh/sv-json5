`ifndef SV_JSON5_DESERIALIZER_SVH
`define SV_JSON5_DESERIALIZER_SVH

// json5_deserializer.svh - JSON5 deserializer extending json_deserializer
// Supports: trailing commas, hex numbers, extended number formats

class json5_deserializer extends json_deserializer;

  function new(json5_lexer l);
    super.new(l);
  endfunction

  // Explicitly override to ensure pull-based methods are used
  virtual function Result#(serde_map_access) deserialize_map();
    return super.deserialize_map();
  endfunction

  virtual function Result#(serde_seq_access) deserialize_seq();
    return super.deserialize_seq();
  endfunction

  // Static factory methods for JSON5
  static function Result#(json_value) from_string(string json_str);
    string_reader r;
    json5_lexer lexer;
    json5_deserializer deser;
    json_value_builder builder;
    Result#(bit) res;

    r = new(json_str);
    lexer = new(r);
    deser = new(lexer);
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) return Result#(json_value)::Err(res.unwrap_err());
    return builder.get_result();
  endfunction

  static function Result#(json_value) from_file(string path);
    int fd;
    string content;
    string line;

    fd = $fopen(path, "r");
    if (fd == 0) begin
      return Result#(json_value)::Err($sformatf("Cannot open file: %s", path));
    end

    content = "";
    while (!$feof(fd)) begin
      if ($fgets(line, fd) != 0) begin
        content = {content, line};
      end
    end
    $fclose(fd);

    return from_string(content);
  endfunction

  // Streaming: deserialize from any io_reader (file_reader, string_reader)
  static function Result#(json_value) from_reader(io_reader r);
    json5_lexer lexer;
    json5_deserializer deser;
    json_value_builder builder;
    Result#(bit) res;

    lexer = new(r);
    deser = new(lexer);
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) return Result#(json_value)::Err(res.unwrap_err());
    return builder.get_result();
  endfunction

  // Override check_has_more to allow trailing commas in JSON5
  // This handles: [1, 2,] and {a: 1,}
  virtual function Result#(bit) check_has_more();
    json_token tok = peek();
    json_context_t ctx = stack[stack.size()-1];
    bit more;

    if (ctx == CTX_ARRAY_START || ctx == CTX_ARRAY_ITEM) begin
      if (tok.get_type() == TOKEN_RBRACKET) begin
        // Consume the closing bracket and pop context (pull model)
        consume();
        void'(stack.pop_back());
        return Result#(bit)::Ok(0);
      end else begin
        if (ctx == CTX_ARRAY_ITEM) begin
          // Check for trailing comma: ,] should be allowed
          if (tok.get_type() == TOKEN_COMMA) begin
            consume();
            tok = peek();
            // After comma, if we see ], it's a trailing comma (OK in JSON5)
            if (tok.get_type() == TOKEN_RBRACKET) begin
              // Consume the closing bracket and pop context (pull model)
              consume();
              void'(stack.pop_back());
              return Result#(bit)::Ok(0);
            end
            // Otherwise, continue parsing
            stack[stack.size()-1] = CTX_ARRAY_ITEM;
            return Result#(bit)::Ok(1);
          end
        end
        stack[stack.size()-1] = CTX_ARRAY_ITEM;
      end
      return Result#(bit)::Ok(1);
    end

    if (ctx == CTX_OBJECT_START || ctx == CTX_OBJECT_KEY) begin
      if (tok.get_type() == TOKEN_RBRACE) begin
        // Consume the closing brace and pop context (pull model)
        consume();
        void'(stack.pop_back());
        return Result#(bit)::Ok(0);
      end else begin
        if (ctx == CTX_OBJECT_KEY) begin
          // Check for trailing comma: ,} should be allowed
          if (tok.get_type() == TOKEN_COMMA) begin
            consume();
            tok = peek();
            // After comma, if we see }, it's a trailing comma (OK in JSON5)
            if (tok.get_type() == TOKEN_RBRACE) begin
              // Consume the closing brace and pop context (pull model)
              consume();
              void'(stack.pop_back());
              return Result#(bit)::Ok(0);
            end
            // Otherwise, continue parsing
            stack[stack.size()-1] = CTX_OBJECT_KEY;
            return Result#(bit)::Ok(1);
          end
        end
        stack[stack.size()-1] = CTX_OBJECT_KEY;
      end
      return Result#(bit)::Ok(1);
    end

    return Result#(bit)::Err("check_has_more called in invalid context");
  endfunction

  // Override deserialize_int to handle hex numbers
  virtual function Result#(longint) deserialize_int();
    json_token tok = peek();
    longint val;
    string s;
    if (tok.get_type() != TOKEN_NUMBER) return Result#(longint)::Err("Expected number");

    s = tok.get_value();

    // Handle hex numbers: 0xFF
    if (s.len() >= 2 && (s[0] == "0" && (s[1] == "x" || s[1] == "X"))) begin
      val = parse_hex_value(s);
      consume();
      return Result#(longint)::Ok(val);
    end

    // Handle explicit plus: +100
    if (s.len() >= 1 && s[0] == "+") begin
      s = s.substr(1, s.len() - 1);
    end

    if (!is_integer(s)) return Result#(longint)::Err("Expected integer, got real");
    val = parse_int_value(s);
    consume();
    return Result#(longint)::Ok(val);
  endfunction

  // Override deserialize_real to handle hex and special floats
  virtual function Result#(real) deserialize_real();
    json_token tok = peek();
    real val;
    string s;
    if (tok.get_type() != TOKEN_NUMBER) return Result#(real)::Err("Expected number");

    s = tok.get_value();

    // Handle hex numbers as integers in real context
    if (s.len() >= 2 && (s[0] == "0" && (s[1] == "x" || s[1] == "X"))) begin
      val = $itor(parse_hex_value(s));
      consume();
      return Result#(real)::Ok(val);
    end

    // Handle explicit plus: +100.5
    if (s.len() >= 1 && s[0] == "+") begin
      s = s.substr(1, s.len() - 1);
    end

    // Handle leading decimal: .5
    if (s.len() >= 1 && s[0] == ".") begin
      s = {"0", s};
    end

    // Handle trailing decimal: 5.
    if (s.len() >= 1 && s[s.len()-1] == ".") begin
      s = {s, "0"};
    end

    val = parse_real_value(s);
    consume();
    return Result#(real)::Ok(val);
  endfunction

  // Helper to parse hex string to longint
  protected function longint parse_hex_value(string s);
    longint result = 0;
    for (int i = 2; i < s.len(); i++) begin
      byte c = s[i];
      int val = 0;
      if (c >= "0" && c <= "9") val = c - "0";
      else if (c >= "a" && c <= "f") val = c - "a" + 10;
      else if (c >= "A" && c <= "F") val = c - "A" + 10;
      result = result * 16 + val;
    end
    return result;
  endfunction

endclass
`endif
