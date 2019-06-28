"""
EEA Implemented in python
Assuming a >= b >= 0
"""
def egcd(a, b):
    """ Returns gcd of a & b, and integers x & y such that xa + yb = gcd. Assumes a >= b >= 0"""
    quotient = a // b
    remainder = a % b

    if remainder == 0:
        return (b, 0, 1)

    gcd, x, y = egcd(b, remainder)
    print(x, y)
    return (gcd, y, x - y * quotient)

def write_egcd(a, b, test_file):
    """ Writes gcd, x, and y into a file, for various test cases """
    gcd, x, y = egcd(a, b)
    test_file.write("(a,b) = (" +str(a)+ ", " +str(b)+ ") : \
(gcd, x, y) = (" +str(gcd)+ ", " +str(x)+ ", " +str(y)+ ")\n")


TEST = open("egcd_test.txt", 'w')

write_egcd(16, 6, TEST)
write_egcd(64, 5, TEST)
write_egcd(98, 21, TEST)

TEST.close()
