`ifndef SERDE_PKG_SV
`define SERDE_PKG_SV
package serde_pkg;
  import common_pkg::*;

  typedef interface class serde_seq_access;
  typedef interface class serde_map_access;
  typedef class serde_deserializer;

  `include "ser/serializer.svh"
  `include "ser/serialize.svh"
  `include "de/visitor.svh"
  `include "de/deserializer.svh"
  `include "de/deserialize.svh"
  `include "de/seq_access.svh"
  `include "de/map_access.svh"
endpackage
`endif //SERDE_PKG_SV
