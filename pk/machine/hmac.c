// See LICENSE for license details.

#include <string.h>
#include "hmac.h"
#include "fdt.h"
#include "mtrap.h"
#include "pk.h"
#include "common_driver_fn.h"

volatile uint32_t* hmac;

struct hmac_scan
{
  int compat;
  uint64_t reg;
};

int hmac_hashString(char *pString, uint32_t *hash, uint32_t *key)
{
  char *ptr = pString;
     

    int done = 0;
    int firstTime = 1;
    int totalBytes = 0;
    
        char message[2 * HMAC_TEXT_BITS];
        for (int i=0; i<2*HMAC_TEXT_BYTES; i++)
            message[i] = 0; 
        
        // Copy next portion of string to message buffer
        char *msg_ptr = message;
        int length = 0;
        while(length < 448) {
            // Check for end of input
            if(*pString == '\0') {
                done = 1;
                break;
            }
            *msg_ptr++ = *pString++;
            ++length;
            ++totalBytes;
        }
        
        // Need to add padding if done
        int addedBytes = 0;
            addedBytes = hmac_addPadding(totalBytes * BITS_PER_BYTE, message);
        
        // Send the message
        while (readFromAddress((uint32_t *)hmac, HMAC_READY) == 0) {
            do_delay(HMAC_READY_DELAY); 
        }

        writeMulticharToAddress((uint32_t *)hmac, HMAC_TEXT_BASE, message, HMAC_TEXT_BYTES); 



        writeMultiToAddress((uint32_t *)hmac, HMAC_KEY_BASE, key, HMAC_KEY_WORDS); 

        // start the hashing
        if(firstTime) {
            //strobeInit();
            writeToAddress((uint32_t *)hmac, HMAC_NEXT_INIT, 0x1); 
            writeToAddress((uint32_t *)hmac, HMAC_NEXT_INIT, 0x0); 
            firstTime = 0;
        } else {
            //strobeNext();
            writeToAddress((uint32_t *)hmac, HMAC_NEXT_INIT, 0x2); 
            writeToAddress((uint32_t *)hmac, HMAC_NEXT_INIT, 0x0); 
        }

        // wait for HMAC to start
        do_delay(20); 

        // wait for valid output
        while (readFromAddress((uint32_t *)hmac, HMAC_VALID) == 0) {
            do_delay(HMAC_VALID_DELAY); 
        }

    // Read the Hash
    readMultiFromAddress((uint32_t *)hmac, HMAC_HASH_BASE, hash, HMAC_HASH_WORDS); 

    return 0; 

}


int hmac_addPadding(uint64_t pMessageBits64Bit, char* buffer) {
    int extraBits = pMessageBits64Bit % HMAC_TEXT_BITS;
    int paddingBits = extraBits > 448 ? (2 * HMAC_TEXT_BITS) - extraBits : HMAC_TEXT_BITS - extraBits;
    
    // Add size to end of string
    const int startByte = extraBits / BITS_PER_BYTE;
    const int sizeStartByte =  startByte + ((paddingBits / BITS_PER_BYTE) - 8);

    for(int i = startByte; i < (sizeStartByte + 8); ++i) {
        if(i == startByte) {
            buffer[i] = 0x80; // 1 followed by many 0's
        } else if( i >= sizeStartByte) {
            int offset = i - sizeStartByte;
            int shftAmnt = 56 - (8 * offset);
            buffer[i] = (pMessageBits64Bit >> shftAmnt) & 0xFF;
        } else {
            buffer[i] = 0x0;
        }
    }
    
    return (paddingBits / BITS_PER_BYTE);
}


int check_hmac()
{
    //// Give a test input and verify AES enryption
    printm("    Verifying HMAC crypto engine ...\n") ;
   
    // Input for HMAC encyption
    char inputText[500] = "jason can walk";
    //char inputText[500] = "abc";
    uint32_t hash[HMAC_HASH_WORDS];
    uint32_t expectedHash[HMAC_HASH_WORDS] = {0xf88c49e2, 0xb696d45a, 0x699eb10e, 0xffafb3c9, 0x522df6f7, 0xfa68c250, 0x9d105e84, 0x9be605ba};
    uint32_t key[8] = {0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c, 0x2b7e1516, 0x28aed2a6, 0x2b7e1516, 0x28aed2a6};
    
    int hmac_working; 

    // call the hmac hashing function
    hmac_hashString(inputText, hash, key);

    // Verify the Hash 
    hmac_working = verifyMulti(expectedHash, hash, HMAC_HASH_WORDS); 
    
    if (hmac_working)
        printm("    HMAC engine hashing successfully verified\n"); 
    else
        printm("    HMAC engine failed, disabling the crypto engine !\n");

    return hmac_working ;  
}


static void hmac_open(const struct fdt_scan_node *node, void *extra)
{
  struct hmac_scan *scan = (struct hmac_scan *)extra;
  memset(scan, 0, sizeof(*scan));
}

static void hmac_prop(const struct fdt_scan_prop *prop, void *extra)
{
  struct hmac_scan *scan = (struct hmac_scan *)extra;
  if (!strcmp(prop->name, "compatible")) {
          if( !strcmp((const char*)prop->value, "hd20,hmac")) {
    scan->compat = 1;
  }
  } else if (!strcmp(prop->name, "reg")) {
    fdt_get_address(prop->node->parent, prop->value, &scan->reg);
  }
}

static void hmac_done(const struct fdt_scan_node *node, void *extra)
{
  struct hmac_scan *scan = (struct hmac_scan *)extra;
  if (!scan->compat || !scan->reg || hmac) return;

  // Enable Rx/Tx channels
  hmac = (void*)(uintptr_t)scan->reg;


}

void query_hmac(uintptr_t fdt)
{
  struct fdt_cb cb;
  struct hmac_scan scan;

  memset(&cb, 0, sizeof(cb));
  cb.open = hmac_open;
  cb.prop = hmac_prop;
  cb.done = hmac_done;
  cb.extra = &scan;

  fdt_scan(fdt, &cb);
}
