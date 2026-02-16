// serde_msgpack.svh - MessagePack facade for user-facing API

`ifndef SV_SERDE_MSGPACK_SVH
`define SV_SERDE_MSGPACK_SVH

class serde_msgpack;
  // Serialize any type that implements serde_serialize to byte array
  static function Result#(byte_array_t) to_array(serde_serialize value);
    msgpack_serializer ser;
    Result#(bit) res;

    ser = new();
    res = value.serialize(ser);
    if (res.is_err()) begin
      return Result#(byte_array_t)::Err(res.unwrap_err());
    end
    return Result#(byte_array_t)::Ok(ser.get_array());
  endfunction

  // Deserialize byte array to msgpack_value (DOM)
  static function Result#(msgpack_value) from_array_to_value(byte_array_t data);
    msgpack_deserializer deser;
    msgpack_value_builder builder;
    Result#(bit) res;

    deser = new(data);
    builder = new();
    res = deser.deserialize_any(builder);
    if (res.is_err()) begin
      return Result#(msgpack_value)::Err(res.unwrap_err());
    end
    return builder.get_result();
  endfunction

  // Deserialize any type that implements serde_deserialize from byte array
  static function Result#(serde_deserialize) from_array(byte_array_t data, serde_deserialize value);
    msgpack_deserializer deser;
    Result#(bit) res;

    deser = new(data);
    res = value.deserialize(deser);
    if (res.is_err()) begin
      return Result#(serde_deserialize)::Err(res.unwrap_err());
    end
    return Result#(serde_deserialize)::Ok(value);
  endfunction

  // Serialize to string (byte-compatible hex string)
  static function Result#(string) to_string(serde_serialize value);
    msgpack_serializer ser;
    Result#(bit) res;

    ser = new();
    res = value.serialize(ser);
    if (res.is_err()) begin
      return Result#(string)::Err(res.unwrap_err());
    end
    return Result#(string)::Ok(ser.get_string());
  endfunction

  // Serialize to file descriptor (binary) - streaming
  static function Result#(bit) to_writer(int fd, serde_serialize value);
    msgpack_serializer ser;
    Result#(bit) res;
    byte_array_t arr;

    ser = new();
    res = value.serialize(ser);
    if (res.is_err()) begin
      return Result#(bit)::Err(res.unwrap_err());
    end

    arr = ser.get_array();
    for (int i = 0; i < arr.size(); i++) begin
      $fwrite(fd, "%c", arr[i]);
    end
    return Result#(bit)::Ok(1);
  endfunction

  // Serialize to file (binary)
  static function Result#(bit) to_file(string path, serde_serialize value);
    int fd;
    Result#(bit) res;

    fd = $fopen(path, "wb");
    if (fd == 0) begin
      return Result#(bit)::Err($sformatf("Cannot open file for writing: %s", path));
    end

    res = to_writer(fd, value);
    void'($fclose(fd));
    return res;
  endfunction

  // Deserialize from file descriptor (binary) - streaming
  static function Result#(msgpack_value) from_reader(int fd);
    byte b;
    byte_array_t data;
    int bytes_read;

    // Read all bytes from file descriptor
    while (1) begin
      bytes_read = $fread(b, fd);
      if (bytes_read == 0) break;
      data = {data, b};
    end

    return from_array_to_value(data);
  endfunction

  // Deserialize from file (binary)
  static function Result#(msgpack_value) from_file(string path);
    int fd;
    Result#(msgpack_value) res;

    fd = $fopen(path, "rb");
    if (fd == 0) begin
      return Result#(msgpack_value)::Err($sformatf("Cannot open file: %s", path));
    end

    res = from_reader(fd);
    void'($fclose(fd));
    return res;
  endfunction
endclass

`endif
