'''
Test reading from shared memory (AXI BRAM Controller) using UIO device with standard py libs
'''
import os  
import mmap
 
# Settings
uio_device = '/dev/uio1'
uio_size   = 8192
 
# Open the UIO device
memfile = os.open(uio_device, os.O_RDWR, os.O_SYNC)
 
if not memfile:
        print(f'Failed to open {uio_device}...')
 
# Map the UIO device
map = mmap.mmap(memfile, uio_size, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE)
 
print(map)
 
 
'''
# seek to the right memory pointer
map.seek(8)
 
# read 8 bytes from the memory (64-bit)
data = int.from_bytes(map.read(8), "little")
 
print(data)
'''
 
for i in range(500):
        pos = i*8
        map.seek(pos)
        data = int.from_bytes(map.read(8), 'little').to_bytes(8, 'big')
        print(f'Addr {i}: 0x{data.hex()}')
 
map.close()
