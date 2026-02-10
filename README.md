# sv-serde

A robust, Verilator-compatible Serde library for SystemVerilog with JSON and JSON5 support.


## Features

- **Rust-like Serde API**: `from_str`, `from_reader`, `from_file`, `to_string`, `to_string_pretty`, `to_writer`, `to_writer_pretty`.
- **JSON5 Support**: Comments (`//`, `/* */`), trailing commas, unquoted keys, single-quoted strings, hex numbers, and flexible decimal formats.
- **Pretty Printing**: Configurable indentation via `custom_indent` parameter.
- **Visitor Pattern**: Powerful architectural pattern for decoupled tree traversal.
- **Format-Agnostic Traits**: `serde_serialize` and `serde_deserialize` interfaces.
- **SAX-style Parsing**: Direct-to-object deserialization via `serde_deserialize` interface.
- **Robust Error Handling**: Rust-inspired `Result#(T)` and `Option#(T)` with functional APIs (`unwrap`, `expect_msg`, `and_then`, `some`, `none`).
- **Verilator Compatible**: Extensively tested with Verilator 5.038.
- **Safety**: Recursion depth protection (default 1024) in both serializer and parser.

## Usage

### Parsing JSON

```systemverilog
import common_pkg::*;
import json_pkg::*;

// Parse from string
Result#(json_value) res = serde_json::from_str('{"key": "value"}');
if (res.is_ok()) begin
    json_value val = res.unwrap();
    // use val...
end else begin
    $display("Error: %s", res.unwrap_err());
end
```

### Parsing JSON from File

```systemverilog
import common_pkg::*;
import json_pkg::*;

// Using from_file (convenience method)
Result#(json_value) res = serde_json::from_file("data.json");

// Using from_reader (file descriptor)
int fd = $fopen("data.json", "r");
if (fd != 0) begin
    res = serde_json::from_reader(fd);
    $fclose(fd);
end
```

### Parsing JSON5

```systemverilog
import common_pkg::*;
import json5_pkg::*;

// Parse JSON5 string
Result#(json_value) res = serde_json5::from_str("{ key: 'value', // comments! \n }");

// Parse JSON5 file
res = serde_json5::from_file("data.json5");
```

### Serializing to String

```systemverilog
import common_pkg::*;
import json_pkg::*;

// Compact output
Result#(string) s = serde_json::to_string(my_val);

// Pretty print with default indent (2 spaces)
s = serde_json::to_string_pretty(my_val);

// Pretty print with custom indent (4 spaces)
s = serde_json::to_string_pretty_indent(my_val, "    ");
```

### Serializing to Writer

```systemverilog
import common_pkg::*;
import json_pkg::*;

int fd = $fopen("output.json", "w");
if (fd != 0) begin
    Result#(bit) res = serde_json::to_writer(fd, my_val);
    // or with custom indent:
    // res = serde_json::to_writer_pretty_indent(fd, my_val, "    ");
    $fclose(fd);
end
```

### Serializing Custom Classes

Implement the `serde_serialize` interface in your classes to support serialization:

```systemverilog
import common_pkg::*;
import serde_pkg::*;

class address implements serde_serialize;
  string city;

  virtual function Result#(bit) serialize(serde_serializer ser);
    return ser.serialize_string(city);
  endfunction
endclass
```

## Running Tests

Requires Verilator installed.

```bash
make clean
make all
```

For targeted tests:

```bash
make test_app_json_compliance     # JSON integration tests
make test_app_json5_compliance   # JSON5 integration tests
make test_smoke_json5_deserialize # JSON5 parser feature tests
```

## License

[MIT](LICENSE)
