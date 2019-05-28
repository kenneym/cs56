# Fibonachi numbers module:
# Description: Determines the neccessary minimum size of the q register for 
# the Extended Euclid Algorithm. This script was used to determine the size
# of the q register for 64 bit, 128 bit, and 256 bit RSA keys


# Determine the smallest number b in the Fibonachi sequence larger than n.
# Use the index of b in the Fibonachi sequence to determine the maximum 
# number of recursions that could occur when utilizing the Extended GCD 
# Algorithm to compute secret key d. (See additional documation for more details)

def fib_recursions(n):
    if n == 0: return -1 # n must be >= 1
    if n == 1: return 0  # 0 flips will occur if n = 1
    
    a, b = 0, 1 # Starting numbers in the Fibonacci Sequence
    index = 0

    # Find index of smallest fibonacci number larger than n
    while a < n:
        a, b = b, a + b
#       print(str(a) + " ")
        index += 1
    return index - 2 # subtract by 2 to obtain number of recursions

reg_sizes = open("reg_sizes.txt", 'w')

# phi of n, the larger of the two inputs to the Extended 
# Euclid's Algorithm, is always half the bits of the key

key_16 = 2**
key_64 = 2**32 
key_128 = 2**64
key_256 = 2**256

reg_sizes.write("16-bit test key: " + str(fib_recursions(key_16)) + "\n")
reg_sizes.write("64-bit key: " + str(fib_recursions(key_64)) + "\n")
reg_sizes.write("128-bit key: " + str(fib_recursions(key_128)) + "\n")
reg_sizes.write("256-bit key: " + str(fib_recursions(key_256)) + "\n")

reg_sizes.close()
