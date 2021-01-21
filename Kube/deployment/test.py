secret_number = 5
count = 0
limit = 9
while count <= limit:
    guess = int(input('Guess: '))
    if guess == secret_number:
        print("You got it.")
        break
    else:
        print("No..")
