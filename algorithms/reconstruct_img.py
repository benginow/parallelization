import cv2

#NOTE: this assumes that rows are outputted one element at a time
def reconstruct(filename,width):
    with open(filename) as f:
        pixels = f.readlines()
    pixels = [x.strip() for x in pixels]
    row_index = 0
    img = []
    row = []
    for i in range (len(pixels)):
        if row_index == width-1:
            img.append(row)
            row.clear()
            row_index = 0
        else:
            row.append(pixels[i])
            row_index+=1
    filename = filename.replace(".out",".png")
    cv2.imsave(filename, np.array(img))

