from math import sqrt
def calc_two(a,b, calculation='sum'):
    if calculation == 'sum':
        return a+b
    elif calculation == 'product':
        return a*b
    else:
        print('calculation isn\'t viable')
def calc_sqrt(a):
    return sqrt(a)
