// serde_json.svh - JSON serialization facade (matches serde_json crate API)
// Provides to_string(), to_string_pretty(), from_str(), from_reader(), to_writer() static methods

class serde_json;

  // Static writers for string output to avoid buffer overwrites
  protected static string_writer compact_writer;
  protected static string_writer pretty_writer;

  // =========================================================================
  // Serialization (to_string family)
  // =========================================================================

  // Serialize to compact JSON string (no whitespace)
  // Equivalent to serde_json::to_string()
  static function Result#(string) to_string(json_value val);
    json_compact_formatter fmt;
    json_serializer ser;
    Result#(bit) res;

    if (compact_writer == null) compact_writer = new();
    else compact_writer.reset();

    fmt = new(compact_writer);
    ser = new(fmt);

    if (val != null)
      res = ser.serialize_value(val);
    else
      res = ser.serialize_null();

    if (res.is_err()) return Result#(string)::Err(res.unwrap_err());
    return ser.get_string();
  endfunction

  // Serialize to pretty-printed JSON string with default 2-space indent
  // Equivalent to serde_json::to_string_pretty()
  static function Result#(string) to_string_pretty(json_value val);
    return to_string_pretty_indent(val, "  ");
  endfunction

  // Serialize to pretty-printed JSON string with custom indent
  // Equivalent to serde_json::to_string_pretty() with custom formatter
  static function Result#(string) to_string_pretty_indent(json_value val, string indent);
    json_pretty_formatter fmt;
    json_serializer ser;
    Result#(bit) res;

    if (pretty_writer == null) pretty_writer = new();
    else pretty_writer.reset();

    fmt = new(pretty_writer);
    void'(fmt.with_indent(indent));  // Configure indent
    ser = new(fmt);

    if (val != null)
      res = ser.serialize_value(val);
    else
      res = ser.serialize_null();

    if (res.is_err()) return Result#(string)::Err(res.unwrap_err());
    return ser.get_string();
  endfunction

  // Serialize to file descriptor (compact) - streaming
  // Equivalent to serde_json::to_writer()
  static function Result#(bit) to_writer(int fd, json_value val);
    return json_serializer::to_writer(fd, val);
  endfunction

  // Serialize to file descriptor (pretty-printed) - streaming
  // Equivalent to serde_json::to_writer_pretty()
  static function Result#(bit) to_writer_pretty(int fd, json_value val);
    return json_serializer::to_writer_pretty(fd, val);
  endfunction

  // Serialize to file descriptor with custom indent - streaming
  static function Result#(bit) to_writer_pretty_indent(int fd, json_value val, string indent);
    // Note: For custom indent, we fall back to string-based approach
    // as the pretty formatter doesn't support runtime indent configuration
    Result#(string) res;

    res = to_string_pretty_indent(val, indent);
    if (res.is_err()) return Result#(bit)::Err(res.unwrap_err());

    $fwrite(fd, res.unwrap());
    return Result#(bit)::Ok(1);
  endfunction

  // =========================================================================
  // Deserialization (from_* family)
  // =========================================================================

  // Deserialize JSON string to json_value
  // Equivalent to serde_json::from_str()
  static function Result#(json_value) from_str(string json_str);
    json_deserializer deser;
    json_value_builder builder;
    Result#(bit) res;

    deser = json_deserializer::from_string(json_str);
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) return Result#(json_value)::Err(res.unwrap_err());
    return builder.get_result();
  endfunction

  // Read and deserialize from an open file descriptor - streaming
  // Equivalent to serde_json::from_reader()
  static function Result#(json_value) from_reader(int fd);
    file_reader reader;
    json_lexer lexer;
    json_deserializer deser;
    json_value_builder builder;
    Result#(bit) res;

    reader = new(fd);
    lexer = new(reader);
    deser = new(lexer);
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) return Result#(json_value)::Err(res.unwrap_err());
    return builder.get_result();
  endfunction

  // Deserialize JSON file to json_value - streaming
  // Equivalent to serde_json::from_file() (not in Rust serde_json, but commonly used)
  static function Result#(json_value) from_file(string path);
    int fd;
    file_reader reader;
    json_lexer lexer;
    json_deserializer deser;
    json_value_builder builder;
    Result#(bit) res;
    Result#(json_value) result;

    fd = $fopen(path, "r");
    if (fd == 0) begin
      return Result#(json_value)::Err($sformatf("Cannot open file: %s", path));
    end

    reader = new(fd);
    lexer = new(reader);
    deser = new(lexer);
    builder = new();
    res = deser.deserialize_any(builder);
    $fclose(fd);

    if (res.is_err()) return Result#(json_value)::Err(res.unwrap_err());
    return builder.get_result();
  endfunction

  // =========================================================================
  // Value conversion (json_value <-> user structs)
  // =========================================================================

  // Convert a serializable object to a json_value tree (DOM)
  // Equivalent to serde_json::to_value()
  static function Result#(json_value) to_value(serde_serialize value);
    json_value_serializer ser;
    Result#(bit) res;

    ser = new();
    if (value != null)
      res = value.serialize(ser);
    else
      res = ser.serialize_null();

    if (res.is_err()) return Result#(json_value)::Err(res.unwrap_err());
    return ser.get_value();
  endfunction

  // Deserialize a json_value tree back into a deserializable object
  // Equivalent to serde_json::from_value()
  static function Result#(bit) from_value(json_value val, serde_deserialize target);
    json_value_deserializer deser;
    Result#(bit) res;

    if (val == null) return Result#(bit)::Err("Cannot deserialize null value");
    if (target == null) return Result#(bit)::Err("Cannot deserialize to null target");

    deser = new(val);
    res = target.deserialize(deser);
    return res;
  endfunction

endclass
