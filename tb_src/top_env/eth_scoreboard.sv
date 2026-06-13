`uvm_analysis_imp_decl(_dut)
`uvm_analysis_imp_decl(_exp)
class eth_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(eth_scoreboard)
  
  uvm_analysis_imp_dut #(eth_tx_transaction, eth_scoreboard) dut_pkt_imp;
  uvm_analysis_imp_exp #(eth_tx_transaction, eth_scoreboard) exp_pkt_imp;
  eth_tx_transaction exp_pkt, dut_pkt;
  eth_tx_transaction dut_pkt_q[$], exp_pkt_q[$];
  int match_cntr  = 0;
  int mismatch_cntr = 0;

  function new(string name = "eth_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);   
    
    dut_pkt_imp  = new("dut_pkt_imp",  this);
    exp_pkt_imp  = new("exp_pkt_imp",  this);
    dut_pkt = eth_tx_transaction::type_id::create("dut_pkt");
    exp_pkt = eth_tx_transaction::type_id::create("exp_pkt");

  endfunction: build_phase
  
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase
  
  function void write_dut(eth_tx_transaction item);
    `uvm_info(get_type_name(), $sformatf("Got a packet from DUT"), UVM_LOW)
    dut_pkt_q.push_back(item);
  endfunction: write_dut
  
  
  function void write_exp(eth_tx_transaction item);
    `uvm_info(get_type_name(), $sformatf("Got an expected packet"), UVM_LOW)
    exp_pkt_q.push_back(item);
  endfunction: write_exp
  
  task run_phase (uvm_phase phase);
    super.run_phase(phase);

    forever begin
      wait(dut_pkt_q.size() > 0 && exp_pkt_q.size() > 0);
      dut_pkt = dut_pkt_q.pop_front();
      exp_pkt = exp_pkt_q.pop_front();
      compare_packets(exp_pkt, dut_pkt);
    end
  endtask: run_phase
  
  
  function void compare_packets(eth_tx_transaction exp_pkt, eth_tx_transaction act_pkt);

    `uvm_info(get_type_name(), $sformatf("Actual Packet from tx scoreboard"), UVM_LOW)
    display_pkt(act_pkt.data);
    `uvm_info(get_type_name(), $sformatf("Expected Packet from tx scoreboard"), UVM_LOW)
    display_pkt(exp_pkt.data);

    if(exp_pkt.data.size() != act_pkt.data.size()) begin
      `uvm_error(get_type_name(), $sformatf("Packet size mismatch: exp_pkt_size=%0dbytes, exp_id=%0d, act_pkt_size=%0dbytes", exp_pkt.data.size(), exp_pkt.pkt_id, act_pkt.data.size()))
      mismatch_cntr++;
      `uvm_info(get_type_name(), $sformatf("Mismatched Packets = %0d, Matched Packets = %0d", mismatch_cntr, match_cntr), UVM_LOW)
      return;
    end

    for(int i=0;i<exp_pkt.data.size();i++) begin
      if(exp_pkt.data[i] != act_pkt.data[i]) begin
        `uvm_error(get_type_name(), $sformatf("Packet mismatch at byte %0d exp=%02h act=%02h, exp_id=%0d", i, exp_pkt.data[i], act_pkt.data[i], exp_pkt.pkt_id))
        mismatch_cntr++;
        `uvm_info(get_type_name(), $sformatf("Mismatched Packets = %0d, Matched Packets = %0d", mismatch_cntr, match_cntr), UVM_LOW)
        return;
      end
    end
    match_cntr++;
    `uvm_info(get_type_name(), $sformatf("Mismatched Packets = %0d, Matched Packets = %0d", mismatch_cntr, match_cntr), UVM_LOW)
  endfunction

  function void display_pkt(byte unsigned data[$]);
    string msg = "\n";
    foreach (data[i]) begin
      msg = {msg, $sformatf("%02h ", data[i])};
      if ((i + 1) % 16 == 0) msg = {msg, "\n"};
    end
    `uvm_info("pkt", msg, UVM_LOW)
endfunction

  
endclass: eth_scoreboard