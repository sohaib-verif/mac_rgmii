/*-------------------------------------------------------------------------
File name   : pt_seq_lib.sv
Project     : SPI UVC
---------------------------------------------------------------------------*/

    // Add more classes of sequences below
class eth_rx_basic_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_basic_seq)

    function new(string name = "eth_rx_basic_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h2070;})

        `uvm_do_with(req,{req.regs_config_seq == 0;  req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;   req.payload.size() == 64;
        req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;})
    endtask

endclass:eth_rx_basic_seq

class eth_rx_64B_pkt_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_64B_pkt_seq)

    function new(string name = "eth_rx_64B_pkt_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h01_2070;})

        `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;   req.payload.size() == 50;
        req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;
        foreach (req.payload[i]) {
        req.payload[i]   == (i + 1);
    }})
    endtask

endclass:eth_rx_64B_pkt_seq

class eth_rx_1000B_pkt_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_1000B_pkt_seq)

    function new(string name = "eth_rx_1000B_pkt_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h2070;})

        `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;   req.payload.size() == 982;
        req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;})
    endtask

endclass:eth_rx_1000B_pkt_seq

class eth_rx_40B_pkt_padding_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_40B_pkt_padding_seq)

    function new(string name = "eth_rx_40B_pkt_padding_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h2070;})

        `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;   req.payload.size() == 22;
        req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;})
    endtask

endclass:eth_rx_40B_pkt_padding_seq

class eth_rx_1518_byte_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_1518_byte_seq)

    function new(string name = "eth_rx_1518_byte_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h2070;})

        `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;   req.payload.size() == 1500;
        req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;})
    endtask

endclass:eth_rx_1518_byte_seq

class eth_rx_multiple_packet_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_multiple_packet_seq)

    function new(string name = "eth_rx_multiple_packet_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h2070;})
        repeat (10) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;  
            req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;})
        end
        
    endtask

endclass:eth_rx_multiple_packet_seq




// class eth_rx_basic_seq extends uvm_sequence#(eth_rx_transaction);

//     `uvm_object_utils(eth_rx_basic_seq)

//     function new(string name = "eth_rx_basic_seq");
//         super.new(name);
//     endfunction
//     task body();  
//         `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
//         req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

//         `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
//         req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

//         `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
//         req.reg_wstrb == 4'hf; req.reg_write_data == 32'h2070;})

//         `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;   req.payload.size() == 64;
//         req.reg_wstrb == 4'hf; req.reg_write_data == 32'h2070;})
//     endtask

// endclass:eth_rx_basic_seq


class eth_rx_promiscous_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_promiscous_seq)

    function new(string name = "eth_rx_promiscous_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h01_2070;})
        repeat (1) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;})
        end
        
    endtask

endclass:eth_rx_promiscous_seq


class eth_rx_disable_promiscous_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_disable_promiscous_seq)

    function new(string name = "eth_rx_disable_promiscous_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h00_2070;})
        repeat (1) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;})
        end
        
    endtask

endclass:eth_rx_disable_promiscous_seq

class eth_rx_2000_byte_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_2000_byte_seq)

    function new(string name = "eth_rx_2000_byte_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h00_2070;})
        repeat (1) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2; req.payload.size() == 1982;  
            req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;})
        end
        
    endtask

endclass:eth_rx_2000_byte_seq

class eth_rx_1520_byte_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_1520_byte_seq)

    function new(string name = "eth_rx_1520_byte_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h00_2070;})
        repeat (1) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2; req.payload.size() == 1502;  
            req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;})
        end
        
    endtask

endclass:eth_rx_1520_byte_seq


class eth_rx_crc_err_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_crc_err_seq)

    function new(string name = "eth_rx_crc_err_seq");
        super.new(name);
    endfunction
    task body();  
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h00_2070;})
        repeat (1) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2; req.payload.size() == 1982; 
            req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'h2070_9800_1032;})
        end
        
    endtask

endclass:eth_rx_crc_err_seq


class eth_rx_broadcast_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_broadcast_seq)

    function new(string name = "eth_rx_broadcast_seq");
        super.new(name);
    endfunction

    task body();        
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h00_2070;})
       
       repeat (1) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2; req.payload.size() == 46; 
            req.src_addr == 48'h2070_9800_1032;     req.dest_addr == 48'hFFFF_FFFF_FFFF;})
        end
                
    endtask

endclass: eth_rx_broadcast_seq


class eth_rx_multicast_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_multicast_seq)

    function new(string name = "eth_rx_multicast_seq");
        super.new(name);
    endfunction

    task body();        
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h9800_1032;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h00_2070;})
       
       repeat (1) begin
            `uvm_do_with(req, {
                req.regs_config_seq == 0;       // Data transfer
                req.dest_addr [47:40] == 8'h01;
                req.dest_addr [39:32] == 8'h0; req.dest_addr [31:24] == 8'h5e;
                
                // *** MULTICAST: Destination MAC = 01:xx:xx:xx:xx:xx ***
                // First byte LSB must be 1 (indicates multicast)
                // req.dest_addr[0] == 8'h01;                        // First byte with LSB=1
                // req.dest_addr[1] == 8'h00;                        // Standard IANA range
                // req.dest_addr[2] == 8'h5E;                        // Standard IANA range
                // req.dest_addr[3] inside {[8'h00 : 8'h7F]};        // Vary the group address
                // req.dest_addr[4] == 8'h12;
                // req.dest_addr[5] == 8'h34;
                
                req.eth_type[0] == 8'h00;
                req.eth_type[1] == 8'hE2;
                req.payload.size() == 46;
            })
        end
                
    endtask

endclass: eth_rx_multicast_seq


class eth_rx_reg_config_seq extends uvm_sequence#(eth_rx_transaction);

    `uvm_object_utils(eth_rx_reg_config_seq)

    function new(string name = "eth_rx_reg_config_seq");
        super.new(name);
    endfunction
    task body();  
    repeat(2000) begin
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data[16] == 1;})

        `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;   req.payload.size() == 46;})
    end


        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        // req.reg_wstrb == 4'hf; req.reg_write_data == 32'hFFFF_FFFF;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        // req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        // req.reg_wstrb == 4'hf; req.reg_write_data[16] == 32'hFFFF_FFFF;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        // req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        // req.reg_wstrb == 4'hf; req.reg_write_data == 32'h0000_0000;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        // req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        // req.reg_wstrb == 4'hf; req.reg_write_data[16] == 32'h0000_0000;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        // req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 1;   req.reg_valid == 1;  
        // req.reg_wstrb == 4'hf; req.reg_write_data == 32'hFFFF_FFFF;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 0;  req.reg_write == 0;   req.reg_valid == 0;  
        // req.reg_wstrb == 4'h0; req.reg_write_data == 32'h0;})

        // `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        // req.reg_wstrb == 4'hf; req.reg_write_data[16] == 32'hFFFF_FFFF;})

        // `uvm_do_with(req,{req.regs_config_seq == 0; req.eth_type[0] == 8'h00;   req.eth_type[1] == 8'hE2;   req.payload.size() == 46;})
    endtask

endclass:eth_rx_reg_config_seq

// // 8. REGISTER CONFIGURATION CONDITION COVERAGE
// // ============================================================================

class eth_rx_register_condition_coverage_seq extends uvm_sequence#(eth_rx_transaction);
    `uvm_object_utils(eth_rx_register_condition_coverage_seq)

    function new(string name = "eth_rx_register_condition_coverage_seq");
        super.new(name);
    endfunction

    task body();  
        // Test different register configurations for condition paths
        
        // Config 1: Promiscuous mode enabled
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h01_2070;})  // Bit 16 set
        
        repeat (3) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; 
            req.eth_type[0] == 8'h00;   
            req.eth_type[1] == 8'hE2; 
            req.payload.size() == 100;
            req.src_addr == 48'hFFFF_FFFF_FFFF;  // Non-matching address
            req.dest_addr == 48'h5555_5555_5555;  // Non-matching address
            })
        end

        // Config 2: Promiscuous mode disabled
        `uvm_do_with(req,{req.regs_config_seq == 1; req.reg_addr == 4;  req.reg_write == 1;   req.reg_valid == 1;  
        req.reg_wstrb == 4'hf; req.reg_write_data == 32'h00_2070;})  // Bit 16 clear
        
        repeat (3) begin
            `uvm_do_with(req,{req.regs_config_seq == 0; 
            req.eth_type[0] == 8'h00;   
            req.eth_type[1] == 8'hE2; 
            req.payload.size() == 100;
            req.src_addr == 48'hFFFF_FFFF_FFFF;  // Should be filtered
            req.dest_addr == 48'h2070_9800_1032;
            })
        end
    endtask

endclass: eth_rx_register_condition_coverage_seq
