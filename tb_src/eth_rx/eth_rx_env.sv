/*-------------------------------------------------------------------------
File name   : eth_rx_env.sv
Project     : SPI UVC
---------------------------------------------------------------------------*/

class eth_rx_env extends uvm_env;

	uvm_analysis_imp#(eth_rx_config, eth_rx_env) eth_rx_cfg_port_in;

	eth_rx_config cfg;
  
	// Virtual Interface variable
	protected virtual eth_rx_interface eth_rx_vif;
  
	// Control properties
	protected int unsigned num_agents = 1;
  
	// The following two bits are used to control whether checks and coverage are
	// done both in the bus monitor class and the interface.
	bit intf_checks_enable = 1;
	bit intf_coverage_enable = 1;
	int wb_data;
  
	// Components of the environment
	eth_rx_agent agents[];
  
	// Provide implementations of virtual methods such as get_type_name and create
	`uvm_component_utils_begin(eth_rx_env)
	  `uvm_field_int(num_agents, UVM_ALL_ON)
	  `uvm_field_int(intf_checks_enable, UVM_ALL_ON)
	  `uvm_field_int(intf_coverage_enable, UVM_ALL_ON)
	`uvm_component_utils_end
  
	// new - constructor
	function new(string name, uvm_component parent);
	  super.new(name, parent);
	eth_rx_cfg_port_in = new ("eth_rx_cfg_port_in", this);
	wb_data =0;
	endfunction : new

  // Additional class methods
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void write(input eth_rx_config cfg );
  extern virtual protected task update_vif_enables();
  extern virtual task run_phase(uvm_phase phase);

endclass:eth_rx_env

	// build
	function void eth_rx_env::build_phase(uvm_phase phase);
	  string inst_name;
	  super.build_phase(phase);
	  agents = new[num_agents];
	  // get config object
	  if(!uvm_config_db#(eth_rx_config)::get(this, "", "cfg", cfg))begin //check
		// if not in config_db create one with default values
		`uvm_warning(get_type_name(),"Default SPI CONFIG OBJ is created")
		cfg = eth_rx_config::type_id::create("cfg", this);
	  end
	  // get virtual interface
	  if(!uvm_config_db#(virtual eth_rx_interface)::get(this, "", "eth_rx_vif", eth_rx_vif))
		`uvm_fatal(get_type_name(),"No SPI VIF is set for this instance")

	  for(int i = 0; i < num_agents; i++) begin
		$sformat(inst_name, "agents[%0d]", i);
		agents[i] = eth_rx_agent::type_id::create(inst_name, this);
		agents[i].agent_id = i;
		// set the virtual intf for all components in this env
		uvm_config_db#(virtual eth_rx_interface)::set(this, $sformatf("%s*",inst_name), "eth_rx_vif", eth_rx_vif);
	  end
	endfunction
  
  function void eth_rx_env::write(input eth_rx_config cfg );
	for(int i = 0; i < num_agents; i++) begin
	  agents[i].update_config(cfg);
	end
  endfunction

	// update_vif_enables
	task eth_rx_env::update_vif_enables();
	  forever begin
		@(intf_checks_enable || intf_coverage_enable);
		eth_rx_vif.has_checks <= intf_checks_enable;
		eth_rx_vif.has_coverage <= intf_coverage_enable;
	  end
	endtask : update_vif_enables
	// implement run task
	task eth_rx_env::run_phase(uvm_phase phase);
	  fork
		update_vif_enables();
	  join
	endtask
  
  