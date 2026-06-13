/*-------------------------------------------------------------------------
File name   : test_pkg.sv
Project     : SPI VIP
---------------------------------------------------------------------------*/
package test_pkg;
    `include "uvm_macros.svh"
    //-----------------Importing uvm package-------------------
    import uvm_pkg::*;
    
    //---------------------Import agents' pkgs---------------------
    import top_env_pkg::*;

    //---------------------Files Inclusion---------------------
    //
    `include "eth_tx_test.sv" 
    `include "eth_rx_test.sv" 
    `include "eth_tx_rx_test.sv" 
    `include "eth_rx_1518_byte_test.sv"
    `include "eth_tx_padding_issue_test.sv"
    `include "eth_tx_tstrb_issue_test.sv"
	`include "eth_tx_tuser_error_test.sv"
    `include "eth_tx_throughput_test.sv"
    `include "eth_tx_1518B_test.sv" 
    `include "eth_tx_2000B_test.sv"
    `include "eth_tx_padding_test.sv"
    `include "eth_rand_pkt_test.sv" 
    `include "eth_tx_1000_pkt_test.sv" 
    `include "eth_tx_64_pkt_test.sv" 
    `include "eth_rx_multiple_packet_test.sv" 
    `include "eth_rx_64B_pkt_test.sv"
    `include "eth_rx_1000B_pkt_test.sv"
    `include "eth_rx_40B_pkt_padding_test.sv"
    `include "eth_rx_promiscous_test.sv"
    `include "eth_rx_disable_promiscous_test.sv"
    `include "eth_rx_2000_byte_test.sv"
    `include "eth_rx_broadcast_test.sv"
    `include "eth_rx_multicast_test.sv"
    `include "eth_rx_1520_byte_test.sv"
    `include "eth_rx_reg_config_test.sv"
    `include "eth_rx_cov_check_test.sv"
    `include "eth_tx_diff_speed_test.sv"
    `include "eth_tx_downsizer_cov_test.sv"
    `include "eth_tx_fibonacci_test.sv"
    `include "eth_tx_galoice_test.sv"
    `include "eth_tx_invalid_lfsr_cfg_test.sv"

endpackage:test_pkg
