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

CSR_TOHOST = 0x51E

opcodes = [OPC_NOOP, OPC_LUI, OPC_AUIPC, OPC_JAL, OPC_JALR, OPC_BRANCH, OPC_STORE, OPC_LOAD, OPC_ARI_RTYPE, OPC_ARI_ITYPE, OPC_CSR]
store_fncs = [FNC_SB, FNC_SH, FNC_SW]
csr_fncs = [FNC_RW, FNC_RWI]

random.seed(os.urandom(32))
file = open('tests/stage3/MWControltestvectors.input', 'w')

testcases = 0

def random_inputs():
    opcode = random.randint(0, 0b111_1111)
    if random.randint(0, 99) < 90:
        opcode = opcodes[random.randint(0, len(opcodes)-1)]
    funct3 = random.randint(0, 0b111)
    csr = random.randint(0, 0xfff)
    return opcode, funct3, csr

def w_mask(opcode, funct3):
    if opcode != OPC_STORE:
        return '0000'
    if funct3 == FNC_SB:
        return '0001'
    if funct3 == FNC_SH:
        return '0011'
    if funct3 == FNC_SW:
        return '1111'
    return '0000'

def wb_sel(opcode):
    if opcode in [OPC_LUI, OPC_AUIPC, OPC_ARI_ITYPE, OPC_ARI_RTYPE, OPC_CSR]:
        return SEL_ALU
    elif opcode in [OPC_JAL, OPC_JALR]:
        return SEL_PC4
    elif opcode in [OPC_LOAD]:
        return SEL_MEM
    return 'xx'


def gen_vector(opcode, funct3, csr):
    # [6:0] opcode, [9:7] funct3, [21:10] csr
    # [25:22] REF_w_mask, [26] REF_re, [28:27] REF_wb_sel, [29] REF_rwe
    global testcases
    testcases += 1

    REF_w_mask = w_mask(opcode, funct3)
    REF_re = '1' if opcode == OPC_LOAD else '0'
    REF_wb_sel = wb_sel(opcode)
    REF_rwe = '1' if opcode in [OPC_LUI, 
                                OPC_AUIPC, 
                                OPC_ARI_ITYPE, 
                                OPC_ARI_RTYPE, 
                                OPC_JAL, 
                                OPC_JALR, 
                                OPC_LOAD] else '0'
    REF_csr_we = '1' if opcode == OPC_CSR and funct3 in [FNC_RW, FNC_RWI] and csr == CSR_TOHOST else '0'

    return ''.join([bin(opcode, 7), bin(funct3, 3), bin(csr, 12), 
                    REF_w_mask, REF_re, REF_wb_sel, REF_rwe, REF_csr_we][::-1])

random_tests = 100

for i in range(random_tests):
    file.write(gen_vector(*random_inputs()) + '\n')

# ---------- Extra Tests ----------


for opcode in opcodes:
    if opcode == OPC_STORE:
        for funct3 in store_fncs:
            _, _, csr = random_inputs()
            file.write(gen_vector(opcode, funct3, csr) + '\n')
    elif opcode == OPC_CSR:
        for funct3 in csr_fncs:
            file.write(gen_vector(opcode, funct3, CSR_TOHOST) + '\n')
            _, _, csr = random_inputs()
            file.write(gen_vector(opcode, funct3, csr) + '\n')
    else:
        for _ in range(10):
            _, funct3, csr = random_inputs()
            file.write(gen_vector(opcode, funct3, csr) + '\n')

print(f'Total number of testcases: {testcases}')