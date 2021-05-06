def store_text(filename, string, substring):
    f = open(filename,"w")

    f.write("movh r1,0" + "\n")

    i = 0
    for ch in string:
        num = ord(ch)
        f.write("movl r1," + str(num) + "\n")
        dest = hex(32768 + i)
        f.write("movl r2," + str(int(dest[4:6],16)) + "\n")
        f.write("movh r2," + str(int(dest[2:4],16)) + "\n")
        f.write("st r2,r1" + "\n")
        i += 1

    i = 0
    for ch in substring:
        num = ord(ch)
        f.write("movl r1," + str(num) + "\n")
        dest = hex(45056+ i)
        f.write("movl r2," + str(int(dest[4:6],16)) + "\n")
        f.write("movh r2," + str(int(dest[2:4],16)) + "\n")
        f.write("st r2,r1" + "\n")
        i += 1

    for i in range(16):
        dest = hex(57344 + i)
        f.write("movl r1," + "1" + "\n")
        f.write("movl r2," + str(int(dest[4:6],16)) + "\n")
        f.write("movh r2," + str(int(dest[2:4],16)) + "\n")
        f.write("st r2,r1" + "\n")

    for i in range(16):
        dest = hex(45312 + i)
        f.write("movl r1," + str(ord(substring[0])) + "\n")
        f.write("movl r2," + str(int(dest[4:6],16)) + "\n")
        f.write("movh r2," + str(int(dest[2:4],16)) + "\n")
        f.write("st r2,r1" + "\n")

    for i in range(16):
        dest = hex(45568 + i)
        f.write("movl r1," +  str(ord(substring[-1])) + "\n")
        f.write("movl r2," + str(int(dest[4:6],16)) + "\n")
        f.write("movh r2," + str(int(dest[2:4],16)) + "\n")
        f.write("st r2,r1" + "\n")
    
        
    f.write("movl r1," + str(len(string)) + "\n")
    f.write("movl r2," + str(len(substring)) + "\n")

    f.close()

store_text("testingWrite.txt", "Hello World", "World")
