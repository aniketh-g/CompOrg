import os 

os.system("vivado -mode batch -source automate.tcl")

f1 = open("test_out.txt", "r")
f2 = open("output.txt", "r")

p_orig = []
p = []

print("\n")

for line in f1.readlines():
    p_orig.append(str(line).strip())

for line in f2.readlines():
    p.append(str(line).strip())

err = 0

for i in range(len(p_orig)):
    print('output from FPGA = {:>7}, expected p = {:>7}'.format(p[i], p_orig[i]))
    if(p[i] != p_orig[i]):
        err+=1
        print(p[i], p_orig[i])

print("\n")

if(err):
    print("FAIL.",err," out of",len(p),"failed.")
else:
    print("SUCCESS. All test cases passed.")