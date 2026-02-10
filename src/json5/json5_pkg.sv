package json5_pkg;
  import common_pkg::*;
  import serde_pkg::*;
  import json_pkg::*;

  // JSON5 extension
  `include "de/json5_lexer.svh"
  `include "de/json5_deserializer.svh"

  // JSON5 facade
  `include "serde_json5.svh"

endpackage
