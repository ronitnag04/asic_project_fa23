#!/usr/bin/python

import random
import os

# Define Constants here
# From src/stage1/stage1_control.vh
PC_SEL_PC_4 = 0b0
PC_SEL_ALU_OUT = 0b1

# From src/const.vh
PC_RESET = 0x00002000

random.seed(os.urandom(32))
file = open('PCtestvectors.input', 'w')


def bin(x, width):
    if x < 0: x = (~x) + 1
    return ''.join([(x & (1 << i)) and '1' or '0' for i in range(width-1, -1, -1)])


def PC_valid(PC):
    return (PC // 4) * 4


Cur_PC = PC_valid(random.randint(0, 0xffffffff))
testcases = 0


def get_ref_PC(ALU_Out, PC_Sel, reset, stall):
    PC_4 = (Cur_PC + 4) % (2**32)

    if (reset == 1):
        return PC_RESET
    if (stall == 1):
        return Cur_PC
    if (PC_Sel == PC_SEL_ALU_OUT):
        return ALU_Out
    if (PC_Sel == PC_SEL_PC_4):
        return PC_4
    values_string = f'Cur_PC: {Cur_PC}, ALU_Out: {ALU_Out}, PC_Sel: {PC_Sel}, reset: {reset}, stall: {stall}'
    error_string = f'Inputs did not generate valid REF_PC_OUT\n Inputs: {values_string}'
    raise ValueError(error_string)


def random_inputs():
    ALU_Out = PC_valid(random.randint(0, 0xffffffff))
    PC_Sel = 0 if random.randint(0, 99) < 70 else 0          # Step 70% of the time
    reset =  1 if random.randint(0, 99) < 20 else 0          # Reset 10% of the time
    stall =  1 if random.randint(0, 99) < 20 else 0          # Stall 10% of the time

    REF_PC_Out = get_ref_PC(ALU_Out, PC_Sel, reset, stall)

    return ALU_Out, REF_PC_Out, PC_Sel, reset, stall


def gen_vector(ALU_Out, REF_PC_Out, PC_Sel, reset, stall):
    # [31:0] ALU_Out, [63:32] REF_PC_Out
    # [64] PC_Sel, [65] reset, [66] stall,
    assert ALU_Out >= 0 and ALU_Out <= 0xffff_ffff
    assert REF_PC_Out >= 0 and ALU_Out <= 0xffff_ffff
    assert PC_Sel == 1 or PC_Sel == 0
    assert reset == 1 or reset == 0
    assert stall == 1 or stall == 0
    global Cur_PC
    global testcases

    Cur_PC = REF_PC_Out
    testcases += 1
    
    return ''.join([bin(stall, 1), 
                    bin(reset, 1), 
                    bin(PC_Sel, 1), # '|', 
                    bin(REF_PC_Out, 32), # '|', 
                    bin(ALU_Out, 32)])


random_tests = 300

file.write(gen_vector(0, PC_RESET, 0, 1, 0) + '\n') # Reset vector to start
for i in range(random_tests):
    file.write(gen_vector(*random_inputs()) + '\n')

# ---------- Manual Tests ---------- 
# Test 1: Overflow
file.write(gen_vector(0xffff_fffc, 0xffff_fffc, 1, 0, 0) + '\n')    # Set PC in penultimate position
file.write(gen_vector(0, 0x0000_0000, 0, 0, 0) + '\n')              # Step PC
file.write(gen_vector(0, 0x0000_0004, 0, 0, 0) + '\n')              # Step PC

# Test 2: Reset
file.write(gen_vector(0x0000_0000, 0x0000_2000, 0, 1, 0) + '\n')    # Reset PC
file.write(gen_vector(0, 0x0000_2004, 0, 0, 0) + '\n')              # Step PC
file.write(gen_vector(0, 0x0000_2000, 0, 1, 1) + '\n')              # Reset takes precedence over stall
file.write(gen_vector(0, 0x0000_2004, 0, 0, 0) + '\n')              # Step PC
file.write(gen_vector(0x0000_ffff, 0x0000_2000, 1, 1, 0) + '\n')    # Reset takes precedence over ALU
file.write(gen_vector(0, 0x0000_2004, 0, 0, 0) + '\n')              # Step PC
file.write(gen_vector(0x0000_ffff, 0x0000_2000, 1, 1, 1) + '\n')    # Reset takes precedence over stall & ALU
file.write(gen_vector(0, 0x0000_2004, 0, 0, 0) + '\n')              # Step PC
file.write(gen_vector(0x0000_ffff, 0x0000_2000, 0, 1, 0) + '\n')    # Stay at 0x2000 while reset is high
file.write(gen_vector(0x0000_ffff, 0x0000_2000, 0, 1, 0) + '\n')    # Stay at 0x2000 while reset is high
file.write(gen_vector(0x0000_ffff, 0x0000_2000, 0, 1, 0) + '\n')    # Stay at 0x2000 while reset is high
file.write(gen_vector(0x0000_ffff, 0x0000_2000, 0, 1, 0) + '\n')    # Stay at 0x2000 while reset is high
file.write(gen_vector(0x0000_ffff, 0x0000_2004, 0, 0, 0) + '\n')    # Step once reset is low

# Test 3: Stall
file.write(gen_vector(0x0000_0000, 0x0000_2000, 0, 1, 0) + '\n')    # Reset PC
file.write(gen_vector(0, 0x0000_2004, 0, 0, 0) + '\n')              # Step PC
file.write(gen_vector(0, 0x0000_2008, 0, 0, 0) + '\n')              # Step PC
file.write(gen_vector(0, 0x0000_2008, 0, 0, 1) + '\n')              # Stall PC
file.write(gen_vector(0, 0x0000_2008, 0, 0, 1) + '\n')              # Stall PC
file.write(gen_vector(0, 0x0000_2008, 0, 0, 1) + '\n')              # Stall PC
file.write(gen_vector(0, 0x0000_200c, 0, 0, 0) + '\n')              # Step PC
file.write(gen_vector(0, 0x0000_200c, 0, 0, 1) + '\n')              # Stall PC
file.write(gen_vector(0, 0x0000_2010, 0, 0, 0) + '\n')              # Step PC

# Test 4: ALU Load
file.write(gen_vector(0x0000_0000, 0x0000_2000, 0, 1, 0) + '\n')    # Reset PC
file.write(gen_vector(0x0000_5230, 0x0000_2004, 0, 0, 0) + '\n')    # Step PC
file.write(gen_vector(0x0000_5230, 0x0000_5230, 1, 0, 0) + '\n')    # Load from ALU
file.write(gen_vector(0, 0x0000_5234, 0, 0, 0) + '\n')              # Step PC

# TODO: Test ALU Misaligned address?


print(f'Total number of testcases: {testcases}')