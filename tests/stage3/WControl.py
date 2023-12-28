#!/usr/bin/python

import random
import os
from tests.utils import twos_bin, bin

# Define Constants here
OPC_NOOP        = 0b0000000
OPC_LUI         = 0b0110111
OPC_AUIPC       = 0b0010111
OPC_JAL         = 0b1101111
OPC_JALR        = 0b1100111
OPC_BRANCH      = 0b1100011
OPC_STORE       = 0b0100011
OPC_LOAD        = 0b0000011
OPC_ARI_RTYPE   = 0b0110011
OPC_ARI_ITYPE   = 0b0010011
OPC_CSR         = 0b1110011

FNC_LB   = 0b000
FNC_LH   = 0b001
FNC_LW   = 0b010
FNC_LBU  = 0b100
FNC_LHU  = 0b101
FNC_SB   = 0b000
FNC_SH   = 0b001
FNC_SW   = 0b010

FNC_RW   = 0b001
FNC_RWI  = 0b101

SEL_MEM  = '00'
SEL_ALU  = '01'
SEL_PC4  = '10'

opcodes = [OPC_NOOP, OPC_LUI, OPC_AUIPC, OPC_JAL, OPC_JALR, OPC_BRANCH, OPC_STORE, OPC_LOAD, OPC_ARI_RTYPE, OPC_ARI_ITYPE, OPC_CSR]
store_fncs = [FNC_SB, FNC_SH, FNC_SW]
csr_fncs = [FNC_RW, FNC_RWI]

random.seed(os.urandom(32))
file = open('tests/stage3/WControltestvectors.input', 'w')

testcases = 0

def random_inputs():
    opcode = random.randint(0, 0b111_1111)
    if random.randint(0, 99) < 90:
        opcode = opcodes[random.randint(0, len(opcodes)-1)]
    funct3 = random.randint(0, 0b111)
    return opcode, funct3

def wb_sel(opcode):
    if opcode in [OPC_LUI, OPC_AUIPC, OPC_ARI_ITYPE, OPC_ARI_RTYPE, OPC_CSR]:
        return SEL_ALU
    elif opcode in [OPC_JAL, OPC_JALR]:
        return SEL_PC4
    elif opcode in [OPC_LOAD]:
        return SEL_MEM
    return 'xx'


def gen_vector(opcode, funct3):
    # [6:0] opcode, [9:7] funct3
    # [11:10] REF_wb_sel, [12] REF_rwe, [13] REF_csr_we
    global testcases
    testcases += 1

    REF_wb_sel = wb_sel(opcode)
    REF_rwe = '1' if opcode in [OPC_LUI, 
                                OPC_AUIPC, 
                                OPC_ARI_ITYPE, 
                                OPC_ARI_RTYPE, 
                                OPC_JAL, 
                                OPC_JALR, 
                                OPC_LOAD] else '0'
    REF_csr_we = '1' if opcode == OPC_CSR and funct3 in [FNC_RW, FNC_RWI] else '0'

    return ''.join([bin(opcode, 7), bin(funct3, 3), 
                    REF_wb_sel, REF_rwe, REF_csr_we][::-1])

random_tests = 100

for i in range(random_tests):
    file.write(gen_vector(*random_inputs()) + '\n')

# ---------- Extra Tests ----------


for opcode in opcodes:
    if opcode == OPC_STORE:
        for funct3 in store_fncs:
            file.write(gen_vector(opcode, funct3) + '\n')
    elif opcode == OPC_CSR:
        for funct3 in csr_fncs:
            file.write(gen_vector(opcode, funct3) + '\n')
    else:
        for _ in range(10):
            _, funct3= random_inputs()
            file.write(gen_vector(opcode, funct3) + '\n')

print(f'Total number of testcases: {testcases}')