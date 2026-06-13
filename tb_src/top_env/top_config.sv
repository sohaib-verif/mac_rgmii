class top_config extends uvm_object;

    wb_config wb_cfg;
    `uvm_object_utils(top_config)

    //----------------------Constructor----------------------
    function new(string name = "env_config");
    super.new(name);
	wb_cfg = wb_config::type_id::create("wb_cfg");
    endfunction
    
endclass:top_config
