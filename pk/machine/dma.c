// See LICENSE for license details.

#include <string.h>
#include "dma.h"
#include "fdt.h"
#include "mtrap.h"
#include "pk.h"
#include "common_driver_fn.h"

volatile uint32_t* dma;


struct dma_scan
{
  int compat;
  uint64_t reg;
};

int dma_transfer(uint32_t sAddress, uint32_t dAddress, uint32_t length, uint32_t wait) {
    
    uint32_t rdata; 

    // wait till the DMA is in IDLE or DONE state
    rdata = readFromAddress((uint32_t *)dma, DMA_STATE);
    while (!(rdata == DMA_STATE_IDLE || rdata == DMA_STATE_DONE)) {
        do_delay(DMA_WAIT_DELAY); 
        rdata = readFromAddress((uint32_t *)dma, DMA_STATE); 
    }

    // Reset DMA if it is in DONE state
    if (rdata == DMA_STATE_DONE)
        writeToAddress((uint32_t *)dma, DMA_CONFIG, 0x2);

    // Configure the DMA
    writeToAddress((uint32_t *)dma, DMA_SADDR, sAddress);  
    writeToAddress((uint32_t *)dma, DMA_DADDR, dAddress);  
    writeToAddress((uint32_t *)dma, DMA_LEN, length); 

    // State the DMA
    writeToAddress((uint32_t *)dma, DMA_CONFIG, 0x01); 
    do_delay(DMA_START_DELAY); 
    writeToAddress((uint32_t *)dma, DMA_CONFIG, 0x00); 

    // If wait == 1, wait till transfer is done
    if (wait) {
        while (readFromAddress((uint32_t *)dma, DMA_STATE) != DMA_STATE_DONE) {
            do_delay(DMA_WAIT_DELAY); 
        }
    }
    return 0; 
}

static void dma_open(const struct fdt_scan_node *node, void *extra)
{
  struct dma_scan *scan = (struct dma_scan *)extra;
  memset(scan, 0, sizeof(*scan));
}

static void dma_prop(const struct fdt_scan_prop *prop, void *extra)
{
  struct dma_scan *scan = (struct dma_scan *)extra;
  if (!strcmp(prop->name, "compatible")) {
          if( !strcmp((const char*)prop->value, "hd20,dma")) {
    scan->compat = 1;
  }
  } else if (!strcmp(prop->name, "reg")) {
    fdt_get_address(prop->node->parent, prop->value, &scan->reg);
  }
}

static void dma_done(const struct fdt_scan_node *node, void *extra)
{
  struct dma_scan *scan = (struct dma_scan *)extra;
  if (!scan->compat || !scan->reg || dma) return;

  // Enable Rx/Tx channels
  dma = (void*)(uintptr_t)scan->reg;
}

void query_dma(uintptr_t fdt)
{
  struct fdt_cb cb;
  struct dma_scan scan;

  memset(&cb, 0, sizeof(cb));
  cb.open = dma_open;
  cb.prop = dma_prop;
  cb.done = dma_done;
  cb.extra = &scan;

  fdt_scan(fdt, &cb);
}
