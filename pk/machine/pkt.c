// See LICENSE for license details.

#include <string.h>
#include "pkt.h"
#include "fdt.h"
#include "mtrap.h"
#include "pk.h"
#include "reglk.h"
#include "common_driver_fn.h"

volatile uint32_t* reglk;
volatile uint32_t* pkt;

struct pkt_scan
{
  int compat;
  uint64_t reg;
};

int pkt_copy_fuse_data(int aes_working, int sha256_working)
{
    int i, j;
    uint32_t rdata, wdata, data; 
    uint32_t waddr; 
    char reglk_bytes[REGLK_BYTES]; 
    reglk_blk reglk_blk_data; 


    //---------------------------------------------------
    // Check if the crypto engines are working properly
    //---------------------------------------------------
      if (!aes_working) 
          reglk_bytes[AES_ID]  =  0xff; // lock all registers 
  
      if (!sha256_working) 
          reglk_bytes[SHA256_ID]  =  0xff; // lock all registers 
  



    printm("    Setting the FUSE data\n");  

    // Enable the fuse request
    wdata = 0x1; 
    writeToAddress((uint32_t *)pkt, PKT_FUSE_REQ, wdata);   

    // Set the Access Control Registers
    for (int acct_word=PKT_ACCT_BASE_INDX; acct_word<(PKT_ACCT_BASE_INDX+PKT_ACCT_WORDS); acct_word++)
    {
        wdata = acct_word ; 
        writeToAddress((uint32_t *)pkt, PKT_FUSE_RADDR, wdata);   
        asm volatile ("nop \n\t") ;  // 1 cycle gap to allow data to be loaded
        waddr = readFromAddress((uint32_t *)pkt, PKT_WADDR_LSB);
        wdata = readFromAddress((uint32_t *)pkt, PKT_FUSE_RDATA);  
        writeToAddress(0, waddr/4, wdata); 
    } 

    // Set the AES keys only if it is working
    if (aes_working)
    {
      for (int aes_word=PKT_AES_BASE_INDX; aes_word<(PKT_AES_BASE_INDX+(AES_NO_KEYS*PKT_AES_WORDS)); aes_word++)
      {
          wdata = aes_word ; 
          writeToAddress((uint32_t *)pkt, PKT_FUSE_RADDR, wdata);   
          asm volatile ("nop \n\t") ;  // 1 cycle gap to allow data to be loaded
          waddr = readFromAddress((uint32_t *)pkt, PKT_WADDR_LSB);
          wdata = readFromAddress((uint32_t *)pkt, PKT_FUSE_RDATA);  
          writeToAddress(0, waddr/4, wdata); 
      }
    }  

    // Disable the fuse request
    wdata = 0x0; 
    writeToAddress((uint32_t *)pkt, PKT_FUSE_REQ, wdata);   


  //---------------------------------------------------
  // Set the Register locks
  //---------------------------------------------------
    printm("    Setting the register locks\n");

    for (int reglk_word=0; reglk_word<REGLK_BYTES; reglk_word++)
    {
        reglk_bytes[reglk_word] = 0; // by default no locks are set
    }
    reglk_bytes[ACCT_ID] =  REGLK_ACCT; 
    reglk_bytes[REGLK_ID] =  REGLK_REGLK; 
    reglk_bytes[AES_ID]  =  aes_working ? REGLK_AES : 0xff; 
    reglk_bytes[SHA256_ID]  =  sha256_working ? REGLK_SHA256 : 0xff; 
    
    for (int reglk_word=0; reglk_word<REGLK_WORDS; reglk_word++)
    {
        reglk_blk_data.slave_byte.s0 = reglk_bytes[reglk_word*4+0]; 
        reglk_blk_data.slave_byte.s1 = reglk_bytes[reglk_word*4+1]; 
        reglk_blk_data.slave_byte.s2 = reglk_bytes[reglk_word*4+2]; 
        reglk_blk_data.slave_byte.s3 = reglk_bytes[reglk_word*4+3]; 
        writeToAddress((uint32_t *)reglk,  reglk_word, reglk_blk_data.word);   
    } 
   
    return 0; 
}
 
static void pkt_open(const struct fdt_scan_node *node, void *extra)
{
  struct pkt_scan *scan = (struct pkt_scan *)extra;
  memset(scan, 0, sizeof(*scan));
}

static void pkt_prop(const struct fdt_scan_prop *prop, void *extra)
{
  struct pkt_scan *scan = (struct pkt_scan *)extra;
  if (!strcmp(prop->name, "compatible")) {
          if( !strcmp((const char*)prop->value, "hd20,pkt")) {
    scan->compat = 1;
  }
  } else if (!strcmp(prop->name, "reg")) {
    fdt_get_address(prop->node->parent, prop->value, &scan->reg);
  }
}

static void pkt_done(const struct fdt_scan_node *node, void *extra)
{
  struct pkt_scan *scan = (struct pkt_scan *)extra;
  if (!scan->compat || !scan->reg || pkt) return;

  // Enable Rx/Tx channels
  pkt = (void*)(uintptr_t)scan->reg;
}

void query_pkt(uintptr_t fdt)
{
  struct fdt_cb cb;
  struct pkt_scan scan;

  memset(&cb, 0, sizeof(cb));
  cb.open = pkt_open;
  cb.prop = pkt_prop;
  cb.done = pkt_done;
  cb.extra = &scan;

  fdt_scan(fdt, &cb);
}
