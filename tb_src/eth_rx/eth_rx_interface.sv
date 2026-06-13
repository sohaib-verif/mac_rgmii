/*-------------------------------------------------------------------------
File name   : eth_rx_interface.sv
Project     : SPI UVC
---------------------------------------------------------------------------*/

interface eth_rx_interface(input logic clk_i, input logic clk90_i, input logic clk_200MHz_i, input logic phy_rx_clk, input logic rst_ni);

    // Control flags
    bit                has_checks = 1;
    bit                has_coverage = 1;
  
    // SPI signals                                     
  // logic                                                   phy_rx_clk;
  logic      [3:0]                                        phy_rxd;
  logic                                                   phy_rx_ctl;
  logic      [3:0]                    reg_bus_addr_i;       
  logic      [3:0]                     reg_bus_wstrb_i;       
  logic      [31:0]                     reg_bus_wdata_i;       
  logic      [31:0]                     reg_bus_rdata_o;       
  logic                                reg_bus_write_i;       
  logic                                reg_bus_valid_i;       
  logic                                reg_bus_ready_o;       
  logic                                reg_bus_error_o;  
   
  logic       [63:0]                                      rx_axis_tdata_o  ;
  logic       [7:0]                                       rx_axis_tstrb_o  ;
  logic       [7:0]                                       rx_axis_tkeep_o  ;
  logic                                                   rx_axis_tlast_o  ;
  logic                                                   rx_axis_tid_o    ;
  logic                                                   rx_axis_tdest_o  ;
  logic                                                   rx_axis_tuser_o  ;
  logic                                                   rx_axis_tvalid_o ;
  logic                                                   rx_axis_tready_i ;
  // Coverage and assertions to be implemented here.
  
  //   covergroup cg_spi @(posedge wb_clk_i); 

  //       coverpoint sclk_pad_o;
  //       coverpoint mosi_pad_o;
  //       coverpoint miso_pad_i;
  //       coverpoint ss_pad_o {
  //         bins ss_pad_o_8 = {~8'd128};
  //         bins ss_pad_o_7 = {~8'd64};
  //         bins ss_pad_o_6 = {~8'd32};
  //         bins ss_pad_o_5 = {~8'd16};
  //         bins ss_pad_o_4 = {~8'd8};
  //         bins ss_pad_o_3 = {~8'd4};
  //         bins ss_pad_o_2 = {~8'd2};
  //         bins ss_pad_o_1 = {~8'd1};
  //       }
  //       cross_1: cross sclk_pad_o, mosi_pad_o;
  //       cross_2: cross sclk_pad_o, miso_pad_i;

  // endgroup
  //       cg_spi cg_eth_rx_ = new();
  endinterface : eth_rx_interface
  
  
