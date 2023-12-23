#!/usr/bin/python

import random
import os
from tests.utils import twos_bin, bin, int_twos

# Define Constants here

random.seed(os.urandom(32))
file = open('tests/stage2/Comparatortestvectors.input', 'w')

testcases = 0

def random_inputs():
    rs1d = random.randint(0, 0xffff_ffff)
    rs2d = random.randint(0, 0xffff_ffff)
    s = random.randint(0, 1)

    if s == 1:
        comp_rs1d = int_twos(bin(rs1d, 32), 32)
        comp_rs2d = int_twos(bin(rs2d, 32), 32)
    else:
        comp_rs1d = rs1d
        comp_rs2d = rs2d

    lt = 1 if comp_rs1d < comp_rs2d else 0
    eq = 1 if rs1d == rs2d else 0

    return rs1d, rs2d, s, lt, eq

def gen_vector(rs1d, rs2d, s, lt, eq):
    # [31:0] rs1d, [63:32] rs2d, [64] s
    # [65] REF_lt, [66] REF_eq 
    global testcases
    testcases += 1

    return ''.join([bin(eq, 1), bin(lt, 1), bin(s, 1), bin(rs2d, 32), bin(rs1d, 32)])

random_tests = 100

for i in range(random_tests):
    file.write(gen_vector(*random_inputs()) + '\n')

# ---------- Extra Tests ---------- 
# Test 1: Check Equality
file.write(gen_vector(0, 0, 0, 0, 1) + '\n')        # Signed mode should not affect
file.write(gen_vector(0, 0, 1, 0, 1) + '\n')
file.write(gen_vector(42, 42, 0, 0, 1) + '\n')        
file.write(gen_vector(42, 42, 1, 0, 1) + '\n') 

# Test 2: Check Less Than
rs1d = int(twos_bin(-200, 32), base=2)
rs2d = int(twos_bin(-100, 32), base=2)       
file.write(gen_vector(rs1d, rs2d, 0, 1, 0) + '\n') 
file.write(gen_vector(rs1d, rs2d, 1, 1, 0) + '\n') 


rs1d = int(twos_bin(-200, 32), base=2)
rs2d = int(twos_bin(100, 32), base=2)       
file.write(gen_vector(rs1d, rs2d, 0, 0, 0) + '\n') 
file.write(gen_vector(rs1d, rs2d, 1, 1, 0) + '\n') 

rs1d = int(twos_bin(200, 32), base=2)
rs2d = int(twos_bin(-100, 32), base=2)       
file.write(gen_vector(rs1d, rs2d, 0, 1, 0) + '\n') 
file.write(gen_vector(rs1d, rs2d, 1, 0, 0) + '\n')

rs1d = int(twos_bin(200, 32), base=2)
rs2d = int(twos_bin(100, 32), base=2)       
file.write(gen_vector(rs1d, rs2d, 0, 0, 0) + '\n') 
file.write(gen_vector(rs1d, rs2d, 1, 0, 0) + '\n')


print(f'Total number of testcases: {testcases}')