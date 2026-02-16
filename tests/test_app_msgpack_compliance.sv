// test_app_msgpack_compliance.sv - MessagePack compliance integration test

module test_app_msgpack_compliance;
  import common_pkg::*;
  import serde_pkg::*;
  import msgpack_pkg::*;

  initial begin
    msgpack_value root_val;
    msgpack_map root_map;
    msgpack_array tags_arr;
    msgpack_array nums_arr;
    msgpack_value serialized_val;
    byte_array_t bytes;
    Result#(byte_array_t) bytes_res;
    Result#(msgpack_value) val_res;
    Result#(bit) write_res;
    int fd;
    bit all_passed;
    int test_num;

    all_passed = 1;
    test_num = 0;

    $display("========================================");
    $display("MessagePack Compliance Integration Test");
    $display("========================================\n");

    // ========================================
    // Test 1: Construct complex msgpack_value
    // ========================================
    test_num = test_num + 1;
    $display("Test %0d: Construct complex msgpack_value", test_num);
    begin
      // Build a complex nested structure:
      // {
      //   "name": "test",
      //   "enabled": true,
      //   "count": 42,
      //   "tags": ["foo", "bar"],
      //   "numbers": [1, 2, 3],
      //   "nested": { "key": "value" },
      //   "empty": null
      // }

      root_map = msgpack_map::create();

      // "name": "test"
      root_map.set("name", msgpack_string::from("test"));

      // "enabled": true
      root_map.set("enabled", msgpack_bool::from(1));

      // "count": 42
      root_map.set("count", msgpack_int::from(42));

      // "tags": ["foo", "bar"]
      tags_arr = msgpack_array::create();
      tags_arr.add(msgpack_string::from("foo"));
      tags_arr.add(msgpack_string::from("bar"));
      root_map.set("tags", tags_arr);

      // "numbers": [1, 2, 3]
      nums_arr = msgpack_array::create();
      nums_arr.add(msgpack_int::from(1));
      nums_arr.add(msgpack_int::from(2));
      nums_arr.add(msgpack_int::from(3));
      root_map.set("numbers", nums_arr);

      // "nested": { "key": "value" }
      begin
        msgpack_map nested = msgpack_map::create();
        nested.set("key", msgpack_string::from("value"));
        root_map.set("nested", nested);
      end

      // "empty": null
      root_map.set("empty", msgpack_null::from());

      root_val = root_map;
      $display("  Constructed complex nested structure");
      $display("  TEST PASSED");
    end

    // ========================================
    // Test 2: Serialize to byte array
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: Serialize to byte array", test_num);
    begin
      bytes_res = serde_msgpack::to_array(root_val);
      if (bytes_res.is_err()) begin
        $display("  TEST FAILED: %s", bytes_res.unwrap_err());
        all_passed = 0;
      end else begin
        bytes = bytes_res.unwrap();
        $display("  Serialized to %0d bytes", bytes.size());
        if (bytes.size() == 0) begin
          $display("  TEST FAILED: Empty byte array");
          all_passed = 0;
        end else begin
          $display("  TEST PASSED");
        end
      end
    end

    // ========================================
    // Test 3: Deserialize from byte array
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: Deserialize from byte array", test_num);
    begin
      if (bytes.size() == 0) begin
        $display("  SKIPPED: Previous test failed");
      end else begin
        val_res = serde_msgpack::from_array_to_value(bytes);
        if (val_res.is_err()) begin
          $display("  TEST FAILED: %s", val_res.unwrap_err());
          all_passed = 0;
        end else begin
          serialized_val = val_res.unwrap();
          $display("  Deserialized to msgpack_value");
          $display("  TEST PASSED");
        end
      end
    end

    // ========================================
    // Test 4: Deep equality check
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: Deep equality check", test_num);
    begin
      if (root_val == null || serialized_val == null) begin
        $display("  SKIPPED: Previous test failed");
      end else begin
        // Debug: print type info
        $display("  DEBUG: root is_map=%b, is_array=%b", root_val.is_map(), root_val.is_array());
        $display("  DEBUG: deser is_map=%b, is_array=%b", serialized_val.is_map(), serialized_val.is_array());

        // Debug: compare sizes
        begin
          msgpack_map root_map = root_val.as_map().unwrap();
          msgpack_map deser_map = serialized_val.as_map().unwrap();
          $display("  DEBUG: root map size=%0d, deser map size=%0d", root_map.size(), deser_map.size());
        end

        if (root_val.equals(serialized_val)) begin
          $display("  Original and deserialized values are equal");
          $display("  TEST PASSED");
        end else begin
          $display("  TEST FAILED: Values not equal");
          all_passed = 0;
        end
      end
    end

    // ========================================
    // Test 5: Write to file and read back
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: Write to file and read back", test_num);
    begin
      string test_file = "tests/data/temp_msgpack_test.bin";

      // Write to file
      write_res = serde_msgpack::to_file(test_file, root_val);
      if (write_res.is_err()) begin
        $display("  TEST FAILED (write): %s", write_res.unwrap_err());
        all_passed = 0;
      end else begin
        $display("  Wrote %0d bytes to %s", bytes.size(), test_file);

        // Read from file
        val_res = serde_msgpack::from_file(test_file);
        if (val_res.is_err()) begin
          $display("  TEST FAILED (read): %s", val_res.unwrap_err());
          all_passed = 0;
        end else begin
          serialized_val = val_res.unwrap();
          $display("  Read back from file");

          // Verify equality
          if (root_val.equals(serialized_val)) begin
            $display("  File round-trip successful, values equal");
            $display("  TEST PASSED");
          end else begin
            $display("  TEST FAILED: Values not equal after file round-trip");
            all_passed = 0;
          end
        end
      end

    end

    // ========================================
    // Test 6: Clone and serialize
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: Clone and serialize", test_num);
    begin
      if (root_val == null) begin
        $display("  SKIPPED: Previous tests failed");
      end else begin
        msgpack_value cloned = root_val.clone();

        // Serialize both and compare bytes
        bytes_res = serde_msgpack::to_array(root_val);
        if (bytes_res.is_err()) begin
          $display("  TEST FAILED (original serialize): %s", bytes_res.unwrap_err());
          all_passed = 0;
        end else begin
          byte_array_t original_bytes = bytes_res.unwrap();

          bytes_res = serde_msgpack::to_array(cloned);
          if (bytes_res.is_err()) begin
            $display("  TEST FAILED (clone serialize): %s", bytes_res.unwrap_err());
            all_passed = 0;
          end else begin
            byte_array_t cloned_bytes = bytes_res.unwrap();

            if (original_bytes.size() != cloned_bytes.size()) begin
              $display("  TEST FAILED: Byte sizes differ");
              all_passed = 0;
            end else begin
              bit match = 1;
              for (int i = 0; i < original_bytes.size(); i++) begin
                if (original_bytes[i] != cloned_bytes[i]) begin
                  match = 0;
                  break;
                end
              end
              if (match) begin
                $display("  Clone serializes to identical bytes");
                $display("  TEST PASSED");
              end else begin
                $display("  TEST FAILED: Cloned bytes differ");
                all_passed = 0;
              end
            end
          end
        end
      end
    end

    // ========================================
    // Test 7: from_reader (streaming)
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: from_reader (streaming)", test_num);
    begin
      string test_file = "tests/data/temp_msgpack_stream.bin";

      // First write the file
      write_res = serde_msgpack::to_file(test_file, root_val);
      if (write_res.is_err()) begin
        $display("  TEST FAILED (write): %s", write_res.unwrap_err());
        all_passed = 0;
      end else begin
        // Open file and use from_reader
        fd = $fopen(test_file, "rb");
        if (fd == 0) begin
          $display("  TEST FAILED: Cannot open file");
          all_passed = 0;
        end else begin
          val_res = serde_msgpack::from_reader(fd);
          void'($fclose(fd));

          if (val_res.is_err()) begin
            $display("  TEST FAILED (from_reader): %s", val_res.unwrap_err());
            all_passed = 0;
          end else begin
            serialized_val = val_res.unwrap();
            if (root_val.equals(serialized_val)) begin
              $display("  Streaming read produces equal value");
              $display("  TEST PASSED");
            end else begin
              $display("  TEST FAILED: Values not equal");
              all_passed = 0;
            end
          end
        end
      end

      // Cleanup - use $system since Verilator doesn't support $fremove
      void'($system($sformatf("rm -f %s", test_file)));
    end

    // ========================================
    // Test 8: to_writer (streaming)
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: to_writer (streaming)", test_num);
    begin
      string test_file = "tests/data/temp_msgpack_writer.bin";

      // Open file and use to_writer
      fd = $fopen(test_file, "wb");
      if (fd == 0) begin
        $display("  TEST FAILED: Cannot open file");
        all_passed = 0;
      end else begin
        write_res = serde_msgpack::to_writer(fd, root_val);
        void'($fclose(fd));

        if (write_res.is_err()) begin
          $display("  TEST FAILED (to_writer): %s", write_res.unwrap_err());
          all_passed = 0;
        end else begin
          // Read back and compare
          val_res = serde_msgpack::from_file(test_file);
          if (val_res.is_err()) begin
            $display("  TEST FAILED (read back): %s", val_res.unwrap_err());
            all_passed = 0;
          end else begin
            serialized_val = val_res.unwrap();
            if (root_val.equals(serialized_val)) begin
              $display("  Streaming write produces equal value on read back");
              $display("  TEST PASSED");
            end else begin
              $display("  TEST FAILED: Values not equal");
              all_passed = 0;
            end
          end
        end
      end

      // Cleanup - use $system since Verilator doesn't support $fremove
      void'($system($sformatf("rm -f %s", test_file)));
    end

    // ========================================
    // Test 9: Golden byte verification
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: Golden byte verification", test_num);
    begin
      msgpack_map golden_map;
      msgpack_array arr;
      msgpack_map inner_map;

      // Test complex nested map:
      // {
      //   "a_array": [1, 2],
      //   "b_bool": true,
      //   "c_map": {"x": 10}
      // }
      // Keys are alphabetically sorted to match SystemVerilog associative array order
      //
      // Expected MessagePack encoding (30 bytes):
      // 83                : fixmap(3)
      // a7 61 5f 61 72 72 61 : "a_array" (7 chars)
      // 92 01 02          : [1, 2]
      // a6 62 5f 62 6f 6f 6c : "b_bool" (6 chars)
      // c3                : true
      // a5 63 5f 6d 61 70   : "c_map" (5 chars)
      // 81                 : fixmap(1)
      // a1 78             : "x" (1 char)
      // 0a                : 10

      golden_map = msgpack_map::create();
      // a_array: [1, 2]
      arr = msgpack_array::create();
      arr.add(msgpack_int::from(1));
      arr.add(msgpack_int::from(2));
      golden_map.set("a_array", arr);
      // b_bool: true
      golden_map.set("b_bool", msgpack_bool::from(1));
      // c_map: {"x": 10}
      inner_map = msgpack_map::create();
      inner_map.set("x", msgpack_int::from(10));
      golden_map.set("c_map", inner_map);

      bytes_res = serde_msgpack::to_array(golden_map);
      if (bytes_res.is_err()) begin
        $display("  TEST FAILED: Serialize error: %s", bytes_res.unwrap_err());
        all_passed = 0;
      end else begin
        byte_array_t actual = bytes_res.unwrap();

        // Expected bytes: 83 a7 61 5f 61 72 72 61 79 92 01 02 a6 62 5f 62 6f 6f 6c c3 a5 63 5f 6d 61 70 81 a1 78 0a
        if (actual.size() != 30) begin
          $display("  TEST FAILED: Size mismatch (expected 30, got %0d)", actual.size());
          all_passed = 0;
        end else begin
          bit mismatch = 0;
          // Compare byte by byte
          byte expected_bytes[30];
          expected_bytes[0] = 8'h83;   // fixmap(3)
          expected_bytes[1] = 8'ha7;   // "a" (7 chars)
          expected_bytes[2] = 8'h61;   // "a"
          expected_bytes[3] = 8'h5f;   // "_"
          expected_bytes[4] = 8'h61;   // "a"
          expected_bytes[5] = 8'h72;   // "r"
          expected_bytes[6] = 8'h72;   // "r"
          expected_bytes[7] = 8'h61;   // "a"
          expected_bytes[8] = 8'h79;   // fixstr(9) for array
          expected_bytes[9] = 8'h92;   // fixarray(2)
          expected_bytes[10] = 8'h01;  // 1
          expected_bytes[11] = 8'h02;  // 2
          expected_bytes[12] = 8'ha6; // "b" (6 chars)
          expected_bytes[13] = 8'h62; // "b"
          expected_bytes[14] = 8'h5f; // "_"
          expected_bytes[15] = 8'h62; // "b"
          expected_bytes[16] = 8'h6f; // "o"
          expected_bytes[17] = 8'h6f; // "o"
          expected_bytes[18] = 8'h6c; // "l"
          expected_bytes[19] = 8'hc3; // true
          expected_bytes[20] = 8'ha5; // "c" (5 chars)
          expected_bytes[21] = 8'h63; // "c"
          expected_bytes[22] = 8'h5f; // "_"
          expected_bytes[23] = 8'h6d; // "m"
          expected_bytes[24] = 8'h61; // "a"
          expected_bytes[25] = 8'h70; // "p"
          expected_bytes[26] = 8'h81; // fixmap(1)
          expected_bytes[27] = 8'ha1; // "x" (1 char)
          expected_bytes[28] = 8'h78; // "x"
          expected_bytes[29] = 8'h0a; // 10
          for (int i = 0; i < 30; i++) begin
            if (actual[i] != expected_bytes[i]) begin
              $display("  Byte mismatch at pos %0d: expected 0x%02h, got 0x%02h", i, expected_bytes[i], actual[i]);
              mismatch = 1;
            end
          end

          if (mismatch) begin
            $display("  Got:      %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h ...",
                     actual[0], actual[1], actual[2], actual[3], actual[4], actual[5], actual[6], actual[7], actual[8], actual[9]);
            $display("  Expected: 83 a7 61 5f 61 72 72 61 79 92 01 02 ...");
            all_passed = 0;
          end else begin
            $display("  Golden bytes match: complex map serialized correctly");
            $display("  TEST PASSED");
          end
        end
      end
    end

    // ========================================
    // Test 10: Stream vs Array consistency
    // ========================================
    test_num = test_num + 1;
    $display("\nTest %0d: Stream vs Array consistency", test_num);
    begin
      // Use the comprehensive binary file as source
      string bin_file = "tests/data/temp_msgpack_test.bin";
      msgpack_value val_from_array;
      msgpack_value val_from_stream;
      byte_array_t file_bytes;
      byte b;

      // 1. Read file into byte_array_t
      fd = $fopen(bin_file, "rb");
      if (fd == 0) begin
        $display("  TEST FAILED: Cannot open %s", bin_file);
        all_passed = 0;
      end else begin
        // Read bytes into array using concatenation
        file_bytes = '{};  // Initialize as empty dynamic array
        while ($fread(b, fd) > 0) begin
          file_bytes = {file_bytes, b};  // Array concatenation
        end
        void'($fclose(fd));
        $display("  Read %0d bytes from file", file_bytes.size());

        // 2. Deserialize from array (in-memory buffer)
        val_res = serde_msgpack::from_array_to_value(file_bytes);
        if (val_res.is_err()) begin
          $display("  TEST FAILED: from_array_to_value error: %s", val_res.unwrap_err());
          all_passed = 0;
        end else begin
          val_from_array = val_res.unwrap();
          $display("  Deserialized from array successfully");

          // 3. Deserialize from stream (file reader)
          fd = $fopen(bin_file, "rb");
          if (fd == 0) begin
            $display("  TEST FAILED: Cannot reopen file for streaming");
            all_passed = 0;
          end else begin
            val_res = serde_msgpack::from_reader(fd);
            void'($fclose(fd));

            if (val_res.is_err()) begin
              $display("  TEST FAILED: from_reader error: %s", val_res.unwrap_err());
              all_passed = 0;
            end else begin
              val_from_stream = val_res.unwrap();
              $display("  Deserialized from stream successfully");

              // 4. Compare
              if (val_from_array.equals(val_from_stream)) begin
                $display("  Array and Stream deserialization produce identical DOMs");
                $display("  TEST PASSED");
              end else begin
                $display("  TEST FAILED: DOM mismatch between Array and Stream sources");
                all_passed = 0;
              end
            end
          end
        end
      end
    end

    $display("\n========================================");
    if (all_passed) begin
      $display("ALL TESTS PASSED (%0d/%0d)", test_num, test_num);
    end else begin
      $display("SOME TESTS FAILED");
    end
    $display("========================================");

    $finish;
  end
endmodule
