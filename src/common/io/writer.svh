// io_writer.svh - Interface for streaming output
// Implement this trait to support writing to different destinations (string, file, etc.)

`ifndef SV_IO_WRITER_SVH
`define SV_IO_WRITER_SVH

interface class io_writer;
  // Write formatted string data
  pure virtual function void write_fmt(string data);

  // Write single byte (for buffered output)
  pure virtual function void write_byte(byte b);

  // Flush any buffered data to underlying destination
  pure virtual function void flush();

  // Get accumulated result (for string_writer)
  // Returns empty string for file-based writers
  pure virtual function string get_result();
endclass

`endif
