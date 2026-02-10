// json_lexer.svh - JSON tokenizer using streaming reader
`ifndef SV_JSON_LEXER_SVH
`define SV_JSON_LEXER_SVH

class json_lexer;
    protected io_reader reader;
    protected int line_num;
    protected int col_num;
    protected byte last_char;

    function new(io_reader r);
        reader = r;
        line_num = 1;
        col_num = 1;
        last_char = 0;
    endfunction

    function int get_pos;
        return reader.get_pos();
    endfunction

    function int get_line;
        return line_num;
    endfunction

    function int get_column;
        return col_num;
    endfunction

    virtual function json_token next_token;
        json_token tok;
        byte c;

        tok = new();
        skip_ws();

        if (reader.is_eof()) begin
            tok.set_type(TOKEN_EOF);
            tok.set_value("");
            return tok;
        end

        c = reader.peek();
        tok.set_line(line_num);
        tok.set_column(col_num);

        case (c)
            "{": begin tok.set_type(TOKEN_LBRACE); tok.set_value("{"); advance(); end
            "}": begin tok.set_type(TOKEN_RBRACE); tok.set_value("}"); advance(); end
            "[": begin tok.set_type(TOKEN_LBRACKET); tok.set_value("["); advance(); end
            "]": begin tok.set_type(TOKEN_RBRACKET); tok.set_value("]"); advance(); end
            ",": begin tok.set_type(TOKEN_COMMA); tok.set_value(","); advance(); end
            ":": begin tok.set_type(TOKEN_COLON); tok.set_value(":"); advance(); end
            34: tok = read_str();  // double quote
            45, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: tok = read_num();  // - and digits
            116: tok = read_kw("true", TOKEN_TRUE);
            102: tok = read_kw("false", TOKEN_FALSE);
            110: tok = read_kw("null", TOKEN_NULL);
            default: begin
                tok.set_type(TOKEN_ERROR);
                tok.set_value("Unexpected char");
                advance();
            end
        endcase

        return tok;
    endfunction

    // Peek at next token without consuming it
    // Useful for checking what's coming next in deserialization
    virtual function json_token peek;
        json_token tok;
        int saved_line;
        int saved_col;
        byte saved_last;

        // Save lexer state
        saved_line = line_num;
        saved_col = col_num;
        saved_last = last_char;
        // Note: reader doesn't have a save/restore, but peek() implementation
        // in subclasses might need to handle this. For now we rely on the
        // fact that peek doesn't advance.

        // Get next token
        tok = next_token();

        // Restore lexer state
        line_num = saved_line;
        col_num = saved_col;
        last_char = saved_last;

        return tok;
    endfunction

    protected function void advance;
        if (!reader.is_eof()) begin
            last_char = reader.next();
            if (last_char == "\n") begin
                line_num = line_num + 1;
                col_num = 1;
            end else begin
                col_num = col_num + 1;
            end
        end
    endfunction

    virtual protected function void skip_ws;
        byte c;
        while (!reader.is_eof()) begin
            c = reader.peek();
            if (c == " " || c == "\t" || c == "\n" || c == "\x0d") begin
                advance();
            end else begin
                break;
            end
        end
    endfunction

    virtual protected function json_token read_str;
        json_token tok;
        string res;
        byte c;
        byte nc;

        tok = new();
        tok.set_line(line_num);
        tok.set_column(col_num);
        res = "";

        advance();  // skip opening quote

        while (!reader.is_eof()) begin
            c = reader.next();

            if (c == 34) begin  // closing quote
                tok.set_type(TOKEN_STRING);
                tok.set_value(res);
                return tok;
            end else if (c == 92) begin  // backslash
                if (reader.is_eof()) begin
                    tok.set_type(TOKEN_ERROR);
                    tok.set_value("Unterminated escape");
                    return tok;
                end
                nc = reader.next();
                case (nc)
                    34: res = {res, "\""};
                    92: res = {res, "\\"};
                    47: res = {res, "/"};
                    98: res = {res, "\x08"};
                    102: res = {res, "\x0C"};
                    110: res = {res, "\x0A"};
                    114: res = {res, "\x0D"};
                    116: res = {res, "\x09"};
                    117: begin  // \uXXXX - unicode escape
                        // Read 4 hex digits sequentially
                        string hex_str;
                        int hex_val;
                        byte hc;
                        hex_str = "";
                        hex_val = 0;
                        for (int hi = 0; hi < 4; hi++) begin
                            if (reader.is_eof()) begin
                                tok.set_type(TOKEN_ERROR);
                                tok.set_value("Incomplete unicode escape");
                                return tok;
                            end
                            hc = reader.next();
                            if ((hc >= 48 && hc <= 57) || (hc >= 65 && hc <= 70) || (hc >= 97 && hc <= 102)) begin
                                // Valid hex char
                                hex_str = {hex_str, string'(hc)};
                                // Accumulate value
                                hex_val = hex_val * 16;
                                if (hc >= 48 && hc <= 57) hex_val = hex_val + (hc - 48);
                                else if (hc >= 65 && hc <= 70) hex_val = hex_val + (hc - 55);
                                else if (hc >= 97 && hc <= 102) hex_val = hex_val + (hc - 87);
                            end else begin
                                tok.set_type(TOKEN_ERROR);
                                tok.set_value("Invalid hex in unicode escape");
                                return tok;
                            end
                        end
                        // Convert to byte (just use lower 8 bits for now)
                        res = {res, string'(byte'(hex_val))};
                    end
                    default: begin
                        tok.set_type(TOKEN_ERROR);
                        tok.set_value("Bad escape");
                        return tok;
                    end
                endcase
            end else if (c < 32) begin
                tok.set_type(TOKEN_ERROR);
                tok.set_value("Control char");
                return tok;
            end else begin
                res = {res, c};
            end
        end

        tok.set_type(TOKEN_ERROR);
        tok.set_value("Unterminated string");
        return tok;
    endfunction

    virtual protected function json_token read_num;
        json_token tok;
        string res;
        byte c;

        tok = new();
        tok.set_line(line_num);
        tok.set_column(col_num);
        res = "";

        c = reader.peek();
        if (c == 45) begin  // minus
            res = {res, string'(c)};
            advance();
        end

        while (!reader.is_eof()) begin
            c = reader.peek();
            if (c >= 48 && c <= 57) begin
                res = {res, string'(c)};
                advance();
            end else begin
                break;
            end
        end

        if (!reader.is_eof()) begin
            c = reader.peek();
            if (c == 46) begin  // dot
                res = {res, "."};
                advance();
                while (!reader.is_eof()) begin
                    c = reader.peek();
                    if (c >= 48 && c <= 57) begin
                        res = {res, string'(c)};
                        advance();
                    end else begin
                        break;
                    end
                end
            end
        end

        if (!reader.is_eof()) begin
            c = reader.peek();
            if (c == 101 || c == 69) begin  // e or E
                res = {res, string'(c)};
                advance();
                if (!reader.is_eof()) begin
                    c = reader.peek();
                    if (c == 43 || c == 45) begin  // + or -
                        res = {res, string'(c)};
                        advance();
                    end
                end
                while (!reader.is_eof()) begin
                    c = reader.peek();
                    if (c >= 48 && c <= 57) begin
                        res = {res, string'(c)};
                        advance();
                    end else begin
                        break;
                    end
                end
            end
        end

        tok.set_type(TOKEN_NUMBER);
        tok.set_value(res);
        tok.set_num_val(0);  // Deserializer will parse from string
        return tok;
    endfunction

    virtual protected function json_token read_kw(string kw, json_token_t tt);
        json_token tok;
        int i;
        byte nc;

        tok = new();
        tok.set_line(line_num);
        tok.set_column(col_num);

        // Check keyword sequentially
        for (i = 0; i < kw.len(); i = i + 1) begin
            if (reader.is_eof()) begin
                tok.set_type(TOKEN_ERROR);
                tok.set_value("Bad identifier");
                return tok;
            end
            nc = reader.next();
            if (nc != kw[i]) begin
                tok.set_type(TOKEN_ERROR);
                tok.set_value("Bad identifier");
                return tok;
            end
        end

        // Check that next char is not part of identifier
        if (!reader.is_eof()) begin
            nc = reader.peek();
            if ((nc >= 97 && nc <= 122) || (nc >= 65 && nc <= 90) || nc == 95 || (nc >= 48 && nc <= 57)) begin
                tok.set_type(TOKEN_ERROR);
                tok.set_value("Bad identifier");
                return tok;
            end
        end

        tok.set_type(tt);
        tok.set_value(kw);
        return tok;
    endfunction
endclass
`endif
