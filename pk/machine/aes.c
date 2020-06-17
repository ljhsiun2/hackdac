// See LICENSE for license details.

#include <string.h>
#include "aes.h"
#include "fdt.h"
#include "mtrap.h"
#include "pk.h"
#include "common_driver_fn.h"

#include <stdio.h>

volatile uint32_t* aes;


struct aes_scan
{
  int compat;
  uint64_t reg;
};

int aes_start_encrypt(uint32_t *pt, uint32_t *st, uint32_t key_sel)
{

    // Write the inputs
    writeToAddress((uint32_t *)aes, AES_KEY_SEL, key_sel); 
    writeMultiToAddress((uint32_t *)aes, AES_PT_BASE, pt, AES_PT_WORDS); 
    writeMultiToAddress((uint32_t *)aes, AES_ST_BASE, st, AES_ST_WORDS); 

    // Start the AES encryption
    writeToAddress((uint32_t *)aes, AES_START, 0x0);
    writeToAddress((uint32_t *)aes, AES_START, 0x1);

    // Wait to see that START has been asserted to make sure DONE has a valid value
    while (readFromAddress((uint32_t *)aes, AES_START) == 0) {
        do_delay(AES_START_DELAY); 
    }
    writeToAddress((uint32_t *)aes, AES_START, 0x0);
    return 0; 

}

int aes_wait()
{
     // Wait for valid output
    uint32_t ct[AES_CT_WORDS];
    printm("Waiting for AES");
    while (readFromAddress((uint32_t *)aes, AES_DONE) == 0) {
        // do_delay(AES_DONE_DELAY); 
        readMultiFromAddress((uint32_t *)aes, AES_CT_BASE, ct, AES_CT_WORDS);
        for(int i = 0; i < AES_CT_WORDS; i++)
            printm("%04x ", ct[i]);
    }

    return 0; 

}

int aes_data_out(uint32_t *ct)
{
    // Read the Encrypted data
    readMultiFromAddress((uint32_t *)aes, AES_CT_BASE, ct, AES_CT_WORDS);

    return 0; 
}


int aes_encrypt(uint32_t *pt, uint32_t *st, uint32_t *ct, uint32_t key_sel)
{
    aes_start_encrypt(pt, st,key_sel); 
    aes_wait();
    aes_data_out(ct); 
    return 0; 
}

int check_aes()
{
    //// Give a test input and verify AES enryption
    printm("    Verifying AES crypto engine ...\n") ;
   
    // Input for AES encyption
    uint32_t pt[4]  = {0x00001111, 0x22223333, 0x44445555, 0x66667777};
    uint32_t st[4]  = {0x3243f6a8, 0x885a308d, 0x313198a2, 0xe0370734};
    uint32_t key[6] = {0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c, 0x2b7e1516, 0x28aed2a6};
    uint32_t ct[AES_CT_WORDS];
    uint32_t pt_deciphered[AES_PT_WORDS];
    uint32_t expectedCt[AES_CT_WORDS] = {0x4fcb9ca9, 0x75a691f2, 0xff338e2b, 0xb85460db};

    uint32_t key_sel = 0; 

    int aes_working; 

    // Write the AES key 
    writeMultiToAddress((uint32_t *)aes, AES_KEY0_BASE, key, AES_KEY_WORDS); 

    // call the aes encryption function
    aes_encrypt(pt, st, ct, key_sel); 

    // Verify the Encrypted data
    aes_working = verifyMulti(expectedCt, ct, AES_CT_WORDS); 

    if (aes_working)
        printm("    AES engine encryption successfully verified\n"); 
    else
        printm("    AES engine failed, disabling the crypto engine !\n");

    return aes_working ;  
    
}

static void aes_open(const struct fdt_scan_node *node, void *extra)
{
  struct aes_scan *scan = (struct aes_scan *)extra;
  memset(scan, 0, sizeof(*scan));
}

static void aes_prop(const struct fdt_scan_prop *prop, void *extra)
{
  struct aes_scan *scan = (struct aes_scan *)extra;
  if (!strcmp(prop->name, "compatible")) {
          if( !strcmp((const char*)prop->value, "hd20,aes0")) {
    scan->compat = 1;
  }
  } else if (!strcmp(prop->name, "reg")) {
    fdt_get_address(prop->node->parent, prop->value, &scan->reg);
  }
}

static void aes_done(const struct fdt_scan_node *node, void *extra)
{
  struct aes_scan *scan = (struct aes_scan *)extra;
  if (!scan->compat || !scan->reg || aes) return;

  // Enable Rx/Tx channels
  aes = (void*)(uintptr_t)scan->reg;

}

void query_aes(uintptr_t fdt)
{
  struct fdt_cb cb;
  struct aes_scan scan;

  memset(&cb, 0, sizeof(cb));
  cb.open = aes_open;
  cb.prop = aes_prop;
  cb.done = aes_done;
  cb.extra = &scan;

  fdt_scan(fdt, &cb);
}
