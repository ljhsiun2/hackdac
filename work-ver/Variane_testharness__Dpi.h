// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Prototypes for DPI import and export functions.
//
// Verilator includes this file in all generated .cpp files that use DPI functions.
// Manually include this file where DPI .c import functions are declared to ensure
// the C functions match the expectations of the DPI imports.

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif
    
    
    // DPI IMPORTS
    // DPI import at /home/hackdac20/HACKDAC_2020/ariane/tb/common/SimDTM.sv:4
    extern int debug_tick(unsigned char* debug_req_valid, unsigned char debug_req_ready, int* debug_req_bits_addr, int* debug_req_bits_op, int* debug_req_bits_data, unsigned char debug_resp_valid, unsigned char* debug_resp_ready, int debug_resp_bits_resp, int debug_resp_bits_data);
    // DPI import at /home/hackdac20/HACKDAC_2020/ariane/tb/common/SimJTAG.sv:3
    extern int jtag_tick(unsigned char* jtag_TCK, unsigned char* jtag_TMS, unsigned char* jtag_TDI, unsigned char* jtag_TRSTn, unsigned char jtag_TDO);
    
#ifdef __cplusplus
}
#endif
