#!/usr/bin/python

import random
import os
from tests.utils import twos_bin, bin

# Define Constants here
# from src/Opcode.vh
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
FNC_BEQ         = 0b000
FNC_BNE         = 0b001
FNC_BLT         = 0b100
FNC_BGE         = 0b101
FNC_BLTU        = 0b110
FNC_BGEU        = 0b111

random.seed(os.urandom(32))
file = open('tests/stage2/Jumptestvectors.input', 'w')

testcases = 0

def random_inputs():
    opcode = random.randint(0, 0b111_1111)
    funct3 = random.randint(0, 0b111)
    lt = random.randint(0, 1)
    eq = random.randint(0, 1 if lt == 0 else 0)
    return opcode, funct3, lt, eq

def isJump(opcode, funct3, lt, eq):
    if opcode in [OPC_JAL, OPC_JALR]:
        return '1'
    if opcode in [OPC_BRANCH]:
        if (funct3 == FNC_BNE and eq == 0):
            return '1'
        if (funct3 == FNC_BEQ and eq == 1):
            return '1'
        if ((funct3 == FNC_BGE or funct3 == FNC_BGEU) and lt == 0):
            return '1'
        if ((funct3 == FNC_BLT or funct3 == FNC_BLTU) and lt == 1):
            return '1'
    return '0'

def isS(opcode, funct3):
    if opcode == OPC_BRANCH:
        if funct3 in [FNC_BGEU, FNC_BLTU]:
            return '0'
        return '1'
    return '0'


def gen_vector(opcode, funct3, lt, eq):
    # [6:0] opcode, [9:7] funct3, [10] REF_s
    # [11] lt, [12] eq, [13] REF_jump
    global testcases
    testcases += 1

    REF_s = isS(opcode, funct3)
    REF_jump = isJump(opcode, funct3, lt, eq)

    return ''.join([bin(opcode, 7), bin(funct3, 3), REF_s, 
                    bin(lt, 1), bin(eq, 1), REF_jump][::-1])
                    

random_tests = 100

for i in range(random_tests):
    file.write(gen_vector(*random_inputs()) + '\n')

# ---------- Extra Tests ---------- 
    
opcodes = [OPC_NOOP, OPC_LUI, OPC_AUIPC, OPC_JAL, OPC_JALR, OPC_BRANCH, OPC_STORE, OPC_LOAD, OPC_ARI_RTYPE, OPC_ARI_ITYPE, OPC_CSR]
branch_fncs = [FNC_BEQ, FNC_BNE, FNC_BLT, FNC_BGE, FNC_BLTU, FNC_BGEU]

for opcode in opcodes:
    _, funct3, lt, eq = random_inputs()
    if opcode == OPC_BRANCH:
        for funct3 in branch_fncs:
            file.write(gen_vector(opcode, funct3, lt, eq) + '\n')
    else:
        for _ in range(5):
            funct3 = random.randint(0, 0b111)
            file.write(gen_vector(opcode, funct3, lt, eq) + '\n')

print(f'Total number of testcases: {testcases}')