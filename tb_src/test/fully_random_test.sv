/*-------------------------------------------------------------------------
File name   : fully_random_test.sv
Project     : SPI VIP
---------------------------------------------------------------------------*/
import wb_pkg::fully_random_seq;
 import wb_pkg::go_busy_seq;
import wb_pkg::rx_read_seq;
import eth_rx_pkg::slave_seq;
import clk_pkg::clk_rst_reset_seq;
class fully_random_test extends uvm_test;

    `uvm_component_utils(fully_random_test)
    fully_random_seq wb_seq;
    go_busy_seq go_seq;
    clk_rst_reset_seq rst_seq;
    rx_read_seq read_seq;
    slave_seq slv_seq;
    top_config cfg;
    top_env env;
    uvm_event ev;
    uvm_event ev2;
    //ral_model regmodel;
    virtual wb_interface vif;
	virtual eth_rx_interface eth_rx_vif;
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);

endclass:fully_random_test

function void fully_random_test::build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual wb_interface)::get(this,"","vif",vif))begin
        `uvm_fatal("TEST","No virtual interface is set for this instance")
    end
	if(!uvm_config_db #(virtual eth_rx_interface)::get(this,"","eth_rx_vif",eth_rx_vif))begin
        `uvm_fatal("TEST","No virtual interface is set for this instance")
    end
    //Pass on the handle to the children
    uvm_config_db#(virtual wb_interface)::set(null,"*","vif",vif);
    uvm_config_db#(virtual eth_rx_interface)::set(null,"*","eth_rx_vif",eth_rx_vif);
    wb_seq = fully_random_seq::type_id::create("wb_seq");
    go_seq = go_busy_seq::type_id::create("go_seq");
    rst_seq = clk_rst_reset_seq::type_id::create("rst_seq");   
    read_seq = rx_read_seq::type_id::create("read_seq");
    slv_seq = slave_seq::type_id::create("slv_seq");
    env = top_env::type_id::create("env",this);
    //regmodel = ral_model::type_id::create("regmodel",this);
    //cfg.regmodel = this.regmodel;
    //uvm_config_db#(apb_wdt_config)::set(null,"uvm_test_top","cfg",cfg);
    uvm_config_db#(top_config)::set(null, "uvm_test_top", "cfg", cfg);  
endfunction:build_phase
int data;
int i=0;
task fully_random_test::run_phase(uvm_phase phase);

    repeat(256) begin
        `uvm_info(get_type_name(),$sformatf("Starting test no %d ", i),UVM_NONE)
        phase.raise_objection(this);  
        ev = uvm_event_pool::get_global("ev_ab");
        ev2 = uvm_event_pool::get_global("ev2_seq2mon");
        begin
            wb_seq.start(env.wb.agents[0].sqr);

            // uvm_resource_db#(int)::set("uvm_test_top.env.*", "wb_data", wb_seq.req.wb_data);
            // TO DO: remove later
            data =  wb_seq.req.wb_data;
            uvm_config_db#(int)::set(null, "*", "wb_data",data);

                `uvm_info(get_type_name(), $sformatf("RDB: wb_data = %01h", data), UVM_LOW)
        
                //event that control data is set
                `uvm_info(get_type_name(),$sformatf(" Before triggering the event"),UVM_LOW)
                ev2.trigger();
                `uvm_info(get_type_name(),$sformatf(" After triggering the event"),UVM_LOW)
            go_seq.start(env.wb.agents[0].sqr);

        end
        begin
            fork
                slv_seq.start(env.spi.agents[0].sqr);


                begin
                    `uvm_info(get_type_name(),$sformatf(" waiting for the event trigger"),UVM_LOW)
                
                    ev.wait_trigger;
                
                    `uvm_info(get_type_name(),$sformatf(" event got triggerd"),UVM_LOW)
                    read_seq.start(env.wb.agents[0].sqr);
                end
            join
            
            
        end

        rst_seq.start(env.clk.clk_agnt.sequencer);
        phase.phase_done.set_drain_time(this,500);
        
        phase.drop_objection(this);
        `uvm_info(get_type_name(),$sformatf("Finishing test no %d ", i),UVM_NONE)
        i++;
    end
endtask


