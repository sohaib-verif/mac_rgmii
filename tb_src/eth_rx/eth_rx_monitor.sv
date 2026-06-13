/*-------------------------------------------------------------------------
File name   : eth_rx_monitor.sv
Project     : SPI UVC
---------------------------------------------------------------------------*/

// Modified by WHDL to make UVM 1.2 compliant

class eth_rx_monitor extends uvm_monitor;

    // This property is the virtual interfaced needed for this component to
    // view HDL signals.
    protected virtual eth_rx_interface eth_rx_vif;

    eth_rx_config cfg;
  
    // Agent Id
    protected int agent_id;
  
    // Property indicating the number of transactions occuring on the pt.
	  protected int unsigned num_transactions = 0;

    // The following bit is used to control whether coverage is
    // done both in the monitor class and the interface.
    bit coverage_enable = 1;
  
    uvm_analysis_port #(eth_rx_transaction) item_collected_port;
  
    // The following property holds the transaction information currently
    // begin captured (by the collect_receive_data and collect_transmit_data methods).
    protected eth_rx_transaction trans_collected;
  
    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(eth_rx_monitor)
      `uvm_field_int(agent_id, UVM_ALL_ON)
      `uvm_field_int(coverage_enable, UVM_ALL_ON)
    `uvm_component_utils_end
  
    // new - constructor
    function new (string name = "", uvm_component parent = null);
      super.new(name, parent);
      item_collected_port = new("item_collected_port", this);
    endfunction : new

    // Additional class methods
	  extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual protected task collect_transactions();
    extern virtual protected task reset_signals();

endclass : eth_rx_monitor

// build
function void eth_rx_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	// get virtual interface
	if(!uvm_config_db#(virtual eth_rx_interface)::get(this, "", "eth_rx_vif", eth_rx_vif))
		`uvm_fatal(get_name(),"No eth_rx_vif is set for this instance")
endfunction

// run phase
task eth_rx_monitor::run_phase(uvm_phase phase);
  trans_collected = eth_rx_transaction::type_id::create("trans_collected",this);
    reset_signals();
    collect_transactions(); 
endtask
  
// reset_signals
task eth_rx_monitor::reset_signals();
	// @(negedge eth_rx_vif.rst_ni);
	// `uvm_info(get_type_name(), "Reset Observed", UVM_LOW)
endtask : reset_signals

task eth_rx_monitor::collect_transactions();
  
  @(posedge eth_rx_vif.rst_ni);
  `uvm_info(get_type_name(), "Reset DONE", UVM_LOW)
  
  forever begin
    // `uvm_info(get_type_name(),$sformatf(" waiting for the event trigger"),UVM_LOW)        
    // `uvm_info(get_type_name(),$sformatf(" event got triggerd"),UVM_LOW)
    // 1. Wait for AXIS ready
    // wait (eth_rx_vif.rx_axis_tready_i == 1);

    // 2. Wait 3 negedges of RX clock
    // repeat (4) @(negedge eth_rx_vif.phy_rx_clk);

    // 3. Wait for ready to become 1 again (re-check / handshake stability)
    wait (eth_rx_vif.rx_axis_tready_i == 1);

    // 4. Wait for phy_rx_ctl to assert at negedge
    @(negedge eth_rx_vif.phy_rx_clk);
    wait (eth_rx_vif.phy_rx_ctl  == 1);
    while (~eth_rx_vif.rx_axis_tlast_o) begin
    // repeat (10) begin
	    `uvm_info(get_type_name(),"eth_rx_monitor while loop",UVM_NONE)
      // 5. Wait for rx_axis_tvalid_o to assert
      repeat (1) @(posedge eth_rx_vif.clk_i);
      `uvm_info(get_type_name(),"1  posedge",UVM_NONE)
      @(posedge eth_rx_vif.rx_axis_tvalid_o);
	    `uvm_info(get_type_name(),"eth_rx_monitor o_valid posedge",UVM_NONE)
      // 6. Sample stable data 
      @(posedge eth_rx_vif.phy_rx_clk);
      trans_collected.rx_axis_tdata_o = eth_rx_vif.rx_axis_tdata_o;
      trans_collected.tlast = eth_rx_vif.rx_axis_tlast_o;
      //  debug
      `uvm_info(get_type_name(), $sformatf("Captured data: 0x%0h", trans_collected.rx_axis_tdata_o), UVM_LOW)
      item_collected_port.write(trans_collected) ;
    end
  `uvm_info(get_type_name(), "while loop break", UVM_LOW)
    trans_collected.tlast = eth_rx_vif.rx_axis_tlast_o;
      // @(posedge eth_rx_vif.rx_axis_tvalid_o);
      // // 6. Sample stable data 
      // @(posedge eth_rx_vif.phy_rx_clk);
      // @(posedge eth_rx_vif.rx_axis_tvalid_o);
      trans_collected.rx_axis_tdata_o = eth_rx_vif.rx_axis_tdata_o;
      //  debug
      `uvm_info(get_type_name(), $sformatf("Captured data: 0x%0h", trans_collected.rx_axis_tdata_o), UVM_LOW)
      item_collected_port.write(trans_collected);
      wait (eth_rx_vif.rx_axis_tready_i == 0);
      @(negedge eth_rx_vif.clk_i);
      @(negedge eth_rx_vif.rx_axis_tlast_o);
	    repeat (2) @(negedge eth_rx_vif.clk_i);
	    // repeat (40) @(negedge eth_rx_vif.clk_i);
  `uvm_info(get_type_name(), "monitor end line", UVM_LOW)
    // num_transactions++;
  end
endtask : collect_transactions
