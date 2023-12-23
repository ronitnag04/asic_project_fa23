def twos_bin(x, width): # [int, int] -> str
    assert -(2**(width-1)) <= x and x <= (2**(width-1)) - 1, f'{x} cannot be represented in {width} bits'

    if x < 0:
        x = 2**width + x
    
    b = format(x, f'0{width}b')
    return b


def bin(x, width): # [int, int] -> str
    assert 0 <= x and x <= (2**(width)) - 1, f'{x} cannot be represented in {width} bits'
    b = format(x, f'0{width}b')
    return b

def int_twos(b, width): # [str, int] -> int
    val = int(b, base=2)
    if b[0] == '1':
        return val - (1 << width)
    return val
