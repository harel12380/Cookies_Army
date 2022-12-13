def generateList():
    res = []
    temp = int("1234", 16)
    for i in range(int("35", 16)):
        temp = int(str(
            hex(
                (temp + int("4743", 16)) *
                int("11bf", 16)
            )
        )[-4:], 16)
        res += [str(temp)]
    res.reverse()
    return (res, temp)

def parse(num):
  # parse number and return his value as integer
  # but only its 4 last digits in hex
  return int(str(hex(num)[2:])[-4:], 16)

arr, start = generateList()
isFail = False
finish = False

# run on all of the numbers
for i in range(1, int("ffff", 16)):
    print(i)
    for j in range(1, int("ffff", 16)):
      # reset variables
      tempStart = start
      isFail = False
      # run and compare to the original array (<arr>)
      for k in range(1, int("35", 16)):
        currentCalc = parse(parse(tempStart * i) + j)
        tempStart = currentCalc
        if str(currentCalc) != arr[k]:
            isFail = True
            break
      if isFail == False:
          print("Mul by: ", i, '\t', "Add: ", j)
          finish = True
          break
    if finish:
        break
