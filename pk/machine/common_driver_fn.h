#ifndef COMMON_DRIVER_FN
#define COMMON_DRIVER_FN

#include <stdint.h>
#include "aes.h"

#define NO_MASTERS   3

#define BITS_PER_BYTE   8
#define BYTES_PER_WORD   4
#define BITS_PER_WORD (BITS_PER_BYTE * BYTES_PER_WORD)

#define   DRAM_ID       0 
#define   GPIO_ID       1 
#define   Ethernet_ID   2 
#define   SPI_ID        3 
#define   TIMER_ID      4 
#define   HMAC_ID       5 
#define   REGLK_ID      6    
#define   DMA_ID        7     
#define   ACCT_ID       8    
#define   PKT_ID        9    
#define   SHA256_ID     10     
#define   AES_ID        11    
#define   UART_ID       12     
#define   PLIC_ID       13     
#define   CLINT_ID      14     
#define   ROM_ID        15    
#define   Debug_ID      16


// AcCt peripheral 
#define ACCT_WORDS_PER_MASTER   3
#define ACCT_WORDS (NO_MASTERS*ACCT_WORDS_PER_MASTER)

typedef union REG_LOCK_BLOCK {
    uint32_t word; 

    struct packed_struct {
        char s0; 
        char s1; 
        char s2; 
        char s3; 
    } slave_byte; 

} reglk_blk;

// declare the functions
uint32_t readFromAddress(uint32_t *base_addr, uint32_t offset);
void writeToAddress(uint32_t *base_addr, uint32_t offset, uint32_t pData);
void readMultiFromAddress(uint32_t *base_addr, uint32_t offset, uint32_t *pData, int block_size);
void writeMultiToAddress(uint32_t *base_addr, uint32_t offset, uint32_t *pData, int block_size);
void writeMulticharToAddress(uint32_t *base_addr, uint32_t offset, char *pData, int block_byte_size);

void do_delay(int wait_cycles); 

int verifyMulti(uint32_t *expectedData, uint32_t *receivedData, int block_size);

#endif
