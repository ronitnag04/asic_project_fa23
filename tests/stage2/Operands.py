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

def random_inputs(rs1, rs2):    # TODO: Complete Constrained Random input generation

    pc = random.randint(0, 0xffff_ffff)
    rs1d = random.randint(0, 0xffff_ffff) if rs1 != 0 else 0
    rs2d = random.randint(0, 0xffff_ffff) if rs2 != 0 else 0
    imm = random.randint(0, 0xffff_ffff)

    wb_data_mw = random.randint(0, 0xffff_ffff)

    return pc, rs1d, rs2d, imm, wb_data_mw

def gen_vector(pc, rs1d, rs2d, imm, wb_data_mw, OPC, rs1, rs2, rd_mw, rwe_mw):
    # [6:0] opcode, [11:7] rs1, [16:12] rs2
    # [48:17] pc, [80:49] rs1d, [112:81] rs2d, [144:113] imm, [176:145] wb_data_mw
    # [181:177] rd_mw, [182] rwe_mw
    # [214:183] REF_A, [246:215] REF_B
    global testcases
    testcases += 1

    opcode = opcodes[OPC][0]
    Asel = opcodes[OPC][1][0]
    Bsel = opcodes[OPC][1][1]

    true_rs1d = rs1d
    if (rd_mw == rs1 and rd_mw != 0 and rwe_mw == 1):
        true_rs1d = wb_data_mw

    true_rs2d = rs2d
    if (rd_mw == rs2 and rd_mw != 0 and rwe_mw == 1):
        true_rs2d = wb_data_mw

    REF_A = [true_rs1d, pc][Asel]
    REF_B = [true_rs2d, imm][Bsel]

    return ''.join([opcode, bin(rs1, 5), bin(rs2, 5),
                    bin(pc, 32), bin(rs1d, 32), bin(rs2d, 32), bin(imm, 32), bin(wb_data_mw, 32),
                    bin(rd_mw, 5), bin(rwe_mw, 1), 
                    bin(REF_A, 32), bin(REF_B, 32)][::-1])

loops = 10

for OPC in opcodes.keys():
    file.write(gen_vector(*random_inputs(0, 0), OPC, 0, 0, 0, 0) + '\n')                  # Natural with x0
    file.write(gen_vector(*random_inputs(0, 0), OPC, 0, 0, 0, 1) + '\n')                  # Forward x0
    for _ in range(loops):
        rs1 = random.randint(1, 31)
        rs2 = random.randint(1, 31)
        file.write(gen_vector(*random_inputs(rs1, rs2), OPC, rs1, rs2, rs1, 0) + '\n')    # Natural rs1
        file.write(gen_vector(*random_inputs(rs1, rs2), OPC, rs1, rs2, rs2, 0) + '\n')    # Natural rs2
        file.write(gen_vector(*random_inputs(rs1, rs2), OPC, rs1, rs2, rs1, 1) + '\n')    # Forward rs1
        file.write(gen_vector(*random_inputs(rs1, rs2), OPC, rs1, rs2, rs2, 1) + '\n')    # Forward rs2

# ---------- Extra Tests ----------

print(f'Total number of testcases: {testcases}')