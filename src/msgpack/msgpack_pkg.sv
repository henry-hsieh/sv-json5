`ifndef MSGPACK_PKG_SV
`define MSGPACK_PKG_SV
package msgpack_pkg;
  import common_pkg::*;
  import serde_pkg::*;

  //====================================================================
  // Type Definitions
  //====================================================================
  typedef byte byte_array_t[];  // Dynamic array (matches Rust Vec<u8>)
  typedef byte byte_queue_t[$]; // Queue for internal buffering

  //====================================================================
  // Forward Declarations
  //====================================================================
  typedef class msgpack_serializer;
  typedef class msgpack_deserializer;
  typedef class msgpack_value;
  typedef class msgpack_int;
  typedef class msgpack_real;
  typedef class msgpack_string;
  typedef class msgpack_bool;
  typedef class msgpack_null;
  typedef class msgpack_array;
  typedef class msgpack_map;
  typedef class msgpack_value_builder;

  //====================================================================
  // MessagePack Value Types
  //====================================================================
  `include "types/msgpack_value.svh"
  `include "types/msgpack_int.svh"
  `include "types/msgpack_real.svh"
  `include "types/msgpack_string.svh"
  `include "types/msgpack_bool.svh"
  `include "types/msgpack_null.svh"
  `include "types/msgpack_array.svh"
  `include "types/msgpack_map.svh"

  //====================================================================
  // Serializers
  //====================================================================
  `include "ser/msgpack_serializer.svh"

  //====================================================================
  // Deserializers
  //====================================================================
  `include "de/msgpack_deserializer.svh"
  `include "de/msgpack_value_builder.svh"

  //====================================================================
  // MessagePack facade
  //====================================================================
  `include "serde_msgpack.svh"
endpackage
`endif
