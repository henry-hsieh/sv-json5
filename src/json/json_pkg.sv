`ifndef JSON_PKG_SV
`define JSON_PKG_SV
package json_pkg;
  import common_pkg::*;
  import serde_pkg::*;

  typedef string string_queue_t[$];
  typedef class json_value;
  typedef json_value json_value_queue_t[$];
  typedef enum { CTX_ROOT, CTX_ARRAY, CTX_OBJECT } context_t;

  // Forward declarations
  typedef class json_object;
  typedef class json_array;
  typedef class json_int;
  typedef class json_real;
  typedef class json_string;
  typedef class json_bool;
  typedef class json_null;
  typedef class json_value_builder;
  typedef class json_formatter;
  typedef class json_pretty_formatter;
  typedef class json_value_serializer;
  typedef class json_value_deserializer;
  typedef class json_value_frame;

  // Formatter abstractions (must be after forward declarations)
  `include "ser/json_formatter.svh"
  `include "ser/json_compact_formatter.svh"
  `include "ser/json_pretty_formatter.svh"

  // JSON value types
  `include "types/json_value.svh"
  `include "types/json_null.svh"
  `include "types/json_bool.svh"
  `include "types/json_string.svh"
  `include "types/json_int.svh"
  `include "types/json_real.svh"
  `include "types/json_array.svh"
  `include "types/json_object.svh"

  // Serializers
  `include "ser/json_serializer.svh"
  `include "ser/json_value_serializer.svh"

  // JSON parser
  `include "de/json_token.svh"
  `include "de/json_lexer.svh"
  `include "de/json_value_builder.svh"

  // Deserializers
  `include "de/json_deserializer.svh"
  `include "de/json_value_deserializer.svh"

  // JSON facade
  `include "serde_json.svh"
endpackage
`endif //JSON_PKG_SV
