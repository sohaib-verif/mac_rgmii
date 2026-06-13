/*-------------------------------------------------------------------------
File name   : eth_rx_pkg.sv
Project     : SPI UVC
---------------------------------------------------------------------------*/

package eth_rx_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    //////////////////////////////////////////////////
    //        UVM Class Forward Declarations        //
    //////////////////////////////////////////////////
    
    typedef class eth_rx_agent;
    typedef class eth_rx_driver;
    typedef class eth_rx_env;
    typedef class eth_rx_monitor;
    typedef class eth_rx_sequencer;
    typedef class eth_rx_transaction;
    
    //////////////////////////////////////////////////
    //              Include files                   //
    //////////////////////////////////////////////////
    `include "eth_rx_transaction.sv"
    `include "eth_rx_config.sv"
    
    `include "eth_rx_monitor.sv"
    `include "eth_rx_sequencer.sv"
    `include "eth_rx_driver.sv"
    `include "eth_rx_agent.sv"
    
    `include "eth_rx_env.sv"
    
    `include "eth_rx_seq_lib.sv"
    
    endpackage
    