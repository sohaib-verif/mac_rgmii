/*-------------------------------------------------------------------------
File name   : eth_rx_transaction.sv
Project     : SPI UVC
---------------------------------------------------------------------------*/

class eth_rx_transaction extends uvm_sequence_item;

    // rand variables
  
    //  rand byte unsigned dest_addr [6];
    //  rand byte unsigned src_addr [6];
     rand byte unsigned eth_type [2];
     rand byte unsigned payload  [$]        ; //Just Payload

    rand bit [47:0] src_addr;
    rand bit [47:0] dest_addr;
    rand bit [3:0] reg_addr;
    rand bit [3:0] reg_wstrb;
    rand bit [31:0] reg_write_data;
    bit [63:0] rx_axis_tdata_o;
    bit tlast;
    rand bit reg_write;
    rand bit reg_valid;
    rand bit regs_config_seq;
    // rand bit [31:0] num_of_packets;
    // constraints
    constraint c_payload_size {soft payload.size() inside {[46:1500]};}
    // constraint c_total_size_64_multiple {soft (18 + payload.size()) % 8 == 0;}

    `uvm_object_utils_begin(eth_rx_transaction)
	   	`uvm_field_int(reg_addr, UVM_DEFAULT)
	   	`uvm_field_int(src_addr, UVM_DEFAULT)
	   	`uvm_field_int(rx_axis_tdata_o, UVM_DEFAULT)
	   	`uvm_field_int(tlast, UVM_DEFAULT)
	   	`uvm_field_int(dest_addr, UVM_DEFAULT)
        `uvm_field_int(reg_write_data, UVM_DEFAULT)
        `uvm_field_int(reg_write, UVM_DEFAULT)
        `uvm_field_int(reg_valid, UVM_DEFAULT)
        // `uvm_field_int(num_of_packets, UVM_DEFAULT)
    `uvm_object_utils_end
  
    function new(string name = "eth_rx_transaction");
        super.new(name);
    endfunction
  
  endclass
  
