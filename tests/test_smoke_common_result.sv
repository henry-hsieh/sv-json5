import common_pkg::*;

module test_smoke_common_result;
  initial begin
    Result#(longint) res_ok;
    Result#(longint) res_err;
    longint val;

    $display("Starting Result type tests...");

    // Test 1: Success state
    res_ok = Result#(longint)::Ok(42);
    if (!res_ok.is_ok()) $display("TEST FAILED: res_ok.is_ok() returned 0");
    if (res_ok.is_err()) $display("TEST FAILED: res_ok.is_err() returned 1");
    if (res_ok.unwrap() != 42) $display("TEST FAILED: res_ok.unwrap() mismatch");
    if (res_ok.unwrap_or(0) != 42) $display("TEST FAILED: res_ok.unwrap_or() mismatch");
    if (res_ok._expect("Should not fail") != 42) $display("TEST FAILED: res_ok._expect() mismatch");
    $display("TEST PASSED: Success state methods");

    // Test 2: Error state
    res_err = Result#(longint)::Err("Something went wrong");
    if (res_err.is_ok()) $display("TEST FAILED: res_err.is_ok() returned 1");
    if (!res_err.is_err()) $display("TEST FAILED: res_err.is_err() returned 0");
    if (res_err.unwrap_or(100) != 100) $display("TEST FAILED: res_err.unwrap_or() mismatch");
    $display("TEST PASSED: Error state methods");

    // Test 3: contains() method
    begin
      if (!res_ok.contains(42)) $display("TEST FAILED: contains(42) on Ok(42)");
      if (res_ok.contains(100)) $display("TEST FAILED: contains(100) on Ok(42)");
      if (res_err.contains(42)) $display("TEST FAILED: contains on Err");
      $display("TEST PASSED: contains() method");
    end

    // Test 4: contains_err() method
    begin
      if (!res_err.contains_err("Something went wrong")) $display("TEST FAILED: contains_err on matching Err");
      if (res_err.contains_err("Wrong message")) $display("TEST FAILED: contains_err on non-matching Err");
      if (res_ok.contains_err("Any error")) $display("TEST FAILED: contains_err on Ok");
      $display("TEST PASSED: contains_err() method");
    end

    // Test 5: ok() method - convert Result to Option
    begin
      Option#(longint) opt;
      opt = res_ok.ok();
      if (!opt.is_some() || opt.unwrap() != 42) $display("TEST FAILED: ok() on Ok");
      opt = res_err.ok();
      if (!opt.is_none()) $display("TEST FAILED: ok() on Err should be None");
      $display("TEST PASSED: ok() method");
    end

    // Test 6: err() method - convert Result to Option
    begin
      Option#(string) opt;
      opt = res_err.err();
      if (!opt.is_some() || opt.unwrap() != "Something went wrong") $display("TEST FAILED: err() on Err");
      opt = res_ok.err();
      if (!opt.is_none()) $display("TEST FAILED: err() on Ok should be None");
      $display("TEST PASSED: err() method");
    end

    // Test 8: unwrap_err() method
    begin
      string err_msg;
      err_msg = res_err.unwrap_err();
      if (err_msg != "Something went wrong") $display("TEST FAILED: unwrap_err() mismatch");
      $display("TEST PASSED: unwrap_err() method");
    end

    // Test 9: expect_err() method
    begin
      string err_msg;
      err_msg = res_err.expect_err("Custom error");
      if (err_msg != "Something went wrong") $display("TEST FAILED: expect_err() mismatch");
      $display("TEST PASSED: expect_err() method");
    end

    // Test 10: _and() combinator
    begin
      Result#(longint) other_ok = Result#(longint)::Ok(100);
      Result#(longint) other_err = Result#(longint)::Err("other error");

      // Ok._and(Ok) -> other (Ok)
      if (!res_ok._and(other_ok).is_ok() || res_ok._and(other_ok).unwrap() != 100)
        $display("TEST FAILED: Ok._and(Ok) mismatch");
      else
        $display("TEST PASSED: Ok._and(Ok)");

      // Ok._and(Err) -> other (Err)
      if (!res_ok._and(other_err).is_err() || !res_ok._and(other_err).contains_err("other error"))
        $display("TEST FAILED: Ok._and(Err) mismatch");
      else
        $display("TEST PASSED: Ok._and(Err)");

      // Err._and(Ok) -> self (Err)
      if (!res_err._and(other_ok).is_err() || !res_err._and(other_ok).contains_err("Something went wrong"))
        $display("TEST FAILED: Err._and(Ok) mismatch");
      else
        $display("TEST PASSED: Err._and(Ok)");

      // Err._and(Err) -> self (Err)
      if (!res_err._and(other_err).is_err() || !res_err._and(other_err).contains_err("Something went wrong"))
        $display("TEST FAILED: Err._and(Err) mismatch");
      else
        $display("TEST PASSED: Err._and(Err)");
    end

    // Test 11: _or() combinator
    begin
      Result#(longint) other_ok = Result#(longint)::Ok(100);
      Result#(longint) other_err = Result#(longint)::Err("other error");

      // Ok._or(Ok) -> self (Ok)
      if (!res_ok._or(other_ok).is_ok() || res_ok._or(other_ok).unwrap() != 42)
        $display("TEST FAILED: Ok._or(Ok) mismatch");
      else
        $display("TEST PASSED: Ok._or(Ok)");

      // Ok._or(Err) -> self (Ok)
      if (!res_ok._or(other_err).is_ok() || res_ok._or(other_err).unwrap() != 42)
        $display("TEST FAILED: Ok._or(Err) mismatch");
      else
        $display("TEST PASSED: Ok._or(Err)");

      // Err._or(Ok) -> other (Ok)
      if (!res_err._or(other_ok).is_ok() || res_err._or(other_ok).unwrap() != 100)
        $display("TEST FAILED: Err._or(Ok) mismatch");
      else
        $display("TEST PASSED: Err._or(Ok)");

      // Err._or(Err) -> other (Err)
      if (!res_err._or(other_err).is_err() || !res_err._or(other_err).contains_err("other error"))
        $display("TEST FAILED: Err._or(Err) mismatch");
      else
        $display("TEST PASSED: Err._or(Err)");
    end

    $display("Result type tests completed!");
    $finish;
  end

endmodule
