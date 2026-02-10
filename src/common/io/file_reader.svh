// file_reader.svh - File-based implementation of io_reader
// Uses a 4KB buffer for efficient I/O

`ifndef SV_FILE_READER_SVH
`define SV_FILE_READER_SVH

`ifndef SV_IO_FILE_READER_BUF_SIZE
`define SV_IO_FILE_READER_BUF_SIZE 4096
`endif

class file_reader implements io_reader;
    // Buffer size - using localparam for SystemVerilog compatibility
    localparam int BUF_SIZE = `SV_IO_FILE_READER_BUF_SIZE;

    int fd;
    byte buffer[BUF_SIZE];
    int buf_pos;      // Current position within buffer
    int buf_len;      // Valid bytes in buffer
    int total_pos;    // Total bytes consumed from file start

    function new(int file_fd);
        this.fd = file_fd;
        this.buf_pos = 0;
        this.buf_len = 0;
        this.total_pos = 0;
        // Initial fill
        refill();
    endfunction

    // Refill buffer from file
    function void refill();
        // Read up to BUF_SIZE bytes
        buf_len = $fread(buffer, fd);
        buf_pos = 0;
        // If we read less than BUF_SIZE, we've hit EOF
        // If 0, file is empty or at EOF
    endfunction

    virtual function byte peek();
        if (buf_pos >= buf_len) begin
            // Buffer empty, try to refill
            refill();
            if (buf_pos >= buf_len) return 0;  // Still empty = EOF
        end
        return buffer[buf_pos];
    endfunction

    virtual function byte next();
        byte b;
        if (buf_pos >= buf_len) begin
            refill();
            if (buf_pos >= buf_len) return 0;
        end
        b = buffer[buf_pos];
        buf_pos++;
        total_pos++;
        return b;
    endfunction

    virtual function void consume();
        if (buf_pos >= buf_len) begin
            refill();
            if (buf_pos >= buf_len) return;
        end
        buf_pos++;
        total_pos++;
    endfunction

    virtual function bit is_eof();
        // Try to refill if buffer is empty
        if (buf_pos >= buf_len) begin
            refill();
        end
        return buf_pos >= buf_len;
    endfunction

    virtual function int get_pos();
        return total_pos;
    endfunction

    virtual function int get_len();
        // Cannot determine file length without seeking
        // Return -1 to indicate unknown
        return -1;
    endfunction
endclass

`endif
