package DMA_CSR_ral_pkg;
  import uvm_pkg::*;
  import rggen_ral_pkg::*;
  `include "uvm_macros.svh"
  `include "rggen_ral_macros.svh"
  class SOURCE_ADDR_REG_reg_model extends rggen_ral_reg;
    rand rggen_ral_field addr;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(addr, 0, 32, "RW", 0, 32'h00000000, '{}, 1, 0, 0, "")
    endfunction
  endclass
  class DEST_ADDR_REG_reg_model extends rggen_ral_reg;
    rand rggen_ral_field addr;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(addr, 0, 32, "RW", 0, 32'h00000000, '{}, 1, 0, 0, "")
    endfunction
  endclass
  class LENGTH_REG_reg_model extends rggen_ral_reg;
    rand rggen_ral_field len;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(len, 0, 16, "RW", 0, 16'h0000, '{}, 1, 0, 0, "")
    endfunction
  endclass
  class CONTROL_REG_reg_model extends rggen_ral_reg;
    rand rggen_ral_custom_field #("DEFAULT", "DEFAULT", 0, 1) go;
    rand rggen_ral_field ie;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(go, 0, 1, "CUSTOM", 1, 1'h0, '{}, 1, 0, 0, "")
      `rggen_ral_create_field(ie, 1, 1, "RW", 0, 1'h0, '{}, 1, 0, 0, "")
    endfunction
  endclass
  class STATUS_REG_reg_model extends rggen_ral_reg;
    rand rggen_ral_field busy;
    rand rggen_ral_field done_if;
    function new(string name);
      super.new(name, 32, 0);
    endfunction
    function void build();
      `rggen_ral_create_field(busy, 0, 1, "RO", 1, 1'h0, '{}, 0, 0, 0, "")
      `rggen_ral_create_field(done_if, 16, 1, "W1C", 1, 1'h0, '{}, 1, 0, 0, "")
    endfunction
  endclass
  class DMA_CSR_block_model extends rggen_ral_block;
    rand SOURCE_ADDR_REG_reg_model SOURCE_ADDR_REG;
    rand DEST_ADDR_REG_reg_model DEST_ADDR_REG;
    rand LENGTH_REG_reg_model LENGTH_REG;
    rand CONTROL_REG_reg_model CONTROL_REG;
    rand STATUS_REG_reg_model STATUS_REG;
    function new(string name);
      super.new(name, 4, 0);
    endfunction
    function void build();
      `rggen_ral_create_reg(SOURCE_ADDR_REG, '{}, '{}, 5'h00, "RW", "g_SOURCE_ADDR_REG.u_register")
      `rggen_ral_create_reg(DEST_ADDR_REG, '{}, '{}, 5'h04, "RW", "g_DEST_ADDR_REG.u_register")
      `rggen_ral_create_reg(LENGTH_REG, '{}, '{}, 5'h08, "RW", "g_LENGTH_REG.u_register")
      `rggen_ral_create_reg(CONTROL_REG, '{}, '{}, 5'h0c, "RW", "g_CONTROL_REG.u_register")
      `rggen_ral_create_reg(STATUS_REG, '{}, '{}, 5'h10, "RW", "g_STATUS_REG.u_register")
    endfunction
  endclass
endpackage
