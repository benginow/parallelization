import numpy as np

def store_matrix(filename,matrix,store_row,start_mem_adress,n_vector_regs):
    f = open(filename,"a")
    data_reg_n = 3

    f.write ("movl r1," + str(start_mem_adress) + "\n")
    f.write ("movl r2,1\n")
    
    if not store_row:
        matrix = list(np.array(matrix).T)

    for row in matrix:
        vector_start_adress = start_mem_adress
        for i in row:
            f.write("movl r" + str(data_reg_n) + "," + str(i) + "\n")
            f.write ("st r" + str(data_reg_n) + ",r1\n")
            #increase memory adress
            f.write ("add r1, r1,r2\n")
            start_mem_adress+=1
        row_length = len(row)
        f.write("vld vr" + str(n_vector_regs) + "," + str(vector_start_adress) + "," + str(row_length) + "\n")
        n_vector_regs+=1
    return start_mem_adress,n_vector_regs

def main (filename,matrices, store_by_rows):
    n_vector_regs = 1
    start_mem_adress = 220
    f = open(filename,"w")
    f.close()

    for matrix, store_by_row in list (zip(matrices,store_by_rows)):
        start_mem_adress,n_vector_regs = store_matrix(filename,matrix,store_by_row,start_mem_adress,n_vector_regs)

matrix_1 = [[1,2,3],[4,5,6],[7,8,9]]
matrix_2 = [[1,2,3],[1,2,3],[1,2,3]]
matrices = [matrix_1,matrix_2]
store_by_rows = [True, False]
filename = "matrix_multiplication_stored.txt"

main (filename,matrices, store_by_rows)