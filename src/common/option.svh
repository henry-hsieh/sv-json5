`ifndef SV_OPTION_SVH
`define SV_OPTION_SVH

// Option data type for optional values (present or null)
class Option#(type T);
  protected bit has_value;
  protected T m_value;

  static function Option#(T) Some(T val);
    Option#(T) inst = new();
    inst.has_value = 1;
    inst.m_value = val;
    return inst;
  endfunction

  static function Option#(T) None();
    Option#(T) inst = new();
    inst.has_value = 0;
    return inst;
  endfunction

  function bit is_some();
    return has_value;
  endfunction

  function bit is_none();
    return !has_value;
  endfunction

  function T unwrap();
    if (!has_value) begin
      $fatal(1, "Called Option::unwrap() on None value");
    end
    return m_value;
  endfunction

  function T unwrap_or(T default_val);
    if (has_value) return m_value;
    return default_val;
  endfunction

  function T _expect(string msg);
    if (!has_value) begin
      $fatal(1, "%s", msg);
    end
    return m_value;
  endfunction

  function bit contains(T val);
    return has_value && (m_value == val);
  endfunction

  // Converts Option to Result, using provided error message for None
  function Result#(T) ok_or(string err);
    if (has_value) return Result#(T)::Ok(m_value);
    else          return Result#(T)::Err(err);
  endfunction

  // Returns other if self is Some, else None
  function Option#(T) _and(Option#(T) other);
    if (has_value) return other;
    return Option#(T)::None();
  endfunction

  // Returns self if self is Some, else other
  function Option#(T) _or(Option#(T) other);
    if (has_value) return this;
    return other;
  endfunction

  // Returns Some if exactly one is Some, else None
  function Option#(T) _xor(Option#(T) other);
    if (has_value != other.is_some()) begin
      if (has_value) return this;
      else return other;
    end
    return Option#(T)::None();
  endfunction

  // Takes value out, leaving None in its place
  function Option#(T) take();
    Option#(T) result = Option#(T)::Some(m_value);
    has_value = 0;
    return result;
  endfunction

  // Inserts value, returns old value as Option
  function Option#(T) insert(T new_val);
    Option#(T) old = (has_value) ? Option#(T)::Some(m_value) : Option#(T)::None();
    has_value = 1;
    m_value = new_val;
    return old;
  endfunction

  // Alias for insert
  function Option#(T) replace(T new_val);
    return insert(new_val);
  endfunction

  // Returns value if Some, else inserts default and returns it
  function T get_or_insert(T default_val);
    if (!has_value) begin
      m_value = default_val;
      has_value = 1;
    end
    return m_value;
  endfunction
endclass

`endif
