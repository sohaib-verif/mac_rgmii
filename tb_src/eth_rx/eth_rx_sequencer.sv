/*-------------------------------------------------------------------------
File name   : eth_rx_sequencer.sv
Project     : SPI UVC
---------------------------------------------------------------------------*/

class eth_rx_sequencer extends uvm_sequencer #(eth_rx_transaction);
    `uvm_component_utils(eth_rx_sequencer)
      // new - constructor
      function new (string name, uvm_component parent);
        super.new(name, parent);
      endfunction : new
    
endclass