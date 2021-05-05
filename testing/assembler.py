def main (file_name):
    f = open(file_name + ".txt", "r")
    lines = f.readlines()
    f.close()

    ins_opcode = {"add": "0000",
                "sub":"0001",
                "mul":"0010",
                "div":"0011",
                "movl":"0100",
                "movh":"0101",
                "jz":["0110","0000"],
                "jnz":["0110","0001"],
                "js":["0110","0010"],
                "jns":["0110","0011"],
                "ld":["0111","0000"],
                "st":["0111","0001"],
                "vadd":"1000",
                "vsub":"1001",
                "vmul":"1010",
                "vdiv":"1011",
                "vld":"1100",
                "vst":"1101",
                "vdot":"1110",
                "HALT":"1111",}

    ins2write = []

    for line in lines:
        line = line.strip()
        line = line.replace(" ", ",")
        line_ = line.split(",")
        line = []
        for l in line_:
            l = l.strip()
            if l != "":
                line.append(l)
        
        ins = line[0]
        opcode = ins_opcode.get(ins)
        
        if ins == "add" or ins == "sub" or ins == "mul" or ins == "div":
            #add rt,ra,rb
            ra = int(line[2].replace("r",""))
            ra = "{0:04b}".format(ra)

            rb = int(line[3].replace("r",""))
            rb = "{0:04b}".format(rb)

            rt = int(line[1].replace("r",""))
            rt = "{0:04b}".format(rt)

            ins2binary = opcode + ra + rb + rt
        elif ins == "vadd" or ins == "vsub" or ins == "vmul" or ins == "vdiv":
            ra = int(line[2].replace("vr",""))
            ra = "{0:04b}".format(ra)

            rb = int(line[3].replace("vr",""))
            rb = "{0:04b}".format(rb)

            rt = int(line[1].replace("vr",""))
            rt = "{0:04b}".format(rt)

            ins2binary = opcode + ra + rb + rt
        elif ins == "vdot":
            ra = int(line[2].replace("vr",""))
            ra = "{0:04b}".format(ra)

            rb = int(line[3].replace("vr",""))
            rb = "{0:04b}".format(rb)

            rt = int(line[1].replace("r",""))
            rt = "{0:04b}".format(rt)

            ins2binary = opcode + ra + rb + rt
        elif ins == "vld" or ins == "vst":
            #vld vrt,ra,$imm+1
            ra = int(line[2].replace("r",""))
            ra = "{0:04b}".format(ra)

            i = int(line[3]) - 1
            i = "{0:04b}".format(i)

            rt = int(line[1].replace("vr",""))
            rt = "{0:04b}".format(rt)
            ins2binary = opcode + ra + i + rt
        elif ins == "movl" or ins == "movh":
            i = int (line[2])
            i = "{0:08b}".format(i)

            rt = int(line[1].replace("r",""))
            rt = "{0:04b}".format(rt)

            ins2binary = opcode + i + rt
        elif ins == "jz" or ins == "jnz" or ins == "js" or ins == "jns" or ins == "ld" or ins == "st":
            ra = int(line[2].replace("r",""))
            ra = "{0:04b}".format(ra)

            rt = int(line[1].replace("r",""))
            rt = "{0:04b}".format(rt)

            ins2binary = opcode[0] + ra + opcode[1] + rt
        elif ins == "HALT":
            ins2binary = "1111111111111111"
        else:
            print("INSTRUCTION NOT RECOGNIZED")
            ins2binary = "ERROR"

        ins2write.append(ins2binary)

    open(file_name + ".hex","w")
    f = open(file_name + ".hex","a")
    f.write("@0\n")
    for line in ins2write:
        encoded = "0x{:04x}".format(int(line,2))
        encoded = encoded.replace("0x","")
        f.write(encoded + "\n")

main ("testing/t02")