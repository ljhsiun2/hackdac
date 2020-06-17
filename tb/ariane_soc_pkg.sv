// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Description: Contains SoC information as constants
package ariane_soc;
  // M-Mode Hart, S-Mode Hart
  localparam int unsigned NumTargets = 2;
  // Uart, SPI, Ethernet, reserved
  localparam int unsigned NumSources = 30;
  localparam int unsigned MaxPriority = 7;

  localparam NrSlaves = 3; // actually masters, but slaves on the crossbar

  // 4 is recommended by AXI standard, so lets stick to it, do not change
  localparam IdWidth   = 4;
  localparam IdWidthSlave = IdWidth + $clog2(NrSlaves);

  typedef enum int unsigned {
    DRAM     = 0,
    GPIO     = 1,
    Ethernet = 2,
    SPI      = 3,
    Timer    = 4,
    HMAC     = 5,
    REGLK    = 6,
    DMA      = 7,
    ACCT     = 8,
    PKT      = 9,
    SHA256   = 10,
    AES      = 11,
    UART     = 12,
    PLIC     = 13,
    CLINT    = 14,
    ROM      = 15,  
    Debug    = 16
  } axi_slaves_t;

  localparam NB_PERIPHERALS = Debug + 1;


  localparam logic[63:0] DebugLength    = 64'h1000;
  localparam logic[63:0] ROMLength      = 64'h10000;
  localparam logic[63:0] CLINTLength    = 64'hC0000;
  localparam logic[63:0] PLICLength     = 64'h3FF_FFFF;
  localparam logic[63:0] UARTLength     = 64'h1000;
  localparam logic[63:0] AESLength      = 64'h1000;
  localparam logic[63:0] SHA256Length   = 64'h1000;
  localparam logic[63:0] PKTLength      = 64'h1000;
  localparam logic[63:0] ACCTLength     = 64'h1000;
  localparam logic[63:0] DMALength      = 64'h1000;
  localparam logic[63:0] REGLKLength    = 64'h1000;
  localparam logic[63:0] HMACLength     = 64'h1000;
  localparam logic[63:0] TimerLength    = 64'h1000_0000;
  localparam logic[63:0] SPILength      = 64'h800000;
  localparam logic[63:0] EthernetLength = 64'h10000;
  localparam logic[63:0] GPIOLength     = 64'h1000;
  localparam logic[63:0] DRAMLength     = 64'h40000000; // 1GByte of DDR (split between two chips on Genesys2)
  localparam logic[63:0] SRAMLength     = 64'h1800000;  // 24 MByte of SRAM
  // Instantiate AXI protocol checkers
  localparam bit GenProtocolChecker = 1'b0;

  typedef enum logic [63:0] {
    DebugBase    = 64'h0000_0000,
    ROMBase      = 64'h0001_0000,
    CLINTBase    = 64'h0200_0000,
    PLICBase     = 64'h0C00_0000,
    UARTBase     = 64'h1000_0000,
    AESBase      = 64'h1010_0000,
    SHA256Base   = 64'h1020_0000,
    PKTBase      = 64'h1030_0000,
    ACCTBase     = 64'h1040_0000,
    DMABase      = 64'h1050_0000,
    REGLKBase    = 64'h1060_0000,
    HMACBase     = 64'h1070_0000,
    TimerBase    = 64'h1800_0000,
    SPIBase      = 64'h2000_0000,
    EthernetBase = 64'h3000_0000,
    GPIOBase     = 64'h4000_0000,
    DRAMBase     = 64'h8000_0000
  } soc_bus_start_t;

  localparam NrRegion = 1;
  localparam logic [NrRegion-1:0][NB_PERIPHERALS-1:0] ValidRule = {{NrRegion * NB_PERIPHERALS}{1'b1}};

  localparam ariane_pkg::ariane_cfg_t ArianeSocCfg = '{
    RASDepth: 2,
    BTBEntries: 32,
    BHTEntries: 128,
    // idempotent region
    NrNonIdempotentRules:  0,
    NonIdempotentAddrBase: {64'b0},
    NonIdempotentLength:   {64'b0},
    NrExecuteRegionRules:  3,
    ExecuteRegionAddrBase: {DRAMBase,   ROMBase,   DebugBase},
    ExecuteRegionLength:   {DRAMLength, ROMLength, DebugLength},
    // cached region
    NrCachedRegionRules:    1,
    CachedRegionAddrBase:  {DRAMBase},
    CachedRegionLength:    {DRAMLength},
    //  cache config
    Axi64BitCompliant:      1'b1,
    SwapEndianess:          1'b0,
    // debug
    DmBaseAddress:          DebugBase
  };

    // Different AES Key ID's this information is public.
    localparam logic[63:0] AESKey0_0    = AESBase + 4*05;  // address for LSB 32 bits
    localparam logic[63:0] AESKey0_1    = AESBase + 4*06;
    localparam logic[63:0] AESKey0_2    = AESBase + 4*07;
    localparam logic[63:0] AESKey0_3    = AESBase + 4*08;
    localparam logic[63:0] AESKey0_4    = AESBase + 4*09;
    localparam logic[63:0] AESKey0_5    = AESBase + 4*10;
    localparam logic[63:0] AESKey1_0    = AESBase + 4*20;  // address for LSB 32 bits
    localparam logic[63:0] AESKey1_1    = AESBase + 4*21;
    localparam logic[63:0] AESKey1_2    = AESBase + 4*22;
    localparam logic[63:0] AESKey1_3    = AESBase + 4*23;
    localparam logic[63:0] AESKey1_4    = AESBase + 4*24;
    localparam logic[63:0] AESKey1_5    = AESBase + 4*25;
    localparam logic[63:0] AESKey2_0    = AESBase + 4*26;  // address for LSB 32 bits
    localparam logic[63:0] AESKey2_1    = AESBase + 4*27;
    localparam logic[63:0] AESKey2_2    = AESBase + 4*28;
    localparam logic[63:0] AESKey2_3    = AESBase + 4*29;
    localparam logic[63:0] AESKey2_4    = AESBase + 4*30;
    localparam logic[63:0] AESKey2_5    = AESBase + 4*31;
    localparam logic[63:0] SHA256Key_0    = SHA256Base + 4*20 ;  // SHA256 has no key input, so, mapping to a invalid address as of now
    localparam logic[63:0] SHA256Key_1    = SHA256Base + 4*20 ;  // SHA256 has no key input, so, mapping to a invalid address as of now
    localparam logic[63:0] SHA256Key_2    = SHA256Base + 4*20 ;  // SHA256 has no key input, so, mapping to a invalid address as of now
    localparam logic[63:0] SHA256Key_3    = SHA256Base + 4*20 ;  // SHA256 has no key input, so, mapping to a invalid address as of now
    localparam logic[63:0] SHA256Key_4    = SHA256Base + 4*20 ;  // SHA256 has no key input, so, mapping to a invalid address as of now
    localparam logic[63:0] SHA256Key_5    = SHA256Base + 4*20 ;  // SHA256 has no key input, so, mapping to a invalid address as of now
    localparam logic[63:0] ACCT_M_00   = ACCTBase + 4*0;
    localparam logic[63:0] ACCT_M_01   = ACCTBase + 4*1;
    localparam logic[63:0] ACCT_M_02   = ACCTBase + 4*2;
    localparam logic[63:0] ACCT_M_10   = ACCTBase + 4*3;
    localparam logic[63:0] ACCT_M_11   = ACCTBase + 4*4;
    localparam logic[63:0] ACCT_M_12   = ACCTBase + 4*5;
    localparam logic[63:0] ACCT_M_20   = ACCTBase + 4*6;
    localparam logic[63:0] ACCT_M_21   = ACCTBase + 4*7;
    localparam logic[63:0] ACCT_M_22   = ACCTBase + 4*8;

endpackage
