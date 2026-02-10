// file_writer.svh - File-based writer with buffered output
// Uses 4KB buffer to minimize system calls

`ifndef SV_FILE_WRITER_SVH
`define SV_FILE_WRITER_SVH

`ifndef SV_IO_FILE_WRITER_BUF_SIZE
`define SV_IO_FILE_WRITER_BUF_SIZE 4096
`endif

class file_writer implements io_writer;
  localparam int BUF_SIZE = `SV_IO_FILE_WRITER_BUF_SIZE;

  protected int fd;                    // File descriptor
  protected byte buffer[BUF_SIZE];     // Output buffer
  protected int buf_idx;              // Current position in buffer

  function new(int file_desc);
    fd = file_desc;
    buf_idx = 0;
  endfunction

  // Write formatted string data
  virtual function void write_fmt(string data);
    for (int i = 0; i < data.len(); i++) begin
      write_byte(data[i]);
    end
  endfunction

  // Write single byte to buffer
  virtual function void write_byte(byte b);
    if (buf_idx >= BUF_SIZE) begin
      flush();
    end
    buffer[buf_idx] = b;
    buf_idx++;
  endfunction

  // Flush buffer to file
  virtual function void flush();
    if (buf_idx > 0) begin
      // Write buffer to file descriptor
      string buf_str;
      buf_str = "";
      for (int i = 0; i < buf_idx; i++) begin
        buf_str = {buf_str, string'(buffer[i])};
      end
      $fwrite(fd, "%s", buf_str);
      buf_idx = 0;
    end
  endfunction

  // Get result (empty for file writer)
  virtual function string get_result();
    return "";
  endfunction

  // Destructor - ensure buffer is flushed
  function void delete();
    flush();
  endfunction
endclass

`endif
