//=============================================================================
// ETHERNET RGMII PACKAGE
//=============================================================================
// This package defines AXI interface parameters for RGMII-related modules.
//
// CONTENTS:
//   - AXI bus width parameters
//   - Type definitions for AXI signals
//
// NOTE: These parameters are for potential AXI memory-mapped interfaces
//       The main RGMII data path uses GMII/AXI-Stream, not AXI.
//=============================================================================

package eth_rgmii_pkg;

  //===========================================================================
  // AXI BUS PARAMETERS
  //===========================================================================
  /// AXI address bus width (32 bits for 4GB address space)
  parameter int unsigned AXI_ADDR_WIDTH = 32;
  /// AXI data bus width (64 bits = 8 bytes per transfer)
  parameter int unsigned AXI_DATA_WIDTH = 64;
  /// AXI transaction ID width (8 bits = 256 unique transactions)
  parameter int unsigned AXI_ID_WIDTH   = 8;
  /// AXI user sideband width (8 bits for custom signals)
  parameter int unsigned AXI_USER_WIDTH = 8;

  /// AXI byte strobe width (8 bytes for 64-bit data)
  localparam int unsigned AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

  //===========================================================================
  // AXI TYPE DEFINITIONS
  //===========================================================================
  typedef logic [AXI_ID_WIDTH-1:0]   id_t;    // Transaction ID
  typedef logic [AXI_ADDR_WIDTH-1:0] addr_t;  // Address
  typedef logic [AXI_DATA_WIDTH-1:0] data_t;  // Data
  typedef logic [AXI_STRB_WIDTH-1:0] strb_t;  // Byte strobe
  typedef logic [AXI_USER_WIDTH-1:0] user_t;  // User sideband

endpackage : eth_rgmii_pkg
