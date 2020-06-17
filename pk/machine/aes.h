// See LICENSE for license details.

#ifndef _RISCV_AES_H
#define _RISCV_AES_H

#include <stdint.h>

extern volatile uint32_t* aes;


#define AES_ENCRYPT_ID 0
#define AES_DECRYPT_ID 1


#define AES_REG_TXFIFO		2
#define AES_REG_RXFIFO		1
#define AES_REG_TXCTRL		2
#define AES_REG_RXCTRL		3
#define AES_REG_DIV		4

#define AES_TXEN		 0x1
#define AES_RXEN		 0x1


#define AES_START_DELAY 1
#define AES_DONE_DELAY 4

// peripheral registers
#define AES_NO_KEYS 3
#define AES_PT_BITS   128
#define AES_ST_BITS   128
#define AES_KEY_BITS   192
#define AES_CT_BITS   128
#define AES_START_WORDS  1
#define AES_DONE_WORDS   1
#define AES_PT_WORDS (AES_PT_BITS / BITS_PER_WORD)
#define AES_ST_WORDS (AES_ST_BITS / BITS_PER_WORD)
#define AES_KEY_WORDS (AES_KEY_BITS / BITS_PER_WORD)
#define AES_CT_WORDS (AES_CT_BITS / BITS_PER_WORD)

#define AES_START   0
#define AES_PT_BASE   ( AES_START     + AES_START_WORDS )
#define AES_KEY0_BASE ( AES_PT_BASE   + AES_PT_WORDS )
#define AES_DONE      ( AES_KEY0_BASE + AES_KEY_WORDS )
#define AES_CT_BASE   ( AES_DONE      + AES_DONE_WORDS )
#define AES_ST_BASE   ( AES_CT_BASE   + AES_CT_WORDS )
#define AES_KEY1_BASE ( AES_ST_BASE   + AES_ST_WORDS )
#define AES_KEY2_BASE ( AES_KEY1_BASE + AES_KEY_WORDS )
#define AES_KEY_SEL   ( AES_KEY2_BASE + AES_KEY_WORDS )


int aes_start_encrypt(uint32_t *pt, uint32_t *st, uint32_t key_sel); 
int aes_wait(); 
int aes_data_out(uint32_t *ct); 
int aes_encrypt(uint32_t *pt, uint32_t *st, uint32_t *ct, uint32_t key_sel);
int check_aes(); 

void query_aes(uintptr_t dtb);

#endif
