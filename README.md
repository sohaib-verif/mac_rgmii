Important Note: The rtl is from "rmd, Javaria". I did its UVM Verification. Following are the specs provided by the designer.
# Ethernet IP - Design Notes

**Designer:** rmd, Javaria  
**Date:** 2024

Hey verification team, here's what you need to know about this ethernet design. Keep it simple, test it well.

## What This Does

This is a **Gigabit Ethernet (1000BASE-T) controller** with RGMII interface. It takes packets from the system via AXI-Stream, adds Ethernet framing (preamble, FCS), and spits them out over RGMII. On RX, it does the reverse - receives RGMII, strips framing, filters by MAC address, and outputs clean packets.

**Speed:** 1 Gbps  
**Standard:** IEEE 802.3 (1000BASE-T)  
**Physical:** RGMII (4-bit DDR @ 125 MHz)

## Top Module

`eth_top` is what you instantiate. There's also `eth_top_synth` which is the same thing but with unpacked ports (easier for synthesis tools).

## File Organization

### Synthesizable RTL Files (rtl/)

All files in `rtl/` are synthesizable RTL. Use these for FPGA/ASIC synthesis:

**Top-Level Modules:**
- `eth_top.sv` - Main top module (uses struct interfaces, good for simulation)
- `eth_top_synth.sv` - Synthesis-friendly wrapper (unpacked ports, use this for FPGA/ASIC)

**Core Modules:**
- `framing_top.sv` - Frame processing, MAC filtering, register interface
- `eth_mac_1g.sv` - 1G Ethernet MAC core
- `eth_mac_1g_rgmii.sv` - MAC + RGMII integration
- `eth_mac_1g_rgmii_fifo.sv` - FIFO buffering for MAC
- `rgmii_soc.sv` - RGMII system-on-chip wrapper
- `rgmii_core.sv` - RGMII core logic
- `rgmii_phy_if.sv` - RGMII PHY interface with DDR primitives
- `axis_gmii_tx.sv` - AXI-Stream to GMII TX converter
- `axis_gmii_rx.sv` - GMII RX to AXI-Stream converter

**Primitives/Utilities:**
- `iddr.sv` - Input DDR primitive (for RGMII RX)
- `oddr.sv` - Output DDR primitive (for RGMII TX)
- `ssio_ddr_in.sv` - DDR input buffer
- `rgmii_lfsr.sv` - LFSR for scrambling (if used)

**Packages (Type Definitions):**
- `eth_top_pkg.sv` - Top-level package (AXI-Stream, REG_BUS types)
- `eth_framing_reg_pkg.sv` - Register map definitions (auto-generated)
- `eth_rgmii_pkg.sv` - RGMII-related types

**Register Interface:**
- `eth_framing_reg_top.sv` - Register file implementation (auto-generated)

**For Synthesis:** Use `eth_top_synth` - it has unpacked ports that synthesis tools handle better.

### Test Infrastructure Files (tb/)

These are **NOT synthesizable** - simulation only:

- `tb/eth_tb.sv` - Main testbench (loopback test with TX/RX modules)

**Testbench Features:**
- AXI-Stream master/slave drivers (with randomization)
- REG_BUS drivers for configuration
- Clock generation (125 MHz, 125 MHz 90°, 200 MHz)
- Loopback connection (TX DUT → RGMII → RX DUT)
- 5 test scenarios (unicast, broadcast, multicast, filtering, promiscuous)

**Note:** Testbench instantiates `eth_top_synth` (the synthesis wrapper) because it's easier to connect individual signals.

## ASIC Implementation (Verification Focus)

**⚠️ ASIC-ONLY VERIFICATION:** This design is verified for ASIC implementation only. All primitives use `TARGET="GENERIC"` fallbacks that are ASIC-synthesizable.

**Key Points:**
- ✅ All DDR primitives use register-based implementations (no FPGA primitives)
- ✅ No IDELAY used (ASIC timing handled by synthesis constraints)
- ✅ No FPGA clock buffers (BUFG/BUFR/BUFIO) used
- ✅ Requires `tech_cells_generic` dependency (for `tc_clk_mux2` in ODDR)

The design uses parameterized primitives with fallbacks for different targets. For ASIC verification, we use `TARGET="GENERIC"` for all primitives (this is the default).

### Primitive Fallbacks

All DDR primitives have a `TARGET` parameter that selects the implementation:

**1. IDDR (Input DDR) - `rtl/iddr.sv`**
- **TARGET="XILINX"**: Uses Xilinx IDDR/IDDR2 primitives (FPGA-only)
  - Requires: Xilinx 7-series, Ultrascale, or Spartan-6
  - IODDR_STYLE: "IODDR" (7-series, Ultrascale) or "IODDR2" (Spartan-6)
- **TARGET="ALTERA"**: Uses Altera altddio_in (FPGA-only)
  - Requires: Intel/Altera FPGA
- **TARGET="GENERIC"**: Uses standard registers on posedge/negedge (ASIC-compatible)
  - Fallback: Two registers (one posedge, one negedge)
  - **This is what you use for ASIC synthesis**

**2. ODDR (Output DDR) - `rtl/oddr.sv`**
- **TARGET="XILINX"**: Uses Xilinx ODDR/ODDR2 primitives (FPGA-only)
  - IODDR_STYLE: "IODDR" or "IODDR2"
- **TARGET="ALTERA"**: Uses Altera altddio_out (FPGA-only)
- **TARGET="GENERIC"**: Uses `tc_clk_mux2` + registers (ASIC-compatible)
  - Fallback: Clock mux from tech_cells_generic + two registers
  - **Requires:** `deps/tech_cells_generic/src/rtl/tc_clk.sv` (tc_clk_mux2 module)
  - **This is what you use for ASIC synthesis**

**3. SSIO_DDR_IN (Source-Synchronous DDR Input) - `rtl/ssio_ddr_in.sv`**
- **TARGET="XILINX"**: Uses IDDR + clock buffers (BUFG/BUFR/BUFIO/BUFIO2)
  - Clock buffers are Xilinx-only primitives (FPGA-only)
  - CLOCK_INPUT_STYLE: "BUFG" (Ultrascale), "BUFR" (7-series), "BUFIO2" (Spartan-6)
- **TARGET="ALTERA"**: Uses altddio_in with dedicated clock (FPGA-only)
- **TARGET="GENERIC"**: Uses standard IDDR (pass-through clock, ASIC-compatible)
  - Fallback: Just passes clock through, uses GENERIC IDDR
  - **This is what you use for ASIC synthesis**

**4. IDELAY (Input Delay) - `rtl/rgmii_soc.sv`**
- **Xilinx-only** (FPGA-only primitive)
- Only instantiated when `GENESYSII` define is set (Xilinx FPGA board)
- Uses IDELAYCTRL and IDELAYE2 primitives
- Requires 200 MHz reference clock (`clk_200_int`)
- **Not used in ASIC** - timing handled by synthesis tools

### ASIC Verification Setup

**Configuration for ASIC Verification:**
- All primitives use `TARGET="GENERIC"` (this is the default)
- **No IDELAY** - ASIC doesn't use it (timing handled by synthesis tools)
- **No FPGA primitives** - All use ASIC-compatible fallbacks
- Make sure `tech_cells_generic` dependency is available (for `tc_clk_mux2` used in ODDR)

**ASIC Implementation Details:**

1. **IDDR (Input DDR):**
   - Uses two-register implementation (one posedge, one negedge)
   - No FPGA primitives - pure RTL registers
   - Verify: Data captured correctly on both clock edges

2. **ODDR (Output DDR):**
   - Uses `tc_clk_mux2` (from tech_cells_generic) + two registers
   - Clock mux selects between rising/falling edge data
   - Verify: DDR output timing is correct (data on both edges)

3. **SSIO_DDR_IN (Source-Synchronous DDR Input):**
   - Pass-through clock (no FPGA clock buffers)
   - Uses GENERIC IDDR internally
   - Verify: Source-synchronous clocking works correctly

4. **IDELAY:**
   - **NOT USED in ASIC** - Only in FPGA (`rgmii_soc.sv` with `GENESYSII` define)
   - ASIC timing handled by synthesis tool constraints
   - Verify: No IDELAY primitives instantiated



**Key Point:** The GENERIC fallbacks are synthesizable for ASIC. Timing is handled by synthesis tool constraints, not hardware primitives like IDELAY.

## Interfaces

### AXI-Stream (Data Path)
- **TX Path (Input):** System sends packets here
  - `tx_axis_tdata[63:0]` - 64-bit data (8 bytes per cycle)
  - `tx_axis_tvalid` - data valid
  - `tx_axis_tready` - backpressure (DUT says "I'm ready")
  - `tx_axis_tlast` - last transfer in packet
  - `tx_axis_tkeep[7:0]` - byte enable (which bytes are valid)
  - `tx_axis_tuser[0]` - error flag (usually 0)

- **RX Path (Output):** DUT sends received packets here
  - Same signals as TX, but output

**Note:** System side is 64-bit, but internally MAC works on 8-bit. Width converters handle this automatically.

### RGMII (Physical Layer)
- **TX (Output to PHY):**
  - `phy_tx_clk` - 125 MHz DDR clock (DUT generates this)
  - `phy_txd[3:0]` - 4-bit DDR data (8 bits per cycle)
  - `phy_tx_ctl` - DDR control (valid/error)

- **RX (Input from PHY):**
  - `phy_rx_clk` - 125 MHz DDR clock from PHY
  - `phy_rxd[3:0]` - 4-bit DDR data
  - `phy_rx_ctl` - DDR control

- **Management:**
  - `phy_reset_n` - PHY reset (active-low)
  - `phy_int_n` - PHY interrupt (active-low, not really used)
  - `phy_pme_n` - power management (not used)

### MDIO (PHY Management)
Optional interface for PHY register access. Not used in current testbench.
- `phy_mdio_i/o/oe` - tri-state MDIO
- `phy_mdc` - MDIO clock

### REG_BUS (Configuration)
32-bit register interface, 4-bit address (16 registers total). See register map below.

### Clocks
- `clk_i` - 125 MHz system clock (main logic)
- `clk90_int` - 125 MHz, 90° phase shift (for RGMII DDR output)
- `clk_200_int` - 200 MHz (not used in ASIC - only for FPGA IDELAY calibration)
- `rst_ni` - active-low reset

**Note:** `clk_200_int` is provided for compatibility but not used in ASIC implementation (IDELAY is FPGA-only).

## Register Map

**Address Width:** 4 bits (0x0 to 0xF)

| Addr | Name    | Bits | Description |
|------|---------|------|-------------|
| 0x0  | CONFIG0 | 31:0 | MAC Address Lower 32 bits |
| 0x4  | CONFIG1 | 15:0 | MAC Address Upper 16 bits |
|      |         | 16   | Promiscuous mode (1=enabled) |
|      |         | 17   | PHY MDIO clock |
|      |         | 18   | PHY MDIO output |
|      |         | 19   | PHY MDIO output enable |
| 0x8  | CONFIG2 | 31:0 | Status (read-only, HW updates) |
| 0xC  | CONFIG3 | 31:0 | Status (read-only, HW updates) |

**MAC Address Format:**
- Write lower 32 bits to 0x0
- Write upper 16 bits to 0x4[15:0]
- Full MAC = {CONFIG1[15:0], CONFIG0[31:0]}

**Example:** To set MAC = 20:70:98:00:10:32
- Write 0x98001032 to 0x0
- Write 0x00002070 to 0x4 (keep bit 16=0 for no promiscuous)

## MAC Address Filtering

RX path filters frames based on destination MAC:
- **Accepts:** Own MAC, Broadcast (FF:FF:FF:FF:FF:FF), Multicast (01:xx:xx:xx:xx:xx)
- **Rejects:** Other unicast addresses (unless promiscuous mode)

**Promiscuous Mode:** Set CONFIG1[16]=1 to accept ALL frames (useful for testing/debugging).

## Frame Format

Ethernet frame structure (what MAC adds/removes automatically):
- **Preamble:** 7 bytes of 0x55 (MAC adds)
- **SFD:** 1 byte of 0xD5 (MAC adds)
- **Dest MAC:** 6 bytes
- **Src MAC:** 6 bytes
- **EtherType/Length:** 2 bytes
- **Payload:** 46-1500 bytes
- **FCS/CRC:** 4 bytes (MAC adds on TX, checks on RX)

**Note:** Testbench sends/receives frame WITHOUT preamble/SFD/FCS - MAC handles those.

## Running Simulation

Testbench is in `tb/eth_tb.sv`. It does a loopback test:
```
[TB Master] --AXI-Stream--> [TX DUT] --RGMII--> [RX DUT] --AXI-Stream--> [TB Slave]
```

**Bender-free flow:** The build uses a checked-in Questa file list (`scripts/eth_files.f`) and compile script (`scripts/compile.eth.tcl`). You do **not** need Bender installed.
**Questa auto-detect:** If `QUESTA` is not set, the Makefile will try to find `vsim` on your `PATH` and use that location.

**Build:**
```bash
make eth-hw-build
```

**Run:**
```bash
make eth-hw-sim
```

**Questa location:** If your Questa is not on `PATH`, or you want to force a specific install, override it:
```bash
QUESTA=/path/to/questa make eth-hw-build
```

**Clean:**
```bash
make clean
```

## Test Scenarios (Current Testbench)

The testbench runs 5 tests:

1. **Unicast to RX MAC** - Frame addressed to RX module's MAC (should accept)
2. **Broadcast** - Frame to FF:FF:FF:FF:FF:FF (should accept)
3. **Multicast** - Frame to 01:xx:xx:xx:xx:xx (should accept)
4. **Different MAC (no promiscuous)** - Frame to different MAC (should reject)
5. **Different MAC (with promiscuous)** - Same frame but promiscuous enabled (should accept)

## Important Notes for Verification

1. **ASIC-Only Verification:** This design is verified for ASIC implementation. All primitives use `TARGET="GENERIC"` (ASIC-compatible fallbacks). No FPGA primitives (IDDR/ODDR/BUFG/IDELAY) are used. Verify that:
   - All DDR primitives use register-based implementations (not FPGA primitives)
   - No IDELAY is instantiated (check `rgmii_soc.sv` - `GENESYSII` define should NOT be set)
   - `tech_cells_generic` dependency is available (for `tc_clk_mux2` in ODDR)

2. **Clock Domain:** RGMII RX clock (`phy_rx_clk`) comes from PHY and is asynchronous to system clock. Make sure your testbench models this correctly.

3. **Reset:** Hold reset for at least 10000 cycles (80 µs @ 125 MHz) to ensure everything initializes properly.

4. **Backpressure:** AXI-Stream `tready` can deassert - testbench should handle this. Current testbench uses randomized wait cycles.

5. **RGMII DDR:** Data is DDR (double data rate) - 4 bits on rising edge, 4 bits on falling edge = 8 bits per clock cycle.

6. **Width Conversion:** System sees 64-bit AXI-Stream, but internally MAC uses 8-bit. Width converters are transparent to testbench.

7. **Frame Timing:** MAC adds preamble/SFD before your data and FCS after. On RX, MAC strips these before outputting to AXI-Stream.

8. **Register Access:** REG_BUS is standard register interface. Make sure to wait for `ready` before next transaction.

9. **Error Handling:** `tuser[0]` on RX indicates frame errors (FCS mismatch, etc.). Check this in your tests.

## Known Issues / Limitations

- MDIO interface is present but not fully tested
- Status registers (CONFIG2, CONFIG3) are read-only but not currently populated with useful info
- No jumbo frame support (max 1500 bytes payload)

## Files to Look At

**For Understanding the Design:**
- `rtl/eth_top.sv` - Top module (struct interfaces)
- `rtl/eth_top_synth.sv` - Synthesis wrapper (unpacked ports)
- `rtl/framing_top.sv` - Frame processing and MAC filtering
- `rtl/eth_mac_1g.sv` - MAC core
- `rtl/rgmii_core.sv` - RGMII physical layer

**For Writing Tests:**
- `tb/eth_tb.sv` - Testbench reference (shows how to drive interfaces, configure registers, verify behavior)

That's it. If something breaks, check the testbench first - it's been working for me.

- rmd

