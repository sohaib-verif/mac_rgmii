/*-------------------------------------------------------------------------
File name   : eth_rx_agent.sv
Project     : SPI UVC
---------------------------------------------------------------------------*/

class eth_rx_agent extends uvm_agent;

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    int agent_id;

	eth_rx_config cfg;
    eth_rx_driver drv;
    eth_rx_sequencer sqr;
    eth_rx_monitor mon;
  
    // Provide implementations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(eth_rx_agent)
      `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
      `uvm_field_int(agent_id, UVM_ALL_ON)
    `uvm_component_utils_end
  
    // new - constructor
    function new (string name, uvm_component parent);
      super.new(name, parent);
    endfunction : new

  // Additional class methods
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual function void connect_phase(uvm_phase phase);
	extern virtual function void update_config(eth_rx_config cfg);
  
endclass:eth_rx_agent

// build
function void eth_rx_agent::build_phase(uvm_phase phase);
	super.build_phase(phase);
	// Configure
	if (cfg == null) begin
		`uvm_warning("NOCONFIG", $sformatf("Config not set for spi agent %0d , using default is_active field",agent_id))
		cfg = eth_rx_config::type_id::create("cfg");
		cfg.is_active = is_active;
	end
	else is_active = cfg.is_active;
	mon = eth_rx_monitor::type_id::create("mon", this);
	// mon.cfg=cfg;
	if(is_active == UVM_ACTIVE) begin
		sqr = eth_rx_sequencer::type_id::create("sqr", this);
		drv = eth_rx_driver::type_id::create("drv", this);
		drv.cfg=cfg;
	end
endfunction

// connect
function void eth_rx_agent::connect_phase(uvm_phase phase);
	if(is_active == UVM_ACTIVE) begin
		drv.seq_item_port.connect(sqr.seq_item_export);
	end
endfunction

// Assign the config to the agent's children
function void eth_rx_agent::update_config(eth_rx_config cfg);
	// mon.cfg = cfg;
	if (is_active == UVM_ACTIVE) begin
	drv.cfg = cfg;
	end
endfunction : update_config

  
