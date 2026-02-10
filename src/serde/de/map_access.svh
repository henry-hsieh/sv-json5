`ifndef SV_SERDE_MAP_ACCESS_SVH
`define SV_SERDE_MAP_ACCESS_SVH

// map_access.svh - Rust-like MapAccess trait
// Implemented by the deserializer to provide a pull-based interface for maps/objects
//
// Usage (in visitor):
//   virtual function Result#(bit) visit_map(serde_map_access map);
//     while (map.has_next()) begin
//       // Pull next key-value pair
//       Result#(bit) res = map.next_entry(visitor);
//       if (res.is_err()) return res;
//     end
//   endfunction

interface class serde_map_access;
  // Returns Ok(1) if there is a next entry, Ok(0) if done, Err on error
  pure virtual function Result#(bit) has_next();

  // Get the next key-value pair by letting the visitor visit both
  // The visitor will first visit the key, then the value
  pure virtual function Result#(bit) next_entry(serde_visitor visitor);
endclass : serde_map_access
`endif
