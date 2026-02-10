`ifndef SV_SERDE_SEQ_ACCESS_SVH
`define SV_SERDE_SEQ_ACCESS_SVH

// seq_access.svh - Rust-like SeqAccess trait
// Implemented by the deserializer to provide a pull-based interface for sequences
//
// Usage (in visitor):
//   virtual function Result#(bit) visit_seq(serde_seq_access seq);
//     while (seq.has_next()) begin
//       // Option#(T) contains the seed if there's a next element
//       Option#(SomeType) elem = seq.next_element_seed();
//       // deserialize into elem
//     end
//   endfunction

interface class serde_seq_access;
  // Note: next_element_seed is not implemented due to SystemVerilog generic limitations
  // We rely on next_element() which takes a visitor

  // Returns Ok(1) if there is a next element, Ok(0) if done, Err on error
  pure virtual function Result#(bit) has_next();

  // Note: SystemVerilog doesn't have generics in interfaces the same way Rust does.
  // In practice, this will be implemented by json_seq_access which has a concrete
  // reference to the json_deserializer and knows the target type.
  // For a true generic interface, we'd use a base class or void* pattern.

  // Get the next element using the deserializer's deserialize_any capability
  // This pulls the next value and lets the visitor handle it
  pure virtual function Result#(bit) next_element(serde_visitor visitor);
endclass : serde_seq_access
`endif
