// string_reader.svh - String-based implementation of io_reader
// Used for backward compatibility and small payloads

`ifndef SV_STRING_READER_SVH
`define SV_STRING_READER_SVH

class string_reader implements io_reader;
    string data;
    int pos;
    int len;

    function new(string s);
        this.data = s;
        this.pos = 0;
        this.len = s.len();
    endfunction

    virtual function byte peek();
        if (pos >= len) return 0;
        return data[pos];
    endfunction

    virtual function byte next();
        if (pos >= len) return 0;
        pos++;
        return data[pos - 1];
    endfunction

    virtual function void consume();
        if (pos < len) pos++;
    endfunction

    virtual function bit is_eof();
        return pos >= len;
    endfunction

    virtual function int get_pos();
        return pos;
    endfunction

    virtual function int get_len();
        return len;
    endfunction
endclass

`endif
