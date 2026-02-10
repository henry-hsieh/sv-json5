import common_pkg::*;

module test_smoke_common_option;
  initial begin
    Option#(int) opt_some;
    Option#(int) opt_none;
    int val;

    $display("Starting Option type tests...");

    // Test 1: Some state
    opt_some = Option#(int)::Some(42);
    if (!opt_some.is_some()) $display("TEST FAILED: opt_some.is_some() returned 0");
    if (opt_some.is_none()) $display("TEST FAILED: opt_some.is_none() returned 1");
    if (opt_some.unwrap() != 42) $display("TEST FAILED: opt_some.unwrap() mismatch");
    if (opt_some.unwrap_or(0) != 42) $display("TEST FAILED: opt_some.unwrap_or() mismatch");
    if (opt_some._expect("Should not be None") != 42) $display("TEST FAILED: opt_some._expect() mismatch");
    $display("TEST PASSED: Some state methods");

    // Test 2: None state
    opt_none = Option#(int)::None();
    if (opt_none.is_some()) $display("TEST FAILED: opt_none.is_some() returned 1");
    if (!opt_none.is_none()) $display("TEST FAILED: opt_none.is_none() returned 0");
    if (opt_none.unwrap_or(100) != 100) $display("TEST FAILED: opt_none.unwrap_or() mismatch");
    $display("TEST PASSED: None state methods");

    // Test 3: contains method
    if (!opt_some.contains(42)) $display("TEST FAILED: contains(42) should be true");
    if (opt_some.contains(100)) $display("TEST FAILED: contains(100) should be false");
    if (opt_none.contains(42)) $display("TEST FAILED: None.contains() should be false");
    $display("TEST PASSED: contains method");

    // Test 4: ok_or method - Some case
    begin
      Result#(int) res;
      res = opt_some.ok_or("error");
      if (!res.is_ok()) $display("TEST FAILED: ok_or on Some should be Ok");
      if (res.unwrap() != 42) $display("TEST FAILED: ok_or on Some value mismatch");
      $display("TEST PASSED: ok_or on Some");
    end

    // Test 5: ok_or method - None case
    begin
      Result#(int) res;
      res = opt_none.ok_or("custom error");
      if (!res.is_err()) $display("TEST FAILED: ok_or on None should be Err");
      if (!res.contains_err("custom error")) $display("TEST FAILED: ok_or error message mismatch");
      $display("TEST PASSED: ok_or on None");
    end

    // Test 6: String type Option
    begin
      Option#(string) opt_str_some;
      Option#(string) opt_str_none;

      opt_str_some = Option#(string)::Some("hello");
      if (!opt_str_some.is_some()) $display("TEST FAILED: string Some.is_some()");
      if (opt_str_some.unwrap() != "hello") $display("TEST FAILED: string unwrap mismatch");
      if (!opt_str_some.contains("hello")) $display("TEST FAILED: string contains mismatch");
      if (opt_str_some.contains("world")) $display("TEST FAILED: string contains should be false");

      opt_str_none = Option#(string)::None();
      if (!opt_str_none.is_none()) $display("TEST FAILED: string None.is_none()");
      if (opt_str_none.unwrap_or("default") != "default") $display("TEST FAILED: string unwrap_or mismatch");

      $display("TEST PASSED: String type Option");
    end

    // Test 7: and method
    begin
      Option#(int) a = Option#(int)::Some(1);
      Option#(int) b = Option#(int)::Some(2);
      Option#(int) c = Option#(int)::None();
      Option#(int) result;

      result = a._and(b);
      if (!result.is_some() || result.unwrap() != 2) $display("TEST FAILED: and(Some, Some) should be Some(2)");

      result = a._and(c);
      if (!result.is_none()) $display("TEST FAILED: and(Some, None) should be None");

      result = c._and(a);
      if (!result.is_none()) $display("TEST FAILED: and(None, Some) should be None");

      result = c._and(c);
      if (!result.is_none()) $display("TEST FAILED: and(None, None) should be None");

      $display("TEST PASSED: _and method");
    end

    // Test 8: or method
    begin
      Option#(int) a = Option#(int)::Some(1);
      Option#(int) b = Option#(int)::Some(2);
      Option#(int) c = Option#(int)::None();
      Option#(int) result;

      result = a._or(b);
      if (!result.is_some() || result.unwrap() != 1) $display("TEST FAILED: or(Some, Some) should be Some(1)");

      result = a._or(c);
      if (!result.is_some() || result.unwrap() != 1) $display("TEST FAILED: or(Some, None) should be Some(1)");

      result = c._or(a);
      if (!result.is_some() || result.unwrap() != 1) $display("TEST FAILED: or(None, Some) should be Some(1)");

      result = c._or(c);
      if (!result.is_none()) $display("TEST FAILED: or(None, None) should be None");

      $display("TEST PASSED: _or method");
    end

    // Test 9: xor method
    begin
      Option#(int) a = Option#(int)::Some(1);
      Option#(int) b = Option#(int)::Some(2);
      Option#(int) c = Option#(int)::None();
      Option#(int) result;

      result = a._xor(b);
      if (!result.is_none()) $display("TEST FAILED: xor(Some, Some) should be None");

      result = a._xor(c);
      if (!result.is_some() || result.unwrap() != 1) $display("TEST FAILED: xor(Some, None) should be Some(1)");

      result = c._xor(a);
      if (!result.is_some() || result.unwrap() != 1) $display("TEST FAILED: xor(None, Some) should be Some(1)");

      result = c._xor(c);
      if (!result.is_none()) $display("TEST FAILED: xor(None, None) should be None");

      $display("TEST PASSED: _xor method");
    end

    // Test 10: take method
    begin
      Option#(int) opt = Option#(int)::Some(42);
      Option#(int) taken;

      taken = opt.take();
      if (!taken.is_some() || taken.unwrap() != 42) $display("TEST FAILED: take should return Some(42)");
      if (!opt.is_none()) $display("TEST FAILED: take should leave None");

      $display("TEST PASSED: take method");
    end

    // Test 11: insert and replace methods
    begin
      Option#(int) opt = Option#(int)::Some(10);
      Option#(int) old;

      old = opt.insert(20);
      if (!old.is_some() || old.unwrap() != 10) $display("TEST FAILED: insert should return old Some(10)");
      if (opt.unwrap() != 20) $display("TEST FAILED: insert should set new value");

      old = opt.replace(30);
      if (!old.is_some() || old.unwrap() != 20) $display("TEST FAILED: replace should return old Some(20)");
      if (opt.unwrap() != 30) $display("TEST FAILED: replace should set new value");

      opt = Option#(int)::None();
      old = opt.insert(50);
      if (!old.is_none()) $display("TEST FAILED: insert on None should return None");
      if (opt.unwrap() != 50) $display("TEST FAILED: insert on None should set value");

      $display("TEST PASSED: insert and replace methods");
    end

    // Test 12: get_or_insert method
    begin
      Option#(int) opt = Option#(int)::Some(42);
      int val;

      val = opt.get_or_insert(100);
      if (val != 42) $display("TEST FAILED: get_or_insert on Some should return 42");

      opt = Option#(int)::None();
      val = opt.get_or_insert(100);
      if (val != 100) $display("TEST FAILED: get_or_insert on None should return default");
      if (!opt.is_some() || opt.unwrap() != 100) $display("TEST FAILED: get_or_insert should insert default");

      $display("TEST PASSED: get_or_insert method");
    end

    $display("Option type tests completed!");
    $finish;
  end

endmodule
