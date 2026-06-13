/*-------------------------------------------------------------------------
File name   : wb_config.sv
Project     : WB UVC
---------------------------------------------------------------------------*/

class wb_config extends uvm_object;

    function new (string name = "");
      super.new(name);
    endfunction
  
    uvm_active_passive_enum  is_active = UVM_ACTIVE;
    
    `uvm_object_utils_begin(wb_config)
      `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
     `uvm_object_utils_end
endclass
  