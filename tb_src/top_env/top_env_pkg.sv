package top_env_pkg;
    `include "uvm_macros.svh"
    //-----------------Importing uvm package-------------------
    import uvm_pkg::*;
    
    //---------------------Import agents' pkgs---------------------
    import eth_tx_pkg::*;
	
    //---------------------Files Inclusion---------------------
    `include "eth_ref_model.sv"
	`include "eth_scoreboard.sv"
	`include "eth_rx_scoreboard.sv"
    `include "top_env.sv"
endpackage:top_env_pkg
