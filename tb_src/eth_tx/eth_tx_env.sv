/*-------------------------------------------------------------------------
File name   : eth_tx_env.sv
Project     : WB UVC
---------------------------------------------------------------------------*/

class eth_tx_env extends uvm_env;

	// uvm_analysis_imp#(wb_config, eth_tx_env) wb_cfg_port_in;

	// wb_config cfg;
  
	// Virtual Interface variable
	protected virtual eth_tx_interface vif;
  
	// Control properties
	protected int unsigned num_agents = 1;
  
	// The following two bits are used to control whether checks and coverage are
	// done both in the bus monitor class and the interface.
	bit intf_checks_enable = 1;
	bit intf_coverage_enable = 1;
  
	// Components of the environment
	wb_agent agents[];
  
	// Provide implementations of virtual methods such as get_type_name and create
	`uvm_component_utils_begin(eth_tx_env)
	  `uvm_field_int(num_agents, UVM_ALL_ON)
	  `uvm_field_int(intf_checks_enable, UVM_ALL_ON)
	  `uvm_field_int(intf_coverage_enable, UVM_ALL_ON)
	`uvm_component_utils_end
  
	// new - constructor
	function new(string name, uvm_component parent);
	  super.new(name, parent);
	wb_cfg_port_in = new ("wb_cfg_port_in", this);
	endfunction : new

  // Additional class methods
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void write(input wb_config cfg );
  extern virtual protected task update_vif_enables();
  extern virtual task run_phase(uvm_phase phase);

endclass:eth_tx_env
	function void eth_tx_env::build_phase(uvm_phase phase);
	string inst_name;
	agents = new[num_agents];
	  super.build_phase(phase);
	  // get config object
	// if(!uvm_config_db#(wb_config)::get(this, "", "cfg", cfg)) begin
	// 	// if not in config_db create one with default values
	// 	`uvm_warning(get_type_name(),"Default wb CONFIG OBJ is created")
	// 	cfg = wb_config::type_id::create("cfg", this);
	// end
	  // get virtual interface
	  if(!uvm_config_db#(virtual eth_tx_interface)::get(this, "", "vif", vif))
		`uvm_fatal(get_type_name(),"No wb VIF is set for this instance")

	  for(int i = 0; i < num_agents; i++) begin
		$sformat(inst_name, "agents[%0d]", i);
		agents[i] = wb_agent::type_id::create(inst_name, this);
		agents[i].agent_id = i;
		// set the virtual intf for all components in this env
		uvm_config_db#(virtual eth_tx_interface)::set(this, $sformatf("%s*",inst_name), "vif", vif);
	  end
	endfunction
  
  function void eth_tx_env::write(input wb_config cfg );
	for(int i = 0; i < num_agents; i++) begin
	  agents[i].update_config(cfg);
	end
  endfunction

	// update_vif_enables
	task eth_tx_env::update_vif_enables();
	  forever begin
		@(intf_checks_enable || intf_coverage_enable);
		vif.has_checks <= intf_checks_enable;
		vif.has_coverage <= intf_coverage_enable;
	  end
	endtask : update_vif_enables
  
	// implement run task
	task eth_tx_env::run_phase(uvm_phase phase);
	  fork
		update_vif_enables();
	  join
	endtask
  
  
