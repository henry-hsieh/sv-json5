`ifndef SV_RESULT_SVH
`define SV_RESULT_SVH

// Parameterized result type for success/error handling
class Result #(type T);
  protected bit is_success;
  protected T value;
  protected string error_msg;

  // Static factory methods
  static function Result#(T) Ok(T val);
    Result#(T) r = new();
    r.is_success = 1;
    r.value = val;
    r.error_msg = "";
    return r;
  endfunction

  static function Result#(T) Err(string msg);
    Result#(T) r = new();
    r.is_success = 0;
    // r.value stays null/default
    r.error_msg = msg;
    return r;
  endfunction

  function bit is_ok();
    return is_success;
  endfunction

  function bit is_err();
    return !is_success;
  endfunction

  // Compatibility with existing success() method
  function bit success();
    return is_success;
  endfunction

  function T unwrap();
    if (!is_success) begin
      $fatal(1, "Called Result::unwrap() on an Err value: %s", error_msg);
    end
    return value;
  endfunction

  function T unwrap_or(T default_val);
    if (!is_success) return default_val;
    return value;
  endfunction

  function T _expect(string msg);
    if (!is_success) begin
      $fatal(1, "%s: %s", msg, error_msg);
    end
    return value;
  endfunction

  // Convert to Option: Some(value) if Ok, None if Err
  function Option#(T) ok();
    if (is_success) return Option#(T)::Some(value);
    else            return Option#(T)::None();
  endfunction

  // Convert error to Option: Some(error_msg) if Err, None if Ok
  function Option#(string) err();
    if (!is_success) return Option#(string)::Some(error_msg);
    else             return Option#(string)::None();
  endfunction

  // Check if Ok and contains the given value
  function bit contains(T val);
    return is_success && (value == val);
  endfunction

  // Check if Err and contains the given error message
  function bit contains_err(string msg);
    return !is_success && (error_msg == msg);
  endfunction

  // Expect error with custom message - fatal if Ok
  function string expect_err(string msg);
    if (is_success) begin
      $fatal(1, "%s: Expected error but got Ok", msg);
    end
    return error_msg;
  endfunction

  // Unwrap error - fatal if Ok
  function string unwrap_err();
    if (is_success) begin
      $fatal(1, "Called Result::unwrap_err() on an Ok value");
    end
    return error_msg;
  endfunction

  // And: If self is Ok, return other. If self is Err, return self (short-circuit)
  function Result#(T) _and(Result#(T) other);
    if (is_success) return other;
    return this;
  endfunction

  // Or: If self is Ok, return self. If self is Err, return other (short-circuit)
  function Result#(T) _or(Result#(T) other);
    if (is_success) return this;
    return other;
  endfunction
endclass

`endif
