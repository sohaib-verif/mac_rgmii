import eth_tx_pkg::eth_tx_sequence_lib;
class eth_tx_test extends uvm_test;
  `uvm_component_utils(eth_tx_test)

  top_env     eth_env     ;
  eth_tx_sequence_lib    eth_seq_lib ;
  eth_ref_model       ref_mod     ;

  
  function new(string name = "eth_tx_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new

  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info(get_type_name(), "eth_tx_test build phase started", UVM_LOW)

    eth_seq_lib       = eth_tx_sequence_lib::type_id::create("eth_seq_lib");
    eth_env           = top_env::type_id::create("eth_env", this);
    ref_mod           = eth_ref_model::type_id::create("ref_mod", this);

  endfunction: build_phase

  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    ref_mod.exp_pkt_port.connect(eth_env.eth_scb.exp_pkt_imp);  // Expected pkt to scoreboard
    eth_env.eth_tx.eth_drv.ref_model_port.connect(ref_mod.seq_pkt_imp); // Raw packet to reference model

  endfunction: connect_phase


  task run_phase (uvm_phase phase);
    super.run_phase(phase);

    phase.raise_objection(this);

    eth_seq_lib.start(eth_env.eth_tx.eth_seqr);

    phase.phase_done.set_drain_time(this, 500ns);
    phase.drop_objection(this);
  endtask: run_phase

endclass: eth_tx_test