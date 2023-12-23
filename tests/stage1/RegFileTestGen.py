#!/usr/bin/python

import random
import os
from tests.utils import twos_bin, bin

# Define Constants here

random.seed(os.urandom(32))
file = open('tests/stage1/RegFiletestvectors.input', 'w')

testcases = 0

# ---------- Mock RegFile ---------- 

regfile = [0 for _ in range(32)]



def updateReadRegFile(rs1, rs2, rd, wb_data, we, stall, reset):
    assert 0 <= rs1 and rs1 <= 31
    assert 0 <= rs2 and rs2 <= 31
    assert 0 <= rd and rd <= 31
    assert 0 <= wb_data and wb_data <= 0xffff_ffff
    assert we == 0 or we == 1
    assert stall == 0 or stall == 1
    assert reset == 0 or reset == 1

    if reset == 1:
        for i in range(32):
            regfile[i] = 0
    elif stall == 0:
        if (we == 1 and rd != 0):
            regfile[rd] = wb_data
    
    rs1d = regfile[rs1]
    rs2d = regfile[rs2]
    return rs1d, rs2d


def random_inputs():
    rs1 = random.randint(0, 31)
    rs2 = random.randint(0, 31)
    rd  = random.randint(0, 31)
    wb_data = random.randint(0, 0xffff_ffff)
    we    = random.randint(0, 1)
    stall = 1 if random.randint(0, 99) < 20 else 0          # Stall 20% of the time
    reset = 1 if random.randint(0, 99) < 10 else 0          # Reset 10% of the time

    return rs1, rs2, rd, wb_data, we, stall, reset


def gen_vector(rs1, rs2, rd, wb_data, we, stall, reset):
    # [4:0] rs1, [9:5] rs2, [14:10] rd
    # [46:15] wb_data
    # [47] we, [48] stall, [49] reset
    # [81:50] REF_rs1d
    # [113:82] REF_rs2d
    global testcases
    testcases += 1

    ref_rs1, ref_rs2 = updateReadRegFile(rs1, rs2, rd, wb_data, we, stall, reset)

    ref_output = ''.join([bin(ref_rs2, 32),
                          bin(ref_rs1, 32)])

    inputs = ''.join([bin(reset, 1), bin(stall, 1), bin(we, 1),
                      bin(wb_data, 32),
                      bin(rd, 5), bin(rs2, 5), bin(rs1, 5)])
    
    return ref_output + inputs


def full_check():
    i = 0
    while i < 32:
        file.write(gen_vector(i, i+1, 0, 0, 0, 0, 0) + '\n')
        i += 2



random_tests = 100  

for i in range(random_tests):
    file.write(gen_vector(*random_inputs()) + '\n')

# ---------- Manual Tests ------------
# Test 1: Write only affects rd register
for rd in range(32):
    wb_data = random.randint(0, 0xffff_ffff)
    file.write(gen_vector(0, 0, rd, wb_data, 1, 0, 0) + '\n')
    full_check()

# Test 2: Stall w/ write leaves regfile unaffected
rd  = random.randint(0, 31)
wb_data = random.randint(0, 0xffff_ffff)
file.write(gen_vector(0, 0, rd, wb_data, 1, 1, 0) + '\n')
full_check()

# Test 3: Reset priority over stall
rd  = random.randint(1, 31)
wb_data = random.randint(1, 0xffff_ffff)
file.write(gen_vector(0, 0, rd, wb_data, 1, 1, 1) + '\n')
for i in range(32):
    assert regfile[i] == 0
full_check()

# Test 4: Write to x0 does not affect
wb_data = random.randint(1, 0xffff_ffff)
file.write(gen_vector(0, 0, 0, wb_data, 1, 0, 0) + '\n')



print(f'Total number of testcases: {testcases}')