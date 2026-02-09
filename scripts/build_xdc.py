'''
Script to generate the .xdc constraints file for the 64-channel implementation. 
In the design, the 64 discriminator inputs are sent to the HDIO A/B/C banks as follows:

Data[0:63] -----> D[0:63]

where:

-------------> D[0:15]  -----<HDA[0:15]>
-------------> D[16:39] -----<HDB[0:23]>
-------------> D[40:63] -----<HDC[0:23]>
'''
import pandas as pd
df = pd.read_csv('Kria_pin_name_mapping.csv')
df = df.reset_index()

IOSTANDARD = 'LVCMOS33'

placeholder = '''
# %s
set_property PACKAGE_PIN %s [get_ports {tdc_hit[%s]}]
set_property IOSTANDARD %s [get_ports {tdc_hit[%s]}]
'''

# Discriminator Input,FPGA Signal Name,Package Pin
for index, row in df.iterrows():
    sig_name = row['FPGA Signal Name']
    pkg_pin = row['Package Pin']
    print(placeholder%(sig_name, pkg_pin, index, IOSTANDARD, index))
