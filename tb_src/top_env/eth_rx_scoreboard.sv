/*-------------------------------------------------------------------------
File name   : eth_rx_scoreboard.sv
Project     : Ethernet VIP
---------------------------------------------------------------------------*/
import eth_rx_pkg::eth_rx_transaction;

`uvm_analysis_imp_decl(_eth_rx_drv)
`uvm_analysis_imp_decl(_eth_rx_mon)

class eth_rx_scoreboard extends uvm_scoreboard;
	int i=0;
  `uvm_component_utils(eth_rx_scoreboard)

	// Analysis imports
	uvm_analysis_imp_eth_rx_mon#(eth_rx_transaction, eth_rx_scoreboard) eth_rx_mon_export;
	uvm_analysis_imp_eth_rx_drv#(eth_rx_transaction, eth_rx_scoreboard) eth_rx_drv_export;
	// tlm fifos
	uvm_tlm_fifo #(eth_rx_transaction) eth_rx_outfifo;
	uvm_tlm_fifo #(eth_rx_transaction) eth_rx_expfifo;
	// temporary memories
	bit [31:0] wb_mem [0:255];
	bit [31:0] eth_rx_mem [0:255];
	//int num_pass, num_fail;
	
	function new(string name, uvm_component parent);
		super.new(name,parent);
		eth_rx_drv_export = new("eth_rx_drv_export", this);
		eth_rx_mon_export = new("eth_rx_mon_export", this);

		eth_rx_outfifo = new("eth_rx_outfifo", this);
		eth_rx_expfifo = new("eth_rx_expfifo", this);
	endfunction
	
	// write functions
	extern function void write_eth_rx_mon(eth_rx_transaction t);
	extern function void write_eth_rx_drv(eth_rx_transaction t);
	extern function void report_phase(uvm_phase phase);
	extern virtual task run_phase(uvm_phase phase);
	extern virtual task compare(bit [63:0] expect_data,eth_rx_transaction tr2);
endclass:eth_rx_scoreboard

	//Actual Data
  function void eth_rx_scoreboard::write_eth_rx_mon(eth_rx_transaction t);
	`uvm_info(get_type_name(), $sformatf("write eth_rx_mon: \n%s",t.sprint()), UVM_LOW)
	void'(eth_rx_outfifo.try_put(t));
  endfunction 
		//Expected Data
  function void eth_rx_scoreboard::write_eth_rx_drv(eth_rx_transaction t);
	`uvm_info(get_type_name(), $sformatf("write eth_rx_drv: \n%s",t.sprint()), UVM_LOW)
	void'(eth_rx_expfifo.try_put(t));
  endfunction
	 task eth_rx_scoreboard::compare(bit [63:0] expect_data, eth_rx_transaction tr2);
		
			if (tr2.rx_axis_tdata_o == expect_data) begin
				`uvm_info (get_type_name(),$sformatf("\nData Match [Pass] \nExpected 0x%h \nActual   0x%h", expect_data, tr2.rx_axis_tdata_o),UVM_NONE)
			end
			else begin
				`uvm_error (get_type_name(),$sformatf("\nData MisMatch [Fail] \nExpected: 0x%h \nActual: 0x%h", expect_data, tr2.rx_axis_tdata_o))
			end
		
	 endtask
	 
  task eth_rx_scoreboard::run_phase(uvm_phase phase);
	
	eth_rx_transaction eth_rx_out_tr, eth_rx_exp_tr ;
	super.run_phase(phase);
	`uvm_info(get_type_name(),"eth_rx_scoreboard run phase",UVM_NONE)
	forever begin
		bit [63:0] expected_data_1;
		bit [63:0] expected_data_2;
		bit [63:0] expected_data;
		int frame_size;
		`uvm_info(get_type_name(),"01 eth rx expected get ",UVM_NONE)
		eth_rx_expfifo.get(eth_rx_exp_tr); // Ethernet trans collected in driver
		`uvm_info("DEBUG", $sformatf("expected data %0h", eth_rx_exp_tr.src_addr), UVM_LOW)
		`uvm_info(get_type_name(),"02 eth rx actual get",UVM_NONE)
		eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
		`uvm_info("DEBUG", $sformatf("actual data %0h", eth_rx_out_tr.rx_axis_tdata_o), UVM_LOW)
		frame_size = eth_rx_exp_tr.payload.size();
		expected_data_1 = {eth_rx_exp_tr.src_addr[15:0], eth_rx_exp_tr.dest_addr};	//6 bytes of src addr and 2 bytes of dest addr
		`uvm_info("DEBUG", $sformatf("expected data %0h", expected_data_1), UVM_LOW)
		compare(expected_data_1, eth_rx_out_tr);
		eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
		expected_data_2 = {eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1], eth_rx_exp_tr.eth_type[1], eth_rx_exp_tr.eth_type[0], eth_rx_exp_tr.src_addr[47:16]};	//4 bytes of desr addr, 2 bytes of dest addr and 2 bytes of payload
		compare(expected_data_2, eth_rx_out_tr);
		eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
		frame_size = frame_size -2;
		while (eth_rx_out_tr.tlast == 0) begin
			while (frame_size > 8) begin
			`uvm_info(get_type_name(),"eth_rx_scoreboard frame_size while loop begin",UVM_NONE)
				expected_data = {eth_rx_exp_tr.payload[frame_size-8], eth_rx_exp_tr.payload[frame_size-7], eth_rx_exp_tr.payload[frame_size-6]
				, eth_rx_exp_tr.payload[frame_size-5], eth_rx_exp_tr.payload[frame_size-4], eth_rx_exp_tr.payload[frame_size-3]
				,eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1]};	
				frame_size = frame_size -8;
				`uvm_info("DEBUG", $sformatf("frame size %0h", frame_size), UVM_LOW)
				compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
			end
				`uvm_info("DEBUG", $sformatf("frame size %0h", frame_size), UVM_LOW)
			if (frame_size == 8) begin
				expected_data = {eth_rx_exp_tr.payload[frame_size-8], eth_rx_exp_tr.payload[frame_size-7], eth_rx_exp_tr.payload[frame_size-6], eth_rx_exp_tr.payload[frame_size-5],
				eth_rx_exp_tr.payload[frame_size-4], eth_rx_exp_tr.payload[frame_size-3], eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1]};
				compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
				// expected_data ={eth_rx_exp_tr.reg_write_data[7:0],eth_rx_exp_tr.reg_write_data[15:8],eth_rx_exp_tr.reg_write_data[23:16], eth_rx_exp_tr.reg_write_data[31:24]};
				// compare(expected_data, eth_rx_out_tr);
				expected_data ={eth_rx_exp_tr.reg_write_data[31:24],eth_rx_exp_tr.reg_write_data[23:16],eth_rx_exp_tr.reg_write_data[15:8], eth_rx_exp_tr.reg_write_data[7:0]};
				compare(expected_data, eth_rx_out_tr);
			end
			else if (frame_size == 7) begin
				expected_data = {eth_rx_exp_tr.reg_write_data[7:0], eth_rx_exp_tr.payload[frame_size-7], eth_rx_exp_tr.payload[frame_size-6], eth_rx_exp_tr.payload[frame_size-5],
				eth_rx_exp_tr.payload[frame_size-4], eth_rx_exp_tr.payload[frame_size-3], eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1]};
				compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
				expected_data ={eth_rx_exp_tr.reg_write_data[31:24],eth_rx_exp_tr.reg_write_data[23:16],eth_rx_exp_tr.reg_write_data[15:8]};
				compare(expected_data, eth_rx_out_tr);
			end
			else if (frame_size == 6) begin
				expected_data = {eth_rx_exp_tr.reg_write_data[15:8], eth_rx_exp_tr.reg_write_data[7:0], eth_rx_exp_tr.payload[frame_size-6], eth_rx_exp_tr.payload[frame_size-5],
				eth_rx_exp_tr.payload[frame_size-4], eth_rx_exp_tr.payload[frame_size-3], eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1]};
				`uvm_info("DEBUG", $sformatf("frame size  expected data%0h", frame_size), UVM_LOW)
				compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
				expected_data ={eth_rx_exp_tr.reg_write_data[31:24],eth_rx_exp_tr.reg_write_data[23:16]};
				// compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor

				// `uvm_info(get_type_name(),"eth_rx_scoreboard frame_size while loop end",UVM_NONE)
			end
			else if (frame_size == 5) begin
				expected_data ={eth_rx_exp_tr.reg_write_data[31:24], eth_rx_exp_tr.reg_write_data[23:16], eth_rx_exp_tr.reg_write_data[15:8], eth_rx_exp_tr.payload[frame_size-5], 
			eth_rx_exp_tr.payload[frame_size-4], eth_rx_exp_tr.payload[frame_size-3], eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1]};
				compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
				expected_data ={eth_rx_exp_tr.reg_write_data[7:0]};
				// compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
			end
			else if (frame_size == 4) begin
				expected_data ={eth_rx_exp_tr.reg_write_data[31:24],eth_rx_exp_tr.reg_write_data[23:16], eth_rx_exp_tr.reg_write_data[15:8], eth_rx_exp_tr.reg_write_data[7:0], eth_rx_exp_tr.payload[frame_size-4], 
				eth_rx_exp_tr.payload[frame_size-3], eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1]};
				compare(expected_data, eth_rx_out_tr);
				`uvm_info("DEBUG", $sformatf("frame size %0h", frame_size), UVM_LOW)
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
			end
			else if (frame_size == 3) begin
				expected_data ={eth_rx_exp_tr.reg_write_data[31:24],eth_rx_exp_tr.reg_write_data[23:16], eth_rx_exp_tr.reg_write_data[15:8], eth_rx_exp_tr.reg_write_data[7:0], eth_rx_exp_tr.payload[frame_size-3], 
				eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1]};
				compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
			end
			else if (frame_size == 2) begin
				expected_data ={eth_rx_exp_tr.reg_write_data[31:24],eth_rx_exp_tr.reg_write_data[23:16], eth_rx_exp_tr.reg_write_data[15:8], eth_rx_exp_tr.reg_write_data[7:0], 
				eth_rx_exp_tr.payload[frame_size-2], eth_rx_exp_tr.payload[frame_size-1]};
				compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
			end
			else if (frame_size == 1) begin
				expected_data ={eth_rx_exp_tr.reg_write_data[31:24],eth_rx_exp_tr.reg_write_data[23:16], eth_rx_exp_tr.reg_write_data[15:8], eth_rx_exp_tr.reg_write_data[7:0], 
				eth_rx_exp_tr.payload[frame_size-1]};
				compare(expected_data, eth_rx_out_tr);
				eth_rx_outfifo.get(eth_rx_out_tr); // Ethernet trans collected in monitor
			end
		end
		// debug
		// 	`uvm_info(get_name(), $sformatf("After compare"), UVM_LOW)
		
	// 	else begin
	// 		`uvm_info(get_type_name(), $sformatf("write wb_mon: wb_outfifo is not empty after get %0d ",j), UVM_LOW) 
	// 	end
	//     `uvm_info(get_type_name(), $sformatf("wb_out_tr: \n%s",wb_out_tr.sprint()), UVM_LOW) 


	end


  endtask   

//   function void eth_rx_scoreboard::report_phase(uvm_phase phase);
// 	//`uvm_info(get_type_name(), $sformatf("Report: Number of tests passed: %0d", num_pass), UVM_LOW);
//   endfunction
  

  function void eth_rx_scoreboard::report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
     svr = uvm_report_server::get_server();
//`uvm_info(get_type_name(), "----------TEST PASS------------------", UVM_NONE)
if(svr.get_severity_count(UVM_FATAL)+svr.get_severity_count(UVM_ERROR)>0)
 begin
        `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
        `uvm_info(get_type_name(), "----            TEST FAIL          ----", UVM_NONE)
        `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     end
   else
 begin
        `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
        `uvm_info(get_type_name(), "----           TEST PASS           ----", UVM_NONE)
        `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     end
 endfunction