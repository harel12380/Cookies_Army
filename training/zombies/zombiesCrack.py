
start = int("7df9", 16)
toSub = int("4743", 16)
res = int("4aca", 16)
ans = []

for i in range(1, int("ffff", 16)):
  for j in range(1, int("ffff", 16)):
    if (str(hex((start + j) * i))[-4:] == hex(res)[-4:]):
      ans += [i, j]
      print(ans)
print("result is: " + ans)  

#int("", 16);
#hex(42)