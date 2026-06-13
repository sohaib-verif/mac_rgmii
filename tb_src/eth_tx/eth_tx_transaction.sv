class eth_tx_transaction extends uvm_sequence_item;
  `uvm_object_utils(eth_tx_transaction)

  rand byte unsigned dest_mac [6]        ;
  rand byte unsigned src_mac  [6]        ;
  rand byte unsigned eth_type [2]        ;
  rand byte unsigned payload  [$]        ; //Just Payload
  rand byte unsigned data     [$]        ; //Whole packet
  static int         global_id_count = 0 ;
  int                pkt_id              ;
  
  rand logic       [3:0]                                 phy_rxd          ;
  rand logic                                             phy_rx_ctl       ;
  logic                                                  phy_tx_clk       ;
  logic            [3:0]                                 phy_txd          ;
  logic                                                  phy_tx_ctl       ;
  logic                                                  phy_reset_n      ;
  rand logic                                             phy_int_n        ;
  rand logic                                             phy_pme_n        ;
  // MDI    ;
  rand logic                                             phy_mdio_i       ;
  logic                                                  phy_mdio_o       ;
  logic                                                  phy_mdio_oe      ;
  logic                                                  phy_mdc          ;

  // AXIS TX
  rand logic     [63:0]                                  tx_axis_tdata_i  ;
  rand logic     [7:0]                                   tx_axis_tstrb_i  ;
  rand logic     [7:0]                                   tx_axis_tkeep_i  ;
  rand logic                                             tx_axis_tlast_i  ;
  rand logic                                             tx_axis_tid_i    ;
  rand logic                                             tx_axis_tdest_i  ;
  rand logic                                             tx_axis_tuser_i  ;
  rand logic                                             tx_axis_tvalid_i ;
  logic                                                  tx_axis_tready_o ;
  // AXIS RX
  logic          [63:0]                                  rx_axis_tdata_o  ;
  logic          [7:0]                                   rx_axis_tstrb_o  ;
  logic          [7:0]                                   rx_axis_tkeep_o  ;
  logic                                                  rx_axis_tlast_o  ;
  logic                                                  rx_axis_tid_o    ;
  logic                                                  rx_axis_tdest_o  ;
  logic                                                  rx_axis_tuser_o  ;
  logic                                                  rx_axis_tvalid_o ;
  rand logic                                             rx_axis_tready_i ;

  // configuration (register interface)
  rand logic     [3:0]                                   reg_bus_addr_i   ;
  rand logic                                             reg_bus_write_i  ;
  rand logic     [31:0]                                  reg_bus_wdata_i  ;
  rand logic     [3:0]                                   reg_bus_wstrb_i  ;
  rand logic                                             reg_bus_valid_i  ;
  logic          [31:0]                                  reg_bus_rdata_o  ;
  logic                                                  reg_bus_error_o  ;
  logic                                                  reg_bus_ready_o  ;

  function new(string name = "eth_tx_transaction");
    super.new(name);
  endfunction: new

  // constraint c_payload_size {soft payload.size() inside {[46:1500]};}
  // constraint c_total_size_64_multiple {soft (14 + payload.size()) % 8 == 0;}

  function void post_randomize();
    global_id_count++;            // Increment the master
    pkt_id = global_id_count;
  endfunction

  function void do_copy(uvm_object rhs);
  eth_tx_transaction rhs_tr;

  super.do_copy(rhs);

  if(!$cast(rhs_tr, rhs))
    `uvm_fatal("DO_COPY", "Cast failed in do_copy")

  // Packet fields
  dest_mac = rhs_tr.dest_mac;
  src_mac  = rhs_tr.src_mac;
  eth_type = rhs_tr.eth_type;
  payload  = rhs_tr.payload;
  data     = rhs_tr.data;

  pkt_id   = rhs_tr.pkt_id;

  // PHY
  phy_rxd     = rhs_tr.phy_rxd;
  phy_rx_ctl  = rhs_tr.phy_rx_ctl;
  phy_tx_clk  = rhs_tr.phy_tx_clk;
  phy_txd     = rhs_tr.phy_txd;
  phy_tx_ctl  = rhs_tr.phy_tx_ctl;
  phy_reset_n = rhs_tr.phy_reset_n;
  phy_int_n   = rhs_tr.phy_int_n;
  phy_pme_n   = rhs_tr.phy_pme_n;
  phy_mdio_i  = rhs_tr.phy_mdio_i;
  phy_mdio_o  = rhs_tr.phy_mdio_o;
  phy_mdio_oe = rhs_tr.phy_mdio_oe;
  phy_mdc     = rhs_tr.phy_mdc;

  // AXIS TX
  tx_axis_tdata_i  = rhs_tr.tx_axis_tdata_i;
  tx_axis_tstrb_i  = rhs_tr.tx_axis_tstrb_i;
  tx_axis_tkeep_i  = rhs_tr.tx_axis_tkeep_i;
  tx_axis_tlast_i  = rhs_tr.tx_axis_tlast_i;
  tx_axis_tid_i    = rhs_tr.tx_axis_tid_i;
  tx_axis_tdest_i  = rhs_tr.tx_axis_tdest_i;
  tx_axis_tuser_i  = rhs_tr.tx_axis_tuser_i;
  tx_axis_tvalid_i = rhs_tr.tx_axis_tvalid_i;
  tx_axis_tready_o = rhs_tr.tx_axis_tready_o;

  // AXIS RX
  rx_axis_tdata_o  = rhs_tr.rx_axis_tdata_o;
  rx_axis_tstrb_o  = rhs_tr.rx_axis_tstrb_o;
  rx_axis_tkeep_o  = rhs_tr.rx_axis_tkeep_o;
  rx_axis_tlast_o  = rhs_tr.rx_axis_tlast_o;
  rx_axis_tid_o    = rhs_tr.rx_axis_tid_o;
  rx_axis_tdest_o  = rhs_tr.rx_axis_tdest_o;
  rx_axis_tuser_o  = rhs_tr.rx_axis_tuser_o;
  rx_axis_tvalid_o = rhs_tr.rx_axis_tvalid_o;
  rx_axis_tready_i = rhs_tr.rx_axis_tready_i;

  // Register interface
  reg_bus_addr_i   = rhs_tr.reg_bus_addr_i;
  reg_bus_write_i  = rhs_tr.reg_bus_write_i;
  reg_bus_wdata_i  = rhs_tr.reg_bus_wdata_i;
  reg_bus_wstrb_i  = rhs_tr.reg_bus_wstrb_i;
  reg_bus_valid_i  = rhs_tr.reg_bus_valid_i;
  reg_bus_rdata_o  = rhs_tr.reg_bus_rdata_o;
  reg_bus_error_o  = rhs_tr.reg_bus_error_o;
  reg_bus_ready_o  = rhs_tr.reg_bus_ready_o;
endfunction

endclass: eth_tx_transaction
  
