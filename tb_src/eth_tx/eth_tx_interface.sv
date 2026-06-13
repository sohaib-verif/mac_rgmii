interface eth_tx_interface(input logic clk_i, input logic clk90_i, input logic clk_200MHz_i, input logic phy_rx_clk, input logic rst_ni);

  // logic                                                   rst_ni           ;
  // logic                                                   clk_i            ;
  // logic                                                   clk90_i          ;
  // logic                                                   clk_200MHz_i     ;
  // Ethernet: 1000BASE-T RGMII      
  // logic                                                   phy_rx_clk       ;
  logic      [3:0]                                        phy_rxd          ;
  logic                                                   phy_rx_ctl       ;
  logic                                                   phy_tx_clk       ;
  logic      [3:0]                                        phy_txd          ;
  logic                                                   phy_tx_ctl       ;
  logic                                                   phy_reset_n      ;
  logic                                                   phy_int_n        ;
  logic                                                   phy_pme_n        ;
  // MDIO        
  logic                                                   phy_mdio_i       ;
  logic                                                   phy_mdio_o       ;
  logic                                                   phy_mdio_oe      ;
  logic                                                   phy_mdc          ;

  // AXIS TX
  logic       [63:0]                                      tx_axis_tdata_i  ;
  logic       [7:0]                                       tx_axis_tstrb_i  ;
  logic       [7:0]                                       tx_axis_tkeep_i  ;
  logic                                                   tx_axis_tlast_i  ;
  logic                                                   tx_axis_tid_i    ;
  logic                                                   tx_axis_tdest_i  ;
  logic                                                   tx_axis_tuser_i  ;
  logic                                                   tx_axis_tvalid_i ;
  logic                                                   tx_axis_tready_o ;
  // AXIS RX
  logic       [63:0]                                      rx_axis_tdata_o  ;
  logic       [7:0]                                       rx_axis_tstrb_o  ;
  logic       [7:0]                                       rx_axis_tkeep_o  ;
  logic                                                   rx_axis_tlast_o  ;
  logic                                                   rx_axis_tid_o    ;
  logic                                                   rx_axis_tdest_o  ;
  logic                                                   rx_axis_tuser_o  ;
  logic                                                   rx_axis_tvalid_o ;
  logic                                                   rx_axis_tready_i ;

  // configuration (register interface)
  logic       [3:0]                                       reg_bus_addr_i   ;
  logic                                                   reg_bus_write_i  ;
  logic       [31:0]                                      reg_bus_wdata_i  ;
  logic       [3:0]                                       reg_bus_wstrb_i  ;
  logic                                                   reg_bus_valid_i  ;
  logic       [31:0]                                      reg_bus_rdata_o  ;
  logic                                                   reg_bus_error_o  ;
  logic                                                   reg_bus_ready_o  ;
endinterface: eth_tx_interface