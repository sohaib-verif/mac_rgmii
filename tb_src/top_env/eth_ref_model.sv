class eth_ref_model extends uvm_component;

  `uvm_component_utils(eth_ref_model)

  uvm_analysis_imp #(eth_tx_transaction, eth_ref_model) seq_pkt_imp;
  uvm_analysis_port #(eth_tx_transaction) exp_pkt_port;

  function new(string name="eth_ref_model", uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    seq_pkt_imp = new("seq_pkt_imp", this);
    exp_pkt_port = new("exp_pkt_port", this);
  endfunction

  function void write(eth_tx_transaction pkt);

  eth_tx_transaction exp_pkt;
  byte unsigned data[$];
  byte unsigned crc_input[$];
  bit [31:0] crc;
  int pad_bytes = 0;

  exp_pkt = eth_tx_transaction::type_id::create("exp_pkt");

  //------------------------------------------------
  // 1. Preamble
  //------------------------------------------------
  repeat(7)
    data.push_back(8'h55);

  //------------------------------------------------
  // 2. SFD
  //------------------------------------------------
  data.push_back(8'hD5);

  //------------------------------------------------
  // 3. Destination MAC
  //------------------------------------------------
  foreach(pkt.dest_mac[i]) begin
    data.push_back(pkt.dest_mac[i]);
    crc_input.push_back(pkt.dest_mac[i]);
  end

  //------------------------------------------------
  // 4. Source MAC
  //------------------------------------------------
  foreach(pkt.src_mac[i]) begin
    data.push_back(pkt.src_mac[i]);
    crc_input.push_back(pkt.src_mac[i]);
  end

  //------------------------------------------------
  // 5. Ethertype
  //------------------------------------------------
  foreach(pkt.eth_type[i]) begin
    data.push_back(pkt.eth_type[i]);
    crc_input.push_back(pkt.eth_type[i]);
  end

  //------------------------------------------------
  // 6. Payload
  //------------------------------------------------
  // Padding zeroes if needed
  if(pkt.payload.size() < 46) begin
    pad_bytes = 46 - pkt.payload.size();
    `uvm_info(get_type_name(), $sformatf("Number of zeros to be padded = %0d", pad_bytes), UVM_LOW)
    for(int i=0;i<pad_bytes;i++)
        pkt.payload.push_back(8'h00);
  end

  foreach(pkt.payload[i]) begin
    data.push_back(pkt.payload[i]);
    crc_input.push_back(pkt.payload[i]);
  end

  //------------------------------------------------
  // 7. CRC Calculation
  // CRC is calculated ONLY on:
  // Dest + Src + EthType + Payload
  //------------------------------------------------
  crc = calc_crc32(crc_input);

  //------------------------------------------------
  // 8. Append FCS (little-endian)
  //------------------------------------------------
  data.push_back(crc[7:0]);
  data.push_back(crc[15:8]);
  data.push_back(crc[23:16]);
  data.push_back(crc[31:24]);

  //------------------------------------------------
  // 9. Assign full packet
  //------------------------------------------------
  exp_pkt.data = data;

  `uvm_info(get_type_name(), $sformatf("Expected packet generated (size=%0d bytes)", exp_pkt.data.size()), UVM_LOW)

  //------------------------------------------------
  // 10. Send to scoreboard
  //------------------------------------------------
  exp_pkt.pkt_id = pkt.pkt_id;
  exp_pkt_port.write(exp_pkt);

endfunction

  function bit [31:0] calc_crc32(byte unsigned data[$]);

    bit [31:0] crc = 32'hFFFFFFFF;

    foreach(data[i]) begin
      crc ^= data[i];
      repeat(8) begin
        if(crc[0])
          crc = (crc >> 1) ^ 32'hEDB88320;
        else
          crc = crc >> 1;
      end
    end
    `uvm_info(get_type_name(), $sformatf("CRC calculated in eth_ref_model: %0h", ~crc), UVM_LOW)
    return ~crc;
  endfunction

endclass