

//=============================================================================
// ETHERNET TOP-LEVEL PACKAGE
//=============================================================================
// This package defines default types and parameters for the Ethernet IP.
//
// CONTENTS:
//   - AXI-Stream interface parameters and types (64-bit default)
//   - REG_BUS interface parameters and types (32-bit, 4-bit address)
//   - Default struct definitions for request/response signals
//
// USAGE:
//   - Used by eth_top module to define default parameter values
//   - Provides consistent type definitions across the Ethernet subsystem
//=============================================================================

`include "axi_stream/assign.svh"
`include "axi_stream/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

package eth_top_pkg;

  //===========================================================================
  // AXI-STREAM PARAMETERS (System-Side Data Interface)
  //===========================================================================
  /// AXI-Stream data width (64 bits = 8 bytes per clock cycle)
  parameter int unsigned DataWidth = 64;
  /// AXI-Stream ID width (0 = not used, for stream routing)
  parameter int unsigned IdWidth = 1;
  /// AXI-Stream destination width (0 = not used, for routing)
  parameter int unsigned DestWidth = 1;
  /// AXI-Stream user sideband width (1 bit for error indication)
  parameter int unsigned UserWidth = 1;

  //===========================================================================
  // AXI-STREAM TYPE DEFINITIONS
  //===========================================================================
  // Define individual signal types for AXI-Stream interface
  typedef logic [DataWidth-1:0]   axis_tdata_t;    // Data bus (64 bits)
  typedef logic [DataWidth/8-1:0] axis_tstrb_t;    // Byte strobe (8 bits)
  typedef logic [DataWidth/8-1:0] axis_tkeep_t;    // Byte keep/valid (8 bits)
  typedef logic [IdWidth-1:0]     axis_tid_t;      // Stream ID (unused)
  typedef logic [DestWidth-1:0]   axis_tdest_t;    // Destination (unused)
  typedef logic [UserWidth-1:0]   axis_tuser_t;    // User sideband (1 bit)

  // Generate complete AXI-Stream typedef (creates s_req_t and s_rsp_t structs)
  // s_req_t contains: tdata, tstrb, tkeep, tlast, tid, tdest, tuser, tvalid
  // s_rsp_t contains: tready
  `AXI_STREAM_TYPEDEF_ALL(s, axis_tdata_t, axis_tstrb_t, axis_tkeep_t, axis_tid_t, axis_tdest_t, axis_tuser_t)

  //===========================================================================
  // REGISTER BUS PARAMETERS (Configuration Interface)
  //===========================================================================
  /// Register bus address width (4 bits = 16 addressable registers)
  parameter int AW_REGBUS = 4;
  /// Register bus data width (32 bits)
  localparam int DW_REGBUS = 32;
  /// Register bus byte strobe width (4 bits = 4 bytes)
  localparam int unsigned STRB_WIDTH = DW_REGBUS/8;

  //===========================================================================
  // REGISTER BUS TYPE DEFINITIONS
  //===========================================================================
  // Define individual signal types for REG_BUS interface
  typedef logic [AW_REGBUS-1:0]   reg_bus_addr_t;  // Address bus (4 bits)
  typedef logic [DW_REGBUS-1:0]   reg_bus_data_t;  // Data bus (32 bits)
  typedef logic [STRB_WIDTH-1:0]  reg_bus_strb_t;  // Byte strobe (4 bits)
  
  // Generate complete REG_BUS typedef (creates reg_bus_req_t and reg_bus_rsp_t structs)
  // reg_bus_req_t contains: addr, write, wdata, wstrb, valid
  // reg_bus_rsp_t contains: rdata, ready, error
  `REG_BUS_TYPEDEF_ALL(reg_bus, reg_bus_addr_t, reg_bus_data_t, reg_bus_strb_t)

endpackage : eth_top_pkg
