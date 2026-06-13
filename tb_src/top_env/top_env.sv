/*-------------------------------------------------------------------------
File name   : top_env.sv
Project     : SPI VIP
---------------------------------------------------------------------------*/
import eth_rx_pkg::eth_rx_env; 
// import clk_pkg::clk_env; 

class top_env extends uvm_env;

eth_tx_agent eth_tx;
eth_rx_env eth_rx_e;
// clk_env clk;
eth_scoreboard eth_scb;
eth_rx_scoreboard eth_rx_scb;

//coverage_collector cov;
`uvm_component_utils(top_env)

function new(string name, uvm_component parent);
    super.new(name,parent);
endfunction

extern virtual function void build_phase(uvm_phase phase);
extern virtual function void connect_phase(uvm_phase phase);

endclass:top_env

function void top_env::build_phase(uvm_phase phase);


    eth_tx = eth_tx_agent::type_id::create("eth_tx",this);
    eth_rx_e = eth_rx_env::type_id::create("eth_rx_e",this); 
    // clk = clk_env::type_id::create("clk",this); 

    eth_scb = eth_scoreboard::type_id::create("eth_scb",this);
    eth_rx_scb = eth_rx_scoreboard::type_id::create("eth_rx_scb",this);

endfunction

function void top_env::connect_phase(uvm_phase phase);
    eth_tx.eth_mon.dut_pkt_port.connect(eth_scb.dut_pkt_imp);
    eth_rx_e.agents[0].mon.item_collected_port.connect(eth_rx_scb.eth_rx_mon_export);
    eth_rx_e.agents[0].drv.item_derived_port.connect(eth_rx_scb.eth_rx_drv_export);

endfunction
