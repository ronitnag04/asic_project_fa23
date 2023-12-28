#!/usr/bin/python

import random
import os
from tests.utils import twos_bin, bin

# Define Constants here

random.seed(os.urandom(32))
file = open('tests/stage1/CSRtestvectors.input', 'w')

testcases = 0

CSR_TOHOST = 0x51e

# ------------ Mock CSR -----------
csr_reg = 0

def random_inputs():    
    wb_data = random.randint(0, 0xffff_ffff)
    csr = CSR_TOHOST if random.randint(0, 99) < 60 else random.randint(0, 0xfff)   # csr=TOHOST 60% of the time
    csr_we   = random.randint(0, 1)
    stall = 1 if random.randint(0, 99) < 20 else 0          # Stall 20% of the time
    reset = 1 if random.randint(0, 99) < 10 else 0          # Reset 10% of the time
    return reset, stall, csr, csr_we, wb_data

def gen_vector(reset, stall, csr, csr_we, wb_data): 
    # [0] reset, [1] stall, [13:2] csr, [14] csr_we, [46:15] wb_data
    # [78:47] REF_csrd
    global testcases
    global csr_reg
    testcases += 1

    if reset == 1:
        csr_reg = 0
    elif stall == 0 and csr_we == 1 and csr == CSR_TOHOST:
        csr_reg = wb_data

    return ''.join([bin(reset, 1), bin(stall, 1), bin(csr, 12),
                    bin(csr_we, 1), bin(wb_data, 32), bin(csr_reg, 32)][::-1])

random_tests = 100

file.write(gen_vector(1, 0, 0, 0, 0) + '\n')
for i in range(random_tests):
    file.write(gen_vector(*random_inputs()) + '\n')

# ---------- Extra Tests ---------- 

print(f'Total number of testcases: {testcases}')