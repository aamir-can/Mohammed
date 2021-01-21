numbers = [8, 1, 9, 5, 4, 3, 7, 0, 2, 4]
numbers = sorted(numbers)
for x in numbers:
    output = ''
    for count in range(x):
        output += 'x'
    print(output)
