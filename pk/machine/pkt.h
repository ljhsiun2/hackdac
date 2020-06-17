// See LICENSE for license details.

#ifndef _RISCV_PKT_H
#define _RISCV_PKT_H

#include <stdint.h>
#include "aes.h"
#include "sha256.h"

extern volatile uint32_t* pkt;

// PKT peripheral
#define PKT_FUSE_REQ 0
#define PKT_FUSE_RADDR (PKT_FUSE_REQ + 1)
#define PKT_WADDR_LSB (PKT_FUSE_RADDR + 2)
#define PKT_FUSE_RDATA (PKT_WADDR_LSB + 1)

#define PKT_AES_WORDS AES_KEY_WORDS
#define PKT_SHA256_WORDS SHA256_KEY_WORDS
#define PKT_ACCT_WORDS ACCT_WORDS
#define PKT_AES_BASE_INDX 0
#define PKT_SHA256_BASE_INDX (PKT_AES_BASE_INDX + (AES_NO_KEYS*PKT_AES_WORDS))
#define PKT_ACCT_BASE_INDX (PKT_SHA256_BASE_INDX + PKT_SHA256_WORDS)




int pkt_copy_fuse_data();

void query_pkt(uintptr_t dtb);

#endif
