#!/usr/bin/python

import random
import os
from tests.utils import twos_bin, bin

# Define Constants here

random.seed(os.urandom(32))
file = open('tests/stage1/ImmGentestvectors.input', 'w')

testcases = 0

imm_types = ['R', 'I', 'I*', 'S', 'B', 'U', 'J']

imm_range_funcs = {
    'R':  lambda : 'x',
    'I':  lambda : random.randint(-(2**11), (2**11)-1),
    'I*': lambda : random.randint(       0, (2**5) -1),
    'S':  lambda : random.randint(-(2**11), (2**11)-1),
    'B':  lambda : random.randint(-(2**12), (2**12)-1) >> 1 << 1,
    'U':  lambda : random.randint(-(2**31), (2**31)-1) >> 12 << 12,
    'J':  lambda : random.randint(-(2**20), (2**20)-1) >> 1 << 1
}

def register_inst(imm):
    rs2    = bin(random.randint(0, 31), 5)
    rs1    = bin(random.randint(0, 31), 5)
    funct3 = bin(random.randint(0, 7), 3)
    funct7 = ['0000000', '0100000'][random.randint(0, 1) if funct3 in ['000', '101'] else 0] 
    rd     = bin(random.randint(0, 31), 5)
    opcode = '0110011'
    return funct7 + rs2 + rs1 + funct3 + rd + opcode

def immediate_inst(imm):
    match (random.randint(0, 2)):
        case 0: 
            opcode = '0010011'
            funct3 = ['000', '111', '110', '100', '010', '011'][random.randint(0, 5)]
        case 1:
            opcode = '0000011'
            funct3 = ['000', '100', '001', '101', '010'][random.randint(0, 4)]
        case 2:
            opcode = '1100111'
            funct3 = '000'
    rs1    = bin(random.randint(0, 31), 5)
    rd     = bin(random.randint(0, 31), 5)
    return twos_bin(imm, 12) + rs1 + funct3 + rd + opcode   

def immediate_star_inst(imm):
    opcode = '0010011'
    funct3 = ['001', '101'][random.randint(0, 1)]
    funct7 = ['0000000', '0100000'][random.randint(0, 1) if funct3 == '101' else 0]
    rs1    = bin(random.randint(0, 31), 5)
    rd     = bin(random.randint(0, 31), 5)
    return funct7 + bin(imm, 5) + rs1 + funct3 + rd + opcode

def store_inst(imm):
    b = twos_bin(imm, 12)
    # 11 10  9  8  7  6  5  4  3  2  1  0    bit position
    #  0  1  2  3  4  5  6  7  8  9 10 11    index
    rs2    = bin(random.randint(0, 31), 5)
    rs1    = bin(random.randint(0, 31), 5)
    funct3 = bin(random.randint(0, 2) , 3)
    opcode = '0100011'
    return b[0:7] + rs2 + rs1 + funct3 + b[7:12] + opcode

def branch_inst(imm):
    b = twos_bin(imm, 13)
    # 12 11 10  9  8  7  6  5  4  3  2  1  0    bit position
    #  0  1  2  3  4  5  6  7  8  9 10 11 12    index
    rs2    = bin(random.randint(0, 31), 5)
    rs1    = bin(random.randint(0, 31), 5)
    funct3 = bin(random.randint(0, 7), 3)
    return b[0] + b[2:8] + rs2 + rs1 + funct3 + b[8:12] + b[1] + '1100011'

def upper_inst(imm):
    b = twos_bin(imm, 32)
    rd     = bin(random.randint(0, 31), 5)
    opcode = ['0010111', '0110111'][random.randint(0, 1)]
    return b[0:20] + rd + opcode

def jump_inst(imm):
    b = twos_bin(imm, 21)
    # 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0    bit position
    #  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20    index
    rd     = bin(random.randint(0, 31), 5)
    return b[0] + b[10:20] + b[9] + b[1:9] + rd + '1101111'

imm_inst_func = {
    'R':  register_inst,
    'I':  immediate_inst,
    'I*': immediate_star_inst,
    'S':  store_inst,
    'B':  branch_inst,
    'U':  upper_inst,
    'J':  jump_inst
}


def random_inputs(type_num):
    imm_type = imm_types[type_num]
    imm = imm_range_funcs[imm_type]()
    inst = imm_inst_func[imm_type](imm)
    return inst, imm


def gen_vector(inst, REF_Imm):
    # [31:0] inst, [63:32] REF_Imm
    global testcases

    testcases += 1
    if isinstance(REF_Imm, str):
        REF_Imm = 'x'*32
    else:
        REF_Imm = twos_bin(REF_Imm, 32)
    
    return ''.join([REF_Imm, # '|', 
                    inst])


random_tests = 100  # per type

for type_num in range(7):
    # file.write('\n' + 'Type ' + imm_types[type_num] + ' Tests' + '\n\n')
    for i in range(random_tests):
        file.write(gen_vector(*random_inputs(type_num)) + '\n')

# ---------- Extrema Tests ---------- 
imm_ranges = {
    'R':  (0, 0),
    'I':  (-(2**11), (2**11)-1),
    'I*': (0, 31),
    'S':  (-(2**11) , (2**11)-1),
    'B':  (-4096 , 4094),
    'U':  (-524288 << 12 , 524287 << 12),
    'J':  (-1048576, 1048574)
}

for type, (lower, upper) in imm_ranges.items():
    file.write(gen_vector(imm_inst_func[type](lower), lower) + '\n')
    file.write(gen_vector(imm_inst_func[type](upper), upper) + '\n')


print(f'Total number of testcases: {testcases}')