
package eth_tx_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"


    //////////////////////////////////////////////////
    //              Include files                   //
    //////////////////////////////////////////////////
    // Parameters
    

    typedef class eth_tx_agent;
    typedef class eth_tx_driver;
    // typedef class eth_tx_environment;
    typedef class eth_tx_monitor;
    typedef class eth_tx_sequencer;
    //typedef class eth_tx_sequence_lib;
    typedef class eth_tx_transaction;
    // typedef class eth_ref_model;
    // typedef class eth_scoreboard;
    



    `include "eth_tx_transaction.sv"        // transaction class
    `include "eth_tx_sequencer.sv"            // sequencer class
    `include "eth_tx_driver.sv"               // driver class
    `include "eth_tx_monitor.sv"              // drivmonitorer class
    `include "eth_tx_agent.sv"                // agent class
    // `include "eth_scoreboard.sv"           // scoreboard Class
    // `include "eth_environment.sv"          // environment class
    `include "eth_tx_sequence_lib.sv"             // sequence class
    // `include "eth_ref_model.sv"            // reference model for expected packet
   
    
endpackage