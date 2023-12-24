#!/usr/bin/python

import random
import os
from tests.utils import twos_bin, bin

# Define Constants here

random.seed(os.urandom(32))
file = open('tests/stage2/Operandstestvectors.input', 'w')

testcases = 0

opcodes = {                        #[Asel, Bsel]
    "OPC_NOOP"       : ('0000000', [0, 0]),
    "OPC_LUI"        : ('0110111', [0, 1]),
    "OPC_AUIPC"      : ('0010111', [1, 1]),
    "OPC_JAL"        : ('1101111', [1, 1]),
    "OPC_JALR"       : ('1100111', [0, 1]),
    "OPC_BRANCH"     : ('1100011', [1, 1]),
    "OPC_STORE"      : ('0100011', [0, 1]),
    "OPC_LOAD"       : ('0000011', [0, 1]),
    "OPC_ARI_RTYPE"  : ('0110011', [0, 0]),
    "OPC_ARI_ITYPE"  : ('0010011', [0, 1])
}


def gen_vector(OPC, rs1, rs2, rd_mw, rwe_mw):
    # [6:0] opcode, [11:7] rs1, [16:12] rs2
    # [21:17] rd_mw, [22] rwe_mw
    # [23] REF_sel_rs1d, [24] REF_sel_rs2d
    # [25] REF_sel_a, [26] REF_sel_b
    global testcases
    testcases += 1

    opcode = opcodes[OPC][0]
    REF_sel_a = opcodes[OPC][1][0]
    REF_sel_b = opcodes[OPC][1][1]

    REF_sel_rs1d = 0
    if (rd_mw == rs1 and rd_mw != 0 and rwe_mw == 1):
        REF_sel_rs1d = 1

    REF_sel_rs2d = 0
    if (rd_mw == rs2 and rd_mw != 0 and rwe_mw == 1):
        REF_sel_rs2d = 1

    return ''.join([opcode, bin(rs1, 5), bin(rs2, 5),
                    bin(rd_mw, 5), bin(rwe_mw, 1), 
                    bin(REF_sel_rs1d, 1), bin(REF_sel_rs2d, 1),
                    bin(REF_sel_a, 1), bin(REF_sel_b, 1)][::-1])

loops = 10

for OPC in opcodes.keys():
    file.write(gen_vector(OPC, 0, 0, 0, 0) + '\n')              # Natural with x0
    file.write(gen_vector(OPC, 0, 0, 0, 1) + '\n')              # Forward x0
    for _ in range(loops):
        rs1 = random.randint(1, 31)
        rs2 = random.randint(1, 31)
        file.write(gen_vector(OPC, rs1, rs2, rs1, 0) + '\n')    # Natural rs1
        file.write(gen_vector(OPC, rs1, rs2, rs2, 0) + '\n')    # Natural rs2
        file.write(gen_vector(OPC, rs1, rs2, rs1, 1) + '\n')    # Forward rs1
        file.write(gen_vector(OPC, rs1, rs2, rs2, 1) + '\n')    # Forward rs2

# ---------- Extra Tests ----------

print(f'Total number of testcases: {testcases}')