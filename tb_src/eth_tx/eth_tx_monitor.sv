class eth_tx_monitor extends uvm_monitor;
  `uvm_component_utils(eth_tx_monitor)
  
  virtual eth_tx_interface intf;
  eth_tx_transaction     pkt;
  
  uvm_analysis_port #(eth_tx_transaction) dut_pkt_port;  

  // Internal variables
  bit [3:0]  txd_rise;
  bit [3:0]  txd_fall;
  bit        tx_ctl_rise;
  bit        tx_ctl_fall;

  bit [7:0]  tx_byte;
  bit        tx_en;
  bit        tx_er;

  // For Throughput
  real start_time_rg, end_time_rg, prev_end_time_rg, tx_time, throughput;
  bit  in_frame;
  int  frame_bytes;

  function new(string name = "eth_tx_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction


  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    dut_pkt_port = new("dut_pkt_port", this);
    
    if(!(uvm_config_db #(virtual eth_tx_interface)::get(this,"*","intf",intf))) begin
      `uvm_error(get_type_name(),"Failed to get intf from config DB!")
    end
  endfunction


  task run_phase (uvm_phase phase);
    super.run_phase(phase);

    forever begin
      @(posedge intf.phy_tx_clk);

      // Rising edge sample
      txd_rise     = intf.phy_txd;
      tx_ctl_rise  = intf.phy_tx_ctl;

      // Falling edge sample
      @(negedge intf.phy_tx_clk);
      txd_fall     = intf.phy_txd;
      tx_ctl_fall  = intf.phy_tx_ctl;

      // Reconstruct byte
      tx_byte = {txd_fall, txd_rise};

      // Decode control
      tx_en = tx_ctl_rise;
      tx_er = tx_ctl_rise ^ tx_ctl_fall;

      //----------------------------------
      // Start of Frame
      //----------------------------------
      if (tx_en && pkt == null) begin
        pkt = eth_tx_transaction::type_id::create("pkt", this);
        pkt.data.delete();

        start_time_rg = $realtime;
        in_frame = 1;
        // *** ADDED IFG ***
        if(prev_end_time_rg != 0) begin
          real ifg = start_time_rg - prev_end_time_rg;
          `uvm_info("MON_IFG", $sformatf("IFG = %0t ns", ifg), UVM_LOW)
        end


        `uvm_info(get_type_name(),"TX packet started", UVM_LOW)
      end

      //----------------------------------
      // Collect packet bytes
      //----------------------------------
      if (tx_en && pkt != null) begin
        pkt.data.push_back(tx_byte);
      end

      //----------------------------------
      // End of Frame
      //----------------------------------
      if (!tx_en && pkt != null) begin


        end_time_rg = $realtime;
        in_frame = 0;
        frame_bytes = pkt.data.size();
        tx_time = end_time_rg - start_time_rg;
        throughput = (frame_bytes * 8.0) / tx_time;
        `uvm_info("MON_TPUT", $sformatf("Frame bytes=%0d time=%0t ns throughput=%0f Gbps", frame_bytes, tx_time, throughput), UVM_LOW)
        prev_end_time_rg = end_time_rg;



        `uvm_info(get_type_name(), $sformatf("TX packet completed. Size = %0d bytes", pkt.data.size()), UVM_MEDIUM)

        dut_pkt_port.write(pkt);

        pkt = null;
      end

    end
  endtask

endclass