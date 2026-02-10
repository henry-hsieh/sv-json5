
`ifndef SV_JSON_DESERIALIZER_SVH
`define SV_JSON_DESERIALIZER_SVH

class json_deserializer extends serde_deserializer implements serde_seq_access, serde_map_access;
  protected json_lexer lexer;
  protected json_token peeked;
  protected bit has_peeked;

  typedef enum {
    CTX_ROOT,
    CTX_ARRAY_START,
    CTX_ARRAY_ITEM,
    CTX_OBJECT_START,
    CTX_OBJECT_KEY,
    CTX_OBJECT_VALUE
  } json_context_t;

  protected json_context_t stack[$];

  function new(json_lexer l);
    lexer = l;
    has_peeked = 0;
    stack.push_back(CTX_ROOT);
  endfunction

  // Public access methods for seq_access/map_access
  function json_token peek();
    if (!has_peeked) begin
      peeked = lexer.next_token();
      has_peeked = 1;
    end
    return peeked;
  endfunction

  function void consume();
    if (has_peeked) begin
      has_peeked = 0;
    end else begin
      void'(lexer.next_token());
    end
  endfunction

  // Legacy/Alias for backward compatibility
  protected function json_token _peek();
    return peek();
  endfunction

  protected function void _consume();
    consume();
  endfunction

  protected function Result#(bit) _expect(json_token_t t);
    json_token tok = peek();
    if (tok.get_type() != t) begin
      return Result#(bit)::Err($sformatf("Expected %s, got %s", t.name(), tok.get_type().name()));
    end
    consume();
    return Result#(bit)::Ok(1);
  endfunction

  protected function Result#(bit) handle_comma();
    json_context_t ctx = stack[stack.size()-1];
    case (ctx)
      CTX_ARRAY_ITEM, CTX_OBJECT_KEY: begin
        json_token tok = peek();
        if (tok.get_type() == TOKEN_COMMA) begin
          consume();
          return Result#(bit)::Ok(1);
        end else if (tok.get_type() == TOKEN_RBRACKET || tok.get_type() == TOKEN_RBRACE) begin
          return Result#(bit)::Ok(1);
        end else begin
          return Result#(bit)::Err("Expected ',' or end of collection");
        end
      end
      default: return Result#(bit)::Ok(1);
    endcase
  endfunction

  // Utility methods for parsing
  protected function bit is_integer(string s);
    for (int i = 0; i < s.len(); i++) begin
      byte c = s[i];
      if (c == "." || c == "e" || c == "E") return 0;
    end
    return 1;
  endfunction

  protected function longint parse_int_value(string s);
    longint result = 0;
    bit negative = 0;
    int i = 0;
    if (s.len() > 0 && s[0] == "-") begin
      negative = 1;
      i = 1;
    end
    for (; i < s.len(); i++) begin
      byte c = s[i];
      if (c >= "0" && c <= "9") begin
        result = result * 10 + (c - "0");
      end
    end
    return negative ? -result : result;
  endfunction

  protected function real parse_real_value(string s);
    real result;
    void'($sscanf(s, "%f", result));
    return result;
  endfunction

  virtual function Result#(bit) check_has_more();
    json_token tok = peek();
    json_context_t ctx = stack[stack.size()-1];
    bit more;

    if (ctx == CTX_ARRAY_START || ctx == CTX_ARRAY_ITEM) begin
      if (tok.get_type() == TOKEN_RBRACKET) begin
        // Consume the closing bracket and pop context
        consume();
        void'(stack.pop_back());
        return Result#(bit)::Ok(0);
      end else begin
        if (ctx == CTX_ARRAY_ITEM) begin
          Result#(bit) res = _expect(TOKEN_COMMA);
          if (res.is_err()) return res;
          tok = peek();
          if (tok.get_type() == TOKEN_RBRACKET) begin
             return Result#(bit)::Err("Trailing comma not allowed");
          end
        end
        stack[stack.size()-1] = CTX_ARRAY_ITEM;
      end
      return Result#(bit)::Ok(1);
    end

    if (ctx == CTX_OBJECT_START || ctx == CTX_OBJECT_KEY) begin
      if (tok.get_type() == TOKEN_RBRACE) begin
        // Consume the closing brace and pop context
        consume();
        void'(stack.pop_back());
        return Result#(bit)::Ok(0);
      end else begin
        if (ctx == CTX_OBJECT_KEY) begin
          Result#(bit) res = _expect(TOKEN_COMMA);
          if (res.is_err()) return res;
          tok = peek();
          if (tok.get_type() == TOKEN_RBRACE) begin
            return Result#(bit)::Err("Trailing comma not allowed");
          end
        end
        stack[stack.size()-1] = CTX_OBJECT_KEY;
      end
      return Result#(bit)::Ok(1);
    end

    return Result#(bit)::Err("check_has_more called in invalid context");
  endfunction

  // Implementation of serde_seq_access
  virtual function Result#(bit) has_next();
    return check_has_more();
  endfunction

  virtual function Result#(bit) next_element(serde_visitor visitor);
    return deserialize_any(visitor);
  endfunction

  // Implementation of serde_map_access
  virtual function Result#(bit) next_entry(serde_visitor visitor);
    Result#(string) key_res;
    string key;
    Result#(bit) res;
    json_token tok;

    // Get key
    key_res = deserialize_key();
    if (key_res.is_err()) return Result#(bit)::Err(key_res.unwrap_err());
    key = key_res.unwrap();

    res = visitor.visit_key(key);
    if (res.is_err()) return res;

    // Get value
    res = deserialize_any(visitor);
    return res;
  endfunction

  virtual function Result#(longint) deserialize_int();
    json_token tok = peek();
    longint val;
    if (tok.get_type() != TOKEN_NUMBER) return Result#(longint)::Err("Expected number");
    if (!is_integer(tok.get_value())) return Result#(longint)::Err("Expected integer, got real");
    val = parse_int_value(tok.get_value());
    consume();
    return Result#(longint)::Ok(val);
  endfunction

  virtual function Result#(longint unsigned) deserialize_uint();
    Result#(longint) res = deserialize_int();
    if (res.is_err()) return Result#(longint unsigned)::Err(res.unwrap_err());
    return Result#(longint unsigned)::Ok($unsigned(res.unwrap()));
  endfunction

  virtual function Result#(real) deserialize_real();
    json_token tok = peek();
    real val;
    if (tok.get_type() != TOKEN_NUMBER) return Result#(real)::Err("Expected number");
    val = parse_real_value(tok.get_value());
    consume();
    return Result#(real)::Ok(val);
  endfunction

  virtual function Result#(string) deserialize_string();
    json_token tok = peek();
    string val;
    if (tok.get_type() != TOKEN_STRING) return Result#(string)::Err("Expected string");
    val = tok.get_value();
    consume();
    return Result#(string)::Ok(val);
  endfunction

  virtual function Result#(bit) deserialize_bool();
    json_token tok = peek();
    bit val;
    if (tok.get_type() == TOKEN_TRUE) val = 1;
    else if (tok.get_type() == TOKEN_FALSE) val = 0;
    else return Result#(bit)::Err("Expected boolean");
    consume();
    return Result#(bit)::Ok(val);
  endfunction

  virtual function Result#(bit) deserialize_null();
    return _expect(TOKEN_NULL);
  endfunction

  virtual function Result#(bit) deserialize_sequence_start();
    Result#(bit) res = _expect(TOKEN_LBRACKET);
    if (res.is_err()) return res;
    stack.push_back(CTX_ARRAY_START);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(bit) deserialize_object_start();
    Result#(bit) res = _expect(TOKEN_LBRACE);
    if (res.is_err()) return res;
    stack.push_back(CTX_OBJECT_START);
    return Result#(bit)::Ok(1);
  endfunction

  virtual function Result#(string) deserialize_key();
    json_token tok = peek();
    string val;
    Result#(bit) res;
    if (tok.get_type() != TOKEN_STRING) return Result#(string)::Err("Expected string key");
    val = tok.get_value();
    consume();
    res = _expect(TOKEN_COLON);
    if (res.is_err()) return Result#(string)::Err(res.unwrap_err());
    return Result#(string)::Ok(val);
  endfunction

  virtual function Result#(bit) deserialize_any(serde_visitor visitor);
    json_token tok = peek();
    Result#(string) str_res;
    Result#(longint) int_res;
    Result#(real) real_res;
    Result#(serde_seq_access) seq_res;
    Result#(serde_map_access) map_res;

    case (tok.get_type())
      TOKEN_LBRACE: begin
        map_res = deserialize_map();
        if (map_res.is_err()) return Result#(bit)::Err(map_res.unwrap_err());
        return visitor.visit_map(map_res.unwrap());
      end
      TOKEN_LBRACKET: begin
        seq_res = deserialize_seq();
        if (seq_res.is_err()) return Result#(bit)::Err(seq_res.unwrap_err());
        return visitor.visit_seq(seq_res.unwrap());
      end
      TOKEN_STRING:   begin
        str_res = deserialize_string();
        if (str_res.is_err()) return Result#(bit)::Err(str_res.unwrap_err());
        return visitor.visit_string(str_res.unwrap());
      end
      TOKEN_NUMBER:   begin
        if (is_integer(tok.get_value())) begin
          int_res = deserialize_int();
          if (int_res.is_err()) return Result#(bit)::Err(int_res.unwrap_err());
          return visitor.visit_int(int_res.unwrap());
        end else begin
          real_res = deserialize_real();
          if (real_res.is_err()) return Result#(bit)::Err(real_res.unwrap_err());
          return visitor.visit_real(real_res.unwrap());
        end
      end
      TOKEN_TRUE:     begin consume(); return visitor.visit_bool(1); end
      TOKEN_FALSE:    begin consume(); return visitor.visit_bool(0); end
      TOKEN_NULL:     begin consume(); return visitor.visit_null(); end
      default:        return Result#(bit)::Err($sformatf("Unexpected token for deserialize_any: %s", tok.get_type().name()));
    endcase
  endfunction

  // Implementation of pull-based deserialization methods
  virtual function Result#(serde_seq_access) deserialize_seq();
    Result#(bit) res = deserialize_sequence_start();
    if (res.is_err()) return Result#(serde_seq_access)::Err(res.unwrap_err());
    return Result#(serde_seq_access)::Ok(this);
  endfunction

  virtual function Result#(serde_map_access) deserialize_map();
    Result#(bit) res = deserialize_object_start();
    if (res.is_err()) return Result#(serde_map_access)::Err(res.unwrap_err());
    return Result#(serde_map_access)::Ok(this);
  endfunction

  // Static factory - from string
  static function json_deserializer from_string(string s);
    string_reader r = new(s);
    json_lexer l = new(r);
    json_deserializer d = new(l);
    return d;
  endfunction

  // Static factory - from reader (for streaming)
  static function json_deserializer from_reader(io_reader r);
    json_lexer l = new(r);
    json_deserializer d = new(l);
    return d;
  endfunction

endclass
`endif
