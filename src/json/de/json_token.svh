// Token types for JSON lexer
`ifndef SV_JSON_TOKEN_SVH
`define SV_JSON_TOKEN_SVH

typedef enum {
  TOKEN_LBRACE,    // {
  TOKEN_RBRACE,    // }
  TOKEN_LBRACKET,  // [
  TOKEN_RBRACKET,  // ]
  TOKEN_COMMA,     // ,
  TOKEN_COLON,     // :
  TOKEN_STRING,    // "..."
  TOKEN_NUMBER,    // 123, -45.67, etc.
  TOKEN_TRUE,      // true
  TOKEN_FALSE,     // false
  TOKEN_NULL,      // null
  TOKEN_EOF,       // End of input
  TOKEN_ERROR      // Lexical error
} json_token_t;

// Token class
class json_token;
  json_token_t tok_type;
  string tok_value;
  longint num_val;
  int tok_line;
  int tok_column;

  function new();
    tok_type = TOKEN_EOF;
    tok_value = "";
    num_val = 0;
    tok_line = 1;
    tok_column = 1;
  endfunction

  function json_token_t get_type();
    return tok_type;
  endfunction

  function void set_type(json_token_t t);
    tok_type = t;
  endfunction

  function string get_value();
    return tok_value;
  endfunction

  function void set_value(string v);
    tok_value = v;
  endfunction

  function int get_line();
    return tok_line;
  endfunction

  function void set_line(int l);
    tok_line = l;
  endfunction

  function int get_column();
    return tok_column;
  endfunction

  function void set_column(int c);
    tok_column = c;
  endfunction

  function bit is_eof();
    return tok_type == TOKEN_EOF;
  endfunction

  function bit is_error();
    return tok_type == TOKEN_ERROR;
  endfunction

  function longint get_num_val();
    return num_val;
  endfunction

  function void set_num_val(longint v);
    num_val = v;
  endfunction
endclass
`endif
