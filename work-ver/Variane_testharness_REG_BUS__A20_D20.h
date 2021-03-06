// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Variane_testharness.h for the primary calling header

#ifndef _VARIANE_TESTHARNESS_REG_BUS__A20_D20_H_
#define _VARIANE_TESTHARNESS_REG_BUS__A20_D20_H_  // guard

#include "verilated_heavy.h"
#include "Variane_testharness__Dpi.h"

//==========

class Variane_testharness__Syms;
class Variane_testharness_VerilatedVcd;


//----------

VL_MODULE(Variane_testharness_REG_BUS__A20_D20) {
  public:
    
    // PORTS
    VL_IN8(clk_i,0,0);
    
    // LOCAL SIGNALS
    IData/*31:0*/ rdata;
    
    // INTERNAL VARIABLES
  private:
    Variane_testharness__Syms* __VlSymsp;  // Symbol table
  public:
    
    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Variane_testharness_REG_BUS__A20_D20);  ///< Copying not allowed
  public:
    Variane_testharness_REG_BUS__A20_D20(const char* name = "TOP");
    ~Variane_testharness_REG_BUS__A20_D20();
    
    // INTERNAL METHODS
    void __Vconfigure(Variane_testharness__Syms* symsp, bool first);
  private:
    void _ctor_var_reset() VL_ATTR_COLD;
  public:
    static void traceInit(VerilatedVcd* vcdp, void* userthis, uint32_t code);
    static void traceFull(VerilatedVcd* vcdp, void* userthis, uint32_t code);
    static void traceChg(VerilatedVcd* vcdp, void* userthis, uint32_t code);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
