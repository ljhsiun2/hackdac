// See LICENSE for license details.

#ifndef _RISCV_REGLK_H
#define _RISCV_REGLK_H

#include <stdint.h>

extern volatile uint32_t* reglk;

// REGLK peripheral
#define REGLK_WORDS 6
#define REGLK_BYTES (REGLK_WORDS*BYTES_PER_WORD) // 24
#define REGLK_ACCT 0xf3
#define REGLK_REGLK 0xcf
#define REGLK_AES 0x00
#define REGLK_SHA256 0x00

void query_reglk(uintptr_t dtb);

#endif
