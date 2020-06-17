// See LICENSE for license details.

#ifndef _RISCV_DMA_H
#define _RISCV_DMA_H

#include <stdint.h>

extern volatile uint32_t* dma;

#define DMA_WAIT_DELAY 8
#define DMA_START_DELAY 2

// peripheral registers
#define DMA_STATE_IDLE 0
#define DMA_STATE_DONE 5
#define DMA_CONFIG  0
#define DMA_LEN    ( 0  + 1 )
#define DMA_SADDR  ( DMA_LEN   + 1 ) 
#define DMA_DADDR  ( DMA_SADDR + 1 ) 
#define DMA_STATE  ( DMA_DADDR + 1 )

int dma_transfer(uint32_t sAddress, uint32_t dAddress, uint32_t length, uint32_t wait);

void query_dma(uintptr_t dtb);

#endif
