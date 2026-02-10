// io_reader.svh - Interface for streaming input
// Abstracts the source of characters (string, file, etc.)

`ifndef SV_IO_READER_SVH
`define SV_IO_READER_SVH

interface class io_reader;
    // Peek at the next character without consuming it
    // Returns 0 if at EOF
    pure virtual function byte peek();

    // Consume and return the next character
    // Returns 0 if at EOF
    pure virtual function byte next();

    // Consume the next character without returning it
    pure virtual function void consume();

    // Check if end of stream has been reached
    pure virtual function bit is_eof();

    // Get current position (for error reporting)
    pure virtual function int get_pos();

    // Get the total length (if known, -1 if streaming from fd)
    pure virtual function int get_len();
endclass

`endif
