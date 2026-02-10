module test_app_json_compliance;
  import common_pkg::*;
  import serde_pkg::*;
  import json_pkg::*;

  // Helper function to read file contents
  function string read_file(string filename);
    integer fd;
    string content;
    string line;
    integer status;

    fd = $fopen(filename, "r");
    if (fd == 0) begin
      $display("  ERROR: Could not open %s", filename);
      return "";
    end

    content = "";
    while (!$feof(fd)) begin
      status = $fgets(line, fd);
      if (status) begin
        content = {content, line};
      end
    end
    $fclose(fd);
    return content;
  endfunction

  initial begin
    string json_content;
    json_deserializer deser;
    json_value_builder builder;
    Result#(bit) res;
    Result#(json_value) result;
    json_value val;
    json_serializer ser;
    Result#(string) ser_result;
    string serialized;
    bit all_passed;
    int test_num;
    integer fd;
    string line;
    integer status;
    string stripped_content;
    int i;
    byte c;
    // Additional for pretty print test
    string pretty_output;
    string golden_content;
    json_deserializer deser3;
    json_value_builder builder3;
    Result#(json_value) result3;
    json_value val3;

    all_passed = 1;
    test_num = 0;

    $display("========================================");
    $display("JSON Compliance Integration Test");
    $display("========================================\n");

    // Test 1: Read JSON from file
    test_num = test_num + 1;
    $display("Test %0d: Read JSON from file", test_num);
    fd = $fopen("tests/data/sample_input.json", "r");
    if (fd == 0) begin
      $display("  TEST FAILED: Could not open tests/data/sample_input.json");
      all_passed = 0;
    end else begin
      // Read file contents into string
      json_content = "";
      while (!$feof(fd)) begin
        status = $fgets(line, fd);
        if (status) begin
          json_content = {json_content, line};
        end
      end
      $fclose(fd);

      // Strip newlines and extra whitespace to get compact JSON
      stripped_content = "";
      for (i = 0; i < json_content.len(); i++) begin
        c = json_content[i];
        if (c != "\n" && c != "\r" && c != "\t" && c != " ") begin
          stripped_content = {stripped_content, string'(c)};
        end
      end
      json_content = stripped_content;

      $display("  Read %0d characters from file (after stripping whitespace)", json_content.len());
      $display("  TEST PASSED: File read successfully");
    end

    // Test 2: Deserialize using json_deserializer::from_string()
    test_num = test_num + 1;
    $display("\nTest %0d: Deserialize using json_deserializer::from_string()", test_num);
    if (json_content.len() == 0) begin
      $display("  SKIPPED: No JSON content");
    end else begin
      deser = json_deserializer::from_string(json_content);
      builder = new();
      res = deser.deserialize_any(builder);
      if (res.is_err()) begin
        $display("  TEST FAILED: Deserialization error: %s", res.unwrap_err());
        all_passed = 0;
      end else begin
        $display("  TEST PASSED: JSON deserialized successfully");
      end
    end

    // Test 3: Get result from builder
    test_num = test_num + 1;
    $display("\nTest %0d: Get result from builder", test_num);
    if (res.is_err()) begin
      $display("  SKIPPED: Previous test failed");
    end else begin
      result = builder.get_result();
      if (result.is_err()) begin
        $display("  TEST FAILED: Builder get_result failed: %s", result.unwrap_err());
        all_passed = 0;
      end else begin
        val = result.unwrap();
        $display("  TEST PASSED: Got json_value from builder");
      end
    end

    // Test 4: Serialize using json_serializer
    test_num = test_num + 1;
    $display("\nTest %0d: Serialize using json_serializer", test_num);
    if (result.is_err()) begin
      $display("  SKIPPED: Previous test failed");
    end else begin
      ser = new();
      res = val.serialize(ser);
      if (res.is_err()) begin
        $display("  TEST FAILED: Serialization error: %s", res.unwrap_err());
        all_passed = 0;
      end else begin
        ser_result = ser.get_string();
        if (ser_result.is_err()) begin
          $display("  TEST FAILED: get_string error: %s", ser_result.unwrap_err());
          all_passed = 0;
        end else begin
          serialized = ser_result.unwrap();
          $display("  Original:  %0d chars", json_content.len());
          $display("  Serialized: %0d chars", serialized.len());
          $display("  TEST PASSED: Serialization successful");
        end
      end
    end

    // Test 5: Round-trip verification (deserialize serialized output)
    test_num = test_num + 1;
    $display("\nTest %0d: Round-trip verification", test_num);
    if (result.is_err() || ser_result.is_err()) begin
      $display("  SKIPPED: Previous test failed");
    end else begin
      json_deserializer deser2;
      json_value_builder builder2;
      Result#(json_value) result2;
      json_value val2;

      deser2 = json_deserializer::from_string(serialized);
      builder2 = new();
      res = deser2.deserialize_any(builder2);
      if (res.is_err()) begin
        $display("  TEST FAILED: Round-trip deserialization error: %s", res.unwrap_err());
        all_passed = 0;
      end else begin
        result2 = builder2.get_result();
        if (result2.is_err()) begin
          $display("  TEST FAILED: Round-trip builder get_result failed");
          all_passed = 0;
        end else begin
          val2 = result2.unwrap();
          // Compare original and round-tripped values
          if (!val.equals(val2)) begin
            $display("  TEST FAILED: Round-trip values not equal");
            $display("  Original serialized: %s", serialized);
            all_passed = 0;
          end else begin
            $display("  TEST PASSED: Round-trip successful, values equal");
          end
        end
      end
    end

    // Test 6: Pretty print serialization - compare with golden file
    test_num = test_num + 1;
    $display("\nTest %0d: Pretty print serialization (golden file compare)", test_num);
    if (result.is_err()) begin
      $display("  SKIPPED: Previous test failed");
    end else begin
      string pretty_output;
      string golden_output;
      string line;
      integer fd_golden;
      bit match = 1;
      int line_num = 1;

      // Serialize with pretty print
      ser_result = serde_json::to_string_pretty(val);
      if (ser_result.is_err()) begin
        $display("  TEST FAILED: Pretty print serialization error: %s", ser_result.unwrap_err());
        all_passed = 0;
      end else begin
        pretty_output = ser_result.unwrap();

        // Load golden file
        fd_golden = $fopen("tests/data/sample_pretty.golden.json", "r");
        if (fd_golden == 0) begin
          $display("  TEST FAILED: Cannot open golden file");
          all_passed = 0;
        end else begin
          golden_output = "";
          while (!$feof(fd_golden)) begin
            void'($fgets(line, fd_golden));
            golden_output = {golden_output, line};
          end
          void'($fclose(fd_golden));

          // Compare line by line
          if (pretty_output.len() != golden_output.len()) begin
            $display("  LENGTH MISMATCH: got=%0d, golden=%0d", pretty_output.len(), golden_output.len());
            match = 0;
          end else begin
            for (int j = 0; j < pretty_output.len(); j++) begin
              if (pretty_output[j] != golden_output[j]) begin
                $display("  CHAR MISMATCH at pos %0d: got='%c' (0x%02h), golden='%c' (0x%02h)",
                         j, pretty_output[j], pretty_output[j], golden_output[j], golden_output[j]);
                match = 0;
                break;
              end
            end
          end

          if (match) begin
            $display("  TEST PASSED: Pretty output matches golden file");
          end else begin
            $display("  TEST FAILED: Pretty output does not match golden file");
            $display("  Got length: %0d", pretty_output.len());
            $display("  Golden length: %0d", golden_output.len());
            $display("  Got output:\n%s", pretty_output);
            all_passed = 0;
          end
        end
      end
    end

    //========================================
    // Test 7: Custom indent (tab)
    //========================================
    test_num++;
    $display("\nTest %0d: Custom indent (tab) ---", test_num);
    begin
      json_deserializer deser7;
      json_value_builder builder7;
      Result#(bit) res7;
      Result#(json_value) result7;
      json_value val7;
      json_pretty_formatter fmt;
      json_serializer ser;
      Result#(bit) ser_res;
      string pretty_str;
      string golden_str;

      deser7 = json_deserializer::from_string(json_content);
      builder7 = new();
      res7 = deser7.deserialize_any(builder7);

      if (res7.is_ok()) begin
        result7 = builder7.get_result();
        if (result7.is_ok()) begin
          val7 = result7.unwrap();

          // Use tab indentation
          fmt = new();
          void'(fmt.with_indent("\t"));  // tab indent
          ser = new(fmt);
          ser_res = ser.serialize_value(val7);

          if (ser_res.is_ok()) begin
            pretty_str = fmt.get_result();

            // Load golden file and compare
            golden_str = read_file("tests/data/sample_custom.golden.json");

            if (golden_str.len() > 0) begin
              // Compare: both should have same structure with tabs
              if (golden_str == pretty_str) begin
                $display("PASS: Custom indent test (golden match)");
              end else begin
                $display("FAIL: Custom indent mismatch");
                $display("Golden (%0d): %s", golden_str.len(), golden_str);
                $display("Got    (%0d): %s", pretty_str.len(), pretty_str);
                all_passed = 0;
              end
            end else begin
              $display("FAIL: Empty golden file");
              all_passed = 0;
            end
          end else begin
            $display("FAIL: Serialize error: %s", ser_res.unwrap_err());
            all_passed = 0;
          end
        end else begin
          $display("FAIL: Builder get_result error: %s", result7.unwrap_err());
          all_passed = 0;
        end
      end else begin
        $display("FAIL: Deserialize error: %s", res7.unwrap_err());
        all_passed = 0;
      end
    end

    //========================================
    // Test 8: Streaming I/O - from_reader
    //========================================
    test_num++;
    $display("\nTest %0d: Streaming I/O - from_reader ---", test_num);
    begin
      int fd_stream;
      json_value stream_val;
      Result#(json_value) stream_result;
      json_object stream_obj;
      json_value title_val;
      Option#(json_object) opt_obj;

      fd_stream = $fopen("tests/data/sample_input.json", "r");
      if (fd_stream == 0) begin
        $display("FAIL: Cannot open file for streaming read");
        all_passed = 0;
      end else begin
        stream_result = serde_json::from_reader(fd_stream);
        void'($fclose(fd_stream));

        if (stream_result.is_err()) begin
          $display("FAIL: from_reader error: %s", stream_result.unwrap_err());
          all_passed = 0;
        end else begin
          stream_val = stream_result.unwrap();
          opt_obj = stream_val.as_object();
          if (opt_obj.is_none()) begin
            $display("FAIL: result is not an object");
            all_passed = 0;
          end else begin
            stream_obj = opt_obj.unwrap();
            title_val = stream_obj.get("title");
            if (title_val.is_string() == 0) begin
              $display("FAIL: title field is not a string");
              all_passed = 0;
            end else begin
              $display("PASS: Streaming from_reader works correctly");
            end
          end
        end
      end
    end

    //========================================
    // Test 9: Streaming I/O - from_file
    //========================================
    test_num++;
    $display("\nTest %0d: Streaming I/O - from_file ---", test_num);
    begin
      json_value file_val;
      Result#(json_value) file_result;
      json_object file_obj;
      json_value ver_val;
      Option#(json_object) opt_obj;

      file_result = serde_json::from_file("tests/data/sample_input.json");
      if (file_result.is_err()) begin
        $display("FAIL: from_file error: %s", file_result.unwrap_err());
        all_passed = 0;
      end else begin
        file_val = file_result.unwrap();
        opt_obj = file_val.as_object();
        if (opt_obj.is_none()) begin
          $display("FAIL: result is not an object");
          all_passed = 0;
        end else begin
          file_obj = opt_obj.unwrap();
          ver_val = file_obj.get("version");
          if (ver_val.is_real() == 0) begin
            $display("FAIL: version field is not a number");
            all_passed = 0;
          end else begin
            $display("PASS: Streaming from_file works correctly");
          end
        end
      end
    end

    //========================================
    // Test 10: Stream vs String consistency
    //========================================
    test_num++;
    $display("\nTest %0d: Stream vs String consistency ---", test_num);
    begin
      json_value stream_result_val;
      json_value string_result_val;
      int fd_cmp;
      Result#(json_value) cmp_result;
      string file_content;
      int chars_read;
      byte b;
      json_object obj_stream, obj_string;
      json_value title_stream_val, title_string_val;
      Option#(json_object) opt_obj_s, opt_obj_st;
      string stream_title, string_title;

      // Read via streaming
      fd_cmp = $fopen("tests/data/sample_input.json", "r");
      if (fd_cmp == 0) begin
        $display("FAIL: Cannot open file for comparison");
        all_passed = 0;
      end else begin
        cmp_result = serde_json::from_reader(fd_cmp);
        void'($fclose(fd_cmp));

        if (cmp_result.is_err()) begin
          $display("FAIL: from_reader failed: %s", cmp_result.unwrap_err());
          all_passed = 0;
        end else begin
          stream_result_val = cmp_result.unwrap();
          opt_obj_s = stream_result_val.as_object();
          if (opt_obj_s.is_some()) begin
            obj_stream = opt_obj_s.unwrap();
            title_stream_val = obj_stream.get("title");
            stream_title = title_stream_val.as_string().unwrap();
          end
        end
      end

      // Read file as string and parse
      fd_cmp = $fopen("tests/data/sample_input.json", "r");
      if (fd_cmp != 0) begin
        file_content = "";
        while (!$feof(fd_cmp)) begin
          chars_read = $fread(b, fd_cmp);
          if (chars_read > 0) begin
            if (b == 10) begin
              file_content = {file_content, "\n"};
            end else if (b != 13) begin
              file_content = {file_content, string'(b)};
            end
          end
        end
        void'($fclose(fd_cmp));

        cmp_result = serde_json::from_str(file_content);
        if (cmp_result.is_err()) begin
          $display("FAIL: from_str failed: %s", cmp_result.unwrap_err());
          all_passed = 0;
        end else begin
          string_result_val = cmp_result.unwrap();
          opt_obj_st = string_result_val.as_object();
          if (opt_obj_st.is_some()) begin
            obj_string = opt_obj_st.unwrap();
            title_string_val = obj_string.get("title");
            string_title = title_string_val.as_string().unwrap();
          end
        end
      end

      // Compare results
      if (stream_title != string_title) begin
        $display("FAIL: title mismatch: stream='%s' string='%s'", stream_title, string_title);
        all_passed = 0;
      end else begin
        $display("PASS: Stream and string parsing produce identical results");
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
