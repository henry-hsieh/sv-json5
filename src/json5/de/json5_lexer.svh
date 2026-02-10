`ifndef SV_JSON5_LEXER_SVH
`define SV_JSON5_LEXER_SVH

// json5_lexer.svh - JSON5 Lexer with streaming reader support
class json5_lexer extends json_lexer;

  function new(io_reader r);
    super.new(r);
  endfunction

  // Override skip_ws to handle comments
  virtual function void skip_ws;
    byte c;
    while (!reader.is_eof()) begin
      c = reader.peek();
      if (c == " " || c == "\t" || c == "\n" || c == "\x0d") begin
        reader.next();
      end else if (c == "/") begin
        // Check if it's a comment
        reader.next(); // consume '/'
        if (!reader.is_eof()) begin
          byte nc = reader.peek();
          if (nc == "/") begin
            // Single-line comment: consume rest of line
            reader.next();
            while (!reader.is_eof()) begin
              c = reader.peek();
              if (c == "\n") break;
              reader.next();
            end
          end else if (nc == "*") begin
            // Multi-line comment
            reader.next(); // consume '*'
            while (!reader.is_eof()) begin
              c = reader.peek();
              if (c == "*") begin
                reader.next(); // consume '*'
                if (!reader.is_eof() && reader.peek() == "/") begin
                  reader.next(); // consume '/'
                  break;
                end
              end else begin
                reader.next();
              end
            end
            // Continue to skip more whitespace after comment
          end else begin
            // Not a comment, put back the '/' by not consuming it
            // Actually, we consumed it already... this is invalid JSON5
            // Just break and let next_token handle the error
            break;
          end
        end else begin
          break;
        end
      end else begin
        break;
      end
    end
  endfunction

  // Parse number with a prefix (for cases where we already consumed some chars during lookahead)
  // This handles the JSON5 ambiguity where we need to check ahead to determine token type
  protected function json_token parse_number_with_prefix(string prefix);
    json_token tok = new();
    string res = prefix;
    byte c;
    bit seen_dot = 0;
    bit seen_exp = 0;
    tok.set_line(line_num);
    tok.set_column(col_num);

    // Determine initial state based on prefix
    if (prefix == ".") seen_dot = 1;
    else if (prefix == "+" || prefix == "-") seen_dot = 0;
    else if (prefix.len() > 0) begin
      // Check if prefix contains dot
      for (int i = 0; i < prefix.len(); i++) begin
        if (prefix[i] == ".") seen_dot = 1;
      end
    end

    // 1. Digits before decimal (if we haven't seen a dot yet)
    if (!seen_dot) begin
      while (!reader.is_eof()) begin
        c = reader.peek();
        if (c >= "0" && c <= "9") begin
          res = {res, c};
          reader.next();
        end else begin
          break;
        end
      end
    end

    // 2. Decimal point (if we haven't seen one yet)
    if (!seen_dot && !reader.is_eof() && reader.peek() == ".") begin
      res = {res, "."};
      reader.next();
      seen_dot = 1;
    end

    // 3. Digits after decimal (if we have seen a dot, either in prefix or just now)
    if (seen_dot) begin
      while (!reader.is_eof()) begin
        c = reader.peek();
        if (c >= "0" && c <= "9") begin
          res = {res, c};
          reader.next();
        end else begin
          break;
        end
      end
    end

    // Scientific notation
    if (!reader.is_eof()) begin
      c = reader.peek();
      if (c == "e" || c == "E") begin
        res = {res, c};
        reader.next();
        seen_exp = 1;
        if (!reader.is_eof()) begin
          c = reader.peek();
          if (c == "+" || c == "-") begin
            res = {res, c};
            reader.next();
          end
        end
        while (!reader.is_eof()) begin
          c = reader.peek();
          if (c >= "0" && c <= "9") begin
            res = {res, c};
            reader.next();
          end else begin
            break;
          end
        end
      end
    end

    tok.set_type(TOKEN_NUMBER);
    tok.set_value(res);
    return tok;
  endfunction

  // Override next_token to handle identifiers and single quote
  virtual function json_token next_token;
    byte c;
    skip_ws();

    if (reader.is_eof()) return super.next_token();

    c = reader.peek();

    // Single quote support
    if (c == "'") return read_str_single();

    // Identifier start chars: A-Z, a-z, underscore, dollar sign (for unquoted keys)
    if ((c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_" || c == "$") begin
      return read_identifier();
    end

    // Hex and leading dot support
    if (c == "0") begin
      reader.next(); // consume '0' to check next char
      if (!reader.is_eof()) begin
        byte nc = reader.peek();
        if (nc == "x" || nc == "X") begin
          // Hex number: 0x...
          return read_hex();
        end else begin
          // Not hex - could be 0.5, 0e10, or just 0
          // We already consumed '0', pass it as prefix
          return parse_number_with_prefix("0");
        end
      end
      // EOF after 0, just return 0
      begin
        json_token tok = new();
        tok.set_line(line_num);
        tok.set_column(col_num);
        tok.set_type(TOKEN_NUMBER);
        tok.set_value("0");
        return tok;
      end
    end

    // Check for leading dot: .5
    if (c == ".") begin
      reader.next(); // consume '.' to check next char
      if (!reader.is_eof()) begin
        byte nc = reader.peek();
        if (nc >= "0" && nc <= "9") begin
          // It's .5 - we already consumed '.'
          return parse_number_with_prefix(".");
        end
      end
      // Not a number (e.g., just "."), put back by calling super with '.'
      // Actually we consumed it. Let super handle the error
      begin
        json_token tok = new();
        tok.set_line(line_num);
        tok.set_column(col_num);
        tok.set_type(TOKEN_ERROR);
        tok.set_value("Unexpected dot");
        return tok;
      end
    end

    if (c == "+") begin
      reader.next(); // consume '+'
      return parse_number_with_prefix("+");
    end

    // Regular digits: use overridden read_num to handle trailing dot
    if (c >= "0" && c <= "9") begin
      return read_num();
    end

    return super.next_token();
  endfunction

  // Single-quoted string reader
  protected function json_token read_str_single;
    json_token tok = new();
    string res = "";
    byte c;
    tok.set_line(line_num);
    tok.set_column(col_num);

    c = reader.next(); // skip opening quote (should be ')
    if (c != "'") begin
      // Put back if not quote
    end

    while (!reader.is_eof()) begin
      c = reader.next();
      if (c == "'") begin
        tok.set_type(TOKEN_STRING);
        tok.set_value(res);
        return tok;
      end else if (c == "\\") begin
        if (!reader.is_eof()) begin
          byte nc = reader.next();
          case (nc)
            34: res = {res, "\""};
            39: res = {res, "'"};
            92: res = {res, "\\"};
            47: res = {res, "/"};
            98: res = {res, "\x08"};
            102: res = {res, "\x0C"};
            110: res = {res, "\x0A"};
            114: res = {res, "\x0D"};
            116: res = {res, "\x09"};
            default: begin
              tok.set_type(TOKEN_ERROR);
              tok.set_value("Bad escape");
              return tok;
            end
          endcase
        end
      end else begin
        res = {res, c};
      end
    end
    tok.set_type(TOKEN_ERROR);
    tok.set_value("Unterminated string");
    return tok;
  endfunction

  // Identifier reader for unquoted keys
  protected function json_token read_identifier;
    json_token tok = new();
    string res = "";
    byte c;
    tok.set_line(line_num);
    tok.set_column(col_num);

    while (!reader.is_eof()) begin
      c = reader.peek();
      if ((c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9") || c == "_" || c == "$") begin
        res = {res, c};
        reader.next();
      end else begin
        break;
      end
    end

    // Check for keywords
    if (res == "true") tok.set_type(TOKEN_TRUE);
    else if (res == "false") tok.set_type(TOKEN_FALSE);
    else if (res == "null") tok.set_type(TOKEN_NULL);
    else tok.set_type(TOKEN_STRING); // Treat other identifiers as strings (keys)

    tok.set_value(res);
    return tok;
  endfunction

  // Hex number reader: reads 0x... after '0' has been consumed and we've peeked 'x'
  protected function json_token read_hex;
    json_token tok = new();
    string res = "0";
    byte c;
    tok.set_line(line_num);
    tok.set_column(col_num);

    // Consume 'x' or 'X'
    if (!reader.is_eof()) begin
      c = reader.peek();
      if (c == "x" || c == "X") begin
        res = {res, c};
        reader.next();
      end
    end

    // Read hex digits
    while (!reader.is_eof()) begin
      c = reader.peek();
      if ((c >= "0" && c <= "9") || (c >= "a" && c <= "f") || (c >= "A" && c <= "F")) begin
        res = {res, c};
        reader.next();
      end else begin
        break;
      end
    end

    tok.set_type(TOKEN_NUMBER);
    tok.set_value(res);
    return tok;
  endfunction

  // Override read_num for leading/trailing dots and explicit plus
  virtual function json_token read_num;
    json_token tok = new();
    string res = "";
    byte c;
    tok.set_line(line_num);
    tok.set_column(col_num);

    // Check for optional sign
    if (!reader.is_eof()) begin
      c = reader.peek();
      if (c == "-" || c == "+") begin
        res = {res, c};
        reader.next();
      end
    end

    // Digits before decimal
    while (!reader.is_eof()) begin
      c = reader.peek();
      if (c >= "0" && c <= "9") begin
        res = {res, c};
        reader.next();
      end else begin
        break;
      end
    end

    // Decimal point
    if (!reader.is_eof() && reader.peek() == ".") begin
      res = {res, "."};
      reader.next();
      // Digits after decimal
      while (!reader.is_eof()) begin
        c = reader.peek();
        if (c >= "0" && c <= "9") begin
          res = {res, c};
          reader.next();
        end else begin
          break;
        end
      end
    end

    // Scientific notation
    if (!reader.is_eof()) begin
      c = reader.peek();
      if (c == "e" || c == "E") begin
        res = {res, c};
        reader.next();
        if (!reader.is_eof()) begin
          c = reader.peek();
          if (c == "+" || c == "-") begin
            res = {res, c};
            reader.next();
          end
        end
        while (!reader.is_eof()) begin
          c = reader.peek();
          if (c >= "0" && c <= "9") begin
            res = {res, c};
            reader.next();
          end else begin
            break;
          end
        end
      end
    end

    tok.set_type(TOKEN_NUMBER);
    tok.set_value(res);
    return tok;
  endfunction

endclass
`endif
