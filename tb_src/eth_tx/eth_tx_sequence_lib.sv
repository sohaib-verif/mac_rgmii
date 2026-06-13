typedef class eth_64B_pkt;
typedef class eth_1000_pkt;
typedef class eth_rand_pkt;
typedef class eth_padding;
typedef class eth_1518B_pkt;
typedef class eth_tx_2000B_pkt;
typedef class eth_throughput;
typedef class eth_tx_tuser_error;
typedef class tstrb_issue_pkt;
typedef class padding_issue_pkt;

class eth_tx_sequence_lib extends uvm_sequence;
  `uvm_object_utils(eth_tx_sequence_lib)
  
  eth_64B_pkt        eth_64B          ;
  eth_1000_pkt       eth_1000         ;
  eth_rand_pkt       eth_rand         ;
  eth_padding        eth_pad          ;
  eth_1518B_pkt      eth_1518B        ;
  eth_tx_2000B_pkt   eth_2000B        ;
  eth_throughput     eth_thrpt        ;
  eth_tx_tuser_error eth_tuser_err    ;
  tstrb_issue_pkt    tstrb_issue      ;
  padding_issue_pkt  padding_issue    ;
  function new(string name= "eth_tx_sequence_lib");
    super.new(name);
  endfunction

  task body();

    eth_64B       = eth_64B_pkt::type_id::create("eth_64B");
    eth_1000      = eth_1000_pkt::type_id::create("eth_1000");
    eth_rand      = eth_rand_pkt::type_id::create("eth_rand");
    eth_pad       = eth_padding::type_id::create("eth_pad");
    eth_1518B     = eth_1518B_pkt::type_id::create("eth_1518B");
    eth_2000B     = eth_tx_2000B_pkt::type_id::create("eth_2000B");
    eth_thrpt     = eth_throughput::type_id::create("eth_thrpt");
    eth_tuser_err = eth_tx_tuser_error::type_id::create("eth_tuser_err");
    tstrb_issue   = tstrb_issue_pkt::type_id::create("tstrb_issue");
    padding_issue = padding_issue_pkt::type_id::create("padding_issue");

    // eth_64B.start(m_sequencer);
    // eth_1000.start(m_sequencer);
    // eth_rand.start(m_sequencer);
    // eth_pad.start(m_sequencer);
    // eth_1518B.start(m_sequencer);
    // eth_2000B.start(m_sequencer);
    // eth_thrpt.start(m_sequencer);
    // eth_tuser_err.start(m_sequencer);
    // tstrb_issue.start(m_sequencer);
    // padding_issue.start(m_sequencer);
    
  endtask: body
  
endclass: eth_tx_sequence_lib


class eth_64B_pkt extends uvm_sequence;
  `uvm_object_utils(eth_64B_pkt)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_64B_pkt");
    super.new(name);
  endfunction

  task body();
    pkt = eth_tx_transaction::type_id::create("pkt");
    `uvm_do_with(pkt,{
      pkt.dest_mac[0]      == 8'h32;
      pkt.dest_mac[1]      == 8'h10;
      pkt.dest_mac[2]      == 8'h00;
      pkt.dest_mac[3]      == 8'h98;
      pkt.dest_mac[4]      == 8'h70;
      pkt.dest_mac[5]      == 8'h20;
      pkt.src_mac[0]       == 8'h32;
      pkt.src_mac[1]       == 8'h10;
      pkt.src_mac[2]       == 8'h00;
      pkt.src_mac[3]       == 8'h98;
      pkt.src_mac[4]       == 8'h70;
      pkt.src_mac[5]       == 8'h20;
      // pkt.eth_type[0]      == 8'h00;
      // pkt.eth_type[1]      == 8'hE2;
      pkt.payload.size()   == 50;
      foreach (pkt.payload[i]) {
        pkt.payload[i]   == (i + 1);
    }
      pkt.tx_axis_tuser_i  == 0; // No error
    })
  endtask: body
  
endclass: eth_64B_pkt


class eth_1000_pkt extends uvm_sequence;
  `uvm_object_utils(eth_1000_pkt)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_1000_pkt");
    super.new(name);
  endfunction

  task body();
    repeat(1000) begin
      pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.eth_type[0]      == 8'h00;
        pkt.eth_type[1]      == 8'hE2;
        pkt.payload.size()   == 50;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
    end
  endtask: body
  
endclass: eth_1000_pkt


class eth_rand_pkt extends uvm_sequence;
  `uvm_object_utils(eth_rand_pkt)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_rand_pkt");
    super.new(name);
  endfunction

  task body();
    pkt = eth_tx_transaction::type_id::create("pkt");
    `uvm_do_with(pkt,{
      pkt.eth_type[0]      == 8'h00;
      pkt.eth_type[1]      == 8'hE2;
      pkt.payload.size()   inside {[46:1500]}; 
      pkt.tx_axis_tuser_i  == 0; // No error
    })
  endtask: body
  
endclass: eth_rand_pkt


class eth_padding extends uvm_sequence;
  `uvm_object_utils(eth_padding)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_padding");
    super.new(name);
  endfunction

  task body();
  repeat(100) begin
    pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.eth_type[0]      == 8'h00;
        pkt.eth_type[1]      == 8'hE2;
        pkt.payload.size()   == 30;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
  end
  endtask: body
  
endclass: eth_padding


class eth_1518B_pkt extends uvm_sequence;
  `uvm_object_utils(eth_1518B_pkt)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_1518B_pkt");
    super.new(name);
  endfunction

  task body();
  //repeat(100) begin
    pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.eth_type[0]      == 8'h00;
        pkt.eth_type[1]      == 8'hE2;
        pkt.payload.size()   == 1504;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
  //end
  endtask: body
  
endclass: eth_1518B_pkt


class eth_tx_2000B_pkt extends uvm_sequence;
  `uvm_object_utils(eth_tx_2000B_pkt)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_tx_2000B_pkt");
    super.new(name);
  endfunction

  task body();
  repeat(100) begin
    pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.eth_type[0]      == 8'h00;
        pkt.eth_type[1]      == 8'hE2;
        pkt.payload.size()   == 1986;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
  end
  endtask: body
  
endclass: eth_tx_2000B_pkt


class eth_throughput extends uvm_sequence;
  `uvm_object_utils(eth_throughput)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_throughput");
    super.new(name);
  endfunction

  task body();
    repeat(15000) begin
      pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.eth_type[0]      == 8'h00;
        pkt.eth_type[1]      == 8'hE2;
        pkt.payload.size()   == 50;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
    end
  endtask: body
  
endclass: eth_throughput


class eth_tx_tuser_error extends uvm_sequence;
  `uvm_object_utils(eth_tx_tuser_error)
  
  eth_tx_transaction pkt;
  function new(string name="eth_tx_tuser_error"); super.new(name); endfunction
  
  task body();
    pkt = eth_tx_transaction::type_id::create("pkt");
    `uvm_do_with(pkt,{
      pkt.eth_type[0] == 8'h00;
      pkt.eth_type[1] == 8'hE2;
      pkt.payload.size() == 50;
      pkt.tx_axis_tuser_i == 1; // Set error flag
    })
  endtask
endclass: eth_tx_tuser_error


class tstrb_issue_pkt extends uvm_sequence;
  `uvm_object_utils(tstrb_issue_pkt)
  
  eth_tx_transaction pkt;
  function new(string name="tstrb_issue_pkt"); super.new(name); endfunction
  
  task body();
    pkt = eth_tx_transaction::type_id::create("pkt");
    `uvm_do_with(pkt,{
      pkt.eth_type[0] == 8'h00;
      pkt.eth_type[1] == 8'hE2;
      pkt.payload.size() == 57; // Payload size that causes tstrb issue
      pkt.tx_axis_tuser_i  == 0; // No error
    })
  endtask
endclass: tstrb_issue_pkt


class padding_issue_pkt extends uvm_sequence;
  `uvm_object_utils(padding_issue_pkt)
  
  eth_tx_transaction pkt;
  function new(string name="padding_issue_pkt"); super.new(name); endfunction
  
  task body();
    pkt = eth_tx_transaction::type_id::create("pkt");
    `uvm_do_with(pkt,{
      pkt.eth_type[0] == 8'h00;
      pkt.eth_type[1] == 8'hE2;
      pkt.payload.size() == 46; // P4 bytes will be pad, according to spec no need of padding
      pkt.tx_axis_tuser_i  == 0; // No error
    })
  endtask
endclass: padding_issue_pkt


class eth_tx_diff_speed_seq extends uvm_sequence;
  `uvm_object_utils(eth_tx_diff_speed_seq)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_tx_diff_speed_seq");
    super.new(name);
  endfunction

  task body();
    repeat(300) begin
      pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        // pkt.eth_type[0]      == 8'h00;
        // pkt.eth_type[1]      == 8'hE2;
        pkt.payload.size()   == 50;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
    end
  endtask: body
  
endclass: eth_tx_diff_speed_seq


// Need to change tstrb and tkeep to 55(in non-last flit) in tx_driver and in last flit make tkeep 0
class eth_tx_downsizer_cov_seq extends uvm_sequence;
  `uvm_object_utils(eth_tx_downsizer_cov_seq)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_tx_downsizer_cov_seq");
    super.new(name);
  endfunction

  task body();
    repeat(300) begin
      pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.payload.size()   == 50;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
    end
  endtask: body
  
endclass: eth_tx_downsizer_cov_seq


// Need to change instantiation of rgmii_lfsr in axis_gmii_tx from ".LFSR_CONFIG("GLOIS"), to .LFSR_CONFIG("FIBONACCI")", ".LFSR_FEED_FORWARD(0), to .LFSR_FEED_FORWARD(1),"
class eth_tx_fibonacci_seq extends uvm_sequence;
  `uvm_object_utils(eth_tx_fibonacci_seq)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_tx_fibonacci_seq");
    super.new(name);
  endfunction

  task body();
    repeat(300) begin
      pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.payload.size()   == 50;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
    end
  endtask: body
  
endclass: eth_tx_fibonacci_seq


// Need to change instantiation of rgmii_lfsr in axis_gmii_tx from ".LFSR_FEED_FORWARD(0), to .LFSR_FEED_FORWARD(1),"
class eth_tx_galoice_seq extends uvm_sequence;
  `uvm_object_utils(eth_tx_galoice_seq)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_tx_galoice_seq");
    super.new(name);
  endfunction

  task body();
    repeat(300) begin
      pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.payload.size()   == 50;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
    end
  endtask: body
  
endclass: eth_tx_galoice_seq


// Need to change instantiation of rgmii_lfsr in axis_gmii_tx from ".LFSR_CONFIG("GLOIS"), to .LFSR_CONFIG("INVALID")",
class eth_tx_invalid_lfsr_cfg_seq extends uvm_sequence;
  `uvm_object_utils(eth_tx_invalid_lfsr_cfg_seq)
  
  eth_tx_transaction pkt;

  function new(string name= "eth_tx_invalid_lfsr_cfg_seq");
    super.new(name);
  endfunction

  task body();
    repeat(300) begin
      pkt = eth_tx_transaction::type_id::create("pkt");
      `uvm_do_with(pkt,{
        pkt.payload.size()   == 50;
        pkt.tx_axis_tuser_i  == 0; // No error
      })
    end
  endtask: body
  
endclass: eth_tx_invalid_lfsr_cfg_seq