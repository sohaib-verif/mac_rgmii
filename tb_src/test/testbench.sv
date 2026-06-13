/*---------------------------------------------------------------------------/
File name   : testbench.sv
Project     : SPI VIP
/---------------------------------------------------------------------------*/
import uvm_pkg::*;
//--------------------------------------------------------
//Top level module
//--------------------------------------------------------
module testbench;
  logic rst_ni       ;
  logic clk_i        ;
  logic clk90_i      ;
  logic clk_200MHz_i ;
  logic phy_rx_clk   ;
  // clk_rst_interface clk_rst_if (eth_tx_clk_i, eth_tx_rst_i);
  eth_tx_interface intf(
      .clk_i        (clk_i),
      .clk90_i      (clk90_i),
      .clk_200MHz_i (clk_200MHz_i),
      .phy_rx_clk   (phy_rx_clk),
      .rst_ni       (rst_ni)
      );
  eth_rx_interface p_if(
      .clk_i        (clk_i),
      .clk90_i      (clk90_i),
      .clk_200MHz_i (clk_200MHz_i),
      .phy_rx_clk   (phy_rx_clk),
      .rst_ni       (rst_ni)
      );
  eth_top_synth DUT (
    // Clock and Reset
    .rst_ni      (intf.rst_ni         ),  // Active-low reset
    .clk_i       (intf.clk_i          ),  // 125 MHz system clock
    .clk90_i     (intf.clk90_i        ),  // 125 MHz 90° shifted (for RGMII DDR)
    .clk_200MHz_i(intf.clk_200MHz_i   ),  // 200 MHz (for IDELAY calibration)

    // RGMII Physical Interface (1000BASE-T)
    // RX side (not used in TX-only module, but must be connected)
    .phy_rx_clk  (phy_rx_clk     ),  // RX clock input
    .phy_rxd     (p_if.phy_rxd        ),  // RX data [3:0]
    .phy_rx_ctl  (p_if.phy_rx_ctl     ),  // RX control (valid/error)

    // TX side (outputs to RX module in loopback)
    .phy_tx_clk  (intf.phy_tx_clk     ),  // TX clock output (125 MHz DDR)
    .phy_txd     (intf.phy_txd        ),  // TX data [3:0] (DDR, 8 bits/cycle)
    .phy_tx_ctl  (intf.phy_tx_ctl     ),  // TX control (valid/error)

    // PHY Management
    .phy_reset_n (intf.phy_reset_n   ),  // PHY reset (active-low)
    .phy_int_n   (/*1'b1*/intf.phy_int_n               ),  // PHY interrupt (not used, tied high)
    .phy_pme_n   (/*1'b1*/intf.phy_pme_n               ),  // PHY power management (not used)

    // MDIO Management Interface (not used in testbench)
    .phy_mdio_i  (/*1'b0*/intf.phy_mdio_i           ),  // MDIO input (tied low)
    .phy_mdio_o  (               ),  // MDIO output (unconnected)
    .phy_mdio_oe (               ),  // MDIO output enable (unconnected)
    .phy_mdc     (intf.phy_mdc               ),  // MDIO clock (unconnected)

    // AXI-Stream TX Interface (Input from testbench)
    .tx_axis_tdata_i (intf.tx_axis_tdata_i),   // TX data [63:0]
    .tx_axis_tstrb_i (intf.tx_axis_tstrb_i),   // TX byte strobe
    .tx_axis_tkeep_i (intf.tx_axis_tkeep_i),   // TX byte keep
    .tx_axis_tlast_i (intf.tx_axis_tlast_i),   // TX last transfer in packet
    .tx_axis_tid_i   (intf.tx_axis_tid_i),     // TX stream ID
    .tx_axis_tdest_i (intf.tx_axis_tdest_i),   // TX destination
    .tx_axis_tuser_i (intf.tx_axis_tuser_i),   // TX user sideband (0=no error)
    .tx_axis_tvalid_i(intf.tx_axis_tvalid_i),   // TX valid
    .tx_axis_tready_o(intf.tx_axis_tready_o),   // TX ready (backpressure)

    // AXI-Stream RX Interface (Output - not used in TX module)
    .rx_axis_tdata_o (p_if.rx_axis_tdata_o),   // RX data [63:0]
    .rx_axis_tstrb_o (p_if.rx_axis_tstrb_o),   // RX byte strobe
    .rx_axis_tkeep_o (p_if.rx_axis_tkeep_o),   // RX byte keep
    .rx_axis_tlast_o (p_if.rx_axis_tlast_o),   // RX last transfer
    .rx_axis_tid_o   (p_if.rx_axis_tid_o),     // RX stream ID
    .rx_axis_tdest_o (p_if.rx_axis_tdest_o),   // RX destination
    .rx_axis_tuser_o (p_if.rx_axis_tuser_o),   // RX user sideband
    .rx_axis_tvalid_o(p_if.rx_axis_tvalid_o),   // RX valid
    .rx_axis_tready_i(p_if.rx_axis_tready_i),   // RX ready

    // Configuration Register Interface (REG_BUS)
    .reg_bus_addr_i  (p_if.reg_bus_addr_i ),   // Register address [3:0]
    .reg_bus_write_i (p_if.reg_bus_write_i),  // Write enable
    .reg_bus_wdata_i (p_if.reg_bus_wdata_i),  // Write data [31:0]
    .reg_bus_valid_i (p_if.reg_bus_valid_i),  // Request valid
    .reg_bus_wstrb_i (p_if.reg_bus_wstrb_i),  // Write strobe (byte enable)
    .reg_bus_rdata_o (p_if.reg_bus_rdata_o),  // Read data [31:0]
    .reg_bus_ready_o (p_if.reg_bus_ready_o),  // Response ready
    .reg_bus_error_o (p_if.reg_bus_error_o)   // Error flag
  );


  initial begin
    uvm_config_db #(virtual eth_tx_interface)::set(null, "*", "intf", intf );
    uvm_config_db #(virtual eth_rx_interface)::set(null,"*", "eth_rx_vif", p_if);
  end

   initial begin
    run_test("");
  end

  initial begin
		$vcdplusfile("eth_waveform.vpd");
		$vcdpluson;
	end
  
  initial begin
    rst_ni        = 1'b0;
    #80000;
    rst_ni        = 1'b1;
    // #40;
    // rst_ni        = 1'b0;
    // #80000;
    // @(posedge clk_i);
    // rst_ni = 1'b1;
  end

  initial begin
    clk_i    = 1;
    clk90_i  = 0;

    forever begin
      #4 clk_i    = ~clk_i; // frequency 125MHz, 1Gbps
      // #20 clk_i    = ~clk_i;   // frequency 25MHz, 100Mbps
      // #200 clk_i    = ~clk_i;   // frequency 2.5MHz, 10Mbps
         clk90_i  = ~clk90_i;
         if(rst_ni)
          phy_rx_clk = clk90_i;
    end
  end
  initial begin
    clk_200MHz_i = 1;
    forever begin
        #2.5 clk_200MHz_i = ~clk_200MHz_i;
    end
  end
endmodule

