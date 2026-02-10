`ifndef SV_SERDE_VISITOR_SVH
`define SV_SERDE_VISITOR_SVH
virtual class serde_visitor;
  virtual function Result#(bit) visit_int(longint val);
    return Result#(bit)::Err("visit_int not supported");
  endfunction

  virtual function Result#(bit) visit_uint(longint unsigned val);
    return Result#(bit)::Err("visit_uint not supported");
  endfunction

  virtual function Result#(bit) visit_real(real val);
    return Result#(bit)::Err("visit_real not supported");
  endfunction

  virtual function Result#(bit) visit_string(string val);
    return Result#(bit)::Err("visit_string not supported");
  endfunction

  virtual function Result#(bit) visit_bool(bit val);
    return Result#(bit)::Err("visit_bool not supported");
  endfunction

  // Pull-based visitor methods
  virtual function Result#(bit) visit_seq(serde_seq_access seq);
    return Result#(bit)::Err("visit_seq not supported");
  endfunction

  virtual function Result#(bit) visit_map(serde_map_access map);
    return Result#(bit)::Err("visit_map not supported");
  endfunction

  virtual function Result#(bit) visit_some(serde_deserializer deser);
    return Result#(bit)::Err("visit_some not supported");
  endfunction

  virtual function Result#(bit) visit_none();
    return Result#(bit)::Err("visit_none not supported");
  endfunction

  virtual function Result#(bit) visit_null();
    return Result#(bit)::Err("visit_null not supported");
  endfunction

  virtual function Result#(bit) visit_object_start();
    return Result#(bit)::Err("visit_object_start not supported");
  endfunction

  virtual function Result#(bit) visit_object_end();
    return Result#(bit)::Err("visit_object_end not supported");
  endfunction

  virtual function Result#(bit) visit_array_start();
    return Result#(bit)::Err("visit_array_start not supported");
  endfunction

  virtual function Result#(bit) visit_array_end();
    return Result#(bit)::Err("visit_array_end not supported");
  endfunction

  virtual function Result#(bit) visit_key(string key);
    return Result#(bit)::Err("visit_key not supported");
  endfunction
endclass
`endif
