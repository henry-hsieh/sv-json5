`ifndef COMMON_PKG_SV
`define COMMON_PKG_SV
package common_pkg;
  typedef class Result;
  typedef class Option;

  // Common utilities
  `include "result.svh"
  `include "option.svh"

  // I/O abstractions
  `include "io/reader.svh"
  `include "io/writer.svh"
  `include "io/string_reader.svh"
  `include "io/file_reader.svh"
  `include "io/string_writer.svh"
  `include "io/file_writer.svh"
  `include "io/queue_writer.svh"
  `include "io/queue_reader.svh"
endpackage
`endif //COMMON_PKG_SV
