#!/usr/bin/python

import random
import os
from tests.utils import twos_bin, bin

# Define Constants here

random.seed(os.urandom(32))
file = open('tests/stage1/CSRtestvectors.input', 'w')

testcases = 0

# ------------ Mock CSR -----------
csr = 0

def random_inputs():    
    wb_data = random.randint(0, 0xffff_ffff)
    csr_we   = random.randint(0, 1)
    stall = 1 if random.randint(0, 99) < 20 else 0          # Stall 20% of the time
    reset = 1 if random.randint(0, 99) < 10 else 0          # Reset 10% of the time
    return reset, stall, csr_we, wb_data

def gen_vector(reset, stall, csr_we, wb_data): 
    # [0] reset, [1] stall, [2] csr_we, [34:3] wb_data
    # [66:35] REF_csrd
    global testcases
    global csr
    testcases += 1

    if reset == 1:
        csr = 0
    elif stall == 0 and csr_we == 1:
        csr = wb_data

    return ''.join([bin(reset, 1), bin(stall, 1), bin(csr_we, 1), bin(wb_data, 32), bin(csr, 32)][::-1])

random_tests = 100

file.write(gen_vector(1, 0, 0, 0) + '\n')
for i in range(random_tests):
    file.write(gen_vector(*random_inputs()) + '\n')

# ---------- Extra Tests ---------- 

print(f'Total number of testcases: {testcases}')