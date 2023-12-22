def twos_bin(x, width):
    assert -(2**(width-1)) <= x and x <= (2**(width-1)) - 1, f'{x} cannot be represented in {width} bits'

    if x < 0:
        x = 2**width + x
    
    b = format(x, f'0{width}b')
    return b


def bin(x, width):
    assert 0 <= x and x <= (2**(width)) - 1, f'{x} cannot be represented in {width} bits'
    b = format(x, f'0{width}b')
    return b
