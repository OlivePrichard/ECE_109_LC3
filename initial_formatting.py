def read_image():
    colors = {}
    image = []
    with open('initials.xpm') as file:
        for i in range(1, 4):
            file.readline()

        for i in range(4, 177):
            line = file.readline()
            key = line[1:3]
            r = int(line[7:9], 16)
            g = int(line[9:11], 16)
            b = int(line[11:13], 16)
            if r == g == b:
                colors[key] = r
            else:
                print(f"Error on line {i}")
        
        for i in range(177, 257):
            image.append([])
            line = file.readline()
            length = line[1:].find('"')
            for j in range(1, length + 1, 2):
                key = line[j:j+2]
                image[-1].append(colors[key])
    
    return image

def is_col_empty(image, col):
    for row in range(len(image)):
        if image[row][col] != 0:
            return False
    return True

def trim_image(image):
    start = 0
    while is_col_empty(image, start):
        start += 1
    end = len(image[0])
    while is_col_empty(image, end - 1):
        end -= 1
    
    return [row[start:end] for row in image]

def compress(image):
    reduction = 256 // 32
    linear = []
    for row in range(len(image)):
        for col in range(len(image[row])):
            linear.append(image[row][col] //reduction)
    compressed = []
    i = 0
    while i < len(linear):
        color = linear[i]
        run_length = 0
        while run_length < 1023 and i + run_length + 1 < len(linear):
            if linear[i + run_length + 1] != color:
                break
            run_length += 1
        if run_length > 2:
            compressed.append(color + 32 * run_length)
            i += run_length + 1
        else:
            compressed.append(linear[i] + 32 * linear[i + 1] + 32**2 * linear[i + 2] + 32**3)
            i += 3
            # if linear[i + 2] == 0:
            #     i -= 1
            #     if linear[i + 1] == 0:
            #         i -= 1
    return compressed

def alt_compress(image):
    reduction = 256 // 32
    linear = []
    for row in range(len(image)):
        for col in range(len(image[row])):
            linear.append(image[row][col] // reduction)

def next_run(image, i):
    value = image[i]
    for j in range(i, len(image)):
        if image[j] != value:
            return j - i
    return -1

def lossy_compress(image):
    threshold = 127
    linear = []
    for col in range(len(image[0])):
        for row in range(len(image)):
            linear.append(1 if image[row][col] > threshold else 0)
    compressed = []
    i = 0
    while True:
        zeros = next_run(linear, i)
        i += zeros
        if zeros == -1:
            break
        ones = next_run(linear, i)
        i += zeros
        compressed.append(ones * 256 + zeros)
    return compressed

def write_to_file(values):
    with open('initials.asm', 'w') as file:
        file.write('.ORIG x0\n')
        for i, value in enumerate(values):
            file.write(' ' * 8 + f'.FILL x{value:04X}\n')
            if i % 128 == 127:
                file.write('\n')
        file.write('.END')

def read(values):
    c = 0
    pixels = []
    for value in values:
        if value >= 2**15:
            v = value - 2**15
            for _ in range(3):
                pixels.append(v % 32)
                v //= 32
                # if v == 0:
                #     break
        else:
            p = value % 32
            if p == 31:
                c += 1
            for _ in range(value // 32 + 1):
                pixels.append(p)
    
    print(len(pixels))
    # write_to_file(pixels)
    for i, pixel in enumerate(pixels):
        print('#' if pixel > 15 else ' ', end='')
        if i % 128 == 127:
            print()

def main():
    image = read_image()
    print(f'Image is {len(image[0])}px by {len(image)}px')
    compressed = compress(image)
    print(f'Compressed image is {len(compressed)} words long')
    write_to_file(compressed)
    read(compressed)

if __name__ == '__main__':
    main()
