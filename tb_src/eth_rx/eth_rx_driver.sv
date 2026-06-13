/*-------------------------------------------------------------------------
File name   : eth_rx_driver.sv
Project     : RX UVC
---------------------------------------------------------------------------*/

class eth_rx_driver extends uvm_driver #(eth_rx_transaction);

    // The virtual interface used to drive and view HDL signals.
    protected virtual eth_rx_interface eth_rx_vif;
  
    eth_rx_config cfg; 
    // Agent Id
	protected int agent_id;
	uvm_analysis_port #(eth_rx_transaction) item_derived_port;
    byte unsigned crc_input[$];
	byte unsigned         temp_pkt[];
	
    // Provide implmentations of virtual methods such as get_type_name and create
    `uvm_component_utils_begin(eth_rx_driver)
      `uvm_field_int(agent_id, UVM_ALL_ON)
    `uvm_component_utils_end
  
    // new - constructor
    function new (string name, uvm_component parent);
	  super.new(name, parent);
	  item_derived_port = new("item_derived_port", this);
    endfunction : new

	task send_byte(input [7:0] data);
		// LSB nibble (negedge)
		@(negedge eth_rx_vif.phy_rx_clk);
        eth_rx_vif.phy_rx_ctl 		<=  1;
		eth_rx_vif.phy_rxd    <= data[3:0];
		// MSB nibble (posedge)
		@(posedge eth_rx_vif.phy_rx_clk);
		eth_rx_vif.phy_rxd    <= data[7:4];
	endtask  : send_byte

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
	`uvm_info(get_type_name(), $sformatf("CRC calculated in eth_rx_driver: %0h", ~crc), UVM_LOW)
    return ~crc;
  endfunction

  function void display_pkt(byte unsigned my_array[]);
    string msg = "\n";
    foreach (my_array[i]) begin
      msg = {msg, $sformatf("%02h ", my_array[i])};
      if ((i + 1) % 16 == 0) msg = {msg, "\n"};
    end
    `uvm_info("pkt_from_sequence", msg, UVM_LOW)
  endfunction

      // Additional class methods
	extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual protected task get_and_drive();
    extern virtual protected task reset_signals();
    extern virtual protected task drive_transfer (eth_rx_transaction trans);
    extern virtual protected task regs_config (eth_rx_transaction trans);  
endclass : eth_rx_driver

// build
function void eth_rx_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get virtual interface
    if(!uvm_config_db#(virtual eth_rx_interface)::get(this, "", "eth_rx_vif", eth_rx_vif))
        `uvm_fatal(get_name(),"No eth_rx_vif is set for this instance")
endfunction

// run phase
task eth_rx_driver::run_phase(uvm_phase phase);
	fork
	get_and_drive();
	reset_signals();
	join
endtask
  
// get_and_drive
task eth_rx_driver::get_and_drive();
	eth_rx_transaction this_trans;
	@(posedge eth_rx_vif.rst_ni);
	`uvm_info(get_type_name(), "Reset Done", UVM_LOW)
	forever begin
		@(negedge eth_rx_vif.clk_i);	@(negedge eth_rx_vif.clk_i);
		seq_item_port.get_next_item(req);
		if (!$cast(this_trans, req))
			uvm_report_fatal("CASTFL", "Failed to cast req to this_trans in get_and_drive");
		`uvm_info(get_type_name(), $sformatf("RX Start Driving Transfer \n%s",this_trans.sprint()), UVM_NONE)
				@(negedge eth_rx_vif.phy_rx_clk);	@(negedge eth_rx_vif.phy_rx_clk);	@(negedge eth_rx_vif.phy_rx_clk);	#2;
				if (this_trans.regs_config_seq)
					regs_config(this_trans);
				else begin
					drive_transfer(this_trans);
				end
		`uvm_info(get_type_name(), "\nEND of DRIVE TRANSFER\n", UVM_LOW)
		seq_item_port.item_done();
	end
endtask : get_and_drive
  
// reset_signals
task eth_rx_driver::reset_signals();
	@(negedge eth_rx_vif.rst_ni);
	`uvm_info(get_type_name(), "Reset Observed", UVM_LOW)
	// update 
	eth_rx_vif.phy_rxd <= 1'b0;
	eth_rx_vif.phy_rx_ctl <= 1'b0;
	
endtask : reset_signals
  
// drive_transfer
task eth_rx_driver::drive_transfer (eth_rx_transaction trans);
int frame_size;
int padding_bytes_size = 0;
bit [31:0] fcs_crc;
		`uvm_info(get_type_name(), "\nStart drive_transfer task\n", UVM_LOW)

	eth_rx_vif.rx_axis_tready_i 		<=  1;
	eth_rx_vif.reg_bus_addr_i 		<=  'b0;
	eth_rx_vif.reg_bus_write_i 		<=  'b0;
	eth_rx_vif.reg_bus_wdata_i 		<=  'b0;
	eth_rx_vif.reg_bus_valid_i 		<=  'b0;
	eth_rx_vif.reg_bus_wstrb_i 		<=  'b0;
	repeat (3) @(negedge eth_rx_vif.phy_rx_clk);
	@(negedge eth_rx_vif.phy_rx_clk);
    // eth_rx_vif.phy_rx_ctl 		<=  1;
	// Step.1: Send Preamble (7 Bytes)
	// Step.2: Send SFD (1 Byte)
    //   CRC is calculated ONLY on:
    //   Dest + Src + EthType + Payload

	temp_pkt = { trans.dest_addr[47:40], trans.dest_addr[39:32], trans.dest_addr[31:24], trans.dest_addr[23:16], trans.dest_addr[15:8], trans.dest_addr[7:0],
             	 trans.src_addr[47:40],  trans.src_addr[39:32],  trans.src_addr[31:24],  trans.src_addr[23:16],  trans.src_addr[15:8],  trans.src_addr[7:0],
             	 trans.eth_type, 
             	 trans.payload };
	display_pkt(temp_pkt);

    crc_input.delete();

	// Destination MAC
	crc_input.push_back(trans.dest_addr[7:0]);
	crc_input.push_back(trans.dest_addr[15:8]);
	crc_input.push_back(trans.dest_addr[23:16]);
	crc_input.push_back(trans.dest_addr[31:24]);
	crc_input.push_back(trans.dest_addr[39:32]);
	crc_input.push_back(trans.dest_addr[47:40]);

	// Source MAC
	crc_input.push_back(trans.src_addr[7:0]);
	crc_input.push_back(trans.src_addr[15:8]);
	crc_input.push_back(trans.src_addr[23:16]);
	crc_input.push_back(trans.src_addr[31:24]);
	crc_input.push_back(trans.src_addr[39:32]);
	crc_input.push_back(trans.src_addr[47:40]);

	// EtherType
	crc_input.push_back(trans.eth_type[0]);
	crc_input.push_back(trans.eth_type[1]);

	// Payload in SAME ORDER as transmitted
	for (int i = trans.payload.size()-1; i >= 0; i--) begin
    	crc_input.push_back(trans.payload[i]);
	end

	// Ethernet minimum payload padding
	if (trans.payload.size() < 46) begin
    	for (int i = 0; i < (46 - trans.payload.size()); i++) begin
        	crc_input.push_back(8'h00);
    	end
	end

	// foreach(crc_input[i]) begin
    //     crc_input[i] = {crc_input[i][3:0], crc_input[i][7:4]};
    // end



	fcs_crc = calc_crc32(crc_input); 
	trans.reg_write_data = fcs_crc;
	item_derived_port.write(trans);
    // eth_rx_vif.phy_rx_ctl 		<=  1;

	repeat (7) send_byte(8'h55); // preamble
	send_byte(8'hD5);            // SFD
	// Step.3: Send Destination Address (6 Bytes)
	send_byte(trans.dest_addr[7:0]);            // 
	send_byte(trans.dest_addr[15:8]);            // 
	send_byte(trans.dest_addr[23:16]);            // 
	send_byte(trans.dest_addr[31:24]);            // 
	send_byte(trans.dest_addr[39:32]);            // 
	send_byte(trans.dest_addr[47:40]);            // 

	// Step.3: Send Source Address (6 Bytes)
	send_byte(trans.src_addr [7:0]);            // 
	send_byte(trans.src_addr [15:8]);            // 
	send_byte(trans.src_addr [23:16]);            // 
	send_byte(trans.src_addr [31:24]);            // 
	send_byte(trans.src_addr [39:32]);            // 
	send_byte(trans.src_addr [47:40]);            // 
	// Step.4: Send Ethernet Type (2 Bytes)
	send_byte(trans.eth_type[0]);            // 
	send_byte(trans.eth_type[1]);            // 
	// Step.5: Send Ethernet Frame (2 Bytes)
	frame_size = trans.payload.size();
	if (frame_size < 46) begin
		padding_bytes_size = 46 - frame_size;
	end
	`uvm_info("DEBUG", $sformatf("Payload size in rx driver %0d", frame_size), UVM_LOW)
	while (frame_size > 0) begin
		send_byte(trans.payload[frame_size -1]);            // 
		frame_size = frame_size -1;
	end
	while (padding_bytes_size > 0) begin
		send_byte('d0);            // 
		padding_bytes_size = padding_bytes_size -1;
	end
	
	// Step.6: Send FCS (4 Bytes)
	//  debug
    `uvm_info(get_type_name(),
      $sformatf("FCS Captured data: 0x%0h", fcs_crc), UVM_LOW)
	send_byte(fcs_crc[7:0]);            //
	send_byte(fcs_crc[15:8]);            // 
	send_byte(fcs_crc[23:16]);            // 
	send_byte(fcs_crc[31:24]);            // 
	// send_byte({fcs_crc[3:0],   fcs_crc[7:4]});
	// send_byte({fcs_crc[11:8],  fcs_crc[15:12]});
	// send_byte({fcs_crc[19:16], fcs_crc[23:20]});
	// send_byte({fcs_crc[27:24], fcs_crc[31:28]});
	// send_byte(8'hFF);
	// send_byte(8'hFF);
	// send_byte(8'hFF);
	// send_byte(8'hFF);
	 @(negedge eth_rx_vif.phy_rx_clk);
    eth_rx_vif.phy_rx_ctl <= 1'b0;
    eth_rx_vif.phy_rxd    <= 4'h0;

    @(posedge eth_rx_vif.phy_rx_clk);
    eth_rx_vif.phy_rx_ctl <= 1'b0;
    eth_rx_vif.phy_rxd    <= 4'h0;
	// send_byte(8'h0);            //

    @(negedge eth_rx_vif.phy_rx_clk);
	eth_rx_vif.phy_rxd    <= 'd0;
		// MSB nibble (posedge)
	@(posedge eth_rx_vif.phy_rx_clk);
	eth_rx_vif.phy_rxd    <= 'd0;

	wait (eth_rx_vif.rx_axis_tlast_o  == 1);
	wait (eth_rx_vif.rx_axis_tvalid_o  == 1);
	#2;
	eth_rx_vif.rx_axis_tready_i 		<=  0;
	@(negedge eth_rx_vif.clk_i);
	repeat (10) @(negedge eth_rx_vif.clk_i);
	`uvm_info(get_type_name(), "End of drive_transfer task", UVM_LOW)
endtask : drive_transfer

task eth_rx_driver::regs_config (eth_rx_transaction trans);
	eth_rx_vif.reg_bus_addr_i 		<=  trans.reg_addr;
	eth_rx_vif.reg_bus_write_i 		<=  trans.reg_write;
	eth_rx_vif.reg_bus_wdata_i 		<=  trans.reg_write_data;
	eth_rx_vif.reg_bus_valid_i 		<=  trans.reg_valid;
	eth_rx_vif.reg_bus_wstrb_i 		<=  trans.reg_wstrb;
	#8;
endtask : regs_config


