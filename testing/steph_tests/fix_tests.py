import os
for file in os.listdir("/u/stephane/parallelization/testing/steph_tests"):
    if file.endswith(".ok"):
        if file == "t01.ok":
            continue
        f = open(file,"r")
        lines = [line.rstrip() for line in f]
        f.close()
        f = open(file,"w")
        print (file)
        print (lines)
        for line in lines:
            f.write(chr(int(line)))
        f.close()
