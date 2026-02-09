/* -----------------------------------------------------------
 * Simple test of userspace application with UIO devices in C
 * Todo: interrupt handling
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <inttypes.h>
#include <limits.h>     // CHAR_BIT

#define UIO_DEVICE "/dev/uio1" // Adjust if your BRAM is mapped to a different UIO device

// isolate channel from the data word
unsigned getbits(uint64_t value, unsigned offset, unsigned n);

unsigned getbits(uint64_t value, unsigned offset, unsigned n) {
    const unsigned max_n = CHAR_BIT * sizeof(unsigned);
    if (offset >= max_n)
        return 0; /* value is padded with infinite zeros on the left */
    value >>= offset; /* drop offset bits */
    if (n >= max_n)
        return value; /* all  bits requested */
    const unsigned mask = (1u << n) - 1; /* n '1's */
    return value & mask;
}


int main() {
    int fd;
    volatile unsigned int *bram_ptr;
    off_t offset = 0; // Offset within the mapped memory region (usually 0 for BRAM)
    size_t length = 8192; // Size of the BRAM in bytes (e.g., 8KB)

    // Open the UIO device
    fd = open(UIO_DEVICE, O_RDWR);
    if (fd < 0) {
        perror("Failed to open UIO device");
        return 1;
    }
    else {
        printf("Opened BRAM 2\n");                                                       
    }                                                                                    
                                                                                         
    // Map the BRAM memory into user space                                               
    bram_ptr = (volatile uint64_t *)mmap(NULL, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, offset);
    if (bram_ptr == MAP_FAILED) {                                                                      
        perror("Failed to mmap BRAM");                                                                 
        close(fd);                                                                                     
        return 1;                                                                                      
    }                                                                                                  
                                                                                                       
    // printf("%d,0x%"PRIx64",%u,%u,%u\n\r",i,bram1_data,coarseTime,fineTime,channelID);               
    for (int i=0; i<250; i+=1) {                                                                       
                                                                                                       
        uint64_t bram1_data = bram_ptr[i];                                                             
                                                                                                       
        unsigned channelID  = getbits(bram1_data, 0, 6);                                               
        unsigned fineTime   = getbits(bram1_data, 6, 5);                                               
        unsigned coarseTime = getbits(bram1_data, 11, 28);                                             
                                                                                                       
        uint64_t data = bram_ptr[i];                                                                   
        //uint64_t data1 = bram_ptr[i];                                                                
        //uint64_t data2 = bram_ptr[i+1];                                                              
        //printf("%#018"PRIx64"\n", data);                                                             
        printf("Read data: 0x%llx%llx\n", data1, data2);                                               
                                                                                                       
        //printf("Address %d: 0x%"PRIx64",\t\tCoarse time: %u,\t\tFine time: %u,\t\tChannel ID: %u\n\r",i,bram1_data,coarseTime,fineTime,channelID);
                                                                                                                                                    
        //bram_ptr[i] = 0;                                                                                                                          
    }                                                                                                                                               
                                                                                                                                                    
                                                                                                                                                    
    // Read a value from BRAM (example: read the first 32-bit word)                                                                                 
    //unsigned int data = bram_ptr[0];                                                                                                              
    //printf("Data read from BRAM: 0x%08X\n", data);                                                                                                
                                                                                                                                                    
    // Unmap the memory and close the device                                                                                                        
    munmap((void *)bram_ptr, length);                                                                                                               
    close(fd);  
    return 0;                                                                                                                                       
}

