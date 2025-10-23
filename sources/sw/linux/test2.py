'''
Read/Write shared memory (AXI BRAM controller) using the device.py classes 
'''
from device import *
import time 

uio = Uio('1')

region = uio.region(0) 

start = time.time()

for i in range(int(region.size/8)):     # 8192 / 8 = 1024
        offset = i*8
        data = int.from_bytes(region.read(8, offset=offset), 'little').to_bytes(8, 'big')
        print(f'Addr {i}: 0x{data.hex()}')
        # overwrite the old data
        uio.write(bytes(8), offset=offset)

end = time.time()

print(f'It took {end-start}s to read {int(region.size/8)} BRAM addresses')

